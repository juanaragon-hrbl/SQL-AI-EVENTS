CREATE FUNCTION dbo.ufn_QualByBaseline(
	@PK_Distributor INT,
	@StartDateBase SMALLDATETIME,
	@EndDateBase SMALLDATETIME,
	@StartDateTarget SMALLDATETIME,
	@EndDateTarget SMALLDATETIME,
	@MetricType VARCHAR(4),
	@MessurementType INT, /*1.- Average	2.- Sum*/
	@IncreasingType INT , /*1.- Amount	2.- Percentage	*/
	@Increase MONEY

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
	FROM dbo.ufn_GetPointsUnpivot2Periods (@PK_Distributor, @StartDateBase, @EndDateBase, @StartDateTarget, @EndDateTarget) 
	),
	VersusPoints(PK_Distributor, MetricType, SumPointsBase, AvgPointsBase, SumPointsTarget, AvgPointsTarget)
	AS
	(
	SELECT 
		PK_Distributor,
		MetricType,
		SUM(CASE WHEN RoyaltyMonth BETWEEN @StartDateBase AND @EndDateBase THEN Points ELSE 0 END) AS SumPointsBase,
		SUM(CASE WHEN RoyaltyMonth BETWEEN @StartDateBase AND @EndDateBase THEN Points ELSE 0 END) / (DATEDIFF(MONTH, @StartDateBase, @EndDateBase) + 1)  AS AvgPointsBase,
		SUM(CASE WHEN RoyaltyMonth BETWEEN @StartDateTarget AND @EndDateTarget THEN Points ELSE 0 END) AS SumPointsTarget,
		SUM(CASE WHEN RoyaltyMonth BETWEEN @StartDateTarget AND @EndDateTarget THEN Points ELSE 0 END) / (DATEDIFF(MONTH, @StartDateTarget, @EndDateTarget) + 1)  AS AvgPointsTarget
	FROM CTM_Points
	WHERE (RoyaltyMonth BETWEEN @StartDateBase AND @EndDateBase
		OR RoyaltyMonth BETWEEN @StartDateTarget AND @EndDateTarget)
	AND MetricType = @MetricType
	AND PK_Distributor = @PK_Distributor
	GROUP BY PK_Distributor, MetricType
	)


	/*1.- Average	1.- Amount*/
	SELECT
		PK_Distributor,
		MetricType,
		SumPointsBase,
		SumPointsTarget,
		AvgPointsBase,
		AvgPointsTarget,
		@StartDateBase AS StartDateBase,
		@EndDateBase AS EndDateBase,
		@StartDateTarget AS StartDateTarget,
		@EndDateTarget AS EndDateTarget,
		@MessurementType AS MessurementType, /*1.- Average	2.- Sum*/
		CASE @MessurementType
			WHEN 1 THEN 'Average'
			WHEN 2 THEN 'Sum'
		END	AS MessurementTypeDesc,
		@IncreasingType AS IncreasingType, /*1.- Amount	2.- Percentage	*/
		CASE @IncreasingType
			WHEN 1 THEN 'Amount'
			WHEN 2 THEN 'Percentage'
		END AS IncreasingTypeDesc,
		@Increase AS Increase,
		AvgPointsTarget - AvgPointsBase ActualIncrease
	FROM VersusPoints
	WHERE
		@MessurementType = 1
		AND @IncreasingType = 1
		AND MetricType = @MetricType
		AND PK_Distributor = @PK_Distributor
		AND AvgPointsTarget >= AvgPointsBase + @Increase
		AND (AvgPointsBase > 0 OR AvgPointsTarget > 0)

		UNION ALL

	/*1.- Average	2.- Percentage*/
	SELECT
		PK_Distributor,
		MetricType,
		SumPointsBase,
		SumPointsTarget,
		AvgPointsBase,
		AvgPointsTarget,
		@StartDateBase AS StartDateBase,
		@EndDateBase AS EndDateBase,
		@StartDateTarget AS StartDateTarget,
		@EndDateTarget AS EndDateTarget,
		@MessurementType AS MessurementType, /*1.- Average	2.- Sum*/
		CASE @MessurementType
			WHEN 1 THEN 'Average'
			WHEN 2 THEN 'Sum'
		END	AS MessurementTypeDesc,
		@IncreasingType AS IncreasingType, /*1.- Amount	2.- Percentage	*/
		CASE @IncreasingType
			WHEN 1 THEN 'Amount'
			WHEN 2 THEN 'Percentage'
		END AS IncreasingTypeDesc,
		@Increase AS Increase,
		ISNULL(((AvgPointsTarget / NULLIF(AvgPointsBase, 0)) - 1), 1) AS ActualIncrease
	FROM VersusPoints
	WHERE
		@MessurementType = 1
		AND @IncreasingType = 2
		AND MetricType = @MetricType
		AND PK_Distributor = @PK_Distributor
		AND ISNULL(((AvgPointsTarget / NULLIF(AvgPointsBase, 0)) - 1), 1) >= (@Increase / 100)
		AND (AvgPointsBase > 0 OR AvgPointsTarget > 0)

		UNION ALL

	/*2.- Sum		1.- Amount*/
	SELECT
		PK_Distributor,
		MetricType,
		SumPointsBase,
		SumPointsTarget,
		AvgPointsBase,
		AvgPointsTarget,
		@StartDateBase AS StartDateBase,
		@EndDateBase AS EndDateBase,
		@StartDateTarget AS StartDateTarget,
		@EndDateTarget AS EndDateTarget,
		@MessurementType AS MessurementType, /*1.- Average	2.- Sum*/
		CASE @MessurementType
			WHEN 1 THEN 'Average'
			WHEN 2 THEN 'Sum'
		END	AS MessurementTypeDesc,
		@IncreasingType AS IncreasingType, /*1.- Amount	2.- Percentage	*/
		CASE @IncreasingType
			WHEN 1 THEN 'Amount'
			WHEN 2 THEN 'Percentage'
		END AS IncreasingTypeDesc,
		@Increase AS Increase,
		SumPointsTarget - SumPointsBase ActualIncrease
	FROM VersusPoints
	WHERE
		@MessurementType = 2
		AND @IncreasingType = 1
		AND MetricType = @MetricType
		AND PK_Distributor = @PK_Distributor
		AND SumPointsTarget >= SumPointsBase + @Increase
		AND (SumPointsBase > 0 OR SumPointsTarget > 0)

		UNION ALL

/*2.- Sum		2.- Percentage*/
	SELECT
		PK_Distributor,
		MetricType,
		SumPointsBase,
		SumPointsTarget,
		AvgPointsBase,
		AvgPointsTarget,
		@StartDateBase AS StartDateBase,
		@EndDateBase AS EndDateBase,
		@StartDateTarget AS StartDateTarget,
		@EndDateTarget AS EndDateTarget,
		@MessurementType AS MessurementType, /*1.- Average	2.- Sum*/
		CASE @MessurementType
			WHEN 1 THEN 'Average'
			WHEN 2 THEN 'Sum'
		END	AS MessurementTypeDesc,
		@IncreasingType AS IncreasingType, /*1.- Amount	2.- Percentage	*/
		CASE @IncreasingType
			WHEN 1 THEN 'Amount'
			WHEN 2 THEN 'Percentage'
		END AS IncreasingTypeDesc,
		@Increase AS Increase,
		ISNULL(((SumPointsTarget / NULLIF(SumPointsBase, 0)) - 1), 1)  AS ActualIncrease
	FROM VersusPoints
	WHERE
		@MessurementType = 2
		AND @IncreasingType = 2
		AND MetricType = @MetricType
		AND PK_Distributor = @PK_Distributor
		AND ISNULL(((SumPointsTarget / NULLIF(SumPointsBase, 0)) - 1), 1) >= (@Increase / 100)
		AND (SumPointsBase > 0 OR SumPointsTarget > 0)
);
GO

