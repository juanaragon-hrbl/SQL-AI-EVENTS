CREATE PROCEDURE [dbo].[usp_AWT_Save_AWT_Promo]
	 @COP AS [VARCHAR](10)
	,@StartMonth DATETIME2 = NULL
	,@EndMonth DATETIME2 = NULL
	,@ActionType CHAR(1) --I,U,D
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG
 
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		[dbo].[usp_AWT_Save_AWT_Promo]

	USE:		
			USE [PubEventManagement]
			GO

			DECLARE	@e int,
					@em varchar(4000)

			EXEC [dbo].[usp_AWT_Save_AWT_Promo]
					 @COP = 'BR'
					,@StartMonth = '2023-02-01'
					,@EndMonth = NULL
					,@ActionType = 'I'
					,@IsDevQA = 0
					,@Error = @e OUTPUT
					,@ErrorMessage = @em OUTPUT

			SELECT	@e AS N'@Error',
					@em AS N'@ErrorMessage'
			GO

	DESCRIPTION: 

	NOTES:	
	/api?/Awt?/InsertAwtPromo
	 
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

	SET @StartMonth = DATEADD(dd,1,EOMONTH(@StartMonth,-1))
	SET @EndMonth = DATEADD(dd,1,EOMONTH(@EndMonth,-1))
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

			;WITH cte_AWT_Promo AS
			(
				SELECT 
					@COP							AS [COP]
					,@StartMonth					AS [StartMonth]
					,@EndMonth						AS [EndMonth]
					,(SELECT sCountryCodeISO 
						FROM v_Countries 
						WHERE sCountryCode = @COP)	AS [COPISO]
			)
 
			INSERT INTO dbo.AWT_Promo(
				COP,
				StartMonth,
				EndMonth,
				COPISO
				)
			SELECT
				P.COP
				,P.StartMonth
				,P.EndMonth
				,P.COPISO
			FROM cte_AWT_Promo AS P 
			WHERE NOT EXISTS (SELECT 1 FROM dbo.AWT_Promo AS AP WITH (NOLOCK) WHERE AP.COP = P.COP)
	END

	IF @ActionType = 'D'
	BEGIN
			
		DELETE FROM dbo.[AWT_Promo] WHERE [COP] = @COP  
		
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

 