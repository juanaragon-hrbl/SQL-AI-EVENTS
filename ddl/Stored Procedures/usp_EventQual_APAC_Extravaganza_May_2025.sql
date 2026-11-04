CREATE PROCEDURE [dbo].[usp_EventQual_APAC_Extravaganza_May_2025]
	@PK_Event INT = NULL
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT
	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
	,@Step SMALLINT = 10
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_APAC_Extravaganza_May_2025

	USE:		

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC dbo.usp_EventQual_APAC_Extravaganza_May_2025
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


	DEVELOPER NOTES:
	The consecutive qualifications are offset by 1 for 202210 event A
	For minimizing the code all the qualifications for both events are the same consecutive qualification number
	But at the end of the SP when merging to the [Event].[DSQual] the quaifications for event A PK 202210 are aligned with the BRD

	Q01 = Q22, Q02 = Q01, Q03 = Q02, Q04 = Q03, Q05 = Q04 etc...

	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2025-02-24			JuanGue			Initial 	
	1.0.1	2025-03-06			JuanGue			Q11 "World Team members who qualify for the World Team..." added
	1.0.2	2025-03-10			JuanGue			#1407118 It should only win E1, E2. with 15000 TVP
	1.0.3	2025-03-11			JuanGue			#1407119 Performance 30 min
	1.0.4	2025-03-11			JuanGue			#1407250 HPL Q13
	1.0.5	2025-03-11			JuanGue			#1407424 E5 Q10 RO
	1.0.6	2025-03-11			JuanGue			Q6 from COP
	1.0.7	2025-03-11			JuanGue			TAB fix
	1.0.8	2025-03-12			JuanGue			SubEvent IN (1,2) in WRK_HPL2025_SubEvent
	1.0.8	2025-03-12			JuanGue			Removing filter DateQualified in WRK_PremierLeague_SubEvent 
	***********************************************************************************************************************************/
	DROP TABLE IF EXISTS #Events

	CREATE TABLE #Events
	(
		PK_Event INT,
		[Location] VARCHAR(300),
		IsMain BIT
	)

	-- Setting up the quals and subevents to the events
	INSERT INTO #Events(PK_Event,[Location],IsMain) 
	VALUES	(202210,'APAC Extravaganza A 2025',1) --A
		   ,(202211,'APAC Extravaganza B 2025',0) --B

	DECLARE @PK_Event_General INT
	
	SELECT	@PK_Event  = (SELECT PK_Event FROM #Events WHERE IsMain = 1)

	DROP TABLE IF EXISTS #Locations

	CREATE TABLE #Locations
	(
		[Location] [varchar](25),
		[PK_Event] [int],
		[ctrl] [bit] DEFAULT(0)
	)

	INSERT INTO #Locations([PK_Event],[Location])
	SELECT PK_event,[Location] 
	FROM #Events

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
			(202210, 63015,14),
			(202210, 63016,15),
			(202210, 63017,16),
			(202210, 63018,17),
			(202210, 63019,18),
			(202210, 63020,19),
			(202210, 63021,20),
			(202210, 63022,21),

			(202210, 63750,22),
			(202210, 63751,23),
			(202210, 63752,24),
			(202210, 63753,25),
			(202210, 63754,26),
			(202210, 63754,27),

			(202211, 63023,14),
			(202211, 63024,15),
			(202211, 63025,16),
			(202211, 63026,17),
			(202211, 63027,18),
			(202211, 63028,19),
			(202211, 63029,20),
			(202211, 63030,21),

			(202211, 63762,22),
			(202211, 63757,23),
			(202211, 63758,24),
			(202211, 63759,25),
			(202211, 63760,26),
			(202211, 63761,27)


		DROP TABLE IF EXISTS #SKUsQsMapping

		CREATE TABLE #SKUsQsMapping
		(
			ID INT IDENTITY(1,1),
			PK_Event INT,
			SKUCode VARCHAR(10),
			QId INT
		)

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
		
		--Q07 Accumulate 15,000 TVP in any three (3) months from May 2024 to Apr 2025
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			l.PK_Event			AS [PK_Event],
			7					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-05-01'		AS [dStartDate], 
			'2025-04-01'		AS [dEndDate], 
			3					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			15000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]
		FROM #Locations AS l
		WHERE l.PK_Event IN (202210,202211)

		--Q08 Accumulate 16,500 TVP in any three (3) months from May 2024 to Apr 2025
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			l.PK_Event			AS [PK_Event],
			8					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-05-01'		AS [dStartDate], 
			'2025-04-01'		AS [dEndDate], 
			3					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			16500				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]	
		FROM #Locations AS l
		WHERE l.PK_Event IN (202210,202211)

		--Q9 Accumulate 18,000 TVP in any three (3) months from May 2024 to Apr 2025
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			l.PK_Event			AS [PK_Event],
			9					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-05-01'		AS [dStartDate], 
			'2025-04-01'		AS [dEndDate], 
			3					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			18000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]
		FROM #Locations AS l
		WHERE l.PK_Event IN (202210,202211)
		
		--Q10 Achieve 1,000 RO in any one (1) month from May 2024 to Apr 2025
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			l.PK_Event			AS [PK_Event],
			10					AS QualificationNumber,
			1					AS Part, 
			'RO'				AS [MetricType], 
			'2024-05-01'		AS [dStartDate], 
			'2025-04-01'		AS [dEndDate], 
			1					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			1000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]	
		FROM #Locations AS l
		WHERE l.PK_Event IN (202210,202211)
		

		IF @IsDevQA = 0
		BEGIN	
			DELETE s FROM [Event].[SetupEventQualification] AS s WITH (NOLOCK) 
			INNER JOIN #Locations AS l
				ON s.PK_Event = l.PK_Event
	 
			INSERT INTO [Event].[SetupEventQualification](PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition 
			FROM #Event_SetupEventQualification
		END
		ELSE
		IF @IsDevQA = 3
		BEGIN	
			DELETE s FROM ##Event_SetupEventQualification_jgue AS s WITH (NOLOCK)
			INNER JOIN #Locations AS l
				ON s.PK_Event = l.PK_Event
	 
			INSERT INTO ##Event_SetupEventQualification_jgue(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition
			FROM #Event_SetupEventQualification
		END

		DECLARE @ColumnToPivot NVARCHAR(MAX),
			@SqlStatement NVARCHAR(MAX),
			@Countries VARCHAR(MAX) = 'HK,MC,JP,KS,TW,AS,NZ,ID,KH,MY,RP,SN,TH,VN'
							
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
				PK_Event				INT
				,PK_Distributor			INT
				,DistributorID			VARCHAR(20)
				,nMainDistributorID		INT DEFAULT 0
				,IsAssociatedID			BIT DEFAULT 0
				,SCountryCode			CHAR(5)
				,DSCurrentTeam			VARCHAR(10)        
				,DSSubTeam				VARCHAR(10)        
				,DSSPTeam				VARCHAR(10)  
				,SPQualDate				DATETIME

				,TVPMay24		MONEY DEFAULT 0.00
				,TVPJun24		MONEY DEFAULT 0.00
				,TVPJul24		MONEY DEFAULT 0.00
				,TVPAug24		MONEY DEFAULT 0.00
				,TVPSep24		MONEY DEFAULT 0.00
				,TVPOct24		MONEY DEFAULT 0.00
				,TVPNov24		MONEY DEFAULT 0.00
				,TVPDec24		MONEY DEFAULT 0.00
				,TVPJan25		MONEY DEFAULT 0.00
				,TVPFeb25		MONEY DEFAULT 0.00
				,TVPMar25		MONEY DEFAULT 0.00
				,TVPApr25		MONEY DEFAULT 0.00

				,ROMay24		MONEY DEFAULT 0.00
				,ROJun24		MONEY DEFAULT 0.00
				,ROJul24		MONEY DEFAULT 0.00
				,ROAug24		MONEY DEFAULT 0.00
				,ROSep24		MONEY DEFAULT 0.00
				,ROOct24		MONEY DEFAULT 0.00
				,RONov24		MONEY DEFAULT 0.00
				,RODec24		MONEY DEFAULT 0.00
				,ROJan25		MONEY DEFAULT 0.00
				,ROFeb25		MONEY DEFAULT 0.00
				,ROMar25		MONEY DEFAULT 0.00
				,ROApr25		MONEY DEFAULT 0.00
				
				,IsFromList			BIT DEFAULT 0
				,IsTicketPurchaser	BIT DEFAULT 0
				,IsFromCOP			BIT DEFAULT 0

			)

			INSERT INTO #DS
			(
				PK_Event
				,PK_Distributor
				,DistributorID
				,nMainDistributorID
				,IsAssociatedID
				,DSCurrentTeam
				,SPQualDate
				,SCountryCode
				,DSSubTeam
				,DSSPTeam
				,IsFromCOP
			)
			SELECT DISTINCT  
			L.PK_Event,
			D.nDistributorID AS PK_Distributor, 
			D.sDistributorID AS DistributorID,
			DA2.nMainDistributorID AS nMainDistributorID,
			CASE WHEN DA.nMainDistributorID IS NULL THEN 0 ELSE 1 END AS IsAssociatedID,
			CASE WHEN D.sTeam IS NULL THEN CASE WHEN D.sType = 'DS' THEN D.sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,
			D.dSupervisorqualification AS SPQualDate,
			D.sDistributorCountryProcessingCode AS SCountryCode,
			D.sSubTeam AS DSSubTeam,
			D.sType AS DSSPTeam,
			1 AS IsFromCOP
			FROM        
			dbo.v_Distributor AS D  
				INNER JOIN #Countries AS C
					ON D.nDistributorCountryProcessingID = C.nCountryID	
				LEFT JOIN dbo.v_DistributorAssociate2 DA2
					ON DA2.nDistributorID = D.nDistributorID AND DA2.dThrough = '2049-12-31'
				LEFT JOIN [Shared].[DistributorAssociation] DA (NOLOCK)
					ON DA.PK_Distributor = DA2.nMainDistributorID AND DA.AssociationType = 2
				CROSS APPLY (SELECT PK_Event FROM #Locations) AS L
			WHERE        
				D.StatusCode = 'COMPLETE'        
				AND D.sType = 'SP' 

			UNION

			SELECT DISTINCT  
			202210 AS PK_Event,
			D.nDistributorID AS PK_Distributor, 
			D.sDistributorID AS DistributorID,
			DA2.nMainDistributorID AS nMainDistributorID,
			CASE WHEN DA.nMainDistributorID IS NULL THEN 0 ELSE 1 END AS IsAssociatedID,
			CASE WHEN D.sTeam IS NULL THEN CASE WHEN D.sType = 'DS' THEN D.sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,
			D.dSupervisorqualification AS SPQualDate,
			D.sDistributorCountryProcessingCode AS SCountryCode,
			D.sSubTeam AS DSSubTeam,
			D.sType AS DSSPTeam,
			1 AS IsFromCOP
			FROM        
			dbo.v_Distributor AS D  
				INNER JOIN #Countries AS C
					ON D.nDistributorCountryProcessingID = C.nCountryID	
				LEFT JOIN dbo.v_DistributorAssociate2 DA2
					ON DA2.nDistributorID = D.nDistributorID AND DA2.dThrough = '2049-12-31'
				LEFT JOIN [Shared].[DistributorAssociation] DA (NOLOCK)
					ON DA.PK_Distributor = DA2.nMainDistributorID AND DA.AssociationType = 2
			WHERE        
				D.StatusCode = 'COMPLETE'        
				AND D.sType = 'DS' 

			CREATE INDEX IX_#DS_PK_Distributor ON #DS(PK_Distributor) INCLUDE(PK_Event);


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
				PK_Event
				,PK_Distributor
				,DistributorID
				,nMainDistributorID
				,IsAssociatedID
				,DSCurrentTeam
				,SPQualDate
				,SCountryCode
				,DSSubTeam
				,DSSPTeam
				,IsFromList
			)
			SELECT DISTINCT  
			L.PK_Event,
			D.nDistributorID AS PK_Distributor, 
			D.sDistributorID AS DistributorID,
			DA2.nMainDistributorID AS nMainDistributorID,
			CASE WHEN DA.nMainDistributorID IS NULL THEN 0 ELSE 1 END AS IsAssociatedID,
			CASE WHEN D.sTeam IS NULL THEN CASE WHEN D.sType = 'DS' THEN D.sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam, 
			D.dSupervisorqualification AS SPQualDate,
			D.sDistributorCountryProcessingCode AS SCountryCode,
			D.sSubTeam AS DSSubTeam,
			D.sType AS DSSPTeam,
			1 AS IsFromList
			FROM dbo.v_Distributor AS D  
				INNER JOIN #DSList AS L
					ON D.nDistributorID = L.PK_Distributor
				LEFT JOIN dbo.v_DistributorAssociate2 DA2
					ON DA2.nDistributorID = D.nDistributorID AND DA2.dThrough = '2049-12-31'
				LEFT JOIN [Shared].[DistributorAssociation] DA (NOLOCK)
					ON DA.PK_Distributor = DA2.nMainDistributorID AND DA.AssociationType = 2
			WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = L.PK_Distributor AND T.PK_Event = L.PK_Event)

			UPDATE D
			SET IsFromList = 1
			FROM #DS AS D  
				INNER JOIN #DSList AS L
					ON D.PK_Distributor = L.PK_Distributor
						AND D.PK_Event = L.PK_Event

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
				PK_Event
				,PK_Distributor
				,DistributorID
				,nMainDistributorID
				,IsAssociatedID
				,DSCurrentTeam
				,SPQualDate
				,SCountryCode
				,DSSubTeam
				,DSSPTeam
				,IsTicketPurchaser
			)
			SELECT DISTINCT       
			S.PK_Event,
			D.nDistributorID AS PK_Distributor, 
			D.sDistributorID AS DistributorID,
			DA2.nMainDistributorID AS nMainDistributorID,
			CASE WHEN DA.nMainDistributorID IS NULL THEN 0 ELSE 1 END AS IsAssociatedID,
			CASE WHEN D.sTeam IS NULL THEN CASE WHEN D.sType = 'DS' THEN D.sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam, 
			D.dSupervisorqualification AS SPQualDate,
			D.sDistributorCountryProcessingCode AS SCountryCode,
			D.sSubTeam AS DSSubTeam,
			D.sType AS DSSPTeam,
			1 AS IsTicketPurchaser
			FROM dbo.v_Distributor AS D  
				INNER JOIN #DSSKUs AS S
					ON D.nDistributorID = S.PK_Distributor
				LEFT JOIN dbo.v_DistributorAssociate2 DA2
					ON DA2.nDistributorID = D.nDistributorID AND DA2.dThrough = '2049-12-31'
				LEFT JOIN [Shared].[DistributorAssociation] DA (NOLOCK)
					ON DA.PK_Distributor = DA2.nMainDistributorID AND DA.AssociationType = 2
			WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = S.PK_Distributor AND T.PK_Event = S.PK_Event)

			UPDATE D
			SET IsTicketPurchaser = 1
			FROM #DS AS D  
				INNER JOIN #DSSKUs AS S
					ON D.PK_Distributor = S.PK_Distributor
						AND D.PK_Event = S.PK_Event

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 2 AND [StepSubGroup] = 2;
	END

	--Step 3: Volume
		
	IF @Step >= 3
	BEGIN

		PRINT 'Executing step 3'

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

		SELECT @PK_Event_General = MIN(PK_Event) FROM #Events WHERE IsMain = 1

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
				FROM #Event_SetupEventQualification WITH (NOLOCK) WHERE PK_Event = @PK_Event_General
	
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 1;

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
					[dSPQualDate] [datetime] NULL,
					[PK_DSType] [int] NULL
				)

				INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate])
				SELECT DISTINCT
					@PK_Event_General AS [PK_Event],
					D.PK_Distributor AS PK_Distributor,
					D.DistributorID AS DistributorID,
					@iStartDate AS [iStartDate],
					@iEndDate AS [iEndDate],
					@dStartDate AS [dStartDate],
					@dEndDate AS [dEndDate],
					D.SPQualDate 
				FROM #DS AS D
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
						
					DROP INDEX IF EXISTS [IX_##tmp_DS_jgue_PK_Distributor]
						ON ##tmp_DS_jgue;

					DELETE d FROM ##tmp_DS_jgue AS d WHERE d.PK_Event = @PK_Event_General 

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
				
			INSERT INTO #TimeLog VALUES ('usp_GetDSVolume', 3, 3, GETUTCDATE(), NULL);
						
			IF (@IsDevQA = 0)
			BEGIN
				-- SourceType 3: Getting points from [PubEventManagement].[dbo].[v_aggFQS_ID]
				EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event_General, @SourceType = 3,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
				--Output [Event].[DSPoints]

				IF @Error <> 0
				BEGIN
					SET @Error = @Error
					SET @ErrorMessage = @ErrorMessage
					RETURN;
				END
		
			END
			ELSE
			IF (@IsDevQA = 3) AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_jgue') IS NOT NULL
			BEGIN
					 
				--Input
				--##tmp_DS_jgue
				--##Event_SetupEventQualification_jgue

				EXEC [dbo].[##usp_GetDSVolume_jgue] @PK_Event = @PK_Event_General, @SourceType = 3,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
				IF @Error <> 0
				BEGIN
					SET @Error = @Error
					SET @ErrorMessage = @ErrorMessage

					SELECT @ErrorMessage
					RETURN;
				END

				--Output
				--##Event_DSPoints_jgue
		
			END
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 3;

			------------------------------------------------------------------------------------------------
			-- 3.5 Getting #Event_DSPoints 
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
					FROM ##Event_DSPoints_jgue
					WHERE PK_Event = @PK_Event_General

				END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 4;

			/***************************************************  
				Update TVP Points monthly on #DS
			****************************************************/
		
			INSERT INTO #TimeLog VALUES ('Update Points on #DS Event ' + CAST(@PK_Event_General AS VARCHAR), 3, 5, GETUTCDATE(), NULL);
			UPDATE
				T
			SET	
				T.TVPMay24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202405),0)
				,T.TVPJun24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202406),0)
				,T.TVPJul24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202407),0)
				,T.TVPAug24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202408),0)
				,T.TVPSep24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202409),0)
				,T.TVPOct24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202410),0)
				,T.TVPNov24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202411),0)
				,T.TVPDec24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202412),0)
				,T.TVPJan25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202501),0)
				,T.TVPFeb25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202502),0)
				,T.TVPMar25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202503),0)
				,T.TVPApr25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'TV' AND A.RoyaltyMonth = 202504),0)

				,T.ROMay24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'RO' AND A.RoyaltyMonth = 202405),0)
				,T.ROJun24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'RO' AND A.RoyaltyMonth = 202406),0)
				,T.ROJul24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'RO' AND A.RoyaltyMonth = 202407),0)
				,T.ROAug24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'RO' AND A.RoyaltyMonth = 202408),0)
				,T.ROSep24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'RO' AND A.RoyaltyMonth = 202409),0)
				,T.ROOct24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'RO' AND A.RoyaltyMonth = 202410),0)
				,T.RONov24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'RO' AND A.RoyaltyMonth = 202411),0)
				,T.RODec24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'RO' AND A.RoyaltyMonth = 202412),0)
				,T.ROJan25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'RO' AND A.RoyaltyMonth = 202501),0)
				,T.ROFeb25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'RO' AND A.RoyaltyMonth = 202502),0)
				,T.ROMar25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'RO' AND A.RoyaltyMonth = 202503),0)
				,T.ROApr25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.MetricType = 'RO' AND A.RoyaltyMonth = 202504),0)
			FROM
				#DS T

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 5;
		--END
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

			IF @IsDevQA = 0
			BEGIN

				INSERT INTO #TimeLog VALUES ('[tmp].[DSQualDef]', 4, 1, GETUTCDATE(), NULL);
					
				DROP INDEX IF EXISTS IX_tmp_DSQualDef_PK_Event ON [tmp].[DSQualDef];

				DELETE [tmp].[DSQualDef] WHERE PK_Event IN (SELECT PK_Event FROM #Locations)

				INSERT INTO [tmp].[DSQualDef]([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[Bonus],[QSVolume])
					SELECT 
						DISTINCT
						D.PK_Event,
						D.PK_Distributor AS PK_Distributor,
						A.StartDate AS dStartDate,
						A.EndDate AS dEndDate,
						CAST(CONVERT(varchar(6), A.StartDate, 112) AS int) AS iStartDate,
						CAST(CONVERT(varchar(6), A.EndDate, 112) AS int) AS iEndDate,
						D.SPQualDate AS [dSPQualDate],
						CAST(CONVERT(varchar(6), D.SPQualDate, 112) AS int) AS [iSPQualDate],
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
						NULL,
						NULL
					FROM #DS AS D					
						LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
							ON D.PK_Distributor = M.PK_Distributor
						OUTER APPLY (SELECT C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated,C.MetricType,C.GoalPoints,C.MinPoints,C.QualificationNumber,C.Part,C.Countries,C.Bonus,C.[QSVolume] FROM  #Event_SetupEventQualification AS C WHERE C.PK_Event = D.PK_Event) AS C
						CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A

			CREATE INDEX IX_tmp_DSQualDef_PK_Event ON [tmp].[DSQualDef](PK_Distributor) INCLUDE(PK_Event);

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 4 AND [StepSubGroup] = 1;

					
		END  
		ELSE IF @IsDevQA = 3
		BEGIN
				
			INSERT INTO ##tmp_DSQualDef_jgue([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[Bonus],[QSVolume])
					SELECT 
						DISTINCT
						D.PK_Event,
						D.PK_Distributor AS PK_Distributor,
						A.StartDate AS dStartDate,
						A.EndDate AS dEndDate,
						CAST(CONVERT(varchar(6), A.StartDate, 112) AS int) AS iStartDate,
						CAST(CONVERT(varchar(6), A.EndDate, 112) AS int) AS iEndDate,
						D.SPQualDate AS [dSPQualDate],
						CAST(CONVERT(varchar(6), D.SPQualDate, 112) AS int) AS [iSPQualDate],
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
						NULL,
						NULL
					FROM #DS AS D					
						LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
							ON D.PK_Distributor = M.PK_Distributor
						OUTER APPLY (SELECT C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated,C.MetricType,C.GoalPoints,C.MinPoints,C.QualificationNumber,C.Part,C.Countries,C.Bonus,C.[QSVolume] FROM  #Event_SetupEventQualification AS C WHERE C.PK_Event = D.PK_Event) AS C
						CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
				
		END
	END
		
	--Step 5: Getting DSPointsSummary		
	IF @Step >= 5
	BEGIN
			
		PRINT 'Executing step 5'
		
		INSERT INTO #TimeLog VALUES ('#Event_DSPoints_Summary', 5, 1, GETUTCDATE(), NULL);
		
		DROP TABLE IF EXISTS #Event_DSPoints_Summary

		CREATE TABLE #Event_DSPoints_Summary
		(
			[PK_Event] [int] NULL,
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
 
		INSERT INTO #Event_DSPoints_Summary(PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,QSVolumePercentage,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries)
			SELECT	DISTINCT
					F.PK_Event,
					U.PK_Distributor,
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
						INNER JOIN [tmp].[DSQualDef] AS F (NOLOCK)
							ON 
								U.PK_Distributor = F.PK_Distributor	
							WHERE 
							F.MetricType = U.MetricType 
							AND 
							U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
							AND 
			(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
			GROUP BY F.PK_Event, U.PK_Distributor,U.RoyaltyMonth,U.MetricType,F.[QSVolume],F.[QSVolumePercentage],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries
					
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

			INSERT INTO #tmp_DSPointsSummary([PK_Event],PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate)
			SELECT DISTINCT
					P.PK_Event AS PK_Event,
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

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 2;


			INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary]', 5, 3, GETUTCDATE(), NULL);

			IF @IsDevQA = 0
			BEGIN			
					
				DELETE t
				FROM [tmp].[DSPointsSummary] AS t
				WHERE t.PK_Event IN (SELECT PK_Event FROM #Locations)

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
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 3;
	
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

				IF @IsDevQA = 3
				BEGIN
					INSERT INTO #Event_DSQualPoints([PK_Event],PK_Distributor,QualificationNumber,Part,QualDate)
					SELECT 
						@PK_Event_Execution AS [PK_Event]
						,PK_Distributor
						,QualificationNumber 
						,Part		
						,QualDate
					FROM ##DSQualPoints_jgue AS Q
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

		INSERT INTO #TimeLog VALUES ('#EventQual', 7, 1, GETUTCDATE(), NULL);

		DROP INDEX IF EXISTS IX_#EventQual ON #EventQual;

		INSERT INTO #EventQual(PK_Event,PK_Distributor,Q01,Q02,Q03,Q04,Q05,Q06,Q28)
			SELECT 
				D.PK_Event AS [PK_Event],
				D.PK_Distributor,
				IIF(D.DSSPTeam = 'SP',1,0)								AS Q01, -- FQS and above
				IIF(D.DSSubTeam = 'WT',1,0)								AS Q02, -- WT 
				IIF(D.DSCurrentTeam IN ('P','A','B','C'),1,0)			AS Q03, -- PT and above
				IIF(D.DSSubTeam = '30K',1,0)							AS Q04, -- PT 30K and above
				IIF(D.DSCurrentTeam IN ('G','M','P','A','B','C'),1,0)	AS Q05, -- TAB
				D.IsFromCOP												AS Q06, -- COP
				IIF(D.DSSPTeam = 'DS',1,0)								AS Q28 -- DS and above
			FROM #DS AS D
			WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)

			CREATE INDEX IX_#EventQual ON #EventQual(PK_Distributor) INCLUDE(PK_Event);

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 1;

			------------------------------------------------------------------------------------------------
			-- List qualifications
			------------------------------------------------------------------------------------------------
			INSERT INTO #TimeLog VALUES ('List qualifications', 7, 2, GETUTCDATE(), NULL);

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

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 2;

			------------------------------------------------------------------------------------------------
			-- SKUs qualifications
			------------------------------------------------------------------------------------------------
			INSERT INTO #TimeLog VALUES ('SKUs qualifications', 7, 3, GETUTCDATE(), NULL);

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
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 3;
			------------------------------------------------------------------------------------------------
			-- Volume qualifications
			------------------------------------------------------------------------------------------------
			INSERT INTO #TimeLog VALUES ('Volume qualifications', 7, 4, GETUTCDATE(), NULL);
			
			BEGIN
			
			DROP TABLE IF EXISTS #QualificationsMapping

			SELECT 
			IDENTITY(INT,1,1) AS ID, 
			PK_Event,QualificationNumber,[Part], 
			IIF(QualificationNumber < 10, 'Q0' + CAST(QualificationNumber AS VARCHAR(5)), 'Q' + CAST(QualificationNumber AS VARCHAR(5))) AS  QColumn, 
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

				DROP TABLE IF EXISTS ##QualVolumeQualifiers_25039

				SET @SqlStatement = ''

				SET @SqlStatement = N'SELECT Q1.PK_Event,Q1.PK_Distributor	
				INTO ##QualVolumeQualifiers_25039
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
				INNER JOIN ##QualVolumeQualifiers_25039 AS QQ
				ON Q.PK_Event = QQ.PK_Event
				AND Q.PK_Distributor = QQ.PK_Distributor'

				EXECUTE sp_executesql @SqlStatement

				UPDATE #QualificationsMapping
				SET [ctrl] = 1
				WHERE ID = @ID


			END

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 4;
			------------------------------------------------------------------------------------------------
			-- Other qualifications
			------------------------------------------------------------------------------------------------
			INSERT INTO #TimeLog VALUES ('Other qualifications', 7, 5, GETUTCDATE(), NULL);

			BEGIN

			 PRINT 'Q11 World Team members who qualify for the World Team 1% Bonus in any one (1) month from April  2024 to April 2025'		 

				--Q11 World Team members who qualify for the World Team 1% Bonus in any one (1) month from April  2024 to April 2025 

				DROP TABLE IF EXISTS #Q11

				SELECT T.PK_Distributor 
				INTO #Q11
				FROM #DS AS t  
 				INNER JOIN dbo.WTOnePercent_Qualifiers_Tracking AS a WITH (NOLOCK)
 	 			ON t.PK_Distributor = a.PK_Distributor   
 				WHERE QualifiedYear = 2024 AND ([Apr] = 1 OR a.[May] = 1 OR a.[Jun] = 1 OR a.[Jul] = 1 OR a.[Aug] = 1 OR a.[Sep] = 1 OR a.[Oct] = 1 OR a.[Nov] = 1 OR a.[Dec] = 1)
				UNION
				SELECT T.PK_Distributor 		 
				FROM #DS AS t  
 				INNER JOIN dbo.WTOnePercent_Qualifiers_Tracking AS a WITH (NOLOCK)
 	 			ON t.PK_Distributor = a.PK_Distributor   
 				WHERE QualifiedYear = 2025 AND ([Jan] = 1 OR [Feb] = 1 OR [Mar] = 1 OR [Apr] = 1)

				CREATE INDEX IX_#Q11_PK_Distributor ON #Q11(PK_Distributor);

				UPDATE E
					SET 
						Q11 = 1
					FROM #EventQual AS E
					INNER JOIN #Q11 AS Q11
					ON E.PK_Distributor = Q11.PK_Distributor

			 PRINT 'Q12 2024 HPL qualifiers Qualified to E1 of the "24087 - WW - Premier League Program 2024" (PK ID 199427) From Aptil 2024 to December 2024'		 

				--Q12 2024 HPL qualifiers Qualified to E1 of the "24087 - WW - Premier League Program 2024" (PK ID 199427) From Aptil 2024 to December 2024

				DROP TABLE IF EXISTS #Q12

				SELECT DISTINCT d.PK_Distributor
				INTO #Q12
				FROM #DS AS d
					INNER JOIN Promo.WRK_PremierLeague_SubEvent AS plq (NOLOCK)
						ON ContributingYear = 2024 AND SubEvent = 1 AND d.PK_Distributor = plq.PK_Distributor

				CREATE INDEX IX_#Q12_PK_Distributor ON #Q12(PK_Distributor)

				UPDATE E
					SET 
						Q12 = 1
					FROM #EventQual AS E
					INNER JOIN #Q12 AS Q12
					ON E.PK_Distributor = Q12.PK_Distributor


				PRINT 'Q13 2025 HPL qualfiers Qualified to E1 of the "25047 - WW HPL 2025" (PK ID 202477) from January 2025 to April 2025'		 

				--Q13 2025 HPL qualfiers Qualified to E1 of the "25047 - WW HPL 2025" (PK ID 202477) from January 2025 to April 2025

				DROP TABLE IF EXISTS #Q13

				SELECT DISTINCT d.PK_Distributor
				INTO #Q13
				FROM #DS AS d
					INNER JOIN Promo.WRK_HPL2025_SubEvent AS plq (NOLOCK)
						ON ContributingYear = 2025 AND SubEvent IN (1,2) AND DateQualified BETWEEN 202501 AND 202504 AND d.PK_Distributor = plq.PK_Distributor

				CREATE INDEX IX_#Q13_PK_Distributor ON #Q13(PK_Distributor)

				UPDATE E
					SET 
						Q13 = 1
					FROM #EventQual AS E
					INNER JOIN #Q13 AS Q13
					ON E.PK_Distributor = Q13.PK_Distributor

			END
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 5;

	END

	--Step 8: Qualifying to Subevents
	IF @Step >= 8
	BEGIN

		PRINT 'Executing step 8'

		INSERT INTO #TimeLog VALUES ('Es #EventQual', 8, 1, GETUTCDATE(), NULL);

		UPDATE 
			#EventQual
		SET
			E01 = (Q01 | Q02 | Q03 | Q04 | Q05 | Q28 | Q22),
			E07 = (Q14),
			E08 = ((Q12 | Q13) & Q06),
			E09 = (Q15),
			E10 = (Q16),
			E11 = (Q17),
			E12 = (Q18),
			E13 = (Q19),
			E14 = ((Q12 | Q13) & Q06),
			E15 = (Q11),
			E16 = (Q20),
			E17 = (Q21)

		UPDATE 
			#EventQual
		SET
			E02 = ((Q01 & Q07) | Q23),
			E03 = ((Q01 & Q08) | Q24),
			E04 = ((Q01 & Q09) | Q25),
			E05 = ((Q05 | (Q01 & Q10) | (Q02 & (Q11 | Q12 | Q13))) | Q26),
			E06 = (Q03 | Q27)
		WHERE 
			PK_Event = 202210

		UPDATE 
			#EventQual
		SET
			E02 = (Q07 | Q23),
			E03 = (Q08 | Q24),
			E04 = (Q09 | Q25),
			E05 = ((Q05 | (Q01 & Q10) | (Q02 & (Q11 | Q12 | Q13)) & Q06) | Q26),
			E06 = (Q03 | Q04 | Q27)
		WHERE 
			PK_Event = 202211

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

	--Step 9: [Event].[DSQual]	
	IF @Step >= 9
	BEGIN
			
		PRINT 'Executing step 9'

		IF @IsDevQA = 0
		BEGIN
			
			INSERT INTO #TimeLog VALUES ('Deleting [Event].[DSQual]', 9, 1, GETUTCDATE(), NULL);

			DROP INDEX IF EXISTS [IX_Event_DSQual_PK_Distributor_PK_Event]
						ON [Event].[DSQual];

			DROP INDEX IF EXISTS [IX_Event_DSQual_PK_Event]
						ON [Event].[DSQual];

			DELETE dq			
			FROM [Event].[DSQual] AS dq
				INNER JOIN #Locations AS l
					ON dq.PK_Event = l.PK_Event

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 9 AND [StepSubGroup] = 1;

			INSERT INTO #TimeLog VALUES ('Inserting [Event].[DSQual]', 9, 2, GETUTCDATE(), NULL);	

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
			FROM #EventQual AS q
			WHERE 
				q.PK_Event = 202211

			UNION

			SELECT
				PK_Event	
				,PK_Distributor	
				,CreatedDate	
				,UpdatedDate	
				,Q28,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10	-- Q28 = Q01 according to the BRD		
				,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20		-- the consecutive qualifications are offset by 1 for 202210 event A
				,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q29,Q30
				,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40
				,Q41,Q42,Q43,Q44,Q45,Q46,Q47,Q48,Q49,Q50	
				,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10
				,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20
				,E21,E22,E23,E24,E25,E26,E27,E28,E29,E30
				,E31,E32,E33,E34,E35,E36,E37,E38,E39,E40
				,E41,E42,E43,E44,E45,E46,E47,E48,E49,E50
			FROM #EventQual AS q
			WHERE 
				q.PK_Event = 202210

			CREATE INDEX [IX_Event_DSQual_PK_Event] ON [Event].[DSQual](PK_Event);
			CREATE INDEX [IX_Event_DSQual_PK_Distributor_PK_Event] ON [Event].[DSQual](PK_Distributor) INCLUDE(PK_Event);

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 9 AND [StepSubGroup] = 2;

		END
		ELSE IF @IsDevQA = 3
		BEGIN

			DROP TABLE IF EXISTS ##Event_DSQual_jgue 
	 
			SELECT
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
			INTO ##Event_DSQual_jgue
			FROM #EventQual AS q		
			WHERE 
				q.PK_Event = 202211

			UNION

			SELECT
				PK_Event	
				,PK_Distributor	
				,CreatedDate	
				,UpdatedDate	
				,Q28,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10	-- Q28 = Q01 according to the BRD		
				,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20		-- the consecutive qualifications are offset by 1 for 202210 event A
				,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q29,Q30
				,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40
				,Q41,Q42,Q43,Q44,Q45,Q46,Q47,Q48,Q49,Q50	
				,E01,E02,E03,E04,E05,E06,E07,E08,E09,E10
				,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20
				,E21,E22,E23,E24,E25,E26,E27,E28,E29,E30
				,E31,E32,E33,E34,E35,E36,E37,E38,E39,E40
				,E41,E42,E43,E44,E45,E46,E47,E48,E49,E50
			FROM #EventQual AS q
			WHERE 
				q.PK_Event = 202210

		END

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