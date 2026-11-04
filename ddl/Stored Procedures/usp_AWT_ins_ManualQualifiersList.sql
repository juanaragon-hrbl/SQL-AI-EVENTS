CREATE PROCEDURE [dbo].[usp_AWT_ins_ManualQualifiersList]
	@AWTYear	INT 
	,@DateAdded smalldatetime = NULL
	,@AWTQualDate smalldatetime = NULL

	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG

AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_AWT_ins_ManualQualifiersList

	USE:		EXEC dbo.usp_AWT_ins_ManualQualifiersList @AWTYear = 2021
			
	DESCRIPTION: 

	NOTES:		

		DistributorSet 41805 for AWT2021_ManualQualifiers

	DEPENDENCIES:

	WORK TABLES (WRK):


	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1	2021-07-27		alejandramed		Initial 
	
	***********************************************************************************************************************************/

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()

	
	SELECT @Error = 0, @ErrorMessage = '';	

BEGIN TRY
		
		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1
		END
		
		SET @DateAdded = IIF(@DateAdded IS NULL, GETUTCDATE(),@DateAdded)

		SET @AWTQualDate = IIF(@AWTQualDate IS NULL, DATEADD(DAY,1,EOMONTH(DATEADD(MM,-1,@DateAdded),-1)),@AWTQualDate)

		DECLARE @DistributorSetManualQualifiers int 
		-----------------------------------------------------------------------------------
		
		DROP TABLE IF EXISTS #AWT_Manual_Qualifiers

		CREATE TABLE #AWT_Manual_Qualifiers
		(
			DistributorID varchar(30)
			,PK_Distributor int
			,Qual_AWT date
			,DateAdded date
		)

		-----------------------------------------------------------------------------------
			
			IF @IsDevQA = 0
			BEGIN
				SELECT 
					@DistributorSetManualQualifiers = [DistributorSetManualQualifiers]
				FROM dbo.AWT_Definitions WITH (NOLOCK) WHERE AWTYear = @AWTYear
			END

			INSERT INTO #AWT_Manual_Qualifiers(DistributorID,PK_Distributor,Qual_AWT,DateAdded)
			SELECT
				D.sDistributorID AS DistributorID,
				D.nDistributorID AS PK_Distributor,
				@AWTQualDate AS [Qual_AWT],
				@DateAdded AS DateAdded
			FROM dbo.v_DistributorSet S
			INNER JOIN dbo.v_Distributor D 
				ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
			WHERE S.nTypeLID = @DistributorSetManualQualifiers
			
			IF @IsDevQA = 0
			BEGIN
				INSERT INTO dbo.AWT_ManualOverride(Flg1,AWTYear,PK_Distributor,DistributorID,DateAdded,Qual_AWT)
				SELECT 1,@AWTYear,PK_Distributor,DistributorID,DateAdded,Qual_AWT
				FROM #AWT_Manual_Qualifiers AS Q
				WHERE NOT EXISTS (SELECT 1 FROM dbo.AWT_ManualOverride AM WITH (NOLOCK) WHERE AM.AWTYear = @AWTYear AND AM.PK_Distributor = Q.PK_Distributor)
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

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
	END CATCH;
END;



