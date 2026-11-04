CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_AUNZVacation2026]
	 @PK_Event INT = 203361
	,@LocaleCode CHAR(5)
	,@DistributorID VARCHAR(10) = ''
	,@Error INT = 0 OUTPUT
	,@ErrorMessage VARCHAR(4000) = '' OUTPUT
	,@IsDevQA TINYINT = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_AUNZVacation2026

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_AUNZVacation2026
					 	 @DistributorID = N'05Y0121606'
					 	,@PK_Event = 203361
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
1.0.0		2025-06-17		puertac		Intitial

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


		SELECT W.PK_Distributor, COPFreeze, IsAddedFromLists, IsFQSNonTABFreeze, IsGETMillFreeze, IsPTFreeze, Total_ROCOP, Total_ROWW, Total_TVP, Local_VacationPoints, WW_VacationPoints
			  ,FirstTimerBonus, HPLBonus, MarchBonus, MayBonus, Total_BonusesOnly, Total_Local, Total_WW
			  ,Q.Q01, Q.Q02, Q.Q03, Q.Q04, Q.Q05, Q.Q06, Q.Q07, Q.Q08, Q.Q09, Q.Q10, Q.Q11, Q.Q12, Q.Q13, Q.Q14, Q.Q15, Q.Q16, Q.Q17, Q.Q18
			  ,Q.E01, Q.E02, Q.E03, Q.E04, Q.E05
		FROM dbo.WRK_AUNZVacation2026 AS W WITH (NOLOCK)
		LEFT JOIN dbo.WRK_DSQual AS Q WITH (NOLOCK)
			ON Q.PK_Event = @PK_Event
			AND W.PK_Distributor = Q.PK_Distributor
		WHERE W.PK_Distributor = @PK_Distributor


		SELECT PK_Distributor, RoyaltyMonth, ROWW, ROCOP, TVP	
		FROM dbo.WRK_AUNZVacation2026_Points AS W WITH (NOLOCK)
		WHERE PK_Distributor = @PK_Distributor

		
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