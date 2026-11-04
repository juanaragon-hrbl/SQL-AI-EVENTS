CREATE PROCEDURE [dbo].[usp_AWT_PotentialsReport]
	
	@AWTYear INT 

	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG
AS 
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_AWT_PotentialsReport]
	
	USE:			
			DECLARE @e int, @em varchar(max)
			
			EXEC [dbo].[usp_AWT_PotentialsReport]
				@AWTYear = 2021
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION: This populate the dbo.AWT_PotentialsReport_WW table which is used on AWT Potencials BI dashboard	

	NOTES: This has to be run manually every month after AWT process runs

	DEPENDENCIES
	------------------------------------------------------------------
	usp_AWT_MAIN

	VERSIONS
	------------------------------------------------------------------
	1.0.0		2021-08-19		alejandramed		Initial
	
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

IF EXISTS (SELECT 1 FROM [DevAdmin].[ScheduleException] WITH (NOLOCK)
WHERE Active = 1 AND CONVERT(DATE,GETUTCDATE()) BETWEEN StartDate AND EndDate
AND TRIM(REPLACE(REPLACE([StoredProcedureName],'[',''),']','')) = TRIM(REPLACE(REPLACE(@StoredProcedure,'[',''),']','')))
BEGIN
	PRINT 'ScheduleException; The process is skipped.'
	RETURN;
END
ELSE 
BEGIN

BEGIN TRY

	IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1
		END

	DECLARE @StartMonth DATETIME,
			@EndMonth DATETIME

	SELECT @EndMonth = MAX(RoyaltyMonth) FROM dbo.AWT_Metrics WITH(NOLOCK) WHERE AWTYear = @AWTYear

	SELECT @StartMonth = DATEADD(MONTH,-5,@EndMonth)

	DROP TABLE IF EXISTS #Metrics

	;WITH cte_DID4CM2500TVL6M AS
	(
		SELECT 
			 DistributorID
			,ISNULL(did2500KTVL6M,0) AS DID4CM2500TVL6M
		FROM AWT_Metrics WITH (NOLOCK)
		WHERE RoyaltyMonth = @EndMonth
	),cte_DID5KTVL6M AS
	(
		SELECT 
			 DistributorID
			,ISNULL(DID5KTVL6M,0) AS DID5KTVL6M
		FROM AWT_Metrics WITH (NOLOCK)
		WHERE RoyaltyMonth = @EndMonth
	),cte_5get5 AS
	(
		SELECT 
			 DistributorID
		FROM AWT_Metrics WITH (NOLOCK)
		WHERE RoyaltyMonth BETWEEN @StartMonth AND @EndMonth
		AND TV_Accelerator = 5000
	)

	SELECT 
	r.*,
	CASE WHEN Promo5get5 = 1 AND DID10KTV = 1 THEN 1 ELSE CASE WHEN DID5KTVL6M + DID10KTV > 1 THEN 1 ELSE 0 END END + DID4CM2500TVL6M + DID500RO AS Criteria
	INTO #Metrics
	FROM 
	(
	SELECT
	t.*
	,c.sRegionCode
	FROM (
		SELECT S.DistributorID
			,S.COP
			,MAX(ISNULL(DID2500ktv,0)) AS DID2500KTV
			,MAX(ISNULL(M.DID4CM2500TVL6M,0)) AS DID4CM2500TVL6M
			,MAX(ISNULL(did5KTV,0)) AS DID5KTV
			,ISNULL(MAX(N.did5KTVL6M),0) AS DID5KTVL6M
			,MAX(ISNULL(did500RO,0)) AS DID500RO
			,MAX(ISNULL(did10KTV,0)) AS DID10KTV
			,MAX(IIF(P.DistributorID IS NULL,0,1)) AS Promo5get5
			,MAX(IIF(A.Qual_AWT IS NULL,0,1)) AS DIDAWT
	FROM AWT_Metrics AS S WITH (NOLOCK) 
	LEFT JOIN cte_DID4CM2500TVL6M AS M
		ON S.DistributorID = m.DistributorID
	LEFT JOIN cte_DID5KTVL6M AS N
		ON S.DistributorID = N.DistributorID
	LEFT JOIN cte_5get5 AS P
		ON S.DistributorID = P.DistributorID
	LEFT JOIN dbo.AWT AS A WITH (NOLOCK)
		ON S.PK_Distributor = A.PK_Distributor AND A.AWTYear = @AWTYear
	WHERE RoyaltyMonth >= @StartMonth
	GROUP BY S.DistributorID,S.COP
	) AS t
	INNER JOIN dbo.v_Countries AS c
		ON t.COP = c.sCountryCodeISO
	WHERE DIDAWT = 0
		--AND t.COP != 'CN' 
	) AS r

	DROP TABLE IF EXISTS #MetricsFiltered

	SELECT DistributorID
			,D.nDistributorID AS PK_Distributor
			,COP
			,DID2500KTV
			,DID4CM2500TVL6M
			,DID5KTV
			,DID5KTVL6M
			,DID500RO
			,DID10KTV
			,DIDAWT
			,Promo5get5
	INTO #MetricsFiltered
	FROM #Metrics AS M
		INNER JOIN v_Distributor AS D
			ON M.DistributorID = D.sDistributorID
	WHERE Criteria >= 2

	---------------------------------------------------------------------------------------------
	DECLARE @Year int = 2006
	DECLARE @NonTABDate smalldatetime

	SELECT @NonTABDate = NonTABDate FROM dbo.AWT_Definitions WITH (NOLOCK) WHERE AWTYear = @AWTYear

	DROP TABLE IF EXISTS #PotentialsInfo

	CREATE TABLE #PotentialsInfo
	(
		[PK_Distributor] INT,
		[DistributorID] VARCHAR(50),
		[DsName] VARCHAR(350),
		[DS Subtype] VARCHAR(10),
		[Region] VARCHAR(30),
		[COP] VARCHAR(5),
		[Email] VARCHAR(250),
		[Phone Number] VARCHAR(150),
		[AppDate] DATE,
		[DS SP Qual Date] DATE,
		[DS WT Qual Date] DATE,
		[DS GT Qual Date] DATE,
		[IsNonTAB] BIT, 
		[First UL ID] VARCHAR(50),
		[First UL Name] VARCHAR(350),
		[PastAWT] VARCHAR(100) DEFAULT ('No'),
		[Earn500Bonus]  AS (CASE WHEN [PastAWT]='No' AND [isNonTAB]= (1) THEN (1) ELSE (0) END),
	)

	DROP TABLE IF EXISTS #History       
				
	SELECT
		nDistributorIDFK AS [PK_Distributor]
		,[224] AS [Qual_W]
		,[225] AS [Qual_G]
	INTO #History
	FROM
	(
		SELECT
			H.nDistributorIDFK
			,H.sDistributorID
			,H.nEventTypeLID
			,H.dFrom
		FROM
			dbo.v_DistributorHistory H
		INNER JOIN
			#MetricsFiltered A
			ON
				H.nDistributorIDFK = A.PK_Distributor
		WHERE
			H.nEventTypeLID BETWEEN 224 AND 225
			AND H.dThrough = '2049-12-31'
	) AS P1 PIVOT (
		MIN(dFrom)
		FOR nEventTypeLID
			IN ([224],[225])
	) AS P2
				
	INSERT #PotentialsInfo([PK_Distributor],[DistributorID],[DsName],[DS Subtype],[Region],[COP],[Email],[Phone Number],[AppDate],[DS SP Qual Date],[DS WT Qual Date],[DS GT Qual Date],[IsNonTAB],[First UL ID],[First UL Name])
		SELECT
			M.PK_Distributor
			,LTRIM(RTRIM(D.sDistributorID)) AS DistributorID
			,CONCAT(D.sFirstName,' ', D.sLastName) AS [DSName]
			,D.sSubTeam AS [DS Subtype]
			,C.sRegionLabel AS [Region]
			,D.sDistributorCountryProcessingCode AS COP
			,ISNULL(E.sString,'') AS [Email]
			,ISNULL(P.sString,'') AS [Phone Number]
			,d.dApplication AS [AppDate]
			,D.dSupervisorQualification AS [DS SP Qual Date]
			,H.Qual_W AS [DS WT Qual Date]
			,H.Qual_G AS [DS GT Qual Date]
			,IsNonTAB = CASE WHEN H.Qual_G <= @NonTABDate THEN 0 ELSE 1 END
			,DL.sDistributorID AS [First UL ID]	
			,CONCAT(DL.sFirstName, '', DL.sLastName) AS [First UL Name]
		FROM 
			#MetricsFiltered AS M
				INNER JOIN v_Distributor AS D
					ON M.DistributorID = D.sDistributorID
				INNER JOIN	dbo.v_Countries AS C
					ON D.sDistributorCountryProcessingCode = C.sCountryCode
				LEFT JOIN #History AS H
					ON M.PK_Distributor = H.PK_Distributor
				LEFT JOIN dbo.v_DistributorLineage AS L
					ON  L.nDistributorID = D.nDistributorID
				LEFT JOIN v_Distributor AS DL
					ON L.n1stSupervisorID = DL.nDistributorID
				LEFT JOIN dbo.v_DistributorEmail AS E
					ON E.nDistributorIDFK = D.nDistributorID
				LEFT JOIN dbo.v_DistributorPrimaryPhone AS P
					ON P.nDistributorIDFK = D.nDistributorID

	WHILE @Year < @AWTYear
	BEGIN

		UPDATE
			A
		SET
			PastAWT = 
				CASE 
					WHEN AWQ.PastAWT = 'No' THEN RIGHT(CONVERT(varchar,@Year),2)
					ELSE AWQ.PastAWT + '-' + RIGHT(CONVERT(varchar,@Year),2) END
		FROM
			#PotentialsInfo A
		INNER JOIN
			dbo.AWT AWQ
		ON
			A.[PK_Distributor] = AWQ.PK_Distributor
		LEFT JOIN
			dbo.v_DistributorAssociate2 DT
		ON
			A.PK_Distributor IN (DT.nMainDistributorID, DT.nDistributorID) 
		INNER JOIN
			dbo.AWT_Qualifiers Q
			ON
				Q.AWTYear = @Year
				AND 
				Q.PK_Distributor IN (A.PK_Distributor,DT.nDistributorID, DT.nMainDistributorID)
			
		SET @Year += 1
	END
	
	DROP TABLE IF EXISTS #Points

		SELECT 
			M.DistributorID,
			M.PK_Distributor,
			CAST(CONVERT(varchar(6),m.RoyaltyMonth, 112) AS int) AS [iRoyaltyMonth],
			M.RoyaltyMonth,
			M.TV,
			M.RO,
			ROW_NUMBER() OVER (PARTITION BY m.PK_Distributor ORDER BY m.RoyaltyMonth ASC) AS MonthNumber
		INTO #Points
		FROM dbo.AWT_Metrics AS M WITH (NOLOCK) 
		INNER JOIN #MetricsFiltered AS MM
			ON M.PK_Distributor = MM.PK_Distributor
		WHERE RoyaltyMonth BETWEEN @StartMonth AND @EndMonth

	DROP TABLE IF EXISTS #TV

	CREATE TABLE #TV (
		PK_Distributor	INT,
		TVFirstMonth	MONEY DEFAULT 0.0,
		TVSecondMonth	MONEY DEFAULT 0.0,
		TVThirdMonth	MONEY DEFAULT 0.0,
		TVFourthMonth	MONEY DEFAULT 0.0,
		TVFifthMonth	MONEY DEFAULT 0.0,
		TVSixthMonth	MONEY DEFAULT 0.0	
	)

	INSERT INTO #TV(PK_Distributor,TVFirstMonth,TVSecondMonth,TVThirdMonth,TVFourthMonth,TVFifthMonth,TVSixthMonth)
		SELECT PK_Distributor AS PK_Distributor,[1],[2],[3],[4],[5],[6]
		FROM   
			(
				SELECT PK_Distributor,MonthNumber,[TV] 
				FROM #Points
			) t 
			PIVOT(
				MAX([TV]) 
				FOR [MonthNumber] IN ([1],[2],[3],[4],[5],[6]) 
			) AS pivot_table;

	DROP TABLE IF EXISTS #RO

	CREATE TABLE #RO (
		PK_Distributor	INT DEFAULT 0.0,
		ROFirstMonth	MONEY DEFAULT 0.0,
		ROSecondMonth	MONEY DEFAULT 0.0,
		ROThirdMonth	MONEY DEFAULT 0.0,
		ROFourthMonth	MONEY DEFAULT 0.0,
		ROFifthMonth	MONEY DEFAULT 0.0,
		ROSixthMonth	MONEY	DEFAULT 0.0
	)

	INSERT INTO #RO(PK_Distributor,ROFirstMonth,ROSecondMonth,ROThirdMonth,ROFourthMonth,ROFifthMonth,ROSixthMonth)
	SELECT PK_Distributor AS PK_Distributor,[1],[2],[3],[4],[5],[6]
	FROM   
		(
			SELECT PK_Distributor,MonthNumber,[RO] 
			FROM #Points
		) t 
		PIVOT(
			MAX([RO]) 
			FOR [MonthNumber] IN ([1],[2],[3],[4],[5],[6]) 
		) AS pivot_table;

	DROP TABLE IF EXISTS dbo.AWT_PotentialsReport_WW

		SELECT
				[CreatedDateUTC] = (getutcdate())
			,[CreatedBy] = (replace(suser_sname(),'HERBALIFECORP\','')) 
			,CAST(@StartMonth AS DATE) AS [StartMonth]
			,CAST(@EndMonth AS DATE) AS [EndMonth]
			,M.PK_Distributor
			,M.DistributorID	
			,R.DsName AS [DS Name]
			,R.[DS Subtype]
			,R.Region
			,R.COP
			,R.Email
			,R.[Phone Number]
			,R.[AppDate]
			,R.[DS SP Qual Date]
			,R.[DS GT Qual Date]
			,R.[DS WT Qual Date]
			,R.[First UL ID]
			,R.[First UL Name]
			,R.Earn500Bonus AS [Is First Time Bonus Earner]
			,IIF(R.PastAWT = 'No',1,0) AS [Is First Time AWT Qualifier]
			,ISNULL(TV.TVFirstMonth,0.0)	AS TVFirstMonth
			,ISNULL(TV.TVSecondMonth,0.0)	AS TVSecondMonth
			,ISNULL(TV.TVThirdMonth,0.0)	AS TVThirdMonth
			,ISNULL(TV.TVFourthMonth,0.0)	AS TVFourthMonth
			,ISNULL(TV.TVFifthMonth,0.0)	AS TVFifthMonth
			,ISNULL(TV.TVSixthMonth,0.0)	AS TVSixthMonth
			,ISNULL(RO.ROFirstMonth,0.0)	AS ROFirstMonth
			,ISNULL(RO.ROSecondMonth,0.0)	AS ROSecondMonth
			,ISNULL(RO.ROThirdMonth,0.0)	AS ROThirdMonth
			,ISNULL(RO.ROFourthMonth,0.0)	AS ROFourthMonth
			,ISNULL(RO.ROFifthMonth,0.0)	AS ROFifthMonth
			,ISNULL(RO.ROSixthMonth,0.0)	AS ROSixthMonth
			,M.DID2500KTV
			,M.DID4CM2500TVL6M
			,M.DID5KTV
			,M.DID5KTVL6M
			,M.DID500RO
			,M.DID10KTV
			,M.DIDAWT
			,M.Promo5get5
		INTO dbo.AWT_PotentialsReport_WW
		FROM #PotentialsInfo  AS R
			INNER JOIN #MetricsFiltered AS M
			ON R.PK_Distributor = M.PK_Distributor
			INNER JOIN #TV  AS TV
			ON TV.PK_Distributor = R.PK_Distributor
			INNER JOIN #RO AS RO
			ON RO.PK_Distributor = R.PK_Distributor

	CREATE INDEX IX_AWT_PotentialsReport_WW_PK_Distributor ON dbo.AWT_PotentialsReport_WW(PK_Distributor)
				
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

END
END;
