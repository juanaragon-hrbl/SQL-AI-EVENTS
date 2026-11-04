
CREATE PROCEDURE [dbo].[usp_EventsAT_Upd_PMPromoCleanUp]
	-- Optional
	@UnpublishPromos	bit = 1
	,@DeletePromos		bit = 1

	-- Defaults
	,@PMPromoType		int = 15
	,@MonthsToUnpublish	int = 2
	,@MonthsToDelete	int = 24
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS

BEGIN
/******************************************************************************

	OBJECT:			[dbo].[usp_EventsAT_Upd_PMPromoCleanUp]

	USE:			
					DECLARE @e int, @em varchar(max);

					EXEC [dbo].[usp_EventsAT_Upd_PMPromoCleanUp]
							@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					
					SELECT @e, @em
					
	DESCRIPTION:	Delete expired promotions
	NOTES:			* Change publish status (IsPublish) set to 0 after 2 months of dEndUTC
					* Delete event after 2 years dEndUTC

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event, dbo.EventLocaleDesc, dbo.EventImage, dbo.EventImageLocaleDesc, dbo.EventURL, dbo.EventDistributorCountryLocales, dbo.EventDSTeamType, dbo.EventExtn

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-05-22		RogelioR		Initial
	1.0.1		2019-10-17		alejandramed	SRE Compliance 
	
******************************************************************************/
SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

	SELECT	@Error = 0, @ErrorMessage = '';	

	BEGIN TRY

		DECLARE @UnpublishDate		datetime2
				,@DeleteDate		datetime2;

		SELECT	@UnpublishDate = DATEADD(MONTH, -@MonthsToUnpublish, GETUTCDATE())
				,@DeleteDate = DATEADD(MONTH, -@MonthsToDelete, GETUTCDATE());

		IF @UnpublishPromos = 1
		BEGIN
			UPDATE [dbo].[Event] SET
					IsPublish = 0
				WHERE PK_EventType = @PMPromoType
					AND dEndUTC <= @UnpublishDate;
		END;

		IF @MonthsToDelete = 1
		BEGIN
			IF OBJECT_ID('tempdb.dbo.#e') IS NOT NULL
				DROP TABLE #e;

			SELECT PK_Event INTO #e
				FROM [dbo].[Event] WITH (NOLOCK)
				WHERE PK_EventType = @PMPromoType
					AND dEndUTC <= @UnpublishDate;

			BEGIN TRANSACTION
				DELETE FROM [EventURL] WHERE PK_Event IN (SELECT PK_Event FROM #e);

				DELETE FROM [EventImageLocaleDesc] WHERE PK_Event IN (SELECT PK_Event FROM #e);

				DELETE FROM [EventImage] WHERE PK_Event IN (SELECT PK_Event FROM #e);

				DELETE FROM [SubEvent] WHERE PK_Event IN (SELECT PK_Event FROM #e);

				DELETE FROM [EventDistributorCountryLocales] WHERE PK_Event IN (SELECT PK_Event FROM #e);

				DELETE FROM [EventDSTeamType] WHERE PK_Event IN (SELECT PK_Event FROM #e);

				DELETE FROM [EventMedia]  WHERE PK_Event IN (SELECT PK_Event FROM #e);

				DELETE FROM [EventLocaleDesc] WHERE PK_Event IN (SELECT PK_Event FROM #e);

				DELETE FROM [EventExtn] WHERE PK_Event IN (SELECT PK_Event FROM #e);

				DELETE FROM [EventQualification] WHERE PK_Event IN (SELECT PK_Event FROM #e);
				
				UPDATE [Event] SET IsActive = 0 WHERE PK_Event IN (SELECT PK_Event FROM #e);
			COMMIT TRANSACTION

			-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;
		END;
	END TRY	
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

		SELECT 
				@Error = ERROR_NUMBER()
				,@ErrorMessage = ERROR_MESSAGE()
				,@StoredProcedure = ERROR_PROCEDURE();

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage;

		SELECT @Error, @ErrorMessage;
	END CATCH;
END;