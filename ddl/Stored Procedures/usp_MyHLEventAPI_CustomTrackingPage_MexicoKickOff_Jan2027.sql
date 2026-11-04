CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_MexicoKickOff_Jan2027]
	-- Mandatory parameters
	 @PK_Event INT = 206787
	,@LocaleCode CHAR(5)
	,@DistributorID VARCHAR(10)

	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_MexicoKickOff_Jan2027

USE:	        
				USE PubEventManagement
				GO

				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_MexicoKickOff_Jan2027
					 	 @DistributorID = N'111692619'
					 	,@PK_Event = 206787
						,@LocaleCode = 'es-MX'
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
1	2027-09-10	ChrisGBarham	Intitial  
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
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
					,E20				BIT DEFAULT 0
					,E21				BIT DEFAULT 0
					,E22				BIT DEFAULT 0
					,E23				BIT DEFAULT 0
					,E24				BIT DEFAULT 0
					,E39				BIT DEFAULT 0 
					,E40				BIT DEFAULT 0 

			)  
			
			DROP TABLE IF EXISTS #DS

			CREATE TABLE #DS
			(
				PK_Distributor		int,   
				DSCurrentTeam		varchar(10),        
				DSSubTeam			varchar(10),        
				DSSPTeam			varchar(10),               
				dSPQualDate			datetime2,        
				CountryCode			varchar(5) 
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
			dbo.v_DistributorCurrent AS D   
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

			 
				;WITH cte_WRK_27012_DSPoints AS
				(
					SELECT  
						P.PK_Distributor,
						P.PK_Country,
						P.RoyaltyMonth, 
						CAST(CONVERT(varchar(6), D.dSPQualDate, 112) AS int) AS [iSPQualDate],
						P.MetricType,
						IIF(P.RoyaltyMonth >= CAST(CONVERT(varchar(6), D.dSPQualDate, 112) AS int) AND P.MetricType = 'TV',[Points],0) AS [Points]
					FROM [dbo].[WRK_27012_DSPoints] AS P WITH (NOLOCK)
						INNER JOIN #DS AS D
							ON P.PK_Distributor = D.PK_Distributor
					WHERE D.DSSPTeam = 'SP' 					 
				)
				 		  

				INSERT INTO #Event_DSPoints_Validations(PK_Distributor, PK_Country, RoyaltyMonth, MetricType, [Points])	
				SELECT  
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth,
					P.MetricType,
					SUM(IIF(Points < 0,0, [Points])) AS [Points]
				FROM cte_WRK_27012_DSPoints AS P
				GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth,P.MetricType

			CREATE CLUSTERED INDEX [IX_#Event_DSPoints_Validations_PK_Distributor] ON #Event_DSPoints_Validations ([PK_Distributor]) 
			CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_Validations_MetricType] ON #Event_DSPoints_Validations ([MetricType])

			DROP TABLE IF EXISTS #DSVolume

			CREATE TABLE #DSVolume
			(
				PK_Distributor INT,
				RoyaltyMonth DATETIME,
				[TV] MONEY
			)


			;WITH 
			cte_TV AS
				(				
					--VolumePoints
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_27012_DSPoints] AS P WITH(NOLOCK) 
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
						SELECT Q.PK_Distributor,
							Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10			
							,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20
							,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30
							,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40
							,Q41,Q42,Q43,Q44,Q45,Q46,Q47,Q48,Q49,Q50					
							,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10
							,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20
							,E21,E22,E23,E24,E25,E26,E27,E28,E29,E30
							,E31,E32,E33,E34,E35,E36,E37,E38,E39,E40
							,E41,E42,E43,E44,E45,E46,E47,E48,E49,E50
							FROM   [Event].[DSQual] AS Q WITH (NOLOCK)
							WHERE Q.PK_Event = @PK_Event AND Q.PK_Distributor = @PK_Distributor 
					) 
			
			INSERT INTO #DSDetails([PK_Distributor],[DistributorID]
			,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10			
			,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20
			,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30
			,Q31,Q32,Q33,Q34,Q35,Q36,Q37 
			,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10
			,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20
			,E21,E22,E23,E24,E39,E40)
			SELECT  
			D.nDistributorID AS [PK_Distributor],
			D.sDistributorID AS [DistributorID],							
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
			IIF(Q.E19 = 1,1,0) AS [E19], 
			IIF(Q.E20 = 1,1,0) AS [E20], 
			IIF(Q.E21 = 1,1,0) AS [E21],
			IIF(Q.E22 = 1,1,0) AS [E22], 
			IIF(Q.E23 = 1,1,0) AS [E23], 
			IIF(Q.E24 = 1,1,0) AS [E24], 
			IIF(Q.E39 = 1,1,0) AS [E39], 
			IIF(Q.E40 = 1,1,0) AS [E40]
			FROM  [dbo].[v_DistributorCurrent] AS D
				INNER JOIN cte_Quals AS Q
					ON D.nDistributorID = Q.PK_Distributor
			WHERE nDistributorID = @PK_Distributor

		DROP TABLE IF EXISTS #ASPContributorsCount

			SELECT PK_UL,COUNT(1) ASPContributors 
			INTO #ASPContributorsCount
			FROM dbo.[WRK_27012_1LDownlines] DL (NOLOCK)
			WHERE DL.PK_UL = @PK_Distributor AND  
				IsASPContributor = 1 AND [IsMainID] = 0
			GROUP BY
				PK_UL
					
			DROP TABLE IF EXISTS #SPContributorsCount

			SELECT PK_UL,COUNT(1) SPContributors 
			INTO #SPContributorsCount
			FROM dbo.[WRK_27012_1LDownlines] DL (NOLOCK)
			WHERE DL.PK_UL = @PK_Distributor AND 
				IsSPContributor = 1 AND [IsMainID] = 0
			GROUP BY
				PK_UL

		SELECT PK_Distributor 
			,DSCurrentTeam   
			,DSSubTeam     
			,DSSPTeam           
			,dSPQualDate     
			,CountryCode 
			,ISNULL(asp.ASPContributors,0) AS ASPContributors
			,ISNULL(sp.SPContributors,0) AS SPContributors
		FROM #DS AS d
			LEFT JOIN #ASPContributorsCount AS asp
				ON d.PK_Distributor = asp.PK_UL
			LEFT JOIN #SPContributorsCount AS sp
				ON d.PK_Distributor = sp.PK_UL

		SELECT [PK_Distributor],[DistributorID]
			,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10			
			,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20
			,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30
			,Q31,Q32,Q33,Q34
			,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10
			,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20
			,E21,E39,E40
			FROM #DSDetails 

 		SELECT 
			PK_Distributor
			,RoyaltyMonth
			,[TV] 
		FROM #DSVolume 


	SELECT 
		U.sDistributorID AS UplineID,
		DL.PK_UL AS PK_Upline,
		PK_UL  AS PK_Downline, D.sDistributorID AS [DownlineID]
		,CONCAT(D.sFirstName,SPACE(1), D.sLastName) AS DSName
		,IsASPContributor
		,IsSPContributor
		,[DL_ASPContributionDate]
		,[DL_FreezeSPQualDate] AS [DL_SPQualDate]
		FROM dbo.[WRK_27012_1LDownlines] AS DL WITH (NOLOCK) 
		INNER JOIN v_Distributor AS D WITH (NOLOCK)
				ON DL.PK_DL = D.nDistributorID
		INNER JOIN v_Distributor AS U WITH (NOLOCK)
				ON DL.PK_UL = U.nDistributorID
	WHERE DL.PK_UL = @PK_Distributor
	AND  (IsASPContributor = 1 OR IsSPContributor = 1) 

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

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
	END CATCH
END

