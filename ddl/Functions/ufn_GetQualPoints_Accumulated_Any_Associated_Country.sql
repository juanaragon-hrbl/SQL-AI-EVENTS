CREATE FUNCTION [dbo].[ufn_GetQualPoints_Accumulated_Any_Associated_Country](
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
	@Country varchar(max) = NULL
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


	;WITH cte_country_order AS
	(
		SELECT DISTINCT PK_Country 
		FROM dbo.[WRK_DSPoints] AS U WITH (NOLOCK)
		WHERE PK_Distributor IN (@PK_Distributor,@PK_AssociatedID)
		AND RoyaltyMonth BETWEEN @iStartDate AND @iEndDate
		AND PK_Event = @PK_Event AND MetricType = @MetricType
	)
	,cte_period AS
		(
			SELECT	
				@PK_Event AS [PK_Event],
				@PK_Distributor AS [PK_Distributor],
				@PK_AssociatedID AS [PK_AssociatedID],
				@MetricType AS [MetricType],
				CAST(CONVERT(varchar(6), MyDate, 112) AS int)  AS [iMonth],
				C.PK_Country
			FROM dbo.SourceDate WITH (NOLOCK)
			CROSS APPLY cte_country_order AS C
			WHERE MyDate BETWEEN @dStartDate AND @dEndDate
		)
	,cte_points_ds_country 	AS
	(	

		SELECT 
					U.PK_Distributor,
					U.PK_Event,
					U.PK_Country,
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
					U.PK_Country,
					U.PK_Distributor,
					U.MetricType,
					U.RoyaltyMonth
	)
	,cte_points_associated_country AS
	(

		SELECT 
			@PK_Distributor AS [PK_Distributor],
			U.PK_Event,
			U.PK_Country,
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
			U.PK_Country,
			U.PK_Distributor,
			U.MetricType,
			U.RoyaltyMonth
	)
	,cte_points AS
	(
		
		SELECT  
			p.PK_Distributor
			,p.PK_Event
			,ISNULL(d.PK_Country,a.PK_Country) AS [PK_Country]
			,p.iMonth AS [RoyaltyMonth]
			,p.MetricType
			,(ISNULL(d.Points,0) + ISNULL(a.Points,0)) AS [Points]
			FROM cte_period AS p	
			LEFT JOIN cte_points_ds_country AS d
				ON p.PK_Distributor = d.PK_Distributor
					AND p.PK_Event = d.PK_Event
					AND p.MetricType = d.MetricType
					AND p.iMonth = d.RoyaltyMonth
					AND p.PK_Country = d.PK_Country
			LEFT JOIN cte_points_associated_country AS a
				ON p.PK_Distributor = a.PK_Distributor
					AND p.PK_Event = a.PK_Event
					AND p.MetricType = a.MetricType
					AND p.iMonth = a.RoyaltyMonth
					AND p.PK_Country = a.PK_Country
	)
	, cte_points_country AS
	(
		SELECT PK_Distributor
			,PK_Event
			,[PK_Country]
			,[RoyaltyMonth]
			,MetricType
			,SUM(ISNULL(Points,0)) AS [Points]
		FROM cte_points
		WHERE Points > 0
		GROUP BY PK_Event,
				PK_Country,
				PK_Distributor,
				MetricType,
				RoyaltyMonth
	)
	,cte_countries AS (
			SELECT nCountryID,sCountryCodeISO
				FROM dbo.v_Countries
					WHERE
						sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(@Country, ',')) 
	)
	,cte_config AS (
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
	-- Volume by countries
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
					p.PK_Distributor,
					p.MetricType,
					p.RoyaltyMonth AS iRoyaltyMonth,
					CONVERT(datetime, CONVERT(VARCHAR(10), ((p.RoyaltyMonth * 100) + 1))) AS [dRoyaltyMonth], 
					p.Points,
					ROW_NUMBER() OVER(PARTITION BY p.PK_Distributor,p.MetricType ORDER BY p.Points DESC) AS RowMonth 
				FROM
					(	SELECT PK_Distributor,MetricType,RoyaltyMonth,SUM(Points) AS [Points]
						FROM cte_points_country AS a
						WHERE EXISTS (SELECT 1 FROM cte_countries AS c WHERE a.PK_Country = c.nCountryID) OR @Country IS NULL
						GROUP BY PK_Distributor,MetricType,RoyaltyMonth
					) AS p
				WHERE
					p.RoyaltyMonth BETWEEN x.iStartDate AND x.iEndDate
					AND
					p.MetricType = x.MetricType
					AND
					p.Points >= x.MinPoints
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
GO
