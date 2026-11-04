CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMSPPromo15]
	-- Mandatory parameters
	 @PK_Event INT = 1222
	,@LocaleCode CHAR(5) -- = 'en-us'
	-- Optional Parameters
	,@DistributorID VARCHAR(10) -- = '100705265'

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMSPPromo15

USE:	        
				DECLARE @e int, @em varchar(4000)
                EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMSPPromo15
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 1222
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
1	2013-02-06	OrlandoL		Intitial
1.1 2016-09-20  SandhyaP		Change the dates and Qualified for Downline
1.2 2016-10-17  Juan			Tunned
1.3	2019-08-14	NoeG			Refactor code (SRE)
1.4 2019-10-17	alejandramed	SRE Compliance 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
	,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	BEGIN TRANSACTION
		/* DECLARE THE REQUIRED VARIABLES */
		DECLARE @PK_Distributor INT
		DECLARE @PK_Locale INT
		DECLARE @PK_DefaultLocale INT
		DECLARE	@COP CHAR (2) = NULL
		DECLARE @MonthName VARCHAR(10)
		DECLARE @sql1 NVARCHAR(MAX) = ''
		DECLARE @Column1 VARCHAR(10) = ''
		DECLARE @Column2 VARCHAR(10) = ''

		/* SET THE VALUES FOR THE DECLARED VARIABLES */

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH(NOLOCK) WHERE PK_Event = @PK_Event

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
		IF EXISTS (SELECT PK_EventTrackingPageSection FROM dbo.EventEventTrackingPageSection WITH(NOLOCK) WHERE PK_EventTrackingPageSection = 1 AND PK_Event = @PK_Event)
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
		IF EXISTS (SELECT PK_EventTrackingPageSection FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 2 AND PK_Event = @PK_Event)
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
		IF EXISTS (SELECT PK_EventTrackingPageSection FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 3 AND PK_Event = @PK_Event)
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
		IF EXISTS (SELECT PK_EventTrackingPageSection FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event)
		BEGIN
		/* DECLARE A TEMP TABLE TO DISPLAY THE VOLUME DETAILS PER THE REQUIREMENT */
		IF OBJECT_ID('tempdb..#ASPQualDateDetails') IS NOT NULL DROP TABLE #ASPQualDateDetails
		IF OBJECT_ID('tempdb..#VolumePeriod') IS NOT NULL DROP TABLE #VolumePeriod

		DECLARE @CurrentDate DATETIME = DATEADD(mm,DATEDIFF(mm,0,GETDATE()),0)
		,@Begin DATETIME = '2015-10-01'
		,@End DATETIME = '2016-12-01'
		,@SQL VARCHAR(MAX) = ''
		,@3Stone DATETIME
		,@5Stone DATETIME
		,@7Stone DATETIME
		,@10Stone DATETIME


		IF DATEADD(MM,-14,@CurrentDate) >= '2015-10-01'
		BEGIN
			SET @Begin	= DATEADD(MM,-13,@CurrentDate)
			SET @End	= DATEADD(MM,1,@CurrentDate)
		END

		CREATE TABLE #ASPQualDateDetails
		( 
			 ActiveSP DATETIME DEFAULT NULL 
			,Stone3 DATETIME DEFAULT NULL 
			,Stone5 DATETIME DEFAULT NULL 
			,Stone7 DATETIME DEFAULT NULL 
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


		/* INSERT PK_DS in temp tables */
		INSERT #ASPQualDateDetails
		( 
			PK_Distributor
		)
		SELECT @PK_Distributor


		/*************************************
				COP
		*************************************/

		SELECT
			@COP = sDistributorCountryProcessingCode
		FROM dbo.v_Distributor WITH (NOLOCK)
		WHERE 	nDistributorID = @PK_Distributor

		IF @COP NOT IN ('US','JM','CA','TT','PR')
			SET @COP = NULL



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
				,Stone3 = ASP.Stone3_QualDate  
				,Stone5 = ASP.Stone5_QualDate  
				,Stone7 = ASP.Stone7_QualDate  
				,Stone10 = ASP.Stone10_QualDate
				,@3Stone = ASP.Stone3_QualDate  
				,@5Stone = CASE WHEN ASP.Stone3_QualDate = ASP.Stone5_QualDate THEN NULL ELSE ASP.Stone5_QualDate END
				,@7Stone =  CASE WHEN ASP.Stone3_QualDate = ASP.Stone7_QualDate OR ASP.Stone5_QualDate = ASP.Stone7_QualDate THEN NULL ELSE ASP.Stone7_QualDate END
				,@10Stone = CASE WHEN ASP.Stone3_QualDate = ASP.Stone10_QualDate OR ASP.Stone5_QualDate = ASP.Stone10_QualDate OR ASP.Stone7_QualDate = ASP.Stone10_QualDate THEN NULL ELSE ASP.Stone10_QualDate END
			FROM
				#ASPQualDateDetails SP
			INNER JOIN
				dbo.WRK_NAMActiveSPPomo2014 ASP WITH (NOLOCK)
			ON
				SP.PK_Distributor = ASP.PK_Distributor
			WHERE
				ASP.IsStar1 = 1
	
			/************************************************************
				UPDATE Total ASP based on the qual month
			*************************************************************/
			IF @3Stone IS NOT NULL
			BEGIN
				;WITH Stone3 (PK_Distributor,QtyStone3) AS
				(
					SELECT DISTINCT
						DL.PK_Distributor,
						COUNT(1)
					FROM 
						[dbo].[v_dimDSLngDownline] DL 
					INNER JOIN
						(
							SELECT 
								nDistributorID
							FROM
								[dbo].[v_aggFQS_ID]
							WHERE
								dRoyaltyMonth BETWEEN DATEADD(mm,-3,@3Stone) AND DATEADD(mm,-1,@3Stone)
								AND
								mVolumePoints >= 2500
							GROUP BY
								nDistributorID
							HAVING 
								COUNT(1) >= 3
						) A2
					ON
						DL.PK_DSDownline = A2.nDistributorID
					WHERE 
						DL.SPLevelFromUL = 2
						AND
						DL.PK_Distributor = @PK_Distributor
					GROUP BY
						DL.PK_Distributor	  
				)
	
				UPDATE
					T
				SET
					T.TotalASP = S.QtyStone3
				FROM	
					#VolumePeriod T
				INNER JOIN
					Stone3 S
				ON
					S.PK_Distributor = T.PK_Distributor
				WHERE
					T.VolumeMonth = DATEADD(MM,-1,@3Stone)
			END

			IF @5Stone IS NOT NULL
			BEGIN
				;WITH Stone5 (PK_Distributor,QtyStone5) AS
				(
					SELECT DISTINCT
						DL.PK_Distributor,
						COUNT(1)
					FROM 
						[dbo].[v_dimDSLngDownline] DL 
					INNER JOIN
						(
							SELECT 
								nDistributorID
							FROM
								[dbo].[v_aggFQS_ID]
							WHERE
								dRoyaltyMonth BETWEEN DATEADD(mm,-3,@5Stone) AND DATEADD(mm,-1,@5Stone)
								AND
								mVolumePoints >= 2500
							GROUP BY
								nDistributorID
							HAVING 
								COUNT(1) >= 3
						) A2
					ON
						DL.PK_DSDownline = A2.nDistributorID
					WHERE 
						DL.SPLevelFromUL = 2
						AND
						DL.PK_Distributor = @PK_Distributor
					GROUP BY
						DL.PK_Distributor
				)
	
				UPDATE
					T
				SET
					T.TotalASP = S.QtyStone5
				FROM	
					#VolumePeriod T
				INNER JOIN
					Stone5 S
				ON
					S.PK_Distributor = T.PK_Distributor
				WHERE
					T.VolumeMonth = DATEADD(MM,-1,@5Stone)
			END

			IF @7Stone IS NOT NULL
			BEGIN
				;WITH Stone7 (PK_Distributor,QtyStone7) AS
				(
					SELECT DISTINCT
						DL.PK_Distributor,
						COUNT(1)
					FROM 
						[dbo].[v_dimDSLngDownline] DL 
					INNER JOIN
						(
							SELECT 
								nDistributorID
							FROM
								[dbo].[v_aggFQS_ID]
							WHERE
								dRoyaltyMonth BETWEEN DATEADD(mm,-3,@7Stone) AND DATEADD(mm,-1,@7Stone)
								AND
								mVolumePoints >= 2500
							GROUP BY
								nDistributorID
							HAVING 
								COUNT(1) >= 3
						) A2
					ON
						DL.PK_DSDownline = A2.nDistributorID
					WHERE 
						DL.SPLevelFromUL = 2
						AND
						DL.PK_Distributor = @PK_Distributor
					GROUP BY
						DL.PK_Distributor
				)
	
				UPDATE
					T
				SET
					T.TotalASP = S.QtyStone7
				FROM	
					#VolumePeriod T
				INNER JOIN
					Stone7 S
				ON
					S.PK_Distributor = T.PK_Distributor
				WHERE
					T.VolumeMonth = DATEADD(MM,-1,@7Stone)
			END

			IF @10Stone IS NOT NULL
			BEGIN
				;WITH Stone10 (PK_Distributor,QtyStone10) AS
				(
					SELECT DISTINCT
						DL.PK_Distributor,
						COUNT(1)
					FROM 
						[dbo].[v_dimDSLngDownline] DL 
					INNER JOIN
						(
							SELECT 
								nDistributorID
							FROM
								[dbo].[v_aggFQS_ID]
							WHERE
								dRoyaltyMonth BETWEEN DATEADD(mm,-3,@10Stone) AND DATEADD(mm,-1,@10Stone)
								AND
								mVolumePoints >= 2500
							GROUP BY
								nDistributorID
							HAVING 
								COUNT(1) >= 3
						) A2
					ON
						DL.PK_DSDownline = A2.nDistributorID
					WHERE 
						DL.SPLevelFromUL = 2
						AND
						DL.PK_Distributor = @PK_Distributor
					GROUP BY
						DL.PK_Distributor
				)
	
				UPDATE
					T
				SET
					T.TotalASP = S.QtyStone10
				FROM	
					#VolumePeriod T
				INNER JOIN
					Stone10 S
				ON
					S.PK_Distributor = T.PK_Distributor
				WHERE
					T.VolumeMonth = DATEADD(MM,-1,@10Stone)
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
			,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4) [EventTrackingPageSectionName]
			,(SELECT TrackingPageSectionDisplayOrder FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event) [DisplayOrder] 
		FROM #ASPQualDateDetails



		END	

		/* NUMBER 5: MAKE SURE WE GET THE EVENT RULES SECTION IF IT IS REQUIRED */ 
		IF EXISTS (SELECT PK_EventTrackingPageSection FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 5)
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
		IF EXISTS (SELECT PK_EventTrackingPageSection FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 6 AND PK_Event = @PK_Event)
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
		IF EXISTS (SELECT PK_EventTrackingPageSection FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 7 AND PK_Event = @PK_Event)
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
		IF EXISTS (SELECT PK_EventTrackingPageSection FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 8 AND PK_Event = @PK_Event)
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

		/* Number 9: SubEvents Result Set */ 
		SELECT
			 SE.PK_SubEvent
			,SE.PK_Event
			,COALESCE(CASE WHEN SD.SubEventQualDesc = '' then null ELSE SD.SubEventQualDesc END
				, CASE WHEN SED.SubEventQualDesc = '' then null ELSE SED.SubEventQualDesc END
				, SE.SubEventName) SubEventName
			,CASE WHEN SE.SubEventNumber = 1 AND T.ActiveSP IS NOT NULL THEN 1
				  WHEN SE.SubEventNumber = 2 AND T.Stone3 IS NOT NULL THEN 1
				  WHEN SE.SubEventNumber = 3 AND T.Stone5 IS NOT NULL THEN 1
				  WHEN SE.SubEventNumber = 4 AND T.Stone7 IS NOT NULL THEN 1
				  WHEN SE.SubEventNumber = 5 AND T.Stone10 IS NOT NULL THEN 1
				 ELSE 0
			 END Qualified	
			,COALESCE(CASE WHEN SD.SubEventQualDesc = '' then null ELSE SD.SubEventQualDesc END
					, CASE WHEN SED.SubEventQualDesc = '' then null ELSE SED.SubEventQualDesc END
					, SE.SubEventName) [SubEventQualDesc]
			,COALESCE(CASE WHEN SD.QualDesc = '' THEN NULL ELSE SD.QualDesc END
					, CASE WHEN SED.QualDesc = '' THEN NULL ELSE SED.QualDesc END ) [QualificiationDesc]
			,SE.PK_SubEventGroup
			,SEG.SubEventGroup [SubEventGroup]
			,SEE.Icon
			,SEE.Color
			, SE.SubEventNumber
			,CASE WHEN SE.SubEventNumber = 1 THEN T.ActiveSP
				  WHEN SE.SubEventNumber = 2 THEN T.Stone3
				  WHEN SE.SubEventNumber = 3 THEN T.Stone5
				  WHEN SE.SubEventNumber = 4 THEN T.Stone7
				  WHEN SE.SubEventNumber = 5 THEN T.Stone10
				 ELSE NULL
			 END [QualDate]	  
			,CASE WHEN SE.SubEventNumber = 1 THEN 0
				  WHEN SE.SubEventNumber = 2 THEN 3
				  WHEN SE.SubEventNumber = 3 THEN 5
				  WHEN SE.SubEventNumber = 4 THEN 7
				  WHEN SE.SubEventNumber = 5 THEN 10
				 ELSE NULL
			 END [NoOfStones]	  
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
			  dbo.SubEventGroup SEG WITH (NOLOCK)
		ON
			  SE.PK_SubEventGroup = SEG.PK_SubEventGroup
		LEFT JOIN
			  dbo.SubEventExtn SEE WITH (NOLOCK) 
		ON
			  SE.PK_SubEvent = SEE.PK_SubEvent	
			  AND
			  SE.PK_Event = SEE.PK_Event
		LEFT JOIN
			#ASPQualDateDetails T 
		ON
			T.PK_Distributor = @PK_Distributor
		WHERE
			SE.PK_Event = @PK_Event 
		AND
			SE.IsTrackingVisible = 1
		ORDER BY
			SEG.DisplayOrder, SE.SubEventNumber

		/* Number 10: Volume for Upline Result Set */ 
		SELECT
			 VolumeMonth AS Date 
			,TVP AS VolumePoints 
			,TotalASP
			,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4) [EventTrackingPageSectionName]
			,(SELECT TrackingPageSectionDisplayOrder FROM dbo.EventEventTrackingPageSection WITH (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event) [DisplayOrder] 
		FROM #VolumePeriod	
		SET @Error = @Error + @@ERROR


		/*************************************************************
			CREATE Temp Tables
		*************************************************************/
		IF OBJECT_ID ('tempDB..#Downline', 'U')IS NOT NULL DROP TABLE #Downline


		CREATE TABLE #Downline
		(
			DSLevel INT,
			PK_Distributor INT,
			DistributorID VARCHAR(30),
			LastName VARCHAR(100),
			FirstName VARCHAR(100),
			TeamLevel VARCHAR(10),
			Email VARCHAR(100),
			Phone VARCHAR(100),
			nSponsorID INT,
			SponsorID VARCHAR(30),
			SponsorName VARCHAR(100),
			RoyaltyMonth DATE,
			TVP MONEY DEFAULT 0,
			Qualified INT DEFAULT 0
		)


		/*************************************************************
			Get Information from 16002 - EMEA ASP Promo 2016 
		*************************************************************/
		INSERT INTO #Downline
		(	
			DSLevel,
			PK_Distributor,
			RoyaltyMonth,
			TVP
		)
		SELECT 
			DL.SPLevelFromUL,
			PK_DSDownline,
			dRoyaltyMonth,
			ISNULL(mVolumePoints,0) 
		FROM 
			[dbo].[v_dimDSLngDownline] DL 
		LEFT JOIN 
			dbo.v_aggFQS_ID F
			ON
				DL.PK_DSDownline = F.ndistributorID
				AND
				dRoyaltyMonth Between @Begin AND @End
		WHERE 
			DL.PK_Distributor = @PK_Distributor
			AND
			DL.SPLevelFromUL = 2


		CREATE INDEX IX_#Downline_nDistributorID ON #Downline(PK_Distributor)





		UPDATE DL
		SET 
			DistributorID = sDistributorID,
			LastName = sLastName,
			FirstName = [sFirstName],
			Email = [sEmail],
			DL.Phone = VD.[Phone],
			TeamLevel = ISNULL(sTeam,sType),
			DL.nSponsorID = vD.[nSponsorID]
		FROM
			#Downline DL
		INNER JOIN
			[dbo].[v_Distributor] vD
			ON 
			DL.PK_Distributor = vD.[nDistributorID]

		UPDATE DL
		SET
		  SponsorID = sDistributorID, 
		  SponsorName = [sFirstName] + [sLastName]
		FROM
			#Downline DL
		INNER JOIN
			[dbo].[v_Distributor] vD
			ON 
			DL.nSponsorID = vD.[nDistributorID]

		/******************************************************************************
			  update Qualification
		******************************************************************************/

		UPDATE DL
		SET 
			Qualified = 1
		FROM
			#Downline DL
		INNER JOIN
			dbo.EventQualifier Q 
			ON
			Q.PK_Distributor = DL.PK_Distributor
		WHERE 
			Q.PK_Event =  @PK_Event

		--SET STATISTICS IO OFF

		SELECT 
			DSLevel-1 AS DSLevel,
			D.DistributorID,
			LastName,
			FirstName,
			TeamLevel,
			Email,
			Phone,
			SponsorID,
			SponsorName,
			RoyaltyMonth,
			TVP,
			Qualified
		FROM 
			#Downline D
		
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
	RETURN 
END CATCH;

/* END THE PROCEDURE */
END
GO

