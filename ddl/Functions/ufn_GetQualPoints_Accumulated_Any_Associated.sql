CREATE FUNCTION [dbo].[ufn_GetQualPoints_Accumulated_Any_Associated](
	@PK_Distributor int,
	@PK_Event int,
	@PK_AssociatedID int,
	@MetricType varchar(5),
	@dStartDate datetime2,
	@dEndDate datetime2,
	@Frequency int,
	@Consecutive bit, 
	@Accumulated bit, 
	@MinPoints money,
	@GoalPoints money,
	@QualificationNumber int = NULL,
	@Part int = NULL
)
RETURNS @result TABLE(
		PK_Distributor			int,
		MetricType				varchar(5),
		MinPoints				money,
		GoalPoints				money,
		Frequency				int,
		Consecutive				bit,
		Accumulated				bit,
		StartDate				datetime2,
		EndDate					datetime2,
		QualDate				datetime2
)
AS
BEGIN

		DECLARE @iStartDate int = CAST(CONVERT(varchar(6), @dStartDate, 112) AS int),
				@iEndDate  int = CAST(CONVERT(varchar(6), @dEndDate, 112) AS int)


	;WITH cte_period AS
		(
			SELECT	
				@PK_Event AS [PK_Event],
				@PK_Distributor AS [PK_Distributor],
				@PK_AssociatedID AS [PK_AssociatedID],
				@MetricType AS [MetricType],
				CAST(CONVERT(varchar(6), MyDate, 112) AS int)  AS [iMonth]
			FROM dbo.SourceDate WITH (NOLOCK)
			WHERE MyDate BETWEEN @dStartDate AND @dEndDate
		)
	,cte_points_ds 	AS
	(	

	SELECT 
				U.PK_Distributor,
				U.PK_Event,
				U.RoyaltyMonth,
				U.MetricType,
				SUM(ISNULL(U.Points,0)) AS [Points]
			FROM dbo.[WRK_DSPoints] AS U WITH (NOLOCK)
				 WHERE U.PK_Event = @PK_Event
				AND U.PK_Distributor = @PK_Distributor
				AND U.MetricType = @MetricType
				AND U.RoyaltyMonth BETWEEN @iStartDate AND @iEndDate
			GROUP BY 
				U.PK_Event,
				U.PK_Distributor,
				U.MetricType,
				U.RoyaltyMonth
		)
		,cte_points_associated AS
		(

			SELECT 
				@PK_Distributor AS [PK_Distributor],
				U.PK_Event,
				U.RoyaltyMonth,
				U.MetricType,
				SUM(ISNULL(U.Points,0)) AS [Points]
			FROM dbo.[WRK_DSPoints] AS U WITH (NOLOCK)
				 WHERE U.PK_Event = @PK_Event
				AND U.PK_Distributor = @PK_AssociatedID
				AND U.MetricType = @MetricType
				AND U.RoyaltyMonth BETWEEN @iStartDate AND @iEndDate
			GROUP BY 
				U.PK_Event,
				U.PK_Distributor,
				U.MetricType,
				U.RoyaltyMonth
	)
	,cte_points AS
	(
		SELECT  
			p.PK_Distributor
			,p.PK_Event
			,p.iMonth AS [RoyaltyMonth]
			,p.MetricType
			,(ISNULL(d.Points,0) + ISNULL(a.Points,0)) AS [Points]
			FROM cte_period AS p	
			LEFT JOIN cte_points_ds AS d
				ON p.PK_Distributor = d.PK_Distributor
					AND p.PK_Event = d.PK_Event
					AND p.MetricType = d.MetricType
					AND p.iMonth = d.RoyaltyMonth
			LEFT JOIN cte_points_associated AS a
				ON p.PK_Distributor = a.PK_Distributor
					AND p.PK_Event = a.PK_Event
					AND p.MetricType = a.MetricType
					AND p.iMonth = a.RoyaltyMonth
	)
	,cte_config AS 
	(
		SELECT	@iStartDate		AS [iStartDate], 
				@dStartDate		AS [dStartDate], 
				@iEndDate		AS [iEndDate], 
				@dEndDate		AS [dEndDate], 
				@MetricType		AS [MetricType], 
				@Frequency		AS Frequency, 
				@Consecutive	AS Consecutive , 
				@Accumulated	AS Accumulated, 
				@MinPoints		AS MinPoints, 
				@GoalPoints		AS GoalPoints 
	)	
	INSERT INTO @result (	
							PK_Distributor,	
							MetricType,		
							MinPoints,		
							GoalPoints,	
							Frequency,	
							Consecutive,	
							Accumulated,		
							StartDate,		
							EndDate,			
							QualDate
						)

	/* Accumulated/Not-Consecutive */  
	-- TAKING into account the main points
	-- Volume WW
	SELECT
		PK_Distributor,
		MetricType,
		MinPoints,
		GoalPoints,
		Frequency,
		Consecutive,	
		Accumulated,
		StartDate,
		EndDate,
		QualDate
	FROM (
			SELECT
				B.PK_Distributor,
				B.MetricType,
				x.MinPoints MinPoints,
				x.GoalPoints AS GoalPoints,
				x.Frequency AS Frequency,
				x.Consecutive,
				x.Accumulated,
				x.dStartDate AS StartDate,
				x.dEndDate AS EndDate,
				MAX(B.[dRoyaltyMonth]) AS QualDate,
				SUM(B.Points) AS TotalPoints,
				COUNT(1) AS TotalRows
				FROM cte_config AS x
			CROSS APPLY 
			(
				SELECT 
					A.PK_Distributor,
					A.MetricType,
					A.RoyaltyMonth AS iRoyaltyMonth,
					CONVERT(datetime, CONVERT(VARCHAR(10), ((A.RoyaltyMonth * 100) + 1))) AS [dRoyaltyMonth], 
					A.Points,
					ROW_NUMBER() OVER(PARTITION BY A.PK_Distributor,A.MetricType ORDER BY A.Points DESC) AS RowMonth 
				FROM
					cte_points AS a
				WHERE
					a.RoyaltyMonth BETWEEN x.iStartDate AND x.iEndDate
					AND
					A.MetricType = x.MetricType
					AND
					A.Points >= x.MinPoints
					AND
					x.Consecutive = 0 --Any
					AND
					x.Accumulated  = 1 --Accumulated

			) AS b
			WHERE
				RowMonth BETWEEN 1 AND x.Frequency
				AND
				x.Consecutive = 0
				AND
				x.Accumulated  = 1
			GROUP BY B.PK_Distributor, B.MetricType, x.MinPoints,x.GoalPoints,x.Consecutive,x.Frequency,x.Accumulated,x.dStartDate,x.dEndDate
	) AS Y
	WHERE
		Y.TotalPoints >= Y.GoalPoints
		AND
		(
			(Y.MinPoints > 0 AND Y.TotalRows >= Y.Frequency)
			OR
			Y.MinPoints <= 0
		)
	RETURN;
END

