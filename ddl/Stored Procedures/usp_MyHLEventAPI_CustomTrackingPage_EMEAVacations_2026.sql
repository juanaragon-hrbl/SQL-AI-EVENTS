CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_EMEAVacations_2026]
	-- Mandatory parameters
	 @PK_Event INT = 202874
	,@LocaleCode CHAR(5)
	-- Optional Parameters
	,@DistributorID VARCHAR(10) = '113507859'
		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_EMEAVacations_2026

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_EMEAVacations_2026
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 202874
						,@LocaleCode = 'es-ES'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.v_AGGFQS_ID, 


VERSIONS
----------------------------------------------------------------------------------
1		2025-02-27	JonathanO	 Intitial
2		2025-04-15	alejandramed User Story 1410700: 26006 - EMEA Vacation 2026 Umbraco Custom Tracker V2 - Stars
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

		/* SET THE VALUES FOR THE DECLARED VARIABLES */

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event


/******************************************************************************
******************************************************************************/
SELECT	
			 WE.PK_Distributor,	
	WE.Q01,	WE.Q02,	WE.Q03,	WE.Q04,	WE.Q05,
	WE.Q06,	WE.Q07,	WE.Q08,	WE.Q09,	WE.Q10,
	WE.Q11, WE.Q12,	WE.Q13,	WE.Q14,	WE.Q15,
	WE.Q16,	WE.Q17,	WE.Q18,	WE.Q19,	WE.Q20,
	WE.Q21,

	WE.E01,	WE.E02,	WE.E03,	WE.E04 ,WE.E05
		
		,WQ.DistributorID  
		,WQ.DSSubTeam	
		,WQ.sCountryCode
		,WQ.[Vacation Bonus]

	,WQ.TVPJan25WW,WQ.TVPJan25EA,WQ.TVPJan25BA				
	,WQ.ROJan25WW ,WQ.ROJan25EA ,WQ.ROJan25BA				
	,WQ.TVPFeb25WW,WQ.TVPFeb25EA,WQ.TVPFeb25BA				
	,WQ.ROFeb25WW ,WQ.ROFeb25EA ,WQ.ROFeb25BA				
	,WQ.TVPMar25WW,WQ.TVPMar25EA,WQ.TVPMar25BA				
	,WQ.ROMar25WW ,WQ.ROMar25EA ,WQ.ROMar25BA				
	,WQ.TVPApr25WW,WQ.TVPApr25EA,WQ.TVPApr25BA				
	,WQ.ROApr25WW ,WQ.ROApr25EA ,WQ.ROApr25BA				
	,WQ.TVPMay25WW,WQ.TVPMay25EA,WQ.TVPMay25BA				
	,WQ.ROMay25WW ,WQ.ROMay25EA ,WQ.ROMay25BA				
	,WQ.TVPJun25WW,WQ.TVPJun25EA,WQ.TVPJun25BA				
	,WQ.ROJun25WW ,WQ.ROJun25EA ,WQ.ROJun25BA				
	,WQ.TVPJul25WW,WQ.TVPJul25EA,WQ.TVPJul25BA				
	,WQ.ROJul25WW ,WQ.ROJul25EA ,WQ.ROJul25BA				
	,WQ.TVPAug25WW,WQ.TVPAug25EA,WQ.TVPAug25BA				
	,WQ.ROAug25WW ,WQ.ROAug25EA ,WQ.ROAug25BA				
	,WQ.TVPSep25WW,WQ.TVPSep25EA,WQ.TVPSep25BA				
	,WQ.ROSep25WW ,WQ.ROSep25EA ,WQ.ROSep25BA				
	,WQ.TVPOct25WW,WQ.TVPOct25EA,WQ.TVPOct25BA				
	,WQ.ROOct25WW ,WQ.ROOct25EA ,WQ.ROOct25BA				
	,WQ.TVPNov25WW,WQ.TVPNov25EA,WQ.TVPNov25BA				
	,WQ.RONov25WW ,WQ.RONov25EA ,WQ.RONov25BA				
	,WQ.TVPDec25WW,WQ.TVPDec25EA,WQ.TVPDec25BA				
	,WQ.RODec25WW ,WQ.RODec25EA ,WQ.RODec25BA
	,WQ.[Stars]
FROM
	Event.DSQual			WE	WITH (NOLOCK)
INNER JOIN
	WRK_EMEAVacations_2026	WQ	WITH (NOLOCK)
ON
	WE.PK_Distributor = WQ.PK_Distributor
AND
	WE.PK_Distributor = @PK_Distributor
AND
	WE.PK_Event = @PK_Event

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