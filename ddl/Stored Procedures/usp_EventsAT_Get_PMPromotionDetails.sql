CREATE PROCEDURE [dbo].[usp_EventsAT_Get_PMPromotionDetails]
	-- Required
	@PK_Event			int

	-- Optional
	,@LocaleCode		varchar(5) = NULL
	,@DistributorId		varchar(255) = null
	,@DVStartDate		datetime2 = null
	,@DVEndDate			datetime2 = null
	,@TeamLevel			varchar(255) = null

	-- Defaults
	,@PK_EventType		int = 15
	,@PK_EventImageType int = 2		-- Banner
	,@PrefMemberPromo	int = 11	-- Preferred member promotion
	,@DisplayEventPDF	int = 12	-- Display Event PDF
	,@PromoCode			int = 13

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			dbo.usp_EventsAT_Get_PMPromotionDetails

	USE:
					DECLARE @e int, @em varchar(4000)

					EXEC dbo.usp_EventsAT_Get_PMPromotionDetails
							@PK_Event = 77875
							,@LocaleCode = 'es-CO'
							,@DistributorId = 'W1X1330722'
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

					SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	Gets promotion data

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event, dbo.EventLocaleDesc, dbo.EventExtn, dbo.EventDSTeamType, dbo.EventDistributorCountryLocales

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-08		RogelioR		Initial
	1.1.0		2017-10-18		RogelioR		Added [IsPublish] and [IsValidAudience] columns
	2.0.0       2018-11-07		SushmaA			Custom Tracking Site SP Name/Downline list SP Name to be displayed for redirection
	2.0.1		2018-11-23		RogelioR		Change source for last dataset (PV) to fix tracker
	2.0.0		2019-08-08		NoeG			Refactor code (SRE)
	2.0.1		2020-10-01		puertac			BUG 382040 PPV points are not display if publish stat/end dates are empty (replace DisplayDates for QualificationDates per BUG 348551)
	3.0.0		2021-04-19		rosarioo		BUG 629058 PPVs are World Wide (pubEvents.[dbo].[factDSFinancial]), so countries should be considered for PC/PM promos ([PubData].[dbo].[factDSFinancial_ctry])
	3.0.1		2021-04-21		ivanci			BUG 630515 - Preferred Member Promotion - PM Promo Page available previus the display date 
	3.0.2		2022-06-20		puertac			US 1050464: Remove Errorlog when PK_event has been deleted
	3.0.3		2023-12-01		ivanci			Return TestEnabled Flag
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@IsValidLocale int
			,@PK_Locale int = (SELECT PK_Locale FROM Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode)
			,@PK_DefaultLocale int = (SELECT [PK_DefaultLocale] FROM [dbo].[Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)
			,@ShowEvent bit = 1
            ,@Today	datetime2 = GETUTCDATE(); -- BUG 630515

	 SELECT @ShowEvent = 1
	 --CASE WHEN @ChkUploadedMember = 1 THEN
		--								CASE WHEN ISNULL((SELECT DISTINCT 1 FROM [UploadedMember] WITH (NOLOCK) WHERE [DistributorId] = @DistributorId AND [PK_Event] = @PK_Event), 0) = 1 THEN 1
		--								ELSE 0 END
		--							ELSE 1 END;

	-- Preferred/Charter Member patch
	SELECT @TeamLevel = REPLACE(@TeamLevel,'BPM', 'BCM');
	SELECT @TeamLevel = REPLACE(@TeamLevel,'SPM', 'SCM');
	SELECT @TeamLevel = REPLACE(@TeamLevel,'GPM', 'GCM');
	SELECT @TeamLevel = REPLACE(@TeamLevel,'CQS', 'PCM');

	SELECT @TeamLevel = REPLACE(@TeamLevel,'PB15', 'BCM');
	SELECT @TeamLevel = REPLACE(@TeamLevel,'PS25', 'SCM');
	SELECT @TeamLevel = REPLACE(@TeamLevel,'PG35', 'GCM');

	SELECT @Error = 0, @ErrorMessage = ''
			,@IsValidLocale = CASE WHEN EXISTS (SELECT [PK_Locale] FROM [dbo].[EventDistributorCountryLocales] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event AND [PK_Locale] = @PK_Locale) THEN 1 ELSE 0 END
			,@PK_Locale = ISNULL((SELECT @PK_Locale FROM [dbo].[EventLocaleDesc] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event AND [PK_Locale] = @PK_Locale), @PK_DefaultLocale);

	IF @isDevQA = 1 SELECT @PK_Locale AS [Locale], @PK_DefaultLocale AS [DefaultLocale];

	BEGIN TRY
		
		-----------------------------------------------------------------------------------------------------------------------
		-- Event Details
		WITH cte_img AS (
			SELECT
					ei.[PK_Event]
					,ei.[PK_EventImage]
					,eild.[PK_EventImageLocaleDesc]
					,ei.[PK_EventImageType]
					,eit.[EventImageType]
					,eild.[PK_Locale]
					,l.[LocaleCode]
					,eild.[EventImageLocation]
				FROM [dbo].[EventImage] AS ei WITH (NOLOCK)
					LEFT JOIN [dbo].[EventImageLocaleDesc] AS eild WITH (NOLOCK) ON eild.[PK_EventImage] = ei.[PK_EventImage]
					INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = @PK_Locale
					INNER JOIN [dbo].[EventImageType] AS eit WITH (NOLOCK) ON eit.[PK_EventImageType] = ei.[PK_EventImageType]
				WHERE ei.[PK_EventImageType] = @PK_EventImageType
					AND l.PK_Locale = @PK_Locale
		)
		SELECT DISTINCT
				e.[PK_Event]
				,e.[dStartUTC]
				,e.[dEndUTC]
				,eld.[PK_Locale]
				,l.[LocaleCode]
				,eld.[EventName]
				,eld.[EventDesc]
				,eld.[EventRules]
				,c.[EventImageLocation] AS [Banner]
				,eu.[EventURL] AS [LinkURL]
				,eu.[EventURLDesc] AS [ButtonText]
				,eup.[EventURL] AS [PromoCode]
				,eup.[EventURLDesc] AS [ClaimPrize]
				,e.[Location]
				,e.[EventTimeZone]
				,eld.[IsCTAEnabledOnUpcoming]
				,CASE WHEN @TeamLevel IN (SELECT DSTeamTypeCode FROM EventDSTeamType WITH (NOLOCK) WHERE PK_Event = @PK_Event) THEN 1 ELSE 0 END AS [HasAccess]
				,IIF((e.[IsPublish] = 1 AND ((e.DisplayStartDate IS NULL OR e.DisplayStartDate <= @Today )					-- BUG 630515
									  AND (e.DisplayEndDate IS NULL OR e.DisplayEndDate >= @Today )									 
									)),1 ,0) AS [IsPublish]
				,@IsValidLocale AS [IsValidAudience]
				,ISNULL(IsCustomTrackingSiteAvailable,0) IsCustomTrackingSiteAvailable
				,[CustomTrackingSiteSPName]
				,ISNULL(ept.[PK_EventPromoTemplateType], 0) AS [EventPromoTemplateType]
				,ISNULL(ext.EnableTesting, 0) AS [EnableTesting]
			FROM [dbo].[Event] AS e WITH (NOLOCK)
				INNER JOIN [dbo].[EventLocaleDesc] AS eld WITH (NOLOCK) ON eld.[PK_Event] = e.[PK_Event]
				INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = eld.[PK_Locale]
				LEFT JOIN [dbo].[EventExtn] AS ext WITH (NOLOCK) ON ext.[PK_Event] = e.[PK_Event]
				LEFT JOIN cte_img AS c WITH (NOLOCK) ON c.[PK_Event] = eld.[PK_Event]
					AND c.[PK_Locale] = eld.[PK_Locale]
				LEFT JOIN [dbo].[EventURL] AS eu WITH (NOLOCK) ON eu.[PK_Event] = eld.[PK_Event]
					AND eu.PK_EventURLType = @PrefMemberPromo
					AND eu.[PK_Locale] = eld.[PK_Locale]
				LEFT JOIN [dbo].[EventURL] AS eup WITH (NOLOCK) ON eup.[PK_Event] = eld.[PK_Event]
					AND eup.PK_EventURLType = @PromoCode
					AND eup.[PK_Locale] = eld.[PK_Locale]
				LEFT JOIN [dbo].[EventPromoTemplate] AS ept WITH (NOLOCK) ON ept.[PK_Event] = eld.[PK_Event]
			WHERE e.[PK_EventType] = @PK_EventType
				AND e.[PK_Event] = @PK_Event
				AND l.[PK_Locale] = @PK_Locale
				AND @ShowEvent = 1;

		-----------------------------------------------------------------------------------------------------------------------
		-- Attachments
		IF @IsDevQA = 1 SELECT @PK_Locale AS [PK_Locale], @PrefMemberPromo AS [DisplayEventPDF], @DisplayEventPDF AS [DisplayEventPDF], @PromoCode AS [PromoCode]

		SELECT
				eu.[PK_EventURL]
				,eu.[PK_Event]
				,eu.[PK_Locale]
				,l.[LocaleCode]
				,eu.[EventURL] AS [Attachment]
				,eu.[EventURLDesc] AS [AttachmentDesc]
				,eu.[PK_EventURLType]
				,eut.[EventURLType]
			FROM [dbo].[EventURL] AS eu WITH (NOLOCK)
				INNER JOIN [dbo].[EventURLType] AS eut WITH (NOLOCK) ON eut.[PK_EventURLType] = eu.[PK_EventURLType]
				INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = eu.[PK_Locale]
			WHERE eu.[PK_Event] = @PK_Event
				AND eu.[PK_EventURLType] NOT IN (@PrefMemberPromo, @DisplayEventPDF, @PromoCode)
				AND eu.[PK_Locale] = @PK_Locale
				AND @ShowEvent = 1;

		-----------------------------------------------------------------------------------------------------------------------
		-- Media
		SELECT
				em.[PK_EventMedia]
				,em.[PK_Event]
				,em.[PK_Locale]
				,l.[LocaleCode]
				,em.[MediaName]
				,em.[MediaDesc]
				,em.[MediaHTML]
			FROM [dbo].[EventMedia] AS em WITH (NOLOCK)
				INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = em.[PK_Locale]
			WHERE em.[PK_Event] = @PK_Event
				AND l.PK_Locale = @PK_Locale
				AND @ShowEvent = 1;

		-----------------------------------------------------------------------------------------------------------------------
		-- Qualifications (SubEvent)
		SELECT
			se.[PK_SubEvent]
			,se.[SubEventName] AS [QualificationName]
			,se.[PK_Event]
			,l.[PK_Locale]
			,l.[LocaleCode]
			,CASE WHEN ISNULL(seld.[SubEventName], '') = '' THEN se.[SubEventName] ELSE seld.[SubEventName] END  AS [SubEventName]
			,seld.[SubEventQualDesc]
			,seld.[Image]
			,q.[Qualified]
			,se.[IsTrackingVisible]
		FROM [dbo].[SubEvent] AS se  WITH (NOLOCK)
			INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = @PK_Locale
			LEFT JOIN [dbo].[SubEventLocaleDesc] AS seld WITH (NOLOCK) ON seld.[PK_Subevent] = se.[PK_SubEvent]
				AND (seld.[PK_Locale] = @PK_Locale)
			LEFT JOIN dbo.[SubEventQualifier] AS q WITH (NOLOCK) ON q.[DistributorId] = @DistributorId
				AND q.[PK_Event] = @PK_Event
				AND q.[PK_SubEvent] = se.PK_SubEvent
				AND q.[RemovedUTC] = '2049-12-31 00:00:00'
		WHERE se.[PK_Event] = @PK_Event
			AND @ShowEvent = 1;

		-----------------------------------------------------------------------------------------------------------------------
		-- Qualification data
		SELECT
				e.[PK_Event]
				,e.[IsQualifytoPurchaseTickets] AS [PromotionRequiresQualification]
				,e.[QualPeriodStart]
				,e.[QualPeriodEnd]
				,e.[CanDisplayQualPeriod] AS [DisplayQualificationDates]
				,e.[IsPublishQualTracking] AS [PublishQualTracker]
				,e.[CanAssignTickets] AS [SameDescriptionAllLeves]
				,e.[DisplayStartDate]
				,e.[DisplayEndDate]
				,ISNULL(ee.[IsDisplayTVP], 0) AS [IsDisplayTVP]
				,ISNULL(ee.[IsDisplayDV], 0) AS [IsDisplayDV]
				,ISNULL(ee.[IsDisplayPPV], 0) AS [IsDisplayPPV]
				,ISNULL(ee.[IsDisplayDLV], 0) AS [IsDisplayDLV]
				,ee.[PromotionCode]
				,ee.[DisplayQualStatus]
			FROM [dbo].[Event] AS e WITH (NOLOCK)
				LEFT JOIN [dbo].[EventExtn] AS ee WITH (NOLOCK) ON ee.[PK_Event] = e.[PK_Event]
			WHERE e.[PK_Event] = @PK_Event
				AND @ShowEvent = 1;


		-----------------------------------------------------------------------------------------------------------------------
		-- DV
		IF @DistributorId IS NOT NULL
		BEGIN
			SELECT
					 @DVStartDate = ISNULL(@DVStartDate, QualPeriodStart) -- BUG 382040 
					,@DVEndDate = ISNULL(@DVEndDate, QualPeriodEnd)		 -- BUG 382040 
				FROM [dbo].[Event] WITH (NOLOCK)
				WHERE [PK_Event] = @PK_Event;

			IF @IsDevQA = 1
				SELECT	@DVStartDate
						,@DVEndDate
						,CAST(SUBSTRING(CONVERT(VARCHAR(10), @DVStartDate, 112), 1, 6) AS int) AS [StartInt]
						,CAST(SUBSTRING(CONVERT(VARCHAR(10), @DVEndDate, 112), 1, 6) AS int) AS [EndInt];

            DECLARE @countries VARCHAR(100) = (SELECT [Value] FROM Promo.Options WHERE PK_Event = @PK_Event AND [Key] = 'Qualifications.RestrictedCountries' AND IsActive = 1) /*BUG 629058*/
           
            IF @countries IS NOT NULL /*BUG 629058*/
            BEGIN
                DECLARE @countriesRestrict as Table (code varchar(5))	
                INSERT INTO @countriesRestrict 
					SELECT	Val
					FROM	dbo.udf_SplitString(@countries,',') SP


                SELECT [PK_Distributor], [RoyaltyMonth], [PPV]
				FROM [PubData].[dbo].[factDSFinancial_ctry] ff WITH (NOLOCK)
                INNER JOIN @countriesRestrict cr ON
                ff.CountryCode = cr.code
				WHERE [DistributorId] = @DistributorId
					AND CONVERT(INT,SUBSTRING(CONVERT(VARCHAR(10),[RoyaltyMonth],112),1,6)) BETWEEN CAST(SUBSTRING(CONVERT(VARCHAR(10), @DVStartDate, 112), 1, 6) AS int)
										AND CAST(SUBSTRING(CONVERT(VARCHAR(10), @DVEndDate, 112), 1, 6) AS int)
                    
            END
            ELSE
            BEGIN
			SELECT [PK_Distributor], CAST(CAST([RoyaltyMonth] as nvarchar(10)) + '01' AS datetime2) AS [RoyaltyMonth], [PPV]
				FROM pubEvents.[dbo].[factDSFinancial] WITH (NOLOCK)
				WHERE [DistributorId] = @DistributorId
					AND [RoyaltyMonth] BETWEEN CAST(SUBSTRING(CONVERT(VARCHAR(10), @DVStartDate, 112), 1, 6) AS int)
										AND CAST(SUBSTRING(CONVERT(VARCHAR(10), @DVEndDate, 112), 1, 6) AS int)
					--AND @IsPM = 1;
            END
		END;

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