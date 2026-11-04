CREATE PROCEDURE [dbo].[usp_EventQual_MexicoMAPSpnsor]
	@PK_Event INT = 62633,
	@DateToProcess DATE = NULL
AS 
BEGIN  
  
/******************************************************************************  
OBJECT:  dbo.usp_EventQual_MexicoMAPSpnsor
  
USE:  EXEC dbo.usp_EventQual_MexicoMAPSpnsor --@PK_Event
  
DESCRIPTION:  
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
VERSIONS  
--------------------------------------------------------------------  
1 2017-12-14   OrlandoL   Initial  
3 2019-11-04   NoeG		  SRE Hardcode changed
  
******************************************************************************/   
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON   
  
DECLARE @ProcName varchar(100)
 ,@ProcParamRecur varchar(100)
 ,@StartTimeRecur datetime
 ,@CurrentMonth DATETIME = ISNULL(@DateToProcess,DATEADD(mm,DATEDIFF(mm,0,GETDATE()),0))
 ,@ValidDate DATETIME = '2049-12-31'

SET @ProcName = 'usp_EventQual_MexicoMAPSpnsor'
SET @ProcParamRecur = CONVERT(VARCHAR,@PK_Event) 
SET @StartTimeRecur = GETUTCDATE() 

IF OBJECT_ID ('tempDB..#RPT_Temp', 'U')IS NOT NULL DROP TABLE #RPT_Temp
IF OBJECT_ID('tempdb..#Associated', 'U') IS NOT NULL DROP TABLE #Associated

CREATE TABLE #Associated
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	nMainAssociatedID INT,
	nDistributorID INT,
	Downlines100 INT DEFAULT 0,
	Downlines300 INT DEFAULT 0
)

CREATE TABLE #RPT_Temp
(
	PK_Distributor INT ,
	DistributorID VARCHAR(20),
	Downlines100 INT DEFAULT 0,
	Downlines300 INT DEFAULT 0,
	IsE1Qualifier BIT DEFAULT 0,
	IsE2Qualifier BIT DEFAULT 0,
	IsE3Qualifier BIT DEFAULT 0,
	IsE4Qualifier BIT DEFAULT 0
)


-- GET ASSOCIATIONS IDs
INSERT INTO #Associated(nMainAssociatedID,nDistributorID)
SELECT nMainDistributorID,nDistributorID
FROM dbo.v_DistributorAssociate2 
WHERE nMainDistributorID IN (
SELECT DISTINCT nMainDistributorID 
FROM   dbo.v_DistributorAssociate2 A 
INNER JOIN dbo.v_Distributor D
ON A.nMainDistributorID = D.nDistributorID
INNER JOIN	dbo.v_Countries C
ON D.nDistributorCountryProcessingID = C.nCountryID
--AND (C.sRegionCode = 'EU' OR C.sCountryCode IN ('CO','BR'))
WHERE  dThrough = @ValidDate
AND Transfer = 0
GROUP BY nMainDistributorID
/*HAVING COUNT(1) >= 3*/) AND nMainDistributorID <> nDistributorID AND dThrough = @ValidDate

CREATE INDEX IX_#Associated_nMainAssociatedID ON #Associated(nMainAssociatedID)
CREATE INDEX IX_#Associated_nDistributorID ON #Associated(nDistributorID)

IF OBJECT_ID('WRK_MexicoMAPSponsor', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.WRK_MexicoMAPSponsor
	(		  
		PK int IDENTITY(1,1) PRIMARY KEY,
		PK_Distributor INT,
		DistributorID VARCHAR(20),
		Downlines100 INT DEFAULT 0,
		Downlines300 INT DEFAULT 0,
		QualDate_E1 DATETIME,
		QualDate_E2 DATETIME,
		QualDate_E3 DATETIME,
		QualDate_E4 DATETIME, 
		CreatedDate DATETIME DEFAULT GETUTCDATE()
	)
END

/******************************************************************************
	Insert All DS from Mexico 
*******************************************************************************/
INSERT INTO #RPT_Temp
(
	PK_Distributor,
	DistributorID
)
SELECT  
	nDistributorID,
	sDistributorID
FROM
	dbo.v_Distributor
WHERE
	sDistributorCountryProcessingCode = 'MX'
	AND
	StatusCode = 'COMPLETE'



/******************************************************************************
	UPDATE Downlines from Mexico MAP work table
*******************************************************************************/
UPDATE
	T
SET 
	T.Downlines100 = A.Total
FROM 
	#RPT_Temp T
INNER JOIN
(
	SELECT 
		DL.PK_Distributor,
		COUNT(1) AS Total
	FROM
		dbo.v_dimDSLngDownline DL
	INNER JOIN
		dbo.WRK_MexicoMAP2017 R (NOLOCK)
	ON
		DL.PK_DSDownline = R.PK_Distributor
	WHERE
		(R.IsE1Qualifier = 1 OR R.IsE2Qualifier = 1 OR R.IsE3Qualifier = 1)
		AND
		R.AppDate BETWEEN DATEADD(MM,-2,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-1,@CurrentMonth))
		AND
		DL.DSLevelFromUL = 2
	GROUP BY
		DL.PK_Distributor
) A
ON
	T.PK_Distributor = A.PK_Distributor



UPDATE
	T
SET 
	T.Downlines300 = A.Total
FROM 
	#RPT_Temp T
INNER JOIN
(
	SELECT 
		DL.PK_Distributor,
		COUNT(1) AS Total
	FROM
		dbo.v_dimDSLngDownline DL
	INNER JOIN
		dbo.WRK_MexicoMAP2017 R (NOLOCK)
	ON
		DL.PK_DSDownline = R.PK_Distributor
	WHERE
		(R.IsE4Qualifier = 1 OR R.IsE5Qualifier = 1 OR R.IsE6Qualifier = 1)
		AND
		R.AppDate BETWEEN DATEADD(MM,-2,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-1,@CurrentMonth))
		AND
		DL.DSLevelFromUL = 2
	GROUP BY
		DL.PK_Distributor
) A
ON
	T.PK_Distributor = A.PK_Distributor


/******************************************************************************
	Assing Main Associated stones to associated IDs
******************************************************************************/
UPDATE
    T
SET
    T.Downlines100 = W.Downlines100,
	T.Downlines300 = W.Downlines300
FROM
    #Associated T
INNER JOIN
	#RPT_Temp W
ON
	T.nMainAssociatedID = W.PK_Distributor

UPDATE
    T
SET
    T.Downlines100 = (T.Downlines100+A.Downlines100),
	T.Downlines300 = (T.Downlines300+A.Downlines300)
FROM
    #RPT_Temp T
INNER JOIN
	#Associated A
ON
	A.nDistributorID = T.PK_Distributor

/******************************************************************************
	UPDATE qualifiers 
*******************************************************************************/
UPDATE
	T
SET 
	T.IsE1Qualifier = CASE WHEN Downlines100 >= 2 THEN 1 ELSE 0 END,
	T.IsE2Qualifier = CASE WHEN Downlines100 >= 4 THEN 1 ELSE 0 END,
	T.IsE3Qualifier = CASE WHEN Downlines300 >= 2 THEN 1 ELSE 0 END,
	T.IsE4Qualifier = CASE WHEN Downlines300 >= 4 THEN 1 ELSE 0 END
FROM 
	#RPT_Temp T



	
/*************************************************************************************
      INSERT NEW Qualifiers to the three event
*************************************************************************************/	
INSERT
	dbo.WRK_MexicoMAPSponsor
(
	PK_Distributor,
	DistributorID,
	Downlines100,
	Downlines300,
	QualDate_E1,
	QualDate_E2,
	QualDate_E3,
	QualDate_E4 
)
SELECT DISTINCT
	PK_Distributor,
	DistributorID,
	Downlines100,
	Downlines300,
	CASE WHEN IsE1Qualifier = 1 THEN @CurrentMonth ELSE NULL END,
	CASE WHEN IsE2Qualifier = 1 THEN @CurrentMonth ELSE NULL END,
	CASE WHEN IsE3Qualifier = 1 THEN @CurrentMonth ELSE NULL END,
	CASE WHEN IsE4Qualifier = 1 THEN @CurrentMonth ELSE NULL END 
FROM
	#RPT_Temp S
WHERE
	NOT EXISTS (SELECT PK_Distributor FROM dbo.WRK_MexicoMAPSponsor W WHERE W.PK_Distributor = S.PK_Distributor)

/******************************************************************************  
 UPDATE WRK_MexicoMAPSponsor Levels
******************************************************************************/       
UPDATE  
	W  
SET  
	W.Downlines100 = SP.Downlines100,
	W.Downlines300 = SP.Downlines300,
	W.QualDate_E1 = CASE WHEN W.QualDate_E1 IS NULL AND SP.IsE1Qualifier = 1 THEN @CurrentMonth ELSE CASE WHEN SP.IsE1Qualifier = 1 AND W.QualDate_E1 > @CurrentMonth THEN W.QualDate_E1 ELSE CASE WHEN SP.IsE1Qualifier = 1 THEN @CurrentMonth ELSE W.QualDate_E1 END END END,
	W.QualDate_E2 = CASE WHEN W.QualDate_E2 IS NULL AND SP.IsE2Qualifier = 1 THEN @CurrentMonth ELSE CASE WHEN SP.IsE2Qualifier = 1 AND W.QualDate_E2 > @CurrentMonth THEN W.QualDate_E2 ELSE CASE WHEN SP.IsE2Qualifier = 1 THEN @CurrentMonth ELSE W.QualDate_E2 END END END,
	W.QualDate_E3 = CASE WHEN W.QualDate_E3 IS NULL AND SP.IsE3Qualifier = 1 THEN @CurrentMonth ELSE CASE WHEN SP.IsE3Qualifier = 1 AND W.QualDate_E3 > @CurrentMonth THEN W.QualDate_E3 ELSE CASE WHEN SP.IsE3Qualifier = 1 THEN @CurrentMonth ELSE W.QualDate_E3 END END END,
	W.QualDate_E4 = CASE WHEN W.QualDate_E4 IS NULL AND SP.IsE4Qualifier = 1 THEN @CurrentMonth ELSE CASE WHEN SP.IsE4Qualifier = 1 AND W.QualDate_E4 > @CurrentMonth THEN W.QualDate_E4 ELSE CASE WHEN SP.IsE4Qualifier = 1 THEN @CurrentMonth ELSE W.QualDate_E4 END END END
FROM   
	dbo.WRK_MexicoMAPSponsor W  
INNER JOIN
	#RPT_Temp SP
ON
	W.PK_Distributor = SP.PK_Distributor
	


/******************************************************************
	Process Qualifiers
******************************************************************/
IF OBJECT_ID('tempdb..##Q1', 'U') IS NOT NULL DROP TABLE ##Q1

DECLARE @PK_SubEvent INT
 
 /*SubEvent E01*/
SELECT @PK_SubEvent = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 1

	SELECT DISTINCT
		T.PK_Distributor
	INTO ##Q1
	FROM
		#RPT_Temp T
	WHERE
		T.IsE1Qualifier = 1

EXEC usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##Q1', 0

IF OBJECT_ID('tempdb..##Q1', 'U') IS NOT NULL DROP TABLE ##Q1
  
/**************************************************************************************************************/
IF OBJECT_ID('tempdb..##Q2', 'U') IS NOT NULL DROP TABLE ##Q2
 
 /*SubEvent E02*/
SELECT @PK_SubEvent = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 2

	SELECT DISTINCT
		T.PK_Distributor
	INTO ##Q2
	FROM
		#RPT_Temp T
	WHERE
		T.IsE2Qualifier = 1 

EXEC usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##Q2', 0

IF OBJECT_ID('tempdb..##Q2', 'U') IS NOT NULL DROP TABLE ##Q2
  

/**************************************************************************************************************/
IF OBJECT_ID('tempdb..##Q3', 'U') IS NOT NULL DROP TABLE ##Q3
 
 /*SubEvent E03*/
SELECT @PK_SubEvent = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 3

	SELECT DISTINCT
		T.PK_Distributor
	INTO ##Q3
	FROM
		#RPT_Temp T
	WHERE
		T.IsE3Qualifier = 1 

EXEC usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##Q3', 0

IF OBJECT_ID('tempdb..##Q3', 'U') IS NOT NULL DROP TABLE ##Q3


/**************************************************************************************************************/
IF OBJECT_ID('tempdb..##Q4', 'U') IS NOT NULL DROP TABLE ##Q4
 
 /*SubEvent E04*/
SELECT @PK_SubEvent = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = 4

	SELECT DISTINCT
		T.PK_Distributor
	INTO ##Q4
	FROM
		#RPT_Temp T
	WHERE
		T.IsE4Qualifier = 1 

EXEC usp_SubEventQualEngine_UpdateSubEventQualifier @PK_SubEvent, '##Q4', 0

IF OBJECT_ID('tempdb..##Q4', 'U') IS NOT NULL DROP TABLE ##Q4



EXEC dbo.usp_Utility_UpdateProcessingLog
@StoredProcedureName = @ProcName
,@StoredProcedureParameters = @ProcParamRecur
,@StartTime = @StartTimeRecur

/******************************************************************************  
 END PROCEDURE  
******************************************************************************/   
END
GO

