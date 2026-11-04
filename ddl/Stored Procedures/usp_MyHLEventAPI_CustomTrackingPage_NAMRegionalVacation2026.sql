CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMRegionalVacation2026]
	-- Mandatory parameters
	@PK_Event INT = 201581
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
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMRegionalVacation2026

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMRegionalVacation2026
					 	 @DistributorID = N'10Y0732854'
					 	,@PK_Event = 201581
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
1	2025-01-28	alejandramed	Intitial
2	2025-02-28	alejandramed	Including contributors
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


	-- Variables for json values
	DECLARE
		@Parameters NVARCHAR(MAX)
		--General
		,@Step INT
		,@Reset BIT
		,@CleanUp BIT  
		,@iCurrentDate INT
		,@Countries VARCHAR(MAX)  
		,@ConvertionsAllowed BIT
		,@TeamFreezeDate INT
		,@NewWTStart INT
		,@NewWTEnd INT

		--Double Bonus 
		,@DoubleVolumeBonusMonth INT
		,@DoubleVolumeBonusLimit MONEY
		,@DoubleVolumeBonusApplicableQuals NVARCHAR(50)
		,@DoubleVolumeBonusMetricType  NVARCHAR(50)
		,@DoubleVolumeBonusActive BIT
		,@DoubleVolumeBonusCOP NVARCHAR(50)

		--New FQS Bonus 
		,@FQSQualDateStart INT 
		,@FQSQualDateEnd INT 
		,@FQSBonusApplicableQuals NVARCHAR(50) 
		,@FQSBonusMetricType  NVARCHAR(50)
		,@FQSBonusActive BIT
		,@FQSFreezeCutDays INT
		,@FQSBonus MONEY

		--New DS Bonus  	 
		,@DSBonusAppDateStart INT 
		,@DSBonusAppDateEnd INT 
		,@DSBonusApplicableQuals NVARCHAR(50) 
		,@DSBonusMetricType  NVARCHAR(50)
		,@DSBonusActive BIT
		,@DSFreezeCutDays INT
		,@DSBonus MONEY

		--New (PM) Preferred Member Bonus  
		,@PMBonusAppDateStart INT  
		,@PMBonusAppDateEnd INT  
		,@PMBonusApplicableQuals NVARCHAR(50) 
		,@PMBonusMetricType  NVARCHAR(50)
		,@PMBonusActive BIT
		,@PMFreezeCutDays INT
		,@PMBonus MONEY

		--New ASP Bonus 	  
		,@RecognitionMonthStart INT
		,@RecognitionMonthEnd INT
		,@QualifiersLevelSubEvents VARCHAR(10)
		,@ASPPromoID INT
		,@ASPBonusApplicableQuals NVARCHAR(50) 
		,@ASPBonusMetricType  NVARCHAR(50)
		,@ASPBonusActive BIT
		,@ASPBonus MONEY

		--Double bonus
		,@FQSDoubleBonusMonth INT  
		,@DSDoubleBonusMonth INT  
		,@PMDoubleBonusMonth INT  
		,@ASPDoubleBonusMonth INT
		,@DoubleBonusApplicableQuals NVARCHAR(50) 
		,@DoubleBonusMetricType  NVARCHAR(50)
		,@DoubleBonusActive BIT

	SELECT @Parameters = [Parameters] FROM [Shared].[QualsExecParams] WITH (NOLOCK) WHERE PK_Event = @PK_Event

	-- Getting parameters values for json
	SELECT  
		@PK_Event = g.pkEvent, 
		@CleanUp = g.cleanUp, 
		@Step = g.step,
		@Reset = g.[reset],
		@iCurrentDate =  FORMAT(g.currentDate, 'yyyyMMdd'),
		@Countries = g.countries,
		@ConvertionsAllowed = g.convertionsAllowed,
		@TeamFreezeDate = g.[teamFreezeDate],
		@NewWTStart = g.[newWTStart],
		@NewWTEnd = g.[newWTEnd],

		--Double bonus 
		@DoubleVolumeBonusMonth = g.[doubleVolumeMonth],
		@DoubleVolumeBonusLimit = g.[doubleVolumeLimit],
		@DoubleVolumeBonusApplicableQuals = g.[doubleVolumeApplicableQuals],
		@DoubleVolumeBonusMetricType = g.[doubleVolumeMetricType],
		@DoubleVolumeBonusActive = g.[doubleVolumeActive],
		@DoubleVolumeBonusCOP = g.[doubleVolumeBonusCOP],

		--New FQS Bonus
		@FQSQualDateStart = g.newFQSQualDateStart,
		@FQSQualDateEnd = g.newFQSQualDateEnd,
		@FQSBonusApplicableQuals = g.newFQSApplicableQuals,
		@FQSBonusMetricType = g.newFQSMetricType,
		@FQSBonusActive = g.newFQSActive,
		@FQSFreezeCutDays = g.[newFQSfreezeCutDays],
		@FQSBonus = g.[newFQSBonus],

		--New DS Bonus  	 
		@DSBonusAppDateStart = g.newDSAppDateStart, 
		@DSBonusAppDateEnd = g.newDSAppDateEnd, 
		@DSBonusApplicableQuals = g.newDSApplicableQuals,
		@DSBonusMetricType = g.newDSMetricType,
		@DSBonusActive = g.newDSActive,
		@DSFreezeCutDays = g.[newDSfreezeCutDays],
		@DSBonus = g.[newDSBonus],

		--New (PM) Preferred Member Bonus  
		@PMBonusAppDateStart = g.newPMAppDateStart, 
		@PMBonusAppDateEnd = g.newPMAppDateEnd, 
		@PMBonusApplicableQuals = g.newPMApplicableQuals,
		@PMBonusMetricType = g.newPMMetricType,
		@PMBonusActive = g.newPMActive,
		@PMFreezeCutDays = g.[newPMfreezeCutDays],
		@PMBonus = g.[newPMBonus],

		--New ASP Bonus 	  
		@RecognitionMonthStart = g.recognitionMonthStart,
		@RecognitionMonthEnd = g.recognitionMonthEnd,
		@QualifiersLevelSubEvents = g.qualifiersLevelSubEvents,
		@ASPPromoID = g.aspPromoID,
		@ASPBonusApplicableQuals = g.aspApplicableQuals,
		@ASPBonusMetricType = g.newASPMetricType,
		@ASPBonusActive = g.newASPActive,
		@ASPBonus = g.[newASPBonus],

		--Double bonus
		@FQSDoubleBonusMonth =  g.doubleBonusNewFQSMonth,
		@DSDoubleBonusMonth = g.doubleBonusNewDSMonth,
		@PMDoubleBonusMonth = g.doubleBonusNewPMMonth,
		@ASPDoubleBonusMonth = g.doubleBonusNewASPMonth,
		@DoubleBonusApplicableQuals = g.doubleBonusApplicableQuals, 
		@DoubleBonusMetricType = g.doubleBonusMetricType,
		@DoubleBonusActive = g.[doubleBonusActive]

	FROM OPENJSON(@Parameters)
	WITH (
			pkEvent INT '$.pkEvent',
			cleanUp BIT '$.cleanUp', 
			step INT '$.step',
			[reset] BIT '$.reset',
			currentDate DATE '$.currentDate',
			countries  VARCHAR(MAX)  '$.countries',
			convertionsAllowed BIT '$.convertionsAllowed',
			teamFreezeDate INT '$.teamFreezeDate',
			newWTStart INT '$.newWTStart',
			newWTEnd INT '$.newWTEnd',
			-- Double bonus 
			[doubleVolumeMonth] INT '$.doubleVolume_month',
			[doubleVolumeLimit] MONEY '$.doubleVolume_limit',
			[doubleVolumeApplicableQuals] NVARCHAR(50) '$.doubleVolume_applicableQuals',
			[doubleVolumeMetricType]  NVARCHAR(50) '$.doubleVolume_metricType',
			[doubleVolumeActive] BIT '$.doubleVolume_active',
			[doubleVolumeBonusCOP] NVARCHAR(50) '$.doubleVolume_cop',
		-- New FQS
			newFQSQualDateStart INT '$.newFQS_qualDateStart',
			newFQSQualDateEnd INT '$.newFQS_qualDateEnd',
			newFQSApplicableQuals NVARCHAR(50) '$.newFQS_applicableQuals',
			[newFQSMetricType]  NVARCHAR(50) '$.newFQS_metricType',
			[newFQSActive] BIT '$.newFQS_active',
			[newFQSfreezeCutDays] INT '$.newFQS_freezeCutDays',
			[newFQSBonus] MONEY '$.newFQS_bonus',
			
		--New DS
			newDSAppDateStart INT '$.newDS_appDateStart',
			newDSAppDateEnd INT '$.newDS_appDateEnd',
			newDSApplicableQuals NVARCHAR(50) '$.newDS_applicableQuals',
			[newDSMetricType]  NVARCHAR(50) '$.newDS_metricType',
			[newDSActive] BIT '$.newDS_active',
			[newDSfreezeCutDays] INT '$.newDS_freezeCutDays',
			[newDSBonus] MONEY '$.newDS_bonus',

		--New PM
			newPMAppDateStart INT '$.newPM_appDateStart',
			newPMAppDateEnd INT '$.newPM_appDateEnd',
			newPMApplicableQuals NVARCHAR(50) '$.newPM_applicableQuals',
			[newPMMetricType]  NVARCHAR(50) '$.newPM_metricType',
			[newPMActive] BIT '$.newPM_active',
			[newPMfreezeCutDays] INT '$.newPM_freezeCutDays',
			[newPMBonus] MONEY '$.newPM_bonus',

		--New ASP
			recognitionMonthStart  INT '$.newASP_recognitionMonthStart',
			recognitionMonthEnd INT '$.newASP_recognitionMonthEnd',
			qualifiersLevelSubEvents NVARCHAR(50) '$.newASP_qualifiersLevelSubEvents',
			aspPromoID INT '$.newASP_aspPromoID',
			aspApplicableQuals NVARCHAR(50) '$.newASP_applicableQuals',
			[newASPMetricType]  NVARCHAR(50) '$.newASP_metricType',
			[newASPActive] BIT '$.newASP_active',
			[newASPBonus] MONEY '$.newASP_bonus',

		--Double bonus
			doubleBonusNewFQSMonth  INT '$.doubleBonus_newFQSMonth', 
			doubleBonusNewDSMonth  INT '$.doubleBonus_newDSMonth', 
			doubleBonusNewPMMonth  INT '$.doubleBonus_newPMMonth', 
			doubleBonusNewASPMonth  INT '$.doubleBonus_newASPMonth', 
			doubleBonusApplicableQuals NVARCHAR(50) '$.doubleBonus_applicableQuals', 
			doubleBonusMetricType NVARCHAR(50) '$.doubleBonus_metricType', 
			[doubleBonusActive] BIT '$.doubleBonus_active' 
	) AS g
	
	-- Default values
	SET @PK_Event = IIF(@PK_Event IS NULL,201581, @PK_Event)
	SET @CleanUp = ISNULL(@CleanUp,1)
	SET @Step = IIF(@Step IS NULL,11, @Step)
	SET @iCurrentDate = IIF(@iCurrentDate IS NULL, FORMAT(GETUTCDATE(), 'yyyyMMdd'), @iCurrentDate)

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
					,dSPQualDate			datetime2   	
					,[New DS Bonus] MONEY DEFAULT 0
					,[TotalNewDS] INT DEFAULT 0
					,[New FQS Bonus] MONEY DEFAULT 0
					,[TotalNewFQS] INT DEFAULT 0
					,[New ASP Bonus] MONEY DEFAULT 0
					,[TotalNewASP] INT DEFAULT 0
					,[New PM Bonus] MONEY DEFAULT 0
					,[TotalNewPM] INT DEFAULT 0
					,[DoubleBonus] MONEY DEFAULT 0
					,[DoubleVolume] MONEY DEFAULT 0
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
					,E01				BIT DEFAULT 0 
					,E02				BIT DEFAULT 0 
					,E03				BIT DEFAULT 0 

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
				TV MONEY,
				RO MONEY
			)


			;WITH 
			cte_TV AS
				(				 
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_26004_DSPoints]  AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'TV' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
					GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				),
			cte_RO AS
				( 
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_26004_DSPoints]  AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'RO' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
					GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				) 
							   				 
			INSERT INTO #DSVolume([PK_Distributor],[RoyaltyMonth],[TV],[RO])
				SELECT 
					D.[PK_Distributor],
					D.dMonth AS [RoyaltyMonth],
				 	IIF(D.dMonth < DS.dSPQualDate, 0,ISNULL(IIF(TV.Points < 0,0, ROUND(TV.Points,2)),0)) AS [TV],
					ISNULL(IIF(RO.Points < 0,0, ROUND(RO.Points,2)),0) AS [RO] 
				FROM #DSMonths AS D
					INNER JOIN #DS AS DS
						ON D.PK_Distributor = DS.PK_Distributor
				LEFT JOIN cte_TV AS TV
					ON D.PK_Distributor = TV.PK_Distributor AND TV.RoyaltyMonth = D.iMonth
				LEFT JOIN cte_RO  AS RO 
					ON D.PK_Distributor = RO.PK_Distributor AND RO.RoyaltyMonth = D.iMonth
				 

			;WITH 
				cte_Quals AS (
						SELECT Q.PK_Distributor,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,E01,E02,E03
							FROM   [Event].[DSQual] AS Q WITH (NOLOCK)
							WHERE Q.PK_Event = @PK_Event AND Q.PK_Distributor = @PK_Distributor 
					)
				,cte_double_volume AS (
						SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
						FROM [dbo].[WRK_26004_DSPoints]  AS P WITH(NOLOCK) 
						WHERE P.MetricType = 'TV' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event AND P.RoyaltyMonth = @DoubleVolumeBonusMonth
						GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
					)
			
			INSERT INTO #DSDetails([PK_Distributor],[DistributorID],[DSSubTeam],dSPQualDate,[sCountryCode],[New DS Bonus],[TotalNewDS],[New FQS Bonus],[TotalNewFQS],[New ASP Bonus],[TotalNewASP],[New PM Bonus],[TotalNewPM],[DoubleBonus],[DoubleVolume],Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,E01,E02,E03)
			SELECT  
			D.nDistributorID AS [PK_Distributor],
			D.sDistributorID AS [DistributorID],							
			D.sSubteam AS [DSSubTeam],
			D.dSupervisorqualification AS dSPQualDate,    
			D.sDistributorCountryProcessingCode AS [sCountryCode],
			ISNULL(B.[New DS Bonus],0)		AS [New DS Bonus],
			ISNULL(B.TotalNewDS,0)		AS [TotalNewDS],
			ISNULL(B.[New FQS Bonus],0)	AS [New FQS Bonus],
			ISNULL(B.[TotalNewFQS],0)	AS [TotalNewFQS],
			ISNULL(B.[New ASP Bonus],0)	AS [New ASP Bonus],
			ISNULL(B.[TotalNewASP],0)	AS [TotalNewASP],
			ISNULL(B.[New PM Bonus],0)	AS [New PM Bonus],
			ISNULL(B.[TotalNewPM],0)	AS [TotalNewPM],
			ISNULL(B.[DoubleBonus],0)	AS [DoubleBonus],
			IIF(d.sDistributorCountryProcessingCode IN ( SELECT CAST([value] AS CHAR(2)) AS [cop] FROM STRING_SPLIT(@DoubleVolumeBonusCOP,',')), IIF(@DoubleVolumeBonusActive = 1, IIF(ISNULL(DV.Points,0) >= @DoubleVolumeBonusLimit, @DoubleVolumeBonusLimit,ISNULL(DV.Points,0)),0.0),0.0)  AS [DoubleVolume],
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
			IIF(Q.E01 = 1,1,0) AS [E01],
			IIF(Q.E02 = 1,1,0) AS [E02],
			IIF(Q.E03 = 1,1,0) AS [E03]
			FROM  dbo.v_Distributor AS D
				INNER JOIN cte_Quals AS Q
					ON D.nDistributorID = Q.PK_Distributor
				LEFT JOIN [dbo].[WRK_26004_BonusSummary] AS B WITH (NOLOCK)
					ON D.nDistributorID = B.PK_Distributor
				LEFT JOIN cte_double_volume AS DV WITH (NOLOCK)
					ON D.nDistributorID = DV.PK_Distributor
			WHERE nDistributorID = @PK_Distributor

		DROP TABLE IF EXISTS #params_values

			SELECT 
			@PK_Event							[PK_Event],
			@CleanUp							[CleanUp],
			@Step								[Step],
			@Reset								[reset],
			@iCurrentDate						[iCurrentDate],
			@Countries							[Countries],
			@ConvertionsAllowed					[ConvertionsAllowed],
			@TeamFreezeDate						[TeamFreezeDate],
			@NewWTStart							[NewWTStart],
			@NewWTEnd							[NewWTEnd],

			--Double bonus						
			@DoubleVolumeBonusMonth				[DoubleVolumeBonusMonth],
			@DoubleVolumeBonusLimit				[DoubleVolumeBonusLimit],
			@DoubleVolumeBonusApplicableQuals	[DoubleVolumeBonusApplicableQuals],
			@DoubleVolumeBonusMetricType		[DoubleVolumeBonusMetricType],
			@DoubleVolumeBonusActive			[DoubleVolumeBonusActive],
			--FQS Bonus							
			@FQSQualDateStart					[FQSQualDateStart],
			@FQSQualDateEnd						[FQSQualDateEnd],
			@FQSBonusApplicableQuals			[FQSBonusApplicableQuals],
			@FQSBonusMetricType					[FQSBonusMetricType],
			@FQSBonusActive						[FQSBonusActive],
			@FQSFreezeCutDays					[FQSFreezeCutDays],
			@FQSBonus							[FQSBonus],
			--New DS Bonus  	 				
			@DSBonusAppDateStart 				[DSBonusAppDateStart], 
			@DSBonusAppDateEnd 					[DSBonusAppDateEnd], 
			@DSBonusApplicableQuals				[DSBonusApplicableQuals],
			@DSBonusMetricType					[DSBonusMetricType],
			@DSBonusActive						[DSBonusActive],
			@DSFreezeCutDays					[DSFreezeCutDays],
			@DSBonus							[DSBonus],
			--New (PM) Preferred Member Bonus  	
			@PMBonusAppDateStart  				[PMBonusAppDateStart],  
			@PMBonusAppDateEnd  				[PMBonusAppDateEnd],  
			@PMBonusApplicableQuals				[PMBonusApplicableQuals],
			@PMBonusMetricType					[PMBonusMetricType],
			@PMBonusActive						[PMBonusActive],
			@PMFreezeCutDays					[PMFreezeCutDays],
			@PMBonus							[PMBonus],
			--New ASP Bonus 	  				
			@RecognitionMonthStart				[RecognitionMonthStart],
			@RecognitionMonthEnd				[RecognitionMonthEnd],
			@QualifiersLevelSubEvents			[QualifiersLevelSubEvents],
			@ASPPromoID							[ASPPromoID],
			@ASPBonusApplicableQuals			[ASPBonusApplicableQuals],
			@ASPBonusMetricType					[ASPBonusMetricType],
			@ASPBonusActive						[ASPBonusActive],
			@ASPBonus							[ASPBonus],
			--Double bonus
			@FQSDoubleBonusMonth				[FQSDoubleBonusMonth], 
			@DSDoubleBonusMonth  				[DSDoubleBonusMonth],   
			@PMDoubleBonusMonth  				[PMDoubleBonusMonth],   
			@ASPDoubleBonusMonth				[ASPDoubleBonusMonth], 
			@DoubleBonusApplicableQuals			[DoubleBonusApplicableQuals], 
			@DoubleBonusMetricType				[DoubleBonusMetricType],
			@DoubleBonusActive					[DoubleBonusActive]
			INTO #params_values

			SELECT 
				[PK_Event],
				[CleanUp],
				[Step],
				[reset],
				[iCurrentDate],
				[Countries],
				[ConvertionsAllowed],
				[TeamFreezeDate],
				[NewWTStart],
				[NewWTEnd],

		
				[DoubleVolumeBonusMonth],
				[DoubleVolumeBonusLimit],
				[DoubleVolumeBonusApplicableQuals],
				[DoubleVolumeBonusMetricType],
				[DoubleVolumeBonusActive],
		
				[FQSQualDateStart],
				[FQSQualDateEnd],
				[FQSBonusApplicableQuals],
				[FQSBonusMetricType],
				[FQSBonusActive],
				[FQSFreezeCutDays],
				[FQSBonus],
		
				[DSBonusAppDateStart], 
				[DSBonusAppDateEnd], 
				[DSBonusApplicableQuals],
				[DSBonusMetricType],
				[DSBonusActive],
				[DSFreezeCutDays],
				[DSBonus],
		
				[PMBonusAppDateStart],  
				[PMBonusAppDateEnd],  
				[PMBonusApplicableQuals],
				[PMBonusMetricType],
				[PMBonusActive],
				[PMFreezeCutDays],
				[PMBonus],
		
				[RecognitionMonthStart],
				[RecognitionMonthEnd],
				[QualifiersLevelSubEvents],
				[ASPPromoID],
				[ASPBonusApplicableQuals],
				[ASPBonusMetricType],
				[ASPBonusActive],
				[ASPBonus],
		
				[FQSDoubleBonusMonth], 
				[DSDoubleBonusMonth],   
				[PMDoubleBonusMonth],   
				[ASPDoubleBonusMonth], 
				[DoubleBonusApplicableQuals], 
				[DoubleBonusMetricType],
				[DoubleBonusActive]
			FROM #params_values

			SELECT  
				[PK_Distributor]
				,[DistributorID]							
				,[DSSubTeam]
				,[dSPQualDate]
				,[sCountryCode]
				,[New DS Bonus]
				,[TotalNewDS]
				,[New FQS Bonus]
				,[TotalNewFQS]
				,[New ASP Bonus]
				,[TotalNewASP]
				,[New PM Bonus]
				,[TotalNewPM]
				,[DoubleBonus]
				,[DoubleVolume]
				,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,E01,E02,E03
			FROM #DSDetails

			SELECT 
				PK_Distributor
				,RoyaltyMonth
				,TV
				,RO
			FROM #DSVolume

			DROP TABLE IF EXISTS #ContributorsDetails

			CREATE TABLE #ContributorsDetails
			(
				PK_DSDownline BIGINT,
				[ContributorID] VARCHAR(25),
				[ContributorName] VARCHAR(250),
				[ContributionType] VARCHAR(10),
				[ContributionMonth] DATE
			)

			INSERT INTO #ContributorsDetails(PK_DSDownline,[ContributorID],[ContributorName],[ContributionType],[ContributionMonth])
			SELECT 
				c.PK_DSDownline, 
				d.sDistributorID AS [ContributorID],
				CONCAT(d.sFirstName,SPACE(1),d.sLastName) AS [ContributorName],
				'NewASP' AS [ContributionType],
				CAST(CAST((ContributionMonth * 100) + 01 AS varchar(10)) AS date) AS [ContributionMonth]
			FROM [dbo].[WRK_26004_NewASPBonusContributors] AS c WITH (NOLOCK) 
				INNER JOIN v_Distributor AS d
					ON c.PK_DSDownline = d.nDistributorID
			WHERE Active = 1 AND PK_Distributor = @PK_Distributor
			UNION
			SELECT 
				c.PK_DSDownline, 
				d.sDistributorID AS [ContributorID],
				CONCAT(d.sFirstName,SPACE(1),d.sLastName) AS [ContributorName],
				'NewDS' AS [ContributionType],
				CAST(CAST((ContributionMonth * 100) + 01 AS varchar(10)) AS date) AS [ContributionMonth]
			FROM [dbo].[WRK_26004_NewDSBonusContributors] AS c WITH (NOLOCK) 
				INNER JOIN v_Distributor AS d
					ON c.PK_DSDownline = d.nDistributorID
			WHERE Active = 1 AND PK_Distributor = @PK_Distributor
			UNION
			SELECT 
				c.PK_DSDownline, 
				d.sDistributorID AS [ContributorID],
				CONCAT(d.sFirstName,SPACE(1),d.sLastName) AS [ContributorName],
				'NewFQS' AS [ContributionType],
				CAST(CAST((ContributionMonth * 100) + 01 AS varchar(10)) AS date) AS [ContributionMonth]
			FROM [dbo].[WRK_26004_NewFQSBonusContributors] AS c WITH (NOLOCK) 
				INNER JOIN v_Distributor AS d
					ON c.PK_DSDownline = d.nDistributorID
			WHERE Active = 1 AND PK_Distributor = @PK_Distributor
			UNION 
			SELECT 
				c.PK_DSDownline, 
				d.sDistributorID AS [ContributorID],
				CONCAT(d.sFirstName,SPACE(1),d.sLastName) AS [ContributorName],
				'NewPM' AS [ContributionType],
				CAST(CAST((ContributionMonth * 100) + 01 AS varchar(10)) AS date) AS [ContributionMonth]
			FROM [dbo].[WRK_26004_NewPMBonusContributors] AS c WITH (NOLOCK) 
				INNER JOIN v_Distributor AS d
					ON c.PK_DSDownline = d.nDistributorID
			WHERE Active = 1 AND PK_Distributor = @PK_Distributor

		SELECT PK_DSDownline,[ContributorID],[ContributorName],[ContributionType],[ContributionMonth] FROM #ContributorsDetails
 
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