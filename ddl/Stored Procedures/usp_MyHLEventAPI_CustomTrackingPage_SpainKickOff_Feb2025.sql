CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_SpainKickOff_Feb2025]
	-- Mandatory parameters
	 @PK_Event INT = 196676
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
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_SpainKickOff_Feb2025

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_SpainKickOff_Feb2025
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 196676
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
1		2024-10-28		JuanGue		Intitial
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
	WE.E01,	WE.E02,	WE.E03,	WE.E04,	WE.E05,
	WE.E06,	WE.E07,	WE.E08,	WE.E09,	WE.E10,
	WE.Q01,	WE.Q02,	WE.Q03,	WE.Q04,	WE.Q05,
	WE.Q06,	WE.Q07,	WE.Q08,	WE.Q09,	WE.Q10,
	WE.Q11,	WE.Q12,	WE.Q13,	WE.Q14,	WE.Q15,
	WE.Q16,	WE.Q17,	WE.Q18,	WE.Q19,	WE.Q20,
	WE.Q21,	WE.Q22,	WE.Q23,	WE.Q24,	WE.Q25
	
	,WQ.DistributorID	
	,WQ.DSCurrentTeam		
	,WQ.DSSubTeam			
	,WQ.DSSPTeam			
	,WQ.dSPQualDate		
	,WQ.CountryCode

	,WQ.IsFromList
	,WQ.IsTicketPurchaser	
	,WQ.IsFromCOP	

	,WQ.TVPOct24	
	,WQ.TVPNov24	
	,WQ.TVPDec24	
	,WQ.TVPJan25	
	,WQ.TotalTVP	

	,WQ.SpainTVPOct24		
	,WQ.SpainTVPNov24
	,WQ.SpainTVPDec24
	,WQ.SpainTVPJan25		
	,WQ.SpainTotalTVP	

FROM
	[Event].[DSQual]			WE	WITH (NOLOCK)
INNER JOIN
	dbo.WRK_SpainKickOff_Feb2025  	WQ	WITH (NOLOCK)
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