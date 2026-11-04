CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMLDW_Oct2026]
	-- Mandatory parameters
	 @PK_Event INT = 206235
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
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMLDW_Oct2026

USE:	        
				DECLARE @e int, @em varchar(4000)
		
                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMLDW_Oct2026
					 	 @DistributorID = N'48076813'
					 	,@PK_Event = 206235
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
1	2026-01-20	alejandramed	Intitial 
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
		@Step INT, 	
		@CurrentDatetime DATETIME,		
		@PK_Event_Log INT,
		@ExecLog BIT,
		@CleanUpTempData BIT,
		@EligibleCountries VARCHAR(MAX),
		--General
		@ProjectID INT 
		,@Reset BIT  
		,@iCurrentDate INT 
		,@ConvertionsAllowed BIT

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
		,@PMBonusRetailOrderPurposeCode NVARCHAR(50)

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

	DECLARE @Parameters NVARCHAR(MAX)= (SELECT [Parameters] FROM [Shared].[QualsExecParams] WITH (NOLOCK) WHERE PK_Event = @PK_Event)

	-- Getting parameters values for json
	SELECT  
		@Step 						= g.step,	
		@CurrentDatetime			= g.currentDatetime,
		@PK_Event_Log				= g.pkEventLog,
		@ExecLog					= g.execLog,
		@CleanUpTempData			= g.cleanUpTempData,
		@EligibleCountries 			= g.eligibleCountries, 
		@ProjectID = g.projectId, 
		@Reset = g.[reset],
		@iCurrentDate =  FORMAT(g.currentDate, 'yyyyMMdd'), 
		@ConvertionsAllowed = g.convertionsAllowed,

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
		@PMBonusRetailOrderPurposeCode = g.[newPM_retail_orderPurposeCode],

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
			step INT '$.step',
			currentDatetime DATETIME '$.currentDatetime',
			pkEventLog INT '$.pkEventLog',
			execLog BIT '$.execLog',
			cleanUpTempData BIT '$.cleanUpTempData',
			eligibleCountries VARCHAR(MAX) '$.eligibleCountries',

			pkEvent INT '$.pkEvent',
			projectId INT '$.projectId',
			cleanUp BIT '$.cleanUp', 
			step INT '$.step',
			[reset] BIT '$.reset',
			currentDate DATE '$.currentDate',  
			convertionsAllowed BIT '$.convertionsAllowed',
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
			[newPM_retail_orderPurposeCode] NVARCHAR(50) '$.newPM_retail_orderPurposeCode',
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
	SET @PK_Event = IIF(@PK_Event IS NULL,206235, @PK_Event)
	SET @CleanUpTempData = ISNULL(@CleanUpTempData,1)
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
				FROM [dbo].[WRK_26101_DSPoints] AS P WITH (NOLOCK)
					INNER JOIN #DS AS D
						ON P.PK_Distributor = D.PK_Distributor
				WHERE D.DSSPTeam = 'DS' AND P.MetricType IN ('DS_PPV','DLV')				 
				GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth

				--Above QS
				INSERT INTO #Event_DSPoints_Validations(PK_Distributor, PK_Country, RoyaltyMonth, MetricType, [Points])
				SELECT  	
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					'VP' AS MetricType,
					SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
				FROM [dbo].[WRK_26101_DSPoints] AS P WITH (NOLOCK)
					INNER JOIN #DS AS D
						ON P.PK_Distributor = D.PK_Distributor
				WHERE D.DSSPTeam = 'SP' AND P.MetricType = 'TV'			 
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
				FROM [dbo].[WRK_26101_DSPoints] AS P WITH (NOLOCK)
					INNER JOIN #DS AS D
						ON P.PK_Distributor = D.PK_Distributor
				WHERE D.DSSPTeam = 'SP' AND D.CountryCode IN ('CA','TT,','JM') AND P.MetricType = 'DS_PPV'			 
				GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth

				--US/PR

				;WITH cte_SPC_PPC AS
				(
					SELECT  
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
					FROM [dbo].[WRK_26101_DSPoints] AS P WITH (NOLOCK)
						INNER JOIN #DS AS D
							ON P.PK_Distributor = D.PK_Distributor
					WHERE D.CountryCode IN ('US','PR') AND P.MetricType IN ('SPC','PPC')			 
					GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth
				),
				cte_MB_Points AS
				(
					SELECT
						P.PK_Distributor,
						P.PK_Country,
						P.RoyaltyMonth,
						SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
					FROM [dbo].[WRK_26101_DSPoints] AS P WITH (NOLOCK)
						INNER JOIN #DS AS D
							ON P.PK_Distributor = D.PK_Distributor
					WHERE D.CountryCode IN ('US','PR') AND P.MetricType IN ('MB_Points')			 
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
						LEFT JOIN cte_MB_Points AS p
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

			--RO
			INSERT INTO #Event_DSPoints_Validations(PK_Distributor, PK_Country, RoyaltyMonth, MetricType, [Points])
			SELECT  	
				P.PK_Distributor,
				P.PK_Country,
				P.RoyaltyMonth, 
				'RO' AS MetricType,
				SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
			FROM [dbo].[WRK_26101_DSPoints] AS P WITH (NOLOCK)
				INNER JOIN #DS AS D
					ON P.PK_Distributor = D.PK_Distributor
			WHERE P.MetricType = 'RO'			 
			GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth

			CREATE CLUSTERED INDEX [IX_#Event_DSPoints_Validations_PK_Distributor] ON #Event_DSPoints_Validations ([PK_Distributor]) 
			CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_Validations_MetricType] ON #Event_DSPoints_Validations ([MetricType])
 
			DROP TABLE IF EXISTS #DSVolume

			CREATE TABLE #DSVolume
			(
				PK_Distributor INT,
				RoyaltyMonth DATETIME,
				[TV] MONEY,
				[PPV] MONEY,
				[DLV] MONEY,
				[PPC] MONEY,
				[SPC] MONEY,
				[PC] MONEY,
				[MB_Points] MONEY,
				[RO] MONEY
			)


			;WITH 
			cte_TV AS
				(				
					--VolumePoints
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_26101_DSPoints] AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'TV' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
					GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				),
			cte_DLV AS
				(
					--DownLineVolume
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_26101_DSPoints] AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'DLV' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
					GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				),
			cte_PPV AS
				(
					--PPV
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_26101_DSPoints] AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'DS_PPV' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
					GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				),
			cte_PPC AS
				(
					--PPC
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_26101_DSPoints] AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'PPC' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event
					GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
				),
			cte_SPC AS
				(
					--SPC
					SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM [dbo].[WRK_26101_DSPoints] AS P WITH(NOLOCK) 
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
				),
				cte_MB_Points AS 
				(
					SELECT @PK_Event AS PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM #Event_DSPoints_Validations AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'MB_Points' AND P.PK_Distributor = @PK_Distributor
					GROUP BY P.PK_Distributor,P.RoyaltyMonth,P.MetricType 
				),
				cte_RO_Points AS 
				(
					SELECT @PK_Event AS PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
					FROM #Event_DSPoints_Validations AS P WITH(NOLOCK) 
					WHERE P.MetricType = 'RO' AND P.PK_Distributor = @PK_Distributor
					GROUP BY P.PK_Distributor,P.RoyaltyMonth,P.MetricType 
				)
							   				 
			INSERT INTO #DSVolume([PK_Distributor],[RoyaltyMonth],[TV],[PPV],[DLV],[PPC],[SPC],[PC],[MB_Points],[RO])
				SELECT 
					D.[PK_Distributor],
					D.dMonth AS [RoyaltyMonth],
					ISNULL(IIF(TV.Points < 0,0, ROUND(TV.Points,2)),0) AS [TV],
					ISNULL(IIF(PPV.Points < 0,0, ROUND(PPV.Points,2)),0) AS [PPV],
					ISNULL(IIF(DLV.Points < 0,0, ROUND(DLV.Points,2)),0) AS [DLV],
					ISNULL(IIF(PPC.Points < 0,0, ROUND(PPC.Points,2)),0) AS [PPC],
					ISNULL(IIF(SPC.Points < 0,0, ROUND(SPC.Points,2)),0) AS [SPC],
					ISNULL(IIF(PC.Points < 0,0, ROUND(PC.Points,2)),0) AS [PC],
					ISNULL(IIF([MBPoints].Points < 0,0, ROUND([MBPoints].Points,2)),0) AS [MB_Points],
					ISNULL(IIF(RO.Points < 0,0, ROUND(RO.Points,2)),0) AS [RO]
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
				LEFT JOIN cte_MB_Points AS [MBPoints]
					ON D.PK_Distributor = [MBPoints].PK_Distributor AND [MBPoints].RoyaltyMonth = D.iMonth
				LEFT JOIN cte_RO_Points AS [RO]
					ON D.PK_Distributor = [RO].PK_Distributor AND [RO].RoyaltyMonth = D.iMonth

			;WITH 
				cte_Quals AS (
						SELECT Q.PK_Distributor,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30,Q31,Q32,Q33,Q34,Q35,Q36,Q37,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10,E11,E12,E13,E14,E15,E16
							FROM   [Event].[DSQual] AS Q WITH (NOLOCK)
							WHERE Q.PK_Event = @PK_Event AND Q.PK_Distributor = @PK_Distributor 
					)
				,cte_double_volume AS (
						SELECT P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType, SUM(Points) AS [Points] 
						FROM [dbo].[WRK_26101_DSPoints] AS P WITH(NOLOCK) 
						WHERE P.MetricType = 'TV' AND P.PK_Distributor = @PK_Distributor AND P.PK_Event = @PK_Event AND P.RoyaltyMonth = @DoubleVolumeBonusMonth
						GROUP BY P.PK_Event,P.PK_Distributor,P.RoyaltyMonth,P.MetricType
					), cte_bonus AS
					(
						SELECT PK_Distributor, [New DS Bonus],[TotalNewDS],[New FQS Bonus],[TotalNewFQS],[New ASP Bonus],[TotalNewASP],[New PM Bonus],[TotalNewPM],[DoubleBonus] FROM [dbo].[WRK_26101_BonusSummary] WITH (NOLOCK) WHERE PK_Distributor = @PK_Distributor
					)
			
			INSERT INTO #DSDetails([PK_Distributor],[DistributorID],[DSSubTeam],[sCountryCode],[New DS Bonus],[TotalNewDS],[New FQS Bonus],[TotalNewFQS],[New ASP Bonus],[TotalNewASP],[New PM Bonus],[TotalNewPM],[DoubleBonus],[DoubleVolume],Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30,Q31,Q32,Q33,Q34,Q35,Q36,Q37,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10,E11,E12,E13,E14,E15,E16)
			SELECT  
			D.nDistributorID AS [PK_Distributor],
			D.sDistributorID AS [DistributorID],							
			D.sSubteam AS [DSSubTeam],
			D.sDistributorCountryProcessingCode AS [sCountryCode],
			ISNULL(B.[New DS Bonus],0)		AS [New DS Bonus],
			ISNULL(B.TotalNewDS,0)		AS [TotalNewDS],
			ISNULL(B.[New FQS Bonus],0)	AS [New FQS Bonus],
			ISNULL(B.[TotalNewFQS],0)	AS [TotalNewFQS],
			ISNULL(B.[New ASP Bonus],0)	AS [New ASP Bonus],
			ISNULL(B.[TotalNewASP],0)	AS [TotalNewASP],
			ISNULL(B.[New PM Bonus],0)	AS [New PM Bonus],
			ISNULL(B.[TotalNewPM],0)	AS [TotalNewPM],
			IIF(@DoubleBonusActive = 1, ISNULL(B.[DoubleBonus],0),0.0) AS [DoubleBonus],
			IIF(@DoubleVolumeBonusActive = 1, IIF(ISNULL(DV.Points,0) >= @DoubleVolumeBonusLimit, @DoubleVolumeBonusLimit,ISNULL(DV.Points,0)),0.0)  AS [DoubleVolume],
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
			IIF(Q.E16 = 1,1,0) AS [E16]
			FROM  dbo.v_Distributor AS D
				INNER JOIN cte_Quals AS Q
					ON D.nDistributorID = Q.PK_Distributor
				LEFT JOIN cte_bonus AS B  
					ON D.nDistributorID = B.PK_Distributor
				LEFT JOIN cte_double_volume AS DV  
					ON D.nDistributorID = DV.PK_Distributor
			WHERE nDistributorID = @PK_Distributor

		 

		SELECT 
		@Step						AS [Step],			
		@CurrentDatetime			AS [CurrentDatetime],
		@PK_Event_Log				AS [PK_Event_Log],
		@ExecLog					AS [ExecLog],
		@CleanUpTempData			AS [CleanUpTempData],
		@EligibleCountries			AS [EligibleCountries],	 
		@ProjectID											AS [ProjectID],
		@PK_Event											AS [PK_Event],
		@Reset												AS [reset],
		@iCurrentDate										AS [iCurrentDate],  
		@ConvertionsAllowed									AS [ConvertionsAllowed],
		--Double bonus										 
		@DoubleVolumeBonusMonth								AS [DoubleVolumeBonusMonth],
		@DoubleVolumeBonusLimit								AS [DoubleVolumeBonusLimit],
		@DoubleVolumeBonusApplicableQuals					AS [DoubleVolumeBonusApplicableQuals],
		@DoubleVolumeBonusMetricType						AS [DoubleVolumeBonusMetricType],
		@DoubleVolumeBonusActive							AS [DoubleVolumeBonusActive],
		@DoubleVolumeBonusCOP								AS [DoubleVolumeBonusCOP],

		--FQS Bonus											
		@FQSQualDateStart									AS [FQSQualDateStart],
		@FQSQualDateEnd										AS [FQSQualDateEnd],
		@FQSBonusApplicableQuals							AS [FQSBonusApplicableQuals],
		@FQSBonusMetricType									AS [FQSBonusMetricType],
		@FQSBonusActive										AS [FQSBonusActive],
		@FQSFreezeCutDays									AS [FQSFreezeCutDays],
		@FQSBonus											AS [FQSBonus],
		--New DS Bonus  	 									 
		@DSBonusAppDateStart 								AS [DSBonusAppDateStart], 
		@DSBonusAppDateEnd 									AS [DSBonusAppDateEnd], 
		@DSBonusApplicableQuals								AS [DSBonusApplicableQuals],
		@DSBonusMetricType									AS [DSBonusMetricType],
		@DSBonusActive										AS [DSBonusActive],
		@DSFreezeCutDays									AS [DSFreezeCutDays],
		@DSBonus											AS [DSBonus],
		--New (PM) Preferred Member Bonus  					 
		@PMBonusAppDateStart  								AS [PMBonusAppDateStart],  
		@PMBonusAppDateEnd  								AS [PMBonusAppDateEnd],  
		@PMBonusApplicableQuals								AS [PMBonusApplicableQuals],
		@PMBonusMetricType									AS [PMBonusMetricType],
		@PMBonusActive										AS [PMBonusActive],
		@PMFreezeCutDays									AS [PMFreezeCutDays],
		@PMBonus											AS [PMBonus],
		@PMBonusRetailOrderPurposeCode						AS [PMBonusRetailOrderPurposeCode],	
		--New ASP Bonus 	  									  
		@RecognitionMonthStart								AS [RecognitionMonthStart],
		@RecognitionMonthEnd								AS [RecognitionMonthEnd],
		@QualifiersLevelSubEvents							AS [QualifiersLevelSubEvents],
		@ASPPromoID											AS [ASPPromoID],
		@ASPBonusApplicableQuals							AS [ASPBonusApplicableQuals],
		@ASPBonusMetricType									AS [ASPBonusMetricType],
		@ASPBonusActive										AS [ASPBonusActive],
		@ASPBonus											AS [ASPBonus],
		--Double bonus
		@FQSDoubleBonusMonth								AS [FQSDoubleBonusMonth], 
		@DSDoubleBonusMonth  								AS [DSDoubleBonusMonth],   
		@PMDoubleBonusMonth  								AS [PMDoubleBonusMonth],   
		@ASPDoubleBonusMonth								AS [ASPDoubleBonusMonth], 
		@DoubleBonusApplicableQuals							AS [DoubleBonusApplicableQuals], 
		@DoubleBonusMetricType								AS [DoubleBonusMetricType],
		@DoubleBonusActive									AS [DoubleBonusActive]

			SELECT  
				[PK_Distributor]
				,[DistributorID]							
				,[DSSubTeam]
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
				,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30,Q31,Q32,Q33,Q34,Q35,Q36,Q37,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10,E11,E12,E13,E14,E15,E16
			FROM #DSDetails

			SELECT 
				PK_Distributor
				,RoyaltyMonth
				,[TV],[PPV],[DLV],[PPC],[SPC],[PC],[MB_Points],[RO]
			FROM #DSVolume
			ORDER BY RoyaltyMonth ASC

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
		FROM [dbo].[WRK_26101_NewASPBonusContributors] AS c WITH (NOLOCK) 
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
		FROM [dbo].[WRK_26101_NewDSBonusContributors] AS c WITH (NOLOCK) 
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
		FROM [dbo].[WRK_26101_NewFQSBonusContributors] AS c WITH (NOLOCK) 
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
		FROM [dbo].[WRK_26101_NewPMBonusContributors] AS c WITH (NOLOCK) 
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