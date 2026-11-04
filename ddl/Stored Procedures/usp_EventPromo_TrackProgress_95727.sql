CREATE PROCEDURE [dbo].[usp_EventPromo_TrackProgress_95727]
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
	OBJECT:		dbo.usp_EventPromo_TrackProgress_95727
	USE:
			DECLARE @e int, @em varchar(max)

			EXEC dbo.usp_EventPromo_TrackProgress_95727
				 @PK_Event = 95727
				,@DistributorID = 'VNY0142240'
				,@CurrentDate = '2025-12-10'				
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
    1.0.0       2025-04-24      rosarioo       Initial (Based on usp_EventPromo_TrackProgress_std)

******************************************************************************/
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@Param varchar(100) = CONVERT(VARCHAR,@PK_Event)
	DECLARE @StartTime datetime = GETUTCDATE()

	BEGIN TRY
	
	IF (@IsDevQA = 2)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END			  
		

	DECLARE  @StartDate		 DATETIME2 
			,@EndDate		 DATETIME2  
			,@PeriodStart	 DATETIME2
			,@PeriodEnd		 DATETIME2
			,@VolumeCase	 int = 0
			,@FirstHLDate 	 INT = 19000101
			,@EvaluationDate DATETIME2
			,@PK_Distributor INT = (SELECT nDistributorID FROM v_Distributor  WHERE sDistributorID = @DistributorID)
			-- Custom Promo.Options
			,@QSAsSP		 BIT = ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'QSAsSP' AND [Group] = 'app' AND IsActive = 1), 1)
			,@First_PK_Target INT = ISNULL( (SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'First_PK_Target' AND [Group] = 'typ' AND IsActive = 1 )
										  ,(SELECT MIN(PK_Target) FROM Promo.TargetByPattern WITH (NOLOCK) WHERE PK_Event = @PK_Event AND ISNULL(QualCut,1) = 1 GROUP BY PK_Event) )			-- 1.0.5
			,@RangeHigherTargetOnly BIT = ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'RangeHigherTargetOnly' AND [Group] = 'typ' AND IsActive = 1), 0)	
			,@StaticPeriodOutput	 BIT = ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'StaticPeriodOutput' AND [Group] = 'app' AND IsActive = 1), 0)
			
			--Custom dbo.EventPromoTemplate
			,@VolumeByCOP	NVARCHAR(1000) =   (SELECT VolumeByCOP FROM EventPromoTemplate WITH (NOLOCK) WHERE PK_Event = @PK_Event)
			,@CustomEvalDate NVARCHAR (1000) = (SELECT CustomEvalDate FROM EventPromoTemplate WITH (NOLOCK) WHERE PK_Event = @PK_Event)
			,@TemplateNumber INT = (SELECT LEFT(PK_EventPromoTemplateType,1) FROM EventPromoTemplate WITH (NOLOCK) WHERE PK_Event = @PK_Event)					-- 1.0.5
			,@OrderPurpose NVARCHAR (1000) = (SELECT OrderPurpose FROM EventPromoTemplate WITH (NOLOCK) WHERE PK_Event = @PK_Event)
	
	DECLARE  @DiffTarget_QId INT = @First_PK_Target -1
			,@MonthsQualPromo INT =ISNULL((SELECT [Value] FROM Promo.Options WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [Key] = 'MonthsQualPromo' AND [Group] = 'app' AND IsActive = 1)
										 ,(SELECT MonthPromoPeriod FROM Promo.TargetByPattern T WITH (NOLOCK) WHERE T.PK_Event = @PK_Event AND PK_Target = @First_PK_Target			)
										 )-- If not configured in Options, Use MonthPromoPeriod from TargetByPattern
	
	SELECT @CurrentDate = CONVERT(DATE,ISNULL(@CurrentDate,GETUTCDATE()))			--US 720693
	
	-- Setup @EvaluationDate, @StartDate & @EndDate  -- EXAMPLE SET @CustomEvalDate = 'SELECT @EvaluationDate = ''20210901'' '
	IF(LEFT(@CustomEvalDate,6) = 'SELECT')
	BEGIN
		DECLARE @ParmDefinition nvarchar(500)= N'@EvaluationDate DATETIME2 OUTPUT'

		EXEC sp_executesql @CustomEvalDate, @ParmDefinition, @EvaluationDate = @EvaluationDate OUTPUT 
	END
	ELSE IF(ISDATE(@CustomEvalDate) = 1)					-- 1.0.2
		SET @EvaluationDate = @CustomEvalDate													  
			
	SELECT  @EvaluationDate =  CASE					WHEN @CustomEvalDate = 'QualPeriodStart'  THEN E.QualPeriodStart
													WHEN @CustomEvalDate = 'dInitialAppDate'  THEN ISNULL(d.dInitialAppDate,(CASE WHEN (MBApplicationDate IS NOT NULL AND MBApplicationDate <> 19000101 AND MBApplicationDate <  APPLICATIONDATE) OR APPLICATIONDATE = 19000101
																				 THEN dMBApplicationDate ELSE dApplicationDate END))----1.2.0
													WHEN @CustomEvalDate = 'dApplicationDate' THEN D.dApplicationDate
													WHEN @CustomEvalDate = 'dContractAcceptanceDate' AND S.PK_Distributor IS NOT NULL THEN D.dApplicationDate
													WHEN @CustomEvalDate = 'dContractAcceptanceDate' AND S.PK_Distributor IS NULL THEN D.dContractAcceptanceDate
													WHEN @CustomEvalDate = 'dSPQualDate' 		THEN D.dSPQualDate
													WHEN @CustomEvalDate = 'dQSQualDate' 		THEN D.dQSQualDate
													WHEN @CustomEvalDate = 'PeriodStartDate'  THEN T.PeriodStartDate
													ELSE  IIF(@EvaluationDate IS NOT NULL, @EvaluationDate, E.QualPeriodStart)	
							  END 
			,@StartDate = IIF(S.PK_Distributor IS NOT NULL,D.dApplicationDate,d.dContractAcceptanceDate)--  E.QualPeriodStart
			,@EndDate = IIF(S.PK_Distributor IS NOT NULL,DATEADD(MM,3,D.dApplicationDate),DATEADD(MM,4,d.dContractAcceptanceDate))--E.QualPeriodEnd 
	FROM [Promo].[dimDistributor] AS D WITH (NOLOCK)
	INNER JOIN [dbo].[Event] AS E WITH (NOLOCK)
		ON E.PK_Event = @PK_Event
	INNER JOIN Promo.TargetByPattern T WITH (NOLOCK)
		ON T.PK_Event = @PK_Event
		AND T.PK_Target = @First_PK_Target					
	LEFT JOIN Promo.DSSubEvent AS S (NOLOCK)
		ON  S.PK_Distributor = D.PK_Distributor
		AND S.PK_Event = E.PK_Event
		AND S.DateQualified < 202501
	WHERE D.PK_Distributor = @PK_Distributor;

 
	DROP TABLE IF EXISTS #Volume

	CREATE TABLE #Volume(
		 PK_Distributor BIGINT					   
		,RoyaltyMonth	INT
		,PPV			MONEY
		,DLV			MONEY
		,TVP			MONEY
		,GV				MONEY
		,LastOrder		INT
		,n				INT
		,IsFQS			TINYINT
		,IsQS			TINYINT
		,MB_POINTS		MONEY
		,IsPM			TINYINT
		,DLV_PM			MONEY	--Referral points
		,PV				MONEY
		,PPV_DLV		AS PPV + DLV
		,PPV_DLV_PM		AS PPV + DLV_PM
		,VP				MONEY ----1.0.13
		,MPCV			MONEY
		,TOTAL_POINTS	MONEY
		,QCPV			MONEY
		,QDV			MONEY
		,RP				MONEY
		,DS_PPV			MONEY
		,PM_PPV			MONEY
	 )


	 IF @EndDate = '2025-02-01'
		BEGIN
		
			SET @VolumeCase = 2
			SET @PeriodStart = @EndDate
			SET @PeriodEnd = @EndDate
			SET @EndDate = DATEADD(MM,1,@StartDate)
			SET @StartDate = '2024-10-01'
		
		END
		ELSE IF @EndDate = '2025-03-01'
		BEGIN

			SET @VolumeCase = 3
			SET @PeriodStart = DATEADD(MM,1,@StartDate)--'2025-02-01'
			SET @PeriodEnd = @EndDate--'2025-03-31'
			SET @EndDate = @StartDate
		
		END
		
		
		IF @VolumeCase > 0
		BEGIN

			INSERT #Volume (PK_Distributor,RoyaltyMonth,PPV,DLV,TVP,GV,LastOrder,n,IsFQS,IsQS,MB_POINTS,IsPM,DLV_PM,PV,VP,MPCV,TOTAL_POINTS,QCPV,QDV,RP,DS_PPV,PM_PPV ) ----1.0.13
			SELECT PK_Distributor,RoyaltyMonth,PPV,DLV,VP,GV,LastOrder,n,IsFQS,IsQS,MB_POINTS,IsPM,DLV_PM,PV,VP,MPCV,TOTAL_POINTS,QCPV,QDV,RP,DS_PPV,PM_PPV   ----1.0.13
			FROM Promo.udf_getDSVolumePoints_v3 (@PK_Distributor,@PeriodStart,@PeriodEnd,@VolumeByCOP,@QSAsSP,@OrderPurpose,@PK_Event)
			
		END
		
		IF @EndDate <= '2025-01-01'
		SET @VolumeByCOP = NULL
		

	 -- Get Volume Points
	 INSERT #Volume (PK_Distributor,RoyaltyMonth,PPV,DLV,TVP,GV,LastOrder,n,IsFQS,IsQS,MB_POINTS,IsPM,DLV_PM,PV,VP,MPCV,TOTAL_POINTS,QCPV,QDV,RP,DS_PPV,PM_PPV ) ----1.0.13
	 SELECT PK_Distributor,RoyaltyMonth,PPV,DLV,VP,GV,LastOrder,n,IsFQS,IsQS,MB_POINTS,IsPM,DLV_PM,PV,VP,MPCV,TOTAL_POINTS,QCPV,QDV,RP,DS_PPV,PM_PPV   ----1.0.13
	 FROM Promo.udf_getDSVolumePoints_v3 (@PK_Distributor,@StartDate,@EndDate,@VolumeByCOP,@QSAsSP,@OrderPurpose,@PK_Event)


	CREATE INDEX IX_#Volume_PKs ON #Volume(PK_Distributor, RoyaltyMonth)
			
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
			--,T.ConsecutiveMonths
			,CASE WHEN D.DateQualified < 202501 THEN 4 ELSE 5 END AS ConsecutiveMonths
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
		
		-- First ResultSet
		SELECT [Name], [Metric], [Value],[Type],[Group],[Operator],IsMain,Cut,[Status]
				,dDateQualified AS DateQualified, Baseline AS BaselineDate, ConsecutiveMonths			-- 1.0.3
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
				,T.ConsecutiveMonths AS VisibleMonths--@VisibleMonths AS VisibleMonths	
				,@MonthsQualPromo AS MonthsQualPromo														 -- 1.0.4
				,DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDate), 0) AS CurrentMonth
				,CAST(NULL AS DATETIME2) AS OutputDateStart							   
				,CAST(NULL AS DATETIME2) AS OutputDateEnd
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
		SET	 OutputDateStart = IIF(@TemplateNumber = 3 AND @EvaluationDate IS NOT NULL AND DATEADD(MONTH, -(VisibleMonths-1),dDateQualified)<@EvaluationDate,@EvaluationDate,DATEADD(MONTH, -(VisibleMonths-1),dDateQualified))
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


		 IF(@TemplateNumber = 4)
		 BEGIN
			SELECT 
				 @OutputDateStart = MIN(DateStart) 
				,@OutputDateEnd = MAX(DATEADD(MONTH,ConsecutiveMonths,DateStart))
			FROM #Targets

		 END

		 SELECT @OutputDateStart = (DATEADD(dd, -( DAY( @OutputDateStart ) -1 ), @OutputDateStart))----1.0.14 PROD BUG 1294358


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
				,NULL AS TargetGroups
		FROM #Volume 
		UNPIVOT ( [Value] 
					FOR [Metric] IN (PPV,DLV,TVP,GV,MB_POINTS,DLV_PM,PV,PPV_DLV,PPV_DLV_PM,[VP],MPCV,TOTAL_POINTS,QCPV,QDV,RP,DS_PPV,PM_PPV)----1.0.13 
		)AS A
		INNER JOIN cte_Targets T WITH (NOLOCK)
			ON T.Metric = A.Metric	
		INNER JOIN #IncrementalBaseLine	INC
			ON INC.BaseLine = CAST((CAST(A.RoyaltyMonth AS VARCHAR)+'01') AS DATETIME2)
			AND INC.Metric = A.Metric
		WHERE @TemplateNumber = 4
		GROUP BY A.RoyaltyMonth, A.Metric, A.[Value]		
		UNION
		SELECT DISTINCT
				CAST((CAST(A.RoyaltyMonth AS VARCHAR)+'01') AS DATE) AS MonthDate
				,A.Metric 
				,A.[Value]
				,STRING_AGG(T.[Group],',') AS TargetGroups
		FROM #Volume 
		UNPIVOT ( [Value] 
					FOR [Metric] IN (PPV,DLV,TVP,GV,MB_POINTS,DLV_PM,PV,PPV_DLV,PPV_DLV_PM,[VP],MPCV,TOTAL_POINTS,QCPV,QDV,RP,DS_PPV,PM_PPV)----1.0.13 
		)AS A
		INNER JOIN cte_Targets T WITH (NOLOCK)
			ON T.Metric = A.Metric							  
		WHERE CAST((CAST(A.RoyaltyMonth AS VARCHAR)+'01') AS DATETIME2) BETWEEN @OutputDateStart AND @OutputDateEnd
		GROUP BY A.RoyaltyMonth, A.Metric, A.[Value]
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
	
	 --Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StoredProcedureParameters = @Param 											 
	,@StartTime = @StartTime
	
END;