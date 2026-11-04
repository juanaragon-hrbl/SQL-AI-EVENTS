CREATE PROCEDURE [dbo].[usp_AWT_Update_DateAdded]
	@AWTYear INT,
	@DistributorID VARCHAR(25),
	@DateAdded SMALLDATETIME,
	--Error Parameters
	@Error	int = 0 OUTPUT,
	@ErrorMessage varchar(4000) = NULL OUTPUT,

	--QA/DEV
	@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
 
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		[dbo].[usp_AWT_Update_DateAdded]

	USE:		
			USE [PubEventManagement]
			GO

			DECLARE	@e int,
					@em varchar(4000)

			EXEC [dbo].[usp_AWT_Update_DateAdded]
					@AWTYear = 2021,
					@DistributorID = 'W1X699223',
					@DateAdded = '2021-09-11',
					@IsDevQA = 0,
					@Error = @e OUTPUT,
					@ErrorMessage = @em OUTPUT

			SELECT	@e AS N'@Error',
					@em AS N'@ErrorMessage'
			GO

	DESCRIPTION: 

	Method: RemoveQualifier
	Stored procedure name : [dbo].[usp_AWT_Update_DateAdded]
	Parameters: @AWTYear INT,
				@DistributorID VARCHAR(25),
				@DateAdded SMALLDATETIME --Optional
				 
	NOTES:	
	/api?/Awt?/UpdateDateAdded

	TABLES:
			
	DEPENDENCIES:
	
 
	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1	2023-03-03		alejandramed		Initial 
  
	***********************************************************************************************************************************/
	 
	SET NOCOUNT ON;

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
				
	SELECT @Error = 0, @ErrorMessage = '';	

BEGIN TRY		

DECLARE @PK_Distributor INT

	SELECT @PK_Distributor = nDistributorID FROM v_Distributor WHERE sDistributorID = @DistributorID
	SELECT @DateAdded = IIF(@DateAdded IS NULL, GETUTCDATE(), DATEADD(SECOND, DATEDIFF(SECOND, '00:00:00', CONVERT(TIME(0),GETDATE())), @DateAdded))  

IF @IsDevQA = 0
BEGIN
 
	UPDATE [PubEventManagement].[dbo].[AWT] 
	SET DateAdded = @DateAdded 
	WHERE 
		AWTYear = @AWTYear  
		AND 
		PK_Distributor = @PK_Distributor

END

/******************************************************************************
				END PROCEDURE
******************************************************************************/
		

		-- Update Processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;
		
END TRY
BEGIN CATCH
 	SET @Error = ERROR_NUMBER()
 	SET @ErrorMessage = ERROR_MESSAGE()
 	SET @StoredProcedure = ERROR_PROCEDURE()

 	IF @IsDevQA = 0 
	BEGIN  
		SELECT ERROR_LINE() AS ErrorLine;  		
		SELECT @Error AS [Error], @ErrorMessage AS [Error Message];
	END  

 	-- UPDATE ERROR LOG
 	EXEC dbo.usp_Utility_UpdateErrorLog 
 			@ProcedureName = @StoredProcedure
 			,@ErrorNumber = 3
 			,@ErrorMessage = @ErrorMessage
 			,@SQLErrorCode = @Error
 			,@SQLErrorMsg = @ErrorMessage
END CATCH;
END

 