CREATE PROCEDURE [dbo].[usp_EventQual_MexicoRegionalVacation_2025]
	 @Parameters NVARCHAR(MAX)
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_MexicoRegionalVacation_2025

	USE:		

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000),
					@Parameters NVARCHAR(MAX) = N'{"pkEvent":198082,"teamFreezeDate":"2024-01-16","step":11,"currentDate":null,"isJulyDoubleBonusActive":1,"isOctoberDoubleBonusActive":0,"isNewDSBonusActive":1}'

			EXEC dbo.usp_EventQual_MexicoRegionalVacation_2025 
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


	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2023-11-13	alejandramed		Initial - BRD V1	
	1.0.1	2023-12-05	alejandramed		Bug 1313823: 25005 - FQS NT not qualifying to E1  
											Bug 1313857: 25005 - Missing Event lists
	1.0.2	2023-12-13	alejandramed		Bug 1315466: 25005 - DS List based (Q14) qualifying to E1 and E2 through different paths
	1.0.3	2023-12-21	alejandramed		Bug 1317498: 25005 - DS are not qualifying (Above PT Level)
	1.0.4	2024-01-17	alejandramed		Including execution with parameters from json.
	1.0.5	2024-09-10	alejandramed		User Story 1356383: 25005 - Mexico Regional Vacation 2025- BRD V2
	1.0.6	2024-10-02	alejandramed		Bug 1365766: 25005 (MX Regional) - VP are duplicated
	***********************************************************************************************************************************/
	
	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_amed') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetDSVolume_amed] is missing, create it manually' AS [Error]
	END

	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetQualifier_Points_amed') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetQualifier_Points_amed] is missing, create it manually' AS [Error]
	END

	IF @IsDevQA = 3 AND ( OBJECT_ID('tempdb.dbo.##DSQualPoints_amed') IS NULL OR 
		OBJECT_ID('tempdb.dbo.##tmp_DS_amed') IS NULL OR
		OBJECT_ID('tempdb.dbo.##Event_SetupEventQualification_amed') IS NULL OR
		OBJECT_ID('tempdb.dbo.##Event_DSPoints_amed') IS NULL OR
		OBJECT_ID('tempdb.dbo.##DSPointsSummary_amed') IS NULL)
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

	DECLARE @PK_Event INT, 
		@TeamFreezeDate DATE,
		@Step INT,
		@iCurrentDate INT, 
		@IsJulyDoubleBonusActive BIT, 
		@IsOctoberDoubleBonusActive BIT, 
		@IsNewDSBonusActive bit 


	-- Getting parameters values for json
		SELECT 
			@PK_Event = pkEvent, 
			@TeamFreezeDate = teamFreezeDate,
			@Step = step,
			@iCurrentDate =  LEFT( CAST(CONVERT(varchar(6),currentDate, 112) AS int),6),
			@IsJulyDoubleBonusActive = isJulyDoubleBonusActive,
			@IsOctoberDoubleBonusActive = isOctoberDoubleBonusActive,
			@IsNewDSBonusActive = isNewDSBonusActive
		FROM OPENJSON(@Parameters)
		WITH (
				pkEvent INT '$.pkEvent',
				teamFreezeDate DATE '$.teamFreezeDate',
				step INT '$.step',
				currentDate datetime '$.currentDate',
				isJulyDoubleBonusActive BIT '$.isJulyDoubleBonusActive',
				isOctoberDoubleBonusActive BIT '$.isOctoberDoubleBonusActive',
				isNewDSBonusActive BIT '$.isNewDSBonusActive'
			)
	 
		-- Default values
		SET @PK_Event = IIF(@PK_Event IS NULL,198082, @PK_Event)
		SET @TeamFreezeDate = IIF(@TeamFreezeDate IS NULL,'2024-01-16', @TeamFreezeDate)
		SET @Step = IIF(@Step IS NULL,11, @Step)
		SET @iCurrentDate = IIF(@iCurrentDate IS NULL, LEFT( CAST(CONVERT(varchar(6),GETUTCDATE(), 112) AS int),6), @iCurrentDate)
		SET @IsJulyDoubleBonusActive = IIF(@IsJulyDoubleBonusActive IS NULL,1, @IsJulyDoubleBonusActive)
		SET @IsOctoberDoubleBonusActive = IIF(@IsOctoberDoubleBonusActive IS NULL,1, @IsOctoberDoubleBonusActive)
		SET @IsNewDSBonusActive = IIF(@IsNewDSBonusActive IS NULL,1, @IsNewDSBonusActive)

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
			@QualPeriodAStart DATE = '2024-01-01'
			,@QualPeriodAEnd DATE = '2024-12-01'		
		
		--Bonus is applicable to Q6,Q7,Q8,Q9,Q10,Q11,Q12,Q13

		DECLARE 
			@BonusApplicableFrom INT = 6,
			@BonusApplicableTo INT = 13

		--Q6	Accumulate 65,000 Vacation Points during qual period with a minimum of 30,000 TVP (Jan 2024 - Dec 2024) and a minimum of 6,000 ROs (Jan 2024 - Dec 2024)
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
			65000				AS [GoalPoints], 
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
			6000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q7	Accumulate 100,000 Vacation Points during qual period with a minimum of 36,000 TVP (Jan 2024 - Dec 2024) and a minimum of 9,000 ROs (Jan 2024 - Dec 2024)
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

		--Q8	Accumulate 140,000 Vacation Points during qual period with a minimum of 40,000 TVP (Jan 2024 - Dec 2024) and a minimum of 36,000 ROs (Jan 2024 - Dec 2024)
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

		--Q9	Accumulate 200,000 Vacation Points during qual period with a minimum of 50,000 TVP (Jan 2024 - Dec 2024) and a minimum of 72,000 ROs (Jan 2024 - Dec 2024)
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

		--Q10	Accumulate 115,000 Vacation Points during qual period with a minimum of 30,000 TVP (Jan 2024 - Dec 2024) and a minimum of 6,000 ROs (Jan 2024 - Dec 2024)
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
			115000				AS [GoalPoints], 
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
			6000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q11	Accumulate 150,000 Vacation Points during qual period with a minimum of 36,000 TVP (Jan 2024 - Dec 2024) and a minimum of 9,000 ROs (Jan 2024 - Dec 2024)
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

		--Q12	Accumulate 190,000 Vacation Points during qual period with a minimum of 40,000 TVP (Jan 2024 - Dec 2024) and a minimum of 36,000 ROs (Jan 2024 - Dec 2024)
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
		
		--Q13	Accumulate 250,000 Vacation Points during qual period with a minimum of 50,000 TVP (Jan 2024 - Dec 2024) and a minimum of 72,000 ROs (Jan 2024 - Dec 2024)
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
			'PPV_MPCV'				AS [MetricType], 
			'2024-08-01'	AS [dStartDate], 
			'2024-08-01'		AS [dEndDate], 
			1					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			250				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			'PPV,MPCV'				AS [MetricTypeDefinition]

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

			DELETE s FROM ##Event_SetupEventQualification_amed AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
			INSERT INTO ##Event_SetupEventQualification_amed(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition
			FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event

		END
		
		DECLARE @ColumnToPivot NVARCHAR(MAX),
			@SqlStatement NVARCHAR(MAX)

		DECLARE @QualificationListFactor INT = 13, --Diff between column ID and QId 
				@QualificationSKUFactor INT = NULL

		DECLARE 
			@Countries VARCHAR(MAX) = 'MX',
			@ListsIDs VARCHAR(MAX) = '57904,57905,57906'
	
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
					INNER JOIN #Countries AS C
						ON D.nDistributorCountryProcessingID = C.nCountryID
				
				WHERE        
					D.StatusCode = 'COMPLETE'        
					AND D.sType = 'SP'
	 
				CREATE INDEX IX_#DS_PK_Distributor ON #DS(PK_Distributor);

			-- If MB becomes New SP during the year, he won't be elegible to qualify. 

			IF GETUTCDATE() < @TeamFreezeDate OR @TeamFreezeDate IS NULL
			BEGIN
				
				DROP TABLE IF EXISTS [dbo].[WRK_25005_DSDetails]

				SELECT PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,		
					CountryCode,
					CAST(0 AS BIT) [IsFromList],
					CAST(0 AS BIT) [IsTicketPurchaser],	
					1 [Status] -- 1 General, 2 List, 3 Ticket
				INTO [dbo].[WRK_25005_DSDetails]
				FROM #DS

			END

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

				MERGE [dbo].[WRK_25005_DSDetails] AS T
				USING (SELECT * FROM #DS WHERE IsFromList = 1)  AS S
				ON S.PK_Distributor = T.PK_Distributor    
				-- Inserts
				WHEN NOT MATCHED BY Target THEN
					INSERT (PK_Distributor,	DSCurrentTeam,DSSubTeam,DSSPTeam,dSPQualDate,CountryCode,IsFromList, [Status]) 
					VALUES (S.PK_Distributor, S.DSCurrentTeam, S.DSSubTeam, S.DSSPTeam, S.dSPQualDate, S.CountryCode, S.IsFromList, 2)    
				-- Updates
				WHEN MATCHED THEN UPDATE SET
					T.IsFromList = S.IsFromList;


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

				MERGE [dbo].[WRK_25005_DSDetails] AS T
				USING (SELECT * FROM #DS WHERE IsTicketPurchaser = 1)  AS S
				ON S.PK_Distributor = T.PK_Distributor    
				-- Inserts
				WHEN NOT MATCHED BY Target THEN
					INSERT (PK_Distributor,	DSCurrentTeam,DSSubTeam,DSSPTeam,dSPQualDate,CountryCode,IsFromList, [Status]) 
					VALUES (S.PK_Distributor, S.DSCurrentTeam, S.DSSubTeam, S.DSSPTeam, S.dSPQualDate, S.CountryCode, S.IsFromList, 3)    
				-- Updates
				WHEN MATCHED THEN UPDATE SET
					T.IsTicketPurchaser = S.IsTicketPurchaser;


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
	
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 1;

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
						Dd.sDistributorID AS DistributorID,
						@iStartDate AS [iStartDate],
						@iEndDate AS [iEndDate],
						@dStartDate AS [dStartDate],
						@dEndDate AS [dEndDate],
						DD.dSupervisorQualification 
					FROM [dbo].[WRK_25005_DSDetails] AS D WITH (NOLOCK) 
					INNER JOIN v_Distributor AS DD
						ON D.PK_Distributor = DD.nDistributorID

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
						RETURN;
					END

					--Output
					--##Event_DSPoints_amed
 
		
					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;
		
				END
			
			------------------------------------------------------------------------------------------------
			-- 3.5 Getting #Event_DSPoints AND #Event_DSPoints_Validations
			------------------------------------------------------------------------------------------------
		
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints', 3, 5, GETUTCDATE(), NULL);

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
					FROM ##Event_DSPoints_amed

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

				INSERT INTO #Event_DSPoints_Validations([PK_Event],PK_Distributor, PK_Country, RoyaltyMonth, MetricType, [Points])	
				SELECT  
					P.[PK_Event],
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					'VP' AS MetricType,
					SUM(IIF(Points < 0 ,0 , [Points])) AS [Points]
				FROM #Event_DSPoints AS P 
					INNER JOIN [dbo].[WRK_25005_DSDetails] AS D WITH (NOLOCK) 
						ON P.PK_Distributor = D.PK_Distributor
				WHERE P.MetricType IN ('TV','RO')				 
				GROUP BY P.[PK_Event],P.PK_Distributor,P.PK_Country,P.RoyaltyMonth				
				UNION
				SELECT  
					p.[PK_Event],
					P.PK_Distributor,
					P.PK_Country,
					P.RoyaltyMonth, 
					P.MetricType,
					P.[Points]
				FROM #Event_DSPoints AS P 
					INNER JOIN [dbo].[WRK_25005_DSDetails] AS D WITH (NOLOCK) 
						ON P.PK_Distributor = D.PK_Distributor		  	

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
						FROM [dbo].[WRK_25005_DSDetails] AS D WITH (NOLOCK) 					
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
					FROM [dbo].[WRK_25005_DSDetails] AS DS  WITH (NOLOCK) --Uplines from Mexico
						INNER JOIN dbo.v_dimDSLngDownline AS DL
							ON DS.PK_Distributor = DL.PK_Distributor
						INNER JOIN v_Distributor AS DD
						ON DL.PK_DSDownline = DD.nDistributorID 
					WHERE DL.DSLevelFromUL = 2  AND DD.sDistributorCountryProcessingCode = 'MX'
									
				DROP TABLE IF EXISTS #DSAssociatedDownlines

					SELECT  DA.PK_Distributor,
							DA.PK_AssociatedID,
							DL.PK_DSDownLine 
					INTO #DSAssociatedDownlines
					FROM [dbo].[WRK_25005_DSDetails] AS D  WITH (NOLOCK) --Uplines from Mexico
					INNER JOIN [Shared].[DistributorAssociation] AS DA WITH (NOLOCK)
						ON D.PK_Distributor = DA.PK_Distributor
					INNER JOIN dbo.v_dimDSLngDownline AS DL
						ON DA.PK_AssociatedID = DL.PK_Distributor
					INNER JOIN v_Distributor AS DD
						ON DL.PK_DSDownline = DD.nDistributorID 
					WHERE DL.DSLevelFromUL = 2  AND DD.sDistributorCountryProcessingCode = 'MX'

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

				EXEC [dbo].[##usp_GetDSConversionDates_amed] @PK_Event = @PK_Event, @IsDevQA = @IsDevQA, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
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

			INSERT INTO #TimeLog VALUES ('#DownlineApplicationDateEval', 5, 212, GETUTCDATE(), NULL);

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
				DROP TABLE IF EXISTS [dbo].[WRK_25005_DownlineApplicationDate]

				SELECT DISTINCT PK_Distributor
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
				INTO [dbo].[WRK_25005_DownlineApplicationDate]
				FROM #DownlineApplicationDate
			END

			DROP TABLE IF EXISTS #DownlineApplicationDateEval

			SELECT DISTINCT PK_Distributor
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
			INTO #DownlineApplicationDateEval
			FROM #DownlineApplicationDate   
			WHERE ApplicationDate = 202408 --Application or conversion date AUGUST 2024. 
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 212;

			INSERT INTO #TimeLog VALUES ('WRK_25005_DSDownlines', 5, 213, GETUTCDATE(), NULL);

			--// Freezing DS status, regardless of the conversion during the month, the status will be updated only on the first day of the month.
			IF @IsDevQA = 0
			BEGIN

				IF OBJECT_ID (N'WRK_25005_DSDownlines', N'U') IS NULL 
				BEGIN
					CREATE TABLE [dbo].[WRK_25005_DSDownlines]
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
					) 
				END

				MERGE [dbo].[WRK_25005_DSDownlines] AS T
					USING #DownlineApplicationDateEval	AS S
					ON S.PK_Distributor = T.PK_Distributor AND S.PK_DSDownLine = T.PK_DSDownLine  AND S.ApplicationDate = T.ApplicationDate 
					WHEN NOT MATCHED BY Target THEN
						INSERT (PK_Distributor
								,PK_DSDownLine 	 
								,PK_DSType
								,ConversionDate					  
								,initialAppDate
								,ApplicationDate
								,LatestConversionMonth
								,DSApplicationDate
								,MBApplicationDate) 
						VALUES (S.PK_Distributor
							,S.PK_DSDownLine 	 
							,S.PK_DSType
							,S.ConversionDate					  
							,S.initialAppDate
							,S.ApplicationDate
							,S.LatestConversionMonth
							,S.DSApplicationDate
							,S.MBApplicationDate )    
					WHEN MATCHED 
						THEN UPDATE SET
						 T.PK_DSType				= S.PK_DSType
						,T.ConversionDate			= S.ConversionDate					  
						,T.initialAppDate			= S.initialAppDate
						,T.ApplicationDate			= S.ApplicationDate
						,T.LatestConversionMonth	= S.LatestConversionMonth
						,T.DSApplicationDate		= S.DSApplicationDate
						,T.MBApplicationDate 		= S.MBApplicationDate 
					;
					
			END
			ELSE IF @IsDevQA = 3
			BEGIN

				
				IF OBJECT_ID('tempdb.dbo.##WRK_25005_DSDownlines') IS NULL 
				BEGIN			 

					CREATE TABLE [dbo].[##WRK_25005_DSDownlines]
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
					)

				END

				 MERGE [dbo].[##WRK_25005_DSDownlines] AS T
					USING #DownlineApplicationDateEval	AS S
					ON S.PK_Distributor = T.PK_Distributor AND S.PK_DSDownLine = T.PK_DSDownLine  AND S.ApplicationDate = T.ApplicationDate 
					WHEN NOT MATCHED BY Target THEN
						INSERT (PK_Distributor
								,PK_DSDownLine 	 
								,PK_DSType
								,ConversionDate					  
								,initialAppDate
								,ApplicationDate
								,LatestConversionMonth
								,DSApplicationDate
								,MBApplicationDate) 
						VALUES (S.PK_Distributor
							,S.PK_DSDownLine 	 
							,S.PK_DSType
							,S.ConversionDate					  
							,S.initialAppDate
							,S.ApplicationDate
							,S.LatestConversionMonth
							,S.DSApplicationDate
							,S.MBApplicationDate )    
					WHEN MATCHED 
						THEN UPDATE SET
						 T.PK_DSType				= S.PK_DSType
						,T.ConversionDate			= S.ConversionDate					  
						,T.initialAppDate			= S.initialAppDate
						,T.ApplicationDate			= S.ApplicationDate
						,T.LatestConversionMonth	= S.LatestConversionMonth
						,T.DSApplicationDate		= S.DSApplicationDate
						,T.MBApplicationDate 		= S.MBApplicationDate 
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
				WHERE QualificationNumber = 50
	
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
						SELECT 
							@PK_Event AS [PK_Event],
							D.PK_DSDownLine AS PK_Distributor,
							DD.DistributorID,
							@iStartDate AS [iStartDate],
							@iEndDate AS [iEndDate],
							@dStartDate AS [dStartDate],
							@dEndDate AS [dEndDate],
							CASE WHEN DD.SPQualDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DD.SPQualDate),112) END, 
							D.PK_DSType -- Frezee type
						FROM [dbo].[WRK_25005_DSDownlines] AS D WITH (NOLOCK)
						INNER JOIN [PubEvents].[dbo].dimDistributor AS DD WITH (NOLOCK)
							ON D.PK_DSDownLine = DD.PK_Distributor

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
							D.PK_DSType -- Frezee type
						FROM [dbo].[##WRK_25005_DSDownlines] AS D
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
						
						DROP INDEX IF EXISTS [IX_##tmp_DS_amed_PK_Distributor]
							ON ##tmp_DS_amed;

						DELETE d FROM ##tmp_DS_amed AS d WHERE d.PK_Event = @PK_Event  

						INSERT INTO ##tmp_DS_amed([PK_Event],[PK_Distributor],[StartDate],[EndDate],[PK_DSType])
						SELECT 
							D.[PK_Event],
							D.PK_Distributor,
							D.[iStartDate],
							D.[iEndDate],
							D.[PK_DSType]
						FROM #tmp_DS AS D 
											 
						CREATE INDEX IX_##tmp_DS_amed_PK_Distributor ON ##tmp_DS_amed(PK_Distributor) INCLUDE(PK_Event);

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
				WHERE [StepGroup] = 5 AND [StepSubGroup] = 4;
		
			END
			ELSE
			IF (@IsDevQA = 3) AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_amed') IS NOT NULL
			BEGIN
					 
				INSERT INTO #TimeLog VALUES ('##usp_GetDSVolume_amed', 5, 4, GETUTCDATE(), NULL);

				--Input
				--##tmp_DS_amed
				--##Event_SetupEventQualification_amed
				--IF @EnableConversionDates = 1 ##tmp_MemberLastestConversion

				EXEC [dbo].[##usp_GetDSVolume_amed] @PK_Event = @PK_Event, @SourceType = 1,@QualFilter = '50', @EnableConversionDates = 1,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
				IF @Error <> 0
				BEGIN
					SET @Error = @Error
					SET @ErrorMessage = @ErrorMessage

					SELECT @ErrorMessage
					RETURN;
				END

				--Output
				--##Event_DSPoints_amed
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
					FROM ##Event_DSPoints_amed

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
					ApplicationDate AS EndMonth 
				FROM [dbo].[WRK_25005_DSDownlines] AS D WITH (NOLOCK)
				WHERE ApplicationDate = 202408 --Application or conversion date AUGUST 2024. 
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
					ApplicationDate AS EndMonth 
				FROM [dbo].[##WRK_25005_DSDownlines] AS D
				WHERE ApplicationDate = 202408 --Application or conversion date AUGUST 2024. 
			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 6;
					 		
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
			-- * OCTOBER DOUBLE VOLUME PROMOTION

			--All FQS and above can double their volume earned in OCTOBER up to 2,500 Bonus Points  
			--QS volume does not apply toward the bonus.
			-- Freeze contributor(s)
			-- Applicable towards the ACCUMULATED VACATION POINTS NOT towards the accumulated Personal TVP or RO.
			-- See Rules Bonus Example Page
			------------------------------------------------------------------------------------------------

			DROP TABLE IF EXISTS #JulyOctoberDoubleVolumePromotion

			;WITH cte_FQS AS
			(
				SELECT DISTINCT PK_Distributor,CAST(CONVERT(VARCHAR(6),dSPQualDate,112) AS INT)  AS iSPQualDate
				FROM [dbo].[WRK_25005_DSDetails] AS D WITH (NOLOCK) WHERE DSSPTeam = 'SP'
			),
			cte_JulyOctoberDoubleVolumePromotion AS
			(

			SELECT 
				d.PK_Distributor,
				d.iSPQualDate,
			IIF(p.RoyaltyMonth = 202407,
					IIF(RoyaltyMonth < d.iSPQualDate,0,
						IIF(Points >= 2500, 2500, Points)),0) AS [JULY DOUBLE VOLUME PROMOTION],	
				IIF(p.RoyaltyMonth = 202410,
					IIF(RoyaltyMonth < d.iSPQualDate,0,
						IIF(Points >= 2500, 2500, Points)),0) AS [OCTOBER DOUBLE VOLUME PROMOTION]	 
			FROM cte_FQS AS d
				INNER JOIN #Event_DSPoints_Validations AS p
					ON d.PK_Distributor = p.PK_Distributor 
						AND p.RoyaltyMonth IN(202407,202410) 
						AND p.MetricType = 'VP'
			)

			SELECT 
				d.PK_Distributor,
				d.iSPQualDate,
			SUM([JULY DOUBLE VOLUME PROMOTION]) AS 	[JULY DOUBLE VOLUME PROMOTION],
			SUM([OCTOBER DOUBLE VOLUME PROMOTION]) AS [OCTOBER DOUBLE VOLUME PROMOTION]		
			INTO #JulyOctoberDoubleVolumePromotion
			FROM cte_JulyOctoberDoubleVolumePromotion AS d 
			GROUP BY d.PK_Distributor,d.iSPQualDate
		 
		 	-- This bonus are assigned below on #WRK_25005_BonusPoints

		 ------------------------------------------------------------------------------------------------
			-- * AUGUST NEW DISTRIBUTOR BONUS

			-- Earn 2000 Bonus Points for each Personally Sponsored DS Downline WW with AUGUST application date or conversion date, including converted from preferred members/preferred customers.
			-- DS Must be COP: MX (Mexico) ONLY  
			-- Must be 1st line Distributor Personally Sponsored (DS Level)
			-- Application date or Converstion in AUGUST 2024 
			-- Purchase a minimum of 250 PPV or MPCV or combination of both (PPV + MPCV) from their most recent application or conversion date AUGUST 2024. 
			-- Freeze contributor(s)
			-- Applicable towards the ACCUMULATED VACATION POINTS NOT towards the accumulated Personal TVP or RO.
		------------------------------------------------------------------------------------------------

			INSERT INTO #TimeLog VALUES ('New DS Bonus', 5, 71, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #NewDSSSummary

			CREATE TABLE #NewDSSSummary
			(
				PK_Distributor INT,
				[TotalNewDS] INT,
				[TotalBonusNewDS] MONEY
			)
			 

			IF @IsDevQA = 0 AND OBJECT_ID (N'WRK_25005_NewDSBonusContributors', N'U') IS NULL  
			BEGIN
				CREATE TABLE [dbo].[WRK_25005_NewDSBonusContributors] 
				(
					[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
					PK_Distributor BIGINT,
					PK_DSDownLine  BIGINT,
					ApplicationDate INT,
					[Active] BIT DEFAULT 1
				)
			END
			ELSE
			IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##WRK_25005_NewDSBonusContributors') IS NULL 
			BEGIN
				CREATE TABLE [dbo].[##WRK_25005_NewDSBonusContributors] 
				(
					[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
					PK_Distributor BIGINT,
					PK_DSDownLine  BIGINT,
					ApplicationDate INT,
					[Active] BIT DEFAULT 1
				)
			END
			
			--// Getting contributors
			DROP TABLE IF EXISTS #NewDS
				
			SELECT d.PK_Distributor, d.PK_DSDownline,d.ApplicationDate 
			INTO #NewDS
			FROM #DownlinesPeriod AS d
			INNER JOIN #Event_DownlinesPoints AS p
				ON d.PK_DSDownline = p.PK_Distributor  AND p.RoyaltyMonth BETWEEN d.StartMonth AND d.EndMonth
			WHERE d.PK_DSType IN (5,4) AND p.MetricType IN ('PPV', 'MPCV')
			GROUP BY d.PK_Distributor, d.PK_DSDownline,d.ApplicationDate
			HAVING SUM(Points) >= 250
				
			--// Freezing contributors
			IF @IsDevQA = 0
			BEGIN
							
				MERGE [dbo].[WRK_25005_NewDSBonusContributors] AS t
				USING #NewDS AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine,ApplicationDate)
							VALUES (s.PK_Distributor, s.PK_DSDownLine,s.ApplicationDate)
				WHEN NOT MATCHED BY SOURCE AND t.ApplicationDate = @iCurrentDate
					THEN UPDATE SET 
						t.Active = 0 ; 
	 
				INSERT INTO #NewDSSSummary(PK_Distributor,[TotalNewDS],[TotalBonusNewDS])
				SELECT 
					F.PK_Distributor,
					COUNT(1) AS [TotalNewDS],
					(COUNT(1) * 2000) AS [TotalBonusNewDS]
				FROM [dbo].[WRK_25005_NewDSBonusContributors] AS F WITH (NOLOCK) 
				WHERE Active = 1
				GROUP BY F.PK_Distributor
				 
			END
			ELSE IF @IsDevQA = 3
			BEGIN
							
				MERGE [dbo].[##WRK_25005_NewDSBonusContributors] AS t
				USING #NewDS AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine,ApplicationDate)
							VALUES (s.PK_Distributor, s.PK_DSDownLine,s.ApplicationDate)
				WHEN NOT MATCHED BY SOURCE AND t.ApplicationDate = @iCurrentDate
					THEN UPDATE SET 
						t.Active = 0; 
	 
				INSERT INTO #NewDSSSummary(PK_Distributor,[TotalNewDS],[TotalBonusNewDS])
				SELECT 
					F.PK_Distributor,
					COUNT(1) AS [TotalNewDS],
					(COUNT(1) * 2000) AS [TotalBonusNewDS]
				FROM [dbo].[##WRK_25005_NewDSBonusContributors]  AS F WITH (NOLOCK)  WHERE Active = 1
				GROUP BY F.PK_Distributor
				 
			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 71;

			------------------------------------------------------------------------------------------------
			-- 5.4 Assigning bonuses
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('#WRK_25005_BonusSummary', 5, 42, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #WRK_25005_BonusSummary

				SELECT 
					D.PK_Distributor,
					ISNULL(DS.[TotalBonusNewDS],0) AS [New DS Bonus],
					ISNULL(DS.[TotalNewDS],0) AS [TotalNewDS],
					ISNULL(db.[JULY DOUBLE VOLUME PROMOTION],0) AS [JULY DOUBLE VOLUME PROMOTION],
					ISNULL(db.[OCTOBER DOUBLE VOLUME PROMOTION],0) AS [OCTOBER DOUBLE VOLUME PROMOTION]
				INTO #WRK_25005_BonusSummary
				FROM #DS AS D
					LEFT JOIN #NewDSSSummary AS DS  
						ON D.PK_Distributor = DS.PK_Distributor		
					LEFT JOIN #JulyOctoberDoubleVolumePromotion AS db
						ON D.PK_Distributor = db.PK_Distributor
					
			CREATE INDEX IX_#WRK_25005_BonusSummary_PK_Distributor ON #WRK_25005_BonusSummary(PK_Distributor)
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 42;

			IF @IsDevQA = 0
			BEGIN

				INSERT INTO #TimeLog VALUES ('WRK_25005_BonusSummary', 5, 41, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS [dbo].[WRK_25005_BonusSummary]

				SELECT 
					PK_Distributor,
					[New DS Bonus],
					[TotalNewDS],
					[JULY DOUBLE VOLUME PROMOTION],
					[OCTOBER DOUBLE VOLUME PROMOTION]
				INTO [dbo].[WRK_25005_BonusSummary]
				FROM #WRK_25005_BonusSummary 
								
			CREATE INDEX IX_WRK_25005_BonusSummary_PK_Distributor ON [dbo].[WRK_25005_BonusSummary](PK_Distributor)
				
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 41;
				
			END
			ELSE IF @IsDevQA = 3
			BEGIN

				INSERT INTO #TimeLog VALUES ('##WRK_25005_BonusSummary', 5, 41, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS [dbo].[##WRK_25005_BonusSummary]

				SELECT 
					PK_Distributor,
					[New DS Bonus],
					[TotalNewDS],
					[JULY DOUBLE VOLUME PROMOTION],
					[OCTOBER DOUBLE VOLUME PROMOTION]
				INTO [dbo].[##WRK_25005_BonusSummary]
				FROM #WRK_25005_BonusSummary 
											
			CREATE INDEX IX_##WRK_25005_BonusSummary_PK_Distributor ON [dbo].[##WRK_25005_BonusSummary](PK_Distributor)
				
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
					
			INSERT INTO #TimeLog VALUES ('#WRK_25005_BonusPoints', 5, 44, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #WRK_25005_BonusPoints

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
					IIF(@IsJulyDoubleBonusActive = 1 AND U.QualificationNumber BETWEEN @BonusApplicableFrom AND @BonusApplicableTo AND U.MetricType = 'VP' AND U.RoyaltyMonth = 202407, BS.[JULY DOUBLE VOLUME PROMOTION],0 ) AS [JULY DOUBLE VOLUME PROMOTION],
					IIF(@IsOctoberDoubleBonusActive = 1 AND U.QualificationNumber BETWEEN @BonusApplicableFrom AND @BonusApplicableTo AND U.MetricType = 'VP' AND U.RoyaltyMonth = 202410, BS.[OCTOBER DOUBLE VOLUME PROMOTION],0 ) AS [OCTOBER DOUBLE VOLUME PROMOTION],
					IIF(@IsNewDSBonusActive = 1 AND U.QualificationNumber BETWEEN @BonusApplicableFrom AND @BonusApplicableTo AND U.MetricType = 'VP' AND U.[monthNumber] = 1, ISNULL(BS.[New DS Bonus],0), 0) AS [New DS Bonus] 
				INTO #WRK_25005_BonusPoints
				FROM #Event_DSPoints_Summary AS U WITH (NOLOCK)
						LEFT JOIN #WRK_25005_BonusSummary AS BS 
							ON U.PK_Distributor = BS.PK_Distributor		
			

			CREATE INDEX IX_#WRK_25005_BonusPoints_PK_Distributor ON #WRK_25005_BonusPoints(PK_Distributor)
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 44;

			IF @IsDevQA = 0
			BEGIN
			
				INSERT INTO #TimeLog VALUES ('WRK_25005_BonusPoints', 5, 43, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS [dbo].[WRK_25005_BonusPoints]

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
						[OCTOBER DOUBLE VOLUME PROMOTION],
						[New DS Bonus]
					INTO [dbo].[WRK_25005_BonusPoints]
					FROM #WRK_25005_BonusPoints	

				CREATE INDEX IX_WRK_25005_BonusPoints_PK_Distributor ON [dbo].[WRK_25005_BonusPoints](PK_Distributor)

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
							(ISNULL(P.[JULY DOUBLE VOLUME PROMOTION],0) + ISNULL(P.[OCTOBER DOUBLE VOLUME PROMOTION],0)+ ISNULL(P.[New DS Bonus],0))  AS [Bonus],
							ISNULL(P.[Points],0) + (ISNULL(P.[JULY DOUBLE VOLUME PROMOTION],0) + ISNULL(P.[OCTOBER DOUBLE VOLUME PROMOTION],0)+ ISNULL(P.[New DS Bonus],0)) AS [TotalPoints],
							P.iStartDate,
							P.iEndDate
						FROM #WRK_25005_BonusPoints AS P WITH (NOLOCK)

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
			WHERE [StepGroup] = 6 AND [StepSubGroup] = 1;
		END

		--Step 7: Qualifications
		IF @Step >= 7
		BEGIN
			
			PRINT 'Executing step 7'

			INSERT INTO #TimeLog VALUES ('#EventQual', 7, 1, GETUTCDATE(), NULL);

			INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q03,Q04,Q05)
				SELECT 
					PK_Distributor,
					@PK_Event AS [PK_Event],
					IIF(d.DSCurrentTeam = 'SP' AND d.IsFromList = 0 ,1,0) AS Q01, -- Supervisor
					IIF(d.DSCurrentTeam = 'W'  AND d.IsFromList = 0,1,0) AS Q02, -- World Team Member
					IIF(d.DSCurrentTeam = 'G'  AND d.IsFromList = 0,1,0) AS Q03, -- Get Team Member
					IIF(d.DSCurrentTeam = 'M'  AND d.IsFromList = 0,1,0) AS Q04, -- Mill Team Member
					IIF(d.DSCurrentTeam IN ('P','A','B','C') AND d.IsFromList = 0,1,0) AS Q05 -- Press Team and Above
				FROM [dbo].[WRK_25005_DSDetails] AS D WITH (NOLOCK)  
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
					E01 = (((Q01 | Q02) & Q06) | (Q03 & Q07) | (Q04 & Q08) | ((Q05 | Q14) & Q09) | Q15) -- ((Q1 OR Q2) + Q6) OR ((Q3  + Q7) OR ((Q4  + Q8) OR ((Q5 OR Q14) + Q9) OR Q15

				UPDATE 
					#EventQual
				SET E02 = (((Q01 | Q02) & Q10) | (Q03 & Q11) | (Q04 & Q12) | ((Q05 | Q14) & Q13) | Q16) --((Q1 OR Q2) + 10) OR ((Q3 + Q11) OR ((Q4 + Q12) OR ((Q5 OR Q14) + Q13) OR Q16
										
 
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

				DROP TABLE IF EXISTS ##Event_DSQual_amed 
				 
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
			INTO ##Event_DSQual_amed
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