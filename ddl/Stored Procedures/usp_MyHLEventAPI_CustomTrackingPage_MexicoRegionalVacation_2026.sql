CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_MexicoRegionalVacation_2026]
	 --Mandatory parameters
	 @PK_Event INT = 201100
	,@LocaleCode CHAR(5)

	-- Optional Parameters
	,@DistributorID VARCHAR(10) 

	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_MexicoRegionalVacation_2026

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_MexicoRegionalVacation_2026
					 	 @DistributorID = N'11083173'
					 	,@PK_Event = 201100
						,@LocaleCode = 'en-US'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
1.0		2025-02-21			juangue			Intitial
1.1		2025-03-26			juangue			Remove August double bonus
1.1		2025-04-02			juangue			Remove IsActiveAugustBonus
1.2		2025-04-04			juangue			Volume Points Breakdown
1.3		2025-04-07			juangue			#1410736 Include Freeze Team level in API
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

BEGIN TRY

	BEGIN -- Body

		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1
		END

	
		-- Variables for json values

		DECLARE @TeamFreezeDate INT,
			@IsJulyDoubleBonusActive BIT, 
			@IsNewDSBonusActive bit, 
			@Parameters NVARCHAR(MAX) = ''

		-- Getting parameters from qualifications execution setup

		SELECT @Parameters = [Parameters] FROM [Shared].[QualsExecParams] WITH (NOLOCK) WHERE PK_Event = @PK_Event

		-- Getting parameters values for json
		SELECT  
			@TeamFreezeDate = teamFreezeDate,
			@IsJulyDoubleBonusActive = isJulyDoubleBonusActive,
			@IsNewDSBonusActive = isNewDSBonusActive
		FROM OPENJSON(@Parameters)
		WITH (
				
				teamFreezeDate INT '$.teamFreezeDate',
				isJulyDoubleBonusActive BIT '$.isJulyDoubleBonusActive',
				isNewDSBonusActive BIT '$.isNewDSBonusActive'
			)
	 
		-- Default values
		SET @PK_Event = IIF(@PK_Event IS NULL,201100, @PK_Event)
		SET @TeamFreezeDate = IIF(@TeamFreezeDate IS NULL,202501, @TeamFreezeDate)
		SET @IsJulyDoubleBonusActive = IIF(@IsJulyDoubleBonusActive IS NULL,1, @IsJulyDoubleBonusActive)
		SET @IsNewDSBonusActive = IIF(@IsNewDSBonusActive IS NULL,1, @IsNewDSBonusActive)

		/* SET THE VALUES FOR THE DECLARED VARIABLES */

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

		----------------------------------------------------------------------------------------------------
		
		--Result set 1
		SELECT 		
			D.[PK_Distributor],
			@DistributorID AS [DistributorID],
			D.[DSTeam],
			D.[DSSubTeam], 
			D.[DSFreezeSubTeam],
			B.[New DS Bonus] AS [New DS Bonus],
			B.[TotalNewDS] AS [TotalNewDS],
			B.[JULY DOUBLE VOLUME PROMOTION] AS [JULY DOUBLE VOLUME PROMOTION],
			Q.Q01,
			Q.Q02,
			Q.Q03,
			Q.Q04,
			Q.Q05,
			Q.Q06,
			Q.Q07,
			Q.Q08,
			Q.Q09,
			Q.Q10,
			Q.Q11,
			Q.Q12,
			Q.Q13,
			Q.Q14,
			Q.Q15,
			Q.Q16,
			Q.E01,
			Q.E02,
			@IsJulyDoubleBonusActive AS [IsJulyDoubleBonusActive],
			@IsNewDSBonusActive AS [IsNewDSBonusActive],
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'TV' AND BP.RoyaltyMonth = 202501),0) AS TVPJan2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'TV' AND BP.RoyaltyMonth = 202502),0) AS TVPFeb2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'TV' AND BP.RoyaltyMonth = 202503),0) AS TVPMar2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'TV' AND BP.RoyaltyMonth = 202504),0) AS TVPApr2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'TV' AND BP.RoyaltyMonth = 202505),0) AS TVPMay2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'TV' AND BP.RoyaltyMonth = 202506),0) AS TVPJun2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'TV' AND BP.RoyaltyMonth = 202507),0) AS TVPJul2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'TV' AND BP.RoyaltyMonth = 202508),0) AS TVPAug2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'TV' AND BP.RoyaltyMonth = 202509),0) AS TVPSep2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'TV' AND BP.RoyaltyMonth = 202510),0) AS TVPOct2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'TV' AND BP.RoyaltyMonth = 202511),0) AS TVPNov2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'TV' AND BP.RoyaltyMonth = 202512),0) AS TVPDec2025,

			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'RO' AND BP.RoyaltyMonth = 202501),0) AS ROJan2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'RO' AND BP.RoyaltyMonth = 202502),0) AS ROFeb2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'RO' AND BP.RoyaltyMonth = 202503),0) AS ROMar2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'RO' AND BP.RoyaltyMonth = 202504),0) AS ROApr2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'RO' AND BP.RoyaltyMonth = 202505),0) AS ROMay2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'RO' AND BP.RoyaltyMonth = 202506),0) AS ROJun2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'RO' AND BP.RoyaltyMonth = 202507),0) AS ROJul2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'RO' AND BP.RoyaltyMonth = 202508),0) AS ROAug2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'RO' AND BP.RoyaltyMonth = 202509),0) AS ROSep2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'RO' AND BP.RoyaltyMonth = 202510),0) AS ROOct2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'RO' AND BP.RoyaltyMonth = 202511),0) AS RONov2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'RO' AND BP.RoyaltyMonth = 202512),0) AS RODec2025,

			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'VP' AND BP.RoyaltyMonth = 202501),0) AS VPJan2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'VP' AND BP.RoyaltyMonth = 202502),0) AS VPFeb2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'VP' AND BP.RoyaltyMonth = 202503),0) AS VPMar2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'VP' AND BP.RoyaltyMonth = 202504),0) AS VPApr2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'VP' AND BP.RoyaltyMonth = 202505),0) AS VPMay2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'VP' AND BP.RoyaltyMonth = 202506),0) AS VPJun2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'VP' AND BP.RoyaltyMonth = 202507),0) AS VPJul2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'VP' AND BP.RoyaltyMonth = 202508),0) AS VPAug2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'VP' AND BP.RoyaltyMonth = 202509),0) AS VPSep2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'VP' AND BP.RoyaltyMonth = 202510),0) AS VPOct2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'VP' AND BP.RoyaltyMonth = 202511),0) AS VPNov2025,
			ISNULL((SELECT DISTINCT BP.[Points] FROM [dbo].[WRK_26003_BonusPoints] BP (NOLOCK) WHERE BP.PK_Distributor = D.PK_Distributor AND BP.MetricType = 'VP' AND BP.RoyaltyMonth = 202512),0) AS VPDec2025
			
		FROM [dbo].[WRK_26003_DSDetails] AS D WITH (NOLOCK) 
		INNER JOIN [Event].[DSQual] AS Q WITH (NOLOCK)
			ON D.PK_Distributor = Q.PK_Distributor AND Q.PK_Event = @PK_Event
		LEFT JOIN [dbo].[WRK_26003_BonusSummary] AS B WITH (NOLOCK)
			ON D.PK_Distributor = B.PK_Distributor
		WHERE  D.PK_Distributor = @PK_Distributor 
		

	END --Body 

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