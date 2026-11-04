
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Standar_TrackingPage]
	-- Mandatory parameters
	 @PK_Event INT = 976
	,@LocaleCode CHAR(5)
	-- Optional Parameters
	,@DistributorID VARCHAR(10) = '2222222222'
	-- Error Parameters
	   ,@IsDevQA		BIT = 0
	   ,@Error	int = 0 OUTPUT
	   ,@ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Standar_TrackingPage

USE:	        
                 EXEC dbo.usp_MyHLEventAPI_Standar_TrackingPage
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 976
						,@LocaleCode = 'en-US'

DESCRIPTION:	This is a custom stored procedure that retreievs all the Sub Events from Russia Extracaganza 

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------


VERSIONS
----------------------------------------------------------------------------------
1	2013-02-06	 OrlandoL	    Intitial
2	2019-10-16	 JonathanO		Refactor code (SRE)

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
DECLARE @Date DATETIME = '2013-03-01'
DECLARE @DateAdd INT = 10
DECLARE @Count INT = 1

/* SET THE VALUES FOR THE DECLARED VARIABLES */

SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
SELECT @PK_Locale = PK_Locale FROM dbo.Locales WHERE LocaleCode = @LocaleCode
SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WHERE PK_Event = @PK_Event


	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

BEGIN TRY
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
IF EXISTS (SELECT 1 FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 1)
BEGIN
SELECT
	 EI.PK_Event
	,EI.PK_EventImageType
	,EIT.EventImageType
	,ISNULL(EI.EventImageLocation,'') [EventImageLocation]
	,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WHERE PK_EventTrackingPageSection = 1) [EventTrackingPageSectionName]
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
IF EXISTS (SELECT 1 FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 2)
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
IF EXISTS (SELECT 1 FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 3 AND PK_Event = @PK_Event)
BEGIN
IF EXISTS (SELECT 1 FROM dbo.SubEventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_Locale)

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
	AND SQ.RemovedUTC = '12-31-2049'
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
	AND SQ.RemovedUTC = '12-31-2049'
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
IF EXISTS (SELECT 1 FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event)
BEGIN
/* DECLARE A TEMP TABLE TO DISPLAY THE VOLUME DETAILS PER THE REQUIREMENT */
IF OBJECT_ID('tempdb..#SubEvents') IS NOT NULL DROP TABLE #SubEvents







END
/* NUMBER 5: MAKE SURE WE GET THE EVENT RULES SECTION IF IT IS REQUIRED */ 
IF EXISTS (SELECT 1 FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 5)
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
IF EXISTS (SELECT 1 FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 6 AND PK_Event = @PK_Event)
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
IF EXISTS (SELECT 1 FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 7 AND PK_Event = @PK_Event)
BEGIN
/* SELECT ALL THE AVAILABLE URLS FOR THE PASSED PK_EVENT */
IF EXISTS (SELECT 1 FROM dbo.EventURL WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_Locale AND (EventURL IS NOT NULL OR Flyer IS NOT NULL))
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
IF EXISTS (SELECT 1 FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 8 AND PK_Event = @PK_Event)
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