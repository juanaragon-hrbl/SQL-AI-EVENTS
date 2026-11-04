
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_BrazilMBActivationProgram18]
	-- Mandatory parameters
	 @PK_Event INT = 9331
	,@LocaleCode CHAR(5)
	-- Optional Parameters
	,@DistributorID VARCHAR(10) = '113507859'
	-- Error Parameters
	   ,@IsDevQA		BIT = 0   
	   ,@Error	int = 0 OUTPUT
	   ,@ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_BrazilMBActivationProgram18

USE:	        
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_BrazilMBActivationProgram18
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 9331
						,@LocaleCode = 'en-US'

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.Subevent, dbo.EventLocaleADesc, dbo.SubeventLocaleDesc, 
dbo.v_AGGFQS_ID, 
dbo.AWT,
dbo.EventTrackingPageSection,
dbo.EventEventTrackingPageSection

VERSIONS
----------------------------------------------------------------------------------
1	2013-02-06	OrlandoL	Intitial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* DECLARE THE REQUIRED VARIABLES */
DECLARE @PK_Distributor INT
DECLARE @PK_Locale INT
DECLARE @PK_DefaultLocale INT
DECLARE @AppDate DATETIME
DECLARE @CurrentDate DATETIME  
DECLARE @MonthPart INT
DECLARE @YearPart INT
DECLARE @SubEventNumber INT = 0
DECLARE @Qualified INT = 0

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

/* SET THE VALUES FOR THE DECLARED VARIABLES */
SELECT @AppDate = dApplication FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event
SELECT @Qualified = Qualified FROM SubEventQualifier WITH (NOLOCK) WHERE PK_Distributor = @PK_Distributor and PK_Event = @PK_Event 
				AND Qualified = 1 AND RemovedUTC = '12-31-2049' 


SELECT @CurrentDate = DATEADD(month, DATEDIFF(month, 0, GETUTCDATE()), 0)   
SELECT @MonthPart = RIGHT('0' + CAST(MONTH(@CurrentDate) AS NVARCHAR(2)), 2)
SELECT @YearPart = DATEPART(YYYY,@CurrentDate)
SELECT @SubEventNumber = (CASE WHEN @YearPart = 2017 AND @MonthPart IN (01, 02, 03) AND @AppDate BETWEEN '2016-07-01' AND '2017-01-31' THEN 1 
							   WHEN @YearPart = 2017 AND @MonthPart IN (02, 03, 04) AND @AppDate BETWEEN '2016-08-01' AND '2017-02-28' THEN 2
							   WHEN @YearPart = 2017 AND @MonthPart IN (03, 04, 05) AND @AppDate BETWEEN '2016-09-01' AND '2017-03-31' THEN 3
							   WHEN @YearPart = 2017 AND @MonthPart IN (04, 05, 06) AND @AppDate BETWEEN '2016-10-01' AND '2017-04-30' THEN 4
							   WHEN @YearPart = 2017 AND @MonthPart IN (05, 06, 07) AND @AppDate BETWEEN '2016-11-01' AND '2017-05-31' THEN 5
							   WHEN @YearPart = 2017 AND @MonthPart IN (06, 07, 08) AND @AppDate BETWEEN '2016-12-01' AND '2017-06-30' THEN 6
							   WHEN @YearPart = 2017 AND @MonthPart IN (07, 08, 09) AND @AppDate BETWEEN '2017-01-01' AND '2017-07-31' THEN 7
							   WHEN @YearPart = 2017 AND @MonthPart IN (08, 09, 10) AND @AppDate BETWEEN '2017-02-01' AND '2017-08-31' THEN 8
							   WHEN @YearPart = 2017 AND @MonthPart IN (09, 10, 11) AND @AppDate BETWEEN '2017-03-01' AND '2017-09-30' THEN 9
							   WHEN @YearPart = 2017 AND @MonthPart IN (10, 11, 12) AND @AppDate BETWEEN '2017-04-01' AND '2017-10-31' THEN 10
							   WHEN ((@YearPart = 2017 AND @MonthPart IN (11, 12)) OR (@YearPart = 2018 AND @MonthPart IN (01))) AND @AppDate BETWEEN '2017-05-01' AND '2017-11-30' THEN 11
							   WHEN ((@YearPart = 2017 AND @MonthPart IN (12)) OR (@YearPart = 2018 AND @MonthPart IN (01, 02))) AND @AppDate BETWEEN '2017-06-01' AND '2017-12-31' THEN 12
							  
						  END)

 BEGIN TRY
/******************************************************************************
      update Qualification
******************************************************************************/
IF @Qualified = 1
BEGIN
SELECT    
  SE.PK_SubEvent    
 ,SE.PK_Event    
 ,COALESCE(CASE WHEN SD.SubEventQualDesc = '' then null ELSE SD.SubEventQualDesc END    
 , CASE WHEN SED.SubEventQualDesc = '' then null ELSE SED.SubEventQualDesc END    
 , SE.SubEventName) SubEventName    
 ,ISNULL(SQ.Qualified,0) Qualified    
 ,COALESCE(CASE WHEN SD.SubEventQualDesc = '' then null ELSE SD.SubEventQualDesc END    
   , CASE WHEN SED.SubEventQualDesc = '' then null ELSE SED.SubEventQualDesc END    
   , SE.SubEventName) [SubEventQualDesc]    
 ,COALESCE(CASE WHEN SD.QualDesc = '' THEN NULL ELSE SD.QualDesc END    
   , CASE WHEN SED.QualDesc = '' THEN NULL ELSE SED.QualDesc END ) [QualificiationDesc]    
 ,SE.PK_SubEventGroup    
 ,SEG.SubEventGroup [SubEventGroup]    
 ,SEE.Icon    
 ,SEE.Color    
 ,SE.SubEventNumber    
 ,SQ.QualDate [QualDate]    
 ,COALESCE(SD.SubEventGroupNameLocale, SED.SubEventGroupNameLocale) SubEventGroupNameLocale     
 ,COALESCE(CASE WHEN SD.[Image] = '' then null ELSE SD.[Image] END, CASE WHEN SED.[Image] = '' then null ELSE SED.[Image] END) AS [Image]       
 ,COALESCE(CASE WHEN SED.SubEventGroupNameLocale  = '' then null ELSE SED.SubEventGroupNameLocale END, SEG.SubEventGroupName) SubEventGroupNameDefaultLocale  
FROM    
 dbo.SubEvent SE WITH (NOLOCK)   
LEFT JOIN    
 dbo.SubeventLocaleDesc SD WITH (NOLOCK)    
ON    
 SE.PK_Event = SD.PK_Event    
 AND SE.PK_SubEvent = SD.PK_Subevent    
 AND SD.PK_Locale = @PK_Locale    
LEFT JOIN    
 dbo.SubeventLocaleDesc SED WITH (NOLOCK)  
ON    
 SE.PK_Event = SED.PK_Event    
 AND SE.PK_SubEvent = SED.PK_Subevent    
 AND SED.PK_Locale = @PK_DefaultLocale    
LEFT JOIN    
 dbo.SubEventQualifier SQ WITH (NOLOCK)  
ON    
 SQ.PK_Event = SE.PK_Event    
 AND SQ.PK_SubEvent = SE.PK_SubEvent    
 AND SQ.RemovedUTC = '12-31-2049'    
 AND SQ.Qualified = 1    
 AND SQ.PK_Distributor = @PK_Distributor    
LEFT JOIN    
   dbo.SubEventGroup SEG WITH (NOLOCK)    
ON    
   SE.PK_SubEventGroup = SEG.PK_SubEventGroup    
LEFT JOIN    
   dbo.SubEventExtn SEE WITH (NOLOCK)    
ON    
   SE.PK_SubEvent = SEE.PK_SubEvent     
   AND    
   SE.PK_Event = SEE.PK_Event    
WHERE    
 SE.PK_Event = 9331     
AND    
 SE.IsTrackingVisible = 1    
AND 
 SQ.Qualified = 1
 --SE.SubEventNumber = @SubEventNumber
ORDER BY    
 SEG.DisplayOrder, SE.SubEventNumber  
END  
ELSE
BEGIN
SELECT  
  SE.PK_SubEvent  
 ,SE.PK_Event  
 ,COALESCE(CASE WHEN SD.SubEventQualDesc = '' then null ELSE SD.SubEventQualDesc END  
 , CASE WHEN SED.SubEventQualDesc = '' then null ELSE SED.SubEventQualDesc END  
 , SE.SubEventName) SubEventName  
 ,ISNULL(SQ.Qualified,0) Qualified  
 ,COALESCE(CASE WHEN SD.SubEventQualDesc = '' then null ELSE SD.SubEventQualDesc END  
   , CASE WHEN SED.SubEventQualDesc = '' then null ELSE SED.SubEventQualDesc END  
   , SE.SubEventName) [SubEventQualDesc]  
 ,COALESCE(CASE WHEN SD.QualDesc = '' THEN NULL ELSE SD.QualDesc END  
   , CASE WHEN SED.QualDesc = '' THEN NULL ELSE SED.QualDesc END ) [QualificiationDesc]  
 ,SE.PK_SubEventGroup  
 ,SEG.SubEventGroup [SubEventGroup]  
 ,SEE.Icon  
 ,SEE.Color  
 ,SE.SubEventNumber  
 ,SQ.QualDate [QualDate]  
 ,COALESCE(SD.SubEventGroupNameLocale, SED.SubEventGroupNameLocale) SubEventGroupNameLocale   
 ,COALESCE(CASE WHEN SD.[Image] = '' then null ELSE SD.[Image] END, CASE WHEN SED.[Image] = '' then null ELSE SED.[Image] END) AS [Image]     
 ,COALESCE(CASE WHEN SED.SubEventGroupNameLocale  = '' then null ELSE SED.SubEventGroupNameLocale END, SEG.SubEventGroupName) SubEventGroupNameDefaultLocale
FROM  
 dbo.SubEvent SE WITH (NOLOCK)
LEFT JOIN  
 dbo.SubeventLocaleDesc SD WITH (NOLOCK)
ON  
 SE.PK_Event = SD.PK_Event  
 AND SE.PK_SubEvent = SD.PK_Subevent  
 AND SD.PK_Locale = @PK_Locale  
LEFT JOIN  
 dbo.SubeventLocaleDesc SED WITH (NOLOCK) 
ON  
 SE.PK_Event = SED.PK_Event  
 AND SE.PK_SubEvent = SED.PK_Subevent  
 AND SED.PK_Locale = @PK_DefaultLocale  
LEFT JOIN  
 dbo.SubEventQualifier SQ WITH (NOLOCK)
ON  
 SQ.PK_Event = SE.PK_Event  
 AND SQ.PK_SubEvent = SE.PK_SubEvent  
 AND SQ.RemovedUTC = '12-31-2049'  
 AND SQ.Qualified = 1  
    AND SQ.PK_Distributor = @PK_Distributor  
LEFT JOIN  
   dbo.SubEventGroup SEG WITH (NOLOCK)  
ON  
   SE.PK_SubEventGroup = SEG.PK_SubEventGroup  
LEFT JOIN  
   dbo.SubEventExtn SEE WITH (NOLOCK) 
ON  
   SE.PK_SubEvent = SEE.PK_SubEvent   
   AND  
   SE.PK_Event = SEE.PK_Event  
WHERE  
 SE.PK_Event = @PK_Event   
AND  
 SE.IsTrackingVisible = 1  
AND
 SE.SubEventNumber = @SubEventNumber
ORDER BY  
 SEG.DisplayOrder, SE.SubEventNumber  
END

SELECT @AppDate AS ApplicationDate


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
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;