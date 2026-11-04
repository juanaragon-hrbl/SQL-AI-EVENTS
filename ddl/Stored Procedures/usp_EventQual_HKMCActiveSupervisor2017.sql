CREATE PROCEDURE [dbo].[usp_EventQual_HKMCActiveSupervisor2017]
	 @PK_Event INT = 10366 
	,@ProcessMonth DATETIME = NULL
AS
BEGIN

/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_HKMCActiveSupervisor2017

	USE:		EXEC dbo.usp_EventQual_HKMCActiveSupervisor2017

	DESCRIPTION: This procedure is a custom qual for the EMEA Active Supervisor Promo. 

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
,@BeginDateTVP DATETIME = '2015-01-01'
,@EndDateTVP DATETIME = DATEADD(mm,DATEDIFF(mm,0,GETDATE()),0)
,@MonthName VARCHAR(20) = ''	
,@BeginDate DATETIME 
,@CurrentMonth DATETIME = ISNULL(@ProcessMonth,DATEADD(mm,DATEDIFF(mm,0,GETDATE()),0))
,@sql nvarchar(max) = ''
,@Count INT = 1
,@DSlevel INT = 3
,@ValidDate DATETIME = '2049-12-31'

--SET @PK_Event = CASE WHEN GETUTCDATE() >= '2017-04-05' THEN @PK_Event ELSE 3434 END

DECLARE @Year INT = CASE WHEN MONTH(@CurrentMonth) = 1 THEN YEAR(@CurrentMonth)-1 ELSE YEAR(@CurrentMonth) END

SET @ProcName = 'usp_EventQual_HKMCActiveSupervisor2017'
SET @ProcParamRecur = CONVERT(VARCHAR,'')
SET @StartTimeRecur = GETUTCDATE() 
      
SET @BeginDate = DATEADD(mm,-3,@CurrentMonth)

SELECT nCountryID INTO #tbl_Countries FROM v_Countries WHERE sCountryCode IN ('HK','MC')

IF OBJECT_ID('tempdb..#Associated', 'U') IS NOT NULL DROP TABLE #Associated
IF OBJECT_ID('tempdb..#wrk_T1', 'U') IS NOT NULL DROP TABLE #wrk_T1
IF OBJECT_ID('tempdb..#AllASP', 'U') IS NOT NULL DROP TABLE #AllASP


CREATE TABLE #wrk_T1
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	PK_Distributor		int,
	COP INT
)

CREATE TABLE #Associated
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	nMainAssociatedID INT,
	nDistributorID INT,
	Stones INT DEFAULT 0,
	IsASP BIT DEFAULT 0
)

		
-- GET ASSOCIATIONS WHERE Mains Will have to be excluded
INSERT INTO #wrk_T1(PK_Distributor,COP)
SELECT DISTINCT nMainDistributorID,C.nCountryID
FROM   dbo.v_DistributorAssociate2 A 
INNER JOIN dbo.v_Distributor D
ON A.nMainDistributorID = D.nDistributorID
INNER JOIN	dbo.v_Countries C
ON D.nDistributorCountryProcessingID = C.nCountryID
AND C.sCountryCode IN ('HK','MC')
WHERE  dThrough = @ValidDate
AND Transfer = 0
GROUP BY nMainDistributorID,C.nCountryID
--HAVING COUNT(1) >= 3

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
INNER JOIN	dbo.v_Countries C
ON D.nDistributorCountryProcessingID = C.nCountryID
AND C.sCountryCode IN ('HK','MC')
WHERE  dThrough = @ValidDate
AND Transfer = 0
GROUP BY nMainDistributorID
/*HAVING COUNT(1) >= 3*/) AND nMainDistributorID <> nDistributorID AND dThrough = @ValidDate

CREATE INDEX IX_#Associated_nMainAssociatedID ON #Associated(nMainAssociatedID)
CREATE INDEX IX_#Associated_nDistributorID ON #Associated(nDistributorID)


/*******************************************************************************************/
CREATE TABLE #AllASP
(
	PK INT IDENTITY(1,1)
	,PK_Distributor INT
	,COP INT
	,PK_FirstDownLine INT
	,FirstLineIsASP BIT DEFAULT 0
	,CanFirstLineBeAssigned INT DEFAULT 0
	,PK_SecondDownLine INT
	,SecondLineIsASP BIT DEFAULT 0
	,CanSecondLineBeAssigned INT DEFAULT 0
	,PK_ThirdDownLine INT
	,ThirdLineIsASP BIT DEFAULT 0
	,CanThirdLineBeAssigned INT DEFAULT 0
	,FirstLineCount INT DEFAULT 0
	,SecondLineCount INT DEFAULT 0
	,ThirdLineCount INT DEFAULT 0	
	,OverallCount AS (FirstLineCount+SecondLineCount+ThirdLineCount) 
)



IF OBJECT_ID('WRK_HKMCActiveSupervisor2017', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.WRK_HKMCActiveSupervisor2017
	(
		   PK int IDENTITY(1,1) PRIMARY KEY
		  ,PK_Distributor INT NOT NULL
		  ,LastRunTotalSP INT DEFAULT 0
		  ,AcviteSupervisor_QualDate DATETIME
		  ,Stone1_QualDate DATETIME 
		  ,TotalStone1 INT DEFAULT 0
		  ,Stone3_QualDate DATETIME 
		  ,TotalStone3 INT DEFAULT 0
		  ,Stone5_QualDate DATETIME 
		  ,TotalStone5 INT DEFAULT 0
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
		  ,IsStar12 BIT DEFAULT 0
		  ,IsStar13 BIT DEFAULT 0
		  ,nYear INT 
		  ,CreatedDate DATETIME DEFAULT GETUTCDATE()
	)
END



IF GETUTCDATE() >= '2016-04-01'
BEGIN
	/******************************************************************************
		Build linaege from All MB in EMEA Region who has achieved 2500 in 3CMG
	*******************************************************************************/
	;WITH Uplines(nDistributorID,nCountryID,dSupervisorQualification) AS 
	(
		SELECT DISTINCT
			D.nDistributorID,
			C.nCountryID,
			D.dSupervisorQualification
		FROM 
			[dbo].[v_Distributor] D (NOLOCK)		
		INNER JOIN
			dbo.v_Countries C
		ON
			D.nDistributorCountryProcessingID = C.nCountryID
			AND
			C.sCountryCode IN ('HK','MC')
		WHERE 
			D.StatusCode = 'COMPLETE'
			AND
			D.sType = 'SP'
			--AND
			--D.dSupervisorQualification <= @BeginDate
/*		UNION
		SELECT 
			W.nDistributorID,
			W.COP
		FROM 
			#ListIDs W*/
	),	
	MainMB25003CM (PK_Distributor,COP) AS
	(
		SELECT 
			PK_Distributor,
			D.nCountryID
		FROM 
			ufn_GetASP (@BeginDate,DATEADD(mm,2,@BeginDate),2500,3,'TV',NULL) A
		INNER JOIN
			Uplines D
		ON
			A.PK_Distributor = D.nDistributorID
		WHERE
			D.dSupervisorQualification <= @BeginDate
		UNION
		SELECT 
			W.PK_Distributor,
			W.COP
		FROM 
			#wrk_T1 W		
	), FirstLvl (PK_Distributor,COP,PK_FirstLine) AS
    (
        SELECT 
			M.PK_Distributor,
			M.COP,
            DL.PK_DSDownline
        FROM
            MainMB25003CM M
        LEFT JOIN
            dbo.v_dimDSLngDownline DL (NOLOCK)
        ON
            M.PK_Distributor = DL.PK_Distributor
            AND 
			DL.DSLevelFromUL = 2
      )
      , SecondLvl (PK_Distributor,COP, PK_FirstLine, PK_SecondLine) AS
      (
        SELECT 
            FirstLvl.PK_Distributor
			,FirstLvl.COP
            ,FirstLvl.PK_FirstLine
            ,DL.PK_DSDownline
        FROM
            FirstLvl
        LEFT JOIN
			dbo.v_dimDSLngDownline DL (NOLOCK)
        ON
            FirstLvl.PK_FirstLine = DL.PK_Distributor
            AND 
			DL.DSLevelFromUL = 2
      )
      , ThirdLvl (PK_Distributor,COP, PK_FirstLine, PK_SecondLine, PK_ThirdLevel) AS
      (
		SELECT 
			SecondLvl.PK_Distributor
			,SecondLvl.COP
			,SecondLvl.PK_FirstLine
			,SecondLvl.PK_SecondLine
			,DL.PK_DSDownline
		FROM
			SecondLvl
		LEFT JOIN
			dbo.v_dimDSLngDownline DL (NOLOCK)
		ON
			SecondLvl.PK_SecondLine = DL.PK_Distributor
			AND 
			DL.DSLevelFromUL = 2
      )


/* INSERT ALL THE QUALIFIERS TO THE TEAM TABLE THAT WAS CREATED ABOVE */
INSERT
	#AllASP
(
	PK_Distributor
	,COP
	,PK_FirstDownLine
	,PK_SecondDownLine
	,PK_ThirdDownLine

)
SELECT
	PK_Distributor
	,COP
	,PK_FirstLine
	,PK_SecondLine
	,PK_ThirdLevel

FROM
	ThirdLvl


CREATE INDEX IX_#AllASP_PK_Distributor ON #AllASP(PK_Distributor)
CREATE INDEX IX_#AllASP_PK_FirstDownLine ON #AllASP(PK_FirstDownLine)
CREATE INDEX IX_#AllASP_PK_SecondDownLine ON #AllASP(PK_SecondDownLine)
CREATE INDEX IX_#AllASP_PK_ThirdDownLine ON #AllASP(PK_ThirdDownLine)


/* ASP NONTAB Downlines*/
;WITH DL(PK_Distributor) AS 
(
	SELECT PK_Distributor
	FROM #AllASP
	UNION
	SELECT PK_FirstDownline
	FROM #AllASP
	UNION
	SELECT PK_SecondDownLine
	FROM #AllASP
	UNION
	SELECT PK_ThirdDownLine
	FROM #AllASP
)
,ASP (PK_Distributor,isASP) AS
(
	SELECT 
		DL.PK_Distributor,
		CASE WHEN ISNULL(A.PK_Distributor,1) = 1 THEN 0 ELSE 1 END isASP
	FROM
		DL
	LEFT JOIN
	(
		SELECT 
			PK_Distributor
		FROM 
			ufn_GetASP (@BeginDate,DATEADD(mm,2,@BeginDate),2500,3,'TV',NULL) A
	) A
	ON
	DL.PK_Distributor = A.PK_Distributor
)


SELECT PK_Distributor,isASP INTO #DLFlags FROM ASP	  

CREATE INDEX IX_#DLFlags_PK_Distributor ON #DLFlags(PK_Distributor) INCLUDE(isASP)






/* UPDATE THE FLAGS FOR ALL donwlines */
UPDATE
	A
SET
	FirstLineIsASP = isASP
FROM
	#AllASP A
INNER JOIN
	#DLFlags D
ON
	A.PK_FirstDownLine = D.PK_Distributor

UPDATE
	A
SET
	SecondLineIsASP = isASP
FROM
	#AllASP A
INNER JOIN
	#DLFlags D
ON
	A.PK_SecondDownLine = D.PK_Distributor

UPDATE
	A
SET
	ThirdLineIsASP = isASP
FROM
	#AllASP A
INNER JOIN
	#DLFlags D
ON
	A.PK_ThirdDownLine = D.PK_Distributor




/*Who can be assisnged as Stone*/	
UPDATE
	T
SET
	CanFirstLineBeAssigned = 1
FROM
	#AllASP T
WHERE
	FirstLineIsASP = 1 

UPDATE
	T
SET
	T.CanSecondLineBeAssigned = 1
FROM
	#AllASP T
WHERE
	SecondLineIsASP = 1 
	AND 
	FirstLineIsASP = 0

	
UPDATE
	T
SET
	T.CanThirdLineBeAssigned = 1
FROM
	#AllASP T
WHERE
	ThirdLineIsASP = 1 
	AND 
	FirstLineIsASP = 0 AND SecondLineIsASP = 0





/*  Assign FirstLevelBouns */

UPDATE
	T
SET
	T.FirstLineCount = A.Stones
FROM
	#AllASP T
INNER JOIN
	(	
		SELECT
		PK_Distributor,
		COUNT(DISTINCT PK_FirstDownLine) AS Stones
		FROM
			#AllASP
		WHERE 
			CanFirstLineBeAssigned = 1
		GROUP BY
			PK_Distributor
	) A	
ON 
	A.PK_Distributor = T.PK_Distributor

UPDATE
	T
SET
	T.SecondLineCount = A.Stones
FROM
	#AllASP T
INNER JOIN
	(	
		SELECT
		PK_Distributor,
		COUNT(DISTINCT PK_SecondDownLine) AS Stones
		FROM
			#AllASP
		WHERE 
			CanSecondLineBeAssigned = 1
		GROUP BY
			PK_Distributor
	) A	
ON 
	A.PK_Distributor = T.PK_Distributor

UPDATE
	T
SET
	T.ThirdLineCount = A.Stones
FROM
	#AllASP T
INNER JOIN
	(	
		SELECT
		PK_Distributor,
		COUNT(DISTINCT PK_ThirdDownLine) AS Stones
		FROM
			#AllASP
		WHERE 
			CanThirdLineBeAssigned = 1
		GROUP BY
			PK_Distributor
	) A	
ON 
	A.PK_Distributor = T.PK_Distributor



END

/*************************************************************************************
      INSERT NEW Qualifiers to the three events project numbers (15033,15034,15035)
*************************************************************************************/	
INSERT
	dbo.WRK_HKMCActiveSupervisor2017
(
	PK_Distributor
	,IsASP
	,IsStar1
	,AcviteSupervisor_QualDate
	--,COP
	,nYear
)
SELECT DISTINCT
	 PK_Distributor 
	,1
	,1
	,@CurrentMonth 
--	,COP
	,@Year
FROM
	#AllASP S
WHERE
	NOT EXISTS (SELECT PK_Distributor FROM dbo.WRK_HKMCActiveSupervisor2017 W WITH(NOLOCK) WHERE W.PK_Distributor = S.PK_Distributor AND W.nYear = @Year)

/******************************************************************************
      UPDATE Total ASP in the current period
******************************************************************************/

/* ***************** SonarQube check 142 - "DELETE" and "UPDATE" statements should contain "WHERE" clauses */
	UPDATE dbo.WRK_HKMCActiveSupervisor2017 SET LastRunTotalSP = 0 WHERE PK > 0
/* ***************** SonarQube check 142 */

/*
UPDATE
	  T
SET
	  T.LastRunTotalSP = F.OverallCountRSM
FROM
	  dbo.WRK_HKMCActiveSupervisor2017 T
INNER JOIN
	#AllASP F
ON
	T.PK_Distributor = F.PK_Distributor
WHERE
--	T.COP IN (SELECT nCountryID FROM #tbl_Countries)
--	AND
	T.nYear = @Year
*/	

/****************************************************************************************************************************/
UPDATE
      T
SET
	  T.LastRunTotalSP = F.OverallCount
FROM
	  dbo.WRK_HKMCActiveSupervisor2017 T
INNER JOIN
	#AllASP F
ON
	T.PK_Distributor = F.PK_Distributor
WHERE
--	T.COP NOT IN (SELECT nCountryID FROM #tbl_Countries)
--	AND
	T.nYear = @Year

	
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
	dbo.WRK_HKMCActiveSupervisor2017 W
ON
	T.nMainAssociatedID = W.PK_Distributor
WHERE
	W.nYear = @Year
	

UPDATE
      T
SET
      T.LastRunTotalSP = (ISNULL(T.LastRunTotalSP,0) + ISNULL(A.Stones,0))
FROM
      dbo.WRK_HKMCActiveSupervisor2017 T
INNER JOIN
	 #Associated A
ON
	A.nDistributorID = T.PK_Distributor
WHERE
	T.nYear = @Year



/******************************************************************************  
 UPDATE WRK_HKMCActiveSupervisor2017 Levels
******************************************************************************/  
UPDATE  
	W  
SET  
	Stone10_QualDate =
		CASE
			WHEN W.LastRunTotalSP >= 10 AND Stone10_QualDate IS NULL THEN @CurrentMonth
			ELSE Stone10_QualDate
		END,
	TotalStone10 =
		CASE
			WHEN W.LastRunTotalSP >= 10 AND Stone10_QualDate IS NULL THEN W.LastRunTotalSP
			ELSE TotalStone10
		END,

	Stone7_QualDate =
		CASE
			WHEN W.LastRunTotalSP >= 7 AND Stone7_QualDate IS NULL THEN @CurrentMonth
			ELSE Stone7_QualDate
		END,
	TotalStone7 =
		CASE
			WHEN W.LastRunTotalSP >= 7 AND Stone7_QualDate IS NULL THEN W.LastRunTotalSP
			ELSE TotalStone7
		END,

	Stone5_QualDate =
		CASE
			WHEN W.LastRunTotalSP >= 5 AND Stone5_QualDate IS NULL THEN @CurrentMonth
			ELSE Stone5_QualDate
		END,
	TotalStone5 =
		CASE
			WHEN W.LastRunTotalSP >= 5 AND Stone5_QualDate IS NULL THEN W.LastRunTotalSP
			ELSE TotalStone5
		END,
	Stone3_QualDate =
		CASE
			WHEN W.LastRunTotalSP >= 3 AND Stone3_QualDate IS NULL THEN @CurrentMonth
			ELSE Stone3_QualDate
		END,
	TotalStone3 =
		CASE
			WHEN W.LastRunTotalSP >= 3 AND Stone3_QualDate IS NULL THEN W.LastRunTotalSP
			ELSE TotalStone3
		END,   
	Stone1_QualDate =
		CASE
			WHEN W.LastRunTotalSP >= 1 AND Stone1_QualDate IS NULL THEN @CurrentMonth
			ELSE Stone1_QualDate
		END,
	TotalStone1 =
		CASE
			WHEN W.LastRunTotalSP >= 1 AND Stone1_QualDate IS NULL THEN W.LastRunTotalSP
			ELSE TotalStone1
		END,
		IsStar2 = CASE WHEN W.LastRunTotalSP >= 1 AND W.Stone1_QualDate IS NULL THEN W.LastRunTotalSP ELSE IsStar2 END,
		IsStar3 = CASE WHEN W.LastRunTotalSP >= 3 AND W.Stone3_QualDate IS NULL THEN W.LastRunTotalSP ELSE IsStar3 END,
		IsStar4 = CASE WHEN W.LastRunTotalSP >= 5 AND W.Stone5_QualDate IS NULL THEN W.LastRunTotalSP ELSE IsStar4 END,
		IsStar5 = CASE WHEN W.LastRunTotalSP >= 10 AND W.Stone10_QualDate IS NULL THEN W.LastRunTotalSP ELSE IsStar5 END,
		IsStar6 = CASE WHEN W.LastRunTotalSP >= 7 AND W.Stone7_QualDate IS NULL THEN W.LastRunTotalSP ELSE IsStar6 END
FROM  
	dbo.WRK_HKMCActiveSupervisor2017 W (NOLOCK) 
WHERE
	W.nYear = @Year




---- This is so that we write the qualifiers to a permanent work table
--IF OBJECT_ID('WRK_EMEAActiveSP_Downlines', 'U') IS NOT NULL DROP TABLE dbo.WRK_EMEAActiveSP_Downlines

--SELECT * INTO dbo.WRK_EMEAActiveSP_Downlines FROM #AllASP

-- Call the stored procedure to insert EMEA ASP 2015 Qualifiers in SubEventQualifier in IA
-- by first copying the work table from BI to IA using the link server within the IA stored procedure
EXEC dbo.usp_StarPromo_UpdateSubEventQualifier @PK_InEvent = @PK_Event, @TabNAme = 'WRK_HKMCActiveSupervisor2017'


EXEC usp_Utility_UpdateProcessingLog
@StoredProcedureName = @ProcName
,@StoredProcedureParameters = @ProcParamRecur
,@StartTime = @StartTimeRecur


/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
GO