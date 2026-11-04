CREATE PROCEDURE [dbo].[usp_EventQual_SAMCAMExtravaganzaJun2024]
	@PK_Event INT = 199089
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT
	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
	,@Step INT = 11
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_SAMCAMExtravaganzaJun2024

	USE:		

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC dbo.usp_EventQual_SAMCAMExtravaganzaJun2024 
					@PK_Event = 199089,
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
	[dbo].[WRK_24057_BonusPoints]

	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2024-04-16	alejandramed		Initial - BRD V1
	1.0.1	2024-04-30	alejandramed		BRD v1.2
	1.0.2	2024-05-02	alejandramed		Bug 1340041: 24057- SAMCAM Extrav Jun 2024_BRD V1.2 - E18 Q44 PT
	1.0.3	2024-05-07	alejandramed		Bug 1340463: 24057- SAMCAM Extrav Jun 2024_BRD V1.2 E1 Q11 AWT
											Bug 1340462: 24057- SAMCAM Extrav Jun 2024_BRD V1.2 E1 Q12 QS
											Bug 1340522: 24057- SAMCAM Extrav Jun 2024_BRD V1.2 New SP Bonus Feb
											Including Panama and Nicaragua
											Bug 1340586: 24057- SAMCAM Extrav Jun 2024_BRD V1.2 SKU CA QS
											Bug 1340564: 24057- SAMCAM Extrav Jun 2024_BRD V1.2 E2 Q46
	1.0.4	2024-05-24	alejandramed		Bug 1346637: 24057- SAMCAM Extrav Jun 2024 (NEW SP Bonus)
	1.0.5	2024-06-11	alejandramed		BUG 1349650
											BUG 1349651
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

	--Quals block
	BEGIN 

		--Step 0: Variables and temp tables 
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
			[QSVolumeBonus]			bit, 
			[PeriodType]			tinyint, -- 1 Fixed period, 2 Relative period base on SPQualDate
			[MetricTypeDefinition]		VARCHAR(50) NULL
		)

		--Q5	Achieve 2,500 TVP each month in any three months (Feb 2024 - May 2024)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			5					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-02-01'		AS [dStartDate], 
			'2024-05-01'		AS [dEndDate], 
			3					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			2500				AS [GoalPoints], 
			NULL				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q6 Achieve 2,500 TVP each month in any three months (Mar 2024 - Jun 2024) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			6					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-03-01'		AS [dStartDate], 
			'2024-06-01'		AS [dEndDate], 
			3					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			2500				AS [GoalPoints], 
			NULL				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q7	Achieve 5,000 TVP any one month  (Feb 2024 - May 2024)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			7					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-02-01'		AS [dStartDate], 
			'2024-05-01'		AS [dEndDate], 
			1					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			5000				AS [GoalPoints], 
			NULL				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q8	Achieve 5,000 TVP any one month (Mar 2024 - Jun 2024) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			8					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-03-01'		AS [dStartDate], 
			'2024-06-01'		AS [dEndDate], 
			1					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			5000				AS [GoalPoints], 
			NULL				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q9	Accumulate 10,000 TVP in four consecutive months  (Feb 2024 - May 2024)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			9					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-02-01'		AS [dStartDate], 
			'2024-05-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			10000				AS [GoalPoints], 
			NULL				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q10	Accumulate 10,000 TVP in four consecutive months (Mar 2024 - Jun 2024) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			10					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-03-01'		AS [dStartDate], 
			'2024-06-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			10000				AS [GoalPoints], 
			NULL				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]		 

		--Q13	Accumulate 15 000 TVP (Feb 2024 - May 2024)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			13					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-02-01'		AS [dStartDate], 
			'2024-05-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			15000				AS [GoalPoints], 
			NULL				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]		 

		--Q14	Accumulate 15,000 TVP (Mar 2024 - Jun 2024) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			14					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-03-01'		AS [dStartDate], 
			'2024-06-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			15000				AS [GoalPoints], 
			NULL				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q15	Accumulate 20,000 TVP (Feb 2024 - May 2024)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			15					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-02-01'		AS [dStartDate], 
			'2024-05-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			20000				AS [GoalPoints], 
			NULL				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q16	Accumulate 20,000 TVP (Mar 2024 - Jun 2024) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			16					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-03-01'		AS [dStartDate], 
			'2024-06-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			20000				AS [GoalPoints], 
			NULL				AS [Countries],
			1					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q17	Accumulate 25,000 TVP (Feb 2024 - May 2024)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			17					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-02-01'		AS [dStartDate], 
			'2024-05-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			25000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q18	Accumulate 25,000 TVP (Mar 2024 - Jun 2024) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			18					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-03-01'		AS [dStartDate], 
			'2024-06-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			25000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q19	Accumulate 35,000 TVP (Feb 2024 - May 2024)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			19					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-02-01'		AS [dStartDate], 
			'2024-05-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			35000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q20	Accumulate 35,000 TVP (Mar 2024 - Jun 2024) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			20					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-03-01'		AS [dStartDate], 
			'2024-06-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			35000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q23	Achieve 1,000 Royalties in any 1 month (Oct 2023 – May 2024)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			23					AS QualificationNumber,
			1					AS Part, 
			'RO'				AS [MetricType], 
			'2023-10-01'		AS [dStartDate], 
			'2024-05-01'		AS [dEndDate], 
			1					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			1000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q26	Accumulate 5,000 TVP in four consecutive months  (Feb 2024 - May 2024)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			26					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-02-01'		AS [dStartDate], 
			'2024-05-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			5000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

		--Q27	Accumulate 5,000 TVP in four consecutive months (Mar 2024 - Jun 2024) (Event date)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[QSVolumeBonus])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			27					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-03-01'		AS [dStartDate], 
			'2024-06-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			5000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [QSVolumeBonus]

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
			@SqlStatement NVARCHAR(MAX),
			@Countries VARCHAR(MAX) = 'AR,UY,BL,CI,CO,CR,DR,EC,GT,HN,PE,PY,SV,VE,BR,PM,NI'
 
		DROP TABLE IF EXISTS #ListsQsMapping

		CREATE TABLE #ListsQsMapping
		(
			ID INT IDENTITY(1,1),
			ListID INT,
			QId INT
		)

		INSERT INTO #ListsQsMapping(ListID,QId)
			VALUES 
				(59622,4), --Q04 PK_59622 24057_SAMFSL_Ext_Leadership_WorldTeam1%List
				(59623,24), --Q24  PK_59623 24057_SAMFSL_Ext_Cumbre_WorldTeam1%List
				(59607,28), --Q28 PK_59607 24507_SAMCAM_Ext_E1AutoQualify
				(59608,29), --Q29 PK_59608 24507_SAMCAM_Ext_Leadership
				(59609,30), --Q30 PK_59609 24507_SAMCAM_Ext_IngresoPreferencial
				(59610,31), --Q31 PK_59610 24507_SAMCAM_Ext_InolvidablePaseo
				(59611,32), --Q32 PK_59611 24507_SAMCAM_Ext_VIP
				(59612,33), --Q33 PK_59612 24507_SAMCAM_Ext_Gold
				(59613,34), --Q34 PK_59613 24507_SAMCAM_Ext_CumbreTAB
				(59614,35), --Q35 PK_59614 24507_SAMCAM_Ext_NewSP
				(59617,36), --Q36 PK_59617 24507_SAMCAM_Ext_SubeventoA
				(59618,37), --Q37 PK_59618 24507_SAMCAM_Ext_SubeventoB
				(59619,38), --Q38 PK_59619 24507_SAMCAM_Ext_SubeventoC
				(59620,39), --Q39 PK_59620 24507_SAMCAM_Ext_SubeventoD
				(59621,40), --Q40 PK_59621 24507_SAMCAM_Ext__SubeventoE
				(59798,41), --Q41 PK_59798 24507_SAMCAM_Ext__SubeventoPremier_2Dummy
				(59799,42), --Q42 PK_59799 24507_SAMCAM_Ext__SubeventoPremier_NODummy
				(60135,45)  --Q45 List PK_60135  24507_SAMCAM_Ext__2000K

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
		SELECT @PK_Event,	'EMEA'	 		 

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
					DSTeam			varchar(10),        
					DSSubTeam			varchar(10),        
					DSSPTeam			varchar(10),               
					dSPQualDate			datetime2,   
					dSPRequalDate		datetime2,  
					dSPDemotion			datetime2,  
					SPQualMonth			int,
					CountryCode			varchar(5),
					IsFromList			bit default(0),
					IsTicketPurchaser	bit default(0),
					Q3	bit default(0),
					Q12	bit default(0),
					Q2	bit default(0),
					Q2A bit default(0),
					Q2B bit default(0), 
					IsVenezuela	bit default(0)
				)

				INSERT INTO #DS
				(
					PK_Distributor,	
					DSTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,	
					dSPRequalDate,
					dSPDemotion,
					SPQualMonth,
					CountryCode,
					Q2,
					Q2A,
					Q2B,
					IsVenezuela
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				D.dSupervisorqualification AS dSPQualDate,     
				D.dSupervisorReQualification AS dSPRequalDate,
				D.dSPDemotion AS dSPDemotion,
				cast(format(D.dSupervisorqualification,'yyyyMM') AS int) AS SPQualMonth,
				D.sDistributorCountryProcessingCode AS CountryCode,
				IIF(d.dSupervisorqualification BETWEEN '2024-03-01' AND '2024-06-01' OR dSupervisorReQualification BETWEEN '2024-03-01' AND '2024-06-01',1,0)  AS Q2, --New FQS Qualify or Requalify (Qual dates:  Mar 2024 - Jun 2024)
				IIF(d.dSupervisorqualification BETWEEN '2024-03-01' AND '2024-06-01' AND D.dSupervisorReQualification IS NULL AND d.dSPDemotion IS NULL,1,0)  AS Q2A, --New FQS Qualify (Qual dates:  Mar 2024 - Jun 2024) NOT Requalified
				IIF(d.dSupervisorqualification BETWEEN '2024-02-01' AND '2024-05-01' AND D.dSupervisorReQualification IS NULL AND d.dSPDemotion IS NULL,1,0)  AS Q2B, --New FQS Qualify (Qual dates:  Feb 2024 - May 2024) NOT Requalified
				IIF(d.sDistributorCountryProcessingCode = 'VE',1,0) AS IsVenezuela
				FROM        
				dbo.v_Distributor AS D  
					INNER JOIN #Countries AS C
						ON D.nDistributorCountryProcessingID = C.nCountryID
				
				WHERE        
					D.StatusCode = 'COMPLETE'        
					AND D.sType IN ('SP', 'DS')
	 							 
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
					DSTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,	
					dSPRequalDate,
					dSPDemotion,
					SPQualMonth,
					CountryCode,
					Q2,
					Q2A,
					Q2B,
					IsVenezuela,
					IsFromList
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				D.dSupervisorqualification AS dSPQualDate,     
				D.dSupervisorReQualification AS dSPRequalDate,
				D.dSPDemotion AS dSPDemotion,
				cast(format(D.dSupervisorqualification,'yyyyMM') AS int) AS SPQualMonth,
				D.sDistributorCountryProcessingCode AS CountryCode,
				IIF(d.dSupervisorqualification BETWEEN '2024-03-01' AND '2024-06-01' OR dSupervisorReQualification BETWEEN '2024-03-01' AND '2024-06-01',1,0)  AS Q2, --New FQS Qualify or Requalify (Qual dates:  Mar 2024 - Jun 2024)
				IIF(d.dSupervisorqualification BETWEEN '2024-03-01' AND '2024-06-01' AND D.dSupervisorReQualification IS NULL AND d.dSPDemotion IS NULL,1,0)  AS Q2A, --New FQS Qualify (Qual dates:  Mar 2024 - Jun 2024) NOT Requalified
				IIF(d.dSupervisorqualification BETWEEN '2024-02-01' AND '2024-05-01' AND D.dSupervisorReQualification IS NULL AND d.dSPDemotion IS NULL,1,0)  AS Q2B, --New FQS Qualify (Qual dates:  Feb 2024 - May 2024) NOT Requalified
				IIF(d.sDistributorCountryProcessingCode = 'VE',1,0) AS IsVenezuela,
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
					DSTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,	
					dSPRequalDate,
					dSPDemotion,
					SPQualMonth,
					CountryCode,
					Q2,
					Q2A,
					Q2B,
					IsVenezuela,
					IsTicketPurchaser
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				D.dSupervisorqualification AS dSPQualDate,     
				D.dSupervisorReQualification AS dSPRequalDate,
				D.dSPDemotion AS dSPDemotion,
				cast(format(D.dSupervisorqualification,'yyyyMM') AS int) AS SPQualMonth,
				D.sDistributorCountryProcessingCode AS CountryCode,
				IIF(d.dSupervisorqualification BETWEEN '2024-03-01' AND '2024-06-01' OR dSupervisorReQualification BETWEEN '2024-03-01' AND '2024-06-01',1,0)  AS Q2, --New FQS Qualify or Requalify (Qual dates:  Mar 2024 - Jun 2024)
				IIF(d.dSupervisorqualification BETWEEN '2024-03-01' AND '2024-06-01' AND D.dSupervisorReQualification IS NULL AND d.dSPDemotion IS NULL,1,0)  AS Q2A, --New FQS Qualify (Qual dates:  Mar 2024 - Jun 2024) NOT Requalified
				IIF(d.dSupervisorqualification BETWEEN '2024-02-01' AND '2024-05-01' AND D.dSupervisorReQualification IS NULL AND d.dSPDemotion IS NULL,1,0)  AS Q2B, --New FQS Qualify (Qual dates:  Feb 2024 - May 2024) NOT Requalified
				IIF(d.sDistributorCountryProcessingCode = 'VE',1,0) AS IsVenezuela,
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
			 
				-- Getting status from history  
			 
				--New World Team (Team Qual Dates  Mar 2024 - June 2024)
				--224	Qual World Team
				;WITH cte_QualWorldTeam AS
				(
					SELECT 
						d.PK_Distributor,
						h.nEventTypeLID
						 
					FROM [dbo].[v_DistributorHistory] AS h
						INNER JOIN #DS AS d
							ON h.nDistributorIDFK = d.PK_Distributor
					WHERE h.nEventTypeLID = 224 AND dFrom BETWEEN '2024-03-01' AND '2024-06-30'

				)
				
					UPDATE W 
					SET Q3 = 1
					FROM cte_QualWorldTeam AS h
						INNER JOIN #DS AS w
							ON h.PK_Distributor = w.PK_Distributor
	  
				--QS, QV, PQS, SQS, 2QS, 5QS (Qual date:  June thorugh the Event date 2024)
				--258	Qual QS
				--256	Qual QV
				--254	Qual PQS
				--261	Qual SQS
				--263	Qual 2QS
				--253	Qual 5QS
				;WITH cte_QualQS AS
				(
					SELECT 
						d.PK_Distributor,
						h.nEventTypeLID
						 
					FROM [dbo].[v_DistributorHistory] AS h
						INNER JOIN #DS AS d
							ON h.nDistributorIDFK = d.PK_Distributor
					WHERE d.DSSPTeam = 'DS' AND h.nEventTypeLID IN (258,256,254,261,263,253) AND dFrom BETWEEN '2024-06-01' AND '2024-06-30'
				)							  
		
				UPDATE W 
					SET Q12 = 1
					FROM cte_QualQS AS h
						INNER JOIN #DS AS w
							ON h.PK_Distributor = w.PK_Distributor

				--Removing all the DS who is not qualifing as QS, QV, PQS, SQS, 2QS, 5QS (Qual date:  June thorugh the Event date 2024)
				DELETE #DS WHERE DSSPTeam = 'DS' AND Q12 = 0


			DROP TABLE IF EXISTS [dbo].[WRK_24057_Distributors]

			SELECT 
				PK_Distributor   
				,DSTeam 
				,DSSubTeam      
				,DSSPTeam           
				,dSPQualDate  
				,dSPRequalDate
				,dSPDemotion
				,SPQualMonth
				,CountryCode
				,IsFromList
				,IsTicketPurchaser
				,Q3
				,Q12
				,Q2
				,Q2A
				,Q2B
				,IsVenezuela
			INTO [dbo].[WRK_24057_Distributors] 
			FROM #DS

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 2;
		END
			    
		--Step 3: Volume		
		IF @Step >= 3 AND EXISTS (SELECT 1 FROM #Event_SetupEventQualification)
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
						[dSPQualDate] [datetime] NULL
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
					FROM #DS AS D WITH (NOLOCK) 
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
			
				 
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 5;
			
		END
			
		--Step 4: Qualification definition
		IF @Step >= 4 AND EXISTS (SELECT 1 FROM #Event_SetupEventQualification)
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
					[QSVolumeBonus] [bit] NULL
					)

				INSERT INTO #tmp_DSQualDef([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[QSVolume],[QSVolumeBonus])
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
						C.[QSVolume],
						C.[QSVolumeBonus]
					FROM #DS AS D WITH (NOLOCK) 					
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
	
		--Step 5: Downlines and Bonuses / DSPointsSummary			
		IF @Step >= 5
		BEGIN
			
			PRINT 'Executing step 5'
			
									
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
				[QSVolumeBonus] [bit] NULL
			)

			INSERT INTO #Event_DSPoints_Summary(PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries,[QSVolumeBonus])
				SELECT U.PK_Distributor,
						U.RoyaltyMonth,
						U.MetricType,
						0 AS PK_Country,
						SUM(IIF(ISNULL(F.[QSVolume],0) = 0,IIF(U.RoyaltyMonth < F.iSPQualDate,0, ISNULL(U.Points,0)),ISNULL(U.Points,0))) AS [Points],	
						F.[QSVolume], 
						F.iSPQualDate,
						F.QualificationNumber,
						F.Part,
						F.iStartDate,
						F.iEndDate,
						F.Countries, 
						F.[QSVolumeBonus]
				FROM #Event_DSPoints AS U WITH (NOLOCK) 
							INNER JOIN #tmp_DSQualDef AS F
								ON u.PK_Distributor = F.PK_Distributor	
								WHERE 
								F.MetricType = U.MetricType 
								AND 
								U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
								AND 
				(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
				GROUP BY U.PK_Distributor,U.RoyaltyMonth,U.MetricType,F.[QSVolume],F.[QSVolumeBonus],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries
					
			INSERT INTO #TimeLog VALUES ('#WRK_24057_BonusPoints', 5, 44, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #WRK_24057_BonusPoints

			--In case of multiple periods, the bonus should be assigned by period
				
			SELECT 
					U.PK_Distributor,
					U.RoyaltyMonth,
					U.MetricType,
					0 AS PK_Country,
					ISNULL(U.Points,0) AS [Points],
					U.[QSVolume], 
					U.iSPQualDate,
					U.QualificationNumber,
					U.Part,
					U.iStartDate,
					U.iEndDate,
					U.Countries,
					U.[QSVolumeBonus],
					IIF(U.RoyaltyMonth >= D.SPQualMonth, IIF(D.IsVenezuela = 0 AND U.QualificationNumber IN (9,10,13,14,15,16,17,18,19,20) AND U.MetricType = 'TV' AND D.Q2A = 1 AND U.RoyaltyMonth BETWEEN 202403 AND 202406 ,U.Points,0),0) AS [SAMCAMNEW SP BONUS],
					IIF(U.RoyaltyMonth >= D.SPQualMonth, IIF(D.IsVenezuela = 0 AND U.QualificationNumber IN (9,10,13,14,15,16,17,18,19,20) AND U.MetricType = 'TV' AND D.Q2A = 0 AND U.RoyaltyMonth = 202402 ,IIF(U.Points >= 5000, 5000, U.Points),0),0) AS [SAMCAM FEBRUARY DOUBLE VOLUME],
					IIF(U.RoyaltyMonth >= D.SPQualMonth, IIF(D.IsVenezuela = 1 AND U.QualificationNumber IN (9,10,13,14,15,16,17,18,19,20) AND U.MetricType = 'TV' AND D.Q2B = 1 AND U.RoyaltyMonth BETWEEN 202403 AND 202406 ,U.Points,0),0) AS [VENEZUELA NEW SP BONUS],
					IIF(U.RoyaltyMonth >= D.SPQualMonth, IIF(D.IsVenezuela = 1 AND U.QualificationNumber IN (13,15,17,19) AND U.MetricType = 'TV' AND D.Q2B = 0 AND U.RoyaltyMonth = 202402 ,IIF(U.Points >= 5000, 5000, U.Points),0),0) AS [VENEZUELA FEBRUARY DOUBLE VOLUME]
				INTO #WRK_24057_BonusPoints
				FROM #Event_DSPoints_Summary AS U WITH (NOLOCK)
					INNER JOIN #DS AS D
						ON U.PK_Distributor = D.PK_Distributor 	
							
			CREATE INDEX IX_#WRK_24057_BonusPoints_PK_Distributor ON #WRK_24057_BonusPoints(PK_Distributor)
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 44;

			IF @IsDevQA = 0
			BEGIN
			
				INSERT INTO #TimeLog VALUES ('WRK_24057_BonusPoints', 5, 43, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS [dbo].[WRK_24057_BonusPoints]

				--In case of multiple periods, the bonus should be assigned by period

				SELECT 
						PK_Distributor,
						RoyaltyMonth,
						MetricType,
						PK_Country,
						[Points],
						[QSVolume], 
						[QSVolumeBonus],
						iSPQualDate,
						QualificationNumber,
						Part,
						iStartDate,
						iEndDate,
						Countries,
						[SAMCAMNEW SP BONUS],
						[SAMCAM FEBRUARY DOUBLE VOLUME],
						[VENEZUELA NEW SP BONUS],
						[VENEZUELA FEBRUARY DOUBLE VOLUME]
					INTO [dbo].[WRK_24057_BonusPoints]
					FROM #WRK_24057_BonusPoints	

				CREATE INDEX IX_WRK_24057_BonusPoints_PK_Distributor ON [dbo].[WRK_24057_BonusPoints](PK_Distributor)

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
							(ISNULL(P.[SAMCAMNEW SP BONUS],0) + ISNULL(P.[SAMCAM FEBRUARY DOUBLE VOLUME],0) + ISNULL(P.[VENEZUELA NEW SP BONUS],0) + ISNULL(P.[VENEZUELA FEBRUARY DOUBLE VOLUME],0)) AS [Bonus],
							ISNULL(P.[Points],0) + (ISNULL(P.[SAMCAMNEW SP BONUS],0) + ISNULL(P.[SAMCAM FEBRUARY DOUBLE VOLUME],0) + ISNULL(P.[VENEZUELA NEW SP BONUS],0) + ISNULL(P.[VENEZUELA FEBRUARY DOUBLE VOLUME],0)) AS [TotalPoints],
							P.iStartDate,
							P.iEndDate
						FROM #WRK_24057_BonusPoints AS P WITH (NOLOCK)

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
		IF @Step >= 6 AND EXISTS (SELECT 1 FROM #Event_SetupEventQualification)
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

			INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q03,Q12,Q21,Q22,Q25,Q44,Q46,Q50) 
				SELECT 
					PK_Distributor,
					@PK_Event AS [PK_Event],
					IIF(d.DSSPTeam = 'SP',1,0) AS Q01, --FQS and Above
					D.Q2  AS Q2, --New FQS Qualify or Requalify (Qual dates:  Mar 2024 - Jun 2024)
					D.Q3 AS Q3, --New World Team (Team Qual Dates  Mar 2024 - June 2024)
					D.Q12 AS Q12, -- QS, QV, PQS, SQS, 2QS, 5QS (Qual date:  June thorugh the Event date 2024)
					IIF(d.DSTeam IN ('G','M','P','A','B','C'),1,0) AS Q21, --TAB Team
					IIF(d.DSTeam IN ('SP','W'),1,0) AS Q22, --FQS (Non-Tab)
					IIF(d.CountryCode = 'VE',1,0) AS Q25, --COP: VE
					IIF(d.DSTeam IN ('P','A','B','C') AND EXISTS (SELECT 1 FROM #Countries AS c WHERE c.sCountryCode = d.CountryCode ),1,0) AS Q44, -- SAM CAM President's Team Member
					IIF(d.CountryCode = 'BR',1,0) AS Q46, --COP: Brazil
					IIF(d.IsTicketPurchaser = 1 AND NOT EXISTS (SELECT 1 FROM #Countries AS c WHERE c.sCountryCode = d.CountryCode ),1,0) AS Q50 --DS Out of SAMCAM with ticket
				FROM #DS AS D WITH (NOLOCK)  
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)

			------------------------------------------------------------------------------------------------
			-- List qualifications
			------------------------------------------------------------------------------------------------
			IF EXISTS (SELECT 1 FROM #ListsQsMapping) 
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
			IF EXISTS (SELECT 1 FROM #SKUsQsMapping)
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
			
			------------------------------------------------------------------------------------------------
			-- Other qualifications
			------------------------------------------------------------------------------------------------
			BEGIN

			--AWT 2024 Qualify OR Re-qualify (NON-TAB) (Qual dates: Feb 2024 - Jun 2024)

			DROP TABLE IF EXISTS #Q11

			SELECT DISTINCT t.PK_Distributor 
			INTO #Q11
			FROM #DS AS d
				INNER JOIN [dbo].[AWT_Qualifiers_Tracking] AS t WITH (NOLOCK) 
					ON d.PK_Distributor = t.PK_Distributor
				INNER JOIN [AWT] AS a WITH (NOLOCK) 
					ON t.PK_Distributor = a.PK_Distributor AND t.AWTYear = a.AWTYear
			WHERE t.AWTYear = 2024 AND ([Feb] = 1 OR [Mar] = 1 OR [Apr] = 1 OR [May] = 1 OR [Jun] = 1) AND a.IsNonTAB = 1

			 CREATE INDEX IX_#Q11_PK_Distributor ON #Q11(PK_Distributor);

			 UPDATE E
			 SET 
				 Q11 = 1
			 FROM #EventQual AS E
				INNER JOIN #Q11 AS Q11
				ON E.PK_Distributor = Q11.PK_Distributor			 

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
					E01 = (Q01 | Q02 | Q12 | Q28 | Q44)
					
				UPDATE 
					#EventQual
				SET
					E03 = ((E01 & (Q13 | Q14)) | Q30 | Q44)

				UPDATE 
					#EventQual
				SET
					E04 = ((E01 & (Q15 | Q16)) | Q03 | Q31  | Q44)
					
				UPDATE 
					#EventQual
				SET
					E05 = ((E01 & (Q17 | Q18)) | Q32 | Q44)
					
				UPDATE 
					#EventQual
				SET
					E06 = ((E01 & ((Q19 | Q20) | Q33)) & ~Q44 & ~Q50)
				
				UPDATE 
					#EventQual
				SET
					E07 = ((E01 & (Q21 | (Q22 & Q23)) | Q24) | Q34  | Q44)
				
				UPDATE 
					#EventQual
				SET
					E02 = ((E01 & ((Q01 & (Q05 | Q06 | Q07 | Q08 | Q09 | Q10 | Q11)) | Q21 | Q04)) | Q29 | (E01 & Q25 & (Q22 & (Q26  | Q27))) | Q44 | (E07 & Q46))

				UPDATE 
					#EventQual
				SET
					E08 = ((E01 & (Q02 | Q12)) | Q35)

				UPDATE 
					#EventQual
				SET
					E09 = (Q36)

				UPDATE 
					#EventQual
				SET
					E10 = (Q37)

				UPDATE 
					#EventQual
				SET
					E11 = (Q38)

				UPDATE 
					#EventQual
				SET
					E12 = (Q39)

				UPDATE 
					#EventQual
				SET
					E13 = (Q40)

				UPDATE 
					#EventQual
				SET
					E14 = (Q41)

				UPDATE 
					#EventQual
				SET
					E15 = (Q42)

				UPDATE 
					#EventQual
				SET
					E16 = (Q45)

				UPDATE 
					#EventQual
				SET
					E17 = (E01)

				UPDATE 
					#EventQual
				SET
					E18 = (Q44)

				UPDATE 
					#EventQual
				SET
					E19 = (Q44 | E03)

				UPDATE 
					#EventQual
				SET
					E20 = (Q44 | E05)
 
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


 
 