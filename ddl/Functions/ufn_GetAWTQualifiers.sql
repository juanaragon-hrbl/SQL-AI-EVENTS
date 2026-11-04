CREATE FUNCTION dbo.ufn_GetAWTQualifiers(@PK_Distributor BIGINT = 0, @StartDate DATE,@EndDate DATE)
RETURNS TABLE
AS
RETURN(
SELECT PK_Distributor, DistributorID
FROM   
	(
		SELECT PK_Distributor, DistributorID, AWTYear, Jan AS [01],Feb AS [02],Mar AS [03],Apr AS [04],May AS [05],Jun AS [06],Jul AS [07],Aug AS [08],Sep AS [09],Oct AS [10],Nov AS [11],Dec AS [12]
		FROM
			dbo.AWT_Qualifiers_Tracking WITH (NOLOCK)
		WHERE 
				(Jan & Feb & Mar & Apr & May & Jun & Jul & Aug & Sep & Oct & Nov & Dec) = 1
			AND
				AWTYear BETWEEN YEAR(@StartDate) AND YEAR(@EndDate)
			AND
				(PK_Distributor = @PK_Distributor OR @PK_Distributor = 0)
	) p  
		UNPIVOT  
			(
				AWTFlag FOR MonthNumber IN ([01],[02],[03],[04],[05],[06],[07],[08],[09],[10],[11],[12])  
			)AS unpvt  
WHERE
	CONVERT(DATETIME,CAST(AWTYear AS VARCHAR(4)) + MonthNumber + '01',112) BETWEEN @StartDate AND @EndDate
GROUP BY PK_Distributor, DistributorID
);