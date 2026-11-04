CREATE FUNCTION dbo.ufn_QualByPoints(
	@PK_Distributor INT,
	@StartDate DATE,
	@EndDate DATE,
	@Frequency SMALLINT,
	@Consecutive BIT,
	@Accumulated BIT,
	@MetricType VARCHAR(4),
	@MinPoints MONEY,
	@GoalPoints MONEY
)
RETURNS TABLE
AS
RETURN(
	WITH CTM_Points
	(
		RoyaltyMonth,
		PK_Distributor,
		DistributorID,
		dDeleted,
		dQual_SP,
		dQual_QS,
		dQual_QS_Actual,
		sTeam,
		sCOP,
		nIsAssocType23,
		nIsMainID,
		nIsInAssocTable,
		nMainDistributorID,
		sMainDistributorID,
		dMainDeleted,
		dMainQual_SP,
		sMainTeam,
		sMainCOP,
		nMainIsType23,
		MetricType,
		Points
	)
	AS
	(
	SELECT
		RoyaltyMonth,
		PK_Distributor,
		DistributorID,
		dDeleted,
		dQual_SP,
		dQual_QS,
		dQual_QS_Actual,
		sTeam,
		sCOP,
		nIsAssocType23,
		nIsMainID,
		nIsInAssocTable,
		nMainDistributorID,
		sMainDistributorID,
		dMainDeleted,
		dMainQual_SP,
		sMainTeam,
		sMainCOP,
		nMainIsType23,
		MetricType,
		Points 
	FROM dbo.ufn_GetPointsUnpivot(@PK_Distributor, @StartDate, @EndDate)
	WHERE MetricType = @MetricType
	)

		/* Accumulated/Consecutive */
		SELECT
			B.PK_Distributor,
			B.MetricType,
			@MinPoints MinPoints,
			@GoalPoints AS GoalPoints,
			CASE
				WHEN @Consecutive = 1
					THEN 'Consecutive'
					ELSE 'Any'
			END AS Consecutive_Any,
			ISNULL(NULLIF(@Frequency,0),(DATEDIFF(MONTH, @StartDate, @EndDate) + 1)) AS Frequency,
			CASE
				WHEN @Accumulated = 1
					THEN 'Accumulated'
					ELSE 'Achieve'
			END AS Accumulated_Achieve,
			@StartDate AS StartDate,
			@EndDate AS EndDate,
			MIN(A.EndDate) AS QualDate
		FROM
			dbo.ufn_GetPeriods(@StartDate, @EndDate, ISNULL(NULLIF(@Frequency,0),(DATEDIFF(MONTH, @StartDate, @EndDate) + 1)), @Consecutive, @Accumulated) A
		CROSS APPLY (
			SELECT
				P.PK_Distributor,
				P.MetricType
			FROM
				CTM_Points P
			WHERE
				P.PK_Distributor = @PK_Distributor
				AND
				P.RoyaltyMonth BETWEEN A.StartDate AND A.EndDate
				AND
				P.MetricType = @MetricType
				AND
				P.Points >= @MinPoints
				AND
				@Consecutive = 1
				AND
				@Accumulated  = 1
			GROUP BY P.PK_Distributor, P.MetricType
			HAVING SUM(P.Points) >= @GoalPoints
		) B
		WHERE
			B.PK_Distributor = @PK_Distributor
			AND
			@Consecutive = 1
			AND
			@Accumulated  = 1
		GROUP BY
			B.PK_Distributor,
			B.MetricType
			
	UNION ALL

		/* Accumulated/Not-Consecutive */
		SELECT
			FP.PK_Distributor,
			FP.MetricType,
			@MinPoints MinPoints,
			@GoalPoints AS GoalPoints,
			CASE
				WHEN @Consecutive = 1
					THEN 'Consecutive'
					ELSE 'Any'
			END AS Consecutive_Any,
			ISNULL(NULLIF(@Frequency,0),(DATEDIFF(MONTH, @StartDate, @EndDate) + 1)) AS Frequency,
			CASE
				WHEN @Accumulated = 1
					THEN 'Accumulated'
					ELSE 'Achieve'
			END AS Accumulated_Achieve,
			@StartDate AS StartDate,
			@EndDate AS EndDate,
			MAX(FP.QualDate) AS QualDate
		FROM 
		(
			SELECT 
				P.PK_Distributor,
				P.MetricType,
				P.RoyaltyMonth QualDate,
				P.Points,
				ROW_NUMBER() OVER(PARTITION BY P.PK_Distributor, P.MetricType ORDER BY P.Points DESC) AS ROWMonth,
				COUNT(1) OVER(PARTITION BY P.PK_Distributor, P.MetricType)  AS TotalRows
			FROM
				CTM_Points P
			WHERE
				P.PK_Distributor = @PK_Distributor
				AND
				P.RoyaltyMonth BETWEEN @StartDate AND @EndDate
				AND
				P.MetricType = @MetricType
				AND
				P.Points >= @MinPoints
				AND
				@Consecutive = 0
				AND
				@Accumulated  = 1
		) FP
		WHERE
			FP.PK_Distributor = @PK_Distributor
			AND
			ROWMonth BETWEEN 1 AND ISNULL(NULLIF(@Frequency,0),(DATEDIFF(MONTH, @StartDate, @EndDate) + 1))
			AND
			@Consecutive = 0
			AND
			@Accumulated  = 1
			AND
			(
				(@MinPoints > 0 AND FP.TotalRows >= ISNULL(NULLIF(@Frequency,0),(DATEDIFF(MONTH, @StartDate, @EndDate) + 1)))
				OR
				@MinPoints <= 0
			)
		GROUP BY
			FP.PK_Distributor,
			FP.MetricType
		HAVING SUM(FP.Points) >= @GoalPoints

	UNION ALL

		/* Achieve/Not-Consecutive */
		SELECT
			B.PK_Distributor,
			B.MetricType,
			B.MinPoints,
			B.GoalPoints,
			B.Consecutive_Any,
			B.Frequency,
			B.Accumulated_Achieve,
			B.StartDate,
			B.EndDate,
			B.QualDate
		FROM 
		(
			SELECT
				P.PK_Distributor,
				P.MetricType,
				@MinPoints AS MinPoints,
				@GoalPoints AS GoalPoints,
				CASE
					WHEN @Consecutive = 1
						THEN 'Consecutive'
						ELSE 'Any'
				END AS Consecutive_Any,
				ISNULL(NULLIF(@Frequency,0),(DATEDIFF(MONTH, @StartDate, @EndDate) + 1)) AS Frequency,
				CASE
					WHEN @Accumulated = 1
						THEN 'Accumulated'
						ELSE 'Achieve'
				END AS Accumulated_Achieve,
				@StartDate AS StartDate,
				@EndDate AS EndDate,
				MAX(P.RoyaltyMonth) AS QualDate
			FROM 
				CTM_Points P
			WHERE
				P.PK_Distributor = @PK_Distributor
				AND
				RoyaltyMonth BETWEEN @StartDate AND @EndDate
				AND
				MetricType = @MetricType
				AND
				Points >= @MinPoints
				AND
				Points >= @GoalPoints
				AND
				@Consecutive = 0
				AND
				@Accumulated  = 0
			GROUP BY P.PK_Distributor, P.MetricType
			HAVING COUNT(*) >= ISNULL(NULLIF(@Frequency,0),(DATEDIFF(MONTH, @StartDate, @EndDate) + 1))
		) B
		WHERE
			B.PK_Distributor = @PK_Distributor
			AND
			@Consecutive = 0
			AND
			@Accumulated  = 0

	UNION ALL

		/* Achieve/Consecutive */
		SELECT
			MB.PK_Distributor,
			MB.MetricType,
			@MinPoints MinPoints,
			@GoalPoints AS GoalPoints,
			CASE
				WHEN @Consecutive = 1
					THEN 'Consecutive'
					ELSE 'Any'
			END AS Consecutive_Any,
			ISNULL(NULLIF(@Frequency,0),(DATEDIFF(MONTH, @StartDate, @EndDate) + 1)) AS Frequency,
			CASE
				WHEN @Accumulated = 1
					THEN 'Accumulated'
					ELSE 'Achieve'
			END AS Accumulated_Achieve,
			@StartDate AS StartDate,
			@EndDate AS EndDate,
			DATEADD(mm, -ROWMonth + 1, MB.RoyaltyMonth)  AS QualDate
		FROM
		(
			SELECT 
				P.PK_Distributor,
				P.MetricType,
				P.RoyaltyMonth,
				P.Points,
				ROW_NUMBER() OVER(PARTITION BY P.PK_Distributor, P.MetricType ORDER BY P.RoyaltyMonth) AS ROWMonth 
			FROM
				CTM_Points P
			WHERE
				P.PK_Distributor = @PK_Distributor
				AND
				P.RoyaltyMonth BETWEEN @StartDate AND @EndDate
				AND
				P.MetricType = @MetricType
				AND
				P.Points >= @GoalPoints
				AND
				@Consecutive = 1
				AND
				@Accumulated  = 0
		) MB
		WHERE
			MB.PK_Distributor = @PK_Distributor
			AND
			@Consecutive = 1
			AND
			@Accumulated  = 0
		GROUP BY
			MB.PK_Distributor,
			MB.MetricType,
			DATEADD(mm, -ROWMonth + 1, RoyaltyMonth)
		HAVING COUNT(1) >= ISNULL(NULLIF(@Frequency,0),(DATEDIFF(MONTH, @StartDate, @EndDate) + 1))
);
GO

