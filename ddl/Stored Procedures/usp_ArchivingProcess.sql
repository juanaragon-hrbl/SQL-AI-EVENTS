CREATE PROCEDURE [dbo].[usp_ArchivingProcess]
	-- QA/DEV
	@IsDevQA smallint = 0
	-- Error Parameters
	,@Error	int  OUTPUT
	,@ErrorMessage varchar(4000) OUTPUT
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_ArchivingProcess

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC	[dbo].[usp_ArchivingProcess] 
					@IsDevQA = 0,
					@Error = @Error OUTPUT, 
					@ErrorMessage = @ErrorMessage OUTPUT
					

			SELECT	@Error as N'@Error',
					@ErrorMessage as N'@ErrorMessage'

			GO

			* @IsDevQA = 0 - PROD
			* @IsDevQA = 2 - Forcing to fail for UT
			
	DESCRIPTION: This stored procedure runs the archiving process 
					
				 
	NOTES: The execution order must consider the references between the tables

	DEPENDENCIES:
	usp_Utility_UpdateErrorLog
	usp_Utility_UpdateProcessingLog
	
	WORK TABLES (WRK):
	
	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2022-07-06		alejandramed		Initial 
	1.0.1	2023-01-13		alejandramed		Obtaining the stored procedure dynamically for archiving process.
	1.0.2	2025-08-22		jairli      		Get strored procedure schema.
	***********************************************************************************************************************************/

	DECLARE @StoredProcedure varchar(255) = 'usp_ArchivingProcess'
			,@StoredProcedureParameters varchar(100) = 'Complete'
			,@StartTime datetime2 = GETUTCDATE();
			
	SELECT @Error = 0, @ErrorMessage = '';	
	DECLARE @e int = 0, @em varchar(max) = '';

	SET NOCOUNT ON;

BEGIN TRY
			
		DECLARE 
		@sqlstatement AS NVARCHAR(MAX), 
		@params_definition  AS NVARCHAR(MAX),
		@stored_procedure_name AS NVARCHAR(MAX),
		@schema_name AS NVARCHAR(MAX) ,
		@ID INT

		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for UT';
			THROW 60001, N'Error UT', 1
		END

		DROP TABLE IF EXISTS #ArchivingExec

		SELECT IDENTITY(INT,1,1) AS ID, [TableName], [StoredProcedureName], 0 AS [ctrl]
		INTO #ArchivingExec
		FROM [Shared].[ArchivingSettings] WITH (NOLOCK)
		WHERE [Active] = 1
		ORDER BY ExecutionOrder ASC

		WHILE EXISTS (SELECT 1 FROM #ArchivingExec AS ex WHERE [ctrl] = 0)
		BEGIN

			SELECT @ID = MIN(ID) FROM #ArchivingExec WHERE [ctrl] = 0  
			
			SELECT 
				@stored_procedure_name = LTRIM(RTRIM(StoredProcedureName)) 
			FROM #ArchivingExec	
			WHERE [ID] = @ID  

			SELECT  @schema_name = s.Name 
			FROM sys.objects O WITH (NOLOCK)
            INNER JOIN sys.schemas s WITH (NOLOCK) ON O.schema_id = S.schema_id AND O.name = @stored_procedure_name
            WHERE type = 'P';

			IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID(@schema_name + '.' + @stored_procedure_name))
			BEGIN 				 

				SET @sqlstatement = N'EXEC [PubEventManagement].['+ @schema_name +'].[' + @stored_procedure_name +'] @Error = @Error_Output OUTPUT, @ErrorMessage = @ErrorMessage_Output OUTPUT'
				SET @params_definition= N'@Error_Output AS INT OUTPUT, @ErrorMessage_Output VARCHAR(MAX) OUTPUT'
				
				
				PRINT ('/--')
				PRINT CONCAT('Stored procedure: ', @stored_procedure_name)
				PRINT CONCAT('Statement: ', @sqlstatement)		


				BEGIN TRY
					 
					EXEC sp_executesql @sqlstatement
						,@params_definition
						,@Error_Output = @e OUTPUT
						,@ErrorMessage_Output =  @em OUTPUT						 

				END TRY
				BEGIN CATCH
 					SET @Error = ERROR_NUMBER()
 					SET @ErrorMessage = ERROR_MESSAGE()
 					SET @StoredProcedure = ERROR_PROCEDURE()

 					IF @IsDevQA = 0 
					BEGIN  

						PRINT CONCAT('Statement execution error: ', @Error)
						PRINT CONCAT('Statement execution error message: ', @ErrorMessage)	
						
					END  

					IF @@TRANCOUNT > 0 AND @Error !=0
					BEGIN
						PRINT 'Rollback due error'
						ROLLBACK TRAN;
					END

 					-- UPDATE ERROR LOG
 					EXEC dbo.usp_Utility_UpdateErrorLog 
 							@ProcedureName = @StoredProcedure
 							,@ErrorNumber = 3
 							,@ErrorMessage = @ErrorMessage
 							,@SQLErrorCode = @Error
 							,@SQLErrorMsg = @ErrorMessage
				END CATCH;
				
				IF @e != 0
				BEGIN
					PRINT CONCAT('Archiving execution Error: ', @e)
					PRINT CONCAT('Archiving execution Error Message: ', @em)
				END
			END
			ELSE 
			BEGIN
				PRINT ('/--')
				PRINT CONCAT(ISNULL(@stored_procedure_name,'NULL'), ' does NOT exists, it is not possible to execute it.')
			END
 
			UPDATE #ArchivingExec
			SET [ctrl] = 1
			WHERE [ID] = @ID  

		END

		IF @e != 0
			PRINT @em

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
					@StoredProcedureName = @StoredProcedure,
					@StoredProcedureParameters = @StoredProcedureParameters,
					@StartTime = @StartTime;

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA != 0 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
	END CATCH;
END;

