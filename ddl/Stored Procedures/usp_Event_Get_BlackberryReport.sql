CREATE PROCEDURE [dbo].[usp_Event_Get_BlackberryReport]
	@PK_Event INT

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_Event_Get_BlackberryReport

USE:
			DECLARE @e int, @em varchar(4000)

			EXEC usp_Event_Get_BlackberryReport
							@PK_Event = 59881
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Inserts record into dbo.PromotionAcceleratorMonths

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.BlackBerryReport

VERSIONS
--------------------------------------------------------------------
1	2009-04-06	Sandhya 		Initial
2	2019-08-14	NoeG			Refactor code (SRE)
3	2019-10-08	alejandramed	SRE Compliance 
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

/******************************************************************************
 Check if the Event Exists
******************************************************************************/
IF NOT EXISTS (SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event)
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
 Check if the Event has the Report Available
******************************************************************************/
IF NOT EXISTS (SELECT PK_Event FROM dbo.v_BlackBerryReport WITH (NOLOCK) WHERE PK_Event = @PK_Event)
  BEGIN
	SET @Error = 255
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
  END

/******************************************************************************
 Get the report
******************************************************************************/
BEGIN TRY

SET NOCOUNT ON

DECLARE @RunSequenceMax INT
      , @Report NVARCHAR(256)
      , @Reports NVARCHAR(MAX)
      , @PK INT


SELECT @RunSequenceMax = MAX(RunSequence) 
FROM dbo.v_BlackBerryReport WITH (NOLOCK)
WHERE PK_Event = @PK_Event

 
CREATE TABLE #BlackBerryReport (PK INT, Report nVarchar(512))

INSERT INTO #BlackBerryReport
SELECT PK_BlackberryReport As PK , Report
FROM dbo.v_BlackBerryReport WITH (NOLOCK)
WHERE PK_Event = @PK_Event 
AND RunSequence = @RunSequenceMax

 
SET @Reports ='' 

WHILE EXISTS (SELECT TOP 1 'exists' FROM #BlackBerryReport)
BEGIN

        SELECT TOP 1 @Report = Report , @PK = PK
        FROM #BlackBerryReport
        ORDER BY PK ASC

            IF @Report is not null
            BEGIN
                  SET @Reports = @Reports + '<br>' + @Report
            END

        DELETE #BlackBerryReport
        WHERE PK= @PK

 END

SET @Reports = right(@Reports, len(@Reports) - 4)

SELECT @Reports AS Report


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
END CATCH

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

SET NOCOUNT OFF

END