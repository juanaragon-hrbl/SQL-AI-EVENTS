
CREATE PROCEDURE [dbo].[usp_EventAPI_AuthenticateUser]
    -- REQUIRED
   @UserName varchar(20)
  ,@Password varchar(20)
	-- OPTIONAL

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_AuthenticateUser

USE:			declare @e int
                       ,@em varchar(4000)

EXEC usp_EventAPI_AuthenticateUser @UserName = 'KelvinK'
                               ,@Password = '3456'
                               ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						       ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						       ,@IsDevQA = 0

DESCRIPTION:	Authenticate the username/password

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1	2009-01-22 Sandhya	Initial
2   2019-09-05 OrlandoL SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

	/******************************************************************************
		variable declaration
	******************************************************************************/

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';


	DECLARE
		@PK_SecurityUser int

	BEGIN TRY

		/******************************************************************************
		be sure the value of FK exists in referenced table
		******************************************************************************/


		IF EXISTS (SELECT PK_SecurityUser FROM dbo.SecurityUsers WITH (NOLOCK) WHERE UserID = @UserName AND UserPassword = @Password)
		  BEGIN
				  (SELECT COUNT(PK_SecurityUser) AS IsUser FROM dbo.SecurityUsers WITH (NOLOCK) WHERE UserID = @UserName AND UserPassword = @Password)
		  END
		ELSE
		  BEGIN
			SET @Error = 228
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			 SELECT 0 AS IsUser
			RETURN 

		  END

	-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 
	END CATCH
 
		/******************************************************************************
			end procedure
		******************************************************************************/
END
GO

