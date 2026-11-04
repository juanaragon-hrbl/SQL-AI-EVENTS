CREATE PROCEDURE [dbo].[usp_EventAPI_Get_Distributor_TicketsInfo]
	-- REQUIRED
	@DistributorID varchar(10)
	,@EventID int

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
  
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_Distributor

USE:			DECLARE @e int, @em varchar(max)

                EXEC usp_EventAPI_Get_Distributor_TicketsInfo @DistributorID = '09505905'
                                                       ,@EventID=23560
                                                       ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                               ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						                               ,@IsDevQA = 0
			SELECT @e AS [Error], @em AS [Error Message]


DESCRIPTION:	Get Distributor

NOTES:			

VERSIONS
--------------------------------------------------------------------
1		2026-03-27	ivanci			Initial
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @e int
DECLARE @em varchar(200)


/******************************************************************************
 Check if Distributor exist
******************************************************************************/

IF EXISTS  (SELECT nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		    UNION
			SELECT PK_Temp FROM dbo.TempDistributors WITH (NOLOCK) WHERE DistributorID = @DistributorID)
   
BEGIN

/******************************************************************************
 Get all the Distributor Info for Registration
******************************************************************************/

BEGIN TRY

EXEC usp_EventAPI_Get_DistributorDetails @DistributorID
                                        ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						                
EXEC usp_EventAPI_Get_DistributorTickets  @DistributorID 
                                         ,@EventID
                                         ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                 ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
EXEC usp_EventAPI_Get_EventAvailableTickets
				@DistributorID 
				,@EventID 
				,@Error = @e OUTPUT  /* @e must be defined in the local call */
				,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
				,@IsDevQA = 0

END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH

END

ELSE

BEGIN
	SET @Error = 8
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN
END

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime  

/******************************************************************************
	End procedure
******************************************************************************/
END
GO
