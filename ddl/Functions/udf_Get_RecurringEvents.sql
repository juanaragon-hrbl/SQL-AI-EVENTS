
/******************************************************************************

OBJECT:			[dbo].[udf_Get_RecurringEvents]

USE:				select * from dbo.udf_Get_RecurringEvents(47001)

DESCRIPTION:	Retrieves a recurring event and it's children. In case PK_Event is a child of a
					recurring event, the function returns the parent and it's children.

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.EventDeleteQueue

VERSIONS (U)
----------------------------------------------------------------------------------
1	2016-11-14	RogelioR	   Intitial

******************************************************************************/

CREATE FUNCTION [dbo].[udf_Get_RecurringEvents](
		@PK_Event int
)
RETURNS TABLE
AS
	RETURN (
		WITH cte_events AS (
		--- Get main event
		SELECT	[PK_Event], [PK_EventType], [PK_OldEventApp], [EventName], [dStartUTC] AS [StartDate], [dEndUTC] AS [EndDate]
				,[EventApprovalStatus], [PK_RecurrenceType], [IsActive], 0 AS [IsChild], 1 AS [IsParent]
			FROM [dbo].[Event] WITH (NOLOCK)	-- Main event
			WHERE [PK_Event] = @PK_Event
				AND [PK_OldEventApp] IS NULL
		UNION ALL	-- It's a child event, get it's parent
		SELECT	[PK_Event], [PK_EventType], [PK_OldEventApp], [EventName], [dStartUTC] AS [StartDate], [dEndUTC] AS [EndDate]
				,[EventApprovalStatus], [PK_RecurrenceType], [IsActive], 0 AS [IsChild], 1 AS [IsParent]
			FROM [dbo].[Event] WITH (NOLOCK)
			WHERE [PK_Event] = (SELECT [PK_OldEventApp] FROM [dbo].[Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)
		-- Get children
		UNION ALL	-- Get children when @PK_Event is the main event
		SELECT	[PK_Event], [PK_EventType], [PK_OldEventApp], [EventName], [dStartUTC] AS [StartDate], [dEndUTC] AS [EndDate]
				,[EventApprovalStatus], [PK_RecurrenceType], [IsActive], 1 AS [IsChild], 0 AS [IsParent]
			FROM [dbo].[Event] WITH (NOLOCK)
			WHERE [PK_Event] IN (SELECT [PK_Event] FROM [dbo].[Event] WITH (NOLOCK) WHERE [PK_OldEventApp] = @PK_Event)
		UNION ALL	-- Get children whose parent (PK_OldEventApp) is @PK_Event
		SELECT	[PK_Event], [PK_EventType], [PK_OldEventApp], [EventName], [dStartUTC] AS [StartDate], [dEndUTC] AS [EndDate]
				,[EventApprovalStatus], [PK_RecurrenceType], [IsActive], 1 AS [IsChild], 0 AS [IsParent]
			FROM [dbo].[Event] WITH (NOLOCK)
			WHERE [PK_OldEventApp] = (SELECT [PK_OldEventApp] FROM [dbo].[Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)
		)
		/* ***************** SonarQube check 116 - Nullable subqueries should not be used in "NOT IN" conditions */
		SELECT	
				[PK_Event]
				,[PK_EventType]
				,[PK_OldEventApp]
				,[EventName]
				,[StartDate]
				,[EndDate]
				,[EventApprovalStatus]
				,[PK_RecurrenceType]
				,[IsActive]
				,[IsChild]
				,[IsParent]
			FROM cte_events
			WHERE [PK_Event] NOT IN (SELECT [PK_Event] FROM [dbo].[EventDeleteQueue] WITH (NOLOCK) WHERE PK_Event IS NOT NULL)
		/* ***************** SonarQube check 116 */
	)