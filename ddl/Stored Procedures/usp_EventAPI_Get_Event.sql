
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_Event]
	--Required
	@PK_Event int
	-- Optional
	,@Error int OUTPUT
	,@ErrorMessage varchar(200) OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_Event

USE:			EXEC usp_EventAPI_Get_Event
					@PK_Event = 1
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@ModifiedBy = ''


DESCRIPTION:	Retrives record from dbo.Event

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.Event

VERSIONS
--------------------------------------------------------------------
1	2008-10-16	Aarti	Initial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime

SET @StoredProcedure = 'usp_EventAPI_Get_Event'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_Event FROM dbo.Event(NOLOCK) WHERE PK_Event = @PK_Event)
BEGIN
	SET @Error = 169
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

/******************************************************************************
select record
******************************************************************************/
BEGIN TRY
	SELECT 
		[PK_Event] 
		,[CreatedDateUTC] 
		,[CreatedBy] 
		,[ModifiedDateUTC] 
		,[IsTicketPurchaseRequired] 
		,[IsPreRegistrationRequired]
		,[CanAssignTickets] 
		,[IsRFIDRequired]
		,[IsHotelEnabled]
		,[MaxNoOfGuest]
		,[MaxNoOfPrimaryGuest] 
		,[MaxCapacity] 
		,[ExpectedCapacity]
		,[EventTimeZone]
		,[EventNamePositionID] 
		,[ModifiedBy] 
		,[PK_EventType]
		,[PK_OldEventApp]
		,[EventName] 
		,[dStartUTC] 
		,[dEndUTC]
		,[StoredProcedure] 
                ,[Location]
                ,[LocalName]
		,[VendorEventID]
	    	,[IsInventoryEnabled]
	FROM 
		[dbo].[Event] WITH (NOLOCK)
	WHERE 
		PK_Event = @PK_Event
END TRY

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

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

/******************************************************************************
	end procedure
******************************************************************************/
END