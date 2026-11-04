CREATE PROCEDURE [dbo].[usp_AWT_DetermineQualifiers]
	@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_AWT_DetermineQualifiers

USE:			dbo.usp_AWT_DetermineQualifiers

DESCRIPTION:	determines awt qualifiers


DEPENDENCIES
--------------------------------------------------------------------
everything

VERSIONS
--------------------------------------------------------------------
1	2010-01-05	Scott	Initial
1.1 2015-10-09  Emi     Add did5KTV and did5KTVL6M 
1.2 2016-07-12  Emi     Use AWT_Promo for did5KTVL6M
1.3 2017-06-01  Ini		Add logic for 5K in one month for US and PR from May 2015
1.4	2017-08-10	ThomasG	Ensure that did5KTVL6M is set for any months after 5K has been reached
						on or after May 2017 for US/PR countries, up to 5 months after
1.5	2025-04-09	alejandramed	User Story 1409217: 25072 - AWT 2025 - Qualifications SAMCAM/MX
1.6	2025-07-17	alejandramed	Bug 1421353: 25072 - AWT 2025 - Qualifications SAMCAM/MX -- Incorrect Qual AWT date
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StartMonthDV_USPR smalldatetime = '2017-05-01'

/******************************************************************************
	determine who did 2 months 5k TV in last 6 months
******************************************************************************/
;WITH 
	Last6Months (PK_Distributor, RoyaltyMonth) AS
	(
		SELECT
			M1.PK_Distributor
			,M1.RoyaltyMonth
		FROM
			dbo.AWT_Metrics M1 WITH(NOLOCK)
		INNER JOIN
			dbo.AWT_Metrics M2 WITH(NOLOCK)
			ON
				M2.RoyaltyMonth BETWEEN DATEADD(m,-5,M1.RoyaltyMonth) AND M1.RoyaltyMonth
				AND M1.PK_Distributor = M2.PK_Distributor
		INNER JOIN 
			dbo.AWT_Promo P WITH(NOLOCK)
			ON	
				M1.COP = P.COP				
		WHERE 
			M1.RoyaltyMonth >= P.StartMonth
			AND
			M2.RoyaltyMonth >= P.StartMonth
		GROUP BY
			M1.PK_Distributor
			,M1.RoyaltyMonth
		HAVING
			SUM(M2.did5KTV) >= 2
	)
UPDATE
	M
SET
	did5KTVL6M = 1
FROM
	dbo.AWT_Metrics M
INNER JOIN
	Last6Months L6M
	ON
		M.PK_Distributor = L6M.PK_Distributor
		AND M.RoyaltyMonth = L6M.RoyaltyMonth

/****************************************************************************************************
	determine who did 5k TV in 1 month in the last 6 months from May 2017 ONLY from COP US and PR
****************************************************************************************************/
;WITH 
	Last6Months5KDV (PK_Distributor, RoyaltyMonth) AS
	(
		SELECT
			M1.PK_Distributor
			,M1.RoyaltyMonth
		FROM
			dbo.AWT_Metrics M1 WITH(NOLOCK)	
		WHERE 
			M1.RoyaltyMonth >= @StartMonthDV_USPR
			AND
			M1.COP IN ('US','PR')
		GROUP BY
			M1.PK_Distributor
			,M1.RoyaltyMonth
		HAVING
			SUM(M1.did5KTV) >= 1
	)
UPDATE
	M
SET
	did5KTVL6M = 1
FROM
	dbo.AWT_Metrics M
INNER JOIN
	Last6Months5KDV L6M
	ON
		M.PK_Distributor = L6M.PK_Distributor
		-- Ensure that did5KTVL6M is set for any months after 5K has been reached
		-- on or after May 2017 for US/PR countries, up to 5 months after
		AND M.RoyaltyMonth Between L6M.RoyaltyMonth And DateAdd(mm,5,L6M.RoyaltyMonth)

/******************************************************************************
	determine who did 4 consecutive months 2500k TV in last 6 months
******************************************************************************/
;WITH 
	FourConsecutiveMonths (PK_Distributor, RoyaltyMonth) AS
	(
		SELECT
			M1.PK_Distributor
			,M1.RoyaltyMonth
		FROM
			dbo.AWT_Metrics M1 WITH(NOLOCK)
		INNER JOIN
			dbo.AWT_Metrics M2 WITH(NOLOCK)
			ON
				M2.RoyaltyMonth BETWEEN DATEADD(m,-3,M1.RoyaltyMonth) AND M1.RoyaltyMonth
				AND M1.PK_Distributor = M2.PK_Distributor
		GROUP BY
			M1.PK_Distributor
			,M1.RoyaltyMonth
		HAVING
			SUM(M2.did2500KTV) = 4
	)
	,Last6Months (PK_Distributor, RoyaltyMonth) AS
	(
		SELECT
			M1.PK_Distributor
			,M1.RoyaltyMonth
		FROM
			dbo.AWT_Metrics M1 WITH(NOLOCK)
		INNER JOIN
			FourConsecutiveMonths M2
			ON
				M1.RoyaltyMonth BETWEEN M2.RoyaltyMonth AND DATEADD(m,2,M2.RoyaltyMonth)
				AND M1.PK_Distributor = M2.PK_Distributor
		GROUP BY
			M1.PK_Distributor
			,M1.RoyaltyMonth
		HAVING
			COUNT(M2.PK_Distributor) > 0
	)
UPDATE
	M
SET
	did2500KTVL6M = 1
FROM
	dbo.AWT_Metrics M
INNER JOIN
	Last6Months L6M
	ON
		M.PK_Distributor = L6M.PK_Distributor
		AND M.RoyaltyMonth = L6M.RoyaltyMonth

/******************************************************************************
	determine who did 10000k TV in last 6 months
******************************************************************************/
;WITH 
	Last6Months (PK_Distributor, RoyaltyMonth) AS
	(
		SELECT
			M1.PK_Distributor
			,M1.RoyaltyMonth
		FROM
			dbo.AWT_Metrics M1 WITH(NOLOCK)
		INNER JOIN
			dbo.AWT_Metrics M2 WITH(NOLOCK)
			ON
				M2.RoyaltyMonth BETWEEN DATEADD(m,-5,M1.RoyaltyMonth) AND M1.RoyaltyMonth
				AND M1.PK_Distributor = M2.PK_Distributor
		GROUP BY
			M1.PK_Distributor
			,M1.RoyaltyMonth
		HAVING
			SUM(M2.did10KTV) > 0
	)
UPDATE
	M
SET
	did10KTVL6M = 1
FROM
	dbo.AWT_Metrics M
INNER JOIN
	Last6Months L6M
	ON
		M.PK_Distributor = L6M.PK_Distributor
		AND M.RoyaltyMonth = L6M.RoyaltyMonth

/******************************************************************************
	determine who did 500 RO in last 6 months
******************************************************************************/
;WITH 
	Last6Months (PK_Distributor, RoyaltyMonth) AS
	(
		SELECT
			M1.PK_Distributor
			,M1.RoyaltyMonth
		FROM
			dbo.AWT_Metrics M1 WITH(NOLOCK)
		INNER JOIN
			dbo.AWT_Metrics M2 WITH(NOLOCK)
			ON
				M2.RoyaltyMonth BETWEEN DATEADD(m,-5,M1.RoyaltyMonth) AND M1.RoyaltyMonth
				AND M1.PK_Distributor = M2.PK_Distributor
		GROUP BY
			M1.PK_Distributor
			,M1.RoyaltyMonth
		HAVING
			SUM(M2.did500RO) > 0
	)
UPDATE
	M
SET
	did500ROL6M = 1
FROM
	dbo.AWT_Metrics M
INNER JOIN
	Last6Months L6M
	ON
		M.PK_Distributor = L6M.PK_Distributor
		AND M.RoyaltyMonth = L6M.RoyaltyMonth

/******************************************************************************
	determine who did 10,000 TV accumulated in 2 consecutive months in the last 6 months
******************************************************************************/
 
DECLARE @StartMonthDV_SAMCAM_MX smalldatetime = '2024-12-01'

DROP TABLE IF EXISTS #AccPeriods

SELECT IDENTITY(INT, 1,1) AS Id,p.StartDate AS StartDate6M, p.EndDate AS EndDate6M, pp.StartDate AS StartDate2M, pp.EndDate AS EndDate2M
INTO #AccPeriods
FROM [dbo].[ufn_GetPeriods](@StartMonthDV_SAMCAM_MX,DATEADD(month, DATEDIFF(month, 0,DATEADD(MM,-1,GETUTCDATE())),0),6,1,1) AS p
	CROSS APPLY [dbo].[ufn_GetPeriods](p.StartDate,p.EndDate,2,1,1) AS pp
 
DROP TABLE IF EXISTS #ACC10K2CMPeriods 
 
SELECT PK_Distributor,p.Id
INTO #ACC10K2CMPeriods
FROM AWT_Metrics AS m WITH (NOLOCK) 
	INNER JOIN #AccPeriods AS p 	
		ON m.RoyaltyMonth BETWEEN p.StartDate2M AND p.EndDate2M
		AND m.RoyaltyMonth BETWEEN p.StartDate6M AND p.EndDate6M
GROUP BY PK_Distributor,p.Id
HAVING SUM([TV]+[TV_Accelerator]) >= 10000
 
DROP TABLE IF EXISTS #ACC10K2CMQualifiers
 
SELECT DISTINCT M.PK_Distributor,M.RoyaltyMonth,p.StartDate2M,p.EndDate2M
INTO #ACC10K2CMQualifiers
FROM AWT_Metrics AS M	
INNER JOIN #ACC10K2CMPeriods AS acc
ON M.PK_Distributor = acc.PK_Distributor
INNER JOIN #AccPeriods AS p
	ON acc.Id = p.Id  
	AND M.RoyaltyMonth BETWEEN p.StartDate2M AND p.EndDate2M
 
 UPDATE
	M
SET
	didAcc10KTV2CM = 1
FROM
	[dbo].[AWT_Metrics] AS M
	INNER JOIN #ACC10K2CMQualifiers AS Q
		ON M.PK_Distributor = Q.PK_Distributor AND M.RoyaltyMonth = Q.RoyaltyMonth


/******************************************************************************
	determine who accumulated 10000k TV in 3 CM in the last 6 months
******************************************************************************/
;WITH 
	Last6Months (PK_Distributor, RoyaltyMonth) AS
	(
		SELECT
			M1.PK_Distributor
			,M1.RoyaltyMonth
		FROM
			dbo.AWT_Metrics M1 WITH(NOLOCK)
		INNER JOIN
			dbo.AWT_Metrics M2 WITH(NOLOCK)
			ON
				M2.RoyaltyMonth BETWEEN DATEADD(m,-5,M1.RoyaltyMonth) AND M1.RoyaltyMonth
				AND M1.PK_Distributor = M2.PK_Distributor
		GROUP BY
			M1.PK_Distributor
			,M1.RoyaltyMonth
		HAVING SUM(M2.didAcc10KTV2CM) >= 2
	)
UPDATE
	M
SET
	didAcc10KTV2CML6M = 1
FROM
	dbo.AWT_Metrics M
INNER JOIN
	Last6Months L6M
	ON
		M.PK_Distributor = L6M.PK_Distributor
		AND M.RoyaltyMonth = L6M.RoyaltyMonth


/******************************************************************************
	end procedure
******************************************************************************/
END