CREATE PROCEDURE [dbo].[usp_EventAPI_Get_EventsUserRoles]
    -- REQUIRED
   @UserName varchar(20)
    -- OPTIONAL
  ,@EventID int = NULL
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_EventsUserRoles

USE:
			DECLARE @e int, @em varchar(4000)

			EXEC usp_EventAPI_Get_EventsUserRoles @UserName = 'SandhyaP'
                               ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						       ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
								,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Get the UserRole for the Events

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1	2009-01-22 Sandhya	Initial
2	2014-03-13 IniU		Added code to return the associated FRID dll filename and namespace for RFID enabled events. 
						The premise is that the RFID association is setup in dbo.EventRFIDConfig table.
3	2019-09-05 NoeG		SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON


/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @PK_SecurityUser int

SELECT @Error = 0, @ErrorMessage = '';

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/

IF EXISTS (SELECT PK_SecurityUser FROM dbo.SecurityUsers WITH (NOLOCK) WHERE UserID = @UserName)
  BEGIN
          (SELECT @PK_SecurityUser = PK_SecurityUser FROM dbo.SecurityUsers WITH (NOLOCK) WHERE UserID = @UserName)
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
		,E.VendorEventID
		,E.IsRFIDRequired
		,E.IsInventoryEnabled
        ,E.CanAssignTickets
        ,ERC.RFID_dllFileName
        ,ERC.RFID_dllNamespace
	FROM 
		dbo.EventSecurityRoles ES WITH (NOLOCK) 
        INNER JOIN
        dbo.SecurityUsers U WITH (NOLOCK) 
        ON
          U.PK_SecurityUser = ES.PK_SecurityUser
        INNER JOIN
        dbo.SecurityRoles R WITH (NOLOCK) 
        ON
          R.PK_SecurityRole = ES.PK_SecurityRole
        INNER JOIN
        dbo.Event E WITH (NOLOCK)
        ON
          E.PK_Event = COALESCE(@EventID, ES.PK_Event)
        LEFT JOIN
			dbo.EventRFIDConfig ERC WITH (NOLOCK) 
		ON
			ES.PK_Event = ERC.PK_Event
	WHERE 
		  U.PK_SecurityUser = @PK_SecurityUser


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
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;