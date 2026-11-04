CREATE PROCEDURE [dbo].[usp_EventQual_MexicoMAP]
	@PK_Event INT = 18744,
	@DateToProcess DATE = NULL
AS
BEGIN  
  
/******************************************************************************  
OBJECT:  dbo.usp_EventQual_MexicoMAP
  
USE:  EXEC dbo.usp_EventQual_MexicoMAP --@PK_Event
  
DESCRIPTION:  
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
VERSIONS  
--------------------------------------------------------------------  
1 2017-12-14   OrlandoL   Initial  
2 2019-10-17   SushmaA	  SRE updates for NOLOCK, NOCOUNT, SELECT *
  
******************************************************************************/   
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON   
  
DECLARE @ProcName varchar(100)
 ,@ProcParamRecur varchar(100)
 ,@StartTimeRecur datetime
 ,@E1IncrementBy MONEY = 350
 ,@E2IncrementBy MONEY = 100
 ,@E3IncrementBy MONEY = 500
 ,@E4IncrementBy MONEY = 1000
 ,@CurrentMonth DATETIME = ISNULL(@DateToProcess,DATEADD(mm,DATEDIFF(mm,0,GETDATE()),0))
 ,@SQL NVARCHAR(MAX) = '' 

SET @ProcName = 'usp_EventQual_MexicoMAP'
SET @ProcParamRecur = CONVERT(VARCHAR,@PK_Event) 
SET @StartTimeRecur = GETUTCDATE() 


IF OBJECT_ID ('tempDB..#RPT_Temp', 'U')IS NOT NULL DROP TABLE #RPT_Temp

IF OBJECT_ID ('tempDB..#Temp', 'U')IS NOT NULL DROP TABLE #Temp

IF OBJECT_ID ('tempDB..#Metrics', 'U')IS NOT NULL DROP TABLE #Metrics

CREATE TABLE #RPT_Temp
(
     --PK int IDENTITY(1,1) PRIMARY KEY
	PK_Distributor INT PRIMARY KEY 
	,DistributorID VARCHAR(30) 
	,PK_Sponsor INT
	,SponsorID VARCHAR(30) 
	,SponsorName VARCHAR(100)
	,PK_FirstTAB INT
	,FirstTABID VARCHAR(30)
	,FirstTABName VARCHAR(100)
	,PK_Downline INT
	,DownlineID VARCHAR(30) 
	,FirstName VARCHAR(150)
	,LastName VARCHAR(150)
	,AppDate DATETIME
	,ContractAcceptanceDate DATETIME
	,ReinstatementDate DATETIME
	,QSQualDate DATETIME
	,SPQualDate DATETIME
	,Email VARCHAR(150)
	,Phone VARCHAR(200)
	,Team VARCHAR(50)
	,COP VARCHAR(5)
	,COPISO VARCHAR(5)
	,DSLevel INT
	,IsInactive BIT DEFAULT 0
	,Month1PPV MONEY DEFAULT 0
	,Month2PPV MONEY DEFAULT 0
	,Month3PPV MONEY DEFAULT 0
	,Month4PPV MONEY DEFAULT 0
	,Month5PPV MONEY DEFAULT 0
	,Month6PPV MONEY DEFAULT 0
	,Month3DLV MONEY DEFAULT 0
	,Month4DLV MONEY DEFAULT 0
	,Month5DLV MONEY DEFAULT 0
	,Month6DLV MONEY DEFAULT 0
	,Month3TV MONEY DEFAULT 0
	,Month4TV MONEY DEFAULT 0
	,Month5TV MONEY DEFAULT 0
	,Month6TV MONEY DEFAULT 0
	,DownlineE1 INT DEFAULT 0
	,DownlineE2 INT DEFAULT 0
	,Cut100 INT DEFAULT 0
	,Cut350 INT DEFAULT 0
	,Cut500 INT DEFAULT 0
	,Cut1000 INT DEFAULT 0
	,ModifiedDate DATETIME
	,QualifiedPeriod100 INT DEFAULT 0
	,QualifiedPeriod350 INT DEFAULT 0
	,QualifiedPeriod500 INT DEFAULT 0
	,QualifiedPeriod1000 INT DEFAULT 0
	,QualifiedMonth100 DATETIME 
	,QualifiedMonth350 DATETIME 
	,QualifiedMonth500 DATETIME 
	,QualifiedMonth1000 DATETIME 
	,CurrMonthVolReqd100 MONEY DEFAULT 0
	,CurrMonthVolReqd350 MONEY DEFAULT 0
	,CurrMonthVolReqd500 MONEY DEFAULT 0
	,CurrMonthVolReqd1000 MONEY DEFAULT 0
	,IsE1Qualifier int DEFAULT 0
	,IsE2Qualifier int DEFAULT 0
	,IsE3Qualifier int DEFAULT 0
	,IsE4Qualifier int DEFAULT 0
	,IsE5Qualifier int DEFAULT 0
	,IsE6Qualifier int DEFAULT 0
	,IsE7Qualifier int DEFAULT 0
	,IsE8Qualifier int DEFAULT 0
	,IsE9Qualifier int DEFAULT 0
	,IsE10Qualifier int DEFAULT 0
	,IsE11Qualifier AS (CASE WHEN IsE1Qualifier = 1 OR IsE2Qualifier = 1 OR IsE3Qualifier = 1 OR IsE4Qualifier = 1 OR IsE5Qualifier = 1 OR IsE6Qualifier = 1 OR IsE7Qualifier = 1 OR IsE8Qualifier = 1 OR IsE9Qualifier = 1 OR IsE10Qualifier = 1 THEN 1 ELSE 0 END)
)

/******************************************************************************
Insert All DS from Mexico 
*******************************************************************************/
-- PK_Distributor in Bizworks is different from nDistributorID in v_Distributor in  So you have to join by DistributorID
-- If you are in the lineage, you are not deleted. Lineage is only built for not deleted people
-- Downlines should also be only from those specific country of processing 
-- Should also be only for downlines that are visible to the upline


CREATE TABLE #Temp
(
	DistributorID VARCHAR(20)
)

INSERT INTO #Temp
(
	DistributorID
)


SELECT
	DS.DistributorID
FROM
(
				SELECT 
					DS.DistributorID
				FROM
					PubData.dbo.factDSFinancial_ctry F WITH (NOLOCK)
				INNER JOIN
					PubEvents.dbo.dimDistributor DS WITH (NOLOCK)
				ON
					F.DistributorID = DS.DistributorID
				WHERE
					DS.StatusCode = 'COMPLETE'
					AND
					(DATEADD(DD,-DAY(CONVERT(DATE,CONVERT(VARCHAR(10),DS.ApplicationDate),112))+1,CONVERT(DATE,CONVERT(DATE,CONVERT(VARCHAR(10),DS.ApplicationDate),112))) BETWEEN CONVERT(VARCHAR(8),DATEADD(MM,-2,@CurrentMonth), 112) AND CONVERT(VARCHAR(8),DATEADD(MM,-1,@CurrentMonth), 112)
					AND F.RoyaltyMonth BETWEEN DATEADD(MM,-2,@CurrentMonth) AND DATEADD(MM,-1,@CurrentMonth) )
					AND DS.CountryCode_COP IN ('MX')	
					AND (DS.TypeCode = 'DS' OR (DS.TypeCode = 'SP' AND DS.SPQualDate > CONVERT(VARCHAR(8),DATEADD(MM,-2,@CurrentMonth), 112)))
				Group By DS.DistributorID
				HAVING SUM(CASE WHEN F.CountryCode IN ('US','PR') AND F.RoyaltyMonth >= '2017-05-01' THEN (ISNULL(F.DV,0) - ISNULL(F.MB_POINTS,0)) ELSE F.PPV END) <= 0
				UNION
				SELECT 
					DS.DistributorID
				FROM
					PubData.dbo.factDSFinancial_ctry F WITH (NOLOCK)
				INNER JOIN
					PubEvents.dbo.dimDistributor DS WITH (NOLOCK)
				ON
					F.DistributorID = DS.DistributorID
				WHERE
					DS.StatusCode = 'COMPLETE'
					AND 
					(DATEADD(DD,-DAY(CONVERT(DATE,CONVERT(VARCHAR(10),DS.ApplicationDate),112))+1,CONVERT(DATE,CONVERT(DATE,CONVERT(VARCHAR(10),DS.ApplicationDate),112))) <= CONVERT(VARCHAR(8),DATEADD(MM,-5,@CurrentMonth), 112) 
					AND F.RoyaltyMonth BETWEEN DATEADD(MM,-5,@CurrentMonth) AND DATEADD(MM,-3,@CurrentMonth))
					AND DS.CountryCode_COP IN ('MX')	
					AND (DS.TypeCode = 'DS' OR (DS.TypeCode = 'SP' AND DS.SPQualDate > CONVERT(VARCHAR(8),DATEADD(MM,-2,@CurrentMonth), 112)))
				Group By DS.DistributorID
				HAVING SUM(CASE WHEN F.CountryCode IN ('US','PR') AND F.RoyaltyMonth >= '2017-05-01' THEN (ISNULL(F.DV,0) - ISNULL(F.MB_POINTS,0)) ELSE F.PPV END) <= 0
				UNION
				SELECT 
					DS.DistributorID
				FROM
					PubData.dbo.factDSFinancial_ctry F WITH (NOLOCK)
				INNER JOIN
					PubEvents.dbo.dimDistributor DS WITH (NOLOCK)
				ON
					F.DistributorID = DS.DistributorID
				WHERE
					DS.StatusCode = 'COMPLETE'
					AND 
					(DATEADD(DD,-DAY(CONVERT(DATE,CONVERT(VARCHAR(10),DS.ApplicationDate),112))+1,CONVERT(DATE,CONVERT(DATE,CONVERT(VARCHAR(10),DS.ApplicationDate),112))) BETWEEN CONVERT(VARCHAR(8),DATEADD(MM,-4,@CurrentMonth), 112) AND CONVERT(VARCHAR(8),DATEADD(MM,-3,@CurrentMonth), 112) 
					AND F.RoyaltyMonth BETWEEN DATEADD(MM,-4,@CurrentMonth) AND DATEADD(MM,-3,@CurrentMonth) )
					AND DS.CountryCode_COP IN ('MX')	
					AND (DS.TypeCode = 'DS' OR (DS.TypeCode = 'SP' AND DS.SPQualDate > CONVERT(VARCHAR(8),DATEADD(MM,-2,@CurrentMonth), 112)))
				Group By DS.DistributorID
				HAVING SUM(CASE WHEN F.CountryCode IN ('US','PR') AND F.RoyaltyMonth >= '2017-05-01' THEN (ISNULL(F.DV,0) - ISNULL(F.MB_POINTS,0)) ELSE F.PPV END) <= 0
				UNION
				SELECT 
					DS.DistributorID
				FROM
					PubData.dbo.factDSFinancial_ctry F WITH (NOLOCK)
				INNER JOIN
					PubEvents.dbo.dimDistributor DS WITH (NOLOCK)
				ON
					F.DistributorID = DS.DistributorID
				WHERE
					DS.StatusCode = 'COMPLETE'
					AND 
					(DATEADD(DD,-DAY(CONVERT(DATE,CONVERT(VARCHAR(10),DS.ApplicationDate),112))+1,CONVERT(DATE,CONVERT(DATE,CONVERT(VARCHAR(10),DS.ApplicationDate),112))) <= CONVERT(VARCHAR(8),DATEADD(MM,-4,@CurrentMonth), 112) 
					AND F.RoyaltyMonth BETWEEN DATEADD(MM,-4,@CurrentMonth) AND DATEADD(MM,-2,@CurrentMonth) )
					AND DS.CountryCode_COP IN ('MX')	
					AND (DS.TypeCode = 'DS' OR (DS.TypeCode = 'SP' AND DS.SPQualDate > CONVERT(VARCHAR(8),DATEADD(MM,-2,@CurrentMonth), 112)))
				Group By DS.DistributorID
				HAVING SUM(CASE WHEN F.CountryCode IN ('US','PR') AND F.RoyaltyMonth >= '2017-05-01' THEN (ISNULL(F.DV,0) - ISNULL(F.MB_POINTS,0)) ELSE F.PPV END) <= 0
				UNION
				SELECT 
					DS.DistributorID
				FROM
					PubData.dbo.factDSFinancial_ctry F WITH (NOLOCK)
				INNER JOIN
					PubEvents.dbo.dimDistributor DS WITH (NOLOCK)
				ON
					F.DistributorID = DS.DistributorID
				WHERE
					DS.StatusCode = 'COMPLETE'
					AND 
					(DATEADD(DD,-DAY(CONVERT(DATE,CONVERT(VARCHAR(10),DS.ApplicationDate),112))+1,CONVERT(DATE,CONVERT(DATE,CONVERT(VARCHAR(10),DS.ApplicationDate),112))) <= CONVERT(VARCHAR(8),DATEADD(MM,-3,@CurrentMonth), 112) 
					AND F.RoyaltyMonth BETWEEN DATEADD(MM,-3,@CurrentMonth) AND DATEADD(MM,-1,@CurrentMonth) )
					AND DS.CountryCode_COP IN ('MX')	
					AND (DS.TypeCode = 'DS' OR (DS.TypeCode = 'SP' AND DS.SPQualDate > CONVERT(VARCHAR(8),DATEADD(MM,-2,@CurrentMonth), 112)))
				Group By DS.DistributorID
				HAVING SUM(CASE WHEN F.CountryCode IN ('US','PR') AND F.RoyaltyMonth >= '2017-05-01' THEN (ISNULL(F.DV,0) - ISNULL(F.MB_POINTS,0)) ELSE F.PPV END) <= 0

				) DS



INSERT
      #RPT_Temp
(
       PK_Distributor
      ,DistributorID
	  ,PK_Downline
	  ,DownlineID
	  ,PK_Sponsor 
	  ,SponsorID 
	  ,DSLevel
	  ,AppDate
	  ,ContractAcceptanceDate
	  ,QSQualDate
	  ,SPQualDate
	  ,Team
	  ,COP
	  ,COPISO
	  ,FirstName 
	  ,LastName 
	  ,Phone
	  ,IsInactive
)
SELECT DS.nDistributorID
      ,DS.sDistributorID
	  ,DS.nDistributorID
	  ,DS.sDistributorID 
	  ,DS.nSponsorID 
	  ,DS.sSponsorID 
	  ,1
	  ,DS.dApplication 
	  ,DS.ContractAcceptanceDate
	  ,DS.dQSQualification
	  ,DS.dSupervisorQualification
	  ,DS.sSubTeam
	  ,DS.sDistributorCountryProcessingCode 
	  ,C.sCountryCodeISO
	  ,DS.sFirstName 
	  ,DS.sLastName 
	  ,DS.Phone
	  ,0
FROM  
    dbo.v_Distributor DS (NOLOCK)
INNER JOIN
	v_Countries C
	ON 
	nDistributorCountryProcessingID = nCountryID
WHERE
	StatusCode = 'COMPLETE'
	AND
    Ds.sDistributorCountryProcessingCode = ('MX')
	AND
	(DS.sType IN ('DS') OR DS.sType IN ('SP'))
	AND
	dApplication >= DATEADD(MM,-3,@CurrentMonth)
	AND
	NOT EXISTS (SELECT 1 FROM #Temp T WHERE DS.sDistributorID = T.DistributorID)
UNION
SELECT 
	  D.PK_Distributor
      ,D.DistributorID
	  ,D.PK_Distributor
	  ,D.DistributorID 
	  ,D.PK_Sponsor 
	  ,D.SponsorID 
	  ,1
	  ,CONVERT(DATETIME,CONVERT(VARCHAR, D.ApplicationDate),112) AS dApplication
	  ,CASE WHEN D.ContractAcceptanceDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, D.ContractAcceptanceDate),112) END AS ContractAcceptanceDate
	  ,CASE WHEN D.QSQualDate = 19000101 THEN NULL WHEN D.QSQualDate IS NULL THEN NULL ELSE DATEADD(M,DATEDIFF(M,0,CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112)),0) END AS QSQualDate
	  ,CASE WHEN D.SPQualDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, D.SPQualDate),112) END AS SPQualDate
	  ,D.SubTypeCode
	  ,C.CountryCode 
	  ,C.CountryCodeISO
	  ,D.FirstName 
	  ,D.LastName 
	  ,CASE WHEN LEN(RTRIM(LTRIM(CI.CellPhone))) <> 0 THEN CI.CellPhone
	      WHEN LEN(RTRIM(LTRIM(CI.DayPhone))) <> 0 THEN CI.DayPhone
	      WHEN LEN(RTRIM(LTRIM(CI.EvePhone))) <> 0 THEN CI.EvePhone
	 END AS Phone
	 ,1
FROM
	#Temp DS
INNER JOIN
	pubEvents.dbo.dimDistributor D WITH (NOLOCK)
ON
	DS.DistributorID = D.DistributorID
INNER JOIN
	pubEvents.dbo.dimCountry C WITH (NOLOCK)
ON
	D.PK_COP = C.PK_Country 
LEFT JOIN
	pubEvents.dbo.dimDSContactInfo CI WITH (NOLOCK)
ON
D.PK_Distributor = CI.PK_Distributor
 
CREATE INDEX IX_#RPT_Temp_PK_Distributor ON #RPT_Temp(PK_Distributor)
CREATE INDEX IX_#RPT_Temp_DistributorID ON #RPT_Temp(DistributorID)
CREATE INDEX IX_#RPT_Temp_PK_Downline ON #RPT_Temp(PK_Downline)
CREATE INDEX IX_#RPT_Temp_DowlineID ON #RPT_Temp(DownlineID)
CREATE INDEX IX_#RPT_Temp_DSLevel ON #RPT_Temp(DSLevel)
CREATE INDEX IX_#RPT_Temp_COPISO ON #RPT_Temp(COPISO)


/*************************************************************************************************
	UPDATE Volume columns based on the SUM of the metrics vailable(PPV,DLV,GV) achieved per MB
*************************************************************************************************/

CREATE TABLE #Metrics
(
	PK int IDENTITY(1,1) PRIMARY KEY
	,DistributorID VARCHAR(30)
	,RoyaltyMonth DATE
	,PPV MONEY DEFAULT 0
	,DLV MONEY DEFAULT 0
	,TV MONEY DEFAULT 0
)

INSERT
      #Metrics
(
       DistributorID
      ,RoyaltyMonth
	  ,PPV 
	  ,DLV
	  ,TV
)


SELECT 
	  D.DistributorID
	  ,DS.RoyaltyMonth
	  ,DS.PPV
	  ,DS.DLV
	  ,DS.TV
FROM
	(
				SELECT 
					DS.DistributorID
					,F.RoyaltyMonth--CONVERT(DATE, CONVERT(VARCHAR(10), F.RoyaltyMonth) + '01') AS RoyaltyMonth
					,SUM(CASE WHEN F.CountryCode IN ('US','PR') THEN (ISNULL(F.DV,0) - ISNULL(F.MB_POINTS,0)) ELSE F.PPV END) AS PPV
					,SUM(CASE WHEN F.CountryCode IN ('US','PR') THEN F.DLV_DV ELSE F.DLV END) AS DLV 
					,SUM(CASE WHEN F.CountryCode IN ('US','PR') THEN CASE WHEN ISNULL(DS.QSQualDate,DS.SPQualDate) <= CAST(CONVERT(VARCHAR(8),F.RoyaltyMonth, 112) AS INT) AND DS.SPQualDate <> 19000101 THEN ISNULL(F.PV_DV,0) + ISNULL(F.GV_DV,0) ELSE (ISNULL(F.DV,0) - ISNULL(F.MB_POINTS,0)) + ISNULL(F.DLV_DV,0) END ELSE CASE WHEN ISNULL(DS.QSQualDate,DS.SPQualDate) <= CAST(CONVERT(VARCHAR(8),F.RoyaltyMonth, 112) AS INT) AND DS.SPQualDate <> 19000101 THEN F.TV ELSE ISNULL(F.PPV,0) + ISNULL(F.DLV,0) END END) AS TV
				FROM
					PubData.dbo.factDSFinancial_ctry F WITH (NOLOCK)
				INNER JOIN
					PubEvents.dbo.dimDistributor DS WITH (NOLOCK)
				ON
					F.DistributorID = DS.DistributorID
				Where
					F.RoyaltyMonth BETWEEN DATEADD(MM,-5,@CurrentMonth) AND @CurrentMonth
					AND
					DS.StatusCode = 'COMPLETE'
					AND
					DS.CountryCode_COP IN ('MX')
					AND (DS.TypeCode = 'DS' OR (DS.TypeCode = 'SP'))
				Group By DS.DistributorID,F.RoyaltyMonth
				) DS
			INNER JOIN
				pubEvents.dbo.dimDistributor D WITH (NOLOCK)
			ON
				DS.DistributorID = D.DistributorID
			INNER JOIN
				pubEvents.dbo.dimCountry C WITH (NOLOCK)
			ON
				D.PK_COP = C.PK_Country 
			LEFT JOIN
				pubEvents.dbo.dimDSContactInfo CI WITH (NOLOCK)
			ON
				D.PK_Distributor = CI.PK_Distributor

CREATE INDEX IX_#Metrics_PK_Distributor ON #Metrics(DistributorID,RoyaltyMonth)

/*************************************************************************************************
	UPDATE Volume columns based on the SUM of the metrics vailable(PPV,DLV,GV) achieved per MB
*************************************************************************************************/
UPDATE 
	T
SET
	Month1PPV = M.PPV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = DATEADD(MM,-5,@CurrentMonth)

UPDATE 
	T
SET
	Month2PPV = M.PPV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = DATEADD(MM,-4,@CurrentMonth)

UPDATE 
	T
SET
	Month3PPV = M.PPV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = DATEADD(MM,-3,@CurrentMonth)

UPDATE 
	T
SET
	Month4PPV = M.PPV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = DATEADD(MM,-2,@CurrentMonth)

UPDATE 
	T
SET
	Month5PPV = M.PPV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = DATEADD(MM,-1,@CurrentMonth)

UPDATE 
	T
SET
	Month6PPV = M.PPV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = @CurrentMonth

/******************************************************************************/
UPDATE 
	T
SET
	Month3DLV = M.DLV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = DATEADD(MM,-3,@CurrentMonth)

UPDATE 
	T
SET
	Month4DLV = M.DLV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = DATEADD(MM,-2,@CurrentMonth)

UPDATE 
	T
SET
	Month5DLV = M.DLV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = DATEADD(MM,-1,@CurrentMonth)

UPDATE 
	T
SET
	Month6DLV = M.DLV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = @CurrentMonth

/***********************************************************************************/

UPDATE 
	T
SET
	Month3TV = M.TV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = DATEADD(MM,-3,@CurrentMonth)

UPDATE 
	T
SET
	Month4TV = M.TV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = DATEADD(MM,-2,@CurrentMonth)

UPDATE 
	T
SET
	Month5TV = M.TV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = DATEADD(MM,-1,@CurrentMonth)

UPDATE 
	T
SET
	Month6TV = M.TV 
FROM
	#RPT_Temp T
INNER JOIN
	#Metrics M
ON
	T.DistributorID = M.DistributorID
	AND
	M.RoyaltyMonth = @CurrentMonth


	
/******************************************************************************
	Update Qualifiers 
*******************************************************************************/
UPDATE
	T
SET
	IsE1Qualifier = CASE WHEN (AppDate = DATEADD(MM,-2,@CurrentMonth) AND T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy) THEN 1 ELSE 0 END
	,QualifiedPeriod100 = CASE WHEN T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy THEN MONTH(DATEADD(M,-2,@CurrentMonth)) ELSE 0 END
	,QualifiedMonth100 = CASE WHEN T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy THEN DATEADD(M,-2,@CurrentMonth) ELSE NULL END
	,Cut100 = CASE WHEN T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy THEN 3
				  WHEN T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV < @E2IncrementBy THEN 3
				  WHEN T.Month4PPV < @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy THEN 2
				  WHEN T.Month4PPV < @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV < @E2IncrementBy THEN 2
				  WHEN AppDate BETWEEN DATEADD(MM,-2,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-1,@CurrentMonth)) AND T.Month4PPV = 0 AND T.Month5PPV = 0 AND (T.Month6PPV < @E2IncrementBy OR T.Month6PPV >= @E2IncrementBy) THEN 1
				  WHEN AppDate BETWEEN DATEADD(MM,-1,@CurrentMonth) AND DATEADD(DD,-1,@CurrentMonth) AND T.Month5PPV < @E2IncrementBy THEN 1
				  WHEN T.Month4PPV = 0 AND T.Month5PPV = 0 AND (T.Month6PPV < @E2IncrementBy OR T.Month6PPV >= @E2IncrementBy) THEN 1
			 ELSE 0 END
	,CurrMonthVolReqd100 = CASE WHEN T.Month6PPV >= @E2IncrementBy THEN 0 ELSE CASE WHEN T.Month6PPV < 0 THEN @E2IncrementBy ELSE @E2IncrementBy-T.Month6PPV END END
	,IsE2Qualifier = CASE WHEN (AppDate BETWEEN DATEADD(MM,-3,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-2,@CurrentMonth)) AND T.Month3PPV < @E2IncrementBy AND T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy) THEN 1 ELSE 0 END
	,IsE3Qualifier = CASE WHEN (AppDate BETWEEN DATEADD(MM,-4,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-3,@CurrentMonth)) AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy) 
							   OR (AppDate <= DATEADD(MM,-5,@CurrentMonth) AND T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy) THEN 1 ELSE 0 END
FROM 
	#RPT_Temp  T
WHERE
	SPQualDate IS NULL OR SPQualDate >= DATEADD(MM,-1,@CurrentMonth)



UPDATE
	T
SET
	IsE4Qualifier = CASE WHEN (AppDate = DATEADD(MM,-2,@CurrentMonth) AND T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy) THEN 1 ELSE 0 END
	,QualifiedPeriod350 = CASE WHEN T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy THEN MONTH(DATEADD(M,-2,@CurrentMonth)) ELSE 0 END
	,QualifiedMonth350 = CASE WHEN T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy THEN DATEADD(M,-2,@CurrentMonth) ELSE NULL END
	,Cut350 = CASE WHEN T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy THEN 3
				  WHEN T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV < @E1IncrementBy THEN 3
				  WHEN T.Month4PPV < @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy THEN 2
				  WHEN T.Month4PPV < @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV < @E1IncrementBy THEN 2
				  WHEN AppDate BETWEEN DATEADD(MM,-2,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-1,@CurrentMonth)) AND T.Month4PPV = 0 AND T.Month5PPV = 0 AND (T.Month6PPV < @E1IncrementBy OR T.Month6PPV >= @E1IncrementBy) THEN 1
				  WHEN AppDate BETWEEN DATEADD(MM,-1,@CurrentMonth) AND DATEADD(DD,-1,@CurrentMonth) AND T.Month5PPV < @E1IncrementBy THEN 1
				  WHEN T.Month4PPV = 0 AND T.Month5PPV = 0 AND (T.Month6PPV < @E1IncrementBy OR T.Month6PPV >= @E1IncrementBy) THEN 1
			 ELSE 0 END
	,CurrMonthVolReqd350 = CASE WHEN T.Month6PPV >= @E1IncrementBy THEN 0 ELSE CASE WHEN T.Month6PPV < 0 THEN @E1IncrementBy ELSE @E1IncrementBy-T.Month6PPV END END
	,IsE5Qualifier = CASE WHEN (AppDate BETWEEN DATEADD(MM,-3,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-2,@CurrentMonth)) AND T.Month3PPV < @E1IncrementBy AND T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy) THEN 1 ELSE 0 END
	,IsE6Qualifier = CASE WHEN (AppDate BETWEEN DATEADD(MM,-4,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-3,@CurrentMonth)) AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy) 
							   OR (AppDate <= DATEADD(MM,-5,@CurrentMonth) AND T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy) THEN 1 ELSE 0 END

FROM 
	#RPT_Temp  T
WHERE
	SPQualDate IS NULL OR SPQualDate >= DATEADD(MM,-1,@CurrentMonth)



UPDATE
	T
SET
	IsE7Qualifier = CASE WHEN (AppDate = DATEADD(MM,-2,@CurrentMonth) AND T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy) THEN 1 ELSE 0 END
	,QualifiedPeriod500 = CASE WHEN T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy THEN MONTH(DATEADD(M,-2,@CurrentMonth)) ELSE 0 END
	,QualifiedMonth500 = CASE WHEN T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy THEN DATEADD(M,-2,@CurrentMonth) ELSE NULL END
	,Cut500 = CASE WHEN T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy THEN 3
				  WHEN T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV < @E3IncrementBy THEN 3
				  WHEN T.Month4PPV < @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy THEN 2
				  WHEN T.Month4PPV < @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV < @E3IncrementBy THEN 2
				  WHEN AppDate BETWEEN DATEADD(MM,-2,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-1,@CurrentMonth)) AND T.Month4PPV = 0 AND T.Month5PPV = 0 AND (T.Month6PPV < @E3IncrementBy OR T.Month6PPV >= @E3IncrementBy) THEN 1
				  WHEN AppDate BETWEEN DATEADD(MM,-1,@CurrentMonth) AND DATEADD(DD,-1,@CurrentMonth) AND T.Month5PPV < @E3IncrementBy THEN 1
				  WHEN T.Month4PPV = 0 AND T.Month5PPV = 0 AND (T.Month6PPV < @E3IncrementBy OR T.Month6PPV >= @E3IncrementBy) THEN 1
			 ELSE 0 END
	,CurrMonthVolReqd500 = CASE WHEN T.Month6PPV >= @E3IncrementBy THEN 0 ELSE CASE WHEN T.Month6PPV < 0 THEN @E3IncrementBy ELSE @E3IncrementBy-T.Month6PPV END END
	,IsE8Qualifier = CASE WHEN (AppDate BETWEEN DATEADD(MM,-3,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-2,@CurrentMonth)) AND T.Month3PPV < @E3IncrementBy AND T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy) THEN 1 ELSE 0 END
FROM 
	#RPT_Temp  T
WHERE
	(SPQualDate IS NULL OR SPQualDate >= DATEADD(MM,-1,@CurrentMonth))
	AND
	AppDate >= DATEADD(MM,-3,@CurrentMonth)


UPDATE
	T
SET
	IsE9Qualifier = CASE WHEN (AppDate = DATEADD(MM,-2,@CurrentMonth) AND T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy)
							  AND (T.Month4TV >= @E4IncrementBy AND T.Month5TV >= @E4IncrementBy AND T.Month6TV >= @E4IncrementBy) THEN 1 ELSE 0 END
	,QualifiedPeriod1000 = CASE WHEN (T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy)
							  AND (T.Month4TV >= @E4IncrementBy AND T.Month5TV >= @E4IncrementBy AND T.Month6TV >= @E4IncrementBy) THEN MONTH(DATEADD(M,-2,@CurrentMonth)) ELSE 0 END
	,QualifiedMonth1000 = CASE WHEN (T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy)
							  AND (T.Month4TV >= @E4IncrementBy AND T.Month5TV >= @E4IncrementBy AND T.Month6TV >= @E4IncrementBy) THEN DATEADD(M,-2,@CurrentMonth) ELSE NULL END
	,Cut1000 = CASE WHEN T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy AND 
						 T.Month4TV >= @E4IncrementBy AND T.Month5TV >= @E4IncrementBy AND T.Month6TV >= @E4IncrementBy THEN 3
				  WHEN T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND
				       T.Month4TV >= @E4IncrementBy AND T.Month5TV >= @E4IncrementBy AND T.Month6TV < @E4IncrementBy THEN 3
				  WHEN T.Month4PPV < @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy AND
				       T.Month4TV < @E4IncrementBy AND T.Month5TV >= @E4IncrementBy AND T.Month6TV >= @E4IncrementBy THEN 2
				  WHEN T.Month4PPV < @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV < @E3IncrementBy AND
				       T.Month4TV < @E4IncrementBy AND T.Month5TV >= @E4IncrementBy AND T.Month6TV < @E4IncrementBy THEN 2
				  WHEN AppDate BETWEEN DATEADD(MM,-2,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-1,@CurrentMonth)) AND T.Month4TV = 0 AND T.Month5TV = 0 AND (T.Month6TV < @E4IncrementBy OR T.Month6TV >= @E4IncrementBy) THEN 1
				  WHEN AppDate BETWEEN DATEADD(MM,-1,@CurrentMonth) AND DATEADD(DD,-1,@CurrentMonth) AND T.Month5TV < @E4IncrementBy THEN 1
				  WHEN T.Month4TV = 0 AND T.Month5TV = 0 AND (T.Month6TV < @E4IncrementBy OR T.Month6TV >= @E4IncrementBy) THEN 1
			 ELSE 0 END
	,CurrMonthVolReqd1000 = CASE WHEN T.Month6TV >= @E4IncrementBy THEN 0 ELSE CASE WHEN T.Month6TV < 0 THEN @E4IncrementBy ELSE @E4IncrementBy-(T.Month6TV) END END
	,IsE10Qualifier = CASE WHEN (AppDate BETWEEN DATEADD(MM,-3,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-2,@CurrentMonth)) AND T.Month3PPV < @E2IncrementBy AND T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy)
								AND (T.Month4TV >= @E4IncrementBy AND T.Month5TV >= @E4IncrementBy AND T.Month6TV >= @E4IncrementBy)  THEN 1 ELSE 0 END
FROM 
	#RPT_Temp  T
WHERE
	(ISNULL(QSQualDate,SPQualDate) IS NULL OR ISNULL(QSQualDate,SPQualDate) >= DATEADD(MM,-1,@CurrentMonth))
	AND
	AppDate >= DATEADD(MM,-3,@CurrentMonth)


/*************************************************************************************************
	UPDATE Flags for those who can't qualify anymore
*************************************************************************************************/
UPDATE
	T
SET
	 QualifiedPeriod1000 = CASE WHEN (T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy)
							  AND (T.Month4TV >= @E4IncrementBy AND T.Month5TV >= @E4IncrementBy AND T.Month6TV >= @E4IncrementBy) THEN 0 ELSE QualifiedPeriod1000 END
	,QualifiedMonth1000 = CASE WHEN (T.Month4PPV >= @E3IncrementBy AND T.Month5PPV >= @E3IncrementBy AND T.Month6PPV >= @E3IncrementBy)
							  AND (T.Month4TV >= @E4IncrementBy AND T.Month5TV >= @E4IncrementBy AND T.Month6TV >= @E4IncrementBy) THEN NULL ELSE QualifiedMonth1000 END
FROM 
	#RPT_Temp  T
WHERE
	AppDate BETWEEN DATEADD(MM,-3,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-2,@CurrentMonth)) AND T.Month3TV >= @E2IncrementBy

/*************************************************************************************************/
UPDATE
	T
SET
	IsE1Qualifier = CASE WHEN ( T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy) THEN 1 ELSE IsE1Qualifier END
	,QualifiedPeriod100 = CASE WHEN ( T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy)  THEN MONTH(DATEADD(M,-3,@CurrentMonth)) ELSE QualifiedPeriod100 END
	,QualifiedMonth100 = CASE WHEN ( T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy)  THEN DATEADD(M,-2,@CurrentMonth) ELSE QualifiedMonth100 END
	,Cut100 = CASE WHEN (T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy)  THEN 3 
				   WHEN (T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV >= @E2IncrementBy AND T.Month5PPV >= @E2IncrementBy) THEN 3
	               WHEN (T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV = 0 AND T.Month5PPV >= @E2IncrementBy AND T.Month6PPV >= @E2IncrementBy) THEN 2
				   WHEN (T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV = 0 AND T.Month5PPV >= @E2IncrementBy) THEN 2
				   WHEN (T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV = 0 AND T.Month5PPV = 0 AND T.Month6PPV >= @E2IncrementBy) THEN 1
				   WHEN (T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV = 0 AND T.Month5PPV = 0 AND T.Month6PPV < @E2IncrementBy) THEN 1
				   ELSE 0 END 
	,CurrMonthVolReqd100 = CASE WHEN T.Month6PPV >= @E2IncrementBy THEN 0 ELSE CASE WHEN T.Month6PPV < 0 THEN @E2IncrementBy ELSE @E2IncrementBy-T.Month6PPV END END
FROM 
	#RPT_Temp  T
WHERE
	IsInactive = 1

UPDATE
	T
SET
	IsE4Qualifier = CASE WHEN ( T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy) THEN 1 ELSE IsE4Qualifier END
	,QualifiedPeriod350 = CASE WHEN ( T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy)  THEN MONTH(DATEADD(M,-3,@CurrentMonth)) ELSE QualifiedPeriod350 END
	,QualifiedMonth350 = CASE WHEN ( T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy)  THEN DATEADD(M,-2,@CurrentMonth) ELSE QualifiedMonth350 END
	,Cut350 = CASE WHEN (T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy)  THEN 3 
				   WHEN (T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV >= @E1IncrementBy AND T.Month5PPV >= @E1IncrementBy) THEN 3
	               WHEN (T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV = 0 AND T.Month5PPV >= @E1IncrementBy AND T.Month6PPV >= @E1IncrementBy) THEN 2
				   WHEN (T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV = 0 AND T.Month5PPV >= @E1IncrementBy) THEN 2
				   WHEN (T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV = 0 AND T.Month5PPV = 0 AND T.Month6PPV >= @E1IncrementBy) THEN 1
				   WHEN (T.Month1PPV = 0 AND T.Month2PPV = 0 AND T.Month3PPV = 0 AND T.Month4PPV = 0 AND T.Month5PPV = 0 AND T.Month6PPV < @E1IncrementBy) THEN 1
				   ELSE 0 END 
	,CurrMonthVolReqd350 = CASE WHEN T.Month6PPV >= @E2IncrementBy THEN 0 ELSE CASE WHEN T.Month6PPV < 0 THEN @E2IncrementBy ELSE @E2IncrementBy-T.Month6PPV END END
FROM 
	#RPT_Temp  T
WHERE
	IsInactive = 1


/*************************************************************************************************
	UPDATE Sponsor first line E1 or E2 qualifiers 
*************************************************************************************************/
/*
UPDATE
	T
SET 
	T.DownlineE1 = A.Total
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
		#RPT_Temp R
	ON
		DL.PK_DSDownline = R.PK_Distributor
	WHERE
		R.IsE1Qualifier = 1 AND R.AppDate BETWEEN DATEADD(MM,-2,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-1,@CurrentMonth))
		AND
		DL.DSLevelFromUL = 2
	GROUP BY
		DL.PK_Distributor
) A
ON
	T.PK_Sponsor = A.PK_Distributor


UPDATE
	T
SET 
	T.DownlineE2 = A.Total
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
		#RPT_Temp R
	ON
		DL.PK_DSDownline = R.PK_Distributor
	WHERE
		R.IsE2Qualifier = 1 AND R.AppDate BETWEEN DATEADD(MM,-2,@CurrentMonth) AND DATEADD(DD,-1,DATEADD(MM,-1,@CurrentMonth))
		AND
		DL.DSLevelFromUL = 2
	GROUP BY
		DL.PK_Distributor
) A
ON
	T.PK_Sponsor = A.PK_Distributor
   	 

/******************************************************************************
	Update Qualifiers to E3 and E4
*******************************************************************************/	 
UPDATE
	T
SET
	IsE3Qualifier = 1
FROM 
	#RPT_Temp  T
WHERE
	DownlineE1 >= 2

UPDATE
	T
SET
	IsE4Qualifier = 1
FROM 
	#RPT_Temp  T
WHERE
	DownlineE2 >= 2
*/
					  
/******************************************************************************
      update distributor E-Mail information
******************************************************************************/
UPDATE
      T
SET
 Email = LEFT(COALESCE(D.sString,''),100)
FROM
      #RPT_Temp  T
INNER JOIN
      v_DistributorEmail D (NOLOCK)
      ON
        T.PK_Downline = D.nDistributorIDFK
 
 /******************************************************************************
      update Sponsor Name
******************************************************************************/
UPDATE
      T
SET
	  SponsorName = COALESCE(D.sFirstName,'') +' '+ COALESCE(D.sLastName,'') 
	  ,ModifiedDate = GETDATE()
FROM
      #RPT_Temp T
INNER JOIN
      dbo.v_Distributor D (NOLOCK)
ON
	  T.PK_Sponsor = D.nDistributorID

/******************************************************************************
      update TAB info
******************************************************************************/  
UPDATE
	T 
SET
	PK_FirstTAB = DUL.FIRSTUPLINETAB
	,FirstTABID = D.DistributorID
	,FirstTABName = ISNULL(D.FirstName,'')+ ' '+ISNULL(D.LastName,'')
FROM 
	#RPT_Temp T
INNER JOIN
	pubEvents.dbo.DIMDSLNGUPLINE DUL WITH (NOLOCK)
ON
	T.PK_Distributor = DUL.PK_DISTRIBUTOR AND DUL.ISVISIBLEUPLINETAB = 1
INNER JOIN
	pubEvents.dbo.dimDistributor D WITH (NOLOCK)
ON
	DUL.FIRSTUPLINETAB = D.PK_Distributor

/******************************************************
		CREATE WorkTable
*******************************************************/

IF OBJECT_ID('WRK_MexicoMAP2017', 'U') IS NOT NULL 
BEGIN
	;
	MERGE INTO dbo.WRK_MexicoMAP2017 t
	USING #RPT_Temp s
		ON t.PK_Distributor = s.PK_Distributor
	WHEN NOT MATCHED THEN 
		INSERT 
		(
			PK_Distributor
			,DistributorID  
			,PK_Sponsor 
			,SponsorID 
			,SponsorName
			,PK_FirstTAB
			,FirstTABID
			,FirstTABName
			,PK_Downline 
			,DownlineID
			,FirstName
			,LastName
			,AppDate
			,ContractAcceptanceDate 
			,ReinstatementDate
			,QSQualDate 
			,SPQualDate 
			,Email
			,Phone 
			,Team 
			,COP 
			,COPISO
			,DSLevel
			,IsInactive
			,Month1PPV
			,Month2PPV
			,Month3PPV
			,Month4PPV
			,Month5PPV
			,Month6PPV
			,Month3DLV 
			,Month4DLV 
			,Month5DLV 
			,Month6DLV 
			,Month3TV
			,Month4TV
			,Month5TV
			,Month6TV
			,DownlineE1 
			,DownlineE2
			,Cut100
			,Cut350
			,Cut500
			,Cut1000
			,ModifiedDate
			,QualifiedPeriod350
			,QualifiedPeriod100
			,QualifiedPeriod500
			,QualifiedPeriod1000
			,QualifiedMonth350
			,QualifiedMonth100 
			,QualifiedMonth500 
			,QualifiedMonth1000 
			,CurrMonthVolReqd350 
			,CurrMonthVolReqd100 
			,CurrMonthVolReqd500 
			,CurrMonthVolReqd1000 
			,IsE1Qualifier
			,IsE2Qualifier
			,IsE3Qualifier 
			,IsE4Qualifier
			,IsE5Qualifier
			,IsE6Qualifier
			,IsE7Qualifier
			,IsE8Qualifier
			,IsE9Qualifier
			,IsE10Qualifier
			,IsE11Qualifier
		)
		VALUES 
		(
			 PK_Distributor
			,DistributorID  
			,PK_Sponsor 
			,SponsorID 
			,SponsorName
			,PK_FirstTAB
			,FirstTABID
			,FirstTABName
			,PK_Downline 
			,DownlineID
			,FirstName
			,LastName
			,AppDate
			,ContractAcceptanceDate 
			,ReinstatementDate
			,QSQualDate 
			,SPQualDate 
			,Email
			,Phone 
			,Team 
			,COP 
			,COPISO
			,DSLevel 
			,IsInactive
			,Month1PPV
			,Month2PPV
			,Month3PPV
			,Month4PPV
			,Month5PPV
			,Month6PPV
			,Month3DLV 
			,Month4DLV 
			,Month5DLV 
			,Month6DLV 
			,Month3TV
			,Month4TV
			,Month5TV
			,Month6TV
			,DownlineE1 
			,DownlineE2
			,Cut100
			,Cut350
			,Cut500
			,Cut1000
			,ModifiedDate 
			,QualifiedPeriod350
			,QualifiedPeriod100
			,QualifiedPeriod500
			,QualifiedPeriod1000
			,QualifiedMonth350
			,QualifiedMonth100 
			,QualifiedMonth500 
			,QualifiedMonth1000 
			,CurrMonthVolReqd350 
			,CurrMonthVolReqd100 
			,CurrMonthVolReqd500 
			,CurrMonthVolReqd1000 
			,IsE1Qualifier
			,IsE2Qualifier
			,IsE3Qualifier
			,IsE4Qualifier
			,IsE5Qualifier
			,IsE6Qualifier
			,IsE7Qualifier
			,IsE8Qualifier
			,IsE9Qualifier
			,IsE10Qualifier
			,IsE11Qualifier
	)
	WHEN MATCHED AND ( (ISNULL(t.Cut350,0) <> ISNULL(s.Cut350,0)
						OR ISNULL(t.Cut100,0) <> ISNULL(s.Cut100,0)
						OR ISNULL(t.Cut500,0) <> ISNULL(s.Cut500,0)
						OR ISNULL(t.Cut1000,0) <> ISNULL(s.Cut1000,0)
						OR ISNULL(t.Month1PPV,0) <> ISNULL(s.Month1PPV,0)
						OR ISNULL(t.Month2PPV,0) <> ISNULL(s.Month2PPV,0)
						OR ISNULL(t.Month3PPV,0) <> ISNULL(s.Month3PPV,0)
						OR ISNULL(t.Month4PPV,0) <> ISNULL(s.Month4PPV,0)
						OR ISNULL(t.Month5PPV,0) <> ISNULL(s.Month5PPV,0)
						OR ISNULL(t.Month6PPV,0) <> ISNULL(s.Month6PPV,0)
						OR ISNULL(t.Month3DLV,0) <> ISNULL(s.Month3DLV,0)
						OR ISNULL(t.Month4DLV,0) <> ISNULL(s.Month4DLV,0)
						OR ISNULL(t.Month5DLV,0) <> ISNULL(s.Month5DLV,0)
						OR ISNULL(t.Month6DLV,0) <> ISNULL(s.Month6DLV,0)
						OR ISNULL(t.Month3TV,0) <> ISNULL(s.Month3TV,0)
						OR ISNULL(t.Month4TV,0) <> ISNULL(s.Month4TV,0)
						OR ISNULL(t.Month5TV,0) <> ISNULL(s.Month5TV,0)
						OR ISNULL(t.Month6TV,0) <> ISNULL(s.Month6TV,0)
						OR ISNULL(t.CurrMonthVolReqd350,0) <> ISNULL(s.CurrMonthVolReqd350,0)
						OR ISNULL(t.CurrMonthVolReqd100,0) <> ISNULL(s.CurrMonthVolReqd100,0)
						OR ISNULL(t.CurrMonthVolReqd500,0) <> ISNULL(s.CurrMonthVolReqd500,0)
						OR ISNULL(t.CurrMonthVolReqd1000,0) <> ISNULL(s.CurrMonthVolReqd1000,0)
						OR ISNULL(t.QualifiedPeriod350,0) <> ISNULL(s.QualifiedPeriod350,0)
						OR ISNULL(t.QualifiedPeriod100,0) <> ISNULL(s.QualifiedPeriod100,0)
						OR ISNULL(t.QualifiedPeriod500,0) <> ISNULL(s.QualifiedPeriod500,0)
						OR ISNULL(t.QualifiedPeriod1000,0) <> ISNULL(s.QualifiedPeriod1000,0)
						OR ISNULL(t.QualifiedMonth350,0) <> ISNULL(s.QualifiedMonth350,0)
						OR ISNULL(t.QualifiedMonth100,0) <> ISNULL(s.QualifiedMonth100,0)
						OR ISNULL(t.QualifiedMonth500,0) <> ISNULL(s.QualifiedMonth500,0)
						OR ISNULL(t.QualifiedMonth1000,0) <> ISNULL(s.QualifiedMonth1000,0)
						OR ISNULL(t.IsE1Qualifier,0) <> ISNULL(s.IsE1Qualifier,0)
						OR ISNULL(t.IsE2Qualifier,0) <> ISNULL(s.IsE2Qualifier,0)
						OR ISNULL(t.IsE3Qualifier,0) <> ISNULL(s.IsE3Qualifier,0)
						OR ISNULL(t.IsE4Qualifier,0) <> ISNULL(s.IsE4Qualifier,0)
						OR ISNULL(t.IsE5Qualifier,0) <> ISNULL(s.IsE5Qualifier,0)
						OR ISNULL(t.IsE6Qualifier,0) <> ISNULL(s.IsE6Qualifier,0)
						OR ISNULL(t.IsE7Qualifier,0) <> ISNULL(s.IsE7Qualifier,0)
						OR ISNULL(t.IsE8Qualifier,0) <> ISNULL(s.IsE8Qualifier,0)
						OR ISNULL(t.IsE9Qualifier,0) <> ISNULL(s.IsE9Qualifier,0)
						OR ISNULL(t.IsE10Qualifier,0) <> ISNULL(s.IsE10Qualifier,0)
						OR ISNULL(t.IsE11Qualifier,0) <> ISNULL(s.IsE11Qualifier,0)) --AND t.QualifiedMonth100 IS NULL AND t.QualifiedMonth350 IS NULL
					  ) 
		THEN 
		UPDATE
			SET t.PK_Sponsor  =  s.PK_Sponsor 
				,t.SponsorID  =  s.SponsorID 
				,t.SponsorName =  s.SponsorName
				,t.PK_FirstTAB =  s.PK_FirstTAB
				,t.FirstTABID =  s.FirstTABID
				,t.FirstTABName =  s.FirstTABName
				,t.PK_Downline  =  s.PK_Downline 
				,t.DownlineID =  s.DownlineID
				,t.FirstName =  s.FirstName
				,t.LastName =  s.LastName
				,t.AppDate =  s.AppDate
				,t.ContractAcceptanceDate  =  s.ContractAcceptanceDate 
				,t.ReinstatementDate  =  s.ReinstatementDate
				,t.QSQualDate  =  s.QSQualDate 
				,t.SPQualDate  =  s.SPQualDate 
				,t.Email =  s.Email
				,t.Phone  =  s.Phone 
				,t.Team  =  s.Team 
				,t.COP  =  s.COP 
				,t.COPISO  =  s.COPISO 
				,t.DSLevel  =  s.DSLevel 
				,t.IsInactive  =  s.IsInactive
				,t.Month1PPV  =  s.Month1PPV
				,t.Month2PPV  =  s.Month2PPV
				,t.Month3PPV  =  s.Month3PPV
				,t.Month4PPV  =  s.Month4PPV
				,t.Month5PPV  =  s.Month5PPV
				,t.Month6PPV  =  s.Month6PPV
				,t.Month3DLV  =  s.Month3DLV 
				,t.Month4DLV  =  s.Month4DLV 
				,t.Month5DLV  =  s.Month5DLV 
				,t.Month6DLV  =  s.Month6DLV 
				,t.Month3TV  =  s.Month3TV 
				,t.Month4TV  =  s.Month4TV 
				,t.Month5TV  =  s.Month5TV 
				,t.Month6TV  =  s.Month6TV 
				,t.DownlineE1  =  s.DownlineE1
				,t.DownlineE2  =  s.DownlineE2
				,t.Cut100  = s.Cut100
				,t.Cut350  = s.Cut350
				,t.Cut500  = s.Cut500
				,t.Cut1000  = s.Cut1000
				,t.ModifiedDate = GETDATE()
				,t.QualifiedPeriod350 = CASE WHEN t.IsE4Qualifier = 1 AND s.IsE1Qualifier = 0 THEN t.QualifiedPeriod350 ELSE CASE WHEN t.IsE4Qualifier = 1 AND s.IsInactive = 1 THEN s.QualifiedPeriod350 ELSE CASE WHEN t.IsE4Qualifier = 0 THEN s.QualifiedPeriod350 ELSE t.QualifiedPeriod350 END END END
				,t.QualifiedMonth350 = CASE WHEN t.IsE4Qualifier = 1 AND s.IsE1Qualifier = 0 THEN t.QualifiedMonth350 ELSE CASE WHEN t.IsE4Qualifier = 1 AND s.IsInactive = 1 THEN s.QualifiedMonth350 ELSE CASE WHEN t.IsE4Qualifier = 0 THEN s.QualifiedMonth350 ELSE t.QualifiedMonth350 END END END
				,t.QualifiedPeriod100 = CASE WHEN t.IsE1Qualifier = 1 AND s.IsE1Qualifier = 0 THEN t.QualifiedPeriod100 ELSE CASE WHEN t.IsE1Qualifier = 1 AND s.IsInactive = 1 THEN s.QualifiedPeriod100 ELSE CASE WHEN t.IsE1Qualifier = 0 THEN s.QualifiedPeriod100 ELSE t.QualifiedPeriod100 END END END
				,t.QualifiedMonth100 = CASE WHEN t.IsE1Qualifier = 1 AND s.IsE1Qualifier = 0 THEN t.QualifiedMonth100 ELSE CASE WHEN t.IsE1Qualifier = 1 AND s.IsInactive = 1 THEN s.QualifiedMonth100 ELSE CASE WHEN t.IsE1Qualifier = 0 THEN s.QualifiedMonth100 ELSE t.QualifiedMonth100 END END END
				,t.QualifiedPeriod500 = CASE WHEN t.IsE7Qualifier = 1 AND s.IsE7Qualifier = 0 THEN t.QualifiedPeriod500 ELSE CASE WHEN t.IsE7Qualifier = 1 AND s.IsInactive = 1 THEN s.QualifiedPeriod500 ELSE CASE WHEN t.IsE7Qualifier = 0 THEN s.QualifiedPeriod500 ELSE t.QualifiedPeriod500 END END END
				,t.QualifiedMonth500 = CASE WHEN t.IsE7Qualifier = 1 AND s.IsE7Qualifier = 0 THEN t.QualifiedMonth500 ELSE CASE WHEN t.IsE7Qualifier = 1 AND s.IsInactive = 1 THEN s.QualifiedMonth500 ELSE CASE WHEN t.IsE7Qualifier = 0 THEN s.QualifiedMonth500 ELSE t.QualifiedMonth500 END END END
				,t.QualifiedPeriod1000 = CASE WHEN t.IsE9Qualifier = 1 AND s.IsE9Qualifier = 0 THEN t.QualifiedPeriod1000 ELSE CASE WHEN t.IsE9Qualifier = 1 AND s.IsInactive = 1 THEN s.QualifiedPeriod1000 ELSE CASE WHEN t.IsE9Qualifier = 0 THEN s.QualifiedPeriod1000 ELSE t.QualifiedPeriod1000 END END END
				,t.QualifiedMonth1000 = CASE WHEN t.IsE9Qualifier = 1 AND s.IsE9Qualifier = 0 THEN t.QualifiedMonth1000 ELSE CASE WHEN t.IsE9Qualifier = 1 AND s.IsInactive = 1 THEN s.QualifiedMonth1000 ELSE CASE WHEN t.IsE9Qualifier = 0 THEN s.QualifiedMonth1000 ELSE t.QualifiedMonth1000 END END END
				,t.CurrMonthVolReqd350 = CASE WHEN t.IsE4Qualifier = 1 AND s.IsE4Qualifier = 0 THEN t.CurrMonthVolReqd350 ELSE CASE WHEN t.IsE4Qualifier = 1 AND s.IsInactive = 1 THEN s.CurrMonthVolReqd350 ELSE CASE WHEN t.IsE4Qualifier = 0 THEN s.CurrMonthVolReqd350 ELSE t.CurrMonthVolReqd350 END END END
				,t.CurrMonthVolReqd100 = CASE WHEN t.IsE1Qualifier = 1 AND s.IsE1Qualifier = 0 THEN t.CurrMonthVolReqd100 ELSE CASE WHEN t.IsE1Qualifier = 1 AND s.IsInactive = 1 THEN s.CurrMonthVolReqd100 ELSE CASE WHEN t.IsE1Qualifier = 0 THEN s.CurrMonthVolReqd100 ELSE t.CurrMonthVolReqd100 END END END
				,t.CurrMonthVolReqd500 = CASE WHEN t.IsE7Qualifier = 1 AND s.IsE7Qualifier = 0 THEN t.CurrMonthVolReqd500 ELSE CASE WHEN t.IsE7Qualifier = 1 AND s.IsInactive = 1 THEN s.CurrMonthVolReqd500 ELSE CASE WHEN t.IsE7Qualifier = 0 THEN s.CurrMonthVolReqd500 ELSE t.CurrMonthVolReqd500 END END END
				,t.CurrMonthVolReqd1000 = CASE WHEN t.IsE9Qualifier = 1 AND s.IsE9Qualifier = 0 THEN t.CurrMonthVolReqd1000 ELSE CASE WHEN t.IsE9Qualifier = 1 AND s.IsInactive = 1 THEN s.CurrMonthVolReqd1000 ELSE CASE WHEN t.IsE9Qualifier = 0 THEN s.CurrMonthVolReqd1000 ELSE t.CurrMonthVolReqd1000 END END END
				,t.IsE1Qualifier = CASE WHEN t.IsE1Qualifier = 1 AND s.IsE1Qualifier = 0 THEN t.IsE1Qualifier ELSE CASE WHEN t.IsE1Qualifier = 1 AND s.IsInactive = 1 THEN s.IsE1Qualifier ELSE CASE WHEN t.IsE1Qualifier = 0 THEN s.IsE1Qualifier ELSE t.IsE1Qualifier END END END
				,t.IsE2Qualifier = CASE WHEN t.IsE2Qualifier = 1 AND s.IsE2Qualifier = 0 THEN t.IsE2Qualifier ELSE CASE WHEN t.IsE2Qualifier = 1 AND s.IsInactive = 1 THEN s.IsE2Qualifier ELSE CASE WHEN t.IsE2Qualifier = 0 THEN s.IsE2Qualifier ELSE t.IsE2Qualifier END END END
				,t.IsE3Qualifier = CASE WHEN t.IsE3Qualifier = 1 AND s.IsE3Qualifier = 0 THEN t.IsE3Qualifier ELSE CASE WHEN t.IsE3Qualifier = 1 AND s.IsInactive = 1 THEN s.IsE3Qualifier ELSE CASE WHEN t.IsE3Qualifier = 0 THEN s.IsE3Qualifier ELSE t.IsE3Qualifier END END END
				,t.IsE4Qualifier = CASE WHEN t.IsE4Qualifier = 1 AND s.IsE4Qualifier = 0 THEN t.IsE4Qualifier ELSE CASE WHEN t.IsE4Qualifier = 1 AND s.IsInactive = 1 THEN s.IsE4Qualifier ELSE CASE WHEN t.IsE4Qualifier = 0 THEN s.IsE4Qualifier ELSE t.IsE4Qualifier END END END
				,t.IsE5Qualifier = CASE WHEN t.IsE5Qualifier = 1 AND s.IsE5Qualifier = 0 THEN t.IsE5Qualifier ELSE CASE WHEN t.IsE5Qualifier = 1 AND s.IsInactive = 1 THEN s.IsE5Qualifier ELSE CASE WHEN t.IsE5Qualifier = 0 THEN s.IsE5Qualifier ELSE t.IsE5Qualifier END END END
				,t.IsE6Qualifier = CASE WHEN t.IsE6Qualifier = 1 AND s.IsE6Qualifier = 0 THEN t.IsE6Qualifier ELSE CASE WHEN t.IsE6Qualifier = 1 AND s.IsInactive = 1 THEN s.IsE6Qualifier ELSE CASE WHEN t.IsE6Qualifier = 0 THEN s.IsE6Qualifier ELSE t.IsE6Qualifier END END END
				,t.IsE7Qualifier = CASE WHEN t.IsE7Qualifier = 1 AND s.IsE7Qualifier = 0 THEN t.IsE7Qualifier ELSE CASE WHEN t.IsE7Qualifier = 1 AND s.IsInactive = 1 THEN s.IsE7Qualifier ELSE CASE WHEN t.IsE7Qualifier = 0 THEN s.IsE7Qualifier ELSE t.IsE7Qualifier END END END
				,t.IsE8Qualifier = CASE WHEN t.IsE8Qualifier = 1 AND s.IsE8Qualifier = 0 THEN t.IsE8Qualifier ELSE CASE WHEN t.IsE8Qualifier = 1 AND s.IsInactive = 1 THEN s.IsE8Qualifier ELSE CASE WHEN t.IsE8Qualifier = 0 THEN s.IsE8Qualifier ELSE t.IsE8Qualifier END END END
				,t.IsE9Qualifier = CASE WHEN t.IsE9Qualifier = 1 AND s.IsE9Qualifier = 0 THEN t.IsE9Qualifier ELSE CASE WHEN t.IsE9Qualifier = 1 AND s.IsInactive = 1 THEN s.IsE9Qualifier ELSE CASE WHEN t.IsE9Qualifier = 0 THEN s.IsE9Qualifier ELSE t.IsE9Qualifier END END END
				,t.IsE10Qualifier = CASE WHEN t.IsE10Qualifier = 1 AND s.IsE10Qualifier = 0 THEN t.IsE10Qualifier ELSE CASE WHEN t.IsE10Qualifier = 1 AND s.IsInactive = 1 THEN s.IsE10Qualifier ELSE CASE WHEN t.IsE10Qualifier = 0 THEN s.IsE10Qualifier ELSE t.IsE10Qualifier END END END
				,t.IsE11Qualifier = CASE WHEN t.IsE11Qualifier = 1 AND s.IsE11Qualifier = 0 THEN t.IsE11Qualifier ELSE CASE WHEN t.IsE11Qualifier = 1 AND s.IsInactive = 1 THEN s.IsE11Qualifier ELSE CASE WHEN t.IsE11Qualifier = 0 THEN s.IsE11Qualifier ELSE t.IsE11Qualifier END END END
	
	WHEN NOT MATCHED BY SOURCE THEN
		UPDATE
			SET 
				 t.Cut350 = 0
				,t.Cut100 = 0 
				,t.Cut500 = 0 
				,t.Cut1000 = 0 
				,t.CurrMonthVolReqd350 = 0
				,t.CurrMonthVolReqd100 = 0
				,t.CurrMonthVolReqd500 = 0
				,t.CurrMonthVolReqd1000 = 0;

END
ELSE
BEGIN
	SELECT PK_Distributor,
	DistributorID,
	PK_Sponsor,
	SponsorID,
	SponsorName,
	PK_FirstTAB,
	FirstTABID,
	FirstTABName,
	PK_Downline,
	DownlineID,
	FirstName,
	LastName,
	AppDate,
	ContractAcceptanceDate,
	ReinstatementDate,
	QPQualDate,
	QSQualDate,
	SPQualDate,
	Email,
	Phone,
	Team,
	COP,
	COPISO,
	DSLevel,
	IsInactive,
	Month1PPV,
	Month2PPV,
	Month3PPV,
	Month4PPV,
	Month5PPV,
	Month6PPV,
	DownlineE1,
	DownlineE2,
	Cut350,
	Cut100,
	ModifiedDate,
	QualifiedPeriod350,
	QualifiedPeriod100,
	QualifiedMonth350,
	QualifiedMonth100,
	CurrMonthVolReqd350,
	CurrMonthVolReqd100,
	IsE1Qualifier,
	IsE2Qualifier,
	IsE3Qualifier,
	IsE4Qualifier,
	Month3DLV,
	Month4DLV,
	Month5DLV,
	Month6DLV,
	Month3TV,
	Month4TV,
	Month5TV,
	Month6TV,
	Cut500,
	Cut1000,
	QualifiedPeriod500,
	QualifiedPeriod1000,
	QualifiedMonth500,
	QualifiedMonth1000,
	CurrMonthVolReqd500,
	CurrMonthVolReqd1000,
	IsE5Qualifier,
	IsE6Qualifier,
	IsE7Qualifier,
	IsE8Qualifier,
	IsE9Qualifier,
	IsE10Qualifier,
	IsE11Qualifier
INTO dbo.WRK_MexicoMAP2017 FROM #RPT_Temp
	
	CREATE CLUSTERED INDEX IX_WRK_MexicoMAP2017_PK_Distributor ON dbo.WRK_MexicoMAP2017(PK_Distributor)

	CREATE NONCLUSTERED INDEX IX_WRK_MexicoMAP2017_DSLevel ON dbo.WRK_MexicoMAP2017(DSLevel)
	
END



/******************************************************************
SET MONTH LAST PROCESSED
******************************************************************/
IF NOT EXISTS(SELECT 1 FROM dbo.EventSchedule WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Schedule = 9 AND EndUTC = @CurrentMonth) 
BEGIN
	UPDATE 
		ES 
	SET
		EndUTC = @CurrentMonth 
	FROM 
		dbo.EventSchedule ES
	WHERE
		PK_Event = @PK_Event
		AND
		PK_Schedule = 9
END



EXEC dbo.usp_Utility_UpdateProcessingLog
@StoredProcedureName = @ProcName
,@StoredProcedureParameters = @ProcParamRecur
,@StartTime = @StartTimeRecur

/******************************************************************************  
 END PROCEDURE  
******************************************************************************/   
END