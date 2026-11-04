CREATE PROCEDURE [dbo].[usp_AWT_Set_ManualOverride]
	@AWTYear INT,
	@DistributorID VARCHAR(25),
	@Qual_AWT DATETIME2,
	@DateAdded DATETIME2 = NULL, --Optional: If null, the 11th day of the current date is used.
	--Error Parameters
	@Error	int = 0 OUTPUT,
	@ErrorMessage varchar(4000) = NULL OUTPUT,

	--QA/DEV
	@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
 
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		[dbo].[usp_AWT_Set_ManualOverride]

	USE:		
			USE [PubEventManagement]
			GO

			DECLARE	@e int,
					@em varchar(4000)

			EXEC [dbo].[usp_AWT_Set_ManualOverride]
					@AWTYear = 2023,
					@DistributorID = '07026887C',
					@Qual_AWT = '2023-01-01',
					@DateAdded = NULL,					
					@IsDevQA = 0,
					@Error = @e OUTPUT,
					@ErrorMessage = @em OUTPUT

			SELECT	@e AS N'@Error',
					@em AS N'@ErrorMessage'
			GO

	DESCRIPTION: 

	Method:  SetManualOverride
	Stored procedure name : [dbo].[usp_AWT_Set_ManualOverride]
	Parameters: @AWTYear INT,
				@DistributorID VARCHAR(25),
				@Qual_AWT DATETIME2,
				@DateAdded DATETIME2 = NULL, --Optional: If null, the 11th day of the current date is used.

	NOTES:	
	/api?/Awt?/InsertAwtManualOverride

	TABLES:
			
	DEPENDENCIES:
	
 
	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1	2023-01-10		alejandramed		Initial 
  
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

	DECLARE 
		@CreatedBy NVARCHAR(MAX) = (replace(suser_sname(),'HERBALIFECORP\','')),
		@Flg1 INT = 1,
		@PK_Distributor INT = (SELECT nDistributorID FROM v_Distributor WHERE sDistributorID = @DistributorID)
			
		SELECT @DateAdded = ISNULL(@DateAdded,DATEFROMPARTS(YEAR(GETUTCDATE()),MONTH(GETUTCDATE()),11))

		IF @PK_Distributor IS NULL
		BEGIN

			SET @Error = 90000
 			SET @ErrorMessage = 'Distributor ID not found'
 			 

 			EXEC dbo.usp_Utility_UpdateErrorLog 
 				@ProcedureName = @StoredProcedure
 				,@ErrorNumber = 3
 				,@ErrorMessage = @ErrorMessage
 				,@SQLErrorCode = @Error
 				,@SQLErrorMsg = @ErrorMessage
			RETURN;

		END

		MERGE [dbo].[AWT_ManualOverride]  AS t
		USING (
		SELECT
				@CreatedBy AS [CreatedBy]
				,@Flg1 AS [Flg1]
				,@AWTYear AS [AWTYear]
				,@PK_Distributor AS [PK_Distributor]
				,@DistributorID AS [DistributorID]
				,@DateAdded AS [DateAdded]
				,@Qual_AWT AS [Qual_AWT]
			) AS s ON s.[PK_Distributor] = t.[PK_Distributor] AND s.[AWTYear] = t.[AWTYear]
			WHEN NOT MATCHED THEN
				INSERT (
					[CreatedBy]
					,[Flg1]
					,[AWTYear]
					,[PK_Distributor]
					,[DistributorID]
					,[DateAdded]
					,[Qual_AWT]	 
				)
			VALUES (
					s.[CreatedBy]
					,s.[Flg1]
					,s.[AWTYear]
					,s.[PK_Distributor]
					,s.[DistributorID]
					,s.[DateAdded]
					,s.[Qual_AWT]	 
			)
			WHEN MATCHED THEN
			UPDATE SET
					[CreatedBy]				= s.[CreatedBy]
					,[Flg1]					= s.[Flg1]
					,[AWTYear]				= s.[AWTYear]
					,[PK_Distributor]		= s.[PK_Distributor]
					,[DistributorID]		= s.[DistributorID]
					,[DateAdded]			= s.[DateAdded]
					,[Qual_AWT]	 	 		= s.[Qual_AWT]
			; -- [dbo].[AWT_ManualOverride]
 

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

 	-- UPDATE ERROR LOG
 	EXEC dbo.usp_Utility_UpdateErrorLog 
 			@ProcedureName = @StoredProcedure
 			,@ErrorNumber = 3
 			,@ErrorMessage = @ErrorMessage
 			,@SQLErrorCode = @Error
 			,@SQLErrorMsg = @ErrorMessage
END CATCH;
END

 