
CREATE PROCEDURE [dbo].[usp_NAM_DV_Promo] 
	@DistributorID VARCHAR(20) 
   -- Error Parameters
	,@Error INT OUTPUT
	,@ErrorMessage VARCHAR(200) OUTPUT
	
	-- QA/DEV
	,@IsDevQA bit = 0
AS
/******************************************************************************
OBJECT:			dbo.usp_NAM_DV_Promo

USE:	        
			declare @e int
			declare @em varchar(200)
			declare @IsDevQA int			
	EXEC usp_NAM_DV_Promo   '10Y0297909'  ,@e output ,@em output
--'10Y0297909' --'10Y0298843'


DESCRIPTION:	This is the main custom stored procedure that retrieves the data using Linked Server for the 
                NAM Documented Volume Promo Mini Ipad that is build in BIETL

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.agg_NAM_DV_Promo -> for DEV2
dbo.agg_NAM_DV_Promo -> for QA2
VERSIONS
----------------------------------------------------------------------------------
1	2017-02-13	Juan	Intitial
2   2017-02-16  Juan	Info based on RoyaltyMonth 
3   2017-02-23  Juan	inluded myDV column 
4	2017-02-27  Juan    Send @hasDL in 3rd Column
5	2017-03-03  Juan	Added the isQualified Column to be consumed by .Net & ActiveDL
6	2017-04-03  Juan	Added HasActiveDL Column on first resultset (by month)

******************************************************************************/

IF OBJECT_ID('tempdb..#agg_NAM_DV_Promo','U') IS NOT NULL DROP TABLE #agg_NAM_DV_Promo

CREATE TABLE #agg_NAM_DV_Promo 
(
	RoyaltyMonth DATE,
	PK_Distributor INT,
	DistributorID VARCHAR(20),
	UL_COP CHAR(2),
	HasActiveDL BIT DEFAULT 0,
	PK_DSDownline INT,
	DownlineID VARCHAR(20),
	SPLevel INT,
	DL_COP CHAR(2),
	DLTypeCode VARCHAR(3),
	Receipts INT DEFAULT 0,
	TV money DEFAULT 0,
	PRV money DEFAULT 0,
	DV money DEFAULT 0,
	PPC money DEFAULT 0,	
	DVPerc money DEFAULT 0,
	[Status] BIT DEFAULT 0)

CREATE INDEX IX_agg_NAM_DV_Promo_DistributorID ON #agg_NAM_DV_Promo (DistributorID) INCLUDE (SPLevel,HasActiveDL,DL_COP)
CREATE INDEX IX_agg_NAM_DV_Promo_PK_Distributor_PK_DsDownline ON #agg_NAM_DV_Promo (PK_Distributor,PK_DSDownline)

INSERT INTO #agg_NAM_DV_Promo
(
	RoyaltyMonth,
	PK_Distributor,
	DistributorID ,
	UL_COP ,
	HasActiveDL ,
	PK_DSDownline ,
	DownlineID ,
	SPLevel ,
	DL_COP ,
	DLTypeCode ,
	Receipts ,
	TV ,
	PRV ,
	DV ,
	PPC ,	
	DVPerc,
	[Status]
)
SELECT  
	RoyaltyMonth,
	PK_Distributor,
	DistributorID ,
	UL_COP ,
	HasActiveDL ,
	PK_DSDownline ,
	DownlineID ,
	SPLevel ,
	DL_COP ,
	DLTypeCode ,
	Receipts ,
	TV ,
	PRV ,
	DV ,
	PPC ,	
	DVPerc,
	CASE WHEN IsQualified = -1 THEN 0 ELSE IsQualified END AS [Status]
FROM 
	dbo.agg_NAM_DV_Promo --(QA & PROD)
WHERE 
	DistributorID = @DistributorID

DECLARE @DisplayDate DATE = DATEADD(d,-1,GETDATE()) --On 1st day of Month still display previous month

DECLARE @HasDL BIT = (SELECT HasActiveDL	
						FROM #agg_NAM_DV_Promo 
						WHERE PK_Distributor = PK_DSDownline 
						AND MONTH(RoyaltyMonth) = MONTH(@DisplayDate))  --DL Count will remain over the course of the promotion
						

/***********   Individual Progress *******************/

SELECT 
	DistributorID,
	MONTH(RoyaltyMonth) AS [Month],
	CASE WHEN Receipts > 0 THEN 1 ELSE 0 END AS Receipt,
	ISNULL(TV,0) AS TV,
	CASE HasActiveDL WHEN 1 THEN ISNULL(DVPerc * 100,0.00) ELSE CASE WHEN TV =  0 THEN 0.00 ELSE ISNULL (DV/TV,0)*100 END END AS DV,
	CASE WHEN TV =  0 THEN 0.00 ELSE ISNULL (DV/TV,0) END *100  AS myDV,
	[Status],
	HasActiveDL 
FROM
	#agg_NAM_DV_Promo
WHERE 
	RoyaltyMonth IN ('2017-02-01','2017-03-01','2017-04-01')
	AND
	PK_Distributor = PK_DSDownline
ORDER by [Month]

/**** Level Summary Details *****/
IF @HasDL = 0
	SELECT 
	'' AS RoyaltyMonth,
	'' AS DistributorID,
	'' AS SPLevel,
	'' AS TV,
	'' AS HasReceipt,
	'' AS DV
	WHERE 1<>1
ELSE
SELECT
	RoyaltyMonth
	,DistributorID
	,SPLevel-1 AS SPLevel 
	,SUM(TV) AS TV
	,(SUM(CASE WHEN Receipts > 0 THEN 1.00 ELSE 0 END)/COUNT(1))*100 AS HasReceipt
	,CASE WHEN SUM(TV) = 0 THEN 0.00 ELSE ISNULL(SUM(DV) / SUM(TV),0) END *100 AS DV	
FROM
	#agg_NAM_DV_Promo 
WHERE
	SPLevel > 1
	AND
	RoyaltyMonth IN ('2017-02-01' , '2017-03-01' ,'2017-04-01')
GROUP BY
	RoyaltyMonth
	,DistributorID
	,SPLevel
ORDER BY RoyaltyMonth,SPLevel

SELECT ISNULL(@HasDL,0) AS HasDL