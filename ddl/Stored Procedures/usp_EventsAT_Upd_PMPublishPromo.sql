
CREATE PROCEDURE [dbo].[usp_EventsAT_Upd_PMPublishPromo]
	-- Required
	@PK_Event			int
	,@IsPublish			bit
	,@IsEnabledTesting  bit = 0

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Upd_PMPublishPromo

	USE:			
				DECLARE @e int, @em varchar(4000);

				EXEC dbo.usp_EventsAT_Upd_PMPublishPromo
						@PK_Event = 48012
						,@IsPublish = 0
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1
				
				SELECT @e, @em;

	DESCRIPTION:	Update the "IsPublish" column for the Event

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-05-22		RogelioR		Initial
	2.0.0		2019-08-08		NoeG			Refactor code (SRE)
	2.0.1		2019-10-17		alejandramed	SRE Compliance 
	2.0.2		2023-11-30		ivanci			Add testing enabled flag
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	DECLARE @s	nvarchar(255) = 'The event ' + CAST(@PK_Event AS VARCHAR(5)) + ' does not exists.';
			
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY
		IF NOT EXISTS(SELECT 1 FROM Event WITH (NOLOCK) WHERE PK_Event = @PK_Event)
		BEGIN
			RAISERROR(@s, 11, 1);
			SELECT 0 AS PK_Event;
		END;

		-- Change Publish column
		UPDATE [Event] SET IsPublish = @IsPublish WHERE PK_Event = @PK_Event;
		UPDATE [EventExtn] SET EnableTesting = @IsEnabledTesting WHERE PK_Event = @PK_Event;

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
	END CATCH
END;
GO

