CREATE PROCEDURE [dbo].[usp_EventQual_Malaysia_Vacation_2025]
	@PK_Event int = 201105
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
	,@Step SMALLINT = 10
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_Malaysia_Vacation_2025

	USE:		

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC dbo.usp_EventQual_Malaysia_Vacation_2025
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
	1.0.0		2024-09-05		JuanGue		Initial 
	1.0.1		2024-09-09		JuanGue		BugFix #1361543 
	1.0.2		2024-09-13		JuanGue		BugFix #1361856 #1361932 #1361933
	1.0.3		2024-09-17		JuanGue		Adding WRK_25017_SponsorsPerMonth
	1.0.4		2024-09-18		JuanGue		Bonuses fix
	1.0.5		2024-09-24		JuanGue		TeamJun2024 column added to the WRK table
	1.0.6		2024-09-25		JuanGue		TeamJun2024 modification
	1.0.7		2024-11-27		JuanGue		List 62485 added as Q15
	1.0.8		2024-12-12		JuanGue		Bugfix #1392916 E5 qualifiers with less than 45K accumulated points
	1.0.9		2024-12-17		JuanGue		Bugfix #1392915 E5 qualifiers with Q8 Japan
	1.0.10		2024-12-17		JuanGue		WRK event table total vacation points without ASP bonus
	1.0.11		2024-12-17		JuanGue		Generate WRK tables of every sponsor type
	1.0.12		2024-12-19		JuanGue		Avoiding duplicates in bonus
	1.0.13		2024-12-19		JuanGue		#1399063 Bug ispremierleague
	1.0.14		2024-12-20		JuanGue		Only achieving 1 bonus in ASP bonus
	1.0.15		2025-01-02		JuanGue		#1400321 ASP Bonus Sum
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

	--Quals block
	BEGIN 
		
		--Variables and temp tables 
		BEGIN

		--Variables and temp tables 
		BEGIN

		DECLARE @ProjectID INT = 25017			 

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
			[Bonus]					bit default(0),
			[QSVolume]				bit,
			[QSVolumePercentage]	int,
			[PeriodType]			tinyint, -- 1 Fixed period, 2 Relative period base on SPQualDate
			[MetricTypeDefinition]	VARCHAR(50) NULL
		)
		
		--Q03 Achieve 2,500 TVP in each month for (4) four consecutive months from Jun 2024 to May 2025
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			3					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-06-01'		AS [dStartDate], 
			'2025-05-01'		AS [dEndDate], 
			4					AS [Frequency], 
			1					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			2500				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]
	
		--Q04 Accumulate 45,000 TotalVacationPoints from Jun 2024 to May 2025
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			4					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-06-01'		AS [dStartDate], 
			'2025-05-01'		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			45000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q05 Accumulate 60,000 TotalVacationPoints from Jun 2024 to May 2025
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			5					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-06-01'		AS [dStartDate], 
			'2025-05-01'		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			60000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q06 Accumulate 80,000 TotalVacationPoints from Jun 2024 to May 2025
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			6					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-06-01'		AS [dStartDate], 
			'2025-05-01'		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			80000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]


		--Q07 Accumulate 100,000 TotalVacationPoints from Jun 2024 to May 2025
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			7					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-06-01'		AS [dStartDate], 
			'2025-05-01'		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			100000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		--Q30 Accumulate 45,000 TotalVacationPoints(Without bonus applied) from Jun 2024 to May 2025
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			30					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-06-01'		AS [dStartDate], 
			'2025-05-01'		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			45000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition]

		DECLARE @ColumnToPivot NVARCHAR(MAX),
			@SqlStatement NVARCHAR(MAX)

		DECLARE @QualificationSKUFactor INT = 0

		DECLARE 
			@Countries VARCHAR(MAX) = 'MY', -- Malaysia					
			@SKUs VARCHAR(MAX) = NULL, 
			@IncludeDSOutsideEligibleMarketswithTicket BIT = 0 --DS outside elegible markets in 8.1 who purchase a ticket will not appear as qualified for this event. 

		DROP TABLE IF EXISTS #ListsQsMapping

		CREATE TABLE #ListsQsMapping
		(
			ID INT IDENTITY(1,1),
			ListID INT,
			QId INT
		)
									
		INSERT INTO #ListsQsMapping(ListID,QId)
			VALUES 
				(61194,10),
				(61195,11),
				(61196,12),
				(61197,13),
				(62485,15)

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
		SELECT @PK_Event,'Malaysia' 

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
					PK_Distributor				INT
					,DistributorID				VARCHAR(MAX)   
					,DSCurrentTeam				VARCHAR(10)        
					,DSSubTeam					VARCHAR(10)        
					,DSSPTeam					VARCHAR(10)               
					,dSPQualDate				DATETIME2   
					,TeamJun2024				VARCHAR(10) 
					,CountryCode				VARCHAR(5)
					,IsFromList					BIT DEFAULT(0)
					,IsTicketPurchaser			BIT DEFAULT(0)
					,IsFromCOP					BIT DEFAULT(0)
					,TVPJun24					MONEY DEFAULT 0
					,TVPJul24					MONEY DEFAULT 0
					,TVPAug24					MONEY DEFAULT 0
					,TVPSep24					MONEY DEFAULT 0
					,TVPOct24					MONEY DEFAULT 0
					,TVPNov24					MONEY DEFAULT 0
					,TVPDec24					MONEY DEFAULT 0
					,TVPJan25					MONEY DEFAULT 0
					,TVPFeb25					MONEY DEFAULT 0
					,TVPMar25					MONEY DEFAULT 0
					,TVPApr25					MONEY DEFAULT 0
					,TVPMay25					MONEY DEFAULT 0
					,TotalTVP					AS (TVPJun24 + TVPJul24 + TVPAug24 + TVPSep24 + TVPOct24 + TVPNov24 + TVPDec24 + TVPJan25 + TVPFeb25 + TVPMar25 + TVPApr25 + TVPMay25)
					,IsASP						BIT DEFAULT(0)
					,ASPSponsors				INT DEFAULT(0)
					,ASPTotalBonus				MONEY DEFAULT(0)
					,WT1BonusSponsors			INT DEFAULT(0)
					,WT1BonusTotalBonus			MONEY DEFAULT(0)
					,PremierLeagueSponsors		INT DEFAULT(0)
					,PremierLeagueTotalBonus	MONEY DEFAULT(0)
					,TotalVacationPoints		AS (WT1BonusTotalBonus + PremierLeagueTotalBonus)
					,IsPremierLeagueQualified	BIT DEFAULT(0)
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


			/******************************************************************************
				UPDATE Freeze Status 
			******************************************************************************/
			;WITH	cte_Freeze	(nDistributorIDFK,nEventTypeLID,SortOrder) AS (
			SELECT	DS.nDistributorIDFK,DS.nEventTypeLID,DS.SortOrder
			FROM 
				dbo.v_DistributorHistory DS 
			INNER JOIN
				#DS T
			ON
				DS.nDistributorIDFK = PK_Distributor
			WHERE 
				DS.dThrough = '2049-12-31'
			AND
				DS.dFrom BETWEEN '1960-01-01' AND '2024-06-01'
			AND 
				DS.nEventTypeLID NOT IN (249,250,251,252,253)
			)

			UPDATE 
				   D
				   SET
					TeamJun2024 = CASE 
						  WHEN H.nEventTypeLID = 220 THEN 'SB'
						  WHEN H.nEventTypeLID = 221 THEN 'QC'
						  WHEN H.nEventTypeLID = 222 THEN 'QP'
						  WHEN H.nEventTypeLID = 223 THEN 'SP'     
						  WHEN H.nEventTypeLID = 224 THEN 'WT'
						  WHEN H.nEventTypeLID = 225 THEN 'GT'
						  WHEN H.nEventTypeLID = 226 THEN 'GP'
						  WHEN H.nEventTypeLID = 227 THEN 'MT'
						  WHEN H.nEventTypeLID = 228 THEN 'MP'
						  WHEN H.nEventTypeLID >= 229 AND H.nEventTypeLID <= 241 THEN 'PT Team'
						  ELSE 'No Team'
						  END
				   FROM
						  #DS D 
				   INNER JOIN 
						  cte_Freeze H 
				   ON 
						  D.PK_Distributor = H.nDistributorIDFK
				   WHERE  NOT EXISTS (SELECT 1 FROM dbo.v_DistributorHistory L WHERE D.PK_Distributor = L.nDistributorIDFK AND L.dThrough = '2049-12-31'
							AND 
								L.nEventTypeLID NOT IN (249,250,251,252,253) 
							AND 
								L.SortOrder > ISNULL(H.SortOrder,0)
							AND 
								L.dFrom BETWEEN '1960-01-01' AND '2024-06-01')

			CREATE INDEX IX_#DS_PK_Distributor ON #DS(PK_Distributor);


			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 1 AND [StepSubGroup] = 1;

			/******************************************************************************
				DOWNLINES
			******************************************************************************/
			/******************************************************************************
				ASP Bonus

				Personally qualify to ASP by Achieving 2,500 TVP in 3 consecutive months from June 2024 to May 2025 and
				Earn 2,000 Bonus points for every directly sponsored 1st SP Level ASP with COP MY that also Achieves 2,500 TVP in 3 consecutive months from June 2024 to May 2025

				? Downline and Upline consecutive months of 2,500 TVP do not need to be the same or overlap, can be any 3 consecutive months.
				? QS volume is not allowed to be used. All volume must be earned after their official SP qual date

				? Bonus points counts for Q4, Q5, Q6, Q7 towards E1, E2, E3, E4 qualification		

			******************************************************************************/
			PRINT 'Getting downlines first SP Level Active Supervisor ASP June 2024 - May 2025';
			INSERT INTO #TimeLog VALUES ('ASP Downlines', 1, 2, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS dbo.WRK_25017_ASP_Sponsors

			CREATE TABLE dbo.WRK_25017_ASP_Sponsors
			(
				UL_PK_Distributor	INT,
				UL_DistributorID	VARCHAR(MAX),
				UL_QualDate			INT,
				DL_PK_Distributor	INT,
				DL_DistributorID	VARCHAR(MAX),
				DL_QualDate			DATETIME,
			)

			DROP TABLE IF EXISTS #UL_ASP

			SELECT DSS.PK_Distributor,D.DistributorID, D.dSPQualDate
			INTO #UL_ASP
			FROM Promo.DSSubEvent DSS WITH (NOLOCK)
			INNER JOIN #DS D ON DSS.PK_Distributor = D.PK_Distributor
			WHERE 
				DSS.PK_Event = 167011 AND DSS.DateQualified BETWEEN 202408 AND 202505
			GROUP BY DSS.PK_Distributor,D.DistributorID, D.dSPQualDate

			--// Getting downlines SPs

			;WITH cte_ASP_Sponsors AS (			
			SELECT DISTINCT
			D.PK_Distributor	UL_PK_Distributor
			,D.DistributorID	UL_DistributorID
			,202505	UL_QualDate
			,DS.nDistributorID DL_PK_Distributor
			,DS.sDistributorID DL_DistributorID
			,DS.dSupervisorqualification DL_QualDate 
			FROM #UL_ASP D 
			INNER JOIN dbo.v_dimDSLngDownline DL 
						ON D.PK_Distributor = DL.PK_Distributor
			INNER JOIN Promo.DSSubEvent DSS 
						ON DL.PK_DSDownline = DSS.PK_Distributor
			INNER JOIN dbo.v_Distributor AS DS 
						ON DSS.PK_Distributor = DS.nDistributorID 
			INNER JOIN #Countries AS C
						ON Ds.nDistributorCountryProcessingID = C.nCountryID	
			WHERE 
				DS.StatusCode = 'COMPLETE'  -- Active status 
				AND DL.SPLevelFromUL = 2	-- First Level 
				AND DSS.PK_Event = 167011 AND DSS.DateQualified BETWEEN 202408 AND 202505
			GROUP BY D.PK_Distributor, D.DistributorID,DSS.DateQualified,DS.nDistributorID,DS.sDistributorID,DS.dSupervisorqualification

			UNION ALL

			SELECT DISTINCT 
			D.PK_Distributor UL_PK_Distributor
			,D.DistributorID  UL_DistributorID
			,202505 UL_QualDate
			,DS.nDistributorID DL_PK_Distributor
			,DS.sDistributorID DL_DistributorID
			,DS.dSupervisorqualification DL_QualDate 		
			FROM #UL_ASP D
			INNER JOIN dbo.v_DistributorAssociate2 DA 
						ON D.PK_Distributor = DA.nMainDistributorID
			INNER JOIN dbo.v_dimDSLngDownline DL 
						ON DA.nMainDistributorID = DL.PK_Distributor
			INNER JOIN Promo.DSSubEvent DSS 
						ON DL.PK_DSDownline = DSS.PK_Distributor
			INNER JOIN dbo.v_Distributor AS DS 
						ON DSS.PK_Distributor = DS.nDistributorID  
			INNER JOIN #Countries AS C
						ON Ds.nDistributorCountryProcessingID = C.nCountryID	
			WHERE 
				DS.StatusCode = 'COMPLETE'  -- Active status 
				AND DL.SPLevelFromUL = 2	-- First Level 
				AND DSS.PK_Event = 167011 AND DSS.DateQualified BETWEEN 202408 AND 202505
			GROUP BY D.PK_Distributor, D.DistributorID,DSS.DateQualified,DS.nDistributorID,DS.sDistributorID,DS.dSupervisorqualification

			)

			INSERT INTO dbo.WRK_25017_ASP_Sponsors(UL_PK_Distributor,UL_DistributorID,UL_QualDate,DL_PK_Distributor,DL_DistributorID,DL_QualDate)
			SELECT DISTINCT UL_PK_Distributor,UL_DistributorID,UL_QualDate,DL_PK_Distributor,DL_DistributorID,DL_QualDate 
			FROM cte_ASP_Sponsors

			CREATE INDEX IX_WRK_25017_ASP_Sponsors_UL_PK_Distributor ON dbo.WRK_25017_ASP_Sponsors(UL_PK_Distributor);

			DROP TABLE IF EXISTS dbo.WRK_25017_ASP_SponsorsPerMonth

			CREATE TABLE dbo.WRK_25017_ASP_SponsorsPerMonth
			(
				PK_Distributor INT,
				ApplicationDate INT,
				ASPSponsors INT,
				ASPSponsorsBonus MONEY
			)

			INSERT INTO dbo.WRK_25017_ASP_SponsorsPerMonth(PK_Distributor,ApplicationDate,ASPSponsors,ASPSponsorsBonus)
			SELECT 
			UL_PK_Distributor PK_Distributor
			,UL_QualDate ApplicationDate
			,COUNT(IIF(DL_PK_Distributor IS NULL,0,1)) AS ASPSponsors
			,COUNT(IIF(DL_PK_Distributor IS NULL,0,1)) * 2000 AS ASPSponsorsBonus
			FROM dbo.WRK_25017_ASP_Sponsors (NOLOCK)
			GROUP BY UL_PK_Distributor,UL_QualDate

			CREATE INDEX IX_WRK_25017_ASP_SponsorsPerMonth_PK_Distributor ON WRK_25017_ASP_SponsorsPerMonth(PK_Distributor);

			-- Update #DS with ASP Sponsors 
			UPDATE
				D
			SET
				D.[ASPSponsors]	= ADL.ASPSponsors
				,D.[ASPTotalBonus]	= ADL.ASPSponsorsBonus
			FROM
				#DS D
			INNER JOIN (
				SELECT PK_Distributor,SUM(IIF(ASPSponsors IS NULL,0,ASPSponsors)) ASPSponsors, SUM(IIF(ASPSponsorsBonus IS NULL,0,ASPSponsorsBonus)) ASPSponsorsBonus
				FROM dbo.WRK_25017_ASP_SponsorsPerMonth (NOLOCK)				
				GROUP BY PK_Distributor
			) ADL ON D.PK_Distributor = ADL.PK_Distributor

			UPDATE
				D
			SET
				D.IsASP = 1
			FROM 
				#DS D
			WHERE EXISTS (SELECT 1 FROM #UL_ASP WHERE PK_Distributor = D.PK_Distributor)

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 1 AND [StepSubGroup] = 2;


			/******************************************************************************
				1% WT Bonus Points

				Earn 2,000 Bonus points for every directly sponsored 1st SP Level WT with COP MY who qualified to the 1% WT Bonus promotion from June 2024 to May 2025
				? Refer to the ongoing promotion ?23080 - WT 1% Bonus Promotion? (event ID 195390) 

				? Bonus points counts only for Q5, Q6, Q7 towards E2, E3, E4 qualification	
			******************************************************************************/
			INSERT INTO #TimeLog VALUES ('1% WT Bonus', 1, 3, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS dbo.WRK_25017_WT1_Sponsors

			CREATE TABLE dbo.WRK_25017_WT1_Sponsors
			(
				UL_PK_Distributor	INT,
				UL_DistributorID	VARCHAR(MAX),
				UL_QualDate			INT,
				DL_PK_Distributor	INT,
				DL_DistributorID	VARCHAR(MAX),
				DL_QualDate			DATETIME,
			)

			--// Getting downlines SPs

			;WITH cte_WT1_Sponsors AS (
			SELECT DISTINCT 
			D.PK_Distributor	UL_PK_Distributor
			,D.DistributorID	UL_DistributorID
			,202505				UL_QualDate
			,DS.nDistributorID	DL_PK_Distributor
			,DS.sDistributorID	DL_DistributorID
			,DS.dSupervisorqualification DL_QualDate 
			FROM #DS D 
			INNER JOIN dbo.v_dimDSLngDownline DL 
						ON D.PK_Distributor = DL.PK_Distributor
			INNER JOIN dbo.WTOnePercent_Qualifiers_Tracking DSS (NOLOCK)
						ON DL.PK_DSDownline = DSS.PK_Distributor
			INNER JOIN dbo.v_Distributor AS DS 
						ON DSS.PK_Distributor = DS.nDistributorID 
			INNER JOIN #Countries AS C
						ON Ds.nDistributorCountryProcessingID = C.nCountryID	
			WHERE 
				DS.StatusCode = 'COMPLETE'  -- Active status 
				AND DL.SPLevelFromUL = 2	-- First Level 
				AND ((QualifiedYear = 2024 AND (Jun = 1 OR Jul = 1 OR Aug = 1 OR Sep = 1 OR Oct = 1 OR Nov = 1 OR [Dec] = 1))
				OR  (QualifiedYear = 2025 AND (Jan = 1 OR Feb = 1 OR Mar = 1 OR Apr = 1 OR May = 1)))
			GROUP BY D.PK_Distributor, D.DistributorID,D.dSPQualDate,DS.nDistributorID,DS.sDistributorID,DS.dSupervisorqualification

			UNION ALL

			SELECT DISTINCT
			D.PK_Distributor UL_PK_Distributor
			,D.DistributorID  UL_DistributorID
			,202505 UL_QualDate
			,DS.nDistributorID DL_PK_Distributor
			,DS.sDistributorID DL_DistributorID
			,DS.dSupervisorqualification DL_QualDate 		
			FROM #DS D 
			INNER JOIN dbo.v_DistributorAssociate2 DA 
						ON D.PK_Distributor = DA.nMainDistributorID
			INNER JOIN dbo.v_dimDSLngDownline DL 
						ON DA.nMainDistributorID = DL.PK_Distributor
			INNER JOIN dbo.WTOnePercent_Qualifiers_Tracking DSS (NOLOCK)
						ON DL.PK_DSDownline = DSS.PK_Distributor
			INNER JOIN dbo.v_Distributor AS DS 
						ON DSS.PK_Distributor = DS.nDistributorID  
			INNER JOIN #Countries AS C
						ON Ds.nDistributorCountryProcessingID = C.nCountryID	
			WHERE 
				DS.StatusCode = 'COMPLETE'  -- Active status 
				AND DL.SPLevelFromUL = 2	-- First Level 
				AND ((DSS.QualifiedYear = 2024 AND (DSS.Jun = 1 OR DSS.Jul = 1 OR DSS.Aug = 1 OR DSS.Sep = 1 OR DSS.Oct = 1 OR DSS.Nov = 1 OR DSS.[Dec] = 1))
				OR  (DSS.QualifiedYear = 2025 AND (DSS.Jan = 1 OR DSS.Feb = 1 OR DSS.Mar = 1 OR DSS.Apr = 1 OR DSS.May = 1)))
			GROUP BY D.PK_Distributor, D.DistributorID,D.dSPQualDate,DS.nDistributorID,DS.sDistributorID,DS.dSupervisorqualification
			)

			INSERT INTO dbo.WRK_25017_WT1_Sponsors(UL_PK_Distributor,UL_DistributorID,UL_QualDate,DL_PK_Distributor,DL_DistributorID,DL_QualDate)
			SELECT DISTINCT UL_PK_Distributor,UL_DistributorID,UL_QualDate,DL_PK_Distributor,DL_DistributorID,DL_QualDate 
			FROM cte_WT1_Sponsors
			

			CREATE INDEX IX_WRK_25017_WT1_Sponsors_UL_PK_Distributor ON WRK_25017_WT1_Sponsors(UL_PK_Distributor);

			DROP TABLE IF EXISTS dbo.WRK_25017_WT1_SponsorsPerMonth

			CREATE TABLE dbo.WRK_25017_WT1_SponsorsPerMonth
			(
				PK_Distributor INT,
				ApplicationDate INT,
				WT1Sponsors INT,
				WT1SponsorsBonus MONEY
			)

			INSERT INTO dbo.WRK_25017_WT1_SponsorsPerMonth(PK_Distributor,ApplicationDate,WT1Sponsors,WT1SponsorsBonus)
			SELECT 
			UL_PK_Distributor PK_Distributor
			,UL_QualDate ApplicationDate
			,COUNT(IIF(DL_PK_Distributor IS NULL,0,1)) AS WT1Sponsors
			,COUNT(IIF(DL_PK_Distributor IS NULL,0,1)) * 2000 AS WT1SponsorsBonus
			FROM dbo.WRK_25017_WT1_Sponsors (NOLOCK)
			GROUP BY UL_PK_Distributor,UL_QualDate

			CREATE INDEX IX_WRK_25017_WT1_SponsorsPerMonth_PK_Distributor ON WRK_25017_WT1_SponsorsPerMonth(PK_Distributor);

			-- Update #DS with WT 1% Sponsors 
			UPDATE
				D
			SET
				D.[WT1BonusSponsors]	= ADL.WT1Sponsors
				,D.WT1BonusTotalBonus	= ADL.WT1SponsorsBonus
			FROM
				#DS D
			INNER JOIN (
				SELECT PK_Distributor,SUM(IIF(WT1Sponsors IS NULL,0,WT1Sponsors)) WT1Sponsors, SUM(IIF(WT1SponsorsBonus IS NULL,0,WT1SponsorsBonus)) WT1SponsorsBonus
				FROM dbo.WRK_25017_WT1_SponsorsPerMonth (NOLOCK)				
				GROUP BY PK_Distributor
			) ADL ON D.PK_Distributor = ADL.PK_Distributor

			/******************************************************************************
				Premier Leangue Bonus Points

				Personally Qualify for 2024 Herbalife Premium League and 
				Earn 1,000 Bonus Points for every directly sponsored 1st SP Level Premier league qualifier with COP MY
				? Refer to the" 24087 - WW - Premier League Program 2024" (event ID 199427)

				? Bonus points counts for Q4, Q5, Q6, Q7 towards E1, E2, E3, E4, E5 qualification	
			******************************************************************************/

			INSERT INTO #TimeLog VALUES ('Premier Leangue Bonus', 1, 3, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS dbo.WRK_25017_PremierLeague_Sponsors

			CREATE TABLE dbo.WRK_25017_PremierLeague_Sponsors
			(
				UL_PK_Distributor	INT,
				UL_DistributorID	VARCHAR(MAX),
				UL_QualDate			INT,
				DL_PK_Distributor	INT,
				DL_DistributorID	VARCHAR(MAX),
				DL_QualDate			DATETIME,
			)
			DROP TABLE IF EXISTS #UL_PremierLeague

			SELECT DSS.PK_Distributor,D.DistributorID, D.dSPQualDate
			INTO #UL_PremierLeague
			FROM PubEventManagement.Promo.WRK_PremierLeague_SubEvent DSS (NOLOCK)
			INNER JOIN #DS D ON DSS.PK_Distributor = D.PK_Distributor
			WHERE 
				DSS.DateQualified BETWEEN 202406 AND 202505
			GROUP BY DSS.PK_Distributor,D.DistributorID, D.dSPQualDate

			--// Getting downlines SPs

			;WITH cte_PremierLeague_Sponsors AS (
			SELECT DISTINCT 
			D.PK_Distributor	UL_PK_Distributor
			,D.DistributorID	UL_DistributorID
			,DSS.DateQualified	UL_QualDate
			,DS.nDistributorID DL_PK_Distributor
			,DS.sDistributorID DL_DistributorID
			,DS.dSupervisorqualification DL_QualDate 
			FROM #DS D 
			INNER JOIN dbo.v_dimDSLngDownline DL 
						ON D.PK_Distributor = DL.PK_Distributor
			INNER JOIN PubEventManagement.Promo.WRK_PremierLeague_SubEvent DSS (NOLOCK)
						ON DL.PK_DSDownline = DSS.PK_Distributor
			INNER JOIN dbo.v_Distributor AS DS 
						ON DSS.PK_Distributor = DS.nDistributorID 
			INNER JOIN #Countries AS C
						ON Ds.nDistributorCountryProcessingID = C.nCountryID	
			WHERE 
				DS.StatusCode = 'COMPLETE'  -- Active status 
				AND DL.SPLevelFromUL = 2	-- First Level 
				AND DSS.DateQualified BETWEEN 202406 AND 202505
				AND EXISTS (SELECT 1 FROM #UL_PremierLeague WHERE PK_Distributor = D.PK_Distributor) -- Only UL that qualified for 2024 Herbalife Premium League  
			GROUP BY D.PK_Distributor, D.DistributorID,DSS.DateQualified,DS.nDistributorID,DS.sDistributorID,DS.dSupervisorqualification

			UNION ALL

			SELECT DISTINCT
			D.PK_Distributor	UL_PK_Distributor
			,D.DistributorID	UL_DistributorID
			,DSS.DateQualified	UL_QualDate
			,DS.nDistributorID	DL_PK_Distributor
			,DS.sDistributorID	DL_DistributorID
			,DS.dSupervisorqualification DL_QualDate 		
			FROM #DS D 
			INNER JOIN dbo.v_DistributorAssociate2 DA 
						ON D.PK_Distributor = DA.nMainDistributorID
			INNER JOIN dbo.v_dimDSLngDownline DL 
						ON DA.nMainDistributorID = DL.PK_Distributor
			INNER JOIN PubEventManagement.Promo.WRK_PremierLeague_SubEvent DSS (NOLOCK)
						ON DL.PK_DSDownline = DSS.PK_Distributor
			INNER JOIN dbo.v_Distributor AS DS 
						ON DSS.PK_Distributor = DS.nDistributorID  
			INNER JOIN #Countries AS C
						ON Ds.nDistributorCountryProcessingID = C.nCountryID	
			WHERE 
				DS.StatusCode = 'COMPLETE'  -- Active status 
				AND DL.SPLevelFromUL = 2	-- First Level 
				AND DSS.DateQualified BETWEEN 202406 AND 202505
				AND EXISTS (SELECT 1 FROM #UL_PremierLeague WHERE PK_Distributor = D.PK_Distributor) -- Only UL that qualified for 2024 Herbalife Premium League 
			GROUP BY D.PK_Distributor, D.DistributorID,DSS.DateQualified,DS.nDistributorID,DS.sDistributorID,DS.dSupervisorqualification
			)

			INSERT INTO dbo.WRK_25017_PremierLeague_Sponsors(UL_PK_Distributor,UL_DistributorID,UL_QualDate,DL_PK_Distributor,DL_DistributorID,DL_QualDate)
			SELECT DISTINCT UL_PK_Distributor,UL_DistributorID,UL_QualDate,DL_PK_Distributor,DL_DistributorID,DL_QualDate 
			FROM cte_PremierLeague_Sponsors
			
			CREATE INDEX IX_WRK_25017_PremierLeague_Sponsors_UL_PK_Distributor ON WRK_25017_PremierLeague_Sponsors(UL_PK_Distributor);

			DROP TABLE IF EXISTS dbo.WRK_25017_PremierLeagueSponsorsPerMonth

			CREATE TABLE dbo.WRK_25017_PremierLeagueSponsorsPerMonth
			(
				PK_Distributor INT,
				ApplicationDate INT,
				PremierLeagueSponsors INT,
				PremierLeagueSponsorsBonus MONEY
			)

			INSERT INTO dbo.WRK_25017_PremierLeagueSponsorsPerMonth(PK_Distributor,ApplicationDate,PremierLeagueSponsors,PremierLeagueSponsorsBonus)
			SELECT 
			UL_PK_Distributor PK_Distributor
			,UL_QualDate ApplicationDate
			,COUNT(IIF(DL_PK_Distributor IS NULL,0,1)) AS PremierLeagueSponsors
			,COUNT(IIF(DL_PK_Distributor IS NULL,0,1)) * 1000 AS PremierLeagueSponsorsBonus
			FROM dbo.WRK_25017_PremierLeague_Sponsors (NOLOCK)
			GROUP BY UL_PK_Distributor,UL_QualDate

			CREATE INDEX IX_WRK_25017_PremierLeagueSponsorsPerMonth_PK_Distributor ON WRK_25017_PremierLeagueSponsorsPerMonth(PK_Distributor);

			-- Update #DS with Premier League Sponsors 
			UPDATE
				D
			SET
				D.PremierLeagueSponsors		= ADL.PremierLeagueSponsors
				,D.PremierLeagueTotalBonus	= ADL.PremierLeagueSponsorsBonus
			FROM
				#DS D
			INNER JOIN (
				SELECT PK_Distributor,SUM(IIF(PremierLeagueSponsors IS NULL,0,PremierLeagueSponsors)) PremierLeagueSponsors, SUM(IIF(PremierLeagueSponsorsBonus IS NULL,0,PremierLeagueSponsorsBonus)) PremierLeagueSponsorsBonus
				FROM dbo.WRK_25017_PremierLeagueSponsorsPerMonth (NOLOCK)			
				GROUP BY PK_Distributor
			) ADL ON D.PK_Distributor = ADL.PK_Distributor

			UPDATE
				D
			SET
				D.IsPremierLeagueQualified = 1
			FROM 
				#DS D
			WHERE EXISTS (SELECT 1 FROM #UL_PremierLeague WHERE PK_Distributor = D.PK_Distributor)

			--	Merging the all temp tables of the different sponsors into just one main table  
			DROP TABLE IF EXISTS [dbo].[WRK_25017_SponsorsPerMonth] 

			;WITH cte_DS AS
			(
				SELECT PK_Distributor,ApplicationDate 
				FROM dbo.WRK_25017_ASP_SponsorsPerMonth (NOLOCK)
				UNION 
				SELECT PK_Distributor,ApplicationDate 
				FROM dbo.WRK_25017_WT1_SponsorsPerMonth (NOLOCK)
				UNION 
				SELECT PK_Distributor,ApplicationDate   
				FROM dbo.WRK_25017_PremierLeagueSponsorsPerMonth (NOLOCK)
			)
			 SELECT 
				ds.PK_Distributor,
				ds.ApplicationDate,
				ISNULL(ASPSponsors,0) AS ASPSponsors,
				ISNULL(ASPSponsorsBonus,0) AS ASPSponsorsBonus,
				ISNULL(WT1Sponsors,0) AS WT1Sponsors,
				ISNULL(WT1SponsorsBonus,0) AS WT1SponsorsBonus,
				ISNULL(PremierLeagueSponsors,0) AS PremierLeagueSponsors,
				ISNULL(PremierLeagueSponsorsBonus,0) AS PremierLeagueSponsorsBonus
			INTO [dbo].[WRK_25017_SponsorsPerMonth] 
			 FROM cte_DS AS ds
				LEFT JOIN dbo.WRK_25017_ASP_SponsorsPerMonth AS d (NOLOCK)
					ON ds.PK_Distributor = d.PK_Distributor AND ds.ApplicationDate = d.ApplicationDate
				LEFT JOIN dbo.WRK_25017_WT1_SponsorsPerMonth AS p (NOLOCK)
					ON ds.PK_Distributor = p.PK_Distributor AND ds.ApplicationDate = p.ApplicationDate
				LEFT JOIN dbo.WRK_25017_PremierLeagueSponsorsPerMonth AS f (NOLOCK)
					ON ds.PK_Distributor = f.PK_Distributor AND ds.ApplicationDate = f.ApplicationDate

			CREATE INDEX IX_WRK_25017_SponsorsPerMonth_PK_Distributor ON WRK_25017_SponsorsPerMonth(PK_Distributor);

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 1 AND [StepSubGroup] = 3;

			PRINT 'Getting downlines for the bonuses END';
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

			IF @IncludeDSOutsideEligibleMarketswithTicket = 1
			BEGIN

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

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE())	
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 2;

		END

		--Step 3: Volume for uplines
		IF @Step >= 3
		BEGIN

			PRINT 'Executing step 3'

			INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification ForUplines', 3, 1, GETUTCDATE(), NULL);

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
			IF @IsDevQA > 0 SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate]
			
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
			------------------------------------------------------------------------------------------------
			-- 3.2 Getting #tmp_DS
			------------------------------------------------------------------------------------------------
			INSERT INTO #TimeLog VALUES ('Inserting to #tmp_DS ForUplines', 3, 2, GETUTCDATE(), NULL);

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
			INSERT INTO #TimeLog VALUES ('usp_GetDSVolume for uplines', 3, 2, GETUTCDATE(), NULL);

			IF (@IsDevQA = 0)
			BEGIN
				--	SourceType 3: Getting points from [PubEventManagement].[dbo].[v_aggFQS_ID] 8.3 WW
				EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 3,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
				--Output [Event].[DSPoints]
				-- SELECT * FROM [Event].[DSPoints] (NOLOCK) WHERE PK_Event = 201105 AND PK_Distributor = 14816453
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
		
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints for uplines', 3, 3, GETUTCDATE(), NULL);
		
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
				  Update TVP Points monthly on #DS
			****************************************************/

			UPDATE
				T
			SET	
				T.TVPJun24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202406),0)
				,T.TVPJul24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202407),0)
				,T.TVPAug24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202408),0)
				,T.TVPSep24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202409),0)
				,T.TVPOct24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202410),0)
				,T.TVPNov24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202411),0)
				,T.TVPDec24	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202412),0)
				,T.TVPJan25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202501),0)
				,T.TVPFeb25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202502),0)
				,T.TVPMar25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202503),0)
				,T.TVPApr25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202504),0)
				,T.TVPMay25	 = ISNULL((SELECT A.Points FROM #Event_DSPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.RoyaltyMonth = 202505),0)
			FROM
				#DS T

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 3;

		END
		
		--Step 4: Qualification definition for uplines
		IF @Step >= 4
		BEGIN
				PRINT 'Executing step 4'

				------------------------------------------------------------------------------------------------
				-- 4.1 Getting all qualification definition for each DS
				------------------------------------------------------------------------------------------------

				INSERT INTO #TimeLog VALUES ('#tmp_DSQualDef uplines', 4, 1, GETUTCDATE(), NULL);

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


				INSERT INTO #TimeLog VALUES ('[tmp].[DSQualDef] uplines', 4, 2, GETUTCDATE(), NULL);

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
			
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints_Summary assigning bonuses', 5, 1, GETUTCDATE(), NULL);
			
			DROP TABLE IF EXISTS #Event_DSPoints_MonthsAdded

			SELECT COALESCE(U.PK_Distributor, SPM.PK_Distributor) AS PK_Distributor,
					COALESCE(U.RoyaltyMonth, SPM.ApplicationDate) AS RoyaltyMonth,
					'TV' AS MetricType,
					0 AS PK_Country,
					ISNULL(U.Points,0) Points
			INTO #Event_DSPoints_MonthsAdded
			FROM #Event_DSPoints AS U WITH (NOLOCK) 
				FULL OUTER JOIN  [dbo].[WRK_25017_SponsorsPerMonth] SPM (NOLOCK) 
				ON SPM.PK_Distributor = U.PK_Distributor AND SPM.ApplicationDate = U.RoyaltyMonth
				GROUP BY COALESCE(U.PK_Distributor, SPM.PK_Distributor),COALESCE(U.RoyaltyMonth, SPM.ApplicationDate),U.Points;


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
				FROM #Event_DSPoints_MonthsAdded AS U WITH (NOLOCK) 
							INNER JOIN #tmp_DSQualDef AS F ON u.PK_Distributor = F.PK_Distributor	
								WHERE 
								F.MetricType = U.MetricType 
								AND 
								U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
								AND 
				(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
				GROUP BY U.PK_Distributor,U.RoyaltyMonth,U.MetricType,F.[QSVolume],F.[QSVolumePercentage],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries


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
					P.[Points],
					P.QualificationNumber,
					P.Part,
						IIF(P.QualificationNumber IN (5,6,7), 
							ISNULL(SPM.ASPSponsorsBonus,0) + ISNULL(SPM.WT1SponsorsBonus,0) +  ISNULL(SPM.PremierLeagueSponsorsBonus,0),
							IIF(P.QualificationNumber = 4,
								ISNULL(SPM.ASPSponsorsBonus,0) + ISNULL(SPM.PremierLeagueSponsorsBonus,0),
								IIF(P.QualificationNumber = 30,
									ISNULL(SPM.PremierLeagueSponsorsBonus,0),
									0))) AS [Bonus],
						IIF(P.QualificationNumber IN (5,6,7), 
							P.[Points] + ISNULL(SPM.ASPSponsorsBonus,0) + ISNULL(SPM.WT1SponsorsBonus,0) +  ISNULL(SPM.PremierLeagueSponsorsBonus,0),
							IIF(P.QualificationNumber = 4,
								P.[Points] + ISNULL(SPM.ASPSponsorsBonus,0) + ISNULL(SPM.PremierLeagueSponsorsBonus,0),
								IIF(P.QualificationNumber = 30,
									P.[Points] + ISNULL(SPM.PremierLeagueSponsorsBonus,0),
									P.[Points]))) AS [TotalPoints],
					P.iStartDate,
					P.iEndDate,
					iSPQualDate,
					[QSVolume],
					[Countries]
				FROM #Event_DSPoints_Summary AS P WITH (NOLOCK)
				LEFT JOIN [dbo].[WRK_25017_SponsorsPerMonth] SPM (NOLOCK) 
					ON SPM.PK_Distributor = P.PK_Distributor AND SPM.ApplicationDate = P.RoyaltyMonth
				GROUP BY P.PK_Distributor,P.RoyaltyMonth,P.MetricType,SPM.ApplicationDate,P.[Points],P.PK_Country,P.QualificationNumber,P.Part,P.iStartDate,P.iEndDate,iSPQualDate,SPM.ASPSponsorsBonus, SPM.WT1SponsorsBonus, SPM.PremierLeagueSponsorsBonus,[QSVolume],[Countries]

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
			INSERT INTO #TimeLog VALUES ('Upline Qualifiers by volume', 6, 1, GETUTCDATE(), NULL);

			DECLARE @QualType SMALLINT  --1 = Accumulated/Non-Consecutive, 2 = Accumulated/Consecutive, 3 = Achieve/Consecutive, 4 = Achieve/Non-Consecutive
				,@PK_Execution INT
				,@PK_Event_Execution INT
				,@OverwritePointsSummary BIT

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
						UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
						WHERE [StepGroup] = 6 AND [StepSubGroup] = 1;
					END


					UPDATE #Executions
					SET Done = 1
					WHERE PK_Execution = @PK_Execution

				END
				
				INSERT INTO #TimeLog VALUES ('Upline Qualifiers by volume #Event_DSQualPoints', 6, 2, GETUTCDATE(), NULL);
				
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

			WITH DistributorHistory AS (
				SELECT 
					ROW_NUMBER() OVER (PARTITION BY nDistributorIDFK ORDER BY DH.dFrom DESC, DH.SortOrder DESC) AS Latest,
					DH.nDistributorIDFK,
					MAX(CASE WHEN T.LifeCycleCode BETWEEN 223 AND 241 THEN 1 ELSE 0 END)	AS Q01,
					MAX(CASE WHEN T.LifeCycleCode		IN (223, 224) THEN 1 ELSE 0 END)	AS Q02,
					MAX(CASE WHEN T.LifeCycleCode BETWEEN 225 AND 241 THEN 1 ELSE 0 END)	AS Q14
				FROM dbo.v_DistributorHistory AS DH
				INNER JOIN dbo.v_dimDSLifeCycle AS T 
					ON T.LifeCycleCode = DH.nEventTypeLID 
				WHERE 
					DH.dThrough = '2049-12-31'
				AND
					DH.dFrom <= '2024-06-01' 
				GROUP BY DH.nDistributorIDFK,DH.dFrom,DH.SortOrder 	
			)

			INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q08,Q09,Q14)
			SELECT 
				d.PK_Distributor,
				@PK_Event AS [PK_Event],
				ISNULL(dh.Q01, 0)						AS Q01, -- FQS and Above
				ISNULL(dh.Q02, 0)						AS Q02, -- FQS Non-TAB (Freeze Status as of Jun 01 2024)
				ISNULL((
				SELECT 1 FROM dbo.SubEventQualifier T (NOLOCK)
				INNER JOIN dbo.SubEvent S ON T.PK_SubEvent = S.PK_SubEvent
				WHERE S.PK_Event = 196029 AND S.SubEventNumber = 1 AND T.RemovedUTC='2049-12-31' AND T.PK_Distributor = d.PK_Distributor
						),0)							AS Q08, -- Qualified to E1 of Project "23085 - Malaysia 2023 Vacation JAPAN", PK ID 196029
				ISNULL((
				SELECT 1 FROM dbo.SubEventQualifier T (NOLOCK)
				INNER JOIN dbo.SubEvent S ON T.PK_SubEvent = S.PK_SubEvent
				WHERE S.PK_Event = 196028 AND S.SubEventNumber = 1 AND T.RemovedUTC='2049-12-31' AND T.PK_Distributor = d.PK_Distributor
						),0)							AS Q09, -- Qualified to E1 of Project "23084 - Malaysia 2023 Vacation BINTAN", PK ID 196028
				ISNULL(dh.Q14, 0)						AS Q14  -- FQS TAB team (Freeze Status as of Jun 01 2024)
			FROM #DS AS d
			LEFT JOIN DistributorHistory AS dh 
						ON d.PK_Distributor = dh.nDistributorIDFK AND dh.Latest = 1
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

			INSERT INTO #TimeLog VALUES ('Es #EventQual', 8, 1, GETUTCDATE(), NULL);
				
				UPDATE 
					#EventQual
				SET
					E04 = ((Q01 & Q03 & Q07) | Q13)

				UPDATE
					#EventQual
				SET
					E03 = ((Q01 & Q03 & Q06 & ~E04) | Q12)

				UPDATE
					#EventQual
				SET
					E02 = ((Q01 & Q03 & Q05 & ~E04 & ~E03) | Q11)
							
				UPDATE 
					#EventQual
				SET
					E01 =  ((Q02 & Q03 & Q04 & ~E04 & ~E03 & ~E02) | Q10)
				
				UPDATE 
					#EventQual
				SET
					E05 = ((Q14 & Q03 & Q30 & ~(Q08 | Q09)) | Q15) --Q30 is like Q4 but without ASP bonus applied

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
		
				--WRK_Malaysia_Vacation_2025
				DROP TABLE IF EXISTS dbo.WRK_Malaysia_Vacation_2025 

				SELECT 
					PK_Distributor				
					,DistributorID				
					,DSCurrentTeam				
					,DSSubTeam					
					,DSSPTeam					
					,dSPQualDate
					,TeamJun2024
					,CountryCode				
					,IsFromList					
					,IsTicketPurchaser			
					,IsFromCOP					
					,TVPJun24					
					,TVPJul24					
					,TVPAug24					
					,TVPSep24					
					,TVPOct24					
					,TVPNov24					
					,TVPDec24					
					,TVPJan25					
					,TVPFeb25					
					,TVPMar25					
					,TVPApr25					
					,TVPMay25					
					,TotalTVP					
					,IsASP	
					,ASPSponsors				
					,ASPTotalBonus				
					,WT1BonusSponsors			
					,WT1BonusTotalBonus			
					,PremierLeagueSponsors		
					,PremierLeagueTotalBonus	
					,TotalVacationPoints
					,IsPremierLeagueQualified
				INTO dbo.WRK_Malaysia_Vacation_2025 
				FROM #DS 
						
				CREATE INDEX [IX_WRK_Malaysia_Vacation_2025_PK_Distributor] ON [dbo].[WRK_Malaysia_Vacation_2025] ([PK_Distributor])

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

				--#WRK_Malaysia_Vacation_2025
				DROP TABLE IF EXISTS dbo.#WRK_Malaysia_Vacation_2025 

				SELECT 
					PK_Distributor				
					,DistributorID				
					,DSCurrentTeam				
					,DSSubTeam					
					,DSSPTeam					
					,dSPQualDate
					,TeamJun2024
					,CountryCode				
					,IsFromList					
					,IsTicketPurchaser			
					,IsFromCOP					
					,TVPJun24					
					,TVPJul24					
					,TVPAug24					
					,TVPSep24					
					,TVPOct24					
					,TVPNov24					
					,TVPDec24					
					,TVPJan25					
					,TVPFeb25					
					,TVPMar25					
					,TVPApr25					
					,TVPMay25					
					,TotalTVP					
					,IsASP						
					,ASPSponsors				
					,ASPTotalBonus				
					,WT1BonusSponsors			
					,WT1BonusTotalBonus			
					,PremierLeagueSponsors		
					,PremierLeagueTotalBonus	
					,TotalVacationPoints	
					,IsPremierLeagueQualified
				INTO dbo.#WRK_Malaysia_Vacation_2025 
				FROM #DS 
						
				CREATE INDEX [IX_#WRK_Malaysia_Vacation_2025_PK_Distributor] ON [dbo].[#WRK_Malaysia_Vacation_2025] ([PK_Distributor])
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