CREATE PROCEDURE [dbo].[usp_EventPromo_TrackingPage_TaiwanVac2026]
	 @PK_Event INT = 203803 
	,@LocaleCode CHAR(5)
	,@DistributorID VARCHAR(10) = ''
	,@Error INT = 0 OUTPUT
	,@ErrorMessage VARCHAR(4000) = '' OUTPUT
	,@IsDevQA TINYINT = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_EventPromo_TrackingPage_TaiwanVac2026

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_EventPromo_TrackingPage_TaiwanVac2026
					 	 @DistributorID = N'05Y0121606'
					 	,@PK_Event = 203803 
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
1.0.0		2025-07-24		puertac		Intitial

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


		DROP TABLE IF EXISTS #Summary_Quals

		SELECT D.PK_Event
				,D.PK_Distributor
				,SUM(CASE WHEN D.QId = 1  THEN 1 ELSE 0 END) AS Q1
				,SUM(CASE WHEN D.QId = 2  THEN 1 ELSE 0 END) AS Q2
				,SUM(CASE WHEN D.QId = 3  THEN 1 ELSE 0 END) AS Q3
				,SUM(CASE WHEN D.QId = 4  THEN 1 ELSE 0 END) AS Q4
				,SUM(CASE WHEN D.QId = 5  THEN 1 ELSE 0 END) AS Q5
				,SUM(CASE WHEN D.QId = 6  THEN 1 ELSE 0 END) AS Q6
				,SUM(CASE WHEN D.QId = 7  THEN 1 ELSE 0 END) AS Q7
				,SUM(CASE WHEN D.QId = 8  THEN 1 ELSE 0 END) AS Q8
				,SUM(CASE WHEN D.QId = 9  THEN 1 ELSE 0 END) AS Q9
				,SUM(CASE WHEN D.QId = 10 THEN 1 ELSE 0 END) AS Q10
				,SUM(CASE WHEN D.QId = 11 THEN 1 ELSE 0 END) AS Q11
				,SUM(CASE WHEN D.QId = 12 THEN 1 ELSE 0 END) AS Q12
				,SUM(CASE WHEN D.QId = 13 THEN 1 ELSE 0 END) AS Q13
				,SUM(CASE WHEN D.QId = 14 THEN 1 ELSE 0 END) AS Q14
		INTO #Summary_Quals
		FROM Promo.DSQual AS D WITH (NOLOCK)
		WHERE PK_Event = @PK_Event
		AND PK_Distributor = @PK_Distributor
		GROUP BY D.PK_Distributor, D.PK_Event
   						
		CREATE INDEX IX_#Summary_Quals_PK ON #Summary_Quals(PK_Distributor)


		DROP TABLE IF EXISTS #Summary_SubEvents

		SELECT D.PK_Event
				,D.PK_Distributor
				,SUM(CASE WHEN D.SubEvent = 1  THEN 1 ELSE 0 END) AS E1
				,SUM(CASE WHEN D.SubEvent = 2  THEN 1 ELSE 0 END) AS E2
				,SUM(CASE WHEN D.SubEvent = 3  THEN 1 ELSE 0 END) AS E3
				,SUM(CASE WHEN D.SubEvent = 4  THEN 1 ELSE 0 END) AS E4
		INTO #Summary_SubEvents
		FROM Promo.DSSubEvent AS D WITH (NOLOCK)
		WHERE PK_Event = @PK_Event
		AND PK_Distributor = @PK_Distributor
		GROUP BY D.PK_Distributor, D.PK_Event
   						
		CREATE INDEX IX_#Summary_SubEvents_PK ON #Summary_SubEvents(PK_Distributor)


		-- ResultSet 1
		SELECT W.PK_Distributor, IsFQSNonTABFreeze, IsTABFreeze, IsAWT2026, Acc_TVP_JunMay, Acc_TVPCOP_JunMay, Acc_TVP_JunAug, Acc_TVPCOP_JunAug
			  ,ISNULL(Q.Q1,0) AS Q01, ISNULL(Q.Q2,0) AS Q02, ISNULL(Q.Q3,0) AS Q03, ISNULL(Q.Q4,0) AS Q04, ISNULL(Q.Q5,0) AS Q05, ISNULL(Q.Q6,0) AS Q06, ISNULL(Q.Q7,0) AS Q07
			  ,ISNULL(Q.Q8,0) AS Q08, ISNULL(Q.Q9,0) AS Q09, ISNULL(Q.Q10,0) AS Q10, ISNULL(Q.Q11,0) AS Q11, ISNULL(Q.Q12,0) AS Q12, ISNULL(Q.Q13,0) AS Q13, ISNULL(Q.Q14,0) AS Q14
			  ,ISNULL(E.E1,0) AS E01, ISNULL(E.E2,0) AS E02, ISNULL(E.E3,0) AS E03, ISNULL(E.E4,0) AS E04
		FROM Promo.WRK_TaiwanVacation2026 AS W WITH (NOLOCK)
		LEFT JOIN #Summary_Quals AS Q WITH (NOLOCK)
			ON W.PK_Distributor = Q.PK_Distributor
		LEFT JOIN #Summary_SubEvents AS E WITH (NOLOCK)
			ON W.PK_Distributor = E.PK_Distributor
		WHERE W.PK_Distributor = @PK_Distributor


		-- ResultSet2
		SELECT PK_Distributor, RoyaltyMonth, TVP, TVP_COP	
		FROM Promo.ProcessedVolume WITH (NOLOCK)
		WHERE PK_Event = @PK_Event
		AND PK_Distributor = @PK_Distributor

		
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