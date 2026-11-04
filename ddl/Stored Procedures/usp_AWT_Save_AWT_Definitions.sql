CREATE PROCEDURE [dbo].[usp_AWT_Save_AWT_Definitions]
	 @AWTYear AS [int]
	,@DistributorSet AS [int]
	,@StartDate DATETIME2
	,@EndDate DATETIME2
	,@NonTABDate DATETIME2
	,@ActionType CHAR(1) --I,U,D
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG
 
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		[dbo].[usp_AWT_Save_AWT_Definitions]

	USE:		
			USE [PubEventManagement]
			GO

			DECLARE	@e int,
					@em varchar(4000)

			EXEC [dbo].[usp_AWT_Save_AWT_Definitions]
					@AWTYear = 2023
					,@DistributorSet = 41709
					,@StartDate = '2022-08-01'
					,@EndDate = '2023-12-01'
					,@NonTABDate = '2022-08-01'
					,@ActionType = 'D'
					,@IsDevQA = 0
					,@Error = @e OUTPUT
					,@ErrorMessage = @em OUTPUT

			SELECT	@e AS N'@Error',
					@em AS N'@ErrorMessage'
			GO

	DESCRIPTION: 

	NOTES:	
	?/api?/Awt?/InsertAwtDefinition
	 
	TABLES:
	 
	DEPENDENCIES:
	
 
	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1	2023-01-09		alejandramed		Initial 
  
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

	IF @ActionType IN ('I','U')
	BEGIN

		;WITH cte_AWT_Definitions AS
		(
			SELECT
				 @AWTYear AS [AWTYear]
				 ,@DistributorSet AS [DistributorSet] 
				,@StartDate AS [StartDate]
				,@EndDate AS [EndDate]
				,@NonTABDate AS [NonTABDate]  
			
		)
 
		MERGE dbo.[AWT_Definitions] AS t
			USING cte_AWT_Definitions AS s ON s.[AWTYear] = t.[AWTYear]
			WHEN NOT MATCHED THEN
				INSERT (
					[AWTYear]
					,[StartDate]
					,[EndDate]
					,[NonTABDate]
					,[DistributorSet]
				)
				VALUES (
					s.[AWTYear]
					,s.[StartDate]
					,s.[EndDate]
					,s.[NonTABDate]
					,s.[DistributorSet]
				)
			WHEN MATCHED THEN
				UPDATE SET
					[AWTYear]			= s.[AWTYear]
					,[StartDate]		= s.[StartDate]
					,[EndDate]			= s.[EndDate]
					,[NonTABDate]		= s.[NonTABDate]
					,[DistributorSet]	= s.[DistributorSet]
			;
	END

	IF @ActionType = 'D'
	BEGIN
			
		DELETE FROM dbo.[AWT_Definitions] WHERE [AWTYear] = @AWTYear  
		
	END
		

		/******************************************************************************
						END PROCEDURE
		******************************************************************************/
		
		-- Update processing Log
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

 