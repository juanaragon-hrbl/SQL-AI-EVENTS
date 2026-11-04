CREATE PROCEDURE [dbo].[usp_EventQual_EMEAVacation2024]
	
	@PK_Event INT = 195906	
	--Error Parameters 
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
	,@Step SMALLINT = 15
	,@Potentials_Commitment_Date DATE = '2025-01-01'
	,@CurrentDate DATE = NULL
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_EMEAVacation2024

	USE:		

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC dbo.usp_EventQual_EMEAVacation2024 
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
		##DSQualPoints_amed
		##tmp_DS_amed
		##Event_SetupEventQualification_amed
		##tmp_DSQualDef_amed
		##Event_DSPoints_amed
		##DSPointsSummary_amed

		##usp_GetDSVolume_amed
	
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

	[dbo].[WRK_24009_DownlinesQualifiers]
	[dbo].[WRK_24009_DSDownlinesBonusSummary]
	[dbo].[WRK_24009_BonusPoints]
	[dbo].[WRK_24009_DownlinesVolume]
	[dbo].[WRK_24009_Downlines_Contribution_L1]
	[dbo].[WRK_24009_Downlines_Contribution_L2]
	[dbo].[WRK_24009_Downlines_Contribution_L3]
	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2023-05-09	alejandramed		Initial 
	1.0.1	2023-06-05	alejandramed		Bug 1266797: 24009 - EMEA Vacation 2024 - Lists are not working, mismatch on QId assignment
	1.0.2	2023-07-14	alejandramed		User Story 1269873: 24009 - EMEA Vacation 2024 - BRD V2
											Bug 1276119: 24009 - EMEA Vacations 2023 Bonus 3000
	1.0.3	2023-08-17	alejandramed		Bug 1285962: 24009 - EMEA Vacations 2023 - BRD V2 - Tab Not Blocking
											Bug 1286276: 24009 - EMEA Vacations 2023 - BRD V2 - Potential Star Count
											Bug 1286458: 24009 - EMEA Vacations 2023 - BRD V2 - Leg 6 Bonus Report
	1.0.4	2023-10-31	puertac				BUG 1307569
	1.0.4	2023-11-17	alejandramed		Bug 1310591: 24009 - EMEA Vacations 2023 - Volume 50% Latvia, Lithuania y Estonia
	1.0.5	2023-12-19	alejandramed		User Story 1314248: 24009 - EMEA Vacation 2024 - BRD V4.1
	1.0.6	2024-01-29	alejandramed		Bug 1322689: 24009 - Bonus not applied to Q19 and Q20
											Bug 1322690: 24009 - QS not counting on Accumulated TVP
	1.0.7	2024-02-06	alejandramed		Bug 1324396: 24009 - EMEA Vacations 2023 BRD v4.1 - max per leg bonus
	1.0.8	2024-03-04	alejandramed		User Story 1329097: 24009 - EMEA Vacation 2024 - BRD V5
	***********************************************************************************************************************************/
	
	IF (@IsDevQA = 3)
	BEGIN
		
		DROP TABLE IF EXISTS ##DSQualPoints_amed

		CREATE TABLE ##DSQualPoints_amed(
			[PK_Distributor] [int] NULL,
			[PK_Event] [int] NULL,
			[QualificationNumber] [int] NULL,
			[Part] [int] NULL,
			[QualDate] [datetime2](7) NULL
		)
		
		DROP TABLE IF EXISTS ##tmp_DS_amed

		CREATE TABLE ##tmp_DS_amed
		(
			[PK_Event] INT NULL,
			[PK_Distributor]  INT NULL, 
			[StartDate]  INT NULL,
			[EndDate]  INT NULL
		)
		
		DROP TABLE IF EXISTS ##Event_SetupEventQualification_amed

		CREATE TABLE ##Event_SetupEventQualification_amed(
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
		
		DROP TABLE IF EXISTS ##tmp_DSQualDef_amed

		CREATE TABLE ##tmp_DSQualDef_amed
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

		DROP TABLE IF EXISTS ##Event_DSPoints_amed

		CREATE TABLE ##Event_DSPoints_amed(
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

		DROP TABLE IF EXISTS ##DSPointsSummary_amed

		CREATE TABLE ##DSPointsSummary_amed
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

	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_amed') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetDSVolume_amed] is missing, create it manually' AS [ErrorMessage]
	END

	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetQualifier_Points_amed') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetQualifier_Points_amed] is missing, create it manually' AS [ErrorMessage]
	END

	SET NOCOUNT ON;

	IF @IsDevQA = 3 AND ( OBJECT_ID('tempdb.dbo.##DSQualPoints_amed') IS NULL OR 
		OBJECT_ID('tempdb.dbo.##tmp_DS_amed') IS NULL OR
		OBJECT_ID('tempdb.dbo.##Event_SetupEventQualification_amed') IS NULL OR
		OBJECT_ID('tempdb.dbo.##Event_DSPoints_amed') IS NULL OR
		OBJECT_ID('tempdb.dbo.##DSPointsSummary_amed') IS NULL)
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

		DECLARE @ProjectID INT = 24009,
				@SPQualFromDateDLBonus INT = 202302, -- 6.1 Vacation Bonus
				@SPQualToDateDLBonus INT = 202401, 
				@iStartDate int,
				@dStartDate datetime,
				@iEndDate int,
				@dEndDate datetime,
				@QualType SMALLINT,  --1 = Accumulated/Non-Consecutive, 2 = Accumulated/Consecutive, 3 = Achieve/Consecutive, 4 = Achieve/Non-Consecutive
				@PK_Execution INT,
				@PK_Event_Execution INT,
				@OverwritePointsSummary BIT,
				@StartQualPeriodA DATETIME = '2023-01-01',
				@EndQualPeriodA DATETIME = '2023-12-01',
				@BonusApplicableToQs VARCHAR(25) = '8,9,19,20' --Bonus Applicable to Q8, Q9, Q19 and Q20

		DECLARE @ColumnToPivot NVARCHAR(MAX),
			@SqlStatement NVARCHAR(MAX)

		DECLARE @QualificationSKUFactor INT = 70

		DECLARE 
			@Countries VARCHAR(MAX) = 'AU,BE,BA,BC,BG,HR,CY,CZ,DA,FI,FR,MK,GE,GH,HE,HU,IC,EI,IS,IT,LB,LT,MT,YO,WA,NL,NO,PL,PO,MD,RO,SR,SK,SI,SF,SP,WZ,SW,SZ,TU,UA,UK,ZM,LG,LH,EE'
		 
		DROP TABLE IF EXISTS #ListsQsMapping

		CREATE TABLE #ListsQsMapping
		(
			ID INT IDENTITY(1,1),
			ListID INT,
			QId INT
		)

		INSERT INTO #ListsQsMapping(ListID,QId)
			VALUES 
				(54604,11),
				(54605,12),
				(54606,13),
				(54607,14),
				(54608,15),
				(54609,16),
				(59395,22),
				(59396,23),
				(59397,24),
				(59398,25),
				(59399,26)

		IF @CurrentDate IS NULL SET @CurrentDate = GETUTCDATE();

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
			[MetricTypeDefinition]		VARCHAR(50) NULL,
			[ForDownlinesOnly]		bit default(0)
		)
		
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

		DROP TABLE IF EXISTS #tmp_DS

		CREATE TABLE #tmp_DS(
			[PK_Event] [int] NOT NULL,
			[PK_Distributor] [int] NULL,
			[DistributorID] VARCHAR(30),
			[iStartDate] [int] NULL,
			[iEndDate] [int] NULL,
			[dStartDate] [datetime] NULL,
			[dEndDate] [datetime] NULL,
			[dSPQualDate] [datetime] NULL
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
			[BonusCount] [bit] 
		)

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

		--Q8 Accumulate 65,000 Vacation Points (TVP + Bonus) during Qual Period A with a minimum of 32,500 EMEA (8.1) Total Volume Points have to be earned within the participating countries in section 8.1
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			8					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			65000				AS [GoalPoints], 
			'-W'				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			1					AS Bonus

		--Q8 Accumulate 65,000 Vacation Points (TVP + Bonus) during Qual Period A with a 
		-- * minimum of 32,500 EMEA (8.1) Total Volume Points have to be earned within the participating countries in section 8.1
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			8					AS QualificationNumber,
			2					AS Part, 
			'TV'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			32500				AS [GoalPoints], 
			'AU,BE,BA,BC,BG,HR,CY,CZ,DA,FI,FR,MK,GE,GH,HE,HU,IC,EI,IS,IT,LB,LT,MT,YO,WA,NL,NO,PL,PO,MD,RO,SR,SK,SI,SF,SP,WZ,SW,SZ,TU,UA,UK,ZM,LG,LH,EE'				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q9 Accumulate 70,000 Vacation Points (TVP + Bonus) during Qual Period A with a minimum of 35,000 EMEA (8.1) Total Volume Points have to be earned within the participating countries in section 8.1
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			9					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			70000				AS [GoalPoints], 
			'-W'				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			1					AS Bonus

		--Q9 Accumulate 70,000 Vacation Points (TVP + Bonus) during Qual Period A
		-- * with a minimum of 35,000 EMEA (8.1) Total Volume Points have to be earned within the participating countries in section 8.1
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			9					AS QualificationNumber,
			2					AS Part, 
			'TV'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			35000				AS [GoalPoints], 
			'AU,BE,BA,BC,BG,HR,CY,CZ,DA,FI,FR,MK,GE,GH,HE,HU,IC,EI,IS,IT,LB,LT,MT,YO,WA,NL,NO,PL,PO,MD,RO,SR,SK,SI,SF,SP,WZ,SW,SZ,TU,UA,UK,ZM,LG,LH,EE'				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q10 Accumulate 120,000 RO Only No Bonus during Qual Period A with a minimum of 60,000 EMEA (8.1) Royalty Points have to be earned within the participating countries in section 8.1
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			10					AS QualificationNumber,
			1					AS Part, 
			'RO'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			120000				AS [GoalPoints], 
			'-W'				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q10 Accumulate 120,000 RO Only No Bonus during Qual Period A 
		-- * with a minimum of 60,000 EMEA (8.1) Royalty Points have to be earned within the participating countries in section 8.1
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			10					AS QualificationNumber,
			2					AS Part, 
			'RO'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			60000				AS [GoalPoints], 
			'AU,BE,BA,BC,BG,HR,CY,CZ,DA,FI,FR,MK,GE,GH,HE,HU,IC,EI,IS,IT,LB,LT,MT,YO,WA,NL,NO,PL,PO,MD,RO,SR,SK,SI,SF,SP,WZ,SW,SZ,TU,UA,UK,ZM,LG,LH,EE'				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q16 Accumulate 2,500 TVP (Including 50% QS Volume) over three (3) consecutive months during Qual Period Jan 2023 to Dec 2023 volume months.
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[ForDownlinesOnly])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			16					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			3					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			2500				AS [GoalPoints], 
			'-W'				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			1					AS [ForDownlinesOnly]
	
		--Q19 Accumulate 65,000 Vacation Points (TVP + Bonus) during Qual Period A
		--with a minimum of 32,500 EMEA (8.1) Total Volume Points have to be earned within countries in 8.1 
		--EXCEPT for volume from Latvia, Lithuania, Estonia cannot be used towards the minimum
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			19					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			65000				AS [GoalPoints], 
			'-W'				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			1					AS Bonus

		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])		
		SELECT 
			@PK_Event	AS [PK_Event],
			19					AS QualificationNumber,
			2					AS Part, 
			'TV'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			32500				AS [GoalPoints], 
			'AU,BE,BA,BC,BG,HR,CY,CZ,DA,FI,FR,MK,GE,GH,HE,HU,IC,EI,IS,IT,LB,LT,MT,YO,WA,NL,NO,PL,PO,MD,RO,SR,SK,SI,SF,SP,WZ,SW,SZ,TU,UA,UK,ZM'				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition] 

		--Q20 Accumulate 70,000 Vacation Points (TVP + Bonus) during Qual Period A
		--with a minimum of 32,500 EMEA (8.1) Total Volume Points have to be earned within countries in 8.1 
		--EXCEPT for volume from Latvia, Lithuania, Estonia cannot be used towards the minimum
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			20					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			70000				AS [GoalPoints], 
			'-W'				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			1					AS Bonus

		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			20					AS QualificationNumber,
			2					AS Part, 
			'TV'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			35000				AS [GoalPoints], 
			'AU,BE,BA,BC,BG,HR,CY,CZ,DA,FI,FR,MK,GE,GH,HE,HU,IC,EI,IS,IT,LB,LT,MT,YO,WA,NL,NO,PL,PO,MD,RO,SR,SK,SI,SF,SP,WZ,SW,SZ,TU,UA,UK,ZM'				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]


		--Accumulate 120,000 RO Only No Bonus during Qual Period A
		--with a minimum of 60,000 EMEA (8.1) Royalty Points have to be earned within the participating countries in section 8.1 
		--EXCEPT for volume from Latvia, Lithuania, Estonia cannot be used towards the minimum
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			21					AS QualificationNumber,
			1					AS Part, 
			'RO'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			120000				AS [GoalPoints], 
			'-W'				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		UNION
		SELECT 
			@PK_Event	AS [PK_Event],
			21					AS QualificationNumber,
			2					AS Part, 
			'RO'				AS [MetricType], 
			@StartQualPeriodA	AS [dStartDate], 
			@EndQualPeriodA		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			60000				AS [GoalPoints], 
			'AU,BE,BA,BC,BG,HR,CY,CZ,DA,FI,FR,MK,GE,GH,HE,HU,IC,EI,IS,IT,LB,LT,MT,YO,WA,NL,NO,PL,PO,MD,RO,SR,SK,SI,SF,SP,WZ,SW,SZ,TU,UA,UK,ZM'				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

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
		SELECT @PK_Event,'EMEA' 
		 
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
					DSCurrentTeam		varchar(10),        
					DSSubTeam			varchar(10),        
					DSSPTeam			varchar(10),               
					dSPQualDate			datetime2,        
					CountryCode			varchar(5),
					IsFromList			bit default(0),
					IsTicketPurchaser	bit default(0),
					[GET_QualDate]		datetime default('1900-01-01'),
					IsNewGet			bit default(0),
					[TAB_QualDate]		datetime default('1900-01-01') 
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
					CountryCode,		
					IsFromList
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate,        
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
					CountryCode,
					IsTicketPurchaser
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate,        
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


			INSERT INTO #TimeLog VALUES ('DS team (History information)', 2, 3, GETUTCDATE(), NULL);

			--NEW GET (GET Team Qual Date A)
			--Team Qual Date A (Date must reach specified Team Level): From Nov 01 2022 to Jan 01 2024

			;WITH cte_get_FirstQual AS -- First GET Team qual date 
			( 
				SELECT 
					D.PK_Distributor, MIN(DH.dFrom) AS [GET_QualDate]
				FROM #DS AS D    
				INNER JOIN	dbo.v_DistributorHistory AS DH (NOLOCK)   
					ON D.PK_Distributor = DH.nDistributorIDFK 
					AND DH.nEventTypeLID = 225                
					AND DH.dThrough = '2049-12-31' 
				GROUP BY D.PK_Distributor
			)

			UPDATE D
				SET [GET_QualDate] = g.[GET_QualDate], -- First GET Team qual date   
					IsNewGet = IIF(g.[GET_QualDate] BETWEEN '2022-11-01' AND '2024-01-01' ,1,0)  -- Get team qual date during the period
			FROM #DS AS D    
				LEFT JOIN cte_get_FirstQual AS g 
					ON g.PK_Distributor = D.PK_Distributor 
				
			--TAB (GT,GP,MT,MP,PT and above on or before TAB Freeze Date A)
			--TAB Freeze Date A (Freeze current team level as of this date for the rest of the promotion qual period): As of Oct 01 2022

			DROP TABLE IF EXISTS #tab_LifeCycleCode 
		 
			SELECT LifeCycleCode 
			INTO #tab_LifeCycleCode
			FROM [dbo].[v_dimDSLifeCycle] WITH(NOLOCK) --TAB Team LifeCycleCode			
			WHERE SortOrder IS NOT NULL 
				AND SortOrder >= 6 
				AND LifeCycleCode NOT IN (242,243,244,245) --Excluding DS and PM levels

			; WITH cte_upline_tab_qualDate AS 
			(
				SELECT D.PK_Distributor,MAX(DH.dFrom) AS [TAB_QualDate] 
				FROM #DS AS D    
				INNER JOIN	dbo.v_DistributorHistory AS DH (NOLOCK)   
					ON D.PK_Distributor = DH.nDistributorIDFK
					AND DH.dFrom <= '2022-10-01'             
					AND DH.dThrough = '2049-12-31'   
				INNER JOIN #tab_LifeCycleCode AS t --TAB Team
					ON DH.nEventTypeLID = t.LifeCycleCode
				GROUP BY D.PK_Distributor
			)

			UPDATE D 
				SET [TAB_QualDate] = DH.[TAB_QualDate]
			FROM #DS AS D    
			INNER JOIN cte_upline_tab_qualDate AS DH (NOLOCK)   
				ON D.PK_Distributor = DH.PK_Distributor
						 
			-- ) Getting basic qualification in advance in order to obtain the uplines
			--------------------------------------------------------------------------------

			INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q04,Q05,Q06,Q07,Q49,Q50,Q17,Q18)
				SELECT 
					PK_Distributor,
					@PK_Event AS [PK_Event],
					IIF(d.DSSPTeam = 'SP',1,0) AS Q01, -- FQS and Above
					IIF(d.DSCurrentTeam IN ('SP', 'W'), 1,0), --FQS (Non-TAB)
					d.IsNewGet AS Q04, --NEW GET (GET Team Qual Date A)
					IIF(TAB_QualDate != '1900-01-01',1,0) AS Q05, --TAB (GT,GP,MT,MP,PT and above on or before TAB Freeze Date A)
					CASE WHEN D.DSCurrentTeam IN ('A', 'B', 'C', 'P') AND d.DSSubTeam NOT IN ('FC','CC') THEN 1 ELSE 0 END Q06, --PT and above and NOT FC OR CC
					IIF(d.DSSubTeam IN ('FC','CC'),1,0) AS Q07, -- FC and CC
					IIF(d.IsTicketPurchaser = 1,1,0) AS Q49,
					IIF(d.IsFromList = 1,1,0) AS Q50,
					IIF(d.CountryCode IN ('AU','BE','BA','BC','BG','HR','CY','CZ','DA','FI','FR','MK','GE','GH','HE','HU','IC','EI','IS','IT','LB','LT','MT','YO','WA','NL','NO','PL','PO','MD','RO','SR','SK','SI','SF','SP','WZ','SW','SZ','TU','UA','UK','ZM'), 1,0) AS Q17,
					IIF(d.CountryCode IN ('LG','LH','EE'), 1,0) AS Q18	
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
				
			------------------------------------------------------------------------------------------------
			-- Other qualifications
			------------------------------------------------------------------------------------------------
			BEGIN

			--Q03	AWT 2023

			DROP TABLE IF EXISTS #Q03

			 SELECT T.PK_Distributor 
			 INTO #Q03
			 FROM #DS AS t  
 			 INNER JOIN dbo.[AWT] AS a WITH (NOLOCK)
 	 			ON t.PK_Distributor = a.PK_Distributor   
 			 WHERE a.AWTYear = 2023 

			 CREATE INDEX IX_#Q03_PK_Distributor ON #Q03(PK_Distributor);

			 UPDATE E
			 SET 
				 Q03 = 1
			 FROM #EventQual AS E
				INNER JOIN #Q03 AS Q03
				ON E.PK_Distributor = Q03.PK_Distributor			 

			END
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 3;

			INSERT INTO #TimeLog VALUES ('Getting elegible uplines', 2, 4, GETUTCDATE(), NULL);

			-- ) Getting uplines, only those DS who are eligible to qualify using volume/bonuses
			--------------------------------------------------------------------------------
			BEGIN

				DROP TABLE IF EXISTS #Uplines CREATE TABLE #Uplines (PK_Distributor INT,Q02 BIT DEFAULT(0),Q03 BIT DEFAULT(0),Q04 BIT DEFAULT(0),Q05 BIT DEFAULT(0))

				INSERT INTO #Uplines(PK_Distributor,Q02,Q03,Q04,Q05)
				SELECT 
					D.PK_Distributor,  
					D.Q02,
					D.Q03,
					D.Q04,
					D.Q05
				FROM #EventQual AS D
				WHERE 
				(D.Q02 = 1) OR -- FQS (Non-TAB)			-- 1.0.4 AWT qualification not required to review lineage
				(D.Q04 = 1) OR -- NEW GET (GET Team Qual Date From Nov 01 2022 to Jan 01 2024)
				(D.Q05 = 1) OR -- TAB (GT,GP,MT,MP,PT and above on or before TAB Freeze Date As of Oct 01 2022)
				(D.Q49 = 1 OR D.Q50 = 1)

				CREATE INDEX IX_#Uplines_PK_Distributor ON #Uplines(PK_Distributor);

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 4;

			INSERT INTO #TimeLog VALUES ('Getting downline', 2, 5, GETUTCDATE(), NULL);

			-- ) Getting downline
			--------------------------------------------------------------------------------
			BEGIN
						
				BEGIN --Lines

				INSERT INTO #TimeLog VALUES ('Lines', 3, 1, GETUTCDATE(), NULL);

				INSERT INTO #TimeLog VALUES ('FirstLine', 4, 1, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #FirstLine;

					SELECT 
						DL.PK_Distributor,
						DL.PK_DSDownline [PK_FirstLine]
					INTO #FirstLine
					FROM
						#Uplines M
					INNER JOIN
						dbo.v_dimDSLngDownline DL WITH (NOLOCK)
					ON
						M.PK_Distributor = DL.PK_Distributor
						AND 
						DL.DSLevelFromUL = 2
					INNER JOIN v_Distributor AS D
						ON DL.PK_DSDownline = D.nDistributorID 
							--AND D.dSupervisorQualification BETWEEN '2021-10-01' AND '2023-01-01' 

					CREATE CLUSTERED INDEX [IX_FirstLine_PK_FirstLine] ON #FirstLine ([PK_FirstLine])

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 4 AND [StepSubGroup] = 1;

				INSERT INTO #TimeLog VALUES ('SecondLine', 4, 2, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #SecondLine;

					SELECT 
						L1.PK_Distributor	
						,L1.PK_FirstLine	
						,DL.PK_DSDownline [PK_SecondLine]
					INTO #SecondLine
					FROM
						#FirstLine L1
					INNER JOIN
						dbo.v_dimDSLngDownline DL WITH (NOLOCK)
					ON
						L1.[PK_FirstLine] = DL.PK_Distributor
						AND 
						DL.DSLevelFromUL = 2
					INNER JOIN v_Distributor AS D
						ON DL.PK_DSDownline = D.nDistributorID 
						--AND D.dSupervisorQualification BETWEEN '2021-10-01' AND '2023-01-01' 
				  
					CREATE CLUSTERED INDEX [IX_SecondLine_PK_SecondLine] ON #SecondLine ([PK_SecondLine])
					CREATE NONCLUSTERED INDEX [IX_SecondLine_PK_FirstLine] ON #SecondLine ([PK_FirstLine])

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 4 AND [StepSubGroup] = 2;

				INSERT INTO #TimeLog VALUES ('ThirdLine', 4, 3, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #ThirdLine;

					SELECT 
						 L2.PK_Distributor
						,L2.PK_FirstLine	
						,L2.PK_SecondLine	
						,DL.PK_DSDownline [PK_ThirdLine]
					INTO #ThirdLine
					FROM
						#SecondLine L2
					INNER JOIN
						dbo.v_dimDSLngDownline DL WITH (NOLOCK)
					ON
						L2.PK_SecondLine = DL.PK_Distributor
						AND 
						DL.DSLevelFromUL = 2
					INNER JOIN v_Distributor AS D
						ON DL.PK_DSDownline = D.nDistributorID 
						--AND D.dSupervisorQualification BETWEEN '2021-10-01' AND '2023-01-01' 

					CREATE CLUSTERED INDEX [IX_ThirdLine_PK_ThirdLine] ON #ThirdLine ([PK_ThirdLine])

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 4 AND [StepSubGroup] = 3;		

				/* INSERT ALL DOWNLINES TO LINEAGE TABLE */

				INSERT INTO #TimeLog VALUES ('Lineage', 5, 1, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #Lineage;
								
					SELECT 
						L1.PK_Distributor
						,L1.PK_FirstLine [PK_FirstDownLine]
						,L2.PK_SecondLine [PK_SecondDownLine]
						,L3.PK_ThirdLine [PK_ThirdDownLine]
					INTO #Lineage
					FROM #FirstLine L1
						LEFT JOIN #SecondLine L2
							ON  L1.PK_FirstLine = L2.PK_FirstLine
						LEFT JOIN #ThirdLine L3
							ON L2.PK_Distributor = L3.PK_Distributor 
								AND L2.PK_SecondLine = L3.PK_SecondLine					
	
					CREATE INDEX IX_#Lineage_PK_Distributor		ON #Lineage(PK_Distributor)
					CREATE INDEX IX_#Lineage_PK_FirstDownLine	ON #Lineage(PK_FirstDownLine)
					CREATE INDEX IX_#Lineage_PK_SecondDownLine	ON #Lineage(PK_SecondDownLine)
					CREATE INDEX IX_#Lineage_PK_ThirdDownLine	ON #Lineage(PK_ThirdDownLine)

			
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 5 AND [StepSubGroup] = 1;

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 1;

				/* GETTING LINEAGE UNIQUE IDs */

				INSERT INTO #TimeLog VALUES ('Lineage', 5, 2, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #LineageIDsUnique;

					SELECT L.PK_Distributor
					INTO #LineageIDsUnique
					FROM
					(
							SELECT PK_FirstDownline [PK_Distributor]
								FROM #Lineage WITH (NOLOCK)
							UNION
							SELECT PK_SecondDownLine [PK_Distributor]
								FROM #Lineage WITH (NOLOCK)
							UNION
							SELECT PK_ThirdDownLine [PK_Distributor]
								FROM #Lineage WITH (NOLOCK)
					) L

					CREATE INDEX IX_LineageIDsUnique_PK_Distributor ON #LineageIDsUnique(PK_Distributor)   
				
				END

				DROP TABLE IF EXISTS #LineageFlags

				CREATE TABLE #LineageFlags(PK_Distributor int, PK_Event int, SPQualDate datetime, iSPQualDate int, IsNewSP BIT DEFAULT(0), Q16 BIT DEFAULT(0), E01 BIT DEFAULT(0), IsTABBeforeFreeze BIT DEFAULT(0), IsTABAfterFreeze BIT DEFAULT(0), IsAWTNonTAB BIT DEFAULT(0))
	
				INSERT INTO #LineageFlags(PK_Distributor,PK_Event,SPQualDate,iSPQualDate)
				SELECT 
					DD.nDistributorID, 
					@PK_Event,
					DD.dSupervisorqualification,
					CAST(CONVERT(varchar(6), DD.dSupervisorqualification , 112) AS int) AS [iSPQualDate]
				FROM #LineageIDsUnique AS L
					INNER JOIN v_Distributor AS DD
						ON L.PK_Distributor = DD.nDistributorID 
				
				DROP TABLE IF EXISTS #DSDownlines_VacationBonus

				SELECT  --New (Never Demoted) SP (SP Qual Dates: Feb 01 2023 to Jan 01 2024)
						D.PK_Distributor AS PK_Distributor,
						DD.sDistributorID AS DistributorID,
						DD.dSupervisorQualification 
				INTO #DSDownlines_VacationBonus
				FROM #LineageFlags AS D
				INNER JOIN v_Distributor AS DD
					ON D.PK_Distributor = DD.nDistributorID
				WHERE D.iSPQualDate BETWEEN @SPQualFromDateDLBonus AND @SPQualToDateDLBonus
				AND DD.dSPDemotion IS NULL --Never demoted

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 2;

			END
					
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 5;

		END

		--Step 3: Getting Volume for New SP (Never Demoted) (SP Qual Dates: Feb 01 2023 to Jan 01 2024)
		
		IF @Step >= 3
		BEGIN

			PRINT 'Executing step 3'

			IF @IsDevQA = 0
			BEGIN	

				DELETE s FROM [Event].[SetupEventQualification] AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
				INSERT INTO [Event].[SetupEventQualification](PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
				SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition 
				FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event AND [ForDownlinesOnly] = 1

			END
			ELSE
			IF @IsDevQA = 3
			BEGIN	

				DELETE s FROM ##Event_SetupEventQualification_amed AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
				INSERT INTO ##Event_SetupEventQualification_amed(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
				SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition
				FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event AND [ForDownlinesOnly] = 1

			END

			------------------------------------------------------------------------------------------------
			-- 3.1 Getting values from #Event_SetupEventQualification
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification', 3, 1, GETUTCDATE(), NULL);
				
				SELECT 
					@iStartDate = CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int), 
					@dStartDate = MIN(dStartDate),
					@iEndDate = CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int),
					@dEndDate = MAX(dEndDate)
					FROM #Event_SetupEventQualification WITH (NOLOCK) 
					WHERE [ForDownlinesOnly] = 1

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 1;

				-- Result set 
				IF @IsDevQA > 0 SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate] 

			------------------------------------------------------------------------------------------------
			-- 3.2 Getting #tmp_DS
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('#tmp_DS', 3, 2, GETUTCDATE(), NULL);

				INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate])
				SELECT  
					@PK_Event AS [PK_Event],
					D.PK_Distributor AS PK_Distributor,
					D.DistributorID,
					@iStartDate AS [iStartDate],
					@iEndDate AS [iEndDate],
					@dStartDate AS [dStartDate],
					@dEndDate AS [dEndDate],
					D.dSupervisorQualification 				 
				FROM #DSDownlines_VacationBonus AS D
					 
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
						
					DROP INDEX IF EXISTS [IX_##tmp_DS_amed_PK_Distributor]
						ON ##tmp_DS_amed;

					DELETE d FROM ##tmp_DS_amed AS d WHERE d.PK_Event = @PK_Event  

					INSERT INTO ##tmp_DS_amed([PK_Event],[PK_Distributor],[StartDate],[EndDate])
					SELECT 
						D.[PK_Event],
						D.PK_Distributor,
						D.[iStartDate],
						D.[iEndDate]
					FROM #tmp_DS AS D 
											 
					CREATE INDEX IX_##tmp_DS_amed_PK_Distributor ON ##tmp_DS_amed(PK_Distributor) INCLUDE(PK_Event);

				END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;

			------------------------------------------------------------------------------------------------
			-- 3.3 Getting [Event].[DSPoints]
			------------------------------------------------------------------------------------------------
			
			IF (@IsDevQA = 0)
			BEGIN
				INSERT INTO #TimeLog VALUES ('usp_GetDSVolume', 3, 3, GETUTCDATE(), NULL);

				--SourceType 1: Getting points from PubEvents.[dbo].[factDSFinancial_ctry], includes divorce and tranfer cases.
				EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 1,@QualFilter = '16',@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
				--Output [Event].[DSPoints]

				IF @Error <> 0
				BEGIN
					SET @Error = @Error
					SET @ErrorMessage = @ErrorMessage
					RETURN;
				END

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 3;
		
			END
			ELSE
			IF (@IsDevQA = 3) AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_amed') IS NOT NULL
			BEGIN
					 
				--Input
				--##tmp_DS_amed
				--##Event_SetupEventQualification_amed

				EXEC [dbo].[##usp_GetDSVolume_amed] @PK_Event = @PK_Event, @SourceType = 1,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
				IF @Error <> 0
				BEGIN
					SET @Error = @Error
					SET @ErrorMessage = @ErrorMessage

					SELECT @ErrorMessage
					RETURN;
				END

				--Output
				--##Event_DSPoints_amed
 
		
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 3;
		
			END
			
			------------------------------------------------------------------------------------------------
			-- 3.4 Getting #Event_DSPoints AND #Event_DSPoints_Validations
			------------------------------------------------------------------------------------------------
		
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints', 3, 4, GETUTCDATE(), NULL);


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
					FROM ##Event_DSPoints_amed

				END

				CREATE CLUSTERED INDEX [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints ([PK_Distributor]) 
				CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints ([MetricType])
			
				IF @IsDevQA = 0
				BEGIN 

					DROP TABLE IF EXISTS [dbo].[WRK_24009_DownlinesVolume]
					SELECT 
							[PK_Distributor],
							[PK_Event],
							[PK_Country],
							[RoyaltyMonth],
							[MetricType],
							[PersonalPoints],
							[TransferPoints],
							[MainPoints],  
							[Points],
							[Bonus]
					INTO [dbo].[WRK_24009_DownlinesVolume]
					FROM #Event_DSPoints

				END ELSE
				IF @IsDevQA = 3
				BEGIN 

					DROP TABLE IF EXISTS #WRK_24009_DownlinesVolume
					SELECT 
							[PK_Distributor],
							[PK_Event],
							[PK_Country],
							[RoyaltyMonth],
							[MetricType],
							[PersonalPoints],
							[TransferPoints],
							[MainPoints],  
							[Points],
							[Bonus]
					INTO #WRK_24009_DownlinesVolume
					FROM #Event_DSPoints

				END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 4;
			
		END

		--Step 4: Qualification definition for New SP (Never Demoted) (SP Qual Dates: Feb 01 2023 to Jan 01 2024) 

		IF @Step >= 4
		BEGIN

			PRINT 'Executing step 4'

			------------------------------------------------------------------------------------------------
			-- 4.1 Getting all qualification definition for each DS
			------------------------------------------------------------------------------------------------

			INSERT INTO #TimeLog VALUES ('#tmp_DSQualDef', 4, 1, GETUTCDATE(), NULL);
			
				INSERT INTO #tmp_DSQualDef([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,QSVolume,Bonus)
					SELECT 
						C.PK_Event,
						D.PK_Distributor AS PK_Distributor,
						A.StartDate AS dStartDate,
						A.EndDate AS dEndDate,
						CAST(CONVERT(varchar(6), A.StartDate, 112) AS int) AS iStartDate,
						CAST(CONVERT(varchar(6), A.EndDate, 112) AS int) AS iEndDate,
						D.dSupervisorQualification AS [dSPQualDate],
						CAST(CONVERT(varchar(6), D.dSupervisorQualification, 112) AS int) AS [iSPQualDate],
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
						[QSVolume],
						ISNULL(C.Bonus,0) AS [Bonus]
					FROM #DSDownlines_VacationBonus AS D					
						LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
							ON D.PK_Distributor = M.PK_Distributor
						OUTER APPLY (SELECT * FROM #Event_SetupEventQualification AS S WITH (NOLOCK) WHERE S.ForDownlinesOnly = 1) AS C
						CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
						
				CREATE INDEX IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef(PK_Distributor);

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 4 AND [StepSubGroup] = 1;

			IF @IsDevQA = 0
			BEGIN

				INSERT INTO #TimeLog VALUES ('[tmp].[DSQualDef]', 4, 2, GETUTCDATE(), NULL);
					
					DELETE [tmp].[DSQualDef] WHERE PK_Event = @PK_Event

					DROP INDEX IF EXISTS IX_tmp_DSQualDef_PK_Event ON [tmp].[DSQualDef];

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
				
			INSERT INTO #TimeLog VALUES ('##tmp_DSQualDef_amed', 4, 2, GETUTCDATE(), NULL);

				INSERT INTO ##tmp_DSQualDef_amed([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[Bonus],[QSVolume])
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
				
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 4 AND [StepSubGroup] = 2;

			END
		END
			
		--Step 5:  DSPointsSummary for New SP (Never Demoted) (SP Qual Dates: Feb 01 2023 to Jan 01 2024) 
		
		IF @Step >= 5
		BEGIN
			
			PRINT 'Executing step 5'
	 
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints_Summary', 5, 1, GETUTCDATE(), NULL);

				INSERT INTO #Event_DSPoints_Summary(PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,QSVolumePercentage,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries)
					SELECT U.PK_Distributor,
							U.RoyaltyMonth,
							U.MetricType,
							U.PK_Country AS PK_Country,
							SUM(IIF(F.[QSVolume] = 0,IIF(U.RoyaltyMonth < F.iSPQualDate,0, ISNULL(U.Points,0)),ISNULL(U.Points,0))) AS [Points],	
							F.[QSVolume],
							F.[QSVolumePercentage],
							F.iSPQualDate,
							F.QualificationNumber,
							F.Part,
							F.iStartDate,
							F.iEndDate,
							F.Countries
					FROM #Event_DSPoints AS U WITH (NOLOCK) 
								INNER JOIN #tmp_DSQualDef AS F
									ON u.PK_Distributor = F.PK_Distributor	
									WHERE 
									F.MetricType = U.MetricType 
									AND 
									U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
									AND 
					(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
					GROUP BY U.PK_Distributor,U.RoyaltyMonth,U.MetricType,U.PK_Country,F.[QSVolume],F.[QSVolumePercentage],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries
					
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 1;
			
			INSERT INTO #TimeLog VALUES ('#tmp_DSPointsSummary', 5, 2, GETUTCDATE(), NULL);

				INSERT INTO #tmp_DSPointsSummary([PK_Event],PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],[Bonus],[QSVolume],[QSVolumePercentage],[iSPQualDate],QualificationNumber,Part,[HasBonus],[TotalPoints],iStartDate,iEndDate,[Countries])
				SELECT 
							@PK_Event AS PK_Event,
							P.PK_Distributor,
							P.RoyaltyMonth,
							P.MetricType,
							P.PK_Country,
							P.[Points],
							0 AS [Bonus],
							P.QSVolume,
							P.QSVolumePercentage,
							P.iSPQualDate,
							P.QualificationNumber,
							P.Part,
							0 AS [HasBonus],
							ISNULL(P.[Points],0) AS [TotalPoints],
							P.iStartDate,
							P.iEndDate,
							P.Countries
						FROM #Event_DSPoints_Summary AS P 

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 5 AND [StepSubGroup] = 2;

				IF @IsDevQA = 0
				BEGIN
					
					INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary]', 5, 3, GETUTCDATE(), NULL);
					
					DELETE t
					FROM [tmp].[DSPointsSummary] AS t
					WHERE t.PK_Event = @PK_Event

					DROP INDEX IF EXISTS IX_tmp_DSPointsSummary_PK_Distributor ON [tmp].[DSPointsSummary];

					INSERT INTO [tmp].[DSPointsSummary](PK_Event, PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,iSPQualDate,QSVolume,[Countries])
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
							iEndDate,
							iSPQualDate,
							QSVolume,
							Countries
						FROM #tmp_DSPointsSummary

					CREATE INDEX IX_tmp_DSPointsSummary_PK_Distributor ON [tmp].[DSPointsSummary](PK_Distributor)INCLUDE (PK_Event);	

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 5 AND [StepSubGroup] = 3;

				END
				ELSE IF @IsDevQA = 3
				BEGIN

					INSERT INTO #TimeLog VALUES ('##DSPointsSummary_amed', 5, 3, GETUTCDATE(), NULL);

					INSERT INTO ##DSPointsSummary_amed(PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate)
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
					WHERE [StepGroup] = 5 AND [StepSubGroup] = 3;

				END
				 			
		END
		
		--Step 6: Qualifiers by volume for New SP (Never Demoted) (SP Qual Dates: Feb 01 2023 to Jan 01 2024) 
	
		IF @Step >= 6
		BEGIN
			
			PRINT 'Executing step 6'

			------------------------------------------------------------------------------------------------
			-- 6.1 Getting qualifiers by volume according to qualification definitions
			------------------------------------------------------------------------------------------------
	
			INSERT INTO #TimeLog VALUES ('Qualifiers by volume', 6, 1, GETUTCDATE(), NULL);

			INSERT INTO #Executions(PK_Event,OverwritePointsSummary,QualType)
			SELECT DISTINCT
					PK_Event, 
					0 AS OverwritePointsSummary,
					 IIF(Accumulated = 0 AND Consecutive = 0, 4, --Achieve Non-Consecutive
						IIF( Accumulated = 0 AND Consecutive = 1, 3, --Achieve Consecutive
							IIF(Accumulated = 1 AND Consecutive = 1, 2, --Accumulated Consecutive
								IIF(Accumulated = 1 AND Consecutive = 0, 1,NULL)))) --Accumulated Non-Consecutive
						AS QualType 
				FROM #Event_SetupEventQualification WHERE [ForDownlinesOnly] = 1
 
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
					 
					INSERT INTO #TimeLog VALUES ('Exec usp_GetQualifier_Points', 6, 11, GETUTCDATE(), NULL);

						 --Input [tmp].[DSPointsSummary]
						EXEC dbo.usp_GetQualifier_Points @PK_Event = @PK_Event_Execution, @QualType = @QualType, @OverwritePointsSummary = @OverwritePointsSummary, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
						--Output [Event].[DSQualPoints]

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 6 AND [StepSubGroup] = 11;

				END
				ELSE IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetQualifier_Points_amed') IS NOT NULL
				BEGIN
					 
					 --Input 
					 --##DSPointsSummary_amed
					 --##Event_DSPoints_amed
					 --##tmp_DSQualDef_amed
					 --##Event_SetupEventQualification_amed
					 				 
						EXEC ##usp_GetQualifier_Points_amed @PK_Event = @PK_Event_Execution, @QualType = @QualType, @OverwritePointsSummary = @OverwritePointsSummary, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
						IF @Error <> 0
						BEGIN
							SET @Error = @Error
							SET @ErrorMessage = @ErrorMessage
							RETURN;
						END				 

					--Output 
					--##DSQualPoints_amed
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
					FROM ##DSQualPoints_amed AS Q
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

				IF @IsDevQA = 0
				BEGIN

					DROP TABLE IF EXISTS dbo.WRK_24009_DownlinesQualifiers

					SELECT DISTINCT Q.PK_Distributor, Q.QualDate, Q.QualificationNumber 
					INTO dbo.WRK_24009_DownlinesQualifiers
					FROM [Event].[DSQualPoints] AS Q WITH (NOLOCK)
						INNER JOIN #DSDownlines_VacationBonus AS D
							ON Q.PK_Distributor = D.PK_Distributor
					WHERE Q.PK_Event = @PK_Event
					ORDER BY Q.PK_Distributor

				END
				ELSE
				BEGIN
						DROP TABLE IF EXISTS #WRK_24009_DownlinesQualifiers

						SELECT DISTINCT Q.PK_Distributor, Q.QualDate,Q.QualificationNumber  
						INTO #WRK_24009_DownlinesQualifiers
						FROM #Event_DSQualPoints AS Q
							INNER JOIN #DSDownlines_VacationBonus AS D
								ON Q.PK_Distributor = D.PK_Distributor
						WHERE Q.PK_Event = @PK_Event
						ORDER BY Q.PK_Distributor
				END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 6 AND [StepSubGroup] = 1;
		END
 
		--Step 7: Downline contribution
		BEGIN

			--Downlines flags
			-----------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('Downlines flags', 7, 0, GETUTCDATE(), NULL);
			
			-- TAB (TAB Status Freeze as of Oct 1st 2022) 

			DROP TABLE IF EXISTS #downline_tab_qualDate_BeforeFreeze 
			
				SELECT D.PK_Distributor,MAX(DH.dFrom) AS [TAB_QualDate] 
				INTO #downline_tab_qualDate_BeforeFreeze
				FROM #LineageIDsUnique AS D    
				INNER JOIN	dbo.v_DistributorHistory AS DH (NOLOCK)   
					ON D.PK_Distributor = DH.nDistributorIDFK
					AND DH.dFrom < '2022-10-01'             
					AND DH.dThrough = '2049-12-31'   
				INNER JOIN #tab_LifeCycleCode AS t --TAB Team
					ON DH.nEventTypeLID = t.LifeCycleCode
				GROUP BY D.PK_Distributor

			UPDATE D 
				SET [IsTABBeforeFreeze] = IIF(DH.[TAB_QualDate] IS NULL,0, IIF(DH.[TAB_QualDate] < '2022-10-01', 1,0)) 
			FROM #LineageFlags AS D    
			LEFT JOIN #downline_tab_qualDate_BeforeFreeze AS DH (NOLOCK)   
				ON D.PK_Distributor = DH.PK_Distributor

				DROP TABLE IF EXISTS #downline_tab_qualDate_Afterfreeze 
			
				SELECT D.PK_Distributor,MAX(DH.dFrom) AS [TAB_QualDate] 
				INTO #downline_tab_qualDate_Afterfreeze
				FROM #LineageIDsUnique AS D    
				INNER JOIN	dbo.v_DistributorHistory AS DH (NOLOCK)   
					ON D.PK_Distributor = DH.nDistributorIDFK
					AND DH.dFrom >= '2022-10-01'             
					AND DH.dThrough = '2049-12-31'   
				INNER JOIN #tab_LifeCycleCode AS t --TAB Team
					ON DH.nEventTypeLID = t.LifeCycleCode
				GROUP BY D.PK_Distributor

			UPDATE D 
				SET [IsTABAfterFreeze] = IIF(DH.[TAB_QualDate] IS NULL,0, IIF(DH.[TAB_QualDate] >= '2022-10-01', 1,0)) 
			FROM #LineageFlags AS D    
			LEFT JOIN #downline_tab_qualDate_Afterfreeze AS DH (NOLOCK)   
				ON D.PK_Distributor = DH.PK_Distributor

			-- Non-TAB AWT 2023
			
				; WITH cte_DS_AWTNonTAB AS
				(
					SELECT a.PK_Distributor FROM #LineageIDsUnique AS l
					INNER JOIN dbo.AWT AS a WITH (NOLOCK) 
						ON l.PK_Distributor = a.PK_Distributor 
					WHERE a.AWTYear = 2023 AND a.IsNonTAB = 1
				)					

				UPDATE fd
				SET IsAWTNonTAB = 1
				FROM #LineageFlags AS fd
				INNER JOIN cte_DS_AWTNonTAB AS d
					ON fd.PK_Distributor = d.PK_Distributor

			--New (Never Demoted) SP (SP Qual Dates: Feb 01 2023 to Jan 01 2024)
			
				UPDATE fd
				SET IsNewSP = 1
				FROM #LineageFlags AS fd
				INNER JOIN #DSDownlines_VacationBonus AS d
					ON fd.PK_Distributor = d.PK_Distributor
			
			--Accumulates 2,500 TVP (Including 50% QS Volume) over three (3) consecutive months during Qual Period Jan 2023 to Dec 2023 volume months.
			
				UPDATE fd
				SET Q16 = 1
				FROM #LineageFlags AS fd
				INNER JOIN #DSDownlines_VacationBonus AS d
					ON fd.PK_Distributor = d.PK_Distributor
				INNER JOIN [Event].[DSQualPoints] AS qp WITH (NOLOCK) 
					ON d.PK_Distributor = qp.PK_Distributor
				WHERE qp.PK_Event = @PK_Event AND qp.QualificationNumber = 16
				
			--Qualifiers for the Vacation 2024
		
				UPDATE fd 
					SET  [E01] = 1 
				 FROM #LineageFlags AS fd 
					INNER JOIN dbo.SubEventQualifier AS DH WITH (NOLOCK)
						ON fd.PK_Distributor = DH.PK_Distributor
					INNER JOIN dbo.SubEvent AS SE WITH (NOLOCK)
						ON SE.PK_Event = DH.PK_Event AND SE.PK_SubEvent = DH.PK_SubEvent     
				  WHERE DH.Qualified = 1
					AND DH.RemovedUTC = '2049-12-31'     
					AND SE.PK_Event = @PK_Event     
					AND SE.SubEventNumber = 1  

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 0;

			/* GETTING FIRST LINE CONTRIBUTION */  
	
			INSERT INTO #TimeLog VALUES ('Contribution_L1', 7, 1, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #Contribution_L1

				SELECT 
					l.PK_Distributor,
					l.PK_FirstDownLine,
					MAX(IIF(L1.Q16 = 1 AND L1.IsNewSP = 1, 1, 0)) AS IsVacationBonusContributor,
					MAX(IIF(L1.IsAWTNonTAB = 1, 1,0)) AS IsStar
				INTO #Contribution_L1
				FROM #Lineage l WITH (NOLOCK) 
					INNER JOIN #Uplines u
						ON l.PK_Distributor = u.PK_Distributor
					INNER JOIN #LineageFlags AS L1
						ON l.PK_FirstDownLine = L1.PK_Distributor
				WHERE 
				(L1.Q16 = 1 AND L1.IsNewSP = 1  OR (L1.IsAWTNonTAB = 1)) --  Brand New (Never Demoted) SP (SP Qual Dates: Feb 01 2023 to Jan 01 2024) that Accumulates 2,500 TVP (Including 50% QS Volume) over three (3) consecutive months during Qual Period A in 3 DS Levels 
																	-- OR AWT 2023 
				AND NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS da WITH (NOLOCK) WHERE da.nMainDistributorID = l.PK_FirstDownline) -- Main ID must not qualify
				GROUP BY l.PK_Distributor,l.PK_FirstDownLine
					
			IF @IsDevQA = 0
			BEGIN
				DROP TABLE IF EXISTS [dbo].[WRK_24009_Downlines_Contribution_L1]

				SELECT 	
					l.PK_Distributor,
					l.PK_FirstDownLine,
					l.IsVacationBonusContributor,
					l.IsStar
				INTO [dbo].[WRK_24009_Downlines_Contribution_L1]
				FROM #Contribution_L1 AS l

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 1;

			/* GETTING SECOND LINE CONTRIBUTION */  
	
			INSERT INTO #TimeLog VALUES ('Contribution_L2', 7, 2, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #Contribution_L2;
				
				SELECT 
					lc.PK_Distributor,
					lc.PK_FirstDownLine, 
					lc.PK_SecondDownLine,
					MAX(lc.IsVacationBonusContributor) AS IsVacationBonusContributor,
					MAX(lc.IsStar) AS IsStar
				INTO #Contribution_L2
				FROM 
				(
				SELECT 
					l.PK_Distributor,
					l.PK_FirstDownLine, 
					l.PK_SecondDownLine,
					IIF(L2.Q16 = 1 AND L2.IsNewSP = 1, 1, 0) AS IsVacationBonusContributor,
					0 AS IsStar
				FROM #Lineage l WITH (NOLOCK) 
					INNER JOIN #Uplines u
						ON l.PK_Distributor = u.PK_Distributor 
					INNER JOIN #LineageFlags AS L1
						ON l.PK_FirstDownLine = L1.PK_Distributor
					INNER JOIN #LineageFlags AS L2
						ON l.PK_SecondDownLine = L2.PK_Distributor
				WHERE 
				(L2.Q16 = 1 AND L2.IsNewSP = 1)  --  Brand New (Never Demoted) SP (SP Qual Dates: Feb 01 2023 to Jan 01 2024) that Accumulates 2,500 TVP (Including 50% QS Volume) over three (3) consecutive months during Qual Period A in 3 DS Levels 					 
				AND L1.[IsTABBeforeFreeze] = 0 -- NonTAB on Freeze block the 2nd and 3rd line
				AND L1.[E01] = 0 --E01 Qualifiers block the 2nd and 3rd line
				--  > Blocking rules apply: - AWT 2023 E1 Qualifiers and TAB (TAB Status Freeze as of Oct 1st 2022) TAB Nov 1st 2022 or after will NOT block unless they qualify for Vacation E01
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_FirstDownLine = l1.PK_FirstDownLine AND l1.IsVacationBonusContributor = 1) --> Max 1 per leg (Leg is defined by 1st DS Level Downline in their organization.  Max number of contributors should not exceed number of 1st DS Level distributors)
				AND
				NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS da WITH (NOLOCK) WHERE da.nMainDistributorID = l.PK_FirstDownline) -- Main ID must not qualify
				UNION
				SELECT 
					l.PK_Distributor,
					l.PK_FirstDownLine, 
					l.PK_SecondDownLine,
					NULL AS IsVacationBonusContributor,
					IIF(L2.IsAWTNonTAB = 1, 1,0) AS IsStar
				FROM #Lineage l WITH (NOLOCK) 
					INNER JOIN #Uplines u
						ON l.PK_Distributor = u.PK_Distributor 
					INNER JOIN #LineageFlags AS L1
						ON l.PK_FirstDownLine = L1.PK_Distributor
					INNER JOIN #LineageFlags AS L2
						ON l.PK_SecondDownLine = L2.PK_Distributor
				WHERE 
				L2.IsAWTNonTAB = 1    -- AWT 2023 
				AND L1.[IsTABBeforeFreeze] = 0 -- NonTAB on Freeze block the 2nd and 3rd line
				AND L1.[E01] = 0 --E01 Qualifiers block the 2nd and 3rd line
				--  > Blocking rules apply: - AWT 2023 E1 Qualifiers and TAB (TAB Status Freeze as of Oct 1st 2022) TAB Nov 1st 2022 or after will NOT block unless they qualify for Vacation E01
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_FirstDownLine = l1.PK_FirstDownLine AND l1.IsStar = 1) --> Max 1 per leg (Leg is defined by 1st DS Level Downline in their organization.  Max number of contributors should not exceed number of 1st DS Level distributors)
				AND
				NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS da WITH (NOLOCK) WHERE da.nMainDistributorID = l.PK_FirstDownline) -- Main ID must not qualify
				) AS lc
				GROUP BY lc.PK_Distributor,lc.PK_FirstDownLine, lc.PK_SecondDownLine

			IF @IsDevQA = 0
			BEGIN
				DROP TABLE IF EXISTS [dbo].[WRK_24009_Downlines_Contribution_L2]

				SELECT 	
					l.PK_Distributor,
					l.PK_FirstDownLine, 
					l.PK_SecondDownLine,
					l.IsVacationBonusContributor,
					l.IsStar
				INTO [dbo].[WRK_24009_Downlines_Contribution_L2]
				FROM #Contribution_L2 AS l

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 2;

			/* GETTING THIRD LINE CONTRIBUTION */  
	
			INSERT INTO #TimeLog VALUES ('Contribution_L3', 7, 3, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #Contribution_L3;

				SELECT 
				lc.PK_Distributor,
				lc.PK_FirstDownLine, 
				lc.PK_SecondDownLine,
				lc.PK_ThirdDownLine,
				MAX(lc.IsVacationBonusContributor) AS IsVacationBonusContributor,
				MAX(lc.IsStar) AS IsStar
				INTO #Contribution_L3
				FROM 
				(
				SELECT 
					l.PK_Distributor,
					l.PK_FirstDownLine, 
					l.PK_SecondDownLine, 
					l.PK_ThirdDownLine,
					IIF(L3.Q16 = 1 AND L3.IsNewSP = 1, 1, 0) AS IsVacationBonusContributor,
					NULL AS IsStar
				FROM #Lineage l WITH (NOLOCK) 
					INNER JOIN #Uplines u
						ON l.PK_Distributor = u.PK_Distributor 
					INNER JOIN #LineageFlags AS L1
						ON l.PK_FirstDownLine = L1.PK_Distributor
					INNER JOIN #LineageFlags AS L2
						ON l.PK_SecondDownLine = L2.PK_Distributor
					INNER JOIN #LineageFlags AS L3
						ON l.PK_ThirdDownLine = L3.PK_Distributor
				WHERE 
				(L3.Q16 = 1 AND L3.IsNewSP = 1) --  Brand New (Never Demoted) SP (SP Qual Dates: Feb 01 2023 to Jan 01 2024) that Accumulates 2,500 TVP (Including 50% QS Volume) over three (3) consecutive months during Qual Period A in 3 DS Levels 
				AND L1.[IsTABBeforeFreeze] = 0 	AND L2.[IsTABBeforeFreeze] = 0 -- NonTAB on Freeze block the 2nd and 3rd line
				AND L1.[E01] = 0 AND L2.[E01] = 0  --E01 Qualifiers block the 2nd and 3rd line
				--  > Blocking rules apply: - AWT 2023 E1 Qualifiers and TAB (TAB Status Freeze as of Oct 1st 2022) TAB Nov 1st 2022 or after will NOT block unless they qualify for Vacation E01
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_FirstDownLine = l1.PK_FirstDownLine AND l1.IsVacationBonusContributor = 1) --> Max 1 per leg (Leg is defined by 1st DS Level Downline in their organization.  Max number of contributors should not exceed number of 1st DS Level distributors)
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L2 l2 WHERE l.PK_FirstDownLine = l2.PK_FirstDownLine AND l2.IsVacationBonusContributor = 1) --> Max 1 per leg (Leg is defined by 1st DS Level Downline in their organization.  Max number of contributors should not exceed number of 1st DS Level distributors)
				AND 
				NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS da WITH (NOLOCK) WHERE da.nMainDistributorID = l.PK_ThirdDownLine) -- Main ID must not qualify
				UNION
				SELECT 
					l.PK_Distributor,
					l.PK_FirstDownLine, 
					l.PK_SecondDownLine, 
					l.PK_ThirdDownLine,
					NULL AS IsVacationBonusContributor,
					IIF(L3.IsAWTNonTAB = 1, 1,0) AS IsStar
				FROM #Lineage l WITH (NOLOCK) 
					INNER JOIN #Uplines u
						ON l.PK_Distributor = u.PK_Distributor 
					INNER JOIN #LineageFlags AS L1
						ON l.PK_FirstDownLine = L1.PK_Distributor
					INNER JOIN #LineageFlags AS L2
						ON l.PK_SecondDownLine = L2.PK_Distributor
					INNER JOIN #LineageFlags AS L3
						ON l.PK_ThirdDownLine = L3.PK_Distributor
				WHERE 
				L3.IsAWTNonTAB = 1    -- AWT 2023 
				AND L1.[IsTABBeforeFreeze] = 0 	AND L2.[IsTABBeforeFreeze] = 0 -- NonTAB on Freeze block the 2nd and 3rd line
				AND L1.[E01] = 0 AND L2.[E01] = 0  --E01 Qualifiers block the 2nd and 3rd line
				--  > Blocking rules apply: - AWT 2023 E1 Qualifiers and TAB (TAB Status Freeze as of Oct 1st 2022) TAB Nov 1st 2022 or after will NOT block unless they qualify for Vacation E01
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_FirstDownLine = l1.PK_FirstDownLine AND l1.IsStar = 1) --> Max 1 per leg (Leg is defined by 1st DS Level Downline in their organization.  Max number of contributors should not exceed number of 1st DS Level distributors)
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L2 l2 WHERE l.PK_FirstDownLine = l2.PK_FirstDownLine AND l2.IsStar = 1) --> Max 1 per leg (Leg is defined by 1st DS Level Downline in their organization.  Max number of contributors should not exceed number of 1st DS Level distributors)
				AND 
				NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS da WITH (NOLOCK) WHERE da.nMainDistributorID = l.PK_ThirdDownLine) -- Main ID must not qualify
				) AS lc
				GROUP BY lc.PK_Distributor,lc.PK_FirstDownLine, lc.PK_SecondDownLine, lc.PK_ThirdDownLine

			IF @IsDevQA = 0
			BEGIN
				DROP TABLE IF EXISTS [dbo].[WRK_24009_Downlines_Contribution_L3]

				SELECT 	
					l.PK_Distributor,
					l.PK_FirstDownLine, 
					l.PK_SecondDownLine,
					l.PK_ThirdDownLine, 
					l.IsVacationBonusContributor,
					l.IsStar
				INTO [dbo].[WRK_24009_Downlines_Contribution_L3]
				FROM #Contribution_L3 AS l

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 3;
			
 
		/* GETTING UPLINE CONTRIBUTOR */

			DROP TABLE IF EXISTS #UplinesContributors

			CREATE TABLE #UplinesContributors
			(
				 PK_Distributor					INT 
				,FirstLineCount					INT DEFAULT 0  
				,SecondLineCount				INT DEFAULT 0  
				,ThirdLineCount					INT DEFAULT 0  
				,FirstLineCount_Associated		INT DEFAULT 0  
				,SecondLineCount_Associated		INT DEFAULT 0  
				,ThirdLineCount_Associated		INT DEFAULT 0  
				,GuaranteedContributors			AS (FirstLineCount+FirstLineCount_Associated)  
				,Potentials						AS (SecondLineCount+ThirdLineCount+SecondLineCount_Associated+ThirdLineCount_Associated) 
				,PotentialsCommited				INT DEFAULT 0
				,OverallCount					INT DEFAULT 0
				,Bonus							AS (OverallCount * 3000)
				,FirstLineStars					INT DEFAULT 0  
				,SecondLineStars				INT DEFAULT 0  
				,ThirdLineStars					INT DEFAULT 0 
				,FirstLineStars_Associated		INT DEFAULT 0  
				,SecondLineStars_Associated		INT DEFAULT 0  
				,ThirdLineStars_Associated		INT DEFAULT 0  
				,GuaranteedStarsContributors	AS (FirstLineStars+FirstLineStars_Associated)  
				,PotentialsStars				AS (SecondLineStars+SecondLineStars_Associated+ThirdLineStars+ThirdLineStars_Associated) 
				,PotentialsStarsCommited		INT DEFAULT 0
				,TotalStars						INT DEFAULT 0 
			)

		INSERT INTO #TimeLog VALUES ('UplinesContributors', 7, 4, GETUTCDATE(), NULL);
				
			INSERT INTO #UplinesContributors (PK_Distributor,FirstLineCount,SecondLineCount,ThirdLineCount,FirstLineStars,SecondLineStars,ThirdLineStars)
			SELECT U.PK_Distributor
					,ISNULL(L1.[FirstLineContributorCount] ,0) [FirstLineCount]
					,ISNULL(L2.[SecondLineContributorCount],0) [SecondLineCount]
					,ISNULL(L3.[ThirdLineContributorCount],0) [ThirdLineCount]
					,ISNULL(L1_Stars.[FirstLineStarCount],0) [FirstLineStars]
					,ISNULL(L2_Stars.[SecondLineStarCount],0) [SecondLineStars]
					,ISNULL(L3_Stars.[ThirdLineStarCount],0) [ThirdLineStars]
			FROM #Uplines U
			LEFT JOIN
				(	
					SELECT PK_Distributor, COUNT(PK_FirstDownLine) AS [FirstLineContributorCount]
					FROM (
						SELECT DISTINCT PK_Distributor,
						PK_FirstDownLine
						FROM
							#Contribution_L1 WHERE IsVacationBonusContributor = 1
					) AS R
						GROUP BY R.PK_Distributor
				) AS L1	
			ON 
				L1.PK_Distributor = U.PK_Distributor
			LEFT JOIN
				(	
					SELECT PK_Distributor, COUNT(PK_FirstDownLine) AS [SecondLineContributorCount]
					FROM (
						SELECT DISTINCT PK_Distributor,
						PK_FirstDownLine
						FROM
							#Contribution_L2 WHERE IsVacationBonusContributor = 1
					) AS R
					GROUP BY R.PK_Distributor
				) L2	
			ON 
				L2.PK_Distributor = U.PK_Distributor
			LEFT JOIN
				(	
					SELECT PK_Distributor, COUNT(PK_FirstDownLine) AS [ThirdLineContributorCount]
					FROM (
						SELECT DISTINCT PK_Distributor,
						PK_FirstDownLine
						FROM
							#Contribution_L3 WHERE IsVacationBonusContributor = 1
					) AS R
						GROUP BY R.PK_Distributor
				) L3	
			ON 
				L3.PK_Distributor = U.PK_Distributor
			LEFT JOIN
				(	
					SELECT PK_Distributor, COUNT(PK_FirstDownLine) AS [FirstLineStarCount]
					FROM (
						SELECT DISTINCT PK_Distributor,
						PK_FirstDownLine
						FROM
							#Contribution_L1 WHERE IsStar = 1
					) AS R
					GROUP BY R.PK_Distributor
				) L1_Stars	
			ON 
				L1_Stars.PK_Distributor = U.PK_Distributor
			LEFT JOIN
				(	
					SELECT PK_Distributor, COUNT(PK_FirstDownLine) AS [SecondLineStarCount]
					FROM (
						SELECT DISTINCT PK_Distributor,
						PK_FirstDownLine
						FROM
							#Contribution_L2 WHERE IsStar = 1
					) AS R
					GROUP BY R.PK_Distributor
				) L2_Stars		
			ON 
				L2_Stars.PK_Distributor = U.PK_Distributor
			LEFT JOIN
				(	
					SELECT PK_Distributor, COUNT(PK_FirstDownLine) AS [ThirdLineStarCount]
					FROM (
						SELECT DISTINCT PK_Distributor,
						PK_FirstDownLine
						FROM
							#Contribution_L3 WHERE IsStar = 1
					) AS R
					GROUP BY R.PK_Distributor
				) L3_Stars		
			ON 
				L3_Stars.PK_Distributor = U.PK_Distributor

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 7 AND [StepSubGroup] = 4;

		/* ADDING MAIN ASSOCIATED Contributors TO ASSOCIATED IDs */

		INSERT INTO #TimeLog VALUES ('Associated UplinesContributors', 7, 5, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #Associated_Contributors 
			 
				SELECT 
					T.PK_Distributor,
					T.PK_AssociatedID,
					ISNULL(B.FirstLineCount,0) AS [FirstLineCount_Associated],
					ISNULL(B.SecondLineCount,0) AS [SecondLineCount_Associated],
					ISNULL(B.ThirdLineCount,0) AS [ThirdLineCount_Associated],
					ISNULL(B.FirstLineStars,0) AS [FirstLineStars_Associated],
					ISNULL(B.SecondLineStars,0) AS [SecondLineStars_Associated],
					ISNULL(B.ThirdLineStars,0) AS [ThirdLineStars_Associated]
				INTO #Associated_Contributors
				 FROM
			 			[Shared].[DistributorAssociation] AS T WITH (NOLOCK)
				 LEFT JOIN
			 		#UplinesContributors B
				 ON
			 		T.PK_AssociatedID = B.PK_Distributor
			 
				 UPDATE
			 			T
				 SET
			 			T.FirstLineCount_Associated =  ISNULL(A.FirstLineCount_Associated,0),
						T.SecondLineCount_Associated = ISNULL(A.SecondLineCount_Associated,0),
						T.ThirdLineCount_Associated  = ISNULL(A.ThirdLineCount_Associated,0), 
						T.FirstLineStars_Associated =  ISNULL(A.FirstLineStars_Associated,0),
						T.SecondLineStars_Associated = ISNULL(A.SecondLineStars_Associated,0),
						T.ThirdLineStars_Associated  = ISNULL(A.ThirdLineStars_Associated,0)
				 FROM
			 			#UplinesContributors T
				 LEFT JOIN
			 			#Associated_Contributors A
				 ON
			 		T.PK_Distributor = A.PK_Distributor 					
										
			IF (@Potentials_Commitment_Date IS NULL OR @CurrentDate >= @Potentials_Commitment_Date)
			BEGIN
				
				UPDATE #UplinesContributors
					SET PotentialsCommited =  Potentials,
						PotentialsStarsCommited = PotentialsStars
			END

			UPDATE #UplinesContributors
			SET 
				OverallCount = ISNULL(FirstLineCount,0)+ISNULL(FirstLineCount_Associated,0)+ISNULL(PotentialsCommited,0),
				TotalStars = ISNULL(FirstLineStars,0)+ISNULL(FirstLineStars_Associated,0)+ISNULL(PotentialsStarsCommited,0)

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 7 AND [StepSubGroup] = 5;
	 
		END

		--Step 8: Volume for uplines
		
		IF @Step >= 8
		BEGIN

			PRINT 'Executing step 8'

			IF @IsDevQA = 0
			BEGIN	

				DELETE s FROM [Event].[SetupEventQualification] AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
				INSERT INTO [Event].[SetupEventQualification](PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
				SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition 
				FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event AND ISNULL([ForDownlinesOnly],0) = 0 

			END
			ELSE
			IF @IsDevQA = 3
			BEGIN	

				DELETE s FROM ##Event_SetupEventQualification_amed AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
				INSERT INTO ##Event_SetupEventQualification_amed(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
				SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition
				FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event AND ISNULL([ForDownlinesOnly],0) = 0

			END

			------------------------------------------------------------------------------------------------
			-- 8.1 Getting values from #Event_SetupEventQualification
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification', 8, 1, GETUTCDATE(), NULL);
				
				SELECT 
					@iStartDate = CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int), 
					@dStartDate = MIN(dStartDate),
					@iEndDate = CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int),
					@dEndDate = MAX(dEndDate)
					FROM #Event_SetupEventQualification WITH (NOLOCK) 
	
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 8 AND [StepSubGroup] = 1;

				-- Result set 
				IF @IsDevQA > 0 SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate]--,@DSCountries AS [DSCountries]--,@MetricType AS [MetricType]

				------------------------------------------------------------------------------------------------
				-- 8.2 Getting #tmp_DS
				------------------------------------------------------------------------------------------------
			
				INSERT INTO #TimeLog VALUES ('#tmp_DS', 8, 2, GETUTCDATE(), NULL);

					DELETE FROM #tmp_DS

					DROP INDEX IF EXISTS IX_#tmp_DS_PK_Distributor ON #tmp_DS;
					
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
					INNER JOIN #EventQual AS EQ
						ON D.PK_Distributor = EQ.PK_Distributor
					INNER JOIN v_Distributor AS DD
						ON D.PK_Distributor = DD.nDistributorID
					WHERE 			 
					(EQ.Q02 = 1 AND EQ.Q03 = 1) OR -- FQS (Non-TAB) AND AWT 2023
					(EQ.Q04 = 1) OR -- NEW GET (GET Team Qual Date From Nov 01 2022 to Jan 01 2024)
					(EQ.Q05 = 1) OR -- TAB (GT,GP,MT,MP,PT and above on or before TAB Freeze Date As of Oct 01 2022)
					(EQ.Q06 = 1) -- PT and Above

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
						
						DROP INDEX IF EXISTS [IX_##tmp_DS_amed_PK_Distributor]
							ON ##tmp_DS_amed;

						DELETE d FROM ##tmp_DS_amed AS d WHERE d.PK_Event = @PK_Event  

						INSERT INTO ##tmp_DS_amed([PK_Event],[PK_Distributor],[StartDate],[EndDate])
						SELECT 
							D.[PK_Event],
							D.PK_Distributor,
							D.[iStartDate],
							D.[iEndDate]
						FROM #tmp_DS AS D 
											 
						CREATE INDEX IX_##tmp_DS_amed_PK_Distributor ON ##tmp_DS_amed(PK_Distributor) INCLUDE(PK_Event);

					END

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 8 AND [StepSubGroup] = 2;

				------------------------------------------------------------------------------------------------
				-- 8.3 Getting [Event].[DSPoints]
				------------------------------------------------------------------------------------------------
			
				IF (@IsDevQA = 0)
				BEGIN
					INSERT INTO #TimeLog VALUES ('usp_GetDSVolume', 8, 3, GETUTCDATE(), NULL);

					--SourceType 1: Getting points from PubEvents.[dbo].[factDSFinancial_ctry], includes divorce and tranfer cases.
					EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 1, @Print = 1, @QualFilter = '8,9,19,20',@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					--Output [Event].[DSPoints]

					--SourceType 2: Getting points from PubEvents.dbo.factdsfinancial_PHX
					EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 2, @Print = 1,@KeepData = 1 ,@QualFilter = '10,21' ,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					--Output [Event].[DSPoints]

					IF @Error <> 0
					BEGIN
						SET @Error = @Error
						SET @ErrorMessage = @ErrorMessage
						RETURN;
					END

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 8 AND [StepSubGroup] = 3;
		
				END
				ELSE
				IF (@IsDevQA = 3) AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_amed') IS NOT NULL
				BEGIN
					 
					 INSERT INTO #TimeLog VALUES ('##usp_GetDSVolume_amed', 8, 3, GETUTCDATE(), NULL);

					--Input
					--##tmp_DS_amed
					--##Event_SetupEventQualification_amed

					EXEC [dbo].[##usp_GetDSVolume_amed] @PK_Event = @PK_Event, @SourceType = 1,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
					IF @Error <> 0
					BEGIN
						SET @Error = @Error
						SET @ErrorMessage = @ErrorMessage

						SELECT @ErrorMessage
						RETURN;
					END

					--Output
					--##Event_DSPoints_amed
 
		
					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 8 AND [StepSubGroup] = 3;
		
				END
			
			------------------------------------------------------------------------------------------------
			-- 8.4 Getting #Event_DSPoints AND #Event_DSPoints_Validations
			------------------------------------------------------------------------------------------------
		
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints', 8, 4, GETUTCDATE(), NULL);

				DELETE FROM #Event_DSPoints
		
				DROP INDEX IF EXISTS [IX_#Event_DSPoints_PK_Distributor_MetricType] ON #Event_DSPoints;

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
					FROM ##Event_DSPoints_amed

				END

				CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_PK_Distributor_MetricType] ON #Event_DSPoints ([PK_Distributor]) INCLUDE ([MetricType]);
	 
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 8 AND [StepSubGroup] = 4;
			
		
		END
			 
		--Step 9: Qualification definition for uplines

		IF @Step >= 9
		BEGIN
				PRINT 'Executing step 9'

				------------------------------------------------------------------------------------------------
				-- 4.1 Getting all qualification definition for each DS
				------------------------------------------------------------------------------------------------

				INSERT INTO #TimeLog VALUES ('#tmp_DSQualDef', 9, 1, GETUTCDATE(), NULL);
			
					DELETE FROM #tmp_DSQualDef

					DROP INDEX IF EXISTS IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef;

					INSERT INTO #tmp_DSQualDef([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,QSVolume,Bonus)
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
							[QSVolume],
							C.Bonus
						FROM #tmp_DS AS D					
							LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
								ON D.PK_Distributor = M.PK_Distributor
							OUTER APPLY #Event_SetupEventQualification AS C WITH (NOLOCK)
							CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
		
					CREATE INDEX IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef(PK_Distributor);

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 9 AND [StepSubGroup] = 1;

				IF @IsDevQA = 0
				BEGIN

					INSERT INTO #TimeLog VALUES ('[tmp].[DSQualDef]', 9, 2, GETUTCDATE(), NULL);
					
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
					WHERE [StepGroup] = 9 AND [StepSubGroup] = 2;
										
			END  
			ELSE IF @IsDevQA = 3
			BEGIN
				
				INSERT INTO ##tmp_DSQualDef_amed([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[Bonus],[QSVolume])
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
		
		--Step 10:  Bonuses / DSPointsSummary	
	
		IF @Step >= 10
		BEGIN
			
			PRINT 'Executing step 10'

			------------------------------------------------------------------------------------------------
			-- 10.1 Getting all downlines contributing for the bonus, including the ones from associated 
			------------------------------------------------------------------------------------------------

			INSERT INTO #TimeLog VALUES ('#WRK_24009_DSDownlinesBonusSummary', 10, 1, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #WRK_24009_DSDownlinesBonusSummary

				SELECT 
					PK_Distributor					
					,FirstLineCount					
					,SecondLineCount				
					,ThirdLineCount					
					,FirstLineCount_Associated		
					,SecondLineCount_Associated		
					,ThirdLineCount_Associated		
					,GuaranteedContributors			
					,Potentials						 
					,PotentialsCommited				
					,OverallCount					
					,Bonus
					,FirstLineStars					 
					,SecondLineStars				  
					,ThirdLineStars					 
					,FirstLineStars_Associated		  
					,SecondLineStars_Associated		  
					,ThirdLineStars_Associated	
					,GuaranteedStarsContributors
					,PotentialsStars
					,PotentialsStarsCommited
					,TotalStars						
				INTO #WRK_24009_DSDownlinesBonusSummary
				FROM #UplinesContributors AS D
				
				IF @IsDevQA = 0
				BEGIN

					DROP TABLE IF EXISTS [dbo].[WRK_24009_DSDownlinesBonusSummary]

					SELECT 
						 PK_Distributor					
						,FirstLineCount					
						,SecondLineCount				
						,ThirdLineCount					
						,FirstLineCount_Associated		
						,SecondLineCount_Associated		
						,ThirdLineCount_Associated		
						,GuaranteedContributors			
						,Potentials						 
						,PotentialsCommited				
						,OverallCount					
						,Bonus
						,FirstLineStars					 
						,SecondLineStars				  
						,ThirdLineStars					 
						,FirstLineStars_Associated		  
						,SecondLineStars_Associated		  
						,ThirdLineStars_Associated	
						,GuaranteedStarsContributors
						,PotentialsStars
						,PotentialsStarsCommited
						,TotalStars	
					INTO [dbo].[WRK_24009_DSDownlinesBonusSummary]
					FROM #WRK_24009_DSDownlinesBonusSummary AS D
						
					CREATE INDEX IX_WRK_24009_DSDownlinesBonusSummary_PK_Distributor ON [dbo].[WRK_24009_DSDownlinesBonusSummary](PK_Distributor)
		
				END
				ELSE IF @IsDevQA = 3
				BEGIN

					DROP TABLE IF EXISTS [dbo].[##WRK_24009_DSDownlinesBonusSummary]

					SELECT 
						 PK_Distributor					
						,FirstLineCount					
						,SecondLineCount				
						,ThirdLineCount					
						,FirstLineCount_Associated		
						,SecondLineCount_Associated		
						,ThirdLineCount_Associated		
						,GuaranteedContributors			
						,Potentials						 
						,PotentialsCommited				
						,OverallCount					
						,Bonus
						,FirstLineStars					 
						,SecondLineStars				  
						,ThirdLineStars					 
						,FirstLineStars_Associated		  
						,SecondLineStars_Associated		  
						,ThirdLineStars_Associated		  
						,TotalStars	
					INTO [dbo].[##WRK_24009_DSDownlinesBonusSummary]
					FROM #WRK_24009_DSDownlinesBonusSummary AS D
						
					CREATE INDEX IX_##WRK_24009_DSDownlinesBonusSummary_PK_Distributor ON [dbo].[##WRK_24009_DSDownlinesBonusSummary](PK_Distributor)
		
				END
		
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 10 AND [StepSubGroup] = 1;
			
			------------------------------------------------------------------------------------------------
			-- 10.2 Assigning bonuses
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints_Summary', 10, 2, GETUTCDATE(), NULL);
			
				DELETE FROM #Event_DSPoints_Summary
			 
				INSERT INTO #Event_DSPoints_Summary(PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,QSVolumePercentage,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries,[BonusCount])
					SELECT U.PK_Distributor,
							U.RoyaltyMonth,
							U.MetricType,
							U.PK_Country AS PK_Country,
							SUM(IIF(ISNULL(F.[QSVolume],0) = 0,IIF(U.RoyaltyMonth < F.iSPQualDate,0, ISNULL(U.Points,0)),ISNULL(U.Points,0))) AS [Points],	
							F.[QSVolume],
							F.[QSVolumePercentage],
							F.iSPQualDate,
							F.QualificationNumber,
							F.Part,
							F.iStartDate,
							F.iEndDate,
							F.Countries,
							F.[Bonus] AS [BonusCount]
					FROM #Event_DSPoints AS U WITH (NOLOCK) 
								INNER JOIN #tmp_DSQualDef AS F
									ON u.PK_Distributor = F.PK_Distributor	
									WHERE 
									F.MetricType = U.MetricType 
									AND 
									U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
									AND 
					(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
					GROUP BY U.PK_Distributor,U.RoyaltyMonth,U.MetricType,U.PK_Country,F.[QSVolume],F.[QSVolumePercentage],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries,F.Bonus
			
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 10 AND [StepSubGroup] = 2;

			INSERT INTO #TimeLog VALUES ('#WRK_24009_BonusPoints', 10, 3, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #WRK_24009_BonusPoints

				--Seeking the greatest volume month per qualification in order to reward that month with a bonus.

				;WITH cte_MaxVolumeMonth AS
				(
					SELECT PK_Distributor,MetricType,PK_Country,QualificationNumber,Part,BonusCount, MAX(RoyaltyMonth) AS RoyaltyMonth  
					FROM #Event_DSPoints_Summary  
					WHERE BonusCount = 1
					GROUP BY PK_Distributor,MetricType,PK_Country,QualificationNumber,Part,BonusCount
				)

				SELECT 
						U.PK_Distributor,
						U.RoyaltyMonth,
						U.MetricType,
						U.PK_Country AS PK_Country,
						ISNULL(U.Points,0) AS [Points],
						U.[QSVolume],
						U.[QSVolumePercentage],
						U.iSPQualDate,
						U.QualificationNumber,
						U.Part,
						U.iStartDate,
						U.iEndDate,
						U.Countries,
						IIF(U.QualificationNumber IN (SELECT [String] FROM dbo.[udf_SplitVarchar](@BonusApplicableToQs, ','))
							AND U.MetricType = 'TV' 
							AND U.[BonusCount] = 1 
							AND U.RoyaltyMonth = VM.RoyaltyMonth, ISNULL(BS.[Bonus],0), 0) AS [Vacation Bonus]
					INTO #WRK_24009_BonusPoints
					FROM #Event_DSPoints_Summary AS U WITH (NOLOCK)
						LEFT JOIN cte_MaxVolumeMonth AS VM
							ON U.PK_Distributor = VM.PK_Distributor
								AND U.MetricType = VM.MetricType
								AND U.PK_Country = VM.PK_Country
								AND U.QualificationNumber = VM.QualificationNumber
								AND U.Part = VM.Part
							LEFT JOIN #WRK_24009_DSDownlinesBonusSummary AS BS 
								ON VM.PK_Distributor = BS.PK_Distributor
											
				CREATE INDEX IX_#WRK_24009_BonusPoints_PK_Distributor ON #WRK_24009_BonusPoints(PK_Distributor)
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 10 AND [StepSubGroup] = 3;

			IF @IsDevQA = 0
			BEGIN
			
				INSERT INTO #TimeLog VALUES ('WRK_24009_BonusPoints', 10, 4, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS [dbo].[WRK_24009_BonusPoints]

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
							[Vacation Bonus]
						INTO [dbo].[WRK_24009_BonusPoints]
						FROM #WRK_24009_BonusPoints	

					CREATE INDEX IX_WRK_24009_BonusPoints_PK_Distributor ON [dbo].[WRK_24009_BonusPoints](PK_Distributor)

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 10 AND [StepSubGroup] = 4;

			END

			INSERT INTO #TimeLog VALUES ('#tmp_DSPointsSummary', 10, 5, GETUTCDATE(), NULL);

				DELETE FROM #tmp_DSPointsSummary
				 
				INSERT INTO #tmp_DSPointsSummary([PK_Event],PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,iSPQualDate,[QSVolume],[Countries])
				SELECT 
							@PK_Event AS PK_Event,
							P.PK_Distributor,
							P.RoyaltyMonth,
							P.MetricType,
							P.PK_Country,
							P.[Points],
							P.QualificationNumber,
							P.Part,
							ISNULL(P.[Vacation Bonus],0) AS [Bonus],
							ISNULL(P.[Points],0) + ISNULL(P.[Vacation Bonus],0) AS [TotalPoints],
							P.iStartDate,
							P.iEndDate,
							iSPQualDate,
							[QSVolume],
							[Countries]
						FROM #WRK_24009_BonusPoints AS P WITH (NOLOCK)

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 10 AND [StepSubGroup] =5;

			IF @IsDevQA = 0
			BEGIN
					
				INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary]', 10, 6, GETUTCDATE(), NULL);
				
				DELETE t
				FROM [tmp].[DSPointsSummary] AS t
				WHERE t.PK_Event = @PK_Event

				DROP INDEX IF EXISTS IX_tmp_DSPointsSummary_PK_Distributor ON [tmp].[DSPointsSummary];

				INSERT INTO [tmp].[DSPointsSummary](PK_Event, PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,[Countries])
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
						iEndDate,
						[Countries]
					FROM #tmp_DSPointsSummary

				CREATE INDEX IX_tmp_DSPointsSummary_PK_Distributor ON [tmp].[DSPointsSummary](PK_Distributor)INCLUDE (PK_Event);	

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 10 AND [StepSubGroup] =6;

			END
			ELSE IF @IsDevQA = 3
			BEGIN

				INSERT INTO ##DSPointsSummary_amed(PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,[Countries])
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
						iEndDate,
						[Countries]
					FROM #tmp_DSPointsSummary

			END

		END

		--Step 11: Uplines Qualifiers by volume
	
		IF @Step >= 11
		BEGIN
			
			PRINT 'Executing step 11'

			------------------------------------------------------------------------------------------------
			-- 11.1 Getting qualifiers by volume according to qualification definitions
			------------------------------------------------------------------------------------------------
	
			INSERT INTO #TimeLog VALUES ('Qualifiers by volume', 11, 1, GETUTCDATE(), NULL);

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
				FROM #Event_SetupEventQualification WHERE [ForDownlinesOnly] = 0

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
				ELSE IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetQualifier_Points_amed') IS NOT NULL
				BEGIN
					 
						--Input 
						--##DSPointsSummary_amed
						--##Event_DSPoints_amed
						--##tmp_DSQualDef_amed
						--##Event_SetupEventQualification_amed

				 
						EXEC ##usp_GetQualifier_Points_amed @PK_Event = @PK_Event_Execution, @QualType = @QualType, @OverwritePointsSummary = @OverwritePointsSummary, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
						IF @Error <> 0
						BEGIN
							SET @Error = @Error
							SET @ErrorMessage = @ErrorMessage
							RETURN;
						END				 

					--Output 
					--##DSQualPoints_amed
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
					FROM ##DSQualPoints_amed AS Q
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
			WHERE [StepGroup] = 11 AND [StepSubGroup] = 1;
		END
	 
		--Step 12: Qualifications

		IF @Step >= 12
		BEGIN
			
			PRINT 'Executing step 12'

			INSERT INTO #TimeLog VALUES ('Qualifications', 12, 1, GETUTCDATE(), NULL);

			------------------------------------------------------------------------------------------------
			-- List qualifications
			------------------------------------------------------------------------------------------------
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
			BEGIN

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
						WHERE (Q'+ CAST(@QPart AS VARCHAR(5)) +'  .QualificationNumber = '+ CAST(@QualificationNumber AS VARCHAR(10)) +' AND Q'+CAST(@QPart AS VARCHAR(10))+'.Part = '+ CAST(@QPart AS VARCHAR(10)) +' AND Q'+CAST(@QPart AS VARCHAR(10))+'.PK_Event = ' + CAST(@PK_Event AS VARCHAR(10)) +')
						AND Q1.PK_Distributor = Q'+ CAST(@QPart AS VARCHAR(5)) +'.PK_Distributor AND Q1.QualificationNumber = Q'+ CAST(@QPart AS VARCHAR(5)) +'.QualificationNumber AND Q1.PK_Event = Q'+ CAST(@QPart AS VARCHAR(5)) +'.PK_Event)'

						UPDATE #QAdditionalParts
						SET [ctrl] = 1
						WHERE QualificationNumber = @QualificationNumber AND Part = @QPart

					END
												
				END

				PRINT @SqlStatement

				EXECUTE sp_executesql @SqlStatement

				SET @SqlStatement = ''

				SET @SqlStatement = 'UPDATE Q
				SET ' + @QColumn + ' = 1' +
				' FROM #EventQual Q
				INNER JOIN ##QualVolumeQualifiers AS QQ
				ON Q.PK_Event = QQ.PK_Event
				AND Q.PK_Distributor = QQ.PK_Distributor'

				PRINT @SqlStatement

				EXECUTE sp_executesql @SqlStatement

				UPDATE #QualificationsMapping
				SET [ctrl] = 1
				WHERE ID = @ID

			END

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 12 AND [StepSubGroup] = 1;

		END
			
		--Step 13: Subevents
		IF @Step >= 13
		BEGIN

			PRINT 'Executing step 13'

			INSERT INTO #TimeLog VALUES ('Es #EventQual', 13, 1, GETUTCDATE(), NULL);
				
				UPDATE 
					#EventQual
				SET

					E02 = (((Q02 & Q03 & ((Q18 & Q08) | (Q17 & Q19))) | Q12) & ~Q23)
				
				UPDATE 
					#EventQual
				SET
					E03 =  (((Q04 & ((Q18 & Q08) | (Q17 & Q19))) | Q13) & ~Q24)
				
				UPDATE 
					#EventQual
				SET
					E04 =  (((Q05 & ((Q18 & Q09) | (Q17 & Q20))) | Q07 | Q14) & ~Q25)
				
				UPDATE 
					#EventQual
				SET
					E05 =  (((Q06 & ((Q18 & Q10) | (Q17 & Q21))) | Q07 | Q15) & ~Q26)
				
				UPDATE 
					#EventQual
				SET
					E01 =  ((E02 | E03 | E04 | E05 | Q11) & ~Q22)

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
			WHERE [StepGroup] = 13 AND [StepSubGroup] = 1;

		END

		--Step 14: [Event].[DSQual]	
		IF @Step >= 14
		BEGIN
			
			PRINT 'Executing step 14'

			INSERT INTO #TimeLog VALUES ('[Event].[DSQual]', 14, 1, GETUTCDATE(), NULL);

			IF @IsDevQA = 0
			BEGIN

				DELETE dq			
				FROM [Event].[DSQual] AS dq
				WHERE PK_Event = @PK_Event
					
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
					 q.PK_Event AS PK_Event	
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
				FROM #EventQual AS q
		
				CREATE INDEX [IX_Event_DSQual_PK_Event] ON [Event].[DSQual](PK_Event);
				CREATE INDEX [IX_Event_DSQual_PK_Distributor_PK_Event] ON [Event].[DSQual](PK_Distributor) INCLUDE(PK_Event);

			END
			ELSE IF @IsDevQA = 3
			BEGIN

				DROP TABLE IF EXISTS ##Event_DSQual_amed 
	 
				SELECT
					 q.PK_Event AS PK_Event	
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
				INTO ##Event_DSQual_amed
				FROM #EventQual AS q		

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 14 AND [StepSubGroup] = 1;

		END

		--Step 15: SubEventQualifiers
		IF @Step >= 15 
		BEGIN

			INSERT INTO #TimeLog VALUES ('SubEventQualifier', 15, 1, GETUTCDATE(), NULL);

			IF @IsDevQA = 0
			BEGIN

				PRINT 'Executing step 15'
		
				DECLARE @Events VARCHAR(MAX)
				
				SELECT @Events = STRING_AGG(PK_Event,',') FROM #Locations

				EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
				@Events = @Events,
				@Source = 2,
				@EvaluateFormula = 0

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 15 AND [StepSubGroup] = 1;
		END
		 
		IF @IsDevQA = 0
		BEGIN

			IF OBJECT_ID('tempdb..#ListsQualificationMapping') IS NOT NULL
			BEGIN

				DROP TABLE IF EXISTS [tmp].[ListsQsMapping]
					 
				SELECT @ProjectID AS [ProjectID], QColumn,ListID
				INTO [tmp].[ListsQsMapping]
				FROM #ListsQualificationMapping

			END

			IF OBJECT_ID('tempdb..#SKUsQsMapping') IS NOT NULL
			BEGIN

				DROP TABLE IF EXISTS [tmp].[SKUsQsMapping]

				SELECT @ProjectID AS [ProjectID], QColumn,SKUCode
				INTO [tmp].[SKUsQsMapping]
				FROM #SKUsQsMapping

			END
		
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