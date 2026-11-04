CREATE FUNCTION [dbo].[ufn_GetQualPoints_Achieve_Consecutive](
	@PK_Distributor int,
	@PK_Event int,
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
		PK_Distributor	int,
		MetricType		varchar(5),
		MinPoints		money,
		GoalPoints		money,
		Frequency		int,
		Consecutive		bit,
		Accumulated		bit,
		StartDate		datetime2,
		EndDate			datetime2,
		QualDate		datetime2
)
AS
BEGIN

		DECLARE @iStartDate int = CAST(CONVERT(varchar(6), @dStartDate, 112) AS int),
				@iEndDate  int = CAST(CONVERT(varchar(6), @dEndDate, 112) AS int)

;WITH cte_points_DS (
		PK_Distributor,
		PK_Event,
		RoyaltyMonth,
		MetricType,
		Points
	)
	AS
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
		GROUP BY U.PK_Distributor
			,U.PK_Event
			,U.RoyaltyMonth
			,U.MetricType

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
	/* Achieve/Consecutive */ 
	-- WITHOUT taking into account the main points
	-- WW Volume
	SELECT 
		MB.PK_Distributor,
		MB.MetricType,
		X.MinPoints AS MinPoints,
		X.GoalPoints AS GoalPoints,
		X.Frequency AS Frequency,
		x.Consecutive,
		x.Accumulated, 		
		X.dStartDate AS StartDate,
		X.dEndDate AS EndDate,
		MAX(dRoyaltyMonth) AS QualDate
		--,DATEADD(mm, x.Frequency, DATEADD(mm, -ROWMonth+1, dRoyaltyMonth) )  AS QualDate
	FROM cte_config AS x
		CROSS APPLY 
		(
			SELECT 
				A.PK_Distributor,
				A.MetricType,
				A.RoyaltyMonth AS iRoyaltyMonth,
				CONVERT(datetime, CONVERT(VARCHAR(10), ((A.RoyaltyMonth * 100) + 1))) AS [dRoyaltyMonth], 
				A.Points,
				ROW_NUMBER() OVER(PARTITION BY A.PK_Distributor, A.MetricType ORDER BY A.RoyaltyMonth) AS RowMonth 
			FROM
				cte_points_DS A
			WHERE
				RoyaltyMonth BETWEEN x.iStartDate AND x.iEndDate
				AND
				MetricType = x.MetricType
				AND
				Points >= X.GoalPoints
				AND
				x.Consecutive = 1 --Consecutive
				AND
				x.Accumulated = 0 --Achieve

	) AS mb
	WHERE
		x.Consecutive = 1
		AND
		x.Accumulated  = 0
	GROUP BY mb.PK_Distributor,mb.MetricType,x.MinPoints,x.GoalPoints,x.Consecutive,x.Frequency,x.Accumulated,x.dStartDate,x.dEndDate,DATEADD(mm, -RowMonth+1, dRoyaltyMonth)
	HAVING COUNT(1) >= x.Frequency
	RETURN;
END

