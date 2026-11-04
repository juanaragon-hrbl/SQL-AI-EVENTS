CREATE PROCEDURE [dbo].[usp_EventsAT_Get_PMSectionCompleteStatus]  
	-- Required  
	@PK_Event int  
    
	-- Optional  
	,@LocaleCode varchar(5) = NULL  
	,@PMP_URLType int = 11  
	,@PMP_Link int = 1  
	,@VideoMedia int = 2  
	,@PK_EventType int = 15  
	,@PromoCodeLink int = 13  
  
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT 

	-- QA/DEV
	,@IsDevQA bit = 0
  
AS  
BEGIN  
/******************************************************************************  
  
 OBJECT:   dbo.usp_EventsAT_Get_PMSectionCompleteStatus  
  
 USE:     
     DECLARE @e int, @em varchar(max)
  
     EXEC dbo.usp_EventsAT_Get_PMSectionCompleteStatus  
       @PK_Event = 48062  
       --,@LocaleCode = 'es-MX'  
  
       -- Errors  
       ,@Error = @e OUTPUT  /* @E must be defined in the local call */  
       ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */  
       ,@IsDevQA = 1
	   
	   SELECT @e AS [Error], @em AS [Error Message]
       
 DESCRIPTION: Returns 3 columns:   
      * [Section] which has the section number on the page  
      * [IsValid]  
        1: Every required field or at least one optional is complete  
        0: Any required field is incomplete  
        NULL: Any required or optional fields are complete  
  
 NOTES:  
  
 DEPENDENCIES  
 --------------------------------------------------------------------  
 dbo.Event, dbo.EventImage, dbo.EventDistributorCountryLocales, dbo.Locales, dbo.EventLocaleDesc, ebo.EventURL, dbo.EventMedia  
  
 VERSIONS  
 --------------------------------------------------------------------  
 1.0.0  2017-05-04  RogelioR		Initial 
 1.1.0	2019-05-21	alejandramed	Homologating of standard error handling 
 1.2.0	2019-07-15	alejandramed	Setting error parameters as optionals
 1.2.1	2020-10-01	puertac			BUG 384680 Promotion with qualification created some time a go after edit translations display INCOMPLETED, not allow publish promotion
									Validate QualificationDates instead of DisplayDates
******************************************************************************/  
   
 SET ANSI_NULLS ON  
 SET QUOTED_IDENTIFIER ON  
 SET NOCOUNT ON  
  
--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';
  
 BEGIN TRY;  
	WITH cte_locales AS ( -- Locales (Audience) for the event  
		SELECT  
				edcl.[PK_Event]  
				,edcl.[PK_Locale]  
				,l.[LocaleCode]  
				,e.[dStartUTC] AS [StartDate]
				,e.[dEndUTC] AS [EndDate]
				,e.[QualPeriodEnd]
				,e.[QualPeriodStart]
				,e.[DisplayStartDate]
				,e.[DisplayEndDate]
				,e.[CanDisplayQualPeriod] AS [PromotionRequiresQualification]
				,e.[Location] AS [EventTimeZone]
			FROM Event AS e WITH (NOLOCK) 
				INNER JOIN [dbo].[EventDistributorCountryLocales] AS edcl WITH (NOLOCK) ON edcl.[PK_Event] = e.[PK_Event]  
				INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = edcl.[PK_Locale]  
			WHERE e.[PK_Event] = @PK_Event  
				AND e.[PK_EventType] = @PK_EventType  
				AND (l.[LocaleCode] = @LocaleCode OR ISNULL(@LocaleCode, '') = '')  
	)  
	,cte_img AS ( -- Events thumbnail and banner  
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
	,cte_eval_2 AS ( -- Evaluate section (2. Describe the Promotion)  
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
	,cte_media AS ( -- Event Media  
		SELECT   
				l.[PK_Locale]  
				,em.[PK_MediaType]  
				,l.[LocaleCode]  
				,em.[MediaHTML]  
			FROM cte_locales AS l
				LEFT JOIN EventMedia AS em WITH (NOLOCK) ON em.[PK_Event] = l.[PK_Event]  
					AND em.[PK_Locale] = l.[PK_Locale]  
	)  
	,cte_url AS ( -- Event Flyers and links  
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
					CASE WHEN QualPeriodStart IS NULL OR QualPeriodEnd IS NULL THEN 0  -- BUG 384680
					ELSE 1 END
				ELSE 1 END AS QualDates
			FROM cte_locales
	)
	SELECT -- (2. Describe the Promotion)
			2 AS [Section]
			,[PK_Locale]
			,[LocaleCode]
			,CASE 	WHEN (EventNameEval + EventDescEval + ThumbnailEval + BannerEval < 4) THEN 0
					WHEN (EventNameEval + EventDescEval + ThumbnailEval + BannerEval = 4) OR EventNameEval + EventDescEval + ThumbnailEval > 0 THEN 1
			END AS [IsValid]
		FROM cte_eval_2
	UNION ALL  
	SELECT -- (3. Media)  
			3 AS [Section]  
			,[PK_Locale]  
			,[LocaleCode]  
			,CASE WHEN (MediaHTML + FlyerLinkPath + FlyerLinkTitle) = 0 THEN NULL  
				WHEN  (MediaHTML + FlyerLinkPath + FlyerLinkTitle) > 0 THEN 1  
			END AS [IsValid]  
		FROM cte_eval_3  
	UNION ALL  
	SELECT -- (5. Dates)  
			5 AS [Section]  
			,[PK_Locale]  
			,[LocaleCode]  
			,CASE WHEN StartDate IS NOT NULL AND EndDate IS NOT NULL AND [EventTimeZone] IS NOT NULL THEN 1  
				ELSE 0 END AS [IsValid]  
		FROM cte_locales
	UNION ALL  
	SELECT -- (4. Qualification dates)  
			4 AS [Section]  
			,[PK_Locale]
			,[LocaleCode]
			,[QualDates] AS [IsValid]
		FROM cte_eval_4;
	END TRY  
	BEGIN CATCH  
		SELECT   
				@Error = ERROR_NUMBER()  
				,@ErrorMessage = ERROR_MESSAGE()  
				,@StoredProcedure = ERROR_PROCEDURE();  
  
  		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG  
		EXEC dbo.usp_Utility_UpdateErrorLog  
				@ProcedureName = @StoredProcedure  
				,@ErrorNumber = 3  
				,@ErrorMessage = @ErrorMessage OUTPUT  
				,@SQLErrorCode = @Error  
				,@SQLErrorMsg = @ErrorMessage;  
	END CATCH;  
END;