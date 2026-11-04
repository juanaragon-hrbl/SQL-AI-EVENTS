CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_EMEA_AWT]
	-- Mandatory parameters
	@DistributorID VARCHAR(10) 
	,@LocaleCode CHAR(5)

	-- Optional Parameters
	,@PK_Event INT = 206120	

	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_EMEA_AWT

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_EMEA_AWT
					 	 @DistributorID = N'28Y0039049'
						,@LocaleCode = 'en-US'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 0

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
1	2026-01-20	alejandramed	Intitial 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	/* DECLARE THE REQUIRED VARIABLES */
	
	DECLARE @PK_Distributor INT
	DECLARE @PK_Locale INT
	DECLARE @PK_DefaultLocale INT
	DECLARE @AWTYear INT = (SELECT TOP 1 AWTYear FROM [AWT_Definitions] WITH (NOLOCK) ORDER BY StartDate DESC)
BEGIN TRY
 
		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1
		END

		/* SET THE VALUES FOR THE DECLARED VARIABLES */

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event
		 
			DROP TABLE IF EXISTS #DS

			CREATE TABLE #DS
			(
				PK_Distributor		int,   
				DSCurrentTeam		varchar(10),        
				DSSubTeam			varchar(10),        
				DSSPTeam			varchar(10),               
				dSPQualDate			datetime2,        
				CountryCode			varchar(5),
				IsFromList			bit default(0),
				IsTicketPurchaser	bit default(0),
				IsAWTQualified bit default(0)
			)

			INSERT INTO #DS
			(
				PK_Distributor,	
				DSCurrentTeam,	
				DSSubTeam,		
				DSSPTeam,			
				dSPQualDate,		
				CountryCode,
				IsAWTQualified
			)
			SELECT DISTINCT        
			D.nDistributorID AS PK_Distributor,   
			CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
			D.sSubteam AS DSSubTeam,        
			D.sType AS DSSPTeam,            
			D.dSupervisorqualification AS dSPQualDate,        
			D.sDistributorCountryProcessingCode AS CountryCode,
			IIF(a.PK_Distributor IS NOT NULL, 1,0) AS IsAWTQualified
			FROM        
			dbo.v_Distributor AS D  
				LEFT JOIN [AWT] AS a WITH (NOLOCK)
					ON D.nDistributorID = a.PK_Distributor AND a.AWTYear = @AWTYear
			WHERE        
				D.sDistributorID = @DistributorID
  
			SELECT 
				AWTYear
				,PK_Distributor
				,RoyaltyMonth 
				,[TV] + [TV_Accelerator] AS [TV]
				,[RO]
				,ISNULL(did2500KTV,0)			AS did2500KTV
				,ISNULL(did10KTV,0)				AS did10KTV	
				,ISNULL(did500RO,0)				AS did500RO	
				,ISNULL(did5KTV,0)				AS did5KTV
				,ISNULL(did2500KTVL6M,0)		AS did2500KTVL6M	
				,ISNULL(did10KTVL6M,0)			AS did10KTVL6M	
				,ISNULL(did500ROL6M,0)			AS did500ROL6M	
				,ISNULL(did5KTVL6M,0)			AS did5KTVL6M	
				,ISNULL(didAWTJanFeb,0)			AS didAWTJanFeb					
				,ISNULL(didAWT,0)				AS didAWT	 
			FROM [AWT_Metrics] AS m WITH (NOLOCK) 
			WHERE AWTYear = @AWTYear
			AND DistributorID =  @DistributorID
			ORDER BY RoyaltyMonth

			 
		   SELECT PK_Distributor,	
				DSCurrentTeam,	
				DSSubTeam,		
				DSSPTeam,			
				dSPQualDate,		
				CountryCode,
				IsAWTQualified
				FROM #DS
				
	SET @Error = @Error + @@ERROR      

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
	END CATCH
END

