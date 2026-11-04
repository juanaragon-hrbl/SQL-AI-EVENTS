CREATE FUNCTION dbo.ufn_GetConsecutive (@Distributor INT,@BeginMonth DATE, @EndMonth DATE, @TotalPoints INT, @ConsecutiveMonths INT, @MetricType VARCHAR(3))
RETURNS TABLE
AS RETURN
(
			
	SELECT 
		nDistributorID AS ID,
		DATEADD(mm,-ROWMonth+1,dRoyaltyMonth)  AS BeginMonth
	FROM 

	(
		SELECT 
			A.nDistributorID,
			dRoyaltyMonth,
			CASE WHEN @MetricType = 'PPV' THEN mPersonalPurchaseVolume
					WHEN @MetricType = 'TV' THEN mVolumePoints
					WHEN @MetricType = 'RO' THEN mRoyaltyOverrides+mRoyaltyOverrides
					END AS [Points],
			ROW_NUMBER() OVER(PARTITION BY A.nDistributorID ORDER BY dRoyaltyMonth) AS ROWMonth 
		FROM
			dbo.v_aggFQS_ID A
		WHERE
			A.nDistributorID = @Distributor
			AND
			CASE WHEN @MetricType = 'PPV' THEN mPersonalPurchaseVolume
				WHEN @MetricType = 'TV' THEN mVolumePoints
				WHEN @MetricType = 'RO' THEN mRoyaltyOverrides+mRoyaltyOverrides
				END >= @TotalPoints
			AND
			dRoyaltyMonth BETWEEN @BeginMonth AND @EndMonth

	) MB
	GROUP BY 
		nDistributorID,DATEADD(mm,-ROWMonth + 1,dRoyaltyMonth)
	HAVING
		COUNT(1) >= @ConsecutiveMonths


)