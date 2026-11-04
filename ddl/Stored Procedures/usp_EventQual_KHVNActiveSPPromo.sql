CREATE PROCEDURE [dbo].[usp_EventQual_KHVNActiveSPPromo]
	 @PK_Event INT = 3720,
	 @PK_Event2 INT = 3721,
	 @DateToProcess DATETIME = NULL
AS
BEGIN

/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_KHVNActiveSPPromo

	USE:		EXEC usp_EventQual_KHVNActiveSPPromo @PK_Event = 3720, @PK_Event2 = 3721

	DESCRIPTION: This procedure is a custom qual for the Cambodia y Vietnam Active Supervisor Promo. 

	NOTES:			

	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	SQL SERVER 2010
	
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1	2014-02-28   OrlandoL  	Initial
	2	2019-08-15   NoeG		Refactor code (SRE)
	3	2019-11-04	 NoeG		SRE Hardcode changed

***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @ProcName varchar(100)
,@ProcParamRecur varchar(100)
,@StartTimeRecur datetime 	
,@BeginDate DATETIME 
,@CurrentMonth DATETIME = ISNULL(@DateToProcess,DATEADD(mm,DATEDIFF(mm,0,GETDATE()),0))
,@ValidDate DATETIME = '2049-12-31'

SET @ProcName = 'usp_EventQual_KHVNActiveSPPromo'
SET @ProcParamRecur = CONVERT(VARCHAR,'3676')
SET @StartTimeRecur = GETUTCDATE() 
      
SET @BeginDate = DATEADD(mm,-3,@CurrentMonth)


IF OBJECT_ID ('tempDB..#ActiveSPDLs', 'U')IS NOT NULL DROP TABLE #ActiveSPDLs
IF OBJECT_ID ('tempDB..#Temp', 'U')IS NOT NULL DROP TABLE #Temp
IF OBJECT_ID('tempdb..#Associated', 'U') IS NOT NULL DROP TABLE #Associated
IF OBJECT_ID('tempdb..#wrk_T1', 'U') IS NOT NULL DROP TABLE #wrk_T1

CREATE TABLE #wrk_T1
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	PK_Distributor		int
)

CREATE TABLE #Associated
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	nMainAssociatedID INT,
	nDistributorID INT,
	Stones INT DEFAULT 0
)


-- GET ASSOCIATIONS WHERE Mains Will have to be excluded
INSERT INTO #wrk_T1(PK_Distributor)
SELECT DISTINCT nMainDistributorID
FROM   dbo.v_DistributorAssociate2 A 
INNER JOIN dbo.v_Distributor D
ON A.nMainDistributorID = D.nDistributorID
WHERE  dThrough = @ValidDate
AND Transfer = 0
AND D.nDistributorCountryProcessingID IN (SELECT nCountryID FROM [dbo].[v_Countries] WHERE sCountryCode IN ('VN','KH'))
GROUP BY nMainDistributorID
HAVING COUNT(1) >= 3

CREATE INDEX IX_#wrk_T1_PK_Distributor ON #wrk_T1(PK_Distributor)


-- GET ASSOCIATIONS IDs
INSERT INTO #Associated(nMainAssociatedID,nDistributorID)
SELECT nMainDistributorID,nDistributorID
FROM dbo.v_DistributorAssociate2 
WHERE nMainDistributorID IN (
SELECT DISTINCT nMainDistributorID 
FROM   dbo.v_DistributorAssociate2 A 
INNER JOIN dbo.v_Distributor D
ON A.nMainDistributorID = D.nDistributorID
WHERE  dThrough = @ValidDate
AND Transfer = 0
AND D.nDistributorCountryProcessingID IN (SELECT nCountryID FROM [dbo].[v_Countries] WHERE sCountryCode IN ('VN','KH'))
GROUP BY nMainDistributorID
HAVING COUNT(1) >= 3) AND nMainDistributorID <> nDistributorID AND dThrough = @ValidDate

CREATE INDEX IX_#Associated_nMainAssociatedID ON #Associated(nMainAssociatedID)
CREATE INDEX IX_#Associated_nDistributorID ON #Associated(nDistributorID)


CREATE TABLE #ActiveSPDLs
(
	 PK INT IDENTITY(1,1) PRIMARY KEY
	,PK_Distributor INT 
	,PK_Downline INT
	,DSLevel INT 
	,Is25003CM BIT DEFAULT 0
	,IsCanCount BIT DEFAULT 0
	,COP INT
)



IF OBJECT_ID('WRK_KHVNActiveSPPromo', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.WRK_KHVNActiveSPPromo
	(
		   PK int IDENTITY(1,1) PRIMARY KEY
		  ,PK_Distributor INT NOT NULL
		  ,LastRunTotalSP INT DEFAULT 0
		  ,AcviteSupervisor_QualDate DATETIME
		  ,Stone3_QualDate DATETIME 
		  ,TotalStone3 INT DEFAULT 0
		  ,Stone5_QualDate DATETIME 
		  ,TotalStone5 INT DEFAULT 0
		  ,Stone7_QualDate DATETIME 
		  ,TotalStone7 INT DEFAULT 0
		  ,Stone10_QualDate DATETIME
		  ,TotalStone10 INT DEFAULT 0  
		  ,IsASP BIT DEFAULT 0
		  ,IsStar1 BIT DEFAULT 0
		  ,IsStar2 BIT DEFAULT 0
		  ,IsStar3 BIT DEFAULT 0
		  ,IsStar4 BIT DEFAULT 0
		  ,IsStar5 BIT DEFAULT 0
		  ,IsStar6 BIT DEFAULT 0
		  ,IsStar7 BIT DEFAULT 0
		  ,IsStar8 BIT DEFAULT 0
		  ,IsStar9 BIT DEFAULT 0
		  ,IsStar10 BIT DEFAULT 0
		  ,IsStar11 BIT DEFAULT 0
		  ,CreatedDate DATETIME DEFAULT GETUTCDATE()
	)
END



/******************************************************************************
	GET All MB from EMEA Region who has achieved 2500 in 3CM
*******************************************************************************/
;WITH MainMB25003CM (PK_Distributor) AS
(
	SELECT DISTINCT
		A.nDistributorID
	FROM 
		[dbo].[v_Distributor] D WITH (NOLOCK)		
	INNER JOIN
		[dbo].[v_aggFQS_ID] A
	ON
		D.nDistributorID = A.nDistributorID
	INNER JOIN
		dbo.v_Countries C
	ON
		D.nDistributorCountryProcessingID = C.nCountryID
		AND
		C.sCountryCode IN ('VN','KH')
	WHERE 
		A.dRoyaltyMonth BETWEEN DATEADD(mm,0,@BeginDate) AND DATEADD(mm,2,@BeginDate)
	AND
		A.mVolumePoints >= 2500 
	AND
		D.StatusCode = 'COMPLETE'
	AND
		D.sType = 'SP'
	AND
		D.dSupervisorQualification <= @BeginDate
	GROUP BY
		A.nDistributorID,C.nCountryID
	HAVING
		COUNT(A.nDistributorID) >= 3
	UNION
	SELECT 
		W.PK_Distributor
	FROM 
		#wrk_T1 W
)


/**********************************************************************************************
	Get count of active downlines/SPs per leg
**********************************************************************************************/	
INSERT INTO #ActiveSPDLs 
(
	PK_Distributor 
	,PK_Downline
	,DSLevel
	,Is25003CM
	,IsCanCount 
)
SELECT
	UL.PK_Distributor 
	,DL.PK_DSDownline
	,DL.DSLevelFromUL
	,CASE WHEN TV.nDistributorID IS NOT NULL THEN 1 ELSE 0 END 
	,CASE WHEN TV.nDistributorID IS NOT NULL THEN 1 ELSE 0 END
FROM 
	MainMB25003CM UL
LEFT JOIN
	dbo.v_dimDsLngDownline DL 
ON
	UL.PK_Distributor = DL.PK_Distributor 
	AND
	DL.SPLevelFromUL = 2
LEFT JOIN
(
	SELECT 
		nDistributorID
	FROM
		[dbo].[v_aggFQS_ID]
	WHERE
		dRoyaltyMonth BETWEEN DATEADD(mm,0,@BeginDate) AND DATEADD(mm,2,@BeginDate)
		AND
		mVolumePoints >= 2500
	GROUP BY
		nDistributorID
	HAVING 
		COUNT(1) >= 3
) TV
ON
	DL.PK_DSDownline = TV.nDistributorID
	


CREATE INDEX IX_#ActiveSPDLs_PK_Distributor ON #ActiveSPDLs(PK_Distributor)	
CREATE INDEX IX_#ActiveSPDLs_PK_Downline ON #ActiveSPDLs(PK_Downline)	


/*************************************************************************************
      INSERT NEW Qualifiers to the three events project numbers (15033,15034,15035)
*************************************************************************************/	
INSERT
	dbo.WRK_KHVNActiveSPPromo
(
	PK_Distributor
	,IsASP
	,IsStar1
	,AcviteSupervisor_QualDate
)
SELECT DISTINCT
	 PK_Distributor 
	,1
	,1
	,@CurrentMonth 
FROM
	#ActiveSPDLs S
WHERE
	NOT EXISTS (SELECT PK_Distributor FROM dbo.WRK_KHVNActiveSPPromo W WITH (NOLOCK) WHERE W.PK_Distributor = S.PK_Distributor)

/******************************************************************************
      UPDATE Total ASP in the current period
******************************************************************************/

/* ***************** SonarQube check 65 - "UPDATE" statements should contain "WHERE" clauses */
UPDATE dbo.WRK_KHVNActiveSPPromo SET LastRunTotalSP = 0 WHERE [PK_Distributor] > 0
/* ***************** SonarQube check 65 */

UPDATE
      T
SET
      T.LastRunTotalSP = F.Qty
FROM
      dbo.WRK_KHVNActiveSPPromo T
INNER JOIN
	(
		SELECT
			PK_Distributor 
			,COUNT(DISTINCT PK_Downline) AS Qty 
		FROM 
			#ActiveSPDLs 
		WHERE
			Is25003CM = 1 
		GROUP BY
			PK_Distributor
	) F
ON
	T.PK_Distributor = F.PK_Distributor
	

/******************************************************************************
	Assing Main Associated stones to associated IDs
******************************************************************************/
UPDATE
      T
SET
      T.Stones = W.LastRunTotalSP
FROM
      #Associated T
INNER JOIN
	dbo.WRK_KHVNActiveSPPromo W
ON
	T.nMainAssociatedID = W.PK_Distributor
	

UPDATE
      T
SET
      T.LastRunTotalSP = (ISNULL(T.LastRunTotalSP,0) + ISNULL(A.Stones,0))
FROM
      dbo.WRK_KHVNActiveSPPromo T
INNER JOIN
	 #Associated A
ON
	A.nDistributorID = T.PK_Distributor
	
/******************************************************************************  
 UPDATE WRK_KHVNActiveSPPromo Levels
******************************************************************************/  

/* ***************** SonarQube check 66 - "UPDATE" statements should contain "WHERE" clauses */
UPDATE  
	W  
SET 
	Stone10_QualDate = CASE WHEN  W.LastRunTotalSP >= 10 AND W.Stone10_QualDate IS NULL THEN @CurrentMonth ELSE W.Stone10_QualDate END,
	TotalStone10 = CASE WHEN W.LastRunTotalSP >= 10 AND W.Stone10_QualDate IS NULL THEN W.LastRunTotalSP ELSE TotalStone10 END,
	Stone7_QualDate = CASE WHEN  W.LastRunTotalSP >= 7 AND W.Stone7_QualDate IS NULL THEN @CurrentMonth ELSE W.Stone7_QualDate END,
	TotalStone7 = CASE WHEN W.LastRunTotalSP >= 7 AND W.Stone7_QualDate IS NULL THEN W.LastRunTotalSP ELSE TotalStone7 END,  
	Stone5_QualDate = CASE WHEN  W.LastRunTotalSP >= 5 AND W.Stone5_QualDate IS NULL THEN @CurrentMonth ELSE W.Stone5_QualDate END,
	TotalStone5 = CASE WHEN W.LastRunTotalSP >= 5AND W.Stone5_QualDate IS NULL THEN W.LastRunTotalSP ELSE TotalStone5 END, 
	Stone3_QualDate =  CASE WHEN  W.LastRunTotalSP >= 3 AND W.Stone3_QualDate IS NULL THEN @CurrentMonth ELSE W.Stone3_QualDate END,
	TotalStone3 = CASE WHEN W.LastRunTotalSP >= 3 AND W.Stone3_QualDate IS NULL THEN W.LastRunTotalSP ELSE TotalStone3 END,  
	IsStar2 = CASE WHEN W.LastRunTotalSP >= 3 THEN W.LastRunTotalSP ELSE IsStar3 END,
	IsStar3 = CASE WHEN W.LastRunTotalSP >= 5 THEN W.LastRunTotalSP ELSE IsStar5 END,
	IsStar4 = CASE WHEN W.LastRunTotalSP >= 7 THEN W.LastRunTotalSP ELSE IsStar7 END,
	IsStar5 = CASE WHEN W.LastRunTotalSP >= 10 THEN W.LastRunTotalSP ELSE IsStar10 END
FROM  
	dbo.WRK_KHVNActiveSPPromo W WITH (NOLOCK) 
WHERE 
	W.PK_Distributor > 0
/* ***************** SonarQube check 66 */





UPDATE dbo.WRK_KHVNActiveSPPromo SET IsASP = 0, IsStar1 = 0 WHERE PK_Distributor IN (SELECT PK_Distributor FROM #wrk_T1)


-- Call the stored procedure to insert EMEA ASP 2015 Qualifiers in SubEventQualifier in IA
-- by first copying the work table from BI to IA using the link server within the IA stored procedure
EXEC dbo.usp_StarPromo_UpdateSubEventQualifier @PK_InEvent = @PK_Event, @TabNAme = 'WRK_KHVNActiveSPPromo'

EXEC dbo.usp_StarPromo_UpdateSubEventQualifier @PK_InEvent = @PK_Event2, @TabNAme = 'WRK_KHVNActiveSPPromo'




EXEC usp_Utility_UpdateProcessingLog
@StoredProcedureName = @ProcName
,@StoredProcedureParameters = @ProcParamRecur
,@StartTime = @StartTimeRecur


/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
GO

