CREATE PROCEDURE [dbo].[usp_AWT_Save_AWT_Accelerator]
	 @AWTYear AS [int]
	,@RoyaltyMonth DATETIME2
	,@COP VARCHAR(10)
	,@ActionType CHAR(1) --I,U,D
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG
 
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		[dbo].[usp_AWT_Save_AWT_Accelerator]

	USE:		
			USE [PubEventManagement]
			GO

			DECLARE	@e int,
					@em varchar(4000)

			EXEC [dbo].[usp_AWT_Save_AWT_Accelerator]
					 @AWTYear = 2023
					,@RoyaltyMonth = '2022-01-22'
					,@COP = 'CN'
					,@ActionType = 'D'
					,@IsDevQA = 0
					,@Error = @e OUTPUT
					,@ErrorMessage = @em OUTPUT

			SELECT	@e AS N'@Error',
					@em AS N'@ErrorMessage'
			GO

	DESCRIPTION: 

	NOTES:	
	/api?/Awt?/InsertAwtAccelerator
	 
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

	SET @RoyaltyMonth = DATEADD(dd,1,EOMONTH(@RoyaltyMonth,-1))
	SET @COP = LTRIM(RTRIM(@COP))

	 IF NOT EXISTS (SELECT 1 FROM v_Countries WHERE sCountryCode = @COP)
	 BEGIN
		SET @Error = 90000
 		SET @ErrorMessage = 'Invalid COP' 			 

 		EXEC dbo.usp_Utility_UpdateErrorLog 
 			@ProcedureName = @StoredProcedure
 			,@ErrorNumber = 3
 			,@ErrorMessage = @ErrorMessage
 			,@SQLErrorCode = @Error
 			,@SQLErrorMsg = @ErrorMessage
		RETURN;
	 END

	IF @ActionType IN ('I','U')
	BEGIN

		;WITH cte_AWT_Accelerator AS
		(		
			SELECT  			 
					1				AS [Flg1]
				,1				AS [PK_AWT_AcceleratorType]
				,@AWTYear		AS [AWTYear]
				,@RoyaltyMonth	AS [Royaltymonth]
				,@COP			AS [COP]
		 
		)		

		MERGE dbo.[AWT_Accelerator] AS t
			USING cte_AWT_Accelerator AS s 
				ON s.[AWTYear] = t.[AWTYear] AND s.[COP] = t.[COP] AND s.[Royaltymonth] =  t.[Royaltymonth]
			WHEN NOT MATCHED THEN
				INSERT (
					[Flg1]
					,[PK_AWT_AcceleratorType]
					,[AWTYear]
					,[Royaltymonth]
					,[COP]
				)
				VALUES (
					s.[Flg1]
					,s.[PK_AWT_AcceleratorType]
					,s.[AWTYear]
					,s.[Royaltymonth]
					,s.[COP]
				)
			WHEN MATCHED THEN
			UPDATE SET
				[Flg1]						= s.[Flg1]
				,[PK_AWT_AcceleratorType]	= s.[PK_AWT_AcceleratorType]
				,[AWTYear]					= s.[AWTYear]
				,[Royaltymonth]				= s.[Royaltymonth]
				,[COP]						= s.[COP]
				;
	END

	IF @ActionType = 'D'
	BEGIN
			
		DELETE FROM dbo.[AWT_Accelerator] WHERE [AWTYear] = @AWTYear AND [COP] = @COP AND [Royaltymonth] = @RoyaltyMonth
		
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

 