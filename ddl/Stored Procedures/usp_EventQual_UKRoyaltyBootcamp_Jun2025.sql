CREATE PROCEDURE [dbo].[usp_EventQual_UKRoyaltyBootcamp_Jun2025]
       -- Error Parameters
		 @Error	INT = NULL OUTPUT
		,@ErrorMessage VARCHAR(4000) = NULL OUTPUT

		-- QA/DEV
		,@IsDevQA TINYINT = 0
AS
BEGIN

/*********************************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_UKRoyaltyBootcamp_Jun2025
	USE:		EXEC dbo.usp_EventQual_UKRoyaltyBootcamp_Jun2025 
				@IsDevQA = 1
	DESCRIPTION:
	NOTES:		
	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1.0.0		2025-03-28	    puertac  		Initial 								 
	2.0.0		2025-05-12		puertac			BRD V2
***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

DECLARE  @PK_Event INT = 202873  						   
		,@Month4 DATETIME  = '2025-02-01'
		,@Month5 DATETIME  = '2025-03-01'
		,@Month6 DATETIME  = '2025-04-01'
		,@Month7 DATETIME  = '2025-05-01'
		,@Month8 DATETIME  = '2025-06-01'					   
		,@TVPs1 MONEY = 2500	
		,@TVPs2 MONEY = 15000	
		,@TVPs3 MONEY = 22500																
		,@TVPs4 MONEY = 30000					   
		
		
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
	)	
			
	DROP TABLE IF EXISTS #ListsIDs

	CREATE TABLE #ListsIDs(
		ListID INT
	)

	INSERT INTO #ListsIDs(ListID)
	VALUES (63200),(63201),(63202),(63203),(63204),(63205),(63206),(65646)

	INSERT INTO #DSList(PK_Distributor,ListID)
	SELECT  S.nDistributorID AS PK_Distributor,
			S.nTypeLID AS ListID
	FROM dbo.v_DistributorSet S
	INNER JOIN dbo.v_Distributor D 
		ON S.nDistributorID = D.nDistributorID 
		AND S.dThrough = '2049-12-31'
	INNER JOIN #ListsIDs l
		ON S.nTypeLID = l.ListID

	CREATE INDEX IX_#DSList_PK_Distributor ON #DSList(PK_Distributor);

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
	SELECT DISTINCT s.PK_Event, s.SKUCode
			FROM [dbo].[EventSKU] AS s WITH (NOLOCK) 
	WHERE s.PK_Event = @PK_Event AND s.PK_EventSKUType = 1 AND s.IsEventTicketSKU = 1 


	INSERT INTO #DSSKUs(PK_Distributor,PK_EventSKU,PK_Event,SKUCode,UniqueID)
	SELECT DISTINCT et.PK_Distributor_Purchaser,esku.PK_EventSKU, s.PK_Event, esku.SKUCode ,CAST(s.PK_Event AS NVARCHAR(20)) + '-' + CAST(et.PK_Distributor_Purchaser AS NVARCHAR(20))+ '-'+ CAST(esku.SKUCode  AS NVARCHAR(20))  AS UniqueID 
	FROM #SKUs AS s 
		INNER JOIN dbo.EventSKU AS esku WITH (NOLOCK)
			ON s.SKUCode = esku.SKUCode
		INNER JOIN [dbo].[SKUPurchased] et WITH (NOLOCK)
			ON et.PK_EventSKU = esku.PK_EventSKU

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
		,IsPT					BIT DEFAULT 0								  
		,IsTAB					BIT DEFAULT 0										  
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
		,IIF(D.sTeam IN ('P','A','B','C'), 1, 0) AS IsPT						
		,IIF(D.sTeam IN ('G','M','P','A','B','C'), 1, 0) AS IsTAB																									
	FROM dbo.v_Distributor D 									
	INNER JOIN #Countries C WITH (NOLOCK) 
			ON D.nDistributorCountryProcessingID = C.nCountryID												  
	WHERE D.sType = 'SP'								
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
		,IIF(D.sTeam IN ('P','A','B','C'), 1, 0) AS IsPT						
		,IIF(D.sTeam IN ('G','M','P','A','B','C'), 1, 0) AS IsTAB		
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
		,IIF(D.sTeam IN ('P','A','B','C'), 1, 0) AS IsPT						
		,IIF(D.sTeam IN ('G','M','P','A','B','C'), 1, 0) AS IsTAB									
	FROM dbo.v_Distributor AS D  
	INNER JOIN #DSSKUs AS S
		ON D.nDistributorID = S.PK_Distributor
	LEFT JOIN #Countries C WITH (NOLOCK) 
			ON D.nDistributorCountryProcessingID = C.nCountryID
	WHERE NOT EXISTS (SELECT 1 FROM #MBIDs AS T WHERE T.PK_Distributor = S.PK_Distributor)

	CREATE INDEX IX_#MBIDs_PK_Distributor ON #MBIDs(PK_Distributor)



	INSERT INTO #EventQual(PK_Event, PK_Distributor, CreatedDate, UpdatedDate, Q01, Q02, Q03, Q08)		
	SELECT	A.PK_Event 
		   ,B.PK_Distributor 
		   ,GETUTCDATE() AS CreatedDate
		   ,GETUTCDATE() AS UpdatedDate
		   ,1 AS Q01											 
		   ,B.IsPT AS Q02
		   ,B.IsTAB AS Q03	
		   ,B.IsFromCOP AS Q08
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
	AND A.dRoyaltyMonth BETWEEN @Month4 AND @Month8							-- Only Qual Period A: Feb 2025 - June 2025

	CREATE INDEX IX_#MBIDsPoints_PK_Distributor ON #MBIDsPoints(PK_Distributor)


	-- Q4 Achieve 2500 TVP in 3 consecutive volume months during Feb 2025 - June 2025 --------------------------------------------
	DROP TABLE IF EXISTS #AchievedQ4

		SELECT PK_Distributor,COUNT(TVP) AS TotalMonths
	INTO #AchievedQ4
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month4 AND @Month6 AND TVP >= @TVPs1
		GROUP BY PK_Distributor
	UNION SELECT PK_Distributor, COUNT(TVP) AS TotalMonths FROM #MBIDsPoints
		  WHERE dRoyaltyMonth BETWEEN @Month5 AND @Month7 AND TVP >= @TVPs1 GROUP BY PK_Distributor																																								  
	UNION SELECT PK_Distributor, COUNT(TVP) AS TotalMonths FROM #MBIDsPoints
		  WHERE dRoyaltyMonth BETWEEN @Month6 AND @Month8 AND TVP >= @TVPs1 GROUP BY PK_Distributor

   
	DROP TABLE IF EXISTS #Q04

	SELECT DISTINCT PK_Distributor
	INTO #Q04
	FROM #AchievedQ4
	WHERE TotalMonths = 3 
							

	CREATE INDEX IX_#Q04_PK_Distributor ON #Q04(PK_Distributor)
					  
	-- Accumulated Qs
		DROP TABLE IF EXISTS #Accumulated

		SELECT PK_Distributor, SUM(TVP) AS AccTVP, @Month4 AS FirstMonth, @Month6 AS LastMonth
	INTO #Accumulated																							 
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month4 AND @Month6 GROUP BY PK_Distributor
	UNION 	SELECT PK_Distributor, SUM(TVP) AS AccTVP, @Month5 AS FirstMonth, @Month7 AS LastMonth
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month5 AND @Month7 GROUP BY PK_Distributor
	UNION 	SELECT PK_Distributor, SUM(TVP) AS AccTVP, @Month6 AS FirstMonth, @Month8 AS LastMonth
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month6 AND @Month8 GROUP BY PK_Distributor


	-- Q05 Accumulate 15,000 TVP in 3 consecutive volume months during Feb 2025 - June 2025 ---------------------------------------------
	DROP TABLE IF EXISTS #Q05

	SELECT PK_Distributor, MIN(FirstMonth) AS FirstMonth, MIN(LastMonth) AS LastMonth
	INTO #Q05
	FROM #Accumulated
	WHERE AccTVP >= @TVPs2 	
	GROUP BY PK_Distributor

	CREATE INDEX IX_#Q05_PK_Distributor ON #Q05(PK_Distributor)


	-- Q06 Accumulate 22,500 TVP in 3 consecutive volume months during Feb 2025 - June 2025 ---------------------------------------------
	DROP TABLE IF EXISTS #Q06

	SELECT PK_Distributor, MIN(FirstMonth) AS FirstMonth, MIN(LastMonth) AS LastMonth
	INTO #Q06
	FROM #Accumulated
	WHERE AccTVP >= @TVPs3 	
	GROUP BY PK_Distributor

	CREATE INDEX IX_#Q06_PK_Distributor ON #Q06(PK_Distributor)
																						   
	-- Q07 Accumulate 30,000 TVP in 3 consecutive volume months during Feb 2025 - June 2025 ---------------------------------------------
	DROP TABLE IF EXISTS #Q07

	SELECT PK_Distributor, MIN(FirstMonth) AS FirstMonth, MIN(LastMonth) AS LastMonth
	INTO #Q07
	FROM #Accumulated
	WHERE AccTVP >= @TVPs4 	
	GROUP BY PK_Distributor

	CREATE INDEX IX_#Q07_PK_Distributor ON #Q07(PK_Distributor)
	
	
	DROP TABLE IF EXISTS #Q19
	
	SELECT DISTINCT M.PK_Distributor
	INTO #Q19
	FROM #MBIDs AS M
	INNER JOIN dbo.AWT as A WITH (NOLOCK) 
		ON M.PK_Distributor = A.PK_Distributor
	WHERE AWTYear IN (2024, 2025)

	CREATE INDEX IX_#Q19_PK_Distributor ON #Q19(PK_Distributor)						  

-----------------------------------------------------------------------------------------------------------
	-- Qualifications 						 
	
	UPDATE Q
	SET  Q04 = IIF(Q04.PK_Distributor IS NOT NULL, 1, 0)
		,Q05 = IIF(Q05.PK_Distributor IS NOT NULL, 1, 0)
		,Q06 = IIF(Q06.PK_Distributor IS NOT NULL, 1, 0)
		,Q07 = IIF(Q07.PK_Distributor IS NOT NULL, 1, 0)
		,Q19 = IIF(Q19.PK_Distributor IS NOT NULL, 1, 0)
		,Q50 = IIF(S.PK_Distributor IS NOT NULL, 1, 0)
	FROM #EventQual AS Q
	LEFT JOIN #Q04 AS Q04
		ON Q.PK_Distributor = Q04.PK_Distributor
	LEFT JOIN #Q05 AS Q05
		ON Q.PK_Distributor = Q05.PK_Distributor
	LEFT JOIN #Q06 AS Q06
		ON Q.PK_Distributor = Q06.PK_Distributor					  
	LEFT JOIN #Q07 AS Q07
		ON Q.PK_Distributor = Q07.PK_Distributor
	LEFT JOIN #Q19 AS Q19
		ON Q.PK_Distributor = Q19.PK_Distributor
	LEFT JOIN(SELECT DISTINCT PK_Distributor FROM #DSSKUs) AS S
		ON Q.PK_Distributor = S.PK_Distributor				   
				
				
	-- Lists
	UPDATE A
	SET  Q11 = ISNULL(L.[63200],0) 
		,Q12 = ISNULL(L.[63201],0)
		,Q13 = ISNULL(L.[63202],0)
		,Q14 = ISNULL(L.[63203],0)
		,Q15 = ISNULL(L.[63204],0)
		,Q16 = ISNULL(L.[63205],0)
		,Q17 = ISNULL(L.[63206],0)
		,Q18 = ISNULL(L.[65646],0)
	FROM #EventQual A
	LEFT JOIN (
		SELECT  PK_Distributor, [63200],[63201],[63202],[63203],[63204],[63205],[63206],[65646]
		FROM (SELECT  PK_Distributor, ListID, CAST(PK_Distributor AS NVARCHAR(20))+ '-' + CAST(ListID AS NVARCHAR(20)) AS UniqueID	FROM #DSList) P
		PIVOT (COUNT (UniqueID)	FOR ListID IN ([63200],[63201],[63202],[63203],[63204],[63205],[63206],[65646])) AS pvt	
	) L
	ON A.PK_Distributor = L.PK_Distributor


	-- UPDATE SubEvents
	UPDATE #EventQual
	SET	 E04 = 	( (Q01 & Q08 & Q04) | Q14 )					-- (Q1+ Q8 + Q4) OR Q14 (List ID: 63203)    COP: UK (United Kingdom), IE (Ireland)
		,E05 = 	( (Q01 & Q08 & Q05) | Q15 ) 				-- (Q1+ Q8 + Q5) OR Q15 (List ID: 63204)    COP: UK (United Kingdom), IE (Ireland)
		,E06 = 	( (Q01 & Q08 & Q06) | Q16 ) 				-- (Q1+ Q8 + Q6) OR Q16 (List ID: 63205)    COP: UK (United Kingdom), IE (Ireland)
		,E07 = 	( (Q01 & Q08 & Q07) | Q17 )					-- (Q1+ Q8 + Q7) OR Q17 (List ID: 63206)    COP: UK (United Kingdom), IE (Ireland)
														 
	UPDATE #EventQual
	SET	 E01 =	( Q01 | Q11 )								-- Q1 OR Q11 (List ID: 63200 )			
		,E02 =	( Q02 | E07 | Q12 )							-- Q2 OR E7 OR Q12 (List ID: 63201)
		,E03 =	( Q02 | E04 | E05 | E06 | E07 | Q13 )		-- Q2 OR E4 OR E5 OR E6 OR E7 OR Q13 (List ID: 63202)
		,E08 =	( Q19 | Q02 | E07 | Q18 )					-- Q19 OR Q2 OR E7 OR Q18 (List ID: 65646)


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
