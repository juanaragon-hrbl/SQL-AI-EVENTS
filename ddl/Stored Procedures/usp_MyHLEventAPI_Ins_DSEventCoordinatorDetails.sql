
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Ins_DSEventCoordinatorDetails]
         --Mandatory Parameters
		 @PK_Event INT
		,@CreatedDistributorID VARCHAR(10)
		,@CoordinatorName nVARCHAR(250)
		,@CoordinatorTitle nVARCHAR(250)
		,@CoordinatorPhone nVARCHAR(250)
		--Optional Parameters
		,@CoordinatorEmail nVARCHAR(400) = NULL
		--Error Parameters
		,@Error INT OUTPUT
		,@ErrorMessage VARCHAR(200) OUTPUT
		-- QA/DEV
		,@IsDevQA bit = 0
	

AS
BEGIN	

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Ins_DSEventCoordinatorDetails
USE:
			declare @e int
			declare @em varchar(200)
			declare @IsDevQA int
			EXEC usp_MyHLEventAPI_Ins_DSEventCoordinatorDetails
					 @Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@PK_Event = 646
					,@CreatedDistributorID = '1111111111'
					,@CoordinatorName = 'Mark Hughes'
					,@CoordinatorTitle = 'Mr'
					,@CoordinatorPhone = '310-410-9600'
					,@CoordinatorEmail = 'MarkH@herbalife.com'
					,@IsDevQA = 0

DESCRIPTION:	Inserts record into dbo.EventCoordinator

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.EventCoordinator

VERSIONS
--------------------------------------------------------------------
1	2008-12-01	PrabhuS	Initial
2	2013-01-16	Sushma	Changes made for Title column of CoOrdinatorDetails

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
SET @StoredProcedure = 'usp_MyHLEventAPI_Ins_DSEventCoordinatorDetails'
SET @StartTime = GETUTCDATE()
SET @CreatedDistributorID = LTRIM(RTRIM(@CreatedDistributorID))
SET @CoordinatorName = LTRIM(RTRIM(@CoordinatorName))
SET @CoordinatorTitle = LTRIM(RTRIM(@CoordinatorTitle))
SET @CoordinatorPhone = LTRIM(RTRIM(@CoordinatorPhone))
SET @CoordinatorEmail = LTRIM(RTRIM(@CoordinatorEmail))

/*Validate special characters for Title */
--IF EXISTS (SELECT 1 WHERE REPLACE(REPLACE(REPLACE(REPLACE(@CoordinatorTitle, ',', ''), '.', ''), '-', ''), ' ', '') LIKE '%[^A-Za-z0-9]%') 
--BEGIN

--	SET @Error = 407
--	-- Update ErrorLog
--	EXEC dbo.usp_Utility_UpdateErrorLog 
--		@ProcedureName = @StoredProcedure 
--		,@ErrorNumber = @Error
--		,@ErrorMessage = @ErrorMessage OUTPUT
--	RETURN 
	
--END

/*Validate if the distributor exists*/
IF NOT EXISTS(SELECT TOP 1 nDistributorID FROM dbo.v_Distributor(NOLOCK)
			WHERE sDistributorID = @CreatedDistributorID)
BEGIN
	SET @Error = 8
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END


/*Validate if the event exists*/
IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.Event(NOLOCK)
			WHERE PK_Event = @PK_Event)
BEGIN
	SET @Error = 5
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END


/* INSERT THE RECORD INTO EVENTCOORDINATORDETAIL TABLE */

BEGIN TRY
INSERT 
	dbo.EventCoordinatorDetail
(
	 PK_Event
	,CreatedDistributorID
	,Coordinatorname
	,CoordinatorPhone
	,CoordinatorEmail
	,CoordinatorTitle
)
SELECT
	 @PK_Event
	,@CreatedDistributorID
	,@CoordinatorName
	,@CoordinatorPhone
	,@CoordinatorEmail
	,@CoordinatorTitle
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