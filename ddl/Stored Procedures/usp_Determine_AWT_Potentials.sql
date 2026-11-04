CREATE PROCEDURE [dbo].[usp_Determine_AWT_Potentials]
	-- Error Parameters
	@Error INT = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_Determine_AWT_Potentials

USE:	        
                 EXEC dbo.usp_Determine_AWT_Potentials

DESCRIPTION:	This stored procedure determines people that are not yet AWT qualifiers for the current year but may 
				be close to the qualification based on their volume. Most recent 6 months activities are considered 
				starting from the previous month. Note that the consecutive volume (1500, 2000, 22000 and 25000) 
				month performances are predertined in subevents in PK_Event 720. This stored procedure is scheduled 
				to be run once a day after the qual engine completes ( or really when PK_Event 720 qualifiers 
				are determined). Note that dbo.AWT_Potentials cannot be truncated as it is going to be replicated to
				IAPRODETL.DistributorReporting

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.Subevent 
LS_SQL_BI_DB02.dbo.v_AGGFQS_ID, 
LS_SQL_BI_DB02.dbo.AWT


VERSIONS
----------------------------------------------------------------------------------
1	2012-05-30	IniU	Intitial
2   2017-06-29  Juan    Fixes
3   2017-07-18  Juan    Add Current Month metrics
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)

IF EXISTS (SELECT 1 FROM [DevAdmin].[ScheduleException] WITH (NOLOCK)
WHERE Active = 1 AND CONVERT(DATE,GETUTCDATE()) BETWEEN StartDate AND EndDate
AND TRIM(REPLACE(REPLACE([StoredProcedureName],'[',''),']','')) = TRIM(REPLACE(REPLACE(@StoredProcedure,'[',''),']','')))
BEGIN
	PRINT 'ScheduleException; The process is skipped.'
	RETURN;
END
ELSE 
BEGIN

BEGIN TRANSACTION

DECLARE @BeginMonth DATETIME = DATEADD(M,-6,CONVERT(DATETIME,CONVERT(VARCHAR(8),GETUTCDATE(),120) + '01',120))
DECLARE @EndMonth DATETIME = DATEADD(M,0,CONVERT(DATETIME,CONVERT(VARCHAR(8),GETUTCDATE(),120) + '01',120))
DECLARE @AWTYear INT = datepart(YYYY,getdate())
DECLARE @5Get5 MONEY = 5000
DECLARE @PK_AWT_AcceleratorType INT
DECLARE @M6 DATETIME = DATEADD(M,-6,CONVERT(DATETIME,CONVERT(VARCHAR(8),GETUTCDATE(),120) + '01',120))
DECLARE @M5 DATETIME = DATEADD(M,-5,CONVERT(DATETIME,CONVERT(VARCHAR(8),GETUTCDATE(),120) + '01',120))
DECLARE @M4 DATETIME = DATEADD(M,-4,CONVERT(DATETIME,CONVERT(VARCHAR(8),GETUTCDATE(),120) + '01',120))
DECLARE @M3 DATETIME = DATEADD(M,-3,CONVERT(DATETIME,CONVERT(VARCHAR(8),GETUTCDATE(),120) + '01',120))
DECLARE @M2 DATETIME = DATEADD(M,-2,CONVERT(DATETIME,CONVERT(VARCHAR(8),GETUTCDATE(),120) + '01',120))
DECLARE @M1 DATETIME = DATEADD(M,-1,CONVERT(DATETIME,CONVERT(VARCHAR(8),GETUTCDATE(),120) + '01',120))
DECLARE @M0 DATETIME = DATEADD(M,0,CONVERT(DATETIME,CONVERT(VARCHAR(8),GETUTCDATE(),120) + '01',120))
DECLARE @MinPK INT
DECLARE @MaxPK INT
DECLARE @COP   VARCHAR(2)
DECLARE @PromoMonth VARCHAR(1000)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @PK_Event INT = 720
DECLARE @PK_SubEvent1 INT
DECLARE @PK_SubEvent2 INT
DECLARE @PK_SubEvent3 INT
DECLARE @PK_SubEvent4 INT
DECLARE @PK_SubEvent5 INT
DECLARE @PK_SubEvent6 INT
DECLARE @PK_SubEvent7 INT
DECLARE @PK_SubEvent8 INT
DECLARE @PK_SubEvent9 INT
DECLARE @PK_SubEvent10 INT
DECLARE @PK_SubEvent11 INT
DECLARE @PK_SubEvent12 INT
DECLARE @PK_SubEvent13 INT
DECLARE @PK_SubEvent14 INT
DECLARE @PK_SubEvent15 INT
DECLARE @PK_SubEvent16 INT
DECLARE @PK_SubEvent17 INT
DECLARE @PK_SubEvent18 INT
DECLARE @PK_SubEvent19 INT
DECLARE @PK_SubEvent20 INT
DECLARE @RemovedUTC DATETIME = '2049-12-31'
DECLARE @ToDay DATETIME = GETUTCDATE()
DECLARE @ProcessededBy VARCHAR(30) = 'usp_AWT_Potentials'

SELECT @PK_AWT_AcceleratorType = PK_AWT_AcceleratorType FROM dbo.AWT_AcceleratorType (NOLOCK) WHERE AcceleratorType = '5-Get-5'
SELECT @AWTYear = CASE WHEN DATEPART(M,GETDATE()) = 2 AND DATEPART(D,GETDATE()) >= 14 THEN DATEPART(YEAR,GETDATE())
                       WHEN DATEPART(M,GETDATE()) > 2 THEN DATEPART(YEAR,GETDATE()) 
				  ELSE DATEPART(YEAR,GETDATE()) -1 END

IF OBJECT_ID('Tempdb..#FinalTab','U') IS NOT NULL DROP TABLE #FinalTab

CREATE TABLE #FinalTab (
	PK INT IDENTITY(1,1) PRIMARY KEY
	,PK_Distributor INT
	,DistributorID  VARCHAR(10)
	,COP VARCHAR(2)
	,IsType23 BIT DEFAULT 0
	,PromoMonths VARCHAR(1000)
	,M6_RO MONEY DEFAULT 0
	,M5_RO MONEY DEFAULT 0
	,M4_RO MONEY DEFAULT 0
	,M3_RO MONEY DEFAULT 0
	,M2_RO MONEY DEFAULT 0
	,M1_RO MONEY DEFAULT 0
	,M0_RO MONEY DEFAULT 0
	,M6_TV MONEY DEFAULT 0
	,M5_TV MONEY DEFAULT 0
	,M4_TV MONEY DEFAULT 0
	,M3_TV MONEY DEFAULT 0
	,M2_TV MONEY DEFAULT 0
	,M1_TV MONEY DEFAULT 0
	,M0_TV MONEY DEFAULT 0
	,Is1800_In1M_InL6M TINYINT DEFAULT 0
	,Is1800_In2CM_InL6M TINYINT DEFAULT 0
	,Is1800_In3CM_InL6M TINYINT DEFAULT 0
	,Is1800_In4CM_InL6M TINYINT DEFAULT 0
	,Is2000_In1M_InL6M TINYINT DEFAULT 0
	,Is2000_In2CM_InL6M TINYINT DEFAULT 0
	,Is2000_In3CM_InL6M TINYINT DEFAULT 0
	,Is2000_In4CM_InL6M TINYINT DEFAULT 0
	,Is2200_In1M_InL6M TINYINT DEFAULT 0
	,Is2200_In2CM_InL6M TINYINT DEFAULT 0
	,Is2200_In3CM_InL6M TINYINT DEFAULT 0
	,Is2200_In4CM_InL6M TINYINT DEFAULT 0
	,Is2500_In1M_InL6M TINYINT DEFAULT 0
	,Is2500_In2CM_InL6M TINYINT DEFAULT 0
	,Is2500_In3CM_InL6M TINYINT DEFAULT 0
	,Is2500_In4CM_InL6M TINYINT DEFAULT 0
	,Is2500_In1M_InL6M_0 TINYINT DEFAULT 0
	,Is2500_In2CM_InL6M_0 TINYINT DEFAULT 0
	,Is2500_In3CM_InL6M_0 TINYINT DEFAULT 0
	,Is2500_In4CM_InL6M_0 TINYINT DEFAULT 0
)

SET @Error = @Error + @@ERROR

IF OBJECT_ID('Tempdb..#RO','U') IS NOT NULL DROP TABLE #RO

CREATE TABLE #RO (
	PK int IDENTITY(1,1) PRIMARY KEY
	,PK_Distributor int
	,DistributorID  varchar(10)
	,COP varchar(2)
	,M6 MONEY DEFAULT 0
	,M5 MONEY DEFAULT 0
	,M4 MONEY DEFAULT 0
	,M3 MONEY DEFAULT 0
	,M2 MONEY DEFAULT 0
	,M1 MONEY DEFAULT 0
	,M0 MONEY DEFAULT 0
)

SET @Error = @Error + @@ERROR

SET @SQL = 'INSERT INTO #RO(PK_Distributor,DistributorID,COP,M6,M5,M4,M3,M2,M1,M0) SELECT LL.nDistributorID,LL.sDistributorID,LL.sCOP,'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M6)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M5)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M4)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M3)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M2)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M1)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M0)+'] '
SET @SQL = @SQL + 'FROM (SELECT agg.dRoyaltyMonth AS RoyaltyMonth, agg.sCOP, agg.nDistributorID, agg.sDistributorID, '
SET @SQL = @SQL + 'ISNULL(agg.mRoyaltyOverrides,0)+ISNULL(agg.mMainRoyaltyOverrides,0) AS mRO '
SET @SQL = @SQL + 'FROM dbo.v_aggFQS_ID agg INNER JOIN dbo.v_Distributor DS ON DS.nDistributorID = agg.nDistributorID '
SET @SQL = @SQL + 'LEFT JOIN dbo.AWT AWT (NOLOCK) ON AWT.AWTYear = '+CONVERT(VARCHAR,@AWTYear) 
SET @SQL = @SQL + ' AND agg.nDistributorID = AWT.PK_Distributor '
SET @SQL = @SQL + ' WHERE agg.dRoyaltyMonth >= ''' + CONVERT(VARCHAR,@BeginMonth) + ''' AND agg.dRoyaltyMonth <= ''' + CONVERT(VARCHAR,@EndMonth) + ''''
SET @SQL = @SQL + ' AND AWT.PK_Distributor IS NULL '
SET @SQL = @SQL + ' AND DS.StatusCode = ''COMPLETE'''
SET @SQL = @SQL + ' AND DS.sType = ''SP'') AGS'
SET @SQL = @SQL + ' PIVOT ( SUM(AGS.mRO) FOR AGS.RoyaltyMonth IN (' 
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M6)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M5)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M4)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M3)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M2)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M1)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M0)+'] )) LL'

--PRINT @SQL

EXEC SP_EXECUTESQL @SQL

SET @Error = @Error + @@ERROR

INSERT INTO #FinalTab( 
	PK_Distributor
	,DistributorID 
	,COP
	,M6_RO
	,M5_RO 
	,M4_RO
	,M3_RO 
	,M2_RO 
	,M1_RO
	,M0_RO
)
SELECT
	PK_Distributor
	,DistributorID
	,COP 
	,M6
	,M5
	,M4
	,M3
	,M2
	,M1
	,M0
FROM
	#RO 
	
SET @Error = @Error + @@ERROR	
	
-- Create Indexes
CREATE INDEX IX_#FinalTab_PK_Distributor ON #FinalTab(PK_Distributor)
CREATE INDEX IX_#FinalTab_DistributorID ON #FinalTab(DistributorID)
CREATE INDEX IX_#FinalTab_COP ON #FinalTab(COP)
	
IF OBJECT_ID('Tempdb..#TVP','U') IS NOT NULL DROP TABLE #TVP

CREATE TABLE #TVP (
	PK int IDENTITY(1,1) PRIMARY KEY
	,PK_Distributor int
	,DistributorID  varchar(10)
	,COP varchar(2)
	,M6 MONEY DEFAULT 0
	,M5 MONEY DEFAULT 0
	,M4 MONEY DEFAULT 0
	,M3 MONEY DEFAULT 0
	,M2 MONEY DEFAULT 0
	,M1 MONEY DEFAULT 0
	,M0 MONEY DEFAULT 0
)

SET @Error = @Error + @@ERROR

SET @SQL = 'INSERT INTO #TVP(PK_Distributor,DistributorID,COP,M6,M5,M4,M3,M2,M1,M0) SELECT LL.nDistributorID,LL.sDistributorID,LL.sCOP,'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M6)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M5)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M4)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M3)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M2)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M1)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M0)+'] '
SET @SQL = @SQL + 'FROM (SELECT agg.dRoyaltyMonth AS RoyaltyMonth, agg.sCOP, agg.nDistributorID, agg.sDistributorID, '
SET @SQL = @SQL + 'CASE WHEN ACL.Royaltymonth IS NOT NULL THEN CASE WHEN ISNULL(agg.mVolumePoints,0) >= '+CONVERT(VARCHAR,@5Get5)+' THEN '+CONVERT(VARCHAR,@5Get5)+' + ISNULL(agg.mVolumePoints,0) ELSE ISNULL(agg.mVolumePoints,0) END ELSE ISNULL(agg.mVolumePoints,0) END AS mTVP'
SET @SQL = @SQL + ' FROM dbo.v_aggFQS_ID agg INNER JOIN dbo.v_Distributor DS ON DS.nDistributorID = agg.nDistributorID '
SET @SQL = @SQL + ' LEFT JOIN dbo.AWT_Accelerator ACL ON ACL.AWTYear = '+ CONVERT(VARCHAR,@AWTYear) +' AND ACL.COP = DS.sDistributorCountryProcessingCode '
SET @SQL = @SQL + ' AND ACL.Royaltymonth = agg.dRoyaltyMonth AND ACL.PK_AWT_AcceleratorType = '+CONVERT(VARCHAR,@PK_AWT_AcceleratorType)
SET @SQL = @SQL + ' LEFT JOIN dbo.AWT AWT (NOLOCK) ON AWT.AWTYear = '+CONVERT(VARCHAR,@AWTYear) 
SET @SQL = @SQL + ' AND agg.nDistributorID = AWT.PK_Distributor '
SET @SQL = @SQL + ' WHERE agg.dRoyaltyMonth >= ''' + CONVERT(VARCHAR,@BeginMonth) + ''' AND agg.dRoyaltyMonth <= ''' + CONVERT(VARCHAR,@EndMonth) + ''''
SET @SQL = @SQL + ' AND AWT.PK_Distributor IS NULL '
SET @SQL = @SQL + ' AND DS.StatusCode = ''COMPLETE'''
SET @SQL = @SQL + ' AND DS.sType = ''SP'') AGS'
SET @SQL = @SQL + ' PIVOT ( SUM(AGS.mTVP) FOR AGS.RoyaltyMonth IN (' 
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M6)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M5)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M4)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M3)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M2)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M1)+'],'
SET @SQL = @SQL + '['+CONVERT(VARCHAR,@M0)+'] )) LL'

--PRINT @SQL

EXEC SP_EXECUTESQL @SQL

SET @Error = @Error + @@ERROR

UPDATE 
	Fin 
SET
	Fin.M0_TV = TV.M0 
	,Fin.M1_TV = TV.M1 
	,Fin.M2_TV = TV.M2 
	,Fin.M3_TV = TV.M3
	,Fin.M4_TV = TV.M4
	,Fin.M5_TV = TV.M5 
	,Fin.M6_TV = TV.M6 
FROM
	#FinalTab Fin
INNER JOIN
	#TVP TV
ON
	Fin.PK_Distributor = TV.PK_Distributor 
	
SET @Error = @Error + @@ERROR

INSERT INTO #FinalTab( 
	PK_Distributor
	,DistributorID 
	,COP
	,M6_TV
	,M5_TV 
	,M4_TV
	,M3_TV 
	,M2_TV 
	,M1_TV
	,M0_TV
)
SELECT
	PK_Distributor
	,DistributorID
	,COP 
	,M6
	,M5
	,M4
	,M3
	,M2
	,M1
	,M0
FROM
	#TVP TV
WHERE
	NOT EXISTS (SELECT 1 FROM #FinalTab Fin WHERE Fin.PK_Distributor = TV.PK_Distributor) 
	
SET @Error = @Error + @@ERROR

DELETE FROM #FinalTab WHERE DistributorID IS NULL OR PK_Distributor IS NULL

-- Process and update Promotiona Months (5Get5 Months)	
IF OBJECT_ID('Tempdb..#COP','U') IS NOT NULL DROP TABLE #COP

CREATE TABLE #COP (
	PK int IDENTITY(1,1) PRIMARY KEY
	,COP varchar(2)
	,PromoMonths VARCHAR(1000)
)

SET @Error = @Error + @@ERROR

INSERT INTO #COP(COP)
SELECT 
	DISTINCT COP
FROM
	dbo.AWT_Accelerator WITH (NOLOCK)
WHERE
	AWTYear = @AWTYear  
	AND 
	PK_AWT_AcceleratorType = @PK_AWT_AcceleratorType 
	
SET @Error = @Error + @@ERROR

IF OBJECT_ID('Tempdb..#PromoMonthsByCOP','U') IS NOT NULL DROP TABLE #PromoMonthsByCOP

CREATE TABLE #PromoMonthsByCOP (
	PK int IDENTITY(1,1) PRIMARY KEY
	,COP varchar(2)
	,PromoMonth VARCHAR(8)
)

SET @Error = @Error + @@ERROR

INSERT INTO #PromoMonthsByCOP(COP,PromoMonth)
SELECT 
	COP
	,CONVERT(VARCHAR(4),DATEPART(YEAR,Royaltymonth))+'/'+CONVERT(VARCHAR(2),DATEPART(MONTH,Royaltymonth)) AS YearMonth
FROM 
	dbo.AWT_Accelerator WITH (NOLOCK)
WHERE
	AWTYear = @AWTYear 
	AND 
	PK_AWT_AcceleratorType = @PK_AWT_AcceleratorType 
	AND
	Royaltymonth <= GETUTCDATE()
ORDER BY 
	COP
	,Royaltymonth 
	
SET @Error = @Error + @@ERROR
	
SELECT 
	@MinPK = MIN(PK)
	,@MaxPK = MAX(PK) 
FROM 
	#PromoMonthsByCOP 
	
WHILE @MinPK <= @MaxPK 
BEGIN
	SELECT 
		@PromoMonth = PromoMonth 
		,@COP = COP 
	FROM
		#PromoMonthsByCOP 
	WHERE
		PK = @MinPK 
		
	UPDATE 
		PM 
	SET
		PromoMonths = ISNULL(PromoMonths,'') + CASE WHEN PromoMonths IS NOT NULL THEN ',' ELSE '' END + @PromoMonth 
	FROM
		#COP PM
	WHERE
		COP = @COP  
		
	SET @MinPK = @MinPK + 1	
END	

SET @Error = @Error + @@ERROR

UPDATE
	FT
SET
	PromoMonths = CP.PromoMonths 	
FROM
	#FinalTab FT 
INNER JOIN
	#COP CP
ON
	FT.COP = CP.COP 
	
SET @Error = @Error + @@ERROR
	
-- Determine the 1800, 2000, 2200 and 2500 TVP Qualifiers
SELECT @PK_SubEvent1 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 1	
SELECT @PK_SubEvent2 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 2	
SELECT @PK_SubEvent3 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 3
SELECT @PK_SubEvent4 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 4	
SELECT @PK_SubEvent5 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 5	
SELECT @PK_SubEvent6 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 6	
SELECT @PK_SubEvent7 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 7	
SELECT @PK_SubEvent8 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 8	
SELECT @PK_SubEvent9 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 9	
SELECT @PK_SubEvent10 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 10	
SELECT @PK_SubEvent11 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 11	
SELECT @PK_SubEvent12 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 12	
SELECT @PK_SubEvent13 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 13	
SELECT @PK_SubEvent14 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 14	
SELECT @PK_SubEvent15 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 15	
SELECT @PK_SubEvent16 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 16	
SELECT @PK_SubEvent17 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 17	
SELECT @PK_SubEvent18 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 18	
SELECT @PK_SubEvent19 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 19	
SELECT @PK_SubEvent20 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 20	
UPDATE
	Fin 
SET
	Fin.Is1800_In1M_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent1 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is1800_In2CM_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent2 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is1800_In3CM_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent3 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is1800_In4CM_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent4 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is2000_In1M_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent5 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is2000_In2CM_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent6 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is2000_In3CM_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent7 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is2000_In4CM_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent8 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is2200_In1M_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent9 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is2200_In2CM_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent10 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is2200_In3CM_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent11 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR

UPDATE
	Fin 
SET
	Fin.Is2200_In4CM_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent12 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR

UPDATE
	Fin 
SET
	Fin.Is2500_In1M_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent13 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is2500_In2CM_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent14 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 

SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is2500_In3CM_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent15 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR

UPDATE
	Fin 
SET
	Fin.Is2500_In4CM_InL6M = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent16 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 

SET @Error = @Error + @@ERROR

/********** Current Month ***********/
UPDATE
	Fin 
SET
	Fin.Is2500_In1M_InL6M_0 = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent17 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is2500_In2CM_InL6M_0 = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent18 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 

SET @Error = @Error + @@ERROR
	
UPDATE
	Fin 
SET
	Fin.Is2500_In3CM_InL6M_0 = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent19 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 
	
SET @Error = @Error + @@ERROR

UPDATE
	Fin 
SET
	Fin.Is2500_In4CM_InL6M_0 = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
ON
	SEQ.PK_Event = @PK_Event 
	AND
	SEQ.PK_SubEvent = @PK_SubEvent20 
	AND
	SEQ.PK_Distributor = Fin.PK_Distributor 
	AND
	SEQ.RemovedUTC = @RemovedUTC 

SET @Error = @Error + @@ERROR
	
-- Update IsType23 column
UPDATE
	Fin 
SET 
	IsType23 = 1
FROM
	#FinalTab Fin
INNER JOIN
	dbo.v_DistributorAssociate2 DA
ON
	Fin.PK_Distributor = DA.nDistributorID
	AND
	DA.Transfer = 0	
	
SET @Error = @Error + @@ERROR
	
DROP TABLE IF EXISTS dbo.wrk_AWT_Potentials

SELECT * 
INTO dbo.wrk_AWT_Potentials
FROM #FinalTab
-- UPDATE, INSERT AND/OR DELETE FROM dbo.AWT_Potentials
BEGIN
	MERGE dbo.AWT_Potentials AWT
	USING #FinalTab Fin
	ON 
		AWT.PK_Distributor_EDW = Fin.PK_Distributor
    WHEN MATCHED  THEN
		UPDATE
		SET
			 AWT.M6_RO = Fin.M6_RO
			,AWT.M5_RO = Fin.M5_RO
			,AWT.M4_RO = Fin.M4_RO
			,AWT.M3_RO = Fin.M3_RO
			,AWT.M2_RO = Fin.M2_RO
			,AWT.M1_RO = Fin.M1_RO
			,AWT.M0_RO = Fin.M0_RO
			,AWT.M6_TV = Fin.M6_TV 
			,AWT.M5_TV = Fin.M5_TV
			,AWT.M4_TV = Fin.M4_TV
			,AWT.M3_TV = Fin.M3_TV
			,AWT.M2_TV = Fin.M2_TV
			,AWT.M1_TV = Fin.M1_TV
			,AWT.M0_TV = Fin.M0_TV
			,AWT.Is1800_In1M_InL6M = Fin.Is1800_In1M_InL6M
			,AWT.Is1800_In2CM_InL6M = Fin.Is1800_In2CM_InL6M
			,AWT.Is1800_In3CM_InL6M = Fin.Is1800_In3CM_InL6M
			,AWT.Is1800_In4CM_InL6M = Fin.Is1800_In4CM_InL6M
			,AWT.Is2000_In1M_InL6M = Fin.Is2000_In1M_InL6M
			,AWT.Is2000_In2CM_InL6M = Fin.Is2000_In2CM_InL6M
			,AWT.Is2000_In3CM_InL6M = Fin.Is2000_In3CM_InL6M
			,AWT.Is2000_In4CM_InL6M = Fin.Is2000_In4CM_InL6M
			,AWT.Is2200_In1M_InL6M = Fin.Is2200_In1M_InL6M
			,AWT.Is2200_In2CM_InL6M = Fin.Is2200_In2CM_InL6M 
			,AWT.Is2200_In3CM_InL6M = Fin.Is2200_In3CM_InL6M 
			,AWT.Is2200_In4CM_InL6M = Fin.Is2200_In4CM_InL6M
			,AWT.Is2500_In1M_InL6M = Fin.Is2500_In1M_InL6M
			,AWT.Is2500_In2CM_InL6M = Fin.Is2500_In2CM_InL6M
			,AWT.Is2500_In3CM_InL6M = Fin.Is2500_In3CM_InL6M
			,AWT.Is2500_In4CM_InL6M = Fin.Is2500_In4CM_InL6M
			,AWT.Is2500_In1M_InL6M_0 = Fin.Is2500_In1M_InL6M_0
			,AWT.Is2500_In2CM_InL6M_0 = Fin.Is2500_In2CM_InL6M_0
			,AWT.Is2500_In3CM_InL6M_0 = Fin.Is2500_In3CM_InL6M_0
			,AWT.Is2500_In4CM_InL6M_0 = Fin.Is2500_In4CM_InL6M_0
			,AWT.PromoMonths = Fin.PromoMonths
			,AWT.ModifiedDateUTC = @Today
			,AWT.ModifiedBy = @ProcessededBy
	WHEN NOT MATCHED BY SOURCE THEN
		DELETE
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (PK_Distributor_EDW 
				,DistributorID  
				,COP 
				,IsType23 
				,PromoMonths 
				,M6_RO 
				,M5_RO 
				,M4_RO 
				,M3_RO 
				,M2_RO 
				,M1_RO 
				,M0_RO
				,M6_TV 
				,M5_TV 
				,M4_TV 
				,M3_TV 
				,M2_TV 
				,M1_TV 
				,M0_TV 
				,Is1800_In1M_InL6M 
				,Is1800_In2CM_InL6M 
				,Is1800_In3CM_InL6M 
				,Is1800_In4CM_InL6M 
				,Is2000_In1M_InL6M 
				,Is2000_In2CM_InL6M 
				,Is2000_In3CM_InL6M 
				,Is2000_In4CM_InL6M 
				,Is2200_In1M_InL6M 
				,Is2200_In2CM_InL6M 
				,Is2200_In3CM_InL6M 
				,Is2200_In4CM_InL6M 
				,Is2500_In1M_InL6M 
				,Is2500_In2CM_InL6M 
				,Is2500_In3CM_InL6M 
				,Is2500_In4CM_InL6M 	
				,Is2500_In1M_InL6M_0 
				,Is2500_In2CM_InL6M_0
				,Is2500_In3CM_InL6M_0 
				,Is2500_In4CM_InL6M_0						
				)
		VALUES (Fin.PK_Distributor
				,Fin.DistributorID  
				,Fin.COP 
				,Fin.IsType23 
				,Fin.PromoMonths 
				,Fin.M6_RO 
				,Fin.M5_RO 
				,Fin.M4_RO 
				,Fin.M3_RO 
				,Fin.M2_RO 
				,Fin.M1_RO
				,Fin.M0_RO 
				,Fin.M6_TV 
				,Fin.M5_TV 
				,Fin.M4_TV 
				,Fin.M3_TV 
				,Fin.M2_TV 
				,Fin.M1_TV 
				,Fin.M0_TV
				,Fin.Is1800_In1M_InL6M 
				,Fin.Is1800_In2CM_InL6M 
				,Fin.Is1800_In3CM_InL6M 
				,Fin.Is1800_In4CM_InL6M 
				,Fin.Is2000_In1M_InL6M 
				,Fin.Is2000_In2CM_InL6M 
				,Fin.Is2000_In3CM_InL6M 
				,Fin.Is2000_In4CM_InL6M 
				,Fin.Is2200_In1M_InL6M 
				,Fin.Is2200_In2CM_InL6M 
				,Fin.Is2200_In3CM_InL6M 
				,Fin.Is2200_In4CM_InL6M 
				,Fin.Is2500_In1M_InL6M 
				,Fin.Is2500_In2CM_InL6M 
				,Fin.Is2500_In3CM_InL6M 
				,Fin.Is2500_In4CM_InL6M 
				,Fin.Is2500_In1M_InL6M_0
				,Fin.Is2500_In2CM_InL6M_0 
				,Fin.Is2500_In3CM_InL6M_0 
				,Fin.Is2500_In4CM_InL6M_0 
				);

SET @Error = @Error + @@ERROR				

END

-- Process BizWorks Events Objects
--EXEC dbo.usp_Maintain_Events_BizWorks @Month_Interval = -12  /*Move this to be part of SMA job */

IF @Error > 0
BEGIN
	ROLLBACK TRANSACTION
--	PRINT 'Error Occured. No Record set was updated.'
END
ELSE
BEGIN
	COMMIT TRANSACTION
--	PRINT 'All Records Updated Successfully'
END

END
END