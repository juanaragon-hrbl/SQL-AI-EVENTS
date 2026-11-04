CREATE PROCEDURE [dbo].[usp_EventAPI_Validate_EventSecurityBadge]
	-- REQUIRED
	 @BadgeUID varchar(20)
	-- OPTIONAL
	,@PK_EventsRegistration int = NULL

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************

OBJECT:			dbo.usp_EventAPI_Validate_EventSecurityBadge
USE:	
		DECLARE @e int, @em varchar(4000)

		EXEC usp_EventAPI_Validate_EventSecurityBadge
					 @BadgeUID = '8393593983589'
				    ,@PK_EventsRegistration = 23452
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Validates badge before any attempt to burn it

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.EventSecurityBadge

VERSIONS
--------------------------------------------------------------------
1	2008-10-16	IniU	Initial
2	2019-09-05	NoeG	SRE template applied
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

	BEGIN TRY

		/******************************************************************************
		At the minimum, badge ID must be entered for search
		******************************************************************************/
		IF @BadgeUID IS NULL
		BEGIN
			SET @Error = 27
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			RETURN 
		END


		/******************************************************************************
		verify badge is not blacklisted
		******************************************************************************/
		IF EXISTS(SELECT 1 FROM dbo.EventSecurityBadge WITH (NOLOCK) WHERE BadgeUID = @BadgeUID and PK_BadgeStatus = 3)
		BEGIN
			SET @Error = 253
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
			RETURN 
		END

		/******************************************************************************
		verify badge belongs to registrant/attendee
		******************************************************************************/
		IF EXISTS(SELECT 1 FROM dbo.EventSecurityBadge WITH (NOLOCK) WHERE BadgeUID = @BadgeUID and PK_EventsRegistration <> @PK_EventsRegistration)
		BEGIN
			SET @Error = 254
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure 
				,@ErrorNumber = @Error
				,@ErrorMessage = @ErrorMessage OUTPUT
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
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;

