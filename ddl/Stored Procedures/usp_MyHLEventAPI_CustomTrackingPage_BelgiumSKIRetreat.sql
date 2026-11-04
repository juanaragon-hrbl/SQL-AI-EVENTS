CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_BelgiumSKIRetreat]
-- Mandatory parameters

	 @PK_Event INT = 2730
	,@LocaleCode CHAR(5)
	-- Optional Parameters
	,@DistributorID VARCHAR(10)
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_BelgiumSKIRetreat

USE:	        
				DECLARE @e int, @em varchar(4000)
			
                EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_BelgiumSKIRetreat
					 	 @DistributorID = N'3110350563'
					 	,@PK_Event = 2730
						,@LocaleCode = 'en-US'
						,@Error = @e OUTPUT
						,@ErrorMessage = @em OUTPUT
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	This is a custom stored procedure that retreievs all the details for the 
                Belgium Ski Retreat Promotion based on the sections defined for the Tracking Page.
                The sections are specific to every event based on what the region decides
                to display on the tracking page

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.Subevent, dbo.EventLocaleADesc, dbo.SubeventLocaleDesc, 
dbo.EventTrackingPageSection,
dbo.EventEventTrackingPageSection
dbo.wrk_BelgiumSKIRetreat2016
dbo.SubEventQualifer

VERSIONS
----------------------------------------------------------------------------------
1	2015-03-01	Juan	Intitial
2	2019-09-30	NoeG	SRE template applied
3	2019-10-30	NoeG	SRE Hardcode changed

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	/* DECLARE THE REQUIRED VARIABLES */
	DECLARE @PK_Distributor INT
	DECLARE @PK_Locale INT
	DECLARE @PK_DefaultLocale INT
	DECLARE @COP VARCHAR(5)

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'	

	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		/* SET THE VALUES FOR THE DECLARED VARIABLES */

		SELECT @PK_Distributor = nDistributorID, @COP = sDistributorCountryProcessingCode FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
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
			dbo.EventEventTrackingPageSection EETP (NOLOCK)
		INNER JOIN
			dbo.EventTrackingPageSection ETP (NOLOCK)
		ON
			EETP.PK_EventTrackingPageSection = ETP.PK_EventTrackingPageSection
		INNER JOIN
			dbo.Event E (NOLOCK)
		ON
			EETP.PK_Event = E.PK_Event
		WHERE
			EETP.PK_Event = @PK_Event

		/* NUMBER 1: MAKE SURE WE GET THE EVENTIMAGEHEADER DETAILS SECTION IF IT IS REQUIRED */
		SELECT
			 EI.PK_Event
			,EI.PK_EventImageType
			,EIT.EventImageType
			,ISNULL(EI.EventImageLocation,'') [EventImageLocation]
			,'EventImageHeader' [EventTrackingPageSectionName]
			,1 [DisplayOrder]	
		FROM
			dbo.EventImage EI (NOLOCK)
		INNER JOIN
			dbo.EventImageType EIT (NOLOCK)
		ON
			EI.PK_EventImageType = EIT.PK_EventImageType
		WHERE
			EI.PK_Event = @PK_Event

		/* EVENTDESCRIPTION DETAILS */
		SELECT
			 E.PK_Event
			,ISNULL(ED.EventName,E.EventName) [EventName]
			,ISNULL(ED.EventDesc,E.EventDesc) [EventDesc]
			,ISNULL(ED.EventSummary,E.EventCostDetails) [EventSummary]
			,'EventDescription' [EventTrackingPageSectionName]	
			,2 [DisplayOrder]
		FROM
			dbo.Event E (NOLOCK)
		LEFT JOIN
			dbo.EventLocaleDesc ED (NOLOCK)
		ON
			ED.PK_Event = E.PK_Event
			AND ED.PK_Locale = @PK_Locale
		WHERE
			E.PK_Event = @PK_Event


		/* SELECT THE SUBEVENT QUALIFICATIONS FOR THE DISTRIBUTORID FOR THE PASSED PK_EVENT */

		SELECT
			 SE.PK_SubEvent
			,SE.PK_Event
			,SD.SubEventName
			,ISNULL(SQ.Qualified,0) Qualified
			,'SubEvent' [EventTrackingPageSectionName]
			,3 [DisplayOrder]
		FROM
			dbo.SubEvent SE (NOLOCK)
		LEFT JOIN
			dbo.SubeventLocaleDesc SD WITH (NOLOCK)
		ON
			SE.PK_Event = SD.PK_Event
			AND SE.PK_SubEvent = SD.PK_Subevent
		LEFT JOIN
			dbo.SubEventQualifier SQ (NOLOCK)
		ON
			SQ.PK_Event = SE.PK_Event
			AND SQ.PK_SubEvent = SE.PK_SubEvent
			AND SQ.RemovedUTC = @ValidDate
			AND SQ.Qualified = 1
			AND SQ.DistributorID = @DistributorID
		WHERE
			SE.PK_Event = @PK_Event 
		AND 
			SD.PK_Locale = @PK_Locale



		/* VACATION DETAILS */

		/* DECLARE A TEMP TABLE TO DISPLAY THE VOLUME DETAILS PER THE REQUIREMENT */
		IF OBJECT_ID('tempdb..#TempTrackerDetails') IS NOT NULL DROP TABLE #TempTrackerDetails

		/* STORE Traker details from RPT source Table */
		SELECT *
		INTO #TempTrackerDetails
		FROM 
			dbo.wrk_BelgiumSKIRetreat2016 WITH (NOLOCK)
		WHERE
			PK_Distributor = @PK_Distributor	

		IF @@ROWCOUNT = 0 
			INSERT INTO #TempTrackerDetails (PK_Distributor) VALUES (-1)

		/* VOLUME TABLE */
		SELECT
			JanTVP, 
			FebTVP,
			MarTVP, 
			AprTVP,
			MayTVP, 
			JunTVP,
			JulTVP,
			AugTVP, 
			SepTVP, 
			OctTVP, 
			NovTVP, 
			DecTVP
		FROM
			#TempTrackerDetails

	

		/* PPV TABLE */

		SELECT
			JanPPV 
			,FebPPV
			,MarPPV
			,AprPPV
			,MayPPV
			,JunPPV
			,JulPPV
			,AugPPV
			,SepPPV
			,OctPPV
			,NovPPV
			,DecPPV
		FROM #TempTrackerDetails	
	

		--/* VACATION POINTS */
		SELECT 
			PK_Distributor,
			CASE 
				WHEN LifeCycleLevel >=  12 THEN 'PT20k' 
				WHEN LifeCycleLevel >= 6 THEN 'TAB' 
				WHEN Qual_FQS IS NOT NULL THEN 'FQS' END TEAM, 
			Qual_AWT,
			Qual_FQS,
			CASE WHEN YEAR([Qual_FQS]) = 2015 THEN Months1500PPV + MONTH([Qual_FQS]) -1 ELSE Months1500PPV END Months1500PPV,
			ISNULL(YearTVP, 0) + ISNULL(Level1Bonus, 0) + ISNULL(Level23Bonus, 0) [YearTVP],
			case when YEAR([Qual_FQS]) = 2015 THEN MONTH('2015-12-31') - MONTH(Qual_FQS) - Months1500PPV + 1--(CASE WHEN MONTH([Qual_FQS]) = 12 THEN 1 ELSE 0 END) 
				else (12 - Months1500PPV) end MonthsFor1500PPV,
			CASE WHEN (LifeCycleLevel>= 6 AND ((72000 - ISNULL(Level1Bonus, 0) - ISNULL (Level23Bonus, 0) - ISNULL(YearTVP, 0)) <= 72000) AND ((72000 - ISNULL(Level1Bonus, 0) - ISNULL (Level23Bonus, 0) - ISNULL(YearTVP, 0)) >= 0)) THEN (72000 - ISNULL(Level1Bonus, 0) - ISNULL (Level23Bonus, 0) - ISNULL(YearTVP, 0)) 
				 WHEN (LifeCycleLevel>= 4 AND ((60000 - ISNULL(Level1Bonus, 0) - ISNULL (Level23Bonus, 0) - ISNULL(YearTVP, 0)) <= 60000) AND ((60000 - ISNULL(Level1Bonus, 0) - ISNULL (Level23Bonus, 0) - ISNULL(YearTVP, 0)) >= 0)) THEN (60000 - ISNULL(Level1Bonus, 0) - ISNULL (Level23Bonus, 0) - ISNULL(YearTVP, 0)) 
				 ELSE 0 END [VPTBAchieved],
			(ISNULL(Level1StarsNew, 0) + ISNULL(Level2StarsNew, 0) + ISNULL(Level3StarsNew, 0)) [StarsNew],
			(ISNULL(Level1StarsRepeat, 0) + ISNULL(Level2StarsRepeat, 0) + ISNULL(Level3StarsRepeat, 0)) [StarsRepeat],
			((ISNULL(Level1StarsNew, 0) + ISNULL(Level2StarsNew, 0) + ISNULL(Level3StarsNew, 0)) * 6000) [NewBonusPnts],
			((ISNULL(Level1StarsRepeat, 0) + ISNULL(Level2StarsRepeat, 0) + ISNULL(Level3StarsRepeat, 0)) * 3000) [RepeatBonusPnts],
			CASE WHEN (Level1StarsNew >=1 OR Level2StarsNew >=1  OR Level3StarsNew >= 1) THEN 1 ELSE 0 END [FirstAWT],
			CASE 
				WHEN Qualified = 1 THEN 1
				WHEN YEAR([Qual_FQS]) = 2015 AND Months1500PPV = (CASE WHEN YEAR(GETUTCDATE()) = 2016 THEN MONTH(GETUTCDATE())+12 ELSE MONTH(GETUTCDATE()) END - 
				CASE WHEN Months1500PPV = MONTH(GETUTCDATE())- MONTH([Qual_FQS]) THEN MONTH([Qual_FQS])+1 ELSE MONTH([Qual_FQS]) END) THEN 2		
				WHEN YEAR([Qual_FQS]) < 2015 AND (Months1500PPV = MONTH(GETUTCDATE()) OR Months1500PPV = MONTH(GETUTCDATE())-1) THEN 2
				ELSE 0 END [Qualified]
		FROM
			#TempTrackerDetails

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
	END CATCH
END