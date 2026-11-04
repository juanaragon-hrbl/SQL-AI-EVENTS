
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_UKASPPromo]
	-- Mandatory parameters
	 @PK_Event INT = 2140
	,@LocaleCode CHAR(5)
	-- Optional Parameters
	,@DistributorID VARCHAR(10) = '2222222222'
	-- Error Parameters
	,@Error INT = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_UKASPPromo

USE:	        
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_UKASPPromo
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 2140
						,@LocaleCode = 'en-US'

DESCRIPTION:	This is a custom stored procedure that retreievs all the details for the 
                EMEA Year End Promo 2014 based on the sections defined for the Tracking Page.
                The sections are specific to every event based on what the region decides
                to display on the tracking page

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
2	2019-08-14	NoeG		Refactor code (SRE)
3	2019-11-04	NoeG		SRE Hardcode changed
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRANSACTION
/* DECLARE THE REQUIRED VARIABLES */
DECLARE @PK_Distributor INT
DECLARE @PK_Locale INT
DECLARE @PK_DefaultLocale INT
DECLARE	@COP CHAR (2) = NULL
DECLARE @ValidDate DATETIME = '2049-12-31'

/* SET THE VALUES FOR THE DECLARED VARIABLES */

SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

/* GET THE DETAILS TO BE DISPLAYED ON THE TRACKING PAGE ALONG WITH THE ASSOCIATED DISPLAY ORDER */
SELECT
	 EETP.PK_Event
	,E.EventName
	,EETP.PK_EventTrackingPageSection
	,ETP.EventTrackingPageSectionName
	,EETP.TrackingPageSectionDisplayOrder
FROM
	dbo.EventEventTrackingPageSection EETP WITH (NOLOCK)
INNER JOIN
	dbo.EventTrackingPageSection ETP WITH (NOLOCK)
ON
	EETP.PK_EventTrackingPageSection = ETP.PK_EventTrackingPageSection
INNER JOIN
	dbo.Event E WITH (NOLOCK)
ON
	EETP.PK_Event = E.PK_Event
WHERE
	EETP.PK_Event = @PK_Event

SET @Error = @Error + @@ERROR

/* START THE DISPLAY DETAILS PER THE REQUIREMENT */

/* NUMBER 1: MAKE SURE WE GET THE EVENTIMAGEHEADER DETAILS SECTION IF IT IS REQUIRED */
IF EXISTS (SELECT [PK_EventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 1 AND PK_Event = @PK_Event)
BEGIN
SELECT
	 EI.PK_Event
	,EI.PK_EventImageType
	,EIT.EventImageType
	,ISNULL(EI.EventImageLocation,'') [EventImageLocation]
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 1) [EventTrackingPageSectionName]
	,EETP.TrackingPageSectionDisplayOrder [DisplayOrder]	
FROM
	dbo.EventImage EI WITH (NOLOCK)
INNER JOIN
	dbo.EventImageType EIT WITH (NOLOCK)
ON
	EI.PK_EventImageType = EIT.PK_EventImageType
INNER JOIN
	dbo.EventEventTrackingPageSection EETP WITH (NOLOCK)
ON
	EI.PK_Event = EETP.PK_Event
	AND EETP.PK_EventTrackingPageSection = 1
WHERE
	EI.PK_Event = @PK_Event
END

SET @Error = @Error + @@ERROR

/* NUMBER 2: MAKE SURE WE GET THE EVENTDESCRIPTION DETAILS SECTION IF IT IS REQUIRED */
IF EXISTS (SELECT [PK_EventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 2 AND PK_Event = @PK_Event)
BEGIN
SELECT
	 ED.PK_Event
	,ISNULL(ED.EventName,E.EventName) [EventName]
	,ISNULL(ED.EventDesc,(SELECT EventDesc FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale)) [EventDesc]
	,ISNULL(ED.EventSummary,(SELECT EventSummary FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale)) [EventSummary]
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 2) [EventTrackingPageSectionName]
	,EETP.TrackingPageSectionDisplayOrder [DisplayOrder]
FROM
	dbo.EventLocaleDesc ED WITH (NOLOCK)
LEFT JOIN
	dbo.Event E WITH (NOLOCK)
ON
	ED.PK_Event = E.PK_Event
	AND ED.PK_Locale = @PK_Locale
INNER JOIN
	dbo.EventEventTrackingPageSection EETP WITH (NOLOCK)
ON
	E.PK_Event = EETP.PK_Event
	AND EETP.PK_EventTrackingPageSection = 2
WHERE
	E.PK_Event = @PK_Event
END

SET @Error = @Error + @@ERROR

/* NUMBER 3: MAKE SURE WE GET THE SUBEVENTQUALIFICATIONS DETAILS SECTION IF IT IS REQUIRED */
IF EXISTS (SELECT [PK_EventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 3 AND PK_Event = @PK_Event)
BEGIN
IF EXISTS (SELECT PK_Locale FROM dbo.SubEventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_Locale)

/* SELECT THE SUBEVENT QUALIFICATIONS FOR THE DISTRIBUTORID FOR THE PASSED PK_EVENT */
BEGIN
SELECT
	 SE.PK_SubEvent
	,SE.PK_Event
	,SD.SubEventName
	,ISNULL(SQ.Qualified,0) Qualified
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 3) [EventTrackingPageSectionName]
	,EETP.TrackingPageSectionDisplayOrder [DisplayOrder]
FROM
	dbo.SubEvent SE WITH (NOLOCK)
LEFT JOIN
	dbo.SubeventLocaleDesc SD WITH (NOLOCK)
ON
	SE.PK_Event = SD.PK_Event
	AND SE.PK_SubEvent = SD.PK_Subevent
LEFT JOIN
	dbo.SubEventQualifier SQ WITH (NOLOCK)
ON
	SQ.PK_Event = SE.PK_Event
	AND SQ.PK_SubEvent = SE.PK_SubEvent
	AND SQ.RemovedUTC = @ValidDate
    AND SQ.Qualified = 1
    AND SQ.DistributorID = @DistributorID
INNER JOIN
	dbo.EventEventTrackingPageSection EETP WITH (NOLOCK)
ON
	SE.PK_Event = EETP.PK_Event
	AND EETP.PK_EventTrackingPageSection = 3
WHERE
	SE.PK_Event = @PK_Event 
AND 
	SD.PK_Locale = @PK_Locale
END
ELSE
BEGIN
SELECT
	 SE.PK_SubEvent
	,SE.PK_Event
	,SD.SubEventName
	,ISNULL(SQ.Qualified,0) Qualified
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 3) [EventTrackingPageSectionName]
	,EETP.TrackingPageSectionDisplayOrder [DisplayOrder]
FROM
	dbo.SubEvent SE WITH (NOLOCK)
INNER JOIN
	dbo.SubeventLocaleDesc SD WITH (NOLOCK)
ON
	SE.PK_Event = SD.PK_Event
	AND SE.PK_SubEvent = SD.PK_Subevent
LEFT JOIN
	dbo.SubEventQualifier SQ WITH (NOLOCK)
ON
	SQ.PK_Event = SE.PK_Event
	AND SQ.PK_SubEvent = SE.PK_SubEvent
	AND SQ.RemovedUTC = @ValidDate
    AND SQ.Qualified = 1
    AND SQ.DistributorID = @DistributorID
INNER JOIN
	dbo.EventEventTrackingPageSection EETP WITH (NOLOCK)
ON
	SE.PK_Event = EETP.PK_Event
	AND EETP.PK_EventTrackingPageSection = 3
WHERE
	SE.PK_Event = @PK_Event 
AND 
	SD.PK_Locale = @PK_DefaultLocale
END
END

SET @Error = @Error + @@ERROR

/* NUMBER 4: MAKE SURE WE GET THE VOLUME POINTS DETAILS SECTION IF IT IS REQUIRED */
IF EXISTS (SELECT [PK_EventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event)
BEGIN
/* DECLARE A TEMP TABLE TO DISPLAY THE VOLUME DETAILS PER THE REQUIREMENT */
IF OBJECT_ID('tempdb..#ASPQualDateDetails') IS NOT NULL DROP TABLE #ASPQualDateDetails
IF OBJECT_ID('tempdb..#VolumePeriod') IS NOT NULL DROP TABLE #VolumePeriod

DECLARE @CurrentDate DATETIME = DATEADD(mm,DATEDIFF(mm,0,GETDATE()),0)
,@Begin DATETIME = '2015-01-01'
,@End DATETIME = '2015-12-01'
,@RunMonth DATETIME 
,@SQL VARCHAR(MAX) = ''
,@1Stone DATETIME
,@2Stone DATETIME
,@3Stone DATETIME
,@5Stone DATETIME
,@7Stone DATETIME
,@10Stone DATETIME
,@15Stone DATETIME
,@Total1Stone INT
,@Total2Stone INT
,@Total3Stone INT
,@Total5Stone INT
,@Total7Stone INT
,@Total10Stone INT
,@Total15Stone INT
,@TotalStonesJan INT
,@TotalStonesFeb INT
,@TotalStonesMar INT
,@TotalStonesApr INT
,@TotalStonesMay INT
,@TotalStonesJun INT
,@TotalStonesJul INT
,@TotalStonesAug INT
,@TotalStonesSep INT
,@TotalStonesOct INT
,@TotalStonesNov INT
,@TotalStonesDec INT


IF DATEADD(MM,-11,@CurrentDate) >= '2015-01-01'
BEGIN
	SET @Begin	= DATEADD(MM,-10,@CurrentDate)
	SET @End	= DATEADD(MM,1,@CurrentDate)
END

CREATE TABLE #ASPQualDateDetails
( 
	 ActiveSP DATETIME DEFAULT NULL 
	,Stone1 DATETIME DEFAULT NULL 
	,Stone2 DATETIME DEFAULT NULL 
	,Stone3 DATETIME DEFAULT NULL 
	,Stone5 DATETIME DEFAULT NULL 
	,Stone7 DATETIME DEFAULT NULL 
	,Stone10 DATETIME DEFAULT NULL 
	,Stone15 DATETIME DEFAULT NULL 
	,PK_Distributor INT NOT NULL
)

CREATE TABLE #VolumePeriod
(
	 VolumeMonth DATETIME
	,TVP MONEY DEFAULT 0
	,TotalASP INT DEFAULT 0
	,PK_Distributor INT NOT NULL
)

IF @PK_Distributor IS NOT NULL
BEGIN
/* INSERT PK_DS in temp tables */
	INSERT #ASPQualDateDetails
	( 
		PK_Distributor
	)
	SELECT @PK_Distributor
END

/*************************************
		COP
*************************************/

SELECT
	@COP = sDistributorCountryProcessingCode
FROM dbo.v_Distributor WITH (NOLOCK)
WHERE sDistributorCountryProcessingCode IN ('UK','EI','IC','SW')
AND
	nDistributorID = @PK_Distributor


/***********************************************
	UPDATE Volume Points & Royalty Overrides
***********************************************/
IF @PK_Distributor IS NOT NULL AND @Begin IS NOT NULL AND @End IS NOT NULL
BEGIN
	INSERT #VolumePeriod (VolumeMonth,PK_Distributor,TVP)
	SELECT 
		dMonth,
		@PK_Distributor,
		CASE WHEN @COP IS NOT NULL THEN ISNULL(A.mVolumePoints,0) ELSE 0 END
	FROM
		[dbo].[v_Months] M
	LEFT JOIN
		[dbo].[v_aggFQS_ID] A
	ON
		M.dMonth = A.dRoyaltyMonth
		AND
		A.nDistributorID = @PK_Distributor
	WHERE
		dMonth BETWEEN @Begin AND @End
END

IF @COP IS NOT NULL
BEGIN 	
	/************************************************************
		UPDATE Qualified Column from #ASPQualDateDetails per Level
	*************************************************************/
	IF @PK_Distributor IS NOT NULL
	UPDATE
		SP
	SET
		 ActiveSP = ASP.AcviteSupervisor_QualDate 
		,Stone1 = ASP.Stone1_QualDate
		,Stone2 = ASP.Stone2_QualDate
		,Stone3 = ASP.Stone3_QualDate  
		,Stone5 = ASP.Stone5_QualDate  
		,Stone7 = ASP.Stone7_QualDate  
		,Stone10 = ASP.Stone10_QualDate
		,Stone15 = ASP.Stone15_QualDate
		,@1Stone = ASP.Stone1_QualDate
		,@2Stone = ASP.Stone2_QualDate
		,@3Stone = ASP.Stone3_QualDate  
		,@5Stone = ASP.Stone5_QualDate  
		,@7Stone = ASP.Stone7_QualDate  
		,@10Stone = ASP.Stone10_QualDate 
		,@15Stone = ASP.Stone15_QualDate
		,@Total1Stone = ASP.TotalStone1
		,@Total2Stone = ASP.TotalStone2
		,@Total3Stone = ASP.TotalStone3
		,@Total5Stone = ASP.TotalStone5
		,@Total7Stone = ASP.TotalStone7
		,@Total10Stone = ASP.TotalStone10
		,@Total15Stone = ASP.TotalStone15
		,@TotalStonesJan = ISNULL(ASP.TotalStonesJan,0)
		,@TotalStonesFeb = ISNULL(ASP.TotalStonesFeb,0)
		,@TotalStonesMar = ISNULL(ASP.TotalStonesMar,0)
		,@TotalStonesApr = ISNULL(ASP.TotalStonesApr,0)
		,@TotalStonesMay = ISNULL(ASP.TotalStonesMay,0)
		,@TotalStonesJun = ISNULL(ASP.TotalStonesJun,0)
		,@TotalStonesJul = ISNULL(ASP.TotalStonesJul,0)
		,@TotalStonesAug = ISNULL(ASP.TotalStonesAug,0)
		,@TotalStonesSep = ISNULL(ASP.TotalStonesSep,0)
		,@TotalStonesOct = ISNULL(ASP.TotalStonesOct,0)
		,@TotalStonesNov = ISNULL(ASP.TotalStonesNov,0)
		,@TotalStonesDec = ISNULL(ASP.TotalStonesDec,0)
	FROM
		#ASPQualDateDetails SP
	INNER JOIN
		dbo.WRK_EMEAActiveSPPromo2015_AnyLine ASP 
	ON
		SP.PK_Distributor = ASP.PK_Distributor
	WHERE
		ASP.IsStar1 = 1
	
	/************************************************************
		UPDATE Total ASP based on the qual month
	*************************************************************/
SET @RunMonth = '2015-01-01'

WHILE @RunMonth <= '2015-12-01'
BEGIN
	UPDATE
		T
	SET
		T.TotalASP = CASE @RunMonth 
							WHEN '2015-01-01' THEN @TotalStonesJan
							WHEN '2015-02-01' THEN @TotalStonesFeb
							WHEN '2015-03-01' THEN @TotalStonesMar
							WHEN '2015-04-01' THEN @TotalStonesApr
							WHEN '2015-05-01' THEN @TotalStonesMay
							WHEN '2015-06-01' THEN @TotalStonesJun
							WHEN '2015-07-01' THEN @TotalStonesJul
							WHEN '2015-08-01' THEN @TotalStonesAug
							WHEN '2015-09-01' THEN @TotalStonesSep
							WHEN '2015-10-01' THEN @TotalStonesOct
							WHEN '2015-11-01' THEN @TotalStonesNov
							WHEN '2015-12-01' THEN @TotalStonesDec
					 END
	FROM	
		#VolumePeriod T
	WHERE
		T.VolumeMonth = @RunMonth 

SET @RunMonth = DATEADD(M,1,@RunMonth)
END
		

END

/**********************************************
	SELECT DATA TO FIRST GRID
**********************************************/
SELECT
	 VolumeMonth AS Date 
	,TVP AS VolumePoints
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4) [EventTrackingPageSectionName]
	,(SELECT TrackingPageSectionDisplayOrder FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event) [DisplayOrder] 
FROM #VolumePeriod

SELECT
	 VolumeMonth AS Date 
	,TotalASP
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4) [EventTrackingPageSectionName]
	,(SELECT TrackingPageSectionDisplayOrder FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event) [DisplayOrder] 
FROM #VolumePeriod

/**********************************************
	SELECT DATA TO THIRD GRID
**********************************************/
SELECT
	 ActiveSP 
	,Stone3 
	,Stone5 
	,Stone7 
	,Stone10
	,Stone15
	,@COP AS COP
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4) [EventTrackingPageSectionName]
	,(SELECT TrackingPageSectionDisplayOrder FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event) [DisplayOrder] 
FROM #ASPQualDateDetails



END	

/* NUMBER 5: MAKE SURE WE GET THE EVENT RULES SECTION IF IT IS REQUIRED */ 
IF EXISTS (SELECT [PK_EventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 5)
BEGIN
SELECT
	 E.PK_Event
	,ISNULL(ED.EventName,E.EventName) [EventName]
	,ISNULL(ED.EventRules,(SELECT EventRules FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale)) EventRules
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 5) [EventTrackingPageSectionName]
	,EETP.TrackingPageSectionDisplayOrder [DisplayOrder]
FROM
	dbo.EventLocaleDesc ED WITH (NOLOCK)
LEFT JOIN
	dbo.Event E WITH (NOLOCK)
ON
	ED.PK_Event = E.PK_Event
	AND ED.PK_Locale = @PK_Locale
INNER JOIN
	dbo.EventEventTrackingPageSection EETP WITH (NOLOCK)
ON
	E.PK_Event = EETP.PK_Event
	AND EETP.PK_EventTrackingPageSection = 5
WHERE
	E.PK_Event = @PK_Event
	
END

SET @Error = @Error + @@ERROR

/* NUMBER 6: MAKE SURE WE GET THE EVENT GUEST SPEAKERS SECTION IF IT IS REQUIRED */ 
IF EXISTS (SELECT [PK_EventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 6 AND PK_Event = @PK_Event)
BEGIN
SELECT
	 E.PK_Event
	,E.EventName [EventName]
	,ISNULL(GS.SpeakerName,'') [GuestSpeakers]
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 6) [EventTrackingPageSectionName]
	,EETP.TrackingPageSectionDisplayOrder [DisplayOrder]
FROM
	dbo.EventGuestSpeakers EG WITH (NOLOCK)
LEFT JOIN
	dbo.GuestSpeakers GS WITH (NOLOCK)
ON
	EG.PK_GuestSpeaker = GS.PK_GuestSpeaker
LEFT JOIN
	dbo.Event E WITH (NOLOCK)
ON
	EG.PK_Event = E.PK_Event
INNER JOIN
	dbo.EventEventTrackingPageSection EETP WITH (NOLOCK)
ON
	EG.PK_Event = EETP.PK_Event
	AND EETP.PK_EventTrackingPageSection = 6
WHERE
	EG.PK_Event = @PK_Event
END

SET @Error = @Error + @@ERROR

/* NUMBER 7: MAKE SURE WE GET THE EVENTURLANDATTACHMENTS DETAILS SECTION IF IT IS REQUIRED */ 
IF EXISTS (SELECT [PK_EventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 7 AND PK_Event = @PK_Event)
BEGIN
/* SELECT ALL THE AVAILABLE URLS FOR THE PASSED PK_EVENT */
IF EXISTS (SELECT PK_Locale FROM dbo.EventURL WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_Locale AND (EventURL IS NOT NULL OR Flyer IS NOT NULL))
BEGIN
SELECT
	 E.PK_Event
	,A.PK_EventURL
	,A.EventURL
	,A.EventURLDesc
	,A.Flyer
	,A.ModifiedDateUTC LastUpdatedDate
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 7) [EventTrackingPageSectionName]
	,EETP.TrackingPageSectionDisplayOrder [DisplayOrder]
FROM 
	dbo.Event E WITH (NOLOCK)
INNER JOIN
	(SELECT PK_Event, PK_Locale, PK_EventURL, EventURL, EventURLDesc, Flyer, ModifiedDateUTC FROM dbo.EventURL WITH (NOLOCK) WHERE PK_Event = @PK_Event AND (EventURL IS NOT NULL OR Flyer IS NOT NULL) AND PK_Locale = @PK_Locale) A
ON
	E.PK_Event = A.PK_Event
INNER JOIN
	dbo.EventEventTrackingPageSection EETP WITH (NOLOCK)
ON
	E.PK_Event = EETP.PK_Event
	AND EETP.PK_EventTrackingPageSection = 7
WHERE
	E.PK_Event = @PK_Event
END
ELSE
BEGIN
SELECT
	 E.PK_Event
	,B.PK_EventURL
	,B.EventURL
	,B.EventURLDesc
	,B.Flyer
	,B.ModifiedDateUTC LastUpdatedDate
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 7) [EventTrackingPageSectionName]
	,EETP.TrackingPageSectionDisplayOrder [DisplayOrder]
FROM 
	dbo.Event E WITH (NOLOCK)
INNER JOIN
	(SELECT PK_Event, PK_Locale, PK_EventURL, EventURL, EventURLDesc, Flyer, ModifiedDateUTC FROM dbo.EventURL WITH (NOLOCK) WHERE PK_Event = @PK_Event AND (EventURL IS NOT NULL OR Flyer IS NOT NULL) AND PK_Locale = @PK_DefaultLocale) B
ON
	E.PK_Event = B.PK_Event
INNER JOIN
	dbo.EventEventTrackingPageSection EETP WITH (NOLOCK)
ON
	E.PK_Event = EETP.PK_Event
	AND EETP.PK_EventTrackingPageSection = 7
WHERE
	E.PK_Event = @PK_Event

END
END
SET @Error = @Error + @@ERROR

/* NUMBER 8: MAKE SURE WE GET THE EVENT LOCATION SECTION IF IT IS REQUIRED */ 
IF EXISTS (SELECT [PK_EventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 8 AND PK_Event = @PK_Event)
BEGIN
SELECT
	E.PK_Event
	,ISNULL(ED.EventName,E.EventName) EventName
	,ISNULL(ED.EventLocation, (SELECT EventLocation FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Locale = @PK_DefaultLocale AND PK_Event = @PK_Event)) [EventLocation]
	,ISNULL(ED.EventAddress, (SELECT EventAddress FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Locale = @PK_DefaultLocale AND PK_Event = @PK_Event)) [EventAddress]
	,ISNULL(ED.EventCity, E.EventCity) [EventCity]
	,ISNULL(ED.EventState, E.EventState) [EventState]
	,C.sCountryName [EventCountry]
	,ISNULL(E.EventZipCode, '') [EventZipCode]
	,ISNULL(ED.EventDisplayAddress,(SELECT EventDisplayAddress FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Locale = @PK_DefaultLocale AND PK_Event = @PK_Event)) [EventDisplayAddress]
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 8) [EventTrackingPageSectionName]
	,EETP.TrackingPageSectionDisplayOrder [DisplayOrder]
FROM
	dbo.EventLocaleDesc ED WITH (NOLOCK)
LEFT JOIN
	dbo.Event E WITH (NOLOCK)
ON
	ED.PK_Event = E.PK_Event
	AND ED.PK_Locale = @PK_Locale
INNER JOIN
	dbo.EventEventTrackingPageSection EETP WITH (NOLOCK)
ON
	E.PK_Event = EETP.PK_Event
	AND EETP.PK_EventTrackingPageSection = 8
INNER JOIN
	dbo.EventCountry EC WITH (NOLOCK)
ON
	E.PK_Event = EC.PK_Event
INNER JOIN
	dbo.v_Countries C
ON
	EC.PK_Country = C.nCountryID
WHERE
	E.PK_Event = @PK_Event
	
END

SET @Error = @Error + @@ERROR

/* ROLLBACK TRANSACTION IF ERROR OCCURED ANYWHERE */
IF @Error > 0
BEGIN
	ROLLBACK TRANSACTION
	PRINT 'Error Occured. No Record set was retrieved.'
END
ELSE
BEGIN
	COMMIT TRANSACTION
	PRINT 'All Records Selected Successfully'
END

/* END THE PROCEDURE */
END
GO

