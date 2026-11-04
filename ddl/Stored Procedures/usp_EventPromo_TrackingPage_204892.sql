CREATE PROCEDURE [dbo].[usp_EventPromo_TrackingPage_204892]
	 @PK_Event INT = 204892
	,@LocaleCode CHAR(5)
	,@DistributorID VARCHAR(10)
	,@Error INT = 0 OUTPUT
	,@ErrorMessage VARCHAR(4000) = '' OUTPUT
	,@IsDevQA TINYINT = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_EventPromo_TrackingPage_204892

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_EventPromo_TrackingPage_204892
					 	 @DistributorID = '05Y0103449'--N'05Y0007754'
					 	,@PK_Event = 204892
						,@LocaleCode = 'en-AU'
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
1.0.0		2025-11-10		jairli		Intitial
2.0.0       2026-03-01      jairli        BRD V2
2.1.0       2026-06-08      jairli      BUG1460163 Tracker in the vacations points section is not properly accounting for Bonus volume

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
	--------------------------------------------------------------------------------				
	DECLARE @AccVP MONEY 			
	DECLARE @AccTVP MONEY 			
	DECLARE @AccRO MONEY 		
	DECLARE @TotalFebBonus MONEY 
	--------------------------------------------------------------------------------
	BEGIN TRY

		IF @IsDevQA= 2 THROW 60000, N'Unit test Error', 1;

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

		-- Getting processed volume points
		DROP TABLE IF EXISTS #VolumePoints;

		SELECT PK_Distributor, RoyaltyMonth, TVP, RO
		, SUM(TVP) OVER (PARTITION BY PK_Distributor ORDER BY RoyaltyMonth) as AccTVP	
		, SUM(RO) OVER (PARTITION BY PK_Distributor ORDER BY RoyaltyMonth) as AccRO	
		, CASE WHEN CAST(CONVERT(varchar(6), CONVERT(DATE,RoyaltyMonth), 112) AS int) = CAST(CONVERT(varchar(6), CONVERT(DATE,TP.PeriodStartDate), 112) AS int) THEN IIF(TVP > VPBonusFactor, VPBonusFactor, TVP) END TotalFebBonus	
		INTO #VolumePoints 
		FROM Promo.[ProcessedVolume] AS W WITH (NOLOCK)
		LEFT JOIN [Promo].[TargetByPattern] AS TP WITH (NOLOCK) ON W.PK_Event = TP.PK_Event
			AND VPBonusFactor > 0
		WHERE PK_Distributor = @PK_Distributor
		AND W.PK_Event = @PK_Event
		ORDER BY RoyaltyMonth

		CREATE INDEX IX_#VolumePoints_PK ON #VolumePoints (PK_Distributor,RoyaltyMonth) INCLUDE (AccTVP,AccRO);

		-- Getting QIds and SubEvent flags
		DROP TABLE IF EXISTS #DSQual;

		SELECT ISNULL(Q.PK_Event,@PK_Event) as PK_Event,D.PK_Distributor
		,MAX(CASE WHEN Q.QId = 01 THEN Q.IsQualified ELSE 0 END) AS Q01
		,MAX(CASE WHEN Q.QId = 02 THEN Q.IsQualified ELSE 0 END) AS Q02
		,MAX(CASE WHEN Q.QId = 03 THEN Q.IsQualified ELSE 0 END) AS Q03
		,MAX(CASE WHEN Q.QId = 04 THEN Q.IsQualified ELSE 0 END) AS Q04
		,MAX(CASE WHEN Q.QId = 05 THEN Q.IsQualified ELSE 0 END) AS Q05
		,MAX(CASE WHEN Q.QId = 06 THEN Q.IsQualified ELSE 0 END) AS Q06
		,MAX(CASE WHEN Q.QId = 07 THEN Q.IsQualified ELSE 0 END) AS Q07
		,MAX(CASE WHEN Q.QId = 08 THEN Q.IsQualified ELSE 0 END) AS Q08
		,MAX(CASE WHEN Q.QId = 09 THEN Q.IsQualified ELSE 0 END) AS Q09
		,MAX(CASE WHEN Q.QId = 10 THEN Q.IsQualified ELSE 0 END) AS Q10
		,MAX(CASE WHEN Q.QId = 11 THEN Q.IsQualified ELSE 0 END) AS Q11
		,MAX(CASE WHEN Q.QId = 12 THEN Q.IsQualified ELSE 0 END) AS Q12
		,MAX(CASE WHEN Q.QId = 13 THEN Q.IsQualified ELSE 0 END) AS Q13
		,MAX(CASE WHEN Q.QId = 14 THEN Q.IsQualified ELSE 0 END) AS Q14
		,MAX(CASE WHEN Q.QId = 15 THEN Q.IsQualified ELSE 0 END) AS Q15
		,MAX(CASE WHEN Q.QId = 16 THEN Q.IsQualified ELSE 0 END) AS Q16
		,MAX(CASE WHEN Q.QId = 17 THEN Q.IsQualified ELSE 0 END) AS Q17
		,MAX(CASE WHEN Q.QId = 18 THEN Q.IsQualified ELSE 0 END) AS Q18
		,MAX(CASE WHEN Q.QId = 19 THEN Q.IsQualified ELSE 0 END) AS Q19
		,MAX(CASE WHEN Q.QId = 20 THEN Q.IsQualified ELSE 0 END) AS Q20
		,MAX(CASE WHEN Q.QId = 21 THEN Q.IsQualified ELSE 0 END) AS Q21
		,MAX(CASE WHEN S.SubEvent = 1 THEN 1 ELSE 0 END) AS [E01]
		,MAX(CASE WHEN S.SubEvent = 2 THEN 1 ELSE 0 END) AS [E02]
		,MAX(CASE WHEN S.SubEvent = 3 THEN 1 ELSE 0 END) AS [E03]
		,MAX(CASE WHEN S.SubEvent = 4 THEN 1 ELSE 0 END) AS [E04]
		,MAX(CASE WHEN S.SubEvent = 5 THEN 1 ELSE 0 END) AS [E05]
		,MAX(CASE WHEN S.SubEvent = 6 THEN 1 ELSE 0 END) AS [E06]
		,MAX(CASE WHEN S.SubEvent = 7 THEN 1 ELSE 0 END) AS [E07]
		,MAX(CASE WHEN S.SubEvent = 8 THEN 1 ELSE 0 END) AS [E08]
		,MAX(CASE WHEN S.SubEvent = 9 THEN 1 ELSE 0 END) AS [E09]
		,MAX(CASE WHEN S.SubEvent = 10 THEN 1 ELSE 0 END) AS [E10]
		,MAX(CASE WHEN S.SubEvent = 11 THEN 1 ELSE 0 END) AS [E11]
		INTO #DSQual
		FROM Promo.dimDistributor AS D (NOLOCK)
		LEFT JOIN Promo.DSQual AS Q WITH(NOLOCK) 
			ON D.PK_Distributor = Q.PK_Distributor
			AND Q.PK_Event = @PK_Event
		LEFT JOIN Promo.DSSubEvent AS S WITH (NOLOCK)
			ON  S.PK_Event  = Q.PK_Event
			AND S.PK_Distributor = Q.PK_Distributor 
		WHERE   D.PK_Distributor = @PK_Distributor
		GROUP BY Q.PK_Event,D.PK_Distributor

		CREATE INDEX IX_#DSQual_PK ON #DSQual (PK_Distributor);

		-- Set Total Volume Points
		SELECT 
			 @AccVP = MAX(AccTVP)+MAX(AccRO)+MAX(ISNULL(TotalFebBonus,0))
			,@AccTVP  = MAX(AccTVP)
			,@AccRO = MAX(AccRO)
			,@TotalFebBonus = MAX(TotalFebBonus)
		FROM #VolumePoints


		---- First result set
		SELECT 
			PK_Event,PK_Distributor,@AccRO AS TotalRO,@AccTVP AS TotalTVP, @AccVP AS TotalVP, @TotalFebBonus AS TotalFebBonus,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10,E11
		FROM #DSQual


		---- Second result set
		SELECT 
			PK_Distributor,RoyaltyMonth,TVP,RO
		FROM #VolumePoints
				
		
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