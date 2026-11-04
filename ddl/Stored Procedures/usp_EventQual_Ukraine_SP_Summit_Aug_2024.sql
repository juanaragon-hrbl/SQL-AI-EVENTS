CREATE PROCEDURE [dbo].[usp_EventQual_Ukraine_SP_Summit_Aug_2024]
	@PK_Event int = 200560
	--Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT
	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG, 4 REPORT
	,@Step SMALLINT = 7
 AS
 BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_Ukraine_SP_Summit_Aug_2024

	USE:		

			USE [PubEventManagement]
			GO
			DECLARE	@Error int,
					@ErrorMessage varchar(4000)

			EXEC dbo.usp_EventQual_Ukraine_SP_Summit_Aug_2024
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
	1.0.0	2024-06-25	JuanGue		Initial BRD v1.0
	***********************************************************************************************************************************/
	
	-- No qualification for volume

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
				
	SELECT @Error = 0, @ErrorMessage = '';	
	   
BEGIN TRY

	--Quals block
	BEGIN 
		
		--Variables and temp tables 
		BEGIN

		DECLARE @ProjectID INT = 24110

		DECLARE @ColumnToPivot NVARCHAR(MAX),
			@SqlStatement NVARCHAR(MAX)

		DECLARE 
			@Countries VARCHAR(MAX) = (SELECT sCountryCode FROM [PubEventManagement].[dbo].[v_Countries] WHERE sCountryName = 'Ukraine'), 		
			@SKUs VARCHAR(MAX) = (SELECT STRING_AGG(SKUCode,',') AS [SKUs] FROM [PubEventManagement].[dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = @PK_Event), 
			@IncludeDSOutsideEligibleMarketswithTicket BIT = 1 --DS outside elegible markets in 8.1 who purchase a ticket will appear as qualified for this event. 

		DROP TABLE IF EXISTS #ListsQsMapping

		CREATE TABLE #ListsQsMapping
		(
			ID INT IDENTITY(1,1),
			ListID INT,
			QId INT
		)
									
		INSERT INTO #ListsQsMapping(ListID,QId)
			VALUES 
				(60568,7),
				(60569,8),
				(60570,9),
				(60571,10),
				(60572,11),
				(60573,12),
				(60574,13),
				(60575,14)

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
			Q51  BIT DEFAULT 0,	Q52  BIT DEFAULT 0,	Q53  BIT DEFAULT 0,	Q54  BIT DEFAULT 0,	Q55  BIT DEFAULT 0,
			Q56  BIT DEFAULT 0,	Q57  BIT DEFAULT 0,	Q58  BIT DEFAULT 0,	Q59  BIT DEFAULT 0,	Q60  BIT DEFAULT 0,

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
		SELECT @PK_Event,'Lviv, Ukraine' 

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
				PK_Distributor			INT,
				DistributorID			VARCHAR(MAX),   
				DSCurrentTeam			VARCHAR(10),        
				DSSubTeam				VARCHAR(10),        
				DSSPTeam				VARCHAR(10),               
				dSPQualDate				DATETIME2,        
				CountryCode				VARCHAR(5),
				IsFromList				BIT DEFAULT(0),
				IsTicketPurchaser		BIT DEFAULT(0),
				IsFromCOP				BIT DEFAULT(0),
				NewSP_QualDate			DATETIME,
				NewWT_QualDate			DATETIME,
				NewGT_QualDate			DATETIME,
				NewAWT_QualDate			DATETIME,
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
	--Step 3: Getting team type from history
	IF @Step >= 3
	BEGIN

		PRINT 'Executing step 3'

		INSERT INTO #TimeLog VALUES ('Getting team type from history', 3, 1, GETUTCDATE(), NULL);

		DECLARE 
			@DateFrom DATETIME = '2023-09-01',
			@DateTo	  DATETIME = '2024-07-01'
		---------------------------------------------------------------------------------------------------
		-- Team Levels								
		-- New WT (for the first time ever) (Team Qual date Sep 2023 to Jul 2024)
		DROP TABLE IF EXISTS #FirstTime_WT

		SELECT DISTINCT D.PK_Distributor,MIN(H.dFrom) AS QualDate
		INTO #FirstTime_WT
		FROM #DS D 
		INNER JOIN dbo.v_DistributorHistory H 
			ON D.PK_Distributor = H.nDistributorIDFK 
			AND H.nEventTypeLID = 224			-- WT Team
			--AND H.dThrough = '2049-12-31'		-- Not necessarily active at the time
		GROUP BY D.PK_Distributor
		
		CREATE INDEX IX_#FirstTime_WT_PK_Distributor ON #FirstTime_WT(PK_Distributor);

	-- New GT (for the first time ever) (Team Qual date Sep 2023 to Jul 2024)
		DROP TABLE IF EXISTS #FirstTime_GT

		SELECT DISTINCT D.PK_Distributor,MIN(H.dFrom) AS QualDate
		INTO #FirstTime_GT
		FROM #DS D 
		INNER JOIN dbo.v_DistributorHistory H 
			ON D.PK_Distributor = H.nDistributorIDFK 
			AND H.nEventTypeLID = 225			-- Get Team
			--AND H.dThrough = '2049-12-31'		-- Not necessarily active at the time
		GROUP BY D.PK_Distributor
		
		CREATE INDEX IX_#FirstTime_GT_PK_Distributor ON #FirstTime_GT(PK_Distributor);																													 

	-- New AWT (for the first time ever) (Qual date Sep 2023 to Jul 2024)

		 DROP TABLE IF EXISTS #FirstTime_AWT 				  

		 SELECT  A.PK_Distributor, A.Qual_AWT QualDate
		 INTO #FirstTime_AWT
		 FROM AWT AS A WITH (NOLOCK)
		 INNER JOIN AWT_Qualifiers_Tracking AS B WITH (NOLOCK)
			ON A.PK_Distributor = B.PK_Distributor
			AND A.AWTYear = B.AWTYear
		 WHERE A.AWTYear IN (2023)  
		 AND A.PastAWT = 'No'				-- Not qualified on previous years
		 AND B.Jan = 0 AND B.Feb = 0 AND B.Mar = 0 AND B.Apr = 0 AND B.May = 0 AND B.Jun = 0 AND B.Jul = 0 AND B.Aug = 0						-- Not previously qualified on Jan 2022
		 AND A.Qual_AWT BETWEEN @DateFrom AND @DateTo
		 UNION
		 SELECT  A.PK_Distributor, A.Qual_AWT QualDate
		 FROM AWT AS A WITH (NOLOCK)
		 INNER JOIN AWT_Qualifiers_Tracking AS B WITH (NOLOCK)
			ON A.PK_Distributor = B.PK_Distributor
			AND A.AWTYear = B.AWTYear
		 WHERE A.AWTYear IN (2024)  
		 AND A.PastAWT = 'No'				-- Not qualified on previous years
		 AND A.Qual_AWT BETWEEN @DateFrom AND @DateTo
		EXCEPT -- Remove the DS that qualified previously
		SELECT  A.PK_Distributor, A.Qual_AWT QualDate
		 FROM AWT AS A WITH (NOLOCK)
		 INNER JOIN AWT_Qualifiers_Tracking AS B WITH (NOLOCK)
			ON A.PK_Distributor = B.PK_Distributor
			AND A.AWTYear = B.AWTYear
		 WHERE A.AWTYear IN (2024)  
		 AND A.PastAWT != 'No'				-- Not qualified on previous years
		 AND A.Qual_AWT BETWEEN @DateFrom AND @DateTo

		 CREATE INDEX IX_#FirstTime_AWT_PK_Distributor ON #FirstTime_AWT(PK_Distributor);

		UPDATE D
		SET D.NewWT_QualDate = WT.QualDate,
			D.NewGT_QualDate = GT.QualDate,
			D.NewAWT_QualDate = AWT.QualDate
		FROM #DS D
		LEFT JOIN #FirstTime_WT WT ON D.PK_Distributor = WT.PK_Distributor
		LEFT JOIN #FirstTime_GT GT ON D.PK_Distributor = GT.PK_Distributor
		LEFT JOIN #FirstTime_AWT AWT ON D.PK_Distributor = AWT.PK_Distributor

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 3 AND [StepSubGroup] = 1;
	END
	--Step 4: Qualifications
	IF @Step >= 4
	BEGIN
			
		PRINT 'Executing step 4'

		INSERT INTO #TimeLog VALUES ('Qualifications', 4, 1, GETUTCDATE(), NULL);

		INSERT INTO #EventQual(PK_Distributor,PK_Event,Q01,Q02,Q03,Q04,Q05,Q06)
			SELECT 
				PK_Distributor,
				@PK_Event AS [PK_Event],
				IIF(d.DSSPTeam = 'SP',1,0)								 AS Q01, -- FQS and Above
				IIF(d.DSCurrentTeam IN ('G','M','P'),1,0)				 AS Q02, -- TAB Team	
				IIF(d.dSPQualDate BETWEEN @DateFrom AND @DateTo,1,0)	 AS Q03, -- New SP (for the first time ever) (SP Qual date Sep 2023 to Jul 2024)	
				IIF(d.NewWT_QualDate BETWEEN @DateFrom AND @DateTo,1,0)  AS Q04, -- New WT (for the first time ever) (Team Qual date Sep 2023 to Jul 2024)	
				IIF(d.NewGT_QualDate BETWEEN @DateFrom AND @DateTo,1,0)  AS Q05, -- New GT (for the first time ever) (Team Qual date Sep 2023 to Jul 2024)	
				IIF(d.NewAWT_QualDate BETWEEN @DateFrom AND @DateTo,1,0) AS Q06  -- New AWT (for the first time ever) (Qual date Sep 2023 to Jul 2024)	
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
		PRINT '#SKUsQsMapping missing because this event does not have SKUs as qualifications end'
		------------------------------------------------------------------------------------------------
		-- Volume qualifications
		------------------------------------------------------------------------------------------------
		PRINT 'Volume qualifications missing because this event does not have SKUs as qualifications end'

		PRINT '#QualificationsMapping end'
		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 4 AND [StepSubGroup] = 1;

	END
			
	--Step 5: Subevents
	IF @Step >= 5
	BEGIN

		PRINT 'Executing step 5'

		INSERT INTO #TimeLog VALUES ('#EventQual', 5, 1, GETUTCDATE(), NULL);
				
			UPDATE 
				#EventQual
			SET
				E01 = (Q01 | Q07),
				E02 = (Q02 | Q08),
				E03 = (Q09),
				E04 = (Q10),
				E05 = (Q03 | Q11),
				E06 = (Q04 | Q12),
				E07 = (Q05 | Q13),
				E08 = (Q06 | Q14)

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
								~Q51  & ~Q52 & ~Q53 & ~Q54 & ~Q55 &
								~Q56  & ~Q57 & ~Q58 & ~Q59 & ~Q60 
							)= 1

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 5 AND [StepSubGroup] = 1;

	END

	--Step 6: [Event].[DSQual]	
	IF @Step >= 6
	BEGIN
			
		PRINT 'Executing step 6';

		INSERT INTO #TimeLog VALUES ('[Event].[DSQual]', 6, 1, GETUTCDATE(), NULL);

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

		END

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 6 AND [StepSubGroup] = 1;

	END

	--Step 7: SubEventQualifiers
	IF @Step >= 7 
	BEGIN

		INSERT INTO #TimeLog VALUES ('SubEventQualifier', 7, 1, GETUTCDATE(), NULL);

		IF @IsDevQA = 0
		BEGIN

			PRINT 'Executing step 6'
		
			DECLARE @Events VARCHAR(MAX)
				
			SELECT @Events = STRING_AGG(PK_Event,',') FROM #Locations

			EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
			@Events = @Events,
			@Source = 2,
			@EvaluateFormula = 0

		END

		UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [StepGroup] = 7 AND [StepSubGroup] = 1;

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