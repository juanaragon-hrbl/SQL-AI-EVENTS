
CREATE PROCEDURE dbo.usp_MyHLEventAPI_Del_DSEventCoordinatorDetails
        --Mandatory Parameters
		 @PK_EventCoordinatorDetail INT
		,@PK_Event INT
		-- Error Parameters
		,@Error INT OUTPUT
		,@ErrorMessage VARCHAR(200) OUTPUT
		-- QA/DEV
		,@IsDevQA bit = 0
	

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Del_DSEventCoordinatorDetails
USE:
			declare @e int
			declare @em varchar(200)
			declare @IsDevQA int
			EXEC usp_MyHLEventAPI_Del_DSEventCoordinatorDetails
					 @Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@PK_EventCoordinatorDetail = 7
					,@PK_Event = 646

DESCRIPTION:	DELETES A record in dbo.EventCoordinatorDetail

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.EventCoordinator

VERSIONS
--------------------------------------------------------------------
1	2008-12-07	PrabhuS	Initial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON	

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StoredProcedure VARCHAR(100)
DECLARE @StartTime DATETIME

SET @Error = 0
SET @ErrorMessage = 'No Error.'
SET @StoredProcedure = 'usp_MyHLEventAPI_Del_DSEventCoordinatorDetails'
SET @StartTime = GETUTCDATE()

/* DELETE THE RECORD INTO EVENTCOORDINATORDETAIL TABLE */
BEGIN TRY

DELETE
FROM
	dbo.EventCoordinatorDetail

WHERE
	PK_Event = @PK_Event
AND
	PK_EventCoordinatorDetail = @PK_EventCoordinatorDetail
	
END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	-- UPDATE ERROR LOG
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END