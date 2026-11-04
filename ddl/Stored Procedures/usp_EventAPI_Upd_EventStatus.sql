
CREATE PROCEDURE [dbo].[usp_EventAPI_Upd_EventStatus]
	-- Required
	@PK_Event int
	,@IsPublish	bit
	,@EventApprovalStatus int = NULL

	-- Defaults
	,@PK_EventType		int = 15

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************

	OBJECT:			[dbo].[usp_EventAPI_Upd_EventStatus]

	USE:			
				DECLARE @e int, @em varchar(4000)

				EXEC [dbo].[usp_EventAPI_Upd_EventStatus]
						@PK_Event = 48012
						,@IsPublish = 0
						,@EventApprovalStatus = 1
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	Update the "IsPublish" and "EventApprovalStatus" columns for the Event

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-05-22		RogelioR		Initial
	1.0.1		2019-09-05		NoeG			SRE template applied
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	DECLARE @t table ([action] nvarchar(15), PK_Key int);

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

	DECLARE @s					nvarchar(255) = 'The event ' + CAST(@PK_Event AS VARCHAR(5)) + ' does not exists.'
			,@PK_EventExtn		int
			,@PK_Locale			int
			,@PK_DefaultLocale	int;
			
	SELECT @Error = 0, @ErrorMessage = '';
	
	BEGIN TRY
		IF NOT EXISTS(SELECT 1 FROM [Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)
		BEGIN
			RAISERROR(@s, 11, 1);
			SELECT 0 AS [PK_Event];
		END;

		-- Change Publish column
		UPDATE [Event] SET
				[IsPublish] = @IsPublish 
				,[EventApprovalStatus] = @EventApprovalStatus
			WHERE [PK_Event] = @PK_Event;
		
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

	-- Dep: 20180426
END;