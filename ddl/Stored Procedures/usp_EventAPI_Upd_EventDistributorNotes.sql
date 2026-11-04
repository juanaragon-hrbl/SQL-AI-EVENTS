
CREATE PROCEDURE [dbo].[usp_EventAPI_Upd_EventDistributorNotes]
	@PK_EventDistributorNote int 
	,@PK_Distributor int  = NULL
	,@PK_Event int  = NULL
	,@PK_EventNoteType int  = NULL
	,@Error int OUTPUT
	,@ErrorMessage varchar(200) OUTPUT
	,@Notes varchar(1000)  = NULL
	,@ModifiedBy varchar(50) = NULL
	,@ModifiedDateUTC smalldatetime = NULL

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************

	OBJECT:			dbo.usp_EventAPI_Upd_EventDistributorNotes
	USE:			EXEC usp_EventAPI_Upd_EventDistributorNotes
					@PK_EventDistributorNote = 1
					,@PK_Distributor = 1
					,@PK_Event = 1
					,@PK_EventNoteType = 1
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@ModifiedBy = NULL
					,@ModifiedDateUTC = NULL
					-- OPTIONAL					
					,@Notes = ''
					,@IsDevQA = 0

	DESCRIPTION:	Updates record in dbo.EventDistributorNotes

	NOTES:			

	DEPENDENCIES
	--------------------------------------------------------------------
	SQL SERVER 2005
	dbo.EventDistributorNotes

	VERSIONS
	--------------------------------------------------------------------
	1	2008-10-14	Aarti	Initial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime
SET @StoredProcedure = 'usp_EventAPI_Upd_EventDistributorNotes'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_EventDistributorNote FROM dbo.EventDistributorNotes(NOLOCK) WHERE PK_EventDistributorNote = @PK_EventDistributorNote)
BEGIN
	SET @Error = 74
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

/******************************************************************************
	set variables to update
******************************************************************************/
SELECT
	@PK_Distributor = COALESCE(@PK_Distributor, PK_Distributor)
	,@Notes = COALESCE(@Notes, Notes)
	,@PK_Event = COALESCE(@PK_Event, PK_Event)
	,@PK_EventNoteType = COALESCE(@PK_EventNoteType, PK_EventNoteType)
FROM 
	dbo.EventDistributorNotes WITH (NOLOCK)
WHERE 
	PK_EventDistributorNote = @PK_EventDistributorNote

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_Event FROM dbo.Event(NOLOCK) WHERE PK_Event = @PK_Event)
BEGIN
	SET @Error = 5
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_EventNoteType FROM dbo.EventNoteTypes(NOLOCK) WHERE PK_EventNoteType = @PK_EventNoteType)
BEGIN
	SET @Error = 7
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

/******************************************************************************
be sure distributor exists
******************************************************************************/
IF NOT EXISTS(SELECT nDistributorID FROM dbo.v_Distributor (NOLOCK) WHERE nDistributorID = @PK_Distributor)
BEGIN
	SET @Error = 8
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END


/******************************************************************************
insert record
******************************************************************************/
BEGIN TRY
UPDATE EDN
SET
	[PK_Distributor] = @PK_Distributor
	,[Notes] = @Notes
	,[PK_Event] = @PK_Event
	,[PK_EventNoteType] = @PK_EventNoteType
	,[ModifiedBy] = ISNULL(@ModifiedBy,replace(suser_sname(),'HERBALIFECORP\',''))
	,[ModifiedDateUTC] = ISNULL(@ModifiedDateUTC,GetUTCdate())
FROM
	dbo.EventDistributorNotes EDN
WHERE
	EDN.PK_EventDistributorNote = @PK_EventDistributorNote
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