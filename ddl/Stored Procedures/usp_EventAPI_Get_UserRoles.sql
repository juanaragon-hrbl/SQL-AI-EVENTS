

CREATE PROCEDURE [dbo].[usp_EventAPI_Get_UserRoles]
    -- REQUIRED
   @UserID varchar(10)
  ,@Pwd varchar(20)
	-- OPTIONAL
  ,@Error int OUTPUT
  ,@ErrorMessage varchar(200) OUTPUT	
	-- QA/DEV
  ,@IsDevQA bit = 0    

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_UserRoles

USE:			EXEC usp_EventAPI_Get_UserRoles @UserID = 'SandhyaP',
                                               ,@Pwd = '1234', 
                                               ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                       ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						                       ,@IsDevQA = 0

DESCRIPTION:	Get the UserRole for the Events

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1	2009-01-22 Sandhya	Initial
2   2019-10-17  SushmaA	SRE updates for NOLOCK, NOCOUNT, SELECT *
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON


/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime

SET @StoredProcedure = 'usp_EventAPI_Get_EventSecurityRoles'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'

DECLARE
   @PK_SecurityUser int


/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/

IF EXISTS (SELECT PK_SecurityUser FROM dbo.SecurityUsers (NOLOCK) WHERE UserID = @UserID AND UserPassword = @Pwd)
  BEGIN
          (SELECT @PK_SecurityUser = PK_SecurityUser FROM dbo.SecurityUsers WITH(NOLOCK) WHERE UserID = @UserID AND UserPassword = @Pwd)
  END
ELSE
  BEGIN
	SET @Error = 219
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
  END

 
/******************************************************************************
select record
******************************************************************************/

BEGIN TRY

	SELECT
         ES.PK_Event
        ,E.EventName
		,R.RoleName
        ,U.UserID
	FROM 
		dbo.EventSecurityRoles ES (NOLOCK) 
        INNER JOIN
        dbo.SecurityUsers U (NOLOCK) 
        ON
          U.PK_SecurityUser = ES.PK_SecurityUser
        INNER JOIN
        dbo.SecurityRoles R (NOLOCK) 
        ON
          R.PK_SecurityRole = ES.PK_SecurityRole
        INNER JOIN
        dbo.Event E (NOLOCK)
        ON
          E.PK_Event = ES.PK_Event
	WHERE 
		  U.PK_SecurityUser = @PK_SecurityUser

END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime  

/******************************************************************************
	end procedure
******************************************************************************/
END