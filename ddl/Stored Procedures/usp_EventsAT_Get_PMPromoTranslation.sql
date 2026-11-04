CREATE PROCEDURE [dbo].[usp_EventsAT_Get_PMPromoTranslation]  
	-- Required  
	@PK_Event   int  
  
	-- Optional  
	,@LocaleCode  varchar(5) = NULL  
  
	-- Defaults  
	,@OnlineEventLink int = 11  
	,@PromoCodeLink  int = 13  
  
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS  
BEGIN  
/******************************************************************************  
  
 OBJECT:   dbo.usp_EventsAT_Get_PMPromoTranslation  
  
 USE:     
	DECLARE @e int, @em varchar(4000)
  
     EXEC dbo.usp_EventsAT_Get_PMPromoTranslation  
       @PK_Event = 53844  
       ,@LocaleCode = 'es-AR'  
       ,@Error = @e OUTPUT  /* @e must be defined in the local call */  
       ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */  
        ,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]
  
 DESCRIPTION: Get Preferred Member Promotion translation  
  
 NOTES:  
  
 DEPENDENCIES  
 --------------------------------------------------------------------  
 dbo.Level, dbo.EventLocaleDesc, dbo.Locales, dbo.EventImageLocaleDesc, ebo.EventURL  
  
 VERSIONS  
 --------------------------------------------------------------------  
 1.0.0		2017-04-05		RogelioR		Initial  
 2.0.0		2019-08-08		NoeG			Refactor code (SRE)
 2.0.1		2019-10-17		alejandramed	SRE Compliance 
 2.0.2		2022-06-20		puertac			US 1050464: Remove Errorlog when PK_event has been deleted
******************************************************************************/  
   
 SET ANSI_NULLS ON  
 SET QUOTED_IDENTIFIER ON  
 SET NOCOUNT ON  
   

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE()
		,@PK_Locale   int  
		,@PK_DefaultLocale int;  
     
SELECT @Error = 0, @ErrorMessage = '';
       
 BEGIN TRY   
	-----------------------------------------------------------------------------------------------------------------------  
	-- Promotion translation  
	SELECT  
			e.[PK_Event]
			,e.[dStartUTC]
			,e.[dEndUTC]
			,eld.[PK_Locale]
			,l.[LocaleCode]
			,l.[LanguageCountryRegion]
			,eld.[EventName]
			,eld.[EventDesc]
			,eld.[EventRules]
			,eu.[EventURL] AS [PromoCode]
			,eu.[EventURLDesc] AS [PromoCodeHTML]
			,eu.[Flyer] AS [ShowPromoCodeAfterQualification]
			,eld.[IsCTAEnabledOnUpcoming]
		FROM [Event] AS e  WITH(NOLOCK)
			INNER JOIN [EventLocaleDesc] AS eld WITH(NOLOCK) ON eld.[PK_Event] = e.[PK_Event]  
			INNER JOIN [Locales] AS l WITH(NOLOCK) ON l.[PK_Locale] = eld.[PK_Locale]  
			LEFT JOIN [EventURL] AS eu  WITH(NOLOCK) ON eu.[PK_Event] = e.[PK_Event]  
				AND eu.[PK_Locale] = l.[PK_Locale]  
				AND eu.[PK_EventURLType] = @PromoCodeLink  
		WHERE e.[PK_Event] = @PK_Event  
			AND (l.[LocaleCode] = @LocaleCode OR ISNULL(@LocaleCode, '') = '');  
    
	-----------------------------------------------------------------------------------------------------------------------  
	-- Promotion Thumbnails, Banners and Links  
	WITH cte_images AS (  
		SELECT  
			eild.[PK_Locale]
			,l.[LocaleCode]
			,l.[LanguageCountryRegion]
			,eild.[EventImageLocation]
			,ei.[PK_EventImageType]
		FROM [EventImageLocaleDesc] AS eild  WITH(NOLOCK)
			INNER JOIN [Locales] AS l WITH(NOLOCK) ON l.[PK_Locale] = eild.[PK_Locale]  
			LEFT JOIN [EventImage] AS ei WITH(NOLOCK) ON ei.[PK_EventImage] = eild.[PK_EventImage]  
		WHERE eild.[PK_Event] = @PK_Event  
			AND (l.[LocaleCode] = @LocaleCode OR ISNULL(@LocaleCode, '') = '')  
		)  
		SELECT [PK_Locale], [LocaleCode], [LanguageCountryRegion], [1] AS Thumbnail, [2] AS Banner  
		FROM (  
		SELECT [PK_Locale], [LocaleCode], [LanguageCountryRegion], [EventImageLocation], [PK_EventImageType]
			FROM cte_images) AS s   
		PIVOT (  
		MAX([EventImageLocation])
		FOR [PK_EventImageType] IN ([1], [2])  
		) AS p;  
    
	-----------------------------------------------------------------------------------------------------------------------  
	-- Promotion Link  
	SELECT  
			eu.PK_Locale  
			,l.LocaleCode  
			,l.LanguageCountryRegion  
			,eu.EventURL  
			,eu.EventURLDesc  
		FROM EventURL AS eu  WITH(NOLOCK)
			INNER JOIN Locales AS l WITH(NOLOCK) ON l.PK_Locale = eu.PK_Locale  
		WHERE eu.PK_Event = @PK_Event  
			AND (l.LocaleCode = @LocaleCode OR ISNULL(@LocaleCode, '') = '')  
			AND eu.PK_EventURLType = @OnlineEventLink;  
  
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