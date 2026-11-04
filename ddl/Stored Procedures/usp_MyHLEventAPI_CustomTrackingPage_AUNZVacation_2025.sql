CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_AUNZVacation_2025]
	-- Mandatory parameters
	@PK_Event INT = 199208
	,@LocaleCode CHAR(5)
	,@DistributorID VARCHAR(10) 

	-- Error Parameters
	,@Error int = 0  OUTPUT
	,@ErrorMessage varchar(4000) = ''  OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS 
BEGIN
/******************************************************************************
OBJECT:			[dbo].[usp_MyHLEventAPI_CustomTrackingPage_AUNZVacation_2025]

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_AUNZVacation_2025
					 	 @DistributorID = N'09189611' 
					 	,@PK_Event = 199208
						,@LocaleCode = 'en-US'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 0

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
1	2024-06-06	alejandramed	Initial
2	2024-07-30	alejandramed	25007 - AU NZ Vacation 2025 (QP Jan 2024 - Dec 2024) - Umbraco Custom Data V2
3	2024-07-31	alejandramed	Bug 1356520: 25007 - AU NZ Vac 2025 - V2 API Total Points
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

		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1
		END

		/* SET THE VALUES FOR THE DECLARED VARIABLES */

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

----------------------------------------------------------------------------------------------------

	DECLARE 
				@iStartDate int,
				@dStartDate datetime,
				@iEndDate int,
				@dEndDate datetime

			SELECT 
				@iStartDate = CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int), 
				@dStartDate = MIN(dStartDate),
				@iEndDate = CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int),
				@dEndDate = MAX(dEndDate)
			FROM [Event].[SetupEventQualification] WITH (NOLOCK) 
			WHERE PK_Event = @PK_Event
			GROUP BY PK_Event

			DROP TABLE IF EXISTS #DSMonths

			SELECT 
				@PK_Distributor AS [PK_Distributor],
				@PK_Event AS [PK_Event],
				CAST(CONVERT(varchar(6), SD.MyDate, 112) AS int) AS [iMonth],
				SD.MyDate AS [dMonth]
			INTO #DSMonths
			FROM dbo.SourceDate AS SD WITH (NOLOCK) 
			WHERE SD.MyDate BETWEEN @dStartDate AND @dEndDate

			DROP TABLE IF EXISTS #DSDetails

			CREATE TABLE #DSDetails      
			(      
					  PK_Distributor		INT
					,DistributorID		VARCHAR(10)
					,DSSubTeam			CHAR(5)
					,SCountryCode		CHAR(5)
					,Achieved40KTVP BIT DEFAULT 0
					,[TVP_Acc]  	MONEY DEFAULT 0
					,[RoyaltyOverrides_Global_Acc] 	MONEY DEFAULT 0
					,[RoyaltyOverrides_Local_Acc] 	MONEY DEFAULT 0
					,[VacationPoints_Acc] 	MONEY DEFAULT 0
					,[April Double Bonus Month] 	MONEY DEFAULT 0
					,[August Double Bonus Month] 	MONEY DEFAULT 0 
					,[Total Vacation Points]	MONEY DEFAULT 0
					,Q01				BIT DEFAULT 0
					,Q02				BIT DEFAULT 0
					,Q03				BIT DEFAULT 0
					,Q04				BIT DEFAULT 0
					,Q05				BIT DEFAULT 0
					,Q06				BIT DEFAULT 0
					,Q07				BIT DEFAULT 0
					,Q08				BIT DEFAULT 0
					,Q09				BIT DEFAULT 0
					,Q10				BIT DEFAULT 0
					,Q11				BIT DEFAULT 0
					,Q12				BIT DEFAULT 0
					,Q13				BIT DEFAULT 0
					,Q14				BIT DEFAULT 0
					,Q15				BIT DEFAULT 0
					,Q16				BIT DEFAULT 0
					,Q17				BIT DEFAULT 0
					,Q18				BIT DEFAULT 0
					,Q19				BIT DEFAULT 0
					,Q20				BIT DEFAULT 0
					,Q21				BIT DEFAULT 0
			)  
			
			DROP TABLE IF EXISTS #DS

			CREATE TABLE #DS
			(
				PK_Distributor		int,   
				DSCurrentTeam		varchar(10),        
				DSSubTeam			varchar(10),        
				DSSPTeam			varchar(10),               
				dSPQualDate			datetime2,        
				CountryCode			varchar(5),
				nCountryID			int,
				IsFromList			bit default(0),
				IsTicketPurchaser	bit default(0)
			)

			INSERT INTO #DS
			(
				PK_Distributor,	
				DSCurrentTeam,	
				DSSubTeam,		
				DSSPTeam,			
				dSPQualDate,		
				CountryCode,
				nCountryID
			)
			SELECT DISTINCT        
			D.nDistributorID AS PK_Distributor,   
			CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
			D.sSubteam AS DSSubTeam,        
			D.sType AS DSSPTeam,            
			D.dSupervisorqualification AS dSPQualDate,        
			D.sDistributorCountryProcessingCode AS CountryCode,
			D.nDistributorCountryProcessingID AS nCountryID
			FROM        
			dbo.v_Distributor AS D  
			WHERE        
				D.sDistributorID = @DistributorID

			DROP TABLE IF EXISTS #DSVolume

			CREATE TABLE #DSVolume
			(
				PK_Distributor INT,
				RoyaltyMonth DATETIME,
				[TVP] MONEY,
				[RoyaltyOverrides_Global]	MONEY,
				[RoyaltyOverrides_Local]	MONEY,
				[VacationPoints]	MONEY 
			)


			;WITH cte_TV_Local AS
			(
				SELECT 
					PK_Distributor,
					PK_Event,
					PK_Country,
					RoyaltyMonth,
					MetricType,
					Points 
				FROM [dbo].[WRK_25007_DSPoints] AS r WITH (NOLOCK)
			WHERE r.MetricType = 'TV' AND r.PK_Distributor = @PK_Distributor 
	 		),		 
			cte_RO_Global AS
			(
				SELECT 
					r.PK_Distributor,
					r.PK_Event,
					r.PK_Country,
					r.RoyaltyMonth,
					MetricType,
					Points 
				FROM #DS AS d
					INNER JOIN [dbo].[WRK_25007_DSPoints] AS r WITH (NOLOCK)
						ON d.PK_Distributor = r.PK_Distributor
				WHERE r.MetricType = 'RO' AND r.PK_Country = 12 AND r.PK_Distributor = @PK_Distributor 
			),
			cte_RO_Local AS
			(
				SELECT 
						r.PK_Distributor,
						r.PK_Event,
						r.PK_Country,
						r.RoyaltyMonth,
						MetricType,
						r.Points AS Points 
				FROM #DS AS d
					INNER JOIN [dbo].[WRK_25007_DSPoints] AS r WITH (NOLOCK)
						ON d.PK_Distributor = r.PK_Distributor AND d.nCountryID = r.PK_Country
				WHERE r.MetricType = 'RO' AND r.PK_Country != 12 AND r.PK_Distributor = @PK_Distributor 
			),
			cte_VP AS
			(
				SELECT 
					PK_Distributor,
					PK_Event,
					PK_Country,
					RoyaltyMonth,
					MetricType,
					Points 
				FROM [dbo].[WRK_25007_DSPoints] AS r WITH (NOLOCK)
				WHERE r.MetricType = 'VP' AND r.PK_Distributor = @PK_Distributor 
			)

			INSERT INTO #DSVolume([PK_Distributor],[RoyaltyMonth],[TVP],[RoyaltyOverrides_Global],[RoyaltyOverrides_Local],[VacationPoints])
				SELECT 
					D.[PK_Distributor],
					D.dMonth AS [RoyaltyMonth],
					ISNULL(IIF(TV.Points < 0,0, ROUND(TV.Points,2)),0) AS [TVP],
					ISNULL(IIF(ROG.Points < 0,0, ROUND(ROG.Points,2)),0) AS [RoyaltyOverrides_Global],
					ISNULL(IIF(ROL.Points < 0,0, ROUND(ROL.Points,2)),0) AS [RoyaltyOverrides_Local],
					ISNULL(IIF(VP.Points < 0,0, ROUND(VP.Points,2)),0) AS [VacationPoints] 
				FROM #DSMonths AS D
				LEFT JOIN cte_TV_Local AS TV
					ON D.PK_Distributor = TV.PK_Distributor AND TV.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_RO_Global  AS ROG 
					ON D.PK_Distributor = ROG.PK_Distributor AND ROG.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_RO_Local AS ROL
					ON D.PK_Distributor = ROL.PK_Distributor AND ROL.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_VP AS VP
					ON D.PK_Distributor = VP.PK_Distributor AND VP.RoyaltyMonth = D.iMonth
 
			;WITH 
				cte_Quals AS (
						SELECT Q.PK_Distributor,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q50 
							FROM   [Event].[DSQual] AS Q WITH (NOLOCK)
							WHERE Q.PK_Event = @PK_Event AND Q.PK_Distributor = @PK_Distributor 
					),
					cte_acc AS
					(
						SELECT 
							PK_Distributor,
							SUM([TVP]) AS [TVP_Acc],
							SUM([RoyaltyOverrides_Global]) AS [RoyaltyOverrides_Global_Acc],
							SUM([RoyaltyOverrides_Local]) AS [RoyaltyOverrides_Local_Acc],
							SUM([VacationPoints]) AS [VacationPoints_Acc]
						FROM #DSVolume
						GROUP BY [PK_Distributor]
					),cte_bonuses AS
					(
						SELECT 
							PK_Distributor,
							SUM([April Double Bonus Month]) AS [April Double Bonus Month],
							SUM([August Double Bonus Month]) AS [August Double Bonus Month]
						FROM [dbo].[WRK_25007_BonusSummary] WITH (NOLOCK) WHERE PK_Distributor = @PK_Distributor
						GROUP BY PK_Distributor
					) 
			
			INSERT INTO #DSDetails([PK_Distributor],
					[DistributorID],
					[DSSubTeam],
					[sCountryCode],
					Achieved40KTVP,
					[TVP_Acc],
					[RoyaltyOverrides_Global_Acc],
					[RoyaltyOverrides_Local_Acc],
					[VacationPoints_Acc],
					[April Double Bonus Month], 
					[August Double Bonus Month], 
					[Total Vacation Points], 
					Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21)
			SELECT  
			D.nDistributorID AS [PK_Distributor],
			D.sDistributorID AS [DistributorID],							
			D.sSubteam AS [DSSubTeam],
			D.sDistributorCountryProcessingCode AS [sCountryCode],
			Q50 AS Achieved40KTVP,
			acc.[TVP_Acc],
			acc.[RoyaltyOverrides_Global_Acc],
			acc.[RoyaltyOverrides_Local_Acc],
			acc.[VacationPoints_Acc],
			B.[April Double Bonus Month],
			B.[August Double Bonus Month],
			acc.[VacationPoints_Acc] + B.[April Double Bonus Month] + B.[August Double Bonus Month] AS [Total Vacation Points],			 
			IIF(Q.Q01 = 1,1,0) AS [Q1],
			IIF(Q.Q02 = 1,1,0) AS [Q2],
			IIF(Q.Q03 = 1,1,0) AS [Q3],
			IIF(Q.Q04 = 1,1,0) AS [Q4],
			IIF(Q.Q05 = 1,1,0) AS [Q5],
			IIF(Q.Q06 = 1,1,0) AS [Q6],
			IIF(Q.Q07 = 1,1,0) AS [Q7],
			IIF(Q.Q08 = 1,1,0) AS [Q8],
			IIF(Q.Q09 = 1,1,0) AS [Q9],
			IIF(Q.Q10 = 1,1,0) AS [Q10],
			IIF(Q.Q11 = 1,1,0) AS [Q11],
			IIF(Q.Q12 = 1,1,0) AS [Q12],
			IIF(Q.Q13 = 1,1,0) AS [Q13],
			IIF(Q.Q14 = 1,1,0) AS [Q14],
			IIF(Q.Q15 = 1,1,0) AS [Q15],
			IIF(Q.Q16 = 1,1,0) AS [Q16],
			IIF(Q.Q17 = 1,1,0) AS [Q17],
			IIF(Q.Q18 = 1,1,0) AS [Q18],
			IIF(Q.Q19 = 1,1,0) AS [Q19],
			IIF(Q.Q20 = 1,1,0) AS [Q20],
			IIF(Q.Q21 = 1,1,0) AS [Q21]
			FROM  dbo.v_Distributor AS D
				INNER JOIN cte_Quals AS Q
					ON D.nDistributorID = Q.PK_Distributor
				LEFT JOIN cte_bonuses AS B WITH (NOLOCK)
					ON D.nDistributorID = B.PK_Distributor		
				LEFT JOIN cte_acc AS acc
					ON D.nDistributorID = acc.PK_Distributor
			WHERE nDistributorID = @PK_Distributor

			SELECT  
				[PK_Distributor],
				[DistributorID],
				[DSSubTeam],
				[sCountryCode],
				Achieved40KTVP,
				[TVP_Acc],
				[RoyaltyOverrides_Global_Acc],
				[RoyaltyOverrides_Local_Acc],
				[VacationPoints_Acc],
				[April Double Bonus Month], 
				[August Double Bonus Month], 
				[Total Vacation Points],
				Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21				 
			FROM #DSDetails

			SELECT 
				PK_Distributor
				,RoyaltyMonth
				,[TVP]
				,[RoyaltyOverrides_Global]
				,[RoyaltyOverrides_Local]
				,[VacationPoints]
			FROM #DSVolume
			ORDER BY RoyaltyMonth

	SET @Error = @Error + @@ERROR      
		
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

 