CREATE PROCEDURE [dbo].[usp_EventPromo_TrackProgress_30805]
		 @PK_Event int 
		,@DistributorID varchar(30) 
		-- Optional Parameters

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA tinyint = 0
		,@CurrentDate DATETIME2 = NULL
AS
BEGIN
/******************************************************************************
	OBJECT:		[dbo].[usp_EventPromo_TrackProgress_30805]
	USE:
			DECLARE @e int, @em varchar(max)

			EXEC [dbo].[usp_EventPromo_TrackProgress_30805]
				 @PK_Event = 30805
				,@DistributorID = '37539863'
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 0
				,@CurrentDate = '2023-08-01'

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:
	NOTES:
	DEPENDENCIES
	--------------------------------------------------------------------
	VERSIONS
	--------------------------------------------------------------------
    1.0.0       2022-05-24      puertac        Initial
	1.0.1		2022-07-29		puertac		   BRD V2
	1.0.2		2022-09-06		puertac		   BUG 1117457 & BUG 1117956
	1.0.3		2022-11-30		rosarioo	   BRD V3 - ONGOING
	1.0.4		2023-01-25		rosarioo	   Task 1324735: SQL - Stop Quals execution 03-01-2024

******************************************************************************/
	SET NOCOUNT ON

	BEGIN TRY
	
		SELECT @CurrentDate = ISNULL(@CurrentDate,GETUTCDATE())		

		 DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
				,@StartTime datetime = GETUTCDATE()
				,@FirstHLDate 	 INT = 19000101
				,@EvaluationDate DATETIME2
				,@PK_Distributor INT = (SELECT PK_Distributor FROM Promo.dimDistributor WITH (NOLOCK) WHERE [DistributorID] = @DistributorID)
				,@SPQualDate DATETIME2  = (SELECT IIF(SPQualDate = 19000101,NULL,dSPQualDate) FROM Promo.dimDistributor WITH (NOLOCK) WHERE [DistributorID] = @DistributorID)
				,@OrderPurpose	 VARCHAR(100) =(SELECT OrderPurpose	 FROM dbo.EventPromoTemplate WITH (NOLOCK) WHERE PK_Event = @PK_Event)		
				,@VolumeByCOP	 VARCHAR(100) =(SELECT VolumeByCOP	 FROM dbo.EventPromoTemplate WITH (NOLOCK) WHERE PK_Event = @PK_Event)
				,@TemplateNumber INT = (SELECT LEFT(PK_EventPromoTemplateType,1) FROM EventPromoTemplate WITH (NOLOCK) WHERE PK_Event = @PK_Event)
				,@RangeHigherTargetOnly BIT = ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'RangeHigherTargetOnly' AND [Group] = 'typ' AND IsActive = 1), 0)	
				,@StaticPeriodOutput	 BIT = ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'StaticPeriodOutput' AND [Group] = 'app' AND IsActive = 1), 0)
				
				,@First_PK_Target INT = ISNULL( (SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'First_PK_Target' AND [Group] = 'typ' AND IsActive = 1 )
										  ,(SELECT MIN(PK_Target) FROM Promo.TargetByPattern WITH (NOLOCK) WHERE PK_Event = @PK_Event AND ISNULL(QualCut,1) = 1 GROUP BY PK_Event) )			-- 1.0.5
		
		DECLARE  @MonthsQualPromo INT =ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'MonthsQualPromo' AND [Group] = 'app' AND IsActive = 1)
										 ,(SELECT MonthPromoPeriod FROM Promo.TargetByPattern T WITH (NOLOCK) WHERE T.PK_Event = @PK_Event AND PK_Target = @First_PK_Target			)
										 )-- If not configured in Options, Use MonthPromoPeriod from TargetByPattern
				,@VisibleMonths	 INT =ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'VisibleMonths' AND [Group] = 'app' AND IsActive = 1)
										 ,(SELECT [Period] FROM Promo.TargetByPattern T WITH (NOLOCK) WHERE T.PK_Event = @PK_Event AND PK_Target = @First_PK_Target			)
										 )-- If not configured in Options, Use Period from TargetByPattern	
	
				,@PromoPeriodEnd datetime2 = (SELECT PromoPeriodEnd FROM Promo.EventDSDate WITH (NOLOCK) WHERE PK_Event = @PK_Event)---1.0.4
			-- 1.0.5
				--,@SQL			 NVARCHAR(MAX) = ''
		DECLARE  @DiffTarget_QId INT = @First_PK_Target -1
		DECLARE @MaxCut INT = 1

		-- BUG 1117956 
		--DECLARE @AsDownline BIT = (SELECT AsDownline FROM Promo.EventDistributor WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Distributor = @PK_Distributor)

		-- BUG 1117457
		DECLARE @AchievedTarget INT = (SELECT MAX(SubEvent) FROM Promo.DSSubEvent WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Distributor = @PK_Distributor	)	
		DECLARE @QualifiedDate INT = (SELECT DateQualified FROM Promo.DSSubEvent WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Distributor = @PK_Distributor AND SubEvent = @AchievedTarget)	
		DECLARE @dQualifiedDate DATE = (SELECT CONVERT(VARCHAR(10),(DateQualified*100)+1) FROM Promo.DSSubEvent WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Distributor = @PK_Distributor AND SubEvent = @AchievedTarget)	
		DECLARE @QualifiedCurrentMonth BIT = IIF(@AchievedTarget = 1 AND @QualifiedDate = SUBSTRING(CONVERT(varchar(6), @CurrentDate, 112), 1, 6), 1 ,0)	
		
		SET @AchievedTarget = IIF(@AchievedTarget IS NOT NULL AND @QualifiedCurrentMonth = 1, NULL, @AchievedTarget)
		----------------------	


		-- Always have 18 months
		DECLARE @StartPeriod DATETIME = IIF(@dQualifiedDate IS NOT NULL,DATEADD(MM,-2,@dQualifiedDate), DATEFROMPARTS(YEAR(@CurrentDate)-1 ,10 ,1)	)--Year, Month, Day
		DECLARE @EndPeriod DATETIME = IIF(@dQualifiedDate IS NOT NULL,@dQualifiedDate, DATEFROMPARTS(YEAR(@CurrentDate)+1 ,3	,1))		--Year, Month, Day

		SET @EvaluationDate = (SELECT PromoPeriodStart FROM Promo.EventDSDate WITH (NOLOCK) WHERE PK_Event  = @PK_Event)
		

		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1
		END


	-- Add Volume Points
		DROP TABLE IF EXISTS #Volume 

		CREATE TABLE #Volume  (
			 PK_Distributor BIGINT
			,RoyaltyMonth	INT
			,PPV			MONEY				
			,DLV			MONEY				
			,TVP			MONEY				
			,GV				MONEY
			,MB_POINTS		MONEY
			,DLV_PM			MONEY				
			,PV				MONEY 
			,PPV_DLV		MONEY				
			,LastOrder		INT
			,[n]			INT
			,IsFQS			TINYINT
			,IsQS			TINYINT				
			,IsPM			TINYINT			
			,PPV_DLV_PM AS PPV+DLV_PM
		--	,PPV2 AS ISNULL(IIF(ISFQS = 1 OR IsQS = 1, PV, PPV), 0) 
		)	

		INSERT INTO #Volume
		SELECT	P.PK_Distributor AS PK_Distributor,RoyaltyMonth,PPV,DLV,VP,GV,MB_POINTS,DLV_PM,PV,PPV_DLV,P.LastOrder,[n],IsFQS,IsQS,IsPM			
		FROM Promo.udf_GetDsVolumePoints_V2(@PK_Distributor,@StartPeriod,@EndPeriod,@VolumeByCOP,0,@OrderPurpose) AS P
				
		CREATE INDEX IX_#Volume_PK_Distributor ON #Volume (PK_Distributor,RoyaltyMonth) INCLUDE (PPV,DLV,TVP,GV,MB_POINTS,DLV_PM,PV,PPV_DLV);


		DROP TABLE IF EXISTS #Targets
					
	;WITH cte_Distributor AS (
		SELECT	 D.COP
				,CASE WHEN D.[SPQualDate] != @FirstHLDate THEN 'FQS' ELSE 'NONFQS' END AS [TeamLevelTarget]
                ,CAST(D.SPQualDate AS VARCHAR(10)) AS SPQualDate
				,IIF(EXISTS (SELECT 1 FROM Promo.TargetMetrics T WITH (NOLOCK) WHERE T.PK_Event = @PK_Event AND T.COP LIKE '%'+D.COP+'%'), 1, 0) AS HasValidCOP	-- 1.0.4
			FROM Promo.dimDistributor d WITH (NOLOCK)
			WHERE D.PK_Distributor = @PK_Distributor
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
				  WHEN (@TemplateNumber = 3 AND @CurrentDate <= TP.PeriodEndDate ) OR D.Cut > 0 THEN 2 	-- Achievable				-- 1.0.5
				  ELSE 0									-- Not Achieved 
			END AS [Status] 
			,D.DateQualified
			,CAST(CAST(D.DateQualified AS VARCHAR(10))+'01'AS DATETIME2) AS dDateQualified
			,T.TeamLevelTarget 
			,T.Baseline
			,T.DateStart		
			,T.ConsecutiveMonths
		INTO #Targets
		FROM Promo.TargetMetrics T WITH (NOLOCK)
		INNER JOIN cte_Distributor C 
			ON t.[COP] LIKE IIF(HasValidCOP = 1, '%' + C.[COP] + '%', '-' )			-- 1.0.4
			AND (T.TeamLevelTarget IS NULL OR C.TeamLevelTarget = T.TeamLevelTarget)
		INNER JOIN Promo.DSQual D WITH (NOLOCK)
			ON D.PK_Event = T.PK_Event
			AND D.PK_Distributor = @PK_Distributor
			AND D.QId = CAST(SUBSTRING(T.TargetName, CHARINDEX('_',T.TargetName)+1,LEN(T.TargetName)) AS INT) + @DiffTarget_QId  --@First_PK_Target
		LEFT JOIN Promo.TargetByPattern TP WITH (NOLOCK)							-- 1.0.5
			ON  TP.PK_Event = T.PK_Event
			AND TP.PK_Target = CAST(SUBSTRING(T.TargetName, CHARINDEX('_',T.TargetName)+1,LEN(T.TargetName)) AS INT) + @DiffTarget_QId  --@First_PK_Target
			AND ISNULL(TP.QualCut,1) = 1
		WHERE T.PK_Event = @PK_Event	
		AND (RIGHT(t.TargetName,1) = @AchievedTarget OR @AchievedTarget IS NULL	)	-- BUG 1117457
			--AND @AsDownline = 1 ---1.0.4
			
		-- First ResultSet
		SELECT [Name], [Metric], [Value],[Type],[Group],[Operator],IsMain,Cut,[Status]
				,dDateQualified AS DateQualified, Baseline AS BaselineDate, ConsecutiveMonths			-- 1.0.3
		FROM #Targets


		-- SET MAX CUT
		SELECT @MaxCut = MAX(Cut) FROM #Targets


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
				,@StartPeriod AS StartDate
				,@EndPeriod AS EndDate
				,DATEADD(MONTH, DATEDIFF(MONTH, 0, @StartPeriod), 0) AS StartMonth
				,IIF(@SPQualDate IS NOT NULL AND T.dDateQualified IS NULL,(DATEADD(MONTH, DATEDIFF(MONTH, 0, @SPQualDate)+1, 0)),(DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndPeriod), 0))) AS EndMonth
				,@EvaluationDate AS EvaluationDate
				,DATEADD(MONTH, DATEDIFF(MONTH, 0, @EvaluationDate), 0) AS EvaluationMonth
				,@VisibleMonths AS VisibleMonths	
				,@MonthsQualPromo AS MonthsQualPromo														 -- 1.0.4
				,DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDate), 0) AS CurrentMonth
				,CAST(NULL AS DATETIME2) AS OutputDateStart							   
				,CAST(NULL AS DATETIME2) AS OutputDateEnd
				,[Type]
				,CAST(NULL AS tinyint) AS OrderBy
		INTO #OutputDates
		FROM #Targets T
	
		
		-- Set StartMonth & EndMonth Based on EvaluationMonth
		UPDATE T
		SET StartMonth = IIF(DATEADD(MONTH, (VisibleMonths-1),EvaluationMonth) < EndMonth
							  ,EvaluationMonth, DATEADD(MONTH, -(VisibleMonths-1),EndMonth) )
		   ,EndMonth = IIF(DATEADD(MONTH, (MonthsQualPromo-1),EvaluationMonth) < EndMonth						-- 1.0.4
							,DATEADD(MONTH, (MonthsQualPromo-1),EvaluationMonth), EndMonth)						-- 1.0.4
		FROM #OutputDates T 
		WHERE EvaluationMonth >= StartMonth							-- 1.0.2
		 
		
		-- Setup OutputDateStart & OutputDateEnd values for each scenario
		UPDATE T																		-- 1.- IF already Qualified, Show Qualified Period
		SET	 OutputDateStart = DATEADD(MONTH, -(VisibleMonths-1),dDateQualified)
			,OutputDateEnd =  dDateQualified
		FROM #OutputDates T
		WHERE dDateQualified IS NOT NULL
		AND dDateQualified <= CurrentMonth


		UPDATE T																		-- 2.- IF CurrentMonth <= End of first Period = show First Period
		SET	 OutputDateStart = StartMonth
			,OutputDateEnd = DATEADD(MONTH,(VisibleMonths-1),StartMonth)
		FROM #OutputDates T
		WHERE OutputDateStart IS NULL AND OutputDateEnd IS NULL		--Meaning not matching any prior scenario
		AND CurrentMonth <= DATEADD(MONTH,(VisibleMonths-1),StartMonth)


		---- Setup OutputDateStart & OutputDateEnd values for Type = 2 (Accumulate Target)
		UPDATE T																		-- 5.- Default : Show Period: Start = CurrentMonth -(VisibleMonths-1)   - For Accumulated							
		SET	 OutputDateStart = DATEADD(MONTH,-(VisibleMonths-1),CurrentMonth) 
			,OutputDateEnd =  CurrentMonth
		FROM #OutputDates T
		WHERE OutputDateStart IS NULL AND OutputDateEnd IS NULL		--Meaning not matching any prior scenario
		AND dDateQualified IS NULL
		AND [Type] = 2 --- Accumulate target


		UPDATE T																		-- 3.- IF Cut 1 = show Current Period, IF Cut 2 = show Period started 1 months prior ...
		SET	 OutputDateStart = DATEADD(MONTH,(+1-Cut),CurrentMonth)
			,OutputDateEnd = DATEADD(MONTH,(VisibleMonths-1), DATEADD(MONTH,(+1-Cut),CurrentMonth))  --From OutputDateStart
		FROM #OutputDates T
		WHERE OutputDateStart IS NULL AND OutputDateEnd IS NULL		--Meaning not matching any prior scenario
		AND Cut > 0 AND dDateQualified IS NULL
		AND DATEADD(MONTH,(VisibleMonths-1), DATEADD(MONTH,(+1-Cut),CurrentMonth)) <= EndMonth
	
		UPDATE T																		-- 4.- IF CurrentMonth > = EndDate = Show Last Period
		SET	 OutputDateStart = DATEADD(MONTH, -(VisibleMonths-1),EndMonth)
			,OutputDateEnd =  EndMonth
		FROM #OutputDates T
		WHERE OutputDateStart IS NULL AND OutputDateEnd IS NULL		--Meaning not matching any prior scenario
		AND CurrentMonth >= IIF(@TemplateNumber <> 3, DATEADD(MONTH, -(VisibleMonths-1),EndMonth), EndMonth)		--  for Template 3 starts until EndMonth (Not EndMonth -(VisibleMonths-1) as the others)	
						
		IF(@TemplateNumber <> 3)																			
		BEGIN
				UPDATE T																		-- 5.- Default : Show current Period									
				SET	 OutputDateStart = CurrentMonth
					,OutputDateEnd =  DATEADD(MONTH,(VisibleMonths-1),CurrentMonth)
				FROM #OutputDates T
				WHERE OutputDateStart IS NULL AND OutputDateEnd IS NULL		--Meaning not matching any prior scenario
		END
		ELSE		-- 1.0.6 : Change default period for Accummulated (template 3) promotions														
		BEGIN 
				UPDATE T																		-- 5.- Default : Show Period: Start = CurrentMonth -(VisibleMonths-1)   - For Accumulated							
				SET	 OutputDateStart = DATEADD(MONTH,-(VisibleMonths-1),CurrentMonth) 
					,OutputDateEnd =  CurrentMonth
				FROM #OutputDates T
				WHERE OutputDateStart IS NULL AND OutputDateEnd IS NULL		--Meaning not matching any prior scenario
		END
		--
		-- Special Case for Static Period   -   Start = EvaluationMonth   EndDate = EvaluationMonth + VisibleMonths
		IF(@StaticPeriodOutput = 1)
		BEGIN
			UPDATE T																		
			SET	 OutputDateStart = EvaluationMonth
				,OutputDateEnd =  DATEADD(MONTH,VisibleMonths,EvaluationMonth)
			FROM #OutputDates T
		END

		-- Set OrderBy OutputDateStart
		UPDATE T1 SET 
		T1.OrderBy = IIF(T1.dDateQualified IS NULL,T2.OrderBy,1)
		FROM #OutputDates T1
		INNER JOIN (SELECT TargetLevel,ROW_NUMBER() OVER (ORDER BY Cut DESC,OutputDateStart) AS OrderBy FROM #OutputDates) AS T2
		ON T2.TargetLevel = T1.TargetLevel

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
				SELECT TOP 1 @OutputDateStart= MIN(OutputDateStart) OVER (ORDER BY OrderBy)
					   ,@OutputDateEnd= MAX(OutputDateEnd) OVER (ORDER BY OrderBy)	
				FROM #OutputDates
				WHERE (@TemplateNumber <> 5 OR Cut = @MaxCut)
		 END

		 SELECT @OutputDateEnd = CASE WHEN @dQualifiedDate IS NULL AND @CurrentDate > @PromoPeriodEnd THEN @PromoPeriodEnd ELSE @OutputDateEnd END ---1.0.4
		 ,@OutputDateStart = CASE WHEN @dQualifiedDate IS NULL AND @CurrentDate > @PromoPeriodEnd THEN DATEADD(MM,-@VisibleMonths,@PromoPeriodEnd) ELSE @OutputDateStart END ---1.0.4


		 IF(@TemplateNumber = 4)
		 BEGIN
			SELECT 
				 @OutputDateStart = MIN(DateStart) 
				,@OutputDateEnd = MAX(DATEADD(MONTH,ConsecutiveMonths,DateStart))
			FROM #Targets

		 END

		 DROP TABLE IF EXISTS #IncrementalBaseLine;

		 SELECT Metric,BaseLine 
		 INTO #IncrementalBaseLine
		 FROM #Targets 
		 WHERE BaseLine IS NOT NULL
		 GROUP BY Metric,[BaseLine]


		 
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
				,A.[Value]
				,STRING_AGG(T.[Group],',') AS TargetGroups
		FROM #Volume 
		UNPIVOT ( [Value] 
					FOR [Metric] IN (PPV,DLV,TVP,GV,MB_POINTS,DLV_PM,PV,PPV_DLV,PPV_DLV_PM) 
		)AS A
		INNER JOIN cte_Targets T WITH (NOLOCK)
			ON T.Metric = A.Metric							  
		WHERE CAST((CAST(A.RoyaltyMonth AS VARCHAR)+'01') AS DATETIME2) BETWEEN @OutputDateStart AND @OutputDateEnd
		GROUP BY A.RoyaltyMonth, A.Metric, A.[Value]
		ORDER BY Metric, MonthDate

		
		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime
				,@StoredProcedureParameters = @CurrentDate;

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