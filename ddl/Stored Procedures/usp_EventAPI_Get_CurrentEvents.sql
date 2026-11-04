
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_CurrentEvents]
/*	returns pk_event, eventname of all current events */

	-- Optional
	@TrackingSiteOnly bit = 1
/*		if set to 1 then will return only those current events that are scheduled to show
		on the trackig site (pk_schedule = 1; MyHerbalife)
*/
	,@Error int OUTPUT
	,@ErrorMessage varchar(200) OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0


AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_CurrentEvents

USE:			DECLARE @e int, @em varchar(200)

				EXEC usp_EventAPI_Get_CurrentEvents
					@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */


DESCRIPTION:	Retrives record from dbo.Event

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.Event

VERSIONS
--------------------------------------------------------------------
1	2009-06-19	ScottB	Initial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime

SET @StoredProcedure = 'usp_EventAPI_Get_CurrentEvents'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'


/******************************************************************************
	get events
******************************************************************************/
BEGIN TRY

--	IF @TrackingSiteOnly = 0 -- all current events
--	BEGIN
--		SELECT
--			E.PK_Event
--			,E.EventName
--		FROM
--			dbo.Event E (NOLOCK)
--		WHERE
--			E.dEndUTC > @StartTime
--                        AND
--                        E.CanShowCurrentQualOnline = 0
--		ORDER BY
--			E.EventName
--	END
--
--	ELSE BEGIN -- all current events with a MyHerbalife schedule
		SELECT 
			E.PK_Event
			,E.EventName
		FROM
			dbo.Event E (NOLOCK)
--		INNER JOIN
--			dbo.EventSchedule ES
--			ON	
--				E.PK_Event = ES.PK_Event
--				AND ES.PK_Schedule = 1
--				AND @StartTime BETWEEN ES.BeginUTC AND ES.EndUTC     /* COMMENTED BY SandhyaP */
		WHERE
			E.dEndUTC > @StartTime
            AND
            E.CanShowCurrentQualOnline = 1
		ORDER BY
			E.EventName
--	END

END TRY

/******************************************************************************
	error capture
******************************************************************************/
BEGIN CATCH

	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 

END CATCH

/******************************************************************************
	update processing log
******************************************************************************/
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

/******************************************************************************
	end procedure
******************************************************************************/
END