CREATE PROCEDURE [dbo].[usp_EventQual_BelgiumSummerSpectacular_Jul2025]
       -- Error Parameters
		 @Error	INT = NULL OUTPUT
		,@ErrorMessage VARCHAR(4000) = NULL OUTPUT

		-- QA/DEV
		,@IsDevQA TINYINT = 0
AS
BEGIN

/*********************************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_BelgiumSummerSpectacular_Jul2025
	USE:		EXEC dbo.usp_EventQual_BelgiumSummerSpectacular_Jul2025 
				@IsDevQA = 1
	DESCRIPTION:
	NOTES:		
	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1.0.0		2025-05-21	    puertac  		Initial 								 
***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

DECLARE  @PK_Event INT = 202815  						   
		,@Month1 DATETIME  = '2025-04-01'
		,@Month2 DATETIME  = '2025-05-01'
		,@Month3 DATETIME  = '2025-06-01'		
		,@Month4 DATETIME  = '2025-07-01'	
		,@Num1 MONEY = 10000
		,@Num2 MONEY = 3500
		,@Num3 MONEY = 5000
		,@Num4 MONEY = 7500
		,@Num5 MONEY = 11500
		,@Num6 MONEY = 17500
		,@Num7 MONEY = 23500
		,@Num8 MONEY = 31000											
		,@SignUpDateRangeStart INT = 20250401
		,@SignUpDateRangeEnd INT = 20250630									   
			
	
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
	WHERE sCountryCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar]('BE', ','))
	
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
	VALUES (63833),(63834),(63835),(63836),(63837),(63838),(63839),(63832)

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
		,IsTAB					BIT DEFAULT 0	
		,IsPT					BIT DEFAULT 0	
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
		,IIF(D.sTeam IN ('G','M','P','A','B','C'), 1, 0) AS IsTAB
		,IIF(D.sTeam IN ('P','A','B','C'), 1, 0) AS IsPT	
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
		,IIF(D.sTeam IN ('G','M','P','A','B','C'), 1, 0) AS IsTAB
		,IIF(D.sTeam IN ('P','A','B','C'), 1, 0) AS IsPT	
	FROM #DSList L
	INNER JOIN  dbo.v_Distributor D 	
		ON L.PK_Distributor = D.nDistributorID
	LEFT JOIN #Countries C WITH (NOLOCK) 
			ON D.nDistributorCountryProcessingID = C.nCountryID
	WHERE NOT EXISTS (SELECT 1 FROM #MBIDs M WHERE M.PK_Distributor = L.PK_Distributor) 


	CREATE INDEX IX_#MBIDs_PK_Distributor ON #MBIDs(PK_Distributor)


	INSERT INTO #EventQual(PK_Event, PK_Distributor, CreatedDate, UpdatedDate, Q01, Q02, Q03, Q04, Q49)		
	SELECT	A.PK_Event 
		   ,B.PK_Distributor 
		   ,GETUTCDATE() AS CreatedDate
		   ,GETUTCDATE() AS UpdatedDate
		   ,1 AS Q01											 
		   ,IIF(B.DSSPTeam = 'SP', 1 , 0) AS Q02
		   ,B.IsTAB AS Q03
		   ,B.IsPT AS Q04					
		   ,IsFromCOP AS Q49
	FROM #Events A
	CROSS APPLY #MBIDs B

	CREATE INDEX IX_#EventQual_PK_Distributor ON #EventQual(PK_Distributor)


	DROP TABLE IF EXISTS #Q05					-- Q5 AWT 2025 (Qualified or Re-Qualified)
	
	SELECT DISTINCT A.PK_Distributor 
	INTO #Q05
	FROM #MBIDs AS M
	INNER JOIN dbo.AWT AS A WITH (NOLOCK)
		ON M.PK_Distributor = A.PK_Distributor
		AND AWTYear = 2025

	CREATE INDEX IX_#Q05_PK_Distributor ON #Q05(PK_Distributor)
	

-----------------------------------------------------------------------------------------------------------
	-- Volume 
	DROP TABLE IF EXISTS #MBIDsPoints

	CREATE TABLE #MBIDsPoints(
		 PK_Distributor INT
		,dRoyaltyMonth  SMALLDATETIME
		,TVP			MONEY DEFAULT 0			   
		,RO				MONEY DEFAULT 0				
		,PPV			MONEY DEFAULT 0
	)	

	INSERT INTO #MBIDsPoints(PK_Distributor, dRoyaltyMonth, TVP, RO, PPV)		
	SELECT 	T.PK_Distributor,				   
			A.dRoyaltyMonth,
			A.mVolumePoints AS TVP,
			(A.mRoyaltyOverrides + A.mMainRoyaltyOverrides) AS RO,
			A.mPersonalPurchaseVolume AS PPV			
	FROM #MBIDs T
	INNER JOIN dbo.v_aggFQS_ID A WITH (NOLOCK)
		ON 	T.PK_Distributor = A.nDistributorID
	AND A.dRoyaltyMonth BETWEEN @Month1 AND @Month3							--  Qual Period : April 2025-June 2025

	CREATE INDEX IX_#MBIDsPoints_PK_Distributor ON #MBIDsPoints(PK_Distributor)


	-- Q6 Achieve 10,000 TVP in any one (1) month during Qual Period (April 2025-June 2025)  --------------------------------------------
		DROP TABLE IF EXISTS #Q06

		SELECT PK_Distributor, MIN(dRoyaltyMonth) AS RoyaltyMonth
		INTO #Q06
		FROM #MBIDsPoints 
		WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 AND TVP >= @Num1 
		GROUP BY PK_Distributor
		 	
		CREATE INDEX IX_#Q06_PK_Distributor ON #Q06(PK_Distributor)


	-- Q7 Achieve 3,500 TVP in each month for three (3) consecutive months during Qual Period (April 2025-June 2025) --------------------------------------------
		DROP TABLE IF EXISTS #AchievedMonthsQ07

			SELECT PK_Distributor,COUNT(TVP) AS TotalMonths
		INTO #AchievedMonthsQ07
			FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 AND TVP >= @Num2 GROUP BY PK_Distributor
																				  	  
		DROP TABLE IF EXISTS #Q07

		SELECT DISTINCT PK_Distributor
		INTO #Q07
		FROM #AchievedMonthsQ07 WHERE TotalMonths = 3 
	
		CREATE INDEX IX_#Q07_PK_Distributor ON #Q07(PK_Distributor)


	-- Q8 Achieve 5,000 TVP in each month for three (3) consecutive months during Qual Period (April 2025-June 2025) --------------------------------------------
		DROP TABLE IF EXISTS #AchievedMonthsQ08

			SELECT PK_Distributor,COUNT(TVP) AS TotalMonths
		INTO #AchievedMonthsQ08
			FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 AND TVP >= @Num3 GROUP BY PK_Distributor
		  
		DROP TABLE IF EXISTS #Q08

		SELECT DISTINCT PK_Distributor
		INTO #Q08				 
		FROM #AchievedMonthsQ08 WHERE TotalMonths = 3 
	
		CREATE INDEX IX_#Q08_PK_Distributor ON #Q08(PK_Distributor)


	-- Q9 Achieve 7,500 TVP in each month for three (3) consecutive months during Qual Period (April 2025-June 2025) --------------------------------------------
		DROP TABLE IF EXISTS #AchievedMonthsQ09

			SELECT PK_Distributor,COUNT(TVP) AS TotalMonths
		INTO #AchievedMonthsQ09
			FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 AND TVP >= @Num4 GROUP BY PK_Distributor
		  
		DROP TABLE IF EXISTS #Q09

		SELECT DISTINCT PK_Distributor
		INTO #Q09
		FROM #AchievedMonthsQ09 WHERE TotalMonths = 3 
	
		CREATE INDEX IX_#Q09_PK_Distributor ON #Q09(PK_Distributor)


	-- Q10 Achieve 10,000 TVP in each month for three (3) consecutive months during Qual Period (April 2025-June 2025) --------------------------------------------
		DROP TABLE IF EXISTS #AchievedMonthsQ10

			SELECT PK_Distributor,COUNT(TVP) AS TotalMonths
		INTO #AchievedMonthsQ10				
			FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 AND TVP >= @Num1 GROUP BY PK_Distributor
		
		
		DROP TABLE IF EXISTS #Q10

		SELECT DISTINCT PK_Distributor
		INTO #Q10
		FROM #AchievedMonthsQ10 WHERE TotalMonths = 3 
	
		CREATE INDEX IX_#Q10_PK_Distributor ON #Q10(PK_Distributor)

	-- Q11 Accumulate 11,500 TVP over three month period during Qual Period  (April 2025-June 2025) --------------------------------------------
		DROP TABLE IF EXISTS #AccumulatedQ11

		SELECT PK_Distributor, SUM(TVP) AS AccTVP, @Month1 AS FirstMonth, @Month3 AS LastMonth
		INTO #AccumulatedQ11																							 
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 GROUP BY PK_Distributor  

		DROP TABLE IF EXISTS #Q11

		SELECT PK_Distributor, MIN(FirstMonth) AS FirstMonth, MIN(LastMonth) AS LastMonth
		INTO #Q11
		FROM #AccumulatedQ11
		WHERE AccTVP >= @Num5
		GROUP BY PK_Distributor

		CREATE INDEX IX_#Q11_PK_Distributor ON #Q11(PK_Distributor)

				 
	-- Q12 Accumulate 17,500 TVP over three month period during Qual Period (April 2025-June 2025) --------------------------------------------
		DROP TABLE IF EXISTS #AccumulatedQ12

		SELECT PK_Distributor, SUM(TVP) AS AccTVP, @Month1 AS FirstMonth, @Month3 AS LastMonth
		INTO #AccumulatedQ12																						 
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 GROUP BY PK_Distributor  

		DROP TABLE IF EXISTS #Q12

		SELECT PK_Distributor, MIN(FirstMonth) AS FirstMonth, MIN(LastMonth) AS LastMonth
		INTO #Q12
		FROM #AccumulatedQ12
		WHERE AccTVP >= @Num6
		GROUP BY PK_Distributor

		CREATE INDEX IX_#Q12_PK_Distributor ON #Q12(PK_Distributor)

	-- Q13 Accumulate 23,500 TVP over three month period during Qual Period (April 2025-June 2025) --------------------------------------------
		DROP TABLE IF EXISTS #AccumulatedQ13

		SELECT PK_Distributor, SUM(TVP) AS AccTVP, @Month1 AS FirstMonth, @Month3 AS LastMonth
		INTO #AccumulatedQ13																							 
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 GROUP BY PK_Distributor  

		DROP TABLE IF EXISTS #Q13

		SELECT PK_Distributor, MIN(FirstMonth) AS FirstMonth, MIN(LastMonth) AS LastMonth
		INTO #Q13
		FROM #AccumulatedQ13
		WHERE AccTVP >= @Num7
		GROUP BY PK_Distributor

		CREATE INDEX IX_#Q13_PK_Distributor ON #Q13(PK_Distributor)

	-- Q14 Accumulate 31,000 TVP over three month period during Qual Period (april 2024-June 2024)  --------------------------------------------
		DROP TABLE IF EXISTS #AccumulatedQ14

		SELECT PK_Distributor, SUM(TVP) AS AccTVP, @Month1 AS FirstMonth, @Month3 AS LastMonth
		INTO #AccumulatedQ14																							 
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 GROUP BY PK_Distributor  

		DROP TABLE IF EXISTS #Q14

		SELECT PK_Distributor, MIN(FirstMonth) AS FirstMonth, MIN(LastMonth) AS LastMonth
		INTO #Q14
		FROM #AccumulatedQ14
		WHERE AccTVP >= @Num8
		GROUP BY PK_Distributor

		CREATE INDEX IX_#Q14_PK_Distributor ON #Q14(PK_Distributor)			



	-- Q18 Achieve 3,500 PPV in each month for three (3) consecutive months during Qual Period (April 2025-June 2025) --------------------------------------------
		DROP TABLE IF EXISTS #AchievedMonthsQ18

			SELECT PK_Distributor,COUNT(PPV) AS TotalMonths
		INTO #AchievedMonthsQ18
			FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 AND PPV >= @Num2 GROUP BY PK_Distributor
		  
		DROP TABLE IF EXISTS #Q18

		SELECT DISTINCT PK_Distributor
		INTO #Q18
		FROM #AchievedMonthsQ18 WHERE TotalMonths = 3 
	
		CREATE INDEX IX_#Q18_PK_Distributor ON #Q18(PK_Distributor)


	-- Q19 Accumulate 11,500 PPV over three month period during Qual Period  (April 2025-June 2025)  --------------------------------------------
		DROP TABLE IF EXISTS #AccumulatedQ19

		SELECT PK_Distributor, SUM(PPV) AS AccPPV, @Month1 AS FirstMonth, @Month3 AS LastMonth
		INTO #AccumulatedQ19																							 
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 GROUP BY PK_Distributor  

		DROP TABLE IF EXISTS #Q19

		SELECT PK_Distributor, MIN(FirstMonth) AS FirstMonth, MIN(LastMonth) AS LastMonth
		INTO #Q19
		FROM #AccumulatedQ19
		WHERE AccPPV >= @Num5
		GROUP BY PK_Distributor

		CREATE INDEX IX_#Q19_PK_Distributor ON #Q19(PK_Distributor)		


-----------------------------------------------------------------------------------------------------------
	-- Downlines

	-- Q15 Have minimum one (1) New Downline Supervisor - First DS Level with SP qual dates: May 2025 to July 2025 (Vol Month: April 2025 - June 2025)
		DROP TABLE IF EXISTS #NewSPDownlines

		SELECT M.PK_Distributor, V.PK_DSDownline, dSupervisorQualification  AS QualDate
		INTO #NewSPDownlines
		FROM #MBIDs AS M WITH (NOLOCK)
		INNER JOIN v_dimDSLngDownline AS V WITH (NOLOCK)
			ON M.PK_Distributor = V.PK_Distributor
			AND DSLevelFromUL = 2
		INNER JOIN v_Distributor AS F
			ON F.nDistributorID = V.PK_DSDownline
			AND F.dSupervisorQualification BETWEEN @Month2 AND @Month4
			AND F.dSupervisorReQualification IS NULL
	
		CREATE INDEX IX_#NewSPDownlines_PK_Distributor ON #NewSPDownlines(PK_Distributor)		

		
		DROP TABLE IF EXISTS #Q15

		SELECT DISTINCT PK_Distributor
		INTO #Q15
		FROM #NewSPDownlines
		GROUP BY PK_Distributor

		CREATE INDEX IX_#Q15_PK_Distributor ON #Q15(PK_Distributor)	


	-- Q16 Have 1 New DS/PC (Signup Month: April 2025 to June 2025) in each month during the Qual Period (April 2025 - June 2025) who achieves 250 PPV in the same month as App date + AppMonth+1.
	-- Q17 Have 4 new DS/PC (Signup Month: April 2025 to June 2025) over Qual Period (April 2025 - June 2025) who achieves 250 PPV in the same month as the App date + AppMonth+1. 
		
		DROP TABLE IF EXISTS #NewDSPCDownlines

		SELECT   M.PK_Distributor, V.PK_DSDownline, 'DS' AS DownlineType
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
				,FORMAT(IIF(DS.ApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd
						,DATEFROMPARTS(YEAR(LEFT(DS.ApplicationDate,4)), CAST(SUBSTRING(CAST(DS.ApplicationDate AS VARCHAR),5,2) AS INT),1)
						,DATEFROMPARTS(YEAR(LEFT(DS.WINBACKREINSTATEMENTDATE,4)), CAST(SUBSTRING(CAST(DS.WINBACKREINSTATEMENTDATE AS VARCHAR),5,2) AS INT),1)
							), 'yyyyMM'
						) AS iSignUpDate
				,FORMAT(DATEADD(MONTH, 1, IIF(DS.ApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd
										,DATEFROMPARTS(YEAR(LEFT(DS.ApplicationDate,4)), CAST(SUBSTRING(CAST(DS.ApplicationDate AS VARCHAR),5,2) AS INT),1)
										,DATEFROMPARTS(YEAR(LEFT(DS.WINBACKREINSTATEMENTDATE,4)), CAST(SUBSTRING(CAST(DS.WINBACKREINSTATEMENTDATE AS VARCHAR),5,2) AS INT),1)
									)
								), 'yyyyMM'
						) AS [iSignUpDate+1]
		INTO #NewDSPCDownlines
		FROM #MBIDs AS M WITH (NOLOCK)
		INNER JOIN v_dimDSLngDownline AS V WITH (NOLOCK)
			ON M.PK_Distributor = V.PK_Distributor
			AND DSLevelFromUL = 2
		INNER JOIN PubEvents.dbo.dimDistributor AS DS WITH (NOLOCK)
			ON DS.PK_Distributor = V.PK_DSDownline
			AND (DS.ApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd OR DS.WINBACKREINSTATEMENTDATE BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd)

		INSERT INTO  #NewDSPCDownlines
		SELECT   M.PK_Distributor, V.PK_DSDownline, 'PC' AS DownlineType
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
				,FORMAT(IIF(DS.MBApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd
						,DATEFROMPARTS(YEAR(LEFT(DS.MBApplicationDate,4)), CAST(SUBSTRING(CAST(DS.MBApplicationDate AS VARCHAR),5,2) AS INT),1)
						,DATEFROMPARTS(YEAR(LEFT(DS.PMREINSTATEMENTDATE,4)), CAST(SUBSTRING(CAST(DS.PMREINSTATEMENTDATE AS VARCHAR),5,2) AS INT),1)
							), 'yyyyMM'
						) AS iSignUpDate
				,FORMAT(DATEADD(MONTH, 1, IIF(DS.MBApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd
										,DATEFROMPARTS(YEAR(LEFT(DS.MBApplicationDate,4)), CAST(SUBSTRING(CAST(DS.MBApplicationDate AS VARCHAR),5,2) AS INT),1)
										,DATEFROMPARTS(YEAR(LEFT(DS.PMREINSTATEMENTDATE,4)), CAST(SUBSTRING(CAST(DS.PMREINSTATEMENTDATE AS VARCHAR),5,2) AS INT),1)
									)
								), 'yyyyMM'
						) AS [iSignUpDate+1]
		FROM #MBIDs AS M WITH (NOLOCK)
		INNER JOIN v_dimDSLngDownline AS V WITH (NOLOCK)
			ON M.PK_Distributor = V.PK_Distributor
			AND DSLevelFromUL = 2
		INNER JOIN PubEvents.dbo.dimDistributor AS DS WITH (NOLOCK)
			ON DS.PK_Distributor = V.PK_DSDownline
			AND (DS.MBApplicationDate BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd OR DS.PMREINSTATEMENTDATE BETWEEN @SignUpDateRangeStart AND @SignUpDateRangeEnd)

		CREATE INDEX IX_#NewDSPCDownlines_PK_Distributor ON #NewDSPCDownlines(PK_Distributor)		


		-- Downlines volume
		DROP TABLE IF EXISTS #Volume_NewDSPCDownlines

		SELECT M.PK_Distributor, M.PK_DSDownline, M.DownlineType, M.SignUpDate
			,SUM( IIF(ISNULL(A.mPersonalPurchaseVolume,0)<0,0, ISNULL(A.mPersonalPurchaseVolume,0)) + IIF(ISNULL(A.mMainPersonalPurchaseVolume,0)<0,0, ISNULL(A.mMainPersonalPurchaseVolume,0)) - IIF(F.PM_POINTS IS NULL OR F.PM_POINTS < 0, 0, F.PM_POINTS) )AS DS_PPV 
			,CAST (0 AS MONEY) AS PC_PPV, dSignUpDate, [dSignUpDate+1], iSignUpDate, [iSignUpDate+1]
		INTO #Volume_NewDSPCDownlines
		FROM #NewDSPCDownlines AS M
		INNER JOIN v_aggFQS_ID AS A 
			ON M.PK_DSDownline = A.nDistributorID
			AND A.dRoyaltyMonth BETWEEN dSignUpDate AND [dSignUpDate+1]
		LEFT JOIN PubEvents.dbo.factDSFinancial_ctry AS F WITH (NOLOCK)
			ON F.PK_Distributor = M.PK_DSDownline
			AND DATEFROMPARTS(LEFT(F.RoyaltyMonth,4),RIGHT(F.RoyaltyMonth,2),01) = A.dRoyaltyMonth
		WHERE M.DownlineType = 'DS'
		GROUP BY M.PK_Distributor, M.PK_DSDownline, M.DownlineType, M.SignUpDate, dSignUpDate, [dSignUpDate+1], iSignUpDate, [iSignUpDate+1]

		INSERT INTO #Volume_NewDSPCDownlines
		SELECT	M.PK_Distributor, M.PK_DSDownline, M.DownlineType, M.SignUpDate, CAST (0 AS MONEY) AS DS_PPV
				,SUM(CASE WHEN F.CountryCode IN ('US','PR') THEN IIF(F.MB_POINTEGERS IS NULL OR F.MB_POINTEGERS < 0, 0, F.MB_POINTEGERS) 
							ELSE IIF(F.PM_POINTS IS NULL OR F.PM_POINTS < 0, 0, F.PM_POINTS) 
						END
					) AS PC_PPV
				 ,dSignUpDate, [dSignUpDate+1], iSignUpDate, [iSignUpDate+1]
		FROM #NewDSPCDownlines AS M
		LEFT JOIN PubEvents.dbo.factDSFinancial_ctry AS F WITH (NOLOCK) 	
			ON F.PK_Distributor = M.PK_DSDownline
			AND F.RoyaltyMonth BETWEEN iSignUpDate AND [iSignUpDate+1]
		WHERE M.DownlineType = 'PC'
		GROUP BY M.PK_Distributor, M.PK_DSDownline, M.DownlineType, M.SignUpDate, dSignUpDate, [dSignUpDate+1], iSignUpDate, [iSignUpDate+1]
				
		
		DROP TABLE IF EXISTS #DSPCDownlinesQualified

		SELECT PK_Distributor, PK_DSDownline, DownlineType, SignUpDate, DS_PPV, PC_PPV
		INTO #DSPCDownlinesQualified
		FROM #Volume_NewDSPCDownlines  
		WHERE (DS_PPV >= 250 OR PC_PPV >= 250)

		
		-- Q16
			DROP TABLE IF EXISTS #UplinesPerMonth

				SELECT DISTINCT PK_Distributor, 1 AS MonthCount	, @Month1 AS StartDate, EOMONTH(@Month1) AS EndDate
			INTO #UplinesPerMonth
				FROM #DSPCDownlinesQualified WHERE CAST(CAST(SignUpDate AS VARCHAR) AS DATE) BETWEEN @Month1 AND EOMONTH(@Month1)
			UNION 
				SELECT DISTINCT PK_Distributor, 1 AS MonthCount, @Month2 AS StartDate, EOMONTH(@Month2) AS EndDate	FROM #DSPCDownlinesQualified WHERE CAST(CAST(SignUpDate AS VARCHAR) AS DATE) BETWEEN @Month2 AND EOMONTH(@Month2)
			UNION
				SELECT DISTINCT PK_Distributor, 1 AS MonthCount, @Month3 AS StartDate, EOMONTH(@Month3) AS EndDate	FROM #DSPCDownlinesQualified WHERE CAST(CAST(SignUpDate AS VARCHAR) AS DATE) BETWEEN @Month3 AND EOMONTH(@Month3)

		
			DROP TABLE IF EXISTS #TotalDownlines1PerMonth

			SELECT PK_Distributor, SUM(MonthCount) AS TotalMonths
			INTO #TotalDownlines1PerMonth
			FROM #UplinesPerMonth
			GROUP BY PK_Distributor

			CREATE INDEX IX_#TotalDownlines1PerMonth_PK_Distributor ON #TotalDownlines1PerMonth(PK_Distributor)	
			

			DROP TABLE IF EXISTS #Q16

			SELECT DISTINCT PK_Distributor
			INTO #Q16
			FROM #TotalDownlines1PerMonth
			WHERE TotalMonths = 3

			CREATE INDEX IX_#Q16_PK_Distributor ON #Q16(PK_Distributor)			

	
		-- Q17
			DROP TABLE IF EXISTS #AccDownlines

			SELECT PK_Distributor, COUNT(PK_DSDownline) AS ContributorsCount
			INTO #AccDownlines
			FROM #DSPCDownlinesQualified
			GROUP BY PK_Distributor
			

			DROP TABLE IF EXISTS #Q17

			SELECT DISTINCT PK_Distributor
			INTO #Q17
			FROM #AccDownlines
			WHERE ContributorsCount >= 4

			CREATE INDEX IX_#Q17_PK_Distributor ON #Q17(PK_Distributor)			
			
-----------------------------------------------------------------------------------------------------------
	-- Qualifications 						 
	
	UPDATE Q
	SET  Q05 = IIF(Q05.PK_Distributor IS NOT NULL, 1, 0) 
		,Q06 = IIF(Q06.PK_Distributor IS NOT NULL, 1, 0) 
		,Q07 = IIF(Q07.PK_Distributor IS NOT NULL, 1, 0)
		,Q08 = IIF(Q08.PK_Distributor IS NOT NULL, 1, 0)
		,Q09 = IIF(Q09.PK_Distributor IS NOT NULL, 1, 0) 
		,Q10 = IIF(Q10.PK_Distributor IS NOT NULL, 1, 0)
		,Q11 = IIF(Q11.PK_Distributor IS NOT NULL, 1, 0)
		,Q12 = IIF(Q12.PK_Distributor IS NOT NULL, 1, 0) 
		,Q13 = IIF(Q13.PK_Distributor IS NOT NULL, 1, 0)
		,Q14 = IIF(Q14.PK_Distributor IS NOT NULL, 1, 0)		
		,Q15 = IIF(Q15.PK_Distributor IS NOT NULL, 1, 0) 
		,Q16 = IIF(Q16.PK_Distributor IS NOT NULL, 1, 0) 
		,Q17 = IIF(Q17.PK_Distributor IS NOT NULL, 1, 0) 
		,Q18 = IIF(Q18.PK_Distributor IS NOT NULL, 1, 0)
		,Q19 = IIF(Q19.PK_Distributor IS NOT NULL, 1, 0)
		,Q50 = IIF(S.PK_Distributor IS NOT NULL, 1, 0)
	FROM #EventQual AS Q
	LEFT JOIN #Q05 AS Q05
		ON Q.PK_Distributor = Q05.PK_Distributor				  
	LEFT JOIN #Q06 AS Q06
		ON Q.PK_Distributor = Q06.PK_Distributor
	LEFT JOIN #Q07 AS Q07
		ON Q.PK_Distributor = Q07.PK_Distributor
	LEFT JOIN #Q08 AS Q08
		ON Q.PK_Distributor = Q08.PK_Distributor
	LEFT JOIN #Q09 AS Q09
		ON Q.PK_Distributor = Q09.PK_Distributor
	LEFT JOIN #Q10 AS Q10
		ON Q.PK_Distributor = Q10.PK_Distributor
	LEFT JOIN #Q11 AS Q11
		ON Q.PK_Distributor = Q11.PK_Distributor
	LEFT JOIN #Q12 AS Q12
		ON Q.PK_Distributor = Q12.PK_Distributor
	LEFT JOIN #Q13 AS Q13
		ON Q.PK_Distributor = Q13.PK_Distributor
	LEFT JOIN #Q14 AS Q14
		ON Q.PK_Distributor = Q14.PK_Distributor
	LEFT JOIN #Q15 AS Q15
		ON Q.PK_Distributor = Q15.PK_Distributor
	LEFT JOIN #Q16 AS Q16
		ON Q.PK_Distributor = Q16.PK_Distributor
	LEFT JOIN #Q17 AS Q17
		ON Q.PK_Distributor = Q17.PK_Distributor
	LEFT JOIN #Q18 AS Q18
		ON Q.PK_Distributor = Q18.PK_Distributor
	LEFT JOIN #Q19 AS Q19
		ON Q.PK_Distributor = Q19.PK_Distributor					  
	LEFT JOIN(SELECT DISTINCT PK_Distributor FROM #DSSKUs) AS S
		ON Q.PK_Distributor = S.PK_Distributor				   
				
				
	-- Lists
	UPDATE A
	SET  Q20 = ISNULL(L.[63833],0) 
		,Q21 = ISNULL(L.[63834],0)
		,Q22 = ISNULL(L.[63835],0) 
		,Q23 = ISNULL(L.[63836],0)
		,Q24 = ISNULL(L.[63837],0) 
		,Q25 = ISNULL(L.[63838],0)
		,Q26 = ISNULL(L.[63839],0) 
		,Q27 = ISNULL(L.[63832],0)					
	FROM #EventQual A
	LEFT JOIN (
		SELECT  PK_Distributor, [63833],[63834],[63835],[63836],[63837],[63838],[63839],[63832]
		FROM (SELECT  PK_Distributor, ListID, CAST(PK_Distributor AS NVARCHAR(20))+ '-' + CAST(ListID AS NVARCHAR(20)) AS UniqueID	FROM #DSList) P
		PIVOT (COUNT (UniqueID)	FOR ListID IN ([63833],[63834],[63835],[63836],[63837],[63838],[63839],[63832])) AS pvt	
	) L
	ON A.PK_Distributor = L.PK_Distributor


	-- UPDATE SubEvents
	UPDATE #EventQual
	SET	 E01 =	Q01 																-- Q1 
		,E02 =	Q01																	-- Q1
		,E03 =	(Q02 & ((Q07 | Q11) & (Q16 | Q17 | Q18 | Q19))) | Q20				-- (Q2 + ((Q7 OR Q11) + (Q16 OR Q17 OR Q18 OR Q19))) OR Q20
		,E04 =	(Q02 & ((Q08 | Q12) & (Q16 | Q17 | Q18 | Q19))) | Q21				-- (Q2 + ((Q8 OR Q12) + (Q16 OR Q17 OR Q18 OR Q19)))  OR Q21
		,E05 =	(Q02 & ((Q09 | Q13) & (Q16 | Q17 | Q18 | Q19))) | Q04 | Q22			-- (Q2 + ((Q9 OR Q13) + (Q16 OR Q17 OR Q18 OR Q19))) OR Q4  OR Q22
		,E06 =	(Q02 & Q06 & (Q16 | Q17 | Q18 | Q19)) | Q04 | Q23					-- (Q2 + Q6 + (Q16 OR Q17 OR Q18 OR Q19)) OR Q4  OR Q23	
		,E08 =	(Q02 & ((Q10 | Q14) & (Q16 | Q17 | Q18 | Q19))) | Q25				-- (Q2 + ((Q10 OR Q14)) + (Q16 OR Q17 OR Q18 OR Q19))) OR Q25
		,E09 =	(Q02 & Q08 & Q15) | Q26												-- (Q2 + Q8 + Q15) OR Q26
		
	UPDATE #EventQual
	SET  E07 =	( (Q02 & ((Q09 | Q13) & (Q16 | Q17 | Q18 | Q19))) | Q24 ) & ~E08	-- (Q2 + ((Q9 OR Q13) + (Q16 OR Q17 OR Q18 OR Q19))) OR Q24			In case a person qualifies for both (E7 & E8), only show qualified to highest level, where 2 hotelovernight stay is the highest.
		,E10 =	E09 | Q03 | Q05 | (Q02 & Q06) | Q27									-- E9 OR Q3 OR Q5 OR (Q2 + Q6) OR Q27
	

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
