CREATE VIEW [dbo].[v_Months]
AS
SELECT
	MonthDate AS dMonth 
FROM
	pubEvents.dbo.dimMonth  (NOLOCK)
