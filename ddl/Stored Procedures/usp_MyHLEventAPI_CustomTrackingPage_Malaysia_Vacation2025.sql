CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_Malaysia_Vacation2025]
	-- Mandatory parameters
	 @PK_Event INT = 201105
	,@LocaleCode CHAR(5)
	-- Optional Parameters
	,@DistributorID VARCHAR(10) = '113507859'
	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT
	-- QA/DEV
	,@IsDevQA int = 0
AS
BEGIN 
/******************************************************************************
OBJECT:	dbo.usp_MyHLEventAPI_CustomTrackingPage_Malaysia_Vacation2025

USE:	        
		DECLARE @e int, @em varchar(4000)
		
        EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_Malaysia_Vacation2025
			@DistributorID = N'10Y2137058'
			,@PK_Event = 201105
			,@LocaleCode = 'es-ES'
			,@Error = @e OUTPUT  -- @e must be defined in the local call   
			,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
			,@IsDevQA = 0

		SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.v_AGGFQS_ID, 


VERSIONS
----------------------------------------------------------------------------------
1		2024-09-24		JuanGue		Intitial
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
			THROW 60000, N'Unit test Error', 1
		END
		/* SET THE VALUES FOR THE DECLARED VARIABLES */

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

		IF @IsDevQA = 0 AND EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_Malaysia_Vacation_2025' and type='U')
		BEGIN

			SELECT	
				WQ.PK_Distributor				
				,WQ.DistributorID				
				,WQ.DSCurrentTeam				
				,WQ.DSSubTeam					
				,WQ.DSSPTeam					
				,WQ.dSPQualDate
				,WQ.TeamJun2024
				,WQ.CountryCode				
				,WQ.IsFromList					
				,WQ.IsTicketPurchaser			
				,WQ.IsFromCOP					
				,WQ.TVPJun24					
				,WQ.TVPJul24					
				,WQ.TVPAug24					
				,WQ.TVPSep24					
				,WQ.TVPOct24					
				,WQ.TVPNov24					
				,WQ.TVPDec24					
				,WQ.TVPJan25					
				,WQ.TVPFeb25					
				,WQ.TVPMar25					
				,WQ.TVPApr25					
				,WQ.TVPMay25					
				,WQ.TotalTVP					
				,WQ.IsASP						
				,WQ.ASPSponsors				
				,WQ.ASPTotalBonus				
				,WQ.WT1BonusSponsors			
				,WQ.WT1BonusTotalBonus			
				,WQ.PremierLeagueSponsors		
				,WQ.PremierLeagueTotalBonus	
				,WQ.TotalVacationPoints
				,WQ.IsPremierLeagueQualified
				,WE.E01,WE.E02, WE.E03, WE.E04, WE.E05
				,WE.Q01,WE.Q02,	WE.Q03,	WE.Q04,	WE.Q05
				,WE.Q06,WE.Q07,	WE.Q08,	WE.Q09,	WE.Q10
				,WE.Q11,WE.Q12,	WE.Q13,	WE.Q14, WE.Q15
			FROM
				[Event].DSQual WE (NOLOCK)
			INNER JOIN WRK_Malaysia_Vacation_2025 WQ (NOLOCK)
				ON	WE.PK_Distributor = WQ.PK_Distributor
			WHERE 
				@LocaleCode IS NOT NULL 
				AND WE.PK_Distributor = @PK_Distributor 
				AND WE.PK_Event = @PK_Event
			
		END

	END -- Body

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

		IF @IsDevQA = 3 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
	END CATCH

END