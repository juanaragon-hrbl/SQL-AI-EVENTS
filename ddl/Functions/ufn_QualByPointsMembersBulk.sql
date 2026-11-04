CREATE FUNCTION [dbo].[ufn_QualByPointsMembersBulk](
	@Qual dbo.udt_QualByPoints READONLY,
	@MBIDs [dbo].[MemberList] READONLY
)
RETURNS TABLE
AS
RETURN(
WITH 
QualFilter
(
	StartDate,
	EndDate,
	MetricType
)
AS
(
	SELECT
		MIN(StartDate) StartDate,
		MAX(EndDate) EndDate,
		MetricType
	FROM @Qual
	GROUP BY MetricType
)
	,CTM_Points
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
		A.RoyaltyMonth,
		A.PK_Distributor,
		A.DistributorID,
		A.dDeleted,
		A.dQual_SP,
		A.dQual_QS,
		A.dQual_QS_Actual,
		A.sTeam,
		A.sCOP,
		A.nIsAssocType23,
		A.nIsMainID,
		A.nIsInAssocTable,
		A.nMainDistributorID,
		A.sMainDistributorID,
		A.dMainDeleted,
		A.dMainQual_SP,
		A.sMainTeam,
		A.sMainCOP,
		A.nMainIsType23,
		A.MetricType,
		A.Points 
	FROM dbo.ufn_GetPointsUnpivotByMembers((SELECT MIN(StartDate) FROM QualFilter) , (SELECT MAX(EndDate) FROM QualFilter),@MBIDs)  A
	WHERE EXISTS (SELECT 1 FROM QualFilter B WHERE A.RoyaltyMonth BETWEEN B.StartDate AND B.EndDate AND A.MetricType = B.MetricType)
	)
	/* Accumulated/Consecutive */
	SELECT
		B.PK_Distributor,
		B.MetricType,
		x.MinPoints MinPoints,
		x.GoalPoints AS GoalPoints,
		CASE WHEN x.Consecutive = 1 THEN 'Consecutive' ELSE 'Any' END AS Consecutive_Any,
		x.Frequency AS Frequency,
		CASE WHEN x.Accumulated = 1 THEN 'Accumulated' ELSE 'Achieve' END AS Accumulated_Achieve,
		x.StartDate AS StartDate,
		x.EndDate AS EndDate,
		MIN(A.EndDate) AS QualDate
	FROM @Qual x
		CROSS APPLY
		dbo.ufn_GetPeriods(x.StartDate, x.EndDate, x.Frequency, x.Consecutive, x.Accumulated) A
	CROSS APPLY (
		SELECT
			C.PK_Distributor,
			C.MetricType
		FROM
			CTM_Points C
		WHERE
			C.RoyaltyMonth BETWEEN A.StartDate AND A.EndDate
			AND
			C.MetricType = X.MetricType
			AND
			C.Points >= x.MinPoints
			AND
			x.Consecutive = 1
			AND
			x.Accumulated  = 1
		GROUP BY C.PK_Distributor, C.MetricType
		HAVING SUM(C.Points) >= x.GoalPoints
	) B
	WHERE
		x.Consecutive = 1
		AND
		x.Accumulated  = 1
	GROUP BY B.PK_Distributor, B.MetricType, x.MinPoints,x.GoalPoints,x.Consecutive,x.Frequency,x.Accumulated,x.StartDate,x.EndDate

			
	UNION ALL

	/* Accumulated/Not-Consecutive */
	SELECT
		PK_Distributor,
		MetricType,
		MinPoints,
		GoalPoints,
		Consecutive_Any,
		Frequency,
		Accumulated_Achieve,
		StartDate,
		EndDate,
		QualDate
	FROM (
			SELECT
				B.PK_Distributor,
				B.MetricType,
				x.MinPoints MinPoints,
				x.GoalPoints AS GoalPoints,
				CASE WHEN x.Consecutive = 1 THEN 'Consecutive' ELSE 'Any' END AS Consecutive_Any,
				x.Frequency AS Frequency,
				CASE WHEN x.Accumulated = 1 THEN 'Accumulated' ELSE 'Achieve' END AS Accumulated_Achieve,
				x.StartDate AS StartDate,
				x.EndDate AS EndDate,
				MAX(B.QualDate) AS QualDate,
				SUM(B.Points) AS TotalPoints,
				COUNT(1) AS TotalRows
				FROM @Qual x
				CROSS APPLY 
			(
				SELECT 
					A.PK_Distributor,
					A.MetricType,
					A.RoyaltyMonth QualDate,
					A.Points,
					ROW_NUMBER() OVER(PARTITION BY A.PK_Distributor,A.MetricType ORDER BY A.Points DESC) AS ROWMonth 
				FROM
					CTM_Points A
				WHERE
					A.RoyaltyMonth BETWEEN x.StartDate AND x.EndDate
					AND
					A.MetricType = x.MetricType
					AND
					A.Points >= x.MinPoints
					AND
					x.Consecutive = 0
					AND
					x.Accumulated  = 1
			) B
			WHERE
				ROWMonth BETWEEN 1 AND x.Frequency
				AND
				x.Consecutive = 0
				AND
				x.Accumulated  = 1
			GROUP BY B.PK_Distributor, B.MetricType, x.MinPoints,x.GoalPoints,x.Consecutive,x.Frequency,x.Accumulated,x.StartDate,x.EndDate
	) AS Y
	WHERE
		Y.TotalPoints >= Y.GoalPoints
		AND
		(
			(Y.MinPoints > 0 AND Y.TotalRows >= Y.Frequency)
			OR
			Y.MinPoints <= 0
		)

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
	FROM @Qual x
			CROSS APPLY
			(
		SELECT
			A.PK_Distributor,
			A.MetricType,
			X.MinPoints,
			X.GoalPoints,
			CASE WHEN X.Consecutive = 1 THEN 'Consecutive' ELSE 'Any' END AS Consecutive_Any,
			X.Frequency AS Frequency,
			CASE WHEN X.Accumulated = 1 THEN 'Accumulated' ELSE 'Achieve' END AS Accumulated_Achieve,
			X.StartDate AS StartDate,
			X.EndDate AS EndDate,
			MAX(A.RoyaltyMonth) AS QualDate
		FROM 
			CTM_Points A
		WHERE
			RoyaltyMonth BETWEEN X.StartDate AND X.EndDate
			AND
			MetricType = X.MetricType
			AND
			Points >= X.MinPoints
			AND
			Points >= X.GoalPoints
			AND
			X.Consecutive = 0
			AND
			X.Accumulated  = 0
		GROUP BY A.PK_Distributor, A.MetricType
		HAVING COUNT(*) >= X.Frequency
		) B
		WHERE
			X.Consecutive = 0
			AND
			X.Accumulated  = 0

	UNION ALL

	/* Achieve/Consecutive */
	SELECT 
		MB.PK_Distributor,
		MB.MetricType,
		X.MinPoints MinPoints,
		X.GoalPoints AS GoalPoints,
		CASE WHEN X.Consecutive = 1 THEN 'Consecutive' ELSE 'Any' END AS Consecutive_Any,
		X.Frequency AS Frequency,
		CASE WHEN X.Accumulated = 1 THEN 'Accumulated' ELSE 'Achieve' END AS Accumulated_Achieve,
		X.StartDate AS StartDate,
		X.EndDate AS EndDate,
		DATEADD(mm, -ROWMonth + 1, MB.RoyaltyMonth)  AS QualDate
	FROM @Qual x
		CROSS APPLY 
	(
		SELECT 
			A.PK_Distributor,
			A.MetricType,
			A.RoyaltyMonth,
			A.Points,
			ROW_NUMBER() OVER(PARTITION BY A.PK_Distributor, A.MetricType ORDER BY A.RoyaltyMonth) AS ROWMonth 
		FROM
			CTM_Points A
		WHERE
			RoyaltyMonth BETWEEN X.StartDate AND X.EndDate
			AND
			MetricType = X.MetricType
			AND
			Points >= X.GoalPoints
			AND
			X.Consecutive = 1
			AND
			X.Accumulated  = 0

	) MB
	WHERE
		X.Consecutive = 1
		AND
		X.Accumulated  = 0
	GROUP BY MB.PK_Distributor,MB.MetricType,X.MinPoints,X.GoalPoints,X.Consecutive,X.Frequency,X.Accumulated,X.StartDate,X.EndDate,DATEADD(mm, -ROWMonth + 1, RoyaltyMonth)
	HAVING COUNT(1) >= X.Frequency
);
GO
