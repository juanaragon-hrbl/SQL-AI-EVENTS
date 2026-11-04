CREATE PROCEDURE [dbo].[usp_EventQual_MexicoRegionalVacation_2026]
	@PK_Event INT = NULL
	 ,@Parameters NVARCHAR(MAX)
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_MexicoRegionalVacation_2026

	USE:		

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000),
					@Parameters NVARCHAR(MAX) = N'{
					"pkEvent":201100,
					"teamFreezeDate":202501,
					"step":11,
					"currentDate":null,
					"isJulyDoubleBonusActive":1,
					"isNewDSBonusActive":1,
					"convertionsAllowed":0,
					"newDS_bonus":2000,
					"newDS_appDateStart":202508,
					"newDS_appDateEnd":202508,
					"newDS_freezeCutDays":15
					}'

			EXEC dbo.usp_EventQual_MexicoRegionalVacation_2026 
					@Parameters = @Parameters,
					@Error = @Error OUTPUT,
					@ErrorMessage = @ErrorMessage OUTPUT

			SELECT	@Error AS N'@Error',
					@ErrorMessage AS N'@ErrorMessage'

			GO

	DESCRIPTION: 

	NOTES:	
		
	OUTPUT TABLES:
		[tmp].[DS]		
		[tmp].[DSQualDef]
		[tmp].[DSPointsSummary]

		[Event].[DSPoints]
		[Event].[DSQualPoints]
		[Event].[DSQual]

	TEMPORARY TABLES:
		#Event_SetupEventQualification
		#tmp_DS
		#SummaryPoints
		#Event_DSPoints
		#Event_DSPoints_Validations
		#tmp_DSQualDef
		#tmp_DSPointsSummary

	DEBUG OBJECT:
		##DSQualPoints_jgue
		##tmp_DS_jgue
		##Event_SetupEventQualification_jgue
		##tmp_DSQualDef_jgue
		##Event_DSPoints_jgue
		##DSPointsSummary_jgue

		##usp_GetDSVolume_jgue
	
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


	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2025-02-18		juangue		Initial - BRD V1	
	1.0.1	2025-04-01		juangue		#1410012 Minums (TVP and RO) not calculated as expected	
	1.0.2	2025-04-01		juangue		#1410010 Freeze not applied over Q1-Q5
	1.0.3	2025-04-01		juangue		#1410011 Q1 not being calculated as expected
	1.0.4	2025-04-02		juangue		For Q5 TeamCode and ~Q14 on the formulas
	1.0.5	2025-04-03		juangue		NOLOCK added
	2.0.0	2025-04-22		juangue		BRD v2
	2.0.1	2025-09-30		juangue		#1428294 Tracker missing Volume Points & Qualified Members in all SubEvents (shared.DSSNAPSHOT)
	***********************************************************************************************************************************/
	
	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_jgue') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetDSVolume_jgue] is missing, create it manually' AS [Error]
	END

	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetQualifier_Points_jgue') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetQualifier_Points_jgue] is missing, create it manually' AS [Error]
	END

	IF @IsDevQA = 3 AND ( OBJECT_ID('tempdb.dbo.##DSQualPoints_jgue') IS NULL OR 
		OBJECT_ID('tempdb.dbo.##tmp_DS_jgue') IS NULL OR
		OBJECT_ID('tempdb.dbo.##Event_SetupEventQualification_jgue') IS NULL OR
		OBJECT_ID('tempdb.dbo.##Event_DSPoints_jgue') IS NULL OR
		OBJECT_ID('tempdb.dbo.##DSPointsSummary_jgue') IS NULL)
	BEGIN
		SELECT 'Temp tables are missing, create them manually' AS [Error]
		SET @ErrorMessage = 'Temp tables are missing, create them manually'
	END

	SET NOCOUNT ON;

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
				
	SELECT @Error = 0, @ErrorMessage = '';	
	   
BEGIN TRY

	-- Variables for json values

	DECLARE 
		@TeamFreezeDate INT,
		@Step INT,
		@iCurrentDate INT, 
		@IsJulyDoubleBonusActive BIT, 
		@IsNewDSBonusActive bit, 
		@ConvertionsAllowed BIT
		--New DS Bonus  	 
		,@DSBonusAppDateStart INT 
		,@DSBonusAppDateEnd INT 
		,@DSFreezeCutDays INT
		,@DSBonus MONEY

	-- Getting parameters values for json
		SELECT 
			@PK_Event = g.pkEvent, 
			@TeamFreezeDate = g.teamFreezeDate,
			@Step = g.step,
			@iCurrentDate =  LEFT( CAST(CONVERT(varchar(6),g.currentDate, 112) AS int),6),
			@ConvertionsAllowed = g.convertionsAllowed,
			@IsJulyDoubleBonusActive = g.isJulyDoubleBonusActive,
			@IsNewDSBonusActive = g.isNewDSBonusActive,
			--New DS Bonus  	 
			@DSBonusAppDateStart = g.newDSAppDateStart, 
			@DSBonusAppDateEnd = g.newDSAppDateEnd, 
			@DSFreezeCutDays = g.[newDSfreezeCutDays],
			@DSBonus = g.[newDSBonus]

		FROM OPENJSON(@Parameters)
		WITH (
				pkEvent INT '$.pkEvent',
				teamFreezeDate INT '$.teamFreezeDate',
				step INT '$.step',
				currentDate datetime '$.currentDate',
				convertionsAllowed BIT '$.convertionsAllowed',
				isJulyDoubleBonusActive BIT '$.isJulyDoubleBonusActive',
				isNewDSBonusActive BIT '$.isNewDSBonusActive',
				--New DS
				[newDSBonus] MONEY '$.newDS_bonus',
				newDSAppDateStart INT '$.newDS_appDateStart',
				newDSAppDateEnd INT '$.newDS_appDateEnd',
				[newDSfreezeCutDays] INT '$.newDS_freezeCutDays'

			) AS g
	 
		-- Default values
		SET @PK_Event = IIF(@PK_Event IS NULL,201100, @PK_Event)
		SET @TeamFreezeDate = IIF(@TeamFreezeDate IS NULL,202501, @TeamFreezeDate)
		SET @Step = IIF(@Step IS NULL,11, @Step)
		SET @iCurrentDate = IIF(@iCurrentDate IS NULL, LEFT( CAST(CONVERT(varchar(6),GETUTCDATE(), 112) AS int),6), @iCurrentDate)
		SET @DSBonusAppDateStart = IIF(@DSBonusAppDateStart IS NULL,202508, @DSBonusAppDateStart)
		SET @DSBonusAppDateEnd = IIF(@DSBonusAppDateEnd IS NULL,202508, @DSBonusAppDateEnd)
		SET @DSFreezeCutDays = IIF(@DSFreezeCutDays IS NULL,15, @DSFreezeCutDays)
		SET @DSBonus = IIF(@DSBonus IS NULL,2000, @DSBonus)
		SET @IsJulyDoubleBonusActive = IIF(@IsJulyDoubleBonusActive IS NULL,1, @IsJulyDoubleBonusActive)
		SET @IsNewDSBonusActive = IIF(@IsNewDSBonusActive IS NULL,1, @IsNewDSBonusActive)
		SELECT
			@TeamFreezeDate										AS [TeamFreezeDate],
			--New DS Bonus  	 									 
			@DSBonusAppDateStart 								AS [DSBonusAppDateStart], 
			@DSBonusAppDateEnd 									AS [DSBonusAppDateEnd], 
			@DSFreezeCutDays									AS [DSFreezeCutDays],
			@DSBonus											AS [DSBonus],
			@IsJulyDoubleBonusActive							AS [IsJulyDoubleBonusActive],
			@IsNewDSBonusActive									AS [IsNewDSBonusActive]

	--Quals block
	BEGIN 

		--Variables and temp tables 
		BEGIN

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
			[QSVolumePercentage]	int,
			[PeriodType]			tinyint, -- 1 Fixed period, 2 Relative period base on SPQualDate
			[MetricTypeDefinition]		VARCHAR(50) NULL
		)

		DECLARE 
			@iStartDate int,
			@dStartDate datetime,
			@iEndDate int,
			@dEndDate datetime,
			@DSCountries VARCHAR(MAX),
			@MetricType VARCHAR(MAX) 

		DECLARE 
			@QualPeriodAStart DATE = '2025-01-01'
			,@QualPeriodAEnd DATE = '2025-12-01'		
		
		--Bonus is applicable to Q6,Q7,Q8,Q9,Q10,Q11,Q12,Q13

		DECLARE 
			@BonusApplicableFrom INT = 6,
			@BonusApplicableTo INT = 13

		--Q6	Accumulate 70,000 Vacation Points during qual period with a minimum of 30,000 TVP (Jan 2025 ? Dec 2025) and a minimum of 1,500 ROs (Jan 2025 ? Dec 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			6					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			70000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV,RO'			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			6					AS QualificationNumber,
			2					AS Part, 
			'TV'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			30000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			6					AS QualificationNumber,
			3					AS Part, 
			'RO'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			1500				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q7	Accumulate 100,000 Vacation Points during qual period with a minimum of 36,000 TVP (Jan 2025 ? Dec 2025) and a minimum of 9,000 ROs (Jan 2025 ? Dec 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			7					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			100000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV,RO'			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			7					AS QualificationNumber,
			2					AS Part, 
			'TV'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			36000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			7					AS QualificationNumber,
			3					AS Part, 
			'RO'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			9000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q8	Accumulate 140,000 Vacation Points during qual period with a minimum of 40,000 TVP (Jan 2025 ? Dec 2025) and a minimum of 36,000 ROs (Jan 2025 ? Dec 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			8					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			140000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV,RO'			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			8					AS QualificationNumber,
			2					AS Part, 
			'TV'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			40000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			8					AS QualificationNumber,
			3					AS Part, 
			'RO'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			36000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q9	Accumulate 200,000 Vacation Points during qual period with a minimum of 50,000 TVP (Jan 2025 ? Dec 2025) and a minimum of 72,000 ROs (Jan 2025 ? Dec 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			9					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			200000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV,RO'				AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			9					AS QualificationNumber,
			2					AS Part, 
			'TV'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			50000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			9					AS QualificationNumber,
			3					AS Part, 
			'RO'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			72000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q10	Accumulate 120,000 Vacation Points during qual period with a minimum of 30,000 TVP (Jan 2025 ? Dec 2025) and a minimum of 1,500 ROs (Jan 2025 ? Dec 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			10					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			120000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV,RO'			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			10					AS QualificationNumber,
			2					AS Part, 
			'TV'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			30000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event			AS [PK_Event],
			10					AS QualificationNumber,
			3					AS Part, 
			'RO'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			1500				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q11	Accumulate 150,000 Vacation Points during qual period with a minimum of 36,000 TVP (Jan 2025 ? Dec 2025) and a minimum of 9,000 ROs (Jan 2025 ? Dec 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			11					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			150000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV,RO'			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			11					AS QualificationNumber,
			2					AS Part, 
			'TV'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			36000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			11					AS QualificationNumber,
			3					AS Part, 
			'RO'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			9000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q12	Accumulate 190,000 Vacation Points during qual period with a minimum of 40,000 TVP (Jan 2025 ? Dec 2025) and a minimum of 36,000 ROs (Jan 2025 ? Dec 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			12					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			190000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV,RO'			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			12					AS QualificationNumber,
			2					AS Part, 
			'TV'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			40000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			12					AS QualificationNumber,
			3					AS Part, 
			'RO'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			36000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]
		
		--Q13	Accumulate 250,000 Vacation Points during qual period with a minimum of 50,000 TVP (Jan 2025 ? Dec 2025) and a minimum of 72,000 ROs (Jan 2025 ? Dec 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			13					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12				    AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			250000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV,RO'			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			13					AS QualificationNumber,
			2					AS Part, 
			'TV'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			50000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL			AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			13					AS QualificationNumber,
			3					AS Part, 
			'RO'				AS [MetricType], 
			@QualPeriodAStart	AS [dStartDate], 
			@QualPeriodAEnd		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			72000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]
		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			50					AS QualificationNumber,
			1					AS Part, 
			'DS_PPV,DLV_DV'		AS [MetricType], 
			'2025-08-01'		AS [dStartDate], 
			'2025-08-31'		AS [dEndDate], 
			1					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			250					AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		IF @IsDevQA = 0
		BEGIN	

			DELETE s FROM [Event].[SetupEventQualification] AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
			INSERT INTO [Event].[SetupEventQualification](PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition 
			FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event

		END
		ELSE
		IF @IsDevQA = 3
		BEGIN	

			DELETE s FROM ##Event_SetupEventQualification_jgue AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
			INSERT INTO ##Event_SetupEventQualification_jgue(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition
			FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event

		END
		
		DECLARE @ColumnToPivot NVARCHAR(MAX),
			@SqlStatement NVARCHAR(MAX)

		DECLARE @QualificationListFactor INT = 13, --Diff between column ID and QId 
				@QualificationSKUFactor INT = NULL

		DECLARE 
			@Countries VARCHAR(MAX) = 'MX',
			@ListsIDs VARCHAR(MAX) = '57904,61187,61188'
	
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
		
		DROP TABLE IF EXISTS #Locations

		CREATE TABLE #Locations
		(
			[Location] [varchar](25),
			[PK_Event] [int],
			[ctrl] [bit] DEFAULT(0)
		)

		INSERT INTO #Locations([PK_Event],[Location])
		SELECT @PK_Event,	'Mexico'	 		 

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
					PK_Distributor		int,  
					DistributorID		varchar(30),
					DSTeam				varchar(10),            
					DSSubTeam			varchar(10),        
					DSSPTeam			varchar(10),               
					dSPQualDate			datetime2, 
					dSPRequalDate		datetime2,
					CountryCode			varchar(5),
					IsFromList			bit default(0),
					IsTicketPurchaser	bit default(0),
					DSFreezeTeam		varchar(10),        
					DSFreezeSubTeam		varchar(10),        
					DSFreezeType		varchar(10),  
					[FreezeType]		int NULL,
					[REINSTATEMENTDATE]	int NULL
				)

				INSERT INTO #DS
				(
					PK_Distributor,
					DistributorID,
					DSTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,
					dSPRequalDate,
					CountryCode
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor, 
				D.sDistributorID AS DistributorID,	
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				D.dSupervisorqualification AS dSPQualDate, 
				D.dSupervisorReQualification AS dSPRequalDate,
				D.sDistributorCountryProcessingCode AS CountryCode
				FROM        
				dbo.v_Distributor AS D  
					INNER JOIN #Countries AS C
						ON D.nDistributorCountryProcessingID = C.nCountryID	
				WHERE        
					D.StatusCode = 'COMPLETE'        
					AND D.sType = 'SP'
	 
				CREATE INDEX IX_#DS_PK_Distributor ON #DS(PK_Distributor);

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 1 AND [StepSubGroup] = 1;
		END
		
		--Step 2: List and SKUs
		IF @Step >= 2
		BEGIN

			PRINT 'Executing step 2'

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
					ListID INT
				)

				INSERT INTO #ListsIDs(PK_Event,ListID)
				SELECT DISTINCT 
					@PK_Event AS PK_Event,
					LTRIM(RTRIM(s.value)) AS [ListID]			 
				FROM STRING_SPLIT(@ListsIDs, ',') AS s
																	
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
					DistributorID,
					DSTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,
					dSPRequalDate,
					CountryCode,		
					IsFromList
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor, 
				D.sDistributorID AS DistributorID,
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate,
				D.dSupervisorReQualification AS dSPRequalDate,
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
					DistributorID,
					DSTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,
					dSPRequalDate,
					CountryCode,
					IsTicketPurchaser
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,  
				D.sDistributorID AS DistributorID,
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate,   
				D.dSupervisorReQualification AS dSPRequalDate,
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

			-- DS Snapshot

			DROP TABLE IF EXISTS #DSSnapshot

				SELECT s.[PK_DISTRIBUTOR]
					  ,s.[DISTRIBUTORID]
					  ,s.[ROYALTYMONTH]
					  ,s.[COP_COUNTRYCODE]
					  ,s.[STATUSCODE]
					  ,s.[SUBTYPECODE]
					  ,s.[TEAMCODE]
					  ,s.[TYPECODE]
				INTO #DSSnapshot
				FROM [PubEventManagement].[Shared].[DSSNAPSHOT] AS s WITH (NOLOCK)
				INNER JOIN #DS AS d
					ON s.[PK_DISTRIBUTOR] = d.[PK_DISTRIBUTOR]
					WHERE RoyaltyMonth = @TeamFreezeDate

				--Q1	Supervisor (Team Freeze as of January 2025)
				--Q2	World Team Member (Team Freeze as of January 2025)
				--Q3	Get Team Members (Team Freeze as of January 2025)
				--Q4	Mill Team Members (Team Freeze as of January 2025)
				--Q5	Pres Team and above (Team Freeze as of January 2025)

				UPDATE t
					SET 
						[DSFreezeSubTeam] = w.[SUBTYPECODE],
						[DSFreezeType] = w.[TYPECODE],
						[DSFreezeTeam] = w.[TEAMCODE],
						[FreezeType] = 1
				FROM #DS AS t
					INNER JOIN #DSSnapshot AS w
						ON t.PK_Distributor = w.PK_DISTRIBUTOR

				;WITH cte_REINSTATEMENTDATE AS 
				(
					SELECT d.PK_Distributor, LEFT(dd.WINBACKREINSTATEMENTDATE,6) AS [REINSTATEMENTDATE] 
					FROM #DS AS d
						INNER JOIN PubEvents.dbo.dimDistributor AS dd WITH (NOLOCK)
							ON d.PK_Distributor = dd.PK_Distributor
					WHERE [DSFreezeType] IS NULL
					AND dd.WINBACKREINSTATEMENTDATE >= LEFT(@TeamFreezeDate,6)
				),
				cte_DSSnapshot AS 
				(
					SELECT r.PK_Distributor,sn.[SUBTYPECODE],sn.[TYPECODE],sn.[TEAMCODE],r.[REINSTATEMENTDATE]
					FROM cte_REINSTATEMENTDATE AS r
						INNER JOIN [PubEventManagement].[Shared].[DSSNAPSHOT] AS sn WITH (NOLOCK)
							ON r.PK_Distributor= sn.PK_DISTRIBUTOR AND r.REINSTATEMENTDATE = sn.ROYALTYMONTH
				)
						 
				UPDATE d
					SET 
						[DSFreezeSubTeam] = IIF(r.PK_Distributor IS NULL, d.DSSubTeam,r.[SUBTYPECODE]),
						[DSFreezeType] = IIF(r.PK_Distributor IS NULL, d.DSSPTeam,r.[TYPECODE]), 
						[DSFreezeTeam] = IIF(r.PK_Distributor IS NULL, d.DSTeam,r.[TEAMCODE]),
						[FreezeType] = IIF(r.PK_Distributor IS NULL, 2,3),
						[REINSTATEMENTDATE] = r.[REINSTATEMENTDATE]
				FROM #DS AS d
					INNER JOIN cte_DSSnapshot AS r
						ON d.PK_Distributor = r.PK_Distributor							 
					WHERE [DSFreezeType] IS NULL  

			-- If MB becomes New SP during the year, he won't be elegible to qualify. 

					IF @IsDevQA =  0
					BEGIN

						DROP TABLE IF EXISTS [dbo].[WRK_26003_DSDetails]

						CREATE TABLE [dbo].[WRK_26003_DSDetails]
						(
							PK_Distributor			int,   
							DistributorID			varchar(30),
							DSTeam					varchar(10),        
							DSSubTeam				varchar(10),        
							DSSPTeam				varchar(10),              
							dSPQualDate				datetime2,
							dSPRequalDate			datetime2,
							CountryCode				varchar(5),
							IsFromList				bit default(0),
							IsTicketPurchaser		bit default(0),
							DSFreezeTeam			varchar(10),        
							DSFreezeSubTeam			varchar(10),        
							DSFreezeType			varchar(10),  
							[FreezeType]			int NULL,
							[REINSTATEMENTDATE]		int NULL
						)

						INSERT INTO [dbo].[WRK_26003_DSDetails](PK_Distributor	
						,DistributorID
						,DSTeam					     
						,DSSubTeam				     
						,DSSPTeam				           
						,dSPQualDate				
						,dSPRequalDate			
						,CountryCode				
						,IsFromList				
						,IsTicketPurchaser		
						,DSFreezeTeam			     
						,DSFreezeSubTeam			     
						,DSFreezeType						
						,[FreezeType]			
						,[REINSTATEMENTDATE])

						SELECT PK_Distributor
							,DistributorID
							,DSTeam					     
							,DSSubTeam				     
							,DSSPTeam				           
							,dSPQualDate				
							,dSPRequalDate			
							,CountryCode				
							,IsFromList				
							,IsTicketPurchaser		
							,DSFreezeTeam			     
							,DSFreezeSubTeam			     
							,DSFreezeType					
							,[FreezeType]			
							,[REINSTATEMENTDATE]		
						FROM #DS

						CREATE INDEX IX_WRK_26003_DSDetails_PK_Distributor ON [dbo].[WRK_26003_DSDetails](PK_Distributor);

					END


			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 2;
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
					@MetricType = STRING_AGG([MetricType],','),
					@DSCountries = STRING_AGG([Countries],',')
				FROM #Event_SetupEventQualification WITH (NOLOCK)
				WHERE QualificationNumber BETWEEN 6 AND 13
	
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 1;

				-- Result set 
				SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate],@DSCountries AS [DSCountries],@MetricType AS [MetricType]

				------------------------------------------------------------------------------------------------
				-- 3.2 Getting #tmp_DS
				------------------------------------------------------------------------------------------------
			
				INSERT INTO #TimeLog VALUES ('#tmp_DS', 3, 2, GETUTCDATE(), NULL);

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

					INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate])
					SELECT 
						@PK_Event AS [PK_Event],
						D.PK_Distributor AS PK_Distributor,
						D.DistributorID AS DistributorID,
						@iStartDate AS [iStartDate],
						@iEndDate AS [iEndDate],
						@dStartDate AS [dStartDate],
						@dEndDate AS [dEndDate],
						D.dSPQualDate 
					FROM [dbo].[WRK_26003_DSDetails] AS D WITH (NOLOCK) 

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
					ELSE 
					IF (@IsDevQA = 3)
					BEGIN
						
						DROP INDEX IF EXISTS [IX_##tmp_DS_jgue_PK_Distributor]
							ON ##tmp_DS_jgue;

						DELETE d FROM ##tmp_DS_jgue AS d WHERE d.PK_Event = @PK_Event  

						INSERT INTO ##tmp_DS_jgue([PK_Event],[PK_Distributor],[StartDate],[EndDate])
						SELECT 
							D.[PK_Event],
							D.PK_Distributor,
							D.[iStartDate],
							D.[iEndDate]
						FROM #tmp_DS AS D 
											 
						CREATE INDEX IX_##tmp_DS_jgue_PK_Distributor ON ##tmp_DS_jgue(PK_Distributor) INCLUDE(PK_Event);

					END

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;

				------------------------------------------------------------------------------------------------
				-- 3.3 Getting [Event].[DSPoints]
				------------------------------------------------------------------------------------------------
			
				IF (@IsDevQA = 0)
				BEGIN
					INSERT INTO #TimeLog VALUES ('usp_GetDSVolume', 3, 2, GETUTCDATE(), NULL);

					--	SourceType 3: Getting points from [PubEventManagement].[dbo].[v_aggFQS_ID]
					EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event,@QualFilter = '6,7,8,9,10,11,12,13', @SourceType = 3,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					--Output [Event].[DSPoints]

					IF @Error <> 0
					BEGIN
						SET @Error = @Error
						SET @ErrorMessage = @ErrorMessage
						RETURN;
					END

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;
		
				END
				ELSE
				IF (@IsDevQA = 3) AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_jgue') IS NOT NULL
				BEGIN
					 
					--Input
					--##tmp_DS_jgue
					--##Event_SetupEventQualification_jgue

					EXEC [dbo].[##usp_GetDSVolume_jgue] @PK_Event = @PK_Event, @SourceType = 1,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
					IF @Error <> 0
					BEGIN
						SET @Error = @Error
						SET @ErrorMessage = @ErrorMessage
						RETURN;
					END

					--Output
					--##Event_DSPoints_jgue
 
		
					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;
		
				END
			
			------------------------------------------------------------------------------------------------
			-- 3.5 Getting #Event_DSPoints AND #Event_DSPoints_Validations
			------------------------------------------------------------------------------------------------
		
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints', 3, 5, GETUTCDATE(), NULL);

				--Allocating volume for uplines.

				DROP INDEX IF EXISTS [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints;
				DROP INDEX IF EXISTS [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints;

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

				IF @IsDevQA = 0
				BEGIN
					INSERT INTO #Event_DSPoints(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points],[Bonus])
					SELECT 
						PK_Distributor,
						[PK_Event],
						PK_Country,
						[RoyaltyMonth],
						MetricType,
						ROUND(IIF([PersonalPoints] < 0,0,[PersonalPoints]),2) AS [PersonalPoints],
						ROUND(IIF([TransferPoints] < 0,0,[TransferPoints]),2) AS [TransferPoints],
						ROUND(IIF([MainPoints] < 0,0,[MainPoints]),2) AS [MainPoints], 
						ROUND(IIF([Points] < 0,0,[Points]),2) AS [Points],
						Bonus
					FROM [Event].[DSPoints] WITH (NOLOCK)
					WHERE PK_Event = @PK_Event

					DROP TABLE IF EXISTS [dbo].[WRK_26003_DSPoints] 
					
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
					INTO [dbo].[WRK_26003_DSPoints] 
					FROM #Event_DSPoints

					CREATE INDEX IX_WRK_26003_DSPoints_PK_Distributor ON [dbo].[WRK_26003_DSPoints] (PK_Distributor);

				END
				ELSE IF @IsDevQA = 3
				BEGIN

					INSERT INTO #Event_DSPoints(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points],[Bonus])
					SELECT 
						PK_Distributor,
						[PK_Event],
						PK_Country,
						[RoyaltyMonth],
						MetricType,
						ROUND(IIF([PersonalPoints] < 0,0,[PersonalPoints]),2) AS [PersonalPoints],
						ROUND(IIF([TransferPoints] < 0,0,[TransferPoints]),2) AS [TransferPoints],
						ROUND(IIF([MainPoints] < 0,0,[MainPoints]),2) AS [MainPoints], 
						ROUND(IIF([Points] < 0,0,[Points]),2) AS [Points],
						Bonus
					FROM ##Event_DSPoints_jgue

				END

				CREATE CLUSTERED INDEX [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints ([PK_Distributor]) 
				CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints ([MetricType])
			
				-- Starts custom points validation
				----------------------------------------------------------------------------------------
				DROP TABLE IF EXISTS #Event_DSPoints_Validations

				CREATE TABLE #Event_DSPoints_Validations
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
				WHERE D.DSSPTeam = 'SP' AND P.MetricType IN ('TV','RO')			 
				GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth	
				
				UNION

				SELECT  
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					P.MetricType,
					P.[Points]
				FROM #Event_DSPoints AS P 
					INNER JOIN #DS AS D
						ON P.PK_Distributor = D.PK_Distributor	
				WHERE D.DSSPTeam = 'SP'

				CREATE CLUSTERED INDEX [IX_#Event_DSPoints_Validations_PK_Distributor] ON #Event_DSPoints_Validations ([PK_Distributor]) 
				CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_Validations_MetricType] ON #Event_DSPoints_Validations ([MetricType])

				IF @IsDevQA = 0
				BEGIN

					DROP TABLE IF EXISTS [dbo].[WRK_26003_DSPoints_Validations] 
					
					SELECT 
						PK_Distributor, 
						PK_Country,
						[RoyaltyMonth],
						MetricType,
						[Points]
					INTO [dbo].[WRK_26003_DSPoints_Validations]  
					FROM #Event_DSPoints_Validations

					CREATE INDEX IX_WRK_26003_DSPoints_Validations_PK_Distributor ON [dbo].[WRK_26003_DSPoints_Validations]  (PK_Distributor);

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
						[QSVolume] [bit] NULL,
						[QSVolumePercentage] [int] NULL
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
						FROM [dbo].[WRK_26003_DSDetails] AS D WITH (NOLOCK) 					
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
			ELSE IF @IsDevQA = 3
			BEGIN
				
				INSERT INTO ##tmp_DSQualDef_jgue([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[Bonus],[QSVolume])
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
				
			END
		END
		
		--Step 5: Getting the following items:
		-- 1) Full downline 
		-- 2) Eligible downlines according to application date
		-- 3) Volume for elegible downlines only
		-- 4) Period for each downline according to application date
		-- 5) Bonuses calculation and assignation on [tmp].[DSPointsSummary]	
		IF @Step >= 5
		BEGIN
			
			PRINT 'Executing step 5'

			------------------------------------------------------------------------------------------------
			-- 5.1 Getting all downlines in 1st DS line for all NAM DS, including the ones from associated 
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('Getting full downline', 5, 1, GETUTCDATE(), NULL);


			DROP TABLE IF EXISTS #DSDownlines

				SELECT DISTINCT
					DL.PK_Distributor,
					DL.PK_DSDownLine
				INTO #DSDownlines
				FROM [dbo].[WRK_26003_DSDetails] AS DS WITH (NOLOCK) --Uplines from Mexico
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
				FROM [dbo].[WRK_26003_DSDetails] AS D WITH (NOLOCK)--Uplines from Mexico
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

				DROP TABLE IF EXISTS #DownlineEvaluationDates	

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
				INTO #DownlineEvaluationDates
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
				DROP TABLE IF EXISTS [dbo].[WRK_26003_DownlineDates] -- Current execution, not freezed table

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
				INTO [dbo].[WRK_26003_DownlineDates]
				FROM #DownlineEvaluationDates
			
				DROP TABLE IF EXISTS [dbo].[WRK_26003_DownlineEvaluationMonth] -- Current execution, not freezed table

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
					 END AS StartMonth,
					 CASE  
						WHEN EvaluationType = 'DS' THEN @DSBonusAppDateEnd 
					 END AS EndMonth,
					  CASE  
						WHEN EvaluationType = 'DS' THEN @DSFreezeCutDays 
					 END AS FreezeCutDays
				INTO [dbo].[WRK_26003_DownlineEvaluationMonth]
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
						IIF(EvaluationType IN ('PM','DS'), LEFT(CONVERT(INT, CONVERT(CHAR(10),CONVERT(DATE, dEvaluationMonth, 104), 112)),6),NULL)  AS StartMonth,
						IIF(EvaluationType IN ('PM','DS'), dEvaluationMonth,NULL) AS dStartMonth,
						IIF(EvaluationType IN ('PM','DS'), IIF(EvaluationMonth+1 > EndMonth ,EndMonth, EvaluationMonth),NULL)  AS EndMonth,
						IIF(EvaluationType IN ('PM','DS'), CAST(CAST((IIF(EvaluationMonth+1 > EndMonth ,EndMonth, EvaluationMonth) * 100) + 01 AS VARCHAR(10)) AS DATE),NULL) AS dEndMonth,
						CONVERT(INT, CONVERT(CHAR(10),CONVERT(DATE, DATEADD(DD,FreezeCutDays, CAST(CAST((IIF(EvaluationType = 'FQS', EvaluationMonth+1,EvaluationMonth+2) * 100) + 01 AS VARCHAR(10)) AS DATE)), 104), 112))  AS FreezeDate, --15th day after the signup month + 1
						DATEADD(DD,FreezeCutDays, CAST(CAST((IIF(EvaluationType = 'FQS', EvaluationMonth+1,EvaluationMonth+2) * 100) + 01 AS VARCHAR(10)) AS DATE)) AS dFreezeDate
					FROM [dbo].[WRK_26003_DownlineEvaluationMonth] WITH (NOLOCK) 			

				END  

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 3;

		------------------------------------------------------------------------------------------------
		-- 5.4 Freezing lineage
		--// Contributor will be evaluated until 15th day after the signup month + 1; If a NewDS RESIGN/TERMINATED or is not at good standing with herbalife, no matter if contributor achieved 100 VP will be removed as Contributor 															
		------------------------------------------------------------------------------------------------

		INSERT INTO #TimeLog VALUES ('Freezing WRK_26003_DSDownlines', 5, 4, GETUTCDATE(), NULL);
		 
			IF @IsDevQA = 0
			BEGIN

				IF OBJECT_ID (N'WRK_26003_DSDownlines', N'U') IS NULL 
				BEGIN
				
					CREATE TABLE [dbo].[WRK_26003_DSDownlines] --Freeze table
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

				MERGE [dbo].[WRK_26003_DSDownlines] AS T
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
					@MetricType = STRING_AGG([MetricType],','),
					@DSCountries = STRING_AGG([Countries],',')
				FROM #Event_SetupEventQualification WITH (NOLOCK)
				WHERE QualificationNumber = 50
	
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 5;

				-- Result set 
				SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate],@DSCountries AS [DSCountries],@MetricType AS [MetricType]
				 
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
						FROM [dbo].[WRK_26003_DSDownlines] AS D WITH (NOLOCK)
						INNER JOIN [PubEvents].[dbo].dimDistributor AS DD WITH (NOLOCK)
							ON D.PK_DSDownLine = DD.PK_Distributor
						WHERE [Active] = 1
						AND @iCurrentDate < D.FreezeDate 

					END ELSE
					BEGIN
						INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate],[PK_DSType])
						SELECT 
							@PK_Event AS [PK_Event],
							D.PK_DSDownLine AS PK_Distributor,
							DD.DistributorID,
							@iStartDate AS [iStartDate],
							@iEndDate AS [iEndDate],
							@dStartDate AS [dStartDate],
							@dEndDate AS [dEndDate],
							CASE WHEN DD.SPQualDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DD.SPQualDate),112) END, 
							NULL PK_DSType -- Frezee type
						FROM [dbo].[##WRK_26003_DSDownlines] AS D
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
					ELSE 
					IF (@IsDevQA = 3)
					BEGIN
						
						DROP INDEX IF EXISTS [IX_##tmp_DS_jgue_PK_Distributor]
							ON ##tmp_DS_jgue;

						DELETE d FROM ##tmp_DS_jgue AS d WHERE d.PK_Event = @PK_Event  

						INSERT INTO ##tmp_DS_jgue([PK_Event],[PK_Distributor],[StartDate],[EndDate],[PK_DSType])
						SELECT 
							D.[PK_Event],
							D.PK_Distributor,
							D.[iStartDate],
							D.[iEndDate],
							D.[PK_DSType]
						FROM #tmp_DS AS D 
											 
						CREATE INDEX IX_##tmp_DS_jgue_PK_Distributor ON ##tmp_DS_jgue(PK_Distributor) INCLUDE(PK_Event);

					END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 6;

			------------------------------------------------------------------------------------------------
			-- 5.4 Getting [Event].[DSPoints]
			------------------------------------------------------------------------------------------------
			
			IF (@IsDevQA = 0)
			BEGIN
				INSERT INTO #TimeLog VALUES ('usp_GetDSVolume', 5, 7, GETUTCDATE(), NULL);

				--Input
				--[tmp].[DS]
				--[Event].[SetupEventQualification]
				--IF @EnableConversionDates = 1 [tmp].[MemberLastestConversion]

				--SourceType 1: Getting points from PubEvents.[dbo].[factDSFinancial_ctry], includes divorce and tranfer cases.
				EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 1, @QualFilter = '50', @EnableConversionDates = 1, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
				
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
			ELSE
			IF (@IsDevQA = 3) AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_jgue') IS NOT NULL
			BEGIN
					 
				INSERT INTO #TimeLog VALUES ('##usp_GetDSVolume_jgue', 5, 7, GETUTCDATE(), NULL);

				--Input
				--##tmp_DS_jgue
				--##Event_SetupEventQualification_jgue
				--IF @EnableConversionDates = 1 ##tmp_MemberLastestConversion

				EXEC [dbo].[##usp_GetDSVolume_jgue] @PK_Event = @PK_Event, @SourceType = 1,@QualFilter = '50', @EnableConversionDates = 1,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
				IF @Error <> 0
				BEGIN
					SET @Error = @Error
					SET @ErrorMessage = @ErrorMessage

					SELECT @ErrorMessage
					RETURN;
				END

				--Output
				--##Event_DSPoints_jgue
				--##tmp_DSSummary 
		
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 5 AND [StepSubGroup] = 7;
		
			END

			------------------------------------------------------------------------------------------------
			-- 5.5 Getting #Event_DownlinesPoints  
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

					DROP TABLE IF EXISTS [dbo].[WRK_26003_DSPoints_Downlines]  -- Current execution, not freeze
					
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
					INTO [dbo].[WRK_26003_DSPoints_Downlines] 
					FROM #Event_DownlinesPoints

					CREATE INDEX IX_WRK_26003_DSPoints_Downlines_PK_Distributor ON [dbo].[WRK_26003_DSPoints_Downlines] (PK_Distributor);

				END
				ELSE IF @IsDevQA = 3
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
					FROM ##Event_DSPoints_jgue

				END

				CREATE CLUSTERED INDEX [IX_#Event_DownlinesPoints_PK_Distributor] ON #Event_DownlinesPoints ([PK_Distributor]) 
				CREATE NONCLUSTERED INDEX [IX_#Event_DownlinesPoints_MetricType] ON #Event_DownlinesPoints ([MetricType])
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 8;
	
		------------------------------------------------------------------------------------------------
		-- 5.9  Bonuses assignation / [tmp].[DSPointsSummary]		
		------------------------------------------------------------------------------------------------
	 
		IF @IsDevQA = 0 AND OBJECT_ID (N'WRK_26003_ContributorsStatus', N'U') IS NULL  
		BEGIN

				CREATE TABLE [dbo].[WRK_26003_ContributorsStatus]  --Freeze table
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

		IF @IsDevQA = 0 AND OBJECT_ID (N'WRK_26003_ContributorsVolume', N'U') IS NULL  
			BEGIN

				CREATE TABLE [dbo].[WRK_26003_ContributorsVolume]  --Freeze table
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
			 
			IF @IsDevQA = 0 AND OBJECT_ID (N'WRK_26003_NewDSBonusContributors', N'U') IS NULL  
			BEGIN

				CREATE TABLE [dbo].[WRK_26003_NewDSBonusContributors]  --Freeze table
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
				FROM [dbo].[WRK_26003_DSDownlines] AS d WITH (NOLOCK)  
				INNER JOIN [dbo].[WRK_26003_DSPoints_Downlines]  AS p WITH (NOLOCK)
					ON d.PK_DSDownline = p.PK_Distributor  
						AND p.RoyaltyMonth BETWEEN d.StartMonth AND d.EndMonth
				WHERE d.Active = 1 AND @iCurrentDate < d.FreezeDate 
				AND d.EvaluationType = 'DS' AND p.MetricType IN ('DS_PPV', 'DLV_DV')
				GROUP BY d.PK_Distributor, d.PK_DSDownline,d.EvaluationMonth,d.FreezeDate
				HAVING SUM(Points) >= 250
				
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
			FROM [dynamic].[WRK_26003_MexicoRegional_NEWDS_Overwrite] AS o WITH (NOLOCK)
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
							
				MERGE [dbo].[WRK_26003_NewDSBonusContributors] AS t
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
				FROM [dbo].[WRK_26003_NewDSBonusContributors] AS F WITH (NOLOCK)
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
				INNER JOIN [dbo].[WRK_26003_DSPoints_Downlines] AS p WITH (NOLOCK)
					ON d.PK_DSDownline = p.PK_Distributor  						 
				WHERE @iCurrentDate < d.FreezeDate  
				AND p.MetricType IN ('DS_PPV', 'DLV_DV')	


				MERGE [dbo].[WRK_26003_ContributorsVolume] AS t
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
				INNER JOIN [WRK_26003_DownlineEvaluationMonth] AS s WITH (NOLOCK)
					ON d.PK_Distributor = s.PK_Distributor AND d.PK_DSDownline = s.PK_DSDownline   	
				WHERE @iCurrentDate < d.FreezeDate  
				AND s.EvaluationType = 'DS'

				MERGE [dbo].[WRK_26003_ContributorsStatus] AS t
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
					 		
			------------------------------------------------------------------------------------------------
			-- 5.7  Bonuses assignation / [tmp].[DSPointsSummary]		
			------------------------------------------------------------------------------------------------ 
			------------------------------------------------------------------------------------------------
			-- * JULY DOUBLE VOLUME PROMOTION

			-- All FQS and above can double their volume earned in JULY up to 2,500 Bonus Points  
			-- QS volume does not apply toward the bonus.
			-- Freeze contributor(s)
			-- Applicable towards the ACCUMULATED VACATION POINTS NOT towards the accumulated Personal TVP or RO.
			-- See Rules Bonus Example Page
			------------------------------------------------------------------------------------------------
			------------------------------------------------------------------------------------------------
			--// Double Bonus
			------------------------------------------------------------------------------------------------ 	

			INSERT INTO #TimeLog VALUES ('Double bonus', 5, 95, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #JulyDoubleVolumePromotion

			;WITH cte_FQS AS
			(
				SELECT DISTINCT PK_Distributor,CAST(CONVERT(VARCHAR(6),dSPQualDate,112) AS INT)  AS iSPQualDate
				FROM [dbo].[WRK_26003_DSDetails] AS D WITH (NOLOCK) WHERE DSSPTeam = 'SP'
			),
			cte_JulyDoubleVolumePromotion AS
			(

			SELECT 
				d.PK_Distributor,
				d.iSPQualDate,
			IIF(p.RoyaltyMonth = 202507,
					IIF(RoyaltyMonth < d.iSPQualDate,0,
						IIF(Points >= 2500, 2500, Points)),0) AS [JULY DOUBLE VOLUME PROMOTION] 
			FROM cte_FQS AS d
				INNER JOIN #Event_DSPoints_Validations AS p
					ON d.PK_Distributor = p.PK_Distributor 
						AND p.RoyaltyMonth IN(202507) 
						AND p.MetricType = 'VP'
			)

			SELECT 
				d.PK_Distributor,
				d.iSPQualDate,
			SUM([JULY DOUBLE VOLUME PROMOTION]) AS 	[JULY DOUBLE VOLUME PROMOTION]	
			INTO #JulyDoubleVolumePromotion
			FROM cte_JulyDoubleVolumePromotion AS d 
			GROUP BY d.PK_Distributor,d.iSPQualDate
		 
		 	-- This bonus are assigned below on #WRK_26003_BonusPoints

		 ------------------------------------------------------------------------------------------------
			-- * AUGUST NEW DISTRIBUTOR BONUS

			--Earn 2000 Bonus Points for each Personally Sponsored DS Downline WW with AUGUST 2025 application date or conversion date, including converted from preferred members/preferred customers.

			-- Must be 1st line Distributor Personally Sponsored (DS Level)
			-- Application date AUGUST 2025 
			-- Purchase a minimum of 250 PPV or DLV or combination of both (PPV DV + DLV DV) from their most recent application or conversion date AUGUST 2025. 
			-- Freeze contributor(s)
			-- Applicable towards the ACCUMULATED VACATION POINTS NOT towards the accumulated Personal TVP or RO.
		------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('#WRK_26003_BonusSummary', 5, 11, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #WRK_26003_BonusSummary

				SELECT 
					D.PK_Distributor,
					ISNULL(DS.[TotalBonusNewDS],0) AS [New DS Bonus],
					ISNULL(DS.[TotalNewDS],0) AS [TotalNewDS],
					ISNULL(db.[JULY DOUBLE VOLUME PROMOTION],0) AS [JULY DOUBLE VOLUME PROMOTION]
				INTO #WRK_26003_BonusSummary
				FROM #DS AS D
					LEFT JOIN #NewDSSSummary AS DS  
						ON D.PK_Distributor = DS.PK_Distributor		
					LEFT JOIN #JulyDoubleVolumePromotion AS db
						ON D.PK_Distributor = db.PK_Distributor
					
			CREATE INDEX IX_#WRK_26003_BonusSummary_PK_Distributor ON #WRK_26003_BonusSummary(PK_Distributor)
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 11;

			IF @IsDevQA = 0
			BEGIN

				INSERT INTO #TimeLog VALUES ('WRK_26003_BonusSummary', 5, 12, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS [dbo].[WRK_26003_BonusSummary]

				SELECT 
					PK_Distributor,
					[New DS Bonus],
					[TotalNewDS],
					[JULY DOUBLE VOLUME PROMOTION]
				INTO [dbo].[WRK_26003_BonusSummary]
				FROM #WRK_26003_BonusSummary 
								
			CREATE INDEX IX_WRK_26003_BonusSummary_PK_Distributor ON [dbo].[WRK_26003_BonusSummary](PK_Distributor)
				
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 12;
				
			END
			ELSE IF @IsDevQA = 3
			BEGIN

				INSERT INTO #TimeLog VALUES ('##WRK_26003_BonusSummary', 5, 13, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS [dbo].[##WRK_26003_BonusSummary]

				SELECT 
					PK_Distributor,
					[New DS Bonus],
					[TotalNewDS],
					[JULY DOUBLE VOLUME PROMOTION]
				INTO [dbo].[##WRK_26003_BonusSummary]
				FROM #WRK_26003_BonusSummary 
											
				CREATE INDEX IX_##WRK_26003_BonusSummary_PK_Distributor ON [dbo].[##WRK_26003_BonusSummary](PK_Distributor)
				
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 13;
				
			END
									
			DROP TABLE IF EXISTS #Event_DSPoints_Summary

			CREATE TABLE #Event_DSPoints_Summary
			(
				PK_Distributor [int],
				RoyaltyMonth [int],
				MetricType [varchar](10),
				PK_Country [int],
				[Points] [money],
				[QSVolume] [bit],
				[QSVolumePercentage] [int],
				iSPQualDate [int],
				QualificationNumber [int],
				Part [int],
				iStartDate [int],
				iEndDate [int],
				[Countries] [varchar](max),
				[monthNumber] INT
			)

			INSERT INTO #Event_DSPoints_Summary(PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,QSVolumePercentage,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries,[monthNumber])
				SELECT U.PK_Distributor,
						U.RoyaltyMonth,
						U.MetricType,
						0 AS PK_Country,
						SUM(ISNULL(U.Points,0)) AS [Points],
						F.[QSVolume],
						F.[QSVolumePercentage],
						F.iSPQualDate,
						F.QualificationNumber,
						F.Part,
						F.iStartDate,
						F.iEndDate,
						F.Countries,
						ROW_NUMBER() OVER (PARTITION BY U.PK_Distributor,F.QualificationNumber,F.Part,U.MetricType ORDER BY U.RoyaltyMonth ASC) AS [monthNumber]
				FROM #Event_DSPoints_Validations AS U WITH (NOLOCK) 
							INNER JOIN #tmp_DSQualDef AS F
								ON u.PK_Distributor = F.PK_Distributor	
								WHERE 
								F.MetricType = U.MetricType 
								AND 
								U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
								AND 
				(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
				GROUP BY U.PK_Distributor,U.RoyaltyMonth,U.MetricType,F.[QSVolume],F.[QSVolumePercentage],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries

			INSERT INTO #TimeLog VALUES ('#WRK_26003_BonusPoints', 5, 14, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #WRK_26003_BonusPoints

			--In case of multiple periods, the bonus should be assigned by period
				
			SELECT 
					U.PK_Distributor,
					U.RoyaltyMonth,
					U.MetricType,
					(SELECT nCountryID FROM v_Countries WHERE sCountryCode = '-W') AS PK_Country,
					ISNULL(U.Points,0) AS [Points],
					U.[QSVolume],
					U.[QSVolumePercentage],
					U.iSPQualDate,
					U.QualificationNumber,
					U.Part,
					U.iStartDate,
					U.iEndDate,
					U.Countries,
					IIF(@IsJulyDoubleBonusActive = 1 AND U.QualificationNumber BETWEEN @BonusApplicableFrom AND @BonusApplicableTo AND U.MetricType = 'VP' AND U.RoyaltyMonth = 202507, BS.[JULY DOUBLE VOLUME PROMOTION],0 ) AS [JULY DOUBLE VOLUME PROMOTION],
					IIF(@IsNewDSBonusActive = 1 AND U.QualificationNumber BETWEEN @BonusApplicableFrom AND @BonusApplicableTo AND U.MetricType = 'VP' AND U.[monthNumber] = 1, ISNULL(BS.[New DS Bonus],0), 0) AS [New DS Bonus] 
				INTO #WRK_26003_BonusPoints
				FROM #Event_DSPoints_Summary AS U WITH (NOLOCK)
						LEFT JOIN #WRK_26003_BonusSummary AS BS 
							ON U.PK_Distributor = BS.PK_Distributor		

			CREATE INDEX IX_#WRK_26003_BonusPoints_PK_Distributor ON #WRK_26003_BonusPoints(PK_Distributor)
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 14;

			IF @IsDevQA = 0
			BEGIN
			
				INSERT INTO #TimeLog VALUES ('WRK_26003_BonusPoints', 5, 15, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS [dbo].[WRK_26003_BonusPoints]

				--In case of multiple periods, the bonus should be assigned by period

				SELECT 
						PK_Distributor,
						RoyaltyMonth,
						MetricType,
						PK_Country,
						[Points],
						[QSVolume],
						[QSVolumePercentage],
						iSPQualDate,
						QualificationNumber,
						Part,
						iStartDate,
						iEndDate,
						Countries,
						[JULY DOUBLE VOLUME PROMOTION],
						[New DS Bonus]
					INTO [dbo].[WRK_26003_BonusPoints]
					FROM #WRK_26003_BonusPoints	

				CREATE INDEX IX_WRK_26003_BonusPoints_PK_Distributor ON [dbo].[WRK_26003_BonusPoints](PK_Distributor)

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 5 AND [StepSubGroup] = 15;

			END

			INSERT INTO #TimeLog VALUES ('#tmp_DSPointsSummary', 5, 16, GETUTCDATE(), NULL);

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
					[QSVolumePercentage] [int] NULL,
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
							(ISNULL(P.[JULY DOUBLE VOLUME PROMOTION],0) + ISNULL(P.[New DS Bonus],0))  AS [Bonus],
							ISNULL(P.[Points],0) + (ISNULL(P.[JULY DOUBLE VOLUME PROMOTION],0) + ISNULL(P.[New DS Bonus],0)) AS [TotalPoints],
							P.iStartDate,
							P.iEndDate
						FROM #WRK_26003_BonusPoints AS P WITH (NOLOCK)

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 5 AND [StepSubGroup] = 16;									 
						
				IF @IsDevQA = 0
				BEGIN
					
					INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary]', 5, 17, GETUTCDATE(), NULL);
					
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
					WHERE [StepGroup] = 5 AND [StepSubGroup] = 17;

				END
				ELSE IF @IsDevQA = 3
				BEGIN

					INSERT INTO ##DSPointsSummary_jgue(PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate)
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
				ELSE IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetQualifier_Points_jgue') IS NOT NULL
				BEGIN
					 
					 --Input 
					 --##DSPointsSummary_jgue
					 --##Event_DSPoints_jgue
					 --##tmp_DSQualDef_jgue
					 --##Event_SetupEventQualification_jgue

				 
						EXEC ##usp_GetQualifier_Points_jgue @PK_Event = @PK_Event_Execution, @QualType = @QualType, @OverwritePointsSummary = @OverwritePointsSummary, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
						IF @Error <> 0
						BEGIN
							SET @Error = @Error
							SET @ErrorMessage = @ErrorMessage
							RETURN;
						END				 

					--Output 
					--##DSQualPoints_jgue
				END


				UPDATE #Executions
				SET Done = 1
				WHERE PK_Execution = @PK_Execution

				END
					 
				IF @IsDevQA = 3
				BEGIN
					INSERT INTO #Event_DSQualPoints(PK_Event,PK_Distributor,QualificationNumber,Part,QualDate)
					SELECT 
						PK_Event
						,PK_Distributor
						,QualificationNumber 
						,Part		
						,QualDate
					FROM ##DSQualPoints_jgue AS Q
				END
				ELSE
				BEGIN
					INSERT INTO #Event_DSQualPoints(PK_Event,PK_Distributor,QualificationNumber,Part,QualDate)
					SELECT 
						PK_Event
						,PK_Distributor
						,QualificationNumber 
						,Part		
						,QualDate
					FROM [Event].[DSQualPoints] AS Q WITH (NOLOCK) WHERE PK_Event = @PK_Event
				END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 6 AND [StepSubGroup] = 1;
		END

		--Step 7: Qualifications
		IF @Step >= 7
		BEGIN
			
			PRINT 'Executing step 7'

			INSERT INTO #TimeLog VALUES ('#EventQual', 7, 1, GETUTCDATE(), NULL);

			INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q03,Q04,Q05,Q17)
				SELECT 
					PK_Distributor,
					@PK_Event AS [PK_Event],
					IIF(D.DSFreezeSubTeam = 'SP',1,0)								AS Q01, -- Supervisor (Team Freeze as of January 2025)
					IIF(D.DSFreezeSubTeam = 'WT',1,0)								AS Q02, -- World Team Member
					IIF(D.DSFreezeSubTeam IN ('GT','GP'),1,0)						AS Q03, -- Get Team Member
					IIF(D.DSFreezeSubTeam IN ('MT','MP'),1,0)						AS Q04, -- Mill Team Member
					IIF(D.DSFreezeTeam = 'P',1,0)									AS Q05, -- Press Team and Above 
					IIF(D.dSPQualDate BETWEEN '2025-01-01' AND '2025-12-31',1,0)	AS Q17  -- New Supervisor (SP Qual Date in 2025)
				FROM #DS AS D WITH (NOLOCK)  
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)

			------------------------------------------------------------------------------------------------
			-- List qualifications
			------------------------------------------------------------------------------------------------
			IF EXISTS ( SELECT 1 FROM #ListsIDs) BEGIN

				DROP TABLE IF EXISTS #UniqueListID

				SELECT DISTINCT ListID,IDENTITY(INT,1,1) AS ID  
				INTO #UniqueListID
				FROM #ListsIDs
				ORDER BY ListID ASC

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
					ORDER BY m.ListID ASC;

					SET @SqlStatement = LEFT(@SqlStatement, LEN(@SqlStatement) - 1) -- remove the last comma
					SET @SqlStatement= @SqlStatement + ' FROM ##DSList_Pivot AS P'

					EXECUTE sp_executesql @SqlStatement

				END

				DROP TABLE IF EXISTS #ListsQsMapping

				SELECT QColumn = 'Q' +   IIF(ID + @QualificationListFactor < 10,  '0' + CAST(ID + @QualificationListFactor AS VARCHAR), CAST(ID + @QualificationListFactor  AS VARCHAR)), ListID--, PK_Event 
				INTO #ListsQsMapping
				FROM #UniqueListID
			
				SET @SqlStatement = '';					

				SELECT  @SqlStatement += N'IF NOT EXISTS (SELECT 1 FROM tempdb.sys.columns WITH (NOLOCK) WHERE [object_id] = object_id(''tempdb..#EventQual'') AND name ='''+ [QColumn] +''') BEGIN ALTER TABLE #EventQual ADD [' + [QColumn] + '] BIT DEFAULT 0; END; '
				FROM #ListsQsMapping AS M

				EXECUTE sp_executesql @SqlStatement

				SET @SqlStatement = '';

				SELECT  @SqlStatement+= 'UPDATE E ' +
						' SET ' + [QColumn] + ' = L.[' + CAST(ListID AS NVARCHAR(MAX))  + ']' +
						' FROM #EventQual AS E INNER JOIN ##DSList_Pivot AS L
						ON E.PK_Event = L.PK_Event_List 
						AND E.PK_Distributor = L.PK_Distributor_List;'					
				FROM #ListsQsMapping AS M
			 	
				EXECUTE sp_executesql @SqlStatement

			END
	
			------------------------------------------------------------------------------------------------
			-- SKUs qualifications
			------------------------------------------------------------------------------------------------
			IF EXISTS ( SELECT 1 FROM #SKUs) BEGIN

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

				DROP TABLE IF EXISTS #SKUsQsMapping

				SELECT QColumn = 'Q' +   IIF(ID + @QualificationSKUFactor < 10,  '0' + CAST(ID + @QualificationSKUFactor AS VARCHAR), CAST(ID + @QualificationSKUFactor AS VARCHAR)), SKUCode, PK_Event 
				INTO #SKUsQsMapping
				FROM #SKUs
				ORDER BY PK_Event,SKUCode
	
				SET @SqlStatement = '';
	
				SELECT  @SqlStatement += N'IF NOT EXISTS (SELECT 1 FROM tempdb.sys.columns WITH (NOLOCK) WHERE [object_id] = object_id(''tempdb..#EventQual'') AND name ='''+ [QColumn] +''') BEGIN ALTER TABLE #EventQual ADD [' + [QColumn] + '] BIT DEFAULT 0; END; '
				FROM #SKUsQsMapping AS M

				EXECUTE sp_executesql @SqlStatement

				SET @SqlStatement = '';

				SELECT  @SqlStatement+= 'UPDATE E ' +
					 ' SET ' + [QColumn] + ' = L.[' + CAST(SKUCode AS NVARCHAR(MAX))  + ']' +
					 ' FROM #EventQual AS E INNER JOIN ##DSSKU_Pivot AS L
						ON E.PK_Event = L.PK_Event_SKU 
						AND E.PK_Distributor = L.PK_Distributor_SKU;'					
				FROM #SKUsQsMapping AS M
			 	
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
			 
			--Getting qualifiers by qualification number
		
			DECLARE @QualificationNumber INT, @QPK_Event INT, @ID INT, @QPart INT, @QColumn VARCHAR(10)

			WHILE EXISTS (SELECT 1 FROM #QualificationsMapping AS m WHERE [ctrl] = 0 AND Part = 1)
			BEGIN
					
				SELECT @ID = MIN(ID) FROM #QualificationsMapping AS m WHERE [ctrl] = 0 AND Part = 1 --AND QualificationNumber = 12

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
						WHERE (Q'+ CAST(@QPart AS VARCHAR(5)) +'.QualificationNumber = '+ CAST(@QualificationNumber AS VARCHAR(10)) +' AND Q'+CAST(@QPart AS VARCHAR(10))+'.Part = '+ CAST(@QPart AS VARCHAR(10)) +')
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
					E01 = (((((Q01 | Q02 | Q17) & Q06) | (Q03 & Q07) | (Q04 & Q08)) & ~Q14) | ((Q05 | Q14) & Q09) | Q15) 

				UPDATE 
					#EventQual
				SET E02 = (((((Q01 | Q02 | Q17) & Q10) | (Q03 & Q11) | (Q04 & Q12)) & ~Q14) | ((Q05 | Q14) & Q13) | Q16) 
										
 
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

				DROP INDEX IF EXISTS [IX_Event_DSQual_PK_Distributor_PK_Event]
							ON [Event].[DSQual];

				DROP INDEX IF EXISTS [IX_Event_DSQual_PK_Event]
							ON [Event].[DSQual];

				INSERT INTO [Event].[DSQual](
					PK_Event		
					,PK_Distributor	
					,CreatedDate	
					,UpdatedDate	
					,Q01			
					,Q02			
					,Q03			
					,Q04			
					,Q05			
					,Q06			
					,Q07			
					,Q08			
					,Q09			
					,Q10			
					,Q11			
					,Q12			
					,Q13			
					,Q14			
					,Q15			
					,Q16			
					,Q17			
					,Q18			
					,Q19			
					,Q20			
					,Q21			
					,Q22			
					,Q23			
					,Q24			
					,Q25			
					,Q26			
					,Q27			
					,Q28			
					,Q29			
					,Q30			
					,Q31			
					,Q32			
					,Q33			
					,Q34			
					,Q35			
					,Q36			
					,Q37			
					,Q38			
					,Q39			
					,Q40			
					,Q41			
					,Q42			
					,Q43			
					,Q44			
					,Q45			
					,Q46			
					,Q47			
					,Q48			
					,Q49			
					,Q50
					,E01			
					,E02			
					,E03			
					,E04			
					,E05			
					,E06			
					,E07			
					,E08			
					,E09			
					,E10			
					,E11			
					,E12			
					,E13			
					,E14			
					,E15			
					,E16			
					,E17			
					,E18			
					,E19			
					,E20			
					,E21			
					,E22			
					,E23			
					,E24			
					,E25			
					,E26			
					,E27			
					,E28			
					,E29			
					,E30			
					,E31			
					,E32			
					,E33			
					,E34			
					,E35			
					,E36			
					,E37			
					,E38			
					,E39			
					,E40			
					,E41			
					,E42			
					,E43			
					,E44			
					,E45			
					,E46			
					,E47			
					,E48			
					,E49			
					,E50
				)
				SELECT
				 l.PK_Event	
				,PK_Distributor	
				,CreatedDate	
				,UpdatedDate	
				,Q01			
				,Q02			
				,Q03			
				,Q04			
				,Q05			
				,Q06			
				,Q07			
				,Q08			
				,Q09			
				,Q10			
				,Q11			
				,Q12			
				,Q13			
				,Q14			
				,Q15			
				,Q16			
				,Q17			
				,Q18			
				,Q19			
				,Q20			
				,Q21			
				,Q22			
				,Q23			
				,Q24			
				,Q25			
				,Q26			
				,Q27			
				,Q28			
				,Q29			
				,Q30			
				,Q31			
				,Q32			
				,Q33			
				,Q34			
				,Q35			
				,Q36			
				,Q37			
				,Q38			
				,Q39			
				,Q40			
				,Q41			
				,Q42			
				,Q43			
				,Q44			
				,Q45			
				,Q46			
				,Q47			
				,Q48			
				,Q49			
				,Q50	
				,E01			
				,E02			
				,E03			
				,E04			
				,E05			
				,E06			
				,E07			
				,E08			
				,E09			
				,E10			
				,E11			
				,E12			
				,E13			
				,E14			
				,E15			
				,E16			
				,E17			
				,E18			
				,E19			
				,E20			
				,E21			
				,E22			
				,E23			
				,E24			
				,E25			
				,E26			
				,E27			
				,E28			
				,E29			
				,E30			
				,E31			
				,E32			
				,E33			
				,E34			
				,E35			
				,E36			
				,E37			
				,E38			
				,E39			
				,E40			
				,E41			
				,E42			
				,E43			
				,E44			
				,E45			
				,E46			
				,E47			
				,E48			
				,E49			
				,E50
			FROM #EventQual
			CROSS APPLY #Locations AS l

				CREATE INDEX [IX_Event_DSQual_PK_Event] ON [Event].[DSQual](PK_Event);
				CREATE INDEX [IX_Event_DSQual_PK_Distributor_PK_Event] ON [Event].[DSQual](PK_Distributor) INCLUDE(PK_Event);
			END
			ELSE IF @IsDevQA = 3
			BEGIN

				DROP TABLE IF EXISTS ##Event_DSQual_jgue 
				 
				SELECT
				 l.PK_Event	
				,PK_Distributor	
				,CreatedDate	
				,UpdatedDate	
				,Q01			
				,Q02			
				,Q03			
				,Q04			
				,Q05			
				,Q06			
				,Q07			
				,Q08			
				,Q09			
				,Q10			
				,Q11			
				,Q12			
				,Q13			
				,Q14			
				,Q15			
				,Q16			
				,Q17			
				,Q18			
				,Q19			
				,Q20			
				,Q21			
				,Q22			
				,Q23			
				,Q24			
				,Q25			
				,Q26			
				,Q27			
				,Q28			
				,Q29			
				,Q30			
				,Q31			
				,Q32			
				,Q33			
				,Q34			
				,Q35			
				,Q36			
				,Q37			
				,Q38			
				,Q39			
				,Q40			
				,Q41			
				,Q42			
				,Q43			
				,Q44			
				,Q45			
				,Q46			
				,Q47			
				,Q48			
				,Q49			
				,Q50	
				,E01			
				,E02			
				,E03			
				,E04			
				,E05			
				,E06			
				,E07			
				,E08			
				,E09			
				,E10			
				,E11			
				,E12			
				,E13			
				,E14			
				,E15			
				,E16			
				,E17			
				,E18			
				,E19			
				,E20			
				,E21			
				,E22			
				,E23			
				,E24			
				,E25			
				,E26			
				,E27			
				,E28			
				,E29			
				,E30			
				,E31			
				,E32			
				,E33			
				,E34			
				,E35			
				,E36			
				,E37			
				,E38			
				,E39			
				,E40			
				,E41			
				,E42			
				,E43			
				,E44			
				,E45			
				,E46			
				,E47			
				,E48			
				,E49			
				,E50
			INTO ##Event_DSQual_jgue
			FROM #EventQual
			CROSS APPLY #Locations AS l

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

		IF @IsDevQA = 1
		BEGIN
		SELECT 
		 	[Milestone]		
		 	,[StepGroup]	
		 	,[StepSubGroup] 
		 	,[StepStart]	
		 	,[Duration]		
		FROM #TimeLog
		END	
		
END TRY
BEGIN CATCH
 	SET @Error = ERROR_NUMBER()
 	SET @ErrorMessage = ERROR_MESSAGE()
 	SET @StoredProcedure = ERROR_PROCEDURE()

 	IF @IsDevQA = 0 
	BEGIN  
		SELECT ERROR_LINE() AS ErrorLine;  		
		SELECT @Error AS [Error], @ErrorMessage AS [Error Message];
	END  

 	-- UPDATE ERROR LOG
 	EXEC dbo.usp_Utility_UpdateErrorLog 
 			@ProcedureName = @StoredProcedure 
 			,@ErrorNumber = 3
 			,@ErrorMessage = @ErrorMessage
 			,@SQLErrorCode = @Error
 			,@SQLErrorMsg = @ErrorMessage
END CATCH;
END