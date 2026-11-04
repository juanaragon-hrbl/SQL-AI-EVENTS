CREATE PROCEDURE [dbo].[usp_EventQual_APAC_FPTR_RoyaltyUniversity_Oct2026]
	@Parameters NVARCHAR(MAX) = NULL
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_APAC_FPTR_RoyaltyUniversity_Oct2026

	USE:		

			USE [PubEventManagement]
			GO
			 
			DECLARE @e int, @em varchar(4000), @param nvarchar(max)
			
			SET @param = N'{
			        "step":11,
					"currentDatetime": null,
				    "pkEventLog":205543,
					"execLog":1,
				    "cleanUpTempData":0,
					"eligibleCountries":"AS,HK,ID,JP,KH,KS,MC,MY,NZ,RP,SN,TH,TW,VN",
					"pkEvent":205543,					
					
					"freezeMTQualDateEnd":"2026-10-01",
					"newSPDownlinesStart":"2025-11-01",
					"newSPDownlinesEnd":"2026-10-01"
					}'

			UPDATE [Shared].[QualsExecParams]
			SET [Parameters] = @param
				WHERE PK_Event = 205543

			EXEC dbo.usp_EventQual_APAC_FPTR_RoyaltyUniversity_Oct2026 @Error = @e OUTPUT, @ErrorMessage = @em OUTPUT 
			
			SELECT @e AS [Error], @em AS [ErrorMessage]
			GO


	DESCRIPTION: 

	NOTES:	
		
	OUTPUT TABLES:
		[tmp].[DS]	
		[tmp].[DSQualDef]
		[tmp].[DSPointsSummary] 
		[tmp].[DSSummary] 

		[Event].[DSPoints]
		[Event].[DSQualPoints]
		[Event].[DSQual]
		[Event].[SetupEventQualification] 
		[Shared].[ExtensionQualification]
		[Shared].[QualsExecParams]

	TEMPORARY TABLES:
	

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
 
	WORK TABLES (WRK):
 	
	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2026-04-13	jairli		Initial    
	***********************************************************************************************************************************/

	SET NOCOUNT ON;

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
				
	SELECT @Error = 0, @ErrorMessage = '';	

	DECLARE @e int, @em varchar(4000)

BEGIN TRY

	DECLARE @ColumnToPivot NVARCHAR(MAX),
		@SqlStatement NVARCHAR(MAX)

	IF @Parameters IS NULL 	
	BEGIN
		PRINT 'Getting parameters from [Shared].[QualsExecParams] '
		SET @Parameters = (SELECT [Parameters] FROM [Shared].[QualsExecParams] WITH (NOLOCK) WHERE PK_Event = 205543)
	END

	PRINT '[Parameters]: ' + @Parameters  
 
	-- Variables for json values
	DECLARE
		--General
		 @PK_Event	INT 
		,@PK_Event_Log INT
		,@Step INT
		,@CurrentDatetime DATETIME
		,@CleanUpTempData BIT   
		,@EligibleCountries VARCHAR(MAX) 
				
		,@FreezeMTQualDateEnd DATE
		,@NewSPDownlinesStart DATE
		,@NewSPDownlinesEnd DATE
 
	-- Getting parameters values for json
	SELECT  
		@PK_Event = g.pkEvent, 
		@PK_Event_Log	= g.pkEventLog,
		@CleanUpTempData = g.cleanUpTempData, 
		@Step = g.step, 
		@CurrentDatetime	= g.currentDatetime,
		@EligibleCountries = g.eligibleCountries, 
				
		--Custom fields		
		@FreezeMTQualDateEnd 		= g.freezeMTQualDateEnd,
		@NewSPDownlinesStart 		= g.newSPDownlinesStart, 
		@NewSPDownlinesEnd 		    = g.newSPDownlinesEnd
		
	FROM OPENJSON(@Parameters)
	WITH (
			pkEvent INT '$.pkEvent',
			pkEventLog INT '$.pkEventLog',
			cleanUpTempData BIT '$.cleanUpTempData', 
			step INT '$.step', 
			currentDatetime DATETIME '$.currentDatetime',
			eligibleCountries  VARCHAR(MAX) '$.eligibleCountries',
						
			freezeMTQualDateEnd DATE '$.freezeMTQualDateEnd',
			newSPDownlinesStart DATE '$.newSPDownlinesStart',
			newSPDownlinesEnd DATE '$.newSPDownlinesEnd'
	) AS g
 
	-- Default values
	SET @PK_Event = IIF(@PK_Event IS NULL,205543, @PK_Event)	
	SET @Step = IIF(@Step IS NULL,11, @Step)
	SET @CurrentDatetime = IIF(@CurrentDatetime IS NULL,GETDATE(), @CurrentDatetime)

	SELECT 
		@PK_Event					AS [PK_Event],
		@PK_Event_Log				AS [PK_Event_Log],
		@CleanUpTempData			AS [CleanUpTempData],
		@Step						AS [Step], 
		@CurrentDatetime			AS [CurrentDatetime],
		@EligibleCountries			AS [EligibleCountries], 
				
		@FreezeMTQualDateEnd		AS [FreezeMTQualDateEnd],
		@NewSPDownlinesStart		AS [NewSPDownlinesStart],
		@NewSPDownlinesEnd			AS [NewSPDownlinesEnd]
		
	------------------------------------------------------------------------------------------------
	-- Tables and variables
	------------------------------------------------------------------------------------------------
	BEGIN 	

		--Variables for logging
		DECLARE @ExecLog bit = 1
		,@PK_TimeLog1 datetime2
		,@StepGroup int					-- StepGroup
		,@StepSubGroup int				-- StepSubGroup
		,@Milestone varchar(255)		-- Milestone
		,@RowCount bigint = NULL

		DECLARE 
			@iStartDate int,
			@dStartDate datetime,
			@iEndDate int,
			@dEndDate datetime,
			@DSCountries VARCHAR(MAX),
			@MetricType VARCHAR(MAX) 
			
		DROP TABLE IF EXISTS #LocationMapping

		CREATE TABLE #LocationMapping
		(			
			[PK_Event] [int], 
			[CountryCode]	varchar(20), 
			[CountryName] nvarchar(max),
			[PK_Country] [int],
			[ctrl] [bit] DEFAULT(0)
		)

		;WITH 
			cte_L1 AS ( SELECT @PK_Event AS [PK_Event], c.nCountryID AS PK_Country,c.sCountryName AS [CountryName], c.sCountryCode AS [CountryCode] FROM string_split(@EligibleCountries,',') AS cc INNER JOIN  v_Countries AS c ON TRIM(cc.[value]) = sCountryCode) 
		
		INSERT INTO #LocationMapping([PK_Event],[CountryCode],[CountryName],[PK_Country])
			SELECT [PK_Event],[CountryCode],[CountryName],PK_Country FROM cte_L1  

		DROP TABLE IF EXISTS #LocationEventID

		SELECT DISTINCT [PK_Event] INTO #LocationEventID FROM #LocationMapping	
		

		DROP TABLE IF EXISTS #ListsQsMapping

		CREATE TABLE #ListsQsMapping
		(
			ID INT IDENTITY(1,1),
			PK_Event INT,
			ListID INT,
			QId INT
		)
		
		INSERT INTO #ListsQsMapping(PK_Event,ListID,QId)
		SELECT eq.PK_Event, eq.QualificationValue,eq.QualificationNumber 
		FROM [Shared].[ExtensionQualification] AS eq WITH (NOLOCK) 
			INNER JOIN #LocationEventID AS l
				ON eq.PK_Event = l.PK_Event
		AND QualificationType = 'List'		
		
		DROP TABLE IF EXISTS #TimeLog;  

		CREATE TABLE #TimeLog(
			[Milestone]		varchar(255)
			,[StepGroup]	tinyint
			,[StepSubGroup] tinyint
			,[StepStart]	datetime2
			,[Duration]		int
		);		
		

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
			[PeriodType]			tinyint, -- 1 Fixed period, 2 Relative period base on SPQualDate
			[MetricTypeDefinition]	VARCHAR(50) NULL
		)
 
		IF @IsDevQA = 0
		BEGIN	
		 
			INSERT INTO #Event_SetupEventQualification(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
			SELECT seq.PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition 
			FROM [Event].[SetupEventQualification] AS seq WITH (NOLOCK)
				INNER JOIN #LocationEventID AS lm
					ON seq.PK_Event = lm.PK_Event
		END
		 				
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
		
	--Quals block
	BEGIN 
		
		DECLARE @PK_EventMultiLocation VARCHAR(MAX) = (SELECT STRING_AGG(PK_Event,',') FROM #LocationEventID)

		IF @CleanUpTempData = 1 EXEC [Shared].[usp_CleanUp_TempData] @IsDevQA = 0 
	 
		IF (@IsDevQA = 2)
		BEGIN
			PRINT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1 
		END
		
		--Step 1: DS
		IF @Step >= 1 
		BEGIN

			PRINT 'Executing step 1'

			SELECT @StepGroup = 1, @StepSubGroup = 1, @Milestone = 'Getting Distributors from eligible countries';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

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
					WHERE sCountryCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar](@EligibleCountries, ','))

				DROP TABLE IF EXISTS #DS

				CREATE TABLE #DS
				(
				    PK_Event				int,
					PK_Distributor			int,   
					DSCurrentTeam			varchar(10), 
					DSFreezeTeam			varchar(10),  					
					DSSubTeam				varchar(10),      
                    DSFreezeSubTeam			varchar(10), 		
					DSSPTeam				varchar(10),               
					dSPQualDate				datetime2,
					dSPRequalDate			datetime2,
					dSPDemotion				datetime2,
					QSQualDate				smalldatetime,		
					QSActualQualDate		smalldatetime,	
					CountryCode				varchar(5),
					IsFromList				bit default(0),
					IsTicketPurchaser		bit default(0), 
					Q10						bit
					
					--
					,NewWTQualDate		date default '1900-01-01'	
					,ReqWTQualDate		date default '1900-01-01'		
				)

				INSERT INTO #DS
				(
				    PK_Event,
					PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,
					dSPRequalDate,
					dSPDemotion,
					QSQualDate,
					QSActualQualDate,
					CountryCode,
					Q10
				)
				SELECT DISTINCT   
                l.PK_Event,				
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				D.dSupervisorqualification AS dSPQualDate,    
				d.dSupervisorReQualification AS dSPRequalDate,
				D.dSPDemotion AS dSPDemotion, 
				D.dQSQualification AS dQSQualification,				
				D.dQSQualification_Actual AS dQSQualification_Actual,
				D.sDistributorCountryProcessingCode AS CountryCode,
				1 AS [Q10]
				FROM        
				dbo.v_Distributor AS D  
					INNER JOIN #LocationMapping AS l
						ON D.nDistributorCountryProcessingID = l.PK_Country				
				WHERE        
					D.StatusCode = 'COMPLETE' 			
				    ---AND D.sType = 'SP'
 
				CREATE INDEX IX_#DS_PK_Distributor ON #DS(PK_Distributor);

			SELECT @StepGroup = 1, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 


		END
		
		--Step 2: List and SKUs and EventQual
		IF @Step >= 2 
		BEGIN

			PRINT 'Executing step 2'

			SELECT @StepGroup = 2, @StepSubGroup = 1, @Milestone = 'Getting Distributors from list';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

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
				    PK_Event,
					PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,		
					dSPQualDate,		
					dSPRequalDate,
					dSPDemotion,
					QSQualDate,
					QSActualQualDate,
					CountryCode,				
					IsFromList
				)
				SELECT DISTINCT    
                L.PK_Event,				
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate, 
				d.dSupervisorReQualification AS dSPRequalDate,
				D.dSPDemotion AS dSPDemotion, 
				D.dQSQualification AS dQSQualification,				
				D.dQSQualification_Actual AS dQSQualification_Actual,
				D.sDistributorCountryProcessingCode AS CountryCode,
				1 AS IsFromList
				FROM dbo.v_Distributor AS D  
					INNER JOIN #DSList AS L
						ON D.nDistributorID = L.PK_Distributor
				WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = L.PK_Distributor AND T.PK_Event = L.PK_Event)

				UPDATE D
				SET IsFromList = 1
				FROM #DS AS D  
					INNER JOIN #DSList AS L
						ON D.PK_Distributor = L.PK_Distributor

			SELECT @StepGroup = 2, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

			SELECT @StepGroup = 2, @StepSubGroup = 2, @Milestone = 'Getting Distributors with SKU';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

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
						INNER JOIN #LocationEventID AS l
						ON s.PK_Event = l.PK_Event

				INSERT INTO #DSSKUs(PK_Distributor,PK_EventSKU,PK_Event,SKUCode,UniqueID)
				SELECT DISTINCT et.PK_Distributor_Purchaser,esku.PK_EventSKU, s.PK_Event, esku.SKUCode ,CAST(l.PK_Event AS NVARCHAR(20)) + '-' + CAST(et.PK_Distributor_Purchaser AS NVARCHAR(20))+ '-'+ CAST(esku.SKUCode  AS NVARCHAR(20))  AS UniqueID 
				FROM #SKUs AS s 
					INNER JOIN dbo.EventSKU AS esku WITH (NOLOCK)
						ON s.SKUCode = esku.SKUCode
					INNER JOIN [dbo].[SKUPurchased] et WITH (NOLOCK)
						ON et.PK_EventSKU = esku.PK_EventSKU
					INNER JOIN #LocationEventID AS l
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
					dSPRequalDate,
					dSPDemotion,
					QSQualDate,
					QSActualQualDate,
					CountryCode,
					IsTicketPurchaser
				)
				SELECT DISTINCT   
                S.PK_Event,				
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,       
				D.dSupervisorqualification AS dSPQualDate,   
				d.dSupervisorReQualification AS dSPRequalDate,
				d.dSPDemotion AS dSPDemotion,
				D.dQSQualification AS dQSQualification,				
				D.dQSQualification_Actual AS dQSQualification_Actual,
				D.sDistributorCountryProcessingCode AS CountryCode,
				1 AS IsTicketPurchaser
				FROM dbo.v_Distributor AS D  
					INNER JOIN #DSSKUs AS S
						ON D.nDistributorID = S.PK_Distributor
				WHERE NOT EXISTS (SELECT 1 FROM #DS AS T WHERE T.PK_Distributor = S.PK_Distributor AND T.PK_Event = S.PK_Event)

				UPDATE D
				SET IsTicketPurchaser = 1
				FROM #DS AS D  
					INNER JOIN #DSSKUs AS S
						ON D.PK_Distributor = S.PK_Distributor

			SELECT @StepGroup = 2, @StepSubGroup = 2
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 			

		END
		
		--Step 2 (Extension): EventQual
		IF @Step >= 2
		BEGIN

			PRINT 'Executing step 2 (Extension)'

			SELECT @StepGroup = 2, @StepSubGroup = 3, @Milestone = 'Getting qualifications';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
			
			
				--DSSNAPSHOT

				DROP TABLE IF EXISTS #DSSNAPSHOT

				SELECT
					DSN.PK_Distributor,
					DSN.ROYALTYMONTH,
					DSN.SUBTYPECODE,
					DSN.TEAMCODE,
					ROW_NUMBER() OVER (PARTITION BY DSN.PK_Distributor ORDER BY ROYALTYMONTH DESC) row_num
				INTO #DSSNAPSHOT
				FROM #DS AS d
					INNER JOIN [PubEventManagement].[Shared].[DSSNAPSHOT] AS DSN WITH (NOLOCK)
						 ON d.PK_Distributor = DSN.PK_Distributor	
                WHERE RoyaltyMonth BETWEEN CAST(CONVERT(varchar(6), DATEADD(MONTH, -1, @FreezeMTQualDateEnd), 112) AS int)
									AND CAST(CONVERT(varchar(6), @FreezeMTQualDateEnd, 112) AS int)
                    ---AND DSN.TEAMCODE IN ('M','P')	
				ORDER BY PK_Distributor,ROYALTYMONTH DESC
				
				IF (SELECT COUNT(1) FROM #DSSNAPSHOT) > 0 AND CAST(@CurrentDatetime AS DATE) >= @FreezeMTQualDateEnd
				BEGIN
					UPDATE D
					SET 
						[DSFreezeSubTeam] = w.[SUBTYPECODE],
						[DSFreezeTeam] = w.[TEAMCODE]					
					FROM #DS AS D
					INNER JOIN #DSSnapshot AS w
						ON D.PK_Distributor = w.PK_DISTRIBUTOR
						AND row_num = 1
                        		
				END
				

			SELECT @StepGroup = 2, @StepSubGroup = 3
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 


			SELECT @StepGroup = 2, @StepSubGroup = 4, @Milestone = '#EventQual';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

			INSERT INTO #EventQual(PK_Distributor,PK_Event, Q10)
				SELECT 
					PK_Distributor,
					d.PK_Event AS [PK_Event] ,
					d.Q10
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
						 
				 
	 			UPDATE q
					SET	Q01 = IIF(d.DSSPTeam = 'SP' ,1,0),																									-- Q01: FQS and above                        						
						Q02 = IIF(CAST(@CurrentDatetime AS DATE) < @FreezeMTQualDateEnd, IIF(d.DSCurrentTeam IN ('M','P','A','B','C'),1,0), IIF(d.DSFreezeTeam IN ('M','P','A','B','C'),1,0))		-- Q02:	MT and above								
				FROM #EventQual AS q
					INNER JOIN #DS AS d
						ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event							 
				  

			SELECT @StepGroup = 2, @StepSubGroup = 4
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

		END							
			
		--Step 3: Volume		
		IF @Step >= 3 
		BEGIN

			PRINT 'Executing step 3'

			------------------------------------------------------------------------------------------------
			-- 3.1 Getting values from #Event_SetupEventQualification
			------------------------------------------------------------------------------------------------
			
			SELECT @StepGroup = 3, @StepSubGroup = 1, @Milestone = 'Getting values from #Event_SetupEventQualification';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

				SELECT 
					@iStartDate = CAST(CONVERT(varchar(6),MIN(dStartDate), 112) AS int), 
					@dStartDate = MIN(dStartDate),
					@iEndDate = CAST(CONVERT(varchar(6),MAX(dEndDate), 112) AS int),
					@dEndDate = MAX(dEndDate),
					@MetricType = STRING_AGG([MetricType], ','),
					@DSCountries = STRING_AGG([Countries],',')
				FROM #Event_SetupEventQualification AS s WITH (NOLOCK)
				
				;WITH cte_MetricType AS (SELECT DISTINCT TRIM([value]) AS [metric] FROM STRING_SPLIT(@MetricType,','))
				 
				 SELECT @MetricType = STRING_AGG([metric],',') FROM cte_MetricType
				 

				-- Result set 
				SELECT @iStartDate AS [iStartDate],@dStartDate AS [dStartDate],@iEndDate AS [iEndDate],@dEndDate AS [dEndDate],@DSCountries AS [DSCountries],@MetricType AS [MetricType]
				 
			SELECT @StepGroup = 3, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

				------------------------------------------------------------------------------------------------
				-- 3.2 Getting #tmp_DS
				------------------------------------------------------------------------------------------------
			
				SELECT @StepGroup = 3, @StepSubGroup = 2, @Milestone = 'Getting #tmp_DS';
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

					DROP INDEX IF EXISTS IX_#tmp_DS_PK_Distributor ON #tmp_DS;
					DELETE #tmp_DS WHERE PK_Event = @PK_Event

					INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate])
					SELECT DISTINCT
						D.PK_Event AS [PK_Event],
						D.PK_Distributor AS PK_Distributor,
						DD.sDistributorID AS DistributorID,
						@iStartDate AS [iStartDate],
						@iEndDate AS [iEndDate],
						@dStartDate AS [dStartDate],
						@dEndDate AS [dEndDate],
						DD.dSupervisorQualification 
					FROM #DS AS D
					INNER JOIN v_Distributor AS DD
						ON D.PK_Distributor = DD.nDistributorID				 
				 
					CREATE INDEX IX_#tmp_DS_PK_Distributor ON #tmp_DS(PK_Distributor);	

					IF (@IsDevQA = 0)
					BEGIN
						
						DROP INDEX IF EXISTS [IX_DS_PK_Distributor]
							ON [tmp].[DS];

						DELETE d FROM [tmp].[DS] AS d 
							INNER JOIN #LocationEventID AS lm
								ON d.PK_Event = lm.PK_Event
								
						INSERT INTO [tmp].[DS]([PK_Event],[PK_Distributor],[StartDate],[EndDate])
						SELECT 
							D.[PK_Event],
							D.PK_Distributor,
							D.[iStartDate],
							D.[iEndDate]
						FROM #tmp_DS AS D 
											 
						CREATE INDEX IX_DS_PK_Distributor ON [tmp].[DS](PK_Distributor) INCLUDE(PK_Event);

					END
					
				SELECT @StepGroup = 3, @StepSubGroup = 2
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

				------------------------------------------------------------------------------------------------
				-- 3.3 Getting [Event].[DSPoints]
				------------------------------------------------------------------------------------------------
			
				IF (@IsDevQA = 0)
				BEGIN
					
					SELECT @StepGroup = 3, @StepSubGroup = 3, @Milestone = 'Getting [Event].[DSPoints]';
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
					
					--Input
					--[tmp].[DS]
					--[Event].[SetupEventQualification]
					
					PRINT CONCAT('Getting volumen for: ', @PK_EventMultiLocation);

					--SourceType 1: Getting points from PubEvents.[dbo].[factDSFinancial_ctry], includes divorce and tranfer cases.
					--SourceType 2: Getting points from PubEvents.dbo.factdsfinancial_PHX
					--SourceType 3: Getting points from [PubEventManagement].[dbo].[v_aggFQS_ID]
					EXEC dbo.usp_GetDSVolume @PK_Event = @PK_EventMultiLocation, @SourceType = 3,@QualFilter = NULL, @KeepNegativeVolume =0, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
					--Output 
					-- [Event].[DSPoints]
					-- [tmp].[DSSummary] 

					IF @Error <> 0
					BEGIN
						SET @Error = @Error
						SET @ErrorMessage = @ErrorMessage
						RETURN;
					END

					SELECT @StepGroup = 3, @StepSubGroup = 3
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

		
				END
								
			------------------------------------------------------------------------------------------------
			-- 3.5 Getting #Event_DSPoints AND [dbo].[WRK_25069_DSPoints_Validations] 
			------------------------------------------------------------------------------------------------
		 
			SELECT @StepGroup = 3, @StepSubGroup = 5, @Milestone = 'Getting #Event_DSPoints ';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

				--Allocating volume for uplines.

				DELETE #Event_DSPoints WHERE PK_Event = @PK_Event

				DROP INDEX IF EXISTS [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints;
				DROP INDEX IF EXISTS [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints;

				IF @IsDevQA = 0
				BEGIN
					INSERT INTO #Event_DSPoints(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points],[Bonus])
					SELECT 
						PK_Distributor,
						p.[PK_Event],
						p.PK_Country,
						[RoyaltyMonth],
						MetricType,
						[PersonalPoints] AS [PersonalPoints],
						[TransferPoints] AS [TransferPoints],
						[MainPoints] AS [MainPoints], 
						ROUND([Points],2) AS [Points],
						Bonus
					FROM [Event].[DSPoints] AS p WITH (NOLOCK)
					INNER JOIN #LocationEventID AS lm
								ON p.PK_Event = lm.PK_Event
								
					SELECT @StepGroup = 3, @StepSubGroup = 6, @Milestone = 'Creating WRK_26061_DSPoints';
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

					DROP TABLE IF EXISTS [dbo].[WRK_26061_DSPoints] 
					
					SELECT 
						PK_Distributor,
						[PK_Event],
						PK_Country,
						[RoyaltyMonth],
						MetricType,
						[PersonalPoints],
						[TransferPoints],
						[MainPoints], 
						[Points],
						Bonus
					INTO [dbo].[WRK_26061_DSPoints] 
					FROM #Event_DSPoints

					CREATE INDEX IX_WRK_26061_DSPoints_PK_Distributor ON [dbo].[WRK_26061_DSPoints] (PK_Distributor);
					
					SELECT @StepGroup = 3, @StepSubGroup = 6
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
				

				END
				
			SELECT @StepGroup = 3, @StepSubGroup = 5
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
				
						
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

				SELECT @StepGroup = 4, @StepSubGroup = 1, @Milestone = 'Getting all qualification definition for each DS';
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

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
						FROM #DS AS D					
							LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
								ON D.PK_Distributor = M.PK_Distributor
							OUTER APPLY #Event_SetupEventQualification AS C WITH (NOLOCK)
							CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
		
					CREATE INDEX IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef(PK_Distributor);

				SELECT @StepGroup = 4, @StepSubGroup = 1
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

				IF @IsDevQA = 0
				BEGIN

					SELECT @StepGroup = 4, @StepSubGroup = 2, @Milestone = '[tmp].[DSQualDef] drop index';
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
					
					DROP INDEX IF EXISTS IX_tmp_DSQualDef_PK_Event ON [tmp].[DSQualDef];
					
					SELECT @StepGroup = 4, @StepSubGroup = 2
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
					
					SELECT @StepGroup = 4, @StepSubGroup = 3, @Milestone = '[tmp].[DSQualDef] delete';
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
					
					DELETE d 
						FROM [tmp].[DSQualDef] AS d
						INNER JOIN #LocationEventID AS lm
						ON d.PK_Event = lm.PK_Event
						
					SELECT @StepGroup = 4, @StepSubGroup = 3
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
					
					SELECT @StepGroup = 4, @StepSubGroup = 4, @Milestone = '[tmp].[DSQualDef] insert';
					IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

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

				SELECT @StepGroup = 4, @StepSubGroup = 4
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
									
			END  

		END
  
		--Step 5: [tmp].[DSPointsSummary]
		IF @Step >= 5
		BEGIN			

			PRINT 'Executing step 5'
 			 
			------------------------------------------------------------------------------------------------
			-- 5.8 #Event_DSPoints_Summary
			------------------------------------------------------------------------------------------------
		 
			SELECT @StepGroup = 5, @StepSubGroup = 1, @Milestone = '#Event_DSPoints_Summary';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
			
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
					[MonthIndex] [int]
				)

				INSERT INTO #Event_DSPoints_Summary(PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries,[MonthIndex])
					SELECT U.PK_Distributor,
							U.RoyaltyMonth,
							U.MetricType,
							U.PK_Country AS PK_Country,
							IIF((F.[QSVolume] = 0 AND U.RoyaltyMonth >= F.iSPQualDate) OR F.[QSVolume] IS NULL, SUM(ISNULL(U.Points,0)),0) AS [Points],  
							F.[QSVolume], 
							F.iSPQualDate,
							F.QualificationNumber,
							F.Part,
							F.iStartDate,
							F.iEndDate,
							F.Countries,
							ROW_NUMBER() OVER (PARTITION BY U.PK_Distributor,U.MetricType,U.PK_Country,F.QualificationNumber,F.Part,F.iStartDate ORDER BY U.RoyaltyMonth ASC) AS [MonthIndex]
					FROM [dbo].[WRK_26061_DSPoints]  AS U WITH (NOLOCK) 
					INNER JOIN #DS AS d
						ON U.PK_Distributor = d.PK_Distributor AND U.PK_Event = d.PK_Event
					INNER JOIN #tmp_DSQualDef AS F
						ON u.PK_Distributor = F.PK_Distributor	
						WHERE 
							F.PK_Event = U.PK_Event
							AND
							F.MetricType = U.MetricType 
							AND 
							U.RoyaltyMonth BETWEEN F.iStartDate AND F.iEndDate
							AND 
							(F.Countries IS NULL OR EXISTS (SELECT 1 FROM dbo.v_Countries AS C WHERE U.PK_Country = C.nCountryID AND sCountryCode IN (SELECT RTRIM(LTRIM(Val)) FROM dbo.udf_SplitString(F.Countries, ','))))
					GROUP BY U.PK_Distributor,U.RoyaltyMonth,U.MetricType,U.PK_Country,F.[QSVolume],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries
					
			SELECT @StepGroup = 5, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
  
			------------------------------------------------------------------------------------------------
			-- 5.10 [tmp].[DSPointsSummary]
			------------------------------------------------------------------------------------------------
		
			SELECT @StepGroup = 5, @StepSubGroup = 2, @Milestone = '[tmp].[DSPointsSummary]';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
			
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
					NULL AS [Bonus],
					ISNULL(P.[Points],0) AS [TotalPoints],
					P.iStartDate,
					P.iEndDate
				FROM #Event_DSPoints_Summary AS P WITH (NOLOCK) 

				IF @IsDevQA = 0
				BEGIN
			 
					DELETE t
					FROM [tmp].[DSPointsSummary] AS t
					INNER JOIN #LocationEventID AS l
							ON t.PK_Event = l.PK_Event

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
		
			SELECT @StepGroup = 5, @StepSubGroup = 2
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
 
		END

		--Step 6: Qualifiers by volume	
		IF @Step >= 6
		BEGIN
			
			PRINT 'Executing step 6'

			------------------------------------------------------------------------------------------------
			-- 6.1 Getting qualifiers by volume according to qualification definitions
			------------------------------------------------------------------------------------------------

			SELECT @StepGroup = 6, @StepSubGroup = 1, @Milestone = 'Getting qualifiers by volume according to qualification definitions';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
	
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
		
				UPDATE #Executions
				SET Done = 1
				WHERE PK_Execution = @PK_Execution

				END
					 
				IF @IsDevQA = 0	
				BEGIN			 
					INSERT INTO #Event_DSQualPoints(PK_Event,PK_Distributor,QualificationNumber,Part,QualDate)
					SELECT 
						PK_Event
						,PK_Distributor
						,QualificationNumber 
						,Part		
						,QualDate
					FROM [Event].[DSQualPoints] AS Q WITH (NOLOCK)
					WHERE PK_Event = @PK_Event
				END

			SELECT @StepGroup = 6, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
 
		END
	 
		--Step 7: Qualifications
		IF @Step >= 7
		BEGIN
			
			PRINT 'Executing step 7'

			SELECT @StepGroup = 7, @StepSubGroup = 1, @Milestone = 'Qualifications';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
		 
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
			-- Custom qualifications
			------------------------------------------------------------------------------------------------
			BEGIN
			
			    ---Achieve First level FQS, where FQS date = Nov 1, 2025 to Oct 1, 2026
				
				DROP TABLE IF EXISTS #DSDownlines

				SELECT D.PK_Distributor, V.PK_DSDownline
				INTO #DSDownlines
				FROM #DS AS D WITH (NOLOCK)
				INNER JOIN v_dimDSLngDownline AS V WITH (NOLOCK)
					ON D.PK_Distributor = V.PK_Distributor
					AND DSLevelFromUL = 2			
				
				CREATE INDEX IX_#DSDownlines_PK_Distributor ON #DSDownlines(PK_Distributor)

				DROP TABLE IF EXISTS #DSAssociatedDownlines

				SELECT DISTINCT
					DA.PK_Distributor,
					DA.PK_AssociatedID,
					DL.PK_DSDownLine,
					DA.nMainDistributorID,
					DA.AssociationType
				INTO #DSAssociatedDownlines
				FROM #DS AS D --Uplines 
				INNER JOIN [Shared].[DistributorAssociation] AS DA WITH (NOLOCK)
					ON D.PK_Distributor = DA.PK_Distributor
				INNER JOIN dbo.v_dimDSLngDownline AS DL
					ON DA.PK_AssociatedID = DL.PK_Distributor
				WHERE DL.DSLevelFromUL = 2 
					AND DA.PK_AssociatedID = DA.nMainDistributorID 
				
				DROP TABLE IF EXISTS #DSDownlinesSummary

				CREATE TABLE #DSDownlinesSummary (PK_Distributor INT,PK_DSDownLine INT,PK_AssociatedID INT,nMainDistributorID INT,AssociationType INT)

				INSERT INTO #DSDownlinesSummary(PK_Distributor,PK_DSDownLine)
				SELECT DISTINCT
					D.PK_Distributor,
					D.PK_DSDownLine
				FROM #DSDownlines AS D
     
				INSERT INTO #DSDownlinesSummary(PK_Distributor,PK_DSDownLine,PK_AssociatedID,nMainDistributorID,AssociationType)
				SELECT DISTINCT
					A.PK_Distributor,
					A.PK_DSDownLine,
					PK_AssociatedID,
					nMainDistributorID,
					AssociationType
				FROM #DSAssociatedDownlines AS A
				WHERE NOT EXISTS (SELECT 1 FROM #DSDownlinesSummary AS S WHERE A.PK_Distributor = S.PK_Distributor AND A.PK_DSDownline = S.PK_DSDownLine)

				CREATE INDEX IX_#DSDownlinesSummary_PK_Distributor ON #DSDownlinesSummary(PK_Distributor) INCLUDE (PK_DSDownLine)
			
				DROP TABLE IF EXISTS #NewSPDownlines

				SELECT DD.PK_Distributor,DD.PK_DSDownLine, F.dSupervisorQualification
				INTO #NewSPDownlines
				FROM #DSDownlinesSummary AS DD
				INNER JOIN v_Distributor AS F
					ON F.nDistributorID =  DD.PK_DSDownline
					AND (F.dSupervisorQualification BETWEEN @NewSPDownlinesStart AND @NewSPDownlinesEnd
					AND (F.dSPDemotion = '1900-01-01' OR F.dSPDemotion IS NULL)
					AND F.sType = 'SP')		
					
				DROP TABLE IF EXISTS #AccDownlines

				SELECT PK_Distributor, COUNT(PK_DSDownline) AS ContributorsCount
				INTO #AccDownlines
				FROM #NewSPDownlines
				GROUP BY PK_Distributor	
					

				--Q05 Achieve 3 new first level FQS, where FQS date = Nov 1, 2025 to Oct 1, 2026                		

				DROP TABLE IF EXISTS #Q05

				SELECT DISTINCT PK_Distributor
				INTO #Q05
				FROM #AccDownlines
				WHERE ContributorsCount = 3

				CREATE INDEX IX_#Q05_PK_Distributor ON #Q05(PK_Distributor)	

				UPDATE E
				SET 
					Q05 = 1
				FROM #EventQual AS E
				INNER JOIN #Q05 AS Q05
					ON E.PK_Distributor = Q05.PK_Distributor	

				--Q06 Achieve 4 new first level FQS, where FQS date = Nov 1, 2025 to Oct 1, 2026	

				DROP TABLE IF EXISTS #Q06

				SELECT DISTINCT PK_Distributor
				INTO #Q06
				FROM #AccDownlines
				WHERE ContributorsCount = 4

				CREATE INDEX IX_#Q06_PK_Distributor ON #Q06(PK_Distributor)	

				UPDATE E
				SET 
					Q06 = 1
				FROM #EventQual AS E
				INNER JOIN #Q06 AS Q06
					ON E.PK_Distributor = Q06.PK_Distributor	

				--Q07 Achieve 5 new first level FQS, where FQS date = Nov 1, 2025 to Oct 1, 2026	

				DROP TABLE IF EXISTS #Q07

				SELECT DISTINCT PK_Distributor
				INTO #Q07
				FROM #AccDownlines
				WHERE ContributorsCount >= 5

				CREATE INDEX IX_#Q07_PK_Distributor ON #Q07(PK_Distributor)	

				UPDATE E
				SET 
					Q07 = 1
				FROM #EventQual AS E
				INNER JOIN #Q07 AS Q07
					ON E.PK_Distributor = Q07.PK_Distributor	


				IF @IsDevQA = 0
				BEGIN
					DROP TABLE IF EXISTS [dbo].[WRK_26061_NewFQSContributors] 
					
					SELECT 
						NSP.[PK_Distributor],
						@PK_Event PK_Event,
						[PK_DSDownLine],
						[dSupervisorQualification] AS [ContributionDate],
						[ContributorsCount]
					INTO [dbo].[WRK_26061_NewFQSContributors] 
					FROM #NewSPDownlines NSP
					INNER JOIN #AccDownlines A ON NSP.PK_Distributor = A.PK_Distributor
					                           AND A.ContributorsCount >= 3

					CREATE INDEX IX_WRK_26061_NewFQSontributors ON [dbo].[WRK_26061_NewFQSContributors] (PK_Distributor);	
				END
					
				
				--Q08	2025 HPL qualifiers Qualified to E1 or E 2 of the "25047 - WW - Premier League Program 2025" (PK ID 202477) From Jan 2025 to Jan 2026

				DROP TABLE IF EXISTS #Q08

				;WITH cte_PremierLeague_Qualifiers_2025 AS
				(
					SELECT DISTINCT PK_Distributor FROM Promo.WRK_HPL2025_SubEvent WHERE ContributingYear = 2025 AND SubEvent IN (1,2) AND DateQualified BETWEEN 202501 AND 202601	
                    UNION
					SELECT DISTINCT PK_Distributor FROM Promo.WRK_HPL2025_SubEvent AS plq (NOLOCK) -- Replace this with the HPL 2026 table
						WHERE ContributingYear = 2026 AND SubEvent IN (1,2) AND DateQualified BETWEEN 202601 AND 202610				
				)

				SELECT DISTINCT d.PK_Distributor
				INTO #Q08
				FROM #DS AS d
					INNER JOIN cte_PremierLeague_Qualifiers_2025 AS plq
						ON d.PK_Distributor = plq.PK_Distributor 

				 CREATE INDEX IX_#Q08_PK_Distributor ON #Q08(PK_Distributor);

				 UPDATE E
				 SET 
					 Q08 = 1
				 FROM #EventQual AS E
					INNER JOIN #Q08 AS Q08
					ON E.PK_Distributor = Q08.PK_Distributor	
					
					
				--Q09 2026 HPL qualfiers Qualified to E1 or E2 of the " - WW HPL 2026" (PK ID ) from Jan 2026 to Oct 2026
				DROP TABLE IF EXISTS #Q09

				SELECT DISTINCT D.PK_Distributor
				INTO #Q09
				FROM #DS D
				INNER JOIN	dbo.SubEventQualifier AS SQ (NOLOCK)
					ON SQ.PK_Distributor = D.PK_Distributor
				INNER JOIN dbo.SubEvent SE (NOLOCK)
					ON	SQ.PK_Event = SE.PK_Event 
						AND SQ.PK_SubEvent = SE.PK_SubEvent 
				WHERE 
					SE.PK_Event = 205086
				AND 
					SE.SubEventNumber IN (1,2)
				AND
					SQ.RemovedUTC = '2049-12-31'

				CREATE INDEX IX_#Q09_PK_Distributor ON #Q09(PK_Distributor)

				UPDATE E
					SET 
						Q09 = 1
					FROM #EventQual AS E
					INNER JOIN #Q09 AS Q09
					ON E.PK_Distributor = Q09.PK_Distributor
			END

			SELECT @StepGroup = 7, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
			
		END
		
		--Step 8: Subevents
		IF @Step >= 8
		BEGIN

			PRINT 'Executing step 8'
			
			DECLARE 
				@PK_SubEvent INT,
				@PK_EventSubEvent INT,
				@SubEventNumber VARCHAR(10),
				@SubEventFormula VARCHAR(MAX)

			SELECT @StepGroup = 8, @StepSubGroup = 1, @Milestone = 'Subevent qualification on #EventQual';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
		  
			DROP TABLE IF EXISTS #SubEventsFormula

			SELECT s.PK_Event
				,s.PK_SubEvent
				,s.SubEventNumber
				,CONCAT('E',(IIF(s.SubEventNumber<10, CONCAT('0',CAST(s.SubEventNumber AS VARCHAR(20))),CAST(s.SubEventNumber AS VARCHAR(20))))) AS SubEventNumberCode
				,s.SubEventFormula
				,ROW_NUMBER() OVER(ORDER BY s.PK_Event,s.SubEventNumber ASC) AS [Order]
				,CAST(0 AS BIT) AS ctrl
			INTO #SubEventsFormula
			FROM [SubEvent] AS s WITH (NOLOCK) 
				INNER JOIN #LocationEventID AS l
					ON s.PK_Event = l.PK_Event 
			WHERE SubEventFormula IS NOT NULL

			SET @SqlStatement = ''

			WHILE EXISTS (SELECT 1 FROM #SubEventsFormula AS se WHERE ctrl = 0)
			BEGIN
	
				SELECT TOP 1 @PK_SubEvent = PK_SubEvent FROM #SubEventsFormula WHERE ctrl = 0 ORDER BY [Order] ASC
		
				SELECT 
					@PK_EventSubEvent = PK_Event,
					@SubEventNumber = SubEventNumberCode,
					@SubEventFormula = SubEventFormula
				FROM #SubEventsFormula WHERE PK_SubEvent = @PK_SubEvent

				SET @SqlStatement = 'UPDATE #EventQual SET' + SPACE(1) + @SubEventNumber + ' = ('  +  @SubEventFormula  + ') WHERE PK_Event = ' + CAST(@PK_EventSubEvent AS VARCHAR(MAX))

				PRINT @SqlStatement
				EXEC (@SqlStatement)

				UPDATE #SubEventsFormula
				SET ctrl = 1
				WHERE PK_SubEvent = @PK_SubEvent
		
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

			SELECT @StepGroup = 8, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
			
		END
	 

		--Step 10: [Event].[DSQual]	
		IF @Step >= 10
		BEGIN
			
			PRINT 'Executing step 10'

			SELECT @StepGroup = 10, @StepSubGroup = 1, @Milestone = '[Event].[DSQual] and [tmp].[DSQual]';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
		 
			IF @IsDevQA = 0
			BEGIN

				DELETE dq			
				FROM [Event].[DSQual] AS dq
					INNER JOIN #LocationEventID AS l
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
								
				--[tmp].[DSQual]  
				DROP TABLE IF EXISTS [tmp].[DSQual]  

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
				INTO [tmp].[DSQual]
				FROM #EventQual
				

				CREATE INDEX IX_tmp_DSQual_PK_Event ON [tmp].[DSQual](PK_Event);

				--[Event].[DSQualifications]
				DROP INDEX IF EXISTS IX_Event_DSQualifications_PK_Distributor ON [Event].[DSQualifications];

				DELETE dq FROM [Event].[DSQualifications] AS dq INNER JOIN #LocationEventID AS l
						ON dq.PK_Event = l.PK_Event

				INSERT INTO [Event].[DSQualifications](PK_Event, PK_Distributor, QId, [IsQualified],[DateQualified])
				SELECT PK_Event, PK_Distributor,CAST(TRIM(REPLACE(QId,'Q', SPACE(1))) AS INT)  AS QId, [value] AS [IsQualified], 
				CAST(FORMAT(CreatedDate, 'yyyyMM') AS INT) AS [DateQualified]  
				FROM (
					SELECT 
						 e.PK_Event		
						,PK_Distributor	
						,CreatedDate	
						,UpdatedDate	
						,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10			
							,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20
							,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30
							,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40
							,Q41,Q42,Q43,Q44,Q45,Q46,Q47,Q48,Q49,Q50	
 
					FROM #EventQual AS e INNER JOIN #LocationEventID AS l
						ON e.PK_Event = l.PK_Event) AS s  
					UNPIVOT
					(VALUE FOR QId IN (Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10			
							,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20
						,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30
						,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40
						,Q41,Q42,Q43,Q44,Q45,Q46,Q47,Q48,Q49,Q50					
						)) AS Q					 

				CREATE INDEX IX_Event_DSQualifications_PK_Distributor ON [Event].[DSQualifications](PK_Distributor) INCLUDE(PK_Event);

			END
	
			SELECT @StepGroup = 10, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
			
		END
		 
		--Step 11: SubEventQualifiers
		IF @Step >= 11 
		BEGIN
					
			PRINT 'Executing step 11'

			SELECT @StepGroup = 11, @StepSubGroup = 1, @Milestone = 'SubEventQualifiers ';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
		  
			IF @IsDevQA = 0 
			BEGIN
									
				EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
				@Events = @PK_EventMultiLocation,
				@Source = 2,
				@EvaluateFormula = 0					

			END

			SELECT @StepGroup = 11, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
				
		END 
	END
 
 
	/******************************************************************************
				END PROCEDURE
	******************************************************************************/
		
		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
		 	@StoredProcedureName = @StoredProcedure
		 	,@StartTime = @StartTime;		

END TRY
BEGIN CATCH
 	SET @Error = ERROR_NUMBER()
 	SET @ErrorMessage = ERROR_MESSAGE()
 	SET @StoredProcedure = ERROR_PROCEDURE()

 	-- UPDATE ERROR LOG
 	EXEC dbo.usp_Utility_UpdateErrorLog 
 			@ProcedureName = @StoredProcedure 
 			,@ErrorNumber = 3
 			,@ErrorMessage = @ErrorMessage
 			,@SQLErrorCode = @Error
 			,@SQLErrorMsg = @ErrorMessage
END CATCH;
END