CREATE PROCEDURE [dbo].[usp_EventQual_PhilippinesVacation_2024]
	@PK_Event int = 199289
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
	,@Step SMALLINT = 14
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_PhilippinesVacation_2024

	USE:		

			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC dbo.usp_EventQual_PhilippinesVacation_2024
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
	1.0.0	2024-05-06	juangue		Initial 
	1.0.1	2024-05-24	JuanGue		DownlineAWT BugFix
	1.0.2	2024-05-27	JuanGue		#1346984 #BugFix Only show highest level qualified where 60K Qualifier is lowest and 100K Qualifier is highest
	1.0.3	2024-05-28	JuanGue		#1346985 #BugFix TAB Freeze Date as of: Sep 01 2023 should not have bonus to qualify because the max awt date is 2024-08
	1.0.4   2024-05-28  JuanGue		Removing code smells
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

		DECLARE @ProjectID INT = 24065			 

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
			[MetricTypeDefinition]	VARCHAR(50) NULL,
			[ForDownlinesOnly]		bit default(0)
		)
		
		--Q02 Achieve 60,000 Total Vacation Points during Qual Period A
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			2					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2023-09-01'		AS [dStartDate], 
			'2024-08-31'		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			60000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [Bonus]
	
		--Q03 Achieve 75,000 Total Vacation Points during Qual Period A
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			3					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2023-09-01'		AS [dStartDate], 
			'2024-08-31'		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			75000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [Bonus]

		--Q04 Achieve 100,000 Total Vacation Points during Qual Period A
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[Bonus])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			4					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2023-09-01'		AS [dStartDate], 
			'2024-08-31'		AS [dEndDate], 
			12					AS [Frequency], 
			0					AS [Consecutive], 
			1					AS [Accumulated], 
			0					AS [MinPoints], 
			100000				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			0					AS [Bonus]

		--Q30 SP achieving 2,500 Total Volume Points in three (3) consecutive months) from Jan 2024 to Nov 2024 -- corresponding to ASP recognition dates of Apr 2024 (Using Jan-Feb-Mar Volume) to Dec 2024 (Using Sep-Oct-Nov Volume)
		INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition],[ForDownlinesOnly])											 
		SELECT 
			@PK_Event			AS [PK_Event],
			30					AS QualificationNumber,
			1					AS Part, 
			'TV'				AS [MetricType], 
			'2024-01-01'		AS [dStartDate], 
			'2024-11-01'		AS [dEndDate], 
			3					AS [Frequency], 
			1					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			2500				AS [GoalPoints], 
			NULL				AS [Countries],
			0					AS [QSVolume], 
			1					AS [PeriodType], 
			NULL				AS [MetricTypeDefinition],
			1					AS [ForDownlinesOnly]

		DECLARE @ColumnToPivot NVARCHAR(MAX),
			@SqlStatement NVARCHAR(MAX)

		DECLARE @QualificationSKUFactor INT = 40

		DECLARE 
			@Countries VARCHAR(MAX) = 'RP', -- Philippines					
			--@ListsIDs VARCHAR(MAX) = '59382,59383,59384,59385',
			@SKUs VARCHAR(MAX) = NULL, 
			@IncludeDSOutsideEligibleMarketswithTicket BIT = 1 --DS outside elegible markets in 8.1 who purchase a ticket will not appear as qualified for this event. 

		DROP TABLE IF EXISTS #ListsQsMapping

		CREATE TABLE #ListsQsMapping
		(
			ID INT IDENTITY(1,1),
			ListID INT,
			QId INT
		)
									
		INSERT INTO #ListsQsMapping(ListID,QId)
			VALUES 
				(59382,5),
				(59383,6),
				(59384,7),
				(59385,8)

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
		SELECT @PK_Event,'Philippines' 

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
					PK_Distributor		INT,
					DistributorID		VARCHAR(MAX),   
					DSCurrentTeam		VARCHAR(10),        
					DSSubTeam			VARCHAR(10),        
					DSSPTeam			VARCHAR(10),               
					dSPQualDate			DATETIME2,        
					CountryCode			VARCHAR(5),
					IsFromList			BIT DEFAULT(0),
					IsTicketPurchaser	BIT DEFAULT(0),
					IsFromCOP			BIT DEFAULT(0),
					IsAWT2024			BIT DEFAULT(0),	
					TVP					MONEY DEFAULT(0),
					ASP2024DLQualifiers INT DEFAULT(0),
					ASP2024TotalBonus	MONEY DEFAULT(0),
					AWT2024DLQualifiers INT DEFAULT(0),
					AWT2024TotalBonus	MONEY DEFAULT(0)

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

			/******************************************************************************
				DOWNLINES
			******************************************************************************/
			/******************************************************************************
				Non-TAB ASP 2024 Bonus Points
				
				Getting downlines first DS Level Non-TAB Active Supervisor ASP 2024
			******************************************************************************/
			PRINT 'Getting downlines Non-TAB active SPs BEGIN';
			INSERT INTO #TimeLog VALUES ('ASP Downlines', 1, 2, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #DownlinesASP

			CREATE TABLE #DownlinesASP
			(
				UL_PK_Distributor	INT,
				UL_DistributorID	VARCHAR(MAX),
				UL_QualDate			DATETIME,
				DL_PK_Distributor	INT,
				DL_DistributorID	VARCHAR(MAX),
				DL_QualDate			DATETIME,
			)

			;WITH cte_DS_ASP2024 AS
			(
			SELECT PK_Distributor
			FROM Promo.DSSubEvent WITH (NOLOCK)
			WHERE PK_Event = 36884 AND SubEvent = 1 AND DateQualified BETWEEN 202404 AND 202412
			EXCEPT
			SELECT PK_Distributor 
			FROM Promo.DSSubEvent WITH (NOLOCK) 
			WHERE PK_Event = 36884 AND SubEvent = 1 AND DateQualified BETWEEN 198501 AND 202403 -- Except qualified BETWEEN 198501 AND 202401
			)

			--// Getting downlines Non-TAB active SPs
			INSERT INTO #DownlinesASP(UL_PK_Distributor,UL_DistributorID,UL_QualDate,DL_PK_Distributor,DL_DistributorID,DL_QualDate)
			SELECT 
			D.PK_Distributor UL_PK_Distributor
			,D.DistributorID  UL_DistributorID
			,D.dSPQualDate UL_QualDate
			,DH.nDistributorIDFK DL_PK_Distributor
			,DH.sDistributorID DL_DistributorID
			,DH.dFrom DL_QualDate 
			FROM #DS D 
			INNER JOIN dbo.v_dimDSLngDownline DL ON D.PK_Distributor = DL.PK_Distributor
			INNER JOIN cte_DS_ASP2024 DLL ON DL.PK_DSDownline = DLL.PK_Distributor
			INNER JOIN dbo.v_DistributorHistory AS DH (NOLOCK) ON DLL.PK_Distributor = DH.nDistributorIDFK AND DH.dFrom >= '2023-09-01' AND DH.dThrough = '2049-12-31' -- Freeze Date as of: Sep 01 2023
			INNER JOIN [dbo].[v_dimDSLifeCycle] AS t ON DH.nEventTypeLID = t.LifeCycleCode
			WHERE 
			DL.DSLevelFromUL = 2 -- First Level 
			AND t.LifeCycleCode IN (223,224) -- (Qual Supervisor, Qual World Team) NON-TAB 
			GROUP BY D.PK_Distributor, D.DistributorID,D.dSPQualDate,DH.nDistributorIDFK,DH.sDistributorID,DH.dFrom 

			UNION ALL

			SELECT 
			D.PK_Distributor UL_PK_Distributor
			,D.DistributorID  UL_DistributorID
			,D.dSPQualDate UL_QualDate
			,DH.nDistributorIDFK DL_PK_Distributor
			,DH.sDistributorID DL_DistributorID
			,DH.dFrom DL_QualDate 			
			FROM #DS D
			INNER JOIN dbo.v_DistributorAssociate2 DA ON D.PK_Distributor = DA.nMainDistributorID
			INNER JOIN dbo.v_dimDSLngDownline DL ON DA.nMainDistributorID = DL.PK_Distributor
			INNER JOIN cte_DS_ASP2024 DLL ON DL.PK_DSDownline = DLL.PK_Distributor
			INNER JOIN dbo.v_DistributorHistory AS DH (NOLOCK) ON DLL.PK_Distributor = DH.nDistributorIDFK AND DH.dFrom >= '2023-09-01' AND DH.dThrough = '2049-12-31' -- Freeze Date as of: Sep 01 2023
			INNER JOIN [dbo].[v_dimDSLifeCycle] AS t ON DH.nEventTypeLID = t.LifeCycleCode
			WHERE 
			DL.DSLevelFromUL = 2 -- First Level 
			AND t.LifeCycleCode IN (223,224) -- (Qual Supervisor, Qual World Team) NON-TAB 
			GROUP BY D.PK_Distributor, D.DistributorID,D.dSPQualDate,DH.nDistributorIDFK,DH.sDistributorID,DH.dFrom 


			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 1 AND [StepSubGroup] = 2;

			/******************************************************************************
				AWT 2024 Bonus Points

				Personally qualify as a 2024 Active World Team and earn 10,000 Vacation Points 
				for every first DS Level 2024 Active World Team (TAB or Non-TAB) from Jan 2024 to Aug 2024
			******************************************************************************/
			INSERT INTO #TimeLog VALUES ('AWT Downlines', 1, 3, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #DownlinesAWT

			CREATE TABLE #DownlinesAWT
			(
				UL_PK_Distributor	INT,
				UL_DistributorID	VARCHAR(MAX),
				UL_QualDate_AWT			DATETIME,
				DL_PK_Distributor	INT,
				DL_DistributorID	VARCHAR(MAX),
				DL_QualDate_AWT			DATETIME,
			)

			--// Getting uplines from AWT (TAB or Non-TAB) AWTYear 2024
			;WITH cte_UL_DS_AWT2024 AS
			(
				SELECT A.PK_Distributor,A.DistributorID,A.Qual_AWT 
				FROM #DS D
				INNER JOIN dbo.AWT A (NOLOCK) ON D.PK_Distributor = A.PK_Distributor
				WHERE A.AWTYear = 2024 
			)

			--// Getting downlines (TAB or Non-TAB) active SPs
			INSERT INTO #DownlinesAWT(UL_PK_Distributor,UL_DistributorID,UL_QualDate_AWT,DL_PK_Distributor,DL_DistributorID,DL_QualDate_AWT)
			SELECT 
			UL_AWT.PK_Distributor	UL_PK_Distributor
			,UL_AWT.DistributorID	UL_DistributorID
			,UL_AWT.Qual_AWT 		UL_QualDate_AWT 
			,DL_AWT.PK_Distributor	DL_PK_Distributor
			,DL_AWT.DistributorID	DL_DistributorID
			,DL_AWT.Qual_AWT		DL_Qual_AWT
			FROM cte_UL_DS_AWT2024 UL_AWT 
			LEFT JOIN dbo.v_dimDSLngDownline DL ON UL_AWT.PK_Distributor = DL.PK_Distributor
			LEFT JOIN dbo.AWT AS DL_AWT (NOLOCK) ON DL.PK_DSDownline = DL_AWT.PK_Distributor AND DL_AWT.Qual_AWT BETWEEN '2024-01-01' AND '2024-08-31'
			LEFT JOIN dbo.v_Distributor D ON DL.PK_DSDownline = D.nDistributorID
			WHERE 
				DL.DSLevelFromUL = 2 -- First Level 
			GROUP BY UL_AWT.PK_Distributor,UL_AWT.DistributorID,UL_AWT.Qual_AWT,DL_AWT.PK_Distributor,DL_AWT.DistributorID,DL_AWT.Qual_AWT	

			UNION ALL

			SELECT 
			UL_AWT.PK_Distributor	UL_PK_Distributor
			,UL_AWT.DistributorID	UL_DistributorID
			,UL_AWT.Qual_AWT		UL_QualDate_AWT
			,DL_AWT.PK_Distributor	DL_PK_Distributor
			,DL_AWT.DistributorID	DL_DistributorID
			,DL_AWT.Qual_AWT		DL_Qual_AWT		
			FROM cte_UL_DS_AWT2024 UL_AWT  
			LEFT JOIN dbo.v_DistributorAssociate2 DA ON UL_AWT.PK_Distributor = DA.nMainDistributorID
			LEFT JOIN dbo.v_dimDSLngDownline DL ON DA.nMainDistributorID = DL.PK_Distributor
			LEFT JOIN dbo.AWT AS DL_AWT (NOLOCK) ON DL.PK_DSDownline = DL_AWT.PK_Distributor AND DL_AWT.Qual_AWT BETWEEN '2024-01-01' AND '2024-08-31'
			LEFT JOIN dbo.v_Distributor D ON DL.PK_DSDownline = D.nDistributorID
			WHERE 
				DL.DSLevelFromUL = 2 -- First Level 
			GROUP BY UL_AWT.PK_Distributor,UL_AWT.DistributorID,UL_AWT.Qual_AWT,DL_AWT.PK_Distributor,DL_AWT.DistributorID,DL_AWT.Qual_AWT	


			-- Update #DS with AWTQualifiers 
			UPDATE
				D
			SET
				D.IsAWT2024				 = 1
				,D.[AWT2024DLQualifiers] = ADL.AWTQualifiers
				,D.[AWT2024TotalBonus]	 = ADL.AWTQualifiers * 10000
			FROM
				#DS D
			INNER JOIN (
				SELECT UL_PK_Distributor,SUM(IIF(DL_PK_Distributor IS NULL,0,1)) AWTQualifiers 
				FROM #DownlinesAWT 
				GROUP BY UL_PK_Distributor
				) ADL ON D.PK_Distributor = ADL.UL_PK_Distributor

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 1 AND [StepSubGroup] = 3;

			PRINT 'Getting downlines Non-TAB active SPs END';
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

		--Step 3: Volume for SP achieving 2,500 Total Volume Points in three (3) consecutive months) from Jan 2024 to Nov 2024 corresponding to ASP recognition dates	
		IF @Step >= 3
		BEGIN

			PRINT 'Executing step 3'

			IF @IsDevQA = 0
			BEGIN	

				DELETE s FROM [Event].[SetupEventQualification] AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
				INSERT INTO [Event].[SetupEventQualification](PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
				SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition 
				FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event AND [ForDownlinesOnly] = 1

			END
			ELSE
			IF @IsDevQA = 3
			BEGIN	

				DELETE s FROM ##Event_SetupEventQualification_jgue AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
				INSERT INTO ##Event_SetupEventQualification_jgue(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
				SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition
				FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event AND [ForDownlinesOnly] = 1

			END
			------------------------------------------------------------------------------------------------
			-- 3.1 Getting values from #Event_SetupEventQualification
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification ForDownlinesOnly', 3, 1, GETUTCDATE(), NULL);

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
					WHERE [ForDownlinesOnly] = 1
	
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 1;

				-- Result set 
				IF @IsDevQA > 0 SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate]--,@DSCountries AS [DSCountries]--,@MetricType AS [MetricType]

				------------------------------------------------------------------------------------------------
				-- 3.2 Getting #tmp_DS
				------------------------------------------------------------------------------------------------
			
				INSERT INTO #TimeLog VALUES ('#tmp_DS ForDownlinesOnly', 3, 2, GETUTCDATE(), NULL);

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
						@PK_Event AS [PK_Event],
						D.DL_PK_Distributor,
						D.DL_DistributorID,
						@iStartDate AS [iStartDate],
						@iEndDate AS [iEndDate],
						@dStartDate AS [dStartDate],
						@dEndDate AS [dEndDate],
						D.DL_QualDate  
					FROM #DownlinesASP AS D

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
				INSERT INTO #TimeLog VALUES ('usp_GetDSVolume ForDownlinesOnly', 3, 3, GETUTCDATE(), NULL);

				IF (@IsDevQA = 0)
				BEGIN	
					--	SourceType 3: Getting points from [PubEventManagement].[dbo].[v_aggFQS_ID] 8.3 WW
					EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 3,@QualFilter = '30',@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					--Output [Event].[DSPoints]

					IF @Error <> 0
					BEGIN
						SET @Error = @Error
						SET @ErrorMessage = @ErrorMessage
						RETURN;
					END

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 3 AND [StepSubGroup] = 3;
		
				END
				ELSE
				IF (@IsDevQA = 3) AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_jgue') IS NOT NULL
				BEGIN
					 
					--Input
					-- SELECT * FROM ##tmp_DS_jgue
					-- SELECT * FROM ##Event_SetupEventQualification_jgue

					EXEC [dbo].[##usp_GetDSVolume_jgue] @PK_Event = @PK_Event, @SourceType = 3,@QualFilter = '30',@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
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
					WHERE [StepGroup] = 3 AND [StepSubGroup] = 3;
		
				END
			
			------------------------------------------------------------------------------------------------
			-- 3.5 Getting #Event_DSPoints 
			------------------------------------------------------------------------------------------------
		
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints ForDownlinesOnly', 3, 4, GETUTCDATE(), NULL);

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
			
				IF @IsDevQA = 0
				BEGIN 

					DROP TABLE IF EXISTS [dbo].[WRK_24065_ASP2024DownlinesVolume]
					SELECT 
						PK_Distributor,
						PK_Event,
						PK_Country,
						RoyaltyMonth,
						MetricType,
						PersonalPoints,
						TransferPoints,
						MainPoints,  
						Points,
						Bonus
					INTO [dbo].[WRK_24065_ASP2024DownlinesVolume]
					FROM #Event_DSPoints

				END ELSE
				IF @IsDevQA = 3
				BEGIN 

					DROP TABLE IF EXISTS #WRK_24065_ASP2024DownlinesVolume
					SELECT 
						PK_Distributor,
						PK_Event,
						PK_Country,
						RoyaltyMonth,
						MetricType,
						PersonalPoints,
						TransferPoints,
						MainPoints,  
						Points,
						Bonus
					INTO #WRK_24065_ASP2024DownlinesVolume
					FROM #Event_DSPoints

				END				

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 4;
			
		
		END
			
		--Step 4: Qualification definition for downlines Non-TAB active SPs
		IF @Step >= 4
		BEGIN
				PRINT 'Executing step 4'

				------------------------------------------------------------------------------------------------
				-- 4.1 Getting all qualification definition for each DS
				------------------------------------------------------------------------------------------------

				INSERT INTO #TimeLog VALUES ('#tmp_DSQualDef ForDownlinesOnly', 4, 1, GETUTCDATE(), NULL);
			
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

					INSERT INTO #tmp_DSQualDef([PK_Event],PK_Distributor,dStartDate,dEndDate,iStartDate,iEndDate,[dSPQualDate],[iSPQualDate],Frequency,Consecutive,Accumulated,MetricType,GoalPoints,MinPoints,QualificationNumber,Part,PK_AssociatedID,Countries,[QSVolume],[Bonus])
						SELECT 
							C.PK_Event,
							D.DL_PK_Distributor AS PK_Distributor,
							A.StartDate AS dStartDate,
							A.EndDate AS dEndDate,
							CAST(CONVERT(varchar(6), A.StartDate, 112) AS int) AS iStartDate,
							CAST(CONVERT(varchar(6), A.EndDate, 112) AS int) AS iEndDate,
							D.DL_QualDate AS [dSPQualDate],
							CAST(CONVERT(varchar(6), D.DL_QualDate, 112) AS int) AS [iSPQualDate],
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
							ISNULL(C.Bonus,0) AS [Bonus]
						FROM #DownlinesASP AS D					
							LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
								ON D.DL_PK_Distributor = M.PK_Distributor
							OUTER APPLY (SELECT * FROM #Event_SetupEventQualification AS S WITH (NOLOCK) WHERE S.ForDownlinesOnly = 1) AS C
							CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
		
					CREATE INDEX IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef(PK_Distributor);

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 4 AND [StepSubGroup] = 1;

				INSERT INTO #TimeLog VALUES ('[tmp].[DSQualDef] ForDownlinesOnly', 4, 2, GETUTCDATE(), NULL);

				IF @IsDevQA = 0
				BEGIN
			
					DELETE [tmp].[DSQualDef] WHERE PK_Event = @PK_Event

					DROP INDEX IF EXISTS IX_tmp_DSQualDef_PK_Event ON [tmp].[DSQualDef];			

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
		
		--Step 5: Getting DSPointsSummary for downlines Non-TAB active SPs		
		IF @Step >= 5
		BEGIN
			
			PRINT 'Executing step 5'
		 				
			INSERT INTO #TimeLog VALUES ('#tmp_DSPointsSummary ForDownlinesOnly', 5, 1, GETUTCDATE(), NULL);

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

				INSERT INTO #tmp_DSPointsSummary([PK_Event],PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],[Bonus],QSVolume,QSVolumePercentage,iSPQualDate,QualificationNumber,Part,[HasBonus],[TotalPoints],iStartDate,iEndDate,Countries)
				SELECT 
							@PK_Event AS PK_Event,
							P.PK_Distributor,
							P.RoyaltyMonth,
							P.MetricType,
							P.PK_Country,
							P.[Points],
							0 AS [Bonus],
							P.QSVolume,
							P.QSVolumePercentage,
							P.iSPQualDate,
							P.QualificationNumber,
							P.Part,
							0 AS [HasBonus],
							ISNULL(P.[Points],0) AS [TotalPoints],
							P.iStartDate,
							P.iEndDate,
							P.Countries
						FROM #Event_DSPoints_Summary AS P
			
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 5 AND [StepSubGroup] = 1;


				INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary] ForDownlinesOnly', 5, 2, GETUTCDATE(), NULL);

				IF @IsDevQA = 0
				BEGIN				
					
					DELETE t
					FROM [tmp].[DSPointsSummary] AS t
					WHERE t.PK_Event = @PK_Event

					DROP INDEX IF EXISTS IX_tmp_DSPointsSummary_PK_Distributor ON [tmp].[DSPointsSummary];


					INSERT INTO [tmp].[DSPointsSummary](PK_Event, PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,iSPQualDate,QSVolume,Countries)
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
							iSPQualDate,
							QSVolume,
							Countries
						FROM #tmp_DSPointsSummary

					CREATE INDEX IX_tmp_DSPointsSummary_PK_Distributor ON [tmp].[DSPointsSummary](PK_Distributor)INCLUDE (PK_Event);	

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 5 AND [StepSubGroup] = 2;

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


					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 5 AND [StepSubGroup] = 2;

				END	 
	
		END
			
		--Step 6: Qualifiers by volume for downlines NON-TAB ASP 2024
		IF @Step >= 6
		BEGIN
			
			PRINT 'Executing step 6'

			------------------------------------------------------------------------------------------------
			-- 6.1 Getting qualifiers by volume according to qualification definitions
			------------------------------------------------------------------------------------------------
	
			INSERT INTO #TimeLog VALUES ('Qualifiers by volume ForDownlinesOnly', 6, 1, GETUTCDATE(), NULL);

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
				FROM #Event_SetupEventQualification WHERE [ForDownlinesOnly] = 1
					 
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
						--SELECT * FROM ##DSQualPoints_jgue

						UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
						WHERE [StepGroup] = 6 AND [StepSubGroup] = 1;
					END


				UPDATE #Executions
				SET Done = 1
				WHERE PK_Execution = @PK_Execution

				END

				INSERT INTO #TimeLog VALUES ('WRK_24065_ASP2024DownlinesQualifiers ForDownlinesOnly', 6, 2, GETUTCDATE(), NULL);

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

				IF @IsDevQA = 0
				BEGIN

					DROP TABLE IF EXISTS dbo.WRK_24065_ASP2024DownlinesQualifiers

					SELECT DISTINCT D.UL_PK_Distributor,D.DL_PK_Distributor, Q.QualDate, Q.QualificationNumber 
					INTO dbo.WRK_24065_ASP2024DownlinesQualifiers
					FROM [Event].[DSQualPoints] AS Q WITH (NOLOCK)
						INNER JOIN #DownlinesASP AS D
							ON Q.PK_Distributor = D.DL_PK_Distributor
					WHERE Q.PK_Event = @PK_Event
					ORDER BY D.UL_PK_Distributor

					;WITH cte_ASP2024 AS
					(
					SELECT X.UL_PK_Distributor, COUNT(*) ASPQualifiers FROM (
						SELECT UL_PK_Distributor, DL_PK_Distributor FROM dbo.WRK_24065_ASP2024DownlinesQualifiers (NOLOCK)
						GROUP BY UL_PK_Distributor, DL_PK_Distributor
					) AS X
					GROUP BY X.UL_PK_Distributor
					)
					-- Update #DS with ASPQualifiers
					UPDATE
						D
					SET
						D.[ASP2024DLQualifiers] = ADL.ASPQualifiers
						,D.[ASP2024TotalBonus] = ADL.ASPQualifiers * 3000
					FROM
						#DS D
					INNER JOIN cte_ASP2024 ADL ON D.PK_Distributor = ADL.UL_PK_Distributor

				END
				ELSE
				BEGIN
					DROP TABLE IF EXISTS #WRK_24065_ASP2024DownlinesQualifiers

					SELECT DISTINCT D.UL_PK_Distributor, D.DL_PK_Distributor, Q.QualDate,Q.QualificationNumber  
					INTO #WRK_24065_ASP2024DownlinesQualifiers
					FROM #Event_DSQualPoints AS Q
						INNER JOIN #DownlinesASP AS D
							ON Q.PK_Distributor = D.DL_PK_Distributor
					WHERE Q.PK_Event = @PK_Event
					ORDER BY D.UL_PK_Distributor

					;WITH cte_ASP2024 AS
					(
					SELECT X.UL_PK_Distributor, COUNT(*) ASPQualifiers FROM (
						SELECT UL_PK_Distributor, DL_PK_Distributor FROM dbo.#WRK_24065_ASP2024DownlinesQualifiers
						GROUP BY UL_PK_Distributor, DL_PK_Distributor
					) AS X
					GROUP BY X.UL_PK_Distributor
					)
					-- Update #DS with ASPQualifiers
					UPDATE
						D
					SET
						D.[ASP2024DLQualifiers] = ADL.ASPQualifiers
						,D.[ASP2024TotalBonus] = ADL.ASPQualifiers * 3000
					FROM
						#DS D
					INNER JOIN cte_ASP2024 ADL ON D.PK_Distributor = ADL.UL_PK_Distributor

				END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 6 AND [StepSubGroup] = 2;
		END

		--Step 7: Volume for uplines
		IF @Step >= 7
		BEGIN

			PRINT 'Executing step 7'

			INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification ForUplines', 7, 1, GETUTCDATE(), NULL);

			IF @IsDevQA = 0
			BEGIN	

				DELETE s FROM [Event].[SetupEventQualification] AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
				INSERT INTO [Event].[SetupEventQualification](PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
				SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition 
				FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event AND ISNULL([ForDownlinesOnly],0) = 0 

			END
			ELSE
			IF @IsDevQA = 3
			BEGIN	

				DELETE s FROM ##Event_SetupEventQualification_jgue AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
				INSERT INTO ##Event_SetupEventQualification_jgue(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
				SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition
				FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event AND ISNULL([ForDownlinesOnly],0) = 0

			END

			------------------------------------------------------------------------------------------------
			-- 7.1 Getting values from #Event_SetupEventQualification
			------------------------------------------------------------------------------------------------
				
				SELECT 
					@iStartDate = CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int), 
					@dStartDate = MIN(dStartDate),
					@iEndDate = CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int),
					@dEndDate = MAX(dEndDate)
					FROM #Event_SetupEventQualification WITH (NOLOCK) 
					WHERE ForDownlinesOnly = 0
	
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 1;

			-- Result set 
			IF @IsDevQA > 0 SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate]--,@DSCountries AS [DSCountries]--,@MetricType AS [MetricType]

			------------------------------------------------------------------------------------------------
			-- 7.2 Getting #tmp_DS
			------------------------------------------------------------------------------------------------
			INSERT INTO #TimeLog VALUES ('Inserting to #tmp_DS ForUplines', 7, 2, GETUTCDATE(), NULL);

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
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 2;

			------------------------------------------------------------------------------------------------
			-- 7.3 Getting [Event].[DSPoints]
			------------------------------------------------------------------------------------------------
			INSERT INTO #TimeLog VALUES ('usp_GetDSVolume for uplines', 7, 2, GETUTCDATE(), NULL);

			IF (@IsDevQA = 0)
			BEGIN
				--	SourceType 3: Getting points from [PubEventManagement].[dbo].[v_aggFQS_ID] 8.3 WW
				EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 3,@QualFilter = '2,3,4',@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
				--Output [Event].[DSPoints]

				IF @Error <> 0
				BEGIN
					SET @Error = @Error
					SET @ErrorMessage = @ErrorMessage
					RETURN;
				END

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 7 AND [StepSubGroup] = 2;
		
			END
			ELSE
			IF (@IsDevQA = 3) AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_jgue') IS NOT NULL
			BEGIN
					 
				--Input
				--##tmp_DS_jgue
				--##Event_SetupEventQualification_jgue

				EXEC [dbo].[##usp_GetDSVolume_jgue] @PK_Event = @PK_Event, @SourceType = 3,@QualFilter = '2,3,4',@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
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
				WHERE [StepGroup] = 7 AND [StepSubGroup] = 2;
		
			END
			
			------------------------------------------------------------------------------------------------
			-- 7.3 Getting #Event_DSPoints 
			------------------------------------------------------------------------------------------------
		
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints for uplines', 7, 3, GETUTCDATE(), NULL);
		
			DROP INDEX IF EXISTS [IX_#Event_DSPoints_PK_Distributor]
				ON #Event_DSPoints;

			DROP INDEX IF EXISTS [IX_#Event_DSPoints_MetricType]
				ON #Event_DSPoints;

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

			-- Update #DS with TVP
			UPDATE
				D
			SET
				D.[TVP] = EDSP.Points
			FROM
				#DS D
			INNER JOIN (
				SELECT PK_Distributor, SUM(Points) Points
				FROM #Event_DSPoints 
				GROUP BY PK_Distributor
				) EDSP ON D.PK_Distributor = EDSP.PK_Distributor

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 3;

		END
		
		--Step 8: Qualification definition for uplines
		IF @Step >= 8
		BEGIN
				PRINT 'Executing step 8'

				------------------------------------------------------------------------------------------------
				-- 4.1 Getting all qualification definition for each DS
				------------------------------------------------------------------------------------------------

				INSERT INTO #TimeLog VALUES ('#tmp_DSQualDef uplines', 8, 1, GETUTCDATE(), NULL);
			
					DELETE FROM #tmp_DSQualDef

					DROP INDEX IF EXISTS IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef;

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
							OUTER APPLY (SELECT * FROM #Event_SetupEventQualification WHERE ForDownlinesOnly = 0) AS C
							CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
		
					CREATE INDEX IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef(PK_Distributor);

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 8 AND [StepSubGroup] = 1;


				INSERT INTO #TimeLog VALUES ('[tmp].[DSQualDef] uplines', 8, 2, GETUTCDATE(), NULL);

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
					WHERE [StepGroup] = 8 AND [StepSubGroup] = 2;
										
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
					WHERE [StepGroup] = 8 AND [StepSubGroup] = 2;
			END
		END
		
		--Step 9:  Bonuses / DSPointsSummary	
		IF @Step >= 9
		BEGIN
			
			PRINT 'Executing step 9'

			------------------------------------------------------------------------------------------------
			-- 9.1 Assigning bonuses
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints_Summary assigning bonuses', 9, 1, GETUTCDATE(), NULL);
			
			DELETE FROM #Event_DSPoints_Summary
			 
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
			WHERE [StepGroup] = 9 AND [StepSubGroup] = 1;

			INSERT INTO #TimeLog VALUES ('#tmp_DSPointsSummary', 9, 2, GETUTCDATE(), NULL);

			DELETE FROM #tmp_DSPointsSummary
				 
			INSERT INTO #tmp_DSPointsSummary([PK_Event],PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,iSPQualDate,[QSVolume],[Countries])
			SELECT 
					@PK_Event AS PK_Event,
					P.PK_Distributor,
					MIN(P.RoyaltyMonth) RoyaltyMonth,
					P.MetricType,
					P.PK_Country,
					SUM(P.[Points]) + D.ASP2024TotalBonus + D.AWT2024TotalBonus AS [Points],
					P.QualificationNumber,
					P.Part,
					1 AS [Bonus],
					SUM(ISNULL(P.[Points],0)) + D.ASP2024TotalBonus + D.AWT2024TotalBonus AS [TotalPoints],
					P.iStartDate,
					P.iEndDate,
					iSPQualDate,
					[QSVolume],
					[Countries]
				FROM #Event_DSPoints_Summary AS P WITH (NOLOCK)
				LEFT JOIN #DS D ON P.PK_Distributor = D.PK_Distributor
				GROUP BY P.PK_Distributor,P.MetricType,P.PK_Country,P.QualificationNumber,P.Part,P.iStartDate,P.iEndDate,iSPQualDate,D.ASP2024TotalBonus,D.AWT2024TotalBonus,[QSVolume],[Countries]

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 9 AND [StepSubGroup] = 2;

			INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary]', 9, 3, GETUTCDATE(), NULL);

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
				WHERE [StepGroup] = 9 AND [StepSubGroup] = 3;

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
				WHERE [StepGroup] = 9 AND [StepSubGroup] = 3;

			END

		END	

		--Step 10: Uplines Qualifiers by volume
		IF @Step >= 10
		BEGIN
			
			PRINT 'Executing step 10'

			------------------------------------------------------------------------------------------------
			-- 10.1 Getting qualifiers by volume according to qualification definitions
			------------------------------------------------------------------------------------------------
			INSERT INTO #TimeLog VALUES ('Upline Qualifiers by volume', 10, 1, GETUTCDATE(), NULL);

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
				FROM #Event_SetupEventQualification WHERE [ForDownlinesOnly] = 0

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
					WHERE [StepGroup] = 10 AND [StepSubGroup] = 1;

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
					--SELECT * FROM ##DSQualPoints_jgue WHERE PK_Distributor = 2193220
					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 10 AND [StepSubGroup] = 1;
				END


				UPDATE #Executions
				SET Done = 1
				WHERE PK_Execution = @PK_Execution

				END
				
				INSERT INTO #TimeLog VALUES ('Upline Qualifiers by volume #Event_DSQualPoints', 10, 2, GETUTCDATE(), NULL);
				
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
			WHERE [StepGroup] = 10 AND [StepSubGroup] = 2;
		END

		--Step 11: Qualifications
		IF @Step >= 11
		BEGIN
			
			PRINT 'Executing step 11'

			INSERT INTO #TimeLog VALUES ('Qualifications', 11, 1, GETUTCDATE(), NULL);

			INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q40)
				SELECT 
					PK_Distributor,
					@PK_Event AS [PK_Event],
					IIF(d.DSSPTeam = 'SP'		 ,1,0)			AS Q01, -- FQS and Above
					d.IsTicketPurchaser							AS Q40  -- Have a ticket 
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
			WHERE [StepGroup] = 11 AND [StepSubGroup] = 1;

		END
			
		--Step 12: Subevents
		IF @Step >= 12
		BEGIN

			PRINT 'Executing step 12'

			INSERT INTO #TimeLog VALUES ('Es #EventQual', 12, 1, GETUTCDATE(), NULL);
				
				UPDATE 
					#EventQual
				SET
					E04 = ((Q01 & Q04) | Q08)

				UPDATE
					#EventQual
				SET
					E03 = ((Q01 & Q03 & ~E04) | Q07)

				UPDATE
					#EventQual
				SET
					E02 = ((Q01 & Q02 & ~E04 & ~E03) | Q06)
							
				UPDATE 
					#EventQual
				SET
					E01 =  (E02 | E03 | E04 | Q05)
				

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
			WHERE [StepGroup] = 12 AND [StepSubGroup] = 1;

		END

		--Step 13: [Event].[DSQual]	
		IF @Step >= 13
		BEGIN
			
			PRINT 'Executing step 13';

			INSERT INTO #TimeLog VALUES ('[Event].[DSQual]', 13, 1, GETUTCDATE(), NULL);

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
		
				--WRK_PhilippinesVacation_2024
				DROP TABLE IF EXISTS dbo.WRK_PhilippinesVacation_2024 

				SELECT 
					PK_Distributor		
					,DistributorID		  
					,DSCurrentTeam		       
					,DSSubTeam			       
					,DSSPTeam			              
					,dSPQualDate			       
					,CountryCode			
					,IsFromList			
					,IsTicketPurchaser	
					,IsFromCOP	
					,TVP	
					,IsAWT2024			
					,ASP2024DLQualifiers
					,AWT2024DLQualifiers 
				INTO dbo.WRK_PhilippinesVacation_2024  
				FROM #DS 
						
				CREATE INDEX [IX_WRK_PhilippinesVacation_2024_PK_Distributor] ON [dbo].[WRK_PhilippinesVacation_2024] ([PK_Distributor])

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

				--WRK_PhilippinesVacation_2024
				DROP TABLE IF EXISTS dbo.#WRK_PhilippinesVacation_2024 

				SELECT 
					PK_Distributor		
					,DistributorID		  
					,DSCurrentTeam		       
					,DSSubTeam			       
					,DSSPTeam			              
					,dSPQualDate			       
					,CountryCode			
					,IsFromList			
					,IsTicketPurchaser	
					,IsFromCOP	
					,TVP	
					,IsAWT2024			
					,ASP2024DLQualifiers
					,ASP2024TotalBonus
					,AWT2024DLQualifiers 
					,AWT2024TotalBonus
				INTO dbo.#WRK_PhilippinesVacation_2024  
				FROM #DS 
						
				CREATE INDEX [IX_#WRK_PhilippinesVacation_2024_PK_Distributor] ON [dbo].[#WRK_PhilippinesVacation_2024] ([PK_Distributor])
			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 13 AND [StepSubGroup] = 1;

		END

		--Step 14: SubEventQualifiers
		IF @Step >= 14 
		BEGIN

			INSERT INTO #TimeLog VALUES ('SubEventQualifier', 14, 1, GETUTCDATE(), NULL);

			IF @IsDevQA = 0
			BEGIN

				PRINT 'Executing step 14'
		
				DECLARE @Events VARCHAR(MAX)
				
				SELECT @Events = STRING_AGG(PK_Event,',') FROM #Locations

				EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
				@Events = @Events,
				@Source = 2,
				@EvaluateFormula = 0

			END

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 14 AND [StepSubGroup] = 1;

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