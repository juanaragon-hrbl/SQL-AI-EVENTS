

CREATE VIEW [dbo].[v_EventOnSiteReportToUpdate]
AS
SELECT DISTINCT
	PK_Event
FROM
	dbo.EventSchedule 
WHERE
	PK_Schedule = 12
	AND
	GETUTCDATE() BETWEEN BeginUTC AND EndUTC