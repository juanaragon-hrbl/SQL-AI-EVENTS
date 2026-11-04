CREATE PROCEDURE [dbo].[usp_EventQual_SAMCAMExtravaganzaJun2025]
	@PK_Event INT = 203127,
	 @Parameters NVARCHAR(MAX)
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT
	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_SAMCAMExtravaganzaJun2025

	USE:		

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000),
					@Parameters NVARCHAR(MAX) = N'{
					"pkEvent":203127,
					"qual1Start":"2025-02-01",
					"qual1End":"2025-05-01",
					"qual2Start":"2025-03-01",
					"qual2End":"2025-06-01",
					"qual3Start":"2024-06-01",
					"qual3End":"2025-05-01",
					"dSqualDateStart":"2025-01-01",
					"dSqualDateEnd":"2025-05-01",
					"sPqualDateStart":"2025-02-01",
					"sPqualDateEnd":"2025-06-01",
					"qSActualQualDateStart":"2025-06-01",
					"qSActualQualDateEnd":"2025-06-30",
					"newWTQualDateStart":"2025-03-01",
					"newWTQualDateEnd":"2025-06-01",
					"step":11,
					"bonusApplicableFrom" : 9,
					"bonusApplicableTo" : 18,
					"countries" : "AR,NI,PM,UY,BL,CI,CO,CR,DR,EC,GT,HN,PE,PY,SV,VE,BR",
					"isFebruaryDoubleBonusActive":1,
					"isNewSPBonusActive":1,
					"newSPBonusDateStart":"2025-03-01",
					"newSPBonusDateEnd":"2025-06-01"
					}'

			EXEC dbo.usp_EventQual_SAMCAMExtravaganzaJun2025
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
	1.0.0	2025-03-26		juangue		Initial - BRD V1	
	1.0.1	2025-04-08		juangue		#1410752  Q39 E2 List
	1.0.2	2025-04-10		juangue		#1410839  Feb Bonus
	1.0.3	2025-04-22		juangue		#1411775 Double Bonus should not apply
	1.0.4	2025-04-22		juangue		#1411841 New SP Demoted and qualifies again
	1.0.5	2025-04-23		juangue		#1411932 New WT Feb , NEW SP Feb
	1.0.6	2025-04-23		juangue		#1411941 Q21 Downline 1
	1.0.7	2025-04-23		juangue		#1411932 New WT Feb , NEW SP Feb
	1.2.0	2025-04-24		juangue		BRD v1.2
	1.2.1	2025-04-28		juangue		#1411926 New WT Demoted Q20
	1.2.2   2025-04-29		juangue		#1412794  Q22 Downline 2 New SP AppValideDate
	1.2.3	2025-05-22		juangue		#1414841 New WT Qualifiers missing in Gala Qualifications E3 + Q20
	1.2.4	2025-05-26		juangue		#1415251 Downline duplicates
	1.2.5	2025-06-09		juangue		#1417146 COP Bolivia wrong country code
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
		@Qual1Start DATETIME,
		@Qual1End DATETIME,
		@Qual2Start DATETIME,
		@Qual2End DATETIME,
		@Qual3Start DATETIME,
		@Qual3End DATETIME,
		@DSQualDateStart DATE,
		@DSQualDateEnd DATE,
		@SPQualDateStart DATE,
		@SPQualDateEnd DATE,
		@NewSPBonusDateStart DATE,
		@NewSPBonusDateEnd DATE,
		@NewWTQualDateStart DATETIME,
		@NewWTQualDateEnd DATETIME,
		@QSActualQualDateStart DATE,
		@QSActualQualDateEnd DATE,
		@Step INT,
		@BonusApplicableFrom INT,
		@BonusApplicableTo INT,
		@Countries VARCHAR(MAX),

		@iCurrentDate INT, 
		@IsFebruaryDoubleBonusActive BIT, 
		@IsNewSPBonusActive bit

	-- Getting parameters values for json
		SELECT 
			@PK_Event = g.pkEvent, 
			@Qual1Start = g.qual1Start,
			@Qual1End = g.qual1End,
			@Qual2Start = g.qual2Start,
			@Qual2End = g.qual2End,
			@Qual3Start = g.qual3Start,
			@Qual3End = g.qual3End,
			@DSQualDateStart = g.dSqualDateStart,
			@DSQualDateEnd = g.dSqualDateEnd,
			@SPQualDateStart = g.sPqualDateStart,
			@SPQualDateEnd = g.sPqualDateEnd,
			@NewWTQualDateStart = g.newWTQualDateStart,
			@NewWTQualDateEnd = g.newWTQualDateEnd,
			@QSActualQualDateStart = G.qSActualQualDateStart,
			@QSActualQualDateEnd = G.qSActualQualDateEnd,
			@IsNewSPBonusActive = g.isNewSPBonusActive,
			@Step = g.step,
			@BonusApplicableFrom = g.bonusApplicableFrom,
			@BonusApplicableTo = g.bonusApplicableTo,
			@Countries = g.countries,
			@iCurrentDate =  LEFT( CAST(CONVERT(varchar(6),g.currentDate, 112) AS int),6),
			@IsFebruaryDoubleBonusActive = g.isFebruaryDoubleBonusActive,
			@NewSPBonusDateStart = g.newSPBonusDateStart,
			@NewSPBonusDateEnd = g.newSPBonusDateEnd 

		FROM OPENJSON(@Parameters)
		WITH (
				pkEvent INT '$.pkEvent',
				qual1Start DATE '$.qual1Start',
				qual1End DATE '$.qual1End',
				qual2Start DATE '$.qual2Start',
				qual2End DATE '$.qual2End',
				qual3Start DATE '$.qual3Start',
				qual3End DATE '$.qual3End',
				dSQualDateStart DATE '$.dSqualDateStart',
				dSqualDateEnd DATE '$.dSqualDateEnd',
				sPQualDateStart DATE '$.sPqualDateStart',
				sPqualDateEnd DATE '$.sPqualDateEnd',
				newWTQualDateStart DATETIME '$.newWTQualDateStart',
				newWTqualDateEnd DATETIME '$.newWTQualDateEnd',
				qSActualQualDateStart DATE '$.qSActualQualDateStart',
				qSActualQualDateEnd DATE '$.qSActualQualDateEnd',
				step INT '$.step',
				bonusApplicableFrom INT '$.bonusApplicableFrom',
				bonusApplicableTo INT '$.bonusApplicableTo',
				countries VARCHAR(MAX) '$.countries',
				
				currentDate datetime '$.currentDate',
				convertionsAllowed BIT '$.convertionsAllowed',
				isNewSPBonusActive BIT '$.isNewSPBonusActive',
				isFebruaryDoubleBonusActive BIT '$.isFebruaryDoubleBonusActive',
				newSPBonusDateStart DATE '$.newSPBonusDateStart',
				newSPBonusDateEnd DATE '$.newSPBonusDateEnd'
			) AS g
	 
		-- Default values
		SET @PK_Event = IIF(@PK_Event IS NULL,203127, @PK_Event)
		SET @Qual1Start = IIF(@Qual1Start IS NULL,'2025-02-01', @Qual1Start)
		SET @Qual1End = IIF(@Qual1End IS NULL,'2025-05-01', @Qual1End)
		SET @Qual2Start = IIF(@Qual2Start IS NULL,'2025-03-01', @Qual2Start)
		SET @Qual2End = IIF(@Qual2End IS NULL,'2025-06-01', @Qual2End)
		SET @Qual3Start = IIF(@Qual3Start IS NULL,'2024-06-01', @Qual3Start)
		SET @Qual3End = IIF(@Qual3End IS NULL,'2025-05-01', @Qual3End)
		SET @DSQualDateStart = IIF(@DSQualDateStart IS NULL, '2025-01-01', @DSQualDateStart)
		SET @DSQualDateEnd = IIF(@DSQualDateEnd IS NULL, '2025-05-01', @DSQualDateEnd)
		SET @BonusApplicableFrom = IIF(@BonusApplicableFrom IS NULL, 9, @BonusApplicableFrom)
		SET @BonusApplicableTo = IIF(@BonusApplicableTo IS NULL, 18, @BonusApplicableTo)
		SET @Countries = IIF(@Countries IS NULL, 'AR,NI,PM,UY,BL,CI,CO,CR,DR,EC,GT,HN,PE,PY,SV,VE,BR', @Countries)
		SET @SPQualDateStart = IIF(@SPQualDateStart IS NULL, '2025-02-01', @SPQualDateStart)
		SET @SPQualDateEnd = IIF(@SPQualDateEnd IS NULL, '2025-06-01', @SPQualDateEnd)
		SET @NewWTQualDateStart = IIF(@NewWTQualDateStart IS NULL, '2025-03-01', @NewWTQualDateStart)
		SET @NewWTQualDateEnd = IIF(@NewWTQualDateEnd IS NULL, '2025-06-01', @NewWTQualDateEnd)

		SET @QSActualQualDateStart = IIF(@QSActualQualDateStart IS NULL, '2025-06-01', @QSActualQualDateStart)
		SET @QSActualQualDateEnd = IIF(@QSActualQualDateEnd IS NULL, '2025-06-30', @QSActualQualDateEnd)

		SET @Step = IIF(@Step IS NULL,11, @Step)
		SET @iCurrentDate = IIF(@iCurrentDate IS NULL, LEFT(CAST(CONVERT(varchar(6),GETUTCDATE(), 112) AS int),6), @iCurrentDate)
		SET @IsNewSPBonusActive = IIF(@IsNewSPBonusActive IS NULL, 1, @IsNewSPBonusActive)
		SET @IsFebruaryDoubleBonusActive = IIF(@IsFebruaryDoubleBonusActive IS NULL,1,@IsFebruaryDoubleBonusActive)
		SET @NewSPBonusDateStart = IIF(@NewSPBonusDateStart IS NULL, '2025-03-01', @NewSPBonusDateStart)
		SET @NewSPBonusDateEnd = IIF(@NewSPBonusDateEnd IS NULL, '2025-06-01', @NewSPBonusDateEnd)

		SELECT
			--Double bonus										 
			@PK_Event						AS [PK_Event],							
			@Step							AS [Step],								
			@Qual1Start						AS [Qual1Start],							
			@Qual1End						AS [Qual1End],							
			@Qual2Start						AS [Qual2Start],							
			@Qual2End						AS [Qual2End],							
			@Qual3Start						AS [Qual3Start],							 									 
			@DSQualDateStart 				AS [DSQualDateStart], 						
			@DSQualDateEnd 					AS [DSQualDateEnd], 							
			@BonusApplicableFrom			AS [BonusApplicableFrom],						
			@BonusApplicableTo				AS [BonusApplicableTo],							
			@Countries						AS [Countries],								
			@SPQualDateStart				AS [SPQualDateStart],							
			@SPQualDateEnd					AS [SPQualDateEnd],																		
			@NewWTQualDateStart				AS [NewWTQualDateStart],					
			@NewWTQualDateEnd				AS [NewWTQualDateEnd],							
			@iCurrentDate					AS [iCurrentDate],
			@IsFebruaryDoubleBonusActive	AS [IsFebruaryDoubleBonusActive],
			@IsNewSPBonusActive				AS [IsNewSPBonusActive],
			@QSActualQualDateStart			AS [QSActualQualDateStart],
			@QSActualQualDateEnd			AS [QSActualQualDateEnd],
			@NewSPBonusDateStart			AS [NewSPBonusDateStart],
			@NewSPBonusDateEnd				AS [NewSPBonusDateEnd]

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

		--Q5	Achieve 2,500 TVP each month in any three months (Feb 2025 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			5					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual1Start			AS [dStartDate], 
			@Qual1End			AS [dEndDate], 
			3					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			2500				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q6	Achieve 2,500 TVP each month in any three months (Mar 2025 - Jun 2025) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			6					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual2Start			AS [dStartDate], 
			@Qual2End			AS [dEndDate], 
			3					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			2500				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q7	Achieve 5,000 TVP any one month  (Feb 2025 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			7					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual1Start			AS [dStartDate], 
			@Qual1End			AS [dEndDate], 
			1					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			5000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q8	Achieve 5,000 TVP any one month (Mar 2025 - Jun 2025) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			8					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual2Start			AS [dStartDate], 
			@Qual2End			AS [dEndDate], 
			1					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			5000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q9	Accumulate 10,000 TVP in 4 months (Feb 2025 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			9					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual1Start			AS [dStartDate], 
			@Qual1End			AS [dEndDate], 
			4					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			10000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q10	Accumulate 10,000 TVP in 4 month (Mar 2025 - Jun 2025) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			10					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual2Start			AS [dStartDate], 
			@Qual2End			AS [dEndDate], 
			4					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			10000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q11	Accumulate 15 000 TVP in 4 month (Feb 2025 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			11					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual1Start			AS [dStartDate], 
			@Qual1End			AS [dEndDate], 
			4					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			15000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q12	Accumulate 15,000 TVP in 4 month (Mar 2025 - Jun 2025) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			12					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual2Start			AS [dStartDate], 
			@Qual2End			AS [dEndDate], 
			4					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			15000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q13	Accumulate 20,000 TVP in 4 month (Feb 2025 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			13					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual1Start			AS [dStartDate], 
			@Qual1End			AS [dEndDate], 
			4					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			20000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q14	Accumulate 20,000 TVP in 4 month (Mar 2025 - Jun 2025) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			14					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual2Start			AS [dStartDate], 
			@Qual2End			AS [dEndDate], 
			4					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			20000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q15	Accumulate 25,000 TVP in 4 month (Feb 2025 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			15					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual1Start			AS [dStartDate], 
			@Qual1End			AS [dEndDate], 
			4					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			25000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q16	Accumulate 25,000 TVP in 4 month (Mar 2025 - Jun 2025) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			16					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual2Start			AS [dStartDate], 
			@Qual2End			AS [dEndDate], 
			4					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			25000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q17	Accumulate 35,000 TVP in 4 month (Feb 2025 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			17					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual1Start			AS [dStartDate], 
			@Qual1End			AS [dEndDate], 
			4					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			35000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q18	Accumulate 35,000 TVP in 4 month (Mar 2025 - Jun 2025) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			18					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			@Qual2Start			AS [dStartDate], 
			@Qual2End			AS [dEndDate], 
			4					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			35000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q40	Achieve 1,000 ROs in any 1 Month  (June 2024 - May 2025)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			40					AS QualificationNumber,
			1					AS Part, 
			'RO'				AS [MetricType], 
			@Qual3Start			AS [dStartDate], 
			@Qual3End			AS [dEndDate], 
			1					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			1000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q42 ***** Purchase a minimum of 250 PPV or MPCV or combination of both (PPV + MPCV) from their Signup Month *****
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event						AS [PK_Event],
			42								AS QualificationNumber,
			1								AS Part, 
			'PPV,MPCV'						AS [MetricType], 
			@DSQualDateStart				AS [dStartDate], 
			DATEADD(MM,1,@DSQualDateEnd)	AS [dEndDate], 
			6								AS [Frequency], 
			0								AS [Consecutive], 
			1								AS [Accumulated], 
			0								AS [MinPoints], 
			250								AS [GoalPoints], 
			NULL							AS [Countries],
			0								AS [QSVolume], 
			2								AS [PeriodType], 
			NULL							AS [MetricTypeDefinition]	

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
	
		DROP TABLE IF EXISTS #ListsQsMapping

		CREATE TABLE #ListsQsMapping
		(
			ID INT IDENTITY(1,1),
			PK_Event INT,
			ListID INT,
			QId INT
		)

		INSERT INTO #ListsQsMapping(PK_Event,ListID,QId)
			VALUES 
				(@PK_Event, 63699,23),
				(@PK_Event, 63697,24),
				(@PK_Event, 63698,25),
				(@PK_Event, 63700,26),
				(@PK_Event, 63701,27),
				(@PK_Event, 63702,28),
				(@PK_Event, 63703,29),
				(@PK_Event, 63704,30),
				(@PK_Event, 63705,31),
				(@PK_Event, 63706,32),
				(@PK_Event, 63707,33),
				(@PK_Event, 63708,34),
				(@PK_Event, 63709,35),
				(@PK_Event, 63710,36),
				(@PK_Event, 63711,37),
				(@PK_Event, 63712,38),
				(@PK_Event, 63695,39),
				(@PK_Event, 65248,41)

		DROP TABLE IF EXISTS #SKUsQsMapping

		CREATE TABLE #SKUsQsMapping
		(
			ID INT IDENTITY(1,1),
			PK_Event INT,
			SKUCode VARCHAR(10),
			QId INT
		)

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
		SELECT @PK_Event,'SAMCAM'	 		 

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
					DSCurrentTeam		varchar(10),        
					DSSubTeam			varchar(10),        
					DSSPTeam			varchar(10),               
					dSPQualDate			datetime2,  
					dSPReQualDate		datetime2,  
					dSPDemotionDate		datetime2,  		
					CountryCode			varchar(5),
					IsFromList			bit default(0),
					IsTicketPurchaser	bit default(0),
					IsFromCOP			bit default(0),
					NewSPQualDate		datetime DEFAULT('1900-01-01'),
					NewWTQualDate		datetime DEFAULT('1900-01-01'),
					QSActualQualDate    smalldatetime DEFAULT('1900-01-01'),
					IsAWTQualifier		bit default(0)
				)

				INSERT INTO #DS
				(
					PK_Distributor,
					DistributorID,
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,
					dSPReQualDate,
					dSPDemotionDate,
					CountryCode,
					IsFromCOP,
					QSActualQualDate
				)

				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor, 
				D.sDistributorID AS DistributorID,	
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				ISNULL(D.dSupervisorqualification,'1900-01-01') AS dSPQualDate,     
				ISNULL(D.dSupervisorReQualification,'1900-01-01') AS dSPReQualDate, 
				ISNULL(D.dSPDemotion,'1900-01-01') AS dSPDemotionDate, 		
				D.sDistributorCountryProcessingCode AS CountryCode,
				1 AS IsFromCOP,
				D.dQSQualification_Actual
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
				l.PK_Event AS PK_Event,
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
				PK_Distributor
				,DistributorID
				,DSCurrentTeam
				,dSPQualDate
				,dSPReQualDate
				,dSPDemotionDate
				,CountryCode
				,DSSubTeam
				,DSSPTeam
				,IsFromList
				,QSActualQualDate
			)
			SELECT DISTINCT  
			D.nDistributorID AS PK_Distributor, 
			D.sDistributorID AS DistributorID,
			CASE WHEN D.sTeam IS NULL THEN CASE WHEN D.sType = 'DS' THEN D.sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam, 
			ISNULL(D.dSupervisorqualification,'1900-01-01') AS dSPQualDate,     
			ISNULL(D.dSupervisorReQualification,'1900-01-01') AS dSPReQualDate, 
			ISNULL(D.dSPDemotion,'1900-01-01') AS dSPDemotionDate, 	
			D.sDistributorCountryProcessingCode AS CountryCode,
			D.sSubTeam AS DSSubTeam,
			D.sType AS DSSPTeam,
			1 AS IsFromList,
			D.dQSQualification_Actual
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
			)

			INSERT INTO #SKUs(PK_Event,SKUCode)
			SELECT DISTINCT 
				l.PK_Event, 
				LTRIM(RTRIM(s.SKUCode))
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
				PK_Distributor
				,DistributorID
				,DSCurrentTeam
				,dSPQualDate
				,dSPReQualDate
				,dSPDemotionDate
				,CountryCode
				,DSSubTeam
				,DSSPTeam
				,IsTicketPurchaser
				,QSActualQualDate
			)
			SELECT DISTINCT       
			D.nDistributorID AS PK_Distributor, 
			D.sDistributorID AS DistributorID,
			CASE WHEN D.sTeam IS NULL THEN CASE WHEN D.sType = 'DS' THEN D.sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam, 
			ISNULL(D.dSupervisorqualification,'1900-01-01') AS dSPQualDate,     
			ISNULL(D.dSupervisorReQualification,'1900-01-01') AS dSPReQualDate, 
			ISNULL(D.dSPDemotion,'1900-01-01') AS dSPDemotionDate, 	
			D.sDistributorCountryProcessingCode AS CountryCode,
			D.sSubTeam AS DSSubTeam,
			D.sType AS DSSPTeam,
			1 AS IsTicketPurchaser,
			D.dQSQualification_Actual
			FROM dbo.v_Distributor AS D  
				INNER JOIN #DSSKUs AS S
					ON D.nDistributorID = S.PK_Distributor
			WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = S.PK_Distributor)

			UPDATE D
			SET IsTicketPurchaser = 1
			FROM #DS AS D  
				INNER JOIN #DSSKUs AS S
					ON D.PK_Distributor = S.PK_Distributor

			--NewFQS
			UPDATE D
			SET NewSPQualDate = IIF(D.dSPDemotionDate = '1900-01-01', 
									D.dSPQualDate, -- First time ever / never demoted
									IIF(D.dSPQualDate > D.dSPReQualDate,D.dSPQualDate,D.dSPReQualDate) -- If demoted then get the latest date between SPQualDate and SPReQualDate
								)
			FROM #DS AS D  
			WHERE DSSPTeam = 'SP'

			--New World Team (WT) 
			;WITH cte_WT AS 
			(
				SELECT 
					D.PK_Distributor,
					MIN(ROYALTYMONTH) AS ROYALTYMONTH
				FROM 
					PubEvents.dbo.DSSNAPSHOT DSNAP (NOLOCK)
				INNER JOIN 
					#DS AS D ON DSNAP.PK_DISTRIBUTOR = D.PK_Distributor  
				WHERE 
					SUBTYPECODE = 'WT'
				GROUP BY 
					D.PK_Distributor,D.dSPDemotionDate
				HAVING 
					(NOT EXISTS (SELECT 1 FROM PubEvents.dbo.DSSNAPSHOT DSNAP2 (NOLOCK) 
								  WHERE DSNAP2.PK_DISTRIBUTOR = D.PK_Distributor 
								  AND DSNAP2.SUBTYPECODE = 'WT'
								  AND DSNAP2.ROYALTYMONTH < CAST(CONVERT(varchar(6), @NewWTQualDateStart, 112) AS int))
					OR 
					(D.dSPDemotionDate != '1900-01-01' 
					 AND EXISTS (SELECT 1 FROM PubEvents.dbo.DSSNAPSHOT DSNAP2 (NOLOCK) 
								 WHERE DSNAP2.PK_DISTRIBUTOR = D.PK_Distributor 
								 AND DSNAP2.SUBTYPECODE = 'WT'
								 AND DSNAP2.ROYALTYMONTH BETWEEN CAST(CONVERT(varchar(6), D.dSPDemotionDate, 112) AS int) AND CAST(CONVERT(varchar(6), @NewWTQualDateStart, 112) AS int))
					)				
					OR 
					(D.dSPDemotionDate = '1900-01-01' 
					 AND EXISTS (SELECT 1 FROM PubEvents.dbo.DSSNAPSHOT DSNAP2 (NOLOCK) 
								 WHERE DSNAP2.PK_DISTRIBUTOR = D.PK_Distributor 
								 AND DSNAP2.SUBTYPECODE = 'WT'
								 AND DSNAP2.ROYALTYMONTH BETWEEN CAST(CONVERT(varchar(6), @NewWTQualDateStart, 112) AS int)  AND CAST(CONVERT(varchar(6), @NewWTQualDateEnd, 112) AS int))
					)
					)
			)

			UPDATE D
			SET NewWTQualDate = ISNULL(CONVERT(DATETIME,CONVERT(VARCHAR, DSNAP.ROYALTYMONTH) + '01',112),'1900-01-01') 
			FROM #DS AS D  
			LEFT JOIN cte_WT DSNAP (NOLOCK)
				ON DSNAP.PK_DISTRIBUTOR = D.PK_Distributor

			IF @IsDevQA =  0
			BEGIN

				DROP TABLE IF EXISTS [dbo].[WRK_25054_DSDetails]

				CREATE TABLE [dbo].[WRK_25054_DSDetails]
				(
					PK_Distributor		int,  
					DistributorID		varchar(30),
					DSCurrentTeam		varchar(10),        
					DSSubTeam			varchar(10),        
					DSSPTeam			varchar(10),               
					dSPQualDate			datetime2,
					dSPReQualDate		datetime2,  
					dSPDemotionDate		datetime2,  
					CountryCode			varchar(5),
					IsFromList			bit default(0),
					IsTicketPurchaser	bit default(0),
					IsFromCOP			bit default(0),
					NewSPQualDate		datetime DEFAULT('1900-01-01'),
					NewWTQualDate		datetime DEFAULT('1900-01-01'),
					QSActualQualDate    smalldatetime DEFAULT('1900-01-01'),
					IsAWTQualifier		bit default(0)
				)

				INSERT INTO [dbo].[WRK_25054_DSDetails](
					PK_Distributor,		
					DistributorID,		
					DSCurrentTeam,		     
					DSSubTeam,			     
					DSSPTeam,			            
					dSPQualDate,
					dSPReQualDate,
					dSPDemotionDate,
					CountryCode,			
					IsFromList,			
					IsTicketPurchaser,	
					IsFromCOP,			
					NewSPQualDate,		
					NewWTQualDate,		
					QSActualQualDate,    
					IsAWTQualifier)		

				SELECT 	PK_Distributor,		
					DistributorID,		
					DSCurrentTeam,		     
					DSSubTeam,			     
					DSSPTeam,			            
					dSPQualDate,
					dSPReQualDate,
					dSPDemotionDate,
					CountryCode,			
					IsFromList,			
					IsTicketPurchaser,	
					IsFromCOP,			
					NewSPQualDate,		
					NewWTQualDate,		
					QSActualQualDate,    
					IsAWTQualifier	
				FROM #DS

				CREATE INDEX IX_WRK_25054_DSDetails_PK_Distributor ON [dbo].[WRK_25054_DSDetails](PK_Distributor);

			END

			DROP TABLE IF EXISTS #DSDownlines

			SELECT 
				M.PK_Distributor,
				DL.PK_DSDownline [PK_FirstLine],
				'DS' AS [Type]
			INTO #DSDownlines
			FROM
				#DS M
			INNER JOIN
				dbo.v_dimDSLngDownline DL WITH (NOLOCK)
			ON
				M.PK_Distributor = DL.PK_Distributor
				AND 
				DL.DSLevelFromUL = 2
					
			UNION
				
			SELECT 
				M.PK_Distributor,
				DL.PK_DSDownline [PK_FirstLine],
				'SP' AS [Type]
			FROM
				#DS M
			INNER JOIN
				dbo.v_dimDSLngDownline DL WITH (NOLOCK)
			ON
				M.PK_Distributor = DL.PK_Distributor
				AND 
				DL.SPLevelFromUL = 2

			CREATE CLUSTERED INDEX [IX_#DSDownlines_PK_FirstLine] ON  dbo.[#DSDownlines] ([PK_FirstLine])

			DROP TABLE IF EXISTS #DSAssociatedDownlines

			SELECT DISTINCT
					DA.PK_Distributor,
					DA.PK_AssociatedID,
					DL.PK_DSDownLine,
					DA.nMainDistributorID,
					DA.AssociationType,
					'DS' AS [Type]
			INTO #DSAssociatedDownlines
			FROM #DS AS D --Uplines from COP
			INNER JOIN [Shared].[DistributorAssociation] AS DA WITH (NOLOCK)
				ON D.PK_Distributor = DA.PK_Distributor
			INNER JOIN dbo.v_dimDSLngDownline AS DL
				ON DA.PK_AssociatedID = DL.PK_Distributor
			WHERE DL.DSLevelFromUL = 2
			AND DA.PK_AssociatedID = DA.nMainDistributorID -- When the Individual Distributorship achieves additional contributor, only the Indiviudal Distributorship will gain the new contributor																

			UNION 

			SELECT DISTINCT
					DA.PK_Distributor,
					DA.PK_AssociatedID,
					DL.PK_DSDownLine,
					DA.nMainDistributorID,
					DA.AssociationType,
					'SP' AS [Type]
			FROM #DS AS D --Uplines from COP
			INNER JOIN [Shared].[DistributorAssociation] AS DA WITH (NOLOCK)
				ON D.PK_Distributor = DA.PK_Distributor
			INNER JOIN dbo.v_dimDSLngDownline AS DL
				ON DA.PK_AssociatedID = DL.PK_Distributor
			WHERE DL.SPLevelFromUL = 2
			AND DA.PK_AssociatedID = DA.nMainDistributorID -- When the Individual Distributorship achieves additional contributor, only the Indiviudal Distributorship will gain the new contributor

			CREATE CLUSTERED INDEX [IX_#DSAssociatedDownlines_PK_FirstLine] ON  dbo.[#DSAssociatedDownlines] ([PK_DSDownLine])

			DROP TABLE IF EXISTS #WRK_25054_1LDownlines

			CREATE TABLE #WRK_25054_1LDownlines
			(
				PK_Distributor		INT,   
				[PK_FirstLine]		INT,
				[Type]				VARCHAR(2),
				PK_AssociatedID		INT,
				nMainDistributorID	INT,
				AssociationType		INT
			)

			INSERT INTO #WRK_25054_1LDownlines(PK_Distributor,[PK_FirstLine],[Type])
			SELECT DISTINCT
				D.PK_Distributor,
				D.[PK_FirstLine],
				D.[Type]
			FROM #DSDownlines AS D
					
						
			INSERT INTO #WRK_25054_1LDownlines(PK_Distributor,[PK_FirstLine],[Type],PK_AssociatedID,nMainDistributorID,AssociationType)
				SELECT DISTINCT
					A.PK_Distributor,
					A.PK_DSDownLine,
					A.[Type],
					PK_AssociatedID,
					nMainDistributorID,
					AssociationType
				FROM #DSAssociatedDownlines AS A
			WHERE NOT EXISTS (SELECT 1 FROM #WRK_25054_1LDownlines (NOLOCK) AS S WHERE A.PK_Distributor = S.PK_Distributor AND A.PK_DSDownline = S.[PK_FirstLine])

		CREATE CLUSTERED INDEX [IX_#WRK_25054_1LDownlines_PK_FirstLine] ON  #WRK_25054_1LDownlines ([PK_FirstLine])

		DROP TABLE IF EXISTS #WRK_25054_1LDownlinesEvaluation


			CREATE TABLE #WRK_25054_1LDownlinesEvaluation
			(
				PK_Distributor				INT,   
				[PK_FirstLine]				INT,
				[Type]						VARCHAR(10),
				ApplicationDate				INT,
				ContractAcceptanceDate		INT,
				DSREINSTATEMENTDATE			INT,
				SPQualDate					INT,
				AchievedPoints				BIT DEFAULT(0),
				AppDateValid				BIT DEFAULT(0),
				StatusCode					VARCHAR(30)
			)

			INSERT INTO #WRK_25054_1LDownlinesEvaluation(PK_Distributor,[PK_FirstLine],[Type],ApplicationDate,ContractAcceptanceDate,DSREINSTATEMENTDATE,SPQualDate,AppDateValid,StatusCode)
			SELECT 
				M.PK_Distributor,
				M.PK_FirstLine,
				M.[Type],
				LEFT(D.ApplicationDate,6) AS ApplicationDate,  
				LEFT(D.ContractAcceptanceDate,6) AS ContractAcceptanceDate,
				LEFT(D.[WINBACKREINSTATEMENTDATE],6) AS DSREINSTATEMENTDATE,
				LEFT(D.[SPQualDate],6) AS SPQualDate,
				CASE
					WHEN D.ApplicationDate BETWEEN CAST(CONVERT(varchar(8),@DSQualDateStart, 112) AS int) AND CAST(CONVERT(varchar(8),@DSQualDateEnd, 112) AS int) THEN 1
					ELSE 0
				END,
				D.StatusCode
			FROM
				#WRK_25054_1LDownlines M
			INNER JOIN [PubEvents].[dbo].[dimDistributor] AS D (NOLOCK)
				ON M.PK_FirstLine = D.PK_Distributor 
			WHERE M.[Type] = 'DS'

			UNION

			SELECT 
				M.PK_Distributor,
				M.PK_FirstLine,
				M.[Type],
				LEFT(D.ApplicationDate,6) AS ApplicationDate,  
				LEFT(D.ContractAcceptanceDate,6) AS ContractAcceptanceDate,
				LEFT(D.[WINBACKREINSTATEMENTDATE],6) AS DSREINSTATEMENTDATE,
				LEFT(D.[SPQualDate],6) AS SPQualDate,
				CASE
					WHEN D.[SPQualDate] BETWEEN CAST(CONVERT(varchar(8),@SPQualDateStart, 112) AS int) AND CAST(CONVERT(varchar(8),@SPQualDateEnd, 112) AS int) THEN 1
					ELSE 0
				END,
				D.StatusCode
			FROM
				#WRK_25054_1LDownlines M
			INNER JOIN [PubEvents].[dbo].[dimDistributor] AS D (NOLOCK)
				ON M.PK_FirstLine = D.PK_Distributor 
			WHERE M.[Type] = 'SP'

			CREATE CLUSTERED INDEX [IX_#WRK_25054_1LDownlinesEvaluation_PK_FirstLine] ON  #WRK_25054_1LDownlinesEvaluation ([PK_FirstLine])

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 2 AND [StepSubGroup] = 2;
	END
			    
	--Step 3: Volume for uplines		
	IF @Step >= 3
	BEGIN

		PRINT 'Executing step 3'

		------------------------------------------------------------------------------------------------
		-- 3.1 Getting values from #Event_SetupEventQualification
		------------------------------------------------------------------------------------------------
			
		INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification uplines', 3, 1, GETUTCDATE(), NULL);
		
		SELECT 
				@iStartDate = CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int), 
				@dStartDate = MIN(dStartDate),
				@iEndDate = CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int),
				@dEndDate = MAX(dEndDate),
				@MetricType = STRING_AGG([MetricType],','),
				@DSCountries = STRING_AGG([Countries],',')
			FROM #Event_SetupEventQualification WITH (NOLOCK)
	
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 1;

			-- Result set 
			SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate],@DSCountries AS [DSCountries],@MetricType AS [MetricType]

			------------------------------------------------------------------------------------------------
			-- 3.2 Getting #tmp_DS
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('#tmp_DS uplines', 3, 2, GETUTCDATE(), NULL);

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
				FROM #DS AS D WITH (NOLOCK) 
				WHERE DSSPTeam = 'SP'

				UNION 

				SELECT 
					@PK_Event AS [PK_Event],
					D.[PK_FirstLine] AS PK_Distributor,
					DD.sDistributorID AS DistributorID,
					@iStartDate AS [iStartDate],
					@iEndDate AS [iEndDate],
					@dStartDate AS [dStartDate],
					@dEndDate AS [dEndDate],
					DD.dSupervisorQualification 
				FROM #WRK_25054_1LDownlinesEvaluation (NOLOCK) AS D
				INNER JOIN v_Distributor AS DD
					ON D.[PK_FirstLine] = DD.nDistributorID	
				WHERE 
					D.AppDateValid = 1 AND D.StatusCode = 'COMPLETE'


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
					FROM #DS AS D WITH (NOLOCK) 					
						LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
							ON D.PK_Distributor = M.PK_Distributor
							OUTER APPLY (SELECT [PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,
												Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType] 
											FROM #Event_SetupEventQualification AS C WITH (NOLOCK)
											WHERE QualificationNumber < 41 ) AS C
						CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
		
				UNION 

					SELECT 
						C.PK_Event,
						D.PK_FirstLine AS PK_Distributor,
						A.StartDate AS dStartDate,
						A.EndDate AS dEndDate,
						CAST(CONVERT(varchar(6), A.StartDate, 112) AS int) AS iStartDate,
						CAST(CONVERT(varchar(6), A.EndDate, 112) AS int) AS iEndDate,
						NULL AS [dSPQualDate],
						NULL AS [iSPQualDate],
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
					FROM #WRK_25054_1LDownlinesEvaluation AS D WITH (NOLOCK) 					
						LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
							ON D.[PK_FirstLine] = M.PK_Distributor
						INNER JOIN v_Distributor AS DD
							ON D.[PK_FirstLine] = DD.nDistributorID		
							OUTER APPLY (SELECT [PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,
												Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType] 
											FROM #Event_SetupEventQualification AS C WITH (NOLOCK)
											WHERE QualificationNumber = 42) AS C
							CROSS APPLY [dbo].[ufn_GetPeriods](
								CASE C.PeriodType WHEN 1 THEN C.dStartDate WHEN 2 THEN CONVERT(DATETIME,CONVERT(VARCHAR, D.ContractAcceptanceDate) + '01',112)   END, -- ContractAcceptanceDate as Initial
								CASE C.PeriodType WHEN 1 THEN C.dEndDate WHEN 2 THEN DATEADD(MM,1,CONVERT(DATETIME,CONVERT(VARCHAR, D.ContractAcceptanceDate) + '01',112))	END, --ContractAcceptanceDate (SignUp Month+1)
								C.Frequency,C.Consecutive,C.Accumulated) AS A -- Relative qualification period based on ContractAcceptanceDate (SignUp Month+1)
					WHERE 
						D.AppDateValid = 1 AND D.StatusCode = 'COMPLETE'

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
	
	-- DSPointsSummary	
	IF @Step >= 5
	BEGIN

		PRINT 'Executing step 5'

		INSERT INTO #TimeLog VALUES ('#tmp_DSPointsSummary', 5, 1, GETUTCDATE(), NULL);

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
				
		DROP TABLE IF EXISTS #PointsMonths 

		SELECT r.dDate,r.iDate,r.iMonth,r.dMonthStart,r.iMonthStart
		INTO #PointsMonths
		FROM
		udf_MonthsRangeByInt(@Qual3Start, DATEDIFF(MM,@Qual3Start,DATEADD(MM,1,@Qual2End)), 1) AS r

		;WITH cte_PPV AS 
		(
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
			FROM #Event_DSPoints WITH (NOLOCK)
			WHERE MetricType = 'PPV'
			),
			cte_MPCV AS
			(
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
			FROM #Event_DSPoints WITH (NOLOCK)
			WHERE MetricType = 'MPCV'
			), cte_DS AS 
			(
				SELECT PK_Distributor,PK_Event,m.iMonth AS [RoyaltyMonth], 0 [PK_Country] FROM #tmp_DS
				CROSS APPLY #PointsMonths AS m
				WHERE PK_Event = @PK_Event 
			)
		 

			INSERT INTO #Event_DSPoints_Validations(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points],[Bonus])		
			SELECT 
				d.PK_Distributor,
				d.[PK_Event],
				d.PK_Country AS PK_Country,
				d.RoyaltyMonth,
				'PPV,MPCV' AS MetricType,
				ISNULL(p.[PersonalPoints],0) + ISNULL(s.[PersonalPoints],0) AS [PersonalPoints],
				ISNULL(p.[TransferPoints],0) + ISNULL(s.[TransferPoints],0) AS [TransferPoints],
				ISNULL(p.[MainPoints],0) + ISNULL(s.[MainPoints],0) AS [MainPoints],
				ISNULL(p.[Points],0) + ISNULL(s.[Points],0) AS [Points],
				ISNULL(p.[Bonus],0) + ISNULL(s.[Bonus],0) AS [Bonus]
			FROM cte_DS AS d
			LEFT JOIN cte_PPV AS p
				ON p.PK_Distributor = d.PK_Distributor AND
				p.[PK_Event] = d.[PK_Event] AND
				p.[RoyaltyMonth] = d.[RoyaltyMonth] AND 
				p.PK_Country = d.PK_Country  
			LEFT JOIN cte_MPCV AS s
				ON s.PK_Distributor = d.PK_Distributor AND
				s.[PK_Event] = d.[PK_Event] AND	
				s.[RoyaltyMonth] = d.[RoyaltyMonth] AND 
				s.PK_Country = d.PK_Country  

	
		INSERT INTO #Event_DSPoints_Validations(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points],[Bonus])		
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
			ISNULL(Bonus,0)
		FROM #Event_DSPoints WITH (NOLOCK)
		WHERE MetricType NOT IN ('PPV','MPCV')

		CREATE CLUSTERED INDEX [IX_#Event_DSPoints_Validations_PK_Distributor] ON #Event_DSPoints_Validations ([PK_Distributor]) 
		CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_Validations_MetricType] ON #Event_DSPoints_Validations ([MetricType])

		IF @IsDevQA = 0
		BEGIN

			DROP TABLE IF EXISTS [dbo].[WRK_25054_DSPoints_Validations] 
					
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
				ISNULL(Bonus,0) Bonus
			INTO [dbo].[WRK_25054_DSPoints_Validations]  
			FROM #Event_DSPoints_Validations

			CREATE INDEX IX_WRK_25054_DSPoints_Validations_PK_Distributor ON [dbo].[WRK_25054_DSPoints_Validations]  (PK_Distributor);

		END

			------------------------------------------------------------------------------------------------
			-- 5.7  Bonuses assignation / [tmp].[DSPointsSummary]		
			------------------------------------------------------------------------------------------------ 
			------------------------------------------------------------------------------------------------
			-- SAMCAM FEBRUARY DOUBLE VOLUME
			------------------------------------------------------------------------------------------------
			--All FQS and above can double their volume earned in FEBRUARY 2025 up to 5,000 TVP .  
			--Bonus Applies towards: E2 Leadership (Q9,Q10), E3 Ingreso Preferencial (Q11, Q12), E4 Gala (Q13,Q14), E5 Expereincia VIP (Q15, Q16), E6 VIP Premium (Q17, Q18)
			------------------------------------------------------------------------------------------------
			--// Double Bonus
			------------------------------------------------------------------------------------------------ 	

			INSERT INTO #TimeLog VALUES ('Double bonus', 5, 95, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #FebruaryDoubleVolumePromotion

			;WITH cte_FQS AS
			(
				SELECT DISTINCT PK_Distributor,CAST(CONVERT(VARCHAR(6),dSPQualDate,112) AS INT)  AS iSPQualDate
				FROM #DS AS D WITH (NOLOCK) WHERE DSSPTeam = 'SP'
			),
			cte_FebruaryDoubleVolumePromotion AS
			(

			SELECT 
				d.PK_Distributor,
				p.RoyaltyMonth,
			IIF(p.RoyaltyMonth = 202502,
					IIF(RoyaltyMonth < d.iSPQualDate,0,
						IIF(Points >= 5000, 5000, Points)),0) AS [FEBRUARY DOUBLE VOLUME PROMOTION] 
			FROM cte_FQS AS d
				INNER JOIN #Event_DSPoints_Validations AS p
					ON d.PK_Distributor = p.PK_Distributor 
						AND p.RoyaltyMonth IN(202502) 
						AND p.MetricType = 'TV'
			)

			SELECT 
				d.PK_Distributor,
				d.RoyaltyMonth,
			SUM([FEBRUARY DOUBLE VOLUME PROMOTION]) AS 	[FEBRUARY DOUBLE VOLUME PROMOTION]	
			INTO #FebruaryDoubleVolumePromotion
			FROM cte_FebruaryDoubleVolumePromotion AS d 
			GROUP BY d.PK_Distributor,d.RoyaltyMonth
		 
		 	-- This bonus are assigned below on #WRK_25054_BonusPoints

		 ------------------------------------------------------------------------------------------------
			-- SAMCAM NEW SP BONUS
			--All NEW FQS in the period (SP qual dates March 2025 - June 2025) from SP Qual Date onwards, can double their Volume in each month of the event Qual Period (February  2025 - June 2025) can use that volume to qualify for this promotion.

			-- Bonus Applies towards: E2 Leadership (Q9,Q10), E3 Ingreso Preferencial (Q11, Q12), E4 Gala (Q13,Q14), E5 Expereincia VIP (Q15, Q16), E6 VIP Premium (Q17, Q18)

			-- New consider ?New SP? from the period, all SP that have SP qual date in HDMS from 01-Mar-2025 until 1-Jun-2025 (regardless of if it is the first time the ID qualifies for SP).
			-- QS volume apply toward the bonus during the SP Qual date Period
			-- Current bonus applies to New SP for the first time ever and also to any New DS where a demotions exist in the profile. (Rule #11)
			-- Example SP Qual Months: 
			--	Mar  -   Apr   -   May   -  Jun
			--	500      5000    1000    2500  TVP Achieved each Month
			--	500      5000    1000    2500   Double Vol
			---------------------------------------------------
			--	1000   10000    2000    5000  Total Volume
		------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('#WRK_25054_BonusSummary', 5, 11, GETUTCDATE(), NULL);
			
			DROP TABLE IF EXISTS #SPDoubleVolumePromotion

			;WITH cte_FQS AS
			(
				SELECT DISTINCT PK_Distributor,	CAST(CONVERT(VARCHAR(6),NewSPQualDate,112) AS INT)  AS iSPQualDate 
				FROM #DS AS D WITH (NOLOCK) WHERE DSSPTeam = 'SP'
			),
			cte_FQS_MAX AS 
			(
				SELECT PK_Distributor,MAX(iSPQualDate) AS iSPQualDate
				FROM cte_FQS
				WHERE iSPQualDate BETWEEN CAST(CONVERT(VARCHAR(6),@NewSPBonusDateStart,112) AS INT) AND CAST(CONVERT(VARCHAR(6),@NewSPBonusDateEnd,112) AS INT)
				GROUP BY PK_Distributor
			),
			cte_SPDoubleVolumePromotion AS
			(

				SELECT 
					d.PK_Distributor,
					p.RoyaltyMonth,
					IIF(p.RoyaltyMonth >= d.iSPQualDate,p.Points,0) AS [SP DOUBLE VOLUME PROMOTION] 
				FROM cte_FQS_MAX AS d
					INNER JOIN #Event_DSPoints_Validations AS p
						ON d.PK_Distributor = p.PK_Distributor 
							AND p.MetricType = 'TV'
			)

			SELECT 
				d.PK_Distributor,
				d.RoyaltyMonth,
			SUM([SP DOUBLE VOLUME PROMOTION]) AS 	[SP DOUBLE VOLUME PROMOTION]	
			INTO #SPDoubleVolumePromotion
			FROM cte_SPDoubleVolumePromotion AS d 
			GROUP BY d.PK_Distributor,d.RoyaltyMonth

			--	Merging the all temp tables of the different sponsors into just one main table  
			DROP TABLE IF EXISTS #WRK_25054_BonusSummary

			;WITH cte_DS AS
			(
				SELECT PK_Distributor,RoyaltyMonth 
				FROM #SPDoubleVolumePromotion (NOLOCK)
				UNION 
				SELECT PK_Distributor,RoyaltyMonth 
				FROM #FebruaryDoubleVolumePromotion (NOLOCK)
			)
			 SELECT 
				ds.PK_Distributor,
				ds.RoyaltyMonth,
				ISNULL([FEBRUARY DOUBLE VOLUME PROMOTION],0) AS [FEBRUARY DOUBLE VOLUME PROMOTION],
				ISNULL([SP DOUBLE VOLUME PROMOTION],0) AS [SP DOUBLE VOLUME PROMOTION]
			INTO #WRK_25054_BonusSummary 
			FROM cte_DS AS ds
			LEFT JOIN #SPDoubleVolumePromotion AS d (NOLOCK)
				ON ds.PK_Distributor = d.PK_Distributor AND ds.RoyaltyMonth = d.RoyaltyMonth
			LEFT JOIN  #FebruaryDoubleVolumePromotion AS p (NOLOCK)
				ON ds.PK_Distributor = p.PK_Distributor AND ds.RoyaltyMonth = p.RoyaltyMonth
					
			CREATE INDEX IX_#WRK_25054_BonusSummary_PK_Distributor ON #WRK_25054_BonusSummary(PK_Distributor)
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 11;

			IF @IsDevQA = 0
			BEGIN

				INSERT INTO #TimeLog VALUES ('WRK_25054_BonusSummary', 5, 12, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS [dbo].[WRK_25054_BonusSummary]

				SELECT 
					PK_Distributor,
					RoyaltyMonth,
					[SP DOUBLE VOLUME PROMOTION],
					[FEBRUARY DOUBLE VOLUME PROMOTION]
				INTO [dbo].[WRK_25054_BonusSummary]
				FROM #WRK_25054_BonusSummary 
								
			CREATE INDEX IX_WRK_25054_BonusSummary_PK_Distributor ON [dbo].[WRK_25054_BonusSummary](PK_Distributor)
				
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 12;
				
			END
			ELSE IF @IsDevQA = 3
			BEGIN

				INSERT INTO #TimeLog VALUES ('##WRK_25054_BonusSummary', 5, 13, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS [dbo].[##WRK_26003_BonusSummary]

				SELECT 
					PK_Distributor,
					RoyaltyMonth,
					[SP DOUBLE VOLUME PROMOTION],
					[FEBRUARY DOUBLE VOLUME PROMOTION]
				INTO [dbo].[##WRK_25054_BonusSummary]
				FROM #WRK_25054_BonusSummary 
											
				CREATE INDEX IX_##WRK_25054_BonusSummary_PK_Distributor ON [dbo].[##WRK_25054_BonusSummary](PK_Distributor)
				
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
				FROM [dbo].[WRK_25054_DSPoints_Validations] AS U WITH (NOLOCK) 
							INNER JOIN #tmp_DSQualDef AS F
								ON u.PK_Distributor = F.PK_Distributor	
								WHERE 
								F.MetricType = U.MetricType 
								AND 
								U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
								AND 
				(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
				GROUP BY U.PK_Distributor,U.RoyaltyMonth,U.MetricType,F.[QSVolume],F.[QSVolumePercentage],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries

			INSERT INTO #TimeLog VALUES ('#WRK_25054_BonusPoints', 5, 14, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #WRK_25054_BonusPoints

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
					IIF(@IsFebruaryDoubleBonusActive = 1 AND U.QualificationNumber BETWEEN @BonusApplicableFrom AND @BonusApplicableTo AND U.MetricType = 'TV', BS.[FEBRUARY DOUBLE VOLUME PROMOTION],0 ) AS [FEBRUARY DOUBLE VOLUME PROMOTION],
					IIF(@IsNewSPBonusActive = 1 AND U.QualificationNumber BETWEEN @BonusApplicableFrom AND @BonusApplicableTo AND U.MetricType = 'TV', ISNULL(BS.[SP DOUBLE VOLUME PROMOTION],0), 0) AS [SP DOUBLE VOLUME PROMOTION] 
				INTO #WRK_25054_BonusPoints
				FROM #Event_DSPoints_Summary AS U WITH (NOLOCK)
						LEFT JOIN [dbo].[WRK_25054_BonusSummary] AS BS (NOLOCK)
							ON U.PK_Distributor = BS.PK_Distributor	
							AND U.RoyaltyMonth = BS.RoyaltyMonth

			CREATE INDEX IX_#WRK_25054_BonusPoints_PK_Distributor ON #WRK_25054_BonusPoints(PK_Distributor)

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 14;

			IF @IsDevQA = 0
			BEGIN
			
				INSERT INTO #TimeLog VALUES ('WRK_25054_BonusPoints', 5, 15, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS [dbo].[WRK_25054_BonusPoints]

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
						[FEBRUARY DOUBLE VOLUME PROMOTION],
						[SP DOUBLE VOLUME PROMOTION]
					INTO [dbo].[WRK_25054_BonusPoints]
					FROM #WRK_25054_BonusPoints	

				CREATE INDEX IX_WRK_25054_BonusPoints_PK_Distributor ON [dbo].[WRK_25054_BonusPoints](PK_Distributor)

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
							(ISNULL(P.[FEBRUARY DOUBLE VOLUME PROMOTION],0) + ISNULL(P.[SP DOUBLE VOLUME PROMOTION],0))  AS [Bonus],
							ISNULL(P.[Points],0) + (ISNULL(P.[FEBRUARY DOUBLE VOLUME PROMOTION],0) + ISNULL(P.[SP DOUBLE VOLUME PROMOTION],0)) AS [TotalPoints],
							P.iStartDate,
							P.iEndDate
						FROM #WRK_25054_BonusPoints AS P WITH (NOLOCK)

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

		INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q03,Q19,Q20,Q45,Q50)
			SELECT 
				PK_Distributor,
				@PK_Event AS [PK_Event],
				IIF(D.DSSPTeam = 'SP',1,0)																			AS Q01, -- FQS and Above 
				IIF(D.NewSPQualDate BETWEEN @qual2Start AND @qual2End,1,0)											AS Q02, -- New FQS (SP Qual dates:  March 2025 - June 2025)
				IIF(D.QSActualQualDate BETWEEN @QSActualQualDateStart AND @QSActualQualDateEnd,1,0)					AS Q03, -- QS, QV, PQS, SQS, 2QS, 5QS (Qual date:  June thorugh the Event date 2025)
				IIF(D.DSCurrentTeam IN ('G','M','P','A','B','C'),	1,0)											AS Q19, -- TAB Team Members
				IIF(D.NewWTQualDate > D.NewSPQualDate AND D.NewWTQualDate BETWEEN @qual2Start AND @qual2End,1,0)	AS Q20, -- New World Team (WT) (Team Qual Date: Mar 2025 - Jun 2025)
				D.IsFromCOP																							AS Q45, -- FromCOP
				IIF(D.DSSubTeam IN ('QS','QV','PQS','SQS','2QS','5QS'),1,0)											AS Q50  -- Include: QS, QV, PQS, SQS, 2QS, 5QS SubTypeCodes
			FROM #DS AS D WITH (NOLOCK)  
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

			SELECT  PK_Event, ListID, QColumn = 'Q' +   IIF(QId < 10,  '0' + CAST(QId AS VARCHAR), CAST(QId  AS VARCHAR))  
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
					AND E.PK_Distributor = L.PK_Distributor_List
					AND L.PK_Event_List = ' + CAST(PK_Event AS NVARCHAR(MAX)) + ';'							
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

		------------------------------------------------------------------------------------------------
		-- Other qualifications
		------------------------------------------------------------------------------------------------

		BEGIN

			-- AWT 2025 Qualify OR Re-qualify (NON-TAB) (Qual dates: Feb 2025 - May 2025)

			DROP TABLE IF EXISTS #AWT_QualRequal_FebMay25
 
			SELECT d.PK_Distributor,@PK_Event as PK_Event
				INTO #AWT_QualRequal_FebMay25
			FROM #DS AS d  
 			INNER JOIN dbo.[AWT] AS a WITH (NOLOCK)
 	 			ON d.PK_Distributor = a.PK_Distributor  AND a.IsNonTab = 1
			INNER JOIN [dbo].[AWT_Qualifiers_Tracking] AS t WITH (NOLOCK)
				ON a.PK_Distributor = t.PK_Distributor AND a.AWTYear = t.AWTYear
 			WHERE (a.AWTYear = 2025 AND (t.[Feb] = 1 OR t.[Mar] = 1 OR t.[Apr] = 1 OR t.[May] = 1))
			
			CREATE INDEX IX_#AWT_QualRequal_FebMay25_PK_Distributor ON #AWT_QualRequal_FebMay25(PK_Distributor);

			UPDATE E
			SET 
				Q04 = IIF(Q04.PK_Distributor IS NULL,0,1)
				FROM #EventQual AS E
				INNER JOIN #AWT_QualRequal_FebMay25 AS Q04
				ON E.PK_Distributor = Q04.PK_Distributor 
					AND E.PK_Event = Q04.PK_Event

			--Verify if the Q42 is true or not and update the AchievedPoints
			UPDATE D
			SET AchievedPoints = IIF(E.PK_Distributor IS NULL,0,1)
			FROM #WRK_25054_1LDownlinesEvaluation (NOLOCK) D
			INNER JOIN #Event_DSQualPoints AS E
			ON D.PK_FirstLine = E.PK_Distributor 
			AND E.QualificationNumber = 42
			AND E.PK_Event = @PK_Event


			IF OBJECT_ID (N'WRK_25054_1LDownlines', N'U') IS NULL 
			BEGIN

				CREATE TABLE [dbo].[WRK_25054_1LDownlines] --Freeze table
				(
					[CreatedDateUTC]   DATETIME, 
					[ModifiedDateUTC]  DATETIME,
					PK_Distributor				INT,   
					[PK_FirstLine]				INT,
					[Type]						VARCHAR(10),
					ApplicationDate				INT,
					ContractAcceptanceDate		INT,
					DSREINSTATEMENTDATE			INT,
					SPQualDate					INT,
					AchievedPoints				BIT DEFAULT(0),
					AppDateValid				BIT DEFAULT(0),
					StatusCode					VARCHAR(30)
				) 

				CREATE CLUSTERED INDEX [IX_WRK_25054_1LDownlines_PK_FirstLine] ON  dbo.[WRK_25054_1LDownlines] ([PK_FirstLine])
			END

			MERGE [dbo].[WRK_25054_1LDownlines] AS T
			USING #WRK_25054_1LDownlinesEvaluation AS S
			ON S.PK_Distributor = T.PK_Distributor 
				AND S.PK_FirstLine = T.PK_FirstLine  
				AND S.[Type] = T.[Type] 
			WHEN NOT MATCHED BY TARGET THEN
			-- For Inserts
				INSERT (
						[CreatedDateUTC],   
						[ModifiedDateUTC],  
						PK_Distributor,				 
						[PK_FirstLine],				
						[Type],						
						ApplicationDate,				
						ContractAcceptanceDate,		
						DSREINSTATEMENTDATE,			
						SPQualDate,					
						AchievedPoints,				
						AppDateValid,				
						StatusCode					
						) 
				VALUES (
						GETUTCDATE(), 
						GETUTCDATE(),
						S.PK_Distributor,				 
						S.[PK_FirstLine],				
						S.[Type],						
						S.ApplicationDate,				
						S.ContractAcceptanceDate,		
						S.DSREINSTATEMENTDATE,			
						S.SPQualDate,					
						S.AchievedPoints,				
						S.AppDateValid,				
						S.StatusCode	
					)
			-- For Updates
			WHEN MATCHED AND T.AchievedPoints = 0 AND S.AchievedPoints = 1 THEN
				UPDATE 
				SET
					[ModifiedDateUTC] = GETUTCDATE(),
					T.AchievedPoints = 1;

			DROP TABLE IF EXISTS #1LDownlinesDSCount

			SELECT @PK_Event as PK_Event,PK_Distributor,[Type],COUNT(*) DownlinesCount 
			INTO #1LDownlinesDSCount
			FROM [dbo].[WRK_25054_1LDownlines] (NOLOCK) D
			WHERE 
				AppDateValid = 1 AND StatusCode = 'COMPLETE' AND AchievedPoints = 1
			GROUP BY PK_Distributor,[Type]

			UPDATE E
			SET 
				Q21 = IIF(Q21.PK_Distributor IS NULL,0,1)
				FROM #EventQual AS E
				INNER JOIN #1LDownlinesDSCount AS Q21
				ON E.PK_Distributor = Q21.PK_Distributor 
					AND E.PK_Event = Q21.PK_Event
					AND Q21.[Type] = 'DS'
					AND Q21.DownlinesCount >= 3 --Have 3 New Distributors with App Month Jan 2025 - May 2025

			DROP TABLE IF EXISTS #1LDownlinesSPCount

			SELECT @PK_Event as PK_Event,PK_Distributor,[Type],COUNT(*) DownlinesCount 
			INTO #1LDownlinesSPCount
			FROM [dbo].[WRK_25054_1LDownlines] (NOLOCK) D
			WHERE 
				AppDateValid = 1 AND StatusCode = 'COMPLETE'
			GROUP BY PK_Distributor,[Type]

			UPDATE E
			SET 
				Q22 = IIF(Q22.PK_Distributor IS NULL,0,1)
				FROM #EventQual AS E
				INNER JOIN #1LDownlinesSPCount AS Q22
				ON E.PK_Distributor = Q22.PK_Distributor 
					AND E.PK_Event = Q22.PK_Event
					AND Q22.[Type] = 'SP'
					AND Q22.DownlinesCount >= 2 -- Have 2 New Supervisors (SPQual Date Feb 2025 - Jun 2025)

		END
		
	END
			
	--Step 8: Subevents
	IF @Step >= 8
	BEGIN

		PRINT 'Executing step 8'

		INSERT INTO #TimeLog VALUES ('Es #EventQual', 8, 1, GETUTCDATE(), NULL);
					
			UPDATE 
				#EventQual
			SET
				E01 = (Q01 | Q02 | (Q03 & Q50) | Q23) 

			UPDATE 
				#EventQual
			SET
				E02 = ((E01 & (Q05 | Q06 | Q07 | Q08 | Q09 | Q10)) | Q04 | Q19 | Q39 | Q24), 
				E03 = ((E01 & (Q11 | Q12)) | Q25), 
				E05 = ((E01 & (Q15 | Q16)) | Q27),
				E06 = ((E01 & (Q17 | Q18) & Q45) | Q28),
				E07 = ((E01 & (Q02 | (Q03 & Q50))) | Q29),
				E08 = ((E01 & (Q19 | Q40 | Q41)) | Q30)
	
			UPDATE 
				#EventQual
			SET
				E04 = ((E01 & (Q13 | Q14)) | (E03 & Q20) | Q26)

			UPDATE 
				#EventQual
			SET
				E09 = ((E08 & (Q21 & Q22)) | Q31),
				E10 = (E05),
				E11 = (E05),
				E12 = (Q32),
				E13 = (Q33),
				E14 = (Q34),
				E15 = (Q35),
				E16 = (Q36),
				E17 = (Q37),
				E18 = (Q38),
				E19 = (Q20 & (~E02 & ~E03 & ~E04))
										
 
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

			IF OBJECT_ID (N'[tmp].[DSQual]', N'U') IS NOT NULL 
			BEGIN

				DELETE dq			
				FROM [tmp].[DSQual] AS dq
					INNER JOIN #Locations AS l
						ON dq.PK_Event = l.PK_Event
			END

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