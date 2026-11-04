CREATE PROCEDURE [dbo].[usp_EventQual_Ukraine_FMTR_July_2025]
	@PK_Event int = 203429
	,@Parameters NVARCHAR(MAX)
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
	,@Step SMALLINT = 10
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_Ukraine_FMTR_July_2025

	USE:		

			USE [PubEventManagement]
			GO
			DECLARE	@Error int,
					@ErrorMessage varchar(4000),
					@Parameters NVARCHAR(MAX) = N'{
						"pkEvent":203429,			
						"qualPeriodStart_Q3A":"2024-06-01",
						"qualPeriodEnd_Q3A":"2024-11-01",
						"qualPeriodStart_Q3B":"2024-07-01",
						"qualPeriodEnd_Q3B":"2024-12-01",
						"qualPeriodStart_Q3C":"2024-08-01",
						"qualPeriodEnd_Q3C":"2025-01-01",
						"qualPeriodStart_Q3D":"2024-09-01",
						"qualPeriodEnd_Q3D":"2025-02-01",
						"qualPeriodStart_Q3E":"2024-10-01",
						"qualPeriodEnd_Q3E":"2025-03-01",
						"qualPeriodStart_Q3F":"2024-11-01",
						"qualPeriodEnd_Q3F":"2025-04-01",
						"qualPeriodStart_Q3G":"2024-12-01",
						"qualPeriodEnd_Q3G":"2025-05-01",
						"step":10,
						"countries":"UA"
					}'

			EXEC dbo.usp_EventQual_Ukraine_FMTR_July_2025
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

	COMMENTS:

	Due to Q3 that stands for spliting the QualPeriod A into 7 periods of 6 months each, 
									JUN24-NOV24, JUL24-DEC24, AGO24-JAN25, SEP24-FEB25, OCT24-MAR25, NOV24-APR25, DEC24-MAY25
									Having the Q3,Q4,Q5,Q6 depending on the period as following
									Q3 = Q30,Q34,Q38,Q42,Q46,Q50,Q54 
									Q4 = Q31,Q35,Q39,Q43,Q47,Q51,Q55
									Q5 = Q32,Q36,Q40,Q44,Q48,Q52,Q56
									Q6 = Q33,Q37,Q41,Q45,Q49,Q53,Q57
	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0		2025-04-29		JuanGue			Initial BRD v1.0
	***********************************************************************************************************************************/
	
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

	-- Variables for json values
	DECLARE 
		@QualPeriodStart_Q3A DATE,
		@QualPeriodEnd_Q3A DATE,
		@QualPeriodStart_Q3B DATE,
		@QualPeriodEnd_Q3B DATE,
		@QualPeriodStart_Q3C DATE,
		@QualPeriodEnd_Q3C DATE,
		@QualPeriodStart_Q3D DATE,
		@QualPeriodEnd_Q3D DATE,
		@QualPeriodStart_Q3E DATE,
		@QualPeriodEnd_Q3E DATE,
		@QualPeriodStart_Q3F DATE,
		@QualPeriodEnd_Q3F DATE,
		@QualPeriodStart_Q3G DATE,
		@QualPeriodEnd_Q3G DATE,
		@Countries VARCHAR(MAX)

	-- Getting parameters values for json
		SELECT 
			@PK_Event				= g.pkEvent, 
			@QualPeriodStart_Q3A	= g.qualPeriodStart_Q3A,
			@QualPeriodEnd_Q3A		= g.qualPeriodEnd_Q3A,
			@QualPeriodStart_Q3B	= g.qualPeriodStart_Q3B,
			@QualPeriodEnd_Q3B		= g.qualPeriodEnd_Q3B,
			@QualPeriodStart_Q3C	= g.qualPeriodStart_Q3C,
			@QualPeriodEnd_Q3C		= g.qualPeriodEnd_Q3C,
			@QualPeriodStart_Q3D	= g.qualPeriodStart_Q3D,
			@QualPeriodEnd_Q3D		= g.qualPeriodEnd_Q3D,
			@QualPeriodStart_Q3E	= g.qualPeriodStart_Q3E,
			@QualPeriodEnd_Q3E		= g.qualPeriodEnd_Q3E,
			@QualPeriodStart_Q3F	= g.qualPeriodStart_Q3F,
			@QualPeriodEnd_Q3F		= g.qualPeriodEnd_Q3F,
			@QualPeriodStart_Q3G	= g.qualPeriodStart_Q3G,
			@QualPeriodEnd_Q3G		= g.qualPeriodEnd_Q3G,
			@Step					= g.step,
			@Countries				= g.countries

		FROM OPENJSON(@Parameters)
		WITH (
				pkEvent INT '$.pkEvent',
				qualPeriodStart_Q3A DATE '$.qualPeriodStart_Q3A',
				qualPeriodEnd_Q3A	DATE '$.qualPeriodEnd_Q3A',
				qualPeriodStart_Q3B DATE '$.qualPeriodStart_Q3B',
				qualPeriodEnd_Q3B	DATE '$.qualPeriodEnd_Q3B',
				qualPeriodStart_Q3C DATE '$.qualPeriodStart_Q3C',
				qualPeriodEnd_Q3C	DATE '$.qualPeriodEnd_Q3C',
				qualPeriodStart_Q3D DATE '$.qualPeriodStart_Q3D',
				qualPeriodEnd_Q3D	DATE '$.qualPeriodEnd_Q3D',
				qualPeriodStart_Q3E DATE '$.qualPeriodStart_Q3E',
				qualPeriodEnd_Q3E	DATE '$.qualPeriodEnd_Q3E',
				qualPeriodStart_Q3F DATE '$.qualPeriodStart_Q3F',
				qualPeriodEnd_Q3F	DATE '$.qualPeriodEnd_Q3F',
				qualPeriodStart_Q3G DATE '$.qualPeriodStart_Q3G',
				qualPeriodEnd_Q3G	DATE '$.qualPeriodEnd_Q3G',
				step INT '$.step',
				countries VARCHAR(MAX) '$.countries'
			) AS g
	 
		-- Default values
		SET @PK_Event				= IIF(@PK_Event IS NULL,203429,@PK_Event)
		SET @QualPeriodStart_Q3A	= IIF(@QualPeriodStart_Q3A IS NULL,'2024-06-01',@QualPeriodStart_Q3A)
		SET @QualPeriodEnd_Q3A		= IIF(@QualPeriodEnd_Q3A IS NULL,'2024-11-01',@QualPeriodEnd_Q3A)
		SET @QualPeriodStart_Q3B	= IIF(@QualPeriodStart_Q3B IS NULL,'2024-07-01',@QualPeriodStart_Q3B)
		SET @QualPeriodEnd_Q3B		= IIF(@QualPeriodEnd_Q3B IS NULL,'2024-12-01',@QualPeriodEnd_Q3B)
		SET @QualPeriodStart_Q3C	= IIF(@QualPeriodStart_Q3C IS NULL,'2024-08-01',@QualPeriodStart_Q3C)
		SET @QualPeriodEnd_Q3C		= IIF(@QualPeriodEnd_Q3C IS NULL,'2025-01-01',@QualPeriodEnd_Q3C)
		SET @QualPeriodStart_Q3D	= IIF(@QualPeriodStart_Q3D IS NULL,'2024-09-01',@QualPeriodStart_Q3D)
		SET @QualPeriodEnd_Q3D		= IIF(@QualPeriodEnd_Q3D IS NULL,'2025-02-01',@QualPeriodEnd_Q3D)
		SET @QualPeriodStart_Q3E	= IIF(@QualPeriodStart_Q3E IS NULL,'2024-10-01',@QualPeriodStart_Q3E)
		SET @QualPeriodEnd_Q3E		= IIF(@QualPeriodEnd_Q3E IS NULL,'2025-03-01',@QualPeriodEnd_Q3E)
		SET @QualPeriodStart_Q3F	= IIF(@QualPeriodStart_Q3F IS NULL,'2024-11-01',@QualPeriodStart_Q3F)
		SET @QualPeriodEnd_Q3F		= IIF(@QualPeriodEnd_Q3F IS NULL,'2025-04-01',@QualPeriodEnd_Q3F)
		SET @QualPeriodStart_Q3G	= IIF(@QualPeriodStart_Q3G IS NULL,'2024-12-01',@QualPeriodStart_Q3G)
		SET @QualPeriodEnd_Q3G		= IIF(@QualPeriodEnd_Q3G IS NULL,'2025-05-01',@QualPeriodEnd_Q3G)
		SET @Step					= IIF(@Step IS NULL,10,@Step)
		SET @Countries				= IIF(@Countries IS NULL,'UA',@Countries)

		SELECT 
			@PK_Event				AS [PK_Event], 
			@QualPeriodStart_Q3A	AS [QualPeriodStart_Q3A],
			@QualPeriodEnd_Q3A		AS [QualPeriodEnd_Q3A],
			@QualPeriodStart_Q3B	AS [QualPeriodStart_Q3B],
			@QualPeriodEnd_Q3B		AS [QualPeriodEnd_Q3B],
			@QualPeriodStart_Q3C	AS [QualPeriodStart_Q3C],
			@QualPeriodEnd_Q3C		AS [QualPeriodEnd_Q3C],
			@QualPeriodStart_Q3D	AS [QualPeriodStart_Q3D],
			@QualPeriodEnd_Q3D		AS [QualPeriodEnd_Q3D],
			@QualPeriodStart_Q3E	AS [QualPeriodStart_Q3E],
			@QualPeriodEnd_Q3E		AS [QualPeriodEnd_Q3E],
			@QualPeriodStart_Q3F	AS [QualPeriodStart_Q3F],
			@QualPeriodEnd_Q3F		AS [QualPeriodEnd_Q3F],
			@QualPeriodStart_Q3G	AS [QualPeriodStart_Q3G],
			@QualPeriodEnd_Q3G		AS [QualPeriodEnd_Q3G],
			@Step					AS [Step],
			@Countries				AS [Countries]

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
			[MetricTypeDefinition]	VARCHAR(50) NULL
		)
		/**** Qual Period A: June 2024 - May 2025 - Include Volume earned as QS ****/

		--Q02 Achieve 1,000 RO in any one month (June 2024 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			2						AS QualificationNumber,
			1						AS Part, 
			'RO'					AS [MetricType], 
			@QualPeriodStart_Q3A	AS [dStartDate], 
			@QualPeriodEnd_Q3G		AS [dEndDate], 
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			1000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]
	
		/**** Q3 PERIOD - JUN24-NOV24 ****/
		--Q30 - BRD Q3 - Achieve 2,500 TVP in four (4) consecutive months of a six (6) month period during Qual Period (June 2024 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			30						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3A	AS [dStartDate], 
			@QualPeriodEnd_Q3A		AS [dEndDate], 
			4						AS [Frequency], 
			1						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			2500					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q31 - BRD Q4 - Achieve 500 ROs in any one (1) month during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			31						AS QualificationNumber,
			1						AS Part, 
			'RO'					AS [MetricType], 
			@QualPeriodStart_Q3A	AS [dStartDate], 
			@QualPeriodEnd_Q3A		AS [dEndDate], 
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			500						AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]
			
		--Q32 - BRD Q5 - Achieve 5,000 TVP in any two (2) months during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			32						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3A	AS [dStartDate], 
			@QualPeriodEnd_Q3A		AS [dEndDate],
			2						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			5000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q33 - BRD Q6 - Achieve 10,000 TVP in any one (1) month during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			33						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3A	AS [dStartDate], 
			@QualPeriodEnd_Q3A		AS [dEndDate],
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			10000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		/**** Q3 PERIOD - JUL24-DEC24 ****/
		--Q34 - BRD Q3 - Achieve 2,500 TVP in four (4) consecutive months of a six (6) month period during Qual Period (June 2024 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			34						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3B	AS [dStartDate], 
			@QualPeriodEnd_Q3B		AS [dEndDate], 
			4						AS [Frequency], 
			1						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			2500					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q35 - BRD Q4 - Achieve 500 ROs in any one (1) month during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			35						AS QualificationNumber,
			1						AS Part, 
			'RO'					AS [MetricType], 
			@QualPeriodStart_Q3B	AS [dStartDate], 
			@QualPeriodEnd_Q3B		AS [dEndDate], 
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			500						AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]
			
		--Q36 - BRD Q5 - Achieve 5,000 TVP in any two (2) months during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			36						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3B	AS [dStartDate], 
			@QualPeriodEnd_Q3B		AS [dEndDate],
			2						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			5000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q37 - BRD Q6 - Achieve 10,000 TVP in any one (1) month during same qual period as Q3 
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			37						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3B	AS [dStartDate], 
			@QualPeriodEnd_Q3B		AS [dEndDate],
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			10000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		/**** Q3 PERIOD - AGO24-JAN25 ****/
		--Q38 - BRD Q3 - Achieve 2,500 TVP in four (4) consecutive months of a six (6) month period during Qual Period (June 2024 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			38						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3C	AS [dStartDate], 
			@QualPeriodEnd_Q3C		AS [dEndDate], 
			4						AS [Frequency], 
			1						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			2500					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q39 - BRD Q4 - Achieve 500 ROs in any one (1) month during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			39						AS QualificationNumber,
			1						AS Part, 
			'RO'					AS [MetricType], 
			@QualPeriodStart_Q3C	AS [dStartDate], 
			@QualPeriodEnd_Q3C		AS [dEndDate], 
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			500						AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]
			
		--Q40 - BRD Q5 - Achieve 5,000 TVP in any two (2) months during same qual period as Q3 
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			40						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3C	AS [dStartDate], 
			@QualPeriodEnd_Q3C		AS [dEndDate],
			2						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			5000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q41 - BRD Q6 - Achieve 10,000 TVP in any one (1) month during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			41						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3C	AS [dStartDate], 
			@QualPeriodEnd_Q3C		AS [dEndDate],
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			10000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		/**** Q3 PERIOD - SEP24-FEB25 ****/
		--Q42 - BRD Q3 - Achieve 2,500 TVP in four (4) consecutive months of a six (6) month period during Qual Period (June 2024 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			42						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3D	AS [dStartDate], 
			@QualPeriodEnd_Q3D		AS [dEndDate], 
			4						AS [Frequency], 
			1						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			2500					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q43 - BRD Q4 - Achieve 500 ROs in any one (1) month during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			43						AS QualificationNumber,
			1						AS Part, 
			'RO'					AS [MetricType], 
			@QualPeriodStart_Q3D	AS [dStartDate], 
			@QualPeriodEnd_Q3D		AS [dEndDate], 
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			500						AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]
			
		--Q44 - BRD Q5 - Achieve 5,000 TVP in any two (2) months during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			44						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3D	AS [dStartDate], 
			@QualPeriodEnd_Q3D		AS [dEndDate],
			2						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			5000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q45 - BRD Q6 - Achieve 10,000 TVP in any one (1) month during same qual period as Q3 
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			45						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3D	AS [dStartDate], 
			@QualPeriodEnd_Q3D		AS [dEndDate],
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			10000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		/**** Q3 PERIOD - OCT24-MAR25 ****/
		--Q46 - BRD Q3 - Achieve 2,500 TVP in four (4) consecutive months of a six (6) month period during Qual Period (June 2024 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			46						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3E	AS [dStartDate], 
			@QualPeriodEnd_Q3E		AS [dEndDate], 
			4						AS [Frequency], 
			1						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			2500					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q47 - BRD Q4 - Achieve 500 ROs in any one (1) month during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			47						AS QualificationNumber,
			1						AS Part, 
			'RO'					AS [MetricType], 
			@QualPeriodStart_Q3E	AS [dStartDate], 
			@QualPeriodEnd_Q3E		AS [dEndDate], 
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			500						AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]
			
		--Q48 - BRD Q5 - Achieve 5,000 TVP in any two (2) months during same qual period as Q3 
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			48						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3E	AS [dStartDate], 
			@QualPeriodEnd_Q3E		AS [dEndDate],
			2						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			5000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q49 - BRD Q6 - Achieve 10,000 TVP in any one (1) month during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			49						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3E	AS [dStartDate], 
			@QualPeriodEnd_Q3E		AS [dEndDate],
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			10000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		/**** Q3 PERIOD - NOV24-APR25 ****/
		--Q50 - BRD Q3 - Achieve 2,500 TVP in four (4) consecutive months of a six (6) month period during Qual Period (June 2024 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			50						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3F	AS [dStartDate], 
			@QualPeriodEnd_Q3F		AS [dEndDate], 
			4						AS [Frequency], 
			1						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			2500					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q51 - BRD Q4 - Achieve 500 ROs in any one (1) month during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			51						AS QualificationNumber,
			1						AS Part, 
			'RO'					AS [MetricType], 
			@QualPeriodStart_Q3F	AS [dStartDate], 
			@QualPeriodEnd_Q3F		AS [dEndDate], 
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			500						AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]
			
		--Q52 - BRD Q5 - Achieve 5,000 TVP in any two (2) months during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			52						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3F	AS [dStartDate], 
			@QualPeriodEnd_Q3F		AS [dEndDate],
			2						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			5000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q53 - BRD Q6 - Achieve 10,000 TVP in any one (1) month during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			53						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3F	AS [dStartDate], 
			@QualPeriodEnd_Q3F		AS [dEndDate],
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			10000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		/**** Q3 PERIOD - DEC24-MAY25 ****/
		--Q54 - BRD Q3 - Achieve 2,500 TVP in four (4) consecutive months of a six (6) month period during Qual Period (June 2024 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			54						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3G	AS [dStartDate], 
			@QualPeriodEnd_Q3G		AS [dEndDate], 
			4						AS [Frequency], 
			1						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			2500					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q55 - BRD Q4 - Achieve 500 ROs in any one (1) month during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			55						AS QualificationNumber,
			1						AS Part, 
			'RO'					AS [MetricType], 
			@QualPeriodStart_Q3G	AS [dStartDate], 
			@QualPeriodEnd_Q3G		AS [dEndDate], 
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			500						AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]
			
		--Q56 - BRD Q5 - Achieve 5,000 TVP in any two (2) months during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			56						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3G	AS [dStartDate], 
			@QualPeriodEnd_Q3G		AS [dEndDate],
			2						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			5000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]

		--Q57 - BRD Q6 - Achieve 10,000 TVP in any one (1) month during same qual period as Q3
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event				AS [PK_Event],
			57						AS QualificationNumber,
			1						AS Part, 
			'TV'					AS [MetricType], 
			@QualPeriodStart_Q3G	AS [dStartDate], 
			@QualPeriodEnd_Q3G		AS [dEndDate],
			1						AS [Frequency], 
			0						AS [Consecutive], 
			0						AS [Accumulated], 
			0						AS [MinPoints], 
			10000					AS [GoalPoints], 
			NULL					AS [Countries],
			1						AS [QSVolume], 
			1						AS [PeriodType], 
			NULL					AS [MetricTypeDefinition],
			0						AS [Bonus]


		DECLARE @ColumnToPivot NVARCHAR(MAX),
			@SqlStatement NVARCHAR(MAX)

		DECLARE 		
			@SKUs VARCHAR(MAX) = (SELECT STRING_AGG(SKUCode,',') AS [SKUs] FROM [PubEventManagement].[dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = @PK_Event)

		DROP TABLE IF EXISTS #ListsQsMapping

		CREATE TABLE #ListsQsMapping
		(
			ID INT IDENTITY(1,1),
			ListID INT,
			QId INT
		)
									
		INSERT INTO #ListsQsMapping(ListID,QId)
			VALUES 
				(65324,7),
				(65325,8),
				(65326,9),
				(65327,10),
				(65328,11),
				(65329,12),
				(65330,13),
				(65331,14),
				(65332,15),
				(65333,16),
				(65334,17),
				(65335,18),
				(65336,19),
				(65337,20),
				(65338,21),
				(65339,22),
				(65342,23),
				(65340,24),
				(65341,25)

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
			Q51  BIT DEFAULT 0,	Q52  BIT DEFAULT 0,	Q53  BIT DEFAULT 0,	Q54  BIT DEFAULT 0,	Q55  BIT DEFAULT 0,
			Q56  BIT DEFAULT 0,	Q57  BIT DEFAULT 0,	Q58  BIT DEFAULT 0,	Q59  BIT DEFAULT 0,	Q60  BIT DEFAULT 0,

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
		SELECT @PK_Event,'Bukovel, Ukraine' 

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
				PK_Distributor			INT,
				DistributorID			VARCHAR(MAX),   
				DSCurrentTeam			VARCHAR(10),        
				DSSubTeam				VARCHAR(10),        
				DSSPTeam				VARCHAR(10),               
				dSPQualDate				DATETIME2,        
				CountryCode				VARCHAR(5),
				IsFromList				BIT DEFAULT(0),
				IsTicketPurchaser		BIT DEFAULT(0),
				IsFromCOP				BIT DEFAULT(0)
			)

			INSERT INTO #DS
			(
				PK_Distributor,	
				DistributorID,
				DSCurrentTeam,	
				DSSubTeam,		
				DSSPTeam,			
				dSPQualDate,		
				CountryCode,
				IsFromCOP
			)
			SELECT DISTINCT        
			D.nDistributorID AS PK_Distributor,
			D.sDistributorID AS DistributorID, 
			CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
			D.sSubteam AS DSSubTeam,        
			D.sType AS DSSPTeam,            
			D.dSupervisorqualification AS dSPQualDate,        
			D.sDistributorCountryProcessingCode AS CountryCode,
			1 AS IsFromCOP
			FROM        
			dbo.v_Distributor AS D  
				INNER JOIN #Countries AS C
					ON D.nDistributorCountryProcessingID = C.nCountryID		
			WHERE        
				D.StatusCode = 'COMPLETE'   -- Active status     
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
		CASE WHEN D.sTeam IS NULL THEN 
			CASE WHEN sType = 'DS' THEN 
				sSubTeam 
			ELSE 'SP' END 
		ELSE D.sTeam END AS DSCurrentTeam,        
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

		--Getting DS with ticket
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
			PK_Event INT
		)

		INSERT INTO #SKUs(PK_Event,SKUCode)
		SELECT DISTINCT 
			@PK_Event AS PK_Event,
			LTRIM(RTRIM(s.value)) AS [SKUCode]			 
		FROM STRING_SPLIT(@SKUs, ',') AS s
	
		INSERT INTO #DSSKUs(PK_Distributor,PK_EventSKU,PK_Event,SKUCode,UniqueID)
		SELECT DISTINCT et.PK_Distributor_Purchaser,esku.PK_EventSKU, esku.PK_Event, esku.SKUCode ,CAST(s.PK_Event AS NVARCHAR(20)) + '-' + CAST(et.PK_Distributor_Purchaser AS NVARCHAR(20))+ '-'+ CAST(esku.SKUCode  AS NVARCHAR(20))  AS UniqueID  
		FROM #SKUs AS s 
			INNER JOIN dbo.EventSKU AS esku WITH (NOLOCK)
				ON s.SKUCode = esku.SKUCode
			INNER JOIN [dbo].[SKUPurchased] et WITH (NOLOCK)
				ON et.PK_EventSKU = esku.PK_EventSKU
		WHERE  et.PK_Event = s.PK_Event 

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

	END

	--Step 3: Getting Volume for DS target
	IF @Step >= 3
	BEGIN

		PRINT 'Executing step 3'

		INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification', 3, 1, GETUTCDATE(), NULL);

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

		------------------------------------------------------------------------------------------------
		-- 3.1 Getting values from #Event_SetupEventQualification
		------------------------------------------------------------------------------------------------
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
				FROM #Event_SetupEventQualification WITH (NOLOCK) 
	
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 3 AND [StepSubGroup] = 1;

		-- Result set 
		IF @IsDevQA > 0 SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate]--,@DSCountries AS [DSCountries]--,@MetricType AS [MetricType]

		------------------------------------------------------------------------------------------------
		-- 3.2 Getting #tmp_DS
		------------------------------------------------------------------------------------------------
		INSERT INTO #TimeLog VALUES ('Inserting to #tmp_DS', 3, 2, GETUTCDATE(), NULL);

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
					
		DROP INDEX IF EXISTS [IX_#tmp_DS_PK_Distributor]
			ON #tmp_DS;

		DELETE d FROM #tmp_DS AS d WHERE d.PK_Event = @PK_Event  

		INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate])
		SELECT DISTINCT
			@PK_Event AS [PK_Event],
			D.PK_Distributor,
			D.DistributorID,
			@iStartDate AS [iStartDate],
			@iEndDate AS [iEndDate],
			@dStartDate AS [dStartDate],
			@dEndDate AS [dEndDate],
			D.dSPQualDate  
		FROM #DS AS D
			
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
		INSERT INTO #TimeLog VALUES ('Exeting usp_GetDSVolume', 3, 2, GETUTCDATE(), NULL);

		IF (@IsDevQA = 0)
		BEGIN
			--	SourceType 3: Getting points from [PubEventManagement].[dbo].[v_aggFQS_ID] 8.3 WW
			EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 3,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
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

			EXEC [dbo].[##usp_GetDSVolume_jgue] @PK_Event = @PK_Event, @SourceType = 3,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
			IF @Error <> 0
			BEGIN
				SET @Error = @Error
				SET @ErrorMessage = @ErrorMessage

				SELECT @ErrorMessage
				RETURN;
			END

			--Output
			--##Event_DSPoints_jgue
		
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;
		
		END
			
		------------------------------------------------------------------------------------------------
		-- 3.3 Getting #Event_DSPoints 
		------------------------------------------------------------------------------------------------
		
		INSERT INTO #TimeLog VALUES ('Creating the #Event_DSPoints', 3, 3, GETUTCDATE(), NULL);
		
		DROP INDEX IF EXISTS [IX_#Event_DSPoints_PK_Distributor]
			ON #Event_DSPoints;

		DROP INDEX IF EXISTS [IX_#Event_DSPoints_MetricType]
			ON #Event_DSPoints;

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

		DELETE d FROM #Event_DSPoints AS d WHERE d.PK_Event = @PK_Event 

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
			FROM ##Event_DSPoints_jgue

		END

		CREATE CLUSTERED INDEX [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints ([PK_Distributor]) 
		CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints ([MetricType])


		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 3 AND [StepSubGroup] = 3;

	END
		
	--Step 4: Qualification
	IF @Step >= 4
	BEGIN
			PRINT 'Executing step 4'

			------------------------------------------------------------------------------------------------
			-- 4.1 Getting all qualification definition for each DS
			------------------------------------------------------------------------------------------------

			INSERT INTO #TimeLog VALUES ('#tmp_DSQualDef', 4, 1, GETUTCDATE(), NULL);
			
			DROP INDEX IF EXISTS IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef;
					
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
					OUTER APPLY #Event_SetupEventQualification AS C
					CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
		
			CREATE INDEX IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef(PK_Distributor);

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 4 AND [StepSubGroup] = 1;


			INSERT INTO #TimeLog VALUES ('[tmp].[DSQualDef]', 4, 2, GETUTCDATE(), NULL);

			IF @IsDevQA = 0
			BEGIN				
					
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
				
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 4 AND [StepSubGroup] = 2;
		END
	END
		
	--Step 5:  Bonuses / DSPointsSummary	
	IF @Step >= 5
	BEGIN
			
		PRINT 'Executing step 5'

		------------------------------------------------------------------------------------------------
		-- 5.1 Assigning bonuses
		------------------------------------------------------------------------------------------------
			
		INSERT INTO #TimeLog VALUES ('#Event_DSPoints_Summary', 5, 1, GETUTCDATE(), NULL);
			
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
					U.PK_Country AS PK_Country,
					SUM(IIF(ISNULL(F.[QSVolume],0) = 0,IIF(U.RoyaltyMonth < F.iSPQualDate,0, ISNULL(U.Points,0)),ISNULL(U.Points,0))) AS [Points],	
					F.[QSVolume],
					F.[QSVolumePercentage],
					F.iSPQualDate,
					F.QualificationNumber,
					F.Part,
					F.iStartDate,
					F.iEndDate,
					F.Countries
			FROM #Event_DSPoints AS U WITH (NOLOCK) 
						INNER JOIN #tmp_DSQualDef AS F ON u.PK_Distributor = F.PK_Distributor	
							WHERE 
							F.MetricType = U.MetricType 
							AND 
							U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
							AND 
			(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
			GROUP BY U.PK_Distributor,U.RoyaltyMonth,U.MetricType,U.PK_Country,F.[QSVolume],F.[QSVolumePercentage],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries,F.Bonus


		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 1;

		INSERT INTO #TimeLog VALUES ('#tmp_DSPointsSummary', 5, 2, GETUTCDATE(), NULL);

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
				 
		INSERT INTO #tmp_DSPointsSummary([PK_Event],PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,iSPQualDate,[QSVolume],[Countries])
		SELECT 
				@PK_Event AS PK_Event,
				P.PK_Distributor,
				P.RoyaltyMonth,
				P.MetricType,
				P.PK_Country,
				SUM(P.[Points]) AS [Points],
				P.QualificationNumber,
				P.Part,
				1 AS [Bonus],
				SUM(P.[Points]) AS [TotalPoints],
				P.iStartDate,
				P.iEndDate,
				iSPQualDate,
				[QSVolume],
				[Countries]
			FROM #Event_DSPoints_Summary AS P WITH (NOLOCK)
			LEFT JOIN #DS D ON P.PK_Distributor = D.PK_Distributor
			GROUP BY P.PK_Distributor,P.RoyaltyMonth,P.MetricType,P.PK_Country,P.QualificationNumber,P.Part,P.iStartDate,P.iEndDate,iSPQualDate,[QSVolume],[Countries]		

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 2;

		INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary]', 5, 3, GETUTCDATE(), NULL);

		IF @IsDevQA = 0
		BEGIN			
				
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
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 3;

		END
		ELSE IF @IsDevQA = 3
		BEGIN

			INSERT INTO ##DSPointsSummary_jgue(PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,[Countries])
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
				
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 3;

		END

	END	

	--Step 6: Uplines Qualifiers by volume
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

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 6 AND [StepSubGroup] = 1;

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
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 6 AND [StepSubGroup] = 1;
			END


			UPDATE #Executions
			SET Done = 1
			WHERE PK_Execution = @PK_Execution

			END
				
			INSERT INTO #TimeLog VALUES ('Qualifiers by volume #Event_DSQualPoints', 6, 2, GETUTCDATE(), NULL);
				
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
		WHERE [StepGroup] = 6 AND [StepSubGroup] = 2;
	END

	--Step 7: Qualifications
	IF @Step >= 7
	BEGIN
			
		PRINT 'Executing step 7'

		INSERT INTO #TimeLog VALUES ('Qualifications', 7, 1, GETUTCDATE(), NULL);

		INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01)
			SELECT 
				PK_Distributor,
				@PK_Event AS [PK_Event],
				IIF(d.DSSPTeam = 'SP',1,0)		AS Q01 -- FQS and Above
			FROM #DS AS d
			WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
		PRINT 'Qualifications end'
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
		PRINT 'ListsQualificationMapping end'
		------------------------------------------------------------------------------------------------
		-- SKUs qualifications
		------------------------------------------------------------------------------------------------
		PRINT '#SKUsQsMapping missing because this event does not have SKUs as qualifications end'
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

		PRINT '#QualificationsMapping end'
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 7 AND [StepSubGroup] = 1;

	END
			
	--Step 8: Subevents
	IF @Step >= 8
	BEGIN

		PRINT 'Executing step 8'

		INSERT INTO #TimeLog VALUES ('#EventQual', 8, 1, GETUTCDATE(), NULL);
				
			UPDATE 
				#EventQual
			SET 
				Q03 = (Q30 | Q34 | Q38 | Q42 | Q46 | Q50 | Q54), 
				Q04 = (Q31 | Q35 | Q39 | Q43 | Q47 | Q51 | Q55),
				Q05 = (Q32 | Q36 | Q40 | Q44 | Q48 | Q52 | Q56),
				Q06 = (Q33 | Q37 | Q41 | Q45 | Q49 | Q53 | Q57)

			UPDATE 
				#EventQual
			SET
				E01 = (Q01 & (Q02 | (Q03 & Q04 & (Q05 | Q06)))), 
				E02 = (Q07),
				E03 = (Q08),
				E04 = (Q09),
				E05 = (Q10),
				E06 = (Q11),
				E07 = (Q12),
				E08 = (Q13),
				E09 = (Q14),
				E10 = (Q15),
				E11 = (Q16),
				E12 = (Q17),
				E13 = (Q18),
				E14 = (Q19),
				E15 = (Q20),
				E16 = (Q21),
				E17 = (Q22),
				E18 = (Q23),
				E19 = (Q24),
				E20 = (Q25)

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
								~Q46  & ~Q47 & ~Q48 & ~Q49 & ~Q50 &
								~Q51  & ~Q52 & ~Q53 & ~Q54 & ~Q55 &
								~Q56  & ~Q57 & ~Q58 & ~Q59 & ~Q60 
							)= 1

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 8 AND [StepSubGroup] = 1;

	END

	--Step 9: [Event].[DSQual]	
	IF @Step >= 9
	BEGIN
			
		PRINT 'Executing step 9';

		INSERT INTO #TimeLog VALUES ('[Event].[DSQual]', 9, 1, GETUTCDATE(), NULL);

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
				INNER JOIN #Locations AS l
					ON q.PK_Event = l.PK_Event

			CREATE INDEX [IX_Event_DSQual_PK_Event] ON [Event].[DSQual](PK_Event);
			CREATE INDEX [IX_Event_DSQual_PK_Distributor_PK_Event] ON [Event].[DSQual](PK_Distributor) INCLUDE(PK_Event);
		
		END
		ELSE IF @IsDevQA = 3
		BEGIN

			DROP TABLE IF EXISTS ##Event_DSQual_jgue 
	 
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
			INTO ##Event_DSQual_jgue
			FROM #EventQual AS q		

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
		 
	IF @IsDevQA = 0
	BEGIN

		IF OBJECT_ID('tempdb..#ListsQualificationMapping') IS NOT NULL
		BEGIN

			DROP TABLE IF EXISTS [tmp].[ListsQsMapping]
					 
			SELECT 25077 AS [ProjectID], QColumn,ListID
			INTO [tmp].[ListsQsMapping]
			FROM #ListsQualificationMapping

		END

		IF OBJECT_ID('tempdb..#SKUsQsMapping') IS NOT NULL
		BEGIN

			DROP TABLE IF EXISTS [tmp].[SKUsQsMapping]

			SELECT 25077 AS [ProjectID], QColumn,SKUCode
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