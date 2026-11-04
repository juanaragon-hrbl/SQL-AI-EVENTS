CREATE PROCEDURE [dbo].[usp_EventQual_EMEAFPTR_2024]
	@PK_Event int = 198079
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT
	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
	,@Step SMALLINT = 11
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_EMEAFPTR_2024

	USE:		
			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC dbo.usp_EventQual_EMEAFPTR_2024 
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
	1.0.0	2024-12-12	juangue		Initial 	
	2.1.0	2024-05-14	juangue		BRD v2.1 	
	2.1.1	2024-05-14	juangue		Bugs fixes	
	2.1.2	2024-06-03	JuanGue		#1338367 SQL API
	2.1.3	2024-06-14	JuanGue		BugFixes #1349854 #1349856 #1349858
	2.1.4	2024-07-02	JuanGue		#1351633 #24038 - EMEA FPTR Dec 2024 - BRD V2 API data
	2.1.5	2024-07-03	JuanGue		Code Smells removed
	3.0.0	2024-07-04	JuanGue		BRD V3
	4.0.0	2024-07-15	JuanGue		BRD V4
	4.0.1	2024-07-26	JuanGue		#1355143 The id is qualifying to E1, E2 but not E7, it should qualify to E7
	4.0.2	2024-07-30	JuanGue		#1355800 Applicable to ALL E3 (Travel voucher) subevents should be EMEA countries, Mexico and other worldwide countries are qualifying by SKUs to E3.
	4.0.3	2024-08-16	JuanGue		#1358584 Travel voucher exception list is not working
	4.0.4	2024-09-17	JuanGue		#1364519 Bugfix	E3 Travel voucher incorrect qualifiers
	5.0.0	2024-10-21	JuanGue		BRD v5 #1366475
	5.0.1	2024-10-22	JuanGue		#1378816 E3 Incorrect qualifiers
	5.0.2	2024-10-22	JuanGue		#1378817 #1378819 #1378820 #1378821 Bug Fixes
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
			[PK_DSType] [int] NULL,
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

		DECLARE @ProjectID INT = 24038			 

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
		
		--Q04 Achieve 2,500 RO in any one (1) volume month from Nov 2023 to Oct 2024 
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			4					AS QualificationNumber,
			1					AS Part, 
			'RO'				AS [MetricType], 
			'2023-11-01'		AS [dStartDate], 
			'2024-10-01'		AS [dEndDate], 
			1					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			2500				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]
	
		--Q09 "Achieve 10,000 RO in any one (1) volume month from Nov 2023 to Oct 2024(cheques paid Dec 2023 to Nov 2024)"
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event	AS [PK_Event],
			9					AS QualificationNumber,
			1					AS Part, 
			'RO'				AS [MetricType], 
			'2023-11-01'		AS [dStartDate], 
			'2024-10-01'		AS [dEndDate], 
			1					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			10000				AS [GoalPoints], 
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

		DECLARE
			@SKUs VARCHAR(MAX) = (SELECT STRING_AGG(SKUCode,',') AS [SKUs] FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = @PK_Event),
			@IncludeDSOutsideEligibleMarketswithTicket BIT = 1,
			@QualificationSKUFactor INT = 39

		DROP TABLE IF EXISTS #ListsQsMapping

		CREATE TABLE #ListsQsMapping
		(
			ID INT IDENTITY(1,1),
			ListID INT,
			QId INT
		)
									
		INSERT INTO #ListsQsMapping(ListID,QId)
			VALUES 
				(57470,5),
				(57471,10),
				(57472,15),
				(60095,17),	
				(61735,18),	
				(60089,30), -- Quals to Q12
				(60090,31),	-- Unquals to Q12
				(60092,32), -- Quals to Q13
				(60093,33),	-- Unquals to Q13
				(61918,20),
				(61919,21),
				(61920,22),
				(61921,23),
				(61922,24),
				(61923,25)

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

			DROP TABLE IF EXISTS #CountriesList 

			CREATE TABLE #CountriesList(ID INT IDENTITY(1,1), sCountryName VARCHAR(MAX))

			INSERT INTO #CountriesList(sCountryName)
			VALUES 
			('Austria'), 
			('Belgium'), 
			('Bosnia and Herzegovina'), 
			('Botswana'),
			('Bulgaria'),
			('Croatia'), 
			('Cyprus'), 
			('Czech Republic'),
			('Denmark'),
			('Estonia'),
			('Eswatini'),
			('Finland'), 
			('France'), 
			('French Polynesia'),
			('Germany'), 
			('Ghana'), 
			('Greece'), 
			('Hungary'), 
			('Iceland'),  
			('Ireland'), 
			('Israel'), 
			('Italy'), 
			('Lebanon'), 
			('Lesotho'), 
			('FYR of Macedonia'), 
			('Lithuania'),
			('Malta'), 
			('Republic of Moldova'),  
			('Montenegro & Kosovo'), 
			('Latvia'), 
			('Namibia'), 
			('Netherlands'),  
			('Norway'), 
			('Poland'), 
			('Portugal'), 
			('Romania'), 
			('Serbia'), 
			('Slovak Republic'), 
			('Slovenia'), 
			('South Africa'), 
			('Spain'),  
			('Swaziland'), 
			('Sweden'), 
			('Switzerland'),  
			('Turkey'), 
			('Ukraine'), 
			('United Kingdom'), 
			('Zambia')

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
				WHERE sCountryCode IN (SELECT sCountryCode FROM [PubEventManagement].dbo.v_Countries c INNER JOIN  #CountriesList cl ON c.sCountryName = cl.sCountryName)

			DROP TABLE IF EXISTS #DS

			CREATE TABLE #DS
			(
				PK_Distributor		INT,   
				DistributorID		VARCHAR (20),
				DSCurrentTeam		VARCHAR(10),        
				DSSubTeam			VARCHAR(10),        
				DSSPTeam			VARCHAR(10),               
				dSPQualDate			DATETIME2,        
				CountryCode			VARCHAR(5),
				IsFromList			BIT DEFAULT(0),
				IsTicketPurchaser	BIT DEFAULT(0),
				[GT_QualDate]		DATETIME DEFAULT('1900-01-01'),
				[GP_QualDate]		DATETIME DEFAULT('1900-01-01'),
				IsFromCOP			BIT DEFAULT(0),
				IsWWCCFC			BIT DEFAULT(0),
				RONov23				MONEY DEFAULT(0),
				RODec23				MONEY DEFAULT(0),
				ROJan24				MONEY DEFAULT(0),
				ROFeb24				MONEY DEFAULT(0),
				ROMar24				MONEY DEFAULT(0),
				ROApr24				MONEY DEFAULT(0),
				ROMay24				MONEY DEFAULT(0),
				ROJun24				MONEY DEFAULT(0),
				ROJul24				MONEY DEFAULT(0),
				ROAug24				MONEY DEFAULT(0),
				ROSep24				MONEY DEFAULT(0),
				ROOct24				MONEY DEFAULT(0)
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
				IsFromCOP,
				IsWWCCFC
			)
			SELECT DISTINCT    
			D.nDistributorID AS PK_Distributor,  
			D.sDistributorID AS DistributorID,
			CASE WHEN D.sTeam IS NULL THEN 
				CASE WHEN sType = 'DS' THEN 
					sSubTeam 
				ELSE 'SP' END 
			ELSE D.sTeam END AS DSCurrentTeam,        
			D.sSubteam AS DSSubTeam,        
			D.sType AS DSSPTeam,            
			D.dSupervisorqualification AS dSPQualDate,        
			D.sDistributorCountryProcessingCode AS CountryCode,
			ISNULL((SELECT 1 FROM #Countries WHERE nCountryID = D.nDistributorCountryProcessingID),0) IsFromCOP,
			IIF(D.sSubteam IN ('CC','FC'),1,0) IsWWCCFC
			FROM        
			dbo.v_Distributor AS D  	
			WHERE        
				D.StatusCode = 'COMPLETE'        
			AND 
				D.sType ='SP' 


			CREATE INDEX IX_#DS_PK_Distributor ON #DS(PK_Distributor);	

			--New GP (GP Qual date Jan 01 2024 to Nov 01 2024)

			UPDATE D
			SET
				D.[GP_QualDate] = DH.dFrom
			FROM 
				#DS D
				INNER JOIN dbo.v_DistributorHistory DH ON D.PK_Distributor = DH.nDistributorIDFK 
					AND DH.nEventTypeLID = 226
					AND DH.dFrom BETWEEN '2024-01-01' AND '2024-11-01'  
					AND DH.dThrough = '2049-12-31'

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
			DistributorID,
			DSCurrentTeam,	
			DSSubTeam,		
			DSSPTeam,		
			dSPQualDate,		
			CountryCode,		
			IsFromList
		)
		SELECT DISTINCT        
		D.nDistributorID AS PK_Distributor,  
		D.sDistributorID AS DistributorID,		
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

		IF @IncludeDSOutsideEligibleMarketswithTicket = 1
		BEGIN

			INSERT INTO #DS
			(
				PK_Distributor,	
				DistributorID,
				DSCurrentTeam,	
				DSSubTeam,		
				DSSPTeam,		
				dSPQualDate,		
				CountryCode,
				IsTicketPurchaser
			)
			SELECT DISTINCT        
			D.nDistributorID AS PK_Distributor,   
			D.sDistributorID AS DistributorID,	
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

					SELECT @ErrorMessage
					RETURN;
				END

				--Output
				--##Event_DSPoints_jgue
 
		
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 2;
		
			END
			
		------------------------------------------------------------------------------------------------
		-- 3.5 Getting #Event_DSPoints 
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

		/***************************************************  
			  Update RO Points Columns on #DS
		****************************************************/

		UPDATE
			T
		SET	
			T.RONov23	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202311),0)
			,T.RODec23	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202312),0)
			,T.ROJan24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202401),0)
			,T.ROFeb24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202402),0)
			,T.ROMar24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202403),0)
			,T.ROApr24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202404),0)
			,T.ROMay24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202405),0)
			,T.ROJun24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202406),0)
			,T.ROJul24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202407),0)
			,T.ROAug24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202408),0)
			,T.ROSep24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202409),0)
			,T.ROOct24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202410),0)

		FROM
			#DS T	

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
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 4 AND [StepSubGroup] = 2;	
		END
	END
		
	--Step 5: Getting DSPointsSummary		
	IF @Step >= 5
	BEGIN
			
		PRINT 'Executing step 5'
		 		
		INSERT INTO #TimeLog VALUES ('#tmp_DSPointsSummary', 5, 1, GETUTCDATE(), NULL);
		
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
			FROM #Event_DSPoints AS U WITH (NOLOCK) 
						INNER JOIN #tmp_DSQualDef AS F
							ON u.PK_Distributor = F.PK_Distributor	
							WHERE 
							F.MetricType = U.MetricType 
							AND 
							U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
							AND 
			(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
			GROUP BY U.PK_Distributor,U.RoyaltyMonth,U.MetricType,F.[QSVolume],F.[QSVolumePercentage],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries
					

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
						0 AS [Bonus],
						ISNULL(P.[Points],0) AS [TotalPoints],
						P.iStartDate,
						P.iEndDate
					FROM #Event_DSPoints_Summary AS P WITH (NOLOCK)

			IF @IsDevQA = 0
			BEGIN
					
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
				 
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 1;		
	
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

		INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q03,Q06,Q07,Q08,Q11,Q12,Q16,Q45,Q50)
			SELECT 
				PK_Distributor,
				@PK_Event AS [PK_Event],
				IIF(D.DSSubTeam = 'GT',1,0)							 AS Q01, --GT
				IIF(D.DSSubTeam = 'GP',1,0)							 AS Q02, --GP
				IIF(D.DSCurrentTeam IN ('M','A', 'B', 'C', 'P'),1,0) AS Q03, --MT and above
				IIF(D.DSSPTeam = 'SP',1,0)							 AS Q06, --FQS and above
				D.IsWWCCFC											 AS Q07, --WW FC CC *Check WW 
				IIF(D.DSCurrentTeam IN ('P','A','B','C'),1,0)		 AS Q08, --PT and above
				IIF(D.[GP_QualDate] != '1900-01-01',1,0)			 AS Q11, --New GP (GP Qual date Jan 01 2024 to Nov 01 2024)
				IIF(D.DSSubTeam IN ('SP','WT','GT'),0,1)			 AS Q12, -- GP and above
				ISNULL((SELECT 1 FROM PubEventManagement.Promo.WRK_PremierLeague_SubEvent WPLS (NOLOCK)
					WHERE 
						WPLS.PK_Distributor = D.PK_Distributor 
					AND
						WPLS.ContributingYear = 2024 
					AND 
						WPLS.SubEvent = 1 ),0)						AS Q16, -- Qualified to E1 of the "24087 - WW - Premier League Program 2024" (PK ID 199427)
				D.IsTicketPurchaser									AS Q45,
				D.IsFromCOP											AS Q50
			FROM #DS AS D
			WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE D.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)

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
		BEGIN

			IF EXISTS (SELECT 1 FROM #SKUs WHERE PK_Event = @PK_Event) 
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
		PRINT '#SKUsQsMapping end'
			
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

		UPDATE #EventQual
		SET 
			Q13 = Q30 & ~Q31, --List ID: 60089 Qualifies the Upline to Q13, List ID: 60090 Unqualifies the Upline to Q13
			Q14 = Q32 & ~Q33  --List ID: 60092 Qualifies the Upline to Q14, List ID: 60093 Unqualifies the Upline to Q14
			
	END

	--Step 8: Subevents
	IF @Step >= 8
	BEGIN

		PRINT 'Executing step 8'

		INSERT INTO #TimeLog VALUES ('Es #EventQual', 8, 1, GETUTCDATE(), NULL);

 
		UPDATE 
			#EventQual
		SET
			E01 = (((((Q01 | Q02 | Q06) & Q04) | Q03) & Q50) | ((((Q01 | Q02 | Q06) & Q04) | Q03) & Q45) | ((((Q01 | Q02 | Q06) & Q04) | Q03) & Q18) | Q05 | Q07)

		UPDATE 
			#EventQual
		SET
			E02 = ((((Q08 | (Q06 & Q09)) & Q50) | ((Q08 | (Q06 & Q09)) & Q45)) | Q07 | Q10),
			E03 = ((((E01 & (Q01 | Q11 | (Q12 & Q13))) & Q50) | Q15) | (E01 & Q18 & (Q01 | Q11 | (Q12 & Q13)))),
			E04 = ((E01 & Q16 & Q50) | (E01 & Q16 & Q45) | Q17)
			
		UPDATE 
			#EventQual
		SET
			E08 = (Q41), -- Q41 is Q19 in the BRD - Purchase SKU 77H4
			E09 = (Q20),
			E10 = (Q21),
			E11 = (Q22),
			E12 = (Q23),
			E13 = (Q24),
			E14 = (Q25)

		UPDATE 
			#EventQual
		SET
			E07 = (E01 | E02 | E03 | E04 | E05 | E06 | E08 | E09 | E10 | E11 | E12 | E13 | E14)

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

		INSERT INTO #TimeLog VALUES ('[Event].[DSQual]', 10, 1, GETUTCDATE(), NULL);

		-- Calculate stones
		BEGIN
			-- Active EMEA ASP Promotion

			DROP TABLE IF EXISTS #ASPUplines_2022

			SELECT 
				PK_Distributor,
				d.sDistributorID,
				MAX(DateQualified) AS DateQualified 
			INTO #ASPUplines_2022
			FROM [Promo].[DSSubEvent] AS s WITH(NOLOCK) 
				INNER JOIN v_Distributor AS d
					ON s.PK_Distributor = d.nDistributorID
			WHERE PK_Event = 36704 
			AND SubEvent = 1 -- ASP
			GROUP BY PK_Distributor, d.sDistributorID


			DROP TABLE IF EXISTS #ASPUplines_2023_2024

			SELECT 
				PK_Distributor,
				d.sDistributorID,
				MAX(DateQualified) AS DateQualified 
			INTO #ASPUplines_2023_2024
			FROM [Promo].[DSSubEvent] AS s WITH(NOLOCK) 
				INNER JOIN v_Distributor AS d
					ON s.PK_Distributor = d.nDistributorID
			WHERE PK_Event = 197094 
			AND SubEvent = 1 -- ASP
			GROUP BY PK_Distributor, d.sDistributorID

			DROP TABLE IF EXISTS #WRK_EMEA_ASPPromo_PrevQualified_CurrentPromo

			CREATE TABLE #WRK_EMEA_ASPPromo_PrevQualified_CurrentPromo
			(
				PK_Event INT,
				PK_Distributor INT,
				DistributorID VARCHAR(30),
				ASP_Year VARCHAR(50)
			)

			--36704	Active Supervisor Promotion
			INSERT INTO #WRK_EMEA_ASPPromo_PrevQualified_CurrentPromo(PK_Event,PK_Distributor,DistributorID,[ASP_Year])
			SELECT DISTINCT
				D.PK_Event,
				D.DLDistributor,
				DD.sDistributorID,
				'2022,2023,2024'
			FROM Promo.DSDownlines AS D WITH (NOLOCK) 
				INNER JOIN #ASPUplines_2022 AS U
					ON D.PK_Distributor = U.PK_Distributor 
				INNER JOIN v_Distributor AS DD
					ON D.DLDistributor = DD.nDistributorID
			WHERE PK_Event = 36704 AND D.DQDate <= 202212 


			INSERT INTO #WRK_EMEA_ASPPromo_PrevQualified_CurrentPromo(PK_Event,PK_Distributor,DistributorID,[ASP_Year])
			SELECT DISTINCT
				D.PK_Event,
				D.DLDistributor,
				DD.sDistributorID,
				'2022,2023,2024'
			FROM Promo.DSDownlines AS D WITH (NOLOCK) 
				INNER JOIN #ASPUplines_2023_2024 AS U
					ON D.PK_Distributor = U.PK_Distributor 
				INNER JOIN v_Distributor AS DD
					ON D.DLDistributor = DD.nDistributorID
			WHERE PK_Event = 197094 AND D.DQDate <= 202404 -- Before Mar-Apr-May 2024 (QualDate May 2024)


			DROP TABLE IF EXISTS #WRK_EMEA_ASPPromo_CurrentQualified_CurrentPromo

			CREATE TABLE #WRK_EMEA_ASPPromo_CurrentQualified_CurrentPromo
			(
				PK_Event INT,
				PK_Distributor INT,
				DistributorID VARCHAR(30),
				ASP_Year VARCHAR(50)
			)

			INSERT INTO #WRK_EMEA_ASPPromo_CurrentQualified_CurrentPromo(PK_Event,PK_Distributor,DistributorID,[ASP_Year])
			SELECT DISTINCT
				D.PK_Event,
				D.DLDistributor,
				DD.sDistributorID,
				'2024'
			FROM Promo.DSDownlines AS D WITH (NOLOCK) 
				INNER JOIN #ASPUplines_2023_2024 AS U
					ON D.PK_Distributor = U.PK_Distributor 
				INNER JOIN v_Distributor AS DD
					ON D.DLDistributor = DD.nDistributorID
			WHERE PK_Event = 197094 AND D.DQDate >= 202405  

			-- For UT purposes
			IF NOT EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_EMEA_ASPPromo_PrevQualified' and type='U')
			BEGIN
				CREATE TABLE WRK_EMEA_ASPPromo_PrevQualified
				(
					PK_Event			INT,
					DistributorID		VARCHAR(30),
					PK_Distributor		INT,   
					ASP_Year			VARCHAR(50)
				)

				INSERT INTO WRK_EMEA_ASPPromo_PrevQualified VALUES(198079,'10Y2137058',187360189,'2024')

			END 

			DROP TABLE IF EXISTS #ASPDownlines_PrevQualified

			CREATE TABLE #ASPDownlines_PrevQualified
			(
				PK_Distributor INT,
				ASP_Year VARCHAR(MAX)
			)

			;WITH cte_WRK_EMEA_ASPPromo_PrevQualified AS 
			(
				SELECT 
					PK_Distributor,
					ASP_Year
				FROM dbo.WRK_EMEA_ASPPromo_PrevQualified WITH (NOLOCK) --Previous qualifiers - Reference the EMEA ASP promos: 2014 (1250), 2015 (2142), 2016 (3434), 2017 (7423), 2018 (20539), 2019 (66565), 2020 (73829), 2021 (51938)
				UNION
				SELECT 
					PK_Distributor,
					ASP_Year
				FROM #WRK_EMEA_ASPPromo_PrevQualified_CurrentPromo --Ongoing promo - Reference the EMEA ASP promos: 2022/2023 (36704 ongoing) before period
			)

			INSERT INTO #ASPDownlines_PrevQualified(PK_Distributor,ASP_Year)
			SELECT PK_Distributor,STRING_AGG(ASP_Year,',')
			FROM cte_WRK_EMEA_ASPPromo_PrevQualified
			GROUP BY PK_Distributor

			DROP TABLE IF EXISTS #ASPDownlines

			SELECT 
				U.PK_Distributor,
				MIN(U.DateQualified) AS [min_UQDate],
				MAX(U.DateQualified) AS [max_UQDate],
				D.DLDistributor,
				MIN(DQDate) AS [min_DQDate], 
				MAX(DQDate) AS [max_DQDate],
				MAX([Level]) AS [Level]						
			INTO #ASPDownlines
			FROM Promo.DSDownlines AS D WITH (NOLOCK) 
				INNER JOIN #ASPUplines_2022 AS U
					ON D.PK_Distributor = U.PK_Distributor 
			WHERE PK_Event = 36704  --AND [Level] = 1
			AND DQDate <= 202212
			GROUP BY U.PK_Distributor,D.DLDistributor

			INSERT INTO #ASPDownlines
			SELECT 
				U.PK_Distributor,
				MIN(U.DateQualified) AS [min_UQDate],
				MAX(U.DateQualified) AS [max_UQDate],
				D.DLDistributor,
				MIN(DQDate) AS [min_DQDate], 
				MAX(DQDate) AS [max_DQDate],
				MAX([Level]) AS [Level]						
			FROM Promo.DSDownlines AS D WITH (NOLOCK) 
				INNER JOIN #ASPUplines_2023_2024 AS U
					ON D.PK_Distributor = U.PK_Distributor 
			WHERE PK_Event = 197094  --AND [Level] = 1
			AND NOT EXISTS (SELECT 1 FROM #ASPDownlines AS A WHERE A.PK_Distributor = U.PK_Distributor AND A.DLDistributor = D.DLDistributor)
			GROUP BY U.PK_Distributor,D.DLDistributor


			DROP TABLE IF EXISTS #ASPUplines_Details

			SELECT 
				UD.sDistributorID AS [UplineDistributorID],
				UD.nDistributorID AS [UplinePK_Distributor],
				UD.sFirstName AS [UplineFirstName],
				UD.sLastName AS [UplineLastName],
				D.[min_UQDate] AS [Upline ASP Qual date],
				DD.sDistributorID AS [ASP Stone ID],
				DD.nDistributorID AS [ASP Stone PK_Distributor],
				D.[Level],		   
				DD.sFirstName AS [ASP Stone FirstName],
				DD.sLastName AS [ASP Stone LastName],
				D.[min_DQDate] AS [ASP Stone Qual date],
				IIF(NN.PK_Distributor IS NULL, 1,0) AS [IsNewStone],
				IIF(NN.ASP_Year IS NULL, cq.[ASP_Year],NN.ASP_Year) AS [ASP_Year],
				IIF(NN.ASP_Year IS NULL, 0,1) AS [ASP_PrevQualifier],
				CAST(NULL AS bit) AS  [VolumeAchievedBeforePeriod],
				CAST(NULL AS smalldatetime) AS  [VolumeAchievedDate]
			INTO #ASPUplines_Details
			FROM #ASPDownlines AS D
				INNER JOIN v_Distributor AS UD
					ON D.PK_Distributor = UD.nDistributorID
				INNER JOIN v_Distributor AS DD
					ON D.DLDistributor = DD.nDistributorID
				LEFT JOIN #ASPDownlines_PrevQualified AS NN 
					ON NN.PK_Distributor = D.DLDistributor 
				LEFT JOIN #WRK_EMEA_ASPPromo_CurrentQualified_CurrentPromo AS cq
				ON DD.nDistributorID = cq.PK_Distributor -- Downline
			ORDER BY D.PK_Distributor




			-- WW FQS (not counted in EMEA ASP promo) who has not done the 2,500 TVP x 3 consecutive months (WW) before Mar-Apr-May 2024 VM

			BEGIN

				DROP TABLE IF EXISTS #D

				CREATE TABLE #D
				(
					PK_Distributor	int,   
					PK_Event		int,
					DSCurrentTeam	varchar(10),        
					DSSubTeam		varchar(10),        
					DSSPTeam		varchar(10),               
					dSPQualDate		datetime2,        
					CountryCode		varchar(5),
					IsTAB			bit,
					IsFromList		bit default(0)
				)

				INSERT INTO #D
				(
					PK_Distributor,	
					PK_Event,
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,		
					CountryCode,		
					IsTAB 
				)
				SELECT DISTINCT        
					D.nDistributorID AS PK_Distributor,   
					@PK_Event AS PK_Event,
					CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
					D.sSubteam AS DSSubTeam,        
					D.sType AS DSSPTeam,            
					D.dSupervisorqualification AS dSPQualDate,        
					D.sDistributorCountryProcessingCode AS CountryCode ,
					CASE WHEN D.sTeam IN ('A', 'B', 'C', 'G', 'M', 'P') THEN 1 ELSE 0 END IsTAB
					FROM        
					dbo.v_Distributor AS D  
					INNER JOIN #ASPUplines_Details AS C
						ON D.nDistributorID = C.[ASP Stone PK_Distributor]

				CREATE INDEX IX_#DS_PK_Distributor ON #D(PK_Distributor);

				DROP TABLE IF EXISTS #Event_SetupEventQualifications

				CREATE TABLE #Event_SetupEventQualifications
				(
					[PK_Event]				int,
					[QualificationNumber]	int,
					[Part]					int,
					[MetricType]			varchar(15),
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
					[QSVolumePercentage]	int
				)


				INSERT INTO #Event_SetupEventQualifications(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,Bonus)
				SELECT @PK_Event AS PK_Event, 1 AS QualificationNumber,1 AS Part, 'TVP'	AS [MetricType], '2017-01-01' AS [dStartDate], '2024-10-01' AS [dEndDate], 3	AS [Frequency], 1 AS [Consecutive], 0 AS [Accumulated], 0 AS [MinPoints], 2500 AS [GoalPoints], NULL AS [Countries], NULL AS [Bonus] 
					
				-- Getting #tmp_DS
				DROP TABLE IF EXISTS #tmp_D

				CREATE TABLE #tmp_D(
					[PK_Event] [int] NOT NULL,
					[PK_Distributor] [int] NOT NULL,
					[StartDate] [int] NOT NULL,
					[EndDate] [int] NOT NULL
				)

				INSERT INTO #tmp_D([PK_Event],[PK_Distributor],[StartDate],[EndDate])
				SELECT 
					@PK_Event AS [PK_Event],
					D.PK_Distributor AS PK_Distributor,
					(SELECT CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int) FROM #Event_SetupEventQualifications WITH (NOLOCK) WHERE PK_Event = @PK_Event) AS [StartDate],
					(SELECT CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int) FROM #Event_SetupEventQualifications WITH (NOLOCK) WHERE PK_Event = @PK_Event) AS [EndDate]
				FROM #D AS D 
				CREATE INDEX IX_#tmp_DS_PK_Distributor ON #tmp_D(PK_Distributor);	

				DECLARE 
				@SourceType smallint = 3
				
				DROP TABLE IF EXISTS #DSVolume

				CREATE TABLE #DSVolume
				(
				[PK_Event] INT NOT NULL,
				[PK_Distributor]  INT NOT NULL, 
				[PK_Country]  INT NOT NULL,
				[RoyaltyMonth]  INT NOT NULL, 
				[MetricType]  VARCHAR(10) NOT NULL,  
				[Points]  MONEY NOT NULL 
				)

					IF @SourceType = 3 -- From PubEventManagement.v_aggFQS_ID
					BEGIN
		

					;WITH cte_tmp_DS AS 
					(
						SELECT 
						D.PK_Distributor,
						CONVERT(datetime, CONVERT(VARCHAR(10), ((D.StartDate * 100) + 1))) AS dStartDate,
						CONVERT(datetime, CONVERT(VARCHAR(10), ((D.EndDate * 100) + 1))) AS dEndDate
						FROM #tmp_D AS D WITH (NOLOCK)		
						WHERE D.PK_Event = @PK_Event
					)

					INSERT INTO #DSVolume([PK_Event],[PK_Distributor],[PK_Country],[RoyaltyMonth],[MetricType],[Points])
					SELECT  
					77764 AS [PK_Event]
					,U.PK_Distributor 
					,U.PK_Country
					,U.RoyaltyMonth 
					,U.MetricType  
					,U.Points 
					FROM (  
						SELECT 
							P.nDistributorID AS PK_Distributor,
							CAST(CONVERT(varchar(6),P.dRoyaltyMonth , 112) AS int) AS RoyaltyMonth,
							0 AS PK_Country, 
							SUM(P.mRoyaltyOverrides) AS RO,
							SUM(P.mVolumePoints) AS TVP
						FROM cte_tmp_DS AS D WITH (NOLOCK)
							INNER JOIN PubEventManagement.dbo.v_aggFQS_ID AS P WITH (NOLOCK)
							ON D.PK_Distributor = P.nDistributorID 
						WHERE P.dRoyaltyMonth BETWEEN D.dStartDate AND D.dEndDate 
						GROUP BY P.nDistributorID,dRoyaltyMonth
					) AS P UNPIVOT ( Points FOR MetricType IN (RO, TVP)) AS U 
					WHERE  U.Points > 0

					END

					DROP TABLE IF EXISTS #Points_DS

					SELECT 
					D.PK_Distributor AS PK_Distributor,
					D.PK_Event AS [PK_Event],
					V.PK_Country,
					V.RoyaltyMonth,
					V.MetricType,
					V.Points,
					M.[AssociationType],
					M.PK_AssociatedID AS PK_AssociatedID
					INTO #Points_DS
					FROM #tmp_D AS D WITH (NOLOCK)
					INNER JOIN #DSVolume AS V
					ON D.PK_Distributor = V.PK_Distributor 
					LEFT JOIN Shared.[DistributorAssociation] AS M WITH (NOLOCK)
					ON D.PK_Distributor = M.PK_Distributor
					WHERE D.PK_Event = @PK_Event 
				
					DROP TABLE IF EXISTS #Points_Associated

					SELECT 
					D.PK_Distributor AS PK_Distributor,
					D.PK_Event AS [PK_Event],
					V.PK_Country,
					V.RoyaltyMonth,
					V.MetricType,
					V.Points,
					M.[AssociationType],
					M.PK_AssociatedID AS PK_AssociatedID
					INTO #Points_Associated
					FROM #tmp_D AS D WITH (NOLOCK)
					INNER JOIN Shared.[DistributorAssociation] AS M WITH (NOLOCK)
					ON D.PK_Distributor = M.PK_Distributor
					INNER JOIN #DSVolume AS V
					ON M.PK_AssociatedID = V.PK_Distributor 
					WHERE D.PK_Event = @PK_Event
	
					DROP TABLE IF EXISTS #Countries_Points

					SELECT DISTINCT PK_Country 
					INTO #Countries_Points
					FROM #Points_DS
					UNION
					SELECT DISTINCT PK_Country 
					FROM #Points_Associated

					DROP TABLE IF EXISTS #Periods

					SELECT	
					D.PK_Event AS [PK_Event],
					D.PK_Distributor AS [PK_Distributor],
					M.PK_AssociatedID AS [PK_AssociatedID],
					M.AssociationType AS [AssociationType],
					G.MetricType AS [MetricType],
					CAST(CONVERT(varchar(6), S.MyDate, 112) AS int)  AS [iMonth],
					C.[PK_Country] 
					INTO #Periods
					FROM
					#tmp_D AS D WITH (NOLOCK)
					LEFT JOIN Shared.[DistributorAssociation] AS M WITH (NOLOCK)
					ON D.PK_Distributor = M.PK_Distributor
					CROSS APPLY dbo.SourceDate AS S WITH (NOLOCK)
					CROSS APPLY (SELECT [PK_Country] FROM #Countries_Points) AS C
					CROSS APPLY (SELECT MetricType FROM #Event_SetupEventQualifications WITH (NOLOCK) WHERE PK_Event = @PK_Event GROUP BY MetricType) AS G
					WHERE MyDate BETWEEN (SELECT MIN(dStartDate) FROM #Event_SetupEventQualifications WITH (NOLOCK) WHERE PK_Event = @PK_Event) AND (SELECT MAX(dEndDate) FROM #Event_SetupEventQualifications WITH (NOLOCK) WHERE PK_Event = @PK_Event) 
					AND D.PK_Event = @PK_Event
		
					DROP TABLE IF EXISTS #Points

					SELECT  
					p.PK_Distributor
					,p.PK_Event
					,P.PK_Country
					,p.iMonth AS [RoyaltyMonth]
					,p.MetricType
					,(ISNULL(d.Points,0) + ISNULL(a.Points,0)) AS [Points]
					,p.[PK_AssociatedID]
					,p.AssociationType
					INTO #Points
					FROM #Periods AS p	
					LEFT JOIN #Points_DS AS d
					ON p.PK_Distributor = d.PK_Distributor
					AND p.PK_Event = d.PK_Event
					AND p.MetricType = d.MetricType
					AND p.iMonth = d.RoyaltyMonth
					AND P.PK_Country = d.PK_Country
					LEFT JOIN #Points_Associated AS a
					ON p.PK_Distributor = a.PK_Distributor
					AND p.PK_Event = a.PK_Event
					AND p.MetricType = a.MetricType
					AND p.iMonth = a.RoyaltyMonth
					AND p.PK_Country = a.PK_Country
		
					DROP TABLE IF EXISTS #SummaryPoints

					CREATE TABLE #SummaryPoints(
					PK_Distributor INT NOT NULL,
					PK_Event INT NOT NULL,
					PK_Country INT NOT NULL,
					RoyaltyMonth INT NOT NULL,
					MetricType VARCHAR(5) NOT NULL,
					Points MONEY,
					PK_AssociatedID INT,
					AssociationType INT,
					Bonus MONEY
					)

					INSERT INTO #SummaryPoints(PK_Distributor,PK_Event,PK_Country,RoyaltyMonth,MetricType,Points,PK_AssociatedID,AssociationType)
					SELECT  
					p.PK_Distributor
					,p.PK_Event
					,P.PK_Country
					,p.[RoyaltyMonth]
					,p.MetricType
					,SUM(p.[Points]) AS [Points]
					,[PK_AssociatedID]
					,AssociationType
					FROM #Points AS p	
					GROUP BY p.PK_Distributor
					,p.PK_Event
					,P.PK_Country
					,p.[RoyaltyMonth]
					,p.MetricType
					,p.[PK_AssociatedID]
					,P.AssociationType
					HAVING SUM(p.[Points]) > 0
					
					CREATE INDEX IX_#SummaryPoints_PK_Distributor ON #SummaryPoints(PK_Distributor)

					DROP TABLE IF EXISTS #Event_DSPointss

					CREATE TABLE #Event_DSPointss
					(
					[PK_Distributor] [int] NULL,
					[PK_Event] [int] NULL,
					[PK_Country] [int] NULL,
					[RoyaltyMonth] [int] NULL,
					[MetricType] [varchar](20) NULL,
					[Points] [money] NULL,
					[AssociationType] [int] NULL,
					[PK_AssociatedID] [int] NULL,
					[Bonus] [money] NULL
					)
		
					INSERT INTO #Event_DSPointss(PK_Distributor,PK_Event,PK_Country,RoyaltyMonth,MetricType,Points,AssociationType,PK_AssociatedID,Bonus)
					SELECT 
					PK_Distributor,
					PK_Event,
					PK_Country,
					[RoyaltyMonth],
					MetricType,
					ROUND([Points],2) AS [Points],
					[PK_AssociatedID],
					AssociationType,
					Bonus
					FROM #SummaryPoints

					CREATE CLUSTERED INDEX [IX_#Event_DSPointss_PK_Distributor] ON #Event_DSPointss ([PK_Distributor]) 
					CREATE NONCLUSTERED INDEX [IX_#Event_DSPointss_PK_Event] ON #Event_DSPointss ([PK_Event]) INCLUDE (MetricType)
		
					DROP TABLE IF EXISTS #tmp_DSQualDefs

					CREATE TABLE #tmp_DSQualDefs
					(
					[PK_Event] [int] NULL,
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
					[MetricType] [varchar](20) NULL,
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

					INSERT INTO #tmp_DSQualDefs(PK_Event,PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries)
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
						m.PK_AssociatedID AS PK_AssociatedID,
						C.Countries
					FROM #D AS D					
						LEFT JOIN Shared.[DistributorAssociation] AS M WITH (NOLOCK)
							ON D.PK_Distributor = M.PK_Distributor
						OUTER APPLY #Event_SetupEventQualifications AS C WITH (NOLOCK)
						CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
						WHERE C.PK_Event = @PK_Event
	
					CREATE INDEX IX_#tmp_DSQualDefs_PK_Distributor ON #tmp_DSQualDefs(PK_Distributor) INCLUDE(PK_Event);

					DROP TABLE IF EXISTS #Event_DSQualPointss

					CREATE TABLE #Event_DSQualPointss
					(
					[PK_Distributor] [int] NULL,
					[PK_Event] [int] NULL,
					[QualificationNumber] [int] NULL,
					[Part] [int] NULL,
					[QualDate] [datetime2](7) NULL
					)

					--usp_GetQualifier_Points definition

					DECLARE @QualTypes SMALLINT

					DROP TABLE IF EXISTS #tmp_DSPointsSummary2

					CREATE TABLE #tmp_DSPointsSummary2(
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

					INSERT INTO #tmp_DSPointsSummary2(PK_Distributor,PK_Event,RoyaltyMonth,MetricType,PK_Country,[Points],[Bonus],[QSVolume]
					,[QSVolumePercentage],iSPQualDate,QualificationNumber,Part,[HasBonus],[TotalPoints],iStartDate,iEndDate,Countries)
					SELECT 
						U.PK_Distributor,
						U.PK_Event,
						U.RoyaltyMonth,
						U.MetricType,
						U.PK_Country,
						ISNULL(U.Points,0) AS [Points],
						ISNULL(U.Bonus,0) AS [Bonus],
						F.[QSVolume],
						F.[QSVolumePercentage],
						F.iSPQualDate,
						F.QualificationNumber,
						F.Part,
						ISNULL(F.Bonus,0) AS [HasBonus],
						IIF(ISNULL(F.Bonus,0) = 1, 
								IIF(F.[QSVolume] = 1,
									IIF(U.RoyaltyMonth < F.iSPQualDate, (ISNULL(U.Points,0) * ISNULL(F.[QSVolumePercentage],100)) / 100 + ISNULL(U.Bonus,0)
									,ISNULL(U.Points,0) + ISNULL(U.Bonus,0)) -- SPQualDate
							,ISNULL(U.Points,0) + ISNULL(U.Bonus,0)) -- QS Volumen
						,IIF(F.[QSVolume] = 1,
									IIF(U.RoyaltyMonth < F.iSPQualDate, ((ISNULL(U.Points,0) * ISNULL(F.[QSVolumePercentage],100)) / 100)
									,ISNULL(U.Points,0)) -- SPQualDate
							,ISNULL(U.Points,0))) -- QS Volumen
						AS [TotalPoints],
						F.iStartDate,
						F.iEndDate,
						F.Countries
					FROM #Event_DSPointss AS U WITH (NOLOCK)
							INNER JOIN #tmp_DSQualDefs AS F WITH (NOLOCK)
								ON u.PK_Distributor = F.PK_Distributor					
							WHERE 
								F.MetricType = U.MetricType 
								AND 
								U.PK_Event = @PK_Event
								AND 
								U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
								AND 
								(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
					
					DROP TABLE IF EXISTS #Config

					CREATE TABLE #Config
					(
					PK_Event int,
					QualificationNumber int,
					Part int,
					MetricType varchar(100),
					dStartDate datetime2,
					iStartDate int,
					dEndDate datetime2,
					iEndDate int,
					Frequency int,
					Consecutive bit,
					Accumulated bit,
					MinPoints money,
					GoalPoints money,
					Countries varchar(max),
					Bonus bit,
					QSVolume bit
					)

					DROP TABLE IF EXISTS #Qualifiers

					CREATE TABLE #Qualifiers
					(
						PK_Distributor int,
						MetricType varchar(100),
						MinPoints int,
						GoalPoints money,
						Frequency int,
						Consecutive bit,	
						Accumulated bit,
						StartDate datetime2,
						EndDate datetime2,
						QualDate datetime2,
						QualificationNumber int,
						Part int
					)

					SET @QualTypes = 3

					IF @QualTypes = 3 /* Achieve/Consecutive */
					BEGIN

					DROP TABLE IF EXISTS #GroupPointsSummary_T3;

					SELECT 
							U.PK_Distributor,
							U.PK_Event,
							U.RoyaltyMonth,
							U.MetricType,
							U.QualificationNumber,
							U.Part,
							SUM(ISNULL([TotalPoints],0)) AS [Points],
							iStartDate,
							iEndDate
						INTO #GroupPointsSummary_T3
						FROM #tmp_DSPointsSummary2 AS U
							GROUP BY 
								U.PK_Event,
								U.PK_Distributor,
								U.MetricType,
								U.RoyaltyMonth,
								U.QualificationNumber,
								U.Part,
								U.iStartDate,
								U.iEndDate

					INSERT INTO #Config(PK_Event,QualificationNumber,Part,MetricType,dStartDate,iStartDate,dEndDate,iEndDate,Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,Bonus,QSVolume)
					SELECT  
						F.PK_Event,
						F.QualificationNumber,
						F.Part,
						F.MetricType,
						A.StartDate,
						CAST(CONVERT(varchar(6), A.StartDate, 112) AS int) AS [iStartDate],
						A.EndDate,
						CAST(CONVERT(varchar(6), A.EndDate, 112) AS int) AS [iEndDate],
						F.Frequency,
						F.Consecutive,
						F.Accumulated,
						F.MinPoints,
						F.GoalPoints,
						F.Countries,
						F.Bonus,
						F.QSVolume
					FROM #Event_SetupEventQualifications AS F	
						CROSS APPLY [dbo].[ufn_GetPeriods](F.dStartDate,F.dEndDate,F.Frequency,F.Consecutive,F.Accumulated) AS A
					WHERE F.Accumulated = 0 AND F.Consecutive = 1 AND F.PK_Event = @PK_Event 

					INSERT INTO #Qualifiers(PK_Distributor,MetricType,MinPoints,GoalPoints,Frequency,Consecutive,Accumulated,StartDate,EndDate,QualDate,QualificationNumber,Part)
					SELECT 
						mb.PK_Distributor,
						mb.MetricType,
						x.MinPoints AS MinPoints,
						x.GoalPoints AS GoalPoints,
						x.Frequency AS Frequency,
						x.Consecutive,
						x.Accumulated, 		
						x.dStartDate AS StartDate,
						x.dEndDate AS EndDate,
						MAX(mb.dRoyaltyMonth) AS QualDate,
						x.QualificationNumber,
						x.Part
					FROM #Config AS x
						CROSS APPLY 
						(
							SELECT 
								A.PK_Distributor,
								A.MetricType,
								A.RoyaltyMonth AS iRoyaltyMonth,
								CONVERT(datetime, CONVERT(VARCHAR(10), ((A.RoyaltyMonth * 100) + 1))) AS [dRoyaltyMonth], 
								A.Points,
								A.QualificationNumber,
								A.Part, 
								ROW_NUMBER() OVER(PARTITION BY A.PK_Distributor, A.MetricType,A.QualificationNumber,A.Part ORDER BY A.RoyaltyMonth) AS RowMonth 
							FROM
								#GroupPointsSummary_T3 A
							WHERE
								a.PK_Event = x.PK_Event
								AND
								a.QualificationNumber = x.QualificationNumber
								AND
								a.Part = x.Part
								AND
								((a.RoyaltyMonth BETWEEN x.iStartDate AND x.iEndDate) AND
								(a.iStartDate = x.iStartDate AND a.iEndDate = x.iEndDate))
								AND
								MetricType = x.MetricType
								AND
								Points >= x.GoalPoints
								AND
								x.Consecutive = 1 --Consecutive
								AND
								x.Accumulated = 0 --Achieve

					) AS mb
					WHERE
						x.Consecutive = 1
						AND
						x.Accumulated  = 0
						AND
						mb.QualificationNumber = x.QualificationNumber
						AND 
						mb.Part = x.Part
					GROUP BY mb.PK_Distributor,mb.MetricType,x.MinPoints,x.GoalPoints,x.Consecutive,x.Frequency,x.Accumulated,x.dStartDate,x.dEndDate,DATEADD(mm, -RowMonth+1, dRoyaltyMonth),x.QualificationNumber,x.Part
					HAVING COUNT(1) >= x.Frequency

					END
				
					INSERT INTO #Event_DSQualPointss(PK_Distributor,PK_Event,QualificationNumber,Part,QualDate)
					SELECT 
						PK_Distributor
						,@PK_Event AS [PK_Event]
						,QualificationNumber 
						,Part		
						,QualDate
					FROM #Qualifiers AS Q

			END


			DROP TABLE IF EXISTS #ASP

			SELECT PK_Distributor,MIN(QualDate)  AS QualDate
			INTO #ASP
			FROM #Event_DSQualPointss
			GROUP BY PK_Distributor

			DROP TABLE IF EXISTS #ASP_BeforePeriod

			SELECT PK_Distributor,QualDate
			INTO #ASP_BeforePeriod
			FROM #ASP
			WHERE QualDate < '2024-05-01'

			DROP TABLE IF EXISTS #ASP_DuringPeriod

			SELECT PK_Distributor,QualDate
			INTO #ASP_DuringPeriod
			FROM #ASP
			WHERE QualDate >= '2024-05-01'

			DROP TABLE IF EXISTS #ASP_NeverQualified

			SELECT 
				PK_Distributor,QualDate 
			INTO #ASP_NeverQualified
			FROM #ASP_DuringPeriod AS a WHERE  
			NOT EXISTS (SELECT 1 FROM #ASPDownlines_PrevQualified AS pq WHERE pq.PK_Distributor = a.PK_Distributor)
			AND NOT EXISTS (SELECT 1 FROM #WRK_EMEA_ASPPromo_CurrentQualified_CurrentPromo AS pq WHERE pq.PK_Distributor = a.PK_Distributor)
			AND NOT EXISTS (SELECT 1 FROM #ASP_BeforePeriod AS pq WHERE pq.PK_Distributor = a.PK_Distributor)

			UPDATE R
			SET 
				[IsNewStone] =  IIF((R.ASP_PrevQualifier = 0 AND bp.PK_Distributor IS NULL AND (cp.PK_Distributor IS NOT NULL  OR DP.PK_Distributor IS NOT NULL OR nq.PK_Distributor IS NOT NULL)),1,0),
				[VolumeAchievedBeforePeriod] = IIF(bp.PK_Distributor IS NULL,0,1),
				[VolumeAchievedDate] = IIF(nq.PK_Distributor IS NULL,IIF(BP.QualDate IS NULL,DP.QualDate,BP.QualDate),nq.QualDate),
				[ASP Stone Qual date] = IIF(nq.PK_Distributor IS NULL, R.[ASP Stone Qual date], NULL),
				[ASP_Year] = IIF(nq.PK_Distributor IS NULL, R.[ASP_Year], NULL)
			FROM #ASPUplines_Details AS R
			LEFT JOIN #ASP_BeforePeriod AS BP
				ON R.[ASP Stone PK_Distributor] = BP.PK_Distributor
			LEFT JOIN #ASP_BeforePeriod AS DP
				ON R.[ASP Stone PK_Distributor] = DP.PK_Distributor
			LEFT JOIN #WRK_EMEA_ASPPromo_CurrentQualified_CurrentPromo AS cp
				ON R.[ASP Stone PK_Distributor] = cp.[PK_Distributor]
			LEFT JOIN #ASP_NeverQualified AS nq
				ON R.[ASP Stone PK_Distributor] = nq.PK_Distributor

			DROP TABLE IF EXISTS #NewStonesCount

			SELECT UplinePK_Distributor, COUNT(1) AS Stones 
			INTO #NewStonesCount
			FROM #ASPUplines_Details AS R
			WHERE [IsNewStone] = 1 
			GROUP BY UplinePK_Distributor

			DROP TABLE IF EXISTS #CurrentTeamQualDate

			SELECT DH.nDistributorIDFK AS PK_Distributor,MAX(DH.dFrom) AS [Team_QualDate] 
			INTO #CurrentTeamQualDate
			FROM #DS DS
			INNER JOIN dbo.v_DistributorHistory AS DH (NOLOCK)	
				ON DH.nDistributorIDFK = DS.PK_Distributor
			INNER JOIN [dbo].[v_dimDSLifeCycle] AS t
				ON DH.nEventTypeLID = t.LifeCycleCode
			WHERE DH.dThrough = '2049-12-31' --AND DH.nDistributorIDFK = @PK_Distributor  
			GROUP BY DH.nDistributorIDFK

		END

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

			--WRK_EMEAFPTR_2024
			DROP TABLE IF EXISTS dbo.WRK_EMEAFPTR_2024

			SELECT 
				DS.PK_Distributor
				,DS.DistributorID
				,DS.DSCurrentTeam		     
				,DS.DSSubTeam			       
				,DS.DSSPTeam			               
				,DS.dSPQualDate
				,CTQD.Team_QualDate
				,DS.CountryCode			
				,DS.IsFromList			
				,DS.IsTicketPurchaser	
				,DS.[GT_QualDate]		
				,DS.[GP_QualDate]		
				,DS.IsFromCOP			
				,DS.IsWWCCFC			
				,DS.RONov23			
				,DS.RODec23			
				,DS.ROJan24			
				,DS.ROFeb24			
				,DS.ROMar24			
				,DS.ROApr24			
				,DS.ROMay24			
				,DS.ROJun24			
				,DS.ROJul24			
				,DS.ROAug24			
				,DS.ROSep24			
				,DS.ROOct24
				,ISNULL(NSC.Stones,0) Stones
			INTO dbo.WRK_EMEAFPTR_2024  
			FROM #DS DS
			INNER JOIN #CurrentTeamQualDate CTQD
				ON DS.PK_Distributor = CTQD.PK_Distributor
			LEFT JOIN #NewStonesCount NSC
				ON DS.PK_Distributor = NSC.UplinePK_Distributor

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

			--#WRK_EMEAFPTR_2024
			DROP TABLE IF EXISTS dbo.#WRK_EMEAFPTR_2024

			SELECT 
				DS.PK_Distributor
				,DS.DistributorID
				,DS.DSCurrentTeam		     
				,DS.DSSubTeam			       
				,DS.DSSPTeam			               
				,DS.dSPQualDate
				,CTQD.Team_QualDate
				,DS.CountryCode			
				,DS.IsFromList			
				,DS.IsTicketPurchaser	
				,DS.[GT_QualDate]		
				,DS.[GP_QualDate]		
				,DS.IsFromCOP			
				,DS.IsWWCCFC			
				,DS.RONov23			
				,DS.RODec23			
				,DS.ROJan24			
				,DS.ROFeb24			
				,DS.ROMar24			
				,DS.ROApr24			
				,DS.ROMay24			
				,DS.ROJun24			
				,DS.ROJul24			
				,DS.ROAug24			
				,DS.ROSep24			
				,DS.ROOct24
				,ISNULL(NSC.Stones,0) Stones
			INTO #WRK_EMEAFPTR_2024  
			FROM #DS DS
			INNER JOIN #CurrentTeamQualDate CTQD
				ON DS.PK_Distributor = CTQD.PK_Distributor
			LEFT JOIN #NewStonesCount NSC
				ON DS.PK_Distributor = NSC.UplinePK_Distributor
		END

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 10 AND [StepSubGroup] = 1;

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