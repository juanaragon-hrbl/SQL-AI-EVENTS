CREATE PROCEDURE [dbo].[usp_Event_aggDSFinancial]
	@MonthsToCalculate int = 30
	,@IsDevQA  	bit = 0    
AS
BEGIN
 
/******************************************************************************
	OBJECT:			dbo.usp_Event_aggDSFinancial
	USE:			EXEC dbo.usp_Event_aggDSFinancial

	DESCRIPTION:	Builds aggDSFinancial (financial aggregates) for PubEventManagement Qual Engine usage
	NOTES:			

	DEPENDENCIES
	--------------------------------------------------------------------
	SQL SERVER 2008
	
	VERSIONS
	--------------------------------------------------------------------
	1   2010-05-27   IniU	Initial
	2   2011-01-01   IniU   Changed the code to use factDSFinancials istead of aggSPFinancials so that all DS metrics are captured, whether SP or not
	3   2011-03-08   IniU   Added Calculated columns for SP_PV, SP_GV, SP_TV, SP_OV, SP_MainPV, SP_MainGV, SP_MainTV and SP_MainOV based on SP Qual Date
	4   2011-07-01	 IniU	Changed the code for Associations to not join with dimDSAssocType because of Akhil's ill adviced changes and deployment with 
							his usual usually ticking time bomb assumptions (It won't affect anything).
    5   2011-07-11   ChandanS/Jahnavi Added DLV, SP_DLV, SP_MainDLV, MainDLV colum
    6	2011-10-13	 IniU	Added code to call stored procedure at the end for transfers
    7   2012-10-05   IniU   This negates item 6 explicit call to the stored procedure to do transfers. That means transfers are now done inline 
							before associations are done to avoid issues of transfers overwriting association metrics logic.
	8	2014-04-04	 IniU	Added logic to use a combination of either QS or SP Qual date to consider TV 
	9   2016-09-16   IniU   Added logic for MPV, MTV, MainMPV and MainMTV
   10   2016-11-11   SandhyaP  Netizza reference changes
   11   2017-05-03	 SandhyaP Added logic to accomodate DV (in TV) for US & PR starting May 2017 and additional metrics NDV,PPC,SPC,PRV,SRV
   12   2017-05-25	 SandhyaP Added RO/PB feed from factDSFinancial for all months
   13   2017-07-20   IniU Added code to update stats on PubEDW at the beginnning of the process
                          and also update stats on dbo.aggDSFinancial at the end.
   14   2017-10-17   IniU Logic added to accomodate the request to not enforce documented volume in September 2017 for people of COP PR or 
						  residence of PR.
   15	2018-06-12	 IniU Updated the logic to use documented volume for any sales by US or PR upline to a foreign downline from January 2018. That is order purpose 
						  is not XX but countrycode is not US or PR.
   16   2018-09-13	 SandhyaP	Code cleanup/Comments updated/Write data into aggDSFinancial on pubEvents DB (Azure migration)
   17   2019-09-03	 IniU	Changed the DV logic to consider order country, COP and COR 
   18   2019-09-24   IniU   Changed the DV logic to consider order country, COP, COR and Order Purpose specifically XX
   19   2019-11-01	 SushmaA Hard Coded Values - SRE
   20   2020--6-24   IniU  -- Implemented PC order purpose due to Turkey segmentation recently
   21	2021-04-07	 alejandramed Implementing divorces rules on TVs and ROs, for 2 ID’s divorces the Main ID is a working ID and all VP and RO are shared between both ID’s
   22	2021-11-18	 JonathanO	Adding the CO orders at the same logic of BR. 
   23 	2023-08-29	 puertac	Adding Marketing Plan Harmonization Columns
   24 	2025-06-12	 rosarioo	Fix Performance
   25	2025-09-24	 alejandramed	Implementing Greater China Association
   26	2025-11-12	 alejandramed	Fix Performance
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE 
	@Timestamp datetime
	,@MinRoyaltyMonth smalldatetime
	,@MaxRoyaltyMonth smalldatetime
	,@EndMonth smalldatetime
	,@StartMonth smalldatetime
	,@StartMonthInt	int
	,@EndMonthInt	int
	,@RowCount		int 
	,@EnabledStats bit
	,@ProccessActiveDS bit
	--For analysis 
	,@Step INT = 23
	,@fp BIT = 1

SET @Timestamp = GETDATE()
SET @MonthsToCalculate =  ISNULL((SELECT CONVERT(INT,MAX([value])) FROM [Promo].[Options] WITH (NOLOCK) WHERE [Key] = 'MonthsToCalculate' AND [IsActive] = 1 AND [Group] = 'QualEngine'),@MonthsToCalculate)
SET @EnabledStats =  ISNULL((SELECT CONVERT(INT,MAX([value])) FROM [Promo].[Options] WITH (NOLOCK) WHERE [Key] = 'EnabledStats' AND [IsActive] = 1 AND [Group] = 'QualEngine'),1)
SET @ProccessActiveDS =  ISNULL((SELECT CONVERT(INT,MAX([value])) FROM [Promo].[Options] WITH (NOLOCK) WHERE [Key] = 'ProccessActiveDS' AND [IsActive] = 1 AND [Group] = 'QualEngine'),1)
 
SELECT @MonthsToCalculate AS [@MonthsToCalculate],@EnabledStats AS [@EnabledStats], @ProccessActiveDS AS [@ProccessActiveDS]

DECLARE @StartTime DATETIME = GETUTCDATE()
DECLARE @EndTime DATETIME
DECLARE @StoredProcedure VARCHAR(100) = OBJECT_NAME(@@PROCID)


IF EXISTS (SELECT 1 FROM [DevAdmin].[ScheduleException] WITH (NOLOCK)
WHERE Active = 1 AND CONVERT(DATE,GETUTCDATE()) BETWEEN StartDate AND EndDate
AND TRIM(REPLACE(REPLACE([StoredProcedureName],'[',''),']','')) = TRIM(REPLACE(REPLACE(@StoredProcedure,'[',''),']','')))
BEGIN
	PRINT 'ScheduleException; The process is skipped.'
	RETURN;
END
ELSE
BEGIN

/*******************************************************************************************
	Update statistics on all objects on the source since not sure of the state of the stats
********************************************************************************************/


BEGIN TRY  
    IF @IsDevQA = 0 AND @EnabledStats = 1 
	BEGIN
	PRINT 'Updating statistics for tables involved in ' + @StoredProcedure + '...'
	EXEC dbo.sp_updatestats      
	PRINT 'Statistics updated successfully.'
	END
END TRY
BEGIN CATCH    
       PRINT 'Error occurred while updating statistics.'   
END CATCH

SET @EndTime = GETUTCDATE()

PRINT 'Step Initial'
PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = 'Initial' ,@StartTime = @StartTime

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  1 OR (@fp = 1 AND @Step >= 1)
BEGIN

/******************************************************************************
	Get Distinct DS Associations and indicate if Associate Type is 2, 3 or not
******************************************************************************/

SET @StartTime = GETUTCDATE() --Step 10

DROP TABLE IF EXISTS #WRK_DimDistributorIni;
 
SELECT DISTINCT D.PK_Distributor,D.DistributorID,CountryCode_COP,CountryCode_COR,PK_DSStatus,DeletedDate,SPQualDate,QSQualDate,ApplicationDate,PK_COP,PK_DSTeam,TypeCode
INTO #WRK_DimDistributorIni
FROM PubEvents.dbo.dimDistributor AS D WITH (NOLOCK)
OPTION (RECOMPILE)

CREATE INDEX IX_#WRK_DimDistributorIni_PK_Distributor ON #WRK_DimDistributorIni (PK_Distributor)
CREATE INDEX IX_#WRK_DimDistributorIni_DistributorID ON #WRK_DimDistributorIni (DistributorID)

IF OBJECT_ID('tempdb..#assoc1') IS NOT NULL DROP TABLE #assoc1

CREATE TABLE #assoc1 
(
	PK_Distributor int
	,DistributorID varchar(30)
	,IsType23 int DEFAULT 0
	,PK_MainDistributor int
	,MainDistributorID varchar(30)
	,PK_AssociatedID int
	,AssociatedDistributorID varchar(30)
	,MainIsType23 bit DEFAULT 0
	,AssociationType INT
)

INSERT
	#assoc1
(
	PK_Distributor
	,DistributorID
	,PK_MainDistributor
	,MainDistributorID
	,PK_AssociatedID
	,AssociatedDistributorID
	,IsType23
	,AssociationType
)
SELECT 
	DISTINCT
	D.PK_Distributor
	,DS.DistributorID
	,D.nMainDistributorID
	,DM.DistributorID AS MainDistributorID
	,PK_AssociatedID
	,DA.DistributorID
	,1 AS IsType23,
	D.AssociationType
FROM [Shared].[DistributorAssociation] AS D WITH (NOLOCK)
	INNER JOIN #WRK_DimDistributorIni DS (NOLOCK)
		ON D.PK_Distributor = DS.PK_Distributor
	INNER JOIN #WRK_DimDistributorIni DM (NOLOCK)
		ON D.nMainDistributorID = DM.PK_Distributor
		INNER JOIN #WRK_DimDistributorIni DA (NOLOCK)
		ON D.PK_AssociatedID = DA.PK_Distributor

/******************************************************************************
	get every main id who is a type23 or has an associate who is type 23
******************************************************************************/

IF OBJECT_ID('tempdb..#mainIsType23') IS NOT NULL DROP TABLE #mainIsType23
CREATE TABLE #mainIsType23 (PK_MainDistributor int)

INSERT
	#mainIsType23 (PK_MainDistributor)
SELECT DISTINCT
	PK_MainDistributor
FROM
	#assoc1
WHERE
	IsType23 = 1

UPDATE A
SET MainIsType23 = 1
FROM #assoc1 A
INNER JOIN #mainIsType23 M ON A.PK_MainDistributor = M.PK_MainDistributor
 
/******************************************************************************
	get every id who has a new ww assocition ID or a new CN association ID
******************************************************************************/
 
IF OBJECT_ID('tempdb..#GCASSOCID') IS NOT NULL DROP TABLE #GCASSOCID

DROP TABLE IF EXISTS #GCASSOCID 

CREATE TABLE #GCASSOCID
(
	PK_MainDistributor int --Original ID
	,MainDistributorID varchar(30)
	,PK_AssociatedID int
	,AssociatedDistributorID varchar(30)
	,MainCOP varchar(5)
	,AssociationType INT
	,[AssociationDate] DATE
	,nMainDistributorID_Divorce INT
	,DivorceType INT
	,[DivorceDate] DATE
	,[Original_As_Main] BIT
)
INSERT
	#GCASSOCID
(
	PK_MainDistributor,
	MainDistributorID,
	PK_AssociatedID,	
	AssociatedDistributorID, 
	MainCOP,
	AssociationType,  -- 1  New WW Association ID when COP of MainID is CN
						-- 2  New CN Association ID when COP of MainID is WW
	[AssociationDate]
	,nMainDistributorID_Divorce
	,DivorceType
	,[DivorceDate]
	,[Original_As_Main]
)
SELECT DISTINCT a.PK_MainDistributor
	,a.MainDistributorID
	,a.PK_Distributor AS PK_AssociatedID
	,a.DistributorID AS AssociatedDistributorID
	,d.sDistributorCountryProcessingCode AS MainCOP
	,IIF(d.sDistributorCountryProcessingCode = 'CN', 1, 2) AS AssociationType,
	a.FromDate AS [AssociationDate]
	,dc.nMainDistributorID
	,dc.[Filter]
	,dc.dFrom AS [DivorceDate]
	,IIF(dc.nMainDistributorID IS NOT NULL, IIF(dc.nMainDistributorID =  a.PK_MainDistributor, 1,0), NULL) AS [Original_As_Main]
FROM [PubEvents].[dbo].[dimDSAssociate] AS a WITH (NOLOCK) 
	INNER JOIN v_Distributor AS d
		ON a.PK_MainDistributor = d.nDistributorID
	LEFT JOIN [Shared].[DistributorAssociation] AS dc WITH (NOLOCK)  
	ON dc.PK_AssociatedID = a.PK_MainDistributor
WHERE a.GCASSOCID IS NOT NULL
AND a.PK_MainDistributor <> a.PK_Distributor

SET @EndTime = GETUTCDATE()

PRINT 'Step 10'
PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)
	
IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '10' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  2 OR (@fp = 1 AND @Step >= 2)
BEGIN

/* Begin Transfers */

SET @StartTime = GETUTCDATE() --Step 30

IF OBJECT_ID('tempdb..#wrk_Transfers') IS NOT NULL  DROP TABLE #wrk_Transfers

CREATE TABLE #wrk_Transfers
(
	PK				INT IDENTITY (1,1) PRIMARY KEY,
	PK_FromDS		INT,
	FromDS			VARCHAR(30),
	PK_ToDS			INT,
	ToDS			VARCHAR(30),
	PK_RollupDS		INT,
	RollupDS		VARCHAR(30),
	FromDSStatus	VARCHAR(20),
	RollupDSStatus  VARCHAR(20),
	CreateDateSrc	DATETIME,
	ModifiedDateSrc	DATETIME
)

-- Fetch Transfers from HMS
INSERT INTO
#wrk_Transfers
	(
	FromDS,
	ToDS,
	CreateDateSrc,
	ModifiedDateSrc
	)	
SELECT 
	DFROM.DistributorID,
	DTO.DistributorID,
	DST.CreatedDate,
	DST.ModifiedDate 
FROM 
	pubEvents.dbo.dimDSTransfers DST WITH (NOLOCK)
INNER JOIN
	#WRK_DimDistributorIni DFROM WITH (NOLOCK)
ON
	DST.PK_FromDistributor = DFROM.PK_Distributor
INNER JOIN
	#WRK_DimDistributorIni DTO WITH (NOLOCK)
ON
	DST.PK_ToDistributor = DTO.PK_Distributor
	
CREATE INDEX IX_1 ON #wrk_Transfers (FromDS)
CREATE INDEX IX_2 ON #wrk_Transfers (ToDS)

-- Remove DUPS (Keep Latest)
DELETE F
FROM 
      #wrk_Transfers F
INNER JOIN 
      (SELECT 
             FromDS
            ,MAX(PK) PK
       FROM 
            #wrk_Transfers
       GROUP BY 
            FromDS
       HAVING 
            COUNT(1) > 1
      ) Dups
      ON F.FromDS = Dups.FromDS
      AND F.PK <> Dups.PK

-- Assign Roll-Up ID for Non-Chained transfers
/*
	b -> c where c is the current id
	From	To		Roll-Up
	b		c		c
*/
UPDATE
	T1
SET
	T1.RollupDS= T1.ToDS
FROM
	#wrk_Transfers T1
LEFT JOIN 
	#wrk_Transfers T2
	ON
		T1.ToDS = T2.FromDS
WHERE
	T2.FromDS IS NULL

-- Assign Roll-Up ID for Chained transfers
/*
	a -> b -> c where c is the current id
	From	To		Roll-Up
	a		b		c
	b		c		c
*/
SET @RowCount = 1

WHILE @RowCount > 0
BEGIN

	UPDATE
		T1
	SET
		RollupDS = T2.RollUpDS
	FROM
		#wrk_Transfers T1
	INNER JOIN 
		#wrk_Transfers T2
		ON
		T1.ToDS = T2.FromDS AND
		T2.RollUpDS IS NOT NULL
	WHERE
		T1.RollupDS IS NULL

	SET @RowCount = @@ROWCOUNT

END	

-- Assign PK's and Status
UPDATE
	Wrk
SET
	Wrk.PK_FromDS = DS_FRM.PK_Distributor,
	Wrk.FromDSStatus = DS_ST_FRM.StatusCode,
	Wrk.PK_ToDS = DS_TO.PK_Distributor,
	Wrk.PK_RollupDS = DS_ROLL.PK_Distributor,	
	Wrk.RollupDSStatus = DS_ST_ROLL.StatusCode
FROM
	#wrk_Transfers Wrk
INNER JOIN
	#WRK_DimDistributorIni DS_FRM (NOLOCK)
	ON Wrk.FromDS = DS_FRM.DistributorID
INNER JOIN 
	pubEvents.dbo.dimDSStatus DS_ST_FRM (NOLOCK)
	ON DS_FRM.PK_DSStatus = DS_ST_FRM.PK_DSStatus
INNER JOIN
	#WRK_DimDistributorIni DS_TO (NOLOCK)
	ON Wrk.ToDS = DS_TO.DistributorID
INNER JOIN
	#WRK_DimDistributorIni DS_ROLL (NOLOCK)
	ON Wrk.RollupDS = DS_ROLL.DistributorID	
INNER JOIN 
	pubEvents.dbo.dimDSStatus DS_ST_ROLL (NOLOCK)
	ON DS_ROLL.PK_DSStatus = DS_ST_ROLL.PK_DSStatus	
		
CREATE INDEX IX_3 ON #wrk_Transfers (PK_FromDS)
CREATE INDEX IX_4 ON #wrk_Transfers (PK_ToDS)
CREATE INDEX IX_5 ON #wrk_Transfers (PK_RollupDS)

-- Remove any transfers with null From/To/Rollup PK
DELETE
	TF
FROM
	#wrk_Transfers TF
WHERE
	PK_FromDS IS NULL OR PK_ToDS IS NULL OR PK_RollupDS IS NULL
	
-- Remove Rejected Transfers
DELETE FROM #wrk_Transfers WHERE 
(FromDSStatus = 'COMPLETE'	AND RollupDSStatus = 'COMPLETE') OR
(FromDSStatus = 'DELETED'	AND RollupDSStatus = 'DELETED') OR
(FromDSStatus = 'DELETED'	AND RollupDSStatus = 'TERMINATED') OR
(FromDSStatus = 'TERMINATED'	AND RollupDSStatus = 'DELETED') OR
(FromDSStatus = 'TERMINATED'	AND RollupDSStatus = 'TERMINATED') 

-- Reverse Transfers
UPDATE
	#wrk_Transfers
SET
	PK_FromDS = PK_RollupDS,
	FromDS = RollupDS,
	RollupDS = FromDS,
	PK_RollupDS = PK_FromDS	
WHERE
(FromDSStatus = 'COMPLETE'	AND RollupDSStatus = 'DELETED') OR
(FromDSStatus = 'COMPLETE'	AND RollupDSStatus = 'TERMINATED')

SET @EndTime = GETUTCDATE() 

PRINT 'Step 30'
PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)
	
IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '30' ,@StartTime = @StartTime
 
END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  3 OR (@fp = 1 AND @Step >= 3)
BEGIN

DROP TABLE IF EXISTS #WRK_DimDistributor

CREATE TABLE #WRK_DimDistributor
(
	 PK_Distributor bigint,
	 DistributorID varchar(30),
	 CountryCode_COP varchar(2),
	 CountryCode_COR varchar(2),
	 PK_DSStatus int,
	 DeletedDate int,
	 SPQualDate int,
	 QSQualDate int,
	 ApplicationDate int,
	 PK_COP int,
	 PK_DSTeam int,
	 TypeCode varchar(5)
)

IF @ProccessActiveDS = 1 
BEGIN

--Removing DELETED DS that are not associated to transfer case or divorce case, pending to include GC associated

;WITH cte_Distributors AS
(
	SELECT D.PK_Distributor,D.DistributorID,CountryCode_COP,CountryCode_COR,PK_DSStatus,DeletedDate,SPQualDate,QSQualDate,ApplicationDate,PK_COP,PK_DSTeam,TypeCode FROM #WRK_DimDistributorIni AS d
	WHERE PK_DSStatus = 3
	UNION
	SELECT D.PK_Distributor,D.DistributorID,CountryCode_COP,CountryCode_COR,PK_DSStatus,DeletedDate,SPQualDate,QSQualDate,ApplicationDate,PK_COP,PK_DSTeam,TypeCode FROM #WRK_DimDistributorIni AS d
		INNER JOIN #assoc1 AS a
			ON d.PK_Distributor IN(a.PK_MainDistributor, a.PK_AssociatedID)
	UNION
	SELECT D.PK_Distributor,D.DistributorID,CountryCode_COP,CountryCode_COR,PK_DSStatus,DeletedDate,SPQualDate,QSQualDate,ApplicationDate,PK_COP,PK_DSTeam,TypeCode FROM #WRK_DimDistributorIni AS d
		INNER JOIN #wrk_Transfers AS a
			ON d.PK_Distributor IN(a.PK_FromDS, a.PK_RollupDS)
)
 
INSERT INTO #WRK_DimDistributor(PK_Distributor,DistributorID,CountryCode_COP,CountryCode_COR,PK_DSStatus,DeletedDate,SPQualDate,QSQualDate,ApplicationDate,PK_COP,PK_DSTeam,TypeCode)
SELECT DISTINCT D.PK_Distributor,D.DistributorID,CountryCode_COP,CountryCode_COR,PK_DSStatus,DeletedDate,SPQualDate,QSQualDate,ApplicationDate,PK_COP,PK_DSTeam,TypeCode
FROM cte_Distributors AS d
OPTION (RECOMPILE)

END
ELSE
BEGIN
 
	INSERT INTO #WRK_DimDistributor(PK_Distributor,DistributorID,CountryCode_COP,CountryCode_COR,PK_DSStatus,DeletedDate,SPQualDate,QSQualDate,ApplicationDate,PK_COP,PK_DSTeam,TypeCode)
	SELECT DISTINCT D.PK_Distributor,D.DistributorID,CountryCode_COP,CountryCode_COR,PK_DSStatus,DeletedDate,SPQualDate,QSQualDate,ApplicationDate,PK_COP,PK_DSTeam,TypeCode
	FROM #WRK_DimDistributorIni AS d
	OPTION (RECOMPILE)

END

CREATE INDEX IX_#WRK_DimDistributor_PK_Distributor ON #WRK_DimDistributor (PK_Distributor)
CREATE INDEX IX_#WRK_DimDistributor_DistributorID ON #WRK_DimDistributor (DistributorID)

/******************************************************************************
	Get aggSPFinancial for Supervisors
******************************************************************************/

SET @StartTime= GETUTCDATE() --Step 20

SET @Timestamp = GETDATE()
SET @EndMonth = DATEADD(d,-(day(GETDATE())-1),GETDATE()) 
SET @StartMonth = DATEADD(d,-(day(DATEADD(m,-@MonthsToCalculate+2,@EndMonth))),DATEADD(m,-@MonthsToCalculate+2,@EndMonth) )

SET @StartMonthInt = CONVERT(INT,CONVERT(VARCHAR,DATEPART(YEAR,@StartMonth))+CASE LEN(DATEPART(MM,@StartMonth)) WHEN 1 THEN CONVERT(VARCHAR(2),'0'+CONVERT(CHAR(1),DATEPART(MM,@StartMonth))) ELSE CONVERT(VARCHAR(2),DATEPART(MM,@StartMonth)) END)
SET @EndMonthInt   = CONVERT(INT,CONVERT(VARCHAR,DATEPART(YEAR,@EndMonth))+CASE LEN(DATEPART(MM,@EndMonth)) WHEN 1 THEN CONVERT(VARCHAR(2),'0'+CONVERT(CHAR(1),DATEPART(MM,@EndMonth))) ELSE CONVERT(VARCHAR(2),DATEPART(MM,@EndMonth)) END)
 
PRINT '@StartMonthInt = ' + CONVERT(VARCHAR(30),@StartMonthInt,121)
PRINT '@EndMonthInt = ' + CONVERT(VARCHAR(30),@EndMonthInt,121)
 
 SELECT @StartMonthInt AS [StartMonthInt], @EndMonthInt AS [EndMonthInt]

IF OBJECT_ID('tempdb..#FQSID_AllIDs') IS NOT NULL 
	DROP TABLE #FQSID_AllIDs

CREATE TABLE #FQSID_AllIDs (
	RoyaltyMonthInt int
	,RoyaltyMonth smalldatetime
	,PK_Distributor int
	,RO money DEFAULT 0
	,PB money DEFAULT 0
	,PV money DEFAULT 0
	,GV money DEFAULT 0
	,PPV money DEFAULT 0
	,OV money DEFAULT 0
	,TV AS (COALESCE([PV],0) + COALESCE([GV],0))
    ,DLV money DEFAULT 0
	,MPV money DEFAULT 0
	,MTV money DEFAULT 0
	,DV money DEFAULT 0
	,PPC money DEFAULT 0
	,PRV money DEFAULT 0
	,NDV money DEFAULT 0
	,SPC money DEFAULT 0
	,SRV money DEFAULT 0
	,PV_DV money DEFAULT 0
	,PV_PPC money DEFAULT 0
	,PV_PRV money DEFAULT 0
	,PV_NDV money DEFAULT 0
	,PV_SPC money DEFAULT 0
	,PV_SRV money DEFAULT 0
	,DLV_DV money DEFAULT 0
	,DLV_PPC money DEFAULT 0
	,DLV_PRV money DEFAULT 0
	,DLV_NDV money DEFAULT 0
	,DLV_SPC money DEFAULT 0
	,DLV_SRV money DEFAULT 0
	,GV_DV money DEFAULT 0
	,GV_PPC money DEFAULT 0
	,GV_PRV money DEFAULT 0
	,GV_NDV money DEFAULT 0
	,GV_SPC money DEFAULT 0
	,GV_SRV money DEFAULT 0
	,EV money DEFAULT 0
	,UV money DEFAULT 0
	,MPCV money DEFAULT 0
	,TOTAL_POINTS money DEFAULT 0
	,QCPV money DEFAULT 0
	,QDV money DEFAULT 0
	,QDV_DV money DEFAULT 0
	,PPV_DLV money DEFAULT 0
	,DV_DLVDV money DEFAULT 0	
	,IsInAssocTable BIT DEFAULT 0
)

	DROP TABLE IF EXISTS #Metrics;


	SELECT
		 RoyaltyMonth as RoyaltyMonthInt
		,CONVERT(DATETIME,CONVERT(VARCHAR,F.RoyaltyMonth*100+1,120)) AS RoyaltyMonth 
		,F.PK_Distributor
		,0 AS RO
		,0 AS OV
		,0 AS PB
				,CASE WHEN F.Order_Purpose = 'XX' THEN PV																						-- Order Purpose = XX
			  WHEN F.CountryCode IN ('US','PR') THEN PV_DV																				-- Order fulfillment US/PR																		     
			  WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose NOT IN ('XX','PC') THEN PV_DV							-- Order fulfillment NOT US/PR/BR/CO and Order Purpose IS NOT XX or PC
			  WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose = 'PC' THEN PV										-- Order fulfillment NOT US/PR/BR/CO and Order Purpose IS PC
			  WHEN F.CountryCode IN ('BR','CO') AND (D.CountryCode_COP IN ('US','PR') OR D.CountryCode_COR IN ('US','PR')) THEN PV_DV	-- Order fulfillment is BR/CO but COP IS US/PR 
			  WHEN F.CountryCode IN ('BR','CO') THEN PV																					-- Order fulfillment is BR/CO and COP not US/PR
		 END AS PV
		,CASE WHEN F.Order_Purpose = 'XX' THEN GV																					
			  WHEN F.CountryCode IN ('US','PR') THEN GV_DV																																					     
			  WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose NOT IN ('XX','PC') THEN GV_DV	
			  WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose = 'PC' THEN GV								
			  WHEN F.CountryCode IN ('BR','CO') AND (D.CountryCode_COP IN ('US','PR') OR D.CountryCode_COR IN ('US','PR')) THEN GV_DV	
			  WHEN F.CountryCode IN ('BR','CO') THEN GV	 						
		 END AS GV
		,CASE WHEN F.Order_Purpose = 'XX' THEN PPV																					
			  WHEN F.CountryCode IN ('US','PR') THEN ISNULL(DV,0)-ISNULL(MB_POINTEGERS,0)																																					     
			  WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose NOT IN ('XX','PC') THEN ISNULL(DV,0)-ISNULL(MB_POINTEGERS,0)	
			  WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose = 'PC' THEN PPV									
			  WHEN F.CountryCode IN ('BR','CO') AND (D.CountryCode_COP IN ('US','PR') OR D.CountryCode_COR IN ('US','PR')) THEN ISNULL(DV,0)-ISNULL(MB_POINTEGERS,0)
			  WHEN F.CountryCode IN ('BR','CO') THEN PPV	 								
		 END AS PPV
		,CASE WHEN F.Order_Purpose = 'XX' THEN DLV																					
			  WHEN F.CountryCode IN ('US','PR') THEN DLV_DV																																					     
			  WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose NOT IN ('XX','PC') THEN DLV_DV	
			  WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose = 'PC' THEN DLV												
			  WHEN F.CountryCode IN ('BR','CO') AND (D.CountryCode_COP IN ('US','PR') OR D.CountryCode_COR IN ('US','PR')) THEN DLV_DV	
			  WHEN F.CountryCode IN ('BR','CO') THEN DLV 					
		 END AS DLV
		,MPV 
		,MTV
		,DV
		,PPC
		,PRV
		,NDV
		,SPC
		,SRV
		,PV_DV
		,PV_PPC
		,PV_PRV
		,PV_NDV
		,PV_SPC
		,PV_SRV
		,DLV_DV
		,DLV_PPC
		,DLV_PRV
		,DLV_NDV
		,DLV_SPC
		,DLV_SRV
		,GV_DV
		,GV_PPC
		,GV_PRV
		,GV_NDV
		,GV_SPC
		,GV_SRV
		,EV
		,UV
		,MPCV 
		,TOTAL_POINTS
		,QCPV 
		,QDV 
		,QDV_DV 
		,PPV_DLV 
		,DV_DLVDV	 
	INTO #Metrics
	FROM pubEvents.dbo.factDSFinancial_ctry F WITH (NOLOCK)
	INNER JOIN #WRK_DimDistributor D WITH (NOLOCK) ON F.PK_Distributor = D.PK_Distributor
	WHERE RoyaltyMonth BETWEEN @StartMonthInt AND @EndMonthInt
	UNION ALL
	SELECT 
		F.RoyaltyMonth as RoyaltyMonthInt
		,CONVERT(DATETIME,CONVERT(VARCHAR,F.RoyaltyMonth*100+1,120)) AS RoyaltyMonth 
		,F.PK_Distributor
		,ISNULL(F.RO,0) AS RO
		,ISNULL(F.OV,0) AS OV
		,ISNULL(F.PB,0) AS PB
		,0 AS PV
		,0 AS GV
		,0 AS PPV
		,0 AS DLV
		,0 AS MPV 
		,0 AS MTV
		,0 AS DV
		,0 AS PPC
		,0 AS PRV
		,0 AS NDV
		,0 AS SPC
		,0 AS SRV
		,0 AS PV_DV
		,0 AS PV_PPC
		,0 AS PV_PRV
		,0 AS PV_NDV
		,0 AS PV_SPC
		,0 AS PV_SRV
		,0 AS DLV_DV
		,0 AS DLV_PPC
		,0 AS DLV_PRV
		,0 AS DLV_NDV
		,0 AS DLV_SPC
		,0 AS DLV_SRV
		,0 AS GV_DV
		,0 AS GV_PPC
		,0 AS GV_PRV
		,0 AS GV_NDV
		,0 AS GV_SPC
		,0 AS GV_SRV
		,0 AS EV
		,0 AS UV
		,0 AS MPCV 
		,0 AS TOTAL_POINTS
		,0 AS QCPV 
		,0 AS QDV 
		,0 AS QDV_DV 
		,0 AS PPV_DLV 
		,0 AS DV_DLVDV		
		FROM (  
					 
				SELECT  
					F.PK_Distributor,
					F.RoyaltyMonth AS RoyaltyMonth,
					F.FINANCIALTYPE,
					SUM(F.AMOUNT) AS [AMOUNT]
				FROM PubEvents.dbo.factdsfinancial_PHX AS F WITH (NOLOCK)
					INNER JOIN #WRK_DimDistributor D WITH (NOLOCK) ON F.PK_Distributor = D.PK_Distributor
				WHERE  F.RoyaltyMonth BETWEEN @StartMonthInt AND @EndMonthInt
				GROUP BY F.PK_Distributor,F.RoyaltyMonth,F.FINANCIALTYPE
			) AS S PIVOT (SUM([AMOUNT]) FOR FINANCIALTYPE IN ([OV],[RO],[PB])) AS F
 
INSERT #FQSID_AllIDs (
	RoyaltyMonthInt
	,RoyaltyMonth
	,PK_Distributor
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
    ,DLV
	,MPV
	,MTV
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV 
	,TOTAL_POINTS
	,QCPV 
	,QDV 
	,QDV_DV 
	,PPV_DLV 
	,DV_DLVDV	   
)
SELECT RoyaltyMonthInt
		,RoyaltyMonth
		,PK_Distributor
		,SUM(RO)
		,SUM(PB)
		,SUM(PV)
		,SUM(GV)
		,SUM(PPV)
		,SUM(OV)
		,SUM(DLV)
		,SUM(MPV)
		,SUM(MTV)
		,SUM(DV)
		,SUM(PPC)
		,SUM(PRV)
		,SUM(NDV)
		,SUM(SPC)
		,SUM(SRV)
		,SUM(PV_DV)
		,SUM(PV_PPC) 
		,SUM(PV_PRV) 
		,SUM(PV_NDV) 
		,SUM(PV_SPC) 
		,SUM(PV_SRV) 
		,SUM(DLV_DV) 
		,SUM(DLV_PPC) 
		,SUM(DLV_PRV) 
		,SUM(DLV_NDV) 
		,SUM(DLV_SPC) 
		,SUM(DLV_SRV) 
		,SUM(GV_DV) 
		,SUM(GV_PPC) 
		,SUM(GV_PRV) 
		,SUM(GV_NDV) 
		,SUM(GV_SPC) 
		,SUM(GV_SRV) 
		,SUM(EV) 
		,SUM(UV) 
		,SUM(MPCV) 
		,SUM(TOTAL_POINTS)
		,SUM(QCPV) 
		,SUM(QDV) 
		,SUM(QDV_DV)
		,SUM(PPV_DLV) 
		,SUM(DV_DLVDV)			 
FROM #Metrics
GROUP BY PK_Distributor, RoyaltyMonth, RoyaltyMonthInt
OPTION (RECOMPILE)

/****************************************************************
	index table
****************************************************************/
CREATE INDEX IX_#FQSID_AllIDs_PK_DS_RoyaltyMonth ON #FQSID_AllIDs(PK_Distributor,RoyaltyMonthInt)
CREATE INDEX IX_tmpFQSID_AllIDs_RoyaltyMonth ON #FQSID_AllIDs (RoyaltyMonth)
CREATE INDEX IX_tmpFQSID_AllIDs_RoyaltyMonthInt ON #FQSID_AllIDs (RoyaltyMonthInt)
CREATE INDEX IX_tmpFQSID_AllIDs_PK_Distributor ON #FQSID_AllIDs (PK_Distributor)
 
SET @EndTime = GETUTCDATE()

PRINT 'Step 20'
PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)
	
IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '20' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
IF @Step =  4 OR (@fp = 1 AND @Step >= 4)
BEGIN

SET @StartTime = GETUTCDATE() --Step 35

-- Get Metrics from factDSFinancial for OLD ID

DROP TABLE IF EXISTS #wrk_FromDSMetrics

SELECT 
	Wrk.PK_RollupDS,
	FACT.RoyaltyMonthInt, 
	FACT.RoyaltyMonth,
	SUM(FACT.PPV) PPV,
	SUM(FACT.PV) PV,
	SUM(FACT.GV) GV,
	SUM(FACT.RO) RO,
	SUM(FACT.PB) PB,
	SUM(FACT.OV) OV,
	SUM(FACT.DLV) DLV,
	SUM(TV) TV,
	SUM(FACT.MPV) MPV,
	SUM(FACT.MTV) MTV,
	SUM(FACT.DV) DV,
	SUM(FACT.PPC) PPC,
	SUM(FACT.PRV) PRV,
	SUM(FACT.NDV) NDV,
	SUM(FACT.SPC) SPC,
	SUM(FACT.SRV) SRV,
	SUM(FACT.PV_DV) PV_DV,
	SUM(FACT.PV_PPC) PV_PPC,
	SUM(FACT.PV_PRV) PV_PRV,
	SUM(FACT.PV_NDV) PV_NDV,
	SUM(FACT.PV_SPC) PV_SPC,
	SUM(FACT.PV_SRV) PV_SRV,
	SUM(FACT.DLV_DV) DLV_DV,
	SUM(FACT.DLV_PPC) DLV_PPC,
	SUM(FACT.DLV_PRV) DLV_PRV,
	SUM(FACT.DLV_NDV) DLV_NDV,
	SUM(FACT.DLV_SPC) DLV_SPC,
	SUM(FACT.DLV_SRV) DLV_SRV,
	SUM(FACT.GV_DV) GV_DV,
	SUM(FACT.GV_PPC) GV_PPC,
	SUM(FACT.GV_PRV) GV_PRV,
	SUM(FACT.GV_NDV) GV_NDV,
	SUM(FACT.GV_SPC) GV_SPC,
	SUM(FACT.GV_SRV) GV_SRV,
	SUM(FACT.EV) EV,
	SUM(FACT.UV) UV,
	SUM(FACT.MPCV) MPCV, 
	SUM(FACT.TOTAL_POINTS) TOTAL_POINTS,
	SUM(FACT.QCPV) QCPV, 
	SUM(FACT.QDV) QDV, 
	SUM(FACT.QDV_DV) QDV_DV,
	SUM(FACT.PPV_DLV) PPV_DLV, 
	SUM(FACT.DV_DLVDV) DV_DLVDV
INTO 
	#wrk_FromDSMetrics
FROM
	#wrk_Transfers WRK
INNER JOIN
    #FQSID_AllIDs FACT
	ON WRK.PK_FromDS = FACT.PK_Distributor
GROUP BY
	Wrk.PK_RollupDS,
	FACT.RoyaltyMonthInt,
	FACT.RoyaltyMonth

-- Get Metrics from aggDSFinancial for Rollup ID

DROP TABLE IF EXISTS #wrk_RollupDSMetrics

SELECT 
	FACT.PK_Distributor AS PK_RollupDS,
	FACT.RoyaltyMonthInt,
	FACT.RoyaltyMonth,
	ISNULL(FACT.PPV,0) PPV,
	ISNULL(FACT.PV,0) PV,
	ISNULL(FACT.GV,0) GV,
	ISNULL(FACT.RO,0) RO,
	ISNULL(FACT.PB,0) PB,
	ISNULL(FACT.DLV,0) DLV,
	ISNULL(FACT.OV,0) OV,
	ISNULL(FACT.TV,0) TV,
	ISNULL(FACT.MPV,0) MPV,
	ISNULL(FACT.MTV,0) MTV,
	ISNULL(FACT.DV,0) DV,
	ISNULL(FACT.PPC,0) PPC,
	ISNULL(FACT.PRV,0) PRV,
	ISNULL(FACT.NDV,0) NDV,
	ISNULL(FACT.SPC,0) SPC,
	ISNULL(FACT.SRV,0) SRV,
	ISNULL(FACT.PV_DV,0) PV_DV,
	ISNULL(FACT.PV_PPC,0) PV_PPC,
	ISNULL(FACT.PV_PRV,0) PV_PRV,
	ISNULL(FACT.PV_NDV,0) PV_NDV,
	ISNULL(FACT.PV_SPC,0) PV_SPC,
	ISNULL(FACT.PV_SRV,0) PV_SRV,
	ISNULL(FACT.DLV_DV,0) DLV_DV,
	ISNULL(FACT.DLV_PPC,0) DLV_PPC,
	ISNULL(FACT.DLV_PRV,0) DLV_PRV,
	ISNULL(FACT.DLV_NDV,0) DLV_NDV,
	ISNULL(FACT.DLV_SPC,0) DLV_SPC,
	ISNULL(FACT.DLV_SRV,0) DLV_SRV,
	ISNULL(FACT.GV_DV,0) GV_DV,
	ISNULL(FACT.GV_PPC,0) GV_PPC,
	ISNULL(FACT.GV_PRV,0) GV_PRV,
	ISNULL(FACT.GV_NDV,0) GV_NDV,
	ISNULL(FACT.GV_SPC,0) GV_SPC,
	ISNULL(FACT.GV_SRV,0) GV_SRV,
	ISNULL(FACT.EV,0) EV,
	ISNULL(FACT.UV,0) UV,
	ISNULL(FACT.MPCV,0)	MPCV, 
	ISNULL(FACT.TOTAL_POINTS,0)	TOTAL_POINTS,
	ISNULL(FACT.QCPV,0) QCPV, 
	ISNULL(FACT.QDV,0) 	QDV, 
	ISNULL(FACT.QDV_DV,0) QDV_DV, 
	ISNULL(FACT.PPV_DLV,0) PPV_DLV, 
	ISNULL(FACT.DV_DLVDV,0) DV_DLVDV
INTO 
	#wrk_RollupDSMetrics
FROM
	#FQSID_AllIDs FACT 
WHERE
	FACT.PK_Distributor IN (SELECT DISTINCT PK_RollupDS FROM #wrk_Transfers)		

-- Find Distinct ID + RO Month combinations that will need to reside in factDSFinancial
-- for the Roll-Up ID
DROP TABLE IF EXISTS #wrk_DistinctCombo

SELECT
	PK_RollupDS,
	RoyaltyMonthInt,
	RoyaltyMonth
INTO
	#wrk_DistinctCombo	
FROM
(
SELECT
	PK_RollupDS,
	RoyaltyMonthInt,
	RoyaltyMonth
FROM
	#wrk_FromDSMetrics
UNION 
SELECT
	PK_RollupDS,
	RoyaltyMonthInt,
	RoyaltyMonth
FROM
	#wrk_RollUpDSMetrics	
) AS UNI

-- Build Financial Records for the Distinct Combinations of ID + Royalty Month

DROP TABLE IF EXISTS #wrk_DSFinancial

SELECT 
	A.PK_RollupDS,
	A.RoyaltyMonth,
	A.RoyaltyMonthInt,
	ISNULL(Roll.PPV,0) + ISNULL(FRM.PPV,0) AS PPV,
	ISNULL(Roll.PV,0) + ISNULL(FRM.PV,0) AS PV,	
	ISNULL(Roll.GV,0) + ISNULL(FRM.GV,0) AS GV,
	ISNULL(Roll.PB,0) + ISNULL(FRM.PB,0) AS PB,
	ISNULL(Roll.RO,0) + ISNULL(FRM.RO,0) AS RO,
	ISNULL(Roll.DLV,0) + ISNULL(FRM.DLV,0) AS DLV,
	ISNULL(Roll.OV,0) + ISNULL(FRM.OV,0) AS OV,
	ISNULL(Roll.TV,0) + ISNULL(FRM.TV,0) AS TV,
	ISNULL(Roll.MPV,0) + ISNULL(FRM.MPV,0) AS MPV,
	ISNULL(Roll.MTV,0) + ISNULL(FRM.MTV,0) AS MTV,
	ISNULL(Roll.DV,0) + ISNULL(FRM.DV,0) AS DV,
	ISNULL(Roll.PPC,0) + ISNULL(FRM.PPC,0) AS PPC,
	ISNULL(Roll.PRV,0) + ISNULL(FRM.PRV,0) AS PRV,
	ISNULL(Roll.NDV,0) + ISNULL(FRM.NDV,0) AS NDV,
	ISNULL(Roll.SPC,0) + ISNULL(FRM.SPC,0) AS SPC,
	ISNULL(Roll.SRV,0) + ISNULL(FRM.SRV,0) AS SRV,
	ISNULL(Roll.PV_DV,0)  + ISNULL(FRM.PV_DV,0) PV_DV,
	ISNULL(Roll.PV_PPC,0)  + ISNULL(FRM.PV_PPC,0) PV_PPC,
	ISNULL(Roll.PV_PRV,0)  + ISNULL(FRM.PV_PRV,0) PV_PRV,
	ISNULL(Roll.PV_NDV,0)  + ISNULL(FRM.PV_NDV,0) PV_NDV,
	ISNULL(Roll.PV_SPC,0) + ISNULL(FRM.PV_SPC,0) PV_SPC,
	ISNULL(Roll.PV_SRV,0) + ISNULL(FRM.PV_SRV,0) PV_SRV,
	ISNULL(Roll.DLV_DV,0) + ISNULL(FRM.DLV_DV,0) DLV_DV,
	ISNULL(Roll.DLV_PPC,0) + ISNULL(FRM.DLV_PPC,0) DLV_PPC,
	ISNULL(Roll.DLV_PRV,0) + ISNULL(FRM.DLV_PRV,0) DLV_PRV,
	ISNULL(Roll.DLV_NDV,0) + ISNULL(FRM.DLV_NDV,0)  DLV_NDV,
	ISNULL(Roll.DLV_SPC,0) + ISNULL(FRM.DLV_SPC,0)  DLV_SPC,
	ISNULL(Roll.DLV_SRV,0) + ISNULL(FRM.DLV_SRV,0) DLV_SRV,
	ISNULL(Roll.GV_DV,0) + ISNULL(FRM.GV_DV,0) GV_DV,
	ISNULL(Roll.GV_PPC,0) + ISNULL(FRM.GV_PPC,0) GV_PPC,
	ISNULL(Roll.GV_PRV,0) + ISNULL(FRM.GV_PRV,0) GV_PRV,
	ISNULL(Roll.GV_NDV,0) + ISNULL(FRM.GV_NDV,0) GV_NDV,
	ISNULL(Roll.GV_SPC,0) + ISNULL(FRM.GV_SPC,0) GV_SPC,
	ISNULL(Roll.GV_SRV,0) + ISNULL(FRM.GV_SRV,0) GV_SRV,
	ISNULL(Roll.EV,0) + ISNULL(FRM.EV,0) EV,
	ISNULL(Roll.UV,0) + ISNULL(FRM.UV,0) UV,
	ISNULL(Roll.MPCV,0) + ISNULL(FRM.MPCV,0) MPCV,
	ISNULL(Roll.TOTAL_POINTS,0) + ISNULL(FRM.TOTAL_POINTS,0) TOTAL_POINTS,
	ISNULL(Roll.QCPV,0) + ISNULL(FRM.QCPV,0) QCPV,
	ISNULL(Roll.QDV,0) + ISNULL(FRM.QDV,0) QDV,
	ISNULL(Roll.QDV_DV,0) + ISNULL(FRM.QDV_DV,0) QDV_DV,
	ISNULL(Roll.PPV_DLV,0) + ISNULL(FRM.PPV_DLV,0) PPV_DLV,
	ISNULL(Roll.DV_DLVDV,0) + ISNULL(FRM.DV_DLVDV,0) DV_DLVDV
INTO
	#wrk_DSFinancial	
FROM
	#wrk_DistinctCombo A
LEFT JOIN
	#wrk_RollupDSMetrics Roll (NOLOCK)
	ON A.PK_RollupDS = Roll.PK_RollupDS AND
	   A.RoyaltyMonth = Roll.RoyaltyMonth 
LEFT JOIN
	#wrk_FromDSMetrics FRM (NOLOCK)
	ON A.PK_RollupDS = FRM.PK_RollupDS AND
	   A.RoyaltyMonth = FRM.RoyaltyMonth 

SET @EndTime = GETUTCDATE()

  PRINT 'Step 35'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '35' ,@StartTime = @StartTime
 
END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  5 OR (@fp = 1 AND @Step >= 5)
BEGIN

SET @StartTime = GETUTCDATE() --Step 40
	   
-- Delete All data for OLD DS 
DELETE 
	FACT
FROM
	#FQSID_AllIDs FACT 
INNER JOIN
	#wrk_Transfers TRF (NOLOCK)
	ON FACT.PK_Distributor = TRF.PK_FromDS		

-- Delete All data for Rollup DS
DELETE 
	FACT
FROM
	#FQSID_AllIDs FACT 
INNER JOIN
	#wrk_Transfers TRF (NOLOCK)
	ON FACT.PK_Distributor = TRF.PK_RollupDS
	
-- Insert new rolled up Data
INSERT INTO #FQSID_AllIDs
(
	PK_Distributor,
	RoyaltyMonthInt,
	RoyaltyMonth,
	RO,
	PB,
	PV,
	GV,
	PPV,
	OV,
	DLV,
	MPV,
	MTV,
	DV,
	PPC,
	PRV,
	NDV,
	SPC,
	SRV,
	PV_DV,
	PV_PPC,
	PV_PRV,
	PV_NDV,
	PV_SPC,
	PV_SRV,
	DLV_DV,
	DLV_PPC,
	DLV_PRV,
	DLV_NDV,
	DLV_SPC,
	DLV_SRV,
	GV_DV,
	GV_PPC,
	GV_PRV,
	GV_NDV,
	GV_SPC,
	GV_SRV,
	EV,
	UV,
	MPCV, 
	TOTAL_POINTS,
	QCPV, 
	QDV, 
	QDV_DV, 
	PPV_DLV, 
	DV_DLVDV
)
SELECT
	FACT.PK_RollupDS,
	FACT.RoyaltyMonthInt,
	FACT.RoyaltyMonth,
	FACT.RO,
	FACT.PB,
	FACT.PV,
	FACT.GV,
	FACT.PPV,
	FACT.OV,
	FACT.DLV,
	FACT.MPV,
	FACT.MTV,
	FACT.DV,
	FACT.PPC,
	FACT.PRV,
	FACT.NDV,
	FACT.SPC,
	FACT.SRV,
	FACT.PV_DV,
	FACT.PV_PPC,
	FACT.PV_PRV,
	FACT.PV_NDV,
	FACT.PV_SPC,
	FACT.PV_SRV,
	FACT.DLV_DV,
	FACT.DLV_PPC,
	FACT.DLV_PRV,
	FACT.DLV_NDV,
	FACT.DLV_SPC,
	FACT.DLV_SRV,
	FACT.GV_DV,
	FACT.GV_PPC,
	FACT.GV_PRV,
	FACT.GV_NDV,
	FACT.GV_SPC,
	FACT.GV_SRV,
	FACT.EV,
	FACT.UV,
	FACT.MPCV, 
	FACT.TOTAL_POINTS,
	FACT.QCPV, 
	FACT.QDV, 
	FACT.QDV_DV, 
	FACT.PPV_DLV, 
	FACT.DV_DLVDV
FROM
	#wrk_DSFinancial FACT
INNER JOIN
    #WRK_DimDistributor DS WITH (NOLOCK)
--	dbo.v_Distributor DS
ON
	FACT.PK_RollupDS = DS.PK_Distributor --nDistributorID

/* End Transfers */

SET @EndTime = GETUTCDATE()

  PRINT 'Step 40'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '40' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  6 OR (@fp = 1 AND @Step >= 6)
BEGIN

SET @StartTime = GETUTCDATE() --Step 45.1

/******************************************************************************
	get min and max royaltymonth
******************************************************************************/
SELECT
	@MinRoyaltyMonth = MIN(RoyaltyMonth)
	,@MaxRoyaltyMonth = MAX(RoyaltyMonth)
FROM
	#FQSID_AllIDs

/******************************************************************************
	xjoin associates across min and max royalty months for all distributors
	in tblDistributorAssociateCurrent
******************************************************************************/
DROP TABLE IF EXISTS #DSMonthsRange

DROP TABLE IF EXISTS #dsAssoc 

	SELECT DISTINCT d.PK_Distributor AS PK_Distributor
	INTO #dsAssoc
	FROM #FQSID_AllIDs AS d
		INNER JOIN #assoc1 AS a
			ON d.PK_Distributor = a.PK_Distributor
	UNION
	SELECT DISTINCT a.PK_AssociatedID AS PK_Distributor
	FROM #FQSID_AllIDs AS d
		INNER JOIN #assoc1 AS a
			ON d.PK_Distributor = a.PK_AssociatedID
 
UPDATE d
	SET IsInAssocTable = 1
FROM #FQSID_AllIDs AS d
	INNER JOIN #dsAssoc AS a
		ON d.PK_Distributor = a.PK_Distributor

;WITH cte_MonthsRange AS
(
	SELECT MonthDate FROM pubEvents.dbo.dimMonth M WITH (NOLOCK) WHERE M.MonthDate BETWEEN @MinRoyaltyMonth AND @MaxRoyaltyMonth 
)

SELECT d.PK_Distributor,M.MONTHDATE AS RoyaltyMonth
INTO #DSMonthsRange
FROM #dsAssoc AS d CROSS APPLY cte_MonthsRange AS M
UNION
SELECT PK_Distributor,RoyaltyMonth FROM #FQSID_AllIDs 


IF OBJECT_ID('tempdb..#FQSID_xJoin') IS NOT NULL 
	DROP TABLE #FQSID_xJoin

CREATE TABLE #FQSID_xJoin
(
	RoyaltyMonth smalldatetime
	,PK_Distributor int
	,IsType23 bit
	,PK_MainDistributor int
	,PK_AssociatedID int
	,MainIsType23 bit
	,TV money DEFAULT 0
	,RO money DEFAULT 0
	,PB money DEFAULT 0
	,PV money DEFAULT 0
	,GV money DEFAULT 0
	,PPV money DEFAULT 0
	,OV money DEFAULT 0
	,DLV money DEFAULT 0
	,MPV money DEFAULT 0
	,MTV money DEFAULT 0
	,DV money DEFAULT 0
	,PPC money DEFAULT 0
	,PRV money DEFAULT 0
	,NDV money DEFAULT 0
	,SPC money DEFAULT 0
	,SRV money DEFAULT 0
	,PV_DV money DEFAULT 0
	,PV_PPC money DEFAULT 0
	,PV_PRV money DEFAULT 0
	,PV_NDV money DEFAULT 0
	,PV_SPC money DEFAULT 0
	,PV_SRV money DEFAULT 0
	,DLV_DV money DEFAULT 0
	,DLV_PPC money DEFAULT 0
	,DLV_PRV money DEFAULT 0
	,DLV_NDV money DEFAULT 0
	,DLV_SPC money DEFAULT 0
	,DLV_SRV money DEFAULT 0
	,GV_DV money DEFAULT 0
	,GV_PPC money DEFAULT 0
	,GV_PRV money DEFAULT 0
	,GV_NDV money DEFAULT 0
	,GV_SPC money DEFAULT 0
	,GV_SRV money DEFAULT 0
	,EV money DEFAULT 0
	,UV money DEFAULT 0
	,MPCV money DEFAULT 0
	,TOTAL_POINTS money DEFAULT 0
	,QCPV money DEFAULT 0
	,QDV money DEFAULT 0
	,QDV_DV money DEFAULT 0
	,PPV_DLV money DEFAULT 0
	,DV_DLVDV money DEFAULT 0					  
)

INSERT
	#FQSID_xJoin
(
	RoyaltyMonth
	,PK_Distributor
	,IsType23
	,PK_MainDistributor
	,PK_AssociatedID
	,MainIsType23
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
	,DLV
	,MPV
	,MTV
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
)
SELECT
	 d.RoyaltyMonth
	,d.PK_Distributor
	,NULL AS IsType23
	,NULL AS PK_MainDistributor
	,NULL AS PK_AssociatedID
	,NULL AS MainIsType23
	,ISNULL(F.TV,0) 
	,ISNULL(F.RO,0)
	,ISNULL(F.PB,0)
	,ISNULL(F.PV,0) 
	,ISNULL(F.GV,0)
	,ISNULL(F.PPV,0)
	,ISNULL(F.OV,0)
 	,ISNULL(F.DLV,0)
	,ISNULL(F.MPV,0)
	,ISNULL(F.MTV,0)
	,ISNULL(F.DV,0)
	,ISNULL(F.PPC,0)
	,ISNULL(F.PRV,0)
	,ISNULL(F.NDV,0)
	,ISNULL(F.SPC,0)
	,ISNULL(F.SRV,0)
	,ISNULL(F.PV_DV,0)
	,ISNULL(F.PV_PPC,0)
	,ISNULL(F.PV_PRV,0)
	,ISNULL(F.PV_NDV,0)
	,ISNULL(F.PV_SPC,0)
	,ISNULL(F.PV_SRV,0)
	,ISNULL(F.DLV_DV,0)
	,ISNULL(F.DLV_PPC,0)
	,ISNULL(F.DLV_PRV,0)
	,ISNULL(F.DLV_NDV,0)
	,ISNULL(F.DLV_SPC,0)
	,ISNULL(F.DLV_SRV,0)
	,ISNULL(F.GV_DV,0)
	,ISNULL(F.GV_PPC,0)
	,ISNULL(F.GV_PRV,0)
	,ISNULL(F.GV_NDV,0)
	,ISNULL(F.GV_SPC,0)
	,ISNULL(F.GV_SRV,0)
	,ISNULL(F.EV,0)
	,ISNULL(F.UV,0)
	,ISNULL(F.MPCV,0)
	,ISNULL(F.TOTAL_POINTS,0)
	,ISNULL(F.QCPV,0)
	,ISNULL(F.QDV,0)
	,ISNULL(F.QDV_DV,0)
	,ISNULL(F.PPV_DLV,0)
	,ISNULL(F.DV_DLVDV,0)					
FROM #DSMonthsRange AS d
		LEFT JOIN #FQSID_AllIDs AS F 
			ON F.PK_Distributor = d.PK_Distributor AND F.RoyaltyMonth = d.RoyaltyMonth
 
SET @EndTime = GETUTCDATE()

  PRINT 'Step 45.1'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '45.1' ,@StartTime = @StartTime

SET @StartTime = GETUTCDATE() --Step 45.2

UPDATE f
SET 
	IsType23 = 1,
	f.PK_MainDistributor = A.PK_MainDistributor,
	f.PK_AssociatedID = A.PK_AssociatedID,
	f.MainIsType23 = A.MainIsType23
FROM #FQSID_xJoin AS f
	INNER JOIN  (SELECT DISTINCT PK_Distributor, PK_AssociatedID,PK_MainDistributor,MainIsType23,IsType23 FROM #assoc1 )AS A
	ON F.PK_Distributor = A.PK_Distributor  
		 
UPDATE f
SET 
	IsType23 = 1,
	f.PK_MainDistributor = A.PK_MainDistributor,
	f.PK_AssociatedID = A.PK_AssociatedID,
	f.MainIsType23 = A.MainIsType23
FROM #FQSID_xJoin AS f
	INNER JOIN  (SELECT DISTINCT PK_Distributor, PK_AssociatedID,PK_MainDistributor,MainIsType23,IsType23 FROM #assoc1 )AS A
	ON f.PK_Distributor = A.PK_AssociatedID 

UPDATE f
SET 
	IsType23 = 1,
	f.PK_MainDistributor = A.PK_MainDistributor,
	f.PK_AssociatedID = A.PK_AssociatedID,
	f.MainIsType23 = A.MainIsType23
FROM #FQSID_xJoin AS f
	INNER JOIN  (SELECT DISTINCT PK_Distributor, PK_AssociatedID,PK_MainDistributor,MainIsType23,IsType23 FROM #assoc1 )AS A
	ON f.PK_Distributor = A.PK_MainDistributor
 
CREATE INDEX IX_tmpFQSID_xJoin_RoyaltyMonth ON #FQSID_xJoin (RoyaltyMonth)
CREATE INDEX IX_tmpFQSID_xJoin_PK_Distributor ON #FQSID_xJoin (PK_Distributor)
CREATE INDEX IX_tmpFQSID_xJoin_IsType23 ON #FQSID_xJoin (IsType23)
CREATE INDEX IX_tmpFQSID_xJoin_PK_MainDistributor ON #FQSID_xJoin (PK_MainDistributor)
CREATE INDEX IX_tmpFQSID_xJoin_MainIsType23 ON #FQSID_xJoin (MainIsType23)

SET @EndTime = GETUTCDATE()

  PRINT 'Step 45.2'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '45.2' ,@StartTime = @StartTime
 
END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  7 OR (@fp = 1 AND @Step >= 7)
BEGIN

/******************************************************************************
	aggregate associates where the main id is not a type 2 or 3
******************************************************************************/
SET @StartTime = GETUTCDATE() --Step 50

IF OBJECT_ID('tempdb..#FQSID_MainNot23') IS NOT NULL 
	DROP TABLE #FQSID_MainNot23

CREATE TABLE #FQSID_MainNot23
(
	RoyaltyMonth smalldatetime
	,PK_Distributor int
	,IsType23 bit
	,PK_MainDistributor int
	,MainIsType23 bit
	,TV money DEFAULT 0
	,RO money DEFAULT 0
	,PB money DEFAULT 0
	,PV money DEFAULT 0
	,GV money DEFAULT 0
	,PPV money DEFAULT 0
	,OV money DEFAULT 0
  	,DLV money DEFAULT 0      
	,MPV money DEFAULT 0  
	,MTV money DEFAULT 0 
	,DV money DEFAULT 0
	,PPC money DEFAULT 0
	,PRV money DEFAULT 0
	,NDV money DEFAULT 0
	,SPC money DEFAULT 0
	,SRV money DEFAULT 0
	,PV_DV money DEFAULT 0
	,PV_PPC money DEFAULT 0
	,PV_PRV money DEFAULT 0
	,PV_NDV money DEFAULT 0
	,PV_SPC money DEFAULT 0
	,PV_SRV money DEFAULT 0
	,DLV_DV money DEFAULT 0
	,DLV_PPC money DEFAULT 0
	,DLV_PRV money DEFAULT 0
	,DLV_NDV money DEFAULT 0
	,DLV_SPC money DEFAULT 0
	,DLV_SRV money DEFAULT 0
	,GV_DV money DEFAULT 0
	,GV_PPC money DEFAULT 0
	,GV_PRV money DEFAULT 0
	,GV_NDV money DEFAULT 0
	,GV_SPC money DEFAULT 0
	,GV_SRV money DEFAULT 0
	,EV money DEFAULT 0
	,UV money DEFAULT 0
	,MPCV money DEFAULT 0
	,TOTAL_POINTS money DEFAULT 0
	,QCPV money DEFAULT 0
	,QDV money DEFAULT 0
	,QDV_DV money DEFAULT 0
	,PPV_DLV money DEFAULT 0
	,DV_DLVDV money DEFAULT 0					  
)

INSERT
	#FQSID_MainNot23
(
	RoyaltyMonth
	,PK_Distributor
	,IsType23
	,PK_MainDistributor
	,MainIsType23
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
    ,DLV
	,MPV
	,MTV
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
)
SELECT
	RoyaltyMonth
	,PK_MainDistributor
	,0
	,PK_MainDistributor
	,0
	,SUM(TV)
	,SUM(RO)
	,SUM(PB)
	,SUM(PV)
	,SUM(GV)
	,SUM(PPV)
	,SUM(OV)
    ,SUM(DLV)
	,SUM(MPV)
	,SUM(MTV)
	,SUM(DV)
	,SUM(PPC)
	,SUM(PRV)
	,SUM(NDV)
	,SUM(SPC)
	,SUM(SRV)
	,SUM(PV_DV)
	,SUM(PV_PPC) 
	,SUM(PV_PRV) 
	,SUM(PV_NDV) 
	,SUM(PV_SPC) 
	,SUM(PV_SRV) 
	,SUM(DLV_DV)
	,SUM(DLV_PPC) 
	,SUM(DLV_PRV) 
	,SUM(DLV_NDV) 
	,SUM(DLV_SPC) 
	,SUM(DLV_SRV) 
	,SUM(GV_DV) 
	,SUM(GV_PPC) 
	,SUM(GV_PRV) 
	,SUM(GV_NDV) 
	,SUM(GV_SPC) 
	,SUM(GV_SRV) 
	,SUM(EV) EV
	,SUM(UV) UV
	,SUM(MPCV) MPCV	
	,SUM(TOTAL_POINTS) TOTAL_POINTS
	,SUM(QCPV) QCPV
	,SUM(QDV) QDV
	,SUM(QDV_DV) QDV_DV
	,SUM(PPV_DLV) PPV_DLV
	,SUM(DV_DLVDV) DV_DLVDV				 
FROM
	#FQSID_xJoin
WHERE
	MainIsType23 != 1
GROUP BY
	RoyaltyMonth
	,PK_MainDistributor

SET @EndTime = GETUTCDATE()

  PRINT 'Step 50'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '50' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  8 OR (@fp = 1 AND @Step >= 8)
BEGIN

/******************************************************************************
	aggregate transfer id's to main id for type 2/3
******************************************************************************/
SET @StartTime = GETUTCDATE() --Step 55

IF OBJECT_ID('tempdb..#FQSID_Type23AggTransfers') IS NOT NULL 
	DROP TABLE #FQSID_Type23AggTransfers

CREATE TABLE #FQSID_Type23AggTransfers
(
	RoyaltyMonth smalldatetime
	,PK_Distributor int
	,IsType23 bit
	,PK_MainDistributor int
	,MainIsType23 bit
	,TV money DEFAULT 0
	,RO money DEFAULT 0
	,PB money DEFAULT 0
	,PV money DEFAULT 0
	,GV money DEFAULT 0
	,PPV money DEFAULT 0
	,OV money DEFAULT 0
    ,DLV money DEFAULT 0
	,MPV money DEFAULT 0
	,MTV money DEFAULT 0
	,DV money DEFAULT 0
	,PPC money DEFAULT 0
	,PRV money DEFAULT 0
	,NDV money DEFAULT 0
	,SPC money DEFAULT 0
	,SRV money DEFAULT 0
	,PV_DV money DEFAULT 0
	,PV_PPC money DEFAULT 0
	,PV_PRV money DEFAULT 0
	,PV_NDV money DEFAULT 0
	,PV_SPC money DEFAULT 0
	,PV_SRV money DEFAULT 0
	,DLV_DV money DEFAULT 0
	,DLV_PPC money DEFAULT 0
	,DLV_PRV money DEFAULT 0
	,DLV_NDV money DEFAULT 0
	,DLV_SPC money DEFAULT 0
	,DLV_SRV money DEFAULT 0
	,GV_DV money DEFAULT 0
	,GV_PPC money DEFAULT 0
	,GV_PRV money DEFAULT 0
	,GV_NDV money DEFAULT 0
	,GV_SPC money DEFAULT 0
	,GV_SRV money DEFAULT 0
	,EV money DEFAULT 0
	,UV money DEFAULT 0
	,MPCV money DEFAULT 0
	,TOTAL_POINTS money DEFAULT 0
	,QCPV money DEFAULT 0
	,QDV money DEFAULT 0
	,QDV_DV money DEFAULT 0
	,PPV_DLV money DEFAULT 0
	,DV_DLVDV money DEFAULT 0					  
)

INSERT
	#FQSID_Type23AggTransfers
(
	RoyaltyMonth
	,PK_Distributor
	,IsType23
	,PK_MainDistributor
	,MainIsType23
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
    ,DLV
	,MPV
	,MTV
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
)
SELECT
	RoyaltyMonth
	,CASE IsType23 WHEN 0 THEN PK_MainDistributor ELSE PK_Distributor END
	,CASE IsType23 WHEN 0 THEN MainIsType23 ELSE IsType23 END
	,PK_MainDistributor
	,MainIsType23
	,SUM(TV)
	,SUM(RO)
	,SUM(PB)
	,SUM(PV)
	,SUM(GV)
	,SUM(PPV)
	,SUM(OV)
    ,SUM(DLV)
	,SUM(MPV)
	,SUM(MTV)
	,SUM(DV)
	,SUM(PPC)
	,SUM(PRV)
	,SUM(NDV)
	,SUM(SPC)
	,SUM(SRV)
	,SUM(PV_DV)
	,SUM(PV_PPC) 
	,SUM(PV_PRV) 
	,SUM(PV_NDV) 
	,SUM(PV_SPC) 
	,SUM(PV_SRV) 
	,SUM(DLV_DV) 
	,SUM(DLV_PPC) 
	,SUM(DLV_PRV) 
	,SUM(DLV_NDV) 
	,SUM(DLV_SPC) 
	,SUM(DLV_SRV) 
	,SUM(GV_DV) 
	,SUM(GV_PPC) 
	,SUM(GV_PRV) 
	,SUM(GV_NDV) 
	,SUM(GV_SPC) 
	,SUM(GV_SRV) 
	,SUM(EV) EV
	,SUM(UV) UV
	,SUM(MPCV) MPCV
	,SUM(TOTAL_POINTS) TOTAL_POINTS
	,SUM(QCPV) QCPV
	,SUM(QDV) QDV
	,SUM(QDV_DV) QDV_DV
	,SUM(PPV_DLV) PPV_DLV
	,SUM(DV_DLVDV) DV_DLVDV				
FROM
	#FQSID_xJoin
WHERE
	MainIsType23 = 1
GROUP BY
	RoyaltyMonth
	,CASE IsType23 WHEN 0 THEN PK_MainDistributor ELSE PK_Distributor END
	,CASE IsType23 WHEN 0 THEN MainIsType23 ELSE IsType23 END
	,PK_MainDistributor
	,MainIsType23

SET @EndTime = GETUTCDATE()

  PRINT 'Step 55'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '55' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  9 OR (@fp = 1 AND @Step >= 9)
BEGIN

/******************************************************************************
	assign main metrics to associates
******************************************************************************/
SET @StartTime = GETUTCDATE() --Step 60

IF OBJECT_ID('tempdb..#FQSID_Type23Final') IS NOT NULL 
	DROP TABLE #FQSID_Type23Final

CREATE TABLE #FQSID_Type23Final
(
	RoyaltyMonth smalldatetime
	,Pk_Distributor int
	,IsType23 bit
	,IsMainID bit 
	,TV money DEFAULT 0
	,RO money DEFAULT 0
	,PB money DEFAULT 0
	,PV money DEFAULT 0
	,GV money DEFAULT 0
	,PPV money DEFAULT 0
	,OV money DEFAULT 0
	,PK_MainDistributor int
	,MainIsType23 bit
	,MainTV money DEFAULT 0
	,MainRO money DEFAULT 0
	,MainPB money DEFAULT 0
	,MainPV money DEFAULT 0
	,MainGV money DEFAULT 0
	,MainPPV money DEFAULT 0
	,MainOV money DEFAULT 0
    ,DLV money DEFAULT 0
    ,MainDLV money DEFAULT 0
	,MPV money DEFAULT 0
	,MTV money DEFAULT 0
	,MainMPV money DEFAULT 0
	,MainMTV money DEFAULT 0
	,DV money DEFAULT 0
	,PPC money DEFAULT 0
	,PRV money DEFAULT 0
	,NDV money DEFAULT 0
	,SPC money DEFAULT 0
	,SRV money DEFAULT 0
	,PV_DV money DEFAULT 0
	,PV_PPC money DEFAULT 0
	,PV_PRV money DEFAULT 0
	,PV_NDV money DEFAULT 0
	,PV_SPC money DEFAULT 0
	,PV_SRV money DEFAULT 0
	,DLV_DV money DEFAULT 0
	,DLV_PPC money DEFAULT 0
	,DLV_PRV money DEFAULT 0
	,DLV_NDV money DEFAULT 0
	,DLV_SPC money DEFAULT 0
	,DLV_SRV money DEFAULT 0
	,GV_DV money DEFAULT 0
	,GV_PPC money DEFAULT 0
	,GV_PRV money DEFAULT 0
	,GV_NDV money DEFAULT 0
	,GV_SPC money DEFAULT 0
	,GV_SRV money DEFAULT 0
	,EV money DEFAULT 0
	,UV money DEFAULT 0
	,MPCV money DEFAULT 0
	,TOTAL_POINTS money DEFAULT 0
	,QCPV money DEFAULT 0
	,QDV money DEFAULT 0
	,QDV_DV money DEFAULT 0
	,PPV_DLV money DEFAULT 0
	,DV_DLVDV money DEFAULT 0					  
	,MainDV money DEFAULT 0
	,MainPPC money DEFAULT 0
	,MainPRV money DEFAULT 0
	,MainNDV money DEFAULT 0
	,MainSPC money DEFAULT 0
	,MainSRV money DEFAULT 0
	,MainPV_DV money DEFAULT 0
	,MainPV_PPC money DEFAULT 0
	,MainPV_PRV money DEFAULT 0
	,MainPV_NDV money DEFAULT 0
	,MainPV_SPC money DEFAULT 0
	,MainPV_SRV money DEFAULT 0
	,MainDLV_DV money DEFAULT 0
	,MainDLV_PPC money DEFAULT 0
	,MainDLV_PRV money DEFAULT 0
	,MainDLV_NDV money DEFAULT 0
	,MainDLV_SPC money DEFAULT 0
	,MainDLV_SRV money DEFAULT 0
	,MainGV_DV money DEFAULT 0
	,MainGV_PPC money DEFAULT 0
	,MainGV_PRV money DEFAULT 0
	,MainGV_NDV money DEFAULT 0
	,MainGV_SPC money DEFAULT 0
	,MainGV_SRV money DEFAULT 0
	,MainEV money DEFAULT 0
	,MainUV money DEFAULT 0
	,MainMPCV money DEFAULT 0
	,MainTOTAL_POINTS money DEFAULT 0
	,MainQCPV money DEFAULT 0
	,MainQDV money DEFAULT 0
	,MainQDV_DV money DEFAULT 0
	,MainPPV_DLV money DEFAULT 0
	,MainDV_DLVDV money DEFAULT 0	
	)


DROP TABLE IF EXISTS #FQSID_Type23AggTransfersMonthCountry

SELECT DISTINCT A.PK_Distributor,S.PK_MainDistributor,S.PK_AssociatedID,A.IsType23,A.MainIsType23,A.RoyaltyMonth
INTO #FQSID_Type23AggTransfersMonthCountry
FROM
	#FQSID_Type23AggTransfers A
INNER JOIN #assoc1 AS s
	ON A.PK_Distributor = s.PK_Distributor
WHERE s.AssociationType = 3
UNION
SELECT DISTINCT A.PK_MainDistributor AS PK_Distributor,S.PK_MainDistributor,S.PK_AssociatedID,A.IsType23,A.MainIsType23,A.RoyaltyMonth
FROM
	#FQSID_Type23AggTransfers A
INNER JOIN #assoc1 AS s
	ON A.PK_MainDistributor = s.PK_MainDistributor
WHERE s.AssociationType = 3
UNION
SELECT DISTINCT s.PK_AssociatedID AS PK_Distributor,S.PK_MainDistributor,S.PK_MainDistributor AS PK_AssociatedID,A.IsType23,A.MainIsType23,A.RoyaltyMonth
FROM
	#FQSID_Type23AggTransfers A
INNER JOIN #assoc1 AS s
	ON A.PK_Distributor = s.PK_MainDistributor
WHERE s.AssociationType = 2
UNION
SELECT DISTINCT s.PK_AssociatedID AS PK_Distributor,S.PK_MainDistributor,S.PK_MainDistributor AS PK_AssociatedID,A.IsType23,A.MainIsType23,A.RoyaltyMonth
FROM
	#FQSID_Type23AggTransfers A
INNER JOIN #assoc1 AS s
	ON A.PK_Distributor = s.PK_AssociatedID
WHERE s.AssociationType = 2
 
DROP TABLE IF EXISTS #FQSID_Type23AggTransfersMonthCountryUniqueCombinations
 
 SELECT DISTINCT PK_AssociatedID	
	,IsType23	
	,MainIsType23	
	,RoyaltyMonth	
INTO #FQSID_Type23AggTransfersMonthCountryUniqueCombinations
FROM #FQSID_Type23AggTransfersMonthCountry

DROP TABLE IF EXISTS #FQSID_Type23AggTransfersCombinations

 SELECT DISTINCT A.PK_Distributor,A.PK_MainDistributor,A.PK_AssociatedID,C.IsType23,C.MainIsType23,C.RoyaltyMonth,a.AssociationType 
  INTO #FQSID_Type23AggTransfersCombinations 
 FROM #FQSID_Type23AggTransfersMonthCountryUniqueCombinations AS c
	INNER JOIN #assoc1 AS a
		ON c.PK_AssociatedID = a.PK_AssociatedID  
UNION
  SELECT DISTINCT A.PK_MainDistributor AS PK_Distributor,A.PK_MainDistributor,A.PK_AssociatedID,C.IsType23,C.MainIsType23,C.RoyaltyMonth,a.AssociationType 
 FROM #FQSID_Type23AggTransfersMonthCountryUniqueCombinations AS c
	INNER JOIN #assoc1 AS a
		ON c.PK_AssociatedID = a.PK_MainDistributor  
WHERE a.AssociationType = 3
UNION
  SELECT DISTINCT A.PK_Distributor,A.PK_MainDistributor,A.PK_AssociatedID,C.IsType23,C.MainIsType23,C.RoyaltyMonth,a.AssociationType 
 FROM #FQSID_Type23AggTransfersMonthCountryUniqueCombinations AS c
	INNER JOIN #assoc1 AS a
		ON c.PK_AssociatedID = a.PK_MainDistributor  
WHERE a.AssociationType = 2


INSERT 
	#FQSID_Type23Final
(
	RoyaltyMonth
	,PK_Distributor
	,IsType23
	,IsMainID
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
	,PK_MainDistributor
	,MainIsType23
	,MainTV
	,MainRO
	,MainPB
	,MainPV
	,MainGV
	,MainPPV
	,MainOV
    ,DLV
    ,MainDLV
	,MPV 
	,MTV 
	,MainMPV 
	,MainMTV
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
	,MainDV
	,MainPPC
	,MainPRV
	,MainNDV
	,MainSPC
	,MainSRV
	,MainPV_DV
	,MainPV_PPC
	,MainPV_PRV
	,MainPV_NDV
	,MainPV_SPC
	,MainPV_SRV
	,MainDLV_DV
	,MainDLV_PPC
	,MainDLV_PRV
	,MainDLV_NDV
	,MainDLV_SPC
	,MainDLV_SRV
	,MainGV_DV
	,MainGV_PPC
	,MainGV_PRV
	,MainGV_NDV
	,MainGV_SPC
	,MainGV_SRV
	,MainEV
	,MainUV
	,MainMPCV
	,MainTOTAL_POINTS
	,MainQCPV
	,MainQDV
	,MainQDV_DV
	,MainPPV_DLV
	,MainDV_DLVDV
)
SELECT DISTINCT
	C.RoyaltyMonth
	,C.PK_Distributor
	,C.IsType23
	,0 AS IsMain
	,ISNULL(A.TV,0) AS [TV]
	,ISNULL(A.RO,0) AS [RO]
	,ISNULL(A.PB,0) AS [PB]
	,ISNULL(A.PV,0) AS [PV]
	,ISNULL(A.GV,0) AS [GV]
	,ISNULL(A.PPV,0) AS [PPV]
	,ISNULL(A.OV,0) AS [OV]
	,C.PK_MainDistributor
	,C.MainIsType23
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.TV,0) END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.RO,0) END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.PB,0) END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.PV,0) END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.GV,0) END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.PPV,0) END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.OV,0)  END
    ,ISNULL(A.DLV,0)
    ,CASE WHEN A.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.DLV,0)END
	,ISNULL(A.MPV,0)
	,ISNULL(A.MTV,0)
	,CASE WHEN A.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.MPV,0)END
	,CASE WHEN A.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.MTV,0)END
	,ISNULL(A.DV,0)
	,ISNULL(A.PPC,0)
	,ISNULL(A.PRV,0)
	,ISNULL(A.NDV,0)
	,ISNULL(A.SPC,0)
	,ISNULL(A.SRV,0)
	,ISNULL(A.PV_DV,0)
	,ISNULL(A.PV_PPC,0)
	,ISNULL(A.PV_PRV,0)
	,ISNULL(A.PV_NDV,0)
	,ISNULL(A.PV_SPC,0)
	,ISNULL(A.PV_SRV,0)
	,ISNULL(A.DLV_DV,0)
	,ISNULL(A.DLV_PPC,0)
	,ISNULL(A.DLV_PRV,0)
	,ISNULL(A.DLV_NDV,0)
	,ISNULL(A.DLV_SPC,0)
	,ISNULL(A.DLV_SRV,0)
	,ISNULL(A.GV_DV,0)
	,ISNULL(A.GV_PPC,0)
	,ISNULL(A.GV_PRV,0)
	,ISNULL(A.GV_NDV,0)
	,ISNULL(A.GV_SPC,0)
	,ISNULL(A.GV_SRV,0)
	,ISNULL(A.EV,0)
	,ISNULL(A.UV,0)
	,ISNULL(A.MPCV,0)
	,ISNULL(A.TOTAL_POINTS,0)
	,ISNULL(A.QCPV,0)
	,ISNULL(A.QDV,0)
	,ISNULL(A.QDV_DV,0)
	,ISNULL(A.PPV_DLV,0)
	,ISNULL(A.DV_DLVDV,0)	
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.DV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.PPC,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.PRV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.NDV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.SPC,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.SRV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.PV_DV,0)END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.PV_PPC,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.PV_PRV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.PV_NDV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.PV_SPC,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.PV_SRV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.DLV_DV,0)END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.DLV_PPC,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.DLV_PRV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.DLV_NDV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.DLV_SPC,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.DLV_SRV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.GV_DV,0)END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.GV_PPC,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.GV_PRV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.GV_NDV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.GV_SPC,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.GV_SRV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.EV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.UV,0)END 
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.MPCV,0)END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.TOTAL_POINTS,0)END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.QCPV,0)END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.QDV,0)END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.QDV_DV,0)END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.PPV_DLV,0)END
	,CASE WHEN C.PK_MainDistributor = A.PK_Distributor AND C.AssociationType= 3 THEN 0 ELSE ISNULL(MAIN.DV_DLVDV,0)END
FROM #FQSID_Type23AggTransfersCombinations AS C
LEFT JOIN
	#FQSID_Type23AggTransfers A
		ON C.RoyaltyMonth = A.RoyaltyMonth 
		AND
		C.PK_Distributor = A.PK_Distributor
LEFT JOIN
	#FQSID_Type23AggTransfers MAIN
	ON
		C.RoyaltyMonth = MAIN.RoyaltyMonth 
		AND
		C.PK_AssociatedID = MAIN.PK_Distributor


UPDATE #FQSID_Type23Final
SET IsMainID = 1
WHERE Pk_Distributor = PK_MainDistributor
 
SET @EndTime = GETUTCDATE()

  PRINT 'Step 60'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '60' ,@StartTime = @StartTime

END

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  10 OR (@fp = 1 AND @Step >= 10)
BEGIN

/******************************************************************************
	Divorce cases with 2 IDs, MainID active
******************************************************************************/
SET @StartTime = GETUTCDATE() --Step 65

	DROP TABLE IF EXISTS #FQSID_Type23Final_Associated 

		SELECT 
			F.PK_Distributor,
			S.PK_AssociatedID,
			F.RoyaltyMonth,
			ISNULL(FA.RO,0)	AS MainRO,
			ISNULL(FA.TV,0)	AS MainTV,
			ISNULL(FA.PV,0)	AS MainPV,
			ISNULL(FA.GV,0)	AS MainGV
		INTO #FQSID_Type23Final_Associated
		FROM #FQSID_Type23Final AS F
			INNER JOIN [PubEventManagement].[Shared].[DistributorAssociation] AS S WITH (NOLOCK)
				ON F.Pk_Distributor = S.PK_Distributor AND F.Pk_Distributor = S.nMainDistributorID
			INNER JOIN #FQSID_Type23Final FA
				ON FA.Pk_Distributor = S.PK_AssociatedID AND FA.RoyaltyMonth = F.RoyaltyMonth

		CREATE INDEX IX_#FQSID_Type23Final_Associated_PK_Distributor ON #FQSID_Type23Final_Associated(PK_Distributor)

		UPDATE F
			SET MainRO = A.MainRO,
				MainTV = A.MainTV,
				MainPV = A.MainPV,
				MainGV = A.MainGV
		FROM #FQSID_Type23Final AS F
			INNER JOIN #FQSID_Type23Final_Associated AS A
				ON F.Pk_Distributor = A.Pk_Distributor  
					AND F.RoyaltyMonth = A.RoyaltyMonth

SET @EndTime = GETUTCDATE()

  PRINT 'Step 65'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '65' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  11 OR (@fp = 1 AND @Step >= 11)
BEGIN

/******************************************************************************
	aggregate all non-type23
******************************************************************************/
SET @StartTime = GETUTCDATE() --Step 70

CREATE INDEX IX_#Assoc1_PK_Distributor ON #Assoc1(PK_Distributor)

IF OBJECT_ID('tempdb..#FQSID_CombinedNonTyp23') IS NOT NULL DROP TABLE #FQSID_CombinedNonTyp23
CREATE TABLE #FQSID_CombinedNonTyp23 (
	RoyaltyMonth smalldatetime
	,PK_Distributor int
	,TV money DEFAULT 0
	,RO money DEFAULT 0
	,PB money DEFAULT 0
	,PV money DEFAULT 0
	,GV money DEFAULT 0
	,PPV money DEFAULT 0
	,OV money DEFAULT 0
    ,DLV money DEFAULT 0
	,MPV money DEFAULT 0
	,MTV money DEFAULT 0
	,DV money DEFAULT 0
	,PPC money DEFAULT 0
	,PRV money DEFAULT 0
	,NDV money DEFAULT 0
	,SPC money DEFAULT 0
	,SRV money DEFAULT 0
	,PV_DV money DEFAULT 0
	,PV_PPC money DEFAULT 0
	,PV_PRV money DEFAULT 0
	,PV_NDV money DEFAULT 0
	,PV_SPC money DEFAULT 0
	,PV_SRV money DEFAULT 0
	,DLV_DV money DEFAULT 0
	,DLV_PPC money DEFAULT 0
	,DLV_PRV money DEFAULT 0
	,DLV_NDV money DEFAULT 0
	,DLV_SPC money DEFAULT 0
	,DLV_SRV money DEFAULT 0
	,GV_DV money DEFAULT 0
	,GV_PPC money DEFAULT 0
	,GV_PRV money DEFAULT 0
	,GV_NDV money DEFAULT 0
	,GV_SPC money DEFAULT 0
	,GV_SRV money DEFAULT 0
	,EV money DEFAULT 0
	,UV money DEFAULT 0
	,MPCV money DEFAULT 0
	,TOTAL_POINTS money DEFAULT 0
	,QCPV money DEFAULT 0
	,QDV money DEFAULT 0
	,QDV_DV money DEFAULT 0
	,PPV_DLV money DEFAULT 0
	,DV_DLVDV money DEFAULT 0				  
)
INSERT
	#FQSID_CombinedNonTyp23
(
	RoyaltyMonth
	,PK_Distributor
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
    ,DLV
	,MPV
	,MTV
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
)
/* get everyone not in associate table */
SELECT
	RoyaltyMonth
	,A.PK_Distributor
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
    ,DLV
	,MPV 
	,MTV
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
FROM
	#FQSID_AllIDs A WHERE A.IsInAssocTable = 0
/* get everyone in associate table not type 2 or 3 */
UNION
SELECT
	 RoyaltyMonth
	,PK_Distributor
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
    ,DLV
	,MPV 
	,MTV
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
FROM
	#FQSID_MainNot23
OPTION (RECOMPILE)

CREATE INDEX IX_CombinedNonTyp23_RoyaltyMonth ON #FQSID_CombinedNonTyp23(RoyaltyMonth)
CREATE INDEX IX_CombinedNonTyp23_DistributorID ON #FQSID_CombinedNonTyp23(PK_Distributor)
CREATE INDEX IX_CombinedNonTyp23_TV ON #FQSID_CombinedNonTyp23(TV)
CREATE INDEX IX_CombinedNonTyp23_RO ON #FQSID_CombinedNonTyp23(RO)
CREATE INDEX IX_CombinedNonTyp23_PB ON #FQSID_CombinedNonTyp23(PB)

SET @EndTime = GETUTCDATE()

  PRINT 'Step 70'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '70' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  12 OR (@fp = 1 AND @Step >= 12)
BEGIN

SET @StartTime = GETUTCDATE() --Step 71

IF OBJECT_ID('tempdb..#FQSID_CombinedNonTyp23_DEDUPED') IS NOT NULL DROP TABLE #FQSID_CombinedNonTyp23_DEDUPED
CREATE TABLE #FQSID_CombinedNonTyp23_DEDUPED (
	RoyaltyMonth smalldatetime
	,PK_Distributor int
	,TV money DEFAULT 0
	,RO money DEFAULT 0
	,PB money DEFAULT 0
	,PV money DEFAULT 0
	,GV money DEFAULT 0
	,PPV money DEFAULT 0
	,OV money DEFAULT 0
    ,DLV money DEFAULT 0
	,MPV money DEFAULT 0
	,MTV money DEFAULT 0
	,DV money DEFAULT 0
	,PPC money DEFAULT 0
	,PRV money DEFAULT 0
	,NDV money DEFAULT 0
	,SPC money DEFAULT 0
	,SRV money DEFAULT 0
	,PV_DV money DEFAULT 0
	,PV_PPC money DEFAULT 0
	,PV_PRV money DEFAULT 0
	,PV_NDV money DEFAULT 0
	,PV_SPC money DEFAULT 0
	,PV_SRV money DEFAULT 0
	,DLV_DV money DEFAULT 0
	,DLV_PPC money DEFAULT 0
	,DLV_PRV money DEFAULT 0
	,DLV_NDV money DEFAULT 0
	,DLV_SPC money DEFAULT 0
	,DLV_SRV money DEFAULT 0
	,GV_DV money DEFAULT 0
	,GV_PPC money DEFAULT 0
	,GV_PRV money DEFAULT 0
	,GV_NDV money DEFAULT 0
	,GV_SPC money DEFAULT 0
	,GV_SRV money DEFAULT 0
	,EV money DEFAULT 0
	,UV money DEFAULT 0
	,MPCV money DEFAULT 0
	,TOTAL_POINTS money DEFAULT 0
	,QCPV money DEFAULT 0
	,QDV money DEFAULT 0
	,QDV_DV money DEFAULT 0
	,PPV_DLV money DEFAULT 0
	,DV_DLVDV money DEFAULT 0					  
)

INSERT
	#FQSID_CombinedNonTyp23_DEDUPED
(
	RoyaltyMonth
	,PK_Distributor
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
    ,DLV
	,MPV 
	,MTV
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
)
SELECT
	RoyaltyMonth
	,PK_Distributor
	,SUM(TV)
	,SUM(RO)
	,SUM(PB)
	,SUM(PV)
	,SUM(GV)
	,SUM(PPV)
	,SUM(OV)
    ,SUM(DLV)
	,SUM(MPV)
	,SUM(MTV)
	,SUM(DV)
	,SUM(PPC)
	,SUM(PRV)
	,SUM(NDV)
	,SUM(SPC)
	,SUM(SRV)
	,SUM(PV_DV) 
	,SUM(PV_PPC) 
	,SUM(PV_PRV) 
	,SUM(PV_NDV) 
	,SUM(PV_SPC) 
	,SUM(PV_SRV) 
	,SUM(DLV_DV)
	,SUM(DLV_PPC) 
	,SUM(DLV_PRV) 
	,SUM(DLV_NDV) 
	,SUM(DLV_SPC) 
	,SUM(DLV_SRV) 
	,SUM(GV_DV) 
	,SUM(GV_PPC) 
	,SUM(GV_PRV) 
	,SUM(GV_NDV) 
	,SUM(GV_SPC) 
	,SUM(GV_SRV) 
	,SUM(EV) EV
	,SUM(UV) UV
	,SUM(MPCV) MPCV
	,SUM(TOTAL_POINTS) TOTAL_POINTS
	,SUM(QCPV) QCPV
	,SUM(QDV) QDV
	,SUM(QDV_DV) QDV_DV
	,SUM(PPV_DLV) PPV_DLV
	,SUM(DV_DLVDV) DV_DLVDV				
FROM
	#FQSID_CombinedNonTyp23
GROUP BY
	RoyaltyMonth
	,PK_Distributor
OPTION (RECOMPILE)

SET @EndTime = GETUTCDATE()

  PRINT 'Step 71'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '71' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  13 OR (@fp = 1 AND @Step >= 13)
BEGIN

/******************************************************************************
	combine transfer of 23 that exist with non-transfer 23
******************************************************************************/
SET @StartTime = GETUTCDATE() --Step 72

IF OBJECT_ID('tempdb..#FQSID_Transfer23') IS NOT NULL DROP TABLE #FQSID_Transfer23
CREATE TABLE #FQSID_Transfer23 (
	RoyaltyMonth smalldatetime
	,PK_Distributor int
	,PK_MainDistributor int
	,TV money DEFAULT 0
	,RO money DEFAULT 0
	,PB money DEFAULT 0
	,PV money DEFAULT 0
	,GV money DEFAULT 0
	,PPV money DEFAULT 0
	,OV money DEFAULT 0
	,MainTV money DEFAULT 0
	,MainRO money DEFAULT 0
	,MainPB money DEFAULT 0
	,MainPV money DEFAULT 0
	,MainGV money DEFAULT 0
	,MainPPV money DEFAULT 0
	,MainOV money DEFAULT 0
    ,DLV money DEFAULT 0
    ,MainDLV money DEFAULT 0
	,MPV money DEFAULT 0
	,MTV money DEFAULT 0
	,DV money DEFAULT 0
	,PPC money DEFAULT 0
	,PRV money DEFAULT 0
	,NDV money DEFAULT 0
	,SPC money DEFAULT 0
	,SRV money DEFAULT 0
	,PV_DV money DEFAULT 0
	,PV_PPC money DEFAULT 0
	,PV_PRV money DEFAULT 0
	,PV_NDV money DEFAULT 0
	,PV_SPC money DEFAULT 0
	,PV_SRV money DEFAULT 0
	,DLV_DV money DEFAULT 0
	,DLV_PPC money DEFAULT 0
	,DLV_PRV money DEFAULT 0
	,DLV_NDV money DEFAULT 0
	,DLV_SPC money DEFAULT 0
	,DLV_SRV money DEFAULT 0
	,GV_DV money DEFAULT 0
	,GV_PPC money DEFAULT 0
	,GV_PRV money DEFAULT 0
	,GV_NDV money DEFAULT 0
	,GV_SPC money DEFAULT 0
	,GV_SRV money DEFAULT 0
	,EV money DEFAULT 0
	,UV money DEFAULT 0
	,MPCV money DEFAULT 0
	,TOTAL_POINTS money DEFAULT 0
	,QCPV money DEFAULT 0
	,QDV money DEFAULT 0
	,QDV_DV money DEFAULT 0
	,PPV_DLV money DEFAULT 0
	,DV_DLVDV money DEFAULT 0					  
	,MainMPV money DEFAULT 0
	,MainMTV money DEFAULT 0
	,MainDV money DEFAULT 0
	,MainPPC money DEFAULT 0
	,MainPRV money DEFAULT 0
	,MainNDV money DEFAULT 0
	,MainSPC money DEFAULT 0
	,MainSRV money DEFAULT 0
	,MainPV_DV money DEFAULT 0
	,MainPV_PPC money DEFAULT 0
	,MainPV_PRV money DEFAULT 0
	,MainPV_NDV money DEFAULT 0
	,MainPV_SPC money DEFAULT 0
	,MainPV_SRV money DEFAULT 0
	,MainDLV_DV money DEFAULT 0
	,MainDLV_PPC money DEFAULT 0
	,MainDLV_PRV money DEFAULT 0
	,MainDLV_NDV money DEFAULT 0
	,MainDLV_SPC money DEFAULT 0
	,MainDLV_SRV money DEFAULT 0
	,MainGV_DV money DEFAULT 0
	,MainGV_PPC money DEFAULT 0
	,MainGV_PRV money DEFAULT 0
	,MainGV_NDV money DEFAULT 0
	,MainGV_SPC money DEFAULT 0
	,MainGV_SRV money DEFAULT 0
	,MainEV money DEFAULT 0
	,MainUV money DEFAULT 0
	,MainMPCV money DEFAULT 0
	,MainTOTAL_POINTS money DEFAULT 0
	,MainQCPV money DEFAULT 0
	,MainQDV money DEFAULT 0
	,MainQDV_DV money DEFAULT 0
	,MainPPV_DLV money DEFAULT 0
	,MainDV_DLVDV money DEFAULT 0						  
)
INSERT
	#FQSID_Transfer23
(
	RoyaltyMonth
	,PK_Distributor
	,PK_MainDistributor
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
	,MainTV
	,MainRO
	,MainPB
	,MainPV
	,MainGV
	,MainPPV
	,MainOV
    ,DLV
    ,MainDLV
	,MPV
	,MTV 
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,MainMPV 
	,MainMTV 
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
	,MainDV
	,MainPPC
	,MainPRV
	,MainNDV
	,MainSPC
	,MainSRV
	,MainPV_DV
	,MainPV_PPC
	,MainPV_PRV
	,MainPV_NDV
	,MainPV_SPC
	,MainPV_SRV
	,MainDLV_DV
	,MainDLV_PPC
	,MainDLV_PRV
	,MainDLV_NDV
	,MainDLV_SPC
	,MainDLV_SRV
	,MainGV_DV
	,MainGV_PPC
	,MainGV_PRV
	,MainGV_NDV
	,MainGV_SPC
	,MainGV_SRV
	,MainEV
	,MainUV
	,MainMPCV
	,MainTOTAL_POINTS
	,MainQCPV
	,MainQDV
	,MainQDV_DV
	,MainPPV_DLV
	,MainDV_DLVDV		  
)
SELECT  
	F.RoyaltyMonth
	,F.PK_Distributor
	,F.PK_MainDistributor
	,F.TV + D.TV
	,F.RO + D.RO
	,F.PB + D.PB
	,F.PV + D.PV
	,F.GV + D.GV
	,F.PPV + D.PPV
	,F.OV + D.OV
	,F.MainTV
	,F.MainRO
	,F.MainPB
	,F.MainPV
	,F.MainGV
	,F.MainPPV
	,F.MainOV
    ,F.DLV + D.DLV
    ,F.MainDLV
	,F.MPV + D.MPV 
	,F.MTV + D.MTV 
	,F.DV + D.DV
	,F.PPC + D.PPC
	,F.PRV + D.PRV
	,F.NDV + D.NDV
	,F.SPC + D.SPC
	,F.SRV + D.SRV
	,F.MainMPV 
	,F.MainMTV 
	,F.PV_DV + D.PV_DV
	,F.PV_PPC + D.PV_PPC
	,F.PV_PRV + D.PV_PRV 
	,F.PV_NDV + D.PV_NDV 
	,F.PV_SPC + D.PV_SPC
	,F.PV_SRV + D.PV_SRV
	,F.DLV_DV + D.DLV_DV
	,F.DLV_PPC + D.DLV_PPC
	,F.DLV_PRV + D.DLV_PRV
	,F.DLV_NDV + D.DLV_NDV
	,F.DLV_SPC + D.DLV_SPC
	,F.DLV_SRV + D.DLV_SRV
	,F.GV_DV + D.GV_DV
	,F.GV_PPC + D.GV_PPC
	,F.GV_PRV + D.GV_PRV
	,F.GV_NDV + D.GV_NDV
	,F.GV_SPC + D.GV_SPC
	,F.GV_SRV + D.GV_SRV
	,F.EV + D.EV
	,F.UV + D.UV
	,F.MPCV + D.MPCV
	,F.TOTAL_POINTS + D.TOTAL_POINTS
	,F.QCPV + D.QCPV
	,F.QDV + D.QDV
	,F.QDV_DV + D.QDV_DV
	,F.PPV_DLV + D.PPV_DLV
	,F.DV_DLVDV + D.DV_DLVDV				 
	,F.MainDV
	,F.MainPPC
	,F.MainPRV
	,F.MainNDV
	,F.MainSPC
	,F.MainSRV
	,F.MainPV_DV
	,F.MainPV_PPC
	,F.MainPV_PRV
	,F.MainPV_NDV
	,F.MainPV_SPC
	,F.MainPV_SRV
	,F.MainDLV_DV
	,F.MainDLV_PPC
	,F.MainDLV_PRV
	,F.MainDLV_NDV
	,F.MainDLV_SPC
	,F.MainDLV_SRV
	,F.MainGV_DV
	,F.MainGV_PPC
	,F.MainGV_PRV
	,F.MainGV_NDV
	,F.MainGV_SPC
	,F.MainGV_SRV
	,F.MainEV
	,F.MainUV
	,F.MainMPCV
	,F.MainTOTAL_POINTS
	,F.MainQCPV
	,F.MainQDV
	,F.MainQDV_DV
	,F.MainPPV_DLV
	,F.MainDV_DLVDV			
FROM
	#FQSID_Type23Final F
INNER JOIN
	#FQSID_CombinedNonTyp23_DEDUPED D
	ON
		F.PK_Distributor = D.PK_Distributor
		AND
		F.RoyaltyMonth = D.RoyaltyMonth

SET @EndTime = GETUTCDATE()

  PRINT 'Step 72'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '72' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  14 OR (@fp = 1 AND @Step >= 14)
BEGIN

SET @StartTime = GETUTCDATE() --Step 73

DELETE FROM
	F
FROM
	#FQSID_Type23Final F
INNER JOIN
	#FQSID_Transfer23 D
	ON
		F.PK_Distributor = D.PK_Distributor
		AND
		F.RoyaltyMonth = D.RoyaltyMonth

DELETE FROM
	F
FROM
	#FQSID_CombinedNonTyp23_DEDUPED F
INNER JOIN
	#FQSID_Transfer23 D
	ON
		F.PK_Distributor = D.PK_Distributor
		AND
		F.RoyaltyMonth = D.RoyaltyMonth

SET @EndTime = GETUTCDATE()

  PRINT 'Step 73'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '73' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  15 OR (@fp = 1 AND @Step >= 15)
BEGIN

/******************************************************************************
	pull yourself together man!
******************************************************************************/
/*
For scenarios involving only transfer, there are multiple records for the 
main distributor for one royalty month. Also, the bit, nIsInAssocTable is 
set to 0 for one record and set to 1 for another record. This is happening 
because while inserting distributors who are not present in the associate table 
into the final table, only the ndistributorid is considered. Since, the main 
involved in transfer does not have any record for him with in the associate table
*/

SET @StartTime = GETUTCDATE()


IF @IsDevQA = 0 TRUNCATE TABLE dbo.wrkDSFinancial

--DISABLE INDEX

IF @IsDevQA = 0 EXEC pubEvents.dbo.usp_UtilityDisableIdx 'PubEventManagement', 'wrkDSFinancial'

SET @EndTime = GETUTCDATE()

  PRINT 'Step 80'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '80' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  16 OR (@fp = 1 AND @Step >= 16)
BEGIN

SET @StartTime = GETUTCDATE() --Step 85
 
DROP TABLE IF EXISTS #SourceMetrics 

SELECT
	 @Timestamp AS LastModifiedDate
	,RoyaltyMonth
	,PK_Distributor
	,0 AS IsAssocType23
	,0 AS IsMainID
	,0 AS IsInAssocTable
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
	,PK_Distributor AS PK_MainDistributorID
	,0 AS MainIsType23
	,0 AS MainTV
	,0 AS MainRO
	,0 AS MainPB
	,0 AS MainPV
	,0 AS MainGV
	,0 AS MainPPV
	,0 AS MainOV
    ,DLV
    ,0 AS MainDLV
	,MPV 
	,MTV 
	,0 AS MainMPV
	,0 AS MainMTV
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
	,0 AS MainDV
	,0 AS MainPPC
	,0 AS MainPRV
	,0 AS MainNDV
	,0 AS MainSPC
	,0 AS MainSRV
	,0 AS MainPV_DV
	,0 AS MainPV_PPC
	,0 AS MainPV_PRV
	,0 AS MainPV_NDV
	,0 AS MainPV_SPC
	,0 AS MainPV_SRV
	,0 AS MainDLV_DV
	,0 AS MainDLV_PPC
	,0 AS MainDLV_PRV
	,0 AS MainDLV_NDV
	,0 AS MainDLV_SPC
	,0 AS MainDLV_SRV
	,0 AS MainGV_DV
	,0 AS MainGV_PPC
	,0 AS MainGV_PRV
	,0 AS MainGV_NDV
	,0 AS MainGV_SPC
	,0 AS MainGV_SRV
	,0 AS MainEV
	,0 AS MainUV
	,0 AS MainMPCV
	,0 AS MainTOTAL_POINTS
	,0 AS MainQCPV
	,0 AS MainQDV
	,0 AS MainQDV_DV
	,0 AS MainPPV_DLV
	,0 AS MainDV_DLVDV	
INTO #SourceMetrics
FROM
	#FQSID_CombinedNonTyp23_DEDUPED
/* get type 2 or 3 assocates */
UNION ALL
SELECT
	@Timestamp
	,RoyaltyMonth
	,PK_Distributor
	,1 --nIsAssocType23
	,IsMainID
	,1 --nIsInAssocTable
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
	,PK_MainDistributor
	,MainIsType23
	,MainTV
	,MainRO
	,MainPB
	,MainPV
	,MainGV
	,MainPPV
	,MainOV
    ,DLV
    ,MainDLV
	,MPV 
	,MTV 
	,MainMPV 
	,MainMTV 
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
	,MainDV
	,MainPPC
	,MainPRV
	,MainNDV
	,MainSPC
	,MainSRV
	,MainPV_DV
	,MainPV_PPC
	,MainPV_PRV
	,MainPV_NDV
	,MainPV_SPC
	,MainPV_SRV
	,MainDLV_DV
	,MainDLV_PPC
	,MainDLV_PRV
	,MainDLV_NDV
	,MainDLV_SPC
	,MainDLV_SRV
	,MainGV_DV
	,MainGV_PPC
	,MainGV_PRV
	,MainGV_NDV
	,MainGV_SPC
	,MainGV_SRV
	,MainEV
	,MainUV
	,MainMPCV
	,MainTOTAL_POINTS
	,MainQCPV
	,MainQDV
	,MainQDV_DV
	,MainPPV_DLV
	,MainDV_DLVDV		  
FROM
	#FQSID_Type23Final
UNION ALL
SELECT
	@Timestamp
	,RoyaltyMonth
	,PK_Distributor
	,1 --nIsAssocType23
	,0 --nIsMainID
	,1 --nIsInAssocTable
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
	,PK_MainDistributor
	,0 --nMainIsType23
	,MainTV
	,MainRO
	,MainPB
	,MainPV
	,MainGV
	,MainPPV
	,MainOV
    ,DLV
    ,MainDLV
	,MPV 
	,MTV 
	,MainMPV 
	,MainMTV 
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
	,MainDV
	,MainPPC
	,MainPRV
	,MainNDV
	,MainSPC
	,MainSRV
	,MainPV_DV
	,MainPV_PPC
	,MainPV_PRV
	,MainPV_NDV
	,MainPV_SPC
	,MainPV_SRV
	,MainDLV_DV
	,MainDLV_PPC
	,MainDLV_PRV
	,MainDLV_NDV
	,MainDLV_SPC
	,MainDLV_SRV
	,MainGV_DV
	,MainGV_PPC
	,MainGV_PRV
	,MainGV_NDV
	,MainGV_SPC
	,MainGV_SRV
	,MainEV
	,MainUV
	,MainMPCV
	,MainTOTAL_POINTS
	,MainQCPV
	,MainQDV
	,MainQDV_DV
	,MainPPV_DLV
	,MainDV_DLVDV		  
FROM
	#FQSID_Transfer23
 
IF @IsDevQA = 0
BEGIN

INSERT
	dbo.wrkDSFinancial
(
	LastModifiedDate
	,RoyaltyMonth
	,PK_Distributor
	,IsAssocType23
	,IsMainID
	,IsInAssocTable
	,TV
	,RO
	,PB
	,PV
	,GV
	,PPV
	,OV
	,PK_MainDistributor
	,MainIsType23
	,MainTV
	,MainRO
	,MainPB
	,MainPV
	,MainGV
	,MainPPV
	,MainOV
    ,DLV
    ,MainDLV
	,MPV 
	,MTV 
	,MainMPV 
	,MainMTV
	,DV
	,PPC
	,PRV
	,NDV
	,SPC
	,SRV
	,PV_DV
	,PV_PPC
	,PV_PRV
	,PV_NDV
	,PV_SPC
	,PV_SRV
	,DLV_DV
	,DLV_PPC
	,DLV_PRV
	,DLV_NDV
	,DLV_SPC
	,DLV_SRV
	,GV_DV
	,GV_PPC
	,GV_PRV
	,GV_NDV
	,GV_SPC
	,GV_SRV
	,EV
	,UV
	,MPCV
	,TOTAL_POINTS
	,QCPV
	,QDV
	,QDV_DV
	,PPV_DLV
	,DV_DLVDV	  
	,MainDV
	,MainPPC
	,MainPRV
	,MainNDV
	,MainSPC
	,MainSRV
	,MainPV_DV
	,MainPV_PPC
	,MainPV_PRV
	,MainPV_NDV
	,MainPV_SPC
	,MainPV_SRV
	,MainDLV_DV
	,MainDLV_PPC
	,MainDLV_PRV
	,MainDLV_NDV
	,MainDLV_SPC
	,MainDLV_SRV
	,MainGV_DV
	,MainGV_PPC
	,MainGV_PRV
	,MainGV_NDV
	,MainGV_SPC
	,MainGV_SRV
	,MainEV
	,MainUV
	,MainMPCV
	,MainTOTAL_POINTS
	,MainQCPV
	,MainQDV
	,MainQDV_DV
	,MainPPV_DLV
	,MainDV_DLVDV		  
	,DistributorID 
	,DeletedDate 
	,Team 
	,Qual_SPDate
	,Qual_QSDate_Actual 	
	,Qual_QSDate 	
	,COP 
	,MainDeletedDate 	
	,MainTeam 
	,MainQual_SPDate 	
	,MainQual_QSDate_Actual 	
	,MainQual_QSDate 	
	,MainCOP 
) 
 /* get everyone not in associate table */
SELECT
	F1.LastModifieddate
	,F1.RoyaltyMonth
	,F1.PK_Distributor 
	,F1.IsAssocType23
	,F1.IsMainID
	,F1.IsInAssocTable
	,F1.TV
	,F1.RO
	,F1.PB
	,F1.PV
	,F1.GV
	,F1.PPV
	,F1.OV
	,F1.PK_MainDistributorID
	,F1.MainIsType23
	,F1.MainTV
	,F1.MainRO
	,F1.MainPB
	,F1.MainPV
	,F1.MainGV
	,F1.MainPPV
	,F1.MainOV
    ,F1.DLV
    ,F1.MainDLV
	,F1.MPV 
	,F1.MTV 
	,F1.MainMPV
	,F1.MainMTV
	,F1.DV
	,F1.PPC
	,F1.PRV
	,F1.NDV
	,F1.SPC
	,F1.SRV
	,F1.PV_DV
	,F1.PV_PPC
	,F1.PV_PRV
	,F1.PV_NDV
	,F1.PV_SPC
	,F1.PV_SRV
	,F1.DLV_DV
	,F1.DLV_PPC
	,F1.DLV_PRV
	,F1.DLV_NDV
	,F1.DLV_SPC
	,F1.DLV_SRV
	,F1.GV_DV
	,F1.GV_PPC
	,F1.GV_PRV
	,F1.GV_NDV
	,F1.GV_SPC
	,F1.GV_SRV
	,F1.EV
	,F1.UV
	,F1.MPCV
	,F1.TOTAL_POINTS
	,F1.QCPV
	,F1.QDV
	,F1.QDV_DV
	,F1.PPV_DLV
	,F1.DV_DLVDV		 
	,F1.MainDV
	,F1.MainPPC
	,F1.MainPRV
	,F1.MainNDV
	,F1.MainSPC
	,F1.MainSRV
	,F1.MainPV_DV
	,F1.MainPV_PPC
	,F1.MainPV_PRV
	,F1.MainPV_NDV
	,F1.MainPV_SPC
	,F1.MainPV_SRV
	,F1.MainDLV_DV
	,F1.MainDLV_PPC
	,F1.MainDLV_PRV
	,F1.MainDLV_NDV
	,F1.MainDLV_SPC
	,F1.MainDLV_SRV
	,F1.MainGV_DV
	,F1.MainGV_PPC
	,F1.MainGV_PRV
	,F1.MainGV_NDV
	,F1.MainGV_SPC
	,F1.MainGV_SRV
	,F1.MainEV
	,F1.MainUV
	,F1.MainMPCV
	,F1.MainTOTAL_POINTS
	,F1.MainQCPV
	,F1.MainQDV
	,F1.MainQDV_DV
	,F1.MainPPV_DLV
	,F1.MainDV_DLVDV			 
	,D.DistributorID
	,CASE WHEN ST.StatusCode = 'COMPLETE' THEN '2049-12-31' ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.DeletedDate),112) END AS DeletedDate
	,DT.TeamCode
	,CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.SPQualDate),112) < '1980-01-01' THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.SPQualDate),112) END AS Qual_SPDate
	,CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) < '1980-01-01' THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) END AS Qual_QSDate_Actual
	,CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) < '1980-01-01' THEN NULL ELSE DATEADD(M,DATEDIFF(M,0,CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112)),0) END AS Qual_QSDate
	,DC.CountryCode AS COP
	,CASE WHEN ST.StatusCode = 'COMPLETE' THEN '2049-12-31' ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.DeletedDate),112) END AS MainDeletedDate
	,DT.TeamCode AS MainTeam
	,CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.SPQualDate),112) < '1980-01-01' THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.SPQualDate),112) END AS MainQual_SPDate
	,CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) < '1980-01-01' THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) END AS MainQual_QSDate_Actual
	,CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) < '1980-01-01' THEN NULL ELSE DATEADD(M,DATEDIFF(M,0,CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112)),0) END AS MainQual_QSDate
	,DC.CountryCode AS MainCOP
FROM  #SourceMetrics AS F1
INNER MERGE JOIN
	#WRK_DimDistributor D (NOLOCK)
ON 	F1.PK_Distributor = D.PK_Distributor
LEFT JOIN
	pubEvents.dbo.dimDSTeam DT (NOLOCK)
ON  D.PK_DSTeam = DT.PK_DSTeam
LEFT JOIN
	pubEvents.dbo.dimCountry DC (NOLOCK)
ON  D.PK_COP = DC.PK_Country
LEFT JOIN
	pubEvents.dbo.dimDSStatus ST (NOLOCK)
ON	D.PK_DSStatus = ST.PK_DSStatus
WHERE F1.RoyaltyMonth >= CAST(@StartMonth AS DATE)  
OPTION (RECOMPILE)
END
 
SET @EndTime = GETUTCDATE()

  PRINT 'Step 85'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '85' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  17 OR (@fp = 1 AND @Step >= 17)
BEGIN

/******************************************************************************
	remove records with 0 across the board
******************************************************************************/

SET @StartTime = GETUTCDATE() --Step 90


IF @IsDevQA = 0
BEGIN

DELETE FROM
	dbo.wrkDSFinancial
WHERE
	IsValidRecord = 0

END

SET @EndTime = GETUTCDATE()

  PRINT 'Step 90'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '90' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  18 OR (@fp = 1 AND @Step >= 18)
BEGIN

/******************************************************************************
	index rebuild
******************************************************************************/
SET @StartTime = GETUTCDATE() --Step 95

IF @IsDevQA = 0 ALTER INDEX IX_aggDSFinacial_PK_Distributor ON dbo.wrkDSFinancial REBUILD
IF @IsDevQA = 0 ALTER INDEX IX_aggDSFinacial_PK_MainDistributor ON dbo.wrkDSFinancial REBUILD

SET @EndTime = GETUTCDATE()

  PRINT 'Step 95'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '95' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  19 OR (@fp = 1 AND @Step >= 19)
BEGIN

/******************************************************************************
	update type 2 or 3 associations that have less than records to set all ids
	to associate status so that the main id will qualify for events
******************************************************************************/
SET @StartTime = GETUTCDATE() --Step 100

IF @IsDevQA = 0
BEGIN

 ;WITH  
	GCAssociation AS
	(
		SELECT
			PK_MainDistributor
		FROM
			pubEvents.dbo.dimDSAssociate A WITH (NOLOCK)
		WHERE
			A.ThroughDate = '2049-12-31' AND A.GCASSOCID IS NULL  
	),
	Type23Main (PK_MainDistributor) AS (
		SELECT
			PK_MainDistributor
		FROM
			pubEvents.dbo.dimDSAssociate A WITH (NOLOCK)
		WHERE
			A.ThroughDate = '2049-12-31' AND NOT EXISTS (SELECT 1 FROM GCAssociation AS g WHERE g.PK_MainDistributor = A.PK_MainDistributor)
		GROUP BY
			PK_MainDistributor
		HAVING 
			COUNT(1) < 3
	),
	Type23Associate (PK_Distributor) AS
	(
		SELECT
			DISTINCT PK_Distributor
		FROM
			pubEvents.dbo.dimDSAssociate A WITH (NOLOCK)
		WHERE
			A.ThroughDate = '2049-12-31' AND NOT EXISTS (SELECT 1 FROM GCAssociation AS g WHERE g.PK_MainDistributor = A.PK_MainDistributor)
			AND EXISTS (SELECT 1 FROM Type23Main C WHERE A.PK_MainDistributor = C.PK_MainDistributor)
	)
	
UPDATE
	F
SET
	IsMainID = 0
FROM
	dbo.wrkDSFinancial F 
INNER JOIN
	Type23Associate A
	ON
		F.PK_Distributor = A.PK_Distributor
END

SET @EndTime = GETUTCDATE()

  PRINT 'Step 100'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '100' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF @Step =  20 OR (@fp = 1 AND @Step >= 20)
BEGIN

/******************************************************************************
	update distributor information
******************************************************************************/
SET @StartTime = GETUTCDATE() --Step 105

IF @IsDevQA = 0
BEGIN

UPDATE
	F
SET
	MainDistributorID = D.DistributorID
	,MainDeletedDate = CASE WHEN ST.StatusCode = 'COMPLETE' THEN '2049-12-31' ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.DeletedDate),112) END
	,MainTeam = DT.TeamCode
	,MainQual_SPDate = CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.SPQualDate),112) < '1980-01-01' THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.SPQualDate),112) END
	,MainQual_QSDate_Actual = CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) < '1980-01-01' THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) END
	,MainQual_QSDate = CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) < '1980-01-01' THEN NULL ELSE DATEADD(M,DATEDIFF(M,0,CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112)),0) END
	,MainCOP = DC.CountryCode
FROM
	dbo.wrkDSFinancial F
INNER JOIN
	#WRK_DimDistributor D (NOLOCK)
ON 	F.PK_MainDistributor = D.PK_Distributor
LEFT JOIN
	pubEvents.dbo.dimDSTeam DT (NOLOCK)
ON  D.PK_DSTeam = DT.PK_DSTeam
LEFT JOIN
	pubEvents.dbo.dimCountry DC (NOLOCK)
ON  D.PK_COP = DC.PK_Country
LEFT JOIN
	pubEvents.dbo.dimDSStatus ST (NOLOCK)
ON	D.PK_DSStatus = ST.PK_DSStatus
WHERE
	F.IsMainID = 0

END

SET @EndTime = GETUTCDATE()

  PRINT 'Step 105'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '105' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
IF @Step =  21 OR (@fp = 1 AND @Step >= 21)
BEGIN

SET @StartTime = GETUTCDATE() --Step 110


IF @IsDevQA = 0
BEGIN

UPDATE
	WRK
SET 
	MainRO = 0
	,MainPB = 0
	,MainTV  = 0
	,MainPV = 0
	,MainGV = 0
	,MainOV = 0
	,RO = 0
	,PB = 0
	,MainMPV = 0
	,MainMTV = 0
	,MainDV = 0
	,MainPPC = 0
	,MainPRV = 0
	,MainNDV = 0
	,MainSPC = 0
	,MainSRV = 0
	,MainPV_DV = 0
	,MainPV_PPC = 0
	,MainPV_PRV = 0
	,MainPV_NDV = 0
	,MainPV_SPC = 0
	,MainPV_SRV = 0
	,MainDLV_DV = 0
	,MainDLV_PPC = 0
	,MainDLV_PRV = 0
	,MainDLV_NDV = 0
	,MainDLV_SPC = 0
	,MainDLV_SRV = 0
	,MainGV_DV = 0
	,MainGV_PPC = 0
	,MainGV_PRV = 0
	,MainGV_NDV = 0
	,MainGV_SPC = 0
	,MainGV_SRV = 0
	,MainEV = 0
	,MainUV = 0
	,MainMPCV = 0
	,MainTOTAL_POINTS = 0
	,MainQCPV = 0
	,MainQDV = 0
	,MainQDV_DV = 0
	,MainPPV_DLV = 0
	,MainDV_DLVDV = 0			  
FROM
	dbo.wrkDSFinancial WRK 
INNER JOIN
	#WRK_DimDistributor DS WITH (NOLOCK)
ON
	WRK.PK_Distributor = DS.PK_Distributor 
	AND
	DS.TypeCode IN ('DS','CS')
	AND
	WRK.IsMainID = 0 
	AND
	WRK.MainIsType23 = 1

	 ALTER INDEX IX_aggDSFinacial_RoyaltyMonth ON dbo.wrkDSFinancial REBUILD

END

 
--------------------------------------------------------------------------------------------------------------------------

SET @EndTime = GETUTCDATE()

  PRINT 'Step 110'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '110' ,@StartTime = @StartTime

SET @StartTime = GETUTCDATE()

--/ Greater China association: Updating GCAssoc fields on wrkDSFinancial
---------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS #Main_GCAAssoc_Volume

SELECT 
	gc.PK_MainDistributor AS [PK_Distributor]
	,gc.PK_AssociatedID
	,f.RoyaltyMonth 
	,f.TV        
	,f.RO
	,f.PB          
	,f.PV          
	,f.GV          
	,f.PPV         
	,f.OV          
	,f.DLV         
	,f.MPV         
	,f.MTV         
	,f.DV          
	,f.PPC         
	,f.PRV         
	,f.NDV         
	,f.SPC         
	,f.SRV         
	,f.PV_DV       
	,f.PV_PPC      
	,f.PV_PRV      
	,f.PV_NDV      
	,f.PV_SPC      
	,f.PV_SRV      
	,f.DLV_DV      
	,f.DLV_PPC     
	,f.DLV_PRV     
	,f.DLV_NDV     
	,f.DLV_SPC     
	,f.DLV_SRV     
	,f.GV_DV       
	,f.GV_PPC      
	,f.GV_PRV      
	,f.GV_NDV      
	,f.GV_SPC      
	,f.GV_SRV      
	,f.EV          
	,f.UV          
	,f.MPCV        
	,f.TOTAL_POINTS
	,f.QCPV        
	,f.QDV         
	,f.QDV_DV      
	,f.PPV_DLV     
	,f.DV_DLVDV    
	,f.MainTV          
	,f.MainRO          
	,f.MainPB          
	,f.MainPV          
	,f.MainGV          
	,f.MainPPV         
	,f.MainOV          
	,f.MainDLV         
	,f.MainMPV         
	,f.MainMTV         
	,f.MainDV          
	,f.MainPPC         
	,f.MainPRV         
	,f.MainNDV         
	,f.MainSPC         
	,f.MainSRV         
	,f.MainPV_DV       
	,f.MainPV_PPC      
	,f.MainPV_PRV      
	,f.MainPV_NDV      
	,f.MainPV_SPC      
	,f.MainPV_SRV      
	,f.MainDLV_DV      
	,f.MainDLV_PPC     
	,f.MainDLV_PRV     
	,f.MainDLV_NDV     
	,f.MainDLV_SPC     
	,f.MainDLV_SRV     
	,f.MainGV_DV       
	,f.MainGV_PPC      
	,f.MainGV_PRV      
	,f.MainGV_NDV      
	,f.MainGV_SPC      
	,f.MainGV_SRV      
	,f.MainEV          
	,f.MainUV          
	,f.MainMPCV        
	,f.MainTOTAL_POINTS
	,f.MainQCPV        
	,f.MainQDV         
	,f.MainQDV_DV      
	,f.MainPPV_DLV     
	,f.MainDV_DLVDV    
INTO #Main_GCAAssoc_Volume
FROM #GCASSOCID AS gc 
INNER JOIN dbo.wrkDSFinancial AS f WITH (NOLOCK)
	ON gc.PK_MainDistributor = f.PK_Distributor 

DROP TABLE IF EXISTS #Associated_GCAAssoc_Volume

SELECT 
	gc.PK_AssociatedID AS PK_Distributor, 
	gc.PK_MainDistributor AS PK_AssociatedID,
	f.RoyaltyMonth 
	,f.TV        
	,f.RO
	,f.PB          
	,f.PV          
	,f.GV          
	,f.PPV         
	,f.OV          
	,f.DLV         
	,f.MPV         
	,f.MTV         
	,f.DV          
	,f.PPC         
	,f.PRV         
	,f.NDV         
	,f.SPC         
	,f.SRV         
	,f.PV_DV       
	,f.PV_PPC      
	,f.PV_PRV      
	,f.PV_NDV      
	,f.PV_SPC      
	,f.PV_SRV      
	,f.DLV_DV      
	,f.DLV_PPC     
	,f.DLV_PRV     
	,f.DLV_NDV     
	,f.DLV_SPC     
	,f.DLV_SRV     
	,f.GV_DV       
	,f.GV_PPC      
	,f.GV_PRV      
	,f.GV_NDV      
	,f.GV_SPC      
	,f.GV_SRV      
	,f.EV          
	,f.UV          
	,f.MPCV        
	,f.TOTAL_POINTS
	,f.QCPV        
	,f.QDV         
	,f.QDV_DV      
	,f.PPV_DLV     
	,f.DV_DLVDV    
	,f.MainTV          
	,f.MainRO          
	,f.MainPB          
	,f.MainPV          
	,f.MainGV          
	,f.MainPPV         
	,f.MainOV          
	,f.MainDLV         
	,f.MainMPV         
	,f.MainMTV         
	,f.MainDV          
	,f.MainPPC         
	,f.MainPRV         
	,f.MainNDV         
	,f.MainSPC         
	,f.MainSRV         
	,f.MainPV_DV       
	,f.MainPV_PPC      
	,f.MainPV_PRV      
	,f.MainPV_NDV      
	,f.MainPV_SPC      
	,f.MainPV_SRV      
	,f.MainDLV_DV      
	,f.MainDLV_PPC     
	,f.MainDLV_PRV     
	,f.MainDLV_NDV     
	,f.MainDLV_SPC     
	,f.MainDLV_SRV     
	,f.MainGV_DV       
	,f.MainGV_PPC      
	,f.MainGV_PRV      
	,f.MainGV_NDV      
	,f.MainGV_SPC      
	,f.MainGV_SRV      
	,f.MainEV          
	,f.MainUV          
	,f.MainMPCV        
	,f.MainTOTAL_POINTS
	,f.MainQCPV        
	,f.MainQDV         
	,f.MainQDV_DV      
	,f.MainPPV_DLV     
	,f.MainDV_DLVDV   
INTO #Associated_GCAAssoc_Volume
FROM #GCASSOCID AS gc
INNER JOIN dbo.wrkDSFinancial AS f WITH (NOLOCK)
	ON gc.PK_AssociatedID = f.PK_Distributor  
	
DROP TABLE IF EXISTS #GCAAssoc_Volume_Main

SELECT 
	gc.PK_MainDistributor AS [PK_Distributor], 
	gc.PK_AssociatedID,
	M.MONTHDATE AS RoyaltyMonth,
	gc.DivorceType,
	gc.Original_As_Main,
	--TV
		ISNULL(fm.TV,0) AS [TV], 
		ISNULL(fm.MainTV,0) AS [MainTV],
		ISNULL(fa.TV,0) AS [GCAssoc_TV],
		ISNULL(fa.MainTV,0) AS [GCAssoc_MainTV],
		ISNULL(fa.MainTV,0) + ISNULL(fa.TV,0) AS [GCAssoc_TotalTV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainTV,0) + ISNULL(fa.TV,0) + ISNULL(fm.MainTV,0) + ISNULL(fm.TV,0) AS [Total_TV],
	--RO          
		ISNULL(fm.RO,0) AS [RO], 
		ISNULL(fm.MainRO,0) AS [MainRO],
		ISNULL(fa.RO,0) AS [GCAssoc_RO],
		ISNULL(fa.MainRO,0) AS [GCAssoc_MainRO],
		ISNULL(fa.MainRO,0) + ISNULL(fa.RO,0) AS [GCAssoc_TotalRO], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainRO,0) + ISNULL(fa.RO,0) + ISNULL(fm.MainRO,0) + ISNULL(fm.RO,0) AS [Total_RO],
	--PB   
		ISNULL(fm.PB,0) AS [PB], 
		ISNULL(fm.MainPB,0) AS [MainPB],
		ISNULL(fa.PB,0) AS [GCAssoc_PB],
		ISNULL(fa.MainPB,0) AS [GCAssoc_MainPB],
		ISNULL(fa.MainPB,0) + ISNULL(fa.PB,0) AS [GCAssoc_TotalPB], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainPB,0) + ISNULL(fa.PB,0) + ISNULL(fm.MainPB,0) + ISNULL(fm.PB,0) AS [Total_PB],
	--PV     
		ISNULL(fm.PV,0) AS [PV], 
		ISNULL(fm.MainPV,0) AS [MainPV],
		ISNULL(fa.PV,0) AS [GCAssoc_PV],
		ISNULL(fa.MainPV,0) AS [GCAssoc_MainPV],
		ISNULL(fa.MainPV,0) + ISNULL(fa.PV,0) AS [GCAssoc_TotalPV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainPV,0) + ISNULL(fa.PV,0) + ISNULL(fm.MainPV,0) + ISNULL(fm.PV,0) AS [Total_PV],
	--GV          
		ISNULL(fm.GV,0) AS [GV], 
		ISNULL(fm.MainGV,0) AS [MainGV],
		ISNULL(fa.GV,0) AS [GCAssoc_GV],
		ISNULL(fa.MainGV,0) AS [GCAssoc_MainGV],
		ISNULL(fa.MainGV,0) + ISNULL(fa.GV,0) AS [GCAssoc_TotalGV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainGV,0) + ISNULL(fa.GV,0) + ISNULL(fm.MainGV,0) + ISNULL(fm.GV,0) AS [Total_GV],
	--PPV         
		ISNULL(fm.PPV,0) AS [PPV], 
		ISNULL(fm.MainPPV,0) AS [MainPPV],
		ISNULL(fa.PPV,0) AS [GCAssoc_PPV],
		ISNULL(fa.MainPPV,0) AS [GCAssoc_MainPPV],
		ISNULL(fa.MainPPV,0) + ISNULL(fa.PPV,0) AS [GCAssoc_TotalPPV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainPPV,0) + ISNULL(fa.PPV,0) + ISNULL(fm.MainPPV,0) + ISNULL(fm.PPV,0) AS [Total_PPV],
	--OV          
		ISNULL(fm.OV,0) AS [OV], 
		ISNULL(fm.MainOV,0) AS [MainOV],
		ISNULL(fa.OV,0) AS [GCAssoc_OV],
		ISNULL(fa.MainOV,0) AS [GCAssoc_MainOV],
		ISNULL(fa.MainOV,0) + ISNULL(fa.OV,0) AS [GCAssoc_TotalOV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainOV,0) + ISNULL(fa.OV,0) + ISNULL(fm.MainOV,0) + ISNULL(fm.OV,0) AS [Total_OV],
	--DLV         
		ISNULL(fm.DLV,0) AS [DLV], 
		ISNULL(fm.MainDLV,0) AS [MainDLV],
		ISNULL(fa.DLV,0) AS [GCAssoc_DLV],
		ISNULL(fa.MainDLV,0) AS [GCAssoc_MainDLV],
		ISNULL(fa.MainDLV,0) + ISNULL(fa.DLV,0) AS [GCAssoc_TotalDLV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainDLV,0) + ISNULL(fa.DLV,0) + ISNULL(fm.MainDLV,0) + ISNULL(fm.DLV,0) AS [Total_DLV],
	--MPV         
		ISNULL(fm.MPV,0) AS [MPV], 
		ISNULL(fm.MainMPV,0) AS [MainMPV],
		ISNULL(fa.MPV,0) AS [GCAssoc_MPV],
		ISNULL(fa.MainMPV,0) AS [GCAssoc_MainMPV],
		ISNULL(fa.MainMPV,0) + ISNULL(fa.MPV,0) AS [GCAssoc_TotalMPV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainMPV,0) + ISNULL(fa.MPV,0) + ISNULL(fm.MainMPV,0) + ISNULL(fm.MPV,0) AS [Total_MPV],
	--MTV      
		ISNULL(fm.MTV,0) AS [MTV], 
		ISNULL(fm.MainMTV,0) AS [MainMTV],
		ISNULL(fa.MTV,0) AS [GCAssoc_MTV],
		ISNULL(fa.MainMTV,0) AS [GCAssoc_MainMTV],
		ISNULL(fa.MainMTV,0) + ISNULL(fa.MTV,0) AS [GCAssoc_TotalMTV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainMTV,0) + ISNULL(fa.MTV,0) + ISNULL(fm.MainMTV,0) + ISNULL(fm.MTV,0) AS [Total_MTV],
	--DV     
		ISNULL(fm.DV,0) AS [DV], 
		ISNULL(fm.MainDV,0) AS [MainDV],
		ISNULL(fa.DV,0) AS [GCAssoc_DV],
		ISNULL(fa.MainDV,0) AS [GCAssoc_MainDV],
		ISNULL(fa.MainDV,0) + ISNULL(fa.DV,0) AS [GCAssoc_TotalDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainDV,0) + ISNULL(fa.DV,0) + ISNULL(fm.MainDV,0) + ISNULL(fm.DV,0) AS [Total_DV],
	--PPC   
		ISNULL(fm.PPC,0) AS [PPC], 
		ISNULL(fm.MainPPC,0) AS [MainPPC],
		ISNULL(fa.PPC,0) AS [GCAssoc_PPC],
		ISNULL(fa.MainPPC,0) AS [GCAssoc_MainPPC],
		ISNULL(fa.MainPPC,0) + ISNULL(fa.PPC,0) AS [GCAssoc_TotalPPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainPPC,0) + ISNULL(fa.PPC,0) + ISNULL(fm.MainPPC,0) + ISNULL(fm.PPC,0) AS [Total_PPC],
	--PRV        
		ISNULL(fm.PRV,0) AS [PRV], 
		ISNULL(fm.MainPRV,0) AS [MainPRV],
		ISNULL(fa.PRV,0) AS [GCAssoc_PRV],
		ISNULL(fa.MainPRV,0) AS [GCAssoc_MainPRV],
		ISNULL(fa.MainPRV,0) + ISNULL(fa.PRV,0) AS [GCAssoc_TotalPRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainPRV,0) + ISNULL(fa.PRV,0) + ISNULL(fm.MainPRV,0) + ISNULL(fm.PRV,0) AS [Total_PRV],
	--NDV     
		ISNULL(fm.NDV,0) AS [NDV], 
		ISNULL(fm.MainNDV,0) AS [MainNDV],
		ISNULL(fa.NDV,0) AS [GCAssoc_NDV],
		ISNULL(fa.MainNDV,0) AS [GCAssoc_MainNDV],
		ISNULL(fa.MainNDV,0) + ISNULL(fa.NDV,0) AS [GCAssoc_TotalNDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainNDV,0) + ISNULL(fa.NDV,0) + ISNULL(fm.MainNDV,0) + ISNULL(fm.NDV,0) AS [Total_NDV],
	--SPC    
		ISNULL(fm.SPC,0) AS [SPC], 
		ISNULL(fm.MainSPC,0) AS [MainSPC],
		ISNULL(fa.SPC,0) AS [GCAssoc_SPC],
		ISNULL(fa.MainSPC,0) AS [GCAssoc_MainSPC],
		ISNULL(fa.MainSPC,0) + ISNULL(fa.SPC,0) AS [GCAssoc_TotalSPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainSPC,0) + ISNULL(fa.SPC,0) + ISNULL(fm.MainSPC,0) + ISNULL(fm.SPC,0) AS [Total_SPC],
	--SRV         
		ISNULL(fm.SRV,0) AS [SRV], 
		ISNULL(fm.MainSRV,0) AS [MainSRV],
		ISNULL(fa.SRV,0) AS [GCAssoc_SRV],
		ISNULL(fa.MainSRV,0) AS [GCAssoc_MainSRV],
		ISNULL(fa.MainSRV,0) + ISNULL(fa.SRV,0) AS [GCAssoc_TotalSRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainSRV,0) + ISNULL(fa.SRV,0) + ISNULL(fm.MainSRV,0) + ISNULL(fm.SRV,0) AS [Total_SRV],
	--PV_DV   
		ISNULL(fm.PV_DV,0) AS [PV_DV], 
		ISNULL(fm.MainPV_DV,0) AS [MainPV_DV],
		ISNULL(fa.PV_DV,0) AS [GCAssoc_PV_DV],
		ISNULL(fa.MainPV_DV,0) AS [GCAssoc_MainPV_DV],
		ISNULL(fa.MainPV_DV,0) + ISNULL(fa.PV_DV,0) AS [GCAssoc_TotalPV_DV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainPV_DV,0) + ISNULL(fa.PV_DV,0) + ISNULL(fm.MainPV_DV,0) + ISNULL(fm.PV_DV,0) AS [Total_PV_DV],
	--PV_PPC   
		ISNULL(fm.PV_PPC,0) AS [PV_PPC], 
		ISNULL(fm.MainPV_PPC,0) AS [MainPV_PPC],
		ISNULL(fa.PV_PPC,0) AS [GCAssoc_PV_PPC],
		ISNULL(fa.MainPV_PPC,0) AS [GCAssoc_MainPV_PPC],
		ISNULL(fa.MainPV_PPC,0) + ISNULL(fa.PV_PPC,0) AS [GCAssoc_TotalPV_PPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainPV_PPC,0) + ISNULL(fa.PV_PPC,0) + ISNULL(fm.MainPV_PPC,0) + ISNULL(fm.PV_PPC,0) AS [Total_PV_PPC],
	--PV_PRV   
		ISNULL(fm.PV_PRV,0) AS [PV_PRV], 
		ISNULL(fm.MainPV_PRV,0) AS [MainPV_PRV],
		ISNULL(fa.PV_PRV,0) AS [GCAssoc_PV_PRV],
		ISNULL(fa.MainPV_PRV,0) AS [GCAssoc_MainPV_PRV],
		ISNULL(fa.MainPV_PRV,0) + ISNULL(fa.PV_PRV,0) AS [GCAssoc_TotalPV_PRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainPV_PRV,0) + ISNULL(fa.PV_PRV,0) + ISNULL(fm.MainPV_PRV,0) + ISNULL(fm.PV_PRV,0) AS [Total_PV_PRV],
	--PV_NDV     
		ISNULL(fm.PV_NDV,0) AS [PV_NDV], 
		ISNULL(fm.MainPV_NDV,0) AS [MainPV_NDV],
		ISNULL(fa.PV_NDV,0) AS [GCAssoc_PV_NDV],
		ISNULL(fa.MainPV_NDV,0) AS [GCAssoc_MainPV_NDV],
		ISNULL(fa.MainPV_NDV,0) + ISNULL(fa.PV_NDV,0) AS [GCAssoc_TotalPV_NDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainPV_NDV,0) + ISNULL(fa.PV_NDV,0) + ISNULL(fm.MainPV_NDV,0) + ISNULL(fm.PV_NDV,0) AS [Total_PV_NDV],
	--PV_SPC    
		ISNULL(fm.PV_SPC,0) AS [PV_SPC], 
		ISNULL(fm.MainPV_SPC,0) AS [MainPV_SPC],
		ISNULL(fa.PV_SPC,0) AS [GCAssoc_PV_SPC],
		ISNULL(fa.MainPV_SPC,0) AS [GCAssoc_MainPV_SPC],
		ISNULL(fa.MainPV_SPC,0) + ISNULL(fa.PV_SPC,0) AS [GCAssoc_TotalPV_SPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainPV_SPC,0) + ISNULL(fa.PV_SPC,0) + ISNULL(fm.MainPV_SPC,0) + ISNULL(fm.PV_SPC,0) AS [Total_PV_SPC],
	--PV_SRV   
		ISNULL(fm.PV_SRV,0) AS [PV_SRV], 
		ISNULL(fm.MainPV_SRV,0) AS [MainPV_SRV],
		ISNULL(fa.PV_SRV,0) AS [GCAssoc_PV_SRV],
		ISNULL(fa.MainPV_SRV,0) AS [GCAssoc_MainPV_SRV],
		ISNULL(fa.MainPV_SRV,0) + ISNULL(fa.PV_SRV,0) AS [GCAssoc_TotalPV_SRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainPV_SRV,0) + ISNULL(fa.PV_SRV,0) + ISNULL(fm.MainPV_SRV,0) + ISNULL(fm.PV_SRV,0) AS [Total_PV_SRV],
	--DLV_DV      
		ISNULL(fm.DLV_DV,0) AS [DLV_DV], 
		ISNULL(fm.MainDLV_DV,0) AS [MainDLV_DV],
		ISNULL(fa.DLV_DV,0) AS [GCAssoc_DLV_DV],
		ISNULL(fa.MainDLV_DV,0) AS [GCAssoc_MainDLV_DV],
		ISNULL(fa.MainDLV_DV,0) + ISNULL(fa.DLV_DV,0) AS [GCAssoc_TotalDLV_DV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainDLV_DV,0) + ISNULL(fa.DLV_DV,0) + ISNULL(fm.MainDLV_DV,0) + ISNULL(fm.DLV_DV,0) AS [Total_DLV_DV],
	--DLV_PPC     
		ISNULL(fm.DLV_PPC,0) AS [DLV_PPC], 
		ISNULL(fm.MainDLV_PPC,0) AS [MainDLV_PPC],
		ISNULL(fa.DLV_PPC,0) AS [GCAssoc_DLV_PPC],
		ISNULL(fa.MainDLV_PPC,0) AS [GCAssoc_MainDLV_PPC],
		ISNULL(fa.MainDLV_PPC,0) + ISNULL(fa.DLV_PPC,0) AS [GCAssoc_TotalDLV_PPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainDLV_PPC,0) + ISNULL(fa.DLV_PPC,0) + ISNULL(fm.MainDLV_PPC,0) + ISNULL(fm.DLV_PPC,0) AS [Total_DLV_PPC],
	--DLV_PRV  
		ISNULL(fm.DLV_PRV,0) AS [DLV_PRV], 
		ISNULL(fm.MainDLV_PRV,0) AS [MainDLV_PRV],
		ISNULL(fa.DLV_PRV,0) AS [GCAssoc_DLV_PRV],
		ISNULL(fa.MainDLV_PRV,0) AS [GCAssoc_MainDLV_PRV],
		ISNULL(fa.MainDLV_PRV,0) + ISNULL(fa.DLV_PRV,0) AS [GCAssoc_TotalDLV_PRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainDLV_PRV,0) + ISNULL(fa.DLV_PRV,0) + ISNULL(fm.MainDLV_PRV,0) + ISNULL(fm.DLV_PRV,0) AS [Total_DLV_PRV],
	--DLV_NDV     
		ISNULL(fm.DLV_NDV,0) AS [DLV_NDV], 
		ISNULL(fm.MainDLV_NDV,0) AS [MainDLV_NDV],
		ISNULL(fa.DLV_NDV,0) AS [GCAssoc_DLV_NDV],
		ISNULL(fa.MainDLV_NDV,0) AS [GCAssoc_MainDLV_NDV],
		ISNULL(fa.MainDLV_NDV,0) + ISNULL(fa.DLV_NDV,0) AS [GCAssoc_TotalDLV_NDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainDLV_NDV,0) + ISNULL(fa.DLV_NDV,0) + ISNULL(fm.MainDLV_NDV,0) + ISNULL(fm.DLV_NDV,0) AS [Total_DLV_NDV],
	--DLV_SPC    
		ISNULL(fm.DLV_SPC,0) AS [DLV_SPC], 
		ISNULL(fm.MainDLV_SPC,0) AS [MainDLV_SPC],
		ISNULL(fa.DLV_SPC,0) AS [GCAssoc_DLV_SPC],
		ISNULL(fa.MainDLV_SPC,0) AS [GCAssoc_MainDLV_SPC],
		ISNULL(fa.MainDLV_SPC,0) + ISNULL(fa.DLV_SPC,0) AS [GCAssoc_TotalDLV_SPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainDLV_SPC,0) + ISNULL(fa.DLV_SPC,0) + ISNULL(fm.MainDLV_SPC,0) + ISNULL(fm.DLV_SPC,0) AS [Total_DLV_SPC],
	--DLV_SRV     
		ISNULL(fm.DLV_SRV,0) AS [DLV_SRV], 
		ISNULL(fm.MainDLV_SRV,0) AS [MainDLV_SRV],
		ISNULL(fa.DLV_SRV,0) AS [GCAssoc_DLV_SRV],
		ISNULL(fa.MainDLV_SRV,0) AS [GCAssoc_MainDLV_SRV],
		ISNULL(fa.MainDLV_SRV,0) + ISNULL(fa.DLV_SRV,0) AS [GCAssoc_TotalDLV_SRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainDLV_SRV,0) + ISNULL(fa.DLV_SRV,0) + ISNULL(fm.MainDLV_SRV,0) + ISNULL(fm.DLV_SRV,0) AS [Total_DLV_SRV],
	--GV_DV       
		ISNULL(fm.GV_DV,0) AS [GV_DV], 
		ISNULL(fm.MainGV_DV,0) AS [MainGV_DV],
		ISNULL(fa.GV_DV,0) AS [GCAssoc_GV_DV],
		ISNULL(fa.MainGV_DV,0) AS [GCAssoc_MainGV_DV],
		ISNULL(fa.MainGV_DV,0) + ISNULL(fa.GV_DV,0) AS [GCAssoc_TotalGV_DV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainGV_DV,0) + ISNULL(fa.GV_DV,0) + ISNULL(fm.MainGV_DV,0) + ISNULL(fm.GV_DV,0) AS [Total_GV_DV],
	--GV_PPC      
		ISNULL(fm.GV_PPC,0) AS [GV_PPC], 
		ISNULL(fm.MainGV_PPC,0) AS [MainGV_PPC],
		ISNULL(fa.GV_PPC,0) AS [GCAssoc_GV_PPC],
		ISNULL(fa.MainGV_PPC,0) AS [GCAssoc_MainGV_PPC],
		ISNULL(fa.MainGV_PPC,0) + ISNULL(fa.GV_PPC,0) AS [GCAssoc_TotalGV_PPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainGV_PPC,0) + ISNULL(fa.GV_PPC,0) + ISNULL(fm.MainGV_PPC,0) + ISNULL(fm.GV_PPC,0) AS [Total_GV_PPC],
	--GV_PRV      
		ISNULL(fm.GV_PRV,0) AS [GV_PRV], 
		ISNULL(fm.MainGV_PRV,0) AS [MainGV_PRV],
		ISNULL(fa.GV_PRV,0) AS [GCAssoc_GV_PRV],
		ISNULL(fa.MainGV_PRV,0) AS [GCAssoc_MainGV_PRV],
		ISNULL(fa.MainGV_PRV,0) + ISNULL(fa.GV_PRV,0) AS [GCAssoc_TotalGV_PRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainGV_PRV,0) + ISNULL(fa.GV_PRV,0) + ISNULL(fm.MainGV_PRV,0) + ISNULL(fm.GV_PRV,0) AS [Total_GV_PRV],
	--GV_NDV      
		ISNULL(fm.GV_NDV,0) AS [GV_NDV], 
		ISNULL(fm.MainGV_NDV,0) AS [MainGV_NDV],
		ISNULL(fa.GV_NDV,0) AS [GCAssoc_GV_NDV],
		ISNULL(fa.MainGV_NDV,0) AS [GCAssoc_MainGV_NDV],
		ISNULL(fa.MainGV_NDV,0) + ISNULL(fa.GV_NDV,0) AS [GCAssoc_TotalGV_NDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainGV_NDV,0) + ISNULL(fa.GV_NDV,0) + ISNULL(fm.MainGV_NDV,0) + ISNULL(fm.GV_NDV,0) AS [Total_GV_NDV],
	--GV_SPC   
		ISNULL(fm.GV_SPC,0) AS [GV_SPC], 
		ISNULL(fm.MainGV_SPC,0) AS [MainGV_SPC],
		ISNULL(fa.GV_SPC,0) AS [GCAssoc_GV_SPC],
		ISNULL(fa.MainGV_SPC,0) AS [GCAssoc_MainGV_SPC],
		ISNULL(fa.MainGV_SPC,0) + ISNULL(fa.GV_SPC,0) AS [GCAssoc_TotalGV_SPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainGV_SPC,0) + ISNULL(fa.GV_SPC,0) + ISNULL(fm.MainGV_SPC,0) + ISNULL(fm.GV_SPC,0) AS [Total_GV_SPC],
	--GV_SRV  
		ISNULL(fm.GV_SRV,0) AS [GV_SRV], 
		ISNULL(fm.MainGV_SRV,0) AS [MainGV_SRV],
		ISNULL(fa.GV_SRV,0) AS [GCAssoc_GV_SRV],
		ISNULL(fa.MainGV_SRV,0) AS [GCAssoc_MainGV_SRV],
		ISNULL(fa.MainGV_SRV,0) + ISNULL(fa.GV_SRV,0) AS [GCAssoc_TotalGV_SRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainGV_SRV,0) + ISNULL(fa.GV_SRV,0) + ISNULL(fm.MainGV_SRV,0) + ISNULL(fm.GV_SRV,0) AS [Total_GV_SRV],
	--EV        
		ISNULL(fm.EV,0) AS [EV], 
		ISNULL(fm.MainEV,0) AS [MainEV],
		ISNULL(fa.EV,0) AS [GCAssoc_EV],
		ISNULL(fa.MainEV,0) AS [GCAssoc_MainEV],
		ISNULL(fa.MainEV,0) + ISNULL(fa.EV,0) AS [GCAssoc_TotalEV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainEV,0) + ISNULL(fa.EV,0) + ISNULL(fm.MainEV,0) + ISNULL(fm.EV,0) AS [Total_EV],
	--UV          
		ISNULL(fm.UV,0) AS [UV], 
		ISNULL(fm.MainUV,0) AS [MainUV],
		ISNULL(fa.UV,0) AS [GCAssoc_UV],
		ISNULL(fa.MainUV,0) AS [GCAssoc_MainUV],
		ISNULL(fa.MainUV,0) + ISNULL(fa.UV,0) AS [GCAssoc_TotalUV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainUV,0) + ISNULL(fa.UV,0) + ISNULL(fm.MainUV,0) + ISNULL(fm.UV,0) AS [Total_UV],
	--MPCV      
		ISNULL(fm.MPCV,0) AS [MPCV], 
		ISNULL(fm.MainMPCV,0) AS [MainMPCV],
		ISNULL(fa.MPCV,0) AS [GCAssoc_MPCV],
		ISNULL(fa.MainMPCV,0) AS [GCAssoc_MainMPCV],
		ISNULL(fa.MainMPCV,0) + ISNULL(fa.MPCV,0) AS [GCAssoc_TotalMPCV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainMPCV,0) + ISNULL(fa.MPCV,0) + ISNULL(fm.MainMPCV,0) + ISNULL(fm.MPCV,0) AS [Total_MPCV],
	--TOTAL_POINTS
		ISNULL(fm.TOTAL_POINTS,0) AS [TOTAL_POINTS], 
		ISNULL(fm.MainTOTAL_POINTS,0) AS [MainTOTAL_POINTS],
		ISNULL(fa.TOTAL_POINTS,0) AS [GCAssoc_TOTAL_POINTS],
		ISNULL(fa.MainTOTAL_POINTS,0) AS [GCAssoc_MainTOTAL_POINTS],
		ISNULL(fa.MainTOTAL_POINTS,0) + ISNULL(fa.TOTAL_POINTS,0) AS [GCAssoc_TotalTOTAL_POINTS], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainTOTAL_POINTS,0) + ISNULL(fa.TOTAL_POINTS,0) + ISNULL(fm.MainTOTAL_POINTS,0) + ISNULL(fm.TOTAL_POINTS,0) AS [Total_TOTAL_POINTS],
	--QCPV        
		ISNULL(fm.QCPV,0) AS [QCPV], 
		ISNULL(fm.MainQCPV,0) AS [MainQCPV],
		ISNULL(fa.QCPV,0) AS [GCAssoc_QCPV],
		ISNULL(fa.MainQCPV,0) AS [GCAssoc_MainQCPV],
		ISNULL(fa.MainQCPV,0) + ISNULL(fa.QCPV,0) AS [GCAssoc_TotalQCPV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainQCPV,0) + ISNULL(fa.QCPV,0) + ISNULL(fm.MainQCPV,0) + ISNULL(fm.QCPV,0) AS [Total_QCPV],
	--QDV         
		ISNULL(fm.QDV,0) AS [QDV], 
		ISNULL(fm.MainQDV,0) AS [MainQDV],
		ISNULL(fa.QDV,0) AS [GCAssoc_QDV],
		ISNULL(fa.MainQDV,0) AS [GCAssoc_MainQDV],
		ISNULL(fa.MainQDV,0) + ISNULL(fa.QDV,0) AS [GCAssoc_TotalQDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainQDV,0) + ISNULL(fa.QDV,0) + ISNULL(fm.MainQDV,0) + ISNULL(fm.QDV,0) AS [Total_QDV],
	--QDV_DV    
		ISNULL(fm.QDV_DV,0) AS [QDV_DV], 
		ISNULL(fm.MainQDV_DV,0) AS [MainQDV_DV],
		ISNULL(fa.QDV_DV,0) AS [GCAssoc_QDV_DV],
		ISNULL(fa.MainQDV_DV,0) AS [GCAssoc_MainQDV_DV],
		ISNULL(fa.MainQDV_DV,0) + ISNULL(fa.QDV_DV,0) AS [GCAssoc_TotalQDV_DV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainQDV_DV,0) + ISNULL(fa.QDV_DV,0) + ISNULL(fm.MainQDV_DV,0) + ISNULL(fm.QDV_DV,0) AS [Total_QDV_DV],
	--PPV_DLV     
		ISNULL(fm.PPV_DLV,0) AS [PPV_DLV], 
		ISNULL(fm.MainPPV_DLV,0) AS [MainPPV_DLV],
		ISNULL(fa.PPV_DLV,0) AS [GCAssoc_PPV_DLV],
		ISNULL(fa.MainPPV_DLV,0) AS [GCAssoc_MainPPV_DLV],
		ISNULL(fa.MainPPV_DLV,0) + ISNULL(fa.PPV_DLV ,0) AS [GCAssoc_TotalPPV_DLV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainPPV_DLV,0) + ISNULL(fa.PPV_DLV,0) + ISNULL(fm.MainPPV_DLV,0) + ISNULL(fm.PPV_DLV ,0) AS [Total_PPV_DLV],
	--DV_DLVDV    
		ISNULL(fm.DV_DLVDV,0) AS [DV_DLVDV], 
		ISNULL(fm.MainDV_DLVDV,0) AS [MainDV_DLVDV],
		ISNULL(fa.DV_DLVDV,0) AS [GCAssoc_DV_DLVDV],
		ISNULL(fa.MainDV_DLVDV,0) AS [GCAssoc_MainDV_DLVDV],
		ISNULL(fa.MainDV_DLVDV,0) + ISNULL(fa.DV_DLVDV ,0) AS [GCAssoc_TotalDV_DLVDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fa.MainDV_DLVDV,0) + ISNULL(fa.DV_DLVDV,0) + ISNULL(fm.MainDV_DLVDV,0) + ISNULL(fm.DV_DLVDV ,0) AS [Total_DV_DLVDV]
INTO #GCAAssoc_Volume_Main
FROM #GCAssocID AS gc
CROSS APPLY (SELECT MonthDate FROM pubEvents.dbo.dimMonth M WITH (NOLOCK) WHERE M.MonthDate BETWEEN @MinRoyaltyMonth AND @MaxRoyaltyMonth) AS M
LEFT JOIN #Main_GCAAssoc_Volume AS fm
	ON gc.PK_MainDistributor = fm.PK_Distributor AND M.MONTHDATE = fm.RoyaltyMonth
LEFT JOIN #Associated_GCAAssoc_Volume AS fa
	ON gc.PK_AssociatedID = fa.PK_Distributor AND M.MONTHDATE = fa.RoyaltyMonth
 
DROP TABLE IF EXISTS #GCAAssoc_Volume_Associated

--Associated  
SELECT 
	gc.PK_AssociatedID  AS [PK_Distributor], 
	gc.PK_MainDistributor,
	M.MONTHDATE AS RoyaltyMonth,
	gc.DivorceType,
	gc.Original_As_Main,
	--TV
		ISNULL(fa.TV,0) AS [TV], 
		ISNULL(fa.MainTV,0) AS [MainTV],
		ISNULL(fm.TV,0) AS [GCAssoc_TV],
		ISNULL(fm.MainTV,0) AS [GCAssoc_MainTV],
		ISNULL(fm.MainTV,0) + ISNULL(fm.TV,0) AS [GCAssoc_TotalTV], -- To update on dbo.wrkDSFinancial 
		ISNULL(fm.MainTV,0) + ISNULL(fm.TV,0) + ISNULL(fa.MainTV,0) + ISNULL(fa.TV,0) AS [Total_TV],
	--RO          
		ISNULL(fa.RO,0) AS [RO], 
		ISNULL(fa.MainRO,0) AS [MainRO],
		ISNULL(fm.RO,0) AS [GCAssoc_RO],
		ISNULL(fm.MainRO,0) AS [GCAssoc_MainRO],
		ISNULL(fm.MainRO,0) + ISNULL(fm.RO,0) AS [GCAssoc_TotalRO], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainRO,0) + ISNULL(fm.RO,0) + ISNULL(fa.MainRO,0) + ISNULL(fa.RO,0) AS [Total_RO],
	--PB   
		ISNULL(fa.PB,0) AS [PB], 
		ISNULL(fa.MainPB,0) AS [MainPB],
		ISNULL(fm.PB,0) AS [GCAssoc_PB],
		ISNULL(fm.MainPB,0) AS [GCAssoc_MainPB],
		ISNULL(fm.MainPB,0) + ISNULL(fm.PB,0) AS [GCAssoc_TotalPB], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainPB,0) + ISNULL(fm.PB,0) + ISNULL(fa.MainPB,0) + ISNULL(fa.PB,0) AS [Total_PB],
	--PV     
		ISNULL(fa.PV,0) AS [PV], 
		ISNULL(fa.MainPV,0) AS [MainPV],
		ISNULL(fm.PV,0) AS [GCAssoc_PV],
		ISNULL(fm.MainPV,0) AS [GCAssoc_MainPV],  
		ISNULL(fm.MainPV,0) + ISNULL(fm.PV,0) AS [GCAssoc_TotalPV], -- To update on dbo.wrkDSFinancial 
		ISNULL(fm.MainPV,0) + ISNULL(fm.PV,0) + ISNULL(fa.MainPV,0) + ISNULL(fa.PV,0) AS [Total_PV],
	--GV          
		ISNULL(fa.GV,0) AS [GV], 
		ISNULL(fa.MainGV,0) AS [MainGV],
		ISNULL(fm.GV,0) AS [GCAssoc_GV],
		ISNULL(fm.MainGV,0) AS [GCAssoc_MainGV],
		ISNULL(fm.MainGV,0) + ISNULL(fm.GV,0) AS [GCAssoc_TotalGV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainGV,0) + ISNULL(fm.GV,0) + ISNULL(fa.MainGV,0) + ISNULL(fa.GV,0) AS [Total_GV],
	--PPV         
		ISNULL(fa.PPV,0) AS [PPV], 
		ISNULL(fa.MainPPV,0) AS [MainPPV],
		ISNULL(fm.PPV,0) AS [GCAssoc_PPV],
		ISNULL(fm.MainPPV,0) AS [GCAssoc_MainPPV],
		ISNULL(fm.MainPPV,0) + ISNULL(fm.PPV,0) AS [GCAssoc_TotalPPV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainPPV,0) + ISNULL(fm.PPV,0) + ISNULL(fa.MainPPV,0) + ISNULL(fa.PPV,0) AS [Total_PPV],
	--OV          
		ISNULL(fa.OV,0) AS [OV], 
		ISNULL(fa.MainOV,0) AS [MainOV],
		ISNULL(fm.OV,0) AS [GCAssoc_OV],
		ISNULL(fm.MainOV,0) AS [GCAssoc_MainOV],
		ISNULL(fm.MainOV,0) + ISNULL(fm.OV,0) AS [GCAssoc_TotalOV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainOV,0) + ISNULL(fm.OV,0) + ISNULL(fa.MainOV,0) + ISNULL(fa.OV,0) AS [Total_OV],
	--DLV         
		ISNULL(fa.DLV,0) AS [DLV], 
		ISNULL(fa.MainDLV,0) AS [MainDLV],
		ISNULL(fm.DLV,0) AS [GCAssoc_DLV],
		ISNULL(fm.MainDLV,0) AS [GCAssoc_MainDLV],
		ISNULL(fm.MainDLV,0) + ISNULL(fm.DLV,0) AS [GCAssoc_TotalDLV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainDLV,0) + ISNULL(fm.DLV,0) + ISNULL(fa.MainDLV,0) + ISNULL(fa.DLV,0) AS [Total_DLV],
	--MPV         
		ISNULL(fa.MPV,0) AS [MPV], 
		ISNULL(fa.MainMPV,0) AS [MainMPV],
		ISNULL(fm.MPV,0) AS [GCAssoc_MPV],
		ISNULL(fm.MainMPV,0) AS [GCAssoc_MainMPV],
		ISNULL(fm.MainMPV,0) + ISNULL(fm.MPV,0) AS [GCAssoc_TotalMPV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainMPV,0) + ISNULL(fm.MPV,0) + ISNULL(fa.MainMPV,0) + ISNULL(fa.MPV,0) AS [Total_MPV],
	--MTV      
		ISNULL(fa.MTV,0) AS [MTV], 
		ISNULL(fa.MainMTV,0) AS [MainMTV],
		ISNULL(fm.MTV,0) AS [GCAssoc_MTV],
		ISNULL(fm.MainMTV,0) AS [GCAssoc_MainMTV],
		ISNULL(fm.MainMTV,0) + ISNULL(fm.MTV,0) AS [GCAssoc_TotalMTV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainMTV,0) + ISNULL(fm.MTV,0) + ISNULL(fa.MainMTV,0) + ISNULL(fa.MTV,0) AS [Total_MTV],
	--DV     
		ISNULL(fa.DV,0) AS [DV], 
		ISNULL(fa.MainDV,0) AS [MainDV],
		ISNULL(fm.DV,0) AS [GCAssoc_DV],
		ISNULL(fm.MainDV,0) AS [GCAssoc_MainDV],
		ISNULL(fm.MainDV,0) + ISNULL(fm.DV,0) AS [GCAssoc_TotalDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainDV,0) + ISNULL(fm.DV,0) + ISNULL(fa.MainDV,0) + ISNULL(fa.DV,0) AS [Total_DV],
	--PPC   
		ISNULL(fa.PPC,0) AS [PPC], 
		ISNULL(fa.MainPPC,0) AS [MainPPC],
		ISNULL(fm.PPC,0) AS [GCAssoc_PPC],
		ISNULL(fm.MainPPC,0) AS [GCAssoc_MainPPC],
		ISNULL(fm.MainPPC,0) + ISNULL(fm.PPC,0) AS [GCAssoc_TotalPPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainPPC,0) + ISNULL(fm.PPC,0) + ISNULL(fa.MainPPC,0) + ISNULL(fa.PPC,0) AS [Total_PPC],
	--PRV        
		ISNULL(fa.PRV,0) AS [PRV], 
		ISNULL(fa.MainPRV,0) AS [MainPRV],
		ISNULL(fm.PRV,0) AS [GCAssoc_PRV],
		ISNULL(fm.MainPRV,0) AS [GCAssoc_MainPRV],
		ISNULL(fm.MainPRV,0) + ISNULL(fm.PRV,0) AS [GCAssoc_TotalPRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainPRV,0) + ISNULL(fm.PRV,0) + ISNULL(fa.MainPRV,0) + ISNULL(fa.PRV,0) AS [Total_PRV],
	--NDV     
		ISNULL(fa.NDV,0) AS [NDV], 
		ISNULL(fa.MainNDV,0) AS [MainNDV],
		ISNULL(fm.NDV,0) AS [GCAssoc_NDV],
		ISNULL(fm.MainNDV,0) AS [GCAssoc_MainNDV],
		ISNULL(fm.MainNDV,0) + ISNULL(fm.NDV,0) AS [GCAssoc_TotalNDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainNDV,0) + ISNULL(fm.NDV,0) + ISNULL(fa.MainNDV,0) + ISNULL(fa.NDV,0) AS [Total_NDV],
	--SPC    
		ISNULL(fa.SPC,0) AS [SPC], 
		ISNULL(fa.MainSPC,0) AS [MainSPC],
		ISNULL(fm.SPC,0) AS [GCAssoc_SPC],
		ISNULL(fm.MainSPC,0) AS [GCAssoc_MainSPC],
		ISNULL(fm.MainSPC,0) + ISNULL(fm.SPC,0) AS [GCAssoc_TotalSPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainSPC,0) + ISNULL(fm.SPC,0) + ISNULL(fa.MainSPC,0) + ISNULL(fa.SPC,0) AS [Total_SPC],
	--SRV         
		ISNULL(fa.SRV,0) AS [SRV], 
		ISNULL(fa.MainSRV,0) AS [MainSRV],
		ISNULL(fm.SRV,0) AS [GCAssoc_SRV],
		ISNULL(fm.MainSRV,0) AS [GCAssoc_MainSRV],
		ISNULL(fm.MainSRV,0) + ISNULL(fm.SRV,0) AS [GCAssoc_TotalSRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainSRV,0) + ISNULL(fm.SRV,0) + ISNULL(fa.MainSRV,0) + ISNULL(fa.SRV,0) AS [Total_SRV],
	--PV_DV   
		ISNULL(fa.PV_DV,0) AS [PV_DV], 
		ISNULL(fa.MainPV_DV,0) AS [MainPV_DV],
		ISNULL(fm.PV_DV,0) AS [GCAssoc_PV_DV],
		ISNULL(fm.MainPV_DV,0) AS [GCAssoc_MainPV_DV],
		ISNULL(fm.MainPV_DV,0) + ISNULL(fm.PV_DV,0) AS [GCAssoc_TotalPV_DV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainPV_DV,0) + ISNULL(fm.PV_DV,0) + ISNULL(fa.MainPV_DV,0) + ISNULL(fa.PV_DV,0) AS [Total_PV_DV],
	--PV_PPC   
		ISNULL(fa.PV_PPC,0) AS [PV_PPC], 
		ISNULL(fa.MainPV_PPC,0) AS [MainPV_PPC],
		ISNULL(fm.PV_PPC,0) AS [GCAssoc_PV_PPC],
		ISNULL(fm.MainPV_PPC,0) AS [GCAssoc_MainPV_PPC],
		ISNULL(fm.MainPV_PPC,0) + ISNULL(fm.PV_PPC,0) AS [GCAssoc_TotalPV_PPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainPV_PPC,0) + ISNULL(fm.PV_PPC,0) + ISNULL(fa.MainPV_PPC,0) + ISNULL(fa.PV_PPC,0) AS [Total_PV_PPC],
	--PV_PRV   
		ISNULL(fa.PV_PRV,0) AS [PV_PRV], 
		ISNULL(fa.MainPV_PRV,0) AS [MainPV_PRV],
		ISNULL(fm.PV_PRV,0) AS [GCAssoc_PV_PRV],
		ISNULL(fm.MainPV_PRV,0) AS [GCAssoc_MainPV_PRV],
		ISNULL(fm.MainPV_PRV,0) + ISNULL(fm.PV_PRV,0) AS [GCAssoc_TotalPV_PRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainPV_PRV,0) + ISNULL(fm.PV_PRV,0) + ISNULL(fa.MainPV_PRV,0) + ISNULL(fa.PV_PRV,0) AS [Total_PV_PRV],
	--PV_NDV     
		ISNULL(fa.PV_NDV,0) AS [PV_NDV], 
		ISNULL(fa.MainPV_NDV,0) AS [MainPV_NDV],
		ISNULL(fm.PV_NDV,0) AS [GCAssoc_PV_NDV],
		ISNULL(fm.MainPV_NDV,0) AS [GCAssoc_MainPV_NDV],
		ISNULL(fm.MainPV_NDV,0) + ISNULL(fm.PV_NDV,0) AS [GCAssoc_TotalPV_NDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainPV_NDV,0) + ISNULL(fm.PV_NDV,0) + ISNULL(fa.MainPV_NDV,0) + ISNULL(fa.PV_NDV,0) AS [Total_PV_NDV],
	--PV_SPC    
		ISNULL(fa.PV_SPC,0) AS [PV_SPC], 
		ISNULL(fa.MainPV_SPC,0) AS [MainPV_SPC],
		ISNULL(fm.PV_SPC,0) AS [GCAssoc_PV_SPC],
		ISNULL(fm.MainPV_SPC,0) AS [GCAssoc_MainPV_SPC],
		ISNULL(fm.MainPV_SPC,0) + ISNULL(fm.PV_SPC,0) AS [GCAssoc_TotalPV_SPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainPV_SPC,0) + ISNULL(fm.PV_SPC,0) + ISNULL(fa.MainPV_SPC,0) + ISNULL(fa.PV_SPC,0) AS [Total_PV_SPC],
	--PV_SRV   
		ISNULL(fa.PV_SRV,0) AS [PV_SRV], 
		ISNULL(fa.MainPV_SRV,0) AS [MainPV_SRV],
		ISNULL(fm.PV_SRV,0) AS [GCAssoc_PV_SRV],
		ISNULL(fm.MainPV_SRV,0) AS [GCAssoc_MainPV_SRV],
		ISNULL(fm.MainPV_SRV,0) + ISNULL(fm.PV_SRV,0) AS [GCAssoc_TotalPV_SRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainPV_SRV,0) + ISNULL(fm.PV_SRV,0) + ISNULL(fa.MainPV_SRV,0) + ISNULL(fa.PV_SRV,0) AS [Total_PV_SRV],
	--DLV_DV      
		ISNULL(fa.DLV_DV,0) AS [DLV_DV], 
		ISNULL(fa.MainDLV_DV,0) AS [MainDLV_DV],
		ISNULL(fm.DLV_DV,0) AS [GCAssoc_DLV_DV],
		ISNULL(fm.MainDLV_DV,0) AS [GCAssoc_MainDLV_DV],
		ISNULL(fm.MainDLV_DV,0) + ISNULL(fm.DLV_DV,0) AS [GCAssoc_TotalDLV_DV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainDLV_DV,0) + ISNULL(fm.DLV_DV,0) + ISNULL(fa.MainDLV_DV,0) + ISNULL(fa.DLV_DV,0) AS [Total_DLV_DV],
	--DLV_PPC     
		ISNULL(fa.DLV_PPC,0) AS [DLV_PPC], 
		ISNULL(fa.MainDLV_PPC,0) AS [MainDLV_PPC],
		ISNULL(fm.DLV_PPC,0) AS [GCAssoc_DLV_PPC],
		ISNULL(fm.MainDLV_PPC,0) AS [GCAssoc_MainDLV_PPC],
		ISNULL(fm.MainDLV_PPC,0) + ISNULL(fm.DLV_PPC,0) AS [GCAssoc_TotalDLV_PPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainDLV_PPC,0) + ISNULL(fm.DLV_PPC,0) + ISNULL(fa.MainDLV_PPC,0) + ISNULL(fa.DLV_PPC,0) AS [Total_DLV_PPC],
	--DLV_PRV  
		ISNULL(fa.DLV_PRV,0) AS [DLV_PRV], 
		ISNULL(fa.MainDLV_PRV,0) AS [MainDLV_PRV],
		ISNULL(fm.DLV_PRV,0) AS [GCAssoc_DLV_PRV],
		ISNULL(fm.MainDLV_PRV,0) AS [GCAssoc_MainDLV_PRV],
		ISNULL(fm.MainDLV_PRV,0) + ISNULL(fm.DLV_PRV,0) AS [GCAssoc_TotalDLV_PRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainDLV_PRV,0) + ISNULL(fm.DLV_PRV,0) + ISNULL(fa.MainDLV_PRV,0) + ISNULL(fa.DLV_PRV,0) AS [Total_DLV_PRV],
	--DLV_NDV     
		ISNULL(fa.DLV_NDV,0) AS [DLV_NDV], 
		ISNULL(fa.MainDLV_NDV,0) AS [MainDLV_NDV],
		ISNULL(fm.DLV_NDV,0) AS [GCAssoc_DLV_NDV],
		ISNULL(fm.MainDLV_NDV,0) AS [GCAssoc_MainDLV_NDV],
		ISNULL(fm.MainDLV_NDV,0) + ISNULL(fm.DLV_NDV,0) AS [GCAssoc_TotalDLV_NDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainDLV_NDV,0) + ISNULL(fm.DLV_NDV,0) + ISNULL(fa.MainDLV_NDV,0) + ISNULL(fa.DLV_NDV,0) AS [Total_DLV_NDV],
	--DLV_SPC    
		ISNULL(fa.DLV_SPC,0) AS [DLV_SPC], 
		ISNULL(fa.MainDLV_SPC,0) AS [MainDLV_SPC],
		ISNULL(fm.DLV_SPC,0) AS [GCAssoc_DLV_SPC],
		ISNULL(fm.MainDLV_SPC,0) AS [GCAssoc_MainDLV_SPC],
		ISNULL(fm.MainDLV_SPC,0) + ISNULL(fm.DLV_SPC,0) AS [GCAssoc_TotalDLV_SPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainDLV_SPC,0) + ISNULL(fm.DLV_SPC,0) + ISNULL(fa.MainDLV_SPC,0) + ISNULL(fa.DLV_SPC,0) AS [Total_DLV_SPC],
	--DLV_SRV     
		ISNULL(fa.DLV_SRV,0) AS [DLV_SRV], 
		ISNULL(fa.MainDLV_SRV,0) AS [MainDLV_SRV],
		ISNULL(fm.DLV_SRV,0) AS [GCAssoc_DLV_SRV],
		ISNULL(fm.MainDLV_SRV,0) AS [GCAssoc_MainDLV_SRV],
		ISNULL(fm.MainDLV_SRV,0) + ISNULL(fm.DLV_SRV,0) AS [GCAssoc_TotalDLV_SRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainDLV_SRV,0) + ISNULL(fm.DLV_SRV,0) + ISNULL(fa.MainDLV_SRV,0) + ISNULL(fa.DLV_SRV,0) AS [Total_DLV_SRV],
	--GV_DV       
		ISNULL(fa.GV_DV,0) AS [GV_DV], 
		ISNULL(fa.MainGV_DV,0) AS [MainGV_DV],
		ISNULL(fm.GV_DV,0) AS [GCAssoc_GV_DV],
		ISNULL(fm.MainGV_DV,0) AS [GCAssoc_MainGV_DV],
		ISNULL(fm.MainGV_DV,0) + ISNULL(fm.GV_DV,0) AS [GCAssoc_TotalGV_DV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainGV_DV,0) + ISNULL(fm.GV_DV,0) + ISNULL(fa.MainGV_DV,0) + ISNULL(fa.GV_DV,0) AS [Total_GV_DV],
	--GV_PPC      
		ISNULL(fa.GV_PPC,0) AS [GV_PPC], 
		ISNULL(fa.MainGV_PPC,0) AS [MainGV_PPC],
		ISNULL(fm.GV_PPC,0) AS [GCAssoc_GV_PPC],
		ISNULL(fm.MainGV_PPC,0) AS [GCAssoc_MainGV_PPC],
		ISNULL(fm.MainGV_PPC,0) + ISNULL(fm.GV_PPC,0) AS [GCAssoc_TotalGV_PPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainGV_PPC,0) + ISNULL(fm.GV_PPC,0) + ISNULL(fa.MainGV_PPC,0) + ISNULL(fa.GV_PPC,0) AS [Total_GV_PPC],
	--GV_PRV      
		ISNULL(fa.GV_PRV,0) AS [GV_PRV], 
		ISNULL(fa.MainGV_PRV,0) AS [MainGV_PRV],
		ISNULL(fm.GV_PRV,0) AS [GCAssoc_GV_PRV],
		ISNULL(fm.MainGV_PRV,0) AS [GCAssoc_MainGV_PRV],
		ISNULL(fm.MainGV_PRV,0) + ISNULL(fm.GV_PRV,0) AS [GCAssoc_TotalGV_PRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainGV_PRV,0) + ISNULL(fm.GV_PRV,0) + ISNULL(fa.MainGV_PRV,0) + ISNULL(fa.GV_PRV,0) AS [Total_GV_PRV],
	--GV_NDV      
		ISNULL(fa.GV_NDV,0) AS [GV_NDV], 
		ISNULL(fa.MainGV_NDV,0) AS [MainGV_NDV],
		ISNULL(fm.GV_NDV,0) AS [GCAssoc_GV_NDV],
		ISNULL(fm.MainGV_NDV,0) AS [GCAssoc_MainGV_NDV],
		ISNULL(fm.MainGV_NDV,0) + ISNULL(fm.GV_NDV,0) AS [GCAssoc_TotalGV_NDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainGV_NDV,0) + ISNULL(fm.GV_NDV,0) + ISNULL(fa.MainGV_NDV,0) + ISNULL(fa.GV_NDV,0) AS [Total_GV_NDV],
	--GV_SPC   
		ISNULL(fa.GV_SPC,0) AS [GV_SPC], 
		ISNULL(fa.MainGV_SPC,0) AS [MainGV_SPC],
		ISNULL(fm.GV_SPC,0) AS [GCAssoc_GV_SPC],
		ISNULL(fm.MainGV_SPC,0) AS [GCAssoc_MainGV_SPC],
		ISNULL(fm.MainGV_SPC,0) + ISNULL(fm.GV_SPC,0) AS [GCAssoc_TotalGV_SPC], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainGV_SPC,0) + ISNULL(fm.GV_SPC,0) + ISNULL(fa.MainGV_SPC,0) + ISNULL(fa.GV_SPC,0) AS [Total_GV_SPC],
	--GV_SRV  
		ISNULL(fa.GV_SRV,0) AS [GV_SRV], 
		ISNULL(fa.MainGV_SRV,0) AS [MainGV_SRV],
		ISNULL(fm.GV_SRV,0) AS [GCAssoc_GV_SRV],
		ISNULL(fm.MainGV_SRV,0) AS [GCAssoc_MainGV_SRV],
		ISNULL(fm.MainGV_SRV,0) + ISNULL(fm.GV_SRV,0) AS [GCAssoc_TotalGV_SRV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainGV_SRV,0) + ISNULL(fm.GV_SRV,0) + ISNULL(fa.MainGV_SRV,0) + ISNULL(fa.GV_SRV,0) AS [Total_GV_SRV],
	--EV        
		ISNULL(fa.EV,0) AS [EV], 
		ISNULL(fa.MainEV,0) AS [MainEV],
		ISNULL(fm.EV,0) AS [GCAssoc_EV],
		ISNULL(fm.MainEV,0) AS [GCAssoc_MainEV],
		ISNULL(fm.MainEV,0) + ISNULL(fm.EV,0) AS [GCAssoc_TotalEV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainEV,0) + ISNULL(fm.EV,0) + ISNULL(fa.MainEV,0) + ISNULL(fa.EV,0) AS [Total_EV],
	--UV          
		ISNULL(fa.UV,0) AS [UV], 
		ISNULL(fa.MainUV,0) AS [MainUV],
		ISNULL(fm.UV,0) AS [GCAssoc_UV],
		ISNULL(fm.MainUV,0) AS [GCAssoc_MainUV],
		ISNULL(fm.MainUV,0) + ISNULL(fm.UV,0) AS [GCAssoc_TotalUV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainUV,0) + ISNULL(fm.UV,0) + ISNULL(fa.MainUV,0) + ISNULL(fa.UV,0) AS [Total_UV],
	--MPCV      
		ISNULL(fa.MPCV,0) AS [MPCV], 
		ISNULL(fa.MainMPCV,0) AS [MainMPCV],
		ISNULL(fm.MPCV,0) AS [GCAssoc_MPCV],
		ISNULL(fm.MainMPCV,0) AS [GCAssoc_MainMPCV],
		ISNULL(fm.MainMPCV,0) + ISNULL(fm.MPCV,0) AS [GCAssoc_TotalMPCV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainMPCV,0) + ISNULL(fm.MPCV,0) + ISNULL(fa.MainMPCV,0) + ISNULL(fa.MPCV,0) AS [Total_MPCV],
	--TOTAL_POINTS
		ISNULL(fa.TOTAL_POINTS,0) AS [TOTAL_POINTS], 
		ISNULL(fa.MainTOTAL_POINTS,0) AS [MainTOTAL_POINTS],
		ISNULL(fm.TOTAL_POINTS,0) AS [GCAssoc_TOTAL_POINTS],
		ISNULL(fm.MainTOTAL_POINTS,0) AS [GCAssoc_MainTOTAL_POINTS],
		ISNULL(fm.MainTOTAL_POINTS,0) + ISNULL(fm.TOTAL_POINTS,0) AS [GCAssoc_TotalTOTAL_POINTS], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainTOTAL_POINTS,0) + ISNULL(fm.TOTAL_POINTS,0) + ISNULL(fa.MainTOTAL_POINTS,0) + ISNULL(fa.TOTAL_POINTS,0) AS [Total_TOTAL_POINTS],
	--QCPV        
		ISNULL(fa.QCPV,0) AS [QCPV], 
		ISNULL(fa.MainQCPV,0) AS [MainQCPV],
		ISNULL(fm.QCPV,0) AS [GCAssoc_QCPV],
		ISNULL(fm.MainQCPV,0) AS [GCAssoc_MainQCPV],
		ISNULL(fm.MainQCPV,0) + ISNULL(fm.QCPV,0) AS [GCAssoc_TotalQCPV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainQCPV,0) + ISNULL(fm.QCPV,0) + ISNULL(fa.MainQCPV,0) + ISNULL(fa.QCPV,0) AS [Total_QCPV],
	--QDV         
		ISNULL(fa.QDV,0) AS [QDV], 
		ISNULL(fa.MainQDV,0) AS [MainQDV],
		ISNULL(fm.QDV,0) AS [GCAssoc_QDV],
		ISNULL(fm.MainQDV,0) AS [GCAssoc_MainQDV],
		ISNULL(fm.MainQDV,0) + ISNULL(fm.QDV,0) AS [GCAssoc_TotalQDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainQDV,0) + ISNULL(fm.QDV,0) + ISNULL(fa.MainQDV,0) + ISNULL(fa.QDV,0) AS [Total_QDV],
	--QDV_DV    
		ISNULL(fa.QDV_DV,0) AS [QDV_DV], 
		ISNULL(fa.MainQDV_DV,0) AS [MainQDV_DV],
		ISNULL(fm.QDV_DV,0) AS [GCAssoc_QDV_DV],
		ISNULL(fm.MainQDV_DV,0) AS [GCAssoc_MainQDV_DV],
		ISNULL(fm.MainQDV_DV,0) + ISNULL(fm.QDV_DV,0) AS [GCAssoc_TotalQDV_DV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainQDV_DV,0) + ISNULL(fm.QDV_DV,0) + ISNULL(fa.MainQDV_DV,0) + ISNULL(fa.QDV_DV,0) AS [Total_QDV_DV],
	--PPV_DLV     
		ISNULL(fa.PPV_DLV,0) AS [PPV_DLV], 
		ISNULL(fa.MainPPV_DLV,0) AS [MainPPV_DLV],
		ISNULL(fm.PPV_DLV,0) AS [GCAssoc_PPV_DLV],
		ISNULL(fm.MainPPV_DLV,0) AS [GCAssoc_MainPPV_DLV],
		ISNULL(fm.MainPPV_DLV,0) + ISNULL(fm.PPV_DLV,0) AS [GCAssoc_TotalPPV_DLV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainPPV_DLV,0) + ISNULL(fm.PPV_DLV,0) + ISNULL(fa.MainPPV_DLV,0) + ISNULL(fa.PPV_DLV,0) AS [Total_PPV_DLV],
	--DV_DLVDV    
		ISNULL(fa.DV_DLVDV,0) AS [DV_DLVDV], 
		ISNULL(fa.MainDV_DLVDV,0) AS [MainDV_DLVDV],
		ISNULL(fm.DV_DLVDV,0) AS [GCAssoc_DV_DLVDV],
		ISNULL(fm.MainDV_DLVDV,0) AS [GCAssoc_MainDV_DLVDV],
		ISNULL(fm.MainDV_DLVDV,0) + ISNULL(fm.DV_DLVDV,0) AS [GCAssoc_TotalDV_DLVDV], -- To update on dbo.wrkDSFinancial
		ISNULL(fm.MainDV_DLVDV,0) + ISNULL(fm.DV_DLVDV,0) + ISNULL(fa.MainDV_DLVDV,0) + ISNULL(fa.DV_DLVDV,0) AS [Total_DV_DLVDV]
INTO #GCAAssoc_Volume_Associated
FROM #GCAssocID AS gc
CROSS APPLY (SELECT MonthDate FROM pubEvents.dbo.dimMonth M WITH (NOLOCK) WHERE M.MonthDate BETWEEN @MinRoyaltyMonth AND @MaxRoyaltyMonth) AS M
LEFT JOIN #Main_GCAAssoc_Volume AS fm
	ON gc.PK_MainDistributor = fm.PK_Distributor AND M.MONTHDATE = fm.RoyaltyMonth
LEFT JOIN #Associated_GCAAssoc_Volume AS fa
	ON gc.PK_AssociatedID = fa.PK_Distributor AND M.MONTHDATE = fa.RoyaltyMonth

 DROP TABLE IF EXISTS #GCAAssoc_Volume 

 SELECT 
	PK_Distributor 
	,PK_AssociatedID
	,RoyaltyMonth
	,1 AS IsValidRecord
	,DivorceType
	,Original_As_Main
	,TV
	,MainTV
	,GCAssoc_TV
	,GCAssoc_MainTV
	,GCAssoc_TotalTV
	,Total_TV
	,RO
	,MainRO
	,GCAssoc_RO
	,GCAssoc_MainRO
	,GCAssoc_TotalRO
	,Total_RO
	,PB
	,MainPB
	,GCAssoc_PB
	,GCAssoc_MainPB
	,GCAssoc_TotalPB
	,Total_PB
	,PV
	,MainPV
	,GCAssoc_PV
	,GCAssoc_MainPV
	,GCAssoc_TotalPV
	,Total_PV
	,GV
	,MainGV
	,GCAssoc_GV
	,GCAssoc_MainGV
	,GCAssoc_TotalGV
	,Total_GV
	,PPV
	,MainPPV
	,GCAssoc_PPV
	,GCAssoc_MainPPV
	,GCAssoc_TotalPPV
	,Total_PPV
	,OV
	,MainOV
	,GCAssoc_OV
	,GCAssoc_MainOV
	,GCAssoc_TotalOV
	,Total_OV
	,DLV
	,MainDLV
	,GCAssoc_DLV
	,GCAssoc_MainDLV
	,GCAssoc_TotalDLV
	,Total_DLV
	,MPV
	,MainMPV
	,GCAssoc_MPV
	,GCAssoc_MainMPV
	,GCAssoc_TotalMPV
	,Total_MPV
	,MTV
	,MainMTV
	,GCAssoc_MTV
	,GCAssoc_MainMTV
	,GCAssoc_TotalMTV
	,Total_MTV
	,DV
	,MainDV
	,GCAssoc_DV
	,GCAssoc_MainDV
	,GCAssoc_TotalDV
	,Total_DV
	,PPC
	,MainPPC
	,GCAssoc_PPC
	,GCAssoc_MainPPC
	,GCAssoc_TotalPPC
	,Total_PPC
	,PRV
	,MainPRV
	,GCAssoc_PRV
	,GCAssoc_MainPRV
	,GCAssoc_TotalPRV
	,Total_PRV
	,NDV
	,MainNDV
	,GCAssoc_NDV
	,GCAssoc_MainNDV
	,GCAssoc_TotalNDV
	,Total_NDV
	,SPC
	,MainSPC
	,GCAssoc_SPC
	,GCAssoc_MainSPC
	,GCAssoc_TotalSPC
	,Total_SPC
	,SRV
	,MainSRV
	,GCAssoc_SRV
	,GCAssoc_MainSRV
	,GCAssoc_TotalSRV
	,Total_SRV
	,PV_DV
	,MainPV_DV
	,GCAssoc_PV_DV
	,GCAssoc_MainPV_DV
	,GCAssoc_TotalPV_DV
	,Total_PV_DV
	,PV_PPC
	,MainPV_PPC
	,GCAssoc_PV_PPC
	,GCAssoc_MainPV_PPC
	,GCAssoc_TotalPV_PPC
	,Total_PV_PPC
	,PV_PRV
	,MainPV_PRV
	,GCAssoc_PV_PRV
	,GCAssoc_MainPV_PRV
	,GCAssoc_TotalPV_PRV
	,Total_PV_PRV
	,PV_NDV
	,MainPV_NDV
	,GCAssoc_PV_NDV
	,GCAssoc_MainPV_NDV
	,GCAssoc_TotalPV_NDV
	,Total_PV_NDV
	,PV_SPC
	,MainPV_SPC
	,GCAssoc_PV_SPC
	,GCAssoc_MainPV_SPC
	,GCAssoc_TotalPV_SPC
	,Total_PV_SPC
	,PV_SRV
	,MainPV_SRV
	,GCAssoc_PV_SRV
	,GCAssoc_MainPV_SRV
	,GCAssoc_TotalPV_SRV
	,Total_PV_SRV
	,DLV_DV
	,MainDLV_DV
	,GCAssoc_DLV_DV
	,GCAssoc_MainDLV_DV
	,GCAssoc_TotalDLV_DV
	,Total_DLV_DV
	,DLV_PPC
	,MainDLV_PPC
	,GCAssoc_DLV_PPC
	,GCAssoc_MainDLV_PPC
	,GCAssoc_TotalDLV_PPC
	,Total_DLV_PPC
	,DLV_PRV
	,MainDLV_PRV
	,GCAssoc_DLV_PRV
	,GCAssoc_MainDLV_PRV
	,GCAssoc_TotalDLV_PRV
	,Total_DLV_PRV
	,DLV_NDV
	,MainDLV_NDV
	,GCAssoc_DLV_NDV
	,GCAssoc_MainDLV_NDV
	,GCAssoc_TotalDLV_NDV
	,Total_DLV_NDV
	,DLV_SPC
	,MainDLV_SPC
	,GCAssoc_DLV_SPC
	,GCAssoc_MainDLV_SPC
	,GCAssoc_TotalDLV_SPC
	,Total_DLV_SPC
	,DLV_SRV
	,MainDLV_SRV
	,GCAssoc_DLV_SRV
	,GCAssoc_MainDLV_SRV
	,GCAssoc_TotalDLV_SRV
	,Total_DLV_SRV
	,GV_DV
	,MainGV_DV
	,GCAssoc_GV_DV
	,GCAssoc_MainGV_DV
	,GCAssoc_TotalGV_DV
	,Total_GV_DV
	,GV_PPC
	,MainGV_PPC
	,GCAssoc_GV_PPC
	,GCAssoc_MainGV_PPC
	,GCAssoc_TotalGV_PPC
	,Total_GV_PPC
	,GV_PRV
	,MainGV_PRV
	,GCAssoc_GV_PRV
	,GCAssoc_MainGV_PRV
	,GCAssoc_TotalGV_PRV
	,Total_GV_PRV
	,GV_NDV
	,MainGV_NDV
	,GCAssoc_GV_NDV
	,GCAssoc_MainGV_NDV
	,GCAssoc_TotalGV_NDV
	,Total_GV_NDV
	,GV_SPC
	,MainGV_SPC
	,GCAssoc_GV_SPC
	,GCAssoc_MainGV_SPC
	,GCAssoc_TotalGV_SPC
	,Total_GV_SPC
	,GV_SRV
	,MainGV_SRV
	,GCAssoc_GV_SRV
	,GCAssoc_MainGV_SRV
	,GCAssoc_TotalGV_SRV
	,Total_GV_SRV
	,EV
	,MainEV
	,GCAssoc_EV
	,GCAssoc_MainEV
	,GCAssoc_TotalEV
	,Total_EV
	,UV
	,MainUV
	,GCAssoc_UV
	,GCAssoc_MainUV
	,GCAssoc_TotalUV
	,Total_UV
	,MPCV
	,MainMPCV
	,GCAssoc_MPCV
	,GCAssoc_MainMPCV
	,GCAssoc_TotalMPCV
	,Total_MPCV
	,TOTAL_POINTS
	,MainTOTAL_POINTS
	,GCAssoc_TOTAL_POINTS
	,GCAssoc_MainTOTAL_POINTS
	,GCAssoc_TotalTOTAL_POINTS
	,Total_TOTAL_POINTS
	,QCPV
	,MainQCPV
	,GCAssoc_QCPV
	,GCAssoc_MainQCPV
	,GCAssoc_TotalQCPV
	,Total_QCPV
	,QDV
	,MainQDV
	,GCAssoc_QDV
	,GCAssoc_MainQDV
	,GCAssoc_TotalQDV
	,Total_QDV
	,QDV_DV
	,MainQDV_DV
	,GCAssoc_QDV_DV
	,GCAssoc_MainQDV_DV
	,GCAssoc_TotalQDV_DV
	,Total_QDV_DV
	,PPV_DLV
	,MainPPV_DLV
	,GCAssoc_PPV_DLV
	,GCAssoc_MainPPV_DLV
	,GCAssoc_TotalPPV_DLV
	,Total_PPV_DLV
	,DV_DLVDV
	,MainDV_DLVDV
	,GCAssoc_DV_DLVDV
	,GCAssoc_MainDV_DLVDV
	,GCAssoc_TotalDV_DLVDV
	,Total_DV_DLVDV
	,NULL AS GCAssoc21_TV
	,NULL AS GCAssoc21_RO
	,NULL AS GCAssoc21_PB
	,NULL AS GCAssoc21_PV
	,NULL AS GCAssoc21_GV 
	,NULL AS GCAssoc21_PPV
	,NULL AS GCAssoc21_OV
	,NULL AS GCAssoc21_DLV
	,NULL AS GCAssoc21_MPV
	,NULL AS GCAssoc21_MTV
	,NULL AS GCAssoc21_DV
	,NULL AS GCAssoc21_PPC
	,NULL AS GCAssoc21_PRV
	,NULL AS GCAssoc21_NDV
	,NULL AS GCAssoc21_SPC
	,NULL AS GCAssoc21_SRV 
	,NULL AS GCAssoc21_PV_DV
	,NULL AS GCAssoc21_PV_PPC
	,NULL AS GCAssoc21_PV_PRV 
	,NULL AS GCAssoc21_PV_NDV
	,NULL AS GCAssoc21_PV_SPC
	,NULL AS GCAssoc21_PV_SRV 
	,NULL AS GCAssoc21_DLV_DV
	,NULL AS GCAssoc21_DLV_PPC
	,NULL AS GCAssoc21_DLV_PRV
	,NULL AS GCAssoc21_DLV_NDV 
	,NULL AS GCAssoc21_DLV_SPC 
	,NULL AS GCAssoc21_DLV_SRV      
	,NULL AS GCAssoc21_GV_DV        
	,NULL AS GCAssoc21_GV_PPC       
	,NULL AS GCAssoc21_GV_PRV       
	,NULL AS GCAssoc21_GV_NDV       
	,NULL AS GCAssoc21_GV_SPC    
	,NULL AS GCAssoc21_GV_SRV   
	,NULL AS GCAssoc21_EV         
	,NULL AS GCAssoc21_UV           
	,NULL AS GCAssoc21_MPCV       
	,NULL AS GCAssoc21_TOTAL_POINTS 
	,NULL AS GCAssoc21_QCPV         
	,NULL AS GCAssoc21_QDV          
	,NULL AS GCAssoc21_QDV_DV     
	,NULL AS GCAssoc21_PPV_DLV    
	,NULL AS GCAssoc21_DV_DLVDV  
INTO #GCAAssoc_Volume 
FROM #GCAAssoc_Volume_Main
UNION
 SELECT 
	PK_Distributor 
	,PK_MainDistributor AS PK_AssociatedID
	,RoyaltyMonth
	,1 AS IsValidRecord
	,DivorceType
	,Original_As_Main
	,TV
	,MainTV
	,GCAssoc_TV
	,GCAssoc_MainTV
	,GCAssoc_TotalTV
	,Total_TV
	,RO
	,MainRO
	,GCAssoc_RO
	,GCAssoc_MainRO
	,GCAssoc_TotalRO
	,Total_RO
	,PB
	,MainPB
	,GCAssoc_PB
	,GCAssoc_MainPB
	,GCAssoc_TotalPB
	,Total_PB
	,PV
	,MainPV
	,GCAssoc_PV
	,GCAssoc_MainPV
	,GCAssoc_TotalPV 
	,Total_PV
	,GV
	,MainGV
	,GCAssoc_GV
	,GCAssoc_MainGV
	,GCAssoc_TotalGV
	,Total_GV
	,PPV
	,MainPPV
	,GCAssoc_PPV
	,GCAssoc_MainPPV
	,GCAssoc_TotalPPV
	,Total_PPV
	,OV
	,MainOV
	,GCAssoc_OV
	,GCAssoc_MainOV
	,GCAssoc_TotalOV
	,Total_OV
	,DLV
	,MainDLV
	,GCAssoc_DLV
	,GCAssoc_MainDLV
	,GCAssoc_TotalDLV
	,Total_DLV
	,MPV
	,MainMPV
	,GCAssoc_MPV
	,GCAssoc_MainMPV
	,GCAssoc_TotalMPV
	,Total_MPV
	,MTV
	,MainMTV
	,GCAssoc_MTV
	,GCAssoc_MainMTV
	,GCAssoc_TotalMTV
	,Total_MTV
	,DV
	,MainDV
	,GCAssoc_DV
	,GCAssoc_MainDV
	,GCAssoc_TotalDV
	,Total_DV
	,PPC
	,MainPPC
	,GCAssoc_PPC
	,GCAssoc_MainPPC
	,GCAssoc_TotalPPC
	,Total_PPC
	,PRV
	,MainPRV
	,GCAssoc_PRV
	,GCAssoc_MainPRV
	,GCAssoc_TotalPRV
	,Total_PRV
	,NDV
	,MainNDV
	,GCAssoc_NDV
	,GCAssoc_MainNDV
	,GCAssoc_TotalNDV
	,Total_NDV
	,SPC
	,MainSPC
	,GCAssoc_SPC
	,GCAssoc_MainSPC
	,GCAssoc_TotalSPC
	,Total_SPC
	,SRV
	,MainSRV
	,GCAssoc_SRV
	,GCAssoc_MainSRV
	,GCAssoc_TotalSRV
	,Total_SRV
	,PV_DV
	,MainPV_DV
	,GCAssoc_PV_DV
	,GCAssoc_MainPV_DV
	,GCAssoc_TotalPV_DV
	,Total_PV_DV
	,PV_PPC
	,MainPV_PPC
	,GCAssoc_PV_PPC
	,GCAssoc_MainPV_PPC
	,GCAssoc_TotalPV_PPC
	,Total_PV_PPC
	,PV_PRV
	,MainPV_PRV
	,GCAssoc_PV_PRV
	,GCAssoc_MainPV_PRV
	,GCAssoc_TotalPV_PRV
	,Total_PV_PRV
	,PV_NDV
	,MainPV_NDV
	,GCAssoc_PV_NDV
	,GCAssoc_MainPV_NDV
	,GCAssoc_TotalPV_NDV
	,Total_PV_NDV
	,PV_SPC
	,MainPV_SPC
	,GCAssoc_PV_SPC
	,GCAssoc_MainPV_SPC
	,GCAssoc_TotalPV_SPC
	,Total_PV_SPC
	,PV_SRV
	,MainPV_SRV
	,GCAssoc_PV_SRV
	,GCAssoc_MainPV_SRV
	,GCAssoc_TotalPV_SRV
	,Total_PV_SRV
	,DLV_DV
	,MainDLV_DV
	,GCAssoc_DLV_DV
	,GCAssoc_MainDLV_DV
	,GCAssoc_TotalDLV_DV
	,Total_DLV_DV
	,DLV_PPC
	,MainDLV_PPC
	,GCAssoc_DLV_PPC
	,GCAssoc_MainDLV_PPC
	,GCAssoc_TotalDLV_PPC
	,Total_DLV_PPC
	,DLV_PRV
	,MainDLV_PRV
	,GCAssoc_DLV_PRV
	,GCAssoc_MainDLV_PRV
	,GCAssoc_TotalDLV_PRV
	,Total_DLV_PRV
	,DLV_NDV
	,MainDLV_NDV
	,GCAssoc_DLV_NDV
	,GCAssoc_MainDLV_NDV
	,GCAssoc_TotalDLV_NDV
	,Total_DLV_NDV
	,DLV_SPC
	,MainDLV_SPC
	,GCAssoc_DLV_SPC
	,GCAssoc_MainDLV_SPC
	,GCAssoc_TotalDLV_SPC
	,Total_DLV_SPC
	,DLV_SRV
	,MainDLV_SRV
	,GCAssoc_DLV_SRV
	,GCAssoc_MainDLV_SRV
	,GCAssoc_TotalDLV_SRV
	,Total_DLV_SRV
	,GV_DV
	,MainGV_DV
	,GCAssoc_GV_DV
	,GCAssoc_MainGV_DV
	,GCAssoc_TotalGV_DV
	,Total_GV_DV
	,GV_PPC
	,MainGV_PPC
	,GCAssoc_GV_PPC
	,GCAssoc_MainGV_PPC
	,GCAssoc_TotalGV_PPC
	,Total_GV_PPC
	,GV_PRV
	,MainGV_PRV
	,GCAssoc_GV_PRV
	,GCAssoc_MainGV_PRV
	,GCAssoc_TotalGV_PRV
	,Total_GV_PRV
	,GV_NDV
	,MainGV_NDV
	,GCAssoc_GV_NDV
	,GCAssoc_MainGV_NDV
	,GCAssoc_TotalGV_NDV
	,Total_GV_NDV
	,GV_SPC
	,MainGV_SPC
	,GCAssoc_GV_SPC
	,GCAssoc_MainGV_SPC
	,GCAssoc_TotalGV_SPC
	,Total_GV_SPC
	,GV_SRV
	,MainGV_SRV
	,GCAssoc_GV_SRV
	,GCAssoc_MainGV_SRV
	,GCAssoc_TotalGV_SRV
	,Total_GV_SRV
	,EV
	,MainEV
	,GCAssoc_EV
	,GCAssoc_MainEV
	,GCAssoc_TotalEV
	,Total_EV
	,UV
	,MainUV
	,GCAssoc_UV
	,GCAssoc_MainUV
	,GCAssoc_TotalUV
	,Total_UV
	,MPCV
	,MainMPCV
	,GCAssoc_MPCV
	,GCAssoc_MainMPCV
	,GCAssoc_TotalMPCV
	,Total_MPCV
	,TOTAL_POINTS
	,MainTOTAL_POINTS
	,GCAssoc_TOTAL_POINTS
	,GCAssoc_MainTOTAL_POINTS
	,GCAssoc_TotalTOTAL_POINTS
	,Total_TOTAL_POINTS
	,QCPV
	,MainQCPV
	,GCAssoc_QCPV
	,GCAssoc_MainQCPV
	,GCAssoc_TotalQCPV
	,Total_QCPV
	,QDV
	,MainQDV
	,GCAssoc_QDV
	,GCAssoc_MainQDV
	,GCAssoc_TotalQDV
	,Total_QDV
	,QDV_DV
	,MainQDV_DV
	,GCAssoc_QDV_DV
	,GCAssoc_MainQDV_DV
	,GCAssoc_TotalQDV_DV
	,Total_QDV_DV
	,PPV_DLV
	,MainPPV_DLV
	,GCAssoc_PPV_DLV
	,GCAssoc_MainPPV_DLV
	,GCAssoc_TotalPPV_DLV
	,Total_PPV_DLV
	,DV_DLVDV
	,MainDV_DLVDV
	,GCAssoc_DV_DLVDV
	,GCAssoc_MainDV_DLVDV
	,GCAssoc_TotalDV_DLVDV
	,Total_DV_DLVDV 
	,NULL AS GCAssoc21_TV
	,NULL AS GCAssoc21_RO
	,NULL AS GCAssoc21_PB
	,NULL AS GCAssoc21_PV
	,NULL AS GCAssoc21_GV 
	,NULL AS GCAssoc21_PPV
	,NULL AS GCAssoc21_OV
	,NULL AS GCAssoc21_DLV
	,NULL AS GCAssoc21_MPV
	,NULL AS GCAssoc21_MTV
	,NULL AS GCAssoc21_DV
	,NULL AS GCAssoc21_PPC
	,NULL AS GCAssoc21_PRV
	,NULL AS GCAssoc21_NDV
	,NULL AS GCAssoc21_SPC
	,NULL AS GCAssoc21_SRV 
	,NULL AS GCAssoc21_PV_DV
	,NULL AS GCAssoc21_PV_PPC
	,NULL AS GCAssoc21_PV_PRV 
	,NULL AS GCAssoc21_PV_NDV
	,NULL AS GCAssoc21_PV_SPC
	,NULL AS GCAssoc21_PV_SRV 
	,NULL AS GCAssoc21_DLV_DV
	,NULL AS GCAssoc21_DLV_PPC
	,NULL AS GCAssoc21_DLV_PRV
	,NULL AS GCAssoc21_DLV_NDV 
	,NULL AS GCAssoc21_DLV_SPC 
	,NULL AS GCAssoc21_DLV_SRV      
	,NULL AS GCAssoc21_GV_DV        
	,NULL AS GCAssoc21_GV_PPC       
	,NULL AS GCAssoc21_GV_PRV       
	,NULL AS GCAssoc21_GV_NDV       
	,NULL AS GCAssoc21_GV_SPC    
	,NULL AS GCAssoc21_GV_SRV   
	,NULL AS GCAssoc21_EV         
	,NULL AS GCAssoc21_UV           
	,NULL AS GCAssoc21_MPCV       
	,NULL AS GCAssoc21_TOTAL_POINTS 
	,NULL AS GCAssoc21_QCPV         
	,NULL AS GCAssoc21_QDV          
	,NULL AS GCAssoc21_QDV_DV     
	,NULL AS GCAssoc21_PPV_DLV    
	,NULL AS GCAssoc21_DV_DLVDV     
FROM #GCAAssoc_Volume_Associated
 
--Divorce cases with 2 IDs will count the volume from GC association 

DROP TABLE IF EXISTS #assoc21  

SELECT 
	gc.PK_MainDistributor AS [PK_Distributor_Main]
	,gc.PK_AssociatedID AS [PK_Distributor_Assoc]
	,a.PK_MainDistributor
	,a.PK_AssociatedID
	,RoyaltyMonth 
	,fm.GCAssoc_TV
	,fm.GCAssoc_RO
	,fm.GCAssoc_PB
	,fm.GCAssoc_PV
	,fm.GCAssoc_GV 
	,fm.GCAssoc_PPV
	,fm.GCAssoc_OV
	,fm.GCAssoc_DLV
	,fm.GCAssoc_MPV
	,fm.GCAssoc_MTV
	,fm.GCAssoc_DV
	,fm.GCAssoc_PPC
	,fm.GCAssoc_PRV
	,fm.GCAssoc_NDV
	,fm.GCAssoc_SPC
	,fm.GCAssoc_SRV 
	,fm.GCAssoc_PV_DV
	,fm.GCAssoc_PV_PPC
	,fm.GCAssoc_PV_PRV 
	,fm.GCAssoc_PV_NDV
	,fm.GCAssoc_PV_SPC
	,fm.GCAssoc_PV_SRV 
	,fm.GCAssoc_DLV_DV
	,fm.GCAssoc_DLV_PPC
	,fm.GCAssoc_DLV_PRV
	,fm.GCAssoc_DLV_NDV 
	,fm.GCAssoc_DLV_SPC 
	,fm.GCAssoc_DLV_SRV      
	,fm.GCAssoc_GV_DV        
	,fm.GCAssoc_GV_PPC       
	,fm.GCAssoc_GV_PRV       
	,fm.GCAssoc_GV_NDV       
	,fm.GCAssoc_GV_SPC    
	,fm.GCAssoc_GV_SRV   
	,fm.GCAssoc_EV         
	,fm.GCAssoc_UV           
	,fm.GCAssoc_MPCV       
	,fm.GCAssoc_TOTAL_POINTS 
	,fm.GCAssoc_QCPV         
	,fm.GCAssoc_QDV          
	,fm.GCAssoc_QDV_DV     
	,fm.GCAssoc_PPV_DLV    
	,fm.GCAssoc_DV_DLVDV     
INTO #assoc21
FROM #GCAssocID AS gc 
INNER JOIN #assoc1 AS a
	ON gc.nMainDistributorID_Divorce = a.PK_MainDistributor AND a.PK_AssociatedID <> gc.PK_MainDistributor
LEFT JOIN #GCAAssoc_Volume AS fm
	ON a.PK_AssociatedID = fm.PK_Distributor   
WHERE gc.DivorceType = 21
UNION
SELECT 
	gc.PK_MainDistributor AS [PK_Distributor_Main]
	,gc.PK_AssociatedID AS [PK_Distributor_Assoc]
	,a.PK_MainDistributor
	,a.PK_AssociatedID
	,RoyaltyMonth 
	,fm.GCAssoc_TV
	,fm.GCAssoc_RO
	,fm.GCAssoc_PB
	,fm.GCAssoc_PV
	,fm.GCAssoc_GV 
	,fm.GCAssoc_PPV
	,fm.GCAssoc_OV
	,fm.GCAssoc_DLV
	,fm.GCAssoc_MPV
	,fm.GCAssoc_MTV
	,fm.GCAssoc_DV
	,fm.GCAssoc_PPC
	,fm.GCAssoc_PRV
	,fm.GCAssoc_NDV
	,fm.GCAssoc_SPC
	,fm.GCAssoc_SRV 
	,fm.GCAssoc_PV_DV
	,fm.GCAssoc_PV_PPC
	,fm.GCAssoc_PV_PRV 
	,fm.GCAssoc_PV_NDV
	,fm.GCAssoc_PV_SPC
	,fm.GCAssoc_PV_SRV 
	,fm.GCAssoc_DLV_DV
	,fm.GCAssoc_DLV_PPC
	,fm.GCAssoc_DLV_PRV
	,fm.GCAssoc_DLV_NDV 
	,fm.GCAssoc_DLV_SPC 
	,fm.GCAssoc_DLV_SRV      
	,fm.GCAssoc_GV_DV        
	,fm.GCAssoc_GV_PPC       
	,fm.GCAssoc_GV_PRV       
	,fm.GCAssoc_GV_NDV       
	,fm.GCAssoc_GV_SPC    
	,fm.GCAssoc_GV_SRV   
	,fm.GCAssoc_EV         
	,fm.GCAssoc_UV           
	,fm.GCAssoc_MPCV       
	,fm.GCAssoc_TOTAL_POINTS 
	,fm.GCAssoc_QCPV         
	,fm.GCAssoc_QDV          
	,fm.GCAssoc_QDV_DV     
	,fm.GCAssoc_PPV_DLV    
	,fm.GCAssoc_DV_DLVDV 
FROM #GCAssocID AS gc 
INNER JOIN #assoc1 AS a
	ON gc.nMainDistributorID_Divorce = a.PK_MainDistributor AND a.PK_AssociatedID <> gc.PK_MainDistributor
LEFT JOIN #GCAAssoc_Volume AS fm
	ON a.PK_MainDistributor = fm.PK_Distributor   
WHERE gc.DivorceType = 21

UPDATE gc
	SET  
	gc.GCAssoc21_TV					= ISNULL(a.GCAssoc_TV,0)
	,gc.GCAssoc21_RO				= ISNULL(a.GCAssoc_RO,0)
	,gc.GCAssoc21_PB				= ISNULL(a.GCAssoc_PB,0)
	,gc.GCAssoc21_PV				= ISNULL(a.GCAssoc_PV,0)
	,gc.GCAssoc21_GV 				= ISNULL(a.GCAssoc_GV,0)
	,gc.GCAssoc21_PPV				= ISNULL(a.GCAssoc_PPV,0)
	,gc.GCAssoc21_OV				= ISNULL(a.GCAssoc_OV,0)
	,gc.GCAssoc21_DLV				= ISNULL(a.GCAssoc_DLV,0)
	,gc.GCAssoc21_MPV				= ISNULL(a.GCAssoc_MPV,0)
	,gc.GCAssoc21_MTV				= ISNULL(a.GCAssoc_MTV,0)
	,gc.GCAssoc21_DV				= ISNULL(a.GCAssoc_DV,0)
	,gc.GCAssoc21_PPC				= ISNULL(a.GCAssoc_PPC,0)
	,gc.GCAssoc21_PRV				= ISNULL(a.GCAssoc_PRV,0)
	,gc.GCAssoc21_NDV				= ISNULL(a.GCAssoc_NDV,0)
	,gc.GCAssoc21_SPC				= ISNULL(a.GCAssoc_SPC,0)
	,gc.GCAssoc21_SRV 				= ISNULL(a.GCAssoc_SRV,0)
	,gc.GCAssoc21_PV_DV				= ISNULL(a.GCAssoc_PV_DV,0)
	,gc.GCAssoc21_PV_PPC			= ISNULL(a.GCAssoc_PV_PPC,0)
	,gc.GCAssoc21_PV_PRV 			= ISNULL(a.GCAssoc_PV_PRV,0)
	,gc.GCAssoc21_PV_NDV			= ISNULL(a.GCAssoc_PV_NDV,0)
	,gc.GCAssoc21_PV_SPC			= ISNULL(a.GCAssoc_PV_SPC,0)
	,gc.GCAssoc21_PV_SRV 			= ISNULL(a.GCAssoc_PV_SRV,0)
	,gc.GCAssoc21_DLV_DV			= ISNULL(a.GCAssoc_DLV_DV,0)
	,gc.GCAssoc21_DLV_PPC			= ISNULL(a.GCAssoc_DLV_PPC,0)
	,gc.GCAssoc21_DLV_PRV			= ISNULL(a.GCAssoc_DLV_PRV,0)
	,gc.GCAssoc21_DLV_NDV 			= ISNULL(a.GCAssoc_DLV_NDV,0)
	,gc.GCAssoc21_DLV_SPC 			= ISNULL(a.GCAssoc_DLV_SPC,0)
	,gc.GCAssoc21_DLV_SRV     		= ISNULL(a.GCAssoc_DLV_SRV,0)
	,gc.GCAssoc21_GV_DV       		= ISNULL(a.GCAssoc_GV_DV,0)
	,gc.GCAssoc21_GV_PPC      		= ISNULL(a.GCAssoc_GV_PPC,0)
	,gc.GCAssoc21_GV_PRV      		= ISNULL(a.GCAssoc_GV_PRV,0)
	,gc.GCAssoc21_GV_NDV      		= ISNULL(a.GCAssoc_GV_NDV,0)
	,gc.GCAssoc21_GV_SPC    		= ISNULL(a.GCAssoc_GV_SPC,0)
	,gc.GCAssoc21_GV_SRV   			= ISNULL(a.GCAssoc_GV_SRV,0)
	,gc.GCAssoc21_EV         		= ISNULL(a.GCAssoc_EV,0)
	,gc.GCAssoc21_UV          		= ISNULL(a.GCAssoc_UV,0)
	,gc.GCAssoc21_MPCV       		= ISNULL(a.GCAssoc_MPCV,0)
	,gc.GCAssoc21_TOTAL_POINTS		= ISNULL(a.GCAssoc_TOTAL_POINTS,0)
	,gc.GCAssoc21_QCPV        		= ISNULL(a.GCAssoc_QCPV,0)
	,gc.GCAssoc21_QDV         		= ISNULL(a.GCAssoc_QDV,0)
	,gc.GCAssoc21_QDV_DV     		= ISNULL(a.GCAssoc_QDV_DV,0)
	,gc.GCAssoc21_PPV_DLV    		= ISNULL(a.GCAssoc_PPV_DLV,0)
	,gc.GCAssoc21_DV_DLVDV			= ISNULL(a.GCAssoc_DV_DLVDV,0)
FROM #GCAAssoc_Volume AS gc 
	INNER JOIN #assoc21 AS a
		ON gc.PK_Distributor = a.PK_Distributor_Assoc AND gc.RoyaltyMonth = a.RoyaltyMonth

UPDATE gc
SET
	gc.GCAssoc21_TV					= ISNULL(a.GCAssoc_TV,0)
	,gc.GCAssoc21_RO				= ISNULL(a.GCAssoc_RO,0)
	,gc.GCAssoc21_PB				= ISNULL(a.GCAssoc_PB,0)
	,gc.GCAssoc21_PV				= ISNULL(a.GCAssoc_PV,0)
	,gc.GCAssoc21_GV 				= ISNULL(a.GCAssoc_GV,0)
	,gc.GCAssoc21_PPV				= ISNULL(a.GCAssoc_PPV,0)
	,gc.GCAssoc21_OV				= ISNULL(a.GCAssoc_OV,0)
	,gc.GCAssoc21_DLV				= ISNULL(a.GCAssoc_DLV,0)
	,gc.GCAssoc21_MPV				= ISNULL(a.GCAssoc_MPV,0)
	,gc.GCAssoc21_MTV				= ISNULL(a.GCAssoc_MTV,0)
	,gc.GCAssoc21_DV				= ISNULL(a.GCAssoc_DV,0)
	,gc.GCAssoc21_PPC				= ISNULL(a.GCAssoc_PPC,0)
	,gc.GCAssoc21_PRV				= ISNULL(a.GCAssoc_PRV,0)
	,gc.GCAssoc21_NDV				= ISNULL(a.GCAssoc_NDV,0)
	,gc.GCAssoc21_SPC				= ISNULL(a.GCAssoc_SPC,0)
	,gc.GCAssoc21_SRV 				= ISNULL(a.GCAssoc_SRV,0)
	,gc.GCAssoc21_PV_DV				= ISNULL(a.GCAssoc_PV_DV,0)
	,gc.GCAssoc21_PV_PPC			= ISNULL(a.GCAssoc_PV_PPC,0)
	,gc.GCAssoc21_PV_PRV 			= ISNULL(a.GCAssoc_PV_PRV,0)
	,gc.GCAssoc21_PV_NDV			= ISNULL(a.GCAssoc_PV_NDV,0)
	,gc.GCAssoc21_PV_SPC			= ISNULL(a.GCAssoc_PV_SPC,0)
	,gc.GCAssoc21_PV_SRV 			= ISNULL(a.GCAssoc_PV_SRV,0)
	,gc.GCAssoc21_DLV_DV			= ISNULL(a.GCAssoc_DLV_DV,0)
	,gc.GCAssoc21_DLV_PPC			= ISNULL(a.GCAssoc_DLV_PPC,0)
	,gc.GCAssoc21_DLV_PRV			= ISNULL(a.GCAssoc_DLV_PRV,0)
	,gc.GCAssoc21_DLV_NDV 			= ISNULL(a.GCAssoc_DLV_NDV,0)
	,gc.GCAssoc21_DLV_SPC 			= ISNULL(a.GCAssoc_DLV_SPC,0)
	,gc.GCAssoc21_DLV_SRV     		= ISNULL(a.GCAssoc_DLV_SRV,0)
	,gc.GCAssoc21_GV_DV       		= ISNULL(a.GCAssoc_GV_DV,0)
	,gc.GCAssoc21_GV_PPC      		= ISNULL(a.GCAssoc_GV_PPC,0)
	,gc.GCAssoc21_GV_PRV      		= ISNULL(a.GCAssoc_GV_PRV,0)
	,gc.GCAssoc21_GV_NDV      		= ISNULL(a.GCAssoc_GV_NDV,0)
	,gc.GCAssoc21_GV_SPC    		= ISNULL(a.GCAssoc_GV_SPC,0)
	,gc.GCAssoc21_GV_SRV   			= ISNULL(a.GCAssoc_GV_SRV,0)
	,gc.GCAssoc21_EV         		= ISNULL(a.GCAssoc_EV,0)
	,gc.GCAssoc21_UV          		= ISNULL(a.GCAssoc_UV,0)
	,gc.GCAssoc21_MPCV       		= ISNULL(a.GCAssoc_MPCV,0)
	,gc.GCAssoc21_TOTAL_POINTS		= ISNULL(a.GCAssoc_TOTAL_POINTS,0)
	,gc.GCAssoc21_QCPV        		= ISNULL(a.GCAssoc_QCPV,0)
	,gc.GCAssoc21_QDV         		= ISNULL(a.GCAssoc_QDV,0)
	,gc.GCAssoc21_QDV_DV     		= ISNULL(a.GCAssoc_QDV_DV,0)
	,gc.GCAssoc21_PPV_DLV    		= ISNULL(a.GCAssoc_PPV_DLV,0)
	,gc.GCAssoc21_DV_DLVDV			= ISNULL(a.GCAssoc_DV_DLVDV,0)
FROM #GCAAssoc_Volume AS gc 
	INNER JOIN #assoc21 AS a
		ON gc.PK_Distributor = a.PK_Distributor_Main AND gc.RoyaltyMonth = a.RoyaltyMonth

UPDATE gc
	SET  
	 gc.GCAssoc_TotalTV				= ISNULL(gc.GCAssoc_TotalTV,0)						+ ISNULL(gc.GCAssoc21_TV,0)
	,gc.GCAssoc_TotalRO				= ISNULL(gc.GCAssoc_TotalRO,0)						+ ISNULL(gc.GCAssoc21_RO,0)
	,gc.GCAssoc_TotalPB				= ISNULL(gc.GCAssoc_TotalPB,0)						+ ISNULL(gc.GCAssoc21_PB,0)
	,gc.GCAssoc_TotalPV				= ISNULL(gc.GCAssoc_TotalPV,0)						+ ISNULL(gc.GCAssoc21_PV,0)
	,gc.GCAssoc_TotalGV 			= ISNULL(gc.GCAssoc_TotalGV,0)						+ ISNULL(gc.GCAssoc21_GV,0)
	,gc.GCAssoc_TotalPPV			= ISNULL(gc.GCAssoc_TotalPPV,0)						+ ISNULL(gc.GCAssoc21_PPV,0)
	,gc.GCAssoc_TotalOV				= ISNULL(gc.GCAssoc_TotalOV,0)						+ ISNULL(gc.GCAssoc21_OV,0)
	,gc.GCAssoc_TotalDLV			= ISNULL(gc.GCAssoc_TotalDLV,0)						+ ISNULL(gc.GCAssoc21_DLV,0)
	,gc.GCAssoc_TotalMPV			= ISNULL(gc.GCAssoc_TotalMPV,0)						+ ISNULL(gc.GCAssoc21_MPV,0)
	,gc.GCAssoc_TotalMTV			= ISNULL(gc.GCAssoc_TotalMTV,0)						+ ISNULL(gc.GCAssoc21_MTV,0)
	,gc.GCAssoc_TotalDV				= ISNULL(gc.GCAssoc_TotalDV,0)						+ ISNULL(gc.GCAssoc21_DV,0)
	,gc.GCAssoc_TotalPPC			= ISNULL(gc.GCAssoc_TotalPPC,0)						+ ISNULL(gc.GCAssoc21_PPC,0)
	,gc.GCAssoc_TotalPRV			= ISNULL(gc.GCAssoc_TotalPRV,0)						+ ISNULL(gc.GCAssoc21_PRV,0)
	,gc.GCAssoc_TotalNDV			= ISNULL(gc.GCAssoc_TotalNDV,0)						+ ISNULL(gc.GCAssoc21_NDV,0)
	,gc.GCAssoc_TotalSPC			= ISNULL(gc.GCAssoc_TotalSPC,0)						+ ISNULL(gc.GCAssoc21_SPC,0)
	,gc.GCAssoc_TotalSRV 			= ISNULL(gc.GCAssoc_TotalSRV,0)						+ ISNULL(gc.GCAssoc21_SRV,0)
	,gc.GCAssoc_TotalPV_DV			= ISNULL(gc.GCAssoc_TotalPV_DV,0)					+ ISNULL(gc.GCAssoc21_PV_DV,0)
	,gc.GCAssoc_TotalPV_PPC			= ISNULL(gc.GCAssoc_TotalPV_PPC,0)					+ ISNULL(gc.GCAssoc21_PV_PPC,0)
	,gc.GCAssoc_TotalPV_PRV 		= ISNULL(gc.GCAssoc_TotalPV_PRV,0)					+ ISNULL(gc.GCAssoc21_PV_PRV,0)
	,gc.GCAssoc_TotalPV_NDV			= ISNULL(gc.GCAssoc_TotalPV_NDV,0)					+ ISNULL(gc.GCAssoc21_PV_NDV,0)
	,gc.GCAssoc_TotalPV_SPC			= ISNULL(gc.GCAssoc_TotalPV_SPC,0)					+ ISNULL(gc.GCAssoc21_PV_SPC,0)
	,gc.GCAssoc_TotalPV_SRV 		= ISNULL(gc.GCAssoc_TotalPV_SRV,0)					+ ISNULL(gc.GCAssoc21_PV_SRV,0)
	,gc.GCAssoc_TotalDLV_DV			= ISNULL(gc.GCAssoc_TotalDLV_DV,0)					+ ISNULL(gc.GCAssoc21_DLV_DV,0)
	,gc.GCAssoc_TotalDLV_PPC		= ISNULL(gc.GCAssoc_TotalDLV_PPC,0)					+ ISNULL(gc.GCAssoc21_DLV_PPC,0)
	,gc.GCAssoc_TotalDLV_PRV		= ISNULL(gc.GCAssoc_TotalDLV_PRV,0)					+ ISNULL(gc.GCAssoc21_DLV_PRV,0)
	,gc.GCAssoc_TotalDLV_NDV 		= ISNULL(gc.GCAssoc_TotalDLV_NDV,0)					+ ISNULL(gc.GCAssoc21_DLV_NDV,0)
	,gc.GCAssoc_TotalDLV_SPC 		= ISNULL(gc.GCAssoc_TotalDLV_SPC,0)					+ ISNULL(gc.GCAssoc21_DLV_SPC,0)
	,gc.GCAssoc_TotalDLV_SRV     	= ISNULL(gc.GCAssoc_TotalDLV_SRV,0)					+ ISNULL(gc.GCAssoc21_DLV_SRV,0)
	,gc.GCAssoc_TotalGV_DV       	= ISNULL(gc.GCAssoc_TotalGV_DV,0)					+ ISNULL(gc.GCAssoc21_GV_DV,0)
	,gc.GCAssoc_TotalGV_PPC      	= ISNULL(gc.GCAssoc_TotalGV_PPC,0)					+ ISNULL(gc.GCAssoc21_GV_PPC,0)
	,gc.GCAssoc_TotalGV_PRV      	= ISNULL(gc.GCAssoc_TotalGV_PRV,0)					+ ISNULL(gc.GCAssoc21_GV_PRV,0)
	,gc.GCAssoc_TotalGV_NDV      	= ISNULL(gc.GCAssoc_TotalGV_NDV,0)					+ ISNULL(gc.GCAssoc21_GV_NDV,0)
	,gc.GCAssoc_TotalGV_SPC    		= ISNULL(gc.GCAssoc_TotalGV_SPC,0)					+ ISNULL(gc.GCAssoc21_GV_SPC,0)
	,gc.GCAssoc_TotalGV_SRV   		= ISNULL(gc.GCAssoc_TotalGV_SRV,0)					+ ISNULL(gc.GCAssoc21_GV_SRV,0)
	,gc.GCAssoc_TotalEV         	= ISNULL(gc.GCAssoc_TotalEV,0)						+ ISNULL(gc.GCAssoc21_EV,0)
	,gc.GCAssoc_TotalUV          	= ISNULL(gc.GCAssoc_TotalUV,0)						+ ISNULL(gc.GCAssoc21_UV,0)
	,gc.GCAssoc_TotalMPCV       	= ISNULL(gc.GCAssoc_TotalMPCV,0)					+ ISNULL(gc.GCAssoc21_MPCV,0)
	,gc.GCAssoc_TotalTOTAL_POINTS	= ISNULL(gc.GCAssoc_TotalTOTAL_POINTS,0)			+ ISNULL(gc.GCAssoc21_TOTAL_POINTS,0)
	,gc.GCAssoc_TotalQCPV        	= ISNULL(gc.GCAssoc_TotalQCPV,0)					+ ISNULL(gc.GCAssoc21_QCPV,0)
	,gc.GCAssoc_TotalQDV         	= ISNULL(gc.GCAssoc_TotalQDV,0)						+ ISNULL(gc.GCAssoc21_QDV,0)
	,gc.GCAssoc_TotalQDV_DV     	= ISNULL(gc.GCAssoc_TotalQDV_DV,0)					+ ISNULL(gc.GCAssoc21_QDV_DV,0)
	,gc.GCAssoc_TotalPPV_DLV    	= ISNULL(gc.GCAssoc_TotalPPV_DLV,0)					+ ISNULL(gc.GCAssoc21_PPV_DLV,0)
	,gc.GCAssoc_TotalDV_DLVDV		= ISNULL(gc.GCAssoc_TotalDV_DLVDV,0)				+ ISNULL(gc.GCAssoc21_DV_DLVDV,0)
FROM #GCAAssoc_Volume AS gc 	 

UPDATE #GCAAssoc_Volume 
SET IsValidRecord = case when [TV]=(0) AND [RO]=(0) AND [PB]=(0) AND [PPV]=(0) AND [MainTV]=(0) AND [MainRO]=(0) AND [MainPB]=(0) AND [MainPPV]=(0) AND [DLV]=(0) AND [MainDLV]=(0) AND [MPV]=(0) AND [MTV]=(0) AND [MainMPV]=(0) AND [MainMTV]=(0) AND [DV]=(0) AND [MPCV]=(0) AND [TOTAL_POINTS]=(0) AND [QCPV]=(0) AND [QDV]=(0) AND [QDV_DV]=(0) AND [PPV_DLV]=(0) AND [DV_DLVDV]=(0) AND [MainMPCV]=(0) AND [MainTOTAL_POINTS]=(0) AND [MainQCPV]=(0) AND [MainQDV]=(0) AND [MainQDV_DV]=(0) AND [MainPPV_DLV]=(0) AND [MainDV_DLVDV]=(0) AND [GCAssoc_TV]=(0) AND [GCAssoc_RO]=(0) AND [GCAssoc_PB]=(0) AND [GCAssoc_PPV]=(0) AND [GCAssoc_DLV]=(0) AND [GCAssoc_MPV]=(0) AND [GCAssoc_MTV]=(0) AND [GCAssoc_MPCV]=(0) AND [GCAssoc_TOTAL_POINTS]=(0) AND [GCAssoc_QCPV]=(0) AND [GCAssoc_QDV]=(0) AND [GCAssoc_QDV_DV]=(0) AND [GCAssoc_PPV_DLV]=(0) AND [GCAssoc_DV_DLVDV]=(0) then (0) else (1) end

DELETE #GCAAssoc_Volume WHERE IsValidRecord = 0


DROP TABLE IF EXISTS #GCAAssoc_Volume_Details

SELECT
		GETUTCDATE() LastModifiedDate, 
		RoyaltyMonth, 
		do.nDistributorID AS [PK_Distributor],
		do.sDistributorID AS [DistributorID], 
		NULL DeletedDate, 
		NULL Qual_SPDate, 
		NULL Qual_QSDate, 
		NULL Qual_QSDate_Actual, 
		NULL Team, 
		NULL COP, 
		NULL IsAssocType23, 
		NULL IsMainID, 
		NULL IsInAssocTable, 
		0 AS TV, 
		0 AS RO, 
		0 AS PB, 
		0 AS PV, 
		0 AS GV, 
		0 AS PPV, 
		0 AS OV, 
		NULL PK_MainDistributor, 
		NULL MainDistributorID, 
		NULL MainDeletedDate, 
		NULL MainQual_SPDate, 
		NULL MainQual_QSDate, 
		NULL MainQual_QSDate_Actual, 
		NULL MainTeam, 
		NULL MainCOP, 
		NULL MainIsType23, 
		0 AS MainTV, 
		0 AS MainRO, 
		0 AS MainPB, 
		0 AS MainPV, 
		0 AS MainGV, 
		0 AS MainPPV, 
		0 AS MainOV, 
		0 AS DLV, 
		0 AS MainDLV, 
		0 AS MPV, 
		0 AS MTV, 
		0 AS MainMPV, 
		0 AS MainMTV, 
		0 AS DV, 
		0 AS PPC, 
		0 AS PRV, 
		0 AS NDV, 
		0 AS SPC, 
		0 AS SRV, 
		0 AS PV_DV, 
		0 AS PV_PPC, 
		0 AS PV_PRV, 
		0 AS PV_NDV, 
		0 AS PV_SPC, 
		0 AS PV_SRV, 
		0 AS DLV_DV, 
		0 AS DLV_PPC, 
		0 AS DLV_PRV, 
		0 AS DLV_NDV, 
		0 AS DLV_SPC, 
		0 AS DLV_SRV, 
		0 AS GV_DV, 
		0 AS GV_PPC, 
		0 AS GV_PRV, 
		0 AS GV_NDV, 
		0 AS GV_SPC, 
		0 AS GV_SRV, 
		0 AS EV, 
		0 AS UV, 
		0 AS MPCV,
		0 AS TOTAL_POINTS,
		0 AS QCPV,
		0 AS QDV,
		0 AS QDV_DV,
		0 AS PPV_DLV,
		0 AS DV_DLVDV,		  
		0 AS MainDV, 
		0 AS MainPPC, 
		0 AS MainPRV, 
		0 AS MainNDV, 
		0 AS MainSPC, 
		0 AS MainSRV, 
		0 AS MainPV_DV, 
		0 AS MainPV_PPC, 
		0 AS MainPV_PRV, 
		0 AS MainPV_NDV, 
		0 AS MainPV_SPC, 
		0 AS MainPV_SRV, 
		0 AS MainDLV_DV, 
		0 AS MainDLV_PPC, 
		0 AS MainDLV_PRV, 
		0 AS MainDLV_NDV, 
		0 AS MainDLV_SPC, 
		0 AS MainDLV_SRV, 
		0 AS MainGV_DV, 
		0 AS MainGV_PPC, 
		0 AS MainGV_PRV, 
		0 AS MainGV_NDV, 
		0 AS MainGV_SPC, 
		0 AS MainGV_SRV, 
		0 AS MainEV, 
		0 AS MainUV,
		0 AS MainMPCV,
		0 AS MainTOTAL_POINTS,
		0 AS MainQCPV,
		0 AS MainQDV,
		0 AS MainQDV_DV,
		0 AS MainPPV_DLV,
		0 AS MainDV_DLVDV,
		--Greater China
		 da.nDistributorID AS [PK_GCAssoc_Distributor]
		,da.sDistributorID AS [GCAssoc_DistributorID] 
		,[GCAssoc_TotalTV]           AS [GCAssoc_TV]           
		,[GCAssoc_TotalRO]           AS [GCAssoc_RO]           
		,[GCAssoc_TotalPB]           AS [GCAssoc_PB]           
		,[GCAssoc_TotalPV]           AS [GCAssoc_PV]           
		,[GCAssoc_TotalGV]           AS [GCAssoc_GV]           
		,[GCAssoc_TotalPPV]          AS [GCAssoc_PPV]          
		,[GCAssoc_TotalOV]           AS [GCAssoc_OV]           
		,[GCAssoc_TotalDLV]          AS [GCAssoc_DLV]          
		,[GCAssoc_TotalMPV]          AS [GCAssoc_MPV]          
		,[GCAssoc_TotalMTV]          AS [GCAssoc_MTV]          
		,[GCAssoc_TotalDV]           AS [GCAssoc_DV]           
		,[GCAssoc_TotalPPC]          AS [GCAssoc_PPC]          
		,[GCAssoc_TotalPRV]          AS [GCAssoc_PRV]          
		,[GCAssoc_TotalNDV]          AS [GCAssoc_NDV]          
		,[GCAssoc_TotalSPC]          AS [GCAssoc_SPC]          
		,[GCAssoc_TotalSRV]          AS [GCAssoc_SRV]          
		,[GCAssoc_TotalPV_DV]        AS [GCAssoc_PV_DV]        
		,[GCAssoc_TotalPV_PPC]       AS [GCAssoc_PV_PPC]       
		,[GCAssoc_TotalPV_PRV]       AS [GCAssoc_PV_PRV]       
		,[GCAssoc_TotalPV_NDV]       AS [GCAssoc_PV_NDV]       
		,[GCAssoc_TotalPV_SPC]       AS [GCAssoc_PV_SPC]       
		,[GCAssoc_TotalPV_SRV]       AS [GCAssoc_PV_SRV]       
		,[GCAssoc_TotalDLV_DV]       AS [GCAssoc_DLV_DV]       
		,[GCAssoc_TotalDLV_PPC]      AS [GCAssoc_DLV_PPC]      
		,[GCAssoc_TotalDLV_PRV]      AS [GCAssoc_DLV_PRV]      
		,[GCAssoc_TotalDLV_NDV]      AS [GCAssoc_DLV_NDV]      
		,[GCAssoc_TotalDLV_SPC]      AS [GCAssoc_DLV_SPC]      
		,[GCAssoc_TotalDLV_SRV]      AS [GCAssoc_DLV_SRV]      
		,[GCAssoc_TotalGV_DV]        AS [GCAssoc_GV_DV]        
		,[GCAssoc_TotalGV_PPC]       AS [GCAssoc_GV_PPC]       
		,[GCAssoc_TotalGV_PRV]       AS [GCAssoc_GV_PRV]       
		,[GCAssoc_TotalGV_NDV]       AS [GCAssoc_GV_NDV]       
		,[GCAssoc_TotalGV_SPC]       AS [GCAssoc_GV_SPC]       
		,[GCAssoc_TotalGV_SRV]       AS [GCAssoc_GV_SRV]       
		,[GCAssoc_TotalEV]           AS [GCAssoc_EV]           
		,[GCAssoc_TotalUV]           AS [GCAssoc_UV]           
		,[GCAssoc_TotalMPCV]         AS [GCAssoc_MPCV]         
		,[GCAssoc_TotalTOTAL_POINTS] AS [GCAssoc_TOTAL_POINTS] 
		,[GCAssoc_TotalQCPV]         AS [GCAssoc_QCPV]         
		,[GCAssoc_TotalQDV]          AS [GCAssoc_QDV]          
		,[GCAssoc_TotalQDV_DV]       AS [GCAssoc_QDV_DV]       
		,[GCAssoc_TotalPPV_DLV]      AS [GCAssoc_PPV_DLV]      
		,[GCAssoc_TotalDV_DLVDV]   	AS [GCAssoc_DV_DLVDV]   
		INTO #GCAAssoc_Volume_Details
		FROM #GCAAssoc_Volume AS gc
			INNER JOIN v_Distributor AS do
			ON do.nDistributorID = gc.PK_Distributor 
			INNER JOIN v_Distributor AS da
			ON da.nDistributorID = gc.PK_AssociatedID 

IF @IsDevQA = 0
BEGIN
	 
MERGE INTO dbo.wrkDSFinancial t
USING #GCAAssoc_Volume_Details AS s
	ON t.PK_Distributor = s.PK_Distributor AND t.RoyaltyMonth = s.RoyaltyMonth  
WHEN NOT MATCHED THEN 
	INSERT 
	(
		LastModifiedDate, 
		RoyaltyMonth, 
		PK_Distributor, 
		DistributorID, 
		DeletedDate, 
		Qual_SPDate, 
		Qual_QSDate, 
		Qual_QSDate_Actual, 
		Team, 
		COP, 
		IsAssocType23, 
		IsMainID, 
		IsInAssocTable, 
		TV, 
		RO, 
		PB, 
		PV, 
		GV, 
		PPV, 
		OV, 
		PK_MainDistributor, 
		MainDistributorID, 
		MainDeletedDate, 
		MainQual_SPDate, 
		MainQual_QSDate, 
		MainQual_QSDate_Actual, 
		MainTeam, 
		MainCOP, 
		MainIsType23, 
		MainTV, 
		MainRO, 
		MainPB, 
		MainPV, 
		MainGV, 
		MainPPV, 
		MainOV, 
		DLV, 
		MainDLV, 
		MPV, 
		MTV, 
		MainMPV, 
		MainMTV, 
		DV, 
		PPC, 
		PRV, 
		NDV, 
		SPC, 
		SRV, 
		PV_DV, 
		PV_PPC, 
		PV_PRV, 
		PV_NDV, 
		PV_SPC, 
		PV_SRV, 
		DLV_DV, 
		DLV_PPC, 
		DLV_PRV, 
		DLV_NDV, 
		DLV_SPC, 
		DLV_SRV, 
		GV_DV, 
		GV_PPC, 
		GV_PRV, 
		GV_NDV, 
		GV_SPC, 
		GV_SRV, 
		EV, 
		UV, 
		MPCV,
		TOTAL_POINTS,
		QCPV,
		QDV,
		QDV_DV,
		PPV_DLV,
		DV_DLVDV,		
		MainDV, 
		MainPPC, 
		MainPRV, 
		MainNDV, 
		MainSPC, 
		MainSRV, 
		MainPV_DV, 
		MainPV_PPC, 
		MainPV_PRV, 
		MainPV_NDV, 
		MainPV_SPC, 
		MainPV_SRV, 
		MainDLV_DV, 
		MainDLV_PPC, 
		MainDLV_PRV, 
		MainDLV_NDV, 
		MainDLV_SPC, 
		MainDLV_SRV, 
		MainGV_DV, 
		MainGV_PPC, 
		MainGV_PRV, 
		MainGV_NDV, 
		MainGV_SPC, 
		MainGV_SRV, 
		MainEV, 
		MainUV,
		MainMPCV,
		MainTOTAL_POINTS,
		MainQCPV,
		MainQDV,
		MainQDV_DV,
		MainPPV_DLV,
		MainDV_DLVDV,
		--Greater China
		[PK_GCAssoc_Distributor]
		,[GCAssoc_DistributorID] 
		,[GCAssoc_TV]           
		,[GCAssoc_RO]           
		,[GCAssoc_PB]           
		,[GCAssoc_PV]           
		,[GCAssoc_GV]           
		,[GCAssoc_PPV]          
		,[GCAssoc_OV]           
		,[GCAssoc_DLV]          
		,[GCAssoc_MPV]          
		,[GCAssoc_MTV]          
		,[GCAssoc_DV]           
		,[GCAssoc_PPC]          
		,[GCAssoc_PRV]          
		,[GCAssoc_NDV]          
		,[GCAssoc_SPC]          
		,[GCAssoc_SRV]          
		,[GCAssoc_PV_DV]        
		,[GCAssoc_PV_PPC]       
		,[GCAssoc_PV_PRV]       
		,[GCAssoc_PV_NDV]       
		,[GCAssoc_PV_SPC]       
		,[GCAssoc_PV_SRV]       
		,[GCAssoc_DLV_DV]       
		,[GCAssoc_DLV_PPC]      
		,[GCAssoc_DLV_PRV]      
		,[GCAssoc_DLV_NDV]      
		,[GCAssoc_DLV_SPC]      
		,[GCAssoc_DLV_SRV]      
		,[GCAssoc_GV_DV]        
		,[GCAssoc_GV_PPC]       
		,[GCAssoc_GV_PRV]       
		,[GCAssoc_GV_NDV]       
		,[GCAssoc_GV_SPC]       
		,[GCAssoc_GV_SRV]       
		,[GCAssoc_EV]           
		,[GCAssoc_UV]           
		,[GCAssoc_MPCV]         
		,[GCAssoc_TOTAL_POINTS] 
		,[GCAssoc_QCPV]         
		,[GCAssoc_QDV]          
		,[GCAssoc_QDV_DV]       
		,[GCAssoc_PPV_DLV]      
		,[GCAssoc_DV_DLVDV]  	
	)
	VALUES 
	(
		LastModifiedDate, 
		RoyaltyMonth, 
		PK_Distributor,  
		DistributorID, 
		DeletedDate, 
		Qual_SPDate, 
		Qual_QSDate, 
		Qual_QSDate_Actual, 
		Team, 
		COP, 
		IsAssocType23, 
		IsMainID, 
		IsInAssocTable, 
		TV, 
		RO, 
		PB, 
		PV, 
		GV, 
		PPV, 
		OV, 
		PK_MainDistributor, 
		MainDistributorID, 
		MainDeletedDate, 
		MainQual_SPDate, 
		MainQual_QSDate, 
		MainQual_QSDate_Actual, 
		MainTeam, 
		MainCOP, 
		MainIsType23, 
		MainTV, 
		MainRO, 
		MainPB, 
		MainPV, 
		MainGV, 
		MainPPV, 
		MainOV, 
		DLV, 
		MainDLV, 
		MPV, 
		MTV, 
		MainMPV, 
		MainMTV, 
		DV, 
		PPC, 
		PRV, 
		NDV, 
		SPC, 
		SRV, 
		PV_DV, 
		PV_PPC, 
		PV_PRV, 
		PV_NDV, 
		PV_SPC, 
		PV_SRV, 
		DLV_DV, 
		DLV_PPC, 
		DLV_PRV, 
		DLV_NDV, 
		DLV_SPC, 
		DLV_SRV, 
		GV_DV, 
		GV_PPC, 
		GV_PRV, 
		GV_NDV, 
		GV_SPC, 
		GV_SRV, 
		EV, 
		UV, 
		MPCV,
		TOTAL_POINTS,
		QCPV,
		QDV,
		QDV_DV,
		PPV_DLV,
		DV_DLVDV,		  
		MainDV, 
		MainPPC, 
		MainPRV, 
		MainNDV, 
		MainSPC, 
		MainSRV, 
		MainPV_DV, 
		MainPV_PPC, 
		MainPV_PRV, 
		MainPV_NDV, 
		MainPV_SPC, 
		MainPV_SRV, 
		MainDLV_DV, 
		MainDLV_PPC, 
		MainDLV_PRV, 
		MainDLV_NDV, 
		MainDLV_SPC, 
		MainDLV_SRV, 
		MainGV_DV, 
		MainGV_PPC, 
		MainGV_PRV, 
		MainGV_NDV, 
		MainGV_SPC, 
		MainGV_SRV, 
		MainEV, 
		MainUV,
		MainMPCV,
		MainTOTAL_POINTS,
		MainQCPV,
		MainQDV,
		MainQDV_DV,
		MainPPV_DLV,
		MainDV_DLVDV,
		--Greater China
		s.[PK_GCAssoc_Distributor]
		,s.[GCAssoc_DistributorID] 
		,s.[GCAssoc_TV]           
		,s.[GCAssoc_RO]           
		,s.[GCAssoc_PB]           
		,s.[GCAssoc_PV]           
		,s.[GCAssoc_GV]           
		,s.[GCAssoc_PPV]          
		,s.[GCAssoc_OV]           
		,s.[GCAssoc_DLV]          
		,s.[GCAssoc_MPV]          
		,s.[GCAssoc_MTV]          
		,s.[GCAssoc_DV]           
		,s.[GCAssoc_PPC]          
		,s.[GCAssoc_PRV]          
		,s.[GCAssoc_NDV]          
		,s.[GCAssoc_SPC]          
		,s.[GCAssoc_SRV]          
		,s.[GCAssoc_PV_DV]        
		,s.[GCAssoc_PV_PPC]       
		,s.[GCAssoc_PV_PRV]       
		,s.[GCAssoc_PV_NDV]       
		,s.[GCAssoc_PV_SPC]       
		,s.[GCAssoc_PV_SRV]       
		,s.[GCAssoc_DLV_DV]       
		,s.[GCAssoc_DLV_PPC]      
		,s.[GCAssoc_DLV_PRV]      
		,s.[GCAssoc_DLV_NDV]      
		,s.[GCAssoc_DLV_SPC]      
		,s.[GCAssoc_DLV_SRV]      
		,s.[GCAssoc_GV_DV]        
		,s.[GCAssoc_GV_PPC]       
		,s.[GCAssoc_GV_PRV]       
		,s.[GCAssoc_GV_NDV]       
		,s.[GCAssoc_GV_SPC]       
		,s.[GCAssoc_GV_SRV]       
		,s.[GCAssoc_EV]           
		,s.[GCAssoc_UV]           
		,s.[GCAssoc_MPCV]         
		,s.[GCAssoc_TOTAL_POINTS] 
		,s.[GCAssoc_QCPV]         
		,s.[GCAssoc_QDV]          
		,s.[GCAssoc_QDV_DV]       
		,s.[GCAssoc_PPV_DLV]      
		,s.[GCAssoc_DV_DLVDV]   
)
WHEN MATCHED AND ( 
		--Greater China
		 t.[PK_GCAssoc_Distributor] <> s.[PK_GCAssoc_Distributor] 
		OR t.[GCAssoc_DistributorID] <> s.[GCAssoc_DistributorID] 
		OR ISNULL(t.[GCAssoc_TV],0) <> ISNULL(s.[GCAssoc_TV],0)
		OR ISNULL(t.[GCAssoc_RO],0) <> ISNULL(s.[GCAssoc_RO],0)
		OR ISNULL(t.[GCAssoc_PB],0) <> ISNULL(s.[GCAssoc_PB],0)
		OR ISNULL(t.[GCAssoc_PV],0) <> ISNULL(s.[GCAssoc_PV],0)
		OR ISNULL(t.[GCAssoc_GV],0) <> ISNULL(s.[GCAssoc_GV],0)
		OR ISNULL(t.[GCAssoc_PPV],0) <> ISNULL(s.[GCAssoc_PPV],0)
		OR ISNULL(t.[GCAssoc_OV],0) <> ISNULL(s.[GCAssoc_OV],0)
		OR ISNULL(t.[GCAssoc_DLV],0) <> ISNULL(s.[GCAssoc_DLV],0)
		OR ISNULL(t.[GCAssoc_MPV],0) <> ISNULL(s.[GCAssoc_MPV],0)
		OR ISNULL(t.[GCAssoc_MTV],0) <> ISNULL(s.[GCAssoc_MTV],0)
		OR ISNULL(t.[GCAssoc_DV],0) <> ISNULL(s.[GCAssoc_DV],0)
		OR ISNULL(t.[GCAssoc_PPC],0) <> ISNULL(s.[GCAssoc_PPC],0)
		OR ISNULL(t.[GCAssoc_PRV],0) <> ISNULL(s.[GCAssoc_PRV],0)
		OR ISNULL(t.[GCAssoc_NDV],0) <> ISNULL(s.[GCAssoc_NDV],0)
		OR ISNULL(t.[GCAssoc_SPC],0) <> ISNULL(s.[GCAssoc_SPC],0)
		OR ISNULL(t.[GCAssoc_SRV],0) <> ISNULL(s.[GCAssoc_SRV],0)
		OR ISNULL(t.[GCAssoc_PV_DV],0) <> ISNULL(s.[GCAssoc_PV_DV],0)
		OR ISNULL(t.[GCAssoc_PV_PPC],0) <> ISNULL(s.[GCAssoc_PV_PPC],0)
		OR ISNULL(t.[GCAssoc_PV_PRV],0) <> ISNULL(s.[GCAssoc_PV_PRV],0)
		OR ISNULL(t.[GCAssoc_PV_NDV],0) <> ISNULL(s.[GCAssoc_PV_NDV] ,0)
		OR ISNULL(t.[GCAssoc_PV_SPC],0) <> ISNULL(s.[GCAssoc_PV_SPC],0)
		OR ISNULL(t.[GCAssoc_PV_SRV],0) <> ISNULL(s.[GCAssoc_PV_SRV],0)
		OR ISNULL(t.[GCAssoc_DLV_DV],0) <> ISNULL(s.[GCAssoc_DLV_DV],0)
		OR ISNULL(t.[GCAssoc_DLV_PPC],0) <> ISNULL(s.[GCAssoc_DLV_PPC],0)
		OR ISNULL(t.[GCAssoc_DLV_PRV],0) <> ISNULL(s.[GCAssoc_DLV_PRV],0)
		OR ISNULL(t.[GCAssoc_DLV_NDV],0) <> ISNULL(s.[GCAssoc_DLV_NDV],0)
		OR ISNULL(t.[GCAssoc_DLV_SPC],0) <> ISNULL(s.[GCAssoc_DLV_SPC],0)
		OR ISNULL(t.[GCAssoc_DLV_SRV],0) <> ISNULL(s.[GCAssoc_DLV_SRV],0)
		OR ISNULL(t.[GCAssoc_GV_DV],0) <> ISNULL(s.[GCAssoc_GV_DV],0)
		OR ISNULL(t.[GCAssoc_GV_PPC],0) <> ISNULL(s.[GCAssoc_GV_PPC],0)
		OR ISNULL(t.[GCAssoc_GV_PRV],0) <> ISNULL(s.[GCAssoc_GV_PRV],0)
		OR ISNULL(t.[GCAssoc_GV_NDV],0) <> ISNULL(s.[GCAssoc_GV_NDV],0)
		OR ISNULL(t.[GCAssoc_GV_SPC],0) <> ISNULL(s.[GCAssoc_GV_SPC],0)
		OR ISNULL(t.[GCAssoc_GV_SRV],0) <> ISNULL(s.[GCAssoc_GV_SRV],0)
		OR ISNULL(t.[GCAssoc_EV],0) <> ISNULL(s.[GCAssoc_EV],0)
		OR ISNULL(t.[GCAssoc_UV],0) <> ISNULL(s.[GCAssoc_UV],0)
		OR ISNULL(t.[GCAssoc_MPCV],0) <> ISNULL(s.[GCAssoc_MPCV],0)
		OR ISNULL(t.[GCAssoc_TOTAL_POINTS] ,0) <> ISNULL(s.[GCAssoc_TOTAL_POINTS] ,0)
		OR ISNULL(t.[GCAssoc_QCPV],0) <> ISNULL(s.[GCAssoc_QCPV],0)
		OR ISNULL(t.[GCAssoc_QDV],0) <> ISNULL(s.[GCAssoc_QDV],0)
		OR ISNULL(t.[GCAssoc_QDV_DV],0) <> ISNULL(s.[GCAssoc_QDV_DV],0)
		OR ISNULL(t.[GCAssoc_PPV_DLV],0) <> ISNULL(s.[GCAssoc_PPV_DLV],0)
		OR ISNULL(t.[GCAssoc_DV_DLVDV],0) <> ISNULL(s.[GCAssoc_DV_DLVDV],0))
	THEN 
	UPDATE
		SET 
		--Greater China
		t.[PK_GCAssoc_Distributor] = s.[PK_GCAssoc_Distributor] 
		,t.[GCAssoc_DistributorID] = s.[GCAssoc_DistributorID] 
		,t.[GCAssoc_TV]			= s.[GCAssoc_TV]
		,t.[GCAssoc_RO]			= s.[GCAssoc_RO]
		,t.[GCAssoc_PB]           = s.[GCAssoc_PB]           
		,t.[GCAssoc_PV]           = s.[GCAssoc_PV]           
		,t.[GCAssoc_GV]           = s.[GCAssoc_GV]           
		,t.[GCAssoc_PPV]          = s.[GCAssoc_PPV]          
		,t.[GCAssoc_OV]           = s.[GCAssoc_OV]           
		,t.[GCAssoc_DLV]          = s.[GCAssoc_DLV]          
		,t.[GCAssoc_MPV]          = s.[GCAssoc_MPV]          
		,t.[GCAssoc_MTV]          = s.[GCAssoc_MTV]          
		,t.[GCAssoc_DV]           = s.[GCAssoc_DV]           
		,t.[GCAssoc_PPC]          = s.[GCAssoc_PPC]          
		,t.[GCAssoc_PRV]          = s.[GCAssoc_PRV]          
		,t.[GCAssoc_NDV]          = s.[GCAssoc_NDV]          
		,t.[GCAssoc_SPC]          = s.[GCAssoc_SPC]          
		,t.[GCAssoc_SRV]          = s.[GCAssoc_SRV]          
		,t.[GCAssoc_PV_DV]        = s.[GCAssoc_PV_DV]        
		,t.[GCAssoc_PV_PPC]       = s.[GCAssoc_PV_PPC]       
		,t.[GCAssoc_PV_PRV]       = s.[GCAssoc_PV_PRV]       
		,t.[GCAssoc_PV_NDV]       = s.[GCAssoc_PV_NDV]       
		,t.[GCAssoc_PV_SPC]       = s.[GCAssoc_PV_SPC]       
		,t.[GCAssoc_PV_SRV]       = s.[GCAssoc_PV_SRV]       
		,t.[GCAssoc_DLV_DV]       = s.[GCAssoc_DLV_DV]       
		,t.[GCAssoc_DLV_PPC]      = s.[GCAssoc_DLV_PPC]      
		,t.[GCAssoc_DLV_PRV]      = s.[GCAssoc_DLV_PRV]      
		,t.[GCAssoc_DLV_NDV]      = s.[GCAssoc_DLV_NDV]      
		,t.[GCAssoc_DLV_SPC]      = s.[GCAssoc_DLV_SPC]      
		,t.[GCAssoc_DLV_SRV]      = s.[GCAssoc_DLV_SRV]      
		,t.[GCAssoc_GV_DV]        = s.[GCAssoc_GV_DV]        
		,t.[GCAssoc_GV_PPC]       = s.[GCAssoc_GV_PPC]       
		,t.[GCAssoc_GV_PRV]       = s.[GCAssoc_GV_PRV]       
		,t.[GCAssoc_GV_NDV]       = s.[GCAssoc_GV_NDV]       
		,t.[GCAssoc_GV_SPC]       = s.[GCAssoc_GV_SPC]       
		,t.[GCAssoc_GV_SRV]       = s.[GCAssoc_GV_SRV]       
		,t.[GCAssoc_EV]           = s.[GCAssoc_EV]           
		,t.[GCAssoc_UV]           = s.[GCAssoc_UV]           
		,t.[GCAssoc_MPCV]         = s.[GCAssoc_MPCV]         
		,t.[GCAssoc_TOTAL_POINTS] = s.[GCAssoc_TOTAL_POINTS] 
		,t.[GCAssoc_QCPV]         = s.[GCAssoc_QCPV]         
		,t.[GCAssoc_QDV]          = s.[GCAssoc_QDV]          
		,t.[GCAssoc_QDV_DV]       = s.[GCAssoc_QDV_DV]       
		,t.[GCAssoc_PPV_DLV]      = s.[GCAssoc_PPV_DLV]      
		,t.[GCAssoc_DV_DLVDV]  	= s.[GCAssoc_DV_DLVDV]   
OPTION (RECOMPILE);
 
--General info, for those records created based on GC association

UPDATE F1
	SET DeletedDate = CASE WHEN ST.StatusCode = 'COMPLETE' THEN '2049-12-31' ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.DeletedDate),112) END  
	,Team = DT.TeamCode
	,Qual_SPDate = CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.SPQualDate),112) < '1980-01-01' THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.SPQualDate),112) END  
	,Qual_QSDate = CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) < '1980-01-01' THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) END  
	,Qual_QSDate_Actual = CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) < '1980-01-01' THEN NULL ELSE DATEADD(M,DATEDIFF(M,0,CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112)),0) END  
	,COP = DC.CountryCode  
FROM  dbo.wrkDSFinancial AS F1
INNER MERGE JOIN
	#WRK_DimDistributor D (NOLOCK)
ON 	F1.PK_Distributor = D.PK_Distributor
LEFT JOIN
	pubEvents.dbo.dimDSTeam DT (NOLOCK)
ON  D.PK_DSTeam = DT.PK_DSTeam
LEFT JOIN
	pubEvents.dbo.dimCountry DC (NOLOCK)
ON  D.PK_COP = DC.PK_Country
LEFT JOIN
	pubEvents.dbo.dimDSStatus ST (NOLOCK)
ON	D.PK_DSStatus = ST.PK_DSStatus
WHERE F1.[PK_GCAssoc_Distributor] IS NOT NULL
OPTION (RECOMPILE)

--Main association for all records.

UPDATE F1 
	SET PK_MainDistributor =  ISNULL(D.nMainDistributorID,F1.PK_Distributor)
	 ,MainIsType23 = IIF(D.PK_Distributor IS NULL,0,1)
	 ,IsAssocType23 = IIF(D.PK_Distributor IS NULL,0,1)
	 ,IsMainID = IIF(D.AssociationType = 3 AND D.nMainDistributorID = F1.PK_Distributor,1,0) --AssociationType 2 never mark any DS as MainID since both must qualify to AWT and others events
	 ,IsInAssocTable = IIF(D.PK_Distributor IS NULL,0,1)
FROM  dbo.wrkDSFinancial AS F1
	LEFT JOIN [PubEventManagement].[Shared].[DistributorAssociation] D (NOLOCK)
		ON 	F1.PK_Distributor = D.PK_Distributor
OPTION (RECOMPILE)

UPDATE F1 
	SET PK_MainDistributor =  nMainDistributorID
	 ,MainIsType23 = 1
	 ,IsAssocType23 = 1
	 ,IsMainID = 1
	 ,IsInAssocTable = 1
FROM  dbo.wrkDSFinancial AS F1
	INNER JOIN [PubEventManagement].[Shared].[DistributorAssociation] D (NOLOCK)
		ON 	F1.PK_Distributor = D.nMainDistributorID
OPTION (RECOMPILE)

--Main association details for those records created based on GC association
UPDATE
	F
SET
	MainDistributorID = D.DistributorID
	,MainDeletedDate = CASE WHEN ST.StatusCode = 'COMPLETE' THEN '2049-12-31' ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.DeletedDate),112) END
	,MainTeam = DT.TeamCode
	,MainQual_SPDate = CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.SPQualDate),112) < '1980-01-01' THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.SPQualDate),112) END
	,MainQual_QSDate_Actual = CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) < '1980-01-01' THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) END
	,MainQual_QSDate = CASE WHEN CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112) < '1980-01-01' THEN NULL ELSE DATEADD(M,DATEDIFF(M,0,CONVERT(DATETIME,CONVERT(VARCHAR,D.QSQualDate),112)),0) END
	,MainCOP = DC.CountryCode
FROM
	dbo.wrkDSFinancial F
INNER JOIN
	#WRK_DimDistributor D (NOLOCK)
ON 	F.PK_MainDistributor = D.PK_Distributor
LEFT JOIN
	pubEvents.dbo.dimDSTeam DT (NOLOCK)
ON  D.PK_DSTeam = DT.PK_DSTeam
LEFT JOIN
	pubEvents.dbo.dimCountry DC (NOLOCK)
ON  D.PK_COP = DC.PK_Country
LEFT JOIN
	pubEvents.dbo.dimDSStatus ST (NOLOCK)
ON	D.PK_DSStatus = ST.PK_DSStatus 
WHERE F.[PK_GCAssoc_Distributor] IS NOT NULL

END  
 
--Considering GC volume from MainID associated to GC Association in case of Divorce cases

IF @IsDevQA = 0
BEGIN

DROP TABLE IF EXISTS #GCAAssoc_Volume_DivorceAssType3_Main
 
 SELECT 
	C2.PK_Distributor
	,C2.RoyaltyMonth
	,MainTV					=	ISNULL(C2.GCAssoc_TV,0)				+ ISNULL(C2.TV,0) 
	,MainRO					=	ISNULL(C2.GCAssoc_RO,0)				+ ISNULL(C2.RO,0) 
	,MainPB					=	ISNULL(C2.GCAssoc_PB,0)				+ ISNULL(C2.PB,0) 
	,MainPV					=	ISNULL(C2.GCAssoc_PV,0)				+ ISNULL(C2.PV,0) 
	,MainGV					=	ISNULL(C2.GCAssoc_GV,0)				+ ISNULL(C2.GV,0) 
	,MainPPV				=	ISNULL(C2.GCAssoc_PPV,0)			+ ISNULL(C2.PPV,0) 
	,MainOV					=	ISNULL(C2.GCAssoc_OV,0)				+ ISNULL(C2.OV,0) 
    ,MainDLV				=	ISNULL(C2.GCAssoc_DLV,0)			+ ISNULL(C2.DLV,0) 
	,MainMPV 				=	ISNULL(C2.GCAssoc_MPV,0) 			+ ISNULL(C2.MPV,0) 
	,MainMTV  				=	ISNULL(C2.GCAssoc_MTV,0)  			+ ISNULL(C2.MTV,0) 
	,MainDV					=	ISNULL(C2.GCAssoc_DV,0)				+ ISNULL(C2.DV,0) 
	,MainPPC				=	ISNULL(C2.GCAssoc_PPC,0)			+ ISNULL(C2.PPC,0) 
	,MainPRV				=	ISNULL(C2.GCAssoc_PRV,0)			+ ISNULL(C2.PRV,0) 
	,MainNDV				=	ISNULL(C2.GCAssoc_NDV,0)			+ ISNULL(C2.NDV,0) 
	,MainSPC				=	ISNULL(C2.GCAssoc_SPC,0)			+ ISNULL(C2.SPC,0) 
	,MainSRV				=	ISNULL(C2.GCAssoc_SRV,0)			+ ISNULL(C2.SRV,0) 
	,MainPV_DV				=	ISNULL(C2.GCAssoc_PV_DV,0)			+ ISNULL(C2.PV_DV,0) 
	,MainPV_PPC				=	ISNULL(C2.GCAssoc_PV_PPC,0)			+ ISNULL(C2.PV_PPC,0) 
	,MainPV_PRV				=	ISNULL(C2.GCAssoc_PV_PRV,0)			+ ISNULL(C2.PV_PRV,0) 
	,MainPV_NDV				=	ISNULL(C2.GCAssoc_PV_NDV,0)			+ ISNULL(C2.PV_NDV,0) 
	,MainPV_SPC				=	ISNULL(C2.GCAssoc_PV_SPC,0)			+ ISNULL(C2.PV_SPC,0) 
	,MainPV_SRV				=	ISNULL(C2.GCAssoc_PV_SRV,0)			+ ISNULL(C2.PV_SRV,0) 
	,MainDLV_DV				=	ISNULL(C2.GCAssoc_DLV_DV,0)			+ ISNULL(C2.DLV_DV,0) 
	,MainDLV_PPC			=	ISNULL(C2.GCAssoc_DLV_PPC,0)		+ ISNULL(C2.DLV_PPC,0) 
	,MainDLV_PRV			=	ISNULL(C2.GCAssoc_DLV_PRV,0)		+ ISNULL(C2.DLV_PRV,0) 
	,MainDLV_NDV			=	ISNULL(C2.GCAssoc_DLV_NDV,0)		+ ISNULL(C2.DLV_NDV,0) 
	,MainDLV_SPC			=	ISNULL(C2.GCAssoc_DLV_SPC,0)		+ ISNULL(C2.DLV_SPC,0) 
	,MainDLV_SRV			=	ISNULL(C2.GCAssoc_DLV_SRV,0)		+ ISNULL(C2.DLV_SRV,0) 
	,MainGV_DV				=	ISNULL(C2.GCAssoc_GV_DV,0)			+ ISNULL(C2.GV_DV,0) 
	,MainGV_PPC				=	ISNULL(C2.GCAssoc_GV_PPC,0)			+ ISNULL(C2.GV_PPC,0) 
	,MainGV_PRV				=	ISNULL(C2.GCAssoc_GV_PRV,0)			+ ISNULL(C2.GV_PRV,0) 
	,MainGV_NDV				=	ISNULL(C2.GCAssoc_GV_NDV,0)			+ ISNULL(C2.GV_NDV,0) 
	,MainGV_SPC				=	ISNULL(C2.GCAssoc_GV_SPC,0)			+ ISNULL(C2.GV_SPC,0) 
	,MainGV_SRV				=	ISNULL(C2.GCAssoc_GV_SRV,0)			+ ISNULL(C2.GV_SRV,0) 
	,MainEV					=	ISNULL(C2.GCAssoc_EV,0)				+ ISNULL(C2.EV,0) 
	,MainUV					=	ISNULL(C2.GCAssoc_UV,0)				+ ISNULL(C2.UV,0) 
	,MainMPCV				=	ISNULL(C2.GCAssoc_MPCV,0)			+ ISNULL(C2.MPCV,0) 
	,MainTOTAL_POINTS		=	ISNULL(C2.GCAssoc_TOTAL_POINTS,0)	+ ISNULL(C2.TOTAL_POINTS,0) 
	,MainQCPV				=	ISNULL(C2.GCAssoc_QCPV,0)			+ ISNULL(C2.QCPV,0) 
	,MainQDV				=	ISNULL(C2.GCAssoc_QDV,0)			+ ISNULL(C2.QDV,0) 
	,MainQDV_DV				=	ISNULL(C2.GCAssoc_QDV_DV,0)			+ ISNULL(C2.QDV_DV,0) 
	,MainPPV_DLV			=	ISNULL(C2.GCAssoc_PPV_DLV,0)		+ ISNULL(C2.PPV_DLV,0) 
	,MainDV_DLVDV  			=	ISNULL(C2.GCAssoc_DV_DLVDV,0)		+ ISNULL(C2.DV_DLVDV,0) 
INTO #GCAAssoc_Volume_DivorceAssType3_Main
FROM dbo.wrkDSFinancial AS C 
	INNER JOIN (SELECT DISTINCT nMainDistributorID,AssociationType  FROM [PubEventManagement].[Shared].[DistributorAssociation] WHERE AssociationType = 3 ) AS A
		ON C.PK_MainDistributor = A.nMainDistributorID
	LEFT JOIN dbo.wrkDSFinancial AS C2
		ON C.PK_MainDistributor = C2.PK_Distributor AND C.RoyaltyMonth = C2.RoyaltyMonth
WHERE C.IsInAssocTable = 1
AND C.IsMainID = 0 
AND C2.PK_GCAssoc_Distributor IS NOT NULL	 

UPDATE C SET 
	 MainTV					=	ISNULL(C2.GCAssoc_TV,0)				+ ISNULL(C2.TV,0) 
	,MainRO					=	ISNULL(C2.GCAssoc_RO,0)				+ ISNULL(C2.RO,0) 
	,MainPB					=	ISNULL(C2.GCAssoc_PB,0)				+ ISNULL(C2.PB,0) 
	,MainPV					=	ISNULL(C2.GCAssoc_PV,0)				+ ISNULL(C2.PV,0) 
	,MainGV					=	ISNULL(C2.GCAssoc_GV,0)				+ ISNULL(C2.GV,0) 
	,MainPPV				=	ISNULL(C2.GCAssoc_PPV,0)			+ ISNULL(C2.PPV,0) 
	,MainOV					=	ISNULL(C2.GCAssoc_OV,0)				+ ISNULL(C2.OV,0) 
    ,MainDLV				=	ISNULL(C2.GCAssoc_DLV,0)			+ ISNULL(C2.DLV,0) 
	,MainMPV 				=	ISNULL(C2.GCAssoc_MPV,0) 			+ ISNULL(C2.MPV,0) 
	,MainMTV  				=	ISNULL(C2.GCAssoc_MTV,0)  			+ ISNULL(C2.MTV,0) 
	,MainDV					=	ISNULL(C2.GCAssoc_DV,0)				+ ISNULL(C2.DV,0) 
	,MainPPC				=	ISNULL(C2.GCAssoc_PPC,0)			+ ISNULL(C2.PPC,0) 
	,MainPRV				=	ISNULL(C2.GCAssoc_PRV,0)			+ ISNULL(C2.PRV,0) 
	,MainNDV				=	ISNULL(C2.GCAssoc_NDV,0)			+ ISNULL(C2.NDV,0) 
	,MainSPC				=	ISNULL(C2.GCAssoc_SPC,0)			+ ISNULL(C2.SPC,0) 
	,MainSRV				=	ISNULL(C2.GCAssoc_SRV,0)			+ ISNULL(C2.SRV,0) 
	,MainPV_DV				=	ISNULL(C2.GCAssoc_PV_DV,0)			+ ISNULL(C2.PV_DV,0) 
	,MainPV_PPC				=	ISNULL(C2.GCAssoc_PV_PPC,0)			+ ISNULL(C2.PV_PPC,0) 
	,MainPV_PRV				=	ISNULL(C2.GCAssoc_PV_PRV,0)			+ ISNULL(C2.PV_PRV,0) 
	,MainPV_NDV				=	ISNULL(C2.GCAssoc_PV_NDV,0)			+ ISNULL(C2.PV_NDV,0) 
	,MainPV_SPC				=	ISNULL(C2.GCAssoc_PV_SPC,0)			+ ISNULL(C2.PV_SPC,0) 
	,MainPV_SRV				=	ISNULL(C2.GCAssoc_PV_SRV,0)			+ ISNULL(C2.PV_SRV,0) 
	,MainDLV_DV				=	ISNULL(C2.GCAssoc_DLV_DV,0)			+ ISNULL(C2.DLV_DV,0) 
	,MainDLV_PPC			=	ISNULL(C2.GCAssoc_DLV_PPC,0)		+ ISNULL(C2.DLV_PPC,0) 
	,MainDLV_PRV			=	ISNULL(C2.GCAssoc_DLV_PRV,0)		+ ISNULL(C2.DLV_PRV,0) 
	,MainDLV_NDV			=	ISNULL(C2.GCAssoc_DLV_NDV,0)		+ ISNULL(C2.DLV_NDV,0) 
	,MainDLV_SPC			=	ISNULL(C2.GCAssoc_DLV_SPC,0)		+ ISNULL(C2.DLV_SPC,0) 
	,MainDLV_SRV			=	ISNULL(C2.GCAssoc_DLV_SRV,0)		+ ISNULL(C2.DLV_SRV,0) 
	,MainGV_DV				=	ISNULL(C2.GCAssoc_GV_DV,0)			+ ISNULL(C2.GV_DV,0) 
	,MainGV_PPC				=	ISNULL(C2.GCAssoc_GV_PPC,0)			+ ISNULL(C2.GV_PPC,0) 
	,MainGV_PRV				=	ISNULL(C2.GCAssoc_GV_PRV,0)			+ ISNULL(C2.GV_PRV,0) 
	,MainGV_NDV				=	ISNULL(C2.GCAssoc_GV_NDV,0)			+ ISNULL(C2.GV_NDV,0) 
	,MainGV_SPC				=	ISNULL(C2.GCAssoc_GV_SPC,0)			+ ISNULL(C2.GV_SPC,0) 
	,MainGV_SRV				=	ISNULL(C2.GCAssoc_GV_SRV,0)			+ ISNULL(C2.GV_SRV,0) 
	,MainEV					=	ISNULL(C2.GCAssoc_EV,0)				+ ISNULL(C2.EV,0) 
	,MainUV					=	ISNULL(C2.GCAssoc_UV,0)				+ ISNULL(C2.UV,0) 
	,MainMPCV				=	ISNULL(C2.GCAssoc_MPCV,0)			+ ISNULL(C2.MPCV,0) 
	,MainTOTAL_POINTS		=	ISNULL(C2.GCAssoc_TOTAL_POINTS,0)	+ ISNULL(C2.TOTAL_POINTS,0) 
	,MainQCPV				=	ISNULL(C2.GCAssoc_QCPV,0)			+ ISNULL(C2.QCPV,0) 
	,MainQDV				=	ISNULL(C2.GCAssoc_QDV,0)			+ ISNULL(C2.QDV,0) 
	,MainQDV_DV				=	ISNULL(C2.GCAssoc_QDV_DV,0)			+ ISNULL(C2.QDV_DV,0) 
	,MainPPV_DLV			=	ISNULL(C2.GCAssoc_PPV_DLV,0)		+ ISNULL(C2.PPV_DLV,0) 
	,MainDV_DLVDV  			=	ISNULL(C2.GCAssoc_DV_DLVDV,0)		+ ISNULL(C2.DV_DLVDV,0) 
FROM dbo.wrkDSFinancial AS C 
	INNER JOIN (SELECT DISTINCT nMainDistributorID,AssociationType  FROM [PubEventManagement].[Shared].[DistributorAssociation] WHERE AssociationType = 3 ) AS A
		ON C.PK_MainDistributor = A.nMainDistributorID
	LEFT JOIN dbo.wrkDSFinancial AS C2
		ON C.PK_MainDistributor = C2.PK_Distributor AND C.RoyaltyMonth = C2.RoyaltyMonth
WHERE C.IsInAssocTable = 1
AND C.IsMainID = 0 
AND C2.PK_GCAssoc_Distributor IS NOT NULL	 	 

--GCAssoc volume + GCAssoc volume from MainID associated to the Main GCID in 3 IDS Divorce case

DROP TABLE IF EXISTS #GCAAssoc_Volume_DivorceAssType3

SELECT
	 C2.PK_Distributor
	,C2.RoyaltyMonth
	,GCAssoc_TV				= ISNULL(C.GCAssoc_TV,0)				+ ISNULL(C2.GCAssoc_TV,0)				
	,GCAssoc_RO				= ISNULL(C.GCAssoc_RO,0)				+ ISNULL(C2.GCAssoc_RO,0)				
	,GCAssoc_PB				= ISNULL(C.GCAssoc_PB,0)				+ ISNULL(C2.GCAssoc_PB,0)				
	,GCAssoc_PV				= ISNULL(C.GCAssoc_PV,0)				+ ISNULL(C2.GCAssoc_PV,0)				
	,GCAssoc_GV				= ISNULL(C.GCAssoc_GV,0)				+ ISNULL(C2.GCAssoc_GV,0)				
	,GCAssoc_PPV				= ISNULL(C.GCAssoc_PPV,0)				+ ISNULL(C2.GCAssoc_PPV,0)			
	,GCAssoc_OV				= ISNULL(C.GCAssoc_OV,0)				+ ISNULL(C2.GCAssoc_OV,0)				
	,GCAssoc_DLV				= ISNULL(C.GCAssoc_DLV,0)				+ ISNULL(C2.GCAssoc_DLV,0)			
	,GCAssoc_MPV 			= ISNULL(C.GCAssoc_MPV,0) 				+ ISNULL(C2.GCAssoc_MPV,0) 			
	,GCAssoc_MTV  			= ISNULL(C.GCAssoc_MTV,0)  				+ ISNULL(C2.GCAssoc_MTV,0)  			
	,GCAssoc_DV				= ISNULL(C.GCAssoc_DV,0)				+ ISNULL(C2.GCAssoc_DV,0)				
	,GCAssoc_PPC				= ISNULL(C.GCAssoc_PPC,0)				+ ISNULL(C2.GCAssoc_PPC,0)			
	,GCAssoc_PRV				= ISNULL(C.GCAssoc_PRV,0)				+ ISNULL(C2.GCAssoc_PRV,0)			
	,GCAssoc_NDV				= ISNULL(C.GCAssoc_NDV,0)				+ ISNULL(C2.GCAssoc_NDV,0)			
	,GCAssoc_SPC				= ISNULL(C.GCAssoc_SPC,0)				+ ISNULL(C2.GCAssoc_SPC,0)			
	,GCAssoc_SRV				= ISNULL(C.GCAssoc_SRV,0)				+ ISNULL(C2.GCAssoc_SRV,0)			
	,GCAssoc_PV_DV			= ISNULL(C.GCAssoc_PV_DV,0)				+ ISNULL(C2.GCAssoc_PV_DV,0)			
	,GCAssoc_PV_PPC			= ISNULL(C.GCAssoc_PV_PPC,0)			+ ISNULL(C2.GCAssoc_PV_PPC,0)			
	,GCAssoc_PV_PRV			= ISNULL(C.GCAssoc_PV_PRV,0)			+ ISNULL(C2.GCAssoc_PV_PRV,0)			
	,GCAssoc_PV_NDV			= ISNULL(C.GCAssoc_PV_NDV,0)			+ ISNULL(C2.GCAssoc_PV_NDV,0)			
	,GCAssoc_PV_SPC			= ISNULL(C.GCAssoc_PV_SPC,0)			+ ISNULL(C2.GCAssoc_PV_SPC,0)			
	,GCAssoc_PV_SRV			= ISNULL(C.GCAssoc_PV_SRV,0)			+ ISNULL(C2.GCAssoc_PV_SRV,0)			
	,GCAssoc_DLV_DV			= ISNULL(C.GCAssoc_DLV_DV,0)			+ ISNULL(C2.GCAssoc_DLV_DV,0)			
	,GCAssoc_DLV_PPC			= ISNULL(C.GCAssoc_DLV_PPC,0)			+ ISNULL(C2.GCAssoc_DLV_PPC,0)		
	,GCAssoc_DLV_PRV			= ISNULL(C.GCAssoc_DLV_PRV,0)			+ ISNULL(C2.GCAssoc_DLV_PRV,0)		
	,GCAssoc_DLV_NDV			= ISNULL(C.GCAssoc_DLV_NDV,0)			+ ISNULL(C2.GCAssoc_DLV_NDV,0)		
	,GCAssoc_DLV_SPC			= ISNULL(C.GCAssoc_DLV_SPC,0)			+ ISNULL(C2.GCAssoc_DLV_SPC,0)		
	,GCAssoc_DLV_SRV			= ISNULL(C.GCAssoc_DLV_SRV,0)			+ ISNULL(C2.GCAssoc_DLV_SRV,0)		
	,GCAssoc_GV_DV			= ISNULL(C.GCAssoc_GV_DV,0)				+ ISNULL(C2.GCAssoc_GV_DV,0)			
	,GCAssoc_GV_PPC			= ISNULL(C.GCAssoc_GV_PPC,0)			+ ISNULL(C2.GCAssoc_GV_PPC,0)			
	,GCAssoc_GV_PRV			= ISNULL(C.GCAssoc_GV_PRV,0)			+ ISNULL(C2.GCAssoc_GV_PRV,0)			
	,GCAssoc_GV_NDV			= ISNULL(C.GCAssoc_GV_NDV,0)			+ ISNULL(C2.GCAssoc_GV_NDV,0)			
	,GCAssoc_GV_SPC			= ISNULL(C.GCAssoc_GV_SPC,0)			+ ISNULL(C2.GCAssoc_GV_SPC,0)			
	,GCAssoc_GV_SRV			= ISNULL(C.GCAssoc_GV_SRV,0)			+ ISNULL(C2.GCAssoc_GV_SRV,0)			
	,GCAssoc_EV				= ISNULL(C.GCAssoc_EV,0)				+ ISNULL(C2.GCAssoc_EV,0)				
	,GCAssoc_UV				= ISNULL(C.GCAssoc_UV,0)				+ ISNULL(C2.GCAssoc_UV,0)				
	,GCAssoc_MPCV			= ISNULL(C.GCAssoc_MPCV,0)				+ ISNULL(C2.GCAssoc_MPCV,0)			
	,GCAssoc_TOTAL_POINTS	= ISNULL(C.GCAssoc_TOTAL_POINTS,0)		+ ISNULL(C2.GCAssoc_TOTAL_POINTS,0)	
	,GCAssoc_QCPV			= ISNULL(C.GCAssoc_QCPV,0)				+ ISNULL(C2.GCAssoc_QCPV,0)			
	,GCAssoc_QDV			= ISNULL(C.GCAssoc_QDV,0)				+ ISNULL(C2.GCAssoc_QDV,0)			
	,GCAssoc_QDV_DV			= ISNULL(C.GCAssoc_QDV_DV,0)			+ ISNULL(C2.GCAssoc_QDV_DV,0)			
	,GCAssoc_PPV_DLV		= ISNULL(C.GCAssoc_PPV_DLV,0)			+ ISNULL(C2.GCAssoc_PPV_DLV,0)		
	,GCAssoc_DV_DLVDV		= ISNULL(C.GCAssoc_DV_DLVDV,0)			+ ISNULL(C2.GCAssoc_DV_DLVDV,0)	
INTO #GCAAssoc_Volume_DivorceAssType3
FROM dbo.wrkDSFinancial AS C 
	INNER JOIN #GCASSOCID AS GC
			ON  GC.PK_AssociatedID = C.PK_Distributor 
	INNER JOIN (SELECT DISTINCT  PK_Distributor,nMainDistributorID,AssociationType  FROM [PubEventManagement].[Shared].[DistributorAssociation] WHERE AssociationType = 3) AS A
		ON A.PK_Distributor = GC.PK_MainDistributor
	LEFT JOIN dbo.wrkDSFinancial AS C2
		ON C2.PK_Distributor = A.nMainDistributorID AND C.RoyaltyMonth = C2.RoyaltyMonth
WHERE  C2.IsInAssocTable = 1
AND C2.IsMainID = 1
AND C.PK_GCAssoc_Distributor IS NOT NULL

UPDATE C
SET 
	GCAssoc_TV				= ISNULL(C.GCAssoc_TV,0)				+ ISNULL(C2.GCAssoc_TV,0)				
	,GCAssoc_RO				= ISNULL(C.GCAssoc_RO,0)				+ ISNULL(C2.GCAssoc_RO,0)				
	,GCAssoc_PB				= ISNULL(C.GCAssoc_PB,0)				+ ISNULL(C2.GCAssoc_PB,0)				
	,GCAssoc_PV				= ISNULL(C.GCAssoc_PV,0)				+ ISNULL(C2.GCAssoc_PV,0)				
	,GCAssoc_GV				= ISNULL(C.GCAssoc_GV,0)				+ ISNULL(C2.GCAssoc_GV,0)				
	,GCAssoc_PPV				= ISNULL(C.GCAssoc_PPV,0)				+ ISNULL(C2.GCAssoc_PPV,0)			
	,GCAssoc_OV				= ISNULL(C.GCAssoc_OV,0)				+ ISNULL(C2.GCAssoc_OV,0)				
	,GCAssoc_DLV				= ISNULL(C.GCAssoc_DLV,0)				+ ISNULL(C2.GCAssoc_DLV,0)			
	,GCAssoc_MPV 			= ISNULL(C.GCAssoc_MPV,0) 				+ ISNULL(C2.GCAssoc_MPV,0) 			
	,GCAssoc_MTV  			= ISNULL(C.GCAssoc_MTV,0)  				+ ISNULL(C2.GCAssoc_MTV,0)  			
	,GCAssoc_DV				= ISNULL(C.GCAssoc_DV,0)				+ ISNULL(C2.GCAssoc_DV,0)				
	,GCAssoc_PPC				= ISNULL(C.GCAssoc_PPC,0)				+ ISNULL(C2.GCAssoc_PPC,0)			
	,GCAssoc_PRV				= ISNULL(C.GCAssoc_PRV,0)				+ ISNULL(C2.GCAssoc_PRV,0)			
	,GCAssoc_NDV				= ISNULL(C.GCAssoc_NDV,0)				+ ISNULL(C2.GCAssoc_NDV,0)			
	,GCAssoc_SPC				= ISNULL(C.GCAssoc_SPC,0)				+ ISNULL(C2.GCAssoc_SPC,0)			
	,GCAssoc_SRV				= ISNULL(C.GCAssoc_SRV,0)				+ ISNULL(C2.GCAssoc_SRV,0)			
	,GCAssoc_PV_DV			= ISNULL(C.GCAssoc_PV_DV,0)				+ ISNULL(C2.GCAssoc_PV_DV,0)			
	,GCAssoc_PV_PPC			= ISNULL(C.GCAssoc_PV_PPC,0)			+ ISNULL(C2.GCAssoc_PV_PPC,0)			
	,GCAssoc_PV_PRV			= ISNULL(C.GCAssoc_PV_PRV,0)			+ ISNULL(C2.GCAssoc_PV_PRV,0)			
	,GCAssoc_PV_NDV			= ISNULL(C.GCAssoc_PV_NDV,0)			+ ISNULL(C2.GCAssoc_PV_NDV,0)			
	,GCAssoc_PV_SPC			= ISNULL(C.GCAssoc_PV_SPC,0)			+ ISNULL(C2.GCAssoc_PV_SPC,0)			
	,GCAssoc_PV_SRV			= ISNULL(C.GCAssoc_PV_SRV,0)			+ ISNULL(C2.GCAssoc_PV_SRV,0)			
	,GCAssoc_DLV_DV			= ISNULL(C.GCAssoc_DLV_DV,0)			+ ISNULL(C2.GCAssoc_DLV_DV,0)			
	,GCAssoc_DLV_PPC			= ISNULL(C.GCAssoc_DLV_PPC,0)			+ ISNULL(C2.GCAssoc_DLV_PPC,0)		
	,GCAssoc_DLV_PRV			= ISNULL(C.GCAssoc_DLV_PRV,0)			+ ISNULL(C2.GCAssoc_DLV_PRV,0)		
	,GCAssoc_DLV_NDV			= ISNULL(C.GCAssoc_DLV_NDV,0)			+ ISNULL(C2.GCAssoc_DLV_NDV,0)		
	,GCAssoc_DLV_SPC			= ISNULL(C.GCAssoc_DLV_SPC,0)			+ ISNULL(C2.GCAssoc_DLV_SPC,0)		
	,GCAssoc_DLV_SRV			= ISNULL(C.GCAssoc_DLV_SRV,0)			+ ISNULL(C2.GCAssoc_DLV_SRV,0)		
	,GCAssoc_GV_DV			= ISNULL(C.GCAssoc_GV_DV,0)				+ ISNULL(C2.GCAssoc_GV_DV,0)			
	,GCAssoc_GV_PPC			= ISNULL(C.GCAssoc_GV_PPC,0)			+ ISNULL(C2.GCAssoc_GV_PPC,0)			
	,GCAssoc_GV_PRV			= ISNULL(C.GCAssoc_GV_PRV,0)			+ ISNULL(C2.GCAssoc_GV_PRV,0)			
	,GCAssoc_GV_NDV			= ISNULL(C.GCAssoc_GV_NDV,0)			+ ISNULL(C2.GCAssoc_GV_NDV,0)			
	,GCAssoc_GV_SPC			= ISNULL(C.GCAssoc_GV_SPC,0)			+ ISNULL(C2.GCAssoc_GV_SPC,0)			
	,GCAssoc_GV_SRV			= ISNULL(C.GCAssoc_GV_SRV,0)			+ ISNULL(C2.GCAssoc_GV_SRV,0)			
	,GCAssoc_EV				= ISNULL(C.GCAssoc_EV,0)				+ ISNULL(C2.GCAssoc_EV,0)				
	,GCAssoc_UV				= ISNULL(C.GCAssoc_UV,0)				+ ISNULL(C2.GCAssoc_UV,0)				
	,GCAssoc_MPCV			= ISNULL(C.GCAssoc_MPCV,0)				+ ISNULL(C2.GCAssoc_MPCV,0)			
	,GCAssoc_TOTAL_POINTS	= ISNULL(C.GCAssoc_TOTAL_POINTS,0)		+ ISNULL(C2.GCAssoc_TOTAL_POINTS,0)	
	,GCAssoc_QCPV			= ISNULL(C.GCAssoc_QCPV,0)				+ ISNULL(C2.GCAssoc_QCPV,0)			
	,GCAssoc_QDV			= ISNULL(C.GCAssoc_QDV,0)				+ ISNULL(C2.GCAssoc_QDV,0)			
	,GCAssoc_QDV_DV			= ISNULL(C.GCAssoc_QDV_DV,0)			+ ISNULL(C2.GCAssoc_QDV_DV,0)			
	,GCAssoc_PPV_DLV		= ISNULL(C.GCAssoc_PPV_DLV,0)			+ ISNULL(C2.GCAssoc_PPV_DLV,0)		
	,GCAssoc_DV_DLVDV		= ISNULL(C.GCAssoc_DV_DLVDV,0)			+ ISNULL(C2.GCAssoc_DV_DLVDV,0)		
FROM dbo.wrkDSFinancial AS C 
	INNER JOIN #GCASSOCID AS GC
			ON  GC.PK_AssociatedID = C.PK_Distributor 
	INNER JOIN (SELECT DISTINCT  PK_Distributor,nMainDistributorID,AssociationType  FROM [PubEventManagement].[Shared].[DistributorAssociation] WHERE AssociationType = 3) AS A
		ON A.PK_Distributor = GC.PK_MainDistributor
	LEFT JOIN dbo.wrkDSFinancial AS C2
		ON C2.PK_Distributor = A.nMainDistributorID AND C.RoyaltyMonth = C2.RoyaltyMonth
WHERE  C2.IsInAssocTable = 1
AND C2.IsMainID = 1
AND C.PK_GCAssoc_Distributor IS NOT NULL

UPDATE
	WRK
SET 
	MainRO = 0
	,MainPB = 0
	,MainTV  = 0
	,MainPV = 0
	,MainGV = 0
	,MainOV = 0
	,RO = 0
	,PB = 0
	,MainMPV = 0
	,MainMTV = 0
	,MainDV = 0
	,MainPPC = 0
	,MainPRV = 0
	,MainNDV = 0
	,MainSPC = 0
	,MainSRV = 0
	,MainPV_DV = 0
	,MainPV_PPC = 0
	,MainPV_PRV = 0
	,MainPV_NDV = 0
	,MainPV_SPC = 0
	,MainPV_SRV = 0
	,MainDLV_DV = 0
	,MainDLV_PPC = 0
	,MainDLV_PRV = 0
	,MainDLV_NDV = 0
	,MainDLV_SPC = 0
	,MainDLV_SRV = 0
	,MainGV_DV = 0
	,MainGV_PPC = 0
	,MainGV_PRV = 0
	,MainGV_NDV = 0
	,MainGV_SPC = 0
	,MainGV_SRV = 0
	,MainEV = 0
	,MainUV = 0
	,MainMPCV = 0
	,MainTOTAL_POINTS = 0
	,MainQCPV = 0
	,MainQDV = 0
	,MainQDV_DV = 0
	,MainPPV_DLV = 0
	,MainDV_DLVDV = 0			  
FROM
	dbo.wrkDSFinancial WRK 
INNER JOIN
	#WRK_DimDistributor DS WITH (NOLOCK)
ON
	WRK.PK_Distributor = DS.PK_Distributor 
	AND
	DS.TypeCode IN ('DS','CS')
	AND
	WRK.IsMainID = 0 
	AND
	WRK.MainIsType23 = 1

END

SET @EndTime = GETUTCDATE()
 
  PRINT 'Greater China Associations'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = 'GC' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
IF @Step =  22 OR (@fp = 1 AND @Step >= 22)
BEGIN

/******************************************************************************
	Populate aggDSFinancial
******************************************************************************/
SET @StartTime = GETUTCDATE() --Step 115
 
IF @IsDevQA = 0
BEGIN

	MERGE INTO pubEvents.dbo.aggDSFinancial t
	USING dbo.wrkDSFinancial s
		ON t.PK_Distributor = s.PK_Distributor AND t.RoyaltyMonth = s.RoyaltyMonth 
	WHEN NOT MATCHED THEN 
		INSERT 
		(
			LastModifiedDate, 
			RoyaltyMonth, 
			PK_Distributor,
			DistributorID, 
			DeletedDate, 
			Qual_SPDate, 
			Qual_QSDate, 
			Qual_QSDate_Actual, 
			Team, 
			COP, 
			IsAssocType23, 
			IsMainID, 
			IsInAssocTable, 
			TV, 
			RO, 
			PB, 
			PV, 
			GV, 
			PPV, 
			OV, 
			PK_MainDistributor, 
			MainDistributorID, 
			MainDeletedDate, 
			MainQual_SPDate, 
			MainQual_QSDate, 
			MainQual_QSDate_Actual, 
			MainTeam, 
			MainCOP, 
			MainIsType23, 
			MainTV, 
			MainRO, 
			MainPB, 
			MainPV, 
			MainGV, 
			MainPPV, 
			MainOV, 
			DLV, 
			MainDLV, 
			MPV, 
			MTV, 
			MainMPV, 
			MainMTV, 
			DV, 
			PPC, 
			PRV, 
			NDV, 
			SPC, 
			SRV, 
			PV_DV, 
			PV_PPC, 
			PV_PRV, 
			PV_NDV, 
			PV_SPC, 
			PV_SRV, 
			DLV_DV, 
			DLV_PPC, 
			DLV_PRV, 
			DLV_NDV, 
			DLV_SPC, 
			DLV_SRV, 
			GV_DV, 
			GV_PPC, 
			GV_PRV, 
			GV_NDV, 
			GV_SPC, 
			GV_SRV, 
			EV, 
			UV, 
			MPCV,
			TOTAL_POINTS,
			QCPV,
			QDV,
			QDV_DV,
			PPV_DLV,
			DV_DLVDV,		
			MainDV, 
			MainPPC, 
			MainPRV, 
			MainNDV, 
			MainSPC, 
			MainSRV, 
			MainPV_DV, 
			MainPV_PPC, 
			MainPV_PRV, 
			MainPV_NDV, 
			MainPV_SPC, 
			MainPV_SRV, 
			MainDLV_DV, 
			MainDLV_PPC, 
			MainDLV_PRV, 
			MainDLV_NDV, 
			MainDLV_SPC, 
			MainDLV_SRV, 
			MainGV_DV, 
			MainGV_PPC, 
			MainGV_PRV, 
			MainGV_NDV, 
			MainGV_SPC, 
			MainGV_SRV, 
			MainEV, 
			MainUV,
			MainMPCV,
			MainTOTAL_POINTS,
			MainQCPV,
			MainQDV,
			MainQDV_DV,
			MainPPV_DLV,
			MainDV_DLVDV,
			--Greater China
			[PK_GCAssoc_Distributor]
			,[GCAssoc_DistributorID] 
			,[GCAssoc_TV]           
			,[GCAssoc_RO]           
			,[GCAssoc_PB]           
			,[GCAssoc_PV]           
			,[GCAssoc_GV]           
			,[GCAssoc_PPV]          
			,[GCAssoc_OV]           
			,[GCAssoc_DLV]          
			,[GCAssoc_MPV]          
			,[GCAssoc_MTV]          
			,[GCAssoc_DV]           
			,[GCAssoc_PPC]          
			,[GCAssoc_PRV]          
			,[GCAssoc_NDV]          
			,[GCAssoc_SPC]          
			,[GCAssoc_SRV]          
			,[GCAssoc_PV_DV]        
			,[GCAssoc_PV_PPC]       
			,[GCAssoc_PV_PRV]       
			,[GCAssoc_PV_NDV]       
			,[GCAssoc_PV_SPC]       
			,[GCAssoc_PV_SRV]       
			,[GCAssoc_DLV_DV]       
			,[GCAssoc_DLV_PPC]      
			,[GCAssoc_DLV_PRV]      
			,[GCAssoc_DLV_NDV]      
			,[GCAssoc_DLV_SPC]      
			,[GCAssoc_DLV_SRV]      
			,[GCAssoc_GV_DV]        
			,[GCAssoc_GV_PPC]       
			,[GCAssoc_GV_PRV]       
			,[GCAssoc_GV_NDV]       
			,[GCAssoc_GV_SPC]       
			,[GCAssoc_GV_SRV]       
			,[GCAssoc_EV]           
			,[GCAssoc_UV]           
			,[GCAssoc_MPCV]         
			,[GCAssoc_TOTAL_POINTS] 
			,[GCAssoc_QCPV]         
			,[GCAssoc_QDV]          
			,[GCAssoc_QDV_DV]       
			,[GCAssoc_PPV_DLV]      
			,[GCAssoc_DV_DLVDV]  	
		)
		VALUES 
		(
			s.LastModifiedDate, 
			s.RoyaltyMonth, 
			s.PK_Distributor, 
			s.DistributorID, 
			s.DeletedDate, 
			s.Qual_SPDate, 
			s.Qual_QSDate, 
			s.Qual_QSDate_Actual, 
			s.Team, 
			s.COP, 
			s.IsAssocType23, 
			s.IsMainID, 
			s.IsInAssocTable, 
			s.TV, 
			s.RO, 
			s.PB, 
			s.PV, 
			s.GV, 
			s.PPV, 
			s.OV, 
		    s.PK_MainDistributor, 
			s.MainDistributorID, 
			s.MainDeletedDate, 
			s.MainQual_SPDate, 
			s.MainQual_QSDate, 
			s.MainQual_QSDate_Actual, 
			s.MainTeam, 
			s.MainCOP, 
			s.MainIsType23, 
			s.MainTV, 
			s.MainRO, 
			s.MainPB, 
			s.MainPV, 
			s.MainGV, 
			s.MainPPV, 
			s.MainOV, 
			s.DLV, 
			s.MainDLV, 
			s.MPV, 
			s.MTV, 
			s.MainMPV, 
			s.MainMTV, 
			s.DV, 
			s.PPC, 
			s.PRV, 
			s.NDV, 
			s.SPC, 
			s.SRV, 
			s.PV_DV, 
			s.PV_PPC, 
			s.PV_PRV, 
			s.PV_NDV, 
			s.PV_SPC, 
			s.PV_SRV, 
			s.DLV_DV, 
			s.DLV_PPC, 
			s.DLV_PRV, 
			s.DLV_NDV, 
			s.DLV_SPC, 
			s.DLV_SRV, 
			s.GV_DV, 
			s.GV_PPC, 
			s.GV_PRV, 
			s.GV_NDV, 
			s.GV_SPC, 
			s.GV_SRV, 
			s.EV, 
			s.UV, 
			s.MPCV,
			s.TOTAL_POINTS,
			s.QCPV,
			s.QDV,
			s.QDV_DV,
			s.PPV_DLV,
			s.DV_DLVDV,		  
			s.MainDV, 
			s.MainPPC, 
			s.MainPRV, 
			s.MainNDV, 
			s.MainSPC, 
			s.MainSRV, 
			s.MainPV_DV, 
			s.MainPV_PPC, 
			s.MainPV_PRV, 
			s.MainPV_NDV, 
			s.MainPV_SPC, 
			s.MainPV_SRV, 
			s.MainDLV_DV, 
			s.MainDLV_PPC, 
			s.MainDLV_PRV, 
			s.MainDLV_NDV, 
			s.MainDLV_SPC, 
			s.MainDLV_SRV, 
			s.MainGV_DV, 
			s.MainGV_PPC, 
			s.MainGV_PRV, 
			s.MainGV_NDV, 
			s.MainGV_SPC, 
			s.MainGV_SRV, 
			s.MainEV, 
			s.MainUV,
			s.MainMPCV,
			s.MainTOTAL_POINTS,
			s.MainQCPV,
			s.MainQDV,
			s.MainQDV_DV,
			s.MainPPV_DLV,
			s.MainDV_DLVDV,
			--Greater China
			 s.[PK_GCAssoc_Distributor]
			,s.[GCAssoc_DistributorID] 
			,s.[GCAssoc_TV]           
			,s.[GCAssoc_RO]           
			,s.[GCAssoc_PB]           
			,s.[GCAssoc_PV]           
			,s.[GCAssoc_GV]           
			,s.[GCAssoc_PPV]          
			,s.[GCAssoc_OV]           
			,s.[GCAssoc_DLV]          
			,s.[GCAssoc_MPV]          
			,s.[GCAssoc_MTV]          
			,s.[GCAssoc_DV]           
			,s.[GCAssoc_PPC]          
			,s.[GCAssoc_PRV]          
			,s.[GCAssoc_NDV]          
			,s.[GCAssoc_SPC]          
			,s.[GCAssoc_SRV]          
			,s.[GCAssoc_PV_DV]        
			,s.[GCAssoc_PV_PPC]       
			,s.[GCAssoc_PV_PRV]       
			,s.[GCAssoc_PV_NDV]       
			,s.[GCAssoc_PV_SPC]       
			,s.[GCAssoc_PV_SRV]       
			,s.[GCAssoc_DLV_DV]       
			,s.[GCAssoc_DLV_PPC]      
			,s.[GCAssoc_DLV_PRV]      
			,s.[GCAssoc_DLV_NDV]      
			,s.[GCAssoc_DLV_SPC]      
			,s.[GCAssoc_DLV_SRV]      
			,s.[GCAssoc_GV_DV]        
			,s.[GCAssoc_GV_PPC]       
			,s.[GCAssoc_GV_PRV]       
			,s.[GCAssoc_GV_NDV]       
			,s.[GCAssoc_GV_SPC]       
			,s.[GCAssoc_GV_SRV]       
			,s.[GCAssoc_EV]           
			,s.[GCAssoc_UV]           
			,s.[GCAssoc_MPCV]         
			,s.[GCAssoc_TOTAL_POINTS] 
			,s.[GCAssoc_QCPV]         
			,s.[GCAssoc_QDV]          
			,s.[GCAssoc_QDV_DV]       
			,s.[GCAssoc_PPV_DLV]      
			,s.[GCAssoc_DV_DLVDV]   
	)
	WHEN MATCHED AND (t.RoyaltyMonth <> s.RoyaltyMonth
			OR t.PK_Distributor <> s.PK_Distributor 
			OR ISNULL(t.DistributorID,'X') <> ISNULL(s.DistributorID,'X')
			OR ISNULL(t.DeletedDate,GETDATE()) <> ISNULL(s.DeletedDate ,GETDATE())
			OR t.Qual_SPDate <> s.Qual_SPDate 
			OR t.Qual_QSDate <> s.Qual_QSDate 
			OR t.Qual_QSDate_Actual <> s.Qual_QSDate_Actual 
			OR ISNULL(t.Team,'X') <> ISNULL(s.Team,'X') 
			OR ISNULL(t.COP,'X') <> ISNULL(s.COP,'X') 
			OR t.IsAssocType23 <> s.IsAssocType23 
			OR t.IsMainID <> s.IsMainID 
			OR t.IsInAssocTable <> s.IsInAssocTable 
			OR ISNULL(t.TV,0) <> ISNULL(s.TV,0) 
			OR ISNULL(t.RO,0) <> ISNULL(s.RO,0) 
			OR ISNULL(t.PB,0) <> ISNULL(s.PB,0) 
			OR ISNULL(t.PV,0) <> ISNULL(s.PV,0) 
			OR ISNULL(t.GV,0) <> ISNULL(s.GV,0) 
			OR ISNULL(t.PPV,0) <> ISNULL(s.PPV,0) 
			OR ISNULL(t.OV,0) <> ISNULL(s.OV,0) 
			OR t.PK_MainDistributor <> s.PK_MainDistributor 
			OR ISNULL(t.MainDistributorID,'X') <> ISNULL(s.MainDistributorID,'X') 
			OR ISNULL(t.MainDeletedDate,GETDATE()) <> ISNULL(s.MainDeletedDate,GETDATE()) 
			OR t.MainQual_SPDate <> s.MainQual_SPDate 
			OR t.MainQual_QSDate <> s.MainQual_QSDate 
			OR t.MainQual_QSDate_Actual <> s.MainQual_QSDate_Actual 
			OR ISNULL(t.MainTeam,'X') <> ISNULL(s.MainTeam,'X') 
			OR ISNULL(t.MainCOP,'X') <> ISNULL(s.MainCOP,'X') 
			OR t.MainIsType23 <> s.MainIsType23 
			OR ISNULL(t.MainTV,0) <> ISNULL(s.MainTV,0) 
			OR ISNULL(t.MainRO,0) <> ISNULL(s.MainRO,0) 
			OR ISNULL(t.MainPB,0) <> ISNULL(s.MainPB,0) 
			OR ISNULL(t.MainPV,0) <> ISNULL(s.MainPV,0) 
			OR ISNULL(t.MainGV,0) <> ISNULL(s.MainGV,0) 
			OR ISNULL(t.MainPPV,0) <> ISNULL(s.MainPPV,0) 
			OR ISNULL(t.MainOV,0) <> ISNULL(s.MainOV,0) 
			OR ISNULL(t.DLV,0) <> ISNULL(s.DLV,0) 
			OR ISNULL(t.MainDLV,0) <> ISNULL(s.MainDLV,0) 
			OR ISNULL(t.MPV,0) <> ISNULL(s.MPV,0) 
			OR ISNULL(t.MTV,0) <> ISNULL(s.MTV,0) 
			OR ISNULL(t.MainMPV,0) <> ISNULL(s.MainMPV,0) 
			OR ISNULL(t.MainMTV,0) <> ISNULL(s.MainMTV,0) 
			OR ISNULL(t.DV,0) <> ISNULL(s.DV,0) 
			OR ISNULL(t.PPC,0) <> ISNULL(s.PPC,0) 
			OR ISNULL(t.PRV,0) <> ISNULL(s.PRV,0) 
			OR ISNULL(t.NDV,0) <> ISNULL(s.NDV,0) 
			OR ISNULL(t.SPC,0) <> ISNULL(s.SPC,0) 
			OR ISNULL(t.SRV,0) <> ISNULL(s.SRV,0) 
			OR ISNULL(t.PV_DV,0) <> ISNULL(s.PV_DV,0) 
			OR ISNULL(t.PV_PPC,0) <> ISNULL(s.PV_PPC,0) 
			OR ISNULL(t.PV_PRV,0) <> ISNULL(s.PV_PRV,0) 
			OR ISNULL(t.PV_NDV,0) <> ISNULL(s.PV_NDV,0) 
			OR ISNULL(t.PV_SPC,0) <> ISNULL(s.PV_SPC,0) 
			OR ISNULL(t.PV_SRV,0) <> ISNULL(s.PV_SRV,0) 
			OR ISNULL(t.DLV_DV,0) <> ISNULL(s.DLV_DV,0) 
			OR ISNULL(t.DLV_PPC,0) <> ISNULL(s.DLV_PPC,0) 
			OR ISNULL(t.DLV_PRV,0) <> ISNULL(s.DLV_PRV,0) 
			OR ISNULL(t.DLV_NDV,0) <> ISNULL(s.DLV_NDV,0) 
			OR ISNULL(t.DLV_SPC,0) <> ISNULL(s.DLV_SPC,0) 
			OR ISNULL(t.DLV_SRV,0) <> ISNULL(s.DLV_SRV,0) 
			OR ISNULL(t.GV_DV,0) <> ISNULL(s.GV_DV,0) 
			OR ISNULL(t.GV_PPC,0) <> ISNULL(s.GV_PPC,0) 
			OR ISNULL(t.GV_PRV,0) <> ISNULL(s.GV_PRV,0) 
			OR ISNULL(t.GV_NDV,0) <> ISNULL(s.GV_NDV,0) 
			OR ISNULL(t.GV_SPC,0) <> ISNULL(s.GV_SPC,0) 
			OR ISNULL(t.GV_SRV,0) <> ISNULL(s.GV_SRV,0) 
			OR ISNULL(t.EV,0) <> ISNULL(s.EV,0) 
			OR ISNULL(t.UV,0) <> ISNULL(s.UV,0) 
			OR ISNULL(t.MPCV,0) <> ISNULL(s.MPCV,0)		
			OR ISNULL(t.TOTAL_POINTS,0) <> ISNULL(s.TOTAL_POINTS,0)
			OR ISNULL(t.QCPV,0) <> ISNULL(s.QCPV,0)
			OR ISNULL(t.QDV,0) <> ISNULL(s.QDV,0)
			OR ISNULL(t.QDV_DV,0) <> ISNULL(s.QDV_DV,0)
			OR ISNULL(t.PPV_DLV,0) <> ISNULL(s.PPV_DLV,0)
			OR ISNULL(t.DV_DLVDV,0) <> ISNULL(s.DV_DLVDV,0)											
			OR ISNULL(t.MainDV,0) <> ISNULL(s.MainDV,0) 
			OR ISNULL(t.MainPPC,0) <> ISNULL(s.MainPPC,0) 
			OR ISNULL(t.MainPRV,0) <> ISNULL(s.MainPRV,0) 
			OR ISNULL(t.MainNDV,0) <> ISNULL(s.MainNDV,0) 
			OR ISNULL(t.MainSPC,0) <> ISNULL(s.MainSPC,0) 
			OR ISNULL(t.MainSRV,0) <> ISNULL(s.MainSRV,0) 
			OR ISNULL(t.MainPV_DV,0) <> ISNULL(s.MainPV_DV,0) 
			OR ISNULL(t.MainPV_PPC,0) <> ISNULL(s.MainPV_PPC,0) 
			OR ISNULL(t.MainPV_PRV,0) <> ISNULL(s.MainPV_PRV,0) 
			OR ISNULL(t.MainPV_NDV,0) <> ISNULL(s.MainPV_NDV,0) 
			OR ISNULL(t.MainPV_SPC,0) <> ISNULL(s.MainPV_SPC,0) 
			OR ISNULL(t.MainPV_SRV,0) <> ISNULL(s.MainPV_SRV,0) 
			OR ISNULL(t.MainDLV_DV,0) <> ISNULL(s.MainDLV_DV,0) 
			OR ISNULL(t.MainDLV_PPC,0) <> ISNULL(s.MainDLV_PPC,0) 
			OR ISNULL(t.MainDLV_PRV,0) <> ISNULL(s.MainDLV_PRV,0) 
			OR ISNULL(t.MainDLV_NDV,0) <> ISNULL(s.MainDLV_NDV,0) 
			OR ISNULL(t.MainDLV_SPC,0) <> ISNULL(s.MainDLV_SPC,0) 
			OR ISNULL(t.MainDLV_SRV,0) <> ISNULL(s.MainDLV_SRV,0) 
			OR ISNULL(t.MainGV_DV,0) <> ISNULL(s.MainGV_DV,0) 
			OR ISNULL(t.MainGV_PPC,0) <> ISNULL(s.MainGV_PPC,0) 
			OR ISNULL(t.MainGV_PRV,0) <> ISNULL(s.MainGV_PRV,0) 
			OR ISNULL(t.MainGV_NDV,0) <> ISNULL(s.MainGV_NDV,0) 
			OR ISNULL(t.MainGV_SPC,0) <> ISNULL(s.MainGV_SPC,0) 
			OR ISNULL(t.MainGV_SRV,0) <> ISNULL(s.MainGV_SRV,0) 
			OR ISNULL(t.MainEV,0) <> ISNULL(s.MainEV,0) 
			OR ISNULL(t.MainUV,0) <> ISNULL(s.MainUV,0)
			OR ISNULL(t.MainMPCV,0) <> ISNULL(s.MainMPCV,0)
			OR ISNULL(t.MainTOTAL_POINTS,0) <> ISNULL(s.MainTOTAL_POINTS,0)
			OR ISNULL(t.MainQCPV,0) <> ISNULL(s.MainQCPV,0)
			OR ISNULL(t.MainQDV,0) <> ISNULL(s.MainQDV,0)
			OR ISNULL(t.MainQDV_DV,0) <> ISNULL(s.MainQDV_DV,0)
			OR ISNULL(t.MainPPV_DLV,0) <> ISNULL(s.MainPPV_DLV,0)
			OR ISNULL(t.MainDV_DLVDV,0) <> ISNULL(s.MainDV_DLVDV,0)
			--Greater China
			OR t.[PK_GCAssoc_Distributor] <> s.[PK_GCAssoc_Distributor] 
			OR t.[GCAssoc_DistributorID] <> s.[GCAssoc_DistributorID] 
			OR ISNULL(t.[GCAssoc_TV],0) <> ISNULL(s.[GCAssoc_TV],0)
			OR ISNULL(t.[GCAssoc_RO],0) <> ISNULL(s.[GCAssoc_RO],0)
			OR ISNULL(t.[GCAssoc_PB],0) <> ISNULL(s.[GCAssoc_PB],0)
			OR ISNULL(t.[GCAssoc_PV],0) <> ISNULL(s.[GCAssoc_PV],0)
			OR ISNULL(t.[GCAssoc_GV],0) <> ISNULL(s.[GCAssoc_GV],0)
			OR ISNULL(t.[GCAssoc_PPV],0) <> ISNULL(s.[GCAssoc_PPV],0)
			OR ISNULL(t.[GCAssoc_OV],0) <> ISNULL(s.[GCAssoc_OV],0)
			OR ISNULL(t.[GCAssoc_DLV],0) <> ISNULL(s.[GCAssoc_DLV],0)
			OR ISNULL(t.[GCAssoc_MPV],0) <> ISNULL(s.[GCAssoc_MPV],0)
			OR ISNULL(t.[GCAssoc_MTV],0) <> ISNULL(s.[GCAssoc_MTV],0)
			OR ISNULL(t.[GCAssoc_DV],0) <> ISNULL(s.[GCAssoc_DV],0)
			OR ISNULL(t.[GCAssoc_PPC],0) <> ISNULL(s.[GCAssoc_PPC],0)
			OR ISNULL(t.[GCAssoc_PRV],0) <> ISNULL(s.[GCAssoc_PRV],0)
			OR ISNULL(t.[GCAssoc_NDV],0) <> ISNULL(s.[GCAssoc_NDV],0)
			OR ISNULL(t.[GCAssoc_SPC],0) <> ISNULL(s.[GCAssoc_SPC],0)
			OR ISNULL(t.[GCAssoc_SRV],0) <> ISNULL(s.[GCAssoc_SRV],0)
			OR ISNULL(t.[GCAssoc_PV_DV],0) <> ISNULL(s.[GCAssoc_PV_DV],0)
			OR ISNULL(t.[GCAssoc_PV_PPC],0) <> ISNULL(s.[GCAssoc_PV_PPC],0)
			OR ISNULL(t.[GCAssoc_PV_PRV],0) <> ISNULL(s.[GCAssoc_PV_PRV],0)
			OR ISNULL(t.[GCAssoc_PV_NDV],0) <> ISNULL(s.[GCAssoc_PV_NDV] ,0)
			OR ISNULL(t.[GCAssoc_PV_SPC],0) <> ISNULL(s.[GCAssoc_PV_SPC],0)
			OR ISNULL(t.[GCAssoc_PV_SRV],0) <> ISNULL(s.[GCAssoc_PV_SRV],0)
			OR ISNULL(t.[GCAssoc_DLV_DV],0) <> ISNULL(s.[GCAssoc_DLV_DV],0)
			OR ISNULL(t.[GCAssoc_DLV_PPC],0) <> ISNULL(s.[GCAssoc_DLV_PPC],0)
			OR ISNULL(t.[GCAssoc_DLV_PRV],0) <> ISNULL(s.[GCAssoc_DLV_PRV],0)
			OR ISNULL(t.[GCAssoc_DLV_NDV],0) <> ISNULL(s.[GCAssoc_DLV_NDV],0)
			OR ISNULL(t.[GCAssoc_DLV_SPC],0) <> ISNULL(s.[GCAssoc_DLV_SPC],0)
			OR ISNULL(t.[GCAssoc_DLV_SRV],0) <> ISNULL(s.[GCAssoc_DLV_SRV],0)
			OR ISNULL(t.[GCAssoc_GV_DV],0) <> ISNULL(s.[GCAssoc_GV_DV],0)
			OR ISNULL(t.[GCAssoc_GV_PPC],0) <> ISNULL(s.[GCAssoc_GV_PPC],0)
			OR ISNULL(t.[GCAssoc_GV_PRV],0) <> ISNULL(s.[GCAssoc_GV_PRV],0)
			OR ISNULL(t.[GCAssoc_GV_NDV],0) <> ISNULL(s.[GCAssoc_GV_NDV],0)
			OR ISNULL(t.[GCAssoc_GV_SPC],0) <> ISNULL(s.[GCAssoc_GV_SPC],0)
			OR ISNULL(t.[GCAssoc_GV_SRV],0) <> ISNULL(s.[GCAssoc_GV_SRV],0)
			OR ISNULL(t.[GCAssoc_EV],0) <> ISNULL(s.[GCAssoc_EV],0)
			OR ISNULL(t.[GCAssoc_UV],0) <> ISNULL(s.[GCAssoc_UV],0)
			OR ISNULL(t.[GCAssoc_MPCV],0) <> ISNULL(s.[GCAssoc_MPCV],0)
			OR ISNULL(t.[GCAssoc_TOTAL_POINTS] ,0) <> ISNULL(s.[GCAssoc_TOTAL_POINTS] ,0)
			OR ISNULL(t.[GCAssoc_QCPV],0) <> ISNULL(s.[GCAssoc_QCPV],0)
			OR ISNULL(t.[GCAssoc_QDV],0) <> ISNULL(s.[GCAssoc_QDV],0)
			OR ISNULL(t.[GCAssoc_QDV_DV],0) <> ISNULL(s.[GCAssoc_QDV_DV],0)
			OR ISNULL(t.[GCAssoc_PPV_DLV],0) <> ISNULL(s.[GCAssoc_PPV_DLV],0)
			OR ISNULL(t.[GCAssoc_DV_DLVDV],0) <> ISNULL(s.[GCAssoc_DV_DLVDV],0))
		THEN 
		UPDATE
			SET t.RoyaltyMonth = s.RoyaltyMonth
			, t.PK_Distributor = s.PK_Distributor 
			, t.DistributorID = s.DistributorID
			, t.DeletedDate = s.DeletedDate 
			, t.Qual_SPDate = s.Qual_SPDate 
			, t.Qual_QSDate = s.Qual_QSDate 
			, t.Qual_QSDate_Actual = s.Qual_QSDate_Actual 
			, t.Team = s.Team 
			, t.COP = s.COP 
			, t.IsAssocType23 = s.IsAssocType23 
			, t.IsMainID = s.IsMainID 
			, t.IsInAssocTable = s.IsInAssocTable 
			, t.TV = s.TV 
			, t.RO = s.RO 
			, t.PB = s.PB 
			, t.PV = s.PV 
			, t.GV = s.GV 
			, t.PPV = s.PPV 
			, t.OV = s.OV 
			, t.PK_MainDistributor = s.PK_MainDistributor 
			, t.MainDistributorID = s.MainDistributorID 
			, t.MainDeletedDate = s.MainDeletedDate 
			, t.MainQual_SPDate = s.MainQual_SPDate 
			, t.MainQual_QSDate = s.MainQual_QSDate 
			, t.MainQual_QSDate_Actual = s.MainQual_QSDate_Actual 
			, t.MainTeam = s.MainTeam 
			, t.MainCOP = s.MainCOP 
			, t.MainIsType23 = s.MainIsType23 
			, t.MainTV = s.MainTV 
			, t.MainRO = s.MainRO 
			, t.MainPB = s.MainPB 
			, t.MainPV = s.MainPV 
			, t.MainGV = s.MainGV 
			, t.MainPPV = s.MainPPV 
			, t.MainOV = s.MainOV 
			, t.DLV = s.DLV 
			, t.MainDLV = s.MainDLV 
			, t.MPV = s.MPV 
			, t.MTV = s.MTV 
			, t.MainMPV = s.MainMPV 
			, t.MainMTV = s.MainMTV 
			, t.DV = s.DV 
			, t.PPC = s.PPC 
			, t.PRV = s.PRV 
			, t.NDV = s.NDV 
			, t.SPC = s.SPC 
			, t.SRV = s.SRV 
			, t.PV_DV = s.PV_DV 
			, t.PV_PPC = s.PV_PPC 
			, t.PV_PRV = s.PV_PRV 
			, t.PV_NDV = s.PV_NDV 
			, t.PV_SPC = s.PV_SPC 
			, t.PV_SRV = s.PV_SRV 
			, t.DLV_DV = s.DLV_DV 
			, t.DLV_PPC = s.DLV_PPC 
			, t.DLV_PRV = s.DLV_PRV 
			, t.DLV_NDV = s.DLV_NDV 
			, t.DLV_SPC = s.DLV_SPC 
			, t.DLV_SRV = s.DLV_SRV 
			, t.GV_DV = s.GV_DV 
			, t.GV_PPC = s.GV_PPC 
			, t.GV_PRV = s.GV_PRV 
			, t.GV_NDV = s.GV_NDV 
			, t.GV_SPC = s.GV_SPC 
			, t.GV_SRV = s.GV_SRV 
			, t.EV = s.EV 
			, t.UV = s.UV 
			, t.MPCV = s.MPCV	
			, t.TOTAL_POINTS = s.TOTAL_POINTS
			, t.QCPV = s.QCPV
			, t.QDV = s.QDV
			, t.QDV_DV = s.QDV_DV
			, t.PPV_DLV = s.PPV_DLV
			, t.DV_DLVDV = s.DV_DLVDV					 
			, t.MainDV = s.MainDV 
			, t.MainPPC = s.MainPPC 
			, t.MainPRV = s.MainPRV 
			, t.MainNDV = s.MainNDV 
			, t.MainSPC = s.MainSPC 
			, t.MainSRV = s.MainSRV 
			, t.MainPV_DV = s.MainPV_DV 
			, t.MainPV_PPC = s.MainPV_PPC 
			, t.MainPV_PRV = s.MainPV_PRV 
			, t.MainPV_NDV = s.MainPV_NDV 
			, t.MainPV_SPC = s.MainPV_SPC 
			, t.MainPV_SRV = s.MainPV_SRV 
			, t.MainDLV_DV = s.MainDLV_DV 
			, t.MainDLV_PPC = s.MainDLV_PPC 
			, t.MainDLV_PRV = s.MainDLV_PRV 
			, t.MainDLV_NDV = s.MainDLV_NDV 
			, t.MainDLV_SPC = s.MainDLV_SPC 
			, t.MainDLV_SRV = s.MainDLV_SRV 
			, t.MainGV_DV = s.MainGV_DV 
			, t.MainGV_PPC = s.MainGV_PPC 
			, t.MainGV_PRV = s.MainGV_PRV 
			, t.MainGV_NDV = s.MainGV_NDV 
			, t.MainGV_SPC = s.MainGV_SPC 
			, t.MainGV_SRV = s.MainGV_SRV 
			, t.MainEV = s.MainEV 
			, t.MainUV = s.MainUV
			, t.MainMPCV = s.MainMPCV
			, t.MainTOTAL_POINTS = s.MainTOTAL_POINTS
			, t.MainQCPV = s.MainQCPV
			, t.MainQDV = s.MainQDV
			, t.MainQDV_DV = s.MainQDV_DV
			, t.MainPPV_DLV = s.MainPPV_DLV
			, t.MainDV_DLVDV = s.MainDV_DLVDV							
			,t.LastModifiedDate = GETDATE()
			--Greater China
			,t.[GCAssoc_TV]			= s.[GCAssoc_TV]
			,t.[GCAssoc_RO]			= s.[GCAssoc_RO]
			,t.[GCAssoc_PB]           = s.[GCAssoc_PB]           
			,t.[GCAssoc_PV]           = s.[GCAssoc_PV]           
			,t.[GCAssoc_GV]           = s.[GCAssoc_GV]           
			,t.[GCAssoc_PPV]          = s.[GCAssoc_PPV]          
			,t.[GCAssoc_OV]           = s.[GCAssoc_OV]           
			,t.[GCAssoc_DLV]          = s.[GCAssoc_DLV]          
			,t.[GCAssoc_MPV]          = s.[GCAssoc_MPV]          
			,t.[GCAssoc_MTV]          = s.[GCAssoc_MTV]          
			,t.[GCAssoc_DV]           = s.[GCAssoc_DV]           
			,t.[GCAssoc_PPC]          = s.[GCAssoc_PPC]          
			,t.[GCAssoc_PRV]          = s.[GCAssoc_PRV]          
			,t.[GCAssoc_NDV]          = s.[GCAssoc_NDV]          
			,t.[GCAssoc_SPC]          = s.[GCAssoc_SPC]          
			,t.[GCAssoc_SRV]          = s.[GCAssoc_SRV]          
			,t.[GCAssoc_PV_DV]        = s.[GCAssoc_PV_DV]        
			,t.[GCAssoc_PV_PPC]       = s.[GCAssoc_PV_PPC]       
			,t.[GCAssoc_PV_PRV]       = s.[GCAssoc_PV_PRV]       
			,t.[GCAssoc_PV_NDV]       = s.[GCAssoc_PV_NDV]       
			,t.[GCAssoc_PV_SPC]       = s.[GCAssoc_PV_SPC]       
			,t.[GCAssoc_PV_SRV]       = s.[GCAssoc_PV_SRV]       
			,t.[GCAssoc_DLV_DV]       = s.[GCAssoc_DLV_DV]       
			,t.[GCAssoc_DLV_PPC]      = s.[GCAssoc_DLV_PPC]      
			,t.[GCAssoc_DLV_PRV]      = s.[GCAssoc_DLV_PRV]      
			,t.[GCAssoc_DLV_NDV]      = s.[GCAssoc_DLV_NDV]      
			,t.[GCAssoc_DLV_SPC]      = s.[GCAssoc_DLV_SPC]      
			,t.[GCAssoc_DLV_SRV]      = s.[GCAssoc_DLV_SRV]      
			,t.[GCAssoc_GV_DV]        = s.[GCAssoc_GV_DV]        
			,t.[GCAssoc_GV_PPC]       = s.[GCAssoc_GV_PPC]       
			,t.[GCAssoc_GV_PRV]       = s.[GCAssoc_GV_PRV]       
			,t.[GCAssoc_GV_NDV]       = s.[GCAssoc_GV_NDV]       
			,t.[GCAssoc_GV_SPC]       = s.[GCAssoc_GV_SPC]       
			,t.[GCAssoc_GV_SRV]       = s.[GCAssoc_GV_SRV]       
			,t.[GCAssoc_EV]           = s.[GCAssoc_EV]           
			,t.[GCAssoc_UV]           = s.[GCAssoc_UV]           
			,t.[GCAssoc_MPCV]         = s.[GCAssoc_MPCV]         
			,t.[GCAssoc_TOTAL_POINTS] = s.[GCAssoc_TOTAL_POINTS] 
			,t.[GCAssoc_QCPV]         = s.[GCAssoc_QCPV]         
			,t.[GCAssoc_QDV]          = s.[GCAssoc_QDV]          
			,t.[GCAssoc_QDV_DV]       = s.[GCAssoc_QDV_DV]       
			,t.[GCAssoc_PPV_DLV]      = s.[GCAssoc_PPV_DLV]      
			,t.[GCAssoc_DV_DLVDV]  	= s.[GCAssoc_DV_DLVDV]   
	WHEN NOT MATCHED BY SOURCE THEN
		DELETE
OPTION (RECOMPILE);

END

SET @EndTime = GETUTCDATE()
 
  PRINT 'Step 115: Merge data to aggDSFinancial'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)

IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = '115' ,@StartTime = @StartTime

END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
IF @Step =  23 OR (@fp = 1 AND @Step >= 23)
BEGIN

/******************************************************************************
	Update Stats on aggDSFinancial
******************************************************************************/

SET @StartTime = GETUTCDATE()

BEGIN TRY  
    IF @EnabledStats = 1 AND @IsDevQA = 0 
	BEGIN
	   PRINT 'Updating statistics on aggDSFinancial...'
		UPDATE STATISTICS pubEvents.dbo.aggDSFinancial  
		PRINT 'Statistics updated successfully on aggDSFinancial.'
	END
END TRY
BEGIN CATCH    
       PRINT 'Error occurred while updating statistics.'   
END CATCH

SET @EndTime = GETUTCDATE()

  PRINT 'Step final: Update Stats on aggDSFinancial'
  PRINT 'StartTime = ' + CONVERT(VARCHAR(30),@StartTime,121)
  PRINT 'EndTime = ' + CONVERT(VARCHAR(30),@EndTime,121)
  PRINT 'Duration = ' + CONVERT(VARCHAR(30),@EndTime -@starttime,114)


IF @IsDevQA = 0 EXEC usp_Utility_UpdateProcessingLog @StoredProcedureName = @StoredProcedure ,@StoredProcedureParameters = 'Final' ,@StartTime = @StartTime
  
END


END
END
 