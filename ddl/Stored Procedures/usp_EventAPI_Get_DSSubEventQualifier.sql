
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_DSSubEventQualifier]
	@PK_Event int,
	@DistributorID varchar(10),



		@IsDevQA		BIT = 0,   
	    @Error	int = 0 OUTPUT,
	    @ErrorMessage varchar(4000) = NULL OUTPUT

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Get_DSSubEventQualifier

USE:		EXEC usp_EventAPI_Get_DSSubEventQualifier
					@PK_Event = 1
					,@DistributorID = ''
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 0

DESCRIPTION:	Select Distributors qualified in dbo.SubEventQualifier table

NOTES:		
VERSION HISTORY:
--   DATE			DEVELOPER       COMMENTS
--   ========		=========		========
--   23-Nov-2011	OrlandoL		First version
--   25-Nov-2011	OrlandoL		It were added two columns dStartUTC and dEndUTC	

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEventQualifier

VERSIONS
--------------------------------------------------------------------
1	2011-11-22	OrlandoL	Initial
2	2019-10-14	JonathanO	Refactor code (SRE)

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime
DECLARE @nDistributorID INT

SET @StoredProcedure = 'usp_EventAPI_Get_DSSubEventQualifier'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event)
BEGIN
	SET @Error = 5
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN
END
/******************************************************************************
be sure distributor exists
******************************************************************************/
SELECT @nDistributorID = nDistributorID FROM dbo.v_Distributor WITH (NOLOCK) WHERE sDistributorID = @DistributorID
IF @@ROWCOUNT = 0
BEGIN
	SET @Error = 8
	-- Update ErrorLosg
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END
/******************************************************************************
SELECT Distributors Qualified 
******************************************************************************/
BEGIN TRY
SELECT
		[PK_SubEventQualifier] 
		,[S].[CreatedDateUTC] 
		,[S].[CreatedBy] 
		,[S].[ModifiedDateUTC] 
		,[S].[ModifiedBy] 
		,[S].[PK_Event] 
		,[S].[PK_SubEvent] 
		,[PK_Distributor] 
		,[QualDate] 
		,[RemovedUTC]
		,[IsManualOverride] 
		,[IsDeleted] 
		,[IsDNR] 
		,[IsType23]
		,[Qualified]
		,'E' + CONVERT(CHAR,[SE].[SubEventNumber]) AS [SubEvent]
		,[E].[dStartUTC] AS [StartDate]
		,[E].[dEndUTC] AS [EndDate]
FROM 
		dbo.SubEventQualifier S WITH (NOLOCK)
INNER JOIN
		dbo.Event E WITH (NOLOCK)
ON
		E.PK_Event = S.PK_Event
INNER JOIN 
		dbo.SubEvent SE WITH (NOLOCK)
ON 
		S.PK_Event = SE.PK_Event
AND
		S.PK_SubEvent = SE.PK_SubEvent
WHERE 
		S.PK_Event = @PK_Event  
AND 
		PK_Distributor = @nDistributorID 
AND 
		RemovedUTC = '2049-12-31'
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