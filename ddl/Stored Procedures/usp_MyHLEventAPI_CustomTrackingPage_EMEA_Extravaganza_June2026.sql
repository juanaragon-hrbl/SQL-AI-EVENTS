CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_EMEA_Extravaganza_June2026]
	-- Mandatory parameters
	 @PK_Event INT = 204914
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
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_EMEA_Extravaganza_June2026

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_EMEA_Extravaganza_June2026
					 	 @DistributorID = N'48076813'
					 	,@PK_Event = 204914
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
1	2026-03-23	alejandramed	Intitial 
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
			WHERE PK_Event = @PK_Event AND QualificationNumber <= 50
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
					,Q30				BIT DEFAULT 0
					,Q31				BIT DEFAULT 0
					,Q32				BIT DEFAULT 0
					,Q33				BIT DEFAULT 0 
					,Q34				BIT DEFAULT 0
					,Q35				BIT DEFAULT 0
					,Q36				BIT DEFAULT 0
					,Q37				BIT DEFAULT 0
					,Q38				BIT DEFAULT 0
					,E01				BIT DEFAULT 0
					,E02				BIT DEFAULT 0
					,E03				BIT DEFAULT 0
					,E04				BIT DEFAULT 0
					,E05				BIT DEFAULT 0
					,E06				BIT DEFAULT 0
					,E07				BIT DEFAULT 0
					,E08				BIT DEFAULT 0
					,E09				BIT DEFAULT 0
					,E10				BIT DEFAULT 0
					,E11				BIT DEFAULT 0
					,E12				BIT DEFAULT 0
					,E13				BIT DEFAULT 0
					,E14				BIT DEFAULT 0
					,E15				BIT DEFAULT 0
					,E16				BIT DEFAULT 0
					,E17				BIT DEFAULT 0
					,E18				BIT DEFAULT 0
					,E19				BIT DEFAULT 0

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
 
			DROP TABLE IF EXISTS #DSVolume

			CREATE TABLE #DSVolume
			(
				PK_Distributor INT,
				RoyaltyMonth DATETIME,
				[TV] MONEY,
			)


			;WITH 
			cte_TV AS
				(				
					--VolumePoints
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_26052_DSPoints] AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'TV' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
					GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				) 
							   				 
			INSERT INTO #DSVolume([PK_Distributor],[RoyaltyMonth],[TV])
				SELECT 
					D.[PK_Distributor],
					D.dMonth AS [RoyaltyMonth],
					ISNULL(IIF(TV.Points < 0,0, ROUND(TV.Points,2)),0) AS [TV]
				FROM #DSMonths AS D
				LEFT JOIN cte_TV AS TV
					ON D.PK_Distributor = TV.PK_Distributor AND TV.RoyaltyMonth = D.iMonth
				
			;WITH 
				cte_Quals AS (
						SELECT Q.PK_Distributor,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10,E11,E12,E13,E14,E15,E16,E17,E18,E19
							FROM   [Event].[DSQual] AS Q WITH (NOLOCK)
							WHERE Q.PK_Event = @PK_Event AND Q.PK_Distributor = @PK_Distributor 
					)

			INSERT INTO #DSDetails([PK_Distributor],[DistributorID],[DSSubTeam],[sCountryCode],Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10,E11,E12,E13,E14,E15,E16,E17,E18,E19)
			SELECT  
			D.nDistributorID AS [PK_Distributor],
			D.sDistributorID AS [DistributorID],							
			D.sSubteam AS [DSSubTeam],
			D.sDistributorCountryProcessingCode AS [sCountryCode],			
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
			IIF(Q.Q30 = 1,1,0) AS [Q30],
			IIF(Q.Q31 = 1,1,0) AS [Q31],
			IIF(Q.Q32 = 1,1,0) AS [Q32],
			IIF(Q.Q33 = 1,1,0) AS [Q33],
			IIF(Q.Q34 = 1,1,0) AS [Q34],
			IIF(Q.Q35 = 1,1,0) AS [Q35],
			IIF(Q.Q36 = 1,1,0) AS [Q36],
			IIF(Q.Q37 = 1,1,0) AS [Q37],
			IIF(Q.Q38 = 1,1,0) AS [Q38],
			IIF(Q.E01 = 1,1,0) AS [E01],
			IIF(Q.E02 = 1,1,0) AS [E02],
			IIF(Q.E03 = 1,1,0) AS [E03],
			IIF(Q.E04 = 1,1,0) AS [E04],
			IIF(Q.E05 = 1,1,0) AS [E05],
			IIF(Q.E06 = 1,1,0) AS [E06],
			IIF(Q.E07 = 1,1,0) AS [E07],
			IIF(Q.E08 = 1,1,0) AS [E08],
			IIF(Q.E09 = 1,1,0) AS [E09],
			IIF(Q.E10 = 1,1,0) AS [E10],
			IIF(Q.E11 = 1,1,0) AS [E11],
			IIF(Q.E12 = 1,1,0) AS [E12],
			IIF(Q.E13 = 1,1,0) AS [E13],
			IIF(Q.E14 = 1,1,0) AS [E14],
			IIF(Q.E15 = 1,1,0) AS [E15],
			IIF(Q.E16 = 1,1,0) AS [E16],
			IIF(Q.E17 = 1,1,0) AS [E17],
			IIF(Q.E18 = 1,1,0) AS [E18],
			IIF(Q.E19 = 1,1,0) AS [E19]
			FROM  dbo.v_Distributor AS D
				INNER JOIN cte_Quals AS Q
					ON D.nDistributorID = Q.PK_Distributor
				
			WHERE nDistributorID = @PK_Distributor

			SELECT  
				[PK_Distributor]
				,[DistributorID]							
				,[DSSubTeam]
				,[sCountryCode]
				,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10,E11,E12,E13,E14,E15,E16,E17,E18,E19			
			FROM #DSDetails

			SELECT 
				PK_Distributor
				,RoyaltyMonth
				,[TV]
			FROM #DSVolume
			ORDER BY RoyaltyMonth ASC

				
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

