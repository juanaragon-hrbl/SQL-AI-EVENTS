
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_EventSKU]
	-- REQUIRED
	@PK_Event int
	-- OPTIONAL
	,@Error int OUTPUT
	,@ErrorMessage varchar(200) OUTPUT	
	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************

OBJECT:			dbo.usp_EventAPI_Get_EventSKU

USE:			
		declare @PK_Event int
	    ,@e int
		,@em varchar(200)
EXEC usp_EventAPI_Get_EventSKU 
					@PK_Event = 23
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 0

DESCRIPTION:	Retrieves record from dbo.EventSKU

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.EventSKU

VERSIONS
--------------------------------------------------------------------
1	2008-10-16	Aarti	Initial
2   2011-03-25  IniU	Added code to include IsEventTicketSKU column
3	2019-10-14	JonathanO	Refactor code (SRE)

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime

SET @StoredProcedure = 'usp_EventAPI_Get_EventSKU'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_EventSKU FROM dbo.EventSKU WITH (NOLOCK) WHERE PK_Event = @PK_Event AND IsEventTicketSKU = 1)
BEGIN
	SET @Error = 186
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
		[PK_EventSKU]
		,[CreatedDateUTC]
		,[CreatedBy] 
		,[ModifiedDateUTC]
		,[ModifiedBy] 
		,[PK_Event] 
		,[SKUCode] 
		,[SKUDesc] 
		,[Price] 
		,[VolumePoints]
		,[QuantityInStock]
		,[QuantitySold]
		,[WareHouseID]
		,[SKUValidBeginUTC]
		,[SKUValidEndUTC] 
		,[PK_EventSKUType]
		,[NumberOfTicketsPerSKU]
		,[IsEventTicketSKU]
	FROM 
		dbo.EventSKU WITH (NOLOCK)
	WHERE 
		PK_Event = @PK_Event
	AND
		IsEventTicketSKU = 1
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


/******************************************************************************
	end procedure
******************************************************************************/
END