CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_MexicoFSL_May2026]
	-- Mandatory parameters
	 @PK_Event INT = 204657
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
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_MexicoFSL_May2026

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_MexicoFSL_May2026
					 	 @DistributorID = N'11399294'
					 	,@PK_Event = 204657
						,@LocaleCode = 'es-ES'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

VERSIONS
----------------------------------------------------------------------------------
1		2026-02-12			JuanGue			Intitial
1.2.0	2026-02-25			JuanGue			#1442500 Downlines Qs (Q6-Q9) are not retrieving any contributor
1.2.1	2026-03-03			JuanGue			Show ASP Qual Dates
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
			WE.Q21,	WE.Q22,	WE.Q23,	WE.Q24,	WE.Q25,
			WQ.dSPQualDate AS SPQualDate

			,WQ.TVPJan26	           
			,WQ.TVPFeb26	           
			,WQ.TVPMar26	           
			,WQ.TVPApr26	           
			,WQ.TotalTVP
			,WQ.IsTicketPurchaser AS HasTicketAssigned

			,WQ.ASPContributors
			,WQ.SPContributors
		FROM
			Event.DSQual			WE	WITH (NOLOCK)
		INNER JOIN
			dbo.WRK_MexicoFSL_May2026	WQ	WITH (NOLOCK)
		ON
			WE.PK_Distributor = WQ.PK_Distributor
		AND
			WE.PK_Distributor = @PK_Distributor
		AND
			WE.PK_Event = @PK_Event

		SELECT
			 W.PK_UL AS UplinePK_Distributor
			,DU.sDistributorID	AS UplineDistributorID
			,W.PK_DL AS PK_DSDownline
			,DD.sDistributorID AS DownlineID
			,DD.sFirstName AS FirstName
			,DD.sLastName AS LastName
			,DD.sType AS sTypeDL
			,DD.dSupervisorqualification AS SPQualDate
			,DD.sType DSLevel
			,W.DL_Achieved3CM
			,W.[DL_ASPContributionDate] AS [ASP Contribution Date]
			,W.IsASPContributor AS [Counts For ASP Qualification]
		FROM
			WRK_26019_1LDownlines W WITH (NOLOCK)
		INNER JOIN v_Distributor DU
			ON DU.nDistributorID = W.PK_UL
		INNER JOIN v_Distributor DD
			ON DD.nDistributorID = W.PK_DL
		WHERE
			W.PK_UL = @PK_Distributor
		AND 
			DD.sType = 'SP'

		SELECT
			 W.PK_UL AS UplinePK_Distributor
			,DU.sDistributorID	AS UplineDistributorID
			,W.PK_DL AS PK_DSDownline
			,DD.sDistributorID AS DownlineID
			,DD.sFirstName AS FirstName
			,DD.sLastName AS LastName
			,DD.sType AS sTypeDL
			,DD.dSupervisorqualification AS [New SP Contribution Date]
			,DD.sType DSLevel
			,W.IsSPContributor AS [Counts For SP Qualification]
		FROM
			WRK_26019_1LDownlines W WITH (NOLOCK)
		INNER JOIN v_Distributor DU
			ON DU.nDistributorID = W.PK_UL
		INNER JOIN v_Distributor DD
			ON DD.nDistributorID = W.PK_DL
		WHERE
			W.PK_UL = @PK_Distributor
		AND 
			DD.sType = 'SP'
		AND 
			W.IsSPContributor = 1

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