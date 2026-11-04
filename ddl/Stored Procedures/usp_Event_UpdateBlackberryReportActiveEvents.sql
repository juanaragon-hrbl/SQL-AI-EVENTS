CREATE PROCEDURE dbo.usp_Event_UpdateBlackberryReportActiveEvents
	-- Error Parameters
	@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_Event_UpdateBlackberryReportActiveEvents

USE:			DECLARE @e int, @em varchar(max)
			
				EXEC usp_Event_UpdateBlackberryReportActiveEvents
				
					 @Error = @e OUTPUT
					,@ErrorMessage = @em OUTPUT
					,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]


DESCRIPTION:	Updates blackberry reports for all active events

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.Event

VERSIONS
--------------------------------------------------------------------
1.2		2019-10-08	alejandramed		SRE Compliance 
1.1		2010-08-10  Sandhya Pendyala    Removed the Exec Procs for Fact & Metrics, Follows EventSchedule for active events
1		2008-06-04  Scott	            Initial
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET ANSI_WARNINGS ON

/******************************************************************************
	variable declaration
******************************************************************************/

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

DECLARE 
	@PK_Schedule int
	,@e int
	,@em varchar(200)
	,@EventCount int
	,@Count int
	,@PK_Event int

BEGIN TRY

	/******************************************************************************
		get active events from EventSchedule for Blackberry
	******************************************************************************/
	SELECT @PK_Schedule = PK_Schedule FROM dbo.Schedule WITH (NOLOCK) WHERE ScheduleName = 'Blackberry Report'

	IF OBJECT_ID('wrk_UpdateBBReport_ActiveEvents','U') IS NOT NULL DROP TABLE dbo.wrk_UpdateBBReport_ActiveEvents

	CREATE TABLE dbo.wrk_UpdateBBReport_ActiveEvents (
		PK int IDENTITY(1,1) PRIMARY KEY
		,PK_Event int
	)

	INSERT
		dbo.wrk_UpdateBBReport_ActiveEvents
	(
		PK_Event
	)
	SELECT
		PK_Event
	FROM
		dbo.EventSchedule WITH(NOLOCK)
	WHERE
		PK_Schedule = @PK_Schedule
		AND
		@StartTime BETWEEN BeginUTC AND EndUTC

	SET @EventCount = @@ROWCOUNT

	/******************************************************************************
		update blackberry report for active events
	******************************************************************************/
	SET @Count = 1

	WHILE @Count <= @EventCount
	BEGIN
		SELECT 
			@PK_Event = PK_Event 
		FROM 
			dbo.wrk_UpdateBBReport_ActiveEvents WITH(NOLOCK)
		WHERE
			PK = @Count

		EXEC dbo.usp_Event_OnsiteReport_bberry
						@PK_Event = @PK_Event
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 0 

		SET @Count = @Count + 1
	END

	/******************************************************************************
		clean up
	******************************************************************************/
	IF @isDevQA = 0
	BEGIN
		IF OBJECT_ID('wrk_UpdateBBReport_ActiveEvents','U') IS NOT NULL DROP TABLE dbo.wrk_UpdateBBReport_ActiveEvents
	END

	/******************************************************************************
		update processing log
	******************************************************************************/
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime

	/******************************************************************************
		end procedure
	******************************************************************************/

END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 
	END CATCH;
END;