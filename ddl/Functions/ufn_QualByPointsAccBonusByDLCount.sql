CREATE FUNCTION dbo.ufn_QualByPointsAccBonusByDLCount(
	@PK_Distributor	INT,
	@StartDate		DATE,
	@EndDate		DATE,
	@Frequency		SMALLINT,
	@Consecutive	BIT,
	@MetricType		VARCHAR(4),
	@MinPoints		MONEY,
	@GoalPoints		MONEY,
	@DLCount		INT,
	@BonusByDlCount MONEY,
	@BonusLimit		MONEY
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
		'Accumulated' AS Accumulated_Achieve,
		@StartDate AS StartDate,
		@EndDate AS EndDate,
		MIN(A.EndDate) AS QualDate
	FROM
		dbo.ufn_GetPeriods(@StartDate, @EndDate, ISNULL(NULLIF(@Frequency,0),(DATEDIFF(MONTH, @StartDate, @EndDate) + 1)), @Consecutive, 1) A
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
		GROUP BY P.PK_Distributor, P.MetricType
		HAVING (SUM(P.Points) + (@DLCount * @BonusByDlCount))  >= @GoalPoints
	) B

	WHERE
		@Consecutive = 1
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
		'Accumulated' AS Accumulated_Achieve,
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
	) FP

	WHERE
		ROWMonth BETWEEN 1 AND ISNULL(NULLIF(@Frequency,0),(DATEDIFF(MONTH, @StartDate, @EndDate) + 1))
		AND
		@Consecutive = 0
		AND
		(
			(@MinPoints > 0 AND FP.TotalRows >= ISNULL(NULLIF(@Frequency,0),(DATEDIFF(MONTH, @StartDate, @EndDate) + 1)))
			OR
			@MinPoints <= 0
		)
	GROUP BY
		FP.PK_Distributor,
		FP.MetricType
	HAVING (SUM(FP.Points) + dbo.ufn_GetActualBonus(@BonusLimit,(@DLCount * @BonusByDlCount))) >= @GoalPoints
);