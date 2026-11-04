CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMTabTeam_2025]
	-- Mandatory parameters
	 @PK_Event INT = 198215
	,@LocaleCode CHAR(5)
	-- Optional Parameters
	,@DistributorID VARCHAR(10)  
		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT
		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMTabTeam_2025

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMTabTeam_2025
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 198215
						,@LocaleCode = 'es-ES'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

VERSIONS
----------------------------------------------------------------------------------
1		2024-02-27	JonathanO	Intitial
1.0.1	2024-08-08	JuanGue		BRD V5 September Double Bonus column added
1.0.2	2024-11-26	JuanGue		New qualifications added to the API
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
			WQ.PK_Distributor,
			ISNULL(WE.Q01,0) AS Q01,	
			ISNULL(WE.Q02,0) AS Q02,	 
			ISNULL(WE.Q03,0) AS Q03,		
			ISNULL(WE.Q04,0) AS Q04,	 
			ISNULL(WE.Q05,0) AS Q05,		
			ISNULL(WE.Q06,0) AS Q06,		
			ISNULL(WE.Q07,0) AS Q07,		
			ISNULL(WE.Q08,0) AS Q08,	
			ISNULL(WE.Q09,0) AS Q09,		
			ISNULL(WE.Q10,0) AS Q10,		
			ISNULL(WE.Q11,0) AS Q11,	 
			ISNULL(WE.Q12,0) AS Q12,	
			ISNULL(WE.Q13,0) AS Q13,	 
			ISNULL(WE.Q14,0) AS Q14,	 
			ISNULL(WE.Q15,0) AS Q15,	 
			ISNULL(WE.Q16,0) AS Q16,	

			 WQ.SPQualDate
	
			,WQ.TeamFreeze
			,WQ.TVPJanDec25
			,WQ.ROsJanDec25

			,WQ.[New DS Bonus]		
			,WQ.[New SP Bonus]		
			,WQ.[New ASP Bonus]	
			,WQ.[New PM Bonus]		
			,WQ.[Double March Bonus]
			,WQ.[Double September Bonus]
		FROM WRK_NAMTabTeam_2025 WQ	WITH (NOLOCK)
			LEFT JOIN [Event].[DSQual]	WE	WITH (NOLOCK)	
		ON
			WE.PK_Distributor = WQ.PK_Distributor AND WE.PK_Event = @PK_Event
		WHERE
			WQ.PK_Distributor = @PK_Distributor


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