CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMPTVacation_2025]
	-- Mandatory parameters
	 @PK_Event INT = 198704
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
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMPTVacation_2025

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMPTVacation_2025
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 198704
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
1		2024-02-01		JuanGue		Intitial
2		2024-04-23		JuanGue		BRD v2
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
	WE.Q11,	WE.Q12,	WE.Q13,	WE.Q14,	WE.Q15,
	WE.Q16,	WE.Q17,	WE.Q18,	WE.Q19,	WE.Q20,
	WE.Q21,			
	WQ.DistributorID				
	,WQ.sMainDistributorID														   
	,WQ.CurrentTeam				
	,WQ.SubTeam					
	,WQ.DSPTeam					
	,WQ.sCountryCode				
	,WQ.QSQualDate					
	,WQ.SPQualDate					
	,WQ.HasTicket					
	,WQ.IsNewPT					
	,WQ.PTQualDate	
	,WQ.TVPJan24	        
	,WQ.TVPFeb24	        
	,WQ.TVPMar24	        
	,WQ.TVPApr24	        
	,WQ.TVPMay24	        
	,WQ.TVPJun24	        
	,WQ.TVPJul24	        
	,WQ.TVPAug24	        
	,WQ.TVPSep24	        
	,WQ.TVPOct24	        
	,WQ.TVPNov24	        
	,WQ.TVPDec24	        
	,WQ.ROJan24	        
	,WQ.ROFeb24	        
	,WQ.ROMar24	        
	,WQ.ROApr24	        
	,WQ.ROMay24	        
	,WQ.ROJun24	        
	,WQ.ROJul24	        
	,WQ.ROAug24	        
	,WQ.ROSep24	        
	,WQ.ROOct24	        
	,WQ.RONov24	        
	,WQ.RODec24					
	,WQ.TotalTVP					
	,WQ.TotalRO					
	,WQ.[New DS Bonus]
	,WQ.[New PM Bonus]		
	,WQ.[New SP Bonus]	
	,WQ.[New ASP Bonus]	
	,WQ.[Double March Bonus]
FROM
	Event.DSQual					WE	WITH (NOLOCK)
INNER JOIN
	WRK_NAMPTVacation_2025			WQ	WITH (NOLOCK)
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