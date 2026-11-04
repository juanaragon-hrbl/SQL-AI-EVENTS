CREATE PROCEDURE [dbo].[usp_EventQual_NAM_JKO_Jan_2025]
	--Error Parameters
	@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT
	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
	,@Step SMALLINT = 10
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_NAM_JKO_Jan_2025

	USE:		

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC dbo.usp_EventQual_NAM_JKO_Jan_2025
					@Error = @Error OUTPUT,
					@ErrorMessage = @ErrorMessage OUTPUT,
					@Step = 10

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
	1.0.0		2024-09-20		JuanGue		Initial 
	1.0.1		2024-09-24		JuanGue		fIX #SKUsQsMapping
	1.0.2		2024-09-27		JuanGue		PC points fix and multilocation
	1.0.3		2024-10-07		JuanGue		#1367441 25020 - NAM JKO Jan 2025 - Q3 250 PC Dec
	1.0.4		2024-10-09		JuanGue		Removing Codesmells
	1.0.5		2024-10-14		JuanGue		#1368484 25020 - NAM JKO Jan 2025 - SKU E1 Max
	1.0.6		2024-10-15		JuanGue		#1368486 25020 - NAM JKO Jan 2025 - API SKU
	2.0.0		2024-11-27		JuanGue		Including tables to overwrite contributors
	2.0.1		2024-12-03		JuanGue		BRD v2.1
	***********************************************************************************************************************************/
	
	DROP TABLE IF EXISTS #Locations

	CREATE TABLE #Locations
	(
		[Location]		[varchar](250),
		[PK_Event]		[int],
		[IsMain] [bit]	DEFAULT(0),
		[ctrl] [bit]	DEFAULT(0)
	)

	-- Setting up the quals and subevents to the events
	INSERT INTO #Locations(PK_Event,[Location],IsMain) 
				VALUES	(201402,'NAM JKO Jan 2025 - Custom Tracker'		,1) --Main
						,(201553,'NAM JKO Jan 2025 - Pomona'			,0) --Pomona
						,(201554,'NAM JKO Jan 2025 - Chicago'			,0) --Chicago
						,(201555,'NAM JKO Jan 2025 - Montreal'			,0) --Montreal
						,(201556,'NAM JKO Jan 2025 - Dallas'			,0) --Dallas
						,(201557,'NAM JKO Jan 2025 - Puerto Rico'		,0) --Puerto Rico
						,(201558,'NAM JKO Jan 2025 - New York'			,0) --New York
						,(201559,'NAM JKO Jan 2025 - Miami'				,0) --Miami
						,(201560,'NAM JKO Jan 2025 - Atlanta'			,0) --Atlanta
						,(201561,'NAM JKO Jan 2025 - San Jose'			,0) --San Jose
						,(201562,'NAM JKO Jan 2025 - Worcester'			,0) --Worcester

	DECLARE @PK_Event INT  = (SELECT PK_Event FROM #Locations WHERE IsMain = 1),
			@iCurrentDate INT 

	IF (@IsDevQA = 3)
	BEGIN
		
		DROP TABLE IF EXISTS ##DSQualPoints_jgue

		CREATE TABLE ##DSQualPoints_jgue(
			[PK_Distributor] [int] NULL,
			[PK_Event] [int] NULL,
			[QualificationNumber] [int] NULL,
			[Part] [int] NULL,
			[QualDate] [datetime2](7) NULL
		)
		
		DROP TABLE IF EXISTS ##tmp_DS_jgue

		CREATE TABLE ##tmp_DS_jgue
		(
			[PK_Event] INT NULL,
			[PK_Distributor]  INT NULL, 
			[PK_DSType] INT NULL, 
			[StartDate]  INT NULL,
			[EndDate]  INT NULL
		)
		
		DROP TABLE IF EXISTS ##Event_SetupEventQualification_jgue

		CREATE TABLE ##Event_SetupEventQualification_jgue(
			[PK_Event] [int] NULL,
			[QualificationNumber] [int] NULL,
			[Part] [int] NULL,
			[MetricType] [varchar](50) NULL,
			[dStartDate] [datetime2](7) NULL,
			[dEndDate] [datetime2](7) NULL,
			[Frequency] [int] NULL,
			[Consecutive] [bit] NULL,
			[Accumulated] [bit] NULL,
			[MinPoints] [money] NULL,
			[GoalPoints] [money] NULL,
			[Countries] [varchar](max) NULL,
			[Bonus] [bit] NULL,
			[QSVolume] [bit] NULL,
			[QSVolumePercentage] [int] NULL,
			[MetricTypeDefinition]		VARCHAR(50) NULL
		)
		
		DROP TABLE IF EXISTS ##tmp_DSQualDef_jgue

		CREATE TABLE ##tmp_DSQualDef_jgue
		(
			PK_Event			int,
			PK_Distributor		int,
			dStartDate			datetime2,
			dEndDate			datetime2,
			iStartDate			int,
			iEndDate			int,
			[dSPQualDate]		datetime2,
			[iSPQualDate]		int,
			Frequency			int,
			Consecutive			bit,
			Accumulated			bit,
			[MetricType]		[varchar](50) NULL,
			GoalPoints			money,
			MinPoints			money,
			QualificationNumber int,
			Part				int,
			PK_AssociatedID		int,
			Countries			varchar(max),
			Bonus				bit,
			[QSVolume]			bit,
			[QSVolumePercentage]		int
	
		)

		DROP TABLE IF EXISTS ##Event_DSPoints_jgue

		CREATE TABLE ##Event_DSPoints_jgue(
			[PK_Distributor] [int] NULL,
			[PK_Event] [int] NULL,
			[PK_Country] [int] NULL,
			[RoyaltyMonth] [int] NULL,
			[MetricType] [varchar](20) NULL,
			[PersonalPoints] [money] NULL DEFAULT(0),
			[TransferPoints] [money] NULL DEFAULT(0),
			[MainPoints] [money] NULL DEFAULT(0),
			[Points] [money] NULL,
			[Bonus] [money] NULL DEFAULT(0),
		)

		DROP TABLE IF EXISTS ##DSPointsSummary_jgue

		CREATE TABLE ##DSPointsSummary_jgue
		(
			PK_Event			int,
			PK_Distributor		int,
			RoyaltyMonth		int,
			[MetricType] [varchar](20) NULL,
			PK_Country			int,
			[Points]			money,
			[Bonus]				money,
			[QSVolume]			bit,
			[QSVolumePercentage]		int,
			[iSPQualDate]		int,
			QualificationNumber int,
			Part				int,
			HasBonus			bit,
			[TotalPoints]		money,
			iStartDate			int,
			iEndDate			int,
			Countries			varchar(max)
	
		)

	END

	IF @IsDevQA = 3 AND OBJECT_ID('[tempdb].dbo.##usp_GetDSVolume_jgue') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetDSVolume_jgue] is missing, create it manually' AS [ErrorMessage]
	END

	IF @IsDevQA = 3 AND OBJECT_ID('[tempdb].dbo.##usp_GetQualifier_Points_jgue') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetQualifier_Points_jgue] is missing, create it manually' AS [ErrorMessage]
	END

	SET NOCOUNT ON;

	IF @IsDevQA = 3 AND ( OBJECT_ID('[tempdb].dbo.##DSQualPoints_jgue') IS NULL OR 
		OBJECT_ID('[tempdb].dbo.##tmp_DS_jgue') IS NULL OR
		OBJECT_ID('[tempdb].dbo.##Event_SetupEventQualification_jgue') IS NULL OR
		OBJECT_ID('[tempdb].dbo.##Event_DSPoints_jgue') IS NULL OR
		OBJECT_ID('[tempdb].dbo.##DSPointsSummary_jgue') IS NULL)
	BEGIN
		SELECT 'Temp tables are missing, create them manually' AS [Error]
		SET @ErrorMessage = 'Temp tables are missing, create them manually'
	END


	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
				
	SELECT @Error = 0, @ErrorMessage = '';	
	   
BEGIN TRY

	--Quals block
	BEGIN 
		
		--Variables and temp tables 
		BEGIN		 

		DROP TABLE IF EXISTS #WRK_25020_BonusPerMonth

		CREATE TABLE #WRK_25020_BonusPerMonth
		(
			PK_Distributor BIGINT DEFAULT 0,
			ApplicationDate INT DEFAULT 0,
			[Total DS Bonus] MONEY DEFAULT 0,
			[Total New DS] INT DEFAULT 0,
			[Total PM Bonus] MONEY DEFAULT 0,
			[Total New PM] INT DEFAULT 0,
			[Total FQS Bonus] MONEY DEFAULT 0,
			[Total New FQS] INT DEFAULT 0,
			[Total ASP Bonus] MONEY DEFAULT 0,
			[Total New ASP] INT DEFAULT 0
		)

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
			[Bonus]					bit default(0),
			[QSVolume]				bit,
			[QSVolumePercentage]	int,
			[PeriodType]			tinyint, -- 1 Fixed period, 2 Relative period base on SPQualDate
			[MetricTypeDefinition]	VARCHAR(50) NULL
		)
		
		--Q02 Achieve a minimum of 2,500 VP* in each month for (3) consecutive months during qual period A
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			2					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			'2024-10-01'		AS [dStartDate], 
			'2024-12-01'		AS [dEndDate], 
			3					AS [Frequency], 
			1					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			2500				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV'				AS [MetricTypeDefinition]
	
		--Q03 Achieve a minimum of 250 PC (Personal Consumption) in any two (2) months during qual period A. (For Example: 250 or more in Oct 2024 and Dec 2024 meets criteria)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])
		SELECT 
			@PK_Event					AS [PK_Event],
			3							AS QualificationNumber,
			1							AS Part, 
			'PC'						AS [MetricType], 
			'2024-10-01'				AS [dStartDate], 
			'2024-12-01'				AS [dEndDate],  
			2							AS [Frequency], 
			0							AS [Consecutive], 
			0							AS [Accumulated], 
			0							AS [MinPoints], 
			250							AS [GoalPoints], 
			NULL						AS [Countries],
			0							AS [QSVolume], 
			1							AS [PeriodType], 
			'PPV,PPC,SPC,MB_Points'		AS [MetricTypeDefinition]

		--Q9 Accumulate 20,000 VP* over three (3) months qualification period A
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event					AS [PK_Event],
			4							AS QualificationNumber,
			1							AS Part, 
			'VP'						AS [MetricType], 
			'2024-10-01'				AS [dStartDate], 
			'2024-12-01'				AS [dEndDate], 
			3							AS [Frequency], 
			1							AS [Consecutive], 
			1							AS [Accumulated], 
			0							AS [MinPoints], 
			20000						AS [GoalPoints], 
			NULL						AS [Countries],
			0							AS [QSVolume], 
			1							AS [PeriodType], 
			'TV'						AS [MetricTypeDefinition]

		--Q05 Accumulate 30,000 VP* over three (3) months qualification period A 
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			5					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			'2024-10-01'		AS [dStartDate], 
			'2024-12-01'		AS [dEndDate], 
			3					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			30000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV'				AS [MetricTypeDefinition]

		--Q06 Accumulate 35,000 VP* over three (3) months qualification period A
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			6					AS QualificationNumber,
			1					AS Part, 
			'VP'				AS [MetricType], 
			'2024-10-01'		AS [dStartDate], 
			'2024-12-01'		AS [dEndDate], 
			3					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			35000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'TV'				AS [MetricTypeDefinition]

		--Downlines PM and DS for Bonuses
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			51					AS QualificationNumber,
			1					AS Part, 
			'DS_PPV,DLV_DV'		AS [MetricType], 
			'2024-10-01'		AS [dStartDate], 
			'2024-12-01'		AS [dEndDate],  
			NULL				AS [Frequency], 
			NULL				AS [Consecutive], 
			NULL				AS [Accumulated], 
			NULL				AS [MinPoints], 
			NULL				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			NULL				AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			52					AS QualificationNumber,
			1					AS Part, 
			'PM_PPV'			AS [MetricType], 
			'2024-10-01'		AS [dStartDate], 
			'2024-12-01'		AS [dEndDate],  
			NULL				AS [Frequency], 
			NULL				AS [Consecutive], 
			NULL				AS [Accumulated], 
			NULL				AS [MinPoints], 
			NULL				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			NULL				AS [PeriodType], 
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

		--New DS Bonus and New (PM) Preferred Member Bonus  
		DECLARE 
			@AppDateStart INT = 202410 
			,@AppDateEnd INT = 202412 

		--New ASP Bonus 
		DECLARE 
			@RecognitionMonthStart INT  = 202411
			,@RecognitionMonthEnd INT = 202501
			,@QualifiersLevelSubEvents VARCHAR(10) = '1'
			,@ASPPromoID INT = 36884 

		--Double Volume Month bonus
		DECLARE 
			@DoubleVolumeMonth INT = 202410
			,@DoubleVolumeLimit  INT = 2500

		--Bonus is applicable to Q4,Q5,Q6 
		DECLARE 
			@BonusApplicableFrom INT = 4,
			@BonusApplicableTo INT = 6

		DECLARE @ColumnToPivot NVARCHAR(MAX),
			@SqlStatement NVARCHAR(MAX),
			@Countries VARCHAR(MAX) = 'US,PR,CA,JM,TT' 

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
				(61436,17),
				(61437,18),
				(61438,19),
				(61439,20),
				(61440,21)

		DROP TABLE IF EXISTS #SKUsQsMapping

		CREATE TABLE #SKUsQsMapping
		(
			ID INT IDENTITY(1,1),
			PK_Event INT,
			SKUCode VARCHAR(10),
			QId INT
		)

		INSERT INTO #SKUsQsMapping(PK_Event,SKUCode,QId)
		(SELECT DISTINCT 201553 PK_Event,SKUCode,7  QId FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = 201553) UNION
		(SELECT DISTINCT 201554 PK_Event,SKUCode,8  QId FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = 201554) UNION
		(SELECT DISTINCT 201555 PK_Event,SKUCode,9  QId FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = 201555) UNION
		(SELECT DISTINCT 201556 PK_Event,SKUCode,10 QId FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = 201556) UNION
		(SELECT DISTINCT 201557 PK_Event,SKUCode,11 QId FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = 201557) UNION
		(SELECT DISTINCT 201558 PK_Event,SKUCode,12 QId FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = 201558) UNION
		(SELECT DISTINCT 201559 PK_Event,SKUCode,13 QId FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = 201559) UNION
		(SELECT DISTINCT 201560 PK_Event,SKUCode,14 QId FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = 201560) UNION
		(SELECT DISTINCT 201561 PK_Event,SKUCode,15 QId FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = 201561) UNION
		(SELECT DISTINCT 201562 PK_Event,SKUCode,16 QId FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = 201562) 

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
				IsFromCOP				bit default(0),
				TVPOct24				money default 0,	        
				TVPNov24				money default 0,
				TVPDec24				money default 0,      	        
				PCOct24					money default 0, 
				PCNov24					money default 0, 
				PCDec24	 				money default 0, 
				PPVOct24				money default 0, 
				PPVNov24				money default 0, 
				PPVDec24	   			money default 0, 		
				[New DS Bonus]			money default 0,
				[New PM Bonus]			money default 0,
				[New FQS Bonus]			money default 0,
				[New ASP Bonus]			money default 0,
				[Double Volume Month]	money default 0

			)

			INSERT INTO #DS
			(
				PK_Distributor,	
				DSCurrentTeam,	
				DSSubTeam,		
				DSSPTeam,			
				dSPQualDate,
				dSPRequalDate,
				CountryCode,
				IsFromCOP
			)
			SELECT DISTINCT        
			D.nDistributorID AS PK_Distributor,   
			CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
			D.sSubteam AS DSSubTeam,        
			D.sType AS DSSPTeam,            
			D.dSupervisorqualification AS dSPQualDate,    
			d.dSupervisorReQualification AS dSPRequalDate,
			D.sDistributorCountryProcessingCode AS CountryCode,
			1	AS IsFromCOP
			FROM        
			dbo.v_Distributor AS D  
				INNER JOIN #Countries AS C
					ON D.nDistributorCountryProcessingID = C.nCountryID
			WHERE        
				D.StatusCode = 'COMPLETE'        
				AND D.sType IN ('DS','SP') 

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
	END

	--Step 3: Volume		
	IF @Step >= 3
	BEGIN

		PRINT 'Executing step 3'

		------------------------------------------------------------------------------------------------
		-- 3.1 Getting values from #Event_SetupEventQualification
		------------------------------------------------------------------------------------------------
			
		INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification', 3, 1, GETUTCDATE(), NULL);
		
			DECLARE 
				@iStartDate int,
				@dStartDate datetime,
				@iEndDate int,
				@dEndDate datetime,
				@MetricType varchar(max),
				@DSCountries varchar(max)

			SELECT 
				@iStartDate = CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int), 
				@dStartDate = MIN(dStartDate),
				@iEndDate = CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int),
				@dEndDate = MAX(dEndDate),
				@MetricType = STRING_AGG([MetricType],','),
				@DSCountries = STRING_AGG([Countries],',')
			FROM #Event_SetupEventQualification WITH (NOLOCK)
			WHERE QualificationNumber BETWEEN 6 AND 10
	
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
				SELECT 
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
				--WHERE D.DSSPTeam = 'SP' -- Only SPs can qualify using volume

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

				--Input
				--[tmp].[DS]
				--[Event].[SetupEventQualification]

				--SourceType 1: Getting points from PubEvents.[dbo].[factDSFinancial_ctry], includes divorce and tranfer cases.
				EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 1,@QualFilter = '2,3,4,5,6', @KeepNegativeVolume = 0,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
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
			ELSE
			IF (@IsDevQA = 3) AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_jgue') IS NOT NULL
			BEGIN
					 
				--Input
				--##tmp_DS_jgue
				--##Event_SetupEventQualification_jgue

				EXEC [dbo].[##usp_GetDSVolume_jgue] @PK_Event = @PK_Event, @SourceType = 1,@QualFilter = '2,3,4,5,6', @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
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

				DROP TABLE IF EXISTS [dbo].[WRK_25020_DSPoints] 
					
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
				INTO [dbo].[WRK_25020_DSPoints] 
				FROM #Event_DSPoints

				CREATE INDEX IX_WRK_25020_DSPoints_PK_Distributor ON [dbo].[WRK_25020_DSPoints] (PK_Distributor);

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
					[PersonalPoints] AS [PersonalPoints],
					[TransferPoints] AS [TransferPoints],
					[MainPoints] AS [MainPoints],  
					ROUND([Points],2) AS [Points],
					Bonus
				FROM ##Event_DSPoints_jgue

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
			WHERE D.DSSPTeam = 'DS' AND P.MetricType IN ('PPV','DLV')				 
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
			WHERE D.DSSPTeam = 'SP' AND D.CountryCode IN ('CA','TT','JM') AND P.MetricType = 'PPV'			 
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
			WHERE D.CountryCode NOT IN ('US','PR','CA','TT','JM') AND P.MetricType = 'PPV'			 
			GROUP BY P.PK_Distributor,P.PK_Country,P.RoyaltyMonth
					
			CREATE CLUSTERED INDEX [IX_#Event_DSPoints_Validations_PK_Distributor] ON #Event_DSPoints_Validations ([PK_Distributor]) 
			CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_Validations_MetricType] ON #Event_DSPoints_Validations ([MetricType])

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

				INSERT INTO #tmp_DSQualDef([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries)
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
						C.Countries
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

				SELECT
					DL.PK_Distributor,
					DL.PK_DSDownLine
				INTO #DSDownlines
				FROM #DS AS DS --Uplines from All NAM Countries 
					INNER JOIN dbo.v_dimDSLngDownline AS DL
						ON DS.PK_Distributor = DL.PK_Distributor
				WHERE DL.DSLevelFromUL = 2 
									
			DROP TABLE IF EXISTS #DSAssociatedDownlines

				SELECT  DA.PK_Distributor,
						DA.PK_AssociatedID,
						DL.PK_DSDownLine 
				INTO #DSAssociatedDownlines
				FROM #DS AS D --Uplines from All NAM Countries 
				INNER JOIN [Shared].[DistributorAssociation] AS DA WITH (NOLOCK)
					ON D.PK_Distributor = DA.PK_Distributor
				INNER JOIN dbo.v_dimDSLngDownline AS DL
					ON DA.PK_AssociatedID = DL.PK_Distributor
				WHERE DL.DSLevelFromUL = 2  
				
			DROP TABLE IF EXISTS #DSDownlinesSummary

			CREATE TABLE #DSDownlinesSummary (PK_Distributor INT,PK_DSDownLine INT)

			INSERT INTO #DSDownlinesSummary(PK_Distributor,PK_DSDownLine)
				SELECT 
					D.PK_Distributor,
					D.PK_DSDownLine 
				FROM #DSDownlines AS D
					
			INSERT INTO #DSDownlinesSummary(PK_Distributor,PK_DSDownLine)
				SELECT 
					A.PK_Distributor,
					A.PK_DSDownLine 
				FROM #DSAssociatedDownlines AS A
			WHERE NOT EXISTS (SELECT 1 FROM #DSDownlinesSummary AS S WHERE A.PK_Distributor = S.PK_Distributor AND A.PK_DSDownline = S.PK_DSDownLine)

			CREATE INDEX IX_#DSDownlinesSummary_PK_Distributor ON #DSDownlinesSummary(PK_Distributor) INCLUDE (PK_DSDownLine)

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 1;

		------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- 5.2.1 Obtaining member conversion dates for downlines in order to determine who is eligible for bonuses regardless of DSType, as New PM and New DS bonuses cover the same period.
		------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		INSERT INTO #TimeLog VALUES ('Getting member conversion', 5, 21, GETUTCDATE(), NULL);

		IF @IsDevQA = 0
		BEGIN
			DROP TABLE IF EXISTS [tmp].[DSForConversionEvaluation] -- This tables must be created within qualification if [dbo].[usp_GetDSConversionDates] will be executed

			SELECT DISTINCT
				@PK_Event AS PK_Event, 
				PK_DSDownLine AS [PK_Distributor]
			INTO [tmp].[DSForConversionEvaluation]
			FROM #DSDownlinesSummary  AS L WITH (NOLOCK)
		END
		ELSE IF @IsDevQA = 3
		BEGIN

			DROP TABLE IF EXISTS ##tmp_DSForConversionEvaluation  

			SELECT DISTINCT
				@PK_Event AS PK_Event, 
				PK_DSDownLine AS [PK_Distributor]
			INTO ##tmp_DSForConversionEvaluation  
			FROM #DSDownlinesSummary  AS L WITH (NOLOCK)

		END

		DROP TABLE IF EXISTS #MemberLastestConversionResult

		CREATE TABLE #MemberLastestConversionResult
		(
			[PK_Event] INT, 
			PK_Distributor BIGINT,
			LastDSConversionMonth INT,
			LastPMConversionMonth INT,
			LatestConversionMonth INT,
			LatestConversionType VARCHAR(25)
		)

		INSERT INTO #TimeLog VALUES ('usp_GetDSConversionDates', 5, 211, GETUTCDATE(), NULL);
			
		IF @IsDevQA = 0
		BEGIN
						
			--Input [tmp].[DSForConversionEvaluation]
			EXEC dbo.usp_GetDSConversionDates @PK_Event = @PK_Event, @IsDevQA = @IsDevQA, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
			--Output  [tmp].[MemberLastestConversion]

			INSERT INTO #MemberLastestConversionResult([PK_Event],
				PK_Distributor,
				LastDSConversionMonth,
				LastPMConversionMonth,
				LatestConversionMonth,
				LatestConversionType)
			SELECT  
				[PK_Event],
				PK_Distributor,
				LastDSConversionMonth,
				LastPMConversionMonth,
				LatestConversionMonth,
				LatestConversionType
			FROM [tmp].[MemberLastestConversion] WITH (NOLOCK)

			IF @Error <> 0
			BEGIN
				SET @Error = @Error
				SET @ErrorMessage = @ErrorMessage
				RETURN;
			END
		
		END
		ELSE IF @IsDevQA = 3
		BEGIN
	
			--Input
			--##tmp_DSForConversionEvaluation

			EXEC [dbo].[##usp_GetDSConversionDates_jgue] @PK_Event = @PK_Event, @IsDevQA = @IsDevQA, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
			IF @Error <> 0
			BEGIN
				SET @Error = @Error
				SET @ErrorMessage = @ErrorMessage

				SELECT @ErrorMessage
				RETURN;
			END

			--Output
			--##tmp_MemberLastestConversion
		
			INSERT INTO #MemberLastestConversionResult([PK_Event],
				PK_Distributor,
				LastDSConversionMonth,
				LastPMConversionMonth,
				LatestConversionMonth,
				LatestConversionType)
			SELECT  
				[PK_Event],
				PK_Distributor,
				LastDSConversionMonth,
				LastPMConversionMonth,
				LatestConversionMonth,
				LatestConversionType 
			FROM ##tmp_MemberLastestConversion							 
		
		END 
			
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 211;

		INSERT INTO #TimeLog VALUES ('[dbo].[WRK_25020_DownlineLatestApplicationDateEval]', 5, 212, GETUTCDATE(), NULL);

		DROP TABLE IF EXISTS #DownlineApplicationDate			
			 
		SELECT D.PK_Distributor
			,d.PK_DSDownLine 
			,DD.SPQualDate 
			,DD.QSQualDate 		 
			,DD.PK_DSType
			,DD.MBContractAcceptanceDate
			,DD.ConversionDate					  
			,DD.initialAppDate
			,DD.SPRequalDate
			,IIF(DD.PK_DSType IN (4,5),IIF(ISNULL(LatestConversionMonth,190001) > LEFT(ApplicationDate,6), LatestConversionMonth,LEFT(ApplicationDate,6)),
			IIF(DD.PK_DSType IN (6,7), IIF (ISNULL(LatestConversionMonth,190001) > LEFT(MBApplicationDate,6), LatestConversionMonth,LEFT(MBApplicationDate,6)), LEFT(ApplicationDate,6))) AS ApplicationDate
			,ISNULL(LatestConversionMonth,190001) AS LatestConversionMonth
			,LEFT(ApplicationDate,6) DSApplicationDate
			,LEFT(MBApplicationDate,6) MBApplicationDate
		INTO #DownlineApplicationDate
		FROM #DSDownlinesSummary  AS d -- Source of DS for evaluation
		INNER JOIN [PubEvents].[dbo].[dimDistributor] AS DD WITH (NOLOCK)
			ON d.PK_DSDownLine = DD.PK_Distributor
		LEFT JOIN #MemberLastestConversionResult AS dc WITH (NOLOCK)
			ON d.PK_DSDownLine = dc.PK_Distributor
		WHERE dc.PK_Event = @PK_Event
	 
		IF @IsDevQA = 0
		BEGIN
			 
		DROP TABLE IF EXISTS [dbo].[WRK_25020_DownlineApplicationDateEval]

		SELECT 
			DISTINCT
			PK_Distributor
			,PK_DSDownLine 
			,SPQualDate 
			,QSQualDate 		 
			,PK_DSType
			,MBContractAcceptanceDate
			,ConversionDate					  
			,initialAppDate
			,SPRequalDate
			,ApplicationDate
			,LatestConversionMonth
			,DSApplicationDate
			,MBApplicationDate
			,ROW_NUMBER() OVER (PARTITION BY PK_Distributor,PK_DSDownLine ORDER BY ApplicationDate DESC) row_num
		INTO [dbo].[WRK_25020_DownlineApplicationDateEval]
		FROM #DownlineApplicationDate  

		DROP TABLE IF EXISTS [dbo].[WRK_25020_DownlineLatestApplicationDateEval]

		SELECT 
			DISTINCT
			PK_Distributor
			,PK_DSDownLine 
			,SPQualDate 
			,QSQualDate 		 
			,PK_DSType
			,MBContractAcceptanceDate
			,ConversionDate					  
			,initialAppDate
			,SPRequalDate
			,ApplicationDate
			,LatestConversionMonth
			,DSApplicationDate
			,MBApplicationDate 
		INTO [dbo].[WRK_25020_DownlineLatestApplicationDateEval]
		FROM [dbo].[WRK_25020_DownlineApplicationDateEval] WITH (NOLOCK) WHERE row_num = 1 
		
	END
	ELSE
	BEGIN
	
		DROP TABLE IF EXISTS [dbo].[##WRK_25020_DownlineApplicationDateEval]

		SELECT 
			DISTINCT
			PK_Distributor
			,PK_DSDownLine 
			,SPQualDate 
			,QSQualDate 		 
			,PK_DSType
			,MBContractAcceptanceDate
			,ConversionDate					  
			,initialAppDate
			,SPRequalDate
			,ApplicationDate
			,LatestConversionMonth
			,DSApplicationDate
			,MBApplicationDate
			,ROW_NUMBER() OVER (PARTITION BY PK_Distributor,PK_DSDownLine ORDER BY ApplicationDate DESC) row_num
		INTO [dbo].[##WRK_25020_DownlineApplicationDateEval]
		FROM #DownlineApplicationDate  

		DROP TABLE IF EXISTS [dbo].[##WRK_25020_DownlineLatestApplicationDateEval]

		SELECT 
			DISTINCT
			PK_Distributor
			,PK_DSDownLine 
			,SPQualDate 
			,QSQualDate 		 
			,PK_DSType
			,MBContractAcceptanceDate
			,ConversionDate					  
			,initialAppDate
			,SPRequalDate
			,ApplicationDate
			,LatestConversionMonth
			,DSApplicationDate
			,MBApplicationDate 
		INTO [dbo].[##WRK_25020_DownlineLatestApplicationDateEval]
		FROM [dbo].[##WRK_25020_DownlineApplicationDateEval] WHERE row_num = 1 
	END



			
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 212;

		INSERT INTO #TimeLog VALUES ('WRK_25020_DSDownlines', 5, 213, GETUTCDATE(), NULL);

		--// Freezing DS status, regardless of the conversion during the month, the status will be updated only on the first day of the month.
		IF @IsDevQA = 0
		BEGIN

			IF OBJECT_ID (N'WRK_25020_DSDownlines_History', N'U') IS NULL 
			BEGIN
				CREATE TABLE [dbo].[WRK_25020_DSDownlines_History]
				(
					[CreatedDateUTC]   DATETIME       DEFAULT (GETUTCDATE()) NULL
					,PK_Distributor INT
					,PK_DSDownLine INT	 
					,PK_DSType INT
					,ConversionDate INT					  
					,initialAppDate INT
					,ApplicationDate INT
					,LatestConversionMonth INT
					,DSApplicationDate INT
					,MBApplicationDate INT
					,SPQualDate INT
					,SPRequalDate INT
				) 

			END

			IF OBJECT_ID (N'WRK_25020_DSDownlines', N'U') IS NULL 
			BEGIN
				CREATE TABLE [dbo].[WRK_25020_DSDownlines]
				(
					PK_Distributor INT
					,PK_DSDownLine INT	 
					,PK_DSType INT
					,ConversionDate INT					  
					,initialAppDate INT
					,ApplicationDate INT
					,LatestConversionMonth INT
					,DSApplicationDate INT
					,MBApplicationDate INT
					,SPQualDate INT
					,SPRequalDate INT
				) 
			END

			INSERT INTO [dbo].[WRK_25020_DSDownlines_History](PK_Distributor
							,PK_DSDownLine 	 
							,PK_DSType
							,ConversionDate					  
							,initialAppDate
							,ApplicationDate
							,LatestConversionMonth
							,DSApplicationDate
							,MBApplicationDate
							,SPQualDate
							,SPRequalDate)
			SELECT PK_Distributor
							,PK_DSDownLine 	 
							,PK_DSType
							,ConversionDate					  
							,initialAppDate
							,ApplicationDate
							,LatestConversionMonth
							,DSApplicationDate
							,MBApplicationDate
							,SPQualDate
							,SPRequalDate
			FROM [dbo].[WRK_25020_DSDownlines] WITH (NOLOCK)

			MERGE [dbo].[WRK_25020_DSDownlines] AS T
				USING [dbo].[WRK_25020_DownlineLatestApplicationDateEval]	AS S
				ON S.PK_Distributor = T.PK_Distributor AND S.PK_DSDownLine = T.PK_DSDownLine   
				WHEN NOT MATCHED BY Target THEN
					INSERT (PK_Distributor
							,PK_DSDownLine 	 
							,PK_DSType
							,ConversionDate					  
							,initialAppDate
							,ApplicationDate
							,LatestConversionMonth
							,DSApplicationDate
							,MBApplicationDate
							,SPQualDate
							,SPRequalDate) 
					VALUES (S.PK_Distributor
						,S.PK_DSDownLine 	 
						,S.PK_DSType
						,S.ConversionDate					  
						,S.initialAppDate
						,S.ApplicationDate
						,S.LatestConversionMonth
						,S.DSApplicationDate
						,S.MBApplicationDate 
						,S.SPQualDate
						,S.SPRequalDate)    
				WHEN MATCHED 
					THEN UPDATE SET
					T.PK_DSType				= S.PK_DSType
					,T.ConversionDate			= S.ConversionDate					  
					,T.initialAppDate			= S.initialAppDate
					,T.ApplicationDate			= S.ApplicationDate
					,T.LatestConversionMonth	= S.LatestConversionMonth
					,T.DSApplicationDate		= S.DSApplicationDate
					,T.MBApplicationDate 		= S.MBApplicationDate 
					,T.SPQualDate				= s.SPQualDate
					,T.SPRequalDate				= s.SPRequalDate
				;		 
					
		END
		ELSE IF @IsDevQA = 3
		BEGIN

				
			IF OBJECT_ID('tempdb.dbo.##WRK_25020_DSDownlines') IS NULL 
			BEGIN			 

				CREATE TABLE [dbo].[##WRK_25020_DSDownlines]
				(
					PK_Distributor INT
					,PK_DSDownLine INT	 
					,PK_DSType INT
					,ConversionDate INT					  
					,initialAppDate INT
					,ApplicationDate INT
					,LatestConversionMonth INT
					,DSApplicationDate INT
					,MBApplicationDate INT
					,SPQualDate INT
					,SPRequalDate INT
				)

			END

				MERGE [dbo].[##WRK_25020_DSDownlines] AS T
				USING [dbo].[##WRK_25020_DownlineLatestApplicationDateEval]	AS S
						ON S.PK_Distributor = T.PK_Distributor AND S.PK_DSDownLine = T.PK_DSDownLine  
				WHEN NOT MATCHED BY Target THEN
					INSERT (PK_Distributor
							,PK_DSDownLine 	 
							,PK_DSType
							,ConversionDate					  
							,initialAppDate
							,ApplicationDate
							,LatestConversionMonth
							,DSApplicationDate
							,MBApplicationDate
							,SPQualDate
							,SPRequalDate) 
					VALUES (S.PK_Distributor
						,S.PK_DSDownLine 	 
						,S.PK_DSType
						,S.ConversionDate					  
						,S.initialAppDate
						,S.ApplicationDate
						,S.LatestConversionMonth
						,S.DSApplicationDate
						,S.MBApplicationDate 
						,S.SPQualDate
						,S.SPRequalDate)    
				WHEN MATCHED 
					THEN UPDATE SET
					T.PK_DSType				= S.PK_DSType
					,T.ConversionDate			= S.ConversionDate					  
					,T.initialAppDate			= S.initialAppDate
					,T.ApplicationDate			= S.ApplicationDate
					,T.LatestConversionMonth	= S.LatestConversionMonth
					,T.DSApplicationDate		= S.DSApplicationDate
					,T.MBApplicationDate 		= S.MBApplicationDate 
					,T.SPQualDate				= s.SPQualDate
					,T.SPRequalDate				= s.SPRequalDate
				;		 

		END
						
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 213;

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 1;
					 
		------------------------------------------------------------------------------------------------
		-- 5.2 Getting values from #Event_SetupEventQualification
		------------------------------------------------------------------------------------------------
			
		INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification', 5, 2, GETUTCDATE(), NULL);

			SELECT 
				@iStartDate = CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int), 
				@dStartDate = MIN(dStartDate),
				@iEndDate = CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int),
				@dEndDate = MAX(dEndDate),
				@MetricType = STRING_AGG([MetricType],','),
				@DSCountries = STRING_AGG([Countries],',')
			FROM #Event_SetupEventQualification WITH (NOLOCK)
			WHERE QualificationNumber IN (51,52)
	
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 2;

			-- Result set 
			SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate],@DSCountries AS [DSCountries],@MetricType AS [MetricType]
				 
		------------------------------------------------------------------------------------------------
		-- 5.3 Getting #tmp_DS
		------------------------------------------------------------------------------------------------

		INSERT INTO #TimeLog VALUES ('#tmp_DS', 5, 3, GETUTCDATE(), NULL);

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
						D.PK_DSType -- Frezee type
					FROM [dbo].[WRK_25020_DSDownlines] AS D WITH (NOLOCK)
					INNER JOIN [PubEvents].[dbo].dimDistributor AS DD WITH (NOLOCK)
						ON D.PK_DSDownLine = DD.PK_Distributor

				END ELSE
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
						D.PK_DSType -- Frezee type
					FROM [dbo].[##WRK_25020_DSDownlines] AS D
					INNER JOIN [PubEvents].[dbo].dimDistributor AS DD WITH (NOLOCK)
						ON D.PK_DSDownLine = DD.PK_Distributor

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
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 3;

		------------------------------------------------------------------------------------------------
		-- 5.4 Getting [Event].[DSPoints]
		------------------------------------------------------------------------------------------------
			
		IF (@IsDevQA = 0)
		BEGIN
			INSERT INTO #TimeLog VALUES ('usp_GetDSVolume', 5, 4, GETUTCDATE(), NULL);

			--Input
			--[tmp].[DS]
			--[Event].[SetupEventQualification]
			--IF @EnableConversionDates = 1 [tmp].[MemberLastestConversion]

			--SourceType 1: Getting points from PubEvents.[dbo].[factDSFinancial_ctry], includes divorce and tranfer cases.
			EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 1, @QualFilter = '51,52', @EnableConversionDates = 1,@KeepNegativeVolume = 0, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
				
			--Output [Event].[DSPoints]
			--Output [tmp].[DSSummary] 

			IF @Error <> 0
			BEGIN
				SET @Error = @Error
				SET @ErrorMessage = @ErrorMessage
				RETURN;
			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 4;
		
		END
		ELSE
		IF (@IsDevQA = 3) AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_jgue') IS NOT NULL
		BEGIN
					 
			INSERT INTO #TimeLog VALUES ('##usp_GetDSVolume_jgue', 5, 4, GETUTCDATE(), NULL);

			--Input
			--##tmp_DS_jgue
			--##Event_SetupEventQualification_jgue
			--IF @EnableConversionDates = 1 ##tmp_MemberLastestConversion

			EXEC [dbo].[##usp_GetDSVolume_jgue] @PK_Event = @PK_Event, @SourceType = 1,@QualFilter = '51,52', @EnableConversionDates = 1,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
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
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 4;
		
		END

		------------------------------------------------------------------------------------------------
		-- 5.5 Getting #Event_DownlinesPoints  
		------------------------------------------------------------------------------------------------
		
		INSERT INTO #TimeLog VALUES ('#Event_DownlinesPoints', 5, 5, GETUTCDATE(), NULL);

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

				DROP TABLE IF EXISTS [dbo].[WRK_25020_DownlinesPoints]

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
				INTO [dbo].[WRK_25020_DownlinesPoints]
				FROM #Event_DownlinesPoints

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

				DROP TABLE IF EXISTS ##WRK_25020_DownlinesPoints

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
				INTO ##WRK_25020_DownlinesPoints
				FROM #Event_DownlinesPoints

			END

			CREATE CLUSTERED INDEX [IX_#Event_DownlinesPoints_PK_Distributor] ON #Event_DownlinesPoints ([PK_Distributor]) 
			CREATE NONCLUSTERED INDEX [IX_#Event_DownlinesPoints_MetricType] ON #Event_DownlinesPoints ([MetricType])
			
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 5;
			
		------------------------------------------------------------------------------------------------
		-- 5.6 Getting #Event_DownlinesPoints  
		------------------------------------------------------------------------------------------------
		
		INSERT INTO #TimeLog VALUES ('#Event_DownlinesPoints', 5, 6, GETUTCDATE(), NULL);

		DROP TABLE IF EXISTS #DownlinesPeriod

		CREATE TABLE #DownlinesPeriod
		(
			PK_Distributor INT,
			PK_DSDownline INT,
			PK_DSType INT,
			ApplicationDate INT,
			StartMonth INT,
			EndMonth INT
		)

		IF @IsDevQA = 0
		BEGIN
			INSERT INTO #DownlinesPeriod(PK_Distributor,
				PK_DSDownline,
				PK_DSType,
				ApplicationDate, 
				StartMonth, 
				EndMonth)
			SELECT 
				PK_Distributor,
				PK_DSDownline,
				PK_DSType,
				ApplicationDate, 
				ApplicationDate AS StartMonth, 
				IIF( ApplicationDate+1 > @AppDateEnd,@AppDateEnd, ApplicationDate+1 )  AS EndMonth
			FROM [dbo].[WRK_25020_DSDownlines] AS D WITH (NOLOCK)
			WHERE ApplicationDate BETWEEN @AppDateStart AND @AppDateEnd
		END ELSE IF @IsDevQA = 3
		BEGIN
			INSERT INTO #DownlinesPeriod(PK_Distributor,
				PK_DSDownline,
				PK_DSType,
				ApplicationDate, 
				StartMonth, 
				EndMonth)
			SELECT 
				PK_Distributor,
				PK_DSDownline,
				PK_DSType,
				ApplicationDate, 
				ApplicationDate AS StartMonth, 
				IIF( ApplicationDate+1 > @AppDateEnd,@AppDateEnd, ApplicationDate+1 )  AS EndMonth
			FROM [dbo].[##WRK_25020_DSDownlines] AS D
			WHERE ApplicationDate BETWEEN @AppDateStart AND @AppDateEnd
		END

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 6;
					 		
		------------------------------------------------------------------------------------------------
		-- 5.7  Bonuses assignation / [tmp].[DSPointsSummary]		
		------------------------------------------------------------------------------------------------
	 
		--// Double volume month
		----------------------------------------------------------------------------------------------------------------------------------- 
		--Double Volume Points in OCT 2024 up to 2500 Bonus Points. Applicable towards the Accumulated VIP Points.
		-- *Bonus Points DO NOT count towards the Personal TDV
		-- *Double bonus is NOT applicable for sections 6.1, 6.2, 6.3, 6.4
		----------------------------------------------------------------------------------------------------------------------------------- 

		-- This bonus is assigned below on #WRK_25020_BonusPoints

		--// New DS Bonus
		----------------------------------------------------------------------------------------------------------------------------------- 
		--Earn 1000 Bonus Points for each Personally Sponsored Downline WW with most recent (application date or conversion date, including converted from preferred members/preferred customers)
		--	Must be 1st line Distributor Personally Sponsored (DS Level)
		--	Application date OCT 2024 - DEC 2024 
		--	Purchase a minimum of 100 Documented PPV or DLV or combination of both (PPV DV + DLV DV) from their most recent application or conversion date month until the end of the following month, limited by the end of the qual period which ends DECEMBER 2024. 
		--	Freeze contributor(s)
		--	Applicable towards the ACCUMULATED VIP Points NOT towards the Personal TDV
		--	See Rules 15.1 and Bonus Example Page
		----------------------------------------------------------------------------------------------------------------------------------- 
			
		INSERT INTO #TimeLog VALUES ('New DS Bonus', 5, 71, GETUTCDATE(), NULL);

		DROP TABLE IF EXISTS #DSDownlinesPeriod

		CREATE TABLE #DSDownlinesPeriod
		(
			PK_Distributor INT,
			PK_DSDownline INT,
			PK_DSType INT,
			ApplicationDate INT,
			StartMonth INT,
			EndMonth INT
		)

		IF @IsDevQA = 0
		BEGIN
			INSERT INTO #DSDownlinesPeriod(PK_Distributor,
				PK_DSDownline,
				PK_DSType,
				ApplicationDate, 
				StartMonth, 
				EndMonth)
			SELECT 
				PK_Distributor,
				PK_DSDownline,
				PK_DSType,
				ApplicationDate, 
				ApplicationDate AS StartMonth, 
				IIF( ApplicationDate+1 > @AppDateEnd,@AppDateEnd, ApplicationDate+1 )  AS EndMonth
			FROM [dbo].[WRK_25020_DSDownlines] AS D WITH (NOLOCK)
			WHERE ApplicationDate BETWEEN @AppDateStart AND @AppDateEnd

		END ELSE IF @IsDevQA = 3
		BEGIN
			INSERT INTO #DSDownlinesPeriod(PK_Distributor,
				PK_DSDownline,
				PK_DSType,
				ApplicationDate, 
				StartMonth, 
				EndMonth)
			SELECT 
				PK_Distributor,
				PK_DSDownline,
				PK_DSType,
				ApplicationDate, 
				ApplicationDate AS StartMonth, 
				IIF( ApplicationDate+1 > @AppDateEnd,@AppDateEnd, ApplicationDate+1 )  AS EndMonth
			FROM [dbo].[##WRK_25020_DSDownlines] AS D WITH (NOLOCK)
			WHERE ApplicationDate BETWEEN @AppDateStart AND @AppDateEnd

		END

		DROP TABLE IF EXISTS #NewDSPerMonth

		CREATE TABLE #NewDSPerMonth
		(
			PK_Distributor INT,
			ApplicationDate INT,
			[TotalNewDS] INT,
			[TotalBonusNewDS] MONEY
		)

		DROP TABLE IF EXISTS #NewDSSSummary

		CREATE TABLE #NewDSSSummary
		(
			PK_Distributor INT,
			[TotalNewDS] INT,
			[TotalBonusNewDS] MONEY
		)


		IF @IsDevQA = 0 AND NOT EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25020_NewDSBonusContributors' and type='U')
		BEGIN
			CREATE TABLE [dbo].[WRK_25020_NewDSBonusContributors] 
			(
				[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ApplicationDate INT,
				[ContributionCount] INT DEFAULT (1),
				[Active] BIT DEFAULT 1
			)
		END
		ELSE
		IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##WRK_25020_NewDSBonusContributors') IS NULL 
		BEGIN

			CREATE TABLE [dbo].[##WRK_25020_NewDSBonusContributors] 
			(
				[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ApplicationDate INT,
				[ContributionCount] INT DEFAULT (1),
				[Active] BIT DEFAULT 1
			)
		END

		--// Getting contributors
		DROP TABLE IF EXISTS #NewDS
				
		SELECT d.PK_Distributor,d.PK_DSDownline,d.ApplicationDate, 1 AS [Active] 
		INTO #NewDS
		FROM #DSDownlinesPeriod AS d
		INNER JOIN #Event_DownlinesPoints AS p
			ON d.PK_DSDownline = p.PK_Distributor  AND p.RoyaltyMonth BETWEEN d.StartMonth AND d.EndMonth
		WHERE d.PK_DSType IN (5,4) AND p.MetricType IN ('DS_PPV','DLV_DV')
		GROUP BY d.PK_Distributor, d.PK_DSDownline,d.ApplicationDate
		HAVING SUM(Points) >= 100
			
			--Overwriting contributors 
			DROP TABLE IF EXISTS #NewDSOverwrite

			SELECT 
				U.nDistributorID AS PK_Distributor,
				D.nDistributorID AS PK_DSDownLine,
				o.ContributionMonth AS ApplicationDate,
				MAX(CONVERT(int,o.Active)) AS [Active]
			INTO #NewDSOverwrite
			FROM [dbo].[WRK_25020_NAMJKO_NEWDS_Overwrite] AS o WITH (NOLOCK)
				INNER JOIN v_Distributor AS U
					ON o.UL_DistributorID = U.sDistributorID
				INNER JOIN v_Distributor AS D
					ON o.DL_DistributorID = D.sDistributorID
			GROUP BY U.nDistributorID,
			D.nDistributorID,
			o.ContributionMonth 


			MERGE #NewDS AS t
			USING #NewDSOverwrite  AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active);

		--// Freezing contributors
		IF @IsDevQA = 0
		BEGIN				
					
			UPDATE [dbo].[WRK_25020_NewDSBonusContributors]
			SET Active = 1	
			WHERE Active = 0

			MERGE [dbo].[WRK_25020_NewDSBonusContributors] AS t
			USING #NewDS AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate);

			UPDATE t
			SET Active = s.Active
			FROM [dbo].[WRK_25020_NewDSBonusContributors] AS t
				INNER JOIN #NewDSOverwrite AS s
					ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate

			-- Add contributor by report  
			;WITH cte_NewDSContributorsReport AS
			(
				SELECT 
					U.nDistributorID AS PK_Distributor,
					D.nDistributorID AS PK_DSDownLine,
					o.ContributionMonth AS ApplicationDate,
					1 AS Active,
					o.ContributionsCount
				FROM [dbo].[WRK_25020_NAMJKO_DSBonusContributors] AS o WITH (NOLOCK)
					INNER JOIN v_Distributor AS U
						ON o.UL_DistributorID = U.sDistributorID
					INNER JOIN v_Distributor AS D
						ON o.DL_DistributorID = D.sDistributorID
			)

			MERGE [dbo].[WRK_25020_NewDSBonusContributors] AS t
			USING cte_NewDSContributorsReport  AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active,ContributionCount)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active,ContributionsCount)
			WHEN MATCHED THEN 
			UPDATE SET 
					t.ContributionCount = t.ContributionCount + s.ContributionsCount; 
						

			--// Getting contributors per month
			INSERT INTO #NewDSPerMonth(PK_Distributor,ApplicationDate,[TotalNewDS],[TotalBonusNewDS])
			SELECT 
				F.PK_Distributor,
				F.ApplicationDate,
				SUM([ContributionCount]) AS [TotalNewDS],
				(SUM([ContributionCount]) * 1000) AS [TotalBonusNewDS]
			FROM [dbo].[WRK_25020_NewDSBonusContributors]   AS F WITH (NOLOCK)
			WHERE Active = 1
			GROUP BY F.PK_Distributor,F.ApplicationDate
				 
		END
		ELSE IF @IsDevQA = 3
		BEGIN
 
			MERGE [dbo].[##WRK_25020_NewDSBonusContributors] AS t
			USING #NewDS AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate);
	 
			-- Add contributor by report  
			;WITH cte_NewDSContributorsReport AS
			(
				SELECT 
					U.nDistributorID AS PK_Distributor,
					D.nDistributorID AS PK_DSDownLine,
					o.ContributionMonth AS ApplicationDate,
					1 AS Active,
					o.ContributionsCount
				FROM [dbo].[WRK_25020_NAMJKO_DSBonusContributors] AS o WITH (NOLOCK)
					INNER JOIN v_Distributor AS U
						ON o.UL_DistributorID = U.sDistributorID
					INNER JOIN v_Distributor AS D
						ON o.DL_DistributorID = D.sDistributorID
			)

			MERGE [##WRK_25020_NewDSBonusContributors] AS t
			USING cte_NewDSContributorsReport  AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active,ContributionCount)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active,ContributionsCount)
			WHEN MATCHED THEN 
			UPDATE SET 
					t.ContributionCount = t.ContributionCount + s.ContributionsCount; 

			--// Getting contributors per month
			INSERT INTO #NewDSPerMonth(PK_Distributor,ApplicationDate,[TotalNewDS],[TotalBonusNewDS])
			SELECT 
				F.PK_Distributor,
				F.ApplicationDate,
				SUM([ContributionCount]) AS [TotalNewDS],
				(SUM([ContributionCount]) * 1000) AS [TotalBonusNewDS]
			FROM [dbo].[##WRK_25020_NewDSBonusContributors]  AS F WITH (NOLOCK)
			WHERE Active = 1
			GROUP BY F.PK_Distributor,F.ApplicationDate
				 
		END

		--// Getting totals per Distributor
		INSERT INTO #NewDSSSummary(PK_Distributor,[TotalNewDS],[TotalBonusNewDS])
		SELECT 
			PK_Distributor,
			SUM(TotalNewDS) [TotalNewDS],
			SUM(TotalBonusNewDS) [TotalBonusNewDS]
		FROM #NewDSPerMonth WITH (NOLOCK)
		GROUP BY PK_Distributor



		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 71;


		--// New (PM) Preferred Member Bonus
		------------------------------------------------------------------------------------------------ 	
		--Earn 500 Bonus Points for each Personally Sponsored Downline WW New PM/PC with most recent (application date or conversion date, including converted from preferred members/preferred customers)
		-- Must be 1st line PM Personally Sponsored.
		-- Application date OCT 2024 - DEC 2024 (New or Reinstated (Converted))
		-- Must achieve 100 Total Points from their application month until the end of the following month, limited by the end of the qual period which ends DECEMBER 2024.
		-- Applicable towards the ACCUMULATED VIP Points NOT towards the Personal TDV	
		------------------------------------------------------------------------------------------------ 

		INSERT INTO #TimeLog VALUES ('New PM Bonus', 5, 72, GETUTCDATE(), NULL);

		/******************************************************************************
			New PM Bonus Promotion
		******************************************************************************/

		------------------------------------------------------------------------------------------------
		-- Getting #Event_DownlinesPoints  
		------------------------------------------------------------------------------------------------

		DROP TABLE IF EXISTS #PMDownlinesPeriod

		CREATE TABLE #PMDownlinesPeriod
		(
			PK_Distributor INT,
			PK_DSDownline INT,
			PK_DSType INT,
			ApplicationDate INT,
			StartMonth INT,
			EndMonth INT
		)

		IF @IsDevQA = 0
		BEGIN
			INSERT INTO #PMDownlinesPeriod(PK_Distributor,
				PK_DSDownline,
				PK_DSType,
				ApplicationDate, 
				StartMonth, 
				EndMonth)
			SELECT 
				PK_Distributor,
				PK_DSDownline,
				PK_DSType,
				ApplicationDate, 
				ApplicationDate AS StartMonth, 
				IIF( ApplicationDate+1 > @AppDateEnd,@AppDateEnd, ApplicationDate+1 )  AS EndMonth
			FROM [dbo].[WRK_25020_DSDownlines] AS D WITH (NOLOCK)
			WHERE ApplicationDate BETWEEN @AppDateStart AND @AppDateEnd

		END ELSE IF @IsDevQA = 3
		BEGIN
			INSERT INTO #PMDownlinesPeriod(PK_Distributor,
				PK_DSDownline,
				PK_DSType,
				ApplicationDate, 
				StartMonth, 
				EndMonth)
			SELECT 
				PK_Distributor,
				PK_DSDownline,
				PK_DSType,
				ApplicationDate, 
				ApplicationDate AS StartMonth, 
				IIF( ApplicationDate+1 > @AppDateEnd,@AppDateEnd, ApplicationDate+1 )  AS EndMonth
			FROM [dbo].[##WRK_25020_DSDownlines] AS D
			WHERE ApplicationDate BETWEEN @AppDateStart AND @AppDateEnd

		END

		-- Setting up PM temp tables

		DROP TABLE IF EXISTS #NewPMPerMonth

		CREATE TABLE #NewPMPerMonth
		(
			PK_Distributor INT,
			ApplicationDate INT,
			[TotalNewPM] INT,
			[TotalBonusNewPM] MONEY
		)

		DROP TABLE IF EXISTS #NewPMSummary

		CREATE TABLE #NewPMSummary
		(
			PK_Distributor INT,
			[TotalNewPM] INT,
			[TotalBonusNewPM] MONEY
		)


		IF @IsDevQA = 0 AND NOT EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25020_NewPMBonusContributors' and type='U')
		BEGIN
			CREATE TABLE [dbo].[WRK_25020_NewPMBonusContributors] 
			(
				[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ApplicationDate INT,
				[ContributionCount] INT DEFAULT (1),
				[Active] BIT DEFAULT 1
			)
		END
		ELSE
		IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##WRK_25020_NewPMBonusContributors') IS NULL 
		BEGIN
			CREATE TABLE [dbo].[##WRK_25020_NewPMBonusContributors] 
			(
				[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ApplicationDate INT,
				[ContributionCount] INT DEFAULT (1),
				[Active] BIT DEFAULT 1
			)
		END

		--// Getting contributors
		DROP TABLE IF EXISTS #NewPM
				
		SELECT d.PK_Distributor,d.PK_DSDownline,d.ApplicationDate, 1 AS [Active]
		INTO #NewPM
		FROM #PMDownlinesPeriod AS d
		INNER JOIN #Event_DownlinesPoints AS p
			ON d.PK_DSDownline = p.PK_Distributor  AND p.RoyaltyMonth BETWEEN d.StartMonth AND d.EndMonth
		WHERE d.PK_DSType IN (6,7) AND p.MetricType = 'PM_PPV'
		GROUP BY d.PK_Distributor, d.PK_DSDownline,d.ApplicationDate
		HAVING SUM(Points) >= 100
 
		--Overwriting contributors 
		DROP TABLE IF EXISTS #NewPMOverwrite

		SELECT 
			U.nDistributorID AS PK_Distributor,
			D.nDistributorID AS PK_DSDownLine,
			o.ContributionMonth AS ApplicationDate,
			MAX(CONVERT(int,o.Active)) AS [Active]
		INTO #NewPMOverwrite
		FROM [dbo].[WRK_25020_NAMJKO_NEWPM_Overwrite] AS o WITH (NOLOCK)
			INNER JOIN v_Distributor AS U
				ON o.UL_DistributorID = U.sDistributorID
			INNER JOIN v_Distributor AS D
				ON o.DL_DistributorID = D.sDistributorID
		GROUP BY U.nDistributorID,
			D.nDistributorID,
			o.ContributionMonth 
			 	
		MERGE #NewPM AS t
		USING #NewPMOverwrite  AS s
		ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
		WHEN NOT MATCHED
			THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active)
					VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active);

		--// Freezing contributors
		IF @IsDevQA = 0
		BEGIN
	 
			UPDATE [dbo].[WRK_25020_NewPMBonusContributors]
			SET Active = 1	
			WHERE Active = 0

			MERGE [dbo].[WRK_25020_NewPMBonusContributors] AS t
			USING #NewPM AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate);

			UPDATE t
			SET Active = s.Active
			FROM [dbo].[WRK_25020_NewPMBonusContributors] AS t
				INNER JOIN #NewPMOverwrite AS s
					ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
	 
			-- Add contributor by report  
			;WITH cte_NewPMContributorsReport AS
			(
				SELECT 
					U.nDistributorID AS PK_Distributor,
					D.nDistributorID AS PK_DSDownLine,
					o.ContributionMonth AS ApplicationDate,
					1 AS Active,
					o.ContributionsCount
				FROM [dbo].[WRK_25020_NAMJKO_PMBonusContributors] AS o WITH (NOLOCK)
					INNER JOIN v_Distributor AS U
						ON o.UL_DistributorID = U.sDistributorID
					INNER JOIN v_Distributor AS D
						ON o.DL_DistributorID = D.sDistributorID
			)

			MERGE [dbo].[WRK_25020_NewPMBonusContributors] AS t
			USING cte_NewPMContributorsReport  AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active,ContributionCount)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active,ContributionsCount)
			WHEN MATCHED THEN 
			UPDATE SET 
					t.ContributionCount = t.ContributionCount + s.ContributionsCount; 

			--// Getting contributors per month
			INSERT INTO #NewPMPerMonth(PK_Distributor,ApplicationDate,[TotalNewPM],[TotalBonusNewPM])
			SELECT 
				F.PK_Distributor,
				F.ApplicationDate,
				SUM([ContributionCount]) AS [TotalNewPM],
				(SUM([ContributionCount]) * 500) AS [TotalBonusNewPM]
			FROM [dbo].[WRK_25020_NewPMBonusContributors]   AS F WITH (NOLOCK)
			WHERE Active = 1
			GROUP BY F.PK_Distributor,F.ApplicationDate
				 
		END
		ELSE IF @IsDevQA = 3
		BEGIN 

			MERGE [dbo].[##WRK_25020_NewPMBonusContributors] AS t
			USING #NewPM_Source AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate);

			-- Add contributor by report  
			;WITH cte_NewPMContributorsReport AS
			(
				SELECT 
					U.nDistributorID AS PK_Distributor,
					D.nDistributorID AS PK_DSDownLine,
					o.ContributionMonth AS ApplicationDate,
					1 AS Active,
					o.ContributionsCount
				FROM [dbo].[WRK_25020_NAMJKO_PMBonusContributors] AS o WITH (NOLOCK)
					INNER JOIN v_Distributor AS U
						ON o.UL_DistributorID = U.sDistributorID
					INNER JOIN v_Distributor AS D
						ON o.DL_DistributorID = D.sDistributorID
			)

			MERGE [##WRK_25020_NewPMBonusContributors] AS t
			USING cte_NewPMContributorsReport  AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active,ContributionCount)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active,ContributionsCount)
			WHEN MATCHED THEN 
			UPDATE SET 
					t.ContributionCount = t.ContributionCount + s.ContributionsCount; 
	 
			--// Getting contributors per month
			INSERT INTO #NewPMPerMonth(PK_Distributor,ApplicationDate,[TotalNewPM],[TotalBonusNewPM])
			SELECT 
				F.PK_Distributor,
				F.ApplicationDate,
				SUM([ContributionCount]) AS [TotalNewPM],
				(SUM([ContributionCount]) * 500) AS [TotalBonusNewPM]
			FROM [dbo].[##WRK_25020_NewPMBonusContributors]  AS F WITH (NOLOCK)
			WHERE Active = 1
			GROUP BY F.PK_Distributor,F.ApplicationDate
				 
		END

		--// Getting totals per Distributor
		INSERT INTO #NewPMSummary(PK_Distributor,[TotalNewPM],[TotalBonusNewPM])
		SELECT 
			PK_Distributor,
			SUM(TotalNewPM) [TotalNewPM],
			SUM(TotalBonusNewPM) [TotalBonusNewPM]
		FROM #NewPMPerMonth WITH (NOLOCK)
		GROUP BY PK_Distributor			

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 72;
			
		--// New FQS Bonus
		------------------------------------------------------------------------------------------------
		--Earn 2000 Bonus Points for each Personally Sponsor New WW Supervisor (NonTAB)
		--First Line (DS Level) Supervisor (Qualified or Re-Qualified) with Recognition month  NOV 2024, DEC 2024, JAN 2025.
		--Freeze contributor(s)
		--Applicable towards the ACCUMULATED VIP Points NOT towards the Personal TDV
		--No Limit in how New SPs can contribute to the upline
		------------------------------------------------------------------------------------------------

		INSERT INTO #TimeLog VALUES ('New FQS Bonus', 5, 73, GETUTCDATE(), NULL);


	DECLARE 	
		@FQSAppDateStart DATETIME  = '2024-11-01' 
		,@FQSAppDateEnd DATETIME = '2025-01-31'

		-- Setting up temp tables
		DROP TABLE IF EXISTS #NewFQSPerMonth

		CREATE TABLE #NewFQSPerMonth
		(
			PK_Distributor INT,
			ApplicationDate INT,
			[TotalNewFQS] INT,
			[TotalBonusNewFQS] MONEY
		)

		DROP TABLE IF EXISTS #NewFQSSummary

		CREATE TABLE #NewFQSSummary
		(
			PK_Distributor INT,
			[TotalNewFQS] INT,
			[TotalBonusNewFQS] MONEY
		)

		IF @IsDevQA = 0 AND NOT EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25020_NewFQSBonusContributors' and type='U')
		BEGIN
			CREATE TABLE [dbo].[WRK_25020_NewFQSBonusContributors] 
			(
				[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ApplicationDate INT,
				[ContributionCount] INT DEFAULT (1),
				[Active] BIT DEFAULT 1
			)
		END
		ELSE
		IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##WRK_25020_NewFQSBonusContributors') IS NULL  
		BEGIN
			CREATE TABLE [dbo].[##WRK_25020_NewFQSBonusContributors] 
			(
				[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ApplicationDate INT,
				[ContributionCount] INT DEFAULT (1),
				[Active] BIT DEFAULT 1
			)

			INSERT INTO [dbo].[##WRK_25020_NewFQSBonusContributors]([CreatedDate],PK_Distributor,PK_DSDownLine,ApplicationDate,[Active])
			SELECT [CreatedDate],PK_Distributor,PK_DSDownLine,ApplicationDate,[Active] FROM [dbo].[WRK_25020_NewFQSBonusContributors] WITH (NOLOCK)

			UPDATE [dbo].[##WRK_25020_NewFQSBonusContributors]
			SET Active = 1			 

		END

		
		--// Getting contributors				
		DROP TABLE IF EXISTS #NewFQS

		SELECT
			DL.PK_Distributor,
			DL.PK_DSDownLine,
			IIF(DD.dSupervisorQualification BETWEEN @FQSAppDateStart AND @FQSAppDateEnd, SUBSTRING(CAST(CONVERT(VARCHAR, DD.dSupervisorQualification, 112) AS VARCHAR), 1, 6),
				IIF(DD.dSupervisorReQualification BETWEEN @FQSAppDateStart AND @FQSAppDateEnd, SUBSTRING(CAST(CONVERT(VARCHAR, DD.dSupervisorReQualification, 112) AS VARCHAR), 1, 6),NULL)) AS ApplicationDate,
			1 AS [Active]
		INTO #NewFQS
		FROM #DSDownlinesSummary AS DL
			INNER JOIN v_Distributor AS DD
				ON DL.PK_DSDownLine = DD.nDistributorID
		WHERE
			DD.StatusCode = 'COMPLETE'
			AND
			(DD.dSupervisorQualification BETWEEN @FQSAppDateStart AND @FQSAppDateEnd OR DD.dSupervisorReQualification BETWEEN @FQSAppDateStart AND @FQSAppDateEnd)
			AND
			(DD.sType = 'SP' AND (DD.sTeam IS NULL OR DD.sTeam = 'W')) 


		--Overwriting contributors 
		DROP TABLE IF EXISTS #NewFQSOverwrite
			 
		SELECT 
			U.nDistributorID AS PK_Distributor,
			D.nDistributorID AS PK_DSDownLine,
			o.ContributionMonth AS ApplicationDate,
			MAX(CONVERT(int,o.Active)) AS [Active]
		INTO #NewFQSOverwrite
		FROM [dbo].[WRK_25020_NAMJKO_NEWFQS_Overwrite] AS o WITH (NOLOCK)
			INNER JOIN v_Distributor AS U
				ON o.UL_DistributorID = U.sDistributorID
			INNER JOIN v_Distributor AS D
				ON o.DL_DistributorID = D.sDistributorID		
			GROUP BY U.nDistributorID,
				D.nDistributorID,
				o.ContributionMonth 		 

			MERGE #NewFQS AS t
			USING #NewFQSOverwrite  AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active);

		-- Freezing contributors							
		IF @IsDevQA = 0
		BEGIN

			UPDATE [dbo].[WRK_25020_NewFQSBonusContributors]
			SET Active = 1		
			WHERE Active = 0

			MERGE [dbo].[WRK_25020_NewFQSBonusContributors] AS t
			USING #NewFQS AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate);

			UPDATE t
			SET Active = s.Active
			FROM [dbo].[WRK_25020_NewFQSBonusContributors] AS t
				INNER JOIN #NewFQSOverwrite AS s
					ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate

			--Add contributor by report : Not applicable

	 		--// Getting contributors per month
			INSERT INTO #NewFQSPerMonth(PK_Distributor,ApplicationDate,[TotalNewFQS],[TotalBonusNewFQS])
			SELECT 
				F.PK_Distributor,
				F.ApplicationDate,
				SUM([ContributionCount]) AS [TotalNewFQS],
				(SUM([ContributionCount]) * 2000) AS [TotalBonusNewFQS]
			FROM [dbo].[WRK_25020_NewFQSBonusContributors]  AS F WITH (NOLOCK)
			WHERE Active = 1
			GROUP BY F.PK_Distributor,F.ApplicationDate

				 
		END
		ELSE IF @IsDevQA = 3
		BEGIN
							
			MERGE [dbo].[##WRK_25020_NewFQSBonusContributors] AS t
			USING #NewFQS AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate);

			UPDATE t
			SET Active = s.Active
			FROM [dbo].[##WRK_25020_NewFQSBonusContributors] AS t
				INNER JOIN #NewFQSOverwrite AS s
					ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate

			--Add contributor by report: Not Applicable
	 
	 		--// Getting contributors per month
			INSERT INTO #NewFQSPerMonth(PK_Distributor,ApplicationDate,[TotalNewFQS],[TotalBonusNewFQS])
			SELECT 
				F.PK_Distributor,
				F.ApplicationDate,
				SUM([ContributionCount]) AS [TotalNewFQS],
				(SUM([ContributionCount]) * 2000) AS [TotalBonusNewFQS]
			FROM [dbo].[##WRK_25020_NewFQSBonusContributors]  AS F WITH (NOLOCK)
			WHERE Active = 1
			GROUP BY F.PK_Distributor,F.ApplicationDate
				 
		END

		--// Getting totals per Distributor
		INSERT INTO #NewFQSSummary(PK_Distributor,[TotalNewFQS],[TotalBonusNewFQS])
		SELECT 
			PK_Distributor,
			SUM(TotalNewFQS) [TotalNewFQS],
			SUM(TotalBonusNewFQS) [TotalBonusNewFQS]
		FROM #NewFQSPerMonth WITH (NOLOCK)
		GROUP BY PK_Distributor

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 73;

		--// New 1st Time Ever NAM ASP
		------------------------------------------------------------------------------------------------
		-- Earn 7500 Bonus Points for each Personally Sponsor New First time "Ever" Active Supervisor (COP NAM)
		-- First Line (DS Level) Supervisor directly sponsored.
		-- ASP Recognition Month NOV 2024, DEC 2024, JAN 2025. (Volume Months May 2024 - September 2024)
		-- Freeze contributor(s)
		-- Applicable towards the ACCUMULATED VIP Points NOT towards the  Personal TDV 
		-- Reference Incremental PK Event ID here:36884
		-- EVP supports 30 month history
		-- No Limit in how New SPs can contribute to the upline
		-- See Rules 15.3 and Bonus Example Page
		------------------------------------------------------------------------------------------------
						
		INSERT INTO #TimeLog VALUES ('New 1st Time Ever NAM ASP', 5, 74, GETUTCDATE(), NULL);

		-- Setting up temp tables

		DROP TABLE IF EXISTS #NewASPPerMonth

		CREATE TABLE #NewASPPerMonth
		(
			PK_Distributor INT,
			ApplicationDate INT,
			[TotalNewASP] INT,
			[TotalBonusNewASP] MONEY
		)

		DROP TABLE IF EXISTS #NewASPSummary

		CREATE TABLE #NewASPSummary
		(
			PK_Distributor INT,
			[TotalNewASP] INT,
			[TotalBonusNewASP] MONEY
		)		


		IF @IsDevQA = 0 AND NOT EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25020_NewASPBonusContributors' and type='U')
		BEGIN
			CREATE TABLE [dbo].[WRK_25020_NewASPBonusContributors] 
			(
				[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ApplicationDate INT,
				[ContributionCount] INT DEFAULT (1),
				[Active] BIT DEFAULT 1
			)
		END
		ELSE
		IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##WRK_25020_NewASPBonusContributors') IS NULL  
		BEGIN
			CREATE TABLE [dbo].[##WRK_25020_NewASPBonusContributors] 
			(
				[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ApplicationDate INT,
				[ContributionCount] INT DEFAULT (1),
				[Active] BIT DEFAULT 1
			)

			INSERT INTO [dbo].[##WRK_25020_NewASPBonusContributors]([CreatedDate],PK_Distributor,PK_DSDownLine,ApplicationDate,[Active])
			SELECT [CreatedDate],PK_Distributor,PK_DSDownLine,ApplicationDate,[Active] FROM [dbo].[WRK_25020_NewASPBonusContributors] WITH (NOLOCK)

			UPDATE [dbo].[##WRK_25020_NewASPBonusContributors]
			SET Active = 1
	 
		END	

		--// Getting contributors				
		DROP TABLE IF EXISTS #NewASP 

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
			WHERE PK_Event = @ASPPromoID AND DateQualified  < @RecognitionMonthStart 
		)

		SELECT DISTINCT
			DLS.PK_DSDownLine,
			DLS.PK_Distributor,
			M.DateQualified AS ApplicationDate,
			1 AS [Active]
		INTO #NewASP
		FROM #DSDownlinesSummary AS DLS
		INNER JOIN cte_ASPQualifiers AS M
			ON DLS.PK_DSDownLine = M.PK_Distributor
		LEFT JOIN cte_ASPPrevQualifiers AS p
			ON M.PK_Distributor = p.PK_Distributor
		WHERE p.PK_Distributor IS NULL
	  
		--Overwriting contributors 
		DROP TABLE IF EXISTS #NewASPOverwrite
				
		SELECT 
			U.nDistributorID AS PK_Distributor,
			D.nDistributorID AS PK_DSDownLine,
			o.ContributionMonth AS ApplicationDate,
			MAX(CONVERT(int,o.Active)) AS [Active]
		INTO #NewASPOverwrite
		FROM [dbo].[WRK_25020_NAMJKO_NEWASP_Overwrite] AS o WITH (NOLOCK)
			INNER JOIN v_Distributor AS U
				ON o.UL_DistributorID = U.sDistributorID
			INNER JOIN v_Distributor AS D
				ON o.DL_DistributorID = D.sDistributorID
		GROUP BY U.nDistributorID,
			D.nDistributorID,
			o.ContributionMonth 	

		MERGE #NewASP AS t
		USING #NewASPOverwrite  AS s
		ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
		WHEN NOT MATCHED
			THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active)
					VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active);

		-- Freezing contributors							
		IF @IsDevQA = 0
		BEGIN

			UPDATE [dbo].[WRK_25020_NewASPBonusContributors]
			SET Active = 1		
			WHERE Active = 0

			MERGE [dbo].[WRK_25020_NewASPBonusContributors] AS t
			USING #NewASP AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate);

			UPDATE t
			SET Active = s.Active
			FROM [dbo].[WRK_25020_NewASPBonusContributors] AS t
				INNER JOIN #NewASPOverwrite AS s
					ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate

			--Add contributor by report: Not Applicable
	 
	 		--// Getting contributors per month
			INSERT INTO #NewASPPerMonth(PK_Distributor,ApplicationDate,[TotalNewASP],[TotalBonusNewASP])
			SELECT 
				F.PK_Distributor,
				F.ApplicationDate,
				SUM([ContributionCount]) AS [TotalNewASP],
				(SUM([ContributionCount]) * 7500) AS [TotalBonusNewASP]
			FROM [dbo].[WRK_25020_NewASPBonusContributors]  AS F WITH (NOLOCK)
			WHERE Active = 1
			GROUP BY F.PK_Distributor,F.ApplicationDate
				 
		END
		ELSE IF @IsDevQA = 3
		BEGIN
							

			MERGE [dbo].[##WRK_25020_NewASPBonusContributors] AS t
			USING #NewASP AS s
			ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
			WHEN NOT MATCHED
				THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
						VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate);
	 
	 		UPDATE t
			SET Active = s.Active
			FROM [dbo].[##WRK_25020_NewASPBonusContributors] AS t
				INNER JOIN #NewASPOverwrite AS s
					ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate

			--Add contributor by report: Not Applicable

	 		--// Getting contributors per month
			INSERT INTO #NewASPPerMonth(PK_Distributor,ApplicationDate,[TotalNewASP],[TotalBonusNewASP])
			SELECT 
				F.PK_Distributor,
				F.ApplicationDate,
				SUM([ContributionCount]) AS [TotalNewASP],
				(SUM([ContributionCount]) * 7500) AS [TotalBonusNewASP]
			FROM [dbo].[##WRK_25020_NewASPBonusContributors]  AS F WITH (NOLOCK)
			WHERE Active = 1
			GROUP BY F.PK_Distributor,F.ApplicationDate
				 
		END


		--// Getting totals per Distributor
		INSERT INTO #NewASPSummary(PK_Distributor,[TotalNewASP],[TotalBonusNewASP])
		SELECT 
			PK_Distributor,
			SUM(TotalNewASP) [TotalNewASP],
			SUM(TotalBonusNewASP) [TotalBonusNewASP]
		FROM #NewASPPerMonth WITH (NOLOCK)
		GROUP BY PK_Distributor

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 74;
 
		------------------------------------------------------------------------------------------------
		-- 5.4 Assigning bonuses
		------------------------------------------------------------------------------------------------
			
		INSERT INTO #TimeLog VALUES ('#WRK_25020_BonusSummary', 5, 42, GETUTCDATE(), NULL);

	/******************************************************************************
		Mergin temp members tables DS, FQS, ASP and PM
	******************************************************************************/
							
	IF @IsDevQA = 0 
	BEGIN
		DROP TABLE IF EXISTS [dbo].[WRK_25020_NewMemberPerMonth]

		;WITH cte_DS AS
		(
			SELECT PK_Distributor,ApplicationDate 
			FROM #NewDSPerMonth
			UNION 
			SELECT PK_Distributor,ApplicationDate 
			FROM #NewPMPermonth
			UNION 
			SELECT PK_Distributor,ApplicationDate   
			FROM #NewFQSPermonth
			UNION 
			SELECT PK_Distributor,ApplicationDate
			FROM #NewASPPermonth
		)
			SELECT 
			ds.PK_Distributor,
			ds.ApplicationDate,
			ISNULL(TotalNewDS,0) AS TotalNewDS,
			ISNULL(TotalBonusNewDS,0) AS TotalBonusNewDS,
			ISNULL(TotalNewPM,0) AS TotalNewPM,
			ISNULL(TotalBonusNewPM,0) AS TotalBonusNewPM,
			ISNULL(TotalNewFQS,0) AS TotalNewFQS,
			ISNULL(TotalBonusNewFQS,0) AS TotalBonusNewFQS,
			ISNULL(TotalNewASP,0) AS TotalNewASP,
			ISNULL(TotalBonusNewASP,0) AS TotalBonusNewASP 
		INTO [dbo].[WRK_25020_NewMemberPerMonth] 
			FROM cte_DS AS ds
			LEFT JOIN #NewDSPerMonth AS d
				ON ds.PK_Distributor = d.PK_Distributor AND ds.ApplicationDate = d.ApplicationDate
			LEFT JOIN #NewPMPermonth AS p
				ON ds.PK_Distributor = p.PK_Distributor AND ds.ApplicationDate = p.ApplicationDate
			LEFT JOIN #NewFQSPermonth AS f
				ON ds.PK_Distributor = f.PK_Distributor AND ds.ApplicationDate = f.ApplicationDate
			LEFT JOIN #NewASPPermonth AS a
				ON ds.PK_Distributor = a.PK_Distributor AND ds.ApplicationDate = a.ApplicationDate

	END
	ELSE IF @IsDevQA = 3
	BEGIN

		DROP TABLE IF EXISTS ##WRK_25020_NewMemberPerMonth

		;WITH cte_DS AS
		(
			SELECT PK_Distributor,ApplicationDate 
			FROM #NewDSPerMonth
			UNION  
			SELECT PK_Distributor,ApplicationDate 
			FROM #NewPMPermonth
			UNION  
			SELECT PK_Distributor,ApplicationDate   
			FROM #NewFQSPermonth
			UNION  
			SELECT PK_Distributor,ApplicationDate
			FROM #NewASPPermonth
		)
			 
			SELECT 
			ds.PK_Distributor,
			ds.ApplicationDate,
			ISNULL(TotalNewDS,0) AS TotalNewDS,
			ISNULL(TotalBonusNewDS,0) AS TotalBonusNewDS,
			ISNULL(TotalNewPM,0) AS TotalNewPM,
			ISNULL(TotalBonusNewPM,0) AS TotalBonusNewPM,
			ISNULL(TotalNewFQS,0) AS TotalNewFQS,
			ISNULL(TotalBonusNewFQS,0) AS TotalBonusNewFQS,
			ISNULL(TotalNewASP,0) AS TotalNewASP,
			ISNULL(TotalBonusNewASP,0) AS TotalBonusNewASP 
		INTO ##WRK_25020_NewMemberPerMonth
			FROM #DS as MB 
			INNER JOIN cte_DS AS ds
				ON MB.PK_Distributor = ds.PK_Distributor
			LEFT JOIN #NewDSPerMonth AS d
				ON ds.PK_Distributor = d.PK_Distributor AND ds.ApplicationDate = d.ApplicationDate
			LEFT JOIN #NewPMPermonth AS p
				ON ds.PK_Distributor = p.PK_Distributor AND ds.ApplicationDate = p.ApplicationDate
			LEFT JOIN #NewFQSPermonth AS f
				ON ds.PK_Distributor = f.PK_Distributor AND ds.ApplicationDate = f.ApplicationDate
			LEFT JOIN #NewASPPermonth AS a
				ON ds.PK_Distributor = a.PK_Distributor AND ds.ApplicationDate = a.ApplicationDate

	END


	/******************************************************************************
		Bonus per month
	******************************************************************************/

	IF @IsDevQA = 0 
	BEGIN	

		INSERT INTO [dbo].[#WRK_25020_BonusPerMonth]
		SELECT 
			D.PK_Distributor,
			DS.ApplicationDate,
			SUM(ISNULL(DS.[TotalBonusNewDS],0)) AS [Total DS Bonus],
			SUM(ISNULL(DS.[TotalNewDS],0)) AS [Total New DS],
			SUM(ISNULL(DS.[TotalBonusNewPM],0)) AS [Total PM Bonus],
			SUM(ISNULL(DS.[TotalNewPM],0)) AS [Total New PM],
			SUM(ISNULL(DS.[TotalBonusNewFQS],0)) AS [Total FQS Bonus],
			SUM(ISNULL(DS.[TotalNewFQS],0)) AS [Total New FQS],
			SUM(ISNULL(DS.[TotalBonusNewASP],0)) AS [Total ASP Bonus],
			SUM(ISNULL(DS.[TotalNewASP],0)) AS [Total New ASP]
		FROM #DS AS D
			LEFT JOIN [dbo].[WRK_25020_NewMemberPerMonth] AS DS (NOLOCK)
				ON D.PK_Distributor = DS.PK_Distributor								 		
		GROUP BY  D.PK_Distributor,DS.ApplicationDate

		CREATE INDEX IX_#WRK_25020_BonusPerMonth_PK_Distributor ON #WRK_25020_BonusPerMonth(PK_Distributor)
	END
	ELSE IF @IsDevQA = 3
	BEGIN
		INSERT INTO [dbo].[#WRK_25020_BonusPerMonth]
		SELECT 
			D.PK_Distributor,
			DS.ApplicationDate,
			SUM(ISNULL(DS.[TotalBonusNewDS],0)) AS [Total DS Bonus],
			SUM(ISNULL(DS.[TotalNewDS],0)) AS [Total New DS],
			SUM(ISNULL(DS.[TotalBonusNewPM],0)) AS [Total PM Bonus],
			SUM(ISNULL(DS.[TotalNewPM],0)) AS [Total New PM],
			SUM(ISNULL(DS.[TotalBonusNewFQS],0)) AS [Total FQS Bonus],
			SUM(ISNULL(DS.[TotalNewFQS],0)) AS [Total New FQS],
			SUM(ISNULL(DS.[TotalBonusNewASP],0)) AS [Total ASP Bonus],
			SUM(ISNULL(DS.[TotalNewASP],0)) AS [Total New ASP]
		FROM #DS AS D	
			LEFT JOIN [dbo].[##WRK_25020_NewMemberPerMonth] AS DS  
				ON D.PK_Distributor = DS.PK_Distributor		
								 		
		GROUP BY  D.PK_Distributor,DS.ApplicationDate

		CREATE INDEX IX_#WRK_25020_BonusPerMonth_PK_Distributor ON #WRK_25020_BonusPerMonth(PK_Distributor)
	END

	/******************************************************************************
		Bonus Summary
	******************************************************************************/							

	DROP TABLE IF EXISTS #WRK_25020_BonusSummary

	SELECT 
		PK_Distributor,
		SUM(ISNULL([Total DS Bonus],0)) AS [Total DS Bonus],
		SUM(ISNULL([Total New DS],0)) AS [Total New DS],
		SUM(ISNULL([Total PM Bonus],0)) AS [Total PM Bonus],
		SUM(ISNULL([Total New PM],0)) AS [Total New PM],
		SUM(ISNULL([Total FQS Bonus],0)) AS [Total FQS Bonus],
		SUM(ISNULL([Total New FQS],0)) AS [Total New FQS],
		SUM(ISNULL([Total ASP Bonus],0)) AS [Total ASP Bonus],
		SUM(ISNULL([Total New ASP],0)) AS [Total New ASP]
	INTO #WRK_25020_BonusSummary
	FROM #WRK_25020_BonusPerMonth			 		
	GROUP BY PK_Distributor	

	CREATE INDEX IX_#WRK_25020_BonusSummary_PK_Distributor ON #WRK_25020_BonusSummary(PK_Distributor)
			
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 42;

		IF @IsDevQA = 0
		BEGIN

			INSERT INTO #TimeLog VALUES ('WRK_25020_BonusSummary', 5, 41, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS [dbo].[WRK_25020_BonusSummary]

			SELECT 
				PK_Distributor,
				[Total DS Bonus],
				[Total New DS],
				[Total FQS Bonus],
				[Total New FQS],
				[Total ASP Bonus],
				[Total New ASP],
				[Total PM Bonus],
				[Total New PM]
			INTO [dbo].[WRK_25020_BonusSummary]
			FROM #WRK_25020_BonusSummary 
								
		CREATE INDEX IX_WRK_25020_BonusSummary_PK_Distributor ON [dbo].[WRK_25020_BonusSummary](PK_Distributor)
				
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 41;
				
		END
		ELSE IF @IsDevQA = 3
		BEGIN

			INSERT INTO #TimeLog VALUES ('##WRK_25020_BonusSummary', 5, 41, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS [dbo].[##WRK_25020_BonusSummary]

			SELECT 
				PK_Distributor,
				[Total DS Bonus],
				[Total New DS],
				[Total FQS Bonus],
				[Total New FQS],
				[Total ASP Bonus],
				[Total New ASP],
				[Total PM Bonus],
				[Total New PM]
			INTO [dbo].[##WRK_25020_BonusSummary]
			FROM #WRK_25020_BonusSummary 
								
		CREATE INDEX IX_##WRK_25020_BonusSummary_PK_Distributor ON [dbo].[##WRK_25020_BonusSummary](PK_Distributor)
				
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 3 AND [StepSubGroup] = 71;
				
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
			[Countries] [varchar](max)
		)

 
		INSERT INTO #Event_DSPoints_Summary(PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,QSVolumePercentage,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries)
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
					F.Countries
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
					
		INSERT INTO #TimeLog VALUES ('#WRK_25020_BonusPoints', 5, 44, GETUTCDATE(), NULL);

		DROP TABLE IF EXISTS #WRK_25020_BonusPoints

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
				IIF(U.QualificationNumber BETWEEN @BonusApplicableFrom AND @BonusApplicableTo AND U.MetricType = 'VP' AND U.RoyaltyMonth = @DoubleVolumeMonth, IIF( U.Points >= @DoubleVolumeLimit, @DoubleVolumeLimit,U.Points),0) AS [Double Volume Month],
				IIF(U.QualificationNumber BETWEEN @BonusApplicableFrom AND @BonusApplicableTo AND U.MetricType = 'VP' AND U.RoyaltyMonth = U.iStartDate, ISNULL(BS.[Total DS Bonus],0), 0) AS [New DS Bonus],
				IIF(U.QualificationNumber BETWEEN @BonusApplicableFrom AND @BonusApplicableTo AND U.MetricType = 'VP' AND U.RoyaltyMonth = U.iStartDate, ISNULL(BS.[Total FQS Bonus],0), 0) AS [New FQS Bonus],
				IIF(U.QualificationNumber BETWEEN @BonusApplicableFrom AND @BonusApplicableTo AND U.MetricType = 'VP' AND U.RoyaltyMonth = U.iStartDate, ISNULL(BS.[Total ASP Bonus],0), 0) AS [New ASP Bonus],
				IIF(U.QualificationNumber BETWEEN @BonusApplicableFrom AND @BonusApplicableTo AND U.MetricType = 'VP' AND U.RoyaltyMonth = U.iStartDate, ISNULL(BS.[Total PM Bonus],0), 0) AS [New PM Bonus]
			INTO #WRK_25020_BonusPoints
			FROM #Event_DSPoints_Summary AS U WITH (NOLOCK)
					LEFT JOIN #WRK_25020_BonusSummary AS BS 
						ON U.PK_Distributor = BS.PK_Distributor		
			

		CREATE INDEX IX_#WRK_25020_BonusPoints_PK_Distributor ON #WRK_25020_BonusPoints(PK_Distributor)
			
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 44;

		IF @IsDevQA = 0
		BEGIN
			
			INSERT INTO #TimeLog VALUES ('WRK_25020_BonusPoints', 5, 43, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS [dbo].[WRK_25020_BonusPoints]

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
					[Double Volume Month],
					[New DS Bonus],
					[New FQS Bonus],
					[New ASP Bonus],
					[New PM Bonus]
				INTO [dbo].[WRK_25020_BonusPoints]
				FROM #WRK_25020_BonusPoints	

			CREATE INDEX IX_WRK_25020_BonusPoints_PK_Distributor ON [dbo].[WRK_25020_BonusPoints](PK_Distributor)

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 43;

		END

		INSERT INTO #TimeLog VALUES ('#tmp_DSPointsSummary', 5, 5, GETUTCDATE(), NULL);

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
						(ISNULL(P.[Double Volume Month],0) + ISNULL(P.[New DS Bonus],0)+ ISNULL(P.[New FQS Bonus],0)+ ISNULL(P.[New ASP Bonus],0)+ ISNULL(P.[New PM Bonus],0)) AS [Bonus],
						ISNULL(P.[Points],0) + (ISNULL(P.[Double Volume Month],0) + ISNULL(P.[New DS Bonus],0)+ ISNULL(P.[New FQS Bonus],0)+ ISNULL(P.[New ASP Bonus],0)+ ISNULL(P.[New PM Bonus],0)) AS [TotalPoints],
						P.iStartDate,
						P.iEndDate
					FROM #WRK_25020_BonusPoints AS P WITH (NOLOCK)

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 5 AND [StepSubGroup] =5;									 
						
			IF @IsDevQA = 0
			BEGIN
					
				INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary]', 5, 51, GETUTCDATE(), NULL);
					
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
				WHERE [StepGroup] = 5 AND [StepSubGroup] =51;

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
			ELSE IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetQualifier_Points_jgue') IS NOT NULL
			BEGIN
					 
					--Input 
					--##DSPointsSummary_jgue
					--##Event_DSPoints_jgue
					--##tmp_DSQualDef_jgue
					--##Event_SetupEventQualification_jgue

				 
					EXEC [dbo].[##usp_GetQualifier_Points_jgue] @PK_Event = @PK_Event_Execution, @QualType = @QualType, @OverwritePointsSummary = @OverwritePointsSummary, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
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

		INSERT INTO #TimeLog VALUES ('#EventQual', 7, 1, GETUTCDATE(), NULL);

		INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q30,Q50)
			SELECT 
				PK_Distributor,
				@PK_Event AS [PK_Event],
				IIF(d.DSSPTeam = 'DS' OR d.DSSPTeam = 'SP' ,1,0)	AS	Q01, -- DS and Above
				d.IsFromCOP											AS  Q30, -- From NAM
				d.IsTicketPurchaser									AS	Q50  -- Have a ticket

			FROM #DS AS d
			WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)

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

			PRINT 'None custom qualifications.'		 

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
				E01 = ((Q01 & (Q30 | Q50)) | Q17),
				E05 = (Q21)


			UPDATE 
				#EventQual
			SET
				E04 = ((Q01 & Q02 & Q03 & Q06 & Q30) | Q20)

			UPDATE 
				#EventQual
			SET
				E03 = (((Q01 & Q02 & Q03 & Q05 & Q30) & ~E04) | Q19)

			UPDATE 
				#EventQual
			SET
				E02 = (((Q01 & Q02 & Q03 & Q04 & Q30) & ~E04 & ~E03) | Q18)

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


			DROP TABLE IF EXISTS #WRK_25020_DSPoints_Grouped

			SELECT PK_Distributor, PK_Country, RoyaltyMonth, MetricType, SUM(Points) Points
			INTO #WRK_25020_DSPoints_Grouped
			FROM [dbo].[WRK_25020_DSPoints] (NOLOCK)
			GROUP BY PK_Distributor,PK_Country, RoyaltyMonth, MetricType
		
			DROP TABLE IF EXISTS #WRK_25020_BonusPoints_Grouped

			SELECT DISTINCT PK_Distributor,PK_Country, [Double Volume Month],[New DS Bonus], [New FQS Bonus],[New ASP Bonus],  [New PM Bonus]
			INTO #WRK_25020_BonusPoints_Grouped
			FROM [dbo].[WRK_25020_BonusPoints] (NOLOCK)
			WHERE ([Double Volume Month] + [New DS Bonus] + [New FQS Bonus] + [New ASP Bonus] + [New PM Bonus])  > 0 

			UPDATE
				D
			SET	
				D.TVPOct24				 =	ISNULL((SELECT A.Points FROM [dbo].[WRK_25020_DSPoints] AS  A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV'  AND A.RoyaltyMonth = 202410),0)
				,D.TVPNov24				 =	ISNULL((SELECT A.Points FROM [dbo].[WRK_25020_DSPoints] AS  A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV'  AND A.RoyaltyMonth = 202411),0)
				,D.TVPDec24				 =	ISNULL((SELECT A.Points FROM [dbo].[WRK_25020_DSPoints] AS  A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV'  AND A.RoyaltyMonth = 202412),0)
				,D.PCOct24				 =	ISNULL((SELECT A.Points FROM #Event_DSPoints_Validations AS  A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor AND A.MetricType = 'PC' AND A.RoyaltyMonth = 202410),0)
				,D.PCNov24				 =	ISNULL((SELECT A.Points FROM #Event_DSPoints_Validations AS  A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor AND A.MetricType = 'PC' AND A.RoyaltyMonth = 202411),0)
				,D.PCDec24				 =	ISNULL((SELECT A.Points FROM #Event_DSPoints_Validations AS  A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor AND A.MetricType = 'PC' AND A.RoyaltyMonth = 202412),0)
				,D.PPVOct24				 =	ISNULL((SELECT A.Points FROM [dbo].[WRK_25020_DSPoints] AS  A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor AND A.MetricType = 'PPV' AND A.RoyaltyMonth = 202410),0)
				,D.PPVNov24				 =	ISNULL((SELECT A.Points FROM [dbo].[WRK_25020_DSPoints] AS  A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor AND A.MetricType = 'PPV' AND A.RoyaltyMonth = 202411),0)
				,D.PPVDec24				 =	ISNULL((SELECT A.Points FROM [dbo].[WRK_25020_DSPoints] AS  A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor AND A.MetricType = 'PPV' AND A.RoyaltyMonth = 202412),0)
				,D.[New DS Bonus]		 =	ISNULL((SELECT A.[Total DS Bonus] FROM [WRK_25020_BonusSummary] A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor),0)
				,D.[New FQS Bonus]		 =	ISNULL((SELECT A.[Total FQS Bonus] FROM [WRK_25020_BonusSummary] A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor),0)
				,D.[New ASP Bonus]		 =	ISNULL((SELECT A.[Total ASP Bonus] FROM [WRK_25020_BonusSummary] A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor),0)
				,D.[New PM Bonus]		 =	ISNULL((SELECT A.[Total PM Bonus] FROM [WRK_25020_BonusSummary] A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor),0)
				,D.[Double Volume Month] =	ISNULL((SELECT IIF(A.Points > 2500, 2500, A.Points) FROM [dbo].[WRK_25020_DSPoints] AS  A WITH (NOLOCK) WHERE D.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202410),0)
			FROM
				#DS D	

			DROP TABLE IF EXISTS dbo.WRK_25020_NAM_JKO_Jan_2025

			SELECT 
				D.PK_Distributor								
				,D.dSPQualDate					
				,D.IsFromList	
				,D.IsFromCOP	
				,D.TVPOct24	 
				,D.TVPNov24	 
				,D.TVPDec24	 
				,D.PCOct24	 
				,D.PCNov24	 
				,D.PCDec24	 
				,D.PPVOct24	 
				,D.PPVNov24	 
				,D.PPVDec24	 
				,D.[New DS Bonus]  
				,D.[New FQS Bonus] 
				,D.[New ASP Bonus] 
				,D.[New PM Bonus]  
				,D.[Double Volume Month] 
			INTO dbo.WRK_25020_NAM_JKO_Jan_2025
			FROM #DS D

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 8 AND [StepSubGroup] = 1;

		END

		--Step 9: [Event].[DSQual]	
		IF @Step >= 9
		BEGIN

			INSERT INTO #TimeLog VALUES ('SubEventQualifier', 9, 1, GETUTCDATE(), NULL);

			PRINT 'Executing step 9'

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
					 L.PK_Event	PK_Event
					,PK_Distributor	
					,CreatedDate	
					,UpdatedDate	
					,Q01,Q02,Q03,Q04,Q05,Q06,
					CASE WHEN L.PK_Event = 201553 OR L.PK_Event = 201402 THEN Q07 ELSE 0 END AS Q07, --ANAHEIM
					CASE WHEN L.PK_Event = 201554 OR L.PK_Event = 201402 THEN Q08 ELSE 0 END AS Q08, --Chicago
					CASE WHEN L.PK_Event = 201555 OR L.PK_Event = 201402 THEN Q09 ELSE 0 END AS Q09, --Montreal
					CASE WHEN L.PK_Event = 201556 OR L.PK_Event = 201402 THEN Q10 ELSE 0 END AS Q10, --Dallas
					CASE WHEN L.PK_Event = 201557 OR L.PK_Event = 201402 THEN Q11 ELSE 0 END AS Q11, --Puerto Rico
					CASE WHEN L.PK_Event = 201558 OR L.PK_Event = 201402 THEN Q12 ELSE 0 END AS Q12, --Atlantic City
					CASE WHEN L.PK_Event = 201559 OR L.PK_Event = 201402 THEN Q13 ELSE 0 END AS Q13, --Miami
					CASE WHEN L.PK_Event = 201560 OR L.PK_Event = 201402 THEN Q14 ELSE 0 END AS Q14, --Atlanta
					CASE WHEN L.PK_Event = 201561 OR L.PK_Event = 201402 THEN Q15 ELSE 0 END AS Q15, --North California
					CASE WHEN L.PK_Event = 201562 OR L.PK_Event = 201402 THEN Q16 ELSE 0 END AS Q16, --Boston
					Q17,Q18,Q19,Q20
					,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30
					,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40
					,Q41,Q42,Q43,Q44,Q45,Q46,Q47,Q48,Q49,Q50					
					,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10
					,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20
					,E21,E22,E23,E24,E25,E26,E27,E28,E29,E30
					,E31,E32,E33,E34,E35,E36,E37,E38,E39,E40
					,E41,E42,E43,E44,E45,E46,E47,E48,E49,E50
				FROM #EventQual
				CROSS APPLY (SELECT PK_Event FROM #Locations) AS L

				CREATE INDEX [IX_Event_DSQual_PK_Event] ON [Event].[DSQual](PK_Event);
				CREATE INDEX [IX_Event_DSQual_PK_Distributor_PK_Event] ON [Event].[DSQual](PK_Distributor) INCLUDE(PK_Event);

			END
			ELSE IF @IsDevQA = 3
			BEGIN

				DROP TABLE IF EXISTS ##Event_DSQual_jgue 
				 
				SELECT
					L.PK_Event	PK_Event
					,PK_Distributor	
					,CreatedDate	
					,UpdatedDate	
					,Q01,Q02,Q03,Q04,Q05,Q06,
					CASE WHEN L.PK_Event = 201553 THEN Q07 ELSE 0 END AS Q07, --ANAHEIM
					CASE WHEN L.PK_Event = 201554 THEN Q08 ELSE 0 END AS Q08, --Chicago
					CASE WHEN L.PK_Event = 201555 THEN Q09 ELSE 0 END AS Q09, --Montreal
					CASE WHEN L.PK_Event = 201556 THEN Q10 ELSE 0 END AS Q10, --Dallas
					CASE WHEN L.PK_Event = 201557 THEN Q11 ELSE 0 END AS Q11, --Puerto Rico
					CASE WHEN L.PK_Event = 201558 THEN Q12 ELSE 0 END AS Q12, --Atlantic City
					CASE WHEN L.PK_Event = 201559 THEN Q13 ELSE 0 END AS Q13, --Miami
					CASE WHEN L.PK_Event = 201560 THEN Q14 ELSE 0 END AS Q14, --Atlanta
					CASE WHEN L.PK_Event = 201561 THEN Q15 ELSE 0 END AS Q15, --North California
					CASE WHEN L.PK_Event = 201562 THEN Q16 ELSE 0 END AS Q16, --Boston
					Q17,Q18,Q19,Q20
					,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30
					,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40
					,Q41,Q42,Q43,Q44,Q45,Q46,Q47,Q48,Q49,Q50					
					,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10
					,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20
					,E21,E22,E23,E24,E25,E26,E27,E28,E29,E30
					,E31,E32,E33,E34,E35,E36,E37,E38,E39,E40
					,E41,E42,E43,E44,E45,E46,E47,E48,E49,E50
				INTO ##Event_DSQual_jgue
				FROM #EventQual
				CROSS APPLY (SELECT PK_Event FROM #Locations) AS L

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 9 AND [StepSubGroup] = 1;
		END

		--Step 10: SubEventQualifiers
		IF @Step >= 10 
		BEGIN

			INSERT INTO #TimeLog VALUES ('SubEventQualifier', 10, 1, GETUTCDATE(), NULL);

			IF @IsDevQA = 0
			BEGIN

				PRINT 'Executing step 10'
		
				DECLARE @Events VARCHAR(MAX)
				
				SELECT @Events = STRING_AGG(PK_Event,',') FROM #Locations

				EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
				@Events = @Events,
				@Source = 2,
				@EvaluateFormula = 0

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 10 AND [StepSubGroup] = 1;
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