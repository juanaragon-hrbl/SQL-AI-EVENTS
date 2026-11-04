CREATE PROCEDURE [dbo].[usp_EventsAT_Del_PMPromotion]
	-- Required
	@PK_Event		int

	-- Defaults
	,@PMPromoType	int = 15
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS

BEGIN
/******************************************************************************

	OBJECT:			[dbo].[usp_EventsAT_Del_PMPromotion]

	USE:			
					DECLARE @e int, @em varchar(4000)

					EXEC [dbo].[usp_EventsAT_Del_PMPromotion]
							@PK_Event = 48313
							
							-- Errors
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	Delete a promotion
	NOTES:
	
	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event, dbo.EventLocaleDesc, dbo.EventImage, dbo.EventImageLocaleDesc, dbo.EventURL, dbo.EventDistributorCountryLocales, dbo.EventDSTeamType, dbo.EventExtn

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-05-22		RogelioR		Initial
	1.0.1		2019-08-15		NoeG			Refactor code (SRE)
	1.0.2		2020-10-01		puertac			BUG 382234 Promotions with Qualification should be deleted (Soft delete only, Event Active = 0, no other delete)
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';
	
	BEGIN TRY

		IF NOT EXISTS(SELECT 1 FROM [dbo].[Event] WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_EventType = @PMPromoType)
		BEGIN
			RAISERROR('The event does not exist or is not a promotion.', 11, 1);
			SELECT 0 AS PK_Event;
		END

		BEGIN TRANSACTION
		
			-- BUG 38223: Do not delete the information, just disable the PM promotion.  
			--DELETE FROM [SubEventLocaleDesc] WHERE PK_Event = @PK_Event;			
			--DELETE FROM [SubEvent] WHERE PK_Event = @PK_Event;
			--DELETE FROM [EventURL] WHERE PK_Event = @PK_Event;
			--DELETE FROM [EventImageLocaleDesc] WHERE PK_Event = @PK_Event;
			--DELETE FROM [EventImage] WHERE PK_Event = @PK_Event;
			--DELETE FROM [SubEvent] WHERE PK_Event = @PK_Event;
			--DELETE FROM [EventDistributorCountryLocales] WHERE PK_Event = @PK_Event;
			--DELETE FROM [EventDSTeamType] WHERE PK_Event = @PK_Event;
			--DELETE FROM [EventMedia]  WHERE PK_Event = @PK_Event;
			--DELETE FROM [EventLocaleDesc] WHERE PK_Event = @PK_Event;
			--DELETE FROM [EventExtn] WHERE PK_Event = @PK_Event;

			UPDATE [Event] SET IsActive = 0 WHERE PK_Event = @PK_Event
			
		COMMIT TRANSACTION


	-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

	END TRY
	
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

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

		SELECT @Error, @ErrorMessage;
	END CATCH;
END;