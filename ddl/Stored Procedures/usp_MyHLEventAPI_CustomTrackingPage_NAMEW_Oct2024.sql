CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMEW_Oct2024]
	-- Mandatory parameters
	 @PK_Event INT = 200492
	,@LocaleCode CHAR(5)
	-- Optional Parameters
	,@DistributorID VARCHAR(10) 
	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT
	-- QA/DEV
	,@IsDevQA SMALLINT = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMEW_Oct2024

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMEW_Oct2024
					 	 @DistributorID = N'090583839'
					 	,@PK_Event = 200492
						,@LocaleCode = 'es-ES'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 0

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

VERSIONS
----------------------------------------------------------------------------------
1		2024-07-16		JuanGue			Intitial
2		2024-07-31		alejandramed	Bug 1356519: 24086 - Missing PPC points in different months
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

			IF (@IsDevQA = 2) THROW 60000, N'Unit test Error', 1;

			/* SET THE VALUES FOR THE DECLARED VARIABLES */

			SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
			SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
			SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event


			IF @IsDevQA = 0 AND OBJECT_ID (N'WRK_24086_NAM_EW_Oct_2024', N'U') IS NOT NULL
			BEGIN

				SELECT	
					WE.PK_Distributor,

					WE.Q01,	WE.Q02,	WE.Q03,	WE.Q04,	
					WE.Q05,	WE.Q06,	WE.Q07,	WE.Q08,
					WE.Q09,	WE.Q10,	WE.Q11,	WE.Q12,
					WE.Q13,	WE.Q14,	WE.Q15,	WE.Q16,
					WE.Q17,	WE.Q18,	WE.Q19,	WE.Q20,
					WE.Q21,	WE.Q22,	WE.Q23,	WE.Q24,	
					WE.Q25,	WE.Q26,	WE.Q27,	WE.Q28,
					WE.Q29,	WE.Q30,	WE.Q31,
					WE.E01,	WE.E02,	WE.E03,	WE.E04,	
					WE.E05,	WE.E06,	WE.E07,	WE.E08,
					WE.E09,	WE.E10,	WE.E11,	WE.E12,
					WE.E13,	WE.E14,	WE.E15,	WE.E16,
					WE.E17,	WE.E18,

					 WQ.dSPQualDate

					,WQ.IsFromList				

					,WQ.TVPJul24	 
					,WQ.TVPAug24	 
					,WQ.TVPSep24
	
					,WQ.PCJul24	 
					,WQ.PCAug24	 
					,WQ.PCSep24	 
	
					,WQ.PPVJul24	 
					,WQ.PPVAug24	 
					,WQ.PPVSep24	 
	
					,WQ.[New DS Bonus]  
					,WQ.[New FQS Bonus] 
					,WQ.[New ASP Bonus] 
					,WQ.[New PM Bonus]  
					,WQ.[Double Volume Month] 	
				FROM
					Event.DSQual				WE	WITH (NOLOCK)
				INNER JOIN
					WRK_24086_NAM_EW_Oct_2024	WQ	WITH (NOLOCK)
				ON
					WE.PK_Distributor = WQ.PK_Distributor
				AND
					WE.PK_Distributor = @PK_Distributor
				AND
					WE.PK_Event = @PK_Event

			END

		END -- Body
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