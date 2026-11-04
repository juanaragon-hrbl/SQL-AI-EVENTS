
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_DSEventQualifier]
	--Required
	@PK_Event INT,
	@DistributorID VARCHAR(10)
	-- Optional
	,@Error INT OUTPUT
	,@ErrorMessage VARCHAR(200) OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_DSEventQualifier

DESCRIPTION:	Checks if DS qualifies for an event and returns a record if yes.
				If not, returns nothing. Ensures that the PK_Event and DistributorID
				passed are valid, else logs appropriate message in error table so
				application can display the error message if necessary.
				
USAGE:
				DECLARE @Err INT, @ErrM VARCHAR(200)
				EXEC dbo.usp_MyHLEventAPI_Get_DSEventQualifier @PK_Event = 3112, @DistributorID = '10Y1050640', @Error = @Err, @ErrorMessage = @ErrM

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.Event

VERSIONS
--------------------------------------------------------------------
1	2011-11-01	IniU		Initial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime

SET @StoredProcedure = 'usp_MyHLEventAPI_Get_DSEventQualifier'
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
be sure DistributorID exist
******************************************************************************/
IF NOT EXISTS(SELECT 1 FROM dbo.v_DistributorUnionTemp WHERE sDistributorID = @DistributorID)
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
select record
******************************************************************************/
BEGIN TRY
	SELECT 
		PK_Event
		,PK_Distributor
		,DistributorID
		,ModifiedDateUTC
		,ModifiedBy 
	FROM 
		dbo.EventQualifier (NOLOCK) 
	WHERE 
		PK_Event = @PK_Event
		AND
		DistributorID = @DistributorID
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