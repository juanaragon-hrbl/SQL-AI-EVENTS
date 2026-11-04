CREATE FUNCTION [dbo].[ufn_GetASP](@BeginMonth DATE , @EndMonth DATE, @TotalPoints INT, @ConsecutiveMonths INT, @MetricType VARCHAR(3), @Country INT)
RETURNS @ASP TABLE 
(
	PK_Distributor INT PRIMARY KEY
)

AS
BEGIN

;WITH MB AS 
(
	SELECT 
		A.nDistributorID,
		dRoyaltyMonth,
		CASE WHEN @MetricType = 'PPV' THEN mPersonalPurchaseVolume
		     WHEN @MetricType = 'TV' THEN mVolumePoints
			 WHEN @MetricType = 'RO' THEN mRoyaltyOverrides+mMainRoyaltyOverrides
			 END AS [Points],
		ROW_NUMBER() OVER(PARTITION BY A.nDistributorID ORDER BY dRoyaltyMonth) AS ROWMonth 
	FROM
		dbo.v_Distributor D
	INNER JOIN
		dbo.v_aggFQS_ID A
	ON
		D.nDistributorID = A.nDistributorID
	WHERE
		CASE WHEN @MetricType = 'PPV' THEN mPersonalPurchaseVolume
		     WHEN @MetricType = 'TV' THEN mVolumePoints
			 WHEN @MetricType = 'RO' THEN mRoyaltyOverrides+mMainRoyaltyOverrides
			 END >= @TotalPoints
		AND
		dRoyaltyMonth BETWEEN @BeginMonth AND @EndMonth
		AND
		D.nDistributorCountryProcessingID = ISNULL(@Country,D.nDistributorCountryProcessingID)
),
MBConsecutive AS
(
	SELECT DISTINCT
		nDistributorID
	FROM 
		MB
	GROUP BY 
		nDistributorID,DATEADD(mm,-ROWMonth,dRoyaltyMonth)
	HAVING
		COUNT([Points]) >= @ConsecutiveMonths
)


INSERT INTO @ASP 
	SELECT
		nDistributorID
	FROM
		MBConsecutive 
		
	RETURN 
END