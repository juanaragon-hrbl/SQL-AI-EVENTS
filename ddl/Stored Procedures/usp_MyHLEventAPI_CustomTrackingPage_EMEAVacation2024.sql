CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_EMEAVacation2024]
	-- Mandatory parameters
	 @PK_Event INT = 195906
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
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_EMEAVacation2024

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_EMEAVacation2024
					 	 @DistributorID = N'36005114'
					 	,@PK_Event = 195906
						,@LocaleCode = 'en-US'
						,@Error = @e OUTPUT  -- @e must be defined in the local call   
						,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
1	2023-01-06	alejandramed	Intitial
2	2023-07-14	alejandramed	BRD v2
2	2024-03-04	alejandramed	BRD v5
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
	DECLARE @EMEACountries VARCHAR(MAX) = 'AU,BE,BA,BC,BG,HR,CY,CZ,DA,FI,FR,MK,GE,GH,HE,HU,IC,EI,IS,IT,LB,LT,MT,YO,WA,NL,NO,PL,PO,MD,RO,SR,SK,SI,SF,SP,WZ,SW,SZ,TU,UA,UK,ZM,LG,LH,EE,AM,GG,AZ'

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
					,sCountryCode		CHAR(5)
					,VacationBonus		INT DEFAULT 0
					,TotalStars		INT DEFAULT 0
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

			DROP TABLE IF EXISTS #Countries

			CREATE TABLE #Countries
			(
				nCountryID		int,   
				sCountryCode	varchar(10), 
				sCountryCodeISO varchar(10), 
				sCountryName	varchar(150)
			)

			INSERT INTO #Countries(nCountryID,sCountryCode,sCountryCodeISO,sCountryName) 
				SELECT nCountryID,sCountryCode,sCountryCodeISO,sCountryName
				FROM dbo.v_Countries
				WHERE sCountryCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar](@EMEACountries, ','))
				
			DROP TABLE IF EXISTS #DSVolume

			CREATE TABLE #DSVolume
			(
				PK_Distributor			INT,
				RoyaltyMonth			DATETIME,
				TV_WW					MONEY,
				TV_EMEA					MONEY,
				[TV_EMEA_Exception]		MONEY,
				[TV_Baltic]				MONEY,
				TV_OutOfEMEA			MONEY,
				RO_WW					MONEY,
				RO_EMEA					MONEY,
				[RO_EMEAException]		MONEY,
				[RO_Baltic]				MONEY,
				RO_OutOfEMEA			MONEY

			)

			;WITH 
			cte_TV_WW AS
			(
				SELECT 
					P.PK_Distributor,
					P.RoyaltyMonth,
					P.MetricType, 
					SUM(Points) AS [Points] 
				FROM [Event].[DSPoints] AS P WITH (NOLOCK)
				WHERE P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event AND P.MetricType = 'TV' AND P.PK_Country = 12
				GROUP BY P.PK_Distributor,
					P.RoyaltyMonth, 
					P.MetricType

			),
			cte_TV_EMEA AS
			(
				SELECT 
						P.PK_Distributor,
						P.RoyaltyMonth,
						P.MetricType, 
						SUM(Points) AS [Points] 
					FROM [Event].[DSPoints] AS P WITH (NOLOCK)
						INNER JOIN #Countries AS c
							ON P.PK_Country = c.nCountryID
					WHERE P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event AND P.MetricType = 'TV'  
					GROUP BY P.PK_Distributor,
						P.RoyaltyMonth, 
						P.MetricType
			),
			cte_TV_EMEAException AS
			(
				SELECT 
						P.PK_Distributor,
						P.RoyaltyMonth,
						P.MetricType, 
						SUM(Points) AS [Points] 
					FROM [Event].[DSPoints] AS P WITH (NOLOCK)
						INNER JOIN #Countries AS c
							ON P.PK_Country = c.nCountryID
					WHERE P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event AND P.MetricType = 'TV'  AND c.sCountryCodeISO NOT IN ('EE','LV','LT')  --Latvia, Lithuania, Estonia

					GROUP BY P.PK_Distributor,
						P.RoyaltyMonth, 
						P.MetricType
			),
			cte_TV_Baltic AS
			(
				SELECT 
						P.PK_Distributor,
						P.RoyaltyMonth,
						P.MetricType, 
						SUM(Points) AS [Points] 
					FROM [Event].[DSPoints] AS P WITH (NOLOCK)
						INNER JOIN #Countries AS c
							ON P.PK_Country = c.nCountryID
					WHERE P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event AND P.MetricType = 'TV'  AND c.sCountryCodeISO IN ('EE','LV','LT')  --Latvia, Lithuania, Estonia

					GROUP BY P.PK_Distributor,
						P.RoyaltyMonth, 
						P.MetricType
			),
			cte_TV_OutOfEMEA AS
			(
				SELECT 
					w.PK_Distributor,
					w.RoyaltyMonth,
					w.MetricType, 
					w.Points - ISNULL(e.Points,0) AS [Points] 
				FROM cte_TV_WW AS w
					LEFT JOIN cte_TV_EMEA AS e
						ON w.PK_Distributor = e.PK_Distributor AND w.RoyaltyMonth = e.RoyaltyMonth AND  w.MetricType = e.MetricType   
			),
			cte_RO_WW AS
			(
				SELECT 
					P.PK_Distributor,
					P.RoyaltyMonth,
					P.MetricType, 
					SUM(Points) AS [Points] 
				FROM [Event].[DSPoints] AS P WITH (NOLOCK)
					LEFT JOIN #Countries AS c
						ON P.PK_Country = c.nCountryID
				WHERE P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event AND P.MetricType = 'RO'  AND P.PK_Country = 12 
				GROUP BY P.PK_Distributor,
					P.RoyaltyMonth, 
					P.MetricType
			),
			cte_RO_EMEA AS
			(
				SELECT 
						P.PK_Distributor,
						P.RoyaltyMonth,
						P.MetricType, 
						SUM(Points) AS [Points] 
					FROM [Event].[DSPoints] AS P WITH (NOLOCK)
						INNER JOIN #Countries AS c
							ON P.PK_Country = c.nCountryID
					WHERE P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event AND P.MetricType = 'RO'  
					GROUP BY P.PK_Distributor,
						P.RoyaltyMonth, 
						P.MetricType
			),
			cte_RO_EMEAException AS
			(
				SELECT 
						P.PK_Distributor,
						P.RoyaltyMonth,
						P.MetricType, 
						SUM(Points) AS [Points] 
					FROM [Event].[DSPoints] AS P WITH (NOLOCK)
						INNER JOIN #Countries AS c
							ON P.PK_Country = c.nCountryID
					WHERE P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event AND P.MetricType = 'RO'  AND c.sCountryCodeISO NOT IN ('EE','LV','LT')  --Latvia, Lithuania, Estonia

					GROUP BY P.PK_Distributor,
						P.RoyaltyMonth, 
						P.MetricType
			),
			cte_RO_Baltic AS
			(
				SELECT 
						P.PK_Distributor,
						P.RoyaltyMonth,
						P.MetricType, 
						SUM(Points) AS [Points] 
					FROM [Event].[DSPoints] AS P WITH (NOLOCK)
						INNER JOIN #Countries AS c
							ON P.PK_Country = c.nCountryID
					WHERE P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event AND P.MetricType = 'RO'  AND c.sCountryCodeISO IN ('EE','LV','LT')  --Latvia, Lithuania, Estonia

					GROUP BY P.PK_Distributor,
						P.RoyaltyMonth, 
						P.MetricType
			),
			cte_RO_OutOfEMEA AS
			(
				SELECT 
					w.PK_Distributor,
					w.RoyaltyMonth,
					w.MetricType, 
					w.Points - ISNULL(e.Points,0) AS [Points] 
				FROM cte_RO_WW AS w
					LEFT JOIN cte_RO_EMEA AS e
						ON w.PK_Distributor = e.PK_Distributor AND w.RoyaltyMonth = e.RoyaltyMonth AND  w.MetricType = e.MetricType  
			)
			 
							   				 
			INSERT INTO #DSVolume([PK_Distributor],[RoyaltyMonth],[TV_WW],[TV_EMEA],[TV_EMEA_Exception],[TV_Baltic],[TV_OutOfEMEA],[RO_WW],[RO_EMEA],[RO_OutOfEMEA],[RO_EMEAException],[RO_Baltic])
				SELECT 
					D.[PK_Distributor],
					D.dMonth AS [RoyaltyMonth],
					ISNULL(IIF(TV_WW.Points < 0,0, ROUND(TV_WW.Points,2)),0) AS [TV_WW],
					ISNULL(IIF(TV_EMEA.Points < 0,0, ROUND(TV_EMEA.Points,2)),0) AS [TV_EMEA],
					ISNULL(IIF(TV_EMEAException.Points < 0,0, ROUND(TV_EMEAException.Points,2)),0) AS [TV_EMEAException],
					ISNULL(IIF(TV_Baltic.Points < 0,0, ROUND(TV_Baltic.Points,2)),0) AS [TV_Baltic],
					ISNULL(IIF(TV_OutOfEMEA.Points < 0,0, ROUND(TV_OutOfEMEA.Points,2)),0) AS [TV_OutOfEMEA],
					ISNULL(IIF(RO_WW.Points < 0,0, ROUND(RO_WW.Points,2)),0) AS [RO_WW],
					ISNULL(IIF(RO_EMEA.Points < 0,0, ROUND(RO_EMEA.Points,2)),0) AS [RO_EMEA], 
					ISNULL(IIF(RO_OutOfEMEA.Points < 0,0, ROUND(RO_OutOfEMEA.Points,2)),0) AS [RO_OutOfEMEA],
					ISNULL(IIF(RO_EMEAException.Points < 0,0, ROUND(RO_EMEAException.Points,2)),0) AS [RO_EMEAException],
					ISNULL(IIF(RO_Baltic.Points < 0,0, ROUND(RO_Baltic.Points,2)),0) AS [RO_Baltic]
				FROM #DSMonths AS D
				LEFT JOIN cte_TV_WW AS TV_WW
					ON D.PK_Distributor = TV_WW.PK_Distributor AND TV_WW.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_TV_EMEA  AS TV_EMEA 
					ON D.PK_Distributor = TV_EMEA.PK_Distributor AND TV_EMEA.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_TV_EMEAException  AS TV_EMEAException  
					ON D.PK_Distributor = TV_EMEAException.PK_Distributor AND TV_EMEAException.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_TV_Baltic  AS TV_Baltic  
					ON D.PK_Distributor = TV_Baltic.PK_Distributor AND TV_Baltic.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_TV_OutOfEMEA AS TV_OutOfEMEA
					ON D.PK_Distributor = TV_OutOfEMEA.PK_Distributor AND TV_OutOfEMEA.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_RO_WW AS RO_WW
					ON D.PK_Distributor = RO_WW.PK_Distributor AND RO_WW.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_RO_EMEA  AS RO_EMEA 
					ON D.PK_Distributor = RO_EMEA.PK_Distributor AND RO_EMEA.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_RO_OutOfEMEA AS RO_OutOfEMEA
					ON D.PK_Distributor = RO_OutOfEMEA.PK_Distributor AND RO_OutOfEMEA.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_RO_EMEAException AS RO_EMEAException 
					ON D.PK_Distributor = RO_EMEAException .PK_Distributor AND RO_EMEAException .RoyaltyMonth = D.iMonth
				LEFT JOIN cte_RO_Baltic AS RO_Baltic 
					ON D.PK_Distributor = RO_Baltic .PK_Distributor AND RO_Baltic .RoyaltyMonth = D.iMonth

			;WITH 
				cte_Quals AS (
						SELECT Q.PK_Distributor,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26
							FROM   [Event].[DSQual] AS Q WITH (NOLOCK)
							WHERE Q.PK_Event = @PK_Event AND Q.PK_Distributor = @PK_Distributor 
					)
				 
			INSERT INTO #DSDetails([PK_Distributor],[DistributorID],[DSSubTeam],[sCountryCode],[VacationBonus],TotalStars,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26)
			SELECT  
			D.nDistributorID AS [PK_Distributor],
			D.sDistributorID AS [DistributorID],							
			D.sSubteam AS [DSSubTeam],
			D.sDistributorCountryProcessingCode AS [sCountryCode],
			ISNULL(B.[Bonus],0)  AS [VacationBonus],
			ISNULL(B.[TotalStars],0)  AS [TotalStars], --> Total stars is considering only Guaranteed Stars Contributions due the commitment day is on 2025
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
			IIF(Q.Q26 = 1,1,0) AS [Q26]
			FROM  dbo.v_Distributor AS D
				INNER JOIN cte_Quals AS Q
					ON D.nDistributorID = Q.PK_Distributor
				LEFT JOIN [dbo].[WRK_24009_DSDownlinesBonusSummary] AS B WITH (NOLOCK)
					ON D.nDistributorID = B.PK_Distributor
			WHERE nDistributorID = @PK_Distributor

			SELECT  
				PK_Distributor	
				,DistributorID  
				,DSSubTeam	
				,sCountryCode
				,[VacationBonus]
				,TotalStars
				,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26
			FROM #DSDetails

			SELECT 
				PK_Distributor
				,RoyaltyMonth
				,[TV_WW]
				,[TV_EMEA]
				,[TV_EMEA_Exception]
				,[TV_Baltic]
				,[TV_OutOfEMEA]
				,[RO_WW]
				,[RO_EMEA]
				,[RO_EMEAException]
				,[RO_Baltic]
				,[RO_OutOfEMEA]
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

 