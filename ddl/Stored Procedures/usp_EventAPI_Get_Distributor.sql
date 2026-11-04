CREATE PROCEDURE [dbo].[usp_EventAPI_Get_Distributor]
	-- REQUIRED
	@DistributorID varchar(10)
	,@EventID int

	-- OPTIONAL
	,@NoteType int = NULL

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

                EXEC usp_EventAPI_Get_Distributor @DistributorID = '09505905'
                                                       ,@EventID=22
                                                       ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                               ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						                               ,@IsDevQA = 0
			SELECT @e AS [Error], @em AS [Error Message]


DESCRIPTION:	Get Distributor

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1		2009-01-23	Sandhya			Initial
1.1		2019-05-21	alejandramed	Homologating of standard error handling	
1.2		2019-07-15	alejandramed	Setting error parameters as optionals
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
DECLARE @PK_Distributor int
DECLARE @PK_SubEvent int
DECLARE @PK_EventsRegistration int
DECLARE @PK_SubEventQualifier int
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
EXEC usp_EventAPI_Get_DistributorGuests @DistributorID
                                         ,@EventID
                                         ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                 ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
EXEC usp_EventAPI_Get_DistributorRegistration @DistributorID
                                         ,@EventID
                                         ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                 ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
EXEC usp_EventAPI_Get_DistributorSubEvents @DistributorID
                                          ,@EventID
                                          ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                  ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
EXEC usp_EventAPI_Get_DistrubutorNotes @DistributorID
                                      ,NULL --@EventID
                                      ,@NoteType
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

