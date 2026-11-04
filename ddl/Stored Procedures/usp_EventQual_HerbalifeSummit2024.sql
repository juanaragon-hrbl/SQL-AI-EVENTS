CREATE PROCEDURE [dbo].[usp_EventQual_HerbalifeSummit2024]
	@Parameters NVARCHAR(MAX)
	   
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 3 DEBUG 2 UT 
AS
BEGIN
/*********************************************************************************************************************
OBJECT:		dbo.usp_EventQual_HerbalifeSummit2024

USE:		DECLARE @e int, @em varchar(4000), @param nvarchar(max)
			
			SET @param = N'{"pkEvent":195939,"currentDate": null, "snapshotLineageDate":"2024-02-09", "potentialsCommitmentDate": null,"step":15}'
			EXEC dbo.usp_EventQual_HerbalifeSummit2024 @Parameters= @param, @Error = @e OUTPUT, @ErrorMessage = @em OUTPUT SELECT @e AS [Error], @em AS [ErrorMessage]
			
DESCRIPTION: 

NOTES:			

DEPENDENCIES:
usp_Utility_UpdateErrorLog
usp_Utility_UpdateProcessingLog
 

WORK TABLES (WRK):

--Defined within the sp definition
 

VERSIONS
-----------------------------------------------------------------------------------------------------------------------------
1.0.0		2023-05-29		alejandramed		Initial 
1.0.1		2023-06-23		alejandramed		Bug 1269789: 24014 - Not getting downlines (E3 thru E10)
1.0.2		2023-07-03		alejandramed		User Story 1271098: 24014 - Herbalife Summit 2024 - BRD V2
1.0.3		2023-08-31		alejandramed		User Story 1291493: 24014 - Herbalife Summit 2024 - BRD V4
1.0.4		2023-09-19		alejandramed		User Story 1296683: 24014 - Herbalife Summit 2024 - BRD V5
1.0.5		2023-11-13		alejandramed		User Story 1309035: 24014 - Herbalife Summit 2024 - BRD V7
1.0.6		2024-01-16		alejandramed		User Story 1311549: 24014 - Herbalife Summit 2024 - BRD V8
1.0.7		2024-01-17		alejandramed		Including execution with parameters from json.
1.0.8		2024-02-15		alejandramed		User Story 1320884: 24014 - Herbalife Summit 2024 - BRD V9
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
			[QSVolumePercentage] [int] NULL,
			[MetricTypeDefinition]		VARCHAR(50) NULL
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

	IF @IsDevQA = 3 AND ( OBJECT_ID('tempdb.dbo.##DSQualPoints_amed') IS NULL OR 
		OBJECT_ID('tempdb.dbo.##tmp_DS_amed') IS NULL OR
		OBJECT_ID('tempdb.dbo.##Event_SetupEventQualification_amed') IS NULL OR
		OBJECT_ID('tempdb.dbo.##Event_DSPoints_amed') IS NULL OR
		OBJECT_ID('tempdb.dbo.##DSPointsSummary_amed') IS NULL)
	BEGIN
		SELECT 'Temp tables are missing, create them manually' AS [Error]
		SET @ErrorMessage = 'Temp tables are missing, create them manually'
	END


	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
				
	SELECT @Error = 0, @ErrorMessage = '';	

	-- Variables for json values

	DECLARE @PK_Event	INT
    ,@CurrentDate DATE
	,@Snapshot_Lineage_Date DATE
	,@Potentials_Commitment_Date DATE
	,@Step INT
 

	-- Getting parameters values for json

	SELECT 
		@PK_Event = pkEvent, 
		@CurrentDate = currentDate,
		@Snapshot_Lineage_Date = snapshotLineageDate,
		@Potentials_Commitment_Date = potentialsCommitmentDate,
		@Step = step
	FROM OPENJSON(@Parameters)
	WITH (
			pkEvent INT '$.pkEvent',
			currentDate DATE '$.currentDate',
			snapshotLineageDate DATE '$.snapshotLineageDate',
			potentialsCommitmentDate DATE '$.potentialsCommitmentDate',
			step INT '$.step'
		)
	 
	-- Default values
	SET @PK_Event = IIF(@PK_Event IS NULL,198082, @PK_Event)
	SET @CurrentDate = IIF(@CurrentDate IS NULL,GETUTCDATE(), @CurrentDate)
	SET @Snapshot_Lineage_Date = IIF(@Snapshot_Lineage_Date IS NULL,'2024-01-15', @Snapshot_Lineage_Date)
	SET @Potentials_Commitment_Date = IIF(@Potentials_Commitment_Date IS NULL,NULL, @Potentials_Commitment_Date)
	SET @Step = IIF(@Step IS NULL,11, @Step)

	DECLARE  @iStartDate int,
			@dStartDate datetime,
			@iEndDate int,
			@dEndDate datetime,
			@QualType SMALLINT,  --1 = Accumulated/Non-Consecutive, 2 = Accumulated/Consecutive, 3 = Achieve/Consecutive, 4 = Achieve/Non-Consecutive
			@PK_Execution INT,
			@PK_Event_Execution INT,
			@OverwritePointsSummary BIT				

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
			[MetricTypeDefinition]		VARCHAR(50) NULL
		)
		
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
			[Countries] [varchar](max),
			[BonusCount] [bit] 
		)

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

BEGIN TRY

		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
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
			Q51  BIT DEFAULT 0,
			E01  BIT DEFAULT 0,	E02  BIT DEFAULT 0,	E03  BIT DEFAULT 0,	E04  BIT DEFAULT 0,	E05  BIT DEFAULT 0,
			E06  BIT DEFAULT 0,	E07  BIT DEFAULT 0,	E08  BIT DEFAULT 0,	E09  BIT DEFAULT 0,	E10  BIT DEFAULT 0,
			E11  BIT DEFAULT 0,	E12  BIT DEFAULT 0,	E13  BIT DEFAULT 0,	E14  BIT DEFAULT 0,	E15  BIT DEFAULT 0,
			E16  BIT DEFAULT 0,	E17  BIT DEFAULT 0,	E18  BIT DEFAULT 0,	E19  BIT DEFAULT 0,	E20  BIT DEFAULT 0,
			E21  BIT DEFAULT 0,	E22  BIT DEFAULT 0,	E23  BIT DEFAULT 0,	E24  BIT DEFAULT 0,	E25  BIT DEFAULT 0,
			E26  BIT DEFAULT 0,	E27  BIT DEFAULT 0,	E28  BIT DEFAULT 0,	E29  BIT DEFAULT 0,	E30  BIT DEFAULT 0,
			E31  BIT DEFAULT 0,	E32  BIT DEFAULT 0,	E33  BIT DEFAULT 0,	E34  BIT DEFAULT 0,	E35  BIT DEFAULT 0,
			E36  BIT DEFAULT 0,	E37  BIT DEFAULT 0,	E38  BIT DEFAULT 0,	E39  BIT DEFAULT 0,	E40  BIT DEFAULT 0,
			E41  BIT DEFAULT 0,	E42  BIT DEFAULT 0,	E43  BIT DEFAULT 0,	E44  BIT DEFAULT 0,	E45  BIT DEFAULT 0,
			E46  BIT DEFAULT 0,	E47  BIT DEFAULT 0,	E48  BIT DEFAULT 0,	E49  BIT DEFAULT 0,	E50  BIT DEFAULT 0,
			E51  BIT DEFAULT 0
		)

		INSERT INTO #TimeLog VALUES ('#Event_SetupEventQualification', 0, 1, GETUTCDATE(), NULL);

		INSERT INTO #Event_SetupEventQualification(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries)
		SELECT 
			@PK_Event			AS PK_Event,
			8					AS QualificationNumber,	
			1					AS Part, 
			'RO'				AS [MetricType], 
			'2023-03-01'		AS [dStartDate], 
			'2024-02-01'		AS [dEndDate],
			1					AS [Frequency], 
			0					AS [Consecutive], 
			0					AS [Accumulated], 
			0					AS [MinPoints], 
			4000				AS [GoalPoints], 
			NULL				AS [Countries]
				 
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 0 AND [StepSubGroup] = 1;

		DROP TABLE IF EXISTS #Associated;

		CREATE TABLE #Associated
		(
			PK int IDENTITY(1,1) PRIMARY KEY,
			nMainAssociatedID INT,
			nDistributorID INT,
			AssociatedGuaranteedStars INT DEFAULT 0,
			AssociatedPotentialsStars INT DEFAULT 0
		)

		DROP TABLE IF EXISTS #UplinesStars

		CREATE TABLE #UplinesStars
		(
			 PK_Distributor					INT 
			,FirstLineCount					INT DEFAULT 0  
			,SecondLineCount				INT DEFAULT 0  
			,ThirdLineCount					INT DEFAULT 0  
			,AssociatedGuaranteedStars		INT DEFAULT 0
			,AssociatedPotentialsStars		INT DEFAULT 0
			,GuaranteedStars				AS (FirstLineCount+AssociatedGuaranteedStars)  
			,Potentials						AS (SecondLineCount+ThirdLineCount+AssociatedPotentialsStars) 
			,PotentialsCommited				INT DEFAULT 0
			,OverallCount					INT --AS (FirstLineCount+AssociatedGuaranteedStars+PotentialsCommited)  
		)

		-- Step 1: DS eligible by country and DS type 
		-- Every active FQS from WW, except China is potentialy eligible for this event
		----------------------------------------------------------------------------------------------------------------------------------------------
		IF @Step >= 1
		BEGIN

			PRINT 'Executing step 1'

			/* GETTING ASSOCIATED DISTRIBUTORS TO MAIN ID */

			INSERT INTO #Associated(nMainAssociatedID,nDistributorID)
			SELECT DISTINCT nMainDistributorID,PK_Distributor FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE (A.AssociationType = 3 OR (A.AssociationType = 2 AND A.PK_AssociatedID = A.nMainDistributorID))
	 
			CREATE INDEX IX_#Associated_nMainAssociatedID ON #Associated(nMainAssociatedID)
			CREATE INDEX IX_#Associated_nDistributorID ON #Associated(nDistributorID)

			INSERT INTO #TimeLog VALUES ('#DS', 1, 1, GETUTCDATE(), NULL);
			 
				DROP TABLE IF EXISTS #DS

				CREATE TABLE #DS
				(
					PK_Distributor		int,   
					DistributorID		varchar(30),  
					DSCurrentTeam		varchar(10),        
					DSSubTeam			varchar(10),        
					DSSPTeam			varchar(10),               
					dSPQualDate			datetime2,        
					CountryCode			varchar(5),
					IsFromList			bit default(0),
					IsTicketPurchaser	bit default(0)
				)

				INSERT INTO #DS
				(
					PK_Distributor,	
					DistributorID,
					DSCurrentTeam,	
					DSSubTeam,		
					DSSPTeam,			
					dSPQualDate,		
					CountryCode
				)
				SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				D.sDistributorID AS DistributorID,
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				D.dSupervisorqualification AS dSPQualDate,        
				D.sDistributorCountryProcessingCode AS CountryCode
				FROM        
				dbo.v_Distributor AS D  
				WHERE        
					D.StatusCode = 'COMPLETE'
					AND		
						D.sType = 'SP'
					AND 
						D.dDeleted = '2049-12-31'
					AND 
						D.nDistributorCountryProcessingID <> 590004 -- China 
			 UNION
			 SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				D.sDistributorID AS DistributorID,
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
				D.sSubteam AS DSSubTeam,        
				D.sType AS DSSPTeam,            
				D.dSupervisorqualification AS dSPQualDate,        
				D.sDistributorCountryProcessingCode AS CountryCode
				FROM        
				dbo.v_Distributor AS D  
				WHERE        
					D.StatusCode = 'COMPLETE'
					AND		
						D.sType = 'SP'
					--AND 
					--	D.sTeam IN ('P','A','B','C')
					AND 
						D.dDeleted = '2049-12-31'
					AND 
						D.nDistributorCountryProcessingID = 590004 -- China can qualify to some subevents

				CREATE INDEX IX_#DS_PK_Distributor ON #DS(PK_Distributor);

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 1 AND [StepSubGroup] = 1;
		END

		-- Step 2: DS eligible by List and SKUs
		----------------------------------------------------------------------------------------------------------------------------------------------
		IF @Step >= 2
		BEGIN

			PRINT 'Executing step 2'

			INSERT INTO #TimeLog VALUES ('Lists', 2, 1, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #DSList

				CREATE TABLE #DSList
				(
					PK_Distributor INT
					,ListID INT
				)	
				
				DROP TABLE IF EXISTS #ListsIDs

				CREATE TABLE #ListsIDs
				(
					ListID INT
				)

				INSERT INTO #ListsIDs(ListID)
				VALUES 
					(54829), --E3
					(54830), --E4
					(54831), --E5
					(54832), --E6
					(54833), --E7
					(54834), --E8
					(54835), --E9
					(54836), --E10

				
					(54837), --Q09
					(54838), --Q10
					(54839), --Q11
					(54840), --Q12
					(54841), --Q13
					(54842), --Q14
					(54843), --Q15
					(54844), --Q16
					(54845), --Q17
					(54846), --Q18
					(54847), --Q19
					(54820), --Q20
					(54821), --Q21
					(54822), --Q22
					(54823), --Q23
					(54824), --Q24
					(55129), --Q25
					(55130), --Q26
					(55131), --Q27
					(54825), --Q28
					(55014), --Q29
					(55015), --Q30
					(55016), --Q31
					(55132), --Q32
					(55133), --Q33
					(55134), --Q34
					(55135), --Q35
					(55136), --Q36
					(57089), --Q38
					(57767), --Q40
					(57768), --Q41
					(57769), --Q42
					(57770), --Q43
					(57814), --Q44
					(57815), --Q45
					--BRD v8
					(58627),
					(58628),
					(58629),
					(58630),
					(58631),
					(58632),
					(58633),
					(58634),
					(58635),
					(58636),
					(58637),
					(58638),
					(58639),
					(58640),
					(58641),
					(58642),
					(58643),
					(58644),
					(58645),
					(58646),
					(58647),
					(58648),
					(58649)
												
				INSERT INTO #DSList(PK_Distributor,ListID)			  
				SELECT												  
					S.nDistributorID AS PK_Distributor,				  
					S.nTypeLID AS ListID
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
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,        
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

				DROP TABLE IF EXISTS #DSSKUs

				CREATE TABLE #DSSKUs
				(
					PK_Distributor INT
					,PK_EventSKU INT
					,SKUCode VARCHAR(10)
				)	
				
				DROP TABLE IF EXISTS #SKUs

				CREATE TABLE #SKUs
				(
					SKUCode VARCHAR(10)
				)
				 
				INSERT INTO #SKUs(SKUCode)
				VALUES 
				('1D79')


				INSERT INTO #DSSKUs(PK_Distributor,PK_EventSKU,SKUCode)
				SELECT DISTINCT et.PK_Distributor_Purchaser,esku.PK_EventSKU, esku.SKUCode  
				FROM #SKUs AS s 
					INNER JOIN dbo.EventSKU AS esku WITH (NOLOCK)
						ON s.SKUCode = esku.SKUCode
					INNER JOIN [dbo].[SKUPurchased] et WITH (NOLOCK)
						ON et.PK_EventSKU = esku.PK_EventSKU
				WHERE  et.PK_Event = @PK_Event

				CREATE INDEX IX_DSSKUs_PK_Distributor ON #DSSKUs(PK_Distributor)

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

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 2 AND [StepSubGroup] = 2;
		END

		--Step 3: Getting Volume  
		----------------------------------------------------------------------------------------------------------------------------------------------
		IF @Step >= 3
		BEGIN

			PRINT 'Executing step 3'

			IF @IsDevQA = 0
			BEGIN	

				DELETE s FROM [Event].[SetupEventQualification] AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
				INSERT INTO [Event].[SetupEventQualification](PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
				SELECT @PK_Event AS PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition 
				FROM #Event_SetupEventQualification  

			END
			ELSE
			IF @IsDevQA = 3
			BEGIN	

				DELETE s FROM ##Event_SetupEventQualification_amed AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
				INSERT INTO ##Event_SetupEventQualification_amed(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
				SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition
				FROM #Event_SetupEventQualification  

			END

			------------------------------------------------------------------------------------------------
			-- 3.1 Getting values from #Event_SetupEventQualification
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('Getting values from #Event_SetupEventQualification', 3, 1, GETUTCDATE(), NULL);
				
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

			------------------------------------------------------------------------------------------------
			-- 3.2 Getting #tmp_DS
			------------------------------------------------------------------------------------------------
			
			INSERT INTO #TimeLog VALUES ('#tmp_DS', 3, 2, GETUTCDATE(), NULL);

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
				INSERT INTO #TimeLog VALUES ('usp_GetDSVolume', 3, 3, GETUTCDATE(), NULL);

				--SourceType 3: Getting points from [PubEventManagement].[dbo].[v_aggFQS_ID]
				EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 3,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
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

					SELECT @ErrorMessage
					RETURN;
				END

				--Output
				--##Event_DSPoints_amed
 
		
				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 3 AND [StepSubGroup] = 3;
		
			END
			
			------------------------------------------------------------------------------------------------
			-- 3.4 Getting #Event_DSPoints AND #Event_DSPoints_Validations
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
					FROM ##Event_DSPoints_amed

				END

				CREATE CLUSTERED INDEX [IX_#Event_DSPoints_PK_Distributor] ON #Event_DSPoints ([PK_Distributor]) 
				CREATE NONCLUSTERED INDEX [IX_#Event_DSPoints_MetricType] ON #Event_DSPoints ([MetricType])
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 3 AND [StepSubGroup] = 4;
			
		
		END

		--Step 4: Qualification definition 

		IF @Step >= 4
		BEGIN

			PRINT 'Executing step 4'

			------------------------------------------------------------------------------------------------
			-- 4.1 Getting all qualification definition for each DS
			------------------------------------------------------------------------------------------------

			INSERT INTO #TimeLog VALUES ('#tmp_DSQualDef', 4, 1, GETUTCDATE(), NULL);
			
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
						ISNULL(C.Bonus,0) AS [Bonus]
					FROM #DS AS D					
						LEFT JOIN [Shared].[DistributorAssociation] AS M WITH (NOLOCK)
							ON D.PK_Distributor = M.PK_Distributor
						OUTER APPLY (SELECT * FROM #Event_SetupEventQualification AS S WITH (NOLOCK)) AS C
						CROSS APPLY [dbo].[ufn_GetPeriods](C.dStartDate,C.dEndDate,C.Frequency,C.Consecutive,C.Accumulated) AS A
						
				CREATE INDEX IX_#tmp_DSQualDef_PK_Distributor ON #tmp_DSQualDef(PK_Distributor);

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 4 AND [StepSubGroup] = 1;

			IF @IsDevQA = 0
			BEGIN

				INSERT INTO #TimeLog VALUES ('[tmp].[DSQualDef]', 4, 2, GETUTCDATE(), NULL);
					
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
				
			INSERT INTO #TimeLog VALUES ('##tmp_DSQualDef_amed', 4, 2, GETUTCDATE(), NULL);

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
				
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 4 AND [StepSubGroup] = 2;

			END
		END
			
		--Step 5:  DSPointsSummary 
		
		IF @Step >= 5
		BEGIN
			
			PRINT 'Executing step 5'
	 
			INSERT INTO #TimeLog VALUES ('#Event_DSPoints_Summary', 5, 1, GETUTCDATE(), NULL);

				INSERT INTO #Event_DSPoints_Summary(PK_Distributor,RoyaltyMonth,MetricType,PK_Country,Points,QSVolume,QSVolumePercentage,iSPQualDate,QualificationNumber,Part,iStartDate,iEndDate,Countries)
					SELECT U.PK_Distributor,
							U.RoyaltyMonth,
							U.MetricType,
							0 AS PK_Country,
							SUM(IIF(F.[QSVolume] = 0,IIF(U.RoyaltyMonth < F.iSPQualDate,0, ISNULL(U.Points,0)),ISNULL(U.Points,0))) AS [Points],	
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
					
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 5 AND [StepSubGroup] = 1;
			
			INSERT INTO #TimeLog VALUES ('#tmp_DSPointsSummary', 5, 2, GETUTCDATE(), NULL);

				INSERT INTO #tmp_DSPointsSummary([PK_Event],PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],[Bonus],[QSVolume],[QSVolumePercentage],[iSPQualDate],QualificationNumber,Part,[HasBonus],[TotalPoints],iStartDate,iEndDate,[Countries])
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
						FROM #Event_DSPoints_Summary AS P WITH (NOLOCK)

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 5 AND [StepSubGroup] = 2;

				IF @IsDevQA = 0
				BEGIN
					
					INSERT INTO #TimeLog VALUES ('[tmp].[DSPointsSummary]', 5, 3, GETUTCDATE(), NULL);
					
					DELETE t
					FROM [tmp].[DSPointsSummary] AS t
					WHERE t.PK_Event = @PK_Event

					DROP INDEX IF EXISTS IX_tmp_DSPointsSummary_PK_Distributor ON [tmp].[DSPointsSummary];

					INSERT INTO [tmp].[DSPointsSummary](PK_Event, PK_Distributor,RoyaltyMonth,MetricType,PK_Country,[Points],QualificationNumber,Part,[Bonus],[TotalPoints],iStartDate,iEndDate,iSPQualDate,QSVolume)
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
							QSVolume
						FROM #tmp_DSPointsSummary

					CREATE INDEX IX_tmp_DSPointsSummary_PK_Distributor ON [tmp].[DSPointsSummary](PK_Distributor)INCLUDE (PK_Event);	

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 5 AND [StepSubGroup] = 3;

				END
				ELSE IF @IsDevQA = 3
				BEGIN

					INSERT INTO #TimeLog VALUES ('##DSPointsSummary_amed', 5, 3, GETUTCDATE(), NULL);

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

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 5 AND [StepSubGroup] = 3;

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

			INSERT INTO #Executions(PK_Event,OverwritePointsSummary,QualType)
				SELECT 
					PK_Event, 
					MAX(0) AS OverwritePointsSummary,
					MAX(IIF(Accumulated = 0 AND Consecutive = 0, 4, --Achieve Non-Consecutive
						IIF( Accumulated = 0 AND Consecutive = 1, 3, --Achieve Consecutive
							IIF(Accumulated = 1 AND Consecutive = 1, 2, --Accumulated Consecutive
								IIF(Accumulated = 1 AND Consecutive = 0, 1,NULL))))) --Accumulated Non-Consecutive
						AS QualType 
				FROM #Event_SetupEventQualification 
				GROUP BY PK_Event
 
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

		--Step 7: Qualifications, based on levels, volumen and AWT or lists
		IF @Step >= 7
		BEGIN
			
			PRINT 'Executing step 7'

			INSERT INTO #TimeLog VALUES ('#Qs ', 7, 0, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #Q1 

				SELECT 
					PK_Distributor
					INTO #Q1
				FROM #DS AS d
				WHERE d.DSSPTeam = 'SP' AND NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
		
				CREATE INDEX IX_#Q1_PK_Distributor ON #Q1(PK_Distributor);

				DROP TABLE IF EXISTS #Q6

				SELECT 
					PK_Distributor
					INTO #Q6
				FROM #DS AS d
				WHERE d.DSCurrentTeam IN ('A', 'B', 'C', 'P')  AND NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)

				CREATE INDEX IX_#Q6_PK_Distributor ON #Q6(PK_Distributor);

				DROP TABLE IF EXISTS #Q7

				SELECT 
					d.PK_Distributor
				INTO #Q7
				FROM #DS AS d  
					INNER JOIN [dbo].[AWT] AS A WITH (NOLOCK)
						ON d.PK_Distributor = A.PK_Distributor AND A.AWTYear = '2023'
			
				CREATE INDEX IX_#Q7_PK_Distributor ON #Q7(PK_Distributor);

				
				--Achieve 4,000 RO in any one (1) month from Mar 2023 to Feb 2024
				DROP TABLE IF EXISTS #Q08

				SELECT Q.PK_Distributor
					INTO #Q08
				FROM #Event_DSQualPoints AS Q WITH(NOLOCK)
				WHERE Q.QualificationNumber = 8 AND Q.Part = 1 
				
				CREATE INDEX IX_#Q08_PK_Distributor ON #Q08(PK_Distributor);	

				--List ID: 54829 
				DROP TABLE IF EXISTS #E03

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E03				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 54829

				CREATE INDEX IX_#E03_PK_Distributor ON #E03(PK_Distributor);

				--List ID: 54830 
				DROP TABLE IF EXISTS #E04

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E04				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 54830

				CREATE INDEX IX_#E04_PK_Distributor ON #E04(PK_Distributor);

				--List ID: 54831 
				DROP TABLE IF EXISTS #E05

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E05				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 54831

				CREATE INDEX IX_#E05_PK_Distributor ON #E05(PK_Distributor);

				--List ID: 54832 
				DROP TABLE IF EXISTS #E06

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E06				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 54832

				CREATE INDEX IX_#E06_PK_Distributor ON #E06(PK_Distributor);

				--List ID: 54833 
				DROP TABLE IF EXISTS #E07

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E07				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 54833

				CREATE INDEX IX_#E07_PK_Distributor ON #E07(PK_Distributor);

				--List ID: 54834 
				DROP TABLE IF EXISTS #E08

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E08				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 54834

				CREATE INDEX IX_#E08_PK_Distributor ON #E08(PK_Distributor);

				--List ID: 54835 
				DROP TABLE IF EXISTS #E09

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E09				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 54835

				CREATE INDEX IX_#E09_PK_Distributor ON #E09(PK_Distributor);

				--List ID: 54836 
				DROP TABLE IF EXISTS #E10

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E10				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 54836

				CREATE INDEX IX_#E10_PK_Distributor ON #E10(PK_Distributor);

				--Q20	List ID 54820 ("24014_Herbalife Summit 2024")
					 
				DROP TABLE IF EXISTS #Q20

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q20				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  54820

				CREATE INDEX IX_#Q20_PK_Distributor ON #Q20(PK_Distributor);	

				--Q21	List ID 54821 ("24014_Level Up Promotion")
					 
				DROP TABLE IF EXISTS #Q21

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q21				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  54821

				CREATE INDEX IX_#Q21_PK_Distributor ON #Q21(PK_Distributor);	

				--Q22	List ID 54822 ("24014_Level Up Retreat Day 1")
					 
				DROP TABLE IF EXISTS #Q22

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q22				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  54822

				CREATE INDEX IX_#Q22_PK_Distributor ON #Q22(PK_Distributor);	

				--Q23	List ID 54823 ("24014_Level Up Retreat Day 1 & 2")
					 
				DROP TABLE IF EXISTS #Q23

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q23				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  54823

				CREATE INDEX IX_#Q23_PK_Distributor ON #Q23(PK_Distributor);	
				
				--Q24	List ID 54824 ("24014_Mark Hughes Bonus Earner")
					 
				DROP TABLE IF EXISTS #Q24

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q24				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  54824

				CREATE INDEX IX_#Q24_PK_Distributor ON #Q24(PK_Distributor);	

				--Q25	"New MT (Team Qual date from Mar 01 2023 to Feb 01 2024)
				--List ID 55129 (""24014_New MT"")"
				
				DROP TABLE IF EXISTS #Q25

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q25				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  55129

				CREATE INDEX IX_#Q25_PK_Distributor ON #Q25(PK_Distributor);	

				--Q26	"New MP (Team Qual date from Mar 01 2023 to Feb 01 2024)
				--List ID 55130 (""24014_New MP"")"
				
				DROP TABLE IF EXISTS #Q26

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q26				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  55130

				CREATE INDEX IX_#Q26_PK_Distributor ON #Q26(PK_Distributor);	

				--Q27	"New PT (Team Qual date from Mar 01 2023 to Feb 01 2024)
				--List ID 55131 (""24014_New PT"")"
				
				DROP TABLE IF EXISTS #Q27

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q27				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  55131

				CREATE INDEX IX_#Q27_PK_Distributor ON #Q27(PK_Distributor);	
				
				--Q28	List ID 54825 ("24014_New Diamond")
					 
				DROP TABLE IF EXISTS #Q28

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q28				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  54825

				CREATE INDEX IX_#Q28_PK_Distributor ON #Q28(PK_Distributor);	

				--Q29	List ID 55014 ("24014_New 2 Diamonds")
					 
				DROP TABLE IF EXISTS #Q29

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q29				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  55014

				CREATE INDEX IX_#Q29_PK_Distributor ON #Q29(PK_Distributor);	

				--Q30	List ID 55015 ("24014_New 3 Diamonds")
					 
				DROP TABLE IF EXISTS #Q30

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q30				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  55015

				CREATE INDEX IX_#Q30_PK_Distributor ON #Q30(PK_Distributor);	

				--Q31	List ID 55016 ("24014_New 4 Diamonds")
					 
				DROP TABLE IF EXISTS #Q31

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q31				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  55016

				CREATE INDEX IX_#Q31_PK_Distributor ON #Q31(PK_Distributor);	

				--Q32	List ID 55132 ("24014_New 1 K Level")
					 
				DROP TABLE IF EXISTS #Q32

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q32				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  55132

				CREATE INDEX IX_#Q32_PK_Distributor ON #Q32(PK_Distributor);	

				--Q33	List ID 55133 ("24014_New 2 K Levels")
					 
				DROP TABLE IF EXISTS #Q33

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q33				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 55133 

				CREATE INDEX IX_#Q33_PK_Distributor ON #Q33(PK_Distributor);	

				--Q34	List ID 55134 ("24014_New 3 K Levels")
					 
				DROP TABLE IF EXISTS #Q34

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q34				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 55134 

				CREATE INDEX IX_#Q34_PK_Distributor ON #Q34(PK_Distributor);	

				--Q35	List ID 55135 ("24014_New 4 K Levels")
					 
				DROP TABLE IF EXISTS #Q35

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q35				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  55135

				CREATE INDEX IX_#Q35_PK_Distributor ON #Q35(PK_Distributor);	

				--Q36	List ID 55136 ("24014_New 5 K Levels")
					 
				DROP TABLE IF EXISTS #Q36

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q36				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  55136

				CREATE INDEX IX_#Q36_PK_Distributor ON #Q36(PK_Distributor);	


				--Q38 "New GSP (Team Qual date from Mar 01 2023 to Feb 01 2024)
				--List ID 57089 (""24014_New GSP"")"
				
				DROP TABLE IF EXISTS #Q38

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q38				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  57089

				CREATE INDEX IX_#Q38_PK_Distributor ON #Q38(PK_Distributor);	

				--Q40	"List ID 57767 (""24014_CN New SSP"")
				--New SSP (Team Qual date from Mar 01 2023 to Feb 01 2024)"

				DROP TABLE IF EXISTS #Q40

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q40			 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  57767

				CREATE INDEX IX_#Q40_PK_Distributor ON #Q40(PK_Distributor);	

				--Q41	"List ID 57768 (""24014_CN New SSSP"")
				--New SSSP (Team Qual date from Mar 01 2023 to Feb 01 2024)"
								
				DROP TABLE IF EXISTS #Q41

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q41				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  57768

				CREATE INDEX IX_#Q41_PK_Distributor ON #Q41(PK_Distributor);

				--Q42	"List ID 57769 (""24014_CN New A"")
				--New A (Team Qual date from Mar 01 2023 to Feb 01 2024)"
				
				
				DROP TABLE IF EXISTS #Q42

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q42				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  57769

				CREATE INDEX IX_#Q42_PK_Distributor ON #Q42(PK_Distributor);

				--Q43	"List ID 57770 (""24014_CN New STAR"")
				--New STAR (Team Qual date from Mar 01 2023 to Feb 01 2024)"
				
				
				DROP TABLE IF EXISTS #Q43

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q43				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 57770 

				CREATE INDEX IX_#Q43_PK_Distributor ON #Q43(PK_Distributor);

				--Q44	List ID 57814 ("24014_China qualifiers")

				
				DROP TABLE IF EXISTS #Q44

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q44				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID =  57814

				CREATE INDEX IX_#Q44_PK_Distributor ON #Q44(PK_Distributor);

				--Q45	List ID 57815 ("24014_BSP")
				
				DROP TABLE IF EXISTS #Q45

				SELECT S.nDistributorID AS PK_Distributor
					INTO #Q45				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 57815 

				CREATE INDEX IX_#Q45_PK_Distributor ON #Q45(PK_Distributor);	


				--BRD v8
				/*
					E17	New Mil Team	Q46 (List ID 58627 ("24014_New Mil Team"))
					E18	New Mil Team 7500	Q47 (List ID 58628 ("24014_New Mil Team 7500"))
					E19	New Pres Team	Q48 (List ID 58629 ("24014_New Pres Team")
					E20	New 15K	Q49 (List ID 58630 ("24014_New 15K"))
					E21	New 20K	Q50 (List ID 58631 ("24014_New 20K"))
					E22	New 30K	Q51 (List ID 58632 ("24014_New 30K"))
					E23	New 40K	Q52 (List ID 58633 ("24014_New 40K"))
					E24	New 1 Diamond	Q53 (List ID 58634 ("24014_New 1 Diamond"))
					E25	New 2 Diamond	Q54 (List ID 58635 ("24014_New 2 Diamond"))
					E26	New 3 Diamond	Q55 (List ID 58636 ("24014_New 3 Diamond"))
					E27	New 4 Diamond	Q56 (List ID 58637 ("24014_New 4 Diamond"))
					E28	New Presidential Plus 250K	Q57 (List ID 58638 ("24014_New Presidential Plus 250K"))
					E29	New Presidential Plus 500K	Q58 (List ID 58639 ("24014_New Presidential Plus 500K"))
					E30	Diamond Qualifiers	Q59 (List ID 58640 ("24014_Diamond Qualifiers"))
					E31	3 AWT Stars	Q60 (List ID 58641 ("24014_3 AWT Stars pin"))
					E32	4 AWT Stars	Q61 (List ID 58642 ("24014_4 AWT Stars pin"))
					E33	5 AWT Stars	Q62 (List ID 58643 ("24014_5 AWT Stars pin"))
					E34	6 AWT Stars	Q63 (List ID 58644 ("24014_6 AWT Stars pin"))
					E35	7 AWT Stars	Q64 (List ID 58645 ("24014_7 AWT Stars pin"))
					E36	8 AWT Stars	Q65 (List ID 58646 ("24014_8 AWT Stars pin"))
					E37	9 AWT Stars	Q66 (List ID 58647 ("24014_9 AWT Stars pin"))
					E38	10 AWT Stars	Q67 (List ID 58648 ("24014_10 AWT Stars pin"))
					E39	DO NOT RECOGNIZE	Q68 (List ID 58649 ("24014_DO NOT RECOGNIZE"))

				
				*/

				DROP TABLE IF EXISTS #E17

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E17				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58627

				CREATE INDEX IX_#E17_PK_Distributor ON #E17(PK_Distributor);

				DROP TABLE IF EXISTS #E18

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E18				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58628

				CREATE INDEX IX_#E18_PK_Distributor ON #E18(PK_Distributor);

				DROP TABLE IF EXISTS #E19

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E19				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58629

				CREATE INDEX IX_#E19_PK_Distributor ON #E19(PK_Distributor);

				DROP TABLE IF EXISTS #E20

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E20				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58630

				CREATE INDEX IX_#E20_PK_Distributor ON #E20(PK_Distributor);

				DROP TABLE IF EXISTS #E21

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E21				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58631

				CREATE INDEX IX_#E21_PK_Distributor ON #E21(PK_Distributor);

				DROP TABLE IF EXISTS #E22

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E22				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58632

				CREATE INDEX IX_#E22_PK_Distributor ON #E22(PK_Distributor);

				DROP TABLE IF EXISTS #E23

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E23				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58633

				CREATE INDEX IX_#E23_PK_Distributor ON #E23(PK_Distributor);

				DROP TABLE IF EXISTS #E24

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E24				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58634

				CREATE INDEX IX_#E24_PK_Distributor ON #E24(PK_Distributor);

				DROP TABLE IF EXISTS #E25

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E25				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58635

				CREATE INDEX IX_#E25_PK_Distributor ON #E25(PK_Distributor);

				DROP TABLE IF EXISTS #E26

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E26				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58636

				CREATE INDEX IX_#E26_PK_Distributor ON #E26(PK_Distributor);

				DROP TABLE IF EXISTS #E27

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E27				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58637

				CREATE INDEX IX_#E27_PK_Distributor ON #E27(PK_Distributor);

				DROP TABLE IF EXISTS #E28

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E28				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58638

				CREATE INDEX IX_#E28_PK_Distributor ON #E28(PK_Distributor);

				DROP TABLE IF EXISTS #E29

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E29				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58639

				CREATE INDEX IX_#E29_PK_Distributor ON #E29(PK_Distributor);

				DROP TABLE IF EXISTS #E30

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E30				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58640

				CREATE INDEX IX_#E30_PK_Distributor ON #E30(PK_Distributor);

				DROP TABLE IF EXISTS #E31

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E31				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58641

				CREATE INDEX IX_#E31_PK_Distributor ON #E31(PK_Distributor);

				DROP TABLE IF EXISTS #E32

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E32				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58642

				CREATE INDEX IX_#E32_PK_Distributor ON #E32(PK_Distributor);

				DROP TABLE IF EXISTS #E33

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E33				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58643

				CREATE INDEX IX_#E33_PK_Distributor ON #E33(PK_Distributor);

				DROP TABLE IF EXISTS #E34

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E34				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58644

				CREATE INDEX IX_#E34_PK_Distributor ON #E34(PK_Distributor);

				DROP TABLE IF EXISTS #E35

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E35				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58645

				CREATE INDEX IX_#E35_PK_Distributor ON #E35(PK_Distributor);

				DROP TABLE IF EXISTS #E36

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E36				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58646

				CREATE INDEX IX_#E36_PK_Distributor ON #E36(PK_Distributor);

				DROP TABLE IF EXISTS #E37

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E37				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58647

				CREATE INDEX IX_#E37_PK_Distributor ON #E37(PK_Distributor);

				DROP TABLE IF EXISTS #E38

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E38				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58648

				CREATE INDEX IX_#E38_PK_Distributor ON #E38(PK_Distributor);

				DROP TABLE IF EXISTS #E39

				SELECT S.nDistributorID AS PK_Distributor
					INTO #E39				 
				FROM dbo.v_DistributorSet AS S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 58649

				CREATE INDEX IX_#E39_PK_Distributor ON #E39(PK_Distributor);

				--Purchase SKU 1D79
				DROP TABLE IF EXISTS #E40

				SELECT S.PK_Distributor  
				INTO #E40				 
				FROM #DSSKUs AS S
				 
				CREATE INDEX IX_E40_PK_Distributor ON #E40(PK_Distributor);
							   				
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 7 AND [StepSubGroup] = 0;
			

		END

		--Step 8: Determine uplines
		IF @Step >= 8
		BEGIN

			PRINT 'Executing step 8'

			DROP TABLE IF EXISTS #Uplines

			CREATE TABLE #Uplines
			(
				 PK_Event							INT DEFAULT 195939
				,PK_Distributor						INT 
				,Q06								BIT DEFAULT 0
				,Q07								BIT DEFAULT 0
				,sSubTeam							VARCHAR(5) 
				,sTeam							    VARCHAR(5) 	
				,sDistributorCountryProcessingCode  VARCHAR(5) 
				,IsMainID							BIT DEFAULT 0
				,IsSpecialMainIDAssociation			BIT DEFAULT 0
				,FromListID							INT NULL
			)

			;WITH cte_uplines AS
			(
				SELECT 
					d.PK_Distributor, 
					IIF(q6.PK_Distributor IS NULL,0, 1) AS Q06, 
					IIF(q7.PK_Distributor IS NULL,0, 1) AS Q07,
					d.DSSubTeam, 
					d.DSCurrentTeam,
					d.CountryCode
				FROM #DS AS d
					LEFT JOIN #Q6 AS q6
						ON d.PK_Distributor = q6.PK_Distributor
					LEFT JOIN #Q7 AS q7
						ON d.PK_Distributor = q7.PK_Distributor
			 )

			 INSERT INTO #Uplines(PK_Distributor,Q06,Q07,sSubTeam,sTeam,sDistributorCountryProcessingCode)
			 SELECT PK_Distributor,Q06,Q07,DSSubTeam,DSCurrentTeam,CountryCode FROM cte_uplines WHERE Q06 = 1 OR Q07 = 1

			INSERT INTO #Uplines(PK_Distributor,sSubTeam,sTeam,sDistributorCountryProcessingCode,IsMainID)
			SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				D.sSubteam AS DSSubTeam,        
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,               
				D.sDistributorCountryProcessingCode AS CountryCode,
				1 AS IsMainID
			FROM [Shared].[DistributorAssociation] AS a WITH (NOLOCK)
				INNER JOIN v_Distributor AS d
					ON a.nMainDistributorID = d.nDistributorID
			WHERE Filter = 31 AND NOT EXISTS (SELECT 1 FROM #Uplines AS u WHERE u.PK_Distributor = D.nDistributorID)

			UPDATE d
			SET	IsMainID = 1
			FROM [Shared].[DistributorAssociation] AS a WITH (NOLOCK)
				INNER JOIN #Uplines AS d
					ON a.nMainDistributorID = d.PK_Distributor
			WHERE a.[Filter] = 31
			 
			INSERT INTO #Uplines(PK_Distributor,sSubTeam,sTeam,sDistributorCountryProcessingCode,IsSpecialMainIDAssociation)
			SELECT DISTINCT        
				D.nDistributorID AS PK_Distributor,   
				D.sSubteam AS DSSubTeam,        
				CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,               
				D.sDistributorCountryProcessingCode AS CountryCode,
				1 AS IsSpecialMainIDAssociation
			FROM [Shared].[DistributorAssociation] AS a WITH (NOLOCK)
				INNER JOIN v_Distributor AS d
					ON a.nMainDistributorID = d.nDistributorID
			WHERE Filter = 21 AND NOT EXISTS (SELECT 1 FROM #Uplines AS u WHERE u.PK_Distributor = a.PK_AssociatedID)

			UPDATE d
			SET	IsSpecialMainIDAssociation = 1
			FROM [Shared].[DistributorAssociation] AS a WITH (NOLOCK)
				INNER JOIN #Uplines AS d
					ON a.nMainDistributorID = d.PK_Distributor
			WHERE a.[Filter] = 21


		END

		--Step 9: Lineage
		IF  @Step >= 9
		BEGIN

			PRINT 'Executing step 9'

			IF (@Snapshot_Lineage_Date IS NULL OR @CurrentDate <= @Snapshot_Lineage_Date) -- Snapshot Lineage 
			BEGIN

			PRINT 'Getting lineage before Snapshot_Lineage_Date '

			INSERT INTO #TimeLog VALUES ('Lines', 9, 0, GETUTCDATE(), NULL);

				INSERT INTO #TimeLog VALUES ('FirstLine', 9, 1, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #FirstLine;

					SELECT 
						M.PK_Distributor,
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
						ON DL.PK_DSDownline = D.nDistributorID AND D.sType = 'SP'

					CREATE CLUSTERED INDEX [IX_FirstLine_PK_FirstLine] ON #FirstLine ([PK_FirstLine])

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 9 AND [StepSubGroup] = 1;

				INSERT INTO #TimeLog VALUES ('SecondLine', 9, 2, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #SecondLine;

					SELECT 
						L1.PK_Distributor	
						,L1.PK_FirstLine	
						,DL.PK_DSDownline [PK_SecondLine]
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
						ON DL.PK_DSDownline = D.nDistributorID AND D.sType = 'SP'
				  
					CREATE CLUSTERED INDEX [IX_SecondLine_PK_SecondLine] ON #SecondLine ([PK_SecondLine])
					CREATE NONCLUSTERED INDEX [IX_SecondLine_PK_FirstLine] ON #SecondLine ([PK_FirstLine])

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 9 AND [StepSubGroup] = 2;

				INSERT INTO #TimeLog VALUES ('ThirdLine', 9, 3, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #ThirdLine;

					SELECT 
						 L2.PK_Distributor
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
						ON DL.PK_DSDownline = D.nDistributorID AND D.sType = 'SP'

					CREATE CLUSTERED INDEX [IX_ThirdLine_PK_ThirdLine] ON #ThirdLine ([PK_ThirdLine])

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 9 AND [StepSubGroup] = 3;		

				/* INSERT ALL DOWNLINES TO LINEAGE TABLE */

				INSERT INTO #TimeLog VALUES ('Lineage', 9, 4, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #Lineage;
								
					SELECT 
						L1.PK_Distributor
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
				WHERE [StepGroup] = 9 AND [StepSubGroup] = 4;

				IF @IsDevQA = 0
				BEGIN
					
					INSERT INTO #TimeLog VALUES ('WRK SNAPSHOOT', 9, 5, GETUTCDATE(), NULL);

					/* CREATING WORK TABLES FOR SNAPSHOOT */ 

					DROP TABLE IF EXISTS dbo.WRK_Lineage_HerbalifeSummit2024

					CREATE TABLE [dbo].[WRK_Lineage_HerbalifeSummit2024]
					(
						 [CreatedDateUTC] [datetime]	NULL DEFAULT (getutcdate())
						,[CreatedBy] [varchar](50)		NULL DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) 
						,[ModifiedDateUTC] [datetime]	NULL DEFAULT (getutcdate())
						,[ModifiedBy] [varchar](50)		NULL DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) 
						,PK_Distributor					INT
						,PK_FirstDownLine				INT   
						,PK_SecondDownLine				INT  
						,PK_ThirdDownLine				INT  
					)


					INSERT INTO dbo.WRK_Lineage_HerbalifeSummit2024 
					(
							PK_Distributor				
						,PK_FirstDownLine			
						,PK_SecondDownLine			
						,PK_ThirdDownLine						
					)	
					SELECT 
					PK_Distributor				
					,PK_FirstDownLine			
					,PK_SecondDownLine			
					,PK_ThirdDownLine			
					FROM #Lineage

					CREATE CLUSTERED INDEX [IX_WRK_Lineage_HerbalifeSummit2024_PK_Distributor] ON [dbo].[WRK_Lineage_HerbalifeSummit2024] ([PK_Distributor])

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 9 AND [StepSubGroup] = 5;

				END 
				ELSE
				BEGIN

					PRINT 'Creating temp tables for lineage'

					INSERT INTO #TimeLog VALUES ('Temp SNAPSHOOT', 9, 6, GETUTCDATE(), NULL);

					DROP TABLE IF EXISTS #WRK_Lineage_HerbalifeSummit2024

					CREATE TABLE #WRK_Lineage_HerbalifeSummit2024
					(
						PK_Distributor					INT
						,PK_FirstDownLine				INT   
						,PK_SecondDownLine				INT  
						,PK_ThirdDownLine				INT  
					)					

					INSERT INTO #WRK_Lineage_HerbalifeSummit2024 
					(
							PK_Distributor				
						,PK_FirstDownLine			
						,PK_SecondDownLine			
						,PK_ThirdDownLine						
					)	
					SELECT 
					PK_Distributor				
					,PK_FirstDownLine			
					,PK_SecondDownLine			
					,PK_ThirdDownLine			
					FROM #Lineage

					CREATE CLUSTERED INDEX [IX_#WRK_Lineage_HerbalifeSummit2024_PK_Distributor] ON #WRK_Lineage_HerbalifeSummit2024([PK_Distributor])

					UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
					WHERE [StepGroup] = 9 AND [StepSubGroup] = 6;

				END

				UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
				WHERE [StepGroup] = 9 AND [StepSubGroup] = 0;

		END
		
			INSERT INTO #TimeLog VALUES ('Lineage', 9, 7, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #LineageIDsUnique;

				CREATE TABLE #LineageIDsUnique
				(
					PK_Distributor INT
				)
			
				IF @IsDevQA = 0
				BEGIN

					INSERT INTO #LineageIDsUnique(PK_Distributor)
					SELECT L.PK_Distributor
					FROM
					(
							SELECT PK_FirstDownline [PK_Distributor]
								FROM dbo.WRK_Lineage_HerbalifeSummit2024 WITH (NOLOCK)
							UNION
							SELECT PK_SecondDownLine [PK_Distributor]
								FROM dbo.WRK_Lineage_HerbalifeSummit2024 WITH (NOLOCK)
							UNION
							SELECT PK_ThirdDownLine [PK_Distributor]
								FROM dbo.WRK_Lineage_HerbalifeSummit2024 WITH (NOLOCK)
					) L

					
				END
				ELSE
				BEGIN

					INSERT INTO #LineageIDsUnique(PK_Distributor)
					SELECT L.PK_Distributor
					FROM
					(
							SELECT PK_FirstDownline [PK_Distributor]
								FROM #WRK_Lineage_HerbalifeSummit2024
							UNION
							SELECT PK_SecondDownLine [PK_Distributor]
								FROM #WRK_Lineage_HerbalifeSummit2024
							UNION
							SELECT PK_ThirdDownLine [PK_Distributor]
								FROM #WRK_Lineage_HerbalifeSummit2024
					) L
			 
				END

				CREATE INDEX IX_LineageIDsUnique_PK_Distributor ON #LineageIDsUnique(PK_Distributor)  
			
			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 9 AND [StepSubGroup] = 7;
		
		END

		--Stars contribution
		IF @Step >= 10
		BEGIN
		
			PRINT 'Executing step 10'

			/* GETTING DOWNLINES AWT */
			
			INSERT INTO #TimeLog VALUES ('Downlines_AWT', 10, 1, GETUTCDATE(), NULL);

				DROP TABLE IF EXISTS #AWT_Downlines;
				
				SELECT 
				T.PK_Distributor
				INTO #AWT_Downlines
				FROM  
						#LineageIDsUnique T  
				INNER JOIN  
						dbo.AWT A WITH (NOLOCK)
						ON T.PK_Distributor = A.PK_Distributor AND A.AWTYear = '2023' 

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 10 AND [StepSubGroup] = 1;

		/* GETTING TAB DOWNLINES, Freeze TAB Status as of Aug 2021 (2021-08-01)*/
			
		INSERT INTO #TimeLog VALUES ('TAB_Downlines', 10, 2, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #TAB_Downlines;

			SELECT
			T.PK_Distributor
			INTO #TAB_Downlines
			FROM
					#LineageIDsUnique T
			INNER JOIN
					dbo.v_DistributorHistory DH
			ON
					DH.nDistributorIDFK = T.[PK_Distributor]
					AND DH.nEventTypeLID BETWEEN 225 AND 241
					AND '2022-08-01' BETWEEN DH.dFrom AND DH.dThrough


			--Non-TAB
			DROP TABLE IF EXISTS #TABDownlines_List_IN

			CREATE TABLE #TABDownlines_List_IN(PK_Distributor int)

				INSERT INTO #TABDownlines_List_IN(PK_Distributor)
				SELECT
					S.nDistributorID AS PK_Distributor
				FROM dbo.v_DistributorSet S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 54848

			--TAB
			DROP TABLE IF EXISTS #TABDownlines_List_OUT

			CREATE TABLE #TABDownlines_List_OUT(PK_Distributor int)

			INSERT INTO #TABDownlines_List_OUT(PK_Distributor)
				SELECT
					S.nDistributorID AS PK_Distributor
				FROM dbo.v_DistributorSet S
				INNER JOIN dbo.v_Distributor D 
					ON S.nDistributorID = D.nDistributorID AND S.dThrough = '2049-12-31'
				WHERE S.nTypeLID = 54849

			INSERT INTO #TAB_Downlines(PK_Distributor)
				SELECT PK_Distributor FROM #TABDownlines_List_IN

			DELETE FROM #TAB_Downlines 
			WHERE PK_Distributor IN (SELECT PK_Distributor FROM #TABDownlines_List_OUT)

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 10 AND [StepSubGroup] = 2;
			
		/* GETTING DOWNLINES FROM CHINA*/
			
		INSERT INTO #TimeLog VALUES ('China_Downlines', 10, 3, GETUTCDATE(), NULL);

			DROP TABLE IF EXISTS #China_Downlines;

			SELECT
			T.PK_Distributor
			INTO #China_Downlines
			FROM #LineageIDsUnique T
			INNER JOIN dbo.v_Distributor D
			ON D.nDistributorID = T.[PK_Distributor] AND  D.nDistributorCountryProcessingID = 590004 --China

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 10 AND [StepSubGroup] = 3;
	
		/* GETTING FIRST LINE CONTRIBUTION */  
	
		DROP TABLE IF EXISTS #Contribution_L1;

		CREATE TABLE #Contribution_L1
		(
			PK_Distributor INT,
			PK_FirstDownLine INT
		)

		IF @IsDevQA = 0
		BEGIN

			INSERT INTO #TimeLog VALUES ('Contribution_L1', 10, 41, GETUTCDATE(), NULL);

				INSERT INTO #Contribution_L1(PK_Distributor,PK_FirstDownLine)
				SELECT 
				l.PK_Distributor,l.PK_FirstDownLine
				FROM  
				dbo.WRK_Lineage_HerbalifeSummit2024 l WITH (NOLOCK) 
					INNER JOIN #Uplines u
						ON l.PK_Distributor = u.PK_Distributor
				WHERE 
				NOT EXISTS (SELECT 1 FROM #China_Downlines dc WHERE dc.PK_Distributor = l.PK_FirstDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #TAB_Downlines dc WHERE dc.PK_Distributor = l.PK_FirstDownLine)
				AND
				EXISTS (SELECT 1 FROM #AWT_Downlines awt WHERE awt.PK_Distributor = l.PK_FirstDownLine)
				AND 
				NOT EXISTS (SELECT 1 FROM #Associated W WHERE W.nMainAssociatedID = l.PK_FirstDownline)
				GROUP BY l.PK_Distributor,l.PK_FirstDownLine

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 10 AND [StepSubGroup] = 41;
		END
		ELSE
		BEGIN
		
			INSERT INTO #TimeLog VALUES ('Contribution_L1', 10, 1, GETUTCDATE(), NULL);
						
					INSERT INTO #Contribution_L1(PK_Distributor,PK_FirstDownLine)
					SELECT 
					l.PK_Distributor,l.PK_FirstDownLine
					FROM #WRK_Lineage_HerbalifeSummit2024 l WITH (NOLOCK) 
						INNER JOIN #Uplines u
							ON l.PK_Distributor = u.PK_Distributor
					WHERE 
					NOT EXISTS (SELECT 1 FROM #China_Downlines dc WHERE dc.PK_Distributor = l.PK_FirstDownLine)
					AND
					NOT EXISTS (SELECT 1 FROM #TAB_Downlines dc WHERE dc.PK_Distributor = l.PK_FirstDownLine)
					AND
					EXISTS (SELECT 1 FROM #AWT_Downlines awt WHERE awt.PK_Distributor = l.PK_FirstDownLine)
					AND 
					NOT EXISTS (SELECT 1 FROM #Associated W WHERE W.nMainAssociatedID = l.PK_FirstDownline)
					GROUP BY l.PK_Distributor,l.PK_FirstDownLine

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 10 AND [StepSubGroup] = 1;
		
		END

		/* GETTING SECOND LINE CONTRIBUTION */  
		
		DROP TABLE IF EXISTS #Contribution_L2;

		CREATE TABLE #Contribution_L2
		(
			PK_Distributor INT,
			PK_FirstDownLine INT,
			PK_SecondDownLine INT
		)

		IF @IsDevQA = 0
		BEGIN

			INSERT INTO #TimeLog VALUES ('Contribution_L2', 10, 42, GETUTCDATE(), NULL);

				INSERT INTO #Contribution_L2(PK_Distributor,PK_FirstDownLine,PK_SecondDownLine)
				SELECT 
				l.PK_Distributor,l.PK_FirstDownLine, l.PK_SecondDownLine
				FROM  
				dbo.WRK_Lineage_HerbalifeSummit2024 l WITH (NOLOCK) 
					INNER JOIN #Uplines u
						ON l.PK_Distributor = u.PK_Distributor 
				WHERE
				NOT EXISTS (SELECT 1 FROM #China_Downlines dc WHERE dc.PK_Distributor = l.PK_SecondDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #TAB_Downlines dc WHERE dc.PK_Distributor = l.PK_FirstDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #TAB_Downlines dc WHERE dc.PK_Distributor = l.PK_SecondDownLine)
				AND
				EXISTS (SELECT 1 FROM #AWT_Downlines awt WHERE awt.PK_Distributor = l.PK_SecondDownLine )
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_SecondDownLine = l1.PK_FirstDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_FirstDownLine = l1.PK_FirstDownLine)
				AND 
				NOT EXISTS (SELECT 1 FROM #Associated W WHERE W.nMainAssociatedID = l.PK_SecondDownLine)
				GROUP BY l.PK_Distributor,l.PK_FirstDownLine, l.PK_SecondDownLine

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 10 AND [StepSubGroup] = 42;

		END
		ELSE
		BEGIN
			
			INSERT INTO #TimeLog VALUES ('Contribution_L2', 10, 42, GETUTCDATE(), NULL);

				INSERT INTO #Contribution_L2(PK_Distributor,PK_FirstDownLine,PK_SecondDownLine)
				SELECT 
				l.PK_Distributor,l.PK_FirstDownLine, l.PK_SecondDownLine
				FROM #WRK_Lineage_HerbalifeSummit2024 l WITH (NOLOCK) 
					INNER JOIN #Uplines u
						ON l.PK_Distributor = u.PK_Distributor 
				WHERE
				NOT EXISTS (SELECT 1 FROM #China_Downlines dc WHERE dc.PK_Distributor = l.PK_SecondDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #TAB_Downlines dc WHERE dc.PK_Distributor = l.PK_FirstDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #TAB_Downlines dc WHERE dc.PK_Distributor = l.PK_SecondDownLine)
				AND
				EXISTS (SELECT 1 FROM #AWT_Downlines awt WHERE awt.PK_Distributor = l.PK_SecondDownLine )
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_SecondDownLine = l1.PK_FirstDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_FirstDownLine = l1.PK_FirstDownLine)
				AND 
				NOT EXISTS (SELECT 1 FROM #Associated W WHERE W.nMainAssociatedID = l.PK_SecondDownLine)
				GROUP BY l.PK_Distributor,l.PK_FirstDownLine, l.PK_SecondDownLine

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 10 AND [StepSubGroup] = 42;

		END

		/* GETTING THIRD LINE CONTRIBUTION */  
		
		DROP TABLE IF EXISTS #Contribution_L3;

		CREATE TABLE #Contribution_L3
		(
			PK_Distributor INT,
			PK_FirstDownLine INT,
			PK_SecondDownLine INT,
			PK_ThirdDownLine INT
		)

		IF @IsDevQA = 0
		BEGIN

			INSERT INTO #TimeLog VALUES ('Contribution_L3', 10, 3, GETUTCDATE(), NULL);
				
				INSERT INTO #Contribution_L3(PK_Distributor,PK_FirstDownLine,PK_SecondDownLine,PK_ThirdDownLine)
				SELECT 
				l.PK_Distributor,l.PK_FirstDownLine, l.PK_SecondDownLine, l.PK_ThirdDownLine
				FROM  
				dbo.WRK_Lineage_HerbalifeSummit2024 l WITH (NOLOCK) 
					INNER JOIN #Uplines u
						ON l.PK_Distributor = u.PK_Distributor 
				WHERE
				NOT EXISTS (SELECT 1 FROM #China_Downlines dc WHERE dc.PK_Distributor = l.PK_ThirdDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #TAB_Downlines dc WHERE dc.PK_Distributor = l.PK_ThirdDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #TAB_Downlines dc WHERE dc.PK_Distributor = l.PK_SecondDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #TAB_Downlines dc WHERE dc.PK_Distributor = l.PK_FirstDownLine)
				AND
				EXISTS (SELECT 1 FROM #AWT_Downlines awt WHERE awt.PK_Distributor = l.PK_ThirdDownLine )
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_ThirdDownLine = l1.PK_FirstDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L2 l2 WHERE l.PK_ThirdDownLine = l2.PK_SecondDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_FirstDownLine = l1.PK_FirstDownLine)
				AND
				NOT EXISTS (SELECT 1 FROM #Contribution_L2 l2 WHERE l.PK_SecondDownLine = l2.PK_SecondDownLine)
				AND 
				NOT EXISTS (SELECT 1 FROM #Associated W WHERE W.nMainAssociatedID = l.PK_ThirdDownLine)
				GROUP BY l.PK_Distributor,l.PK_FirstDownLine, l.PK_SecondDownLine,l.PK_ThirdDownLine

			UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
			WHERE [StepGroup] = 10 AND [StepSubGroup] = 3;
					
		END
		ELSE
		BEGIN
			INSERT INTO #TimeLog VALUES ('Contribution_L3', 10, 3, GETUTCDATE(), NULL);

			INSERT INTO #Contribution_L3(PK_Distributor,PK_FirstDownLine,PK_SecondDownLine,PK_ThirdDownLine)
			SELECT 
			l.PK_Distributor,l.PK_FirstDownLine, l.PK_SecondDownLine, l.PK_ThirdDownLine
			FROM #WRK_Lineage_HerbalifeSummit2024 l WITH (NOLOCK) 
				INNER JOIN #Uplines u
					ON l.PK_Distributor = u.PK_Distributor 
			WHERE
			NOT EXISTS (SELECT 1 FROM #China_Downlines dc WHERE dc.PK_Distributor = l.PK_ThirdDownLine)
			AND
			NOT EXISTS (SELECT 1 FROM #TAB_Downlines dc WHERE dc.PK_Distributor = l.PK_ThirdDownLine)
			AND
			NOT EXISTS (SELECT 1 FROM #TAB_Downlines dc WHERE dc.PK_Distributor = l.PK_SecondDownLine)
			AND
			NOT EXISTS (SELECT 1 FROM #TAB_Downlines dc WHERE dc.PK_Distributor = l.PK_FirstDownLine)
			AND
			EXISTS (SELECT 1 FROM #AWT_Downlines awt WHERE awt.PK_Distributor = l.PK_ThirdDownLine )
			AND
			NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_ThirdDownLine = l1.PK_FirstDownLine)
			AND
			NOT EXISTS (SELECT 1 FROM #Contribution_L2 l2 WHERE l.PK_ThirdDownLine = l2.PK_SecondDownLine)
			AND
			NOT EXISTS (SELECT 1 FROM #Contribution_L1 l1 WHERE l.PK_FirstDownLine = l1.PK_FirstDownLine)
			AND
			NOT EXISTS (SELECT 1 FROM #Contribution_L2 l2 WHERE l.PK_SecondDownLine = l2.PK_SecondDownLine)
			AND 
			NOT EXISTS (SELECT 1 FROM #Associated W WHERE W.nMainAssociatedID = l.PK_ThirdDownLine)
			GROUP BY l.PK_Distributor,l.PK_FirstDownLine, l.PK_SecondDownLine,l.PK_ThirdDownLine

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 10 AND [StepSubGroup] = 3;

		END

		/* GETTING UPLINE STARS */

		INSERT INTO #TimeLog VALUES ('UplinesStars', 11, 1, GETUTCDATE(), NULL);

			INSERT INTO #UplinesStars (PK_Distributor,FirstLineCount,SecondLineCount,ThirdLineCount)
			SELECT U.PK_Distributor
					,ISNULL(L1.Stars,0) [FirstLineCount]
					,ISNULL(L2.Stars,0) [SecondLineCount]
					,ISNULL(L3.Stars,0) [ThirdLineCount]
			FROM #Uplines U
			LEFT JOIN
				(	
					SELECT
					PK_Distributor,
					COUNT(PK_FirstDownLine) AS Stars
					FROM
						#Contribution_L1
					GROUP BY
						PK_Distributor
				) L1	
			ON 
				L1.PK_Distributor = U.PK_Distributor
			LEFT JOIN
				(	
					SELECT
					PK_Distributor,
					COUNT(PK_SecondDownLine) AS Stars
					FROM
						#Contribution_L2
					GROUP BY
						PK_Distributor
				) L2	
			ON 
				L2.PK_Distributor = U.PK_Distributor
			LEFT JOIN
				(	
					SELECT
					PK_Distributor,
					COUNT(PK_ThirdDownLine) AS Stars
					FROM
						#Contribution_L3
					GROUP BY
						PK_Distributor
				) L3	
			ON 
				L3.PK_Distributor = U.PK_Distributor

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 11 AND [StepSubGroup] = 1;

		/* ADDING MAIN ASSOCIATED STARS TO ASSOCIATED IDs */

		INSERT INTO #TimeLog VALUES ('UplinesStars', 11, 2, GETUTCDATE(), NULL);

			UPDATE
					T
			SET
					T.AssociatedGuaranteedStars = ISNULL(B.FirstLineCount,0), 
					T.AssociatedPotentialsStars = ISNULL(B.SecondLineCount,0) + ISNULL(B.ThirdLineCount,0)
			FROM
					#Associated T
			INNER JOIN
				#UplinesStars B
			ON
				T.nMainAssociatedID = B.PK_Distributor

			UPDATE
					T
			SET
					T.AssociatedGuaranteedStars =  A.AssociatedGuaranteedStars,
					T.AssociatedPotentialsStars = A.AssociatedPotentialsStars
			FROM
					#UplinesStars T
			INNER JOIN
					#Associated A
			ON
				T.PK_Distributor = A.nDistributorID 

			IF (@Potentials_Commitment_Date IS NULL OR @CurrentDate >= @Potentials_Commitment_Date)
			BEGIN
				
				UPDATE #UplinesStars
						SET PotentialsCommited =  Potentials
			END

			UPDATE #UplinesStars
			SET OverallCount = ISNULL(FirstLineCount,0)+ISNULL(AssociatedGuaranteedStars,0)+ISNULL(PotentialsCommited,0)
				
			--Force stars overallcount according to lists

			UPDATE D
			SET OverallCount = 	0			
			FROM dbo.v_DistributorSet S
			INNER JOIN #UplinesStars D 
				ON S.nDistributorID = D.PK_Distributor 
			WHERE S.nTypeLID = 54847 AND S.dThrough = '2049-12-31'

			UPDATE D
			SET OverallCount = 	1			
			FROM dbo.v_DistributorSet S
			INNER JOIN #UplinesStars D 
				ON S.nDistributorID = D.PK_Distributor 
			WHERE S.nTypeLID = 54846 AND S.dThrough = '2049-12-31'

			UPDATE D
			SET OverallCount = 2				
			FROM dbo.v_DistributorSet S
			INNER JOIN #UplinesStars D 
				ON S.nDistributorID = D.PK_Distributor 
			WHERE S.nTypeLID = 54845 AND S.dThrough = '2049-12-31'

			UPDATE D
			SET OverallCount = 3				
			FROM dbo.v_DistributorSet S
			INNER JOIN #UplinesStars D 
				ON S.nDistributorID = D.PK_Distributor 
			WHERE S.nTypeLID = 54844 AND S.dThrough = '2049-12-31'

			UPDATE D
			SET OverallCount = 4				
			FROM dbo.v_DistributorSet S
			INNER JOIN #UplinesStars D 
				ON S.nDistributorID = D.PK_Distributor 
			WHERE S.nTypeLID = 54843 AND S.dThrough = '2049-12-31'

			UPDATE D
			SET OverallCount = 5				
			FROM dbo.v_DistributorSet S
			INNER JOIN #UplinesStars D 
				ON S.nDistributorID = D.PK_Distributor 
			WHERE S.nTypeLID = 54842  AND S.dThrough = '2049-12-31'

			UPDATE D
			SET OverallCount = 6				
			FROM dbo.v_DistributorSet S
			INNER JOIN #UplinesStars D 
				ON S.nDistributorID = D.PK_Distributor 
			WHERE S.nTypeLID = 54841 AND S.dThrough = '2049-12-31'

			UPDATE D
			SET OverallCount = 7				
			FROM dbo.v_DistributorSet S
			INNER JOIN #UplinesStars D 
				ON S.nDistributorID = D.PK_Distributor 
			WHERE S.nTypeLID = 54840 AND S.dThrough = '2049-12-31'
				   
			UPDATE D
			SET OverallCount = 8				
			FROM dbo.v_DistributorSet S
			INNER JOIN #UplinesStars D 
				ON S.nDistributorID = D.PK_Distributor 
			WHERE S.nTypeLID = 54839  AND S.dThrough = '2049-12-31'

			UPDATE D
			SET OverallCount = 9				
			FROM dbo.v_DistributorSet S
			INNER JOIN #UplinesStars D 
				ON S.nDistributorID = D.PK_Distributor 
			WHERE S.nTypeLID = 54838 AND S.dThrough = '2049-12-31'

			UPDATE D
			SET OverallCount = 10				
			FROM dbo.v_DistributorSet S
			INNER JOIN #UplinesStars D 
				ON S.nDistributorID = D.PK_Distributor 
			WHERE S.nTypeLID = 54837 AND S.dThrough = '2049-12-31'

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 11 AND [StepSubGroup] = 2;

		END
		
		-- #EventQual Qualifications
		IF @Step >= 11
		BEGIN

			PRINT 'Executing step 11'

			INSERT INTO #EventQual(PK_Event,PK_Distributor,Q01,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30,Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q40,Q41,Q42,Q43,Q44,Q45)
			SELECT 
				195939 AS PK_Event,
				d.PK_Distributor, 
				IIF(q1.PK_Distributor IS NULL,0,1) AS Q01, 
				IIF(q6.PK_Distributor IS NULL,0,1) AS Q06,
				IIF(q7.PK_Distributor IS NULL,0,1) AS Q07,
				IIF(q8.PK_Distributor IS NULL,0,1) AS Q08,
				CASE WHEN ISNULL(us.OverallCount, 0) >= 10 THEN 1 ELSE 0 END [Q09],
				CASE WHEN ISNULL(us.OverallCount, 0) = 9 THEN 1 ELSE 0 END   [Q10],
				CASE WHEN ISNULL(us.OverallCount, 0) = 8 THEN 1 ELSE 0 END   [Q11],
				CASE WHEN ISNULL(us.OverallCount, 0) = 7 THEN 1 ELSE 0 END   [Q12],
				CASE WHEN ISNULL(us.OverallCount, 0) = 6 THEN 1 ELSE 0 END   [Q13],
				CASE WHEN ISNULL(us.OverallCount, 0) = 5 THEN 1 ELSE 0 END   [Q14],
				CASE WHEN ISNULL(us.OverallCount, 0) = 4 THEN 1 ELSE 0 END   [Q15],
				CASE WHEN ISNULL(us.OverallCount, 0) = 3 THEN 1 ELSE 0 END   [Q16],	
				CASE WHEN ISNULL(us.OverallCount, 0) = 2 THEN 1 ELSE 0 END   [Q17],	
				CASE WHEN ISNULL(us.OverallCount, 0) = 1 THEN 1 ELSE 0 END   [Q18],	
				CASE WHEN ISNULL(us.OverallCount, 0) = 0 THEN 1 ELSE 0 END   [Q19],
				IIF(q20.PK_Distributor IS NULL,0,1) AS Q20,
				IIF(q21.PK_Distributor IS NULL,0,1) AS Q21,
				IIF(q22.PK_Distributor IS NULL,0,1) AS Q22,
				IIF(q23.PK_Distributor IS NULL,0,1) AS Q23,
				IIF(q24.PK_Distributor IS NULL,0,1) AS Q24,
				IIF(q25.PK_Distributor IS NULL,0,1) AS Q25,
				IIF(q26.PK_Distributor IS NULL,0,1) AS Q26,
				IIF(q27.PK_Distributor IS NULL,0,1) AS Q27,
				IIF(q28.PK_Distributor IS NULL,0,1) AS Q28,
				IIF(q29.PK_Distributor IS NULL,0,1) AS Q29,
				IIF(q30.PK_Distributor IS NULL,0,1) AS Q30,
				IIF(q31.PK_Distributor IS NULL,0,1) AS Q31,
				IIF(q32.PK_Distributor IS NOT NULL AND q33.PK_Distributor IS NULL AND q34.PK_Distributor IS NULL AND q35.PK_Distributor IS NULL AND q36.PK_Distributor IS NULL,1,0) AS Q32,
				IIF(q33.PK_Distributor IS NOT NULL AND q34.PK_Distributor IS NULL AND q35.PK_Distributor IS NULL AND q36.PK_Distributor IS NULL,1,0) AS Q33,
				IIF(q34.PK_Distributor IS NOT NULL AND q35.PK_Distributor IS NULL AND q36.PK_Distributor IS NULL,1,0) AS Q34,
				IIF(q35.PK_Distributor IS NOT NULL AND q36.PK_Distributor IS NULL,1,0) AS Q35,
				IIF(q36.PK_Distributor IS NOT NULL,1,0) AS Q36,
				IIF(d.CountryCode = 'CN' AND D.DSCurrentTeam IN ('P','A','B','C'),1,0) AS Q37,
				IIF(Q38.PK_Distributor IS NULL,0,1) AS Q38,
				IIF(Q40.PK_Distributor IS NULL,0,1) AS Q40,
				IIF(Q41.PK_Distributor IS NULL,0,1) AS Q41,
				IIF(Q42.PK_Distributor IS NULL,0,1) AS Q42,
				IIF(Q43.PK_Distributor IS NULL,0,1) AS Q43,
				IIF(Q44.PK_Distributor IS NULL,0,1) AS Q44,
				IIF(Q45.PK_Distributor IS NULL,0,1) AS Q45
			FROM #DS AS d
				LEFT JOIN #UplinesStars AS us
					ON D.PK_Distributor = us.PK_Distributor
				LEFT JOIN #Q1 AS q1
					ON d.PK_Distributor = q1.PK_Distributor
				LEFT JOIN #Q6 AS q6
					ON d.PK_Distributor = q6.PK_Distributor
				LEFT JOIN #Q7 AS q7
					ON d.PK_Distributor = q7.PK_Distributor
				LEFT JOIN #Q08 AS q8
					ON d.PK_Distributor = q8.PK_Distributor
				LEFT JOIN #Q20 AS Q20
					 ON d.PK_Distributor = Q20.PK_Distributor
				LEFT JOIN #Q21 AS Q21
					 ON d.PK_Distributor = Q21.PK_Distributor
				LEFT JOIN #Q22 AS Q22
					 ON d.PK_Distributor = Q22.PK_Distributor
				LEFT JOIN #Q23 AS Q23
					 ON d.PK_Distributor = Q23.PK_Distributor
				LEFT JOIN #Q24 AS Q24
					 ON d.PK_Distributor = Q24.PK_Distributor
				LEFT JOIN #Q25 AS Q25
					 ON d.PK_Distributor = Q25.PK_Distributor
				LEFT JOIN #Q26 AS Q26
					 ON d.PK_Distributor = Q26.PK_Distributor
				LEFT JOIN #Q27 AS Q27
					 ON d.PK_Distributor = Q27.PK_Distributor
				LEFT JOIN #Q28 AS Q28
					 ON d.PK_Distributor = Q28.PK_Distributor
				LEFT JOIN #Q29 AS Q29
					 ON d.PK_Distributor = Q29.PK_Distributor
				LEFT JOIN #Q30 AS Q30
					 ON d.PK_Distributor = Q30.PK_Distributor
				LEFT JOIN #Q31 AS Q31
					 ON d.PK_Distributor = Q31.PK_Distributor
				LEFT JOIN #Q32 AS Q32
					 ON d.PK_Distributor = Q32.PK_Distributor
				LEFT JOIN #Q33 AS Q33
					 ON d.PK_Distributor = Q33.PK_Distributor
				LEFT JOIN #Q34 AS Q34
					 ON d.PK_Distributor = Q34.PK_Distributor
				LEFT JOIN #Q35 AS Q35
					 ON d.PK_Distributor = Q35.PK_Distributor
				LEFT JOIN #Q36 AS Q36
					 ON d.PK_Distributor = Q36.PK_Distributor
				LEFT JOIN #Q38 AS Q38
					 ON d.PK_Distributor = Q38.PK_Distributor	
				LEFT JOIN #Q40 AS Q40
					 ON d.PK_Distributor = Q40.PK_Distributor	
				LEFT JOIN #Q41 AS Q41
					 ON d.PK_Distributor = Q41.PK_Distributor	
				LEFT JOIN #Q42 AS Q42
					 ON d.PK_Distributor = Q42.PK_Distributor	
				LEFT JOIN #Q43 AS Q43
					 ON d.PK_Distributor = Q43.PK_Distributor	
				LEFT JOIN #Q44 AS Q44
					 ON d.PK_Distributor = Q44.PK_Distributor	
				LEFT JOIN #Q45 AS Q45
					 ON d.PK_Distributor = Q45.PK_Distributor	
				WHERE NOT EXISTS (SELECT 1 FROM [Shared].[DistributorAssociation] AS A WITH (NOLOCK) WHERE d.PK_Distributor = A.nMainDistributorID AND A.AssociationType = 3)
				 
		END

		-- #EventQual SubEvents
		IF @Step >= 12
		BEGIN

			PRINT 'Executing step 12'

			--E01
			--Q6 OR (Q1 + Q8) OR Q20 OR Q37
			--(Q06 | (Q01 & Q08)| Q20 | Q37)
			UPDATE #EventQual
			SET
				E01 = (Q06 | (Q01 & Q08)| Q20 | Q37 )
				
			--E03
			--List ID: 54829 OR (Q9 & Q6) OR (Q9 & Q1 & Q8 & Q7)
			--(Q09 & Q06) | (Q09 & Q01 & Q08 & Q07))
			UPDATE 
				#EventQual
			SET
				E03 = ((Q09 & Q06) | (Q09 & Q01 & Q08 & Q07))

			--List ID: 54829
			UPDATE 
				#EventQual
			SET
				E03 = 1
			FROM #EventQual AS E
				INNER JOIN #E03 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			--E04
			--List ID: 54830 OR (Q10 & Q6) OR(Q10 & Q1 & Q8 & Q7)
			--(Q10 & Q06) | (Q10 & Q01 & Q08 & Q07)
			UPDATE 
				#EventQual
			SET
				E04 = (~E03) & ((Q10 & Q06) | (Q10 & Q01 & Q08 & Q07)) 


			--List ID: 54830
			UPDATE 
				#EventQual
			SET
				E04 = 1
			FROM #EventQual AS E
				INNER JOIN #E04 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			--E05
			--List ID: 54831 OR (Q11 & Q6) OR (Q11 & Q1 & Q8 & Q7)
			--(Q11 & Q06) | (Q11 & Q01 & Q08 & Q07)			
			UPDATE 
				#EventQual
			SET
				E05 = (~E03 & ~E04) & ((Q11 & Q06) | (Q11 & Q01 & Q08 & Q07)) 

			--List ID: 54831
			UPDATE 
				#EventQual
			SET
				E05 = 1
			FROM #EventQual AS E
				INNER JOIN #E05 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			--E06
			--List ID: 54832 OR (Q12 & Q6) OR (Q12 & Q1 & Q8 & Q7)
			--(Q12 & Q06) | (Q12 & Q01 & Q08 & Q07)
			UPDATE 
				#EventQual
			SET
				E06 = (~E03 & ~E04 & ~E05) & ((Q12 & Q06) | (Q12 & Q01 & Q08 & Q07)) 

			--List ID: 54832
			UPDATE 
				#EventQual
			SET
				E06 = 1
			FROM #EventQual AS E
				INNER JOIN #E06 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			--E07
			--List ID: 54834 OR (Q13 & Q6) OR (Q13 & Q1 & Q8 & Q7)
			--(Q13 & Q06) | (Q13 & Q01 & Q08 & Q07)
			UPDATE 
				#EventQual
			SET
				E07 = (~E03 & ~E04 & ~E05 & ~E06) & ((Q13 & Q06) | (Q13 & Q01 & Q08 & Q07)) 

				--List ID: 54834
			UPDATE 
				#EventQual
			SET
				E07 = 1
			FROM #EventQual AS E
				INNER JOIN #E07 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			--E08
			--List ID: 54834 OR (Q14 & Q6) OR (Q14 & Q1 & Q8 & Q7)
			--(Q14 & Q06) | (Q14 & Q01 & Q08 & Q07)
			UPDATE 
				#EventQual
			SET
				E08 = (~E03 & ~E04 & ~E05 & ~E06 & ~E07) & ((Q14 & Q06) | (Q14 & Q01 & Q08 & Q07))
	
				--List ID: 54834
			UPDATE 
				#EventQual
			SET
				E08 = 1
			FROM #EventQual AS E
				INNER JOIN #E08 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			--E09
			--List ID: 54835 OR (Q15 & Q6) OR (Q15 & Q1 & Q8 & Q7)
			--(Q15 & Q06) | (Q15 & Q01 & Q08 & Q07)
			UPDATE 
				#EventQual
			SET
				E09 = (~E03 & ~E04 & ~E05 & ~E06 & ~E07 & ~E08) & ((Q15 & Q06) | (Q15 & Q01 & Q08 & Q07)) 

			--List ID: 54835
			UPDATE 
				#EventQual
			SET
				E09 = 1
			FROM #EventQual AS E
				INNER JOIN #E09 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			--E10
			--List ID: 54836 OR (Q16 & Q6) OR (Q16 & Q1 & Q8 & Q7)
			--(Q16 & Q06) | (Q16 & Q01 & Q08 & Q07)
			UPDATE 
				#EventQual
			SET
				E10 = (~E03 & ~E04 & ~E05 & ~E06 & ~E07 & ~E09) & ((Q16 & Q06) | (Q16 & Q01 & Q08 & Q07)) 

			--List ID: 54836
			UPDATE 
				#EventQual
			SET
				E10 = 1
			FROM #EventQual AS E
				INNER JOIN #E10 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			--E02
			--E3 OR E4 OR E5 OR E6 OR E7 OR E8 OR E9 OR E10
			--(E03 | E04 | E05 | E06 | E07 | E08 | E09 | E10)
			UPDATE 
				#EventQual
			SET
				E02= (E03 | E04 | E05 | E06 | E07 | E08 | E09 | E10)

		
	
			--E13
			--(E1 + (Q27 OR Q38)) OR Q23 OR ((Q6 OR Q37) + (Q28 OR Q29 OR Q30 OR Q31)) OR ((Q6 OR Q37) + (Q32 OR Q33 OR OR Q34 OR Q35 OR Q36)) 
			--(E01 & (Q27 | Q38)) | Q23 | ((Q06 | Q37) & (Q28 | Q29 | Q30 | Q31)) | ((Q06 | Q37)  & (Q32 | Q33 |  Q34 | Q35 | Q36))  
			UPDATE 
				#EventQual
			SET
				E13= (((E01 & (Q27 | Q38 | Q42 | Q43))) | Q23 | ((Q06 | Q37) & (Q28 | Q29 | Q30 | Q31)) | ((Q06 | Q37)  & (Q32 | Q33 |  Q34 | Q35 | Q36))) 


			--E12
			--(E1 & Q26) OR Q22 
			--(E01 & Q26) | Q22  
			UPDATE 
				#EventQual
			SET
				E12= ((~E13) & (E01 & Q26) | Q22 | (E01 & Q41))

							--E11
			--(E1 & Q25) OR Q21
			--(E01 & Q25) | Q21 
			UPDATE 
				#EventQual
			SET
				E11= ((~E12 & ~E13) & (E01 & Q25) | Q21 | (E01 & Q40))

			--E14
			--Q24 
			--Q24
			UPDATE 
				#EventQual
			SET
				E14= (Q24)

			--E15
			--Q44 
			--Q44
			UPDATE 
				#EventQual
			SET
				E15= (Q44)

			--E16
			--Q45 
			--Q45
			UPDATE 
				#EventQual
			SET
				E16= (Q45)

			--///////////////////////////////////------------------BRD v8
			
		
			UPDATE 
				#EventQual
			SET
				E17 = 1
			FROM #EventQual AS E
				INNER JOIN #E17 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E18 = 1
			FROM #EventQual AS E
				INNER JOIN #E18 AS Q
					ON E.PK_Distributor = Q.PK_Distributor
									   					 
			UPDATE 
				#EventQual
			SET
				E19 = 1
			FROM #EventQual AS E
				INNER JOIN #E19 AS Q
					ON E.PK_Distributor = Q.PK_Distributor
									   
			UPDATE 
				#EventQual
			SET
				E20 = 1
			FROM #EventQual AS E
				INNER JOIN #E20 AS Q
					ON E.PK_Distributor = Q.PK_Distributor
									   
			UPDATE 
				#EventQual
			SET
				E21 = 1
			FROM #EventQual AS E
				INNER JOIN #E21 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E22 = 1
			FROM #EventQual AS E
				INNER JOIN #E22 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E23 = 1
			FROM #EventQual AS E
				INNER JOIN #E23 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E24 = 1
			FROM #EventQual AS E
				INNER JOIN #E24 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E25 = 1
			FROM #EventQual AS E
				INNER JOIN #E25 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E26 = 1
			FROM #EventQual AS E
				INNER JOIN #E26 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E27 = 1
			FROM #EventQual AS E
				INNER JOIN #E27 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E28 = 1
			FROM #EventQual AS E
				INNER JOIN #E28 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E29 = 1
			FROM #EventQual AS E
				INNER JOIN #E29 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E30 = 1
			FROM #EventQual AS E
				INNER JOIN #E30 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E31 = 1
			FROM #EventQual AS E
				INNER JOIN #E31 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E32 = 1
			FROM #EventQual AS E
				INNER JOIN #E32 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E33 = 1
			FROM #EventQual AS E
				INNER JOIN #E33 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E34 = 1
			FROM #EventQual AS E
				INNER JOIN #E34 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E35 = 1
			FROM #EventQual AS E
				INNER JOIN #E35 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E36 = 1
			FROM #EventQual AS E
				INNER JOIN #E36 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E37 = 1
			FROM #EventQual AS E
				INNER JOIN #E37 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E38 = 1
			FROM #EventQual AS E
				INNER JOIN #E38 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E39 = 1
			FROM #EventQual AS E
				INNER JOIN #E39 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E40 = 1
			FROM #EventQual AS E
				INNER JOIN #E40 AS Q
					ON E.PK_Distributor = Q.PK_Distributor

			UPDATE 
				#EventQual
			SET
				E41= (Q06 | E14)

			UPDATE 
				#EventQual
			SET
				E42= (E31 | E32 | E33 | E34 | E35 | E36 | E37 | E38)


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
							~Q46  & ~Q47 & ~Q48 & ~Q49 & ~Q50 & 
							~Q51 
						)= 1

		END

		--[Event].[DSQual]	
		IF @Step >= 13
		BEGIN
			
			PRINT 'Executing step 13'

			IF @IsDevQA = 0
			BEGIN

				DELETE dq			
				FROM [Event].[DSQual] AS dq
				WHERE PK_Event = @PK_Event

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
					,Q51
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
					,E51
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
				,Q51
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
				,E51
			FROM #EventQual
			
			END

		END

		--SubEventQualifiers
		IF @Step >= 14  AND @IsDevQA = 0
		BEGIN

				PRINT 'Executing step 14'

				EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
				@Events = @PK_Event,
				@Source = 2,
				@MaxQualNumber = 51,
				@EvaluateFormula = 0
		END

		--WRK tables
		IF @Step >= 15 AND @IsDevQA = 0
		BEGIN
					
			PRINT 'Executing step 15'

			DROP TABLE IF EXISTS dbo.WRK_Uplines_HerbalifeSummit2024;	
			DROP TABLE IF EXISTS dbo.WRK_Contribution_L1_HerbalifeSummit2024;
			DROP TABLE IF EXISTS dbo.WRK_Contribution_L2_HerbalifeSummit2024;
			DROP TABLE IF EXISTS dbo.WRK_Contribution_L3_HerbalifeSummit2024;
			DROP TABLE IF EXISTS dbo.WRK_DSLists_HerbalifeSummit2024;	
			DROP TABLE IF EXISTS dbo.WRK_UplinesStars_HerbalifeSummit2024;
			DROP TABLE IF EXISTS dbo.WRK_TABDownlines_HerbalifeSummit2024;

			--WRK_Uplines
			SELECT 
				PK_Event							
				,PK_Distributor													
				,Q06								
				,Q07	
				,sSubTeam							
				,sTeam							    
				,sDistributorCountryProcessingCode  
				,IsMainID							
				,IsSpecialMainIDAssociation			
				,FromListID	
			INTO dbo.WRK_Uplines_HerbalifeSummit2024
			FROM #Uplines
			
			--WRK_Contribution_L1
			SELECT 
				PK_Distributor
			,PK_FirstDownLine
			INTO dbo.WRK_Contribution_L1_HerbalifeSummit2024
			FROM #Contribution_L1

			--WRK_Contribution_L2
			SELECT 
				PK_Distributor
			,PK_FirstDownLine
			,PK_SecondDownLine
			INTO dbo.WRK_Contribution_L2_HerbalifeSummit2024
			FROM #Contribution_L2
			
			--WRK_Contribution_L3
			SELECT 
				PK_Distributor
			,PK_FirstDownLine
			,PK_SecondDownLine
			,PK_ThirdDownLine
			INTO dbo.WRK_Contribution_L3_HerbalifeSummit2024
			FROM #Contribution_L3

			--WRK_DSLists_HerbalifeSummit2024
			SELECT 
				PK_Distributor
				,ListID
			INTO dbo.WRK_DSLists_HerbalifeSummit2024
			FROM #DSList			

			--WRK_UplinesStars_HerbalifeSummit2024
			SELECT 
				PK_Distributor					
			,FirstLineCount					
			,SecondLineCount				
			,ThirdLineCount					
			,AssociatedGuaranteedStars		
			,AssociatedPotentialsStars		
			,GuaranteedStars				
			,Potentials						
			,PotentialsCommited				
			,OverallCount					  
			INTO dbo.WRK_UplinesStars_HerbalifeSummit2024
			FROM #UplinesStars

			SELECT PK_Distributor
			INTO dbo.WRK_TABDownlines_HerbalifeSummit2024
			FROM #TAB_Downlines 

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

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
	END CATCH;
END;