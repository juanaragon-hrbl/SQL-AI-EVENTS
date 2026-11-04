
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_GEASPPromo]
	-- Mandatory parameters
	 @PK_Event INT = 2141
	,@LocaleCode CHAR(5)
	-- Optional Parameters
	,@DistributorID VARCHAR(10) = '2222222222'
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_GEASPPromo

USE:			
			DECLARE @e int, @em varchar(4000)
		
            EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_GEASPPromo
					@DistributorID = N'2222222222'
				,@PK_Event = 2141
				,@LocaleCode = 'en-US'
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	This is a custom stored procedure that retreievs all the details for the 
                EMEA Year End Promo 2014 based on the sections defined for the Tracking Page.
                The sections are specific to every event based on what the region decides
                to display on the tracking page

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.Subevent, dbo.EventLocaleADesc, dbo.SubeventLocaleDesc, 
dbo.v_aggFQS_ID, 
dbo.AWT,
dbo.EventTrackingPageSection,
dbo.EventEventTrackingPageSection

VERSIONS
----------------------------------------------------------------------------------
1	2013-02-06	OrlandoL	Intitial
1.2	2019-08-14		NoeG		Refactor code (SRE)
1.3	2019-10-30		NoeG		SRE Hardcode changed

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY


		BEGIN TRANSACTION
		/* DECLARE THE REQUIRED VARIABLES */
		DECLARE @PK_Distributor INT
		DECLARE @PK_Locale INT
		DECLARE @PK_DefaultLocale INT
		DECLARE	@COP CHAR (2) = NULL

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
		IF EXISTS (SELECT [PK_EventEventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 1 AND PK_Event = @PK_Event)
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
		IF EXISTS (SELECT [PK_EventEventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 2 AND PK_Event = @PK_Event)
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
		IF EXISTS (SELECT [PK_EventEventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 3 AND PK_Event = @PK_Event)
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
		IF EXISTS (SELECT [PK_EventEventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event)
		BEGIN
		/* DECLARE A TEMP TABLE TO DISPLAY THE VOLUME DETAILS PER THE REQUIREMENT */
		IF OBJECT_ID('tempdb..#ASPQualDateDetails') IS NOT NULL DROP TABLE #ASPQualDateDetails
		IF OBJECT_ID('tempdb..#VolumePeriod') IS NOT NULL DROP TABLE #VolumePeriod

		DECLARE @CurrentDate DATETIME = DATEADD(mm,DATEDIFF(mm,0,GETDATE()),0)
		,@Begin DATETIME = '2015-01-01'
		,@End DATETIME = '2015-12-01'
		,@SQL VARCHAR(MAX) = ''
		,@1Stone DATETIME
		,@2Stone DATETIME
		,@3Stone DATETIME
		,@4Stone DATETIME
		,@5Stone DATETIME
		,@6Stone DATETIME
		,@7Stone DATETIME
		,@8Stone DATETIME
		,@9Stone DATETIME
		,@10Stone DATETIME
		,@Total1Stone INT
		,@Total2Stone INT
		,@Total3Stone INT
		,@Total4Stone INT
		,@Total5Stone INT
		,@Total6Stone INT
		,@Total7Stone INT
		,@Total8Stone INT
		,@Total9Stone INT
		,@Total10Stone INT


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
			,Stone4 DATETIME DEFAULT NULL 
			,Stone5 DATETIME DEFAULT NULL 
			,Stone6 DATETIME DEFAULT NULL 
			,Stone7 DATETIME DEFAULT NULL 
			,Stone8 DATETIME DEFAULT NULL 
			,Stone9 DATETIME DEFAULT NULL 
			,Stone10 DATETIME DEFAULT NULL  
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
		WHERE sDistributorCountryProcessingCode IN ('GE')
		AND
			nDistributorID = @PK_Distributor


		/***********************************************
			UPDATE Volume Points & Royalty Overrides
		***********************************************/
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


		IF @COP IS NOT NULL
		BEGIN 	
			/************************************************************
				UPDATE Qualified Column from #ASPQualDateDetails per Level
			*************************************************************/
			UPDATE
				SP
			SET
				 ActiveSP = ASP.AcviteSupervisor_QualDate 
				,Stone1 = ASP.Stone1_QualDate 
				,Stone2 = ASP.Stone2_QualDate 
				,Stone3 = ASP.Stone3_QualDate 
				,Stone4 = ASP.Stone4_QualDate  
				,Stone5 = ASP.Stone5_QualDate 
				,Stone6 = ASP.Stone6_QualDate  
				,Stone7 = ASP.Stone7_QualDate 
				,Stone8 = ASP.Stone8_QualDate 
				,Stone9 = ASP.Stone9_QualDate  
				,Stone10 = ASP.Stone10_QualDate
				,@1Stone = ASP.Stone1_QualDate
				,@2Stone = ASP.Stone2_QualDate
				,@3Stone = ASP.Stone3_QualDate
				,@4Stone = ASP.Stone4_QualDate  
				,@5Stone = ASP.Stone5_QualDate
				,@6Stone = ASP.Stone6_QualDate  
				,@7Stone = ASP.Stone7_QualDate
				,@8Stone = ASP.Stone8_QualDate
				,@9Stone = ASP.Stone9_QualDate  
				,@10Stone = ASP.Stone10_QualDate 
				,@Total1Stone = ASP.TotalStone1
				,@Total2Stone = ASP.TotalStone2
				,@Total3Stone = ASP.TotalStone3
				,@Total4Stone = ASP.TotalStone4
				,@Total5Stone = ASP.TotalStone5
				,@Total6Stone = ASP.TotalStone6
				,@Total7Stone = ASP.TotalStone7
				,@Total8Stone = ASP.TotalStone8
				,@Total9Stone = ASP.TotalStone9
				,@Total10Stone = ASP.TotalStone10
			FROM
				#ASPQualDateDetails SP
			INNER JOIN
				dbo.WRK_EMEAActiveSPPromo2015_ThreeLines ASP WITH (NOLOCK) 
			ON
				SP.PK_Distributor = ASP.PK_Distributor
			WHERE
				ASP.IsStar1 = 1
	
			/************************************************************
				UPDATE Total ASP based on the qual month
			*************************************************************/
			UPDATE
				T
			SET
				T.TotalASP = @Total1Stone
			FROM	
				#VolumePeriod T
			WHERE
				T.VolumeMonth = DATEADD(MM,-1,@1Stone)
	
			UPDATE
				T
			SET
				T.TotalASP = @Total2Stone
			FROM	
				#VolumePeriod T
			WHERE
				T.VolumeMonth = DATEADD(MM,-1,@2Stone)
		
			UPDATE
				T
			SET
				T.TotalASP = @Total3Stone
			FROM	
				#VolumePeriod T
			WHERE
				T.VolumeMonth = DATEADD(MM,-1,@3Stone)
		
			UPDATE
				T
			SET
				T.TotalASP = @Total4Stone
			FROM	
				#VolumePeriod T
			WHERE
				T.VolumeMonth = DATEADD(MM,-1,@4Stone)
		
			UPDATE
				T
			SET
				T.TotalASP = @Total5Stone
			FROM	
				#VolumePeriod T
			WHERE
				T.VolumeMonth = DATEADD(MM,-1,@5Stone)
		
			UPDATE
				T
			SET
				T.TotalASP = @Total6Stone
			FROM	
				#VolumePeriod T
			WHERE
				T.VolumeMonth = DATEADD(MM,-1,@6Stone)
		
			UPDATE
				T
			SET
				T.TotalASP = @Total7Stone
			FROM	
				#VolumePeriod T
			WHERE
				T.VolumeMonth = DATEADD(MM,-1,@7Stone)
		
			UPDATE
				T
			SET
				T.TotalASP = @Total8Stone
			FROM	
				#VolumePeriod T
			WHERE
				T.VolumeMonth = DATEADD(MM,-1,@8Stone)
		
			UPDATE
				T
			SET
				T.TotalASP = @Total9Stone
			FROM	
				#VolumePeriod T
			WHERE
				T.VolumeMonth = DATEADD(MM,-1,@9Stone)
		
			UPDATE
				T
			SET
				T.TotalASP = @Total10Stone
			FROM	
				#VolumePeriod T
			WHERE
				T.VolumeMonth = DATEADD(MM,-1,@10Stone)
	
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
			,Stone1
			,Stone2
			,Stone3
			,Stone4 
			,Stone5
			,Stone6 
			,Stone7
			,Stone8
			,Stone9 
			,Stone10
			,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4) [EventTrackingPageSectionName]
			,(SELECT TrackingPageSectionDisplayOrder FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event) [DisplayOrder] 
		FROM #ASPQualDateDetails



		END	

		/* NUMBER 5: MAKE SURE WE GET THE EVENT RULES SECTION IF IT IS REQUIRED */ 
		IF EXISTS (SELECT [PK_EventEventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 5)
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
		IF EXISTS (SELECT [PK_EventEventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 6 AND PK_Event = @PK_Event)
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
		IF EXISTS (SELECT [PK_EventEventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 7 AND PK_Event = @PK_Event)
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
			dbo.EventEventTrackingPageSection EETP (NOLOCK)
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
		IF EXISTS (SELECT [PK_EventEventTrackingPageSection] FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 8 AND PK_Event = @PK_Event)
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
		RETURN 
	END CATCH

/* END THE PROCEDURE */
END
GO

