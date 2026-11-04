CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_SAMCAM_Vacation2024]
	-- Mandatory parameters
	 @PK_Event INT = 197954
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
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_SAMCAM_Vacation2024

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_SAMCAM_Vacation2024
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 192227
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
1		2023-12-07	JonathanO	Intitial
2		2024-05-06	JonathanO	Intitial

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
	WE.Q16,

	 WQ.sSubTeam					
	,WQ.SPQualDate					
	,WQ.PTQualDate					
	,WQ.AWTQualDate				
	,WQ.IsDivorceCase				
	,WQ.TotalVolumeAccumulated_WW	
	,(WQ.TotalVolumeAccumulated_SA-WQ.MainIDVol) AS 	TotalVolumeAccumulated_SA	
	,WQ.TotalVolumeAccumulated_VE	
	,WQ.MainIDVol
	,WQ.MainIDVol_WW
	,WQ.[NEW GET & GET2500 BONUS]	
	,WQ.[NEW MT & MT7500 BONUS]	
	,WQ.[100,000 RO BONUS]
	,WQ.[1% WT BONUS]
	,WQ.VolumeMonthBonus_WW		
	,WQ.VolumeMonthBonus_SA		
	,WQ.VolumeMonthBonus_VE		
	,WQ.NewSPBonus_WW				
	,WQ.NewSPBonus_SA				
	,WQ.NewSPBonus_VE
	,WQ.TVPApr24_Full
	,WQ.TVPApr24_WW
	,WQ.TVPApr24_SA
	,WQ.TVPApr24_VE
	,WQ.TVPApr24_SA_Bonus
	,WQ.TVPApr24_WW_Bonus
	,WQ.TVPApr24_VE_Bonus
	,WQ.IsFromList		
FROM
	Event.DSQual			WE	WITH (NOLOCK)
INNER JOIN
	WRK_SAMCAM_Vacation2024	WQ	WITH (NOLOCK)
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