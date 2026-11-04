CREATE PROCEDURE [dbo].[usp_EventQual_NAM_Extravaganza_July2025]
	 @Parameters NVARCHAR(MAX) = NULL
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_NAM_Extravaganza_July2025

	USE:		

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			DECLARE @e int, @em varchar(4000), @param nvarchar(max)
			
			SET @param = N'{
					"pkEvent":203028,
					"cleanUp":1,
					"step":11, 
					"reset":0,
					"currentDate":null, 
					"countries":"US,PR,CA,JM,TT",
					"convertionsAllowed":0,
					"teamFreezeDate":202501,
					"newWTStart":202502,
					"newWTEnd":202601,
					"doubleVolume_month":202506, 
					"doubleVolume_limit":2500, 
					"doubleVolume_applicableQuals":"7,8,9",
					"doubleVolume_metricType":"VP", 
					"doubleVolume_active":1, 
					"doubleVolume_cop":"CA,JM,TT",
					"newFQS_qualDateStart":"202505",
					"newFQS_qualDateEnd":"202507",
					"newFQS_applicableQuals":"7,8,9",
					"newFQS_metricType":"VP", 
					"newFQS_active":1,
					"newFQS_freezeCutDays":15,
					"newFQS_bonus":2000,
					"newDS_appDateStart":202504,
					"newDS_appDateEnd":202506,
					"newDS_applicableQuals":"7,8,9",
					"newDS_metricType":"VP", 
					"newDS_active":1,
					"newDS_freezeCutDays":15,
					"newDS_bonus":1000,
					"newPM_appDateStart":202504,
					"newPM_appDateEnd":202506,
					"newPM_applicableQuals":"7,8,9",
					"newPM_metricType":"VP", 
					"newPM_active":1,
					"newPM_freezeCutDays":15,
					"newPM_bonus":500,
					"newASP_recognitionMonthStart":202505,
					"newASP_recognitionMonthEnd":202507,
					"newASP_qualifiersLevelSubEvents":"1",
					"newASP_aspPromoID":36884,
					"newASP_applicableQuals":"7,8,9",
					"newASP_metricType":"VP",
					"newASP_active":1,
					"newASP_bonus":7500,
					"doubleBonus_newFQSMonth":null,
					"doubleBonus_newDSMonth":null,
					"doubleBonus_newPMMonth":null,
					"doubleBonus_newASPMonth":null,
					"doubleBonus_applicableQuals":null,
					"doubleBonus_metricType":null,
					"doubleBonus_active":0
				}'

			EXEC dbo.usp_EventQual_NAM_Extravaganza_July2025 @Parameters= @param, @Error = @e OUTPUT, @ErrorMessage = @em OUTPUT 
			
			SELECT @e AS [Error], @em AS [ErrorMessage]
			GO


	DESCRIPTION: 

	NOTES:	
		
	OUTPUT TABLES:
		[tmp].[DS]	
		[tmp].[DSQualDef]
		[tmp].[DSPointsSummary] 
		[tmp].[DSSummary] 

		[Event].[DSPoints]
		[Event].[DSQualPoints]
		[Event].[DSQual]
		[Event].[SetupEventQualification] 

	TEMPORARY TABLES:
		DROP TABLE IF EXISTS [#Event_DSQualPoints];
		DROP TABLE IF EXISTS [#ListsQsMapping];
		DROP TABLE IF EXISTS [#SKUsQsMapping];
		DROP TABLE IF EXISTS [#Event_DownlinesPoints];
		DROP TABLE IF EXISTS [#Event_DSPoints_Validations];
		DROP TABLE IF EXISTS [#TimeLog];
		DROP TABLE IF EXISTS [#tmp_DSQualDef];
		DROP TABLE IF EXISTS [#EventQual];
		DROP TABLE IF EXISTS [#DSDownlines];
		DROP TABLE IF EXISTS [#UniqueListID];
		DROP TABLE IF EXISTS [#DSAssociatedDownlines];
		DROP TABLE IF EXISTS [#Countries];
		DROP TABLE IF EXISTS [#ListsQualificationMapping];
		DROP TABLE IF EXISTS [#DSDownlinesSummary];
		DROP TABLE IF EXISTS [#NewDSSSummary];
		DROP TABLE IF EXISTS [#DS];
		DROP TABLE IF EXISTS [#DSForEvaluation];
		DROP TABLE IF EXISTS [#NewDS];
		DROP TABLE IF EXISTS [#dimMemberConversion];
		DROP TABLE IF EXISTS [#QualificationsMapping];
		DROP TABLE IF EXISTS [#ASPNewQualifiers];
		DROP TABLE IF EXISTS [#NewDSOverwrite];
		DROP TABLE IF EXISTS [#DownlineEvaluationDates];
		DROP TABLE IF EXISTS [#NewDSContributorsVolume_Debug];
		DROP TABLE IF EXISTS [#DownlineEvaluationMonth];
		DROP TABLE IF EXISTS [#NewDSContributorsStatus_Debug];
		DROP TABLE IF EXISTS [#DSList];
		DROP TABLE IF EXISTS [#WRK_25060_DownlineApplicationDates];
		DROP TABLE IF EXISTS [#NewFQSSummary];
		DROP TABLE IF EXISTS [#ListsIDs];
		DROP TABLE IF EXISTS [#WRK_25060_DownlineEvaluationMonth];
		DROP TABLE IF EXISTS [#NewFQS];
		DROP TABLE IF EXISTS [#DSSKUs];
		DROP TABLE IF EXISTS [#QAdditionalParts];
		DROP TABLE IF EXISTS [#DownlinesEvaluationPeriod];
		DROP TABLE IF EXISTS [#SKUs];
		DROP TABLE IF EXISTS [#NewFQSOverwrite];
		DROP TABLE IF EXISTS [#NewASPSummary];
		DROP TABLE IF EXISTS [#NewASP];
		DROP TABLE IF EXISTS [#NewASPOverwrite];
		DROP TABLE IF EXISTS [#NewPMSummary];
		DROP TABLE IF EXISTS [#NewPM];
		DROP TABLE IF EXISTS [#Locations];
		DROP TABLE IF EXISTS [#NewPMOverwrite];
		DROP TABLE IF EXISTS [#DoubleBonusSummary];
		DROP TABLE IF EXISTS [#WRK_25060_DoubleBonusContributions];
		DROP TABLE IF EXISTS [#Event_SetupEventQualification];
		DROP TABLE IF EXISTS [#WRK_25060_BonusSummary];
		DROP TABLE IF EXISTS [#tmp_DS];
		DROP TABLE IF EXISTS [#Event_DSPoints_Summary];
		DROP TABLE IF EXISTS [#Event_DSPoints];
		DROP TABLE IF EXISTS [#WRK_25060_BonusPoints];
		DROP TABLE IF EXISTS [#tmp_DSPointsSummary];
		DROP TABLE IF EXISTS [#Executions];

	DEPENDENCIES:
	
	--Stored procedures
		usp_Utility_UpdateErrorLog
		usp_Utility_UpdateProcessingLog

		[Shared].[usp_EventPromo_UpdateSubEventQualifier]
		
		dbo.usp_GetDSVolume
		dbo.usp_GetQualifier_Points

	--Functions	

		[dbo].[ufn_GetPeriods]
	
	--Tables
		
		[Shared].[DistributorAssociation]
		[Promo].[DSSubEvent]

	WORK TABLES (WRK):

	[dbo].[WRK_25060_DSPoints] 
	[dbo].[WRK_25060_DSPoints_Validations] 
	[dbo].[WRK_25060_DownlineDates] -- Just for reference
	[dbo].[WRK_25060_DownlineEvaluationMonth]

	[dbo].[WRK_25060_DSPoints_Downlines]

	[dbo].[WRK_25060_DSDownlines] -- Freeze	
	[dbo].[WRK_25060_ContributorsStatus] -- Freeze
	[dbo].[WRK_25060_ContributorsVolume] -- Freeze
	[dbo].[WRK_25060_NewDSBonusContributors] -- Freeze 
	[dbo].[WRK_25060_NewFQSBonusContributors] -- Freeze 
	[dbo].[WRK_25060_NewASPBonusContributors] -- Freeze 
	[dbo].[WRK_25060_NewPMBonusContributors] -- Freeze
	
	[dbo].[WRK_25060_DoubleBonusContributions]

	[dbo].[WRK_25060_BonusSummary]
	[dbo].[WRK_25060_BonusPoints]
	
	[dynamic].[WRK_25060_NAMEW_NEWFQS_Overwrite]
	[dynamic].[WRK_25060_NAMEW_NEWASP_Overwrite]
	[dynamic].[WRK_25060_NAMEW_NEWPM_Overwrite]
	[dynamic].[WRK_25060_NAMEW_NEWDS_Overwrite]


	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2025-03-04	alejandramed		User Story 1405838: 25060 - NAM Extravaganza July 2025 (July 25- 27) BRD V1  
	1.0.1	2025-05-19	alejandramed		User Story 1414402: 25060 - NAM Extravaganza July 2025 (July 25- 27) BRD V1.2 - Add Sub Event E14  
	1.0.2	2025-06-11	alejandramed		User Story 1417680: 25060 - NAM Extravaganza July 2025 (July 25- 27) BRD V1.3 - E8 - Only PL qualifers from NAM	
	1.0.3	2025-06-17	alejandramed		User Story 1418002: 25060 - NAM Extravaganza July 25-27 2025 - BRD V1.4 - New Sub event: E15 - Multiburn Promotion
	1.0.4	2025-06-25	alejandramed		User Story 1419022: 25060 - NAM Extravaganza July 25-27 2025 - BRD 1.5
	***********************************************************************************************************************************/

	SET NOCOUNT ON;

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
				
	SELECT @Error = 0, @ErrorMessage = '';	

BEGIN TRY

	DECLARE @ColumnToPivot NVARCHAR(MAX),
		@SqlStatement NVARCHAR(MAX)

	IF @Parameters IS NULL 	
	BEGIN
		PRINT 'Getting parameters from [Shared].[QualsExecParams] '
		SET @Parameters = (SELECT [Parameters] FROM [Shared].[QualsExecParams] WITH (NOLOCK) WHERE PK_Event = 203028)
	END

	PRINT '[Parameters]: ' + @Parameters  
 
	-- Variables for json values
	DECLARE
		--General
		 @PK_Event	INT 
		,@Step INT
		,@Reset BIT
		,@CleanUp BIT  
		,@iCurrentDate INT
		,@Countries VARCHAR(MAX)  
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

	-- Getting parameters values for json
	SELECT  
		@PK_Event = g.pkEvent, 
		@CleanUp = g.cleanUp, 
		@Step = g.step,
		@Reset = g.[reset],
		@iCurrentDate =  FORMAT(g.currentDate, 'yyyyMMdd'),
		@Countries = g.countries,
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
	SET @PK_Event = IIF(@PK_Event IS NULL,203028, @PK_Event)
	SET @CleanUp = ISNULL(@CleanUp,1)
	SET @Step = IIF(@Step IS NULL,11, @Step)
	SET @iCurrentDate = IIF(@iCurrentDate IS NULL, FORMAT(GETUTCDATE(), 'yyyyMMdd'), @iCurrentDate)

	SELECT 
		@PK_Event											AS [PK_Event],
		@CleanUp											AS [CleanUp],
		@Step												AS [Step],
		@Reset												AS [reset],
		@iCurrentDate										AS [iCurrentDate],
		@Countries											AS [Countries],
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
		 
	--Quals block
	BEGIN 
		
		IF @Reset = 1 AND @IsDevQA = 0
		BEGIN
			
			DROP TABLE IF EXISTS [dbo].[WRK_25060_DSDownlines]
			DROP TABLE IF EXISTS [dbo].[WRK_25060_ContributorsStatus]
			DROP TABLE IF EXISTS [dbo].[WRK_25060_ContributorsVolume]
			DROP TABLE IF EXISTS [dbo].[WRK_25060_NewDSBonusContributors]
			DROP TABLE IF EXISTS [dbo].[WRK_25060_NewFQSBonusContributors]
			DROP TABLE IF EXISTS [dbo].[WRK_25060_NewASPBonusContributors]
			DROP TABLE IF EXISTS [dbo].[WRK_25060_NewPMBonusContributors]

		END  

		--Variables and temp tables 
		BEGIN
 
		DROP TABLE IF EXISTS #Locations

		CREATE TABLE #Locations
		(
			[Location] [varchar](250),
			[PK_Event] [int],
			[IsMain] [bit]	DEFAULT(0),
			[ctrl] [bit] DEFAULT(0)
		)
		 
		INSERT INTO #Locations(PK_Event,[Location],IsMain) 
			VALUES	
			(@PK_Event,'AT&T Stadium, Dallas, TX',1) 			

		--Qual period 
		DECLARE @QualPeriodStart DATE = '2025-04-01',@QualPeriodEnd DATE = '2025-06-01'

		DROP TABLE IF EXISTS #Event_SetupEventQualification

		CREATE TABLE #Event_SetupEventQualification
		(
			[PK_Event]				int,
			[QualificationNumber]	int,
			[Part]					int,
			[MetricType]			varchar(50),
			[dStartDate]			datetime2,
			[dEndDate]				datetime2,
			[Frequency]				int,
			[Consecutive]			bit, 
			[Accumulated]			bit, 
			[MinPoints]				money,
			[GoalPoints]			money,
			[Countries]				varchar(max),
			[Bonus]					bit,
			[QSVolume]				bit, 
			[PeriodType]			tinyint, -- 1 Fixed period, 2 Relative period base on SPQualDate
			[MetricTypeDefinition]	VARCHAR(50) NULL
		)
		
		--Q5	Achieve a minimum of 2,500 VP* in each month for three (3) consecutive months during qual period (April 2025 - June 2025) 
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			5					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			@QualPeriodStart	AS [dStartDate], 
			@QualPeriodEnd		AS [dEndDate], 
			3					AS [Frequency], 
			1					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			2500				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV'			AS [MetricTypeDefinition]

		--Q6 Achieve a minimum of 250 Personal Consumption Volume Points (PCV) in any two (2) out of the three months (April 2025 - June 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])
		SELECT 
			@PK_Event								AS [PK_Event],
			6										AS QualificationNumber,
			1										AS Part, 
			'PC'									AS [MetricType], 
			@QualPeriodStart						AS [dStartDate], 
			@QualPeriodEnd							AS [dEndDate],  
			2										AS [Frequency], 
			0										AS [Consecutive], 
			0										AS [Accumulated], 
			0										AS [MinPoints], 
			250										AS [GoalPoints], 
			NULL									AS [Countries],
			NULL									AS [QSVolume], 
			1										AS [PeriodType], 
			'PPV,DS_PPV,PPC,SPC,MB_Points,DLV'		AS [MetricTypeDefinition]
			
		--Q7 Accumulate 25,000 VP* during the qualification period  (April 2025 -June 2025) 
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			7					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			@QualPeriodStart	AS [dStartDate], 
			@QualPeriodEnd		AS [dEndDate], 
			3					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			25000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV'				AS [MetricTypeDefinition]
					 
		--Q8 Accumulate 35,000 VP* during the qualification period  (April 2025 - June 2025) 
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			8					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			@QualPeriodStart	AS [dStartDate], 
			@QualPeriodEnd		AS [dEndDate], 
			3					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			35000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV'				AS [MetricTypeDefinition]

		--Q9 Accumulate 40,000 VP* during the qualification period  (April 2025 - June 2025) 
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			9					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			@QualPeriodStart	AS [dStartDate], 
			@QualPeriodEnd		AS [dEndDate], 
			3					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			40000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV'			AS [MetricTypeDefinition]
 
		--Downlines PM and DS for Bonuses
		--PPV(DS_PPV) + DLV for DS
		--PPV(PM_PPV) for PM
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			51						AS QualificationNumber,
			1						AS Part, 
			'DS_PPV,DLV_DV,PM_PPV'	AS [MetricType], 
			'2025-03-01'			AS [dStartDate],  
			'2025-07-01'			AS [dEndDate],  
			NULL					AS [Frequency], 
			NULL					AS [Consecutive], 
			NULL					AS [Accumulated], 
			NULL					AS [MinPoints], 
			NULL					AS [GoalPoints], 
			NULL					AS [Countries],
			0						AS [QSVolume], 
			NULL					AS [PeriodType], 
			NULL					AS [MetricTypeDefinition]
 
		IF @IsDevQA = 0
		BEGIN	

			DELETE s FROM [Event].[SetupEventQualification] AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
			INSERT INTO [Event].[SetupEventQualification](PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition 
			FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event

		END
		 				
		DECLARE 
			@iStartDate int,
			@dStartDate datetime,
			@iEndDate int,
			@dEndDate datetime,
			@DSCountries VARCHAR(MAX),
			@MetricType VARCHAR(MAX) 

		DROP TABLE IF EXISTS #tmp_DS

		CREATE TABLE #tmp_DS(
			[PK_Event] [int] NOT NULL,
			[PK_Distributor] [int] NULL,
			[DistributorID] VARCHAR(30),
			[iStartDate] [int] NULL,
			[iEndDate] [int] NULL,
			[dStartDate] [datetime] NULL,
			[dEndDate] [datetime] NULL,
			[dSPQualDate] [datetime] NULL,
			[PK_DSType] [int] NULL
		)

		DROP TABLE IF EXISTS #Event_DSPoints

		CREATE TABLE #Event_DSPoints
		(
			[PK_Distributor] [int] NULL,
			[PK_Event] [int] NULL,
			[PK_Country] [int] NULL,
			[RoyaltyMonth] [int] NULL,
			[MetricType] [varchar](20) NULL,
			[PersonalPoints] [money] NULL DEFAULT(0),
			[TransferPoints] [money] NULL DEFAULT(0),
			[MainPoints] [money] NULL DEFAULT(0),
			[Points] [money] NULL DEFAULT(0),
			[Bonus] [money] NULL DEFAULT(0)
		)
		
		DROP TABLE IF EXISTS #ListsQsMapping

		CREATE TABLE #ListsQsMapping
		(
			ID INT IDENTITY(1,1),
			ListID INT,
			QId INT
		)

		INSERT INTO #ListsQsMapping(ListID,QId)
			VALUES 
				(63632,19),
				(63633,20),
				(63634,21),
				(63661,22),
				(63658,23),
				(63660,24),
				(63662,25), 
				(65755,26),
				(66083,27)
	
		DROP TABLE IF EXISTS #SKUsQsMapping  

		CREATE TABLE #SKUsQsMapping
		(
			ID INT IDENTITY(1,1),
			PK_Event INT,
			SKUCode VARCHAR(10),
			QId INT
		) 
		
		INSERT INTO #SKUsQsMapping(PK_Event,SKUCode,QId)
			VALUES 
				(203028,'5D98',15),
				(203028,'85D0',16),
				(203028,'85D1',17),
				(203028,'85D2',18),  
				(203028,'85D3',18),  
				(203028,'85D4',18) 

		IF (@IsDevQA = 2)
		BEGIN
			PRINT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1 
		END
		
		DROP TABLE IF EXISTS #TimeLog;  

		CREATE TABLE #TimeLog(
			[Milestone]		varchar(255)
			,[StepGroup]	tinyint
			,[StepSubGroup] tinyint
			,[StepStart]	datetime2
			,[Duration]		int
		);
		
		DROP TABLE IF EXISTS #EventQual;

		CREATE TABLE #EventQual
		(
			PK_Event		INT,
			PK_Distributor	INT,
			CreatedDate		DATETIME DEFAULT  GETUTCDATE(),
			UpdatedDate		DATETIME DEFAULT  GETUTCDATE(),
			Q01  BIT DEFAULT 0,	Q02  BIT DEFAULT 0,	Q03  BIT DEFAULT 0,	Q04  BIT DEFAULT 0,	Q05  BIT DEFAULT 0,
			Q06  BIT DEFAULT 0,	Q07  BIT DEFAULT 0,	Q08  BIT DEFAULT 0,	Q09  BIT DEFAULT 0,	Q10  BIT DEFAULT 0,
			Q11  BIT DEFAULT 0,	Q12  BIT DEFAULT 0,	Q13  BIT DEFAULT 0,	Q14  BIT DEFAULT 0,	Q15  BIT DEFAULT 0,
			Q16  BIT DEFAULT 0,	Q17  BIT DEFAULT 0,	Q18  BIT DEFAULT 0,	Q19  BIT DEFAULT 0,	Q20  BIT DEFAULT 0,
			Q21  BIT DEFAULT 0,	Q22  BIT DEFAULT 0,	Q23  BIT DEFAULT 0,	Q24  BIT DEFAULT 0,	Q25  BIT DEFAULT 0,
			Q26  BIT DEFAULT 0,	Q27  BIT DEFAULT 0,	Q28  BIT DEFAULT 0,	Q29  BIT DEFAULT 0,	Q30  BIT DEFAULT 0,
			Q31  BIT DEFAULT 0,	Q32  BIT DEFAULT 0,	Q33  BIT DEFAULT 0,	Q34  BIT DEFAULT 0,	Q35  BIT DEFAULT 0,
			Q36  BIT DEFAULT 0,	Q37  BIT DEFAULT 0,	Q38  BIT DEFAULT 0,	Q39  BIT DEFAULT 0,	Q40  BIT DEFAULT 0,
			Q41  BIT DEFAULT 0,	Q42  BIT DEFAULT 0,	Q43  BIT DEFAULT 0,	Q44  BIT DEFAULT 0,	Q45  BIT DEFAULT 0,
			Q46  BIT DEFAULT 0,	Q47  BIT DEFAULT 0,	Q48  BIT DEFAULT 0,	Q49  BIT DEFAULT 0,	Q50  BIT DEFAULT 0,

			E01  BIT DEFAULT 0,	E02  BIT DEFAULT 0,	E03  BIT DEFAULT 0,	E04  BIT DEFAULT 0,	E05  BIT DEFAULT 0,
			E06  BIT DEFAULT 0,	E07  BIT DEFAULT 0,	E08  BIT DEFAULT 0,	E09  BIT DEFAULT 0,	E10  BIT DEFAULT 0,
			E11  BIT DEFAULT 0,	E12  BIT DEFAULT 0,	E13  BIT DEFAULT 0,	E14  BIT DEFAULT 0,	E15  BIT DEFAULT 0,
			E16  BIT DEFAULT 0,	E17  BIT DEFAULT 0,	E18  BIT DEFAULT 0,	E19  BIT DEFAULT 0,	E20  BIT DEFAULT 0,
			E21  BIT DEFAULT 0,	E22  BIT DEFAULT 0,	E23  BIT DEFAULT 0,	E24  BIT DEFAULT 0,	E25  BIT DEFAULT 0,
			E26  BIT DEFAULT 0,	E27  BIT DEFAULT 0,	E28  BIT DEFAULT 0,	E29  BIT DEFAULT 0,	E30  BIT DEFAULT 0,
			E31  BIT DEFAULT 0,	E32  BIT DEFAULT 0,	E33  BIT DEFAULT 0,	E34  BIT DEFAULT 0,	E35  BIT DEFAULT 0,
			E36  BIT DEFAULT 0,	E37  BIT DEFAULT 0,	E38  BIT DEFAULT 0,	E39  BIT DEFAULT 0,	E40  BIT DEFAULT 0,
			E41  BIT DEFAULT 0,	E42  BIT DEFAULT 0,	E43  BIT DEFAULT 0,	E44  BIT DEFAULT 0,	E45  BIT DEFAULT 0,
			E46  BIT DEFAULT 0,	E47  BIT DEFAULT 0,	E48  BIT DEFAULT 0,	E49  BIT DEFAULT 0,	E50  BIT DEFAULT 0
		)

	END
		
		--Step 1: DS
		IF @Step >= 1 
		BEGIN

			PRINT 'Executing step 1'

			INSERT INTO #TimeLog VALUES ('#DS', 1, 1, GETUTCDATE(), NULL);

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
					WHERE sCountryCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar](@Countries, ','))

				DROP TABLE IF EXISTS #DS

				CREATE TABLE #DS
				(
					PK_Distributor			int,   
					DSCurrentTeam			varchar(10),        
					DSSubTeam				varchar(10),        
					DSSPTeam				varchar(10),               
					dSPQualDate				datetime2,
					dSPRequalDate			datetime2,
					CountryCode				varchar(5),
					IsFromList				bit default(0),
					IsTicketPurchaser		bit default(0),
				)

				INSERT INTO #DS
				(
					PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,
					dSPRequalDate,
					CountryCode
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				D.dSupervisorqualification AS dSPQualDate,    
				d.dSupervisorReQualification AS dSPRequalDate,
				D.sDistributorCountryProcessingCode AS CountryCode
				FROM        
				dbo.v_Distributor AS D  
					INNER JOIN #Countries AS C
						ON D.nDistributorCountryProcessingID = C.nCountryID				
				WHERE        
					D.StatusCode = 'COMPLETE'        
					AND D.sType IN ('DS','SP') 
	 

				INSERT INTO #DS
				(
					PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,	
					dSPRequalDate,
					CountryCode
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				D.dSupervisorqualification AS dSPQualDate,   
				d.dSupervisorReQualification AS dSPRequalDate,
				D.sDistributorCountryProcessingCode AS CountryCode
				FROM        
				dbo.v_Distributor AS D  
				WHERE        
					D.StatusCode = 'COMPLETE'        
					AND D.sSubteam IN ('FC','CC') 
					AND NOT EXISTS (SELECT 1 FROM #DS AS DS WHERE DS.PK_Distributor = D.nDistributorID)

				CREATE INDEX IX_#DS_PK_Distributor ON #DS(PK_Distributor);

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 1 AND [StepSubGroup] = 1;
		END
		
		--Step 2: List and SKUs and EventQual
		IF @Step >= 2 
		BEGIN

			PRINT 'Executing step 2'

			-- Exception: DS and above outside of NAM that buy an HPL ticket (SKU Code 5D98)  are not eligible for any subevent.
			-- This is done on Events setup, where only NAM countries were set as allowed

			INSERT INTO #TimeLog VALUES ('Lists', 2, 1, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #DSList

				CREATE TABLE #DSList
				(
					[PK_Event] INT
					,PK_Distributor INT
					,ListID INT
					,UniqueID NVARCHAR(MAX)
				)	
				
				DROP TABLE IF EXISTS #ListsIDs

				CREATE TABLE #ListsIDs
				(
					ID INT IDENTITY(1,1),
					PK_Event INT,
					ListID INT,
					QId INT
				)

				INSERT INTO #ListsIDs(PK_Event,ListID,QId)
				SELECT DISTINCT 
					@PK_Event AS PK_Event,
					l.ListID AS [ListID],
					l.QId
				FROM #ListsQsMapping  AS l
																	
				INSERT INTO #DSList([PK_Event],PK_Distributor,ListID,UniqueID)			  
				SELECT		
					l.PK_Event,
					S.nDistributorID AS PK_Distributor,				  
					S.nTypeLID AS ListID,
					CAST(l.PK_Event AS NVARCHAR(20)) + '-' + CAST(S.nDistributorID AS NVARCHAR(20))+ '-'+ CAST(s.nTypeLID AS NVARCHAR(20))  AS UniqueID
				FROM dbo.v_DistributorSet S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				INNER JOIN #ListsIDs l
					ON S.nTypeLID = l.ListID

				CREATE INDEX IX_#DSList_PK_Distributor ON #DSList(PK_Distributor);

				INSERT INTO #DS
				(
					PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,		
					dSPRequalDate,
					CountryCode,		
					IsFromList
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate, 
				d.dSupervisorReQualification AS dSPRequalDate,
				D.sDistributorCountryProcessingCode AS CountryCode,
				1 AS IsFromList
				FROM dbo.v_Distributor AS D  
					INNER JOIN #DSList AS L
						ON D.nDistributorID = L.PK_Distributor
				WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = L.PK_Distributor)

				UPDATE D
				SET IsFromList = 1
				FROM #DS AS D  
					INNER JOIN #DSList AS L
						ON D.PK_Distributor = L.PK_Distributor

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 1;

			INSERT INTO #TimeLog VALUES ('SKUs', 2, 2, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #DSSKUs

				CREATE TABLE #DSSKUs
				(
					PK_Distributor INT
					,PK_EventSKU INT
					,PK_Event INT
					,SKUCode VARCHAR(10)
					,UniqueID NVARCHAR(MAX)
				)	
				
				DROP TABLE IF EXISTS #SKUs

				CREATE TABLE #SKUs
				(
					ID INT IDENTITY(1,1),
					SKUCode VARCHAR(10),
					PK_Event INT,
					PK_Location INT
				)

				INSERT INTO #SKUs(PK_Event,PK_Location,SKUCode)
				SELECT DISTINCT @PK_Event, l.PK_Event, s.SKUCode
						FROM [dbo].[EventSKU] AS s WITH (NOLOCK) 
						INNER JOIN #Locations AS l
						ON s.PK_Event = l.PK_Event

				INSERT INTO #DSSKUs(PK_Distributor,PK_EventSKU,PK_Event,SKUCode,UniqueID)
				SELECT DISTINCT et.PK_Distributor_Purchaser,esku.PK_EventSKU, s.PK_Event, esku.SKUCode ,CAST(l.PK_Event AS NVARCHAR(20)) + '-' + CAST(et.PK_Distributor_Purchaser AS NVARCHAR(20))+ '-'+ CAST(esku.SKUCode  AS NVARCHAR(20))  AS UniqueID 
				FROM #SKUs AS s 
					INNER JOIN dbo.EventSKU AS esku WITH (NOLOCK)
						ON s.SKUCode = esku.SKUCode
					INNER JOIN [dbo].[SKUPurchased] et WITH (NOLOCK)
						ON et.PK_EventSKU = esku.PK_EventSKU
					INNER JOIN #Locations AS l
						ON et.PK_Event = l.PK_Event

				CREATE INDEX IX_DSSKUs_PK_Distributor ON #DSSKUs(PK_Distributor)

				INSERT INTO #DS
				(
					PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,		
					dSPRequalDate,
					CountryCode,
					IsTicketPurchaser
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate,   
				d.dSupervisorReQualification AS dSPRequalDate,
				D.sDistributorCountryProcessingCode AS CountryCode,
				1 AS IsTicketPurchaser
				FROM dbo.v_Distributor AS D  
					INNER JOIN #DSSKUs AS S
						ON D.nDistributorID = S.PK_Distributor
				WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = S.PK_Distributor)

				UPDATE D
				SET IsTicketPurchaser = 1
				FROM #DS AS D  
					INNER JOIN #DSSKUs AS S
						ON D.PK_Distributor = S.PK_Distributor

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 2;

			INSERT INTO #TimeLog VALUES ('#EventQual', 2, 3, GETUTCDATE(), NULL);

			INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q03,Q04,Q10,Q13,Q14,Q46,Q47,Q48,Q49,Q50)
				SELECT 
					PK_Distributor,
					@PK_Event AS [PK_Event],
					IIF(d.DSSPTeam = 'DS' OR d.DSSPTeam = 'SP' ,1,0) AS Q01, -- DS and Above
					IIF(d.DSSPTeam = 'SP',1,0) AS Q02, -- FQS and Above
					CASE WHEN D.DSCurrentTeam IN ('A', 'B', 'C', 'G', 'M', 'P') THEN 1 ELSE 0 END Q03, --TAB Team
					CASE WHEN D.DSCurrentTeam IN ('A', 'B', 'C', 'P') THEN 1 ELSE 0 END Q04, --PT and above
					IIF(d.DSSubTeam IN ('FC','CC'),1,0) AS Q10, -- WW FC and CC 
					IIF(d.CountryCode IN ('CA','JM','TT'),1,0) AS Q13, -- DS from Jamaica, Trinidad, Tobago, Canada	
					IIF(d.CountryCode IN ('US','PR'),1,0) AS Q14, -- DS from USA, Puerto Rico					
					IIF(d.CountryCode IN ('US','PR','CA','JM','TT'),1,0) AS Q46, -- DS and above from NAM
					IIF(d.IsTicketPurchaser = 1 AND d.CountryCode NOT IN ('US','PR','CA','JM','TT'),1,0) AS Q47, -- DS and above outside of NAM that buy a ticket 
					IIF(d.CountryCode IN ('US','PR','CA','JM','TT') AND d.DSSubTeam IN ('FC','CC'),1,0) AS Q48, -- FC and CC from NAM
					IIF(d.IsTicketPurchaser = 1 AND d.CountryCode NOT IN ('US','PR','CA','JM','TT') AND d.DSSubTeam IN ('FC','CC'),1,0) AS Q49, -- FC and CC outside of NAM that buy a ticket 
					IIF(d.IsTicketPurchaser = 1 AND d.CountryCode NOT IN ('US','PR','CA','JM','TT') AND d.DSSubTeam NOT IN ('FC','CC'),1,0) AS Q50 -- DS and above outside of NAM that buy a ticket and not FC and CC
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)

			DELETE #DS WHERE DSSPTeam = 'DS' -- Note: DS are not eligible for volume qualifications and bonuses

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 3;

		END

		--Step 3: Volume		
		IF @Step >= 3 
		BEGIN

			PRINT 'Executing step 3'

			------------------------------------------------------------------------------------------------
			-- 3.1 Getting values from #Event_SetupEventQualification
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification', 3, 1, GETUTCDATE(), NULL);

				SELECT 
					@iStartDate = CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int), 
					@dStartDate = MIN(dStartDate),
					@iEndDate = CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int),
					@dEndDate = MAX(dEndDate),
					@MetricType = STRING_AGG([MetricType], ','),
					@DSCountries = STRING_AGG([Countries],',')
				FROM #Event_SetupEventQualification WITH (NOLOCK)
				WHERE QualificationNumber BETWEEN 5 AND 9
	
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 1;

				-- Result set 
				SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate],@DSCountries AS [DSCountries],@MetricType AS [MetricType]
				 
				------------------------------------------------------------------------------------------------
				-- 3.2 Getting #tmp_DS
				------------------------------------------------------------------------------------------------
			
				INSERT INTO #TimeLog VALUES ('#tmp_DS', 3, 2, GETUTCDATE(), NULL);

					DROP INDEX IF EXISTS IX_#tmp_DS_PK_Distributor ON #tmp_DS;
					DELETE #tmp_DS WHERE PK_Event = @PK_Event

					INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate])
					SELECT DISTINCT
						@PK_Event AS [PK_Event],
						D.PK_Distributor AS PK_Distributor,
						DD.sDistributorID AS DistributorID,
						@iStartDate AS [iStartDate],
						@iEndDate AS [iEndDate],
						@dStartDate AS [dStartDate],
						@dEndDate AS [dEndDate],
						DD.dSupervisorQualification 
					FROM #DS AS D
					INNER JOIN v_Distributor AS DD
						ON D.PK_Distributor = DD.nDistributorID
					WHERE D.DSSPTeam = 'SP' -- Only SPs can qualify using volume

					CREATE INDEX IX_#tmp_DS_PK_Distributor ON #tmp_DS(PK_Distributor);	

					IF (@IsDevQA = 0)
					BEGIN
						
						DROP INDEX IF EXISTS [IX_DS_PK_Distributor]
							ON [tmp].[DS];

						DELETE d FROM [tmp].[DS] AS d WHERE d.PK_Event = @PK_Event  

						INSERT INTO [tmp].[DS]([PK_Event],[PK_Distributor],[StartDate],[EndDate])
						SELECT 
							D.[PK_Event],
							D.PK_Distributor,
							D.[iStartDate],
							D.[iEndDate]
						FROM #tmp_DS AS D 
											 
						CREATE INDEX IX_DS_PK_Distributor ON [tmp].[DS](PK_Distributor) INCLUDE(PK_Event);

					END
					
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;

				------------------------------------------------------------------------------------------------
				-- 3.3 Getting [Event].[DSPoints]
				------------------------------------------------------------------------------------------------
			
				IF (@IsDevQA = 0)
				BEGIN
					INSERT INTO #TimeLog VALUES ('usp_GetDSVolume', 3, 2, GETUTCDATE(), NULL);

					--Input
					--[tmp].[DS]
					--[Event].[SetupEventQualification]

					--SourceType 1: Getting points from PubEvents.[dbo].[factDSFinancial_ctry], includes divorce and tranfer cases.
					EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 1,@QualFilter = '5,6,7,8,9', @KeepNegativeVolume =0, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
					--Output 
					-- [Event].[DSPoints]
					-- [tmp].[DSSummary] 

					IF @Error <> 0
					BEGIN
						SET @Error = @Error
						SET @ErrorMessage = @ErrorMessage
						RETURN;
					END

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;
		
				END
								
			------------------------------------------------------------------------------------------------
			-- 3.5 Getting #Event_DSPoints AND #Event_DSPoints_Validations
			------------------------------------------------------------------------------------------------
		
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints', 3, 5, GETUTCDATE(), NULL);

				--Allocating volume for uplines.

				DELETE #Event_DSPoints WHERE PK_Event = @PK_Event

				DROP INDEX IF EXISTS [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints;
				DROP INDEX IF EXISTS [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints;

				IF @IsDevQA = 0
				BEGIN
					INSERT INTO #Event_DSPoints(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points],[Bonus])
					SELECT 
						PK_Distributor,
						[PK_Event],
						PK_Country,
						[RoyaltyMonth],
						MetricType,
						[PersonalPoints] AS [PersonalPoints],
						[TransferPoints] AS [TransferPoints],
						[MainPoints] AS [MainPoints], 
						ROUND([Points],2) AS [Points],
						Bonus
					FROM [Event].[DSPoints] WITH (NOLOCK)
					WHERE PK_Event = @PK_Event

					DROP TABLE IF EXISTS [dbo].[WRK_25060_DSPoints] 
					
					SELECT 
						PK_Distributor,
						[PK_Event],
						PK_Country,
						[RoyaltyMonth],
						MetricType,
						[PersonalPoints],
						[TransferPoints],
						[MainPoints], 
						[Points],
						Bonus
					INTO [dbo].[WRK_25060_DSPoints] 
					FROM #Event_DSPoints

					CREATE INDEX IX_WRK_25060_DSPoints_PK_Distributor ON [dbo].[WRK_25060_DSPoints] (PK_Distributor);

				END
				
				CREATE CLUSTERED INDEX [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints ([PK_Distributor]) 
				CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints ([MetricType])
			
				-- Starts custom points validation
				----------------------------------------------------------------------------------------
				DROP TABLE IF EXISTS #Event_DSPoints_Validations -- This table holds volume only for uplines

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
				FROM #Event_DSPoints AS P 
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
				FROM #Event_DSPoints AS P 
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
				FROM #Event_DSPoints AS P 
					INNER JOIN #DS AS D
						ON P.PK_Distributor = D.PK_Distributor
				WHERE D.DSSPTeam = 'SP' AND D.CountryCode IN ('CA','TT','JM') AND P.MetricType = 'DS_PPV'			 
				GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth

				--US/PR

				;WITH cte_SPC_PPC AS
				(
					SELECT  
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
					FROM #Event_DSPoints AS P 
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
					FROM #Event_DSPoints AS P 
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

				--PC
				--Out of US/PR/CA/TT/JM

				INSERT INTO #Event_DSPoints_Validations(PK_Distributor, PK_Country, RoyaltyMonth, MetricType, [Points])
				SELECT 
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					'PC' AS MetricType,
					SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
				FROM #Event_DSPoints AS P 
					INNER JOIN #DS AS D
						ON P.PK_Distributor = D.PK_Distributor
				WHERE D.CountryCode NOT IN ('US','PR','CA','TT','JM') AND P.MetricType = 'DS_PPV'			 
				GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth
					
				CREATE CLUSTERED INDEX [IX_#Event_DSPoints_Validations_PK_Distributor] ON #Event_DSPoints_Validations ([PK_Distributor]) 
				CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_Validations_MetricType] ON #Event_DSPoints_Validations ([MetricType])

				IF @IsDevQA = 0
				BEGIN

					DROP TABLE IF EXISTS [dbo].[WRK_25060_DSPoints_Validations] 
					
					SELECT 
						PK_Distributor, 
						PK_Country,
						[RoyaltyMonth],
						MetricType,
						[Points]
					INTO [dbo].[WRK_25060_DSPoints_Validations]  
					FROM #Event_DSPoints_Validations

					CREATE INDEX IX_WRK_25060_DSPoints_Validations_PK_Distributor ON [dbo].[WRK_25060_DSPoints_Validations]  (PK_Distributor);

				END

			--Ends custom points validation
			----------------------------------------------------------------------------------------

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 5;
			
		
		END
			
		--Step 4: Qualification definition
		IF @Step >= 4 
		BEGIN
				PRINT 'Executing step 4'

				------------------------------------------------------------------------------------------------
				-- 4.1 Getting all qualification definition for each DS
				------------------------------------------------------------------------------------------------

				INSERT INTO #TimeLog VALUES ('#tmp_DSQualDef', 4, 1, GETUTCDATE(), NULL);
			
					DROP TABLE IF EXISTS #tmp_DSQualDef

					CREATE TABLE #tmp_DSQualDef
					(
						[PK_Event] [int] NOT NULL,
						[PK_Distributor] [int] NULL,
						[dStartDate] [datetime2](7) NULL,
						[dEndDate] [datetime2](7) NULL,
						[iStartDate] [int] NULL,
						[iEndDate] [int] NULL,
						[dSPQualDate] [datetime2](7) NULL,
						[iSPQualDate] [int] NULL,
						[Frequency] [int] NULL,
						[Consecutive] [bit] NULL,
						[Accumulated] [bit] NULL,
						[MetricType] [varchar](50) NULL,
						[GoalPoints] [money] NULL,
						[MinPoints] [money] NULL,
						[QualificationNumber] [int] NULL,
						[Part] [int] NULL,
						[PK_AssociatedID] [int] NULL,
						[Countries] [varchar](max) NULL,
						[Bonus] [bit] NULL,
						[QSVolume] [bit] NULL 
						)

					INSERT INTO #tmp_DSQualDef([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,QSVolume)
						SELECT 
							C.PK_Event,
							D.PK_Distributor AS PK_Distributor,
							A.StartDate AS dStartDate,
							A.EndDate AS dEndDate,
							CAST(CONVERT(varchar(6), A.StartDate, 112) AS int) AS iStartDate,
							CAST(CONVERT(varchar(6), A.EndDate, 112) AS int) AS iEndDate,
							D.dSPQualDate AS [dSPQualDate],
							CAST(CONVERT(varchar(6), D.dSPQualDate, 112) AS int) AS [iSPQualDate],
							C.Frequency AS Frequency,
							C.Consecutive AS Consecutive,
							C.Accumulated AS Accumulated,
							 C.MetricType AS MetricType,
							C.GoalPoints AS GoalPoints,
							C.MinPoints AS MinPoints,
							C.QualificationNumber,
							C.Part,
							m.PK_AssociatedID AS PK_AssociatedID,
							C.Countries,
							C.QSVolume
						FROM #DS AS D					
							LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
								ON D.PK_Distributor = M.PK_Distributor
							OUTER APPLY #Event_SetupEventQualification AS C WITH (NOLOCK)
							CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
		
					CREATE INDEX IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef(PK_Distributor);

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 4 AND [StepSubGroup] = 1;

				IF @IsDevQA = 0
				BEGIN

					INSERT INTO #TimeLog VALUES ('[tmp].[DSQualDef]', 4, 2, GETUTCDATE(), NULL);
					
					DROP INDEX IF EXISTS IX_tmp_DSQualDef_PK_Event ON [tmp].[DSQualDef];

					DELETE [tmp].[DSQualDef] WHERE PK_Event = @PK_Event

					INSERT INTO [tmp].[DSQualDef]([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[Bonus],[QSVolume])
						SELECT 
							[PK_Event],
							PK_Distributor,
							dStartDate,
							dEndDate,
							iStartDate,
							iEndDate,
							[dSPQualDate],
							[iSPQualDate],
							Frequency,
							Consecutive,
							Accumulated,
							MetricType,
							GoalPoints,
							MinPoints,
							QualificationNumber,
							Part,
							PK_AssociatedID,
							Countries,
							[Bonus],
							[QSVolume]
						FROM #tmp_DSQualDef

				CREATE INDEX IX_tmp_DSQualDef_PK_Event ON [tmp].[DSQualDef](PK_Event);

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 4 AND [StepSubGroup] = 2;

					
			END  

		END
 
		--Step 5: Getting the following items:
			-- 1) Full downline 
			-- 2) Eligible downlines according to evaluation month
			-- 3) Volume for elegible downlines only
			-- 4) Period for each downline according to application date
			-- 5) Bonuses calculation and assignation on [tmp].[DSPointsSummary]	
		IF @Step >= 5
		BEGIN
			

		PRINT 'Executing step 5'

		-----------------------------------------------------------------------------------------------------------------
		-- 5.1 Getting all downlines in 1st DS line for all NAM DS, including the ones from associated 
		-----------------------------------------------------------------------------------------------------------------
			
		INSERT INTO #TimeLog VALUES ('Getting full downline', 5, 1, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #DSDownlines

				SELECT DISTINCT
					DL.PK_Distributor,
					DL.PK_DSDownLine
				INTO #DSDownlines
				FROM #DS AS DS --Uplines from All NAM Countries 
					INNER JOIN dbo.v_dimDSLngDownline AS DL
						ON DS.PK_Distributor = DL.PK_Distributor
				WHERE DL.DSLevelFromUL = 2 
									
			DROP TABLE IF EXISTS #DSAssociatedDownlines

				SELECT DISTINCT
						DA.PK_Distributor,
						DA.PK_AssociatedID,
						DL.PK_DSDownLine,
						DA.nMainDistributorID,
						DA.AssociationType
				INTO #DSAssociatedDownlines
				FROM #DS AS D --Uplines from All NAM Countries 
				INNER JOIN [Shared].[DistributorAssociation] AS DA WITH (NOLOCK)
					ON D.PK_Distributor = DA.PK_Distributor
				INNER JOIN dbo.v_dimDSLngDownline AS DL
					ON DA.PK_AssociatedID = DL.PK_Distributor
				WHERE DL.DSLevelFromUL = 2 
				AND DA.PK_AssociatedID = DA.nMainDistributorID -- When the Individual Distributorship achieves additional contributor, only the Indiviudal Distributorship will gain the new contributor																
																						   /* When the Original Distributorship achieves for additional contributor, 
																								the Individual Distributorship will also benefit from contributor recruited by the Original Distributorship after 
																								completion of the divorce on system			
																							*/
				
			DROP TABLE IF EXISTS #DSDownlinesSummary

			CREATE TABLE #DSDownlinesSummary (PK_Distributor INT,PK_DSDownLine INT,PK_AssociatedID INT,nMainDistributorID INT,AssociationType INT)

			INSERT INTO #DSDownlinesSummary(PK_Distributor,PK_DSDownLine)
				SELECT DISTINCT
					D.PK_Distributor,
					D.PK_DSDownLine
				FROM #DSDownlines AS D
					
			INSERT INTO #DSDownlinesSummary(PK_Distributor,PK_DSDownLine,PK_AssociatedID,nMainDistributorID,AssociationType)
				SELECT DISTINCT
					A.PK_Distributor,
					A.PK_DSDownLine,
					PK_AssociatedID,
					nMainDistributorID,
					AssociationType
				FROM #DSAssociatedDownlines AS A
			WHERE NOT EXISTS (SELECT 1 FROM #DSDownlinesSummary AS S WHERE A.PK_Distributor = S.PK_Distributor AND A.PK_DSDownline = S.PK_DSDownLine)

			CREATE INDEX IX_#DSDownlinesSummary_PK_Distributor ON #DSDownlinesSummary(PK_Distributor) INCLUDE (PK_DSDownLine)

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 1;

	 	---------------------------------------------------------------------------------------------------------------------------
		-- 5.2 Obtaining member conversion dates for downlines in order to determine who is eligible for bonuses
		---------------------------------------------------------------------------------------------------------------------------

		INSERT INTO #TimeLog VALUES ('Obtaining member conversion dates', 5, 2, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #DSForEvaluation  

				SELECT DISTINCT
					@PK_Event AS PK_Event, 
					L.PK_DSDownLine AS [PK_Distributor]
					,DD.QSQualDate 	
					,LEFT(DD.SPQualDate ,6) AS SPQualDate 
					,DD.SPRequalDate
					,DD.PK_DSType AS [CurrentPK_DSType]
					,DD.TypeCode AS [CurrentTypeCode]
					,DD.TeamCode
					,LEFT(DD.ContractAcceptanceDate,6) AS ContractAcceptanceDate
					,LEFT(DD.MBContractAcceptanceDate,6) AS MBContractAcceptanceDate
					,LEFT(ApplicationDate,6) ApplicationDate
					,LEFT(MBApplicationDate,6) MBApplicationDate
					,DD.ConversionDate					  
					,DD.initialAppDate
					,LEFT(DD.[WINBACKREINSTATEMENTDATE],6) AS [DSREINSTATEMENTDATE]
					,LEFT(DD.[PMREINSTATEMENTDATE],6) AS [PMREINSTATEMENTDATE]
				INTO #DSForEvaluation  
				FROM #DSDownlinesSummary  AS L WITH (NOLOCK) -- Source of DS for evaluation
					INNER JOIN [PubEvents].[dbo].[dimDistributor] AS DD WITH (NOLOCK)
						ON L.PK_DSDownLine = DD.PK_Distributor
				WHERE DD.StatusCode = 'COMPLETE'
						
			--For NewDS and NewPM bonus only
			DROP TABLE IF EXISTS #dimMemberConversion  
		 
				SELECT  
					M.PK_Distributor
					,M.ROYALTYMONTH  AS ConversionMonth  
					,CONVERSIONTYPE
					,M.PK_TOSUBTYPE
					,DST.SubTypeCode 
					,DST.TYPECODE
					,ROW_NUMBER() OVER (PARTITION BY M.PK_Distributor ORDER BY M.ROYALTYMONTH ASC) AS [ConversionIndex]
				INTO #dimMemberConversion
				FROM PubEvents.dbo.dimMemberConversion AS M WITH (NOLOCK) 
				INNER JOIN #DSForEvaluation AS L WITH (NOLOCK)
					ON L.PK_Distributor = M.PK_DISTRIBUTOR
				INNER JOIN PubEvents.[dbo].[dimDSSubType] DST (NOLOCK) 
				ON M.PK_ToSubType = DST.PK_DSSubType
				WHERE  CONVERSIONTYPE  IN ('DStoMB','MBToDS')
				AND DST.TYPECODE != 'SP' --Elegible DS Subtype Code: DS,OPC,FMM,FMS,PQS,SC,SB,PQP,QP,2MM,2MS,2QS,5QS,QS,QV,SQS
				
			--For New ASP bonus only
			DROP TABLE IF EXISTS #ASPNewQualifiers

			;WITH cte_ASPQualifiers AS
			(
				SELECT DISTINCT PK_Distributor,DateQualified
				FROM [pubeventmanagement].[Promo].[DSSubEvent] AS d WITH (NOLOCK)
					INNER JOIN ( SELECT [value] AS [SubEvent] FROM STRING_SPLIT(@QualifiersLevelSubEvents, ',')  ) AS se
						ON d.SubEvent = se.SubEvent
				WHERE PK_Event = @ASPPromoID AND DateQualified  BETWEEN  @RecognitionMonthStart AND @RecognitionMonthEnd
			), cte_ASPPrevQualifiers AS
			( 
				SELECT DISTINCT PK_Distributor,DateQualified
				FROM [pubeventmanagement].[Promo].[DSSubEvent] AS d WITH (NOLOCK)
					INNER JOIN ( SELECT [value] AS [SubEvent] FROM STRING_SPLIT(@QualifiersLevelSubEvents, ',')  ) AS se
						ON d.SubEvent = se.SubEvent
				WHERE PK_Event = @ASPPromoID AND DateQualified  < @RecognitionMonthStart -1
			)

			SELECT DISTINCT
				DLS.PK_DSDownLine,
				DLS.PK_Distributor,
				M.DateQualified  
			INTO #ASPNewQualifiers
			FROM #DSDownlinesSummary AS DLS
			INNER JOIN cte_ASPQualifiers AS M
				ON DLS.PK_DSDownLine = M.PK_Distributor
			LEFT JOIN cte_ASPPrevQualifiers AS p
				ON M.PK_Distributor = p.PK_Distributor
			WHERE p.PK_Distributor IS NULL

			DROP TABLE IF EXISTS #DownlineEvaluationDates			
			 
				-- PM by MBContractAcceptanceDate
				SELECT D.PK_Distributor
					,d.PK_DSDownLine 
					,1 AS [Type] 
					,DD.QSQualDate 	
					,DD.SPQualDate 
					,DD.SPRequalDate
					,DD.[CurrentTypeCode]
					,DD.TeamCode
					,DD.ContractAcceptanceDate
					,DD.MBContractAcceptanceDate
					,ApplicationDate
					,MBApplicationDate
					,DD.ConversionDate					  
					,DD.initialAppDate
					,DD.[DSREINSTATEMENTDATE]
					,DD.[PMREINSTATEMENTDATE]
					,NULL AS CONVERSIONTYPE
					,NULL AS SubTypeCode
					,NULL AS ConversionMonth
					,'PM' AS [EvaluationType]
					,MBContractAcceptanceDate AS EvaluationMonth
				INTO #DownlineEvaluationDates
				FROM #DSDownlinesSummary  AS d -- Source of DS for evaluation
				INNER JOIN #DSForEvaluation AS DD WITH (NOLOCK)
					ON d.PK_DSDownLine = DD.PK_Distributor
				WHERE DD.MBContractAcceptanceDate BETWEEN @PMBonusAppDateStart AND @PMBonusAppDateEnd
				UNION 
				-- DS by ContractAcceptanceDate
				SELECT D.PK_Distributor
					,d.PK_DSDownLine 
					,2 AS [Type] 
					,DD.QSQualDate 	
					,DD.SPQualDate 
					,DD.SPRequalDate
					,[CurrentTypeCode]
					,DD.TeamCode
					,DD.ContractAcceptanceDate
					,DD.MBContractAcceptanceDate
					,ApplicationDate
					,MBApplicationDate
					,DD.ConversionDate					  
					,DD.initialAppDate
					,DD.[DSREINSTATEMENTDATE]
					,DD.[PMREINSTATEMENTDATE]
					,NULL AS CONVERSIONTYPE
					,NULL AS SubTypeCode
					,NULL AS ConversionMonth
					,'DS' AS [EvaluationType]
					,ContractAcceptanceDate AS EvaluationMonth
				FROM #DSDownlinesSummary  AS d -- Source of DS for evaluation
				INNER JOIN #DSForEvaluation AS DD WITH (NOLOCK)
					ON d.PK_DSDownLine = DD.PK_Distributor
				WHERE DD.ContractAcceptanceDate BETWEEN @DSBonusAppDateStart AND @DSBonusAppDateEnd
				UNION
				--DS by ConversionMonth
				SELECT D.PK_Distributor
					,d.PK_DSDownLine 
					,3 AS [Type] 
					,DD.QSQualDate 	
					,DD.SPQualDate 
					,DD.SPRequalDate
					,DD.[CurrentTypeCode]
					,DD.TeamCode
					,DD.ContractAcceptanceDate
					,DD.MBContractAcceptanceDate
					,ApplicationDate
					,MBApplicationDate
					,DD.ConversionDate					  
					,DD.initialAppDate
					,DD.[DSREINSTATEMENTDATE]
					,DD.[PMREINSTATEMENTDATE]
					,dc.CONVERSIONTYPE
					,dc.SubTypeCode
					,ISNULL(ConversionMonth,190001) AS ConversionMonth
					,'DS'  AS [EvaluationType]			 
					,ConversionMonth  AS EvaluationMonth
				FROM #DSDownlinesSummary  AS d -- Source of DS for evaluation
				INNER JOIN #DSForEvaluation AS DD WITH (NOLOCK)
					ON d.PK_DSDownLine = DD.PK_Distributor
				INNER JOIN #dimMemberConversion AS dc WITH (NOLOCK)
					ON d.PK_DSDownLine = dc.PK_Distributor 
				WHERE dc.ConversionMonth BETWEEN @DSBonusAppDateStart AND @DSBonusAppDateEnd
				AND dc.CONVERSIONTYPE = 'MBtoDS'
				AND [ConversionIndex] = 1
				AND @ConvertionsAllowed = 1
				UNION
				-- PM by ConversionMonth
				SELECT D.PK_Distributor
					,d.PK_DSDownLine 
					,4 AS [Type] 
					,DD.QSQualDate 	
					,DD.SPQualDate 
					,DD.SPRequalDate
					,DD.[CurrentTypeCode]
					,DD.TeamCode
					,DD.ContractAcceptanceDate
					,DD.MBContractAcceptanceDate
					,ApplicationDate
					,MBApplicationDate
					,DD.ConversionDate					  
					,DD.initialAppDate
					,DD.[DSREINSTATEMENTDATE]
					,DD.[PMREINSTATEMENTDATE]
					,dc.CONVERSIONTYPE
					,dc.SubTypeCode
					,ISNULL(ConversionMonth,190001) AS ConversionMonth
					,'PM'  AS [EvaluationType]			 
					,ConversionMonth  AS EvaluationMonth
				FROM #DSDownlinesSummary  AS d -- Source of DS for evaluation
				INNER JOIN #DSForEvaluation AS DD WITH (NOLOCK)
					ON d.PK_DSDownLine = DD.PK_Distributor
				INNER JOIN #dimMemberConversion AS dc WITH (NOLOCK)
					ON d.PK_DSDownLine = dc.PK_Distributor 
				WHERE dc.ConversionMonth BETWEEN @PMBonusAppDateStart AND @PMBonusAppDateEnd
				AND dc.CONVERSIONTYPE = 'DStoMB'
				AND [ConversionIndex] = 1
				AND @ConvertionsAllowed = 1
			UNION
			--FQS by SPQualDate
			SELECT D.PK_Distributor
					,d.PK_DSDownLine 
					,5 AS [Type] 
					,DD.QSQualDate 	
					,DD.SPQualDate 
					,DD.SPRequalDate
					,DD.[CurrentTypeCode]
					,DD.TeamCode
					,DD.ContractAcceptanceDate
					,DD.MBContractAcceptanceDate
					,ApplicationDate
					,MBApplicationDate
					,DD.ConversionDate					  
					,DD.initialAppDate
					,DD.[DSREINSTATEMENTDATE]
					,DD.[PMREINSTATEMENTDATE]
					,NULL AS CONVERSIONTYPE
					,NULL AS SubTypeCode
					,NULL AS ConversionMonth
					,'FQS'  AS [EvaluationType]			 
					,DD.SPQualDate  AS EvaluationMonth
				FROM #DSDownlinesSummary  AS d -- Source of DS for evaluation
				INNER JOIN #DSForEvaluation AS DD WITH (NOLOCK)
					ON d.PK_DSDownLine = DD.PK_Distributor				 
				WHERE DD.SPQualDate BETWEEN @FQSQualDateStart AND @FQSQualDateEnd
			 	AND DD.[CurrentTypeCode] = 'SP' AND DD.TeamCode IN ('N','W') 
				UNION
				--ASP by QualDate
				SELECT D.PK_Distributor
					,d.PK_DSDownLine 
					,6 AS [Type] 
					,DD.QSQualDate 	
					,DD.SPQualDate 
					,DD.SPRequalDate
					,DD.[CurrentTypeCode]
					,DD.TeamCode
					,DD.ContractAcceptanceDate
					,DD.MBContractAcceptanceDate
					,DD.ApplicationDate
					,DD.MBApplicationDate
					,DD.ConversionDate					  
					,DD.initialAppDate
					,DD.[DSREINSTATEMENTDATE]
					,DD.[PMREINSTATEMENTDATE]
					,NULL AS CONVERSIONTYPE
					,NULL AS SubTypeCode
					,NULL AS ConversionMonth
					,'ASP'  AS [EvaluationType]			 
					,ds.DateQualified   AS EvaluationMonth
				FROM #DSDownlinesSummary  AS d -- Source of DS for evaluation
				INNER JOIN #DSForEvaluation AS DD WITH (NOLOCK)
					ON d.PK_DSDownLine = DD.PK_Distributor
				INNER JOIN #ASPNewQualifiers AS ds WITH (NOLOCK)
					ON ds.PK_DSDownLine = d.PK_DSDownLine AND ds.PK_Distributor = d.PK_Distributor 
				UNION
				-- PM Reinstatements  
				SELECT D.PK_Distributor
					,d.PK_DSDownLine 
					,7 AS [Type] 
					,DD.QSQualDate 	
					,DD.SPQualDate 
					,DD.SPRequalDate
					,DD.[CurrentTypeCode]
					,DD.TeamCode
					,DD.ContractAcceptanceDate
					,DD.MBContractAcceptanceDate
					,ApplicationDate
					,MBApplicationDate
					,DD.ConversionDate					  
					,DD.initialAppDate
					,DD.[DSREINSTATEMENTDATE]
					,DD.[PMREINSTATEMENTDATE]
					,NULL AS CONVERSIONTYPE
					,NULL AS SubTypeCode
					,NULL AS ConversionMonth
					,'PM' AS [EvaluationType]
					,[PMREINSTATEMENTDATE] AS EvaluationMonth
				FROM #DSDownlinesSummary  AS d -- Source of DS for evaluation
				INNER JOIN #DSForEvaluation AS DD WITH (NOLOCK)
					ON d.PK_DSDownLine = DD.PK_Distributor
				WHERE DD.[PMREINSTATEMENTDATE] BETWEEN @PMBonusAppDateStart AND @PMBonusAppDateEnd
				UNION 
				--DS Reinstatements  
				SELECT D.PK_Distributor
					,d.PK_DSDownLine 
					,8 AS [Type] 
					,DD.QSQualDate 	
					,DD.SPQualDate 
					,DD.SPRequalDate
					,[CurrentTypeCode]
					,DD.TeamCode
					,DD.ContractAcceptanceDate
					,DD.MBContractAcceptanceDate
					,ApplicationDate
					,MBApplicationDate
					,DD.ConversionDate					  
					,DD.initialAppDate
					,DD.[DSREINSTATEMENTDATE]
					,DD.[PMREINSTATEMENTDATE]
					,NULL AS CONVERSIONTYPE
					,NULL AS SubTypeCode
					,NULL AS ConversionMonth
					,'DS' AS [EvaluationType]
					,[DSREINSTATEMENTDATE] AS EvaluationMonth
				FROM #DSDownlinesSummary  AS d -- Source of DS for evaluation
				INNER JOIN #DSForEvaluation AS DD WITH (NOLOCK)
					ON d.PK_DSDownLine = DD.PK_Distributor
				WHERE DD.[DSREINSTATEMENTDATE] BETWEEN @DSBonusAppDateStart AND @DSBonusAppDateEnd
				 
 			DROP TABLE IF EXISTS #DownlineEvaluationMonth 

				SELECT DISTINCT PK_Distributor,PK_DSDownline,EvaluationType,MIN(EvaluationMonth) AS  EvaluationMonth
				INTO #DownlineEvaluationMonth
				FROM #DownlineEvaluationDates
				GROUP BY PK_Distributor,PK_DSDownline,EvaluationType
			
			IF @IsDevQA = 0
			BEGIN
				DROP TABLE IF EXISTS [dbo].[WRK_25060_DownlineDates] -- Current execution, not freezed table

				SELECT DISTINCT
					PK_Distributor
					,PK_DSDownLine 
					,[Type] 
					,QSQualDate 	
					,SPQualDate 
					,SPRequalDate
					,[CurrentTypeCode]
					,[TeamCode]
					,MBContractAcceptanceDate
					,ContractAcceptanceDate
					,ApplicationDate
					,MBApplicationDate
					,ConversionDate					  
					,initialAppDate
					,[DSREINSTATEMENTDATE]
					,[PMREINSTATEMENTDATE]
					,CONVERSIONTYPE
					,SubTypeCode
					,ConversionMonth
					,[EvaluationType]
					,EvaluationMonth
				INTO [dbo].[WRK_25060_DownlineDates]
				FROM #DownlineEvaluationDates
			
				DROP TABLE IF EXISTS [dbo].[WRK_25060_DownlineEvaluationMonth] -- Current execution, not freezed table

				SELECT 
					m.PK_Distributor
					,m.PK_DSDownLine  
					,DD.QSQualDate 	
					,DD.SPQualDate 
					,DD.SPRequalDate
					,DD.[CurrentTypeCode]
					,DD.[TeamCode]
					,DD.MBContractAcceptanceDate
					,DD.ContractAcceptanceDate
					,DD.ApplicationDate
					,DD.MBApplicationDate
					,DD.ConversionDate					  
					,DD.initialAppDate
					,DD.[DSREINSTATEMENTDATE]
					,DD.[PMREINSTATEMENTDATE]
					,NULL AS CONVERSIONTYPE
					,NULL AS SubTypeCode
					,NULL AS ConversionMonth
					,m.[EvaluationType]
					,m.EvaluationMonth
					,CAST(CAST((EvaluationMonth * 100) + 01 AS varchar(10)) AS datetime2) AS dEvaluationMonth,
					CASE  
						WHEN EvaluationType = 'DS' THEN @DSBonusAppDateStart 
						WHEN EvaluationType = 'PM' THEN @PMBonusAppDateStart 
						WHEN EvaluationType = 'FQS' THEN @FQSQualDateStart 
					 END AS StartMonth,
					 CASE  
						WHEN EvaluationType = 'DS' THEN @DSBonusAppDateEnd 
						WHEN EvaluationType = 'PM' THEN @PMBonusAppDateEnd 
						WHEN EvaluationType = 'FQS' THEN @FQSQualDateEnd 
					 END AS EndMonth,
					  CASE  
						WHEN EvaluationType = 'DS' THEN @DSFreezeCutDays 
						WHEN EvaluationType = 'PM' THEN @PMFreezeCutDays 
						WHEN EvaluationType = 'FQS' THEN @FQSFreezeCutDays 
					 END AS FreezeCutDays
				INTO [dbo].[WRK_25060_DownlineEvaluationMonth]
				FROM #DownlineEvaluationMonth AS m
					INNER JOIN #DSForEvaluation AS DD WITH (NOLOCK)
						ON m.PK_DSDownLine = DD.PK_Distributor

			END
						
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 2;

		---------------------------------------------------------------------------------------------------------------------------
		-- 5.3 Obtaining the evluation period for all the downlines eligible for bonuses
		---------------------------------------------------------------------------------------------------------------------------

		INSERT INTO #TimeLog VALUES ('#DownlinesEvaluationPeriod', 5, 3, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #DownlinesEvaluationPeriod

				CREATE TABLE #DownlinesEvaluationPeriod
				(
					PK_Distributor INT,
					PK_DSDownline INT,			 
					EvaluationType VARCHAR(10),
					EvaluationMonth INT,
					dEvaluationMonth DATE,
					StartMonth INT,
					dStartMonth DATE,
					EndMonth INT,
					dEndMonth DATE,
					FreezeDate INT,
					dFreezeDate DATE
				)

				IF @IsDevQA = 0
				BEGIN

					INSERT INTO #DownlinesEvaluationPeriod(
						PK_Distributor,
						PK_DSDownLine, 
						EvaluationType,
						EvaluationMonth, 
						dEvaluationMonth,
						StartMonth,
						dStartMonth,
						EndMonth,
						dEndMonth,
						FreezeDate,
						dFreezeDate)
					 SELECT 
						PK_Distributor,
						PK_DSDownLine, 
						EvaluationType,
						EvaluationMonth, 
						dEvaluationMonth, 
						IIF(EvaluationType IN ('PM','DS'), LEFT(CONVERT(INT, CONVERT(CHAR(10),CONVERT(DATE, DATEADD(MM,-1,dEvaluationMonth) , 104), 112)),6),NULL)  AS StartMonth,
						IIF(EvaluationType IN ('PM','DS'), DATEADD(MM,-1,dEvaluationMonth),NULL) AS dStartMonth,
						IIF(EvaluationType IN ('PM','DS'), IIF(EvaluationMonth+1 > EndMonth ,EndMonth, EvaluationMonth+1),NULL)  AS EndMonth, -- Sign-up month +1
						IIF(EvaluationType IN ('PM','DS'), CAST(CAST((IIF(EvaluationMonth+1 > EndMonth ,EndMonth, EvaluationMonth+1) * 100) + 01 AS VARCHAR(10)) AS DATE),NULL) AS dEndMonth,
						CONVERT(INT, CONVERT(CHAR(10),CONVERT(DATE, DATEADD(DD,FreezeCutDays, CAST(CAST((IIF(EvaluationType = 'FQS', EvaluationMonth+1,EvaluationMonth+2) * 100) + 01 AS VARCHAR(10)) AS DATE)), 104), 112))  AS FreezeDate, --15th day after the signup month + 1
						DATEADD(DD,FreezeCutDays, CAST(CAST((IIF(EvaluationType = 'FQS', EvaluationMonth+1,EvaluationMonth+2) * 100) + 01 AS VARCHAR(10)) AS DATE)) AS dFreezeDate
					FROM [dbo].[WRK_25060_DownlineEvaluationMonth] WITH (NOLOCK) 			

				END  

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 3;
			
		------------------------------------------------------------------------------------------------
		-- 5.4 Freezing lineage
		--// Contributor will be evaluated until 15th day after the signup month + 1; If a NewDS RESIGN/TERMINATED or is not at good standing with herbalife, no matter if contributor achieved 100 VP will be removed as Contributor 															
		------------------------------------------------------------------------------------------------

		INSERT INTO #TimeLog VALUES ('Freezing WRK_25060_DSDownlines', 5, 4, GETUTCDATE(), NULL);
		 
			IF @IsDevQA = 0
			BEGIN

				IF OBJECT_ID (N'WRK_25060_DSDownlines', N'U') IS NULL 
				BEGIN
				
					CREATE TABLE [dbo].[WRK_25060_DSDownlines] --Freeze table
					(
						[CreatedDateUTC]   DATETIME, 
						[ModifiedDateUTC]  DATETIME,
						PK_Distributor INT,
						PK_DSDownline INT,			 
						EvaluationType VARCHAR(10),
						EvaluationMonth INT,
						dEvaluationMonth DATE,
						StartMonth INT,
						dStartMonth DATE,
						EndMonth INT,
						dEndMonth DATE,
						FreezeDate INT,
						dFreezeDate DATE,
						[Active] BIT DEFAULT 1
					) 
				END

				MERGE [dbo].[WRK_25060_DSDownlines] AS T
				USING #DownlinesEvaluationPeriod AS S
				ON S.PK_Distributor = T.PK_Distributor 
					AND S.PK_DSDownLine = T.PK_DSDownLine  
					AND S.EvaluationMonth = T.EvaluationMonth 
					AND T.EvaluationType = S.EvaluationType
				WHEN NOT MATCHED BY TARGET THEN
				-- For Inserts
					INSERT (
							[CreatedDateUTC], 
							[ModifiedDateUTC],
							PK_Distributor,
							PK_DSDownline,
							EvaluationType,
							EvaluationMonth,
							dEvaluationMonth,
							StartMonth,
							dStartMonth,
							EndMonth,
							dEndMonth,
							FreezeDate,
							dFreezeDate
							) 
					VALUES (
							GETUTCDATE(), 
							GETUTCDATE(),
							S.PK_Distributor,
							S.PK_DSDownline,
							S.EvaluationType,
							S.EvaluationMonth,
							S.dEvaluationMonth,
							S.StartMonth,
							S.dStartMonth,
							S.EndMonth,
							S.dEndMonth,
							S.FreezeDate,
							S.dFreezeDate
						)		
				-- For Updates
				WHEN MATCHED AND @iCurrentDate < T.FreezeDate  AND T.EvaluationType != 'ASP' THEN
					UPDATE 
					SET
						[ModifiedDateUTC] = GETUTCDATE(),
						T.Active = 1 
				-- For Deletes
				WHEN NOT MATCHED BY SOURCE AND @iCurrentDate < T.FreezeDate  AND T.EvaluationType != 'ASP' THEN
					UPDATE 
					SET
						[ModifiedDateUTC] = GETUTCDATE(),
						T.Active = 0;
					
			END
									
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 4;


		------------------------------------------------------------------------------------------------
		-- 5.5 Getting values from #Event_SetupEventQualification
		------------------------------------------------------------------------------------------------
			
		INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification', 5, 5, GETUTCDATE(), NULL);

			SELECT 
				@iStartDate = CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int), 
				@dStartDate = MIN(dStartDate),
				@iEndDate = CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int),
				@dEndDate = MAX(dEndDate),
				@MetricType =  STRING_AGG([MetricType], ','),
				@DSCountries = STRING_AGG([Countries],',')
			FROM #Event_SetupEventQualification WITH (NOLOCK)
			WHERE QualificationNumber = 51 --Applicable only for downlines

			-- Result set 
			SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate],@DSCountries AS [DSCountries],@MetricType AS [MetricType]
	
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 5;

		
		------------------------------------------------------------------------------------------------
		-- 5.6 Getting #tmp_DS
		------------------------------------------------------------------------------------------------
			
		INSERT INTO #TimeLog VALUES ('#tmp_DS', 5, 6, GETUTCDATE(), NULL);

			DROP INDEX IF EXISTS IX_#tmp_DS_PK_Distributor ON #tmp_DS;
			DELETE #tmp_DS WHERE PK_Event = @PK_Event
					
				IF @IsDevQA = 0
				BEGIN

					INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate],[PK_DSType])
					SELECT DISTINCT
						@PK_Event AS [PK_Event],
						D.PK_DSDownLine AS PK_Distributor,
						DD.DistributorID,
						@iStartDate AS [iStartDate],
						@iEndDate AS [iEndDate],
						@dStartDate AS [dStartDate],
						@dEndDate AS [dEndDate],
						CASE WHEN DD.SPQualDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DD.SPQualDate),112) END, 
						NULL PK_DSType -- Frezee type or NULL to take the current status 
					FROM [dbo].[WRK_25060_DSDownlines] AS D WITH (NOLOCK)
					INNER JOIN [PubEvents].[dbo].dimDistributor AS DD WITH (NOLOCK)
						ON D.PK_DSDownLine = DD.PK_Distributor
					WHERE [Active] = 1
					AND @iCurrentDate < D.FreezeDate 

				END  
					
				IF (@IsDevQA = 0)
				BEGIN
						
					DROP INDEX IF EXISTS [IX_DS_PK_Distributor]
						ON [tmp].[DS];

					DELETE d FROM [tmp].[DS] AS d WHERE d.PK_Event = @PK_Event  

					INSERT INTO [tmp].[DS]([PK_Event],[PK_Distributor],[StartDate],[EndDate],[PK_DSType]) 
					SELECT 
						D.[PK_Event],
						D.PK_Distributor,
						D.[iStartDate],
						D.[iEndDate],
						D.[PK_DSType]
					FROM #tmp_DS AS D 
											 
					CREATE INDEX IX_DS_PK_Distributor ON [tmp].[DS](PK_Distributor) INCLUDE(PK_Event);

				END

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 6;

		------------------------------------------------------------------------------------------------
		-- 5.7 Getting ##Event_DSPoints_25060
		------------------------------------------------------------------------------------------------
			
		IF (@IsDevQA = 0)
		BEGIN
			INSERT INTO #TimeLog VALUES ('usp_GetDSVolume', 5, 7, GETUTCDATE(), NULL);

			--Input
			--[tmp].[DS]
			--[Event].[SetupEventQualification]  

			--SourceType 1: Getting points from PubEvents.[dbo].[factDSFinancial_ctry], includes divorce and tranfer cases.
			EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 1, @QualFilter = '51', @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
				
			--Output [Event].[DSPoints]
			--Output [tmp].[DSSummary] 

			IF @Error <> 0
			BEGIN
				SET @Error = @Error
				SET @ErrorMessage = @ErrorMessage
				RETURN;
			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 7;
		
		END

		------------------------------------------------------------------------------------------------
		-- 5.8 Getting #Event_DownlinesPoints  
		------------------------------------------------------------------------------------------------
		
		INSERT INTO #TimeLog VALUES ('#Event_DownlinesPoints', 5, 8, GETUTCDATE(), NULL);

			--Allocating volume for downlines.

			DROP TABLE IF EXISTS #Event_DownlinesPoints

			CREATE TABLE #Event_DownlinesPoints
			(
				[PK_Distributor] [int] NULL,
				[PK_Event] [int] NULL,
				[PK_Country] [int] NULL,
				[RoyaltyMonth] [int] NULL,
				[MetricType] [varchar](20) NULL,
				[PersonalPoints] [money] NULL DEFAULT(0),
				[TransferPoints] [money] NULL DEFAULT(0),
				[MainPoints] [money] NULL DEFAULT(0),
				[Points] [money] NULL DEFAULT(0) 
			)

			IF @IsDevQA = 0
			BEGIN
				
				INSERT INTO #Event_DownlinesPoints(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points])
				SELECT 
					PK_Distributor,
					[PK_Event],
					PK_Country,
					[RoyaltyMonth],
					MetricType,
					[PersonalPoints] AS [PersonalPoints],
					[TransferPoints] AS [TransferPoints],
					[MainPoints] AS [MainPoints], 
					ROUND([Points],2) AS [Points] 
				FROM [Event].[DSPoints] WITH (NOLOCK)
				WHERE PK_Event = @PK_Event
								
				DROP TABLE IF EXISTS [dbo].[WRK_25060_DSPoints_Downlines]  -- Current execution, not freeze
					
				SELECT 
					PK_Distributor,
					[PK_Event],
					PK_Country,
					[RoyaltyMonth],
					MetricType,
					[PersonalPoints],
					[TransferPoints],
					[MainPoints], 
					[Points] 
				INTO [dbo].[WRK_25060_DSPoints_Downlines] 
				FROM #Event_DownlinesPoints

				CREATE INDEX IX_WRK_25060_DSPoints_Downlines_PK_Distributor ON [dbo].[WRK_25060_DSPoints_Downlines] (PK_Distributor);

			END

			CREATE CLUSTERED INDEX [IX_#Event_DownlinesPoints_PK_Distributor] ON #Event_DownlinesPoints ([PK_Distributor]) 
			CREATE NONCLUSTERED INDEX [IX_#Event_DownlinesPoints_MetricType] ON #Event_DownlinesPoints ([MetricType])
			
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 8;
								 		
		------------------------------------------------------------------------------------------------
		-- 5.9  Bonuses assignation / [tmp].[DSPointsSummary]		
		------------------------------------------------------------------------------------------------
	 
		IF @IsDevQA = 0 AND OBJECT_ID (N'WRK_25060_ContributorsStatus', N'U') IS NULL  
		BEGIN

				CREATE TABLE [dbo].[WRK_25060_ContributorsStatus]  --Freeze table
					(
						[CreatedDateUTC]  DATETIME DEFAULT GETUTCDATE(), 
						PK_Distributor	int,
						PK_DSDownLine	int,
						[FreezeDate] int,
						[ContributionMonth] int,
						QSQualDate	int,
						SPQualDate	int,
						SPRequalDate	int,
						CurrentTypeCode	varchar(5),
						TeamCode	varchar(5),
						MBContractAcceptanceDate	int,
						ContractAcceptanceDate	int,
						ApplicationDate	int,
						MBApplicationDate	int,
						ConversionDate	int,
						initialAppDate	int,
						[DSREINSTATEMENTDATE] int,
						[PMREINSTATEMENTDATE] int,
						CONVERSIONTYPE	varchar(5),
						SubTypeCode	varchar(10),
						ConversionMonth	int,
						EvaluationType	varchar(5),
						EvaluationMonth	int
					) 

			END

		IF @IsDevQA = 0 AND OBJECT_ID (N'WRK_25060_ContributorsVolume', N'U') IS NULL  
			BEGIN

				CREATE TABLE [dbo].[WRK_25060_ContributorsVolume]  --Freeze table
					(
						[CreatedDateUTC]  DATETIME DEFAULT GETUTCDATE(), 
						PK_Distributor INT,
						PK_DSDownline INT,
						ContributionMonth INT,
						ContributionType VARCHAR(10),
						FreezeDate INT,
						[PK_Country] [int] NULL,
						[RoyaltyMonth] [int] NULL,
						[MetricType] [varchar](20) NULL,
						[PersonalPoints] [money] NULL DEFAULT(0),
						[TransferPoints] [money] NULL DEFAULT(0),
						[MainPoints] [money] NULL DEFAULT(0),
						[Points] [money] NULL DEFAULT(0) 
					) 

			END
			
			--// Double volume month
			----------------------------------------------------------------------------------------------------------------------------------- 
			-- This bonus will applied depending of the settings
			----------------------------------------------------------------------------------------------------------------------------------- 

			--// New DS Bonus
			-----------------------------------------------------------------------------------------------------------------------------------  
			
			INSERT INTO #TimeLog VALUES ('New DS Bonus', 5, 91, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #NewDSSSummary

			CREATE TABLE #NewDSSSummary
			(
				PK_Distributor INT,
				[TotalNewDS] INT,
				[TotalBonusNewDS] MONEY
			)
			 
			IF @IsDevQA = 0 AND OBJECT_ID (N'WRK_25060_NewDSBonusContributors', N'U') IS NULL  
			BEGIN

				CREATE TABLE [dbo].[WRK_25060_NewDSBonusContributors]  --Freeze table
					(
						[CreatedDateUTC]   DATETIME, 
						[ModifiedDateUTC]  DATETIME,
						PK_Distributor INT,
						PK_DSDownline INT,
						ContributionMonth INT,
						IsOverwritten BIT,
						FreezeDate INT,
						[Active] BIT DEFAULT 1
					) 

			END
						
			--// Getting contributors
			DROP TABLE IF EXISTS #NewDS
				
			CREATE TABLE #NewDS
			(
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ContributionMonth INT,
				IsOverwritten BIT DEFAULT 0,
				FreezeDate INT,  
				[Active] BIT  DEFAULT 1
			)
				
			--Evaluating just those downlines that are not frozen
			IF @IsDevQA = 0
			BEGIN

				INSERT INTO #NewDS(PK_Distributor,PK_DSDownline,ContributionMonth,FreezeDate)
				SELECT d.PK_Distributor, d.PK_DSDownline,d.EvaluationMonth AS ContributionMonth,d.FreezeDate
				FROM [dbo].[WRK_25060_DSDownlines] AS d WITH (NOLOCK)  
				INNER JOIN [dbo].[WRK_25060_DSPoints_Downlines]  AS p WITH (NOLOCK)
					ON d.PK_DSDownline = p.PK_Distributor  
						AND p.RoyaltyMonth BETWEEN d.StartMonth AND d.EndMonth
				WHERE d.Active = 1 AND @iCurrentDate < d.FreezeDate 
				AND d.EvaluationType = 'DS' AND p.MetricType IN ('DS_PPV', 'DLV_DV')
				GROUP BY d.PK_Distributor, d.PK_DSDownline,d.EvaluationMonth,d.FreezeDate
				HAVING SUM(Points) >= 100
				
			END 

			--Overwriting contributors 
			DROP TABLE IF EXISTS #NewDSOverwrite
				 
			SELECT 
				U.nDistributorID AS PK_Distributor,
				D.nDistributorID AS PK_DSDownLine,
				o.ContributionMonth,
				MAX(CONVERT(int,o.Active)) AS [Active],
				FORMAT(GETUTCDATE(), 'yyyyMMdd') AS FreezeDate  
			INTO #NewDSOverwrite
			FROM [dynamic].[WRK_25060_NAMEW_NEWDS_Overwrite] AS o WITH (NOLOCK)
				INNER JOIN v_Distributor AS U
					ON o.UL_DistributorID = U.sDistributorID
				INNER JOIN v_Distributor AS D
					ON o.DL_DistributorID = D.sDistributorID	
			GROUP BY U.nDistributorID,
				D.nDistributorID,
				o.ContributionMonth 		 

			MERGE #NewDS AS t
			USING #NewDSOverwrite  AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ContributionMonth = s.ContributionMonth
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ContributionMonth,Active,FreezeDate,IsOverwritten)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ContributionMonth,Active,FreezeDate,1)
				WHEN MATCHED  
					THEN UPDATE SET 
						t.Active = s.Active,
						t.IsOverwritten = 1;

			--// Freezing contributors
			IF @IsDevQA = 0
			BEGIN
							
				MERGE [dbo].[WRK_25060_NewDSBonusContributors] AS t
				USING #NewDS AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ContributionMonth = s.ContributionMonth
				AND @iCurrentDate < s.FreezeDate 
				WHEN NOT MATCHED BY TARGET 
					THEN INSERT ([CreatedDateUTC],[ModifiedDateUTC],PK_Distributor, PK_DSDownLine,ContributionMonth,IsOverwritten,FreezeDate,Active)
							VALUES (GETUTCDATE(),GETUTCDATE(),s.PK_Distributor, s.PK_DSDownLine,s.ContributionMonth,s.IsOverwritten,s.FreezeDate,s.Active)
				WHEN MATCHED AND (s.IsOverwritten = 1 OR @iCurrentDate < s.FreezeDate) 
					THEN UPDATE SET 
						t.Active = s.Active,
						t.[ModifiedDateUTC] = GETUTCDATE()	
				WHEN NOT MATCHED BY SOURCE AND  @iCurrentDate < t.FreezeDate  
					THEN UPDATE SET 
						t.Active = 0,
						t.[ModifiedDateUTC] = GETUTCDATE();	 
						
				INSERT INTO #NewDSSSummary(PK_Distributor,[TotalNewDS],[TotalBonusNewDS])
				SELECT 
					F.PK_Distributor,
					COUNT(1) AS [TotalNewDS],
					(COUNT(1) * @DSBonus) AS [TotalBonusNewDS]
				FROM [dbo].[WRK_25060_NewDSBonusContributors] AS F WITH (NOLOCK)
				WHERE Active = 1
				GROUP BY F.PK_Distributor

				--Freeze volumen for guaranteed contributors 1 day prior the freeze date

				DROP TABLE IF EXISTS #NewDSContributorsVolume

				SELECT 
					d.PK_Distributor, 
					d.PK_DSDownline,
					d.ContributionMonth,
					'DS' AS ContributionType,
					d.FreezeDate, 				
					p.PK_Country,
					p.RoyaltyMonth,
					p.MetricType,
					p.PersonalPoints,
					p.TransferPoints,
					p.MainPoints,
					p.Points
				INTO #NewDSContributorsVolume
				FROM #NewDS AS d  
				INNER JOIN [dbo].[WRK_25060_DSPoints_Downlines] AS p WITH (NOLOCK)
					ON d.PK_DSDownline = p.PK_Distributor  						 
				WHERE @iCurrentDate < d.FreezeDate  
				AND p.MetricType IN ('DS_PPV', 'DLV_DV')	


				MERGE [dbo].[WRK_25060_ContributorsVolume] AS t
				USING #NewDSContributorsVolume AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ContributionMonth = s.ContributionMonth
					AND t.ContributionType = s.ContributionType AND t.FreezeDate = s.FreezeDate AND t.[PK_Country] = s.[PK_Country]
					AND t.RoyaltyMonth = s.RoyaltyMonth AND t.MetricType = s.MetricType  
					AND @iCurrentDate < s.FreezeDate 
				WHEN NOT MATCHED BY TARGET 
					THEN INSERT (
						PK_Distributor,
						PK_DSDownline,
						ContributionMonth,
						ContributionType,
						FreezeDate,
						[PK_Country],
						[RoyaltyMonth],
						[MetricType],
						[PersonalPoints],
						[TransferPoints],
						[MainPoints],
						[Points])
					VALUES (
						S.PK_Distributor,
						S.PK_DSDownline,
						S.ContributionMonth,
						S.ContributionType,
						S.FreezeDate,
						S.[PK_Country],
						S.[RoyaltyMonth],
						S.[MetricType],
						S.[PersonalPoints],
						S.[TransferPoints],
						S.[MainPoints],
						S.[Points]
						)
					WHEN MATCHED AND @iCurrentDate < T.FreezeDate THEN UPDATE SET						 
						T.[PersonalPoints]		= S.[PersonalPoints],
						T.[TransferPoints]		= S.[TransferPoints],
						T.[MainPoints]			= S.[MainPoints],
						T.[Points]				= S.[Points]
						; 
 
				--Freeze status for guaranteed contributors 1 day prior the freeze date

				DROP TABLE IF EXISTS #NewDSContributorsStatus

				 SELECT DISTINCT
					d.PK_Distributor
					,d.PK_DSDownLine 
					,d.ContributionMonth
					,d.FreezeDate
					,s.QSQualDate 	
					,s.SPQualDate 
					,s.SPRequalDate
					,s.[CurrentTypeCode]
					,s.[TeamCode]
					,s.MBContractAcceptanceDate
					,s.ContractAcceptanceDate
					,s.ApplicationDate
					,s.MBApplicationDate
					,s.ConversionDate					  
					,s.initialAppDate
					,s.[DSREINSTATEMENTDATE]
					,s.[PMREINSTATEMENTDATE]
					,s.CONVERSIONTYPE
					,s.SubTypeCode
					,s.ConversionMonth
					,s.[EvaluationType]
					,s.EvaluationMonth
				INTO #NewDSContributorsStatus
				FROM #NewDS AS d  
				INNER JOIN [WRK_25060_DownlineEvaluationMonth] AS s WITH (NOLOCK)
					ON d.PK_Distributor = s.PK_Distributor AND d.PK_DSDownline = s.PK_DSDownline   	
				WHERE @iCurrentDate < d.FreezeDate  
				AND s.EvaluationType = 'DS'

				MERGE [dbo].[WRK_25060_ContributorsStatus] AS t
				USING #NewDSContributorsStatus AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ContributionMonth = s.ContributionMonth
					AND t.FreezeDate = s.FreezeDate AND t.[EvaluationType] = s.[EvaluationType] AND t.EvaluationMonth = s.EvaluationMonth  
					AND @iCurrentDate < s.FreezeDate 
				WHEN NOT MATCHED BY TARGET 
					THEN INSERT (
						PK_Distributor
						,PK_DSDownLine 
						,QSQualDate 	
						,SPQualDate 
						,SPRequalDate
						,[CurrentTypeCode]
						,[TeamCode]
						,MBContractAcceptanceDate
						,ContractAcceptanceDate
						,ApplicationDate
						,MBApplicationDate
						,ConversionDate					  
						,initialAppDate
						,[DSREINSTATEMENTDATE]
						,[PMREINSTATEMENTDATE]
						,CONVERSIONTYPE
						,SubTypeCode
						,ConversionMonth
						,[EvaluationType]
						,EvaluationMonth
						,ContributionMonth
						,FreezeDate)
					VALUES (
						S.PK_Distributor
						,S.PK_DSDownLine 
						,S.QSQualDate 	
						,S.SPQualDate 
						,S.SPRequalDate
						,S.[CurrentTypeCode]
						,S.[TeamCode]
						,S.MBContractAcceptanceDate
						,S.ContractAcceptanceDate
						,S.ApplicationDate
						,S.MBApplicationDate
						,S.ConversionDate					  
						,S.initialAppDate
						,S.[DSREINSTATEMENTDATE]
						,S.[PMREINSTATEMENTDATE]
						,S.CONVERSIONTYPE
						,S.SubTypeCode
						,S.ConversionMonth
						,S.[EvaluationType]
						,S.EvaluationMonth
						,S.ContributionMonth
						,S.FreezeDate
						)
					WHEN MATCHED AND @iCurrentDate < T.FreezeDate  THEN UPDATE SET 				
						 T.QSQualDate 							= S.QSQualDate 				
						,T.SPQualDate 							= S.SPQualDate 				
						,T.SPRequalDate							= S.SPRequalDate				
						,T.[CurrentTypeCode]					= S.[CurrentTypeCode]			
						,T.[TeamCode]							= S.[TeamCode]				
						,T.MBContractAcceptanceDate				= S.MBContractAcceptanceDate	
						,T.ContractAcceptanceDate				= S.ContractAcceptanceDate	
						,T.ApplicationDate						= S.ApplicationDate			
						,T.MBApplicationDate					= S.MBApplicationDate			
						,T.ConversionDate					  	= S.ConversionDate			
						,T.initialAppDate						= S.initialAppDate	
						,T.[DSREINSTATEMENTDATE] 				= S.[DSREINSTATEMENTDATE]
						,T.[PMREINSTATEMENTDATE]				= S.[PMREINSTATEMENTDATE]		
						,T.CONVERSIONTYPE						= S.CONVERSIONTYPE			
						,T.SubTypeCode							= S.SubTypeCode				
						,T.ConversionMonth 						= S.ConversionMonth
						,T.ContributionMonth					= S.ContributionMonth
						,T.FreezeDate							= S.FreezeDate
						; 	

				
			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 91;
		
			--// New FQS Bonus
			------------------------------------------------------------------------------------------------ 
		 
			INSERT INTO #TimeLog VALUES ('New FQS Bonus', 5, 92, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #NewFQSSummary

			CREATE TABLE #NewFQSSummary
			(
				PK_Distributor INT,
				[TotalNewFQS] INT,
				[TotalBonusNewFQS] MONEY
			)
			 

			IF @IsDevQA = 0 AND OBJECT_ID (N'WRK_25060_NewFQSBonusContributors', N'U') IS NULL 
			BEGIN
				CREATE TABLE [dbo].[WRK_25060_NewFQSBonusContributors] 
				(
					[CreatedDateUTC]   DATETIME, 
					[ModifiedDateUTC]  DATETIME,
					PK_Distributor INT,
					PK_DSDownline INT,
					ContributionMonth INT,
					IsOverwritten BIT,
					FreezeDate INT,
					[Active] BIT DEFAULT 1
				)
			END
			
			--// Getting contributors				
			DROP TABLE IF EXISTS #NewFQS
				
			CREATE TABLE #NewFQS
			(
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ContributionMonth INT,
				IsOverwritten BIT DEFAULT 0,
				FreezeDate INT,  
				[Active] BIT  DEFAULT 1
			)

			--Evaluating just those downlines that are not frozen
			IF @IsDevQA = 0
			BEGIN 

				INSERT INTO #NewFQS(PK_Distributor,PK_DSDownline,ContributionMonth,FreezeDate)
				SELECT d.PK_Distributor, d.PK_DSDownline,d.EvaluationMonth AS ContributionMonth,d.FreezeDate
				FROM [dbo].[WRK_25060_DSDownlines] AS d WITH (NOLOCK)  
					INNER JOIN [dbo].[WRK_25060_DownlineEvaluationMonth] AS DD WITH (NOLOCK) 
					ON d.PK_Distributor = DD.PK_Distributor AND d.PK_DSDownLine = DD.PK_DSDownLine
					AND d.EvaluationType = DD.EvaluationType
				WHERE d.Active = 1 AND @iCurrentDate < d.FreezeDate 
					AND d.EvaluationType = 'FQS'  					
					
				
			END 

			--Overwriting contributors 
			DROP TABLE IF EXISTS #NewFQSOverwrite
				 
			SELECT 
				U.nDistributorID AS PK_Distributor,
				D.nDistributorID AS PK_DSDownLine,
				o.ContributionMonth,
				MAX(CONVERT(int,o.Active)) AS [Active],
				FORMAT(GETUTCDATE(), 'yyyyMMdd') AS FreezeDate  
			INTO #NewFQSOverwrite
			FROM [dynamic].[WRK_25060_NAMEW_NEWFQS_Overwrite] AS o WITH (NOLOCK)
				INNER JOIN v_Distributor AS U
					ON o.UL_DistributorID = U.sDistributorID
				INNER JOIN v_Distributor AS D
					ON o.DL_DistributorID = D.sDistributorID	
			GROUP BY U.nDistributorID,
				D.nDistributorID,
				o.ContributionMonth 		 

			MERGE #NewFQS AS t
			USING #NewFQSOverwrite  AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ContributionMonth = s.ContributionMonth
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ContributionMonth,Active,FreezeDate,IsOverwritten)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ContributionMonth,Active,FreezeDate,1)
				WHEN MATCHED  
					THEN UPDATE SET 
						t.Active = s.Active,
						t.IsOverwritten = 1;

			-- Freezing contributors							
			IF @IsDevQA = 0
			BEGIN

				MERGE [dbo].[WRK_25060_NewFQSBonusContributors] AS t
				USING #NewFQS AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ContributionMonth = s.ContributionMonth
				AND @iCurrentDate < s.FreezeDate 
				WHEN NOT MATCHED BY TARGET 
					THEN INSERT ([CreatedDateUTC],[ModifiedDateUTC],PK_Distributor, PK_DSDownLine,ContributionMonth,IsOverwritten,FreezeDate,Active)
							VALUES (GETUTCDATE(),GETUTCDATE(),s.PK_Distributor, s.PK_DSDownLine,s.ContributionMonth,s.IsOverwritten,s.FreezeDate,s.Active)
				WHEN MATCHED AND (s.IsOverwritten = 1 OR  @iCurrentDate < s.FreezeDate ) 
					THEN UPDATE SET 
						t.Active = s.Active,
						t.[ModifiedDateUTC] = GETUTCDATE()	
				WHEN NOT MATCHED BY SOURCE AND @iCurrentDate < T.FreezeDate  
					THEN UPDATE SET 
						t.Active = 0,
						t.[ModifiedDateUTC] = GETUTCDATE();	 
	 
				INSERT INTO #NewFQSSummary(PK_Distributor,[TotalNewFQS],[TotalBonusNewFQS])
				SELECT 
					F.PK_Distributor,
					COUNT(1) AS [TotalNewFQS],
					(COUNT(1) * @FQSBonus) AS [TotalBonusNewFQS]
				FROM [dbo].[WRK_25060_NewFQSBonusContributors] AS F WITH (NOLOCK)
				WHERE F.Active = 1
				GROUP BY F.PK_Distributor
				 
			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 92;

			 
			--// New ASP Bonus
			------------------------------------------------------------------------------------------------ 	 
						
			INSERT INTO #TimeLog VALUES ('New 1st Time Ever NAM ASP', 5, 93, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #NewASPSummary

			CREATE TABLE #NewASPSummary
			(
				PK_Distributor INT,
				[TotalNewASP] INT,
				[TotalBonusNewASP] MONEY
			)			 

			IF @IsDevQA = 0 AND OBJECT_ID (N'WRK_25060_NewASPBonusContributors', N'U') IS NULL 			
			BEGIN
				CREATE TABLE [dbo].[WRK_25060_NewASPBonusContributors] 
				(
					[CreatedDateUTC]   DATETIME, 
					[ModifiedDateUTC]  DATETIME,
					PK_Distributor INT,
					PK_DSDownline INT,
					ContributionMonth INT,
					IsOverwritten BIT,
					FreezeDate INT,  
					[Active] BIT DEFAULT 1
				)
			END
	
			--// Getting contributors				
			DROP TABLE IF EXISTS #NewASP 
				
			CREATE TABLE #NewASP
			(
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ContributionMonth INT,
				IsOverwritten BIT DEFAULT 0,
				FreezeDate INT,  
				[Active] BIT  DEFAULT 1
			)

			IF @IsDevQA = 0
			BEGIN

				INSERT INTO #NewASP(PK_Distributor,PK_DSDownline,ContributionMonth,FreezeDate)
				SELECT DISTINCT
					DLS.PK_Distributor,
					DLS.PK_DSDownLine,
					DLS.DateQualified AS ContributionMonth,
					d.FreezeDate  
				FROM [dbo].[WRK_25060_DSDownlines] AS d WITH (NOLOCK)   
					INNER JOIN #ASPNewQualifiers AS DLS 
						ON d.PK_Distributor = DLS.PK_Distributor AND d.PK_DSDownline = DLS.PK_DSDownLine
				WHERE d.EvaluationType = 'ASP'
			
			END 

			--Overwriting contributors 
			DROP TABLE IF EXISTS #NewASPOverwrite
				 
			SELECT 
				U.nDistributorID AS PK_Distributor,
				D.nDistributorID AS PK_DSDownLine,
				o.ContributionMonth,
				MAX(CONVERT(int,o.Active)) AS [Active],
				NULL AS FreezeDate  
			INTO #NewASPOverwrite
			FROM [dynamic].[WRK_25060_NAMEW_NEWASP_Overwrite] AS o WITH (NOLOCK)
				INNER JOIN v_Distributor AS U
					ON o.UL_DistributorID = U.sDistributorID
				INNER JOIN v_Distributor AS D
					ON o.DL_DistributorID = D.sDistributorID	
			GROUP BY U.nDistributorID,
				D.nDistributorID,
				o.ContributionMonth 		 

			MERGE #NewASP AS t
			USING #NewASPOverwrite  AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ContributionMonth = s.ContributionMonth
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ContributionMonth,Active,FreezeDate,IsOverwritten)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ContributionMonth,Active,FreezeDate,1)
				WHEN MATCHED  
					THEN UPDATE SET 
						t.Active = s.Active,
						t.IsOverwritten = 1;

			-- Freezing contributors							
			IF @IsDevQA = 0
			BEGIN

				MERGE [dbo].[WRK_25060_NewASPBonusContributors] AS t
				USING #NewASP AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ContributionMonth = s.ContributionMonth
				WHEN NOT MATCHED BY TARGET 
					THEN INSERT ([CreatedDateUTC],[ModifiedDateUTC],PK_Distributor, PK_DSDownLine,ContributionMonth,IsOverwritten,FreezeDate,Active)
							VALUES (GETUTCDATE(),GETUTCDATE(),s.PK_Distributor, s.PK_DSDownLine,s.ContributionMonth,s.IsOverwritten,s.FreezeDate,s.Active)
				WHEN MATCHED AND (s.IsOverwritten = 1 OR s.FreezeDate IS NULL)
					THEN UPDATE SET 
						t.Active = s.Active,
						t.[ModifiedDateUTC] = GETUTCDATE()	
				WHEN NOT MATCHED BY SOURCE  
					THEN UPDATE SET 
						t.Active = 0,
						t.[ModifiedDateUTC] = GETUTCDATE();	 	 
	 
				INSERT INTO #NewASPSummary(PK_Distributor,[TotalNewASP],[TotalBonusNewASP])
				SELECT 
					F.PK_Distributor,
					COUNT(1) AS [TotalNewASP],
					(COUNT(1) * @ASPBonus) AS [TotalBonusNewASP]
				FROM [dbo].[WRK_25060_NewASPBonusContributors] AS F WITH (NOLOCK)
				WHERE Active = 1
				GROUP BY F.PK_Distributor
				 
			END
		
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 93;
			
			--// New (PM) Preferred Member Bonus
			------------------------------------------------------------------------------------------------ 	

			INSERT INTO #TimeLog VALUES ('New PM Bonus', 5, 94, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #NewPMSummary

			CREATE TABLE #NewPMSummary
			(
				PK_Distributor INT,
				[TotalNewPM] INT,
				[TotalBonusNewPM] MONEY
			)
			 

			IF @IsDevQA = 0 AND OBJECT_ID (N'WRK_25060_NewPMBonusContributors', N'U') IS NULL 	
			BEGIN
				CREATE TABLE [dbo].[WRK_25060_NewPMBonusContributors] 
				(
					[CreatedDateUTC]   DATETIME, 
					[ModifiedDateUTC]  DATETIME,
					PK_Distributor INT,
					PK_DSDownline INT,
					ContributionMonth INT,
					IsOverwritten BIT,
					FreezeDate INT,
					[Active] BIT DEFAULT 1
				)
			END
			
			--// Getting contributors
			DROP TABLE IF EXISTS #NewPM
				
			CREATE TABLE #NewPM
			(
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ContributionMonth INT,
				IsOverwritten BIT DEFAULT 0,
				FreezeDate INT,  
				[Active] BIT  DEFAULT 1
			)

			--Evaluating just those downlines that are not frozen
			IF @IsDevQA = 0
			BEGIN

				INSERT INTO #NewPM(PK_Distributor,PK_DSDownline,ContributionMonth,FreezeDate)
				SELECT d.PK_Distributor, d.PK_DSDownline,d.EvaluationMonth AS ContributionMonth,d.FreezeDate
				FROM [dbo].[WRK_25060_DSDownlines] AS d WITH (NOLOCK)  
				INNER JOIN [dbo].[WRK_25060_DSPoints_Downlines]  AS p WITH (NOLOCK)
					ON d.PK_DSDownline = p.PK_Distributor  
						AND p.RoyaltyMonth BETWEEN d.StartMonth AND d.EndMonth
				WHERE d.Active = 1 AND @iCurrentDate < d.FreezeDate 
				AND d.EvaluationType = 'PM' AND p.MetricType = 'PM_PPV'
				GROUP BY d.PK_Distributor, d.PK_DSDownline,d.EvaluationMonth,d.FreezeDate
				HAVING SUM(Points) >= 100
				
			END 

			--Overwriting contributors 
			DROP TABLE IF EXISTS #NewPMOverwrite
				 
			SELECT 
				U.nDistributorID AS PK_Distributor,
				D.nDistributorID AS PK_DSDownLine,
				o.ContributionMonth,
				MAX(CONVERT(int,o.Active)) AS [Active],
				FORMAT(GETUTCDATE(), 'yyyyMMdd') AS FreezeDate  
			INTO #NewPMOverwrite
			FROM [dynamic].[WRK_25060_NAMEW_NEWPM_Overwrite] AS o WITH (NOLOCK)
				INNER JOIN v_Distributor AS U
					ON o.UL_DistributorID = U.sDistributorID
				INNER JOIN v_Distributor AS D
					ON o.DL_DistributorID = D.sDistributorID	
			GROUP BY U.nDistributorID,
				D.nDistributorID,
				o.ContributionMonth 		 

			MERGE #NewPM AS t
			USING #NewPMOverwrite  AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ContributionMonth = s.ContributionMonth
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ContributionMonth,Active,FreezeDate,IsOverwritten)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ContributionMonth,Active,FreezeDate,1)
				WHEN MATCHED  
					THEN UPDATE SET 
						t.Active = s.Active,
						t.IsOverwritten = 1;
							
			--// Freezing contributors
			IF @IsDevQA = 0
			BEGIN
							
				MERGE [dbo].[WRK_25060_NewPMBonusContributors] AS t
				USING #NewPM AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ContributionMonth = s.ContributionMonth
				AND @iCurrentDate < s.FreezeDate  
				WHEN NOT MATCHED BY TARGET 
					THEN INSERT ([CreatedDateUTC],[ModifiedDateUTC],PK_Distributor, PK_DSDownLine,ContributionMonth,IsOverwritten,FreezeDate,Active)
							VALUES (GETUTCDATE(),GETUTCDATE(),s.PK_Distributor, s.PK_DSDownLine,s.ContributionMonth,s.IsOverwritten,s.FreezeDate,s.Active)
				WHEN MATCHED AND (s.IsOverwritten = 1 OR  @iCurrentDate < s.FreezeDate ) 
					THEN UPDATE SET 
						t.Active = s.Active,
						t.[ModifiedDateUTC] = GETUTCDATE()	
				WHEN NOT MATCHED BY SOURCE AND @iCurrentDate < T.FreezeDate  
					THEN UPDATE SET 
						t.Active = 0,
						t.[ModifiedDateUTC] = GETUTCDATE();	 
	 
				INSERT INTO #NewPMSummary(PK_Distributor,[TotalNewPM],[TotalBonusNewPM])
				SELECT 
					F.PK_Distributor,
					COUNT(1) AS [TotalNewPM],
					(COUNT(1) * @PMBonus) AS [TotalBonusNewPM]
				FROM [dbo].[WRK_25060_NewPMBonusContributors] AS F WITH (NOLOCK)  
				WHERE Active = 1
				GROUP BY F.PK_Distributor
				 
				--Freeze volumen for guaranteed contributors 1 day prior the freeze date

				DROP TABLE IF EXISTS #NewPMContributorsVolume

				SELECT 					
					d.PK_Distributor, 
					d.PK_DSDownline,
					d.ContributionMonth,
					'PM' AS ContributionType,
					d.FreezeDate, 				
					p.PK_Country,
					p.RoyaltyMonth,
					p.MetricType,
					p.PersonalPoints,
					p.TransferPoints,
					p.MainPoints,
					p.Points
				INTO #NewPMContributorsVolume
				FROM #NewPM AS d  
				INNER JOIN [dbo].[WRK_25060_DSPoints_Downlines]  AS p WITH (NOLOCK)
					ON d.PK_DSDownline = p.PK_Distributor  						 
				WHERE @iCurrentDate < d.FreezeDate  
				AND p.MetricType = 'PM_PPV'


				MERGE [dbo].[WRK_25060_ContributorsVolume] AS t
				USING #NewPMContributorsVolume AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ContributionMonth = s.ContributionMonth
					AND t.ContributionType = s.ContributionType AND t.FreezeDate = s.FreezeDate AND t.[PK_Country] = s.[PK_Country]
					AND t.RoyaltyMonth = s.RoyaltyMonth AND t.MetricType = s.MetricType 
					AND @iCurrentDate < s.FreezeDate  
				WHEN NOT MATCHED BY TARGET 
					THEN INSERT (
						PK_Distributor,
						PK_DSDownline,
						ContributionMonth,
						ContributionType,
						FreezeDate,
						[PK_Country],
						[RoyaltyMonth],
						[MetricType],
						[PersonalPoints],
						[TransferPoints],
						[MainPoints],
						[Points])
					VALUES (
						S.PK_Distributor,
						S.PK_DSDownline,
						S.ContributionMonth,
						S.ContributionType,
						S.FreezeDate,
						S.[PK_Country],
						S.[RoyaltyMonth],
						S.[MetricType],
						S.[PersonalPoints],
						S.[TransferPoints],
						S.[MainPoints],
						S.[Points]
						)
					WHEN MATCHED AND @iCurrentDate < T.FreezeDate  THEN UPDATE SET						 
						T.[PersonalPoints]		= S.[PersonalPoints],
						T.[TransferPoints]		= S.[TransferPoints],
						T.[MainPoints]			= S.[MainPoints],
						T.[Points]				= S.[Points]
						; 
 	
			--Freeze status for guaranteed contributors 1 day prior the freeze date

				DROP TABLE IF EXISTS #NewPMContributorsStatus

				 SELECT DISTINCT
					d.PK_Distributor
					,d.PK_DSDownLine 
					,d.ContributionMonth
					,d.FreezeDate
					,s.QSQualDate 	
					,s.SPQualDate 
					,s.SPRequalDate
					,s.[CurrentTypeCode]
					,s.[TeamCode]
					,s.MBContractAcceptanceDate
					,s.ContractAcceptanceDate
					,s.ApplicationDate
					,s.MBApplicationDate
					,s.ConversionDate					  
					,s.initialAppDate
					,s.[DSREINSTATEMENTDATE]
					,s.[PMREINSTATEMENTDATE]
					,s.CONVERSIONTYPE
					,s.SubTypeCode
					,s.ConversionMonth
					,s.[EvaluationType]
					,s.EvaluationMonth
				INTO #NewPMContributorsStatus
				FROM #NewPM AS d  
				INNER JOIN [dbo].[WRK_25060_DownlineEvaluationMonth] AS s WITH (NOLOCK)
					ON d.PK_Distributor = s.PK_Distributor AND d.PK_DSDownline = s.PK_DSDownline   	
				WHERE @iCurrentDate < d.FreezeDate  
				AND s.EvaluationType = 'PM'

				MERGE [dbo].[WRK_25060_ContributorsStatus] AS t
				USING #NewPMContributorsStatus AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ContributionMonth = s.ContributionMonth
					AND t.FreezeDate = s.FreezeDate AND t.[EvaluationType] = s.[EvaluationType] AND t.EvaluationMonth = s.EvaluationMonth  
					AND @iCurrentDate < s.FreezeDate  
					WHEN NOT MATCHED BY TARGET 
					THEN INSERT (
						PK_Distributor
						,PK_DSDownLine 
						,QSQualDate 	
						,SPQualDate 
						,SPRequalDate
						,[CurrentTypeCode]
						,[TeamCode]
						,MBContractAcceptanceDate
						,ContractAcceptanceDate
						,ApplicationDate
						,MBApplicationDate
						,ConversionDate					  
						,initialAppDate
						,[DSREINSTATEMENTDATE]
						,[PMREINSTATEMENTDATE]
						,CONVERSIONTYPE
						,SubTypeCode
						,ConversionMonth
						,[EvaluationType]
						,EvaluationMonth
						,ContributionMonth
						,FreezeDate)
					VALUES (
						S.PK_Distributor
						,S.PK_DSDownLine 
						,S.QSQualDate 	
						,S.SPQualDate 
						,S.SPRequalDate
						,S.[CurrentTypeCode]
						,S.[TeamCode]
						,S.MBContractAcceptanceDate
						,S.ContractAcceptanceDate
						,S.ApplicationDate
						,S.MBApplicationDate
						,S.ConversionDate					  
						,S.initialAppDate
						,S.[DSREINSTATEMENTDATE]
						,S.[PMREINSTATEMENTDATE]
						,S.CONVERSIONTYPE
						,S.SubTypeCode
						,S.ConversionMonth
						,S.[EvaluationType]
						,S.EvaluationMonth
						,S.ContributionMonth
						,S.FreezeDate
						)
					WHEN MATCHED AND @iCurrentDate < T.FreezeDate  THEN UPDATE SET 			
						 T.QSQualDate 							= S.QSQualDate 				
						,T.SPQualDate 							= S.SPQualDate 				
						,T.SPRequalDate							= S.SPRequalDate				
						,T.[CurrentTypeCode]					= S.[CurrentTypeCode]			
						,T.[TeamCode]							= S.[TeamCode]				
						,T.MBContractAcceptanceDate				= S.MBContractAcceptanceDate	
						,T.ContractAcceptanceDate				= S.ContractAcceptanceDate	
						,T.ApplicationDate						= S.ApplicationDate			
						,T.MBApplicationDate					= S.MBApplicationDate			
						,T.ConversionDate					  	= S.ConversionDate			
						,T.initialAppDate						= S.initialAppDate	
						,T.[DSREINSTATEMENTDATE] 				= S.[DSREINSTATEMENTDATE]
						,T.[PMREINSTATEMENTDATE]				= S.[PMREINSTATEMENTDATE]		
						,T.CONVERSIONTYPE						= S.CONVERSIONTYPE			
						,T.SubTypeCode							= S.SubTypeCode				
						,T.ConversionMonth 						= S.ConversionMonth
						,T.ContributionMonth					= S.ContributionMonth
						,T.FreezeDate							= S.FreezeDate
						; 	 


			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 94;
		 			
			--// Double Bonus
			------------------------------------------------------------------------------------------------ 	

			INSERT INTO #TimeLog VALUES ('Double bonus', 5, 95, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #DoubleBonusSummary CREATE TABLE #DoubleBonusSummary(PK_Distributor INT,[DoubleBonusAmount] MONEY)

			IF @IsDevQA = 0
			BEGIN
			
				DROP TABLE IF EXISTS [dbo].[WRK_25060_DoubleBonusContributions]

				 SELECT 
					PK_Distributor,
					ContributionMonth, 
					COUNT(1) AS Contributors,
					'DS' AS [Type],
					COUNT(1) * @DSBonus [DoubleBonusAmount]
				INTO [dbo].[WRK_25060_DoubleBonusContributions]
				FROM [dbo].[WRK_25060_NewDSBonusContributors] WITH (NOLOCK)
				WHERE Active = 1  AND ContributionMonth = @DSDoubleBonusMonth  
				GROUP BY PK_Distributor,ContributionMonth
				UNION
				SELECT 
					PK_Distributor,
					ContributionMonth, 
					COUNT(1) AS Contributors,
					'PM' AS [Type],
					COUNT(1) * @PMBonus [DoubleBonusAmount] 
				FROM [dbo].[WRK_25060_NewPMBonusContributors] WITH (NOLOCK)
				WHERE Active = 1  AND ContributionMonth = @PMDoubleBonusMonth  
				GROUP BY PK_Distributor,ContributionMonth
				UNION
				SELECT 
					PK_Distributor,
					ContributionMonth, 
					COUNT(1) AS Contributors,
					'FQS' AS [Type],
					COUNT(1) * @FQSBonus [DoubleBonusAmount] 
				FROM [dbo].[WRK_25060_NewFQSBonusContributors] WITH (NOLOCK)
				WHERE Active = 1  AND ContributionMonth = @FQSDoubleBonusMonth  
				GROUP BY PK_Distributor,ContributionMonth
				UNION
				SELECT 
					PK_Distributor,
					ContributionMonth, 
					COUNT(1) AS Contributors,
					'ASP' AS [Type],
					COUNT(1) * @ASPBonus [DoubleBonusAmount] 
				FROM [dbo].[WRK_25060_NewASPBonusContributors] WITH (NOLOCK)
				WHERE Active = 1  AND ContributionMonth = @ASPDoubleBonusMonth  
				GROUP BY PK_Distributor,ContributionMonth

				INSERT INTO #DoubleBonusSummary(PK_Distributor,[DoubleBonusAmount])
				SELECT PK_Distributor, SUM([DoubleBonusAmount]) AS [DoubleBonusAmount]
				FROM [dbo].[WRK_25060_DoubleBonusContributions] AS C WITH (NOLOCK) 
				GROUP BY PK_Distributor
			
			END  

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 95;
		 
			------------------------------------------------------------------------------------------------
			-- 5.5 Assigning bonuses
			------------------------------------------------------------------------------------------------
		 
			INSERT INTO #TimeLog VALUES ('#WRK_25060_BonusSummary', 5, 51, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #WRK_25060_BonusSummary

			CREATE TABLE #WRK_25060_BonusSummary
			(
					PK_Distributor INT,
					[New DS Bonus] MONEY,
					[TotalNewDS]INT,
					[New FQS Bonus] MONEY,
					[TotalNewFQS] INT,
					[New ASP Bonus] MONEY,
					[TotalNewASP] INT,
					[New PM Bonus] MONEY,
					[TotalNewPM] INT,
					[DoubleBonus] MONEY
			)

				INSERT INTO #WRK_25060_BonusSummary(PK_Distributor,[New DS Bonus],[TotalNewDS],[New FQS Bonus],[TotalNewFQS],[New ASP Bonus],[TotalNewASP],[New PM Bonus],[TotalNewPM],[DoubleBonus])
				SELECT DISTINCT
					D.PK_Distributor,
					ISNULL(DS.[TotalBonusNewDS],0) AS [New DS Bonus],
					ISNULL(DS.[TotalNewDS],0) AS [TotalNewDS],
					ISNULL(FQS.TotalBonusNewFQS,0) AS [New FQS Bonus],
					ISNULL(FQS.[TotalNewFQS],0) AS [TotalNewFQS],
					ISNULL(ASP.[TotalBonusNewASP],0) AS [New ASP Bonus],
					ISNULL(ASP.[TotalNewASP],0) AS [TotalNewASP],
					ISNULL(PM.[TotalBonusNewPM],0) AS [New PM Bonus],
					ISNULL(PM.[TotalNewPM],0) AS [TotalNewPM],
					IIF(@DoubleBonusActive = 1, ISNULL(DB.[DoubleBonusAmount],0),0) AS [DoubleBonus]
				FROM #DS AS D
					LEFT JOIN #NewDSSSummary AS DS  
						ON D.PK_Distributor = DS.PK_Distributor		
					LEFT JOIN #NewFQSSummary AS FQS  
						ON D.PK_Distributor = FQS.PK_Distributor
					LEFT JOIN #NewASPSummary AS ASP  
						ON D.PK_Distributor = ASP.PK_Distributor
					LEFT JOIN #NewPMSummary AS PM  
						ON D.PK_Distributor = PM.PK_Distributor			 		
					LEFT JOIN #DoubleBonusSummary AS DB
						ON D.PK_Distributor = db.PK_Distributor	 

			CREATE INDEX IX_#WRK_25060_BonusSummary_PK_Distributor ON #WRK_25060_BonusSummary(PK_Distributor)
	

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 51;

			IF @IsDevQA = 0
			BEGIN

				INSERT INTO #TimeLog VALUES ('WRK_25060_BonusSummary', 5, 52, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS [dbo].[WRK_25060_BonusSummary]

				SELECT 
					PK_Distributor,
					[New DS Bonus],
					[TotalNewDS],
					[New FQS Bonus],
					[TotalNewFQS],
					[New ASP Bonus],
					[TotalNewASP],
					[New PM Bonus],
					[TotalNewPM],
					[DoubleBonus]
				INTO [dbo].[WRK_25060_BonusSummary]
				FROM #WRK_25060_BonusSummary 
								
			CREATE INDEX IX_WRK_25060_BonusSummary_PK_Distributor ON [dbo].[WRK_25060_BonusSummary](PK_Distributor)
				
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 52;
				
			END
			
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints_Summary', 5, 53, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #Event_DSPoints_Summary

			CREATE TABLE #Event_DSPoints_Summary
			(
				PK_Distributor [int],
				RoyaltyMonth [int],
				MetricType [varchar](10),
				PK_Country [int],
				[Points] [money],
				[QSVolume] [bit], 
				iSPQualDate [int],
				QualificationNumber [int],
				Part [int],
				iStartDate [int],
				iEndDate [int],
				[Countries] [varchar](max),
				[MonthIndex] [int]
			)

			INSERT INTO #Event_DSPoints_Summary(PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries,[MonthIndex])
				SELECT U.PK_Distributor,
						U.RoyaltyMonth,
						U.MetricType,
						U.PK_Country AS PK_Country,
						IIF((F.[QSVolume] = 0 AND U.RoyaltyMonth >= F.iSPQualDate) OR F.[QSVolume] IS NULL, SUM(ISNULL(U.Points,0)),0) AS [Points],  
						F.[QSVolume], 
						F.iSPQualDate,
						F.QualificationNumber,
						F.Part,
						F.iStartDate,
						F.iEndDate,
						F.Countries,
						ROW_NUMBER() OVER (PARTITION BY U.PK_Distributor,U.MetricType,U.PK_Country,F.QualificationNumber,F.Part,F.iStartDate ORDER BY U.RoyaltyMonth ASC) AS [MonthIndex]
				FROM #Event_DSPoints_Validations AS U WITH (NOLOCK) 
							INNER JOIN #tmp_DSQualDef AS F
								ON u.PK_Distributor = F.PK_Distributor	
								WHERE 
								F.MetricType = U.MetricType 
								AND 
								U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
								AND 
				(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
				GROUP BY U.PK_Distributor,U.RoyaltyMonth,U.MetricType,U.PK_Country,F.[QSVolume],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries
					
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 53;

			INSERT INTO #TimeLog VALUES ('#WRK_25060_BonusPoints', 5, 54, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #WRK_25060_BonusPoints

			--In case of multiple periods, the bonus should be assigned by period

			SELECT 
					U.PK_Distributor,
					U.RoyaltyMonth,
					U.MetricType,
					(SELECT nCountryID FROM v_Countries WHERE sCountryCode = '-W') AS PK_Country,
					ISNULL(U.Points,0) AS [Points],
					U.[QSVolume], 
					U.iSPQualDate,
					U.QualificationNumber,
					U.Part,
					U.iStartDate,
					U.iEndDate,
					U.Countries,
					IIF(@DoubleVolumeBonusActive = 1, IIF(d.sDistributorCountryProcessingCode IN ( SELECT CAST([value] AS CHAR(2)) AS [cop] FROM STRING_SPLIT(@DoubleVolumeBonusCOP,',')), IIF(U.QualificationNumber IN ( SELECT CAST([value] AS INT) AS [QId] FROM STRING_SPLIT(@DoubleVolumeBonusApplicableQuals,',')) AND U.MetricType = @DoubleVolumeBonusMetricType AND U.RoyaltyMonth = @DoubleVolumeBonusMonth, IIF( U.Points >= @DoubleVolumeBonusLimit, @DoubleVolumeBonusLimit,U.Points),0), NULL),NULL) AS [Double Volume Month],
					IIF(@DSBonusActive = 1,IIF(U.QualificationNumber IN ( SELECT CAST([value] AS INT) AS [QId] FROM STRING_SPLIT(@DSBonusApplicableQuals,',')) AND U.MetricType = @DSBonusMetricType AND U.[MonthIndex] = 1, ISNULL(BS.[New DS Bonus],0), 0), NULL) AS [New DS Bonus],
					IIF(@FQSBonusActive = 1,IIF(U.QualificationNumber IN ( SELECT CAST([value] AS INT) AS [QId] FROM STRING_SPLIT(@FQSBonusApplicableQuals,',')) AND U.MetricType = @FQSBonusMetricType AND U.[MonthIndex] = 1, ISNULL(BS.[New FQS Bonus],0), 0), NULL) AS [New FQS Bonus],
					IIF(@ASPBonusActive = 1,IIF(U.QualificationNumber IN ( SELECT CAST([value] AS INT) AS [QId] FROM STRING_SPLIT(@ASPBonusApplicableQuals,',')) AND U.MetricType = @ASPBonusMetricType AND U.[MonthIndex] = 1, ISNULL(BS.[New ASP Bonus],0), 0), NULL) AS [New ASP Bonus],
					IIF(@PMBonusActive = 1,IIF(U.QualificationNumber IN ( SELECT CAST([value] AS INT) AS [QId] FROM STRING_SPLIT(@PMBonusApplicableQuals,',')) AND U.MetricType = @PMBonusMetricType AND U.[MonthIndex] = 1, ISNULL(BS.[New PM Bonus],0), 0), NULL) AS [New PM Bonus],
					IIF(@DoubleBonusActive = 1,IIF(U.QualificationNumber IN ( SELECT CAST([value] AS INT) AS [QId] FROM STRING_SPLIT(@DoubleBonusApplicableQuals,',')) AND U.MetricType = @DoubleBonusMetricType AND U.[MonthIndex] = 1, ISNULL(BS.[DoubleBonus],0), 0), NULL) AS [DoubleBonus]
				INTO #WRK_25060_BonusPoints
				FROM #Event_DSPoints_Summary AS U WITH (NOLOCK) 
					INNER JOIN v_Distributor AS d 
						ON u.PK_Distributor = d.nDistributorID
						LEFT JOIN #WRK_25060_BonusSummary AS BS 
							ON U.PK_Distributor = BS.PK_Distributor		

			CREATE INDEX IX_#WRK_25060_BonusPoints_PK_Distributor ON #WRK_25060_BonusPoints(PK_Distributor)
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 54;

			IF @IsDevQA = 0
			BEGIN
			
				INSERT INTO #TimeLog VALUES ('WRK_25060_BonusPoints', 5, 55, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS [dbo].[WRK_25060_BonusPoints]

				--In case of multiple periods, the bonus should be assigned by period

				SELECT 
						PK_Distributor,
						RoyaltyMonth,
						MetricType,
						PK_Country,
						[Points],
						[QSVolume], 
						iSPQualDate,
						QualificationNumber,
						Part,
						iStartDate,
						iEndDate,
						Countries,
						[Double Volume Month],
						[New DS Bonus],
						[New FQS Bonus],
						[New ASP Bonus],
						[New PM Bonus],
						[DoubleBonus]
					INTO [dbo].[WRK_25060_BonusPoints]
					FROM #WRK_25060_BonusPoints	

				CREATE INDEX IX_WRK_25060_BonusPoints_PK_Distributor ON [dbo].[WRK_25060_BonusPoints](PK_Distributor)

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 5 AND [StepSubGroup] = 55;

			END

			INSERT INTO #TimeLog VALUES ('#tmp_DSPointsSummary', 5, 56, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #tmp_DSPointsSummary

				CREATE TABLE #tmp_DSPointsSummary(
					[PK_Event] [int] NULL,
					[PK_Distributor] [int] NULL,
					[RoyaltyMonth] [int] NULL,
					[MetricType] [varchar](20) NULL,
					[PK_Country] [int] NULL,
					[Points] [money] NULL,
					[Bonus] [money] NULL,
					[QSVolume] [bit] NULL, 
					[iSPQualDate] [int] NULL,
					[QualificationNumber] [int] NULL,
					[Part] [int] NULL,
					[HasBonus] [bit] NULL,
					[TotalPoints] [money] NULL,
					[iStartDate] [int] NULL,
					[iEndDate] [int] NULL,
					[Countries] [varchar](max) NULL
				)

				INSERT INTO #tmp_DSPointsSummary([PK_Event],PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate)
				SELECT 
							@PK_Event AS PK_Event,
							P.PK_Distributor,
							P.RoyaltyMonth,
							P.MetricType,
							P.PK_Country,
							P.[Points],
							P.QualificationNumber,
							P.Part,
							(ISNULL(P.[Double Volume Month],0) + ISNULL(P.[New DS Bonus],0)+ ISNULL(P.[New FQS Bonus],0)+ ISNULL(P.[New ASP Bonus],0)+ ISNULL(P.[New PM Bonus],0))  + ISNULL(P.[DoubleBonus],0)  AS [Bonus],
							ISNULL(P.[Points],0) + (ISNULL(P.[Double Volume Month],0) + ISNULL(P.[New DS Bonus],0)+ ISNULL(P.[New FQS Bonus],0)+ ISNULL(P.[New ASP Bonus],0)+ ISNULL(P.[New PM Bonus],0)  + ISNULL(P.[DoubleBonus],0)) AS [TotalPoints],
							P.iStartDate,
							P.iEndDate
						FROM #WRK_25060_BonusPoints AS P WITH (NOLOCK)

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] =56;									 
						
				IF @IsDevQA = 0
				BEGIN
					
					INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary]', 5, 57, GETUTCDATE(), NULL);
					
					DELETE t
					FROM [tmp].[DSPointsSummary] AS t
					WHERE t.PK_Event = @PK_Event

					INSERT INTO [tmp].[DSPointsSummary](PK_Event, PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate)
					SELECT 
							PK_Event,
							PK_Distributor,
							RoyaltyMonth,
							MetricType,
							PK_Country,
							[Points],
							QualificationNumber,
							Part,
							[Bonus],
							[TotalPoints],
							iStartDate,
							iEndDate
						FROM #tmp_DSPointsSummary

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 5 AND [StepSubGroup] =57;

				END
 
		END

		--Step 6: Qualifiers by volume	
		IF @Step >= 6
		BEGIN
			
			PRINT 'Executing step 6'

			------------------------------------------------------------------------------------------------
			-- 6.1 Getting qualifiers by volume according to qualification definitions
			------------------------------------------------------------------------------------------------
	
			INSERT INTO #TimeLog VALUES ('Qualifiers by volume', 6, 1, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #Executions

			CREATE TABLE #Executions(
				PK_Execution INT IDENTITY(1,1),
				PK_Event INT,
				OverwritePointsSummary BIT,
				QualType SMALLINT,
				Done BIT DEFAULT(0)
			)

			DROP TABLE IF EXISTS #Event_DSQualPoints

			CREATE TABLE #Event_DSQualPoints
			(
				[PK_Event] [int] NULL,
				[PK_Distributor] [int] NULL,
				[QualificationNumber] [int] NULL,
				[Part] [int] NULL,
				[QualDate] [datetime2](7) NULL
			)

			DECLARE @QualType SMALLINT  --1 = Accumulated/Non-Consecutive, 2 = Accumulated/Consecutive, 3 = Achieve/Consecutive, 4 = Achieve/Non-Consecutive
					,@PK_Execution INT
					,@PK_Event_Execution INT
					,@OverwritePointsSummary BIT

				DELETE FROM #Executions

				INSERT INTO #Executions(PK_Event,OverwritePointsSummary,QualType)
				SELECT DISTINCT
					PK_Event, 
					0 AS OverwritePointsSummary,
					 IIF(Accumulated = 0 AND Consecutive = 0, 4, --Achieve Non-Consecutive
						IIF( Accumulated = 0 AND Consecutive = 1, 3, --Achieve Consecutive
							IIF(Accumulated = 1 AND Consecutive = 1, 2, --Accumulated Consecutive
								IIF(Accumulated = 1 AND Consecutive = 0, 1,NULL)))) --Accumulated Non-Consecutive
						AS QualType 
				FROM #Event_SetupEventQualification
					 
				WHILE EXISTS (SELECT 1 FROM #Executions WHERE Done = 0)
				BEGIN

					SELECT TOP 1 
						@PK_Execution = PK_Execution,
						@QualType = QualType,
						@PK_Event_Execution = PK_Event,
						@OverwritePointsSummary = OverwritePointsSummary
					FROM #Executions 
					WHERE Done = 0

				IF @IsDevQA = 0
				BEGIN
					 
					 --Input [tmp].[DSPointsSummary]
					EXEC dbo.usp_GetQualifier_Points @PK_Event = @PK_Event_Execution, @QualType = @QualType, @OverwritePointsSummary = @OverwritePointsSummary, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					--Output [Event].[DSQualPoints]
				END
		
				UPDATE #Executions
				SET Done = 1
				WHERE PK_Execution = @PK_Execution

				END
					 
				IF @IsDevQA = 0	
				BEGIN			 
					INSERT INTO #Event_DSQualPoints(PK_Event,PK_Distributor,QualificationNumber,Part,QualDate)
					SELECT 
						PK_Event
						,PK_Distributor
						,QualificationNumber 
						,Part		
						,QualDate
					FROM [Event].[DSQualPoints] AS Q WITH (NOLOCK)
					WHERE PK_Event = @PK_Event
				END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 6 AND [StepSubGroup] = 1;
		END
		
		--Step 7: Qualifications
		IF @Step >= 7
		BEGIN
			
			PRINT 'Executing step 7'

			INSERT INTO #TimeLog VALUES ('Qualifications', 7, 1, GETUTCDATE(), NULL);

			------------------------------------------------------------------------------------------------
			-- List qualifications
			------------------------------------------------------------------------------------------------
			IF EXISTS (SELECT 1 FROM #ListsIDs) 
			BEGIN

				DROP TABLE IF EXISTS #UniqueListID

				SELECT DISTINCT ListID,IDENTITY(INT,1,1) AS ID  
				INTO #UniqueListID
				FROM #ListsIDs
				ORDER BY ListID

				SET @ColumnToPivot = ''
				SET @SqlStatement = ''

				SELECT 
					@ColumnToPivot+=QUOTENAME(m.ListID) + ','
				FROM 
					#UniqueListID AS  m
				ORDER BY 
					ListID;
									
				SET @ColumnToPivot = LEFT(@ColumnToPivot, LEN(@ColumnToPivot) - 1); -- remove the last comma
							 
				DROP TABLE IF EXISTS ##DSList_Pivot				
 
				SET @SqlStatement = N'SELECT A.PK_Distributor AS [PK_Distributor_List], A.PK_Event AS [PK_Event_List], ' + @ColumnToPivot  + 
				'INTO ##DSList_Pivot' +
				' FROM #EventQual A
				LEFT JOIN 
				(
					SELECT  PK_Distributor, PK_Event,' + @ColumnToPivot +' FROM 
					(
						SELECT  PK_Distributor,PK_Event, ListID, UniqueID
							FROM #DSList
					) P
					PIVOT
					(
					COUNT (UniqueID)
					FOR ListID IN
					( 
						'+ @ColumnToPivot +')
					) AS pvt
				) L
				ON A.PK_Distributor = L.PK_Distributor AND A.PK_Event = L.PK_Event'

				EXECUTE sp_executesql @SqlStatement
 
				IF OBJECT_ID('tempdb..##DSList_Pivot') IS NOT NULL
				BEGIN

					--) Setting default values on lists fields

					SET @SqlStatement = 'UPDATE P SET '

					SELECT 	@SqlStatement+=QUOTENAME(m.ListID) + '= ISNULL('+QUOTENAME(m.ListID)+',0), '
					FROM #UniqueListID AS  m
					ORDER BY m.ListID;

					SET @SqlStatement = LEFT(@SqlStatement, LEN(@SqlStatement) - 1) -- remove the last comma
					SET @SqlStatement= @SqlStatement + ' FROM ##DSList_Pivot AS P'

					EXECUTE sp_executesql @SqlStatement

				END

				DROP TABLE IF EXISTS #ListsQualificationMapping

				SELECT QColumn = 'Q' +   IIF(QId < 10,  '0' + CAST(QId AS VARCHAR), CAST(QId  AS VARCHAR)), ListID 
				INTO #ListsQualificationMapping
				FROM #ListsQsMapping
			
				SET @SqlStatement = '';					

				SELECT  @SqlStatement += N'IF NOT EXISTS (SELECT 1 FROM tempdb.sys.columns WITH (NOLOCK) WHERE [object_id] = object_id(''tempdb..#EventQual'') AND name ='''+ [QColumn] +''') BEGIN ALTER TABLE #EventQual ADD [' + [QColumn] + '] BIT DEFAULT 0; END; '
				FROM #ListsQualificationMapping AS M

				EXECUTE sp_executesql @SqlStatement

				SET @SqlStatement = '';

				SELECT  @SqlStatement+= 'UPDATE E ' +
						' SET ' + [QColumn] + ' = L.[' + CAST(ListID AS NVARCHAR(MAX))  + ']' +
						' FROM #EventQual AS E INNER JOIN ##DSList_Pivot AS L
						ON E.PK_Event = L.PK_Event_List 
						AND E.PK_Distributor = L.PK_Distributor_List;'					
				FROM #ListsQualificationMapping AS M
			 	
				EXECUTE sp_executesql @SqlStatement

			END
	
			------------------------------------------------------------------------------------------------
			-- SKUs qualifications
			------------------------------------------------------------------------------------------------
			IF EXISTS (SELECT 1 FROM #SKUs)
			BEGIN
			
				DROP TABLE IF EXISTS #UniqueSKUsID

				SELECT DISTINCT SKUCode,IDENTITY(INT,1,1) AS ID  
				INTO #UniqueSKUsID
				FROM #SKUs

				SET @ColumnToPivot = ''
				SET @SqlStatement = ''

				SELECT 
					@ColumnToPivot+=QUOTENAME(m.SKUCode) + ','
				FROM 
					#UniqueSKUsID AS  m
				ORDER BY 
					SKUCode;
									
				SET @ColumnToPivot = LEFT(@ColumnToPivot, LEN(@ColumnToPivot) - 1); -- remove the last comma
							 
				DROP TABLE IF EXISTS ##DSSKU_Pivot				
 
				SET @SqlStatement = N'SELECT A.PK_Distributor AS [PK_Distributor_SKU], A.PK_Event AS [PK_Event_SKU], ' + @ColumnToPivot  + 
				'INTO ##DSSKU_Pivot' +
				' FROM #EventQual A
				LEFT JOIN 
				(
					SELECT  PK_Distributor, PK_Event,' + @ColumnToPivot +' FROM 
					(
						SELECT  PK_Distributor,PK_Event, SKUCode, UniqueID
							FROM #DSSKUs
					) P
					PIVOT
					(
					COUNT (UniqueID)
					FOR SKUCode IN
					( 
						'+ @ColumnToPivot +')
					) AS pvt
				) L
				ON A.PK_Distributor = L.PK_Distributor AND A.PK_Event = L.PK_Event'

				EXECUTE sp_executesql @SqlStatement
 
				IF OBJECT_ID('tempdb..##DSSKU_Pivot') IS NOT NULL
				BEGIN

					--) Setting default values on lists fields

					SET @SqlStatement = 'UPDATE P SET '

					SELECT 	@SqlStatement+=QUOTENAME(m.SKUCode) + '= ISNULL('+QUOTENAME(m.SKUCode)+',0), '
					FROM #UniqueSKUsID AS  m
					ORDER BY m.SKUCode;

					SET @SqlStatement = LEFT(@SqlStatement, LEN(@SqlStatement) - 1) -- remove the last comma
					SET @SqlStatement= @SqlStatement + ' FROM ##DSSKU_Pivot AS P'

					EXECUTE sp_executesql @SqlStatement

				END

				DROP TABLE IF EXISTS #SKUsQualificationMapping

				SELECT QColumn = 'Q' +   IIF(QId < 10,  '0' + CAST(QId AS VARCHAR), CAST(QId  AS VARCHAR)),SKUCode, PK_Event 
				INTO #SKUsQualificationMapping
				FROM #SKUsQsMapping
			 
	
				SET @SqlStatement = '';
	
				SELECT  @SqlStatement += N'IF NOT EXISTS (SELECT 1 FROM tempdb.sys.columns WITH (NOLOCK) WHERE [object_id] = object_id(''tempdb..#EventQual'') AND name ='''+ [QColumn] +''') BEGIN ALTER TABLE #EventQual ADD [' + [QColumn] + '] BIT DEFAULT 0; END; '
				FROM #SKUsQualificationMapping AS M

				EXECUTE sp_executesql @SqlStatement

				SET @SqlStatement = '';

				SELECT  @SqlStatement+= 'UPDATE E ' +
					 ' SET ' + [QColumn] + ' = ' + STRING_AGG('L.[' + CAST(SKUCode AS NVARCHAR(MAX))  + ']' , ' | ') +
					 ' FROM #EventQual AS E INNER JOIN ##DSSKU_Pivot AS L
						ON E.PK_Event = L.PK_Event_SKU 
						AND E.PK_Distributor = L.PK_Distributor_SKU;'					
				FROM #SKUsQualificationMapping AS M
				GROUP BY QColumn
			 	
				EXECUTE sp_executesql @SqlStatement
		
			END	
			
			------------------------------------------------------------------------------------------------
			-- Volume qualifications
			------------------------------------------------------------------------------------------------
			BEGIN
			
			DROP TABLE IF EXISTS #QualificationsMapping

			SELECT 
			IDENTITY(INT,1,1) AS ID, 
			PK_Event,QualificationNumber,[Part], 
			IIF(QualificationNumber < 10, 'Q0' + CAST(QualificationNumber AS VARCHAR(5)), 'Q' + CAST(QualificationNumber AS VARCHAR(5))) AS  QColumn, 
			0 AS [ctrl]
			INTO #QualificationsMapping
			FROM #Event_SetupEventQualification
			WHERE QualificationNumber <= 50
			
			--Getting qualifiers by qualification number
		
			DECLARE @QualificationNumber INT, @QPK_Event INT, @ID INT, @QPart INT, @QColumn VARCHAR(10)

			WHILE EXISTS (SELECT 1 FROM #QualificationsMapping AS m WHERE [ctrl] = 0 AND Part = 1)
			BEGIN
					
				SELECT @ID = MIN(ID) FROM #QualificationsMapping AS m WHERE [ctrl] = 0 AND Part = 1

				SELECT 
					@QualificationNumber = m.QualificationNumber,
					@QPK_Event = m.PK_Event,
					@QColumn = m.QColumn
				FROM #QualificationsMapping AS m WHERE [ID] = @ID

				DROP TABLE IF EXISTS #QAdditionalParts

				SELECT PK_Event,QualificationNumber,Part, 0 AS [ctrl] 
				INTO #QAdditionalParts
				FROM #QualificationsMapping AS m 
				WHERE PK_Event = @QPK_Event AND QualificationNumber = @QualificationNumber AND Part != 1

				DROP TABLE IF EXISTS ##QualVolumeQualifiers

				SET @SqlStatement = ''

				SET @SqlStatement = N'SELECT Q1.PK_Event,Q1.PK_Distributor	
				INTO ##QualVolumeQualifiers
				FROM #Event_DSQualPoints AS Q1 WHERE (Q1.QualificationNumber = '+ CAST(@QualificationNumber AS VARCHAR(10)) +' AND Q1.Part = 1 AND Q1.PK_Event =' + CAST(@QPK_Event AS VARCHAR(10)) +' ) '
					
				IF @SqlStatement != ''
				BEGIN
					WHILE EXISTS (SELECT 1 FROM #QAdditionalParts WHERE [ctrl] = 0)
					BEGIN

						SELECT @QPart = Part FROM #QAdditionalParts WHERE [ctrl] = 0 AND QualificationNumber = @QualificationNumber

						SET @SqlStatement += ' AND EXISTS ( SELECT Q'+ CAST(@QPart AS VARCHAR(5)) +'.PK_Distributor FROM #Event_DSQualPoints AS Q'+ CAST(@QPart AS VARCHAR(5)) +'  
						WHERE (Q'+ CAST(@QPart AS VARCHAR(5)) +'  .QualificationNumber = '+ CAST(@QualificationNumber AS VARCHAR(10)) +' AND Q'+CAST(@QPart AS VARCHAR(10))+'.Part = '+ CAST(@QPart AS VARCHAR(10)) +')
						AND Q1.PK_Distributor = Q'+ CAST(@QPart AS VARCHAR(5)) +'.PK_Distributor AND Q1.QualificationNumber = Q'+ CAST(@QPart AS VARCHAR(5)) +'.QualificationNumber AND Q1.PK_Event = Q'+ CAST(@QPart AS VARCHAR(5)) +'.PK_Event)'

						UPDATE #QAdditionalParts
						SET [ctrl] = 1
						WHERE QualificationNumber = @QualificationNumber AND Part = @QPart

					END
												
				END

				EXECUTE sp_executesql @SqlStatement

				SET @SqlStatement = ''

				SET @SqlStatement = 'UPDATE Q
				SET ' + @QColumn + ' = 1' +
				' FROM #EventQual Q
				INNER JOIN ##QualVolumeQualifiers AS QQ
				ON Q.PK_Event = QQ.PK_Event
				AND Q.PK_Distributor = QQ.PK_Distributor'

				EXECUTE sp_executesql @SqlStatement

				UPDATE #QualificationsMapping
				SET [ctrl] = 1
				WHERE ID = @ID

			END

			END

			------------------------------------------------------------------------------------------------
			-- Other qualifications
			------------------------------------------------------------------------------------------------
			BEGIN
			 
			--Q11	Qualified to 2024 Premier League Program 2024 (PK ID 199427) OR Premier League Program 2025 up to July 1st, 2025 (PK ID 202477)

			DROP TABLE IF EXISTS #Q11

			;WITH cte_PremierLeague_Qualifiers AS
			(
				SELECT PK_Distributor FROM Promo.WRK_PremierLeague_SubEvent WITH (NOLOCK) WHERE ContributingYear = 2024 AND SubEvent = 1 
				UNION
				SELECT PK_Distributor FROM Promo.WRK_HPL2025_SubEvent WITH (NOLOCK) WHERE ContributingYear = 2025 AND SubEvent IN (1,2) AND DateQualified BETWEEN 202501 AND 202507
			)

			SELECT DISTINCT d.PK_Distributor
			INTO #Q11
			FROM #DS AS d
				INNER JOIN cte_PremierLeague_Qualifiers AS plq
					ON d.PK_Distributor = plq.PK_Distributor 

			 CREATE INDEX IX_#Q11_PK_Distributor ON #Q11(PK_Distributor);

			 UPDATE E
			 SET 
				 Q11 = 1
			 FROM #EventQual AS E
				INNER JOIN #Q11 AS Q11
				ON E.PK_Distributor = Q11.PK_Distributor	

			--Q12	Qualify or ReQualify to the “23080 - WT 1% Bonus Promotion" (event ID 195390) with qual dates from Jan 1st, 2024 to July 1st, 2025

			DROP TABLE IF EXISTS #Q12

			 SELECT DISTINCT T.PK_Distributor 
			 INTO #Q12
			 FROM #DS AS t  
 			 INNER JOIN dbo.WTOnePercent_Qualifiers_Tracking AS a WITH (NOLOCK)
 	 			ON t.PK_Distributor = a.PK_Distributor   
 			 WHERE QualifiedYear = 2024  
			 UNION
			 SELECT DISTINCT T.PK_Distributor 		 
			 FROM #DS AS t  
 			 INNER JOIN dbo.WTOnePercent_Qualifiers_Tracking AS a WITH (NOLOCK)
 	 			ON t.PK_Distributor = a.PK_Distributor   
 			 WHERE QualifiedYear = 2025 AND ([Jan] = 1 OR [Feb] = 1 OR [Mar] = 1 OR [Apr] = 1 OR a.[May] = 1 OR a.[Jun] = 1 OR a.[Jul] = 1)

			 CREATE INDEX IX_#Q12_PK_Distributor ON #Q12(PK_Distributor);

			 UPDATE E
			 SET 
				 Q12 = 1
			 FROM #EventQual AS E
				INNER JOIN #Q12 AS Q12
				ON E.PK_Distributor = Q12.PK_Distributor	

			 --Q15 Applicable ONLY for NAM Purchasers

				UPDATE #EventQual
				SET Q15 = 0
				WHERE Q15 = 1 AND (Q13 = 0 AND Q14 = 0)
			
			END
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 1;

		END
			
		--Step 8: Subevents
		IF @Step >= 8
		BEGIN

			PRINT 'Executing step 8'

			INSERT INTO #TimeLog VALUES ('Es #EventQual', 8, 1, GETUTCDATE(), NULL);

			UPDATE 
				#EventQual
			SET
				E01 = (Q01 | Q10),
				E02 = (Q04 | Q10),
				E03 = (Q03 | Q12 | Q10)

			UPDATE 
				#EventQual
			SET 
				E06 = ((Q02 & Q05 & Q06 & Q09 & Q14) | (Q02 & Q05 & Q09 & Q13) | Q10 | (Q04 & Q16))

			UPDATE 
				#EventQual
			SET 
				E05 =(((Q02 & Q05 & Q06 & Q08 & Q14) | (Q02 & Q05 & Q08 & Q13)) & (~E06))

			UPDATE 
				#EventQual
			SET 
				E04 = (((Q02 & Q05 & Q06 & Q07 & Q14) | (Q02 & Q05 & Q07 & Q13)) & (~E05 & ~E06))

			UPDATE 
				#EventQual
			SET
				E07 = (E06 | (Q04 & Q16) | Q24),
				E08 = ((Q11 & Q15 & (Q13 | Q14)) | Q19),
				E09 = (Q12 | Q20),
				E10 = ((E01 & Q17) | Q22),
				E11 = ((E01 & Q18) | Q23),
				E12 = (Q10 & Q21),
				E13 = (Q25),
				E14 = (Q26),
				E15 = (Q27)

				DELETE FROM #EventQual
							WHERE ( 
									~Q01  & ~Q02 & ~Q03 & ~Q04 & ~Q05 &
									~Q06  & ~Q07 & ~Q08 & ~Q09 & ~Q10 &
									~Q11  & ~Q12 & ~Q13 & ~Q14 & ~Q15 &
									~Q16  & ~Q17 & ~Q18 & ~Q19 & ~Q20 &
									~Q21  & ~Q22 & ~Q23 & ~Q24 & ~Q25 &
									~Q26  & ~Q27 & ~Q28 & ~Q29 & ~Q30 &
									~Q31  & ~Q32 & ~Q33 & ~Q34 & ~Q35 &
									~Q36  & ~Q37 & ~Q38 & ~Q39 & ~Q40 &
									~Q41  & ~Q42 & ~Q43 & ~Q44 & ~Q45 &
									~Q46  & ~Q47 & ~Q48 & ~Q49 & ~Q50 
								)= 1

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 8 AND [StepSubGroup] = 1;

		END

		--Step 10: [Event].[DSQual]	
		IF @Step >= 10
		BEGIN
			
			PRINT 'Executing step 10'

			IF @IsDevQA = 0
			BEGIN

				DELETE dq			
				FROM [Event].[DSQual] AS dq
					INNER JOIN #Locations AS l
						ON dq.PK_Event = l.PK_Event

				INSERT INTO [Event].[DSQual](
					PK_Event		
					,PK_Distributor	
					,CreatedDate	
					,UpdatedDate	
					,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10			
					,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20
					,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30
					,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40
					,Q41,Q42,Q43,Q44,Q45,Q46,Q47,Q48,Q49,Q50					
					,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10
					,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20
					,E21,E22,E23,E24,E25,E26,E27,E28,E29,E30
					,E31,E32,E33,E34,E35,E36,E37,E38,E39,E40
					,E41,E42,E43,E44,E45,E46,E47,E48,E49,E50
					)
					SELECT
					 l.PK_Event	
					,PK_Distributor	
					,CreatedDate	
					,UpdatedDate	
					,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10			
					,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20
					,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30
					,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40
					,Q41,Q42,Q43,Q44,Q45,Q46,Q47,Q48,Q49,Q50					
					,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10
					,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20
					,E21,E22,E23,E24,E25,E26,E27,E28,E29,E30
					,E31,E32,E33,E34,E35,E36,E37,E38,E39,E40
					,E41,E42,E43,E44,E45,E46,E47,E48,E49,E50
				FROM #EventQual
				CROSS APPLY #Locations AS l
				
				DROP TABLE IF EXISTS [tmp].[DSQual]  

				SELECT
					 l.PK_Event	
					,PK_Distributor	
					,CreatedDate	
					,UpdatedDate	
					,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10			
					,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20
					,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30
					,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40
					,Q41,Q42,Q43,Q44,Q45,Q46,Q47,Q48,Q49,Q50					
					,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10
					,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20
					,E21,E22,E23,E24,E25,E26,E27,E28,E29,E30
					,E31,E32,E33,E34,E35,E36,E37,E38,E39,E40
					,E41,E42,E43,E44,E45,E46,E47,E48,E49,E50
				INTO [tmp].[DSQual]
				FROM #EventQual
				CROSS APPLY #Locations AS l

				CREATE INDEX IX_tmp_DSQual_PK_Event ON [tmp].[DSQual](PK_Event);

			END
 
		END

		--Step 11: SubEventQualifiers
		IF @Step >= 11 
		BEGIN

			INSERT INTO #TimeLog VALUES ('SubEventQualifier', 11, 1, GETUTCDATE(), NULL);

			IF @IsDevQA = 0
			BEGIN

				PRINT 'Executing step 11'
		
				DECLARE @Events VARCHAR(MAX)
				
				SELECT @Events = STRING_AGG(PK_Event,',') FROM #Locations

				EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
				@Events = @Events,
				@Source = 2,
				@EvaluateFormula = 0

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 11 AND [StepSubGroup] = 1;
		END

	END
 
	/******************************************************************************
				END PROCEDURE
	******************************************************************************/
		
		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
		 	@StoredProcedureName = @StoredProcedure
		 	,@StartTime = @StartTime;

		SELECT 
		 	[Milestone]		
		 	,[StepGroup]	
		 	,[StepSubGroup] 
		 	,[StepStart]	
		 	,[Duration]		
		FROM #TimeLog
		
		IF ISNULL(@CleanUp,1) = 1
		BEGIN 
			TRUNCATE TABLE [tmp].[DSQualDef]
			TRUNCATE TABLE [tmp].[DSPointsSummary]
			TRUNCATE TABLE [tmp].[DSSummary] 
			TRUNCATE TABLE [tmp].[DS] 

			DROP TABLE IF EXISTS [#Event_DSQualPoints];
			DROP TABLE IF EXISTS [#ListsQsMapping];
			DROP TABLE IF EXISTS [#SKUsQsMapping];
			DROP TABLE IF EXISTS [#Event_DownlinesPoints];
			DROP TABLE IF EXISTS [#Event_DSPoints_Validations];
			DROP TABLE IF EXISTS [#TimeLog];
			DROP TABLE IF EXISTS [#tmp_DSQualDef];
			DROP TABLE IF EXISTS [#EventQual];
			DROP TABLE IF EXISTS [#DSDownlines];
			DROP TABLE IF EXISTS [#UniqueListID];
			DROP TABLE IF EXISTS [#DSAssociatedDownlines];
			DROP TABLE IF EXISTS [#Countries];
			DROP TABLE IF EXISTS [#ListsQualificationMapping];
			DROP TABLE IF EXISTS [#DSDownlinesSummary];
			DROP TABLE IF EXISTS [#NewDSSSummary];
			DROP TABLE IF EXISTS [#DS];
			DROP TABLE IF EXISTS [#DSForEvaluation];
			DROP TABLE IF EXISTS [#NewDS];
			DROP TABLE IF EXISTS [#dimMemberConversion];
			DROP TABLE IF EXISTS [#QualificationsMapping];
			DROP TABLE IF EXISTS [#ASPNewQualifiers];
			DROP TABLE IF EXISTS [#NewDSOverwrite];
			DROP TABLE IF EXISTS [#DownlineEvaluationDates];
			DROP TABLE IF EXISTS [#NewDSContributorsVolume_Debug];
			DROP TABLE IF EXISTS [#DownlineEvaluationMonth];
			DROP TABLE IF EXISTS [#NewDSContributorsStatus_Debug];
			DROP TABLE IF EXISTS [#DSList];
			DROP TABLE IF EXISTS [#WRK_25060_DownlineApplicationDates];
			DROP TABLE IF EXISTS [#NewFQSSummary];
			DROP TABLE IF EXISTS [#ListsIDs];
			DROP TABLE IF EXISTS [#WRK_25060_DownlineEvaluationMonth];
			DROP TABLE IF EXISTS [#NewFQS];
			DROP TABLE IF EXISTS [#DSSKUs];
			DROP TABLE IF EXISTS [#QAdditionalParts];
			DROP TABLE IF EXISTS [#DownlinesEvaluationPeriod];
			DROP TABLE IF EXISTS [#SKUs];
			DROP TABLE IF EXISTS [#NewFQSOverwrite];
			DROP TABLE IF EXISTS [#NewASPSummary];
			DROP TABLE IF EXISTS [#NewASP];
			DROP TABLE IF EXISTS [#NewASPOverwrite];
			DROP TABLE IF EXISTS [#NewPMSummary];
			DROP TABLE IF EXISTS [#NewPM];
			DROP TABLE IF EXISTS [#Locations];
			DROP TABLE IF EXISTS [#NewPMOverwrite];
			DROP TABLE IF EXISTS [#DoubleBonusSummary];
			DROP TABLE IF EXISTS [#WRK_25060_DoubleBonusContributions];
			DROP TABLE IF EXISTS [#Event_SetupEventQualification];
			DROP TABLE IF EXISTS [#WRK_25060_BonusSummary];
			DROP TABLE IF EXISTS [#tmp_DS];
			DROP TABLE IF EXISTS [#Event_DSPoints_Summary];
			DROP TABLE IF EXISTS [#Event_DSPoints];
			DROP TABLE IF EXISTS [#WRK_25060_BonusPoints];
			DROP TABLE IF EXISTS [#tmp_DSPointsSummary];
			DROP TABLE IF EXISTS [#Executions];
		END

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
END CATCH;
END
   

 