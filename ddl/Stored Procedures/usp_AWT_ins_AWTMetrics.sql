CREATE PROCEDURE [dbo].[usp_AWT_ins_AWTMetrics]
	@AWTYear int
	,@AWTStartMonth smalldatetime
	,@AWTEndMonth smalldatetime
	,@RoyaltyMonth smalldatetime
	,@IsDevQA int 
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_AWT_ins_AWTMetrics

USE:			dbo.usp_AWT_ins_AWTMetrics
					@AWTYear = 2009
					,@AWTStartMonth = '2009-01-01'
					,@AWTEndMonth = '2009-12-01'
					,@RoyaltyMonth = '2010-12-01'
					,@IsDevQA = 1

DESCRIPTION:	populates AWT_Metrics from aggregation


DEPENDENCIES
--------------------------------------------------------------------
everything

VERSIONS
--------------------------------------------------------------------
1	2010-01-05	Scott			Initial
2   2013-02-01  Emi				Add AWTYear population
3   2018-04-03	Ini				Added code to only use PV as TV for China
4   2019-05-17  Ini				Added code specifically for China such that prior to 2019-03-01 TV = GV, else TV=PV+GV due to China's adoption of QS volume from March 2019 
5   2020-07-07	Emi				Populate AWT_PrevQualifiers from dbo.AWT
6	2025-06-19	alejandramed	Including VN regulation, only local volume must be consider for AWT recognition
7	2025-07-17	alejandramed	Bug 1421460: 25072 - AWT 2025 - Qualifications SAMCAM/MX -- Duplication of TVP and RO in divorce cases
8	2026-02-12	alejandramed	Handle the promotion exclusively for the participating countries.
9	2026-03-04	alejandramed	Reverts to the pre–Greater China logic 
10	2026-04-21	alejandramed	Revert this change on v8: Handle the promotion exclusively for the participating countries.
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @EndMonth smalldatetime

/******************************************************************************
	set end month of date range to look at
******************************************************************************/
SET @EndMonth = CASE WHEN @RoyaltyMonth > @AWTEndMonth THEN @AWTEndMonth ELSE @RoyaltyMonth END

/******************************************************************************
	backup AWT_Qualifiers table for the current AWT Year
******************************************************************************/
TRUNCATE TABLE dbo.AWT_PrevQualifiers

INSERT INTO dbo.AWT_PrevQualifiers(
	PK_AWT_Qualifiers
	,CreatedDateUTC
	,CreatedBy
	,Flg1
	,AWTYear
	,PK_Distributor
	,DistributorID
	,DateAdded
	,Qual_AWT
	,PastAWT
	)
SELECT
	PK_AWT
	,CreatedDateUTC
	,CreatedBy
	,Flg1
	,AWTYear
	,PK_Distributor
	,DistributorID
	,DateAdded
	,Qual_AWT
	,PastAWT
FROM
	dbo.AWT (NOLOCK)
WHERE
	AWTYear = @AWTYear 

/******************************************************************************
	truncate metrics table
******************************************************************************/
TRUNCATE TABLE dbo.AWT_Metrics

/******************************************************************************
	get metrics from aggregation
	get anyone is not a divorce
	get anyone is a divorce but not the main id
******************************************************************************/

DROP TABLE IF EXISTS #AWTMetrics

SELECT
	F.nDistributorID
	,D.sDistributorID
	,F.sCOP
	,F.nIsAssocType23
	,F.dQual_SP
	,F.dRoyaltyMonth
	,CASE WHEN D.sDistributorCountryProcessingCode <> 'CN' 
			THEN IIF(F.sCOP = 'VN' AND F.dRoyaltyMonth >= '2025-02-01', mVolumePointsLocal, --Local Volume for VN after Feb 2025
				F.mVolumePoints - ISNULL(f.mGCAssocVolumePoints,0)) -- Personal Volume TV for non CN
	      WHEN D.sDistributorCountryProcessingCode = 'CN'  AND F.dRoyaltyMonth >= '2019-03-01' 
			THEN  F.mVolumePoints - ISNULL(f.mGCAssocVolumePoints,0)  -- Personal Volume TV for CN after Mar 2019
	 ELSE F.mPersonalVolume END AS [TV]
	,IIF(F.sCOP = 'VN', mRoyaltyOverridesLocal + mMainRoyaltyOverridesLocal, -- Local RO for VN
		(F.mRoyaltyOverrides - ISNULL(mGCAssocRoyaltyOverrides,0)   --WW Personal RO
		+ F.mMainRoyaltyOverrides))  AS [RO]
INTO #AWTMetrics
FROM  [dbo].[v_aggDSFinancial] F 
INNER JOIN
	dbo.v_Distributor D
	ON
		F.nDistributorID = D.nDistributorID
WHERE F.dRoyaltyMonth BETWEEN @AWTStartMonth AND @EndMonth
		AND
		(
			F.nMainIsType23 = 0
			OR
				(
					F.nMainIsType23 = 1
					AND F.nIsMainID = 0
				)
		)

CREATE INDEX IX_#AWTMetrics_nDistributorID ON #AWTMetrics(nDistributorID)

DROP TABLE IF EXISTS #PeriodMonths

SELECT  DISTINCT
	StartDate AS [RoyaltyMonth]
INTO #PeriodMonths
FROM [dbo].[ufn_GetPeriods](@AWTStartMonth,@EndMonth,1,1,0)

DROP TABLE IF EXISTS #DS

SELECT DISTINCT nDistributorID,sDistributorID 
INTO #DS
FROM #AWTMetrics

DROP TABLE IF EXISTS #DSPeriodMonths

SELECT DISTINCT
	nDistributorID,
	sDistributorID,
	p.RoyaltyMonth
INTO #DSPeriodMonths 
FROM #PeriodMonths AS p
CROSS APPLY #DS AS d
 
CREATE INDEX IX_#DSPeriodMonths_nDistributorID ON #DSPeriodMonths(nDistributorID)

DROP TABLE IF EXISTS #AWTMetricsPeriodMonths

SELECT 
	m.nDistributorID,	
	m.sDistributorID,	
	IIF(mm.nDistributorID IS NULL,d.sDistributorCountryProcessingCode, sCOP) AS sCOP,	
	IIF(mm.nDistributorID IS NULL, 0, mm.nIsAssocType23) AS nIsAssocType23,	
	IIF(mm.nDistributorID IS NULL,d.dSupervisorQualification,dQual_SP) AS dQual_SP,
	IIF(mm.nDistributorID IS NULL,m.RoyaltyMonth,mm.dRoyaltyMonth) AS RoyaltyMonth,
	IIF(mm.nDistributorID IS NULL,0,TV) AS TV,	
	IIF(mm.nDistributorID IS NULL,0,RO) AS RO,
	IIF(mm.nDistributorID IS NULL,1,0) AS AddedManually
INTO #AWTMetricsPeriodMonths
FROM #DSPeriodMonths AS m
	INNER JOIN v_DistributorCurrent AS d
		ON m.nDistributorID = d.nDistributorID
	LEFT JOIN #AWTMetrics AS mm
		ON m.RoyaltyMonth = mm.dRoyaltyMonth
		AND m.nDistributorID = mm.nDistributorID 
 
CREATE INDEX IX_#AWTMetricsPeriodMonths_nDistributorID ON #AWTMetricsPeriodMonths(nDistributorID)

INSERT
	dbo.AWT_Metrics
(
	PK_Distributor
	,DistributorID
	,COP
	,isType23
	,Qual_SP
	,RoyaltyMonth
	,TV
	,RO
	,AWTYear
)
SELECT  p.nDistributorID
	,p.sDistributorID
	,p.sCOP
	,p.nIsAssocType23
	,p.dQual_SP
	,p.RoyaltyMonth
	,ISNULL([TV],0) AS [TV]
	,ISNULL([RO],0) AS [RO]
	,@AWTYear AS [AWTYear]
  FROM #AWTMetricsPeriodMonths AS p

/******************************************************************************
	end procedure
******************************************************************************/
END