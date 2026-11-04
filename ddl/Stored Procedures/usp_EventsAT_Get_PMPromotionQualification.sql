CREATE PROCEDURE [dbo].[usp_EventsAT_Get_PMPromotionQualification]  
	-- Required  
	@PK_Event		int
	,@LocaleCode	varchar(5)
  
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS  
BEGIN  
/******************************************************************************  
  
 OBJECT:   dbo.usp_EventsAT_Get_PMPromotionQualification  
  
 USE:     
	DECLARE @e int, @em varchar(4000)
  
     EXEC dbo.usp_EventsAT_Get_PMPromotionQualification  
       @PK_Event = 48062  
       ,@LocaleCode = 'es-US'  
       ,@Error = @e OUTPUT  /* @e must be defined in the local call */  
       ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */  
        ,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]
     
 DESCRIPTION: Gets promotion qualification data  
  
 NOTES:  
  
 DEPENDENCIES  
 --------------------------------------------------------------------  
 dbo.Event, dbo.EventLocaleDesc, dbo.SubEvent, dbo.SubEventLocaleDesc  
  
 VERSIONS  
 --------------------------------------------------------------------  
 1.0.0		2017-04-12		RogelioR		Initial  
 2.0.0		2019-08-08		NoeG			Refactor code (SRE)
 2.0.1		2020-08-31		puertac			BUG 348551: Qualification Display Date and Publish Display Date use the same column
											Fix: Use QualificationDates instead of DisplayDates from dbo.Event table
 2.0.2		2022-06-20		puertac			US 1050464: Remove Errorlog when PK_event has been deleted
 2.0.3		2023-03-24		alejandramed	Taking the flag [IsQualifytoPurchaseTickets] as 1 if the PM Promo comes from Events Self service tool 
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
  
	SELECT @PK_Locale = PK_Locale FROM Locales WITH(NOLOCK) WHERE LocaleCode = @LocaleCode;  
  
	-----------------------------------------------------------------------------------------------------------------------  
	-- Qualification data  
	SELECT   
			e.[PK_Event]  
			,IIF(s.PK_Event IS NULL, e.[IsQualifytoPurchaseTickets], 1) AS [PromotionRequiresQualification]  -- v2.0.2
			,e.QualPeriodStart AS [DisplayStartDate]						-- BUG 348551: Use QualificationDates instead of DisplayDates		
			,e.QualPeriodEnd AS [DisplayEndDate]							-- BUG 348551: Use QualificationDates instead of DisplayDates
			,e.[CanDisplayQualPeriod] AS [DisplayQualificationDates]  
			,e.[IsPublishQualTracking] AS [PublishQualTracker]  
			,e.[CanAssignTickets] AS [SameDescriptionAllLeves]  
			,ISNULL(ee.[IsDisplayTVP], 0) AS [IsDisplayTVP]  
			,ISNULL(ee.[IsDisplayDV], 0) AS [IsDisplayDV]  
			,ISNULL(ee.[IsDisplayPPV], 0) AS [IsDisplayPPV]  
			,ISNULL(ee.[IsDisplayDLV], 0) AS [IsDisplayDLV]
			,ISNULL(ee.[DisplayQualStatus], 0) AS [DisplayQualStatus]
			,ISNULL(ee.[PromotionCode], '') AS [PromotionCode]
		FROM [dbo].[Event] AS e  WITH(NOLOCK) 
			LEFT JOIN [dbo].[EventExtn] AS ee WITH(NOLOCK) ON ee.[PK_Event] = e.[PK_Event]  
			LEFT JOIN [eventpromo].[Settings] AS s WITH (NOLOCK) ON e.[PK_Event] = s.[PK_Event]  
		WHERE e.[PK_Event] = @PK_Event  
    
	-----------------------------------------------------------------------------------------------------------------------  
	-- Return qualification locales for the Event  
	DECLARE @l int = 0;  
  
	IF EXISTS (SELECT 1 FROM SubEventLocaleDesc WITH(NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_Locale)  
		SELECT @l = 1;  
  
	SELECT  
			se.[PK_SubEvent]  
			,se.[SubEventName] AS [QualificationName]  
			,se.[PK_Event]  
			,l.[PK_Locale]  
			,l.[LocaleCode]  
			,seld.[SubEventName]
			,seld.[SubEventQualDesc]  
			,seld.[Image]
			,se.[IsTrackingVisible]
		FROM SubEvent AS se  WITH(NOLOCK)
			JOIN [dbo].[Locales] AS l WITH(NOLOCK) ON l.[PK_Locale] = @PK_Locale
			LEFT JOIN [dbo].[SubEventLocaleDesc] AS seld WITH(NOLOCK) ON seld.[PK_Subevent] = se.[PK_SubEvent]      
				AND (seld.PK_Locale = @PK_Locale)  
		WHERE se.PK_Event = @PK_Event     


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