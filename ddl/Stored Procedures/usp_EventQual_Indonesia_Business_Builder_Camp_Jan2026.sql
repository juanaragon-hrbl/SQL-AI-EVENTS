CREATE PROCEDURE [dbo].[usp_EventQual_Indonesia_Business_Builder_Camp_Jan2026]
	@Parameters NVARCHAR(MAX) = NULL
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT
	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_Indonesia_Business_Builder_Camp_Jan2026

	USE:	
	

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			DECLARE @e int, @em varchar(4000), @param nvarchar(max)
			
			SET @param = N'{
					"pK_Event":204539,
					"step":10,
					"countries":"ID",
					"spQualDateStart":"1969-01-01",
					"spQualDateEnd":"2025-09-01",
					"qualPeriodStartA":"2025-09-01",
					"qualPeriodEndA":"2025-12-01",
					"listsValues": [
										{ "pK_Event":204539, "listID":66830, "qId":7 },
										{ "pK_Event":204539, "listID":66831, "qId":8 },
										{ "pK_Event":204539, "listID":66832, "qId":9 }
									]
			}'

			EXEC dbo.usp_EventQual_Indonesia_Business_Builder_Camp_Jan2026 @Parameters= @param, @IsDevQA = 0, @Error = @e OUTPUT, @ErrorMessage = @em OUTPUT 
			
			SELECT @e AS [Error], @em AS [ErrorMessage]

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

	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2025-10-08			JuanGue			Initial 	
	1.0.1	2025-11-05			JuanGue			#1431022 DS id not qualified to E2 by Q3 Achieve 3,500 TVP Sep - Dec 2025
	1.0.2	2025-11-05			JuanGue			#1431029 DS ids outside COP qualified and does not have SKU
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
			[QSVolumePercentage] [int] NULL
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

	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_jgue') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetDSVolume_jgue] is missing, create it manually' AS [ErrorMessage]
	END

	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetQualifier_Points_jgue') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetQualifier_Points_jgue] is missing, create it manually' AS [ErrorMessage]
	END

	SET NOCOUNT ON;

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
				
	SELECT @Error = 0, @ErrorMessage = '';	

BEGIN TRY
		
	-- Variables for json values

	DECLARE 
		@PK_Event INT,
		@QualPeriodStartA DATETIME,
		@QualPeriodEndA DATETIME,
		@SPQualDateStart DATETIME,
		@SPQualDateEnd DATETIME,
		@Step INT,
		@Countries VARCHAR(MAX),
		@ListsValues NVARCHAR(MAX)

	-- Getting parameters values for json

	SELECT   
		@PK_Event 				= g.pK_Event,
		@QualPeriodStartA		= g.qualPeriodStartA,		
		@QualPeriodEndA			= g.qualPeriodEndA,	
		@SPQualDateStart		= g.spQualDateStart,		
		@SPQualDateEnd			= g.spQualDateEnd,		
		@Step 					= g.step, 						
		@Countries 				= g.countries,
		@ListsValues			= g.listsValues

	FROM OPENJSON(@Parameters)
	WITH ( 
			pK_Event INT '$.pK_Event',
			qualPeriodStartA DATETIME '$.qualPeriodStartA',
			qualPeriodEndA DATETIME '$.qualPeriodEndA',
			spQualDateStart DATETIME '$.spQualDateStart',
			spQualDateEnd DATETIME '$.spQualDateEnd',
			step INT '$.step',
			countries VARCHAR(MAX) '$.countries',
			listsValues NVARCHAR(MAX) '$.listsValues'
		) AS g
	 
	-- Default values

	SET	@PK_Event = IIF(@PK_Event IS NULL,204539, @PK_Event)
	SET	@QualPeriodStartA = IIF(@QualPeriodStartA IS NULL,'2025-09-01', @QualPeriodStartA)
	SET	@QualPeriodEndA  = IIF(@QualPeriodEndA IS NULL,'2025-12-01', @QualPeriodEndA)
	SET	@SPQualDateStart = IIF(@SPQualDateStart IS NULL,'1969-01-01', @SPQualDateStart)
	SET	@SPQualDateEnd  = IIF(@SPQualDateEnd IS NULL,'2025-09-01', @SPQualDateEnd)
	SET @Step = IIF(@Step IS NULL,10, @Step)
	SET @Countries = IIF(@Countries IS NULL,'ID', @Countries)
	SET @ListsValues = IIF(@ListsValues IS NULL, N'[
													{ "pK_Event":204539, "listID":66830, "qId":7 },
													{ "pK_Event":204539, "listID":66831, "qId":8 },
													{ "pK_Event":204539, "listID":66832, "qId":9 }
												]', @ListsValues)

	SELECT
		@PK_Event			AS	[PK_Event],
		@QualPeriodStartA	AS	[QualPeriodStartA],
		@QualPeriodEndA 	AS	[QualPeriodEndA],
		@SPQualDateStart	AS	[SPQualDateStart],
		@SPQualDateEnd 		AS	[SPQualDateEnd],
		@Step				AS	[Step],
		@Countries			AS	[Countries],
		@ListsValues		AS	[ListsValues]


	-- Getting lists values from the parameter for json

	DROP TABLE IF EXISTS #ListsQsMapping

	CREATE TABLE #ListsQsMapping
	(
		ID INT IDENTITY(1,1),
		PK_Event INT,
		ListID INT,
		QId INT
	)

	INSERT INTO #ListsQsMapping(PK_Event,ListID,QId)
	SELECT   
		g.pK_Event,
		g.listID,
		g.qId
	FROM OPENJSON(@ListsValues)
	WITH ( 
			pK_Event INT '$.pK_Event',
			listID INT '$.listID',
			qId INT '$.qId'
	) AS g

	------------------------------------------------------------------------------------------------
	-- Tables and variables
	------------------------------------------------------------------------------------------------
	BEGIN

		-- *  Custom

		DECLARE @ColumnToPivot NVARCHAR(MAX),
				@SqlStatement NVARCHAR(MAX)

		DECLARE @PK_Event_General	INT

		DROP TABLE IF EXISTS #Locations

		CREATE TABLE #Locations
		(			
			[PK_Event] [int],
			[Location] [varchar](200),
			[CountryCode]	varchar(200), 
			[ctrl] [bit] DEFAULT(0)
		)

		INSERT INTO #Locations([PK_Event],[Location], [CountryCode])
		SELECT 
			@PK_Event AS [PK_Event],
			'Indonesia' AS [Location],
			@Countries AS [CountryCode]

		SELECT * FROM #ListsQsMapping

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

		IF (@IsDevQA = 2)
		BEGIN
			PRINT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1 
		END

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
			--Q2	Achieve 2,500 TVP in each month from Sep 2025 - Dec 2025
			SELECT 
			l.PK_Event,
			2 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodStartA AS [dStartDate], 
			@QualPeriodEndA AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			'-W' AS [Countries],
			1 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event)
			UNION
			--Q3	Achieve 3,500 TVP in each month from Sep 2025 - Dec 2025
			SELECT 
			l.PK_Event,
			3 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodStartA AS [dStartDate], 
			@QualPeriodEndA AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			3500 AS [GoalPoints], 
			'-W' AS [Countries],
			1 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event)
			UNION
			--Q4	Achieve 5,000 TVP in each month from Sep 2025 - Dec 2025
			SELECT 
			l.PK_Event,
			4 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodStartA AS [dStartDate], 
			@QualPeriodEndA AS [dEndDate],  
			4 AS [Frequency], 
			1 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			'-W' AS [Countries],
			1 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event)
			UNION
			--Q5  Accumulate 14,000 TVP from Sep 2025 - Dec 2025
			--    with a minimum of 12,600 points (90%) from COP = ID
			SELECT 
			l.PK_Event,
			5 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodStartA AS [dStartDate], 
			@QualPeriodEndA AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			14000 AS [GoalPoints], 
			'-W' AS [Countries],
			1 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event)
			UNION
			-- with a minimum of 12,600 points (90%) from COP = ID
			SELECT 
			l.PK_Event,
			36 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodStartA AS [dStartDate], 
			@QualPeriodEndA AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			12600 AS [GoalPoints], 
			'ID' AS [Countries],
			1 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event)
			UNION
			--Q6   Accumulate 20,000 TVP from Sep 2025 - Dec 2025
			--     with a minimum of 18,000 points (90%) from COP = ID
			SELECT 
			l.PK_Event,
			6 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodStartA AS [dStartDate], 
			@QualPeriodEndA AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			20000 AS [GoalPoints], 
			'-W' AS [Countries],
			1 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event)
			UNION
			-- with a minimum of 18,000 points (90%) from COP = ID
			SELECT 
			l.PK_Event,
			37 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodStartA AS [dStartDate], 
			@QualPeriodEndA AS [dEndDate],  
			4 AS [Frequency], 
			0 AS [Consecutive], 
			1 AS [Accumulated], 
			0 AS [MinPoints], 
			18000 AS [GoalPoints], 
			'ID' AS [Countries],
			1 AS [QSVolume],
			0 AS [Bonus]
			FROM #Locations AS l
			WHERE l.PK_Event IN (@PK_Event)
		) 

	INSERT INTO #Event_SetupEventQualification(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,QSVolume)
	SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,QSVolume
	FROM cte_Quals

		IF @IsDevQA = 0
		BEGIN	

			DELETE s 
			FROM [Event].[SetupEventQualification] AS s WITH (NOLOCK)  
				INNER JOIN #Locations AS l
					ON s.PK_Event = l.PK_Event
	 
			INSERT INTO [Event].[SetupEventQualification](PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,QSVolume)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,QSVolume
			FROM #Event_SetupEventQualification
		 
		END
		ELSE IF @IsDevQA = 3
		BEGIN	

			DELETE s 
			FROM ##Event_SetupEventQualification_jgue AS s  
				INNER JOIN #Locations AS l
					ON s.PK_Event = l.PK_Event
	 
			INSERT INTO ##Event_SetupEventQualification_jgue(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,QSVolume)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,QSVolume
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
			WHERE sCountryCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar](@Countries, ','))

			DROP TABLE IF EXISTS #DS

			CREATE TABLE #DS
			(
				PK_Event				INT
				,PK_Distributor			INT
				,DistributorID			VARCHAR(MAX) 
				,nMainDistributorID		INT DEFAULT 0
				,IsAssociatedID			BIT DEFAULT 0	
				,DSCurrentTeam			VARCHAR(10)        
				,DSSubTeam				VARCHAR(10)        
				,DSSPTeam				VARCHAR(10)               
				,dSPQualDate			DATETIME2        
				,CountryCode			VARCHAR(5)
				,IsFromList				BIT DEFAULT(0)
				,IsTicketPurchaser		BIT DEFAULT(0)
				,IsFromCOP				BIT DEFAULT(0)
				,TVPSep25				MONEY DEFAULT 0
				,TVPOct25				MONEY DEFAULT 0
				,TVPNov25				MONEY DEFAULT 0
				,TVPDec25				MONEY DEFAULT 0
				,IndonesiaTVPSep25		MONEY DEFAULT 0
				,IndonesiaTVPOct25		MONEY DEFAULT 0
				,IndonesiaTVPNov25		MONEY DEFAULT 0
				,IndonesiaTVPDec25		MONEY DEFAULT 0
				,TotalTVP				AS (TVPSep25 + TVPOct25 + TVPNov25 + TVPDec25)
				,IndonesiaTotalTVP		AS (IndonesiaTVPSep25 + IndonesiaTVPOct25 + IndonesiaTVPNov25 + IndonesiaTVPDec25)
			)

			INSERT INTO #DS
			(
				PK_Event
				,PK_Distributor
				,DistributorID
				,nMainDistributorID
				,IsAssociatedID
				,DSCurrentTeam
				,dSPQualDate
				,CountryCode
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
			D.dSupervisorqualification AS dSPQualDate,
			D.sDistributorCountryProcessingCode AS CountryCode,
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
				AND D.sType IN ('SP') 
							   	
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
			,dSPQualDate
			,CountryCode
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
				,dSPQualDate
				,CountryCode
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

		SELECT @PK_Event_General = MIN(PK_Event) FROM #Locations

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
					D.dSPQualDate 
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
				-- SourceType 1: Getting points from PubEvents.[dbo].[factDSFinancial_ctry], includes divorce and tranfer cases.
				EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event_General, @SourceType = 1,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
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
				-- SourceType 1: Getting points from PubEvents.[dbo].[factDSFinancial_ctry], includes divorce and tranfer cases.
				EXEC [dbo].[##usp_GetDSVolume_jgue] @PK_Event = @PK_Event_General, @SourceType = 1,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
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

			CREATE CLUSTERED INDEX [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints ([PK_Distributor]) 
			CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints ([MetricType])						

			/***************************************************  
				  Update TVP Points monthly on #DS
			****************************************************/

			UPDATE
				T
			SET	
				T.TVPSep25				= IIF(A.RoyaltyMonth = 202509 AND A.MetricType = 'TV'	AND A.PK_Country = 12,A.Points,0)
				,T.TVPOct25				= IIF(A.RoyaltyMonth = 202510 AND A.MetricType = 'TV'	AND A.PK_Country = 12,A.Points,0) 
				,T.TVPNov25				= IIF(A.RoyaltyMonth = 202511 AND A.MetricType = 'TV'	AND A.PK_Country = 12,A.Points,0)
				,T.TVPDec25				= IIF(A.RoyaltyMonth = 202512 AND A.MetricType = 'TV'	AND A.PK_Country = 12,A.Points,0)
				,T.IndonesiaTVPSep25	= IIF(A.RoyaltyMonth = 202509 AND A.MetricType = 'TV'	AND A.PK_Country = 710003,A.Points,0) 				
				,T.IndonesiaTVPOct25	= IIF(A.RoyaltyMonth = 202510 AND A.MetricType = 'TV'	AND A.PK_Country = 710003,A.Points,0) 
				,T.IndonesiaTVPNov25	= IIF(A.RoyaltyMonth = 202511 AND A.MetricType = 'TV'	AND A.PK_Country = 710003,A.Points,0) 
				,T.IndonesiaTVPDec25	= IIF(A.RoyaltyMonth = 202512 AND A.MetricType = 'TV'	AND A.PK_Country = 710003,A.Points,0) 
			FROM
				#DS T
			INNER JOIN #Event_DSPoints A
				ON A.PK_Distributor = T.PK_Distributor

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
					U.PK_Country,
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
						INNER JOIN [tmp].[DSQualDef] AS F (NOLOCK)
							ON 
								U.PK_Distributor = F.PK_Distributor	
							WHERE 
							F.MetricType = U.MetricType 
							AND 
							U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
							AND 
			(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
			GROUP BY F.PK_Event, U.PK_Distributor,U.RoyaltyMonth,U.MetricType,U.PK_Country,F.[QSVolume],F.[QSVolumePercentage],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries
					
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
					 --##DSPointsSummary_jgue
					 --##Event_DSPoints_jgue
					 --##tmp_DSQualDef_jgue
					 --##Event_SetupEventQualification_jgue
					EXEC ##usp_GetQualifier_Points_jgue @PK_Event = @PK_Event_Execution, @QualType = @QualType, @OverwritePointsSummary = @OverwritePointsSummary, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
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

		INSERT INTO #EventQual(PK_Event,PK_Distributor,Q01,Q45,Q50)
			SELECT 
				D.PK_Event AS [PK_Event],
				D.PK_Distributor,
				IIF(D.DSSPTeam = 'SP' 
					AND D.dSPQualDate BETWEEN @SPQualDateStart AND @SPQualDateEnd,1,0)	AS Q01, -- FQS and above (SP Qual Date <= Sep 01 2025)
				D.IsTicketPurchaser														AS Q45, -- Ticket purchaser
				D.IsFromCOP																AS Q50	-- From COP
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

				DROP TABLE IF EXISTS ##QualVolumeQualifiers_26025

				SET @SqlStatement = ''

				SET @SqlStatement = N'SELECT Q1.PK_Event,Q1.PK_Distributor	
				INTO ##QualVolumeQualifiers_26025
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
				INNER JOIN ##QualVolumeQualifiers_26025 AS QQ
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

			 PRINT 'No Other qualifications'		 

			END
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 5;
		END
 
		--Step 8: Subevents
		IF @Step >= 8
		BEGIN

			PRINT 'Executing step 8'

			INSERT INTO #TimeLog VALUES ('Es #EventQual', 8, 1, GETUTCDATE(), NULL);
	 
			-- Delete distributors who are nor achieving any qualification
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

			UPDATE 
				#EventQual
			SET
				E01 = (((Q45 | Q50) & (Q01 & Q02)) | Q07)

			UPDATE 
				#EventQual
			SET
				E02 = (((Q45 | Q50) & (E01 & (Q03 | (Q05 & Q36 & Q02)))) | Q08),
				E03 = (((Q45 | Q50) & (E01 & (Q04 | (Q06 & Q37 & Q02)))) | Q09)

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 8 AND [StepSubGroup] = 1;

		END

		--Step 9: [Event].[DSQual]	
		IF @Step >= 9
		BEGIN
			
			PRINT 'Executing step 9'

			INSERT INTO #TimeLog VALUES ('[Event].[DSQual]	', 9, 1, GETUTCDATE(), NULL);

			IF @IsDevQA = 0
			BEGIN

				IF OBJECT_ID (N'[tmp].[DSQual]', N'U') IS NOT NULL 
				BEGIN
					DELETE dq			
					FROM [tmp].[DSQual] AS dq
						INNER JOIN #Locations AS l
							ON dq.PK_Event = l.PK_Event
				END

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
			FROM #EventQual

				CREATE INDEX [IX_Event_DSQual_PK_Event] ON [Event].[DSQual](PK_Event);
				CREATE INDEX [IX_Event_DSQual_PK_Distributor_PK_Event] ON [Event].[DSQual](PK_Distributor) INCLUDE(PK_Event);

			END
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 9 AND [StepSubGroup] = 1;

		END
	 
		--Step 10: SubEventQualifiers
		IF @Step >= 10  AND  @IsDevQA = 0
		BEGIN

			PRINT 'Executing step 10'
		
			INSERT INTO #TimeLog VALUES ('SubEventQualifiers', 10, 1, GETUTCDATE(), NULL);

			DECLARE @Events VARCHAR(MAX)
				
			SELECT @Events = STRING_AGG(PK_Event,',') FROM #Locations

			EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
			@Events = @Events,
			@Source = 2,
			@EvaluateFormula = 0		

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