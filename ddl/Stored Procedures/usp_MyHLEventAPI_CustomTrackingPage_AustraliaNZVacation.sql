CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_AustraliaNZVacation]
	-- Mandatory parameters
	 @PK_Event INT = 6540
	,@LocaleCode CHAR(5)
	-- Optional Parameters
	,@DistributorID VARCHAR(10) = '05480674'
	-- Error Parameters
	,@Error INT = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_AustraliaNZVacation

USE:	        
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_AustraliaNZVacation
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 60593
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
2   2018-03-15  Juan		NZ vacation 2018

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

SET @Error = @Error + @@ERROR

IF OBJECT_ID('tempdb..#MBDetails') IS NOT NULL DROP TABLE #MBDetails

-- Creating temp table 
CREATE TABLE #MBDetails
(
	PK_Distributor INT NOT NULL
	,IsAWTQualified BIT DEFAULT 0   
	,TotalDownlineAWT INT DEFAULT 0  
	,IsTAB BIT DEFAULT 0
	,AWTBonus INT DEFAULT 0  
	,ROBaseline MONEY DEFAULT 0
	,HighestRO MONEY DEFAULT 0
	,ROBonus MONEY DEFAULT 0
	,AccumulatedTVP MONEY DEFAULT 0
	,AccumulatedRO MONEY DEFAULT 0
	,TotalTVP MONEY DEFAULT 0
)


IF @PK_Event = 6540
BEGIN
	--Getting the MB info from WRK_HerbalifeHonorsMar2016 
	INSERT #MBDetails
	(
		 PK_Distributor
		,IsAWTQualified  
		,TotalDownlineAWT
		,AWTBonus
		,ROBaseline
		,HighestRO
		,ROBonus
		,AccumulatedTVP
		,AccumulatedRO
	)
	SELECT 
		 PK_Distributor 
		,IsAWT
		,AWTBonus/10000
		,AWTBonus
		,ROBaseline
		,HighestRO
		,ROBonus
		,AccumulatedTVP
		,AccumulatedRO
	FROM 
		dbo.WRK_ASVacation2017 WITH(NOLOCK)
	WHERE
		PK_Distributor = @PK_Distributor



	/**********************************************
		SELECT DATA TO THIRD GRID
	**********************************************/
	SELECT DISTINCT 
		 IsAWTQualified  
		,TotalDownlineAWT
		,AWTBonus
		,ROBaseline
		,HighestRO
		,ROBonus
		,AccumulatedTVP
		,AccumulatedRO
		,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection (NOLOCK) WHERE PK_EventTrackingPageSection = 4) [EventTrackingPageSectionName]
		,(SELECT TrackingPageSectionDisplayOrder FROM dbo.EventEventTrackingPageSection (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event) [DisplayOrder] 
	FROM 
		#MBDetails
END
ELSE IF @PK_Event = 6929
BEGIN
	--Getting the MB info from WRK_HerbalifeHonorsMar2016 
	INSERT #MBDetails
	(
		 PK_Distributor
		,IsAWTQualified  
		,IsTAB
		,TotalDownlineAWT
		,AWTBonus
		,AccumulatedTVP
		,TotalTVP
	)
	SELECT 
		 PK_Distributor 
		,IsAWT
		,IsTAB
		,AWTBonus/10000
		,AWTBonus
		,AccumulatedTVP
		,TotalTVP
	FROM 
		dbo.WRK_NZVacation2017 WITH(NOLOCK)
	WHERE
		PK_Distributor = @PK_Distributor



	/**********************************************
		SELECT DATA TO THIRD GRID
	**********************************************/
	SELECT DISTINCT 
		 IsAWTQualified  
		,IsTAB
		,TotalDownlineAWT
		,AWTBonus
		,AccumulatedTVP
		,TotalTVP AS [TotalTVPforPT]
		,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection (NOLOCK) WHERE PK_EventTrackingPageSection = 4) [EventTrackingPageSectionName]
		,(SELECT TrackingPageSectionDisplayOrder FROM dbo.EventEventTrackingPageSection (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event) [DisplayOrder] 
	FROM 
		#MBDetails
END
ELSE IF @PK_Event = 60593
BEGIN
/*****************
NZ Vacation 2018
****************/
	INSERT INTO #MBDetails 
	(
		PK_Distributor
		,IsAWTQualified
		,IsTAB
	)

	SELECT
		nDistributorID
		,CASE WHEN AWTYEAR IS NOT NULL THEN 1 ELSE 0 END --IsAWT
		,CASE WHEN sTeam IN ('G','M','A','B','C','P') THEN 1 ELSE 0 END --TAB
	FROM	
		v_Distributor D
	LEFT JOIN
		PubEvents.dbo.AWT A
	ON
		nDistributorID = A.PK_Distributor
		AND
		AWTYear = 2018
	WHERE
		d.nDistributorID = @PK_Distributor

	UPDATE Q SET TotalDownlineAWT = Total 
	FROM #MBDetails Q
	INNER JOIN
	(
		SELECT
			DL.PK_Distributor, COUNT(1) AS Total
		FROM 
			PubEvents.dbo.dimDSLngDownline_wBlock DL WITH(NOLOCK)
		JOIN
			v_Distributor DS
		ON
			DL.PK_DSDownline = DS.nDistributorID
		JOIN
			dbo.EventQualifier EQ (Nolock) 
		ON  
			PK_DSDownline = EQ.PK_Distributor
		WHERE 
			DSLevelFromUL = 2 
			AND
			EQ.PK_Event = 58723 --17138- NZ MAP Promo
			AND
			EQ.Qualified = 1
			AND 
			DS.dSupervisorQualification BETWEEN '2017-09-01' AND '2018-08-01'
		GROUP BY 
			Dl.PK_Distributor
	) A ON Q.PK_Distributor = A.PK_Distributor


	UPDATE Q 
	SET 
		AccumulatedTVP = agg + ISNULL(DblPoints,0)
	FROM #MBDetails Q INNER JOIN 
	(
		SELECT nDistributorID ,SUM(mVolumePoints) agg 
		FROM v_aggFQS_ID 
		WHERE dRoyaltyMonth BETWEEN '2017-09-01' AND '2018-08-01'     
		GROUP BY nDistributorID    
	) M
	ON PK_Distributor = nDistributorID
	LEFT JOIN
	(
		SELECT nDistributorID, CASE WHEN mVolumePoints >= 5000 THEN 5000 ELSE mVolumePoints END AS DblPoints      
		FROM  v_aggFQS_ID
		WHERE droyaltymonth = '2017-09-01'
	) D
    ON  PK_Distributor = D.nDistributorID


	UPDATE #MBDetails
	SET TotalTVP = AccumulatedTVP  +  CASE WHEN IsAWTQualified = 1 THEN 10000 ELSE 0 END + isNull(TotalDownlineAWT*2000,0)

	SELECT  
		 IsAWTQualified  
		,IsTAB
		,TotalDownlineAWT
		, CASE WHEN IsAWTQualified = 1 THEN 10000 ELSE 0 END AWTBonus
		,AccumulatedTVP
		,TotalTVP AS [TotalTVPforPT]
		,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection (NOLOCK) WHERE PK_EventTrackingPageSection = 4) [EventTrackingPageSectionName]
		,(SELECT TrackingPageSectionDisplayOrder FROM dbo.EventEventTrackingPageSection (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event) [DisplayOrder] 
	FROM 
		#MBDetails
	
END
ELSE

		SELECT DISTINCT 
		 IsAWTQualified  
		,IsTAB
		,TotalDownlineAWT
		,AWTBonus
		,AccumulatedTVP
		,TotalTVP AS [TotalTVPforPT]
		,(SELECT EventTrackingPageSectionName FROM dbo.EventTrackingPageSection (NOLOCK) WHERE PK_EventTrackingPageSection = 4) [EventTrackingPageSectionName]
		,(SELECT TrackingPageSectionDisplayOrder FROM dbo.EventEventTrackingPageSection (NOLOCK) WHERE PK_EventTrackingPageSection = 4 AND PK_Event = @PK_Event) [DisplayOrder] 
	FROM 
		#MBDetails		


COMMIT TRANSACTION

/* END THE PROCEDURE */
END