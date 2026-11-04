CREATE PROCEDURE [dbo].[usp_AWT_ins_Qualifiers]
	@AWTYear int

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_AWT_ins_Qualifiers

USE:			DECLARE @e int, @em varchar(max)
			
				EXEC dbo.usp_AWT_ins_Qualifiers
					 @AWTYear = 2009
					,@Error = @e OUTPUT
					,@ErrorMessage = @em OUTPUT
					,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	get list of everyone who currenly qualifies and everyone who has
				already qualified not in the current qualifier list and
				insert into dbo.AWT

DEPENDENCIES
--------------------------------------------------------------------
everything

VERSIONS
--------------------------------------------------------------------
1	2010-01-05	Scott			Initial
1.1 2016-07-06  Emi				modify Jan/Feb Qual to commodate 5k 2m new qual   
								Also add logic to populate didAWT field instead of using compute column
1.2 2017-06-01  Ini				Add logic to implement 5K in one month for US and PR from May 2017
1.3 2019-10-01	alejandramed	SRE Compliance 
1.4 2020-07-07  Emi				populate PastAWT
1.5 2020-08-13  Emi				fix bug where NULL is populate for PastAWT 
1.6 2020-09-11  Emi				fix bug PastAWT MAX pick no over real PastAWT value
1.7	2025-04-09	alejandramed	User Story 1409217: 25072 - AWT 2025 - Qualifications SAMCAM/MX
1.8	2026-02-20	alejandramed	Removing the didAcc10KTV2CML6M criterion from the JanFebQuals logic, since the SAMCAM region is no longer eligible for the promotion.
1.8	2026-02-20	alejandramed	Including the didAcc10KTV2CML6M criteria since the report will run WW again.
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	/******************************************************************************
		delete any previous records for @AWTYear
	******************************************************************************/
	DELETE FROM dbo.AWT WHERE AWTYear = @AWTYear

	/******************************************************************************
		get list of everyone who currenly qualifies and everyone who has
		already qualified not in the current qualifier list
	******************************************************************************/
	DECLARE
		@Start4CM2500 smalldatetime = CONVERT(varchar,@AWTYear-1) + '/10/1'
		,@End4CM2500Jan smalldatetime = CONVERT(varchar,@AWTYear) + '/1/1'
		,@MaxRoyaltyMonth smalldatetime
		,@StartMonthDV_USPR smalldatetime = '2017-05-01'
		,@StartMonthDV_SAMCAM_MX smalldatetime = '2024-12-01'

	SELECT  @MaxRoyaltyMonth = MAX(RoyaltyMonth) FROM dbo.AWT_Metrics WITH (NOLOCK)
	
	DROP TABLE IF EXISTS #SAMCAM_MX_COP  
	 
		SELECT 'AA' AS [COP]
		INTO #SAMCAM_MX_COP
		UNION
		SELECT 'AR' AS [COP] UNION
		SELECT 'BL' AS [COP] UNION
		SELECT 'BR' AS [COP] UNION
		SELECT 'CI' AS [COP] UNION
		SELECT 'CO' AS [COP] UNION
		SELECT 'CR' AS [COP] UNION
		SELECT 'DR' AS [COP] UNION
		SELECT 'EC' AS [COP] UNION
		SELECT 'GT' AS [COP] UNION
		SELECT 'HN' AS [COP] UNION
		SELECT 'NI' AS [COP] UNION
		SELECT 'PE' AS [COP] UNION
		SELECT 'PM' AS [COP] UNION
		SELECT 'PY' AS [COP] UNION
		SELECT 'SV' AS [COP] UNION
		SELECT 'UY' AS [COP] UNION
		SELECT 'VE' AS [COP] UNION
		SELECT 'MX' AS [COP] 

	IF OBJECT_ID ('tempdb..#JanFebQualifiers') IS NOT NULL DROP TABLE #JanFebQualifiers

	BEGIN

	;WITH 
		JanFebQuals (PK_Distributor,RoyaltyMonth) AS
		(
			/* EVERYONE WHO DID 4CM2500K ENDING JAN OF MHBYEAR */
			SELECT
				PK_Distributor
				,@End4CM2500Jan [RoyaltyMonth]
			FROM
				dbo.AWT_Metrics WITH (NOLOCK)
			WHERE
				RoyaltyMonth BETWEEN @Start4CM2500 AND @End4CM2500Jan
				AND did2500KTV = 1
			GROUP BY
				PK_Distributor
			HAVING
				SUM(did2500KTV) = 4

			UNION

			/* EVERYONE WHO DID 4CM2500K ENDING FEB OF MHBYEAR */
			SELECT
				PK_Distributor
				,DATEADD(m,1,@End4CM2500Jan) [RoyaltyMonth]
			FROM
				dbo.AWT_Metrics WITH (NOLOCK)
			WHERE
				RoyaltyMonth BETWEEN DATEADD(m,1,@Start4CM2500) AND DATEADD(m,1,@End4CM2500Jan)
				AND did2500KTV = 1
			GROUP BY
				PK_Distributor
			HAVING
				SUM(did2500KTV) = 4
			
			UNION	

			/* EVERYONE WHO DID 10K JAN OR FEB */
			SELECT 
				PK_Distributor
				,RoyaltyMonth [RoyaltyMonth]
			FROM
				dbo.AWT_Metrics WITH (NOLOCK)
			WHERE
				RoyaltyMonth BETWEEN DATEADD(m,3,@Start4CM2500) AND DATEADD(m,4,@Start4CM2500)
				AND did10KTV = 1
			
			UNION	
			
			/* EVERYONE WHO DID 500RO JAN OR FEB */
			SELECT 
				PK_Distributor
				,RoyaltyMonth [RoyaltyMonth]
			FROM
				dbo.AWT_Metrics WITH (NOLOCK)
			WHERE
				RoyaltyMonth BETWEEN DATEADD(m,3,@Start4CM2500) AND DATEADD(m,4,@Start4CM2500)
				AND did500RO = 1

			UNION 

			/* EVERYONE WHO DID 5K 2M JAN OR FEB */
			SELECT 
				PK_Distributor
				,RoyaltyMonth [RoyaltyMonth]
			FROM
				dbo.AWT_Metrics A WITH (NOLOCK)
			JOIN 
				dbo.AWT_Promo P WITH (NOLOCK)
					ON A.COP = P.COP
			WHERE
				RoyaltyMonth BETWEEN DATEADD(m,3,@Start4CM2500) AND DATEADD(m,4,@Start4CM2500)
				AND did5KTV = 1
				AND A.RoyaltyMonth >= P.StartMonth
				AND (P.EndMonth IS NULL OR A.RoyaltyMonth < P.EndMonth)

			UNION	
			
			/* EVERYONE FROM US AND PR WHO DID 5K JAN OR FEB AFTER MAY 2017 */
			SELECT 
				PK_Distributor
				,RoyaltyMonth [RoyaltyMonth]
			FROM
				dbo.AWT_Metrics WITH (NOLOCK)
			WHERE
				RoyaltyMonth BETWEEN DATEADD(m,3,@Start4CM2500) AND DATEADD(m,4,@Start4CM2500)
				AND did5KTV = 1
				AND COP IN ('US','PR')
				AND RoyaltyMonth > @StartMonthDV_USPR
			UNION
				/* EVERYONE WHO ACC 10K ON JAN OR FEB */
			SELECT 
				PK_Distributor
				,RoyaltyMonth [RoyaltyMonth]
			FROM
				dbo.AWT_Metrics AS m WITH (NOLOCK)
					INNER JOIN #SAMCAM_MX_COP AS c
						ON m.COP = c.COP
			WHERE
				RoyaltyMonth BETWEEN DATEADD(m,3,@Start4CM2500) AND DATEADD(m,4,@Start4CM2500)
				AND didAcc10KTV2CM = 1


		)
	/* SELECT ALL THE RECORDS FROM THE JANFEBQUALIFIERS INTO A TEMP TABLE */

	SELECT
		PK_Distributor,RoyaltyMonth
	INTO
		#JanFebQualifiers
	FROM
		JanFebQuals

	/* CREATE INSEXES ON THE PK_DISTRIBUTOR COLUMN ON THE JANFEB QUALIFIERS TEMP TABLE */
	CREATE INDEX IX_#JanFebQUalifiers_PK_Distributor ON #JanFebQualifiers(PK_Distributor)
	CREATE INDEX IX_#JanFebQUalifiers_RoyaltyMonth ON #JanFebQualifiers(RoyaltyMonth)

	/* UPDATE THE AWT_METRICS TABLE FOR THE NEW FLAG */
	UPDATE
		T
	SET
		[didAWTJanFeb] = 1
	FROM
		dbo.AWT_Metrics T
	INNER JOIN
		#JanFebQualifiers J
	ON
		T.PK_Distributor = J.PK_Distributor
		AND T.RoyaltyMonth = J.RoyaltyMonth

	/* POPULATE didAWT FLAG*/

	; WITH cte_didAWT AS
	(
		SELECT
			A.PK_Distributor,
			A.RoyaltyMonth,
			CASE WHEN did2500KTVL6M = 1 -- 2500 4CM 
					  AND 
						(
							did10KTVL6M = 1 OR (P.COP IS NOT NULL AND did5KTVL6M = 1) OR (A.COP IN ('US','PR') AND did5KTVL6M = 1 AND A.RoyaltyMonth >= @StartMonthDV_USPR) -- 10K volume month or 5K in 2M for promo countries or 5K in 1M for COP US/PR from May 2017
							OR (c.COP IS NOT NULL AND didAcc10KTV2CML6M = 1 AND A.RoyaltyMonth >= @StartMonthDV_SAMCAM_MX) --OR 10K ACC 2CM for SAMCAM and MX
					  
						) 
					  AND did500ROL6M = 1 -- 500 RO 1M
					  AND datepart(year, RoyaltyMonth)= AWTYear 
					  AND ((datepart(month,RoyaltyMonth) <= 2 AND didAWTJanFeb = 1) OR datepart(month,RoyaltyMonth) > 2) 
				 THEN 1 
				 ELSE 0 
			END AS didAWT
		FROM 
			dbo.AWT_Metrics A WITH (NOLOCK)
		LEFT JOIN 
			dbo.AWT_Promo P WITH (NOLOCK)
			ON A.COP = P.COP
				AND A.RoyaltyMonth >= P.StartMonth
				AND (P.EndMonth IS NULL OR A.RoyaltyMonth < P.EndMonth)
		LEFT JOIN #SAMCAM_MX_COP AS c
			ON  A.COP = c.COP
	)

	UPDATE
		A
	SET 
		didAWT = 1
	FROM 
		dbo.AWT_Metrics A
	JOIN
		cte_didAWT T
		ON A.PK_Distributor = T.PK_Distributor
			AND A.RoyaltyMonth = T.RoyaltyMonth
	WHERE T.didAWT = 1


	/* HANDLE THE REST OF THE CONDITIONS */
		;WITH ManualOverride (PK_Distributor, Qual_AWT) AS
		(
			SELECT  
				PK_Distributor
				,Qual_AWT
			FROM 
				dbo.AWT_ManualOverride AM WITH (NOLOCK)
			WHERE
				AWTYear = @AWTYear
				AND
				NOT EXISTS (SELECT 1 FROM dbo.AWT A WITH (NOLOCK) WHERE AWTYear = @AWTYear AND A.PK_Distributor = AM.PK_Distributor AND A.Qual_AWT = AM.Qual_AWT)
		)
		,CurrentJanFebQualifiers (PK_Distributor, Qual_AWT) AS
		(
			SELECT  
				A.PK_Distributor
				,MIN(JFQ.RoyaltyMonth)
			FROM 
				dbo.AWT_Metrics A WITH (NOLOCK)
			LEFT JOIN
				ManualOverride Q WITH (NOLOCK)
				ON
					A.PK_Distributor = Q.PK_Distributor
			INNER JOIN
				(SELECT PK_Distributor, RoyaltyMonth [RoyaltyMonth] FROM #JanFebQualifiers) JFQ
				ON
					A.PK_Distributor = JFQ.PK_Distributor
				AND 
					A.RoyaltyMonth = JFQ.RoyaltyMonth
			WHERE 
				A.didAWT = 1
				AND Q.PK_Distributor IS NULL
			GROUP BY
				A.PK_Distributor
		)
		,CurrentQualifiers (PK_Distributor, Qual_AWT) AS
		(
			SELECT  
				A.PK_Distributor
				,MIN(A.RoyaltyMonth)
			FROM 
				dbo.AWT_Metrics A WITH (NOLOCK)
			LEFT JOIN
				ManualOverride Q WITH (NOLOCK)
				ON
					A.PK_Distributor = Q.PK_Distributor
			WHERE 
				A.didAWT = 1
				AND Q.PK_Distributor IS NULL
			GROUP BY
				A.PK_Distributor
		)
		,PastQualiers (PK_Distributor, Qual_AWT, PastAWT) AS
		(
			SELECT
				A.PK_Distributor
				,MIN(A.Qual_AWT)
				,MAX(A.PastAWT)
			FROM
				dbo.AWT_PrevQualifiers A WITH (NOLOCK)
			WHERE
				A.AWTYear = @AWTYear
			GROUP BY
				A.PK_Distributor
		)

	INSERT
		dbo.AWT
	(
		AWTYear
		,PK_Distributor
		,Qual_AWT
		,PastAWT
	)
	SELECT AWTYear, PK_Distributor, MIN(Qual_AWT) AS Qual_AWT, ISNULL(NULLIF(MAX(PastAWT),''),'No') AS PastAWT
	FROM
	(
	SELECT @AWTYear AS AWTYear, PK_Distributor, Qual_AWT, NULL AS PastAWT FROM ManualOverride
	UNION ALL SELECT @AWTYear AS AWTYear, PK_Distributor, CASE WHEN Qual_AWT <= '2012-01-01' THEN '2012-01-01' ELSE Qual_AWT END, '' AS PastAWT  FROM CurrentJanFebQualifiers
	UNION ALL SELECT @AWTYear AS AWTYear, PK_Distributor, CASE WHEN Qual_AWT <= '2012-01-01' THEN '2012-01-01' ELSE Qual_AWT END, '' AS PastAWT  FROM CurrentQualifiers
	UNION ALL SELECT @AWTYear AS AWTYear, PK_Distributor, Qual_AWT, PastAWT FROM PastQualiers
	) QL
	GROUP BY AWTYear, PK_Distributor

	END

	/******************************************************************************
		End procedure
	******************************************************************************/

	-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
	END CATCH;
END;