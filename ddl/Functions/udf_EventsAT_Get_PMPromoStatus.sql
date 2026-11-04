CREATE FUNCTION [dbo].[udf_EventsAT_Get_PMPromoStatus] (
	-- Required
	@PK_Event int 
		
	-- Optional
	,@LocaleCode varchar(5) = NULL		-- Checks all locales if not provided

	-- Defaults
	,@PMP_URLType int = 11				-- Preferred Member Promotion Type
	,@PMP_Link int = 1					-- File Attachments type
	,@VideoMedia int = 2				-- Video type (MediaType)
	,@PK_EventType int = 15				-- Preferred Member Promotion Type (EventType)
	,@PromoCodeLink	int = 13			-- Preferred Member Promo Code Type (EventURLType)
	,@ValidIfNULL int = 0				-- Marks a NULL value as valid
)
RETURNS TABLE
AS

/******************************************************************************

	OBJECT:			dbo.udf_EventsAT_Get_PMPromoStatus

	USE:			
					SELECT * FROM dbo.udf_EventsAT_Get_PMPromoStatus(48019, default, default, default, default, default, default, default)

	DESCRIPTION:	Returns 4 columns: 
						* [PK_Event] has the event id
						* [n] which has the number of sections checked
						* [DefaulLocate] if the locale is the Event.PK_DefaultLocale
						* [ValidSections] number of valid sections

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event, dbo.EventImage, dbo.EventDistributorCountryLocales, dbo.Locales, dbo.EventLocaleDesc, ebo.EventURL, dbo.EventMedia

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-05-17		RogelioR		Initial
	1.0.1		2020-10-02		puertac			BUG 384680 Promotion with qualification created some time a go after edit translations display INCOMPLETED, not allow publish promotion
												Validate QualificationDates instead of DisplayDates
******************************************************************************/
	
RETURN
	WITH cte_locales AS (	-- Locales (Audience) for the event
		SELECT
				edcl.[PK_Event]
				,edcl.[PK_Locale]
				,l.[LocaleCode]
				,e.[dStartUTC] AS [StartDate]
				,e.[dEndUTC] AS [EndDate]
				,e.[QualPeriodEnd]
				,e.[QualPeriodStart]
				,e.[CanDisplayQualPeriod] AS [PromotionRequiresQualification]
				,e.[Location] AS [EventTimeZone]
				,e.[DisplayStartDate] AS [DisplayStartDate]
				,e.[DisplayEndDate] AS [DisplayEndDate]
			FROM Event AS e WITH (NOLOCK)
				INNER JOIN EventDistributorCountryLocales AS edcl WITH (NOLOCK) ON edcl.[PK_Event] = e.[PK_Event]
				INNER JOIN Locales AS l WITH (NOLOCK) ON l.[PK_Locale] = edcl.[PK_Locale]
			WHERE e.[PK_Event] = @PK_Event
				AND e.[PK_EventType] = @PK_EventType
				AND (ISNULL(@LocaleCode, '') = '' OR l.[LocaleCode] = @LocaleCode)
	)
	,cte_img AS (	-- Events thumbnail and banner
		SELECT
				ei.[PK_Event]
				,eild.[PK_EventImageLocaleDesc]
				,ei.[PK_EventImageType]
				,eild.[PK_Locale]
				,l.[LocaleCode]
				,eild.[EventImageLocation]
			FROM EventImage AS ei WITH (NOLOCK)
				LEFT JOIN EventImageLocaleDesc AS eild WITH (NOLOCK) ON eild.[PK_EventImage] = ei.[PK_EventImage]
				INNER JOIN cte_locales AS l ON l.[PK_Locale] = eild.[PK_Locale]
					AND l.[PK_Event] = eild.[PK_Event]
	)
	,cte_eval_2 AS (	-- Evaluate section (2. Describe the Promotion)
		SELECT
				e.[PK_Event]
				,l.[PK_Locale]
				,l.[LocaleCode]
				,e.dStartUTC AS StartDate
				,e.dEndUTC AS EndDate
				,(CASE WHEN eld.EventName IS NOT NULL THEN 1 ELSE 0 END) AS EventNameEval
				,(CASE WHEN eld.EventDesc IS NOT NULL THEN 1 ELSE 0 END) AS EventDescEval
				,(CASE WHEN eld.EventRules IS NOT NULL THEN 1 ELSE 0 END) AS EventTermsEval
				,(CASE WHEN (SELECT EventImageLocation FROM cte_img WHERE PK_EventImageType = 1 AND PK_Locale = eld.[PK_Locale]) IS NOT NULL THEN 1 ELSE 0 END) AS ThumbnailEval
				,(CASE WHEN (SELECT EventImageLocation FROM cte_img WHERE PK_EventImageType = 2 AND PK_Locale = eld.[PK_Locale]) IS NOT NULL THEN 1 ELSE 0 END) AS BannerEval
				,(CASE WHEN eu.[EventURL] IS NOT NULL THEN 1 ELSE 0 END) AS LinkURL
				,(CASE WHEN eu.[EventURLDesc] IS NOT NULL THEN 1 ELSE 0 END) AS ButtonText
				,(CASE WHEN ec.[EventURL] IS NOT NULL THEN 1 ELSE 0 END) AS PromoCode
				,(CASE WHEN ec.[EventURLDesc] IS NOT NULL THEN 1 ELSE 0 END) AS PromoCodeHTML
			FROM cte_locales AS l
				INNER JOIN Event AS e WITH (NOLOCK) ON e.[PK_Event] = l.[PK_Event]
				LEFT JOIN EventLocaleDesc AS eld WITH (NOLOCK) ON eld.[PK_Event] = l.[PK_Event]
					AND eld.[PK_Locale] = l.[PK_Locale]
				LEFT JOIN EventURL AS eu WITH (NOLOCK) ON eu.[PK_Event] = l.[PK_Event]
					AND eu.[PK_Locale] = eld.[PK_Locale]
					AND eu.[PK_EventURLType] = @PMP_URLType
				LEFT JOIN EventURL AS ec WITH (NOLOCK) ON ec.PK_Event = l.PK_Event
					AND ec.PK_Locale = l.PK_Locale
					AND ec.PK_EventURLType = @PromoCodeLink
	)
	,cte_media AS (	-- Event Media
		SELECT 
				l.[PK_Locale]
				,em.[PK_MediaType]
				,l.[LocaleCode]
				,em.[MediaHTML]
			FROM cte_locales AS l
				LEFT JOIN EventMedia AS em WITH (NOLOCK) ON em.[PK_Event] = l.[PK_Event]
					AND em.[PK_Locale] = l.[PK_Locale]
	)
	,cte_url AS (	-- Event Flyers and links
		SELECT	
				l.[PK_Locale]
				,l.[LocaleCode]
				,eu.[EventURL]
				,eu.[EventURLDesc]
			FROM cte_locales AS l
				LEFT JOIN EventURL AS eu WITH (NOLOCK) ON eu.[PK_Event] = l.[PK_Event]
						AND eu.[PK_Locale] = l.[PK_Locale]
						AND eu.[PK_EventURLType] = @PMP_Link
	)
	,cte_eval_3 AS ( -- Evaluate section (3. Media)
		SELECT
				l.[PK_Locale]
				,l.[LocaleCode]
				,CASE WHEN (SELECT TOP 1 MediaHTML FROM cte_media WHERE PK_Locale = l.[PK_Locale] AND PK_MediaType = @VideoMedia) IS NOT NULL THEN 1 ELSE 0 END AS MediaHTML
				,CASE WHEN (SELECT TOP 1 EventURL FROM cte_url AS u WHERE u.PK_Locale = l.[PK_Locale]) IS NOT NULL THEN 1 ELSE 0 END AS FlyerLinkPath
				,CASE WHEN (SELECT TOP 1 EventURLDesc FROM cte_url AS u WHERE u.PK_Locale = l.[PK_Locale]) IS NOT NULL THEN 1 ELSE 0 END AS FlyerLinkTitle
			FROM cte_locales AS l
	)
	,cte_eval_4 AS ( -- Evaluate section (4. Qualifications)
		SELECT 
				[PK_Locale]
				,[LocaleCode]
				,CASE WHEN [PromotionRequiresQualification] = 1 THEN
					CASE WHEN QualPeriodStart IS NULL OR QualPeriodEnd IS NULL THEN 0		-- BUG 384680
					ELSE 1 END
				ELSE 1 END AS QualDates
			FROM cte_locales
	)
	,cte_format AS (	-- Format all section evaluations
		SELECT	-- (2. Describe the Promotion)
				2 AS [Section]
				,[PK_Locale]
				,[LocaleCode]
				,CASE WHEN (EventNameEval + EventDescEval + ThumbnailEval + BannerEval < 4) THEN 0
					WHEN (EventNameEval + EventDescEval + ThumbnailEval + BannerEval = 4) OR EventNameEval + EventDescEval + ThumbnailEval > 0 THEN 1
				END AS [IsValid]
			FROM cte_eval_2
		UNION ALL
		SELECT	-- (3. Media)
				3 AS [Section]
				,[PK_Locale]
				,[LocaleCode]
				,ISNULL(CASE WHEN (MediaHTML + FlyerLinkPath + FlyerLinkTitle) = 0 THEN NULL
					WHEN  (MediaHTML + FlyerLinkPath + FlyerLinkTitle) > 0 THEN 1
				END, 1) AS [IsValid]
			FROM cte_eval_3
		UNION ALL
		SELECT	-- (5. Dates)
				5 AS [Section]
				,[PK_Locale]
				,[LocaleCode]
				,CASE WHEN StartDate IS NULL AND EndDate IS NULL AND [EventTimeZone] IS NULL  THEN NULL 
					WHEN StartDate IS NOT NULL AND EndDate IS NOT NULL AND [EventTimeZone] IS NOT NULL THEN 1
					ELSE 0 END AS [IsValid]
			FROM cte_locales
		UNION ALL  
		SELECT -- (4. Qualification dates)  
				4 AS [Section]  
				,[PK_Locale]
				,[LocaleCode]
				,[QualDates] AS [IsValid]
			FROM cte_eval_4
	)
	,cte_valid AS ( -- Get the status of the sections by locale
		SELECT 
				s.Section
				,s.PK_Locale
				,s.LocaleCode
				,ISNULL(s.IsValid, @ValidIfNULL) AS IsValid
				,CASE WHEN ((SELECT COUNT(1) FROM EventImageLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = s.PK_Locale)
					+ (SELECT COUNT(1) FROM EventURL WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = s.PK_Locale) 
					+ (SELECT COUNT(1) FROM EventMedia WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = s.PK_Locale)) = 0 THEN 1 ELSE 0 END 
				AS [NotStarted]	-- All sections of the locale are empty (Default locale can be used) so its not invalid
				,CASE WHEN (SELECT PK_DefaultLocale FROM Event WITH (NOLOCK) WHERE PK_Event = @PK_Event) = s.PK_Locale THEN 1 ELSE 0 END AS DefaultLocale
			FROM cte_format AS s
	)
	,cte_agg AS (	-- Pivot the sections by locale
		SELECT
				c.PK_Locale
				,c.LocaleCode
				,c.DefaultLocale
				,MAX((CASE WHEN c.Section = 2 THEN CAST(IsValid AS INT) ELSE NULL END)) AS IsValidS2
				,MAX((CASE WHEN c.Section = 2 THEN NotStarted ELSE NULL END)) AS NotStartedS2
				,MAX((CASE WHEN c.Section = 3 THEN CAST(IsValid AS INT) ELSE NULL END)) AS IsValidS3
				,MAX((CASE WHEN c.Section = 3 THEN NotStarted ELSE NULL END)) AS NotStartedS3
				,MAX((CASE WHEN c.Section = 4 THEN CAST(IsValid AS INT) ELSE NULL END)) AS IsValidS4
				,MAX((CASE WHEN c.Section = 4 THEN NotStarted ELSE NULL END)) AS NotStartedS4
				,MAX((CASE WHEN c.Section = 5 THEN CAST(IsValid AS INT) ELSE NULL END)) AS IsValidS5
				,MAX((CASE WHEN c.Section = 5 THEN NotStarted ELSE NULL END)) AS NotStartedS5
			FROM cte_valid AS c
			GROUP BY c.PK_locale, c.LocaleCode, c.DefaultLocale
	)
	SELECT	@PK_Event AS PK_Event
			,COUNT(1) AS n
			,SUM(DefaultLocale) AS DefaultLocale
			,SUM(CASE WHEN (ISNULL(IsValidS2, 0) + ISNULL(IsValidS3, 0) + ISNULL(IsValidS4, 0) + ISNULL(IsValidS5, 0) = 4) THEN 1 ELSE 0 END) AS ValidSections
		FROM cte_agg		
		WHERE (NotStartedS2 + NotStartedS3 + NotStartedS5) != 3