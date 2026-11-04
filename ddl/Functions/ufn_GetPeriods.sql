CREATE FUNCTION dbo.ufn_GetPeriods(
@StartDate SMALLDATETIME,
@EndDate SMALLDATETIME,
@Frequency SMALLINT,
@Consecutive BIT,
@Accumulated BIT
)

RETURNS TABLE
AS
RETURN(
SELECT 
	MyDate AS StartDate,
	ISNULL(DATEADD(MONTH, (@Frequency -1) + NULLIF(~@Consecutive,1), MyDate),@EndDate) AS EndDate,
	@Frequency AS Frequency,
	@Consecutive AS Consecutive,
	@Accumulated AS Accummulated
FROM dbo.SourceDate WITH (NOLOCK)
WHERE MyDate BETWEEN @StartDate AND ISNULL(DATEADD(MONTH, -(@Frequency -1) + NULLIF(~@Consecutive,1), @EndDate),@StartDate)
);