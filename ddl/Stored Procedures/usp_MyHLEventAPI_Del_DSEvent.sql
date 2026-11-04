CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Del_DSEvent]
	-- Required
	@PK_Event		varchar(max)

	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************

	OBJECT:			[dbo].[usp_MyHLEventAPI_Del_DSEvent]

	USE:			
					DECLARE @e int, @em varchar(4000)

					EXEC [dbo].[usp_MyHLEventAPI_Del_DSEvent]
							@PK_Event = '189153'
							
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

	VERSIONS (d)
	--------------------------------------------------------------------
	1.0.0		2017-10-20		RogelioR		Initial
	1.1.0		2019-08-14		NoeG			Refactor code (SRE)
	1.2.0		2019-10-16      puertac			SRE Implementation 
	1.2.1		2021-11-08      ivanci			BUG 835253 - Manage My Event display after remove DS from coordinator  
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';
		
	BEGIN TRY
		IF OBJECT_ID('tempdb..#Events') IS NOT NULL
			DROP TABLE #Events;
	
		SELECT	
				f.[PK_Event]
				,CASE WHEN EXISTS (SELECT [PK_Event] FROM [Event] WITH(NOLOCK) WHERE [PK_Event] = f.[PK_Event]) THEN 1 ELSE 0 END AS [Exists]
			INTO #Events
			FROM (SELECT CAST([String] AS int) AS [PK_Event] FROM [udf_SplitVarchar](@PK_Event, ',')) AS f
				
		IF @IsDevQA = 1 SELECT PK_Event,[Exists] FROM #Events;
		
		IF EXISTS(SELECT 1 FROM #Events WHERE [Exists] = 0)
		BEGIN
			DECLARE @Invalids varchar(max) = '';

			SELECT @Invalids = @Invalids + ISNULL(CAST([PK_Event] AS varchar(max)) + ',', '') FROM #Events;
			SELECT @Invalids = 'The event(s) ' + @Invalids + ' are not valid.';

			RAISERROR(@Invalids, 11, 1);

			SELECT 0 AS PK_Event;
		END
		
		BEGIN TRANSACTION
			-- Delete EventSKU
			DELETE FROM [EventSKULocaleDesc] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			DELETE FROM [EventSKU] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			-- Delete Agenda
			DELETE FROM [AgendaItem] WHERE [PK_Agenda] IN (SELECT [PK_Agenda] FROM [Agenda] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events));
			
			DELETE FROM [Agenda] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events)

			-- Delete GuestSpeakers
			DELETE FROM EventGuestSpeakerLocale WHERE PK_Event IN (SELECT [PK_Event] FROM #Events);

			DELETE FROM EventGuestSpeakers WHERE PK_Event IN (SELECT [PK_Event] FROM #Events);

			-- Delete images
			DELETE FROM [EventImageLocaleDesc] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			DELETE FROM [EventImage] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			-- Delete Subevent info
			DELETE FROM [SubEventQualification] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			DELETE FROM [SubEventLocaleDesc] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			DELETE FROM [SubEvent] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			-- Delete links
			DELETE FROM [EventURL] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			-- Delete audiences
			DELETE FROM [EventDistributorCountryLocales] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			-- Delete authorized levels
			DELETE FROM [EventDSTeamType] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			-- Delete Media
			DELETE FROM [EventMedia]  WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			-- Event locales and extended info
			DELETE FROM [EventLocaleDesc] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			DELETE FROM [EventExtn] WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

            -- Delete Coordinator																	-- 1.2.1
			DELETE FROM [EventCoordinatorDetail]  WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);

			-- Delete Event: soft delete
			UPDATE [Event] SET IsActive = 0 WHERE [PK_Event] IN (SELECT [PK_Event] FROM #Events);
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
		 
	END CATCH;
--Deployed 20180423
END;
