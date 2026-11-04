CREATE PROCEDURE [dbo].[usp_EventPromo_TrackProgress_asp_v2]
		 @PK_Event INT
		,@DistributorID VARCHAR(30)

		-- Error Parameters
		,@Error	INT = 0 OUTPUT
		,@ErrorMessage VARCHAR(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA TINYINT = 0
		,@CurrentDate DATETIME2 = NULL
AS
BEGIN
/******************************************************************************
	OBJECT:		dbo.usp_EventPromo_TrackProgress_asp_v2
	USE:
			DECLARE @e int, @em varchar(max)

			EXEC dbo.usp_EventPromo_TrackProgress_asp_v2
				 @PK_Event = 205349
				,@DistributorID = 'T1Y0158171'
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 0

			SELECT @e AS Error, @em AS [Error Message]

	DESCRIPTION:
	NOTES:
	DEPENDENCIES
	--------------------------------------------------------------------
	VERSIONS
	--------------------------------------------------------------------
    1.0.0       2026-03-05      rosarioo        Initial (Based on usp_EventPromo_TrackProgress_asp)
    2.0.0       2026-03-05      rosarioo        Get & Show First Time ASP Dates
    3.0.0       2026-09-22      rosarioo        User Story 1484660: 26063 - EA ASP 2026 (Recurring) - TYP - First Time Qualifier bonus
    3.1.0       2026-09-22      rosarioo        TYP - First Time Qualifier bonus + PK_SubEvent + FirstTimeASP QualDate

******************************************************************************/
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
	DECLARE @StartTime datetime = GETUTCDATE()

	BEGIN TRY
	
	IF (@IsDevQA = 2)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END			  
		

	DECLARE  @StartDate		 DATETIME2 
			,@EndDate		 DATETIME2  
			,@FirstHLDate 	 INT = 19000101
			,@EvaluationDate DATETIME2
			,@PK_Distributor INT = (SELECT nDistributorID FROM v_Distributor WHERE sDistributorID = @DistributorID)
			-- Custom Promo.Options
			,@QSAsSP		 BIT = ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'QSAsSP' AND [Group] = 'app' AND IsActive = 1), 1)
			,@First_PK_Target INT = ISNULL( (SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'First_PK_Target' AND [Group] = 'typ' AND IsActive = 1 )
										  ,(SELECT MIN(PK_Target) FROM Promo.TargetByPattern WITH (NOLOCK) WHERE PK_Event = @PK_Event GROUP BY PK_Event) )
			,@RangeHigherTargetOnly BIT = ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'RangeHigherTargetOnly' AND [Group] = 'typ' AND IsActive = 1), 0)	
			--Custom dbo.EventPromoTemplate
			,@VolumeByCOP	NVARCHAR(1000) =   (SELECT VolumeByCOP FROM EventPromoTemplate WITH (NOLOCK) WHERE PK_Event = @PK_Event)
			,@CustomEvalDate NVARCHAR (1000) = (SELECT CustomEvalDate FROM EventPromoTemplate WITH (NOLOCK) WHERE PK_Event = @PK_Event)
			,@RetroactiveDivorce BIT =  ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'RetroactiveDivorce' AND [Group] = 'app' AND IsActive = 1), 1)
			,@GetFirstTimeASP BIT = ISNULL( (SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'GetFirstTimeASP' AND [Group] = 'app' AND IsActive = 1),0) -- 2.0.0
			,@BonusStartDate DATETIME2 = ISNULL( (SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'ASPBonusStartDate' AND [Group] = 'app' AND IsActive = 1),null) -- 3.0.0
			,@BonusEndDate DATETIME2 = ISNULL( (SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'ASPBonusEndDate' AND [Group] = 'app' AND IsActive = 1),null) -- 3.0.0
	
	DECLARE  @DiffTarget_QId INT = @First_PK_Target -1
			,@VisibleMonths	 INT =ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'VisibleMonths' AND [Group] = 'app' AND IsActive = 1)
										 ,(SELECT [Period] FROM Promo.TargetByPattern T WITH (NOLOCK) WHERE T.PK_Event = @PK_Event AND PK_Target = @First_PK_Target			)
										 )-- If not configured in Options, Use Period from TargetByPattern
	
	SELECT @CurrentDate = CONVERT(DATE,ISNULL(@CurrentDate,GETUTCDATE()))			--US 720693
	DECLARE @CurrentYear INT = YEAR(@CurrentDate)									-- 1.1.0		
	
	-- Reset Static Dates for template 602   -- 1.1.0
	SELECT @EvaluationDate =  DATEFROMPARTS(@CurrentYear-1, 11, 01)			-- 1.1.0	Nov from previous Year
		  ,@StartDate = DATEFROMPARTS(@CurrentYear-1, 11, 01)				-- 1.1.0	Nov from previous Year
		  ,@EndDate = DATEFROMPARTS(@CurrentYear, 12, 31)					-- 1.1.0	Dec current year
 
	IF (@PK_Event = 167011)---- QA BUG 1348263 -- MALAYSIA ASP 2024 RECURRING
	BEGIN

		SELECT @StartDate = DATEFROMPARTS(@CurrentYear, 01, 01)
		,@EvaluationDate  = DATEFROMPARTS(@CurrentYear, 01, 01)

	END

	IF (@PK_Event = 200797 AND @CurrentDate < '2025-01-01') --1.4.1: 24041 - Hong Kong & Macau ASP 2024 Recurring Promotion
	BEGIN

		SELECT @StartDate = '2024-01-01'
			,@EvaluationDate  ='2024-01-01'
			
	END
	
	--1.4.3: 23140 - TAIWAN ASP 2024 RECURRING
	IF @PK_Event = 200843 
	BEGIN
		IF MONTH(@CurrentDate) <= 2 
		SELECT @StartDate = DATEFROMPARTS(@CurrentYear-1, 01, 01)			--	Jan from previous year
		,@EvaluationDate  = DATEFROMPARTS(@CurrentYear-1, 01, 01)			--	Jan from previous year
		 ,@EndDate = DATEFROMPARTS(@CurrentYear, 02, 01)					-- 	Feb current year
		ELSE
		SELECT @StartDate = DATEFROMPARTS(@CurrentYear, 01, 01)				-- Jan current year
		,@EvaluationDate  = DATEFROMPARTS(@CurrentYear, 01, 01)				-- Jan current year
		 ,@EndDate = DATEFROMPARTS(@CurrentYear+1, 02, 01)					-- Feb next year
		
	END


	DROP TABLE IF EXISTS #Volume

	CREATE TABLE #Volume(
		 PK_Distributor BIGINT					   
		,RoyaltyMonth INT
		,PPV		MONEY
		,DLV		MONEY
		,TVP2		MONEY
		,TVP		MONEY
		,GV			MONEY
		,LastOrder	INT
		,n			INT
		,IsFQS		TINYINT
		,IsQS		TINYINT
		,MB_POINTS	MONEY
		,IsPM		TINYINT
		,DLV_PM		MONEY	--Referral points
		,PV			MONEY
	 )

	 -- Get Volume Points		-- 1.1.0
	INSERT #Volume (PK_Distributor,RoyaltyMonth,PPV,DLV,TVP2,GV,LastOrder,n,IsFQS,IsQS,MB_POINTS,IsPM,DLV_PM,PV)
	EXEC Promo.usp_GetDSVolumePoints
		 @StartMonth = @StartDate	
		,@EndMonth = @EndDate
		,@PK_Distributor = @PK_Distributor
		,@QSAsSP = @QSAsSP
		,@VolumeByCOP = @VolumeByCOP
		,@RetroactiveDivorce = @RetroactiveDivorce 

	CREATE INDEX IX_#Volume_PKs ON #Volume(PK_Distributor, RoyaltyMonth)

	UPDATE V
	SET V.TVP = IIF((V.IsFQS = 1) OR (@QSAsSP = 1 AND V.IsQS = 1), V.TVP2, 0)				-- BUG 1262479 & 1285502
	FROM #Volume AS V

 
	-- EXCEPTION DIVORCE CASE			-- 1.3.0
	IF(@PK_Distributor IN (10164748,22592332) AND @PK_Event = 197094 ) -- Exception divorce case for EMEA ASP only
	 BEGIN
			DROP TABLE IF EXISTS #ExceptionPoints

			SELECT FORMAT(dRoyaltyMonth,'yyyyMM') AS RoyaltyMonth, SUM(mVolumePoints-mMainVolumePoints) AS VP 
			INTO #ExceptionPoints
			FROM v_aggFQS_ID 
			WHERE nDistributorID IN (10164748,22592332,4998607) 
			AND dRoyaltyMonth BETWEEN @StartDate AND @EndDate
			GROUP BY dRoyaltyMonth

			UPDATE V
			SET V.TVP = E.VP
			FROM #Volume AS V
			INNER JOIN #ExceptionPoints AS E
				ON V.RoyaltyMonth = E.RoyaltyMonth
	 END
	-- EXCEPTION DIVORCE CASE

	-- 2.0.0  Get Downlines with First Time ASP in current period
	DROP TABLE IF EXISTS #Target_Downlines;

	CREATE TABLE #Target_Downlines (
		 MonthDate DATE
		,[Metric] VARCHAR(100)
		,[Value] MONEY
		,[TargetGroups] VARCHAR(100)
	)

	IF @GetFirstTimeASP = 1 AND @CurrentDate BETWEEN @BonusStartDate AND @BonusEndDate -- 3.0.0
	BEGIN

		DROP TABLE IF EXISTS #Summary_Downlines;

		SELECT 
			D.PK_Distributor,D.DQDate,COUNT(1) AS TotalDWL
		INTO #Summary_Downlines
		FROM Promo.DSDownlines AS D WITH (NOLOCK) 
		INNER JOIN Promo.WRK_EMEA_ASP_PrevQualified AS W WITH (NOLOCK)
		ON W.PK_Distributor = D.DLDistributor
		AND W.IsFirstTime = 1
		AND W.DateQualified BETWEEN @StartDate AND @EndDate
		AND W.ASP_Year = YEAR(@EndDate)
		AND D.DQDate = FORMAT(W.DateQualified,'yyyyMM')
		WHERE D.PK_Distributor = @PK_Distributor
		AND D.PK_Event = @PK_Event
		GROUP BY D.PK_Distributor,D.DQDate

		CREATE INDEX IX_#Summary_Downlines_PKs ON #Summary_Downlines(PK_Distributor, DQDate);

		-- Show New First Time ASP starting March 2026
		IF @PK_Event = 205349 AND YEAR(@EndDate) = 2026
		BEGIN
			DELETE FROM #Summary_Downlines WHERE DQDate < 202603 
		END

		;WITH cte_Targets AS (
		SELECT 
		iMonth, dMonthStart as RoyaltyMonth
		FROM dbo.udf_MonthsRangeByInt(@StartDate, DATEDIFF(MM,@StartDate,@EndDate)+1, 1) as M
		)
		INSERT #Target_Downlines (MonthDate,[Metric],[Value],[TargetGroups])
		SELECT 
			 t.RoyaltyMonth
			,'NewASP' AS [Metric]
			,CAST(ISNULL(d.TotalDWL,0) AS MONEY) as [Value]
			,'1' AS TargetGroups
		FROM cte_Targets as t
		LEFT JOIN  #Summary_Downlines AS d
		ON D.DQDate = t.iMonth
	
	END

	CREATE INDEX IX_#Target_Downlines_PKs ON #Target_Downlines(MonthDate, [Metric]);

			
	DROP TABLE IF EXISTS #Targets
					
	;WITH cte_Distributor AS (
		SELECT	 COP
				,CASE WHEN [SPQualDate] != @FirstHLDate THEN 'FQS' ELSE 'NONFQS' END AS [TeamLevelTarget]
                ,CAST(SPQualDate AS VARCHAR(10)) AS SPQualDate
			FROM Promo.dimDistributor d WITH (NOLOCK)
			WHERE PK_Distributor = @PK_Distributor
	)
	SELECT 	 T.TargetName AS [Name]
			,T.MetricNames AS [Metric]
			,CAST(T.MetricValues AS DECIMAL(12,2)) AS [Value] 
			,CAST(T.TargetType AS INT) AS [Type]				-- 1 Achieve  2 Accumulate 	
			,CAST(T.TargetGroup AS INT) AS [Group]				 
			,T.TargetOperator AS [Operator]
			,T.IsMain 
			,D.Cut
			,CASE WHEN D.DateQualified IS NOT NULL THEN 1	-- Achieved	 (Do not base this in cut 4)
				  WHEN D.Cut > 0 THEN 2						-- Achievable			
				  ELSE 0									-- Not Achieved 
			END AS [Status] 
			,SE.DateQualified
			,CAST(CAST(SE.DateQualified AS VARCHAR(10))+'01'AS DATETIME2) AS dDateQualified
			,T.TeamLevelTarget 
			,T.Baseline
			,T.DateStart		
			,T.ConsecutiveMonths
			,T.PK_SubEvent -- 3.1.0
		INTO #Targets
		FROM Promo.TargetMetrics T WITH (NOLOCK)
		INNER JOIN cte_Distributor C 
			ON t.[COP] LIKE '%' + C.[COP] + '%' OR t.[COP]  = '-'
			AND (T.TeamLevelTarget IS NULL OR C.TeamLevelTarget = T.TeamLevelTarget)
		INNER JOIN Promo.DSQual D WITH (NOLOCK)
			ON D.PK_Event = T.PK_Event
			AND D.PK_Distributor = @PK_Distributor
			AND QId = CAST(SUBSTRING(TargetName, CHARINDEX('_',TargetName)+1,LEN(TargetName)) AS INT) + @DiffTarget_QId  --@First_PK_Target
		LEFT JOIN (SELECT PK_Event,PK_Distributor, MIN(DateQualified) AS DateQualified  FROM Promo.DSSubEvent 
			WHERE PK_Event = @PK_Event
			AND PK_Distributor = @PK_Distributor
			AND SubEvent = 1						-- Hardcoded SubEvent 1
			AND LEFT(DateQualified,4) = @CurrentYear 
			AND DateQualified <= FORMAT(@CurrentDate,'yyyyMM')
			GROUP BY PK_Event,PK_Distributor
		)AS SE 
			ON SE.PK_Event = T.PK_Event
		WHERE T.PK_Event = @PK_Event	
		

		IF @GetFirstTimeASP = 1 AND @CurrentDate BETWEEN @BonusStartDate AND @BonusEndDate -- 3.0.0-- 2.0.0
		BEGIN

			INSERT INTO #Targets ([Name],[Metric],[Value],[Type],[Group],[IsMain],[Cut],[Status],[ConsecutiveMonths],DateQualified,dDateQualified)
			SELECT DISTINCT 'DF_1' AS [Name],'NewASP' AS [Metric],'0' AS [Value],[Type],[Group],[IsMain],[Cut],[Status],[ConsecutiveMonths]
			,DateQualified,dDateQualified -- Getting DateQualified in the current wave
			FROM #Targets

			-- 3.1.0 -- DISPLAY "FIRST TIME ASP QUALIFICATION" ONLY FOR POTENTIALS OR QUALIFIERS DURING BONUS PERIOD
			IF (EXISTS (SELECT 1 FROM Promo.WRK_EMEA_ASP_PrevQualified AS X (NOLOCK) WHERE X.PK_Distributor = @PK_Distributor AND X.DateQualified >= @BonusStartDate AND X.DateQualified <= @BonusEndDate AND X.IsFirstTime = 1) 
			OR NOT EXISTS (SELECT 1 FROM Promo.WRK_EMEA_ASP_PrevQualified AS X (NOLOCK) WHERE X.PK_Distributor = @PK_Distributor AND X.DateQualified < @BonusStartDate AND X.IsFirstTime = 1))
			AND @CurrentDate BETWEEN @BonusStartDate AND @BonusEndDate
			BEGIN
				INSERT INTO #Targets ([Name],[Metric],[Value],[Type],[Group],[IsMain],[Cut],[Status],[ConsecutiveMonths],DateQualified,dDateQualified,PK_SubEvent)
				SELECT DISTINCT 'DF_1' AS [Name],'FirstTimeASP' AS [Metric],'0' AS [Value],1 AS [Type],1 AS [Group], 1 AS  [IsMain], 1 AS [Cut],IIF(W.PK_Distributor IS NOT NULL, 1, 2) AS [Status],NULL AS [ConsecutiveMonths]
				,FORMAT(W.DateQualified,'yyyyMM') AS DateQualified,W.DateQualified AS dDateQualified,S.PK_SubEvent  -- Getting DateQualified in the current wave
				FROM dbo.SubEvent AS S (NOLOCK)
				LEFT JOIN Promo.WRK_EMEA_ASP_PrevQualified AS W (NOLOCK)
					ON  W.PK_Distributor = @PK_Distributor
					AND W.IsFirstTime = 1
					AND W.DateQualified BETWEEN @BonusStartDate AND @BonusEndDate
				WHERE S.PK_Event = @PK_Event AND S.SubEventNumber = 99
			END

		END


		-- First ResultSet
		SELECT [Name], [Metric], [Value],[Type],[Group],[Operator],IsMain,Cut,[Status]
				,dDateQualified AS DateQualified ,Baseline AS BaselineDate, ConsecutiveMonths, PK_SubEvent -- 3.1.0		  -- 1.2.0
		FROM #Targets
				

		-- Set Ranges for each target
		DECLARE  @OutputDateStart DATETIME2 
				,@OutputDateEnd	  DATETIME2
		
		DROP TABLE IF EXISTS #OutputDates

		SELECT   T.[Name]
				,SUBSTRING(T.[Name],CHARINDEX('_',T.[Name])+1,LEN(T.[Name])) AS TargetLevel
				,T.[Metric]
				,T.[Value] 
				,T.dDateQualified
				,T.Cut
				,@StartDate AS StartDate
				,@EndDate AS EndDate
				,DATEADD(MONTH, DATEDIFF(MONTH, 0, @StartDate), 0) AS StartMonth
				,DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0) AS EndMonth
				,@EvaluationDate AS EvaluationDate
				,DATEADD(MONTH, DATEDIFF(MONTH, 0, @EvaluationDate), 0) AS EvaluationMonth
				,@VisibleMonths AS VisibleMonths	
				,DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDate), 0) AS CurrentMonth
				,CAST(NULL AS DATETIME2) AS OutputDateStart							   
				,CAST(NULL AS DATETIME2) AS OutputDateEnd
		INTO #OutputDates
		FROM #Targets T
	
			 
		-- Set StartMonth & EndMonth Based on EvaluationMonth
		UPDATE T
		SET StartMonth = IIF(DATEADD(MONTH, (VisibleMonths-1),EvaluationMonth) < EndMonth
							  ,EvaluationMonth, DATEADD(MONTH, -(VisibleMonths-1),EndMonth) )
		   ,EndMonth = IIF(DATEADD(MONTH, (VisibleMonths-1),EvaluationMonth) < EndMonth
							,DATEADD(MONTH, (VisibleMonths-1),EvaluationMonth), EndMonth)
		FROM #OutputDates T 
		WHERE EvaluationMonth >= StartMonth							-- 1.0.2
		 
		 
		-- Reset to Static Dates for template 602
		UPDATE T
		SET	 OutputDateStart = StartMonth												
			,OutputDateEnd =  EndMonth
		FROM #OutputDates T


		-- Select the Range type
		IF(@RangeHigherTargetOnly = 1)										-- Get Date Range from the higher target level only
		 BEGIN
				SELECT  @OutputDateStart = OutputDateStart
					   ,@OutputDateEnd = OutputDateEnd
				FROM #OutputDates
				WHERE TargetLevel = (SELECT MAX(TargetLevel) FROM #OutputDates)
		 END
		ELSE															-- Get the entire Date Range from all the targets
		 BEGIN
				SELECT  @OutputDateStart= MIN(OutputDateStart)
					   ,@OutputDateEnd= MAX(OutputDateEnd)	
				FROM #OutputDates
		 END


		-- Second ResultSet
		;WITH cte_Targets AS(
			SELECT DISTINCT Metric, [Group]
			FROM #Targets T
			WHERE ( (T.[Group] = (SELECT MAX(TargetLevel) FROM #OutputDates)) 
					 OR @RangeHigherTargetOnly = 0
				  )
		)		  
		SELECT DISTINCT
				CAST((CAST(A.RoyaltyMonth AS VARCHAR)+'01') AS DATE) AS MonthDate
				,A.Metric 
				,IIF(A.[Value]<0,0,A.[Value]) as [Value] --1.4.2 Set negative volume as zero
				,CAST(STRING_AGG(T.[Group],',') AS VARCHAR(100)) AS TargetGroups
		FROM #Volume 
		UNPIVOT ( [Value] 
					FOR [Metric] IN (PPV,DLV,TVP,GV,MB_POINTS,DLV_PM,PV) 
		)AS A
		INNER JOIN cte_Targets T WITH (NOLOCK)
			ON T.Metric = A.Metric							  
		WHERE CAST((CAST(A.RoyaltyMonth AS VARCHAR)+'01') AS DATETIME2) BETWEEN @OutputDateStart AND @OutputDateEnd
		GROUP BY A.RoyaltyMonth, A.Metric, A.[Value]
		UNION ALL
		SELECT 
			MonthDate,[Metric],[Value],[TargetGroups]
		FROM #Target_Downlines
		ORDER BY Metric, MonthDate


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
	
	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime
	
END;