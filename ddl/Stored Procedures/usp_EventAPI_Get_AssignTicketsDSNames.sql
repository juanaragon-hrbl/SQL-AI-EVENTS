CREATE PROCEDURE [dbo].[usp_EventAPI_Get_AssignTicketsDSNames]
	 @DistributorID varchar(10)
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_AssignTicketsDSNames

USE:
			DECLARE @e int, @em varchar(4000)
                 EXEC usp_EventAPI_Get_AssignTicketsDSNames
					 @DistributorID = '09219342'
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves the header Records for group ticket assignment for the purchaser

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
dbo.EventTicketAssignment

VERSIONS
--------------------------------------------------------------------
1	2010-07-13	Prabhu		Intitial
2	2018-11-22	SushmaA		China Members to be excluded
3   2019-09-05  OrlandoL	SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

DECLARE 
     @FirstName VARCHAR(250)
    ,@LastName VARCHAR(250)
    ,@PK_Distributor INT
    
SELECT @Error = 0, @ErrorMessage = '';

/******************************************************************************
  Check If Distributor Exists
******************************************************************************/

BEGIN TRY

	IF EXISTS ( SELECT nDistributorID FROM dbo.v_DistributorUnionTemp WHERE sDistributorID = @DistributorID )
	   BEGIN
	   SELECT @PK_Distributor = nDistributorID FROM dbo.v_DistributorUnionTemp WHERE sDistributorID = @DistributorID and DSClass IN ('Distributor','Temp')
	   AND sdistributorcountryprocessingcode <> 'CN'
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

	/******************************************************************************
	  IF THE DS ID EXISTS SELECT THE NAMES FROM THE VIEW
	******************************************************************************/
	IF @PK_Distributor IS NOT NULL

	BEGIN

	SELECT
		 sFirstName 
		,sLastName
		,sType
		,sDistributorCountryProcessingCode
	FROM
		dbo.v_DistributorUnionTemp
	WHERE
		nDistributorID = @PK_Distributor
	AND
		DSClass IN ('Distributor','Temp')
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
	END CATCH;

/******************************************************************************
	end procedure
******************************************************************************/
END