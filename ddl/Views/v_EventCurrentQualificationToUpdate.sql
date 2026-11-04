
CREATE VIEW [dbo].[v_EventCurrentQualificationToUpdate]
AS
SELECT DISTINCT
	PK_Event
FROM
	dbo.EventSchedule 
WHERE
	PK_Schedule in (5,6)
	AND
	GETUTCDATE() BETWEEN BeginUTC AND EndUTC
