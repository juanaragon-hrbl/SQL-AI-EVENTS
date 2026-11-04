
CREATE FUNCTION [dbo].[ufn_GetConsecutiveBasedSPDate](@BeginMonth DATE , @EndMonth DATE, @TotalPoints INT, @ConsecutiveMonths INT, @MetricType VARCHAR(3), @Country INT)
RETURNS @ASP TABLE 
(
	PK_Distributor INT PRIMARY KEY,
	[Month] DATETIME
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
			 WHEN @MetricType = 'RO' THEN mRoyaltyOverrides+mRoyaltyOverrides
			 END AS [Points],
		dSupervisorQualification, 
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
			 WHEN @MetricType = 'RO' THEN mRoyaltyOverrides+mRoyaltyOverrides
			 END >= @TotalPoints
		AND
		dRoyaltyMonth BETWEEN @BeginMonth AND @EndMonth
		AND
		D.nDistributorCountryProcessingID = ISNULL(@Country,D.nDistributorCountryProcessingID)
), Final AS 
(
	SELECT DISTINCT
		nDistributorID,
		(SELECT MIN(dRoyaltyMonth)
           FROM MB b 
           WHERE b.nDistributorID = a.nDistributorID 
        ) AS [Month],
		dSupervisorQualification
	FROM 
		MB a
	GROUP BY 
		nDistributorID,DATEADD(mm,-ROWMonth,dRoyaltyMonth),dSupervisorQualification
	HAVING
		COUNT([Points]) >= @ConsecutiveMonths
	
)


INSERT INTO @ASP
SELECT 
	nDistributorID,
	MIN([Month]) AS [Month]
FROM
	Final
WHERE
	dSupervisorQualification > [Month]
	OR
	dSupervisorQualification IS NULL
GROUP BY
	nDistributorID

RETURN



END