CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMExtravaganza_Jul2024]
	-- Mandatory parameters
	 @PK_Event INT = 199467
	,@LocaleCode CHAR(5)

	-- Optional Parameters
	,@DistributorID VARCHAR(10)

	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			[dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMExtravaganza_Jul2024]

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMExtravaganza_Jul2024
					 	 @DistributorID = N'10Y0631538'
					 	,@PK_Event = 199467
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
1	2024-04-05	alejandramed	Intitial
2	2024-04-30	alejandramed	Bug 1339681: 24085 - Modify Month Bonus
3	2024-05-09	alejandramed	Bug 1338490: 24085 - NAM Extravaganza - DS outside NAM incorrectly qualifying to E6, E7, E8
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

	DECLARE @DoubleVolumeMonth INT = 202404

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
					,DoubleVolumeEarned	MONEY DEFAULT 0
					,[New DS Bonus]		MONEY DEFAULT 0
					,[TotalNewDS]		INT DEFAULT 0
					,[New FQS Bonus]	MONEY DEFAULT 0
					,[TotalNewFQS]		INT DEFAULT 0
					,[New ASP Bonus]	MONEY DEFAULT 0
					,[TotalNewASP]		INT DEFAULT 0
					,[New PM Bonus]		MONEY DEFAULT 0
					,[TotalNewPM]		INT DEFAULT 0
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
					,Q22				BIT DEFAULT 0
					,Q23				BIT DEFAULT 0
					,Q24				BIT DEFAULT 0
					,Q25				BIT DEFAULT 0
					,Q26				BIT DEFAULT 0
					,Q27				BIT DEFAULT 0
					,Q28				BIT DEFAULT 0
					,Q29				BIT DEFAULT 0
					,Q46				BIT DEFAULT 0
					,Q47				BIT DEFAULT 0

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
				CountryCode
			)
			SELECT DISTINCT        
			D.nDistributorID AS PK_Distributor,   
			CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
			D.sSubteam AS DSSubTeam,        
			D.sType AS DSSPTeam,            
			D.dSupervisorqualification AS dSPQualDate,        
			D.sDistributorCountryProcessingCode AS CountryCode
			FROM        
			dbo.v_Distributor AS D  
			WHERE        
				D.sDistributorID = @DistributorID

			DROP TABLE IF EXISTS #Event_DSPoints_Validations

				CREATE TABLE #Event_DSPoints_Validations
				(
					PK_Distributor INT, 
					PK_Country INT, 
					RoyaltyMonth INT, 
					MetricType VARCHAR(10), 
					[Points] MONEY
				)

				--Below DS
				INSERT INTO #Event_DSPoints_Validations(PK_Distributor, PK_Country, RoyaltyMonth, MetricType, [Points])	
				SELECT  
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					'VP' AS MetricType,
					SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
				FROM [dbo].[WRK_24085_DSPoints]  AS P WITH (NOLOCK)
					INNER JOIN #DS AS D
						ON P.PK_Distributor = D.PK_Distributor
				WHERE P.PK_Event = @PK_Event AND D.DSSPTeam = 'DS' AND P.MetricType IN ('PPV','DLV')				 
				GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth

				--Above QS
				INSERT INTO #Event_DSPoints_Validations(PK_Distributor, PK_Country, RoyaltyMonth, MetricType, [Points])
				SELECT  	
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					'VP' AS MetricType,
					SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
				FROM [dbo].[WRK_24085_DSPoints]  AS P WITH (NOLOCK)
					INNER JOIN #DS AS D
						ON P.PK_Distributor = D.PK_Distributor
				WHERE P.PK_Event = @PK_Event AND D.DSSPTeam = 'SP' AND P.MetricType = 'TV'			 
				GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth

				--PC
				--CA/TT/JM

				INSERT INTO #Event_DSPoints_Validations(PK_Distributor, PK_Country, RoyaltyMonth, MetricType, [Points])
				SELECT 
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					'PC' AS MetricType,
					SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
				FROM [dbo].[WRK_24085_DSPoints]  AS P WITH (NOLOCK)
					INNER JOIN #DS AS D
						ON P.PK_Distributor = D.PK_Distributor
				WHERE P.PK_Event = @PK_Event AND D.DSSPTeam = 'SP' AND D.CountryCode IN ('CA','TT,','JM') AND P.MetricType = 'PPV'			 
				GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth

				--US/PR

				;WITH cte_SPC_PPC AS
				(
					SELECT  
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
					FROM [dbo].[WRK_24085_DSPoints]  AS P WITH (NOLOCK)
						INNER JOIN #DS AS D
							ON P.PK_Distributor = D.PK_Distributor
					WHERE P.PK_Event = @PK_Event AND D.CountryCode IN ('US','PR') AND P.MetricType IN ('SPC','PPC')			 
					GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth
				),
				cte_PM_Points AS
				(
					SELECT
						P.PK_Distributor,
						P.PK_Country,
						P.RoyaltyMonth,
						SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
					FROM [dbo].[WRK_24085_DSPoints]  AS P WITH (NOLOCK)
						INNER JOIN #DS AS D
							ON P.PK_Distributor = D.PK_Distributor
					WHERE P.PK_Event = @PK_Event AND D.CountryCode IN ('US','PR') AND P.MetricType IN ('PM_Points')			 
					GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth
				),
				cte_PC AS
				(
					SELECT 
						c.PK_Distributor,
						c.PK_Country,
						c.RoyaltyMonth,
						c.Points - ISNULL(IIF(p.Points < 0, 0, p.Points) ,0) AS [Points]
					FROM cte_SPC_PPC AS c
						LEFT JOIN cte_PM_Points AS p
							ON p.PK_Distributor = c.PK_Distributor 
								AND p.PK_Country = c.PK_Country 
								AND p.RoyaltyMonth = c.RoyaltyMonth
				)

				INSERT INTO #Event_DSPoints_Validations(PK_Distributor, PK_Country, RoyaltyMonth, MetricType, [Points])
				SELECT  
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					'PC' AS MetricType,
					IIF(Points < 0, 0, [Points]) AS [Points]
				FROM cte_PC AS p



				--PC
				--Out of US/PR/CA/TT/JM

				INSERT INTO #Event_DSPoints_Validations(PK_Distributor, PK_Country, RoyaltyMonth, MetricType, [Points])
				SELECT 
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					'PC' AS MetricType,
					SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
				FROM  [dbo].[WRK_24085_DSPoints] AS P WITH (NOLOCK)
					INNER JOIN #DS AS D
						ON P.PK_Distributor = D.PK_Distributor
				WHERE D.CountryCode NOT IN ('US','PR','CA','TT','JM') AND P.MetricType = 'PPV'			 
				GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth

			CREATE CLUSTERED INDEX [IX_#Event_DSPoints_Validations_PK_Distributor] ON #Event_DSPoints_Validations ([PK_Distributor]) 
			CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_Validations_MetricType] ON #Event_DSPoints_Validations ([MetricType])

			DROP TABLE IF EXISTS #DSVolume

			CREATE TABLE #DSVolume
			(
				PK_Distributor INT,
				RoyaltyMonth DATETIME,
				VolumePoints MONEY,
				PersonalPurchaseVolume	MONEY,
				DownLineVolume	MONEY,
				PPV	MONEY,
				PPC	MONEY,
				SPC	MONEY,
				PC	MONEY
			)


			;WITH 
			cte_TV AS
				(				
					--VolumePoints
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_24085_DSPoints]  AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'TV' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
					GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				),
			cte_DLV AS
				(
					--DownLineVolume
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_24085_DSPoints]  AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'DLV' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
					GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				),
			cte_PPV AS
				(
					--PPV
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_24085_DSPoints]  AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'PPV' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
					GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				),
			cte_PPC AS
				(
					--PPC
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_24085_DSPoints]  AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'PPC' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
					GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				),
			cte_SPC AS
				(
					--SPC
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_24085_DSPoints]  AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'SPC' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
					GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				),
			cte_PC AS
				(
					--PC
					SELECT @PK_Event AS PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM #Event_DSPoints_Validations AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'PC' AND P.PK_Distributor = @PK_Distributor
					GROUP BY P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				)
							   				 
			INSERT INTO #DSVolume([PK_Distributor],[RoyaltyMonth],[VolumePoints],[PersonalPurchaseVolume],[DownLineVolume],[PPC],[SPC],[PC])
				SELECT 
					D.[PK_Distributor],
					D.dMonth AS [RoyaltyMonth],
					ISNULL(IIF(TV.Points < 0,0, ROUND(TV.Points,2)),0) AS [VolumePoints],
					ISNULL(IIF(PPV.Points < 0,0, ROUND(PPV.Points,2)),0) AS [PersonalPurchaseVolume],
					ISNULL(IIF(DLV.Points < 0,0, ROUND(DLV.Points,2)),0) AS [DownLineVolume],
					ISNULL(IIF(PPC.Points < 0,0, ROUND(PPC.Points,2)),0) AS [PPC],
					ISNULL(IIF(SPC.Points < 0,0, ROUND(SPC.Points,2)),0) AS [SPC],
					ISNULL(IIF(PC.Points < 0,0, ROUND(PC.Points,2)),0) AS [PC]
				FROM #DSMonths AS D
				LEFT JOIN cte_TV AS TV
					ON D.PK_Distributor = TV.PK_Distributor AND TV.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_DLV  AS DLV 
					ON D.PK_Distributor = DLV.PK_Distributor AND DLV.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_PPV AS PPV
					ON D.PK_Distributor = PPV.PK_Distributor AND PPV.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_PPC AS PPC
					ON D.PK_Distributor = PPC.PK_Distributor AND PPC.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_SPC AS SPC
					ON D.PK_Distributor = SPC.PK_Distributor AND SPC.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_PC AS PC
					ON D.PK_Distributor = PC.PK_Distributor AND PC.RoyaltyMonth = D.iMonth

			;WITH 
				cte_Quals AS (
						SELECT Q.PK_Distributor,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q46,Q47
							FROM   [Event].[DSQual] AS Q WITH (NOLOCK)
							WHERE Q.PK_Event = @PK_Event AND Q.PK_Distributor = @PK_Distributor 
					)
				,cte_double_volume AS (
						SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
						FROM [dbo].[WRK_24085_DSPoints]  AS P WITH(NOLOCK) 
						WHERE P.MetricType = 'TV' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event AND P.RoyaltyMonth = @DoubleVolumeMonth
						GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
					)
			
			INSERT INTO #DSDetails([PK_Distributor],
					[DistributorID],
					[DSSubTeam],
					[sCountryCode],
					[New DS Bonus],
					[TotalNewDS],
					[New FQS Bonus],
					[TotalNewFQS],
					[New ASP Bonus],
					[TotalNewASP],
					[New PM Bonus],
					[TotalNewPM],
					[DoubleVolumeEarned],Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q46,Q47)
			SELECT  
			D.nDistributorID AS [PK_Distributor],
			D.sDistributorID AS [DistributorID],							
			D.sSubteam AS [DSSubTeam],
			D.sDistributorCountryProcessingCode AS [sCountryCode],
			ISNULL(B.[New DS Bonus] ,0) AS [New DS Bonus],
			ISNULL(B.[TotalNewDS] ,0) AS [TotalNewDS],
			ISNULL(B.[New FQS Bonus] ,0) AS [New FQS Bonus],
			ISNULL(B.[TotalNewFQS] ,0) AS [TotalNewFQS],
			ISNULL(B.[New ASP Bonus] ,0) AS [New ASP Bonus],
			ISNULL(B.[TotalNewASP] ,0) AS [TotalNewASP],
			ISNULL(B.[New PM Bonus] ,0) AS [New PM Bonus],
			ISNULL(B.[TotalNewPM] ,0) AS [TotalNewPM],
			IIF(ISNULL(DV.Points,0) > 2500, 2500,ISNULL(DV.Points,0))  AS [DoubleVolumeEarned],
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
			IIF(Q.Q21 = 1,1,0) AS [Q21],
			IIF(Q.Q22 = 1,1,0) AS [Q22],
			IIF(Q.Q23 = 1,1,0) AS [Q23],
			IIF(Q.Q24 = 1,1,0) AS [Q24],
			IIF(Q.Q25 = 1,1,0) AS [Q25],
			IIF(Q.Q26 = 1,1,0) AS [Q26],
			IIF(Q.Q27 = 1,1,0) AS [Q27],
			IIF(Q.Q28 = 1,1,0) AS [Q28],
			IIF(Q.Q29 = 1,1,0) AS [Q29],
			IIF(Q.Q46 = 1,1,0) AS [Q46],
			IIF(Q.Q47 = 1,1,0) AS [Q47]
			FROM  dbo.v_Distributor AS D
				INNER JOIN cte_Quals AS Q
					ON D.nDistributorID = Q.PK_Distributor
				LEFT JOIN [dbo].[WRK_24085_BonusSummary] AS B WITH (NOLOCK)
					ON D.nDistributorID = B.PK_Distributor
				LEFT JOIN cte_double_volume AS DV WITH (NOLOCK)
					ON D.nDistributorID = DV.PK_Distributor
			WHERE nDistributorID = @PK_Distributor

			SELECT  
				PK_Distributor	
				,DistributorID  
				,DSSubTeam	
				,sCountryCode
				,[DoubleVolumeEarned]
				,[New DS Bonus]
				,[TotalNewDS]
				,[New FQS Bonus]
				,[TotalNewFQS]
				,[New ASP Bonus]
				,[TotalNewASP]
				,[New PM Bonus]
				,[TotalNewPM]
				,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q46,Q47
			FROM #DSDetails

			SELECT 
				PK_Distributor
				,RoyaltyMonth
				,VolumePoints
				,PersonalPurchaseVolume
				,DownLineVolume
				,PPC
				,SPC
				,PC
			FROM #DSVolume

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
