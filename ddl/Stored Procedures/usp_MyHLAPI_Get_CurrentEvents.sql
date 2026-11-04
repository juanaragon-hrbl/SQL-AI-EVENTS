
CREATE PROCEDURE dbo.usp_MyHLAPI_Get_CurrentEvents
	@Error int OUTPUT
	,@ErrorMessage varchar(200) OUTPUT
	,@IsDevQA bit = 0


AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_MyHLAPI_Get_CurrentEvents

USE:			DECLARE @e int, @em varchar(200)

				EXEC usp_MyHLAPI_Get_CurrentEvents
					@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */


DESCRIPTION:	Get current events to display on myherbalife

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.Event

VERSIONS
--------------------------------------------------------------------
1	2009-07-28	ScottB	Initial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime

SET @StoredProcedure = 'usp_MyHLAPI_Get_CurrentEvents'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'

/******************************************************************************
	get events
******************************************************************************/
BEGIN TRY

		SELECT 
			E.PK_Event
			,E.EventName
		FROM
			dbo.Event E (NOLOCK)
		INNER JOIN
			dbo.EventSchedule ES (NOLOCK)
			ON	
				E.PK_Event = ES.PK_Event
				AND ES.PK_Schedule = 1  --MyHerbalife
				AND @StartTime BETWEEN ES.BeginUTC AND ES.EndUTC
		WHERE
			E.dEndUTC > @StartTime
            AND
            E.CanShowCurrentQualOnline = 1
		ORDER BY
			E.EventName

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