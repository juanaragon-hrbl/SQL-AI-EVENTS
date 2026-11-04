CREATE PROCEDURE [dbo].[usp_PromoTracker_Downline]
		@request nvarchar(max)
	    --Error Parameters
	   ,@Error	int = 0 OUTPUT
	   ,@ErrorMessage varchar(4000) = NULL OUTPUT

	    --QA/DEV
	   ,@IsDevQA SMALLINT = 0 
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_PromoTracker_Downline

	USE:		
		DECLARE @request nvarchar(max) =
		N'{   
                    "DsProcCountry":["EC"],
                    "DsDLProcCountry":["EC"],
                    "DSStatus":["COMPLETE"],
                    "DSDLStatus":["COMPLETE"],
                    "DLLevel": "6"
                }'

	EXEC dbo.usp_PromoTracker_Downline @request = @request, @IsDevQA BIT = 0 

	DESCRIPTION: 

	NOTES:			

	DEPENDENCIES:
	

	WORK TABLES (WRK):
	

	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1	2021-02-25		alejandramed		Initial 

*********************************************************************************************************************/

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

	DECLARE @DLLevel INT

		SELECT 
			@DLLevel = ISNULL(DLLevel,0)
		FROM OPENJSON(@request)
		WITH
		(
			DLLevel VARCHAR(20) '$.DLLevel'
		)

	DROP TABLE IF EXISTS #DLLevels

		SELECT [n] + 1 AS [DLLevel]
		INTO #DLLevels
		FROM [PubEventManagement].[dbo].[Numbers]
		WHERE n > 0 AND n <= @DLLevel

	DROP TABLE IF EXISTS #DsProcCountry

		SELECT c.nCountryID, c.sCountryCode, c.sCountryCodeISO, c.sCountryName 
		INTO #DsProcCountry
		FROM
		(
			SELECT CAST(sCountryCodeISO AS VARCHAR(10)) AS sCountryCodeISO
			FROM OPENJSON(@request,'$.DsProcCountry')
			WITH( 
			sCountryCodeISO VARCHAR(20) '$')
		) AS j
			INNER JOIN v_Countries AS c
				ON j.sCountryCodeISO = c.sCountryCodeISO
			
	CREATE INDEX IX_#DsProcCountry_nCountryID ON #DsProcCountry(nCountryID)

	DROP TABLE IF EXISTS #DsDLProcCountry

		SELECT c.nCountryID, c.sCountryCode, c.sCountryCodeISO, c.sCountryName 
		INTO #DsDLProcCountry
		FROM
		(
			SELECT CAST(sCountryCodeISO AS VARCHAR(10)) AS sCountryCodeISO
			FROM OPENJSON(@request,'$.DsDLProcCountry')
			WITH( 
			sCountryCodeISO VARCHAR(20) '$')
		) AS j
			INNER JOIN v_Countries AS c
				ON j.sCountryCodeISO = c.sCountryCodeISO
			
	CREATE INDEX IX_#DsDLProcCountry_nCountryID ON #DsProcCountry(nCountryID)

	DROP TABLE IF EXISTS #DSStatus

		SELECT CAST(DSStatus AS VARCHAR(10)) AS DSStatus
		INTO #DSStatus
		FROM OPENJSON(@request,'$.DSStatus')
		WITH( 
		DSStatus VARCHAR(20) '$' )

	CREATE INDEX IX_#DSStatus_DSStatus ON #DSStatus(DSStatus)

	DROP TABLE IF EXISTS #DSDLStatus

		SELECT CAST(DSDLStatus AS VARCHAR(10)) AS DSDLStatus
		INTO #DSDLStatus
		FROM OPENJSON(@request,'$.DSDLStatus')
		WITH( 
		DSDLStatus VARCHAR(20) '$')

	CREATE INDEX IX_#DSDLStatus_DSDLStatus ON #DSDLStatus(DSDLStatus)

	DROP TABLE IF EXISTS #DS;

		CREATE TABLE #DS
		(		
			[PK_Distributor]			int, 
			[DSId]						varchar(25),
			[DS1stULSP]					varchar(25),
			[DS1stULSPName]				varchar(150)
		);

		INSERT INTO #DS(
			[PK_Distributor]	
			,[DSId]
			,[DS1stULSP]
			,[DS1stULSPName]
		)
		SELECT 
			d.nDistributorID
			,d.sDistributorID AS DSId
			,COALESCE(ld.sDistributorID,'') AS DS1stULSP
			,CONCAT(COALESCE(ld.sLastName,''), ' , ',COALESCE(ld.sFirstName,'')) AS DS1stULSPName
		FROM [dbo].[v_Distributor] AS d
			INNER JOIN dbo.v_DistributorLineage AS l (NOLOCK)
				ON d.nDistributorID = l.nDistributorID
			INNER JOIN v_Distributor AS ld (NOLOCK)
				ON l.n1stSupervisorID = ld.nDistributorID
		WHERE EXISTS (SELECT 1 FROM #DSDLStatus AS s WHERE s.DSDLStatus = d.StatusCode)
			AND EXISTS (SELECT 1 FROM #DsProcCountry AS C WHERE c.nCountryID = d.nDistributorCountryProcessingID)
			
		CREATE INDEX IX_#DS_PK_Distributor ON #DS([PK_Distributor]) 

	DROP TABLE IF EXISTS #DL

		SELECT 
				U.PK_Distributor,
				U.DSId AS DS,
				DL.PK_DSDownline,
				DLD.sDistributorID AS [DSDL],
				DL.DSLevelFromUL - 1 AS DLLevel,
				U.DS1stULSP,
				U.DS1stULSPName
			INTO #DL
			FROM
				#DS AS U
			INNER JOIN
				dbo.v_dimDSLngDownline AS DL WITH (NOLOCK)
			ON
				U.PK_Distributor = DL.PK_Distributor
			INNER JOIN v_Distributor AS DLD 
				ON DLD.nDistributorID = DL.PK_DSDownline
			WHERE EXISTS (SELECT 1 FROM #DLLevels AS l WHERE DL.DSLevelFromUL = l.DLLevel)
				
		CREATE INDEX IX_#DL_PK_Distributor ON #DL([PK_Distributor]) 

		DECLARE @DisplayResult BIT = 1

		IF OBJECT_ID('Shared.UnitTestSettings', 'U') IS NOT NULL
		BEGIN
	
			 SET @DisplayResult =  (SELECT TOP 1 CAST([Value] AS BIT) FROM [Shared].[UnitTestSettings] 
										WHERE [ObjectName] =  'usp_PromoTracker_Downline' AND [Key] = 'DisplayResult' AND [IsActive] = 1)
		END
		
		IF @DisplayResult = 1
		BEGIN
			SELECT 
				DS,
				[DSDL],
				DLLevel,
				DS1stULSP,
				DS1stULSPName
			FROM #DL
		END
	
		
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




