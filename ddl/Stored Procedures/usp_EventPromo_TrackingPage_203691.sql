CREATE PROCEDURE [dbo].[usp_EventPromo_TrackingPage_203691]
	 @PK_Event INT = 203691
	,@LocaleCode CHAR(5)
	,@DistributorID VARCHAR(10) = ''
	,@Error INT = 0 OUTPUT
	,@ErrorMessage VARCHAR(4000) = '' OUTPUT
	,@IsDevQA TINYINT = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_EventPromo_TrackingPage_203691

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_EventPromo_TrackingPage_203691
					 	 @DistributorID = N'W1273756'
					 	,@PK_Event = 203691
						,@LocaleCode = 'es-ES'
						,@Error = @e OUTPUT  
						,@ErrorMessage = @em OUTPUT   
						,@IsDevQA = 0

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	
NOTES:			
DEPENDENCIES
----------------------------------------------------------------------------------

VERSIONS
----------------------------------------------------------------------------------
1.0.0		2025-07-18		rosarioo		Intitial
1.1.0		2026-01-06		rosarioo		Bug 1437247: <203691> - Qualifications data keep loading
2.0.0		2026-04-22		rosarioo		User Story 1443813: 27008 - India Vacation 2027 - BRD V1 - Umbraco Custom tracker + Contributor Table

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	DECLARE @PK_Distributor INT
	DECLARE @PK_Locale INT
	DECLARE @PK_DefaultLocale INT

	BEGIN TRY

		IF @IsDevQA= 2 THROW 60000, N'Unit test Error', 1;

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

		
		SELECT   W.[PK_Distributor]
				,W.[IsFromCOP]	
				,W.[IsAddedFromLists]
				,W.[IsFirstLineRetention]
				,W.[IsAdded_0KAWTBonus]	
				,W.[IsAdded_5KAWTBonus]	
				,W.[IsAdded_15KAWTBonus]	
				,W.[AWTBonus]
				,W.[IsHPLBonusQualifier]
				,W.Total_HPLContributors
				,W.[3K_HPLBonus]
				,W.[5K_HPLBonus]
				,W.[SpecialBonus]
				,W.Total_TVP
				,W.Total_AWTBonus
				,W.Total_SpecialBonus
				,W.Total_VacationsPoints
			  ,Q.Q01, Q.Q02, Q.Q03, Q.Q04, Q.Q05, Q.Q06, Q.Q07,Q.Q08,Q.Q09,Q.Q10,Q.Q11,Q.Q12,Q.Q13,Q.Q14,Q.Q15
			  ,Q.E01, Q.E02, Q.E03, Q.E04
		FROM Promo.[WRK_IndiaVacation2026] AS W WITH (NOLOCK)
		LEFT JOIN dbo.WRK_DSQual AS Q WITH (NOLOCK)
			ON Q.PK_Event = W.PK_Event
			AND W.PK_Distributor = Q.PK_Distributor
		WHERE W.PK_Distributor = @PK_Distributor
		AND (W.PK_Event = @PK_Event OR W.PK_Event IS NULL)

		SELECT PK_Distributor, RoyaltyMonth, TVP	
		FROM Promo.[ProcessedVolume] AS W WITH (NOLOCK)
		WHERE PK_Distributor = @PK_Distributor
		AND PK_Event = @PK_Event
		ORDER BY RoyaltyMonth
		
		

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