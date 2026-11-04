CREATE FUNCTION [dbo].[udf_EventPromo_GetTrackerReportMonth]
(
	@EventID INT
)
RETURNS DATETIME 
AS
BEGIN
	DECLARE @ReportMonth AS DATETIME = NULL

	/* get report run month from Event Schedule */
	SELECT @ReportMonth = DATEADD(MONTH,DATEDIFF(MONTH,0,DATEADD(MONTH,0,EndUTC)),0)
	FROM dbo.EventSchedule (NOLOCK)
	WHERE PK_Event = @EventID
		AND PK_Schedule = 9

	/* if report month definition not exists, determine by current date*/
	IF @ReportMonth IS NULL
	BEGIN
		DECLARE @CurrentMonth DATETIME
		SET @CurrentMonth = GETDATE()
		SELECT @ReportMonth = CASE WHEN DAY(@CurrentMonth) < 2 THEN DATEADD(MONTH,DATEDIFF(MONTH,0,DATEADD(MONTH,-1,@CurrentMonth)),0) ELSE DATEADD(MONTH,DATEDIFF(MONTH,0,(@CurrentMonth)),0) END	
	END
	

	RETURN @ReportMonth
END