CREATE PROCEDURE [dbo].[usp_EventQual_SAMCAM_FSL_Oct24]
	@Parameters NVARCHAR(MAX) = NULL
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_SAMCAM_FSL_Oct24

	USE:	
	
			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			DECLARE @e int, @em varchar(4000), @param nvarchar(max)
			
			SET @param = N'{"cleanUp":1,"step":11}'

			EXEC dbo.usp_EventQual_SAMCAM_FSL_Oct24 @Parameters= @param, @IsDevQA = 0, @Error = @e OUTPUT, @ErrorMessage = @em OUTPUT 
			
			SELECT @e AS [Error], @em AS [ErrorMessage]

			GO

	DESCRIPTION: 

	NOTES:	

	DEBUG TABLES:	
		
	DEPENDENCIES:
	
	WORK TABLES (WRK):

	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2024-07-12		alejandramed		Initial 
	1.0.1	2024-07-18		JuanGue				BugFix #1353515 The id is in list and is not qualifying.
												#1353516 The id is in not qualifying to any level
												#1353526 The id in VE is qualifying twice to each event. 1,1,2,2,3,3,4,4
	1.0.2	2024-07-18		JuanGue				#1354384 The id is in List 60785 and it is not qualifying to E1.
	1.0.3	2024-07-19		JuanGue				#1354390 The id as acumulated 2500 TVP in 4 months should qualify to E1
												#1354411 The id should not qualify to E4 since it has only 14K points and Oct Bonus cannot be aplied
	1.0.4	2024-07-22		JuanGue				#1354385 The id qualifies in middle month and is not detected as new QS
	1.0.5	2024-07-22		JuanGue				E40 added
	1.0.6	2024-07-26		JuanGue				#1355414 #1355295 #1355169 BugFixes
	1.0.7	2024-07-26		JuanGue				#1355456 CR Q9 AWT
	1.0.8	2024-08-12		alejandramed		BRD v2
	1.0.9	2024-08-19		alejandramed		Bug #1358919: 24089 - SAMCAM LDW FSL Oct 2024 Q3 HN E7 30K
	1.0.10	2024-08-29		alejandramed		User Story 1360056: 24089 - SAM CAM LDW FSL Oct 2024 - BRD V3
	1.0.11	2024-09-03		alejandramed		Removing Q10 from E3 on Venezuela; Udating E6 name on Chile
	1.0.12	2024-09-04		alejandramed		Bug 1361328: 24089 - SAMCAM LDW FSL Oct Pe bonus E1
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
			[QSVolumePercentage] [int] NULL
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

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
				
	SELECT @Error = 0, @ErrorMessage = '';	

BEGIN TRY
		
	-- Variables for json values

	DECLARE  @Step INT,@CleanUp BIT  

	-- Getting parameters values for json

	SELECT   
		@CleanUp = cleanUp, 
		@Step = step
	FROM OPENJSON(@Parameters)
	WITH ( 
			cleanUp BIT '$.cleanUp', 
			step INT '$.step'
		)
	 
	-- Default values 
	SET @CleanUp = ISNULL(@CleanUp,1)
	SET @Step = IIF(@Step IS NULL,11, @Step)

	------------------------------------------------------------------------------------------------
	-- Tables and variables
	------------------------------------------------------------------------------------------------
	BEGIN

		-- *  Custom

		DECLARE @ColumnToPivot NVARCHAR(MAX),
				@SqlStatement NVARCHAR(MAX)

		DECLARE @PK_Event_General INT
		,@PK_Event_PM INT = 200590
		,@PK_Event_PE INT = 200591
		,@PK_Event_AR_UY_PY INT = 200592
		,@PK_Event_CI INT = 200593
		,@PK_Event_CO INT = 200594
		,@PK_Event_BL INT = 200615
		,@PK_Event_EC INT = 200618
		,@PK_Event_GT_SV INT = 200620
		,@PK_Event_HN INT = 200622
		,@PK_Event_CR  INT = 200623
		,@PK_Event_NI INT = 200642
		,@PK_Event_VE INT = 200643	
		,@PK_Event_DR INT = 200649
		,@SAMCAMCountries VARCHAR(MAX) = 'SV,DR,CI,BL,EC,AR,NI,PM,UY,PE,CO,HN,VE,PY,CR,GT'
		,@QSQualDateFrom DATETIME = '2024-10-01'
		,@QSQualDateTo DATETIME = '2024-10-31'
		,@NewFQSBonusFrom INT = 202407
		,@NewFQSBonusTo INT  = 202410
		,@NewFQSFrom DATETIME = '2024-07-01'
		,@NewFQSTo DATETIME = '2024-10-31'
	
		DROP TABLE IF EXISTS #Locations

		CREATE TABLE #Locations
		(			
			[PK_Event] [int],
			[Location] [varchar](100),
			[CountryCode]	varchar(10), 
			[PK_Country] [int],
			[ctrl] [bit] DEFAULT(0)
		)
 
		INSERT INTO #Locations([PK_Event],[Location], [CountryCode],[PK_Country])
		SELECT 
			@PK_Event_PM AS [PK_Event],
			'Panama' AS [Location],
			'PM' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'PM' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_PE AS [PK_Event],
			'Peru' AS [Location],
			'PE' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'PE' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_AR_UY_PY AS [PK_Event],
			'Argentina,Uruguay,Paraguay' AS [Location],
			'AR,UY,PY' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'AR' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_AR_UY_PY AS [PK_Event],
			'Argentina,Uruguay,Paraguay' AS [Location],
			'AR,UY,PY' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'UY' ) AS PK_Country
				UNION
		SELECT 
			@PK_Event_AR_UY_PY AS [PK_Event],
			'Argentina,Uruguay,Paraguay' AS [Location],
			'AR,UY,PY' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'PY' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_CI AS [PK_Event],
			'Chile' AS [Location],
			'CI' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'CI' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_CO AS [PK_Event],
			'Colombia' AS [Location],
			'CO' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'CO' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_BL AS [PK_Event],
			'Bolivia' AS [Location],
			'BL' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'BL' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_EC AS [PK_Event],
			'Ecuador' AS [Location],
			'EC' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'EC' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_GT_SV AS [PK_Event],
			'Guatemala,El Salvador' AS [Location],
			'GT,SV' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'GT' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_GT_SV AS [PK_Event],
			'Guatemala,El Salvador' AS [Location],
			'GT,SV' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'SV' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_HN AS [PK_Event],
			'Honduras' AS [Location],
			'HN' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'HN' ) AS PK_Country
		UNION
		SELECT  
			@PK_Event_CR AS [PK_Event],
			'Costa Rica' AS [Location],
			'CR' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'CR' ) AS PK_Country
		UNION
		SELECT  
			@PK_Event_NI AS [PK_Event],
			'Nicaragua' AS [Location],
			'NI' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'NI' ) AS PK_Country
		UNION
		SELECT 
			@PK_Event_VE AS [PK_Event],
			'Venezuela' AS [Location],
			'VE' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'VE' ) AS PK_Country
		UNION
		SELECT  
			@PK_Event_DR AS [PK_Event],
			'Dominican Republic' AS [Location],
			'DR' AS [CountryCode],
			(SELECT nCountryID FROM v_Countries WHERE sCountryCode = 'DR' ) AS PK_Country

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
				(@PK_Event_PM, 60602,20),
				(@PK_Event_PM, 60596,22),
				(@PK_Event_PM, 60597,23),
				(@PK_Event_PM, 60598,24),
				(@PK_Event_PM, 60599,25),
				(@PK_Event_PM, 60600,26),
				(@PK_Event_PM, 60601,27),
				(@PK_Event_PM, 61148,28), -- BRD v2

				(@PK_Event_PE, 60609,20),
				(@PK_Event_PE, 60603,22),
				(@PK_Event_PE, 60604,23),
				(@PK_Event_PE, 60605,24),
				(@PK_Event_PE, 60606,25),
				(@PK_Event_PE, 60607,26),
				(@PK_Event_PE, 60608,27),
				(@PK_Event_PE, 61149,28), -- BRD v2
				

				(@PK_Event_AR_UY_PY, 60618,20),
				(@PK_Event_AR_UY_PY, 60612,22),
				(@PK_Event_AR_UY_PY, 60613,23),
				(@PK_Event_AR_UY_PY, 60614,24),
				(@PK_Event_AR_UY_PY, 60615,25),
				(@PK_Event_AR_UY_PY, 60616,26),
				(@PK_Event_AR_UY_PY, 60617,27),
				(@PK_Event_AR_UY_PY, 61150,28), -- BRD v2
				
				(@PK_Event_CI, 60624,20),
				(@PK_Event_CI, 60619,22),
				(@PK_Event_CI, 60620,23),
				(@PK_Event_CI, 60621,24),
				(@PK_Event_CI, 60625,25),
				(@PK_Event_CI, 60622,26),
				(@PK_Event_CI, 60623,27),
				(@PK_Event_CI, 61151,28), -- BRD v2

				(@PK_Event_CO, 60631,20),
				(@PK_Event_CO, 60626,22),
				(@PK_Event_CO, 60627,23),
				(@PK_Event_CO, 60628,24),
				(@PK_Event_CO, 60632,25),
				(@PK_Event_CO, 60629,26),
				(@PK_Event_CO, 60630,27),
				(@PK_Event_CO, 61152,28), -- BRD v2

				(@PK_Event_BL, 60651,20),
				(@PK_Event_BL, 60646,22),
				(@PK_Event_BL, 60647,23),
				(@PK_Event_BL, 60648,24),
				(@PK_Event_BL, 60652,25),
				(@PK_Event_BL, 60649,26),
				(@PK_Event_BL, 60650,27),
				(@PK_Event_BL, 61153,28), -- BRD v2

				(@PK_Event_EC, 60660,20),
				(@PK_Event_EC, 60654,22),
				(@PK_Event_EC, 60655,23),
				(@PK_Event_EC, 60656,24),
				(@PK_Event_EC, 60657,25),
				(@PK_Event_EC, 60658,26),
				(@PK_Event_EC, 60659,27),
				(@PK_Event_EC, 61154,28), -- BRD v2

				(@PK_Event_GT_SV, 60667,20),
				(@PK_Event_GT_SV, 60661,22),
				(@PK_Event_GT_SV, 60662,23),
				(@PK_Event_GT_SV, 60663,24),
				(@PK_Event_GT_SV, 60664,25),
				(@PK_Event_GT_SV, 60665,26),
				(@PK_Event_GT_SV, 60666,27),
				(@PK_Event_GT_SV, 61155,28), -- BRD v2

				(@PK_Event_HN, 60680,31),
				(@PK_Event_HN, 60670,33),
				(@PK_Event_HN, 60671,34),
				(@PK_Event_HN, 60672,35),
				(@PK_Event_HN, 60674,36),
				(@PK_Event_HN, 60675,37),
				(@PK_Event_HN, 60676,38),
				(@PK_Event_HN, 60677,39),
				(@PK_Event_HN, 60678,40),
				(@PK_Event_HN, 60679,41),
				(@PK_Event_HN, 61156,42), -- BRD v2

				(@PK_Event_CR, 60703,25),
				(@PK_Event_CR, 60696,27),
				(@PK_Event_CR, 60697,28),
				(@PK_Event_CR, 60698,29),
				(@PK_Event_CR, 60699,30),
				(@PK_Event_CR, 60700,31),
				(@PK_Event_CR, 60701,32),
				(@PK_Event_CR, 60702,33), 
				(@PK_Event_CR, 61157,34), -- BRD v2

				(@PK_Event_NI, 60760,19),
				(@PK_Event_NI, 60752,22),
				(@PK_Event_NI, 60753,23),
				(@PK_Event_NI, 60754,24),
				(@PK_Event_NI, 60755,25),
				(@PK_Event_NI, 60756,26),
				(@PK_Event_NI, 60757,27),
				(@PK_Event_NI, 60758,28),
				(@PK_Event_NI, 60759,29), 
				(@PK_Event_NI, 61158,30), -- BRD v2

				(@PK_Event_VE, 60761,11),
				(@PK_Event_VE, 60762,12),
				(@PK_Event_VE, 60763,13),
				(@PK_Event_VE, 60764,14),
				(@PK_Event_VE, 60765,15),
				(@PK_Event_VE, 60766,16),
				(@PK_Event_VE, 60767,17),  
				(@PK_Event_VE, 61159,18), -- BRD v2
				(@PK_Event_VE, 61322,21), -- BRD v3

				(@PK_Event_DR, 60785,19),
				(@PK_Event_DR, 60786,20),
				(@PK_Event_DR, 60787,21),
				(@PK_Event_DR, 60788,22), 
				(@PK_Event_DR, 61160,23) -- BRD v2

		DROP TABLE IF EXISTS #SKUsQsMapping

		CREATE TABLE #SKUsQsMapping
		(
			ID INT IDENTITY(1,1),
			PK_Event INT,
			SKUCode VARCHAR(10),
			QId INT
		)

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
	
	------------------------------------------------------------------------------------------------
	-- Volume qualifications setup
	------------------------------------------------------------------------------------------------
	BEGIN

		DROP TABLE IF EXISTS #Event_SetupEventQualification

		CREATE TABLE #Event_SetupEventQualification
		(
			ID int IDENTITY(1,1),
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
			[HasQualReference]		bit DEFAULT 0,
		)


		;WITH cte_Quals AS
		(
			--Q3	Achieve 2,500 TVP in any one month (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			3 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_NI)
			UNION
			--Q3 Achieve 1,500 TVP in any one month (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			3 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			1500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_HN,@PK_Event_CR,@PK_Event_DR)
			UNION
			--Q4 Achieve 2,500 TVP in any one month (Jul 2024 - Oct 2024) (Event date)	
			SELECT 
			l.PK_Event,
			4 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_NI)
			UNION
			--Q4 Achieve 1,500 TVP in any one month (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			4 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			1500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_HN,@PK_Event_CR,@PK_Event_DR)
			UNION
			--Q4 Accumulate 3,000 TVP in four consecutive months (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			4 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			3000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_VE
			UNION
			--Q5 Accumulate 5,000 TVP in four consecutive months (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			5 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_NI)
			UNION
			--Q5 Accumulate 2,500 TVP in four consecutive months (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			5 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_HN,@PK_Event_CR,@PK_Event_DR)
			UNION
			--Q5 Accumulate 3,000 TVP in four consecutive months (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			5 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			3000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_VE
			UNION
			--Q6 Accumulate 5,000 TVP in four consecutive months (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			6 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_NI)
			UNION
			--Q6 Accumulate 2,500 TVP in four consecutive months (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			6 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_HN,@PK_Event_CR,@PK_Event_DR)
			UNION
			--Q6 Accumulate 15,000 TVP (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			6 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_VE
			UNION
			--Q7 Achieve 2,500 TVP each month in any three months (Jun 2024 - Sep 2024) 
			SELECT 
			l.PK_Event,
			7 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			3 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_NI)
			UNION
			--Q7 Achieve 2,500 TVP in any one month  (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			7 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_HN 
			UNION
			--Q7 Accumulate 15,000 TVP (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			7 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_VE
			UNION						
			--Q7 Accumulate 10,000 TVP in four consecutive months (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			7 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			10000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_CR 
			UNION
			--Q8 Achieve 2,500 TVP each month in any three months (Jul 2024 - Oct 2024) (Event date) 
			SELECT 
			l.PK_Event,
			8 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			3 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_NI)
			UNION
			--Q8 Achieve 2,500 TVP in any one month  (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			8 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_HN 
			UNION
			--Q8 Accumulate 20,000 TVP (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			8 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			20000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_VE
			UNION						
			--Q8 Accumulate 10,000 TVP in four consecutive months (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			8 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			10000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_CR 
			UNION						
			--Q8 Accumulate 10,000 TVP (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			8 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			10000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_DR
			UNION
			--Q9 Achieve 5,000 TVP any one month (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			9 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV)
			UNION
			--Q9 Accumulate 5,000 TVP in four consecutive months (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			9 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_HN 
			UNION
			--Q9 Accumulate 20,000 TVP (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			9 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			20000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_VE
			UNION						
			--Q9 Achieve 5,000 TVP any one month  (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			9 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_NI
			UNION						
			--Q9 Accumulate 10,000 TVP (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			9 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			10000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_DR
			UNION
			--Q10 Achieve 5,000 TVP any one month (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			10 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_NI)
			UNION
			--Q10 Accumulate 5,000 TVP in four consecutive months (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			10 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_HN 
			UNION						
			--Q10 Accumulate 15,000 TVP (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			10 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_DR
			UNION
			--Q11 Accumulate 10,000 TVP in four consecutive months (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			11 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			10000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_HN,@PK_Event_NI)
			UNION
			--Q11 Accumulate 15 000 TVP (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			11 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_CR 
			UNION
			--Q11 Accumulate 15,000 TVP (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			11 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_DR	 
			UNION
			--Q12 Accumulate 10,000 TVP in four consecutive months (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			12 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			10000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_HN,@PK_Event_NI)
			UNION
			--Q12 Accumulate 15,000 TVP (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			12 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_CR 		
			UNION	 
			--Q13 Accumulate 20,000 TVP (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			13 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			20000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_CR 		
			UNION	 
			--Q14 Accumulate 20,000 TVP (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			14 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			20000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_CR 
			UNION
			--Q14 Accumulate 15 000 TVP (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			14 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_NI 
			UNION
			--Q14 Accumulate 1,000 PPV in a month within the period  (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			14 AS QualificationNumber,
			1 AS Part, 
			'PPV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			1000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_DR
			UNION
			--Q15 Accumulate 15 000 TVP (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			15 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_HN)
			UNION
			--Q15 Accumulate 1,000 PPV in a month within the period  (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			15 AS QualificationNumber,
			1 AS Part, 
			'PPV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			1000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_CR
			UNION
			--Q15 Accumulate 15,000 TVP (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			15 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_NI
			UNION
			--Q15 Accumulate 1,000 PPV in a month within the period (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			15 AS QualificationNumber,
			1 AS Part, 
			'PPV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			1000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_DR
			UNION
			--Q16 Accumulate 15,000 TVP (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			16 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			15000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_HN)
			UNION
			--Q16 Accumulate 1,000 PPV in a month within the period (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			16 AS QualificationNumber,
			1 AS Part, 
			'PPV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			1000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_CR
			UNION
			--Q16 Accumulate 25,000 TVP (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			16 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			25000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_NI
			UNION
			--Q17 Accumulate 20,000 TVP (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			17 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			20000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_HN)
			UNION
			--Q17 Accumulate 25,000 TVP (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			17 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			25000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_NI
			UNION
			--Q18 Accumulate 20,000 TVP (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			18 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			20000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_HN)			 
			UNION
			--Q19 Accumulate 1,000 PPV within the period  (Jun 2024 - Sep 2024) 
			SELECT 
			l.PK_Event,
			19 AS QualificationNumber,
			1 AS Part, 
			'PPV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			1000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_HN		 
			UNION
			--Q19 Achieve 2,500 TVP each month in any three months (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			19 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			3 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_CR	
			UNION
			--Q20 Accumulate 1,000 PPV within the period (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			20 AS QualificationNumber,
			1 AS Part, 
			'PPV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			1000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_HN	
			UNION
			--Q20 Achieve 2,500 TVP each month in any three months (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			20 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			3 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_CR	
			UNION
			--Q21 Achieve 4,000 TVP any one month (Jun 2024 - Sep 2024)
			SELECT 
			l.PK_Event,
			21 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			4000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_CR	
			UNION
			--Q22 Achieve 4,000 TVP any one month (Jul 2024 - Oct 2024) (Event date)
			SELECT 
			l.PK_Event,
			22 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			4000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_CR
			UNION
			--Q23 Achieve 2,500 TVP each month in any three months (Jun 2024 - Sep 2024) 
			SELECT 
			l.PK_Event,
			23 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			3 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_HN
			UNION
			--Q24 Achieve 2,500 TVP each month in any three months (Jul 2024 - Oct 2024) (Event date) 
			SELECT 
			l.PK_Event,
			24 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			3 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_HN
			UNION
			--Q25 Achieve 5,000 TVP any one month (Jun 2024 - Sep 2024) 
			SELECT 
			l.PK_Event,
			25 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_HN
			UNION
			--Q26 Achieve 5,000 TVP any one month (Jul 2024 - Oct 2024) (Event date) 
			SELECT 
			l.PK_Event,
			26 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			1 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_HN
			UNION
			--Q27 Accumulate 30,000 TVP (Jun 2024 - Sep 2024) 
			SELECT 
			l.PK_Event,
			27 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-06-01' AS [dStartDate], 
			'2024-09-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			30000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_HN
			UNION
			--Q28 Accumulate 30,000 TVP (Jul 2024 - Oct 2024) (Event date) 
			SELECT 
			l.PK_Event,
			28 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			'2024-07-01' AS [dStartDate], 
			'2024-10-01' AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			30000 AS [GoalPoints], 
			NULL AS [Countries],
			0 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event = @PK_Event_HN

			) 

	INSERT INTO #Event_SetupEventQualification(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries)
	SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries 
	FROM cte_Quals



		IF @IsDevQA = 0
		BEGIN	

			DELETE s 
			FROM [Event].[SetupEventQualification] AS s WITH (NOLOCK)  
				INNER JOIN #Locations AS l
					ON s.PK_Event = l.PK_Event
	 
			INSERT INTO [Event].[SetupEventQualification](PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries 
			FROM #Event_SetupEventQualification
		 
		END
		ELSE IF @IsDevQA = 3
		BEGIN	

			DELETE s 
			FROM ##Event_SetupEventQualification_amed AS s  
				INNER JOIN #Locations AS l
					ON s.PK_Event = l.PK_Event
	 
			INSERT INTO ##Event_SetupEventQualification_amed(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries 
			FROM #Event_SetupEventQualification

		END
	
	END

	------------------------------------------------------------------------------------------------
	-- Qualifications block
	------------------------------------------------------------------------------------------------
	BEGIN 

		IF (@IsDevQA = 2) THROW 60000, N'Unit test Error', 1; --Forcing to fail for unit testing purpose
	 		
		--Step 1: DS
		IF @Step >= 1
		BEGIN

			PRINT 'Executing step 1'

			INSERT INTO #TimeLog VALUES ('#DS', 1, 1, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #Countries

				CREATE TABLE #Countries
				(
					PK_Event INT,
					nCountryID		int,   
					sCountryCode	varchar(10), 
					sCountryCodeISO varchar(10), 
					sCountryName	varchar(150)
				)

				INSERT INTO #Countries(nCountryID,sCountryCode,sCountryCodeISO,sCountryName) 
					SELECT DISTINCT nCountryID,sCountryCode,sCountryCodeISO,sCountryName
					FROM dbo.v_Countries
					WHERE sCountryCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar](@SAMCAMCountries, ','))

				DROP TABLE IF EXISTS #DS

				CREATE TABLE #DS
				(
					PK_Event			int,  
					PK_Distributor		int,   
					DSCurrentTeam		varchar(10),        
					DSSubTeam			varchar(10),        
					DSSPTeam			varchar(10),               
					dSPQualDate			datetime2,
					SPQualDate			int,
					dRequalSPQualDate	datetime2,
					RequalSPQualDate	int,
					CountryCode			varchar(5),
					PK_Country			int,
					QSQualDate			smalldatetime,		
					QSActualQualDate	smalldatetime,	
					SPDemotionDate		smalldatetime,	
					IsFromList			bit default(0),
					IsTicketPurchaser	bit default(0),
					dQPQualification datetime2,
					dQPDemotion datetime2
				)

				--FQS AND DS

				INSERT INTO #DS
				(
					PK_Event,
					PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,
					[SPQualDate],
					dRequalSPQualDate,
					RequalSPQualDate,
					CountryCode,
					PK_Country,
					QSQualDate,		
					QSActualQualDate,
					SPDemotionDate,
					dQPQualification,
					dQPDemotion

				)
				SELECT DISTINCT  
				C.PK_Event,
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				D.dSupervisorqualification AS dSPQualDate, 
				CAST(CONVERT(varchar(6), d.dSupervisorQualification, 112) AS int) AS [SPQualDate],
				D.dSupervisorReQualification AS dRequalSPQualDate, 
				CAST(CONVERT(varchar(6), d.dSupervisorReQualification, 112) AS int) AS [RequalSPQualDate],
				D.sDistributorCountryProcessingCode AS CountryCode,
				C.PK_Country,
				D.dQSQualification,				
				D.dQSQualification_Actual,
				D.dSPDemotion,
				D.dQPQualification,
				D.dQPDemotion
				FROM dbo.v_Distributor AS D  
				INNER JOIN #Locations AS C
					ON D.nDistributorCountryProcessingID = C.PK_Country
				WHERE        
					D.StatusCode = 'COMPLETE'        
					AND D.sType IN  ('SP','DS')		

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
					PK_Event,
					PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,	
					[SPQualDate],
					dRequalSPQualDate,
					RequalSPQualDate,
					CountryCode,	
					PK_Country,
					IsFromList,
					dQPQualification,
					dQPDemotion
				)
				SELECT DISTINCT  
				L.PK_Event,
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate,   
				CAST(CONVERT(varchar(6), d.dSupervisorQualification, 112) AS int) AS [SPQualDate],
				D.dSupervisorReQualification AS dRequalSPQualDate, 
				CAST(CONVERT(varchar(6), d.dSupervisorReQualification, 112) AS int) AS [RequalSPQualDate],
				D.sDistributorCountryProcessingCode AS CountryCode,
				D.nDistributorCountryProcessingID,
				1 AS IsFromList,
				D.dQPQualification,
				D.dQPDemotion
				FROM dbo.v_Distributor AS D  
					INNER JOIN #DSList AS L
						ON D.nDistributorID = L.PK_Distributor
				WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = L.PK_Distributor AND T.PK_Event = L.PK_Event)

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
					PK_Event,
					PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,
					[SPQualDate],
					dRequalSPQualDate,
					RequalSPQualDate,
					CountryCode,
					PK_Country,
					QSQualDate,		
					QSActualQualDate,
					SPDemotionDate,
					IsTicketPurchaser,
					dQPQualification,
					dQPDemotion
				)
				SELECT DISTINCT       
				S.PK_Event,
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate,      
				CAST(CONVERT(varchar(6), d.dSupervisorQualification, 112) AS int) AS [SPQualDate],
				D.dSupervisorReQualification AS dRequalSPQualDate, 
				CAST(CONVERT(varchar(6), d.dSupervisorReQualification, 112) AS int) AS [RequalSPQualDate],
				D.sDistributorCountryProcessingCode AS CountryCode,
				D.nDistributorCountryProcessingID,
				D.dQSQualification,				
				D.dQSQualification_Actual,
				D.dSPDemotion,
				1 AS IsTicketPurchaser,
				D.dQPQualification,
				D.dQPDemotion
				FROM dbo.v_Distributor AS D  
					INNER JOIN #DSSKUs AS S
						ON D.nDistributorID = S.PK_Distributor
				WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = S.PK_Distributor AND T.PK_Event = S.PK_Event)

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

			DROP TABLE IF EXISTS #vExec

			SELECT DISTINCT PK_Event,
			0 AS [ctrl]
			INTO #vExec
			FROM #Locations

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

			WHILE EXISTS (SELECT 1 FROM #vExec WHERE ctrl = 0)
			BEGIN

			SELECT @PK_Event_General = MIN(PK_Event) FROM #vExec WHERE ctrl = 0

			PRINT 'Getting volume for ' + CAST(@PK_Event_General AS VARCHAR(10))
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
					FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event_General
	
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
						@PK_Event_General AS [PK_Event], --AR,BL,CI,CO,CR,DR,EC,GT,HN,NI,PM,PE,PY,SV,UY,VE
						D.PK_Distributor AS PK_Distributor,
						Dd.sDistributorID AS DistributorID,
						@iStartDate AS [iStartDate],
						@iEndDate AS [iEndDate],
						@dStartDate AS [dStartDate],
						@dEndDate AS [dEndDate],
						DD.dSupervisorQualification 
					FROM #DS AS D
					INNER JOIN v_Distributor AS DD
						ON D.PK_Distributor = DD.nDistributorID	
					WHERE D.PK_Event = @PK_Event_General

					CREATE INDEX IX_#tmp_DS_PK_Distributor ON #tmp_DS(PK_Distributor);	

					IF (@IsDevQA = 0)
					BEGIN
						
						DROP INDEX IF EXISTS [IX_DS_PK_Distributor]
							ON [tmp].[DS];

						DELETE d FROM [tmp].[DS] AS d WHERE d.PK_Event = @PK_Event_General

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

						DELETE d FROM ##tmp_DS_amed AS d WHERE d.PK_Event = @PK_Event_General

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
							
					--Input
					--[tmp].[DS]
					--[Event].[SetupEventQualification]

					EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event_General, @SourceType = 1,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
					--Output [Event].[DSPoints]

					IF ISNULL(@Error,0) != 0
					BEGIN
						SELECT 'usp_GetDSVolume' AS [usp], @Error AS [Error], @ErrorMessage AS [ErrorMessage]
						RETURN;
					END

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;
		
				END
				ELSE
				IF (@IsDevQA = 3)
				BEGIN
					INSERT INTO #TimeLog VALUES ('usp_GetDSVolume', 3, 2, GETUTCDATE(), NULL);

					--Input
					--##tmp_DS_amed
					--##Event_SetupEventQualification_amed

					EXEC [dbo].[##usp_GetDSVolume_amed] @PK_Event = @PK_Event_General, @SourceType = 1,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
					--Output
					--##Event_DSPoints_amed
			
					IF ISNULL(@Error,0) != 0
					BEGIN
						SELECT '##usp_GetDSVolume_amed' AS [usp], @Error AS [Error], @ErrorMessage AS [ErrorMessage]
						RETURN;
					END
					 
					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;
		
				END
			
			------------------------------------------------------------------------------------------------
			-- 3.5 Getting #Event_DSPoints AND #Event_DSPoints_Validations
			------------------------------------------------------------------------------------------------
		
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints', 3, 5, GETUTCDATE(), NULL);

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
					WHERE PK_Event = @PK_Event_General

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
					WHERE PK_Event = @PK_Event_General

				END		
			
			UPDATE #vExec
			SET [Ctrl] = 1
			WHERE PK_Event = @PK_Event_General

			END

			CREATE CLUSTERED INDEX [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints ([PK_Distributor]) 
			CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints ([MetricType])

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

				INSERT INTO #tmp_DSQualDef([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[Bonus],[QSVolume])
					SELECT 
						D.PK_Event,
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
						M.PK_AssociatedID AS PK_AssociatedID,
						C.Countries,
						C.Bonus,
						C.[QSVolume]
					FROM #DS AS D					
						LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
							ON D.PK_Distributor = M.PK_Distributor
						OUTER APPLY (SELECT C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated,C.MetricType,C.GoalPoints,C.MinPoints,C.QualificationNumber,C.Part,C.Countries,C.Bonus,C.[QSVolume] FROM  #Event_SetupEventQualification AS C WHERE C.PK_Event = D.PK_Event) AS C
						CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
					
				CREATE INDEX IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef(PK_Distributor);

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 4 AND [StepSubGroup] = 1;

			IF @IsDevQA = 0
			BEGIN

				INSERT INTO #TimeLog VALUES ('[tmp].[DSQualDef]', 4, 2, GETUTCDATE(), NULL);
								 
				DELETE [tmp].[DSQualDef] WHERE PK_Event = @PK_Event_General

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

		--Step 5: Bonuses
		IF @Step >= 5
		BEGIN
			
			PRINT 'Executing step 5'

			------------------------------------------------------------------------------------------------
			-- 5.1 Getting bonuses
			------------------------------------------------------------------------------------------------

			------------------------------------------------------------------------------------------------
			-- * NEW SP BONUS 
			------------------------------------------------------------------------------------------------

				DROP TABLE IF EXISTS #bNewFQS
								 
				SELECT PK_Event,PK_Distributor,SPQualDate  
				INTO #bNewFQS
				FROM #DS WHERE SPQualDate BETWEEN @NewFQSBonusFrom AND @NewFQSBonusTo --This Promotion Does not apply to Regular FQS or Requalified FQS.		 
				AND SPDemotionDate IS NULL

			------------------------------------------------------------------------------------------------
			-- * SPECIAL Jun DOUBLE VOLUME
			------------------------------------------------------------------------------------------------

				DROP TABLE IF EXISTS #SpecialBonusFQS

				SELECT PK_Event, PK_Distributor, PK_Country, SPQualDate
				INTO #SpecialBonusFQS
				FROM #DS AS d WHERE DSSPTeam = 'SP' 
				AND NOT EXISTS (SELECT 1 FROM #bNewFQS AS n WHERE n.PK_Distributor = d.PK_Distributor) --This Promotion is not applicable for New Supervisors. 
			
				DROP TABLE IF EXISTS #SpecialBonusFQSMonth

				--Nicaragua (NI)
				;WITH cte_NicaraguaVolume AS 
				(
					SELECT  
						P.PK_Event,
						P.PK_Distributor,
						P.RoyaltyMonth,
						P.[Points],
						ROW_NUMBER() OVER (PARTITION BY P.PK_Event,P.PK_Distributor ORDER BY P.[Points] DESC) AS row_num
					FROM #Event_DSPoints AS P
						INNER JOIN #SpecialBonusFQS AS d
							ON P.PK_Event = d.PK_Event AND P.PK_Distributor = d.PK_Distributor 
					WHERE P.PK_Event = @PK_Event_NI
					AND P.RoyaltyMonth IN (202406, 202407)
				)

				SELECT 
					d.PK_Event,
					d.PK_Distributor,
					IIF(d.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY, @PK_Event_CI, @PK_Event_CO, @PK_Event_BL, @PK_Event_EC, @PK_Event_GT_SV,@PK_Event_CR,@PK_Event_DR,@PK_Event_HN, @PK_Event_VE), 202406,
						IIF(d.PK_Event = @PK_Event_NI, P.RoyaltyMonth, NULL))	AS RoyaltyMonth
				INTO #SpecialBonusFQSMonth
				FROM #SpecialBonusFQS AS d
					LEFT JOIN cte_NicaraguaVolume AS P
						ON d.PK_Event = P.PK_Event AND d.PK_Distributor = P.PK_Distributor AND row_num = 1
 
			
			------------------------------------------------------------------------------------------------
			-- * Extra Bonus (Honduras (HN))
			------------------------------------------------------------------------------------------------

				INSERT INTO #TimeLog VALUES ('Lines', 3, 1, GETUTCDATE(), NULL);

				-- ) Getting uplines, only DS from Honduras
				--------------------------------------------------------------------------------
	 
				DROP TABLE IF EXISTS #Uplines CREATE TABLE #Uplines (PK_Event INT,PK_Distributor INT)

				INSERT INTO #Uplines(PK_Event,PK_Distributor)
				SELECT 
					D.PK_Event,
					D.PK_Distributor
				FROM #DS AS D
				WHERE D.PK_Event = @PK_Event_HN

				CREATE INDEX IX_#Uplines_PK_Distributor ON #Uplines(PK_Event,PK_Distributor);
				
				INSERT INTO #TimeLog VALUES ('FirstLine', 4, 1, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #FirstLine;

					SELECT 
						DL.PK_Distributor,
						M.PK_Event,
						DL.PK_DSDownline [PK_FirstLine]
					INTO #FirstLine
					FROM
						#Uplines M
					INNER JOIN
						dbo.v_dimDSLngDownline DL WITH (NOLOCK)
					ON
						M.PK_Distributor = DL.PK_Distributor
						AND 
						DL.SPLevelFromUL = 2
					INNER JOIN v_Distributor AS D
						ON DL.PK_DSDownline = D.nDistributorID 
				
				CREATE CLUSTERED INDEX [IX_FirstLine_PK_FirstLine] ON #FirstLine ([PK_FirstLine])

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 4 AND [StepSubGroup] = 1;

				INSERT INTO #TimeLog VALUES ('SecondLine', 4, 2, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #SecondLine;

					SELECT 
						L1.PK_Distributor,	
						L1.PK_Event,
						L1.PK_FirstLine,	
						DL.PK_DSDownline [PK_SecondLine]
					INTO #SecondLine
					FROM
						#FirstLine L1
					INNER JOIN
						dbo.v_dimDSLngDownline DL WITH (NOLOCK)
					ON
						L1.[PK_FirstLine] = DL.PK_Distributor
						AND 
						DL.SPLevelFromUL = 2
					INNER JOIN v_Distributor AS D
						ON DL.PK_DSDownline = D.nDistributorID  
				  
					CREATE CLUSTERED INDEX [IX_SecondLine_PK_SecondLine] ON #SecondLine ([PK_SecondLine])
					CREATE NONCLUSTERED INDEX [IX_SecondLine_PK_FirstLine] ON #SecondLine ([PK_FirstLine])

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 4 AND [StepSubGroup] = 2;

				INSERT INTO #TimeLog VALUES ('ThirdLine', 4, 3, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #ThirdLine;

					SELECT 
						 L2.PK_Distributor
						,L2.PK_Event
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
						DL.SPLevelFromUL = 2
					INNER JOIN v_Distributor AS D
						ON DL.PK_DSDownline = D.nDistributorID  

					CREATE CLUSTERED INDEX [IX_ThirdLine_PK_ThirdLine] ON #ThirdLine ([PK_ThirdLine])

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 4 AND [StepSubGroup] = 3;		

				/* INSERT ALL DOWNLINES TO LINEAGE TABLE */

				INSERT INTO #TimeLog VALUES ('Lineage', 5, 1, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #Lineage;
								
					SELECT 
						L1.PK_Distributor
						,L1.PK_Event
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

					SELECT L.PK_Event, L.UplineID, L.PK_Distributor
					INTO #LineageIDsUnique
					FROM
					(
							SELECT PK_Event, PK_Distributor  AS UplineID, PK_FirstDownline [PK_Distributor]
								FROM #Lineage WITH (NOLOCK)
							UNION
							SELECT PK_Event, PK_Distributor  AS UplineID, PK_SecondDownLine [PK_Distributor]
								FROM #Lineage WITH (NOLOCK)
							UNION
							SELECT PK_Event, PK_Distributor  AS UplineID, PK_ThirdDownLine [PK_Distributor]
								FROM #Lineage WITH (NOLOCK)
					) L

					CREATE INDEX IX_LineageIDsUnique_PK_Distributor ON #LineageIDsUnique(PK_Distributor)   
				
				DROP TABLE IF EXISTS #LineageFlags

				CREATE TABLE #LineageFlags(UplineID int,PK_Distributor int, PK_Event int, SPQualDate datetime, iSPQualDate int, IsNewSP BIT DEFAULT(0), IsTAB BIT DEFAULT(0), IsFQS BIT DEFAULT(0))
	
				INSERT INTO #LineageFlags(UplineID,PK_Distributor,PK_Event,SPQualDate,iSPQualDate,IsNewSP,IsTAB, IsFQS)
				SELECT 
					L.UplineID,
					DD.nDistributorID, 
					L.PK_Event,
					DD.dSupervisorqualification,
					CAST(CONVERT(varchar(6), DD.dSupervisorqualification , 112) AS int) AS [iSPQualDate],
					IIF(DD.dSupervisorqualification BETWEEN '2024-07-01' AND '2024-10-01', 1, 0) AS IsNewSP,
					IIF(DD.sType = 'SP', IIF(DD.dSupervisorqualification BETWEEN '2024-07-01' AND '2024-10-01', 0, 1),0) AS IsFQS,
					IIF(DD.sTeam IN ('G','M','P','A','B','C'), 1, 0) AS IsTAB
				FROM #LineageIDsUnique AS L
					INNER JOIN v_Distributor AS DD
						ON L.PK_Distributor = DD.nDistributorID 
 
			/* GETTING FIRST LINE CONTRIBUTION */  
	
			INSERT INTO #TimeLog VALUES ('Contribution_L1', 7, 1, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #Contribution_L1

				SELECT 
					l.PK_Distributor,
					l.PK_Event,
					l.PK_FirstDownLine 
				INTO #Contribution_L1
				FROM #Lineage l WITH (NOLOCK) 
					INNER JOIN #Uplines u
						ON l.PK_Distributor = u.PK_Distributor
					INNER JOIN #LineageFlags AS L1
						ON l.PK_FirstDownLine = L1.PK_Distributor
				WHERE 
				(L1.IsNewSP = 1)  -- New Supervisor during the qualification Period (Jul 2024 - Oct 2024). 																 
				AND NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS da WITH (NOLOCK) WHERE da.nMainDistributorID = l.PK_FirstDownline) -- Main ID must not qualify
				GROUP BY l.PK_Distributor,l.PK_Event,l.PK_FirstDownLine
					
			IF @IsDevQA = 0
			BEGIN
				DROP TABLE IF EXISTS [dbo].[WRK_24089_Downlines_Contribution_L1]

				SELECT 	
					l.PK_Distributor,
					l.PK_Event,
					l.PK_FirstDownLine
				INTO [dbo].[WRK_24089_Downlines_Contribution_L1]
				FROM #Contribution_L1 AS l

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 1;

			/* GETTING SECOND LINE CONTRIBUTION */  
	
			INSERT INTO #TimeLog VALUES ('Contribution_L2', 7, 2, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #Contribution_L2;
				
				SELECT 
					l.PK_Distributor,
					l.PK_Event,
					l.PK_FirstDownLine,
					l.PK_SecondDownLine
				INTO #Contribution_L2
				FROM #Lineage l WITH (NOLOCK) 
					INNER JOIN #Uplines u
						ON l.PK_Distributor = u.PK_Distributor 
					INNER JOIN #LineageFlags AS L1
						ON l.PK_FirstDownLine = L1.PK_Distributor
					INNER JOIN #LineageFlags AS L2
						ON l.PK_SecondDownLine = L2.PK_Distributor
				WHERE 
				L2.IsNewSP = 1 -- New Supervisor during the qualification Period (Jul 2024 - Oct 2024). 		
				AND L1.IsTAB = 0 AND L1.IsFQS = 0 --TAB / FQS block					 
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_FirstDownLine = l1.PK_FirstDownLine) --> 1 downline per leg	
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l1.PK_FirstDownLine = l2.PK_Distributor) --> No double counting allowed.  	
				AND
				NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS da WITH (NOLOCK) WHERE da.nMainDistributorID = l.PK_FirstDownline) -- Main ID must not qualify
				GROUP BY l.PK_Distributor,l.PK_Event,l.PK_FirstDownLine, l.PK_SecondDownLine

			IF @IsDevQA = 0
			BEGIN
				DROP TABLE IF EXISTS [dbo].[WRK_24089_Downlines_Contribution_L2]

				SELECT 	
					l.PK_Distributor,
					l.PK_FirstDownLine, 
					l.PK_SecondDownLine
				INTO [dbo].[WRK_24089_Downlines_Contribution_L2]
				FROM #Contribution_L2 AS l

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 2;

			/* GETTING THIRD LINE CONTRIBUTION */  
	
			INSERT INTO #TimeLog VALUES ('Contribution_L3', 7, 3, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #Contribution_L3;

				SELECT 
					l.PK_Distributor,
					l.PK_FirstDownLine, 
					l.PK_SecondDownLine,
					l.PK_ThirdDownLine
				INTO #Contribution_L3
				FROM #Lineage l WITH (NOLOCK) 
					INNER JOIN #Uplines u
						ON l.PK_Distributor = u.PK_Distributor 
					INNER JOIN #LineageFlags AS L1
						ON l.PK_FirstDownLine = L1.PK_Distributor
					INNER JOIN #LineageFlags AS L2
						ON l.PK_SecondDownLine = L2.PK_Distributor
					INNER JOIN #LineageFlags AS L3
						ON l.PK_SecondDownLine = L3.PK_Distributor
				WHERE 
				(L3.IsNewSP = 1)  -- New Supervisor during the qualification Period (Jul 2024 - Oct 2024). 	
				AND (L1.IsTAB = 0 AND L1.IsFQS = 0 AND L2.IsTAB = 0 AND L2.IsFQS = 0) --TAB / FQS block		
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_FirstDownLine = l1.PK_FirstDownLine) --> 1 downline per leg	
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L2 l2 WHERE l.PK_FirstDownLine = l2.PK_FirstDownLine) --> 1 downline per leg	
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l1.PK_FirstDownLine = l3.PK_Distributor) --> No double counting allowed.  
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L2 l2 WHERE l2.PK_SecondDownLine = l3.PK_Distributor) --> No double counting allowed.  
				AND 
				NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS da WITH (NOLOCK) WHERE da.nMainDistributorID = l.PK_ThirdDownLine) -- Main ID must not qualify
				GROUP BY l.PK_Distributor,l.PK_Event,l.PK_FirstDownLine, l.PK_SecondDownLine,l.PK_ThirdDownLine

			IF @IsDevQA = 0
			BEGIN
				DROP TABLE IF EXISTS [dbo].[WRK_24089_Downlines_Contribution_L3]

				SELECT 	
					l.PK_Distributor,
					l.PK_FirstDownLine, 
					l.PK_SecondDownLine,
					l.PK_ThirdDownLine
				INTO [dbo].[WRK_24089_Downlines_Contribution_L3]
				FROM #Contribution_L3 AS l

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 3;

			/* GETTING UPLINE CONTRIBUTOR */

			DROP TABLE IF EXISTS [dbo].[WRK_24089_UplinesContributors]

			CREATE TABLE [dbo].[WRK_24089_UplinesContributors]
			(
				 PK_Distributor					INT 
				,PK_Event						INT 
				,FirstLineCount					INT DEFAULT 0  
				,SecondLineCount				INT DEFAULT 0  
				,ThirdLineCount					INT DEFAULT 0  
				,FirstLineCount_Associated		INT DEFAULT 0  
				,SecondLineCount_Associated		INT DEFAULT 0  
				,ThirdLineCount_Associated		INT DEFAULT 0  
				,Contributors					AS (FirstLineCount+FirstLineCount_Associated+SecondLineCount+ThirdLineCount+SecondLineCount_Associated+ThirdLineCount_Associated)  
			)

		INSERT INTO #TimeLog VALUES ('UplinesContributors', 7, 4, GETUTCDATE(), NULL);
				
			INSERT INTO [dbo].[WRK_24089_UplinesContributors] (PK_Distributor,PK_Event,FirstLineCount,SecondLineCount,ThirdLineCount)
			SELECT U.PK_Distributor
					,U.PK_Event
					,ISNULL(L1.Contributors,0) [FirstLineCount]
					,ISNULL(L2.Contributors,0) [SecondLineCount]
					,ISNULL(L3.Contributors,0) [ThirdLineCount] 
			FROM #Uplines U
			LEFT JOIN
				(	
					SELECT
					PK_Distributor,
					COUNT(PK_FirstDownLine) AS Contributors
					FROM
						#Contribution_L1  
					GROUP BY
						PK_Distributor,PK_FirstDownLine
				) L1	
			ON 
				L1.PK_Distributor = U.PK_Distributor
			LEFT JOIN
				(	
					SELECT
					PK_Distributor,
					COUNT(PK_FirstDownLine) AS Contributors
					FROM
						#Contribution_L2  
					GROUP BY
						PK_Distributor,PK_FirstDownLine
				) L2	
			ON 
				L2.PK_Distributor = U.PK_Distributor
			LEFT JOIN
				(	
					SELECT
					PK_Distributor,
					COUNT(PK_FirstDownLine) AS Contributors
					FROM
						#Contribution_L3  
					GROUP BY
						PK_Distributor,PK_FirstDownLine
				) L3	
			ON 
				L3.PK_Distributor = U.PK_Distributor
			 

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
					ISNULL(B.ThirdLineCount,0) AS [ThirdLineCount_Associated] 
				INTO #Associated_Contributors
				 FROM
			 			[Shared].[DistributorAssociation] AS T WITH (NOLOCK)
				 LEFT JOIN
			 		[dbo].[WRK_24089_UplinesContributors] B WITH (NOLOCK)
				 ON
			 		T.PK_AssociatedID = B.PK_Distributor
			 
				 UPDATE
			 			T
				 SET
			 			T.FirstLineCount_Associated =  ISNULL(A.FirstLineCount_Associated,0),
						T.SecondLineCount_Associated = ISNULL(A.SecondLineCount_Associated,0),
						T.ThirdLineCount_Associated  = ISNULL(A.ThirdLineCount_Associated,0) 
				 FROM
			 			[dbo].[WRK_24089_UplinesContributors] T
				 LEFT JOIN
			 			#Associated_Contributors A
				 ON
			 		T.PK_Distributor = A.PK_Distributor 	

						

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 7 AND [StepSubGroup] = 5;

			--// Bonus assignation
			
			DROP TABLE IF EXISTS #Event_DSPoints_Summary

			CREATE TABLE #Event_DSPoints_Summary
			(
				PK_Event [int],
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
				row_num int
			)
					
			INSERT INTO #Event_DSPoints_Summary(PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries,row_num)
			SELECT  
				U.PK_Event,
				U.PK_Distributor,
				U.RoyaltyMonth,
				U.MetricType,
				(SELECT nCountryID FROM v_Countries WHERE sCountryCode = '-W') AS PK_Country,
				SUM(U.Points) AS [Points],
				F.[QSVolume],
				F.iSPQualDate,
				F.QualificationNumber,
				F.Part,
				F.iStartDate,
				F.iEndDate,
				F.Countries, 
				ROW_NUMBER() OVER (PARTITION BY U.PK_Event,U.PK_Distributor,F.QualificationNumber ORDER BY U.RoyaltyMonth ) row_num
			FROM #Event_DSPoints AS U WITH (NOLOCK) 
				INNER JOIN #tmp_DSQualDef AS F
					ON u.PK_Distributor = F.PK_Distributor
			WHERE U.PK_Event = F.PK_Event AND F.MetricType = U.MetricType AND 
					U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
			GROUP BY U.PK_Event,U.PK_Distributor,U.RoyaltyMonth,U.MetricType,F.[QSVolume],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries
								 	
			--Bonuses

			DROP TABLE IF EXISTS dbo.[WRK_24089_BonusPoints]

			SELECT 
					d.PK_Event,
					d.PK_Distributor,
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
					IIF(b.PK_Distributor IS NOT NULL AND U.MetricType = 'TV' AND U.RoyaltyMonth >= d.SPQualDate,
						IIF(d.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY, @PK_Event_CI, @PK_Event_CO, @PK_Event_BL, @PK_Event_EC, @PK_Event_GT_SV)
						AND U.QualificationNumber IN(11,12,15,16,17,18), U.Points,
						IIF(d.PK_Event = @PK_Event_HN
						AND U.QualificationNumber IN(11,12,15,16,17,18,27,28), U.Points,
						IIF(d.PK_Event = @PK_Event_CR
						AND U.QualificationNumber IN(7,8,11,12,13,14), U.Points,
						IIF(d.PK_Event = @PK_Event_NI 
							AND U.QualificationNumber IN(11,12,14,15,16,17), U.Points,
						IIF(d.PK_Event = @PK_Event_DR
							AND U.QualificationNumber IN(8,9,10,11), U.Points,
						IIF(d.PK_Event = @PK_Event_VE
							AND U.QualificationNumber IN(6,7,8,9), U.Points,0)))))),0) AS [NEW SP BONUS],
					IIF(c.PK_Distributor IS NOT NULL AND U.MetricType = 'TV' AND U.RoyaltyMonth = c.RoyaltyMonth,
						IIF(d.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY, @PK_Event_CI, @PK_Event_CO, @PK_Event_BL, @PK_Event_EC, @PK_Event_GT_SV)
						AND U.QualificationNumber IN(11,12,15,16,17,18), IIF(U.Points > 5000, 5000, U.Points),
						IIF(d.PK_Event = @PK_Event_HN
						AND U.QualificationNumber IN(9,10,11,12,15,16,17,18,27,28), IIF(U.Points > 5000, 5000, U.Points),
						IIF(d.PK_Event = @PK_Event_CR
						AND U.QualificationNumber IN(7,8,11,12,13,14), IIF(U.Points > 5000, 5000, U.Points),
						IIF(d.PK_Event = @PK_Event_NI 
							AND U.QualificationNumber IN(11,12,14,15,16,17), IIF(U.Points > 5000, 5000, U.Points),
						IIF(d.PK_Event = @PK_Event_DR
							AND U.QualificationNumber IN(8,9,10,11), IIF(U.Points > 5000, 5000, U.Points),
						IIF(d.PK_Event = @PK_Event_VE
							AND U.QualificationNumber IN(6,7,8,9), IIF(U.Points > 5000, 5000, U.Points),0)))))),0) AS [SPECIAL DOUBLE BONUS],
						IIF(d.PK_Event = @PK_Event_HN AND U.QualificationNumber IN(27,28) AND U.row_num = 1,	ISNULL(uc.Contributors,0) * 2500, 0) AS [HN EXTRA BONUS],
						U.row_num AS [Pos]
				INTO dbo.[WRK_24089_BonusPoints]
				FROM #DS AS d
					INNER JOIN #Event_DSPoints_Summary AS U WITH (NOLOCK)
						ON d.PK_Event = U.PK_Event AND d.PK_Distributor = U.PK_Distributor   
					LEFT JOIN #bNewFQS AS b
						ON d.PK_Event = b.PK_Event AND d.PK_Distributor = b.PK_Distributor
					LEFT JOIN #SpecialBonusFQSMonth AS c
						ON d.PK_Event = c.PK_Event AND d.PK_Distributor = c.PK_Distributor
					LEFT JOIN [dbo].[WRK_24089_UplinesContributors] AS uc WITH (NOLOCK)
						ON d.PK_Event = uc.PK_Event AND d.PK_Distributor = uc.PK_Distributor

			CREATE INDEX IX_WRK_24089_BonusPoints_PK_Distributor ON dbo.[WRK_24089_BonusPoints](PK_Distributor)

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
							P.PK_Event,
							P.PK_Distributor,
							P.RoyaltyMonth,
							P.MetricType,
							P.PK_Country,
							P.[Points],
							P.QualificationNumber,
							P.Part,
							ISNULL([NEW SP BONUS],0) + ISNULL([SPECIAL DOUBLE BONUS] ,0) + ISNULL([HN EXTRA BONUS],0) AS [Bonus], 
							P.[Points] + ISNULL([NEW SP BONUS],0) + ISNULL([SPECIAL DOUBLE BONUS] ,0) + ISNULL([HN EXTRA BONUS],0) AS [TotalPoints],  
							P.iStartDate,
							P.iEndDate
						FROM dbo.[WRK_24089_BonusPoints] AS P WITH (NOLOCK)

				IF @IsDevQA = 0
				BEGIN
					
					INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary]', 5, 51, GETUTCDATE(), NULL);
					
					DELETE t
					FROM [tmp].[DSPointsSummary] AS t
						INNER JOIN #Locations AS l
							ON t.PK_Event = l.PK_Event

					INSERT INTO [tmp].[DSPointsSummary](PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,iSPQualDate)
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
							iSPQualDate
						FROM #tmp_DSPointsSummary

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 5 AND [StepSubGroup] =51;

				END
				ELSE IF @IsDevQA = 3
				BEGIN

					INSERT INTO ##DSPointsSummary_amed(PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,iSPQualDate)
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
							iSPQualDate
						FROM #tmp_DSPointsSummary

				END
				 
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 5 AND [StepSubGroup] = 5;

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
				ELSE IF @IsDevQA = 3
				BEGIN
					 
					 --Input 
					 --##DSPointsSummary_amed
					 --##Event_DSPoints_amed
					 --##tmp_DSQualDef_amed
					 --##Event_SetupEventQualification_amed
					EXEC ##usp_GetQualifier_Points_amed @PK_Event = @PK_Event_Execution, @QualType = @QualType, @OverwritePointsSummary = @OverwritePointsSummary, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					--Output 
					--##DSQualPoints_amed
				END

				IF @IsDevQA = 3
				BEGIN
					INSERT INTO #Event_DSQualPoints([PK_Event],PK_Distributor,QualificationNumber,Part,QualDate)
					SELECT 
						@PK_Event_Execution AS [PK_Event]
						,PK_Distributor
						,QualificationNumber 
						,Part		
						,QualDate
					FROM ##DSQualPoints_amed AS Q
					WHERE PK_Event = @PK_Event_Execution
					AND NOT EXISTS (SELECT 1 FROM #Event_DSQualPoints WHERE PK_Distributor = Q.PK_Distributor AND PK_Event = Q.PK_Event AND QualificationNumber = Q.QualificationNumber AND Part = Q.Part AND QualDate = Q.QualDate )
				END
				ELSE
				BEGIN
					INSERT INTO #Event_DSQualPoints([PK_Event],PK_Distributor,QualificationNumber,Part,QualDate)
					SELECT 
						[PK_Event]
						,PK_Distributor
						,QualificationNumber 
						,Part		
						,QualDate
					FROM [Event].[DSQualPoints] AS Q WITH (NOLOCK)
					WHERE Q.PK_Event = @PK_Event_Execution
					AND NOT EXISTS (SELECT 1 FROM #Event_DSQualPoints WHERE PK_Distributor = Q.PK_Distributor AND PK_Event = Q.PK_Event AND QualificationNumber = Q.QualificationNumber AND Part = Q.Part AND QualDate = Q.QualDate )
				END

				UPDATE #Executions
				SET Done = 1
				WHERE PK_Execution = @PK_Execution

				END
				
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 6 AND [StepSubGroup] = 1;

		END
			
		--Step 7: Qualifications
		IF @Step >= 7
		BEGIN
			
			PRINT 'Executing step 7'

			INSERT INTO #TimeLog VALUES ('#EventQual', 4, 1, GETUTCDATE(), NULL);

			------------------------------------------------------------------------------------------------
			-- General qualifications
			------------------------------------------------------------------------------------------------
			BEGIN

				INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q14,[Q19])
				SELECT 
					PK_Distributor,
					d.PK_Event AS [PK_Event],
					IIF(d.DSSPTeam = 'SP',1,0) AS Q01, -- FQS 
					IIF(d.dSPQualDate BETWEEN @NewFQSFrom AND @NewFQSTo OR d.dRequalSPQualDate BETWEEN @NewFQSFrom AND @NewFQSTo, 1, 0) AS [Q02], --New FQS Qualify or Requalify (Qual dates:  Jul 2024 - Oct 2024)
					IIF(d.QSQualDate = @QSQualDateFrom AND d.QSActualQualDate BETWEEN @QSQualDateFrom AND @QSQualDateTo,1,0) AS Q14, --QS, QV, PQS, SQS, 2QS, 5QS (Qual date: Oct Event date 2024)
					IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0) AS [Q19]	
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
				AND d.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV) 

				INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q14,[Q29],[Q30])
				SELECT 
					PK_Distributor,
					d.PK_Event AS [PK_Event],
					IIF(d.DSSPTeam = 'SP' AND d.DSCurrentTeam IN ('SP','W','G','M'),1,0) AS Q01, --FQS (SP,W,G,M)
					IIF(d.dSPQualDate BETWEEN @NewFQSFrom AND @NewFQSTo, 1, 0) AS [Q02], --New FQS (Qual dates:  Jul 2024 - Oct 2024)
					IIF(d.QSQualDate = @QSQualDateFrom AND d.QSActualQualDate BETWEEN @QSQualDateFrom AND @QSQualDateTo,1,0) AS Q14, --QS, QV, PQS, SQS, 2QS, 5QS (Qual date: Oct Event date 2024)
					IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0) AS [Q29],
					IIF(d.DSSPTeam = 'DS',1,0) AS Q30 --DS (Non SP)					
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
				AND d.PK_Event  = @PK_Event_HN

				
				INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q10,[Q23],[Q24],[Q17],[Q18])
				SELECT 
					PK_Distributor,
					d.PK_Event AS [PK_Event],
					IIF(d.DSSPTeam = 'SP' AND d.DSCurrentTeam IN ('SP','W','G','M'),1,0) AS Q01, --FQS (SP,W,G,M)
					IIF(d.dSPQualDate BETWEEN @NewFQSFrom AND @NewFQSTo OR d.dRequalSPQualDate BETWEEN @NewFQSFrom AND @NewFQSTo, 1, 0) AS [Q02], --New FQS Qualify or Requalify (Qual dates:  Jul 2024 - Oct 2024)
					IIF(d.QSQualDate = @QSQualDateFrom AND d.QSActualQualDate BETWEEN @QSQualDateFrom AND @QSQualDateTo,1,0) AS Q10, --QS, QV, PQS, SQS, 2QS, 5QS (Qual date: Oct 2024) (Event date)
					IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0) AS [Q23],
					IIF(d.DSSPTeam = 'DS',1,0) AS Q24, --DS (Non SP)	
					IIF(d.dQPDemotion IS NULL AND d.dQPQualification IS NOT NULL AND d.dQPQualification BETWEEN '2024-06-01' AND '2024-09-01',1,0) AS Q17,--New Qualified Producer (Jun 2024 - Sep 2024)
					IIF(d.dQPDemotion IS NULL AND d.dQPQualification IS NOT NULL AND d.dQPQualification BETWEEN '2024-07-01' AND '2024-10-01',1,0) AS Q18--New Qualified Producer (Jul 2024 - Oct 2024) (Event date)
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
				AND d.PK_Event  = @PK_Event_CR
				
				INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q13,[Q18],[Q20])
				SELECT 
					PK_Distributor,
					d.PK_Event AS [PK_Event],
					IIF(d.DSSPTeam = 'SP',1,0) AS Q01, --FQS
					IIF(d.dSPQualDate BETWEEN @NewFQSFrom AND @NewFQSTo OR d.dRequalSPQualDate BETWEEN @NewFQSFrom AND @NewFQSTo, 1, 0) AS [Q02], --New FQS Qualify or Requalify (Qual dates:  Jul 2024 - Oct 2024)
					IIF(d.QSQualDate = @QSQualDateFrom AND d.QSActualQualDate BETWEEN @QSQualDateFrom AND @QSQualDateTo,1,0) AS Q13, --QS, QV, PQS, SQS, 2QS, 5QS (Qual date: Oct 2024) (Event date)
					IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0) AS [Q18],
					IIF(d.DSSPTeam = 'DS',1,0) AS Q20 --DS (Non SP)					
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
				AND d.PK_Event  = @PK_Event_NI
				
				INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q03,Q20)
				SELECT 
					PK_Distributor,
					d.PK_Event AS [PK_Event],
					IIF(d.DSSPTeam = 'SP',1,0) AS Q01, -- FQS and Above
					IIF(d.dSPQualDate BETWEEN @NewFQSFrom AND @NewFQSTo OR d.dRequalSPQualDate BETWEEN @NewFQSFrom AND @NewFQSTo, 1, 0) AS [Q02], --New FQS Qualify or Requalify (Qual dates:  Jul 2024 - Oct 2024)
					IIF(d.QSQualDate = @QSQualDateFrom AND d.QSActualQualDate BETWEEN @QSQualDateFrom AND @QSQualDateTo,1,0) AS Q03, --QS, QV, PQS, SQS, 2QS, 5QS (Qual date: Oct Event date 2024) 
					IIF(d.DSCurrentTeam IN ('G','M','P','A','B','C'), 1,0) AS [Q20] --TAB Team
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
				AND d.PK_Event  = @PK_Event_VE
				
				INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q07,Q12,Q13,[Q16],Q17)
				SELECT 
					PK_Distributor,
					d.PK_Event AS [PK_Event],
					IIF(d.DSSPTeam = 'SP',1,0) AS Q01, -- FQS 
					IIF(d.dSPQualDate BETWEEN @NewFQSFrom AND @NewFQSTo OR d.dRequalSPQualDate BETWEEN @NewFQSFrom AND @NewFQSTo, 1, 0) AS [Q02], --New FQS Qualify or Requalify (Qual dates:  Jul 2024 - Oct 2024)
					IIF(d.QSQualDate = @QSQualDateFrom AND d.QSActualQualDate BETWEEN @QSQualDateFrom AND @QSQualDateTo,1,0) AS Q07, --QS, QV, PQS, SQS, 2QS, 5QS (Qual date: Oct Event date 2024)
					IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0) AS [Q12],
					IIF(d.DSSPTeam = 'DS',1,0) AS Q13, --DS (Non SP)		
					IIF(d.dQPDemotion IS NULL AND d.dQPQualification IS NOT NULL AND d.dQPQualification BETWEEN '2024-06-01' AND '2024-09-01',1,0) AS Q16,--New Qualified Producer (Jun 2024 - Sep 2024)
					IIF(d.dQPDemotion IS NULL AND d.dQPQualification IS NOT NULL AND d.dQPQualification BETWEEN '2024-07-01' AND '2024-10-01',1,0) AS Q17--New Qualified Producer (Jul 2024 - Oct 2024) (Event date)
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
				AND d.PK_Event  = @PK_Event_DR


			END
						
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
			[HasQualReference],
			0 AS [ctrl]
			INTO #QualificationsMapping
			FROM #Event_SetupEventQualification
			ORDER BY PK_Event,QualificationNumber,[Part]

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
				AND [HasQualReference] = 1 

				DROP TABLE IF EXISTS ##QualVolumeQualifiers_23020

				SET @SqlStatement = ''

				SET @SqlStatement = N'SELECT Q1.PK_Event,Q1.PK_Distributor	
				INTO ##QualVolumeQualifiers_23020
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
				INNER JOIN ##QualVolumeQualifiers_23020 AS QQ
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

				-- AWT 2024 Qualify OR Re-qualify ( NOT TAB) (Qual dates: Jun 2024 - Oct 2024)

				DROP TABLE IF EXISTS #AWT_QualRequal_JunOct24
 
				SELECT d.PK_Distributor, d.PK_Event 
					INTO #AWT_QualRequal_JunOct24
				FROM #DS AS d  
 				INNER JOIN dbo.[AWT] AS a WITH (NOLOCK)
 	 				ON d.PK_Distributor = a.PK_Distributor  
				INNER JOIN [dbo].[AWT_Qualifiers_Tracking] AS t WITH (NOLOCK)
					ON a.PK_Distributor = t.PK_Distributor AND a.AWTYear = t.AWTYear
 				WHERE a.AWTYear = 2024 AND (t.[Jun] = 1 OR t.[Jul] = 1 OR t.[Aug] = 1 OR t.[Sep] = 1 OR t.[Oct] = 1)
 				AND ISNONTAB = 1
			
				CREATE INDEX IX_#AWT_QualRequal_OctDec2022_PK_Distributor ON #AWT_QualRequal_JunOct24(PK_Distributor);

				--New WT (WT Qual date:  Jul 2024 - Oct 2024)

				DROP TABLE IF EXISTS #NewWT
 
				SELECT d.PK_Event, d.PK_Distributor, MIN(H.dFrom) AS [TeamDate]  
					INTO #NewWT
				FROM #DS AS d 
				INNER JOIN dbo.v_DistributorHistory AS H             
					ON d.PK_Distributor = H.nDistributorIDFK                   
				WHERE H.nEventTypeLID = 224 --Qual World Team
				AND H.dThrough = '2049-12-31'  
				AND H.dFrom BETWEEN '2024-07-01' AND '2024-10-01' 
				GROUP BY d.PK_Event, d.PK_Distributor	

				--AWT 2024 Qualify OR Re-qualify ( NOT TAB) (Qual dates: Jun 2024 - Oct 2024)
				--Q13 for PM, PE, AR-UY-YU,CI,CO,BL,EC,GT-SV,HN
				--Q9 for CR
				UPDATE E
				SET 
					 Q13 = IIF(Q13.PK_Distributor IS NULL,0,1)
				 FROM #EventQual AS E
					INNER JOIN #AWT_QualRequal_JunOct24 AS Q13
					ON E.PK_Distributor = Q13.PK_Distributor 
						AND E.PK_Event = Q13.PK_Event
				WHERE E.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_HN) 

				--AWT 2024 Qualify OR Re-qualify ( NOT TAB) (Qual dates: Jun 2024 - Oct 2024)
				--Q9 for CR
				UPDATE E
				SET 
					 Q09 = IIF(Q09.PK_Distributor IS NULL,0,1)
				 FROM #EventQual AS E
					INNER JOIN #AWT_QualRequal_JunOct24 AS Q09
					ON E.PK_Distributor = Q09.PK_Distributor 
						AND E.PK_Event = Q09.PK_Event
				WHERE E.PK_Event IN (@PK_Event_CR)

				--AWT 2024 Qualify OR Re-qualify ( NOT TAB) (Qual dates: Jun 2024 - Oct 2024) -- BRD v3
				--Q19 for VE
				UPDATE E
				SET 
					 Q19 = IIF(Q19.PK_Distributor IS NULL,0,1)
				 FROM #EventQual AS E
					INNER JOIN #AWT_QualRequal_JunOct24 AS Q19
					ON E.PK_Distributor = Q19.PK_Distributor 
						AND E.PK_Event = Q19.PK_Event
				WHERE E.PK_Event IN (@PK_Event_VE)

				--New WT (WT Qual date:  Jul 2024 - Oct 2024)
				--Q21 for PM, PE, AR-UY-YU,CI,CO,BL,EC,GT-SV,NI
				--Q32 for HN
				--Q26 for CR
				--Q10 for VE
				--Q18 for DR
				UPDATE E
				SET 
					Q21 = IIF(Q.PK_Distributor IS NOT NULL AND E.PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV,@PK_Event_NI),1,0),
					Q32 = IIF(Q.PK_Distributor IS NOT NULL AND E.PK_Event = @PK_Event_HN ,1,0),
					Q26 = IIF(Q.PK_Distributor IS NOT NULL AND E.PK_Event = @PK_Event_CR ,1,0),
					Q10 = IIF(Q.PK_Distributor IS NOT NULL AND E.PK_Event = @PK_Event_VE ,1,0),
					Q18 = IIF(Q.PK_Distributor IS NOT NULL AND E.PK_Event = @PK_Event_DR ,1,0)
				 FROM #EventQual AS E
					INNER JOIN #NewWT AS Q
					ON E.PK_Distributor = Q.PK_Distributor 
						AND E.PK_Event = Q.PK_Event
		
			END
	
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
			WHERE [StepGroup] = 4 AND [StepSubGroup] = 1; 

		END
 
		--Step 8: Subevents
		IF @Step >= 8
		BEGIN

			PRINT 'Executing step 8'

			INSERT INTO #TimeLog VALUES ('Es #EventQual', 8, 1, GETUTCDATE(), NULL);
	 
 
			--PM, PE, AR-UY-PY, CI, CO, BL, EC, GT-SV
			UPDATE 
				#EventQual
			SET
				E01 = ((Q01 & (Q03 | Q04 | Q05 | Q06)) | Q02 | Q14 | Q19 | Q22)
			WHERE PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV)

			UPDATE 
				#EventQual
			SET
				E02 = ((E01 & (Q07 | Q08 | Q09 | Q10 | Q11 | Q12 | Q13)) | Q19 | Q20 | Q23),
				E03 = ((E01 & (Q15 | Q16)) | Q19 | Q21 | Q24),
				E04 = ((E01 & (Q17 | Q18)) | Q19 | Q25),
				E05 = ((E01 & (Q02 | Q14))),
				E06 = (Q26),
				E07 = (Q27),
				E08 = (E01 & Q28) --BRD v2
			WHERE PK_Event IN (@PK_Event_PM, @PK_Event_PE, @PK_Event_AR_UY_PY,@PK_Event_CI,@PK_Event_CO,@PK_Event_BL,@PK_Event_EC,@PK_Event_GT_SV)

			 --HN
			UPDATE 
				#EventQual
			SET
				E01 = ((Q01 & (Q03 | Q04 | Q05 | Q06)) | Q02 | Q14 | Q29 | Q33)
			WHERE PK_Event = @PK_Event_HN

			UPDATE 
				#EventQual
			SET
				E02 = ((Q01 | (Q30 & (Q19 | Q20)) & ~E01) | Q34)
			WHERE PK_Event = @PK_Event_HN

			UPDATE 
				#EventQual
			SET
				E03 = ((E01 & (Q11 | Q12 | Q13 | Q23 | Q24 | Q25 | Q26)) | Q29 | Q31 | Q35),
				E04 = ((E01 & (Q15 | Q16)) | Q29 | Q32 | Q36),
				E05 = ((E01 & (Q17 | Q18)) | Q29 | Q37),
				E06 = ((E01& (Q02 | Q07 | Q08 | Q09 | Q10 | Q14)) | Q38),
				E07 = ((E01 & (Q27 | Q28)) | Q39),
				E08 = (Q40),
				E09 = (Q41),
				E10 = ((E01 | E02) & Q42) --BRD v2
			WHERE PK_Event = @PK_Event_HN

			--CR
			UPDATE 
				#EventQual
			SET
				E01 = ((Q01 & (Q03 | Q04 | Q05 | Q06)) | Q02 | Q10 | Q23 | Q27)
			WHERE PK_Event = @PK_Event_CR

			UPDATE 
				#EventQual
			SET
				E02 = ((Q01 | (Q24 & (Q15 | Q16 | Q17 | Q18)) & ~E01) | Q28)
			WHERE PK_Event = @PK_Event_CR

			UPDATE 
				#EventQual
			SET
				E03 = ((E01 & (Q07 | Q08 | Q09 | Q19 | Q20 | Q21 | Q22)) | Q23 | Q25 | Q29),
				E04 = ((E01 & (Q11 | Q12)) | Q23 | Q26 | Q30),
				E05 = ((E01 & (Q13 | Q14)) | Q23 | Q31),
				E06 = (E01 & (Q02 | Q10)),
				E07 = (Q32),
				E08 = (Q33),
				E09 = ((E01 | E02) & Q34) --BRD v2
			WHERE PK_Event = @PK_Event_CR

			--NI
			UPDATE 
				#EventQual
			SET
				E01 = ((Q01 & (Q03 | Q04 | Q05 | Q06)) | Q02 | Q13 | Q18 | Q22)
			WHERE PK_Event = @PK_Event_NI

			UPDATE 
				#EventQual
			SET
				E02 = ((Q01 & ~E01) | Q23)
			WHERE PK_Event = @PK_Event_NI

			UPDATE 
				#EventQual
			SET
				E03 = ((E01 & (Q07 | Q08 | Q09 | Q10 | Q11 | Q12)) | Q18 | Q19 | Q24),
				E04 = ((E01 & (Q14 | Q15)) | Q18 | Q21 |  Q25),
				E05 = ((E01 & (Q16 | Q17)) | Q18 | Q26),
				E06 = (E01 & (Q02 | Q13)),
				E07 = (Q27),
				E08 = (Q28),
				E09 = (Q20 | Q29),
				E10 = ((E01 | E02) & Q30) --BRD v2
			WHERE PK_Event = @PK_Event_NI

			--VE
			UPDATE 
				#EventQual
			SET
				E01 = (Q01 | Q02 | Q03 | Q11)
			WHERE PK_Event = @PK_Event_VE

			UPDATE 
				#EventQual
			SET
				E02 = ((E01 & (Q04 | Q05 | Q19)) | Q20 | Q21 | Q12),
				E03 = ((E01 & (Q06 | Q07)) | Q13),
				E04 = ((E01 & (Q08 | Q09)) | Q14),
				E05 = (Q15),
				E06 = (Q16),
				E07 = (Q17),
				E08 = (E01 & Q18) --BRD v2
			WHERE PK_Event = @PK_Event_VE

			--DR
			UPDATE 
				#EventQual
			SET
				E01 = ((Q01 & (Q03 | Q04 | Q05 | Q06)) | Q02 | Q07 | Q12 | Q19)
			WHERE PK_Event = @PK_Event_DR

			UPDATE 
				#EventQual
			SET
				E02 = ((Q01 | (Q13 & (Q14 | Q15 | Q16 | Q17)) & ~E01) | Q20)
			WHERE PK_Event = @PK_Event_DR

			UPDATE 
				#EventQual
			SET
				E03 = ((E01 & (Q08 | Q09)) | Q12 | Q18 | Q21),
				E04 = ((E01 & (Q10 | Q11)) | Q12 | Q22),
				E05 = ((E01 | E02) & Q23) --BRD v2
			WHERE PK_Event = @PK_Event_DR

			--PE
			UPDATE 
				#EventQual
			SET
				E40 = (E01 | E02 | E03 | E04 | E05 | E06 | E07)
			WHERE PK_Event = @PK_Event_PE

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 8 AND [StepSubGroup] = 1;

		END

		--Step 10: [Event].[DSQual]	
		IF @Step >= 10
		BEGIN
			
			PRINT 'Executing step 10'

			IF @IsDevQA = 0
			BEGIN

				DROP INDEX IF EXISTS [IX_Event_DSQual_PK_Distributor_PK_Event]
							ON [Event].[DSQual];

				DROP INDEX IF EXISTS [IX_Event_DSQual_PK_Event]
							ON [Event].[DSQual];

				DELETE dq			
				FROM [Event].[DSQual] AS dq
					INNER JOIN #Locations AS l
						ON dq.PK_Event = l.PK_Event

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
			FROM #EventQual

				CREATE INDEX [IX_Event_DSQual_PK_Event] ON [Event].[DSQual](PK_Event);
				CREATE INDEX [IX_Event_DSQual_PK_Distributor_PK_Event] ON [Event].[DSQual](PK_Distributor) INCLUDE(PK_Event);

			END
			
		END
	 
		--Step 11: SubEventQualifiers
		IF @Step >= 11  AND  @IsDevQA = 0
		BEGIN

			PRINT 'Executing step 11'
		
			DECLARE @Events VARCHAR(MAX)
				
			SELECT @Events = STRING_AGG(PK_Event,',') FROM #Locations

			EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
			@Events = @Events,
			@Source = 2,
			@EvaluateFormula = 0		

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
 
 
 