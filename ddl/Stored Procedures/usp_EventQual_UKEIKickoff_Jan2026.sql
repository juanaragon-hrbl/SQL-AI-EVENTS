CREATE PROCEDURE [dbo].[usp_EventQual_UKEIKickoff_Jan2026]
		@PK_Event INT = 203318  						   
       -- Error Parameters
		,@Error	INT = NULL OUTPUT
		,@ErrorMessage VARCHAR(4000) = NULL OUTPUT

		-- QA/DEV
		,@IsDevQA TINYINT = 0
AS
BEGIN

/*********************************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_UKEIKickoff_Jan2026
	USE:		EXEC dbo.usp_EventQual_UKEIKickoff_Jan2026 
				@IsDevQA = 1
	DESCRIPTION:
	NOTES:		
	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1.0.0		2025-05-07	    rosarioo  		Initial 								 
	1.0.1		2025-06-16	    rosarioo  		BUG 1417858, BUG 1417861 & BUG 1417864
	2.0.0		2025-07-28	    rosarioo  		User Story 1421103: 26008 - UK EI Kick Off Jan 23-25 2026 - BRD V2, Adding E09 - Level 5
	3.0.0		2025-12-01	    rosarioo  		User Story 1435218: 26008 - UK EI Kick Off Jan 23-25 2026 - BRD V3
	4.0.0		2025-12-18		alejandramed	User Story 1436743: 26008 - UK EI Kick Off Jan 23-25 2026 - BRD V4
***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

DECLARE  @Month2 DATETIME  = '2025-10-01'
		,@Month3 DATETIME  = '2025-11-01'
		,@Month4 DATETIME  = '2025-12-01'
		,@Month5 DATETIME  = '2026-01-01'							   			 
		,@TVPs1 MONEY = 2500	
		,@TVPs2 MONEY = 15000	
		,@TVPs3 MONEY = 22500	
		,@TVPs4 MONEY = 30000	
		,@TVPs5 MONEY = 40000	--2.0.0
															   
		
		
BEGIN TRY   

	IF @IsDevQA= 2 THROW 60000, N'Unit test Error', 1;
	

	DROP TABLE IF EXISTS #EventQual	
	
	CREATE TABLE #EventQual	(
		PK_Event		INT,
		PK_Distributor	INT,
		CreatedDate		DATETIME,
		UpdatedDate		DATETIME,
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


	DROP TABLE IF EXISTS #Events

	CREATE TABLE #Events (
		PK_Event INT
	)								 
															 
	INSERT INTO #Events(PK_Event)
	VALUES (@PK_Event) 
			   		

	-- COPs
	DROP TABLE IF EXISTS #Countries

	CREATE TABLE #Countries	(
		PK_Event		INT,
		nCountryID		INT,   
		sCountryCode	VARCHAR(10), 
		sCountryCodeISO VARCHAR(10), 
		sCountryName	VARCHAR(150)
	)


	INSERT INTO #Countries(PK_Event,nCountryID,sCountryCode,sCountryCodeISO,sCountryName) 
	SELECT @PK_Event,nCountryID,sCountryCode,sCountryCodeISO,sCountryName
	FROM dbo.v_Countries
	WHERE sCountryCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar]('UK,EI', ','))
	
	CREATE INDEX [IX_#Countries_PKs] ON #Countries (nCountryID)

	-- Adding Lists
	DROP TABLE IF EXISTS #DSList

	CREATE TABLE #DSList(
		PK_Distributor INT
		,ListID INT
		,QId int
	)	
			
	DROP TABLE IF EXISTS #ListsIDs

	CREATE TABLE #ListsIDs(
		ListID INT,QId INT
	)

	INSERT INTO #ListsIDs(ListID,QId)
	VALUES (64945,1)
		 ,(64946,12)
		 ,(64947,13)
		 ,(64948,14)
		 ,(64953,15)
		 ,(64950,16)
		 ,(64951,17)
		 ,(64952,18)
		 ,(66357,20) -- 2.0.0
		 ,(67758,21) -- 3.0.0 --Q21	List PK_67758 - 26008_UK_Kickoff_2026_E7_AWT_2025
		 ,(67759,22) -- 3.0.0 --Q22	List PK_67759 - 26008_UK_Kickoff_2026_E10_ASP_2025

	
	INSERT INTO #DSList(PK_Distributor,ListID,QId)
	SELECT  S.nDistributorID AS PK_Distributor,
			S.nTypeLID AS ListID,l.QId
	FROM dbo.v_DistributorSet S
	INNER JOIN dbo.v_Distributor D 
		ON S.nDistributorID = D.nDistributorID 
		AND S.dThrough = '2049-12-31'
	INNER JOIN #ListsIDs l
		ON S.nTypeLID = l.ListID

	CREATE INDEX IX_#DSList_PK_Distributor ON #DSList(PK_Distributor) INCLUDE (QId,ListID);

	--Getting DS with ticket
	DROP TABLE IF EXISTS #DSSKUs

	CREATE TABLE #DSSKUs
	(
		PK_Distributor INT
		,PK_EventSKU INT
		,PK_Event INT
		,SKUCode VARCHAR(10)
		,UniqueID NVARCHAR(MAX)
		,IsEventTicketSKU BIT
	)	
				
	DROP TABLE IF EXISTS #SKUs

	CREATE TABLE #SKUs
	(
		ID INT IDENTITY(1,1),
		SKUCode VARCHAR(10),
		PK_Event INT,
		IsEventTicketSKU BIT
	)

	INSERT INTO #SKUs(PK_Event,SKUCode, IsEventTicketSKU)
	SELECT DISTINCT s.PK_Event, s.SKUCode, s.IsEventTicketSKU
			FROM [dbo].[EventSKU] AS s WITH (NOLOCK) 
	WHERE s.PK_Event = @PK_Event 

	INSERT INTO #DSSKUs(PK_Distributor,PK_EventSKU,PK_Event,SKUCode,UniqueID,IsEventTicketSKU)
	SELECT DISTINCT et.PK_Distributor_Purchaser,esku.PK_EventSKU, s.PK_Event, esku.SKUCode
	,CAST(s.PK_Event AS NVARCHAR(20)) + '-' + CAST(et.PK_Distributor_Purchaser AS NVARCHAR(20))+ '-'+ CAST(esku.SKUCode  AS NVARCHAR(20))  AS UniqueID 
	,s.IsEventTicketSKU
	FROM #SKUs AS s 
		INNER JOIN dbo.EventSKU AS esku WITH (NOLOCK)
			ON s.SKUCode = esku.SKUCode
			AND S.PK_Event = esku.PK_Event --1.0.1
		INNER JOIN [dbo].[SKUPurchased] et WITH (NOLOCK)
			ON et.PK_EventSKU = esku.PK_EventSKU
			AND et.PK_Event = esku.PK_Event --1.0.1

	CREATE INDEX IX_DSSKUs_PK_Distributor ON #DSSKUs(PK_Distributor)
				
				
-----------------------------------------------------------------------------------------------------------
	-- Potential Qualifiers

	DROP TABLE IF EXISTS #MBIDs
				   
	CREATE TABLE #MBIDs	(
		 PK_Distributor			INT
		,DSCurrentTeam			CHAR(5)
		,DSSubTeam				CHAR(5)
		,DSSPTeam				CHAR(5)
		,ApplicationDate		DATETIME	
		,SPQualDate				DATETIME		
		,SPRequalDate			DATETIME
		,CountryCode			CHAR(2)
		,IsFromCOP				BIT DEFAULT 0					
		,IsCOPandTeamLvl		BIT DEFAULT 0
		,IsAddedFromLists		BIT DEFAULT 0
		,IsAddedFromSKU			BIT DEFAULT 0	
		,Q02  BIT
		,Q03  BIT
		,Q04  BIT
		,Q05  BIT
		,Q11  BIT
	)

	INSERT INTO	#MBIDs
	SELECT DISTINCT
		D.nDistributorID AS PK_Distributor
		,CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam
		,D.sSubteam AS DSSubTeam
		,D.sType AS DSSPTeam
		,D.dApplication AS ApplicationDate 
		,D.dSupervisorqualification AS SPQualDate
		,D.dSupervisorReQualification AS SPRequalDate
		,D.sDistributorCountryProcessingCode AS CountryCode
		,1 AS IsFromCOP
		,1 AS IsCOPandTeamLvl									
		,0 AS IsAddedFromLists
		,0 AS IsAddedFromSKU
		,IIF(d.sType IN ('DS','SP'),1,0) AS Q02 --DS And Above
		,IIF(d.sType IN ('SP'),1,0) AS Q03 --SP And Above
		,IIF(d.sTeam IN ('P','A','B','C'),1,0) AS Q04 --PT Team --1.0.1
		,IIF(d.sTeam IN ('G','M','P','A','B','C'),1,0) AS Q05 --Tab Team--1.0.1
		,IIF(d.sDistributorCountryProcessingCode IN ('UK','EI'),1,0) AS Q11 -- COP: UK (United Kingdom), EI (Ireland)
	FROM dbo.v_Distributor D 									
	INNER JOIN #Countries C WITH (NOLOCK) 
			ON D.nDistributorCountryProcessingID = C.nCountryID												  
	WHERE D.sType IN ('DS','SP')
	AND D.StatusCode = 'COMPLETE'   


	-- Exception IDs from Lists 	
	INSERT INTO #MBIDs
	SELECT DISTINCT
		D.nDistributorID AS PK_Distributor
		,CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam
		,D.sSubteam AS DSSubTeam
		,D.sType AS DSSPTeam
		,D.dApplication AS ApplicationDate 
		,D.dSupervisorqualification AS SPQualDate
		,D.dSupervisorReQualification AS SPRequalDate
		,D.sDistributorCountryProcessingCode AS CountryCode
		,IIF(C.nCountryID IS NOT NULL, 1, 0)AS IsFromCOP
		,0 AS IsCOPandTeamLvl								
		,1 AS IsAddedFromLists
		,0 AS IsAddedFromSKU
		,IIF(d.sType IN ('DS','SP'),1,0) AS Q02 --DS And Above
		,IIF(d.sType IN ('SP'),1,0) AS Q03 --SP And Above
		,IIF(d.sTeam IN ('P','A','B','C'),1,0) AS Q04 --PT Team--1.0.1
		,IIF(d.sTeam IN ('G','M','P','A','B','C'),1,0) AS Q05 --Tab Team--1.0.1
		,IIF(d.sDistributorCountryProcessingCode IN ('UK','EI'),1,0) AS Q11 -- COP: UK (United Kingdom), EI (Ireland)
	FROM #DSList L
	INNER JOIN  dbo.v_Distributor D 	
		ON L.PK_Distributor = D.nDistributorID
	LEFT JOIN #Countries C WITH (NOLOCK) 
			ON D.nDistributorCountryProcessingID = C.nCountryID
	WHERE NOT EXISTS (SELECT 1 FROM #MBIDs M WHERE M.PK_Distributor = L.PK_Distributor) 


	--IDs with tickets 
	INSERT INTO	#MBIDs
	SELECT DISTINCT
		D.nDistributorID AS PK_Distributor
		,CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam
		,D.sSubteam AS DSSubTeam
		,D.sType AS DSSPTeam
		,D.dApplication AS ApplicationDate 
		,D.dSupervisorqualification AS SPQualDate
		,D.dSupervisorReQualification AS SPRequalDate
		,D.sDistributorCountryProcessingCode AS CountryCode
		,IIF(C.nCountryID IS NOT NULL, 1, 0)AS IsFromCOP
		,0 AS IsCOPandTeamLvl								
		,0 AS IsAddedFromLists
		,1 AS IsAddedFromSKU		
		,IIF(d.sType IN ('DS','SP'),1,0) AS Q02 --DS And Above
		,IIF(d.sType IN ('SP'),1,0) AS Q03 --SP And Above
		,IIF(d.sTeam IN ('P','A','B','C'),1,0) AS Q04 --PT Team--1.0.1
		,IIF(d.sTeam IN ('G','M','P','A','B','C'),1,0) AS Q05 --Tab Team--1.0.1
		,IIF(d.sDistributorCountryProcessingCode IN ('UK','EI'),1,0) AS Q11 -- COP: UK (United Kingdom), EI (Ireland)
	FROM dbo.v_Distributor AS D  
	INNER JOIN #DSSKUs AS S
		ON D.nDistributorID = S.PK_Distributor
	INNER JOIN #Countries C WITH (NOLOCK) 
			ON D.nDistributorCountryProcessingID = C.nCountryID
	WHERE NOT EXISTS (SELECT 1 FROM #MBIDs AS T WHERE T.PK_Distributor = S.PK_Distributor)

	CREATE INDEX IX_#MBIDs_PK_Distributor ON #MBIDs(PK_Distributor)


	INSERT INTO #EventQual(PK_Event, PK_Distributor, CreatedDate, UpdatedDate, Q02,Q03,Q04,Q05,Q11)		
	SELECT	A.PK_Event 
		   ,B.PK_Distributor 
		   ,GETUTCDATE() AS CreatedDate
		   ,GETUTCDATE() AS UpdatedDate
		   ,Q02
		   ,Q03
		   ,Q04
		   ,Q05
		   ,Q11
	FROM #Events A
	CROSS APPLY #MBIDs B

	CREATE INDEX IX_#EventQual_PK_Distributor ON #EventQual(PK_Distributor)

-----------------------------------------------------------------------------------------------------------
	-- Volume 
	DROP TABLE IF EXISTS #MBIDsPoints

	CREATE TABLE #MBIDsPoints(
		 PK_Distributor INT
		,dRoyaltyMonth  SMALLDATETIME
		,TVP			MONEY DEFAULT 0			   
		,RO				MONEY DEFAULT 0				
	)	

	INSERT INTO #MBIDsPoints(PK_Distributor, dRoyaltyMonth, TVP, RO)		
	SELECT 	T.PK_Distributor,				   
			A.dRoyaltyMonth,
			A.mVolumePoints AS TVP,
			(A.mRoyaltyOverrides + A.mMainRoyaltyOverrides) AS RO					
	FROM #MBIDs T
	INNER JOIN dbo.v_aggFQS_ID A WITH (NOLOCK)
		ON 	T.PK_Distributor = A.nDistributorID
	AND A.dRoyaltyMonth BETWEEN @Month2 AND @Month5							--  Qual Period : Oct 2025 - Jan 2026

	CREATE INDEX IX_#MBIDsPoints_PK_Distributor ON #MBIDsPoints(PK_Distributor)


	-- Q7 Achieve 2,500 TVP in 3 consecutive months between Sep 2025 and Jan 2026 --------------------------------------------
		DROP TABLE IF EXISTS #AchievedMonthsQ07

		SELECT PK_Distributor, COUNT(TVP) AS TotalMonths 
		INTO #AchievedMonthsQ07
		FROM #MBIDsPoints	WHERE dRoyaltyMonth BETWEEN @Month2 AND @Month4 AND TVP >= @TVPs1 GROUP BY PK_Distributor
		UNION SELECT PK_Distributor, COUNT(TVP) AS TotalMonths FROM #MBIDsPoints							 
			  WHERE dRoyaltyMonth BETWEEN @Month3 AND @Month5 AND TVP >= @TVPs1 GROUP BY PK_Distributor
																			 
	
 		DROP TABLE IF EXISTS #Q07
					  
		SELECT DISTINCT PK_Distributor
		INTO #Q07
		FROM #AchievedMonthsQ07
		WHERE TotalMonths = 3 
	
		CREATE INDEX IX_#Q07_PK_Distributor ON #Q07(PK_Distributor)

	-- Q8 Accumulate at least 15,000 TVP in 3 consecutive months between September 2025 to January 2026 VM --------------------------------------------
		DROP TABLE IF EXISTS #AccumulatedMonthsQ08

		SELECT PK_Distributor,IIF(SUM(TVP)>=@TVPs2,1,0) AS IsAccTVPs 
		INTO #AccumulatedMonthsQ08
		FROM #MBIDsPoints							 
			  WHERE dRoyaltyMonth BETWEEN @Month2 AND @Month4  GROUP BY PK_Distributor
		UNION SELECT PK_Distributor,IIF(SUM(TVP)>=@TVPs2,1,0) AS IsAccTVPs FROM #MBIDsPoints							 
			  WHERE dRoyaltyMonth BETWEEN @Month3 AND @Month5 GROUP BY PK_Distributor
																			 
	
 		DROP TABLE IF EXISTS #Q08
					  
		SELECT DISTINCT PK_Distributor
		INTO #Q08
		FROM #AccumulatedMonthsQ08
		WHERE IsAccTVPs = 1
	
		CREATE INDEX IX_#Q08_PK_Distributor ON #Q08(PK_Distributor)
																							   
	-- Q9 Accumulate at least 22,500 TVP in 3 consecutive months between September 2025 to January 2026 VM --------------------------------------------
		DROP TABLE IF EXISTS #AccumulatedMonthsQ09

		SELECT PK_Distributor,IIF(SUM(TVP)>=@TVPs3,1,0) AS IsAccTVPs 
		INTO #AccumulatedMonthsQ09
		FROM #MBIDsPoints							 
			  WHERE dRoyaltyMonth BETWEEN @Month2 AND @Month4  GROUP BY PK_Distributor
		UNION SELECT PK_Distributor,IIF(SUM(TVP)>=@TVPs3,1,0) AS IsAccTVPs FROM #MBIDsPoints							 
			  WHERE dRoyaltyMonth BETWEEN @Month3 AND @Month5 GROUP BY PK_Distributor
																			 
	
 		DROP TABLE IF EXISTS #Q09
					  
		SELECT DISTINCT PK_Distributor
		INTO #Q09
		FROM #AccumulatedMonthsQ09
		WHERE IsAccTVPs = 1
	
		CREATE INDEX IX_#Q09_PK_Distributor ON #Q09(PK_Distributor)

	-- Q10 Accumulate at least 30,000 TVP in 3 consecutive months between September 2025 to January 2026 VM --------------------------------------------
		DROP TABLE IF EXISTS #AccumulatedMonthsQ10

		SELECT PK_Distributor,IIF(SUM(TVP)>=@TVPs4,1,0) AS IsAccTVPs 
		INTO #AccumulatedMonthsQ10
		FROM #MBIDsPoints							 
			  WHERE dRoyaltyMonth BETWEEN @Month2 AND @Month4  GROUP BY PK_Distributor
		UNION SELECT PK_Distributor,IIF(SUM(TVP)>=@TVPs4,1,0) AS IsAccTVPs FROM #MBIDsPoints							 
			  WHERE dRoyaltyMonth BETWEEN @Month3 AND @Month5 GROUP BY PK_Distributor
																			 
	
 		DROP TABLE IF EXISTS #Q10
					  
		SELECT DISTINCT PK_Distributor
		INTO #Q10
		FROM #AccumulatedMonthsQ10
		WHERE IsAccTVPs = 1
	
		CREATE INDEX IX_#Q10_PK_Distributor ON #Q10(PK_Distributor)

	--  2.0.0: Q19	Accumulate at least 40,000 TVP in 3 consecutive months between September 2025 to January 2026 VM --------------------------------------------
		DROP TABLE IF EXISTS #AccumulatedMonthsQ19

		SELECT PK_Distributor,IIF(SUM(TVP)>=@TVPs5,1,0) AS IsAccTVPs 
		INTO #AccumulatedMonthsQ19
		FROM #MBIDsPoints							 
			  WHERE dRoyaltyMonth BETWEEN @Month2 AND @Month4  GROUP BY PK_Distributor
		UNION SELECT PK_Distributor,IIF(SUM(TVP)>=@TVPs5,1,0) AS IsAccTVPs FROM #MBIDsPoints							 
			  WHERE dRoyaltyMonth BETWEEN @Month3 AND @Month5 GROUP BY PK_Distributor
																			 
	
 		DROP TABLE IF EXISTS #Q19
					  
		SELECT DISTINCT PK_Distributor
		INTO #Q19
		FROM #AccumulatedMonthsQ19
		WHERE IsAccTVPs = 1
	
		CREATE INDEX IX_#Q19_PK_Distributor ON #Q19(PK_Distributor)
																						   
-----------------------------------------------------------------------------------------------------------
	-- Qualifications 						 
	
	UPDATE Q
	SET  Q07 = IIF(Q07.PK_Distributor IS NOT NULL, 1, 0)
		,Q08 = IIF(Q08.PK_Distributor IS NOT NULL, 1, 0)
		,Q09 = IIF(Q09.PK_Distributor IS NOT NULL, 1, 0)						  
		,Q10 = IIF(Q10.PK_Distributor IS NOT NULL, 1, 0)						  
		,Q06 = IIF(S.PK_Distributor IS NOT NULL, 1, 0) --Q06 - Purchase any ticket SKU from section # 9
		,Q19 = IIF(Q19.PK_Distributor IS NOT NULL, 1, 0) -- 2.0.0						  
	FROM #EventQual AS Q
	LEFT JOIN #Q07 AS Q07
		ON Q.PK_Distributor = Q07.PK_Distributor
	LEFT JOIN #Q08 AS Q08
		ON Q.PK_Distributor = Q08.PK_Distributor
	LEFT JOIN #Q09 AS Q09
		ON Q.PK_Distributor = Q09.PK_Distributor	
	LEFT JOIN #Q10 AS Q10
		ON Q.PK_Distributor = Q10.PK_Distributor
	LEFT JOIN #Q19 AS Q19 -- 2.0.0
		ON Q.PK_Distributor = Q19.PK_Distributor
	LEFT JOIN(SELECT DISTINCT PK_Distributor FROM #DSSKUs WHERE IsEventTicketSKU = 1) AS S
		ON Q.PK_Distributor = S.PK_Distributor				   
				
				
	-- Lists
	UPDATE A
	SET  Q01 = ISNULL(L.[1],0) 
		,Q12 = ISNULL(L.[12],0)						
		,Q13 = ISNULL(L.[13],0)						
		,Q14 = ISNULL(L.[14],0)						
		,Q15 = ISNULL(L.[15],0)						
		,Q16 = ISNULL(L.[16],0)						
		,Q17 = ISNULL(L.[17],0)						
		,Q18 = ISNULL(L.[18],0)						
		,Q20 = ISNULL(L.[20],0)		--2.0.0				
		,Q21 = ISNULL(L.[21],0)		--3.0.0				
		,Q22 = ISNULL(L.[22],0)		--3.0.0				
	FROM #EventQual A
	LEFT JOIN (
		SELECT  PK_Distributor, [1],[12],[13],[14],[15],[16],[17],[18],[20],[21],[22]
		FROM (SELECT  PK_Distributor, Qid AS ListQId, CAST(PK_Distributor AS NVARCHAR(20))+ '-' + CAST(ListID AS NVARCHAR(20)) AS UniqueID	FROM #DSList) P
		PIVOT (COUNT (UniqueID)	FOR ListQId IN ([1],[12],[13],[14],[15],[16],[17],[18],[20],[21],[22])) AS pvt	
	) L
	ON A.PK_Distributor = L.PK_Distributor


	--SKUS
	--Q23	Purchase SKU 2E86
	--Q24	Purchase SKU 42V7



	;WITH cte_Q23 AS 
	(
		SELECT PK_Distributor FROM #DSSKUs WHERE SKUCode = '2E86'
	),cte_Q24 AS 
	(
		SELECT PK_Distributor FROM #DSSKUs WHERE SKUCode = '42V7'
	) 

	UPDATE q
		SET Q23 = IIF(q23.PK_Distributor IS NULL,0,1),
			Q24 = IIF(q24.PK_Distributor IS NULL,0,1)
	FROM #EventQual AS q
		LEFT JOIN cte_Q23 AS q23
			ON q.PK_Distributor = q23.PK_Distributor
		LEFT JOIN cte_Q24 AS q24
			ON q.PK_Distributor = q24.PK_Distributor

	------ UPDATE SubEvents
	--General Training
	UPDATE #EventQual
	SET	 E01 =	(Q02 & Q06) | Q01							-- Q1 OR (Q2 + Q6) 
	
	--2.0.0 - Level 5
	UPDATE E9 
	SET	 E9.E09 =	(Q03 & Q19 & Q11) | Q20							-- (Q3 + Q19 + Q11) OR Q20
	FROM #EventQual E9

	--Level 4
	UPDATE E5 
	SET	 E5.E05 =	((Q03 & Q10 & Q11) | Q15) & ~E09				-- ((Q3 + Q10 + Q11) OR Q15) AND NOT EXISTS LEVEL 5
	FROM #EventQual E5
	
	--Level 3
	UPDATE E4 
	SET	 E4.E04 =	((Q03 & Q09 & Q11) | Q14) & ~E05 & ~E09				-- ((Q3 + Q9 + Q11) OR Q14) AND NOT EXISTS LEVEL 4,5
	FROM #EventQual E4

	--Level 2
	UPDATE E3 
	SET	 E3.E03 =	((Q03 & Q08 & Q11) | Q13) & ~E04 & ~E05 & ~E09		-- ((Q3 + Q8 + Q11) OR Q13) AND NOT EXISTS LEVEL 3,4,5
	FROM #EventQual E3

	--Level 1
	UPDATE E2 
	SET	 E2.E02 =	((Q03 & Q07 & Q11) | Q12) & ~E03 & ~E04 & ~E05 & ~E09	-- ((Q3 + Q7 + Q11) OR Q12) AND NOT EXISTS LEVEL 2,3,4,5
	FROM #EventQual E2

	--Saturday Drink Reception
	UPDATE #EventQual
	SET	 E06 =	Q04 | E02 | E03 | E04 | E05 | Q16 | E09							-- Q4 OR E2 OR E3 OR E4 OR E5 OR Q16 OR E09
	--Friday Leadership & Social drinks
	UPDATE #EventQual
	SET	 E07 =	Q04 | E05 | Q17 | E09  | Q21	--3.0.0							-- Q4 OR E5 OR Q17 OR E9 OR Q21
	--Saturday morning Supervisor School
	UPDATE #EventQual
	SET	 E08 =	Q03 | Q18														-- Q3 OR Q18
	-- Sunday Morning
	UPDATE #EventQual
	SET	 E10 =	Q22																-- Q22
	--NC Commitment			
	UPDATE #EventQual
	SET	 E11 =	(Q23)
	--H24 Games
	UPDATE #EventQual
	SET	 E12 =	(Q24)


	DELETE FROM #EventQual
	WHERE ( 
			~Q01  & ~Q02 & ~Q03 & ~Q04 & ~Q05 & ~Q06  & ~Q07 & ~Q08 & ~Q09 & ~Q10 &
			~Q11  & ~Q12 & ~Q13 & ~Q14 & ~Q15 &	~Q16  & ~Q17 & ~Q18 & ~Q19 & ~Q20 &
			~Q21  & ~Q22 & ~Q23 & ~Q24 & ~Q25 &	~Q26  & ~Q27 & ~Q28 & ~Q29 & ~Q30 &
			~Q31  & ~Q32 & ~Q33 & ~Q34 & ~Q35 &	~Q36  & ~Q37 & ~Q38 & ~Q39 & ~Q40 &
			~Q41  & ~Q42 & ~Q43 & ~Q44 & ~Q45 &	~Q46  & ~Q47 & ~Q48 & ~Q49 & ~Q50 
			)= 1				  


-------------------------------------------------------------------------------------------------------------
	-- WorkTables
	
	-- Insert into WRK_DSQual or Custom WorkTable as needed
	DELETE dbo.WRK_DSQual WHERE PK_Event = @PK_Event											 

	INSERT INTO dbo.WRK_DSQual(
		  PK_Event		
		  ,PK_Distributor	
		  ,CreatedDate	
		  ,UpdatedDate	
		  ,Q01, Q02, Q03, Q04, Q05, Q06, Q07, Q08, Q09, Q10
		  ,Q11, Q12, Q13, Q14, Q15, Q16, Q17, Q18, Q19, Q20
		  ,Q21, Q22, Q23, Q24, Q25, Q26, Q27, Q28, Q29, Q30
		  ,Q31, Q32, Q33, Q34, Q35, Q36, Q37, Q38, Q39, Q40
		  ,Q41, Q42, Q43, Q44, Q45, Q46, Q47, Q48, Q49, Q50
		  	  	   	    	 	  
		  ,E01, E02, E03, E04, E05, E06, E07, E08, E09, E10
		  ,E11, E12, E13, E14, E15, E16, E17, E18, E19, E20
		  ,E21, E22, E23, E24, E25, E26, E27, E28, E29, E30
		  ,E31, E32, E33, E34, E35, E36, E37, E38, E39, E40
		  ,E41, E42, E43, E44, E45, E46, E47, E48, E49, E50
	)	
	SELECT PK_Event		
		  ,PK_Distributor	
		  ,CreatedDate	
		  ,UpdatedDate	
		  ,Q01, Q02, Q03, Q04, Q05, Q06, Q07, Q08, Q09, Q10
		  ,Q11, Q12, Q13, Q14, Q15, Q16, Q17, Q18, Q19, Q20
		  ,Q21, Q22, Q23, Q24, Q25, Q26, Q27, Q28, Q29, Q30
		  ,Q31, Q32, Q33, Q34, Q35, Q36, Q37, Q38, Q39, Q40
		  ,Q41, Q42, Q43, Q44, Q45, Q46, Q47, Q48, Q49, Q50
		  	  	   	    	 	  
		  ,E01, E02, E03, E04, E05, E06, E07, E08, E09, E10
		  ,E11, E12, E13, E14, E15, E16, E17, E18, E19, E20
		  ,E21, E22, E23, E24, E25, E26, E27, E28, E29, E30
		  ,E31, E32, E33, E34, E35, E36, E37, E38, E39, E40
		  ,E41, E42, E43, E44, E45, E46, E47, E48, E49, E50	
    FROM #EventQual		  
                        
						
	-- INSERT INTO WRK_EventQual to be processed by usp_UpdateSubEventQualifierByWRKTBL
	IF OBJECT_ID('WRK_EventQual', 'U') IS NOT NULL DROP TABLE dbo.WRK_EventQual
                   
    SELECT PK_Event					
		  ,PK_Distributor	
		  ,CreatedDate	
		  ,UpdatedDate	
		  ,Q01, Q02, Q03, Q04, Q05, Q06, Q07, Q08, Q09, Q10
		  ,Q11, Q12, Q13, Q14, Q15, Q16, Q17, Q18, Q19, Q20
		  ,Q21, Q22, Q23, Q24, Q25, Q26, Q27, Q28, Q29, Q30
		  ,Q31, Q32, Q33, Q34, Q35, Q36, Q37, Q38, Q39, Q40
		  ,Q41, Q42, Q43, Q44, Q45, Q46, Q47, Q48, Q49, Q50
		  	  	   	    	 	  
		  ,E01, E02, E03, E04, E05, E06, E07, E08, E09, E10
		  ,E11, E12, E13, E14, E15, E16, E17, E18, E19, E20
		  ,E21, E22, E23, E24, E25, E26, E27, E28, E29, E30
		  ,E31, E32, E33, E34, E35, E36, E37, E38, E39, E40
		  ,E41, E42, E43, E44, E45, E46, E47, E48, E49, E50	
    INTO dbo.WRK_EventQual 
	FROM #EventQual

    CREATE CLUSTERED INDEX IX_WRK_EventQual_PK_Distributor ON dbo.WRK_EventQual (PK_Distributor)

-------------------------------------------------------------------------------------------------------------
	-- 	INSERT ON SubEventQualifier																				

	EXEC dbo.usp_UpdateSubEventQualifierByWRKTBL @PK_Event
  

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
	 
	END CATCH
END
