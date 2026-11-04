CREATE PROCEDURE [dbo].[usp_EventQual_NorwayKickOff_Feb2024]
       -- Error Parameters
		 @Error	INT = NULL OUTPUT
		,@ErrorMessage VARCHAR(4000) = NULL OUTPUT

		-- QA/DEV
		,@IsDevQA TINYINT = 0
AS
BEGIN

/*********************************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_NorwayKickOff_Feb2024
	USE:		EXEC dbo.usp_EventQual_NorwayKickOff_Feb2024 
				@IsDevQA = 1
	DESCRIPTION:
	NOTES:		
	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1.0.0		2023-11-07	    puertac  		Initial 								 
***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

DECLARE  @PK_Event INT = 197332  						   
		,@Month1 DATETIME  = '2023-01-01'
		,@Month2 DATETIME  = '2023-02-01'
		,@Month3 DATETIME  = '2023-03-01'
		,@Month4 DATETIME  = '2023-04-01'
		,@Month5 DATETIME  = '2023-05-01'
		,@Month6 DATETIME  = '2023-06-01'
		,@Month7 DATETIME  = '2023-07-01'
		,@Month8 DATETIME  = '2023-08-01'
	    ,@Month9 DATETIME  = '2023-09-01'
		,@Month10 DATETIME = '2023-10-01'
		,@Month11 DATETIME = '2023-11-01'
		,@Month12 DATETIME = '2023-12-01'
		,@ValidDate DATETIME = '2049-12-31'									   
		,@TVPs1 MONEY = 2500	
		,@TVPs2 MONEY = 5000	
		,@TVPs3 MONEY = 10000	
		,@AWTYear INT = 2023						   
		
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


	-- IDs with Ticket
	DROP TABLE IF EXISTS #EventSKU

	CREATE TABLE #EventSKU	(
		PK_Event INT
		,PK_Distributor INT
		,HasTicket BIT DEFAULT 0
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
	WHERE sCountryCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar]('NO,DA,SW,FI', ','))
	
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
	VALUES (57478),(57479),(57480)

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
	WHERE s.PK_Event = @PK_Event AND s.SKUCode IN ('1V40','1V41','1V42')

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
		,IIF(D.sTeam IN ('G','M','P','A','B','C'), 1, 0) AS IsTAB																									
	FROM dbo.v_Distributor D 									
	INNER JOIN #Countries C WITH (NOLOCK) 
			ON D.nDistributorCountryProcessingID = C.nCountryID												  
	WHERE (D.sType = 'DS' OR D.sType = 'SP')								
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
		,IIF(D.sTeam IN ('G','M','P','A','B','C'), 1, 0) AS IsTAB									
	FROM dbo.v_Distributor AS D  
	INNER JOIN #DSSKUs AS S
		ON D.nDistributorID = S.PK_Distributor
	LEFT JOIN #Countries C WITH (NOLOCK) 
			ON D.nDistributorCountryProcessingID = C.nCountryID
	WHERE NOT EXISTS (SELECT 1 FROM #MBIDs AS T WHERE T.PK_Distributor = S.PK_Distributor)

	CREATE INDEX IX_#MBIDs_PK_Distributor ON #MBIDs(PK_Distributor)


	INSERT INTO #EventQual(PK_Event, PK_Distributor, CreatedDate, UpdatedDate, Q01, Q02, Q49)		
	SELECT	A.PK_Event 
		   ,B.PK_Distributor 
		   ,GETUTCDATE() AS CreatedDate
		   ,GETUTCDATE() AS UpdatedDate
		   ,1 AS Q01											 
		   ,B.IsTAB AS Q02				 
		   ,B.IsFromCOP AS Q49
	FROM #Events A
	CROSS APPLY #MBIDs B

	CREATE INDEX IX_#EventQual_PK_Distributor ON #EventQual(PK_Distributor)


	-- Q3  AWT 2023  ------------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #Q03

	SELECT E.PK_Distributor
	INTO #Q03
	FROM #EventQual E
	INNER JOIN dbo.AWT A WITH (NOLOCK)
		ON E.PK_Distributor = A.PK_Distributor 
		AND A.AWTYear = @AWTYear

	CREATE INDEX IX_#Q03_PK_Distributor ON #Q03(PK_Distributor);

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
	AND A.dRoyaltyMonth BETWEEN @Month1 AND @Month12

	CREATE INDEX IX_#MBIDsPoints_PK_Distributor ON #MBIDsPoints(PK_Distributor)


	-- Q04 TVP >= 2,500 in each month for theree (3) conscutive months during Jul 2023 to Dec 2023 --------------------------------------------
	DROP TABLE IF EXISTS #AchievedQ4

		SELECT PK_Distributor,COUNT(TVP) AS TotalMonths							 
	INTO #AchievedQ4				  
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month7 AND @Month9 AND TVP >= @TVPs1
		GROUP BY PK_Distributor
	UNION SELECT PK_Distributor, COUNT(TVP) AS TotalMonths FROM #MBIDsPoints
		  WHERE dRoyaltyMonth BETWEEN @Month8 AND @Month10 AND TVP >= @TVPs1 GROUP BY PK_Distributor
	UNION SELECT PK_Distributor, COUNT(TVP) AS TotalMonths FROM #MBIDsPoints
		  WHERE dRoyaltyMonth BETWEEN @Month9 AND @Month11 AND TVP >= @TVPs1 GROUP BY PK_Distributor
	UNION SELECT PK_Distributor, COUNT(TVP) AS TotalMonths FROM #MBIDsPoints
		  WHERE dRoyaltyMonth BETWEEN @Month10 AND @Month12 AND TVP >= @TVPs1 GROUP BY PK_Distributor

   
	DROP TABLE IF EXISTS #Q04

	SELECT DISTINCT PK_Distributor
	INTO #Q04
	FROM #AchievedQ4
	WHERE TotalMonths = 3 
							

	CREATE INDEX IX_#Q04_PK_Distributor ON #Q04(PK_Distributor)
					  
	
	-- Q05 TVP >= 5,000 in each month for theree (3) conscutive months during Jan 2023 to Dec 2023. ------------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #AchievedQ5

		SELECT PK_Distributor, COUNT(TVP) AS TotalMonths, @Month1 AS FirstMonth, @Month3 AS LastMonth
	INTO #AchievedQ5
		FROM #MBIDsPoints
		WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 AND TVP >= @TVPs2 GROUP BY PK_Distributor
	UNION
		SELECT PK_Distributor, COUNT(TVP) AS TotalMonths, @Month2 AS FirstMonth, @Month4 AS LastMonth FROM #MBIDsPoints
		WHERE dRoyaltyMonth BETWEEN @Month2 AND @Month4 AND TVP >= @TVPs2 GROUP BY PK_Distributor
	UNION
		SELECT PK_Distributor, COUNT(TVP) AS TotalMonths, @Month3 AS FirstMonth, @Month5 AS LastMonth FROM #MBIDsPoints
		WHERE dRoyaltyMonth BETWEEN @Month3 AND @Month5 AND TVP >= @TVPs2 GROUP BY PK_Distributor
	UNION
		SELECT PK_Distributor, COUNT(TVP) AS TotalMonths, @Month4 AS FirstMonth, @Month6 AS LastMonth FROM #MBIDsPoints
		WHERE dRoyaltyMonth BETWEEN @Month4 AND @Month6 AND TVP >= @TVPs2 GROUP BY PK_Distributor
	UNION
		SELECT PK_Distributor, COUNT(TVP) AS TotalMonths, @Month5 AS FirstMonth, @Month7 AS LastMonth FROM #MBIDsPoints
		WHERE dRoyaltyMonth BETWEEN @Month5 AND @Month7 AND TVP >= @TVPs2 GROUP BY PK_Distributor
	UNION
		SELECT PK_Distributor, COUNT(TVP) AS TotalMonths, @Month6 AS FirstMonth, @Month8 AS LastMonth FROM #MBIDsPoints
		WHERE dRoyaltyMonth BETWEEN @Month6 AND @Month8 AND TVP >= @TVPs2 GROUP BY PK_Distributor	
	UNION
		SELECT PK_Distributor, COUNT(TVP) AS TotalMonths, @Month7 AS FirstMonth, @Month9 AS LastMonth FROM #MBIDsPoints
		WHERE dRoyaltyMonth BETWEEN @Month7 AND @Month9 AND TVP >= @TVPs2 GROUP BY PK_Distributor
	UNION
		SELECT PK_Distributor, COUNT(TVP) AS TotalMonths, @Month8 AS FirstMonth, @Month10 AS LastMonth FROM #MBIDsPoints
		WHERE dRoyaltyMonth BETWEEN @Month8 AND @Month10 AND TVP >= @TVPs2 GROUP BY PK_Distributor
	UNION
		SELECT PK_Distributor, COUNT(TVP) AS TotalMonths, @Month9 AS FirstMonth, @Month11 AS LastMonth FROM #MBIDsPoints
		WHERE dRoyaltyMonth BETWEEN @Month9 AND @Month11 AND TVP >= @TVPs2 GROUP BY PK_Distributor
	UNION
		SELECT PK_Distributor, COUNT(TVP) AS TotalMonths, @Month10 AS FirstMonth, @Month12 AS LastMonth FROM #MBIDsPoints
		WHERE dRoyaltyMonth BETWEEN @Month10 AND @Month12 AND TVP >= @TVPs2 GROUP BY PK_Distributor


	DROP TABLE IF EXISTS #Q05

	SELECT PK_Distributor, MIN(FirstMonth) AS FirstMonth, MIN(LastMonth) AS LastMonth
	INTO #Q05
	FROM #AchievedQ5
	WHERE TotalMonths = 3 	
	GROUP BY PK_Distributor

	CREATE INDEX IX_#Q05_PK_Distributor ON #Q05(PK_Distributor)
		  
						  
	-- Q06  TVP >= 10,000 in any one (1) month of the 3 conscutive months used in Q5 ------------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #AchievedQ06

	SELECT PK_Distributor, dRoyaltyMonth
	INTO #AchievedQ06
	FROM #MBIDsPoints
	WHERE TVP >= @TVPs3


	DROP TABLE IF EXISTS #Q06

	SELECT A.PK_Distributor, MIN(A.dRoyaltyMonth) AS dRoyaltyMonth
	INTO #Q06
	FROM #AchievedQ06 AS A
	INNER JOIN #AchievedQ5 AS Q5
		ON A.PK_Distributor = Q5.PK_Distributor
		AND A.dRoyaltyMonth BETWEEN Q5.FirstMonth AND Q5.LastMonth
		AND Q5.TotalMonths = 3 	
	GROUP BY A.PK_Distributor

	CREATE INDEX IX_#Q06_PK_Distributor ON #Q06(PK_Distributor)

		
-----------------------------------------------------------------------------------------------------------
	-- Qualifications 						 
	
	UPDATE Q
	SET  Q03 = IIF(Q03.PK_Distributor IS NOT NULL, 1, 0)
		,Q04 = IIF(Q04.PK_Distributor IS NOT NULL, 1, 0)
		,Q05 = IIF(Q05.PK_Distributor IS NOT NULL, 1, 0)
		,Q06 = IIF(Q06.PK_Distributor IS NOT NULL, 1, 0)								  
		,Q50 = IIF(S.PK_Distributor IS NOT NULL, 1, 0)
	FROM #EventQual AS Q
	LEFT JOIN #Q03 AS Q03
		ON Q.PK_Distributor = Q03.PK_Distributor
	LEFT JOIN #Q04 AS Q04
		ON Q.PK_Distributor = Q04.PK_Distributor
	LEFT JOIN #Q05 AS Q05
		ON Q.PK_Distributor = Q05.PK_Distributor
	LEFT JOIN #Q06 AS Q06
		ON Q.PK_Distributor = Q06.PK_Distributor					  
	LEFT JOIN #DSSKUs AS S
		ON Q.PK_Distributor = S.PK_Distributor					   
				
				
	-- Lists
	UPDATE A
	SET  Q07 = ISNULL(L.[57478],0) 
		,Q08 = ISNULL(L.[57479],0)
		,Q09 = ISNULL(L.[57480],0)
	FROM #EventQual A
	LEFT JOIN (
		SELECT  PK_Distributor, [57478],[57479],[57480]
		FROM (SELECT  PK_Distributor, ListID, CAST(PK_Distributor AS NVARCHAR(20))+ '-' + CAST(ListID AS NVARCHAR(20)) AS UniqueID	FROM #DSList) P
		PIVOT (COUNT (UniqueID)	FOR ListID IN ([57478],[57479],[57480])) AS pvt	
	) L
	ON A.PK_Distributor = L.PK_Distributor


	-- UPDATE SubEvents
	UPDATE #EventQual
	SET	 E01 =	((Q01 & (Q50 | Q49))| Q07) 					-- Q1 OR Q [List ID:57478 ] + COP OR Has a ticket
		,E02 =	((Q02 | Q03 | (Q01 & Q05)) & Q49) | Q08		-- Q2 OR Q3 OR (Q1 + Q5) OR Q [List ID:57479]	+ COP
		,E03 =	((Q01 & Q04 & Q49) | Q09) 					-- (Q1 + Q4) OR Q [List ID:57480]	+ COP
		,E04 = 	(Q01 & Q05 & Q49) 							-- Q1 + Q5	+ COP
		,E05 = 	(Q01 & Q05 & Q06 & Q49) 					-- Q1 + Q5 + Q6	 + COP
		


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
