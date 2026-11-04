CREATE PROCEDURE [dbo].[usp_EventQual_MexicoFSL_May2026]
	@Parameters NVARCHAR(MAX) = NULL
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT
	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_MexicoFSL_May2026

	USE:		
			Execution 1
			---------------------------------------------------------------------------------------------------------

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			DECLARE @e int, @em varchar(4000) 			
			 
			EXEC dbo.usp_EventQual_MexicoFSL_May2026  @IsDevQA = 0, @Error = @e OUTPUT, @ErrorMessage = @em OUTPUT 
			
			SELECT @e AS [Error], @em AS [ErrorMessage]

			GO

			Execution 2
			---------------------------------------------------------------------------------------------------------

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			DECLARE @e int, @em varchar(4000), @param nvarchar(max)
			
			SET @param = N'{
					"currentDatetime": null,
					"pK_Event_MAIN":204657,
					"pK_Event_VE":205329,
					"pK_Event_PU":205330,
					"pK_Event_MO":205331,
					"pK_Event_CA":205332,
					"pK_Event_AC":205333,

					"step":11,
					"eventEndDateMAIN":"2026-05-30",
					"eventEndDateVE":"2026-05-30",
					"eventEndDatePU":"2026-05-30",
					"eventEndDateMO":"2026-05-30",
					"eventEndDateCA":"2026-05-30",
					"eventEndDateAC":"2026-05-30",

					"qualPeriodStartQ5":"2026-01-01",
					"qualPeriodEndQ5":"2026-04-01",
					"qualPeriodStartQ10":"2026-01-01",
					"qualPeriodEndQ10":"2026-04-01",
					"qualPeriodStartQ11":"2026-01-01",
					"qualPeriodEndQ11":"2026-04-01",

					"qualPeriodForDLStart":"2026-01-01",
					"qualPeriodForDLEnd":"2026-04-01",
					"dLCountries":"MX",
					"qSVolume":1,

					"sPqualDateStartA":"2026-01-01",
					"sPqualDateEndA":"2026-05-01",
					"qSActualQualDateStart":"2026-05-01",
					"qSActualQualDateEnd":"2026-05-31",

					"aSPQualPeriodStart":"2026-01-01",
					"aSPQualPeriodEnd":"2026-04-01",

					"countries":"MX",
					"listsValues": [
									{ "pK_Event":204657, "listID":65928, "qId":12 },
									{ "pK_Event":204657, "listID":67007, "qId":13 },
									{ "pK_Event":204657, "listID":67008, "qId":14 },
									{ "pK_Event":204657, "listID":67009, "qId":15 },
									{ "pK_Event":204657, "listID":67010, "qId":16 },
									{ "pK_Event":204657, "listID":67011, "qId":17 },
									{ "pK_Event":204657, "listID":67012, "qId":18 },
									{ "pK_Event":204657, "listID":67013, "qId":19 },
									{ "pK_Event":204657, "listID":68185, "qId":20 }
								]
				}'

			EXEC dbo.usp_EventQual_MexicoFSL_May2026 @Parameters= @param, @IsDevQA = 0, @Error = @e OUTPUT, @ErrorMessage = @em OUTPUT 
			
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

	WORK TABLES (WRK):


	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2026-01-29			JuanGue			BRD v1 
	1.0.1	2026-02-17			JuanGue			Task #1426924 MX FSL Custom SQL API
	1.2.0	2026-02-25			JuanGue			#1442500 Downlines Qs (Q6-Q9) are not retrieving any contributor
	1.2.1	2026-02-27			JuanGue			#1442692 QS volume should count for ASP (Downlines)
	1.2.2	2026-03-03			JuanGue			Show ASP Qual Dates
	1.2.3	2026-03-13			alejandramed	User Story 1443432: 26019 - Mexico FSL May 2026 - BRD V2
	1.2.3	2026-03-26			alejandramed	Removing SPDemotion codition for New SP contributors as they can be requalifiers.
	1.2.4	2026-04-07			alejandramed	User Story 1450487: 26019 - Mexico FSL May 2026 - BRD V3 
	1.2.5	2026-04-20			alejandramed	Bug 1450764: 26019 MX FSL > Demoted SP should count as contributor
	1.2.6	2026-04-24			alejandramed	User Story 1454506: 26019 - Mexico FSL May 2026 - BRD V4
	***********************************************************************************************************************************/

	DECLARE @ProjectID INT = 26019

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
		@PK_Event_MAIN			INT,
		@PK_Event_VE			INT,
		@PK_Event_PU			INT,
		@PK_Event_MO			INT,
		@PK_Event_CA			INT,
		@PK_Event_AC			INT,
		@EventEndDateMAIN		DATETIME,
		@EventEndDateVE			DATETIME,
		@EventEndDatePU			DATETIME,
		@EventEndDateMO			DATETIME,
		@EventEndDateCA			DATETIME,
		@EventEndDateAC			DATETIME,
		@QualPeriodStartQ5		DATETIME,
		@QualPeriodEndQ5		DATETIME,
		@QualPeriodStartQ10		DATETIME,
		@QualPeriodEndQ10		DATETIME,
		@QualPeriodStartQ11		DATETIME,
		@QualPeriodEndQ11		DATETIME,

		@QualPeriodForDLStart	DATETIME,
		@QualPeriodForDLEnd		DATETIME,
		@DLCountries			NVARCHAR(MAX),
		@QSVolume				BIT,

		@SPqualDateStartA		DATETIME,
		@SPqualDateEndA			DATETIME,
		@QSActualQualDateStart	DATETIME,
		@QSActualQualDateEnd	DATETIME,

		@ASPQualPeriodStart		DATETIME,
		@ASPQualPeriodEnd		DATETIME,

		@Step					INT,
		@Countries				VARCHAR(MAX),
		@ListsValues			NVARCHAR(MAX),
		@CurrentDatetime		DATETIME

	-- Getting parameters values for json

	SELECT   
		@PK_Event_MAIN		=	g.pK_Event_MAIN,	
		@PK_Event_VE		=	g.pK_Event_VE,		
		@PK_Event_PU		=	g.pK_Event_PU,		
		@PK_Event_MO		=	g.pK_Event_MO,		
		@PK_Event_CA		=	g.pK_Event_CA,		
		@PK_Event_AC		=	g.pK_Event_AC,		
		@EventEndDateMAIN	=	g.eventEndDateMAIN,	
		@EventEndDateVE		=	g.eventEndDateVE,		
		@EventEndDatePU		=	g.eventEndDatePU,		
		@EventEndDateMO		=	g.eventEndDateMO,		
		@EventEndDateCA		=	g.eventEndDateCA,		
		@EventEndDateAC		=	g.eventEndDateAC,												
		@QualPeriodStartQ5	=	g.qualPeriodStartQ5,	
		@QualPeriodEndQ5	=	g.qualPeriodEndQ5,	
		@QualPeriodStartQ10	=	g.qualPeriodStartQ10,	
		@QualPeriodEndQ10	=	g.qualPeriodEndQ10,	
		@QualPeriodStartQ11	=	g.qualPeriodStartQ11,	
		@QualPeriodEndQ11	=	g.qualPeriodEndQ11,	
		@QualPeriodForDLStart	=	g.qualPeriodForDLStart,	
		@QualPeriodForDLEnd		=	g.qualPeriodForDLEnd,	
		@DLCountries		=	g.dLCountries,
		@QSVolume			=	g.qSVolume,

		@SPqualDateStartA	=	g.sPqualDateStartA,	
		@SPqualDateEndA		=	g.sPqualDateEndA,	
		@QSActualQualDateStart	=	g.qSActualQualDateStart,
		@QSActualQualDateEnd	=	g.qSActualQualDateEnd,
		@ASPQualPeriodStart	=	g.aSPQualPeriodStart,	
		@ASPQualPeriodEnd	=	g.aSPQualPeriodEnd,	
		@Countries			=	g.countries,
		@ListsValues		=	g.listsValues,
		@CurrentDatetime	=	g.currentDatetime

	FROM OPENJSON(@Parameters)
	WITH ( 
			pK_Event_MAIN			INT				'$.pK_Event_MAIN',	
			pK_Event_VE				INT				'$.pK_Event_VE',		
			pK_Event_PU				INT				'$.pK_Event_PU',		
			pK_Event_MO				INT				'$.pK_Event_MO',		
			pK_Event_CA				INT				'$.pK_Event_CA',		
			pK_Event_AC				INT				'$.pK_Event_AC',		
			eventEndDateMAIN		DATETIME		'$.eventEndDateMAIN',	
			eventEndDateVE			DATETIME		'$.eventEndDateVE',	
			eventEndDatePU			DATETIME		'$.eventEndDatePU',	
			eventEndDateMO			DATETIME		'$.eventEndDateMO',	
			eventEndDateCA			DATETIME		'$.eventEndDateCA',	
			eventEndDateAC			DATETIME		'$.eventEndDateAC',	
			qualPeriodStartQ5		DATETIME		'$.qualPeriodStartQ5',
			qualPeriodEndQ5			DATETIME		'$.qualPeriodEndQ5',	
			qualPeriodStartQ10		DATETIME		'$.qualPeriodStartQ10',
			qualPeriodEndQ10		DATETIME		'$.qualPeriodEndQ10',	
			qualPeriodStartQ11		DATETIME		'$.qualPeriodStartQ11',
			qualPeriodEndQ11		DATETIME		'$.qualPeriodEndQ11',	

			qualPeriodForDLStart	DATETIME		'$.qualPeriodForDLStart',	
			qualPeriodForDLEnd		DATETIME		'$.qualPeriodForDLEnd',
			dLCountries				NVARCHAR(MAX)	'$.dLCountries',
			qSVolume				BIT				'$.qSVolume',

			sPqualDateStartA		DATETIME		'$.sPqualDateStartA',	
			sPqualDateEndA			DATETIME		'$.sPqualDateEndA',	
			qSActualQualDateStart	DATETIME		'$.qSActualQualDateStart',	
			qSActualQualDateEnd		DATETIME		'$.qSActualQualDateEnd',	

			aSPQualPeriodStart		DATETIME		'$.aSPQualPeriodStart',
			aSPQualPeriodEnd		DATETIME		'$.aSPQualPeriodEnd',

			countries				VARCHAR(MAX)	'$.countries',
			listsValues				NVARCHAR(MAX)	'$.listsValues',
			currentDatetime			DATETIME		'$.currentDatetime'
		) AS g
	 
	-- Default values
	SET @PK_Event_MAIN		=	IIF(@PK_Event_MAIN IS NULL,204657,@PK_Event_MAIN)
	SET @PK_Event_VE		=	IIF(@PK_Event_VE IS NULL,205329,@PK_Event_VE)
	SET @PK_Event_PU		=	IIF(@PK_Event_PU IS NULL,205330,@PK_Event_PU)
	SET @PK_Event_MO		=	IIF(@PK_Event_MO IS NULL,205331,@PK_Event_MO)
	SET @PK_Event_CA		=	IIF(@PK_Event_CA IS NULL,205332,@PK_Event_CA)
	SET @PK_Event_AC		=	IIF(@PK_Event_AC IS NULL,205333,@PK_Event_AC)
	SET @EventEndDateMAIN	=	IIF(@EventEndDateMAIN IS NULL,'2026-05-30',@EventEndDateMAIN)
	SET @EventEndDateVE		=	IIF(@EventEndDateVE IS NULL,'2026-05-30',@EventEndDateVE)
	SET @EventEndDatePU		=	IIF(@EventEndDatePU IS NULL,'2026-05-30',@EventEndDatePU)
	SET @EventEndDateMO		=	IIF(@EventEndDateMO IS NULL,'2026-05-30',@EventEndDateMO)
	SET @EventEndDateCA		=	IIF(@EventEndDateCA IS NULL,'2026-05-30',@EventEndDateCA)
	SET @EventEndDateAC		=	IIF(@EventEndDateAC IS NULL,'2026-05-30',@EventEndDateAC)
	SET @QualPeriodStartQ5	=	IIF(@QualPeriodStartQ5 IS NULL,'2026-01-01',@QualPeriodStartQ5)
	SET @QualPeriodEndQ5	=	IIF(@QualPeriodEndQ5 IS NULL,'2026-04-01',@QualPeriodEndQ5)
	SET @QualPeriodStartQ10	=	IIF(@QualPeriodStartQ10 IS NULL,'2026-01-01',@QualPeriodStartQ10)
	SET @QualPeriodEndQ10	=	IIF(@QualPeriodEndQ10 IS NULL,'2026-04-01',@QualPeriodEndQ10)
	SET @QualPeriodStartQ11	=	IIF(@QualPeriodStartQ11 IS NULL,'2026-01-01',@QualPeriodStartQ11)
	SET @QualPeriodEndQ11	=	IIF(@QualPeriodEndQ11 IS NULL,'2026-04-01',@QualPeriodEndQ11)

	SET @QualPeriodForDLStart	=	IIF(@QualPeriodForDLStart IS NULL,'2026-01-01',@QualPeriodForDLStart)
	SET @QualPeriodForDLEnd		=	IIF(@QualPeriodForDLEnd IS NULL,'2026-04-01',@QualPeriodForDLEnd)
	SET @DLCountries		=	IIF(@DLCountries IS NULL,'MX',@DLCountries)
	
	SET	@QSVolume			=	IIF(@QSVolume IS NULL,1,@QSVolume)

	SET @SPqualDateStartA	=	IIF(@SPqualDateStartA IS NULL,'2026-01-01',@SPqualDateStartA)
	SET @SPqualDateEndA		=	IIF(@SPqualDateEndA IS NULL,'2026-05-01',@SPqualDateEndA)
	SET @QSActualQualDateStart	=	IIF(@QSActualQualDateStart IS NULL,'2026-05-01',@QSActualQualDateStart)
	SET @QSActualQualDateEnd	=	IIF(@QSActualQualDateEnd IS NULL,'2026-05-31',@QSActualQualDateEnd)

	SET @ASPQualPeriodStart	=	IIF(@ASPQualPeriodStart IS NULL,'2026-01-01',@ASPQualPeriodStart)
	SET @ASPQualPeriodEnd	=	IIF(@ASPQualPeriodEnd IS NULL,'2026-04-01',@ASPQualPeriodEnd)

	SET @Step				=	IIF(@Step	IS NULL,11,@Step)
	SET @Countries			=	IIF(@Countries IS NULL,'MX',@Countries)
	SET @ListsValues		=	IIF(@ListsValues IS NULL, N'[
									{ "pK_Event":204657, "listID":65928, "qId":12 },
									{ "pK_Event":204657, "listID":67007, "qId":13 },
									{ "pK_Event":204657, "listID":67008, "qId":14 },
									{ "pK_Event":204657, "listID":67009, "qId":15 },
									{ "pK_Event":204657, "listID":67010, "qId":16 },
									{ "pK_Event":204657, "listID":67011, "qId":17 },
									{ "pK_Event":204657, "listID":67012, "qId":18 },
									{ "pK_Event":204657, "listID":67013, "qId":19 },
									{ "pK_Event":204657, "listID":68185, "qId":20 }
								]', @ListsValues)
	SET @CurrentDatetime	=	IIF(@CurrentDatetime IS NULL,GETDATE(), @CurrentDatetime)

	SELECT   
		@PK_Event_MAIN		AS	[PK_Event_MAIN]			,	
		@PK_Event_VE		AS	[PK_Event_VE]			,		
		@PK_Event_PU		AS	[PK_Event_PU]			,		
		@PK_Event_MO		AS	[PK_Event_MO]			,		
		@PK_Event_CA		AS	[PK_Event_CA]			,		
		@PK_Event_AC		AS	[PK_Event_AC]			,		
		@EventEndDateMAIN	AS	[EventEndDateMAIN]		,	
		@EventEndDateVE		AS	[EventEndDateVE]		,		
		@EventEndDatePU		AS	[EventEndDatePU]		,		
		@EventEndDateMO		AS	[EventEndDateMO]		,		
		@EventEndDateCA		AS	[EventEndDateCA]		,		
		@EventEndDateAC		AS	[EventEndDateAC]		,												
		@QualPeriodStartQ5	AS	[QualPeriodStartQ5]		,	
		@QualPeriodEndQ5	AS	[QualPeriodEndQ5]		,	
		@QualPeriodStartQ10	AS	[QualPeriodStartQ10]	,	
		@QualPeriodEndQ10	AS	[QualPeriodEndQ10]		,	
		@QualPeriodStartQ11	AS	[QualPeriodStartQ11]	,	
		@QualPeriodEndQ11	AS	[QualPeriodEndQ11]		,	
		
		@QualPeriodForDLStart	AS	[QualPeriodForDLStart],
		@QualPeriodForDLEnd		AS	[QualPeriodForDLEnd],
		@DLCountries		AS	[DLCountries],
		@QSVolume			AS	[QSVolume],

		@SPqualDateStartA	AS	[SPqualDateStartA]		,	
		@SPqualDateEndA		AS	[SPqualDateEndA]		,	
		@QSActualQualDateStart	AS	[QSActualQualDateStart]		,	
		@QSActualQualDateEnd	AS	[QSActualQualDateEnd]		,	


		@ASPQualPeriodStart	AS	[ASPQualPeriodStart],
		@ASPQualPeriodEnd	AS	[ASPQualPeriodEnd],
	
		@Countries			AS	[Countries]				,
		@ListsValues		AS	[ListsValues]			,
		@CurrentDatetime	AS	[CurrentDatetime]	

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

		DROP TABLE IF EXISTS #Locations

		CREATE TABLE #Locations
		(			
			[PK_Event] [int],
			[Location] [varchar](200),
			[CountryCode]	varchar(200), 
			[PK_Country] [int],
			[Main] [bit] DEFAULT(0),
			[ctrl] [bit] DEFAULT(0)
		)

		INSERT INTO #Locations([PK_Event],[Location], [CountryCode], [Main])
		SELECT 	@PK_Event_MAIN AS [PK_Event],'MAIN' AS [Location],'MX' AS [CountryCode],1
		UNION
		SELECT 	@PK_Event_VE AS [PK_Event],'VERACRUZ' AS [Location],'MX' AS [CountryCode],0
		UNION
		SELECT 	@PK_Event_PU AS [PK_Event],'PUERTO VALLARTA' AS [Location],'MX' AS [CountryCode],0
		UNION
		SELECT 	@PK_Event_MO AS [PK_Event],'MONTERREY' AS [Location],'MX' AS [CountryCode],0
		UNION
		SELECT 	@PK_Event_CA AS [PK_Event],'CANCUN' AS [Location],'MX' AS [CountryCode],0
		UNION
		SELECT 	@PK_Event_AC AS [PK_Event],'ACAPULCO' AS [Location],'MX' AS [CountryCode],0

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
			--Q5	 Achieve 2,500 TVP in each month in four (4) months (January 2026 - April 2026)
			SELECT 
			@PK_Event_MAIN AS PK_Event,
			5 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodStartQ5 AS [dStartDate], 
			@QualPeriodEndQ5 AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			@QSVolume AS [QSVolume],
			0 AS [Bonus]

			UNION
			--Q10 Achieve 3,500 TVP in each month in 4 months (January 2026 - April 2026)
			SELECT 
			@PK_Event_MAIN AS PK_Event,
			10 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodStartQ10 AS [dStartDate], 
			@QualPeriodEndQ10 AS [dEndDate], 
			4 AS [Frequency], 
			0 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			3500 AS [GoalPoints], 
			NULL AS [Countries],
			@QSVolume AS [QSVolume],
			0 AS [Bonus]
			UNION
			--Q11	Achieve 5,000 TVP in each month in 4 months (January 2026 - April 2026)
			SELECT 
			@PK_Event_MAIN AS PK_Event,
			11 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@QualPeriodStartQ11 AS [dStartDate], 
			@QualPeriodEndQ11 AS [dEndDate], 
			4 AS [Frequency], 
			1 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			5000 AS [GoalPoints], 
			NULL AS [Countries],
			@QSVolume AS [QSVolume],
			0 AS [Bonus]

			UNION
			--Q30	Achieve 2500 VPs in each month in 3 consecutive months
			SELECT 
			@PK_Event_MAIN AS PK_Event,
			30 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			@ASPQualPeriodStart AS [dStartDate], 
			DATEADD(month,-1, @ASPQualPeriodEnd) AS [dEndDate], 
			3 AS [Frequency], 
			1 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			@QSVolume AS [QSVolume],
			0 AS [Bonus]

			UNION
			--Q31	Achieve 2500 VPs in each month in 3 consecutive months
			SELECT 
			@PK_Event_MAIN AS PK_Event,
			31 AS QualificationNumber,
			1 AS Part, 
			'TV' AS [MetricType], 
			DATEADD(month,1, @ASPQualPeriodStart) AS [dStartDate], 
			@ASPQualPeriodEnd AS [dEndDate], 
			3 AS [Frequency], 
			1 AS [Consecutive], 
			0 AS [Accumulated], 
			0 AS [MinPoints], 
			2500 AS [GoalPoints], 
			NULL AS [Countries],
			@QSVolume AS [QSVolume],
			0 AS [Bonus]
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

	--Quals block
	BEGIN 
		
		IF (@IsDevQA = 2)
		BEGIN
			PRINT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1 
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
					QSActualQualDate    smalldatetime DEFAULT('1900-01-01'),
					DSCurrentTeam		varchar(10),        
					DSSubTeam			varchar(10),        
					DSSPTeam			varchar(10),               
					dSPQualDate			datetime2,    
					dSPDemotion			datetime2,  
					dSPReQualDate		datetime2,
					NewSPQualDate		datetime DEFAULT('1900-01-01'),
					CountryCode			varchar(5),
					IsFromList			bit default(0),
					IsTicketPurchaser	bit default(0),
					IsFromCOP			bit default(0),
					TVPJan26	        money default 0,
					TVPFeb26	        money default 0,
					TVPMar26	        money default 0,
					TVPApr26	        money default 0,
					TotalTVP			AS (TVPJan26 + TVPFeb26 + TVPMar26 + TVPApr26),
					ASPContributors		smallint default(0),
					SPContributors		smallint default(0)
				)

				INSERT INTO #DS
				(
					PK_Distributor,
					DistributorID,
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,
					dSPDemotion,
					dSPReQualDate,
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
				D.dSupervisorqualification AS dSPQualDate, 
				D.dSPDemotion AS dSPDemotion,
				D.dSupervisorReQualification AS dSPReQualDate,
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
					PK_Distributor,	
					DistributorID,
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,		
					dSPRequalDate,
					CountryCode,		
					IsFromList,
					QSActualQualDate
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,  
				D.sDistributorID AS DistributorID,
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate, 
				d.dSupervisorReQualification AS dSPRequalDate,
				D.sDistributorCountryProcessingCode AS CountryCode,
				1 AS IsFromList,
				D.dQSQualification_Actual
				FROM dbo.v_Distributor AS D  
					INNER JOIN (SELECT DISTINCT PK_Distributor FROM #DSList) AS L
						ON D.nDistributorID = L.PK_Distributor
				WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = L.PK_Distributor)

				UPDATE D
				SET IsFromList = 1
				FROM #DS AS D  
					INNER JOIN (SELECT DISTINCT PK_Distributor FROM #DSList)  AS L
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
				SELECT DISTINCT l.PK_Event, l.PK_Event, s.SKUCode
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
					DistributorID,
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,		
					dSPRequalDate,
					CountryCode,
					IsTicketPurchaser,
					QSActualQualDate
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor, 
				D.sDistributorID AS DistributorID,
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate,   
				d.dSupervisorReQualification AS dSPRequalDate,
				D.sDistributorCountryProcessingCode AS CountryCode,
				1 AS IsTicketPurchaser,
				D.dQSQualification_Actual
				FROM dbo.v_Distributor AS D  
					INNER JOIN (SELECT DISTINCT PK_Distributor FROM #DSSKUs) AS S
						ON D.nDistributorID = S.PK_Distributor
				WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = S.PK_Distributor)

				UPDATE D
				SET IsTicketPurchaser = 1
				FROM #DS AS D  
					INNER JOIN (SELECT DISTINCT PK_Distributor FROM #DSSKUs) AS S
						ON D.PK_Distributor = S.PK_Distributor

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 2;

			--Have Sponsored FQS (DS level)

			INSERT INTO #TimeLog VALUES ('#DSDownlines', 2, 3, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #DSDownlines

			SELECT 
				M.PK_Distributor PK_UL,
				DL.PK_DSDownline [PK_DL],
				DATEADD(month, DATEDIFF(month, 0, D.dSupervisorqualification), 0) AS [DL_SPQualDate],
				DATEADD(month, DATEDIFF(month, 0, D.dSupervisorReQualification), 0) AS [DL_SPRequalDate],
				D.sDistributorCountryProcessingCode DL_CountryCode,
				D.dSPDemotion
			INTO #DSDownlines
			FROM
				#DS M
			INNER JOIN
				dbo.v_dimDSLngDownline DL WITH (NOLOCK)
			ON
				M.PK_Distributor = DL.PK_Distributor
				AND 
				DL.DSLevelFromUL = 2
			INNER JOIN v_Distributor AS D
				ON DL.PK_DSDownline = D.nDistributorID 
				AND 
				D.StatusCode = 'COMPLETE'
				AND D.sDistributorCountryProcessingCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar](@DLCountries, ',')) --DL DS with COP must be only for MX

			CREATE CLUSTERED INDEX [IX_#DSDownlines_PK_DL] ON  dbo.[#DSDownlines] ([PK_DL])

			DROP TABLE IF EXISTS #DSAssociatedDownlines

			SELECT DISTINCT
					DA.PK_Distributor PK_UL,
					DA.PK_AssociatedID,
					DL.PK_DSDownline PK_DL,
					DATEADD(month, DATEDIFF(month, 0, DD.dSupervisorqualification), 0) AS [DL_SPQualDate],
					DATEADD(month, DATEDIFF(month, 0, DD.dSupervisorReQualification), 0) AS [DL_SPRequalDate],
					DD.sDistributorCountryProcessingCode DL_CountryCode,
					DD.dSPDemotion,
					DA.nMainDistributorID,
					DA.AssociationType
			INTO #DSAssociatedDownlines
			FROM #DS AS D --Uplines from COP
			INNER JOIN [Shared].[DistributorAssociation] AS DA WITH (NOLOCK)
				ON D.PK_Distributor = DA.PK_Distributor
			INNER JOIN dbo.v_dimDSLngDownline AS DL
				ON DA.PK_AssociatedID = DL.PK_Distributor
			INNER JOIN v_Distributor AS DD
				ON DL.PK_DSDownline = DD.nDistributorID 
			AND 
				DD.StatusCode = 'COMPLETE'
			WHERE DL.DSLevelFromUL = 2
			AND DA.PK_AssociatedID = DA.nMainDistributorID -- When the Individual Distributorship achieves additional contributor, only the Indiviudal Distributorship will gain the new contributor																	
																								/*	When the Original Distributorship achieves for additional contributor, 
																								the Individual Distributorship will also benefit from contributor recruited by the Original Distributorship after 
																								completion of the divorce on system	*/
			AND DD.sDistributorCountryProcessingCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar](@DLCountries, ',')) --DL DS with COP must be only for MX

			CREATE CLUSTERED INDEX [IX_#DSAssociatedDownlines_PK_UL] ON  dbo.[#DSAssociatedDownlines] ([PK_UL])


			IF OBJECT_ID('dbo.WRK_26019_1LDownlines', 'U') IS NULL
			BEGIN			

				CREATE TABLE dbo.[WRK_26019_1LDownlines]
				(
					PK_UL				INT,   
					[PK_DL]				INT,
					[DL_SPQualDate]		DATETIME,
					[DL_SPRequalDate]	DATETIME,
					DL_CountryCode		VARCHAR(MAX),
					[DL_SPDemotion]		DATETIME NULL,
					PK_AssociatedID		INT,
					nMainDistributorID	INT,
					AssociationType		INT,
					DL_Achieved3CM		BIT DEFAULT 0,
					[DL_ASPContributionDate]	DATETIME NULL,
					IsASPContributor	BIT DEFAULT 0,
					IsSPContributor		BIT DEFAULT 0,
					DL_FreezeSPQualDate DATETIME,
					[IsMainID] BIT DEFAULT 0,
				)
			END

			DROP TABLE IF EXISTS #WRK_26019_1LDownlines

			
			CREATE TABLE #WRK_26019_1LDownlines
			(
				PK_UL				INT,   
				[PK_DL]				INT,
				[DL_SPQualDate]		DATETIME,
				[DL_SPRequalDate]	DATETIME,
				DL_CountryCode		VARCHAR(MAX),
				[DL_SPDemotion]		DATETIME NULL,
				PK_AssociatedID		INT,
				nMainDistributorID	INT,
				AssociationType		INT,
				DL_Achieved3CM		BIT DEFAULT 0,
				[DL_ASPContributionDate]	DATETIME NULL,
				IsASPContributor	BIT DEFAULT 0,
				IsSPContributor		BIT DEFAULT 0,
				DL_FreezeSPQualDate DATETIME,
				[IsMainID] BIT DEFAULT 0,
			)

			INSERT INTO #WRK_26019_1LDownlines(PK_UL,[PK_DL],[DL_SPQualDate],[DL_SPRequalDate],DL_CountryCode,[DL_SPDemotion])
			SELECT DISTINCT
				D.PK_UL,
				D.[PK_DL],
				D.[DL_SPQualDate],
				D.[DL_SPRequalDate],
				D.DL_CountryCode,
				D.[dSPDemotion]
			FROM #DSDownlines AS D			
						
			INSERT INTO #WRK_26019_1LDownlines(PK_UL,[PK_DL],[DL_SPQualDate],[DL_SPRequalDate],DL_CountryCode,[DL_SPDemotion],PK_AssociatedID,nMainDistributorID,AssociationType)
				SELECT DISTINCT
					A.PK_UL,
					A.PK_DL,
					A.[DL_SPQualDate],
					A.[DL_SPRequalDate],
					A.DL_CountryCode,
					A.[dSPDemotion],
					PK_AssociatedID,
					nMainDistributorID,
					AssociationType
				FROM #DSAssociatedDownlines AS A
			WHERE NOT EXISTS (SELECT 1 FROM dbo.[WRK_26019_1LDownlines] (NOLOCK) AS S WHERE A.PK_UL = S.PK_UL AND A.PK_DL = S.[PK_DL])

			CREATE CLUSTERED INDEX [IX_#WRK_26019_1LDownlines_PK_UL] ON  #WRK_26019_1LDownlines ([PK_UL])

			UPDATE D
			SET DL_FreezeSPQualDate =  IIF(D.[DL_SPQualDate] BETWEEN @SPqualDateStartA AND  @SPqualDateEndA,D.[DL_SPQualDate],NULL)
			FROM #WRK_26019_1LDownlines AS D 		


			MERGE dbo.[WRK_26019_1LDownlines] AS T
			USING #WRK_26019_1LDownlines AS S
			ON T.PK_UL = S.PK_UL AND T.[PK_DL] = S.[PK_DL]
			-- For Inserts
			WHEN NOT MATCHED BY Target THEN
				INSERT (PK_UL,[PK_DL],[DL_SPQualDate],[DL_SPRequalDate],DL_CountryCode,[DL_SPDemotion],PK_AssociatedID,nMainDistributorID,AssociationType,DL_FreezeSPQualDate)
				VALUES (S.PK_UL,[PK_DL],S.[DL_SPQualDate],S.[DL_SPRequalDate],S.DL_CountryCode,S.[DL_SPDemotion],S.PK_AssociatedID,S.nMainDistributorID,S.AssociationType,S.DL_FreezeSPQualDate)    
			-- For Updates
			WHEN MATCHED THEN UPDATE SET 
					T.PK_UL = S.PK_UL, 
					T.PK_DL = S.PK_DL,
					T.[DL_SPQualDate] = S.[DL_SPQualDate],
					T.[DL_SPRequalDate] = S.[DL_SPRequalDate],
					T.DL_CountryCode = S.DL_CountryCode,
					T.[DL_SPDemotion] = S.[DL_SPDemotion],
					T.PK_AssociatedID = S.PK_AssociatedID,
					T.nMainDistributorID = S.nMainDistributorID,
					T.AssociationType = S.AssociationType, 
					T.DL_FreezeSPQualDate = IIF(T.DL_FreezeSPQualDate IS NOT NULL, T.DL_FreezeSPQualDate,S.DL_FreezeSPQualDate),
					T.DL_Achieved3CM = 0 -- Always evaluating the volume qualification
			-- For Deletes
			WHEN NOT MATCHED BY Source THEN
				DELETE;

			--Dynamic table
			MERGE dbo.[WRK_26019_1LDownlines] AS T
			USING (
					SELECT 
						du.nDistributorID AS PK_UL,
						dd.nDistributorID AS PK_DL,
						dl.DL_FreezeSPQualDate
					FROM [dynamic].WRK_26019_1LDownlines AS dl
						INNER JOIN v_Distributor AS du
							ON dl.UL_DistributorID = du.sDistributorID 
						INNER JOIN v_Distributor AS dd
							ON dl.DL_DistributorID = dd.sDistributorID 
			) AS S
			ON T.PK_UL = S.PK_UL AND T.[PK_DL] = S.[PK_DL]	 
			 -- For Updates
			WHEN MATCHED THEN UPDATE SET 
				T.DL_FreezeSPQualDate = S.DL_FreezeSPQualDate
			;

			UPDATE D
				SET [IsMainID] = 1			
			FROM dbo.[WRK_26019_1LDownlines] AS D WITH (NOLOCK)
				INNER JOIN [Shared].[DistributorAssociation] AS DA WITH (NOLOCK)
					ON D.PK_DL = DA.nMainDistributorID

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
						[dSPQualDate] [datetime] NULL,
						[PK_DSType] [int] NULL
					)

					INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate])
					SELECT 
						@PK_Event_MAIN AS [PK_Event],
						D.PK_Distributor AS PK_Distributor,
						D.DistributorID AS DistributorID,
						@iStartDate AS [iStartDate],
						@iEndDate AS [iEndDate],
						@dStartDate AS [dStartDate],
						@dEndDate AS [dEndDate],
						D.dSPQualDate 
					FROM #DS AS D

					UNION

					SELECT DISTINCT
						@PK_Event_MAIN AS [PK_Event],
						W.PK_DL AS PK_Distributor,
						V.sDistributorID AS DistributorID,
						@iStartDate AS [iStartDate],
						@iEndDate AS [iEndDate],
						@dStartDate AS [dStartDate],
						@dEndDate AS [dEndDate],
						W.DL_SPQualDate 
					FROM dbo.[WRK_26019_1LDownlines] AS W
					INNER JOIN v_Distributor AS V
						ON W.PK_DL = V.nDistributorID

					CREATE INDEX IX_#tmp_DS_PK_Distributor ON #tmp_DS(PK_Distributor);	

					IF (@IsDevQA = 0)
					BEGIN
						
						DROP INDEX IF EXISTS [IX_DS_PK_Distributor]
							ON [tmp].[DS];

						DELETE d FROM [tmp].[DS] AS d WHERE d.PK_Event = @PK_Event_MAIN  

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

						DELETE d FROM ##tmp_DS_jgue AS d WHERE d.PK_Event = @PK_Event_MAIN  

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

					--	SourceType 3: Getting points from [PubEventManagement].[dbo].[v_aggFQS_ID] 8.3 WW
					EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event_MAIN, @SourceType = 3,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
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

					EXEC [dbo].[##usp_GetDSVolume_jgue] @PK_Event = @PK_Event_MAIN, @SourceType = 3,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
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
					WHERE PK_Event = @PK_Event_MAIN

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
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 5;		
		
			INSERT INTO #TimeLog VALUES ('Update TVP Points monthly on #DS', 3, 6, GETUTCDATE(), NULL);

			/***************************************************  
				  Update TVP Points monthly on #DS
			****************************************************/

			;WITH P AS (
				SELECT
					E.PK_Distributor,
					TVPJan26 = MAX(CASE WHEN E.RoyaltyMonth = 202601 AND E.MetricType = 'TV' THEN E.Points END),
					TVPFeb26 = MAX(CASE WHEN E.RoyaltyMonth = 202602 AND E.MetricType = 'TV' THEN E.Points END),
					TVPMar26 = MAX(CASE WHEN E.RoyaltyMonth = 202603 AND E.MetricType = 'TV' THEN E.Points END),
					TVPApr26 = MAX(CASE WHEN E.RoyaltyMonth = 202604 AND E.MetricType = 'TV' THEN E.Points END)
				FROM #Event_DSPoints AS E
				WHERE E.MetricType = 'TV'
				  AND E.RoyaltyMonth IN (202601, 202602, 202603, 202604)
				GROUP BY E.PK_Distributor
			)
			UPDATE T
			SET
				T.TVPJan26 = ISNULL(P.TVPJan26, 0),
				T.TVPFeb26 = ISNULL(P.TVPFeb26, 0),
				T.TVPMar26 = ISNULL(P.TVPMar26, 0),
				T.TVPApr26 = ISNULL(P.TVPApr26, 0)
			FROM #DS AS T
			LEFT JOIN P
				ON P.PK_Distributor = T.PK_Distributor;

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 6;

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

					INSERT INTO #tmp_DSQualDef([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[QSVolume])
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
						C.[QSVolume]
					FROM #DS AS D					
					LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
						ON D.PK_Distributor = M.PK_Distributor
					OUTER APPLY (SELECT [PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,
										Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume]
									FROM #Event_SetupEventQualification WITH (NOLOCK)
									WHERE QualificationNumber < 20 ) AS C
					CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
		
					UNION 

					SELECT DISTINCT
						C.PK_Event,
						D.PK_DL AS PK_Distributor,
						A.StartDate AS dStartDate,
						A.EndDate AS dEndDate,
						CAST(CONVERT(varchar(6), A.StartDate, 112) AS int) AS iStartDate,
						CAST(CONVERT(varchar(6), A.EndDate, 112) AS int) AS iEndDate,
						D.DL_SPQualDate AS [dSPQualDate],
						CAST(CONVERT(varchar(6), D.DL_SPQualDate, 112) AS int) AS [iSPQualDate],
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
						C.[QSVolume]
					FROM dbo.[WRK_26019_1LDownlines] AS D					
					LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
						ON D.PK_DL = M.PK_Distributor
					OUTER APPLY (SELECT [PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,
										Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume]
									FROM #Event_SetupEventQualification WITH (NOLOCK)
									WHERE QualificationNumber >= 30 ) AS C
					CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A

					CREATE INDEX IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef(PK_Distributor);


				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 4 AND [StepSubGroup] = 1;

				IF @IsDevQA = 0
				BEGIN

					INSERT INTO #TimeLog VALUES ('[tmp].[DSQualDef]', 4, 2, GETUTCDATE(), NULL);
					
					DROP INDEX IF EXISTS IX_tmp_DSQualDef_PK_Event ON [tmp].[DSQualDef];

					DELETE [tmp].[DSQualDef] WHERE PK_Event = @PK_Event_MAIN

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
		
		--Step 5: Getting DSPointsSummary		
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
				INNER JOIN #tmp_DSQualDef AS F
					ON u.PK_Distributor = F.PK_Distributor	
					WHERE 
					F.MetricType = U.MetricType 
					AND 
					U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
					AND 
				(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
				GROUP BY U.PK_Distributor,U.RoyaltyMonth,U.MetricType,F.[QSVolume],F.[QSVolumePercentage],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries
					
			 
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
					@PK_Event_MAIN AS PK_Event,
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
					INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary]', 5, 51, GETUTCDATE(), NULL);
					
					DELETE t
					FROM [tmp].[DSPointsSummary] AS t
					WHERE t.PK_Event = @PK_Event_MAIN

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
					FROM [Event].[DSQualPoints] AS Q WITH (NOLOCK) WHERE PK_Event = @PK_Event_MAIN
				END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 6 AND [StepSubGroup] = 1;
		END

		--Step 7: Qualifications

		IF @Step >= 7
		BEGIN
			
			PRINT 'Executing step 7'

			INSERT INTO #TimeLog VALUES ('#EventQual', 7, 1, GETUTCDATE(), NULL);

			INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q03,Q04,Q45,Q47,Q50)
				SELECT 
					d.PK_Distributor,
					@PK_Event_MAIN AS [PK_Event],
					IIF(d.QSActualQualDate BETWEEN @QSActualQualDateStart AND @QSActualQualDateEnd,1,0)		AS Q01, -- DS with QS status on May 2026 (The whole month) Include: QS, QS5, QV, PQS, SQS, 2QS, 5QS SubTypeCodes
					IIF(d.DSSPTeam = 'SP',1,0)																AS Q02, -- FQS and above
					IIF(D.DSSubTeam IN ('SP','WT'),1,0)														AS Q03, -- Non TAB Team Members
					IIF(D.DSCurrentTeam IN ('G','M','P','A','B','C'),	1,0)								AS Q04, -- TAB Team Members
					d.IsFromCOP																				AS Q45,  -- From COP
					d.IsTicketPurchaser																		AS Q47,  -- Ticket purchaser
					IIF(d.DSSubTeam IN ('DS','QS5','QV','PQS','SQS','2QS','5QS'),1,0)						AS Q50  -- Include: QS, QS5, QV, PQS, SQS, 2QS, 5QS SubTypeCodes
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID )
				
				/* Update divorce case where 2 IDs (One is Main Active and second is associate active) only the associate can qualify for the Mexico events.   
					Main ID should not appear as qualified or under any exception list as qualified.  
					Applicable to all Mexico events and promotions. 
				*/

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

					PRINT 'Downlines qualifications'	

					UPDATE D
					SET DL_Achieved3CM = 1
					FROM dbo.[WRK_26019_1LDownlines] D
					WHERE 
						EXISTS (SELECT 1 FROM #Event_DSQualPoints QVQ WHERE QVQ.PK_Event = @PK_Event_MAIN AND QVQ.PK_Distributor = D.PK_DL AND QualificationNumber IN (30,31))	

					UPDATE D
					SET IsASPContributor = IIF(D.DL_Achieved3CM = 1,1,0) --Achieve 2500 VPs in each month in 3 consecutive months.										
					FROM dbo.[WRK_26019_1LDownlines] D (NOLOCK)
	 
	 				-- ASP Contribution Date
	 				UPDATE D
					SET [DL_ASPContributionDate] = '2026-04-01' 
					FROM dbo.[WRK_26019_1LDownlines] D (NOLOCK)
					INNER JOIN #Event_DSQualPoints QVQ 
						ON QVQ.PK_Event = @PK_Event_MAIN AND QVQ.PK_Distributor = D.PK_DL AND QualificationNumber = 30

	 				UPDATE D
					SET [DL_ASPContributionDate] = '2026-05-01' 
					FROM dbo.[WRK_26019_1LDownlines] D (NOLOCK)
					INNER JOIN #Event_DSQualPoints QVQ 
						ON QVQ.PK_Event = @PK_Event_MAIN AND QVQ.PK_Distributor = D.PK_DL AND QualificationNumber = 31

	 				UPDATE D
					SET IsSPContributor = IIF((D.[DL_FreezeSPQualDate] BETWEEN @SPqualDateStartA AND @SPqualDateEndA),1,0) --Supervisors with SP Qual Dates Jan 1st to May 1st.						 
					FROM dbo.[WRK_26019_1LDownlines] D (NOLOCK)

					DROP TABLE IF EXISTS #ASPContributorsCount

					SELECT PK_UL,COUNT(*) ASPContributors 
					INTO #ASPContributorsCount
					FROM dbo.[WRK_26019_1LDownlines] D (NOLOCK)
					WHERE 
						IsASPContributor = 1 AND [IsMainID] = 0
					GROUP BY
						PK_UL
					
					DROP TABLE IF EXISTS #SPContributorsCount

					SELECT PK_UL,COUNT(*) SPContributors 
					INTO #SPContributorsCount
					FROM dbo.[WRK_26019_1LDownlines] D (NOLOCK)
					WHERE 
						IsSPContributor = 1 AND [IsMainID] = 0
					GROUP BY
						PK_UL

					--Personally Sponsor two (2) Active Supervisors
					UPDATE E
					SET Q06 = 1
					FROM #EventQual E
					INNER JOIN #ASPContributorsCount D (NOLOCK)
					ON E.PK_Event = @PK_Event_MAIN AND E.PK_Distributor = D.PK_UL
					AND D.ASPContributors >= 2

					--Personally Sponsor (1) Active Supervisors 
					UPDATE E
					SET Q07 = 1
					FROM #EventQual E
					INNER JOIN #ASPContributorsCount D (NOLOCK)
					ON E.PK_Event = @PK_Event_MAIN AND E.PK_Distributor = D.PK_UL
					AND D.ASPContributors >= 1

					--Personally Sponsor Two (2) Supervisors with SP Qual Dates Jan 1st to May 1st.
					UPDATE E
					SET Q08 = 1
					FROM #EventQual E
					INNER JOIN #SPContributorsCount D (NOLOCK)
					ON E.PK_Event = @PK_Event_MAIN AND E.PK_Distributor = D.PK_UL
					AND D.SPContributors >= 2

					--Personally Sponsor One (1) Supervisor with SP Qual Dates Jan 1st to May 1st.
					UPDATE E
					SET Q09 = 1
					FROM #EventQual E
					INNER JOIN #SPContributorsCount D (NOLOCK)
					ON E.PK_Event = @PK_Event_MAIN AND E.PK_Distributor = D.PK_UL
					AND D.SPContributors >= 1
					
					-- Set the number of downlines as contributors
					UPDATE D
					SET ASPContributors = ISNULL(C.ASPContributors,0)
					FROM #DS D
					INNER JOIN #ASPContributorsCount C
						ON	D.PK_Distributor = C.PK_UL

					UPDATE D
					SET SPContributors = ISNULL(E.SPContributors,0)
					FROM #DS D
					INNER JOIN #SPContributorsCount E
						ON	D.PK_Distributor = E.PK_UL

				END
			
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 7 AND [StepSubGroup] = 1;

		END

		--Step 8: Qualifying to Subevents
		IF @Step >= 8
		BEGIN

			PRINT 'Executing step 8'

			INSERT INTO #TimeLog VALUES ('Es #EventQual', 8, 1, GETUTCDATE(), NULL);


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
				E01 = (((Q01 | Q50) | Q02) | Q13),
				E03 = (((Q03 & Q07 & Q09 & Q10) | ((Q04 | Q12) & Q06 & Q08 & Q11)) | Q15),
				E04 = (Q16),
				E05 = (Q17),
				E06 = (Q18),
				E07 = (Q19),
				E08 = (Q20)

			UPDATE 
				#EventQual
			SET
					E02 = ((Q02 & Q05 & ~E03) | Q14),
					E40 = (E01)

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 8 AND [StepSubGroup] = 1;

		END

		--Step 10: [Event].[DSQual]	
		IF @Step >= 10
		BEGIN
			
			PRINT 'Executing step 10'

			INSERT INTO #TimeLog VALUES ('[Event].[DSQual]', 10, 1, GETUTCDATE(), NULL);

			IF @IsDevQA = 0
			BEGIN

				DELETE dq			
				FROM [Event].[DSQual] AS dq
					INNER JOIN #Locations AS l
						ON dq.PK_Event = l.PK_Event


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
					L.PK_Event AS PK_Event	
					,q.PK_Distributor	
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
				CROSS APPLY (SELECT PK_Event FROM #Locations) AS L

				CREATE INDEX [IX_Event_DSQual_PK_Event] ON [Event].[DSQual](PK_Event);
				CREATE INDEX [IX_Event_DSQual_PK_Distributor_PK_Event] ON [Event].[DSQual](PK_Distributor) INCLUDE(PK_Event);

				
				DROP INDEX IF EXISTS [IX_WRK_MexicoFSL_May2026_PK_Distributor]
				ON [dbo].[WRK_MexicoFSL_May2026];

				DROP TABLE IF EXISTS dbo.WRK_MexicoFSL_May2026

				SELECT 
					PK_Distributor		
					,DistributorID		
					,QSActualQualDate    
					,DSCurrentTeam		
					,DSSubTeam			
					,DSSPTeam			
					,dSPQualDate			
					,dSPDemotion			
					,dSPReQualDate		
					,NewSPQualDate		
					,CountryCode			
					,IsFromList			
					,IsTicketPurchaser	
					,IsFromCOP			
					,TVPJan26	        
					,TVPFeb26	        
					,TVPMar26	        
					,TVPApr26	        
					,TotalTVP			
					,ASPContributors
					,SPContributors
				INTO dbo.WRK_MexicoFSL_May2026
				FROM #DS 

				CREATE INDEX [IX_WRK_MexicoFSL_May2026_PK_Distributor] ON [dbo].[WRK_MexicoFSL_May2026](PK_Distributor);

			END
			ELSE IF @IsDevQA = 3
			BEGIN

				DROP TABLE IF EXISTS ##Event_DSQual_jgue 
	 
				SELECT
					L.PK_Event AS PK_Event	
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
				CROSS APPLY (SELECT PK_Event FROM #Locations) AS L
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

			IF OBJECT_ID('tempdb..#ListsQsMapping') IS NOT NULL
			BEGIN

				DROP TABLE IF EXISTS [tmp].[ListsQsMapping]
					 
				SELECT @ProjectID AS [ProjectID], QId,ListID
				INTO [tmp].[ListsQsMapping]
				FROM #ListsQsMapping

			END

			IF OBJECT_ID('tempdb..#SKUsQsMapping') IS NOT NULL
			BEGIN

				DROP TABLE IF EXISTS [tmp].[SKUsQsMapping]

				SELECT @ProjectID AS [ProjectID], QId,SKUCode
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