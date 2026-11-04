CREATE FUNCTION dbo.ufn_QualByASP(
	@PK_Distributor INT,
	@StartDate DATE,
	@EndDate DATE
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
	WHERE MetricType = 'TV'
	AND Points >= 2500
	)

	
	/* Achieve/Consecutive */
SELECT 
		X.PK_Distributor,
		X.MetricType,
		2500 AS MinPoints,
		2500 AS GoalPoints,
		'Consecutive' AS Consecutive_Any,
		3 AS Frequency,
		'Achieve' AS Accumulated_Achieve,
		@StartDate AS StartDate,
		@EndDate AS EndDate,
		MIN(X.QualDate) AS QualDate
FROM (
	SELECT
		MB.PK_Distributor,
		MB.MetricType,
		((DATEADD(mm, -ROWMonth + 1, MB.RoyaltyMonth)))  AS QualDate
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
			P.MetricType = 'TV'
			AND
			P.Points >= 2500

	) MB
	GROUP BY
		MB.PK_Distributor,
		MB.MetricType,
		--UQ.MinPoints,
		--UQ.GoalPoints,
		--UQ.Consecutive,
		--UQ.Frequency,
		--UQ.Accumulated,
		--UQ.StartDate,
		--UQ.EndDate,
		(DATEADD(mm, -ROWMonth + 1, RoyaltyMonth))
	HAVING COUNT(1) >= 3
) AS X 
GROUP BY X.PK_Distributor, X.MetricType
);