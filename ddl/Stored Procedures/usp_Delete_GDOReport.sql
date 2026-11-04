CREATE PROCEDURE [dbo].[usp_Delete_GDOReport]
	@PK_Event INT, 
	--Error Parameters
	@Error	int = 0 OUTPUT,
	@ErrorMessage varchar(4000) = NULL OUTPUT,

	--QA/DEV
	@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
 
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		[dbo].[usp_Delete_GDOReport]

	USE:		
			USE [PubEventManagement]
			GO

			DECLARE	@e int,
					@em varchar(4000)

			EXEC [dbo].[usp_Delete_GDOReport]
					@PK_Event = 193891, 					
					@IsDevQA = 0,
					@Error = @e OUTPUT,
					@ErrorMessage = @em OUTPUT

			SELECT	@e AS N'@Error',
					@em AS N'@ErrorMessage'
			GO

	DESCRIPTION: 

	Method: RemoveGDOReport
	Stored procedure name : [dbo].[usp_Delete_GDOReport]
	Parameters: @@PK_Event INT 
				 
	NOTES:	
	 
	TABLES:
			
	DEPENDENCIES:
	
 
	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1	2023-02-21		alejandramed		Initial 
  
	***********************************************************************************************************************************/
	 
	SET NOCOUNT ON;

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
				
	SELECT @Error = 0, @ErrorMessage = '';	

BEGIN TRY		

IF (@IsDevQA = 2)
BEGIN
	PRINT 'Forcing to fail for unit testing purpose';
	THROW 60000, N'Unit test Error', 1 
END

IF @IsDevQA = 0
BEGIN
 
	DELETE [tmp].[GDOReport] WHERE PK_Event = @PK_Event

END

/******************************************************************************
				END PROCEDURE
******************************************************************************/
				
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

 