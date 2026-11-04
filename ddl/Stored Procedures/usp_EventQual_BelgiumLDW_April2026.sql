CREATE PROCEDURE [dbo].[usp_EventQual_BelgiumLDW_April2026]
	@Parameters NVARCHAR(MAX) = NULL
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT
	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_BelgiumLDW_April2026

	USE:	
	
			USE [PubEventManagement]
			GO

			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			DECLARE @e int, @em varchar(4000), @param nvarchar(max)
			
			SET @param =  N'{
				"step":11,
				"currentDatetime": null,
				"pkEventLog":205434,
				"execLog":1,
				"cleanUpTempData":0,
				"eligibleCountries":"BE",	
				"pK_Event":205434,

				"fqsFirtTimeEver":1,
				"fqsRequalificationCount":0,

				"aWTQualDateStart":"2026-02-01",
				"aWTQualDateEnd":"2026-05-01",
				"aWTYear":2026,	
                "isNonTAB":0,				
				"requalifiedCount":1,
				
				"newSPDownlinesStart":"2025-02-01",
				"newSPDownlinesEnd":"2026-04-01",
				"signUpDateRangeStart":20260101,
				"signUpDateRangeEnd":20260331,
				
				"qualPeriodStartMonth1":"2026-01-01",
				"qualPeriodStartMonth2":"2026-02-01",
				"qualPeriodStartMonth3":"2026-03-01",
				 
				"newQPQualDateStart":"2025-10-01",
				"newQPQualDateEnd":"2026-03-01",
				"newSPQualDateStart":"2025-11-01",
				"newSPQualDateEnd":"2026-04-01"				
			}'

			UPDATE [Shared].[QualsExecParams]
			SET Parameters = @param
			WHERE ProjectID = 26077

			EXEC dbo.usp_EventQual_BelgiumLDW_April2026 @Parameters= @param, @IsDevQA = 0, @Error = @e OUTPUT, @ErrorMessage = @em OUTPUT 
			
			SELECT @e AS [Error], @em AS [ErrorMessage]

			GO


			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			DECLARE @e int, @em varchar(4000), @param nvarchar(max)
			 
			EXEC dbo.usp_EventQual_BelgiumLDW_April2026 @IsDevQA = 0, @Error = @e OUTPUT, @ErrorMessage = @em OUTPUT 
			
			SELECT @e AS [Error], @em AS [ErrorMessage]

			GO

	DESCRIPTION: 

	NOTES:	

	DEBUG TABLES:	
		
	DEPENDENCIES:
	
	WORK TABLES (WRK):

	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1.0.0	2026-03-23		jairli			Initial  
***********************************************************************************************************************************/

	
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
		
	DECLARE @ColumnToPivot NVARCHAR(MAX),
	@SqlStatement NVARCHAR(MAX)

	IF @Parameters IS NULL 	
	BEGIN
		PRINT 'Getting parameters from [Shared].[QualsExecParams] '
		SET @Parameters = (SELECT TOP 1 [Parameters] FROM [Shared].[QualsExecParams] WITH (NOLOCK) WHERE ProjectID = 26071)
	END

	PRINT '[Parameters]: ' + @Parameters  

	-- Variables for json values
	DECLARE  
		@Step INT, 	
		@CurrentDatetime DATETIME,		
		@PK_Event_Log INT,
		@ExecLog BIT,
		@CleanUpTempData BIT,
		@EligibleCountries VARCHAR(MAX),
		@PK_Event INT, 
		 
		@FQSFirtTimeEver BIT,
		@FQSRequalificationCount BIT,
 
		@AWTYear INT,
		@IsNonTAB BIT,
		@RequalifiedCount BIT,
		@AWTQualDateStart DATE,
		@AWTQualDateEnd DATE,

   
		@NewSPDownlinesStart DATE,
		@NewSPDownlinesEnd DATE,
		@SignUpDateRangeStart INT,
		@SignUpDateRangeEnd INT,
		
		@QualPeriodStartMonth1 DATE,
		@QualPeriodStartMonth2 DATE,
		@QualPeriodStartMonth3 DATE,
		
		@NewQPQualDateStart DATE,
		@NewQPQualDateEnd DATE,
		@NewSPQualDateStart DATE,
		@NewSPQualDateEnd DATE
		
	-- Getting parameters values for json
	SELECT   
		
		@Step 						= g.step,	
		@CurrentDatetime			= g.currentDatetime,
		@PK_Event_Log				= g.pkEventLog,
		@ExecLog					= g.execLog,
		@CleanUpTempData			= g.cleanUpTempData,
		@EligibleCountries 			= g.eligibleCountries, 
		@PK_Event 					= g.pK_Event,
		--Custom fields		 
		@FQSFirtTimeEver			= g.fqsFirtTimeEver,
		@FQSRequalificationCount	= g.fqsRequalificationCount,


		@AWTQualDateStart			= g.aWTQualDateStart, 
		@AWTQualDateEnd 			= g.aWTQualDateEnd, 	
		@AWTYear					= g.aWTYear,
		@IsNonTAB					= g.isNonTAB,
		@RequalifiedCount			= g.requalifiedCount,


        @NewSPDownlinesStart 		= g.newSPDownlinesStart, 
		@NewSPDownlinesEnd 		    = g.newSPDownlinesEnd,	
        @SignUpDateRangeStart 		= g.signUpDateRangeStart, 	
        @SignUpDateRangeEnd 		= g.signUpDateRangeEnd,

		@QualPeriodStartMonth1      = g.qualPeriodStartMonth1,
		@QualPeriodStartMonth2      = g.qualPeriodStartMonth2,
		@QualPeriodStartMonth3      = g.qualPeriodStartMonth3,
		
        @NewQPQualDateStart 		= g.newQPQualDateStart, 		
		@NewQPQualDateEnd 			= g.newQPQualDateEnd,
		@NewSPQualDateStart 		= g.newSPQualDateStart, 	
		@NewSPQualDateEnd 			= g.newSPQualDateEnd	
				
	FROM OPENJSON(@Parameters)
	WITH ( 
			
			step INT '$.step',
			currentDatetime DATETIME '$.currentDatetime',
			pkEventLog INT '$.pkEventLog',
			execLog BIT '$.execLog',
			cleanUpTempData BIT '$.cleanUpTempData',
			eligibleCountries VARCHAR(MAX) '$.eligibleCountries',
			pK_Event INT '$.pK_Event',
			 
			fqsFirtTimeEver BIT '$.fqsFirtTimeEver',
			fqsRequalificationCount BIT '$.fqsRequalificationCount',

			aWTQualDateStart DATE '$.aWTQualDateStart',
			aWTQualDateEnd DATE '$.aWTQualDateEnd',
			aWTYear	INT '$.aWTYear',
			isNonTAB BIT '$.isNonTAB',
			requalifiedCount BIT '$.requalifiedCount',
			newSPDownlinesStart DATE '$.newSPDownlinesStart',
			newSPDownlinesEnd DATE '$.newSPDownlinesEnd',
			signUpDateRangeStart INT '$.signUpDateRangeStart',
			signUpDateRangeEnd INT '$.signUpDateRangeEnd',
			qualPeriodStartMonth1 DATE '$.qualPeriodStartMonth1',
			qualPeriodStartMonth2 DATE '$.qualPeriodStartMonth2',
			qualPeriodStartMonth3 DATE '$.qualPeriodStartMonth3',
			newQPQualDateStart DATE '$.newQPQualDateStart',
			newQPQualDateEnd DATE '$.newQPQualDateEnd',
			newSPQualDateStart DATE '$.newSPQualDateStart',
			newSPQualDateEnd DATE '$.newSPQualDateEnd'

		) AS g
	 
	-- Default values 
	 
	SET @Step = IIF(@Step IS NULL,11, @Step) 
	SET @CurrentDatetime = IIF(@CurrentDatetime IS NULL,GETDATE(), @CurrentDatetime)

	SELECT			
		@Step						AS [Step],			
		@CurrentDatetime			AS [CurrentDatetime],
		@PK_Event_Log				AS [PK_Event_Log],
		@ExecLog					AS [ExecLog],
		@CleanUpTempData			AS [CleanUpTempData],
		@EligibleCountries			AS [EligibleCountries],	 
		@PK_Event					AS [PK_Event],		 
 	
		@FQSFirtTimeEver			AS [FQSFirtTimeEver],
		@FQSRequalificationCount	AS [FQSRequalificationCount],

		@AWTQualDateStart			AS [AWTQualDateStart], 
		@AWTQualDateEnd				AS [AWTQualDateEnd],
		@AWTYear					AS [AWTYear],
		@IsNonTAB					AS [IsNonTAB],
		 
		@NewSPDownlinesStart		AS [NewSPDownlinesStart],
		@NewSPDownlinesEnd			AS [NewSPDownlinesEnd],	

        @SignUpDateRangeStart		AS [SignUpDateRangeStart],	
        @SignUpDateRangeEnd  		AS [SignUpDateRangeEnd],	

        @QualPeriodStartMonth1		AS [QualPeriodStartMonth1],
		@QualPeriodStartMonth2		AS [QualPeriodStartMonth2],
		@QualPeriodStartMonth3		AS [QualPeriodStartMonth3],
		
        @NewQPQualDateStart			AS [NewQPQualDateStart],		
		@NewQPQualDateEnd			AS [NewQPQualDateEnd],
		@NewSPQualDateStart			AS [NewSPQualDateStart],		
		@NewSPQualDateEnd			AS [NewSPQualDateEnd]

	------------------------------------------------------------------------------------------------
	-- Tables and variables
	------------------------------------------------------------------------------------------------
	BEGIN

		--Variables for logging
		DECLARE  
		 @PK_TimeLog1 datetime2
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
		 
			INSERT INTO #Event_SetupEventQualification(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition,QSVolume)
			SELECT seq.PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition,QSVolume
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
					DSSubTeam				varchar(10),        
					DSSPTeam				varchar(10), 
                    ApplicationDate		    DATETIME2,					
					dSPQualDate				datetime2,
					dSPRequalDate			datetime2,
					dSPDemotion				datetime2 default '1900-01-01',
					QSQualDate				smalldatetime,		
					QSActualQualDate		smalldatetime,	
					CountryCode				varchar(5),
					IsFromList				bit default(0),
					IsTicketPurchaser		bit default(0)

					--
					,NewSPQualDate		date 
					,IsAWTQualifier		BIT DEFAULT 0
					,NewQPQualDate		date default '1900-01-01'					
				)

				INSERT INTO #DS
				(
					PK_Event,
					PK_Distributor,	
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,
                    ApplicationDate,				
					dSPQualDate,
					dSPRequalDate,
					dSPDemotion,
					QSQualDate,
					QSActualQualDate,
					CountryCode
				)
				SELECT DISTINCT    
				l.PK_Event,
				D.nDistributorID AS PK_Distributor,   
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam, 
                D.dApplication AS ApplicationDate,			
				D.dSupervisorqualification AS dSPQualDate,    
				d.dSupervisorReQualification AS dSPRequalDate,
				D.dSPDemotion AS dSPDemotion, 
				D.dQSQualification AS dQSQualification,				
				D.dQSQualification_Actual AS dQSQualification_Actual,
				D.sDistributorCountryProcessingCode AS CountryCode
				FROM        
				dbo.v_Distributor AS D  
					INNER JOIN #LocationMapping AS l
						ON D.nDistributorCountryProcessingID = l.PK_Country				
				WHERE        
					D.StatusCode = 'COMPLETE' 
	 
				CREATE INDEX IX_#DS_PK_Distributor ON #DS(PK_Distributor);

			SELECT @StepGroup = 1, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 


		END
		
		--Step 2: SKUs 
		IF @Step >= 2 
		BEGIN

			PRINT 'Executing step 2'			

			SELECT @StepGroup = 2, @StepSubGroup = 1, @Milestone = 'Getting Distributors with SKU';
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
					PK_Event INT 
				)

				INSERT INTO #SKUs(PK_Event,SKUCode)
				SELECT DISTINCT l.PK_Event, s.SKUCode
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
                    ApplicationDate,				
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
                D.dApplication AS ApplicationDate,					
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

			SELECT @StepGroup = 2, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 

			
		END 

		--Step 2 (Extension): EventQual
		IF @Step >= 2
		BEGIN

			PRINT 'Executing step 2 (Extension)'

			SELECT @StepGroup = 2, @StepSubGroup = 2, @Milestone = 'Getting qualifications';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
			
			    --NewFQS
				UPDATE D
				SET NewSPQualDate = IIF(@FQSFirtTimeEver = 1 
										,IIF(D.dSPDemotion = '1900-01-01' OR D.dSPDemotion IS NULL, D.dSPQualDate, -- First time ever / never demoted
										 NULL) -- If demoted cannot be New SP
										,D.dSPQualDate) -- If @FQSFirtTimeEver = 0 take dSPQualDate
				FROM #DS AS D  
				WHERE DSSPTeam = 'SP'


				UPDATE D
				SET NewSPQualDate =  IIF(@FQSRequalificationCount = 1, 
										IIF(D.dSPQualDate > D.dSPReQualDate OR D.dSPReQualDate IS NULL ,D.dSPQualDate,D.dSPReQualDate) -- If requalification counts take the latest date between SPQualDate and SPReQualDate
										,D.NewSPQualDate)  -- If requalificaton does not count take the date evaluated above
				FROM #DS AS D  
				WHERE DSSPTeam = 'SP'	


				--DSSNAPSHOT

				DROP TABLE IF EXISTS #DSSNAPSHOT

				SELECT
					DSN.PK_Distributor,
					DSN.ROYALTYMONTH,
					DSN.SUBTYPECODE,
					DSN.TEAMCODE
				INTO #DSSNAPSHOT
				FROM #DS AS d
					INNER JOIN [PubEventManagement].[Shared].[DSSNAPSHOT] AS DSN WITH (NOLOCK)
						 ON d.PK_Distributor = DSN.PK_Distributor			 
				ORDER BY PK_Distributor,ROYALTYMONTH DESC

				-- AWT 2026 Qual or Requal
				DROP TABLE IF EXISTS #AWT_QualRequal 

				SELECT PK_Distributor, IsNonTab, IsQualified,Qual_AWT,ReQualDate
				INTO #AWT_QualRequal
				FROM 
					(
					 SELECT  
						PK_Distributor, IsNonTab, IsQualified,Qual_AWT,
						CASE QualMonth  
							WHEN 'Jan' THEN  DATEFROMPARTS(@AWTYear, 1, 1)
							WHEN 'Feb' THEN  DATEFROMPARTS(@AWTYear, 2, 1)
							WHEN 'Mar' THEN  DATEFROMPARTS(@AWTYear, 3, 1)
							WHEN 'Apr' THEN  DATEFROMPARTS(@AWTYear, 4, 1)
							WHEN 'May' THEN  DATEFROMPARTS(@AWTYear, 5, 1)
							WHEN 'Jun' THEN  DATEFROMPARTS(@AWTYear, 6, 1)
							WHEN 'Jul' THEN  DATEFROMPARTS(@AWTYear, 7, 1)
							WHEN 'Aug' THEN  DATEFROMPARTS(@AWTYear, 8, 1)
							WHEN 'Sep' THEN  DATEFROMPARTS(@AWTYear, 9, 1)
							WHEN 'Oct' THEN  DATEFROMPARTS(@AWTYear, 10, 1)
							WHEN 'Nov' THEN  DATEFROMPARTS(@AWTYear, 11, 1)
							WHEN 'Dec' THEN  DATEFROMPARTS(@AWTYear, 12, 1)
						END AS ReQualDate 
					 FROM
						(
							SELECT d.PK_Distributor 
                            ,a.IsNonTab							
							,a.AWTYear
							,a.Qual_AWT  
							,t.[Jan]
							,t.[Feb]
							,t.[Mar]
							,t.[Apr]
							,t.[May]
							,t.[Jun]
							,t.[Jul]
							,t.[Aug]
							,t.[Sep]
							,t.[Oct]
							,t.[Nov]
							,t.[Dec] 
						FROM #DS AS d  
 						INNER JOIN dbo.[AWT] AS a WITH (NOLOCK)
 	 						ON d.PK_Distributor = a.PK_Distributor 
						INNER JOIN [dbo].[AWT_Qualifiers_Tracking] AS t WITH (NOLOCK)
							ON a.PK_Distributor = t.PK_Distributor AND a.AWTYear = t.AWTYear
 						WHERE a.AWTYear = @AWTYear 
						) p	UNPIVOT (IsQualified FOR QualMonth IN ([Jan],[Feb],[Mar],[Apr],[May],[Jun],[Jul],[Aug],[Sep],[Oct],[Nov],[Dec])) AS up
					) AS qr
				WHERE IsQualified = 1	
                AND (isNonTAB = @IsNonTAB OR @IsNonTAB IS NULL)				
				AND ((@RequalifiedCount = 1 AND ReQualDate BETWEEN @AWTQualDateStart AND @AWTQualDateEnd) OR Qual_AWT BETWEEN @AWTQualDateStart AND @AWTQualDateEnd)
				 
				UPDATE D
				SET IsAWTQualifier = 1
				FROM #DS AS d
					INNER JOIN #AWT_QualRequal AS q
						ON d.PK_Distributor = q.PK_Distributor						
						
                --New QP

				DROP TABLE IF EXISTS #CurrentQP

				SELECT 
					PK_Distributor,
					CAST(CONVERT(varchar(6), DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrentDatetime), 0), 112) AS int)  ROYALTYMONTH,
					DSSubTeam AS SUBTYPECODE
				INTO #CurrentQP
				FROM #DS WHERE DSSubTeam = 'QP'
				GROUP BY PK_Distributor,DSSubTeam
			 
				DROP TABLE IF EXISTS #NewQP
			
				;WITH cte_QPBeforePeriod AS
				(
					SELECT DISTINCT PK_DISTRIBUTOR 
					FROM #DSSNAPSHOT WHERE TEAMCODE = '-1'  AND ROYALTYMONTH < CAST(CONVERT(varchar(6), @NewQPQualDateStart, 112) AS int)
				
				),
				cte_NewQP AS 
				(

					SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) ROYALTYMONTH, 0 AS [IsCurrentStatus] 				
					FROM #DSSNAPSHOT AS s
					WHERE TEAMCODE = 'W' 
						AND ROYALTYMONTH BETWEEN CAST(CONVERT(varchar(6), @NewQPQualDateStart, 112) AS int) AND CAST(CONVERT(varchar(6), @NewQPQualDateEnd, 112) AS int)
						AND NOT EXISTS (SELECT 1 FROM cte_QPBeforePeriod AS pQP WHERE pQP.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
					GROUP BY PK_DISTRIBUTOR
					UNION
					SELECT PK_DISTRIBUTOR,ROYALTYMONTH,1 AS [IsCurrentStatus]  
					FROM #CurrentQP AS s
					WHERE NOT EXISTS (SELECT 1 FROM cte_QPBeforePeriod AS pqp WHERE pqp.PK_DISTRIBUTOR = s.PK_DISTRIBUTOR)
				)

				SELECT PK_DISTRIBUTOR, MIN(ROYALTYMONTH) AS ROYALTYMONTH,MAX([IsCurrentStatus]) AS [IsCurrentStatus] 		
				INTO #NewQP
				FROM cte_NewQP
				GROUP BY PK_DISTRIBUTOR

				UPDATE D
					SET D.NewQPQualDate = ISNULL(CONVERT(DATETIME,CONVERT(VARCHAR,DQ.ROYALTYMONTH) + '01',112),'1900-01-01')
				FROM #DS AS D 
				LEFT JOIN #NewQP DQ
					ON D.PK_Distributor = DQ.PK_Distributor	
				

			SELECT @StepGroup = 2, @StepSubGroup = 2
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 


			SELECT @StepGroup = 2, @StepSubGroup = 3, @Milestone = '#EventQual';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone

			INSERT INTO #EventQual(PK_Distributor,PK_Event)
				SELECT 
					PK_Distributor,
					d.PK_Event AS [PK_Event] 
				FROM #DS AS d
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
						 
				 
	 			UPDATE q
					SET	Q01 = IIF(d.DSSPTeam = 'SP' ,1,0),																						-- Q01: FQS and above
						Q02 = IIF(d.NewQPQualDate BETWEEN @NewQPQualDateStart AND @NewQPQualDateEnd,1,0),                                       -- Q02: New QP - Vol Mon Oct 2025 - Marc 2026
						Q03 = IIF(d.NewSPQualDate IS NOT NULL AND d.NewSPQualDate BETWEEN @NewSPQualDateStart AND @NewSPQualDateEnd, 1, 0),     -- Q03: New SP qual month Nov 2025 - Apri 2026		
                        Q04 = IIF(d.DSCurrentTeam IN ('P','A','B','C'), 1,0) ,																	-- Q04: PT and above 	
                        Q05 = IIF(d.DSCurrentTeam IN ('G','M','P','A','B','C'), 1,0),															-- Q05:	TAB team							
						Q06 = IIF(d.IsAWTQualifier = 1, 1,0)																					-- Q06: AWT 2026 (Qualified or Requalified)						
				FROM #EventQual AS q
					INNER JOIN #DS AS d
						ON q.PK_Distributor = d.PK_Distributor AND q.PK_Event = d.PK_Event						 
				  

			SELECT @StepGroup = 2, @StepSubGroup = 3
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 


			SELECT @StepGroup = 2, @StepSubGroup = 4, @Milestone = 'WRK_26071_DSDetails';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone


			DROP TABLE IF EXISTS dbo.[WRK_26071_DSDetails]

			SELECT  
				PK_Event				
				,PK_Distributor			
				,DSCurrentTeam			
				,DSSubTeam				
				,DSSPTeam				
				,dSPQualDate				
				,dSPRequalDate			
				,dSPDemotion				
				,QSQualDate				
				,QSActualQualDate		
				,CountryCode				
				,IsFromList				
				,IsTicketPurchaser 
				,NewSPQualDate		
				,IsAWTQualifier		
				,NewQPQualDate					
			INTO dbo.[WRK_26071_DSDetails]
			FROM #DS

			SELECT @StepGroup = 2, @StepSubGroup = 4
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 


		END

		--Step 3: Volume		
		IF @Step >= 3 
		BEGIN
 
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

					DELETE #tmp_DS

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
							PK_Event AS [PK_Event],
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
					EXEC dbo.usp_GetDSVolume @PK_Event = @PK_EventMultiLocation, @SourceType = 3, @QualFilter = NULL, @KeepNegativeVolume =0, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
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
				-- 3.5 Getting #Event_DSPoints AND #Event_DSPoints_Validations
				------------------------------------------------------------------------------------------------
		 
				SELECT @StepGroup = 3, @StepSubGroup = 5, @Milestone = 'Getting #Event_DSPoints';
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
 
 
                    DELETE #Event_DSPoints WHERE PK_Event = @PK_Event

					DROP INDEX IF EXISTS [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints;
					DROP INDEX IF EXISTS [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints;
					
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
									
				SELECT @StepGroup = 3, @StepSubGroup = 5
				IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 


			SELECT @StepGroup = 3, @StepSubGroup = 6, @Milestone = 'Creating WRK_26071_DSPoints';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
 
			CREATE CLUSTERED INDEX [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints ([PK_Distributor]) 
			CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints ([MetricType])

			IF @IsDevQA = 0
			BEGIN
				 
				DROP TABLE IF EXISTS [dbo].[WRK_26071_DSPoints] 
					
				SELECT 
					p.PK_Distributor,
					p.[PK_Event],
					PK_Country,
					[RoyaltyMonth],
					MetricType,
					[PersonalPoints],
					[TransferPoints],
					[MainPoints], 
					[Points] 
				INTO [dbo].[WRK_26071_DSPoints] 
				FROM #Event_DSPoints AS p
					INNER JOIN #DS AS d
						ON p.PK_Distributor = d.PK_Distributor AND p.PK_Event = d.PK_Event

				CREATE INDEX IX_WRK_26071_DSPoints_PK_Distributor ON [dbo].[WRK_26071_DSPoints] (PK_Distributor);

			END
				
			SELECT @StepGroup = 3, @StepSubGroup = 6
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
					
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

				
					DROP TABLE IF EXISTS #tmpQualDef

						SELECT  
							C.PK_Event, 
							A.StartDate AS dStartDate,
							A.EndDate AS dEndDate,
							CAST(CONVERT(varchar(6), A.StartDate, 112) AS int) AS iStartDate,
							CAST(CONVERT(varchar(6), A.EndDate, 112) AS int) AS iEndDate,
							C.Frequency AS Frequency,
							C.Consecutive AS Consecutive,
							C.Accumulated AS Accumulated,
							C.MetricType AS MetricType,
							C.GoalPoints AS GoalPoints,
							C.MinPoints AS MinPoints,
							C.QualificationNumber,
							C.Part, 
							C.Countries,
							C.QSVolume
						INTO #tmpQualDef
						FROM #Event_SetupEventQualification AS C WITH (NOLOCK)  			
							CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A

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
							D.PK_Event,
							D.PK_Distributor AS PK_Distributor,
							C.dStartDate,
							C.dEndDate,
							C.iStartDate,
							C.iEndDate,
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
							INNER JOIN #tmpQualDef AS C
								ON C.PK_Event = D.PK_Event
							LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
								ON D.PK_Distributor = M.PK_Distributor	 

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

		--Step 5: Bonuses
		IF @Step >= 5
		BEGIN			

			PRINT 'Executing step 5'			
				 
 			------------------------------------------------------------------------------------------------
			-- 5.8 #Event_DSPoints_Summary
			------------------------------------------------------------------------------------------------
		 
			SELECT @StepGroup = 5, @StepSubGroup = 8, @Milestone = '#Event_DSPoints_Summary';
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @PK_TimeLog = @PK_TimeLog1 OUTPUT, @Milestone = @Milestone
			
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
					[MonthIndex] [int]
				)

				INSERT INTO #Event_DSPoints_Summary(PK_Event,PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries,[MonthIndex])
					SELECT U.PK_Event,
							U.PK_Distributor,
							U.RoyaltyMonth,
							U.MetricType,
							U.PK_Country AS PK_Country,
							IIF((F.[QSVolume] = 0 AND U.RoyaltyMonth >= F.iSPQualDate) OR F.[QSVolume] IS NULL OR F.[QSVolume] = 1, SUM(ISNULL(U.Points,0)),0) AS [Points],  
							F.[QSVolume], 
							F.iSPQualDate,
							F.QualificationNumber,
							F.Part,
							F.iStartDate,
							F.iEndDate,
							F.Countries,
							ROW_NUMBER() OVER (PARTITION BY U.PK_Event,U.PK_Distributor,U.MetricType,U.PK_Country,F.QualificationNumber,F.Part,F.iStartDate ORDER BY U.RoyaltyMonth ASC) AS [MonthIndex]
					FROM #Event_DSPoints AS U WITH (NOLOCK) 
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
					GROUP BY U.PK_Event,U.PK_Distributor,U.RoyaltyMonth,U.MetricType,U.PK_Country,F.[QSVolume],F.iSPQualDate,F.QualificationNumber,F.Part,F.iStartDate,F.iEndDate,F.Countries
					
			SELECT @StepGroup = 5, @StepSubGroup = 8
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT  
			
			------------------------------------------------------------------------------------------------
			-- 5.10 [tmp].[DSPointsSummary]
			------------------------------------------------------------------------------------------------
		
			SELECT @StepGroup = 5, @StepSubGroup = 10, @Milestone = '[tmp].[DSPointsSummary]';
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

				INSERT INTO #tmp_DSPointsSummary([PK_Event],PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[TotalPoints],iStartDate,iEndDate,QSVolume)
				SELECT 
					E.PK_Event AS PK_Event,
					E.PK_Distributor,
					E.RoyaltyMonth,
					E.MetricType,
					E.PK_Country,
					E.[Points],
					E.QualificationNumber,
					E.Part, 
					ISNULL(E.[Points],0) AS [TotalPoints],
					E.iStartDate,
					E.iEndDate,
					E.QSVolume
				FROM #Event_DSPoints_Summary AS E
					 	
				IF @IsDevQA = 0
				BEGIN
			 
					DELETE t
					FROM [tmp].[DSPointsSummary] AS t 
						INNER JOIN #LocationEventID AS l
							ON t.PK_Event = l.PK_Event

					INSERT INTO [tmp].[DSPointsSummary](PK_Event, PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[TotalPoints],iStartDate,iEndDate,QSVolume)
					SELECT 
							PK_Event,
							PK_Distributor,
							RoyaltyMonth,
							MetricType,
							PK_Country,
							[Points],
							QualificationNumber,
							Part,
							[TotalPoints],
							iStartDate,
							iEndDate,
							QSVolume
						FROM #tmp_DSPointsSummary

	 			END
		
			SELECT @StepGroup = 5, @StepSubGroup = 10
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
						Q.PK_Event
						,PK_Distributor
						,QualificationNumber 
						,Part		
						,QualDate
					FROM [Event].[DSQualPoints] AS Q WITH (NOLOCK)
						INNER JOIN #LocationEventID AS l
							ON Q.PK_Event = l.PK_Event
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
				 
			--Q18	Have minimum one (1) New Downline Supervisor - First DS Level with SP qual dates: Feb 2025 to April 2026

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
			FROM #DS AS D --Uplines from Belgium
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

			SELECT DD.PK_Distributor,DD.PK_DSDownLine
			INTO #NewSPDownlines
			FROM #DSDownlinesSummary AS DD
			INNER JOIN v_Distributor AS F
				ON F.nDistributorID =  DD.PK_DSDownline
				AND (F.dSupervisorQualification BETWEEN @NewSPDownlinesStart AND @NewSPDownlinesEnd
				AND F.dSupervisorReQualification IS NULL
				---AND (F.dSPDemotion = '1900-01-01' OR F.dSPDemotion IS NULL)
				AND F.sType = 'SP')
			UNION
			SELECT DD.PK_Distributor,DD.PK_DSDownLine
			FROM #DSDownlinesSummary AS DD
			INNER JOIN v_Distributor AS F
				ON F.nDistributorID =  DD.PK_DSDownline
				WHERE  (F.dSPDemotion >= '1900-01-01'  AND F.dSupervisorReQualification BETWEEN @NewSPDownlinesStart AND @NewSPDownlinesEnd )
			
			DROP TABLE IF EXISTS #Q18

			SELECT DISTINCT PK_Distributor
			INTO #Q18
			FROM #NewSPDownlines
			GROUP BY PK_Distributor

		    CREATE INDEX IX_#Q18_PK_Distributor ON #Q18(PK_Distributor)	

			UPDATE E
			SET 
				Q18 = 1
			FROM #EventQual AS E
			INNER JOIN #Q18 AS Q18
				ON E.PK_Distributor = Q18.PK_Distributor
				
				
		-- Q19 Have 1 New DS/PC (Signup Month: January 2026 to Mar 2026) in each month during the Qual Period (January 2026 - Mar 2026) who achieves 250 PPV in the same month as App date + AppMonth+1.
		-- Q20 Have 4 new DS/PC (Signup Month: January 2026 to Mar 2026) over Qual Period (January 2026 - Mar 2026) who achieves 250 PPV in the same month as the App date + AppMonth+1. 
		
			DROP TABLE IF EXISTS #NewDSPCDownlines

			SELECT   D.PK_Distributor, V.PK_DSDownline, 'DS' AS DownlineType
					,IIF(DS.ApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd, DS.ApplicationDate, DS.WINBACKREINSTATEMENTDATE) AS SignUpDate
					,IIF(DS.ApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd
							,DATEFROMPARTS(YEAR(LEFT(DS.ApplicationDate,4)), CAST(SUBSTRING(CAST(DS.ApplicationDate AS VARCHAR),5,2) AS INT),1)
							,DATEFROMPARTS(YEAR(LEFT(DS.WINBACKREINSTATEMENTDATE,4)), CAST(SUBSTRING(CAST(DS.WINBACKREINSTATEMENTDATE AS VARCHAR),5,2) AS INT),1)
							) AS dSignUpDate
					,DATEADD(MONTH, 1, IIF(DS.ApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd
											,DATEFROMPARTS(YEAR(LEFT(DS.ApplicationDate,4)), CAST(SUBSTRING(CAST(DS.ApplicationDate AS VARCHAR),5,2) AS INT),1)
											,DATEFROMPARTS(YEAR(LEFT(DS.WINBACKREINSTATEMENTDATE,4)), CAST(SUBSTRING(CAST(DS.WINBACKREINSTATEMENTDATE AS VARCHAR),5,2) AS INT),1)
										)
								) AS [dSignUpDate+1]					
			INTO #NewDSPCDownlines
			FROM #DS AS D WITH (NOLOCK)
			INNER JOIN v_dimDSLngDownline AS V WITH (NOLOCK)
				ON D.PK_Distributor = V.PK_Distributor
				AND DSLevelFromUL = 2
			INNER JOIN PubEvents.dbo.dimDistributor AS DS WITH (NOLOCK)
				ON DS.PK_Distributor = V.PK_DSDownline
				AND (DS.ApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd OR DS.WINBACKREINSTATEMENTDATE BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd)

			INSERT INTO  #NewDSPCDownlines
			SELECT   D.PK_Distributor, V.PK_DSDownline, 'PC' AS DownlineType
					,IIF(DS.MBApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd, DS.MBApplicationDate, DS.PMREINSTATEMENTDATE) AS SignUpDate
					,IIF(DS.MBApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd
							,DATEFROMPARTS(YEAR(LEFT(DS.MBApplicationDate,4)), CAST(SUBSTRING(CAST(DS.MBApplicationDate AS VARCHAR),5,2) AS INT),1)
							,DATEFROMPARTS(YEAR(LEFT(DS.PMREINSTATEMENTDATE,4)), CAST(SUBSTRING(CAST(DS.PMREINSTATEMENTDATE AS VARCHAR),5,2) AS INT),1)
							) AS dSignUpDate
					,DATEADD(MONTH, 1, IIF(DS.MBApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd
											,DATEFROMPARTS(YEAR(LEFT(DS.MBApplicationDate,4)), CAST(SUBSTRING(CAST(DS.MBApplicationDate AS VARCHAR),5,2) AS INT),1)
											,DATEFROMPARTS(YEAR(LEFT(DS.PMREINSTATEMENTDATE,4)), CAST(SUBSTRING(CAST(DS.PMREINSTATEMENTDATE AS VARCHAR),5,2) AS INT),1)
										)
								) AS [dSignUpDate+1]					
			FROM #DS AS D WITH (NOLOCK)
			INNER JOIN v_dimDSLngDownline AS V WITH (NOLOCK)
				ON D.PK_Distributor = V.PK_Distributor
				AND DSLevelFromUL = 2
			INNER JOIN PubEvents.dbo.dimDistributor AS DS WITH (NOLOCK)
				ON DS.PK_Distributor = V.PK_DSDownline
				AND (DS.MBApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd OR DS.PMREINSTATEMENTDATE BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd)

			CREATE INDEX IX_#NewDSPCDownlines_PK_Distributor ON #NewDSPCDownlines(PK_Distributor)	
			
			
		-- Downlines volume
			DROP TABLE IF EXISTS #Volume_NewDSPCDownlines

			SELECT M.PK_Distributor, M.PK_DSDownline, M.DownlineType, M.SignUpDate
				,SUM(ISNULL(F.DS_PPV,0) + ISNULL(F.MainDS_PPV,0 ) + ISNULL(F.GCASSOC_DS_PPV,0)) AS DS_PPV 
				,CAST (0 AS MONEY) AS PC_PPV, dSignUpDate, [dSignUpDate+1]
			INTO #Volume_NewDSPCDownlines
			FROM #NewDSPCDownlines AS M			
			LEFT JOIN PubEvents.dbo.aggDSFinancial_ctry AS F WITH (NOLOCK)
				ON F.PK_Distributor = M.PK_DSDownline
				AND RoyaltyMonth BETWEEN dSignUpDate AND [dSignUpDate+1]				
			WHERE M.DownlineType = 'DS'
			GROUP BY M.PK_Distributor, M.PK_DSDownline, M.DownlineType, M.SignUpDate, dSignUpDate, [dSignUpDate+1]

			INSERT INTO #Volume_NewDSPCDownlines
			SELECT	M.PK_Distributor, M.PK_DSDownline, M.DownlineType, M.SignUpDate, CAST (0 AS MONEY) AS DS_PPV
					,SUM(ISNULL(F.PM_PPV,0) + ISNULL(F.MainPM_PPV,0 ) + ISNULL(F.GCASSOC_PM_PPV,0)) AS PC_PPV
					,dSignUpDate, [dSignUpDate+1]
			FROM #NewDSPCDownlines AS M
			LEFT JOIN PubEvents.dbo.aggDSFinancial_ctry AS F WITH (NOLOCK) 	
				ON F.PK_Distributor = M.PK_DSDownline
				AND F.RoyaltyMonth BETWEEN dSignUpDate AND [dSignUpDate+1]
			WHERE M.DownlineType = 'PC'
			GROUP BY M.PK_Distributor, M.PK_DSDownline, M.DownlineType, M.SignUpDate, dSignUpDate, [dSignUpDate+1]
				
		
			DROP TABLE IF EXISTS #DSPCDownlinesQualified

			SELECT PK_Distributor, PK_DSDownline, DownlineType, SignUpDate, DS_PPV, PC_PPV
			INTO #DSPCDownlinesQualified
			FROM #Volume_NewDSPCDownlines  
			WHERE (DS_PPV >= 250 OR PC_PPV >= 250)			
			
			IF @IsDevQA = 0
				BEGIN				 

					DROP TABLE IF EXISTS [dbo].[WRK_26071_DSPoints_Downlines] 
					
					SELECT 
						PK_Distributor,
						@PK_Event PK_Event,
						PK_DSDownline,
						DownlineType,
						SignUpDate,
						DS_PPV,
						PC_PPV
					INTO [dbo].[WRK_26071_DSPoints_Downlines] 
					FROM #DSPCDownlinesQualified 					

					CREATE INDEX IX_WRK_26049_DSPoints_Downlines_PK_Distributor ON [dbo].[WRK_26071_DSPoints_Downlines] (PK_Distributor);

				END				
	
		-- Q19
			DROP TABLE IF EXISTS #UplinesPerMonth

				SELECT DISTINCT PK_Distributor, 1 AS MonthCount	, @QualPeriodStartMonth1 AS StartDate, EOMONTH(@QualPeriodStartMonth1) AS EndDate
			INTO #UplinesPerMonth
				FROM #DSPCDownlinesQualified WHERE CAST(CAST(SignUpDate AS VARCHAR) AS DATE) BETWEEN @QualPeriodStartMonth1 AND EOMONTH(@QualPeriodStartMonth1)
			UNION 
				SELECT DISTINCT PK_Distributor, 1 AS MonthCount, @QualPeriodStartMonth2 AS StartDate, EOMONTH(@QualPeriodStartMonth2) AS EndDate	FROM #DSPCDownlinesQualified WHERE CAST(CAST(SignUpDate AS VARCHAR) AS DATE) BETWEEN @QualPeriodStartMonth2 AND EOMONTH(@QualPeriodStartMonth2)
			UNION
				SELECT DISTINCT PK_Distributor, 1 AS MonthCount, @QualPeriodStartMonth3 AS StartDate, EOMONTH(@QualPeriodStartMonth3) AS EndDate	FROM #DSPCDownlinesQualified WHERE CAST(CAST(SignUpDate AS VARCHAR) AS DATE) BETWEEN @QualPeriodStartMonth3 AND EOMONTH(@QualPeriodStartMonth3)

		
			DROP TABLE IF EXISTS #TotalDownlines1PerMonth

			SELECT PK_Distributor, SUM(MonthCount) AS TotalMonths
			INTO #TotalDownlines1PerMonth
			FROM #UplinesPerMonth
			GROUP BY PK_Distributor

			CREATE INDEX IX_#TotalDownlines1PerMonth_PK_Distributor ON #TotalDownlines1PerMonth(PK_Distributor)	
			

			DROP TABLE IF EXISTS #Q19

			SELECT DISTINCT PK_Distributor
			INTO #Q19
			FROM #TotalDownlines1PerMonth
			WHERE TotalMonths = 3

			CREATE INDEX IX_#Q19_PK_Distributor ON #Q19(PK_Distributor)	

			UPDATE E
			SET 
				Q19 = 1
			FROM #EventQual AS E
			INNER JOIN #Q19 AS Q19
				ON E.PK_Distributor = Q19.PK_Distributor			

	
		-- Q20
			DROP TABLE IF EXISTS #AccDownlines

			SELECT PK_Distributor, COUNT(PK_DSDownline) AS ContributorsCount
			INTO #AccDownlines
			FROM #DSPCDownlinesQualified
			GROUP BY PK_Distributor
			

			DROP TABLE IF EXISTS #Q20

			SELECT DISTINCT PK_Distributor
			INTO #Q20
			FROM #AccDownlines
			WHERE ContributorsCount >= 4

			CREATE INDEX IX_#Q20_PK_Distributor ON #Q20(PK_Distributor)	

			UPDATE E
			SET 
				Q20 = 1
			FROM #EventQual AS E
			INNER JOIN #Q20 AS Q20
				ON E.PK_Distributor = Q20.PK_Distributor	
				
			END			
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

			END
	
			SELECT @StepGroup = 10, @StepSubGroup = 1
			IF @ExecLog = 1 EXEC [Shared].[usp_LogEventRun] @PK_EventRun = @PK_Event_Log, @StepGroup = @StepGroup, @StepSubGroup = @StepSubGroup, @RowCount = @RowCount, @PK_TimeLog = @PK_TimeLog1 OUTPUT 
			
		END
		 
		--Step 11: SubEventQualifiers
		IF @Step >= 11 
		BEGIN
					
			PRINT 'Executing step 11'

			SELECT @StepGroup = 11, @StepSubGroup = 1, @Milestone = 'usp_EventPromo_UpdateSubEventQualifier';
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
