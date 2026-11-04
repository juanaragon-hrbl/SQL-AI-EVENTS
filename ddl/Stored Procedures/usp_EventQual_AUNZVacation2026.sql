CREATE PROCEDURE [dbo].[usp_EventQual_AUNZVacation2026]
       -- Error Parameters
		 @Error	INT = NULL OUTPUT
		,@ErrorMessage VARCHAR(4000) = NULL OUTPUT

		-- QA/DEV
		,@IsDevQA TINYINT = 0
AS
BEGIN

/*********************************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_AUNZVacation2026
	USE:		EXEC dbo.usp_EventQual_AUNZVacation2026 
				@IsDevQA = 1
	DESCRIPTION:
	NOTES:		
	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1.0.0		2025-05-20	    puertac  		Initial 								 
	1.1.0		2025-07-29		puertac			BRD V2
***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

DECLARE  @PK_Event INT = 203361  						   
		,@Month1 DATETIME  = '2025-01-01'
		,@Month2 DATETIME  = '2025-12-01'
		,@iMonth1 INT  = 202501
		,@iMonth2 INT  = 202512	
		,@iBonusMonth1 INT = 202503 
		,@iBonusMonth2 INT = 202505
		,@VacationPoints1 MONEY = 80000
		,@VacationPoints2 MONEY = 100000
		,@VacationPoints3 MONEY = 130000
		,@TVP1 MONEY = 40000
		,@TVP2 MONEY = 50000
		,@ROs1 MONEY = 70000								
		,@Bonus MONEY = 5000
		,@SubTypeFreezeDate  INT = 202501											
		,@FirstTimeBonusListID INT = 66457
			
	
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
	WHERE sCountryCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar]('AS,NZ', ','))
	
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
	VALUES (65542),(65543),(65544),(65545),(65546)

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

-----------------------------------------------------------------------------------------------------------
	-- Potential Qualifiers

	DROP TABLE IF EXISTS #FQSNonTABFreeze

	SELECT S.PK_DISTRIBUTOR, S.DISTRIBUTORID, S.ROYALTYMONTH, S.SUBTYPECODE, S.TEAMCODE, S.TYPECODE, COP_CountryCode
	INTO #FQSNonTABFreeze
	FROM PubEventManagement.Shared.DSSNAPSHOT AS S WITH (NOLOCK)
		WHERE RoyaltyMonth = @SubTypeFreezeDate
		AND SubTypeCode IN ('SP','WT')
		AND COP_CountryCode IN ('AS','NZ')
		AND StatusCode = 'COMPLETE'
			
	CREATE INDEX IX_#FQSNonTABFreeze_PK_Distributor ON #FQSNonTABFreeze(PK_Distributor);


	DROP TABLE IF EXISTS #GetMillFreeze

	SELECT S.PK_DISTRIBUTOR, S.DISTRIBUTORID, S.ROYALTYMONTH, S.SUBTYPECODE, S.TEAMCODE, S.TYPECODE, COP_CountryCode
	INTO #GetMillFreeze
	FROM PubEventManagement.Shared.DSSNAPSHOT AS S WITH (NOLOCK)
		WHERE RoyaltyMonth = @SubTypeFreezeDate
		AND SubTypeCode IN ('GT','GP','MT','MP')
		AND COP_CountryCode IN ('AS','NZ')
		AND StatusCode = 'COMPLETE'

	CREATE INDEX IX_#GetMillFreeze_PK_Distributor ON #GetMillFreeze(PK_Distributor);


	DROP TABLE IF EXISTS #PTAndAboveFreeze

	SELECT S.PK_DISTRIBUTOR, S.DISTRIBUTORID, S.ROYALTYMONTH, S.SUBTYPECODE, S.TEAMCODE, S.TYPECODE, COP_CountryCode
	INTO #PTAndAboveFreeze
	FROM PubEventManagement.Shared.DSSNAPSHOT AS S WITH (NOLOCK)
		WHERE RoyaltyMonth = @SubTypeFreezeDate
		AND TeamCode = 'P'	
		AND COP_CountryCode IN ('AS','NZ')
		AND StatusCode = 'COMPLETE'

	CREATE INDEX IX_#PTAndAboveFreeze_PK_Distributor ON #PTAndAboveFreeze(PK_Distributor);		   


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
		,IsAddedFromLists		BIT DEFAULT 0
		,IsFQSNonTABFreeze		BIT DEFAULT 0
		,IsGETMillFreeze		BIT DEFAULT 0	
		,IsPTFreeze				BIT DEFAULT 0	
		,IsFromAU				BIT DEFAULT 0
		,IsFromNZ				BIT DEFAULT 0
		,COPFreeze				CHAR(2)
	)

	INSERT INTO	#MBIDs					-- Insert FQS (Non-TAB)
	SELECT DISTINCT
		D.nDistributorID AS PK_Distributor
		,CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam
		,D.sSubteam AS DSSubTeam
		,D.sType AS DSSPTeam
		,D.dApplication AS ApplicationDate 
		,D.dSupervisorqualification AS SPQualDate
		,D.dSupervisorReQualification AS SPRequalDate
		,D.sDistributorCountryProcessingCode AS CountryCode
		,0 AS IsAddedFromLists, 1 AS IsFQSNonTABFreeze, 0 AS IsGETMillFreeze, 0 AS IsPTFreeze	
		,IIF(F.COP_CountryCode = 'AS', 1, 0) AS IsFromAU, IIF(F.COP_CountryCode = 'NZ', 1, 0) AS IsFromNZ
		,F.COP_COUNTRYCODE AS COPFreeze
	FROM dbo.v_Distributor D 									
	INNER JOIN #FQSNonTABFreeze AS F
		ON F.PK_DISTRIBUTOR = D.nDistributorID
	WHERE D.sType ='SP'	AND D.StatusCode = 'COMPLETE'   

	
	INSERT INTO	#MBIDs				-- Insert GET and MILL
	SELECT DISTINCT
		 D.nDistributorID AS PK_Distributor
		,CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam
		,D.sSubteam AS DSSubTeam
		,D.sType AS DSSPTeam
		,D.dApplication AS ApplicationDate 
		,D.dSupervisorqualification AS SPQualDate
		,D.dSupervisorReQualification AS SPRequalDate
		,D.sDistributorCountryProcessingCode AS CountryCode	
		,0 AS IsAddedFromLists, 0 AS IsFQSNonTABFreeze, 1 AS IsGETMillFreeze, 0 AS IsPTFreeze
		,IIF(G.COP_CountryCode = 'AS', 1, 0) AS IsFromAU, IIF(G.COP_CountryCode = 'NZ', 1, 0) AS IsFromNZ
		,G.COP_COUNTRYCODE AS COPFreeze
	FROM dbo.v_Distributor D 									
	INNER JOIN #GetMillFreeze AS G
		ON G.PK_DISTRIBUTOR = D.nDistributorID
	WHERE D.sType ='SP'	AND D.StatusCode = 'COMPLETE'  
	

	INSERT INTO	#MBIDs				-- Insert PT and Above
	SELECT DISTINCT
		 D.nDistributorID AS PK_Distributor
		,CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam
		,D.sSubteam AS DSSubTeam
		,D.sType AS DSSPTeam
		,D.dApplication AS ApplicationDate 
		,D.dSupervisorqualification AS SPQualDate
		,D.dSupervisorReQualification AS SPRequalDate
		,D.sDistributorCountryProcessingCode AS CountryCode	
		,0 AS IsAddedFromLists, 0 AS IsFQSNonTABFreeze, 0 AS IsGETMillFreeze, 1 AS IsPTFreeze	
		,IIF(P.COP_CountryCode = 'AS', 1, 0) AS IsFromAU, IIF(P.COP_CountryCode = 'NZ', 1, 0) AS IsFromNZ
		,P.COP_COUNTRYCODE AS COPFreeze
	FROM dbo.v_Distributor D 									
	INNER JOIN #PTAndAboveFreeze AS P
		ON P.PK_DISTRIBUTOR = D.nDistributorID
	WHERE D.sType ='SP'	AND D.StatusCode = 'COMPLETE'  


	INSERT INTO #MBIDs		-- Exception IDs from Lists 
	SELECT DISTINCT
		D.nDistributorID AS PK_Distributor
		,CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam
		,D.sSubteam AS DSSubTeam
		,D.sType AS DSSPTeam
		,D.dApplication AS ApplicationDate 
		,D.dSupervisorqualification AS SPQualDate
		,D.dSupervisorReQualification AS SPRequalDate
		,D.sDistributorCountryProcessingCode AS CountryCode
		,1 AS IsAddedFromLists, 0 AS IsFQSNonTABFreeze, 0 AS IsGETMillFreeze, 0 AS IsPTFreeze	
		,0 AS IsFromAU, 0 AS IsFromNZ, NULL AS COPFreeze
	FROM #DSList L
	INNER JOIN  dbo.v_Distributor D 	
		ON L.PK_Distributor = D.nDistributorID
	LEFT JOIN #Countries C WITH (NOLOCK) 
			ON D.nDistributorCountryProcessingID = C.nCountryID
	WHERE NOT EXISTS (SELECT 1 FROM #MBIDs M WHERE M.PK_Distributor = L.PK_Distributor) 


	CREATE INDEX IX_#MBIDs_PK_Distributor ON #MBIDs(PK_Distributor)


	INSERT INTO #EventQual(PK_Event, PK_Distributor, CreatedDate, UpdatedDate, Q01, Q02, Q03, Q04, Q09)		
	SELECT	A.PK_Event 
		   ,B.PK_Distributor 
		   ,GETUTCDATE() AS CreatedDate
		   ,GETUTCDATE() AS UpdatedDate
		   ,B.IsFQSNonTABFreeze AS Q01	
		   ,B.IsGETMillFreeze AS Q02
		   ,B.IsPTFreeze AS Q03
		   ,B.IsFromAU AS Q04
		   ,B.IsFromNZ AS Q09
	FROM #Events A
	CROSS APPLY #MBIDs B

	CREATE INDEX IX_#EventQual_PK_Distributor ON #EventQual(PK_Distributor)
-----------------------------------------------------------------------------------------------------------
	-- Volume 
	DROP TABLE IF EXISTS #ROsWW
		
	SELECT 	T.PK_Distributor
			,FORMAT(A.dRoyaltyMonth,'yyyyMM') AS RoyaltyMonth					  
			,(A.mRoyaltyOverrides + A.mMainRoyaltyOverrides) AS RO
	INTO #ROsWW
	FROM #MBIDs T
	INNER JOIN dbo.v_aggFQS_ID A WITH (NOLOCK)
		ON 	T.PK_Distributor = A.nDistributorID
		AND A.dRoyaltyMonth BETWEEN @Month1 AND @Month2							-- Qual Period A: Jan 2025 to Dec 2025
	WHERE T.IsPTFreeze = 1

	CREATE INDEX IX_#ROsWW_PK_Distributor ON #ROsWW(PK_Distributor)


		DROP TABLE IF EXISTS #PersonalAndInherited_ROsCOP						
						   
			SELECT P.PK_Distributor, P.RoyaltyMonth, P.CountryCode, P.AMOUNT AS RO, CAST (0 AS BIT) AS Isinherited
		INTO #PersonalAndInherited_ROsCOP
			FROM #MBIDs AS D
			INNER JOIN PubEvents.dbo.factDSFinancial_PHX AS P WITH (NOLOCK)
				ON D.PK_Distributor = P.PK_Distributor
				AND P.FINANCIALTYPE = 'RO'
				AND P.COUNTRYCODE = D.COPFreeze
			WHERE P.RoyaltyMonth BETWEEN @iMonth1 AND @iMonth2							-- Qual Period A: Jan 2025 to Dec 2025
		UNION
			SELECT P.PK_Distributor, P.RoyaltyMonth, P.CountryCode, P.AMOUNT AS RO, CAST (1 AS BIT) AS Isinherited
			FROM Shared.DistributorAssociation AS A WITH (NOLOCK)
			INNER JOIN #MBIDs AS D
				ON A.PK_Distributor = D.PK_Distributor
			INNER JOIN PubEvents.dbo.factDSFinancial_PHX AS P WITH (NOLOCK)
				ON A.PK_AssociatedID = P.PK_Distributor
				AND P.FINANCIALTYPE = 'RO'
				AND P.COUNTRYCODE = D.COPFreeze
			WHERE P.RoyaltyMonth BETWEEN @iMonth1 AND @iMonth2							-- Qual Period A: Jan 2025 to Dec 2025		

		CREATE INDEX IX_#PersonalAndInherited_ROsCOP_PK_Distributor ON #PersonalAndInherited_ROsCOP(PK_Distributor)
	
																																			  
	DROP TABLE IF EXISTS #ROsCOP

	SELECT PK_Distributor, RoyaltyMonth, CountryCode, SUM(RO) AS RO
	INTO #ROsCOP
	FROM #PersonalAndInherited_ROsCOP
	GROUP BY PK_Distributor, RoyaltyMonth, CountryCode

	CREATE INDEX IX_#ROsCOP_PK_Distributor ON #ROsCOP(PK_Distributor)

												

		DROP TABLE IF EXISTS #PersonalAndInherited_TVPCOP	

			SELECT M.PK_Distributor, F.RoyaltyMonth, F.CountryCode
				,CASE WHEN F.Order_Purpose = 'XX' THEN PV																						-- Order Purpose = XX																	    
					 WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose NOT IN ('XX','PC') THEN PV_DV							-- Order fulfillment NOT US/PR/BR/CO and Order Purpose IS NOT XX or PC
					 WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose = 'PC' THEN PV											-- Order fulfillment NOT US/PR/BR/CO and Order Purpose IS PC																			
				 END AS PV
				,CASE WHEN F.Order_Purpose = 'XX' THEN GV																					
					  WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose NOT IN ('XX','PC') THEN GV_DV	
					  WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose = 'PC' THEN GV								
				 END AS GV
				,(CASE WHEN F.Order_Purpose = 'XX' THEN PV																						-- Order Purpose = XX																	    
					 WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose NOT IN ('XX','PC') THEN PV_DV							-- Order fulfillment NOT US/PR/BR/CO and Order Purpose IS NOT XX or PC
					 WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose = 'PC' THEN PV											-- Order fulfillment NOT US/PR/BR/CO and Order Purpose IS PC																			
				  END + CASE	WHEN F.Order_Purpose = 'XX' THEN GV																					
			 					WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose NOT IN ('XX','PC') THEN GV_DV	
								WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose = 'PC' THEN GV								
						 END
				  )AS TVP
		INTO #PersonalAndInherited_TVPCOP
			FROM  PubEvents.dbo.factDSFinancial_ctry AS F WITH (NOLOCK)
			INNER JOIN #MBIDs AS M
				ON F.PK_Distributor = M.PK_Distributor
			WHERE F.RoyaltyMonth BETWEEN @iMonth1 AND @iMonth2																				-- Qual Period A: Jan 2025 to Dec 2025
			AND F.CountryCode = IIF(M.COPFreeze = 'AS', 'AU', M.COPFreeze)			-- This table has Australia COP by contrycodeISO
		UNION
			SELECT M.PK_Distributor, F.RoyaltyMonth, F.CountryCode
				,CASE WHEN F.Order_Purpose = 'XX' THEN PV																						-- Order Purpose = XX																	    
					 WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose NOT IN ('XX','PC') THEN PV_DV							-- Order fulfillment NOT US/PR/BR/CO and Order Purpose IS NOT XX or PC
					 WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose = 'PC' THEN PV											-- Order fulfillment NOT US/PR/BR/CO and Order Purpose IS PC																			
				 END AS PV
				,CASE WHEN F.Order_Purpose = 'XX' THEN GV																					
					  WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose NOT IN ('XX','PC') THEN GV_DV	
					  WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose = 'PC' THEN GV								
				 END AS GV
				,(CASE WHEN F.Order_Purpose = 'XX' THEN PV																						-- Order Purpose = XX																	    
					 WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose NOT IN ('XX','PC') THEN PV_DV							-- Order fulfillment NOT US/PR/BR/CO and Order Purpose IS NOT XX or PC
					 WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose = 'PC' THEN PV											-- Order fulfillment NOT US/PR/BR/CO and Order Purpose IS PC																			
				  END + CASE	WHEN F.Order_Purpose = 'XX' THEN GV																					
			 					WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose NOT IN ('XX','PC') THEN GV_DV	
								WHEN F.CountryCode NOT IN ('US','PR','BR','CO') AND F.Order_Purpose = 'PC' THEN GV								
						 END
				  )AS TVP
			FROM  PubEvents.dbo.factDSFinancial_ctry AS F WITH (NOLOCK)
			INNER JOIN Shared.DistributorAssociation AS A WITH (NOLOCK)
				ON A.PK_AssociatedID = F.PK_Distributor
			INNER JOIN #MBIDs AS M
				ON A.PK_Distributor = M.PK_Distributor
			WHERE F.RoyaltyMonth BETWEEN @iMonth1 AND @iMonth2																				-- Qual Period A: Jan 2025 to Dec 2025
			AND F.CountryCode = IIF(M.COPFreeze = 'AS', 'AU', M.COPFreeze)			-- This table has Australia COP by contrycodeISO
			
			CREATE INDEX IX_#PersonalAndInherited_TVPCOP_PK_Distributor ON #PersonalAndInherited_TVPCOP(PK_Distributor)
		
																																							  
		DROP TABLE IF EXISTS #TVPCOP	
						 
		SELECT PK_Distributor, RoyaltyMonth, CountryCode, SUM(TVP) AS TVP
		INTO #TVPCOP
		FROM #PersonalAndInherited_TVPCOP
		GROUP BY PK_Distributor, RoyaltyMonth, CountryCode

		CREATE INDEX IX_#TVPCOP_PK_Distributor ON #TVPCOP(PK_Distributor)		
		   

	DROP TABLE IF EXISTS #Months 

	SELECT iMonth,dMonthStart AS dMonth
	INTO #Months
	FROM udf_MonthsRangeByInt(@Month1, 12, 1)	
				
	CREATE INDEX IX_#Months_PKs ON #Months(dMonth)	
							 

	DROP TABLE IF EXISTS #TotalVolumePoints

	SELECT I.PK_Distributor, dMonth AS RoyaltyMonth, ISNULL(RW.RO, 0) AS ROWW, ISNULL(RC.RO, 0) AS ROCOP, ISNULL(TC.TVP, 0) AS TVP 
	INTO #TotalVolumePoints
	FROM #MBIDs AS I
	CROSS APPLY	#Months AS M
	LEFT JOIN #ROsWW AS RW
		ON RW.PK_Distributor = I.PK_Distributor
		AND RW.RoyaltyMonth = M.iMonth
	LEFT JOIN #ROsCOP AS RC
		ON RC.PK_Distributor = I.PK_Distributor
		AND RC.RoyaltyMonth = M.iMonth
	LEFT JOIN #TVPCOP AS TC
		ON TC.PK_Distributor = I.PK_Distributor
		AND TC.RoyaltyMonth = M.iMonth

	CREATE INDEX IX_#TotalVolumePoints_PK_Distributor ON #TotalVolumePoints(PK_Distributor)	

--------------------------------------------------------------------------------------------------------------------------------------
	-- Bonuses
		DROP TABLE IF EXISTS #AllPrevQualifiers   	   	   -- 1.1.0

			SELECT S.nDistributorID AS PK_Distributor												  
			INTO #AllPrevQualifiers
			FROM dbo.v_DistributorSet AS S
			WHERE S.dThrough = '2049-12-31'
			AND S.nTypeLID = @FirstTimeBonusListID

		CREATE INDEX IX_#AllPrevQualifiers_PK_Distributor ON #AllPrevQualifiers(PK_Distributor)	

																																			
	DROP TABLE IF EXISTS #FirstTimerBonus
											  
	SELECT M.PK_Distributor, @Bonus AS BonusAmount
	INTO #FirstTimerBonus
	FROM #MBIDs AS M 
	WHERE NOT EXISTS (SELECT 1 FROM	#AllPrevQualifiers AS P WHERE P.PK_Distributor = M.PK_Distributor)

	CREATE INDEX IX_#FirstTimerBonus_PK_Distributor ON #FirstTimerBonus(PK_Distributor)	
		   
	DROP TABLE IF EXISTS #HPLBonus

	SELECT PK_Distributor, @Bonus AS BonusAmount
	INTO #HPLBonus
	FROM Promo.WRK_HPL2025_SubEvent WHERE SubEvent IN (1,2)
	AND DateQualified BETWEEN @iMonth1 AND @iMonth2

	CREATE INDEX IX_#HPLBonus_PK_Distributor ON #HPLBonus(PK_Distributor)	
											  
																							 
	DROP TABLE IF EXISTS #March2025Bonus
		   
	SELECT PK_Distributor, TVP AS MarVol, IIF(TVP<= @Bonus, TVP, @Bonus) AS BonusAmount
	INTO #March2025Bonus
	FROM #TVPCOP
	WHERE RoyaltyMonth = @iBonusMonth1
	AND TVP > 0

	CREATE INDEX IX_#March2025Bonus_PK_Distributor ON #March2025Bonus(PK_Distributor)	

																																			   
	DROP TABLE IF EXISTS #May2025Bonus

	SELECT PK_Distributor, TVP AS MarVol, IIF(TVP<= @Bonus, TVP, @Bonus) AS BonusAmount
	INTO #May2025Bonus
	FROM #TVPCOP
	WHERE RoyaltyMonth = @iBonusMonth2
	AND TVP > 0

	CREATE INDEX IX_#May2025Bonus_PK_Distributor ON #May2025Bonus(PK_Distributor)	

								
	DROP TABLE IF EXISTS #Total_RegularVolumePoints

	SELECT PK_Distributor, SUM(ROCOP) AS Total_ROCOP, SUM(ROWW) AS Total_ROWW, SUM(TVP) AS Total_TVP, SUM(ROCOP+TVP) AS Local_VacationPoints, SUM(ROWW+TVP) AS WW_VacationPoints
	INTO #Total_RegularVolumePoints
	FROM #TotalVolumePoints
	GROUP BY PK_Distributor
	
	CREATE INDEX IX_#Total_RegularVolumePointss_PK_Distributor ON #Total_RegularVolumePoints(PK_Distributor)

	
	DROP TABLE IF EXISTS #MBIDsSummary
																																							   
	SELECT I.PK_Distributor, I.COPFreeze, I.IsAddedFromLists, I.IsFQSNonTABFreeze, I.IsGETMillFreeze, I.IsPTFreeze, T.Total_ROCOP, T.Total_ROWW, T.Total_TVP, T.Local_VacationPoints, T.WW_VacationPoints
		   ,ISNULL(FB.BonusAmount,0) AS FirstTimerBonus, ISNULL(HB.BonusAmount,0) AS HPLBonus, ISNULL(MB1.BonusAmount,0) AS MarchBonus, ISNULL(MB2.BonusAmount,0) AS MayBonus
		   ,ISNULL(FB.BonusAmount,0) + ISNULL(HB.BonusAmount,0) + ISNULL(MB1.BonusAmount,0) + ISNULL(MB2.BonusAmount,0) AS Total_BonusesOnly
		   ,Local_VacationPoints + ISNULL(FB.BonusAmount,0) + ISNULL(HB.BonusAmount,0) + ISNULL(MB1.BonusAmount,0) + ISNULL(MB2.BonusAmount,0) AS Total_Local
		   ,WW_VacationPoints + ISNULL(FB.BonusAmount,0) + ISNULL(HB.BonusAmount,0) + ISNULL(MB1.BonusAmount,0) + ISNULL(MB2.BonusAmount,0) AS Total_WW
	INTO #MBIDsSummary
	FROM #MBIDs AS I
	INNER JOIN #Total_RegularVolumePoints AS T
		ON I.PK_Distributor = T.PK_Distributor
	LEFT JOIN #FirstTimerBonus AS FB
		ON FB.PK_Distributor = I.PK_Distributor
	LEFT JOIN #HPLBonus AS HB
		ON HB.PK_Distributor = I.PK_Distributor
	LEFT JOIN #March2025Bonus AS MB1
		ON MB1.PK_Distributor = I.PK_Distributor	
	LEFT JOIN #May2025Bonus AS MB2
		ON MB2.PK_Distributor = I.PK_Distributor	
	
	CREATE INDEX IX_#MBIDsSummary_PK_Distributor ON #MBIDsSummary(PK_Distributor)	
										
--------------------------------------------------------------------------------------------------------------------------------------
	-- Qualifications

	-- Q5 Vacation Points >= 80,000 over Qual Period A   --------------------------------------------
		DROP TABLE IF EXISTS #Q05

		SELECT PK_Distributor, COPFreeze
		INTO #Q05
		FROM #MBIDsSummary 
		WHERE Total_Local >= @VacationPoints1
		 	
		CREATE INDEX IX_#Q05_PK_Distributor ON #Q05(PK_Distributor)


	-- Q6 Vacation Points >= 100,000 over Qual Period A   --------------------------------------------
		DROP TABLE IF EXISTS #Q06

		SELECT PK_Distributor, COPFreeze
		INTO #Q06
		FROM #MBIDsSummary 
		WHERE Total_Local >= @VacationPoints2
		 	
		CREATE INDEX IX_#Q06_PK_Distributor ON #Q06(PK_Distributor)


	-- Q7 Vacation Points >= 130,000 over Qual Period A with a minimum of TVP >= 40,000  --------------------------------------------
		DROP TABLE IF EXISTS #Q07

		SELECT PK_Distributor, COPFreeze
		INTO #Q07
		FROM #MBIDsSummary 
		WHERE Total_Local >= @VacationPoints3
		AND (Total_TVP+Total_BonusesOnly) >= @TVP1
		 	
		CREATE INDEX IX_#Q07_PK_Distributor ON #Q07(PK_Distributor)


	-- Q8 Vacation Points >= 130,000 over Qual Period A with a minimum of TVP >= 50,000 and a minimum of RO >= 70,000  ---------------------
		DROP TABLE IF EXISTS #Q08

		SELECT PK_Distributor, COPFreeze
		INTO #Q08
		FROM #MBIDsSummary 
		WHERE Total_WW >= @VacationPoints3
		AND (Total_TVP+Total_BonusesOnly) >= @TVP2 
		AND Total_ROWW >= @ROs1
		 	
		CREATE INDEX IX_#Q08_PK_Distributor ON #Q08(PK_Distributor)
		
				 
	UPDATE Q
	SET  Q05 = IIF(Q05.PK_Distributor IS NOT NULL, 1, 0) 
		,Q06 = IIF(Q06.PK_Distributor IS NOT NULL, 1, 0) 
		,Q07 = IIF(Q07.PK_Distributor IS NOT NULL, 1, 0)
		,Q08 = IIF(Q08.PK_Distributor IS NOT NULL, 1, 0)
		,Q10 = IIF(Q10.PK_Distributor IS NOT NULL, 1, 0)
		,Q11 = IIF(Q11.PK_Distributor IS NOT NULL, 1, 0)
		,Q12 = IIF(Q12.PK_Distributor IS NOT NULL, 1, 0) 
		,Q13 = IIF(Q13.PK_Distributor IS NOT NULL, 1, 0)
	FROM #EventQual AS Q
	LEFT JOIN #Q05 AS Q05
		ON Q.PK_Distributor = Q05.PK_Distributor				  
		AND Q05.COPFreeze = 'AS'
	LEFT JOIN #Q06 AS Q06
		ON Q.PK_Distributor = Q06.PK_Distributor
		AND Q06.COPFreeze = 'AS'
	LEFT JOIN #Q07 AS Q07
		ON Q.PK_Distributor = Q07.PK_Distributor
		AND Q07.COPFreeze = 'AS'
	LEFT JOIN #Q08 AS Q08
		ON Q.PK_Distributor = Q08.PK_Distributor
		AND Q08.COPFreeze = 'AS'	  
	LEFT JOIN #Q05 AS Q10
		ON Q.PK_Distributor = Q10.PK_Distributor
		AND Q10.COPFreeze = 'NZ'
	LEFT JOIN #Q06 AS Q11
		ON Q.PK_Distributor = Q11.PK_Distributor
		AND Q11.COPFreeze = 'NZ'
	LEFT JOIN #Q07 AS Q12
		ON Q.PK_Distributor = Q12.PK_Distributor
		AND Q12.COPFreeze = 'NZ'
	LEFT JOIN #Q08 AS Q13
		ON Q.PK_Distributor = Q13.PK_Distributor
		AND Q13.COPFreeze = 'NZ'
		   				
				
	-- Lists
	UPDATE A
	SET  Q14 = ISNULL(L.[65542],0) 
		,Q15 = ISNULL(L.[65543],0)
		,Q16 = ISNULL(L.[65544],0) 
		,Q17 = ISNULL(L.[65545],0)
		,Q18 = ISNULL(L.[65546],0) 					
	FROM #EventQual A
	LEFT JOIN (
		SELECT  PK_Distributor, [65542],[65543],[65544],[65545],[65546]
		FROM (SELECT  PK_Distributor, ListID, CAST(PK_Distributor AS NVARCHAR(20))+ '-' + CAST(ListID AS NVARCHAR(20)) AS UniqueID	FROM #DSList) P
		PIVOT (COUNT (UniqueID)	FOR ListID IN ([65542],[65543],[65544],[65545],[65546])) AS pvt	
	) L
	ON A.PK_Distributor = L.PK_Distributor


	-- UPDATE SubEvents
	UPDATE #EventQual
	SET	 E02 =	(Q01 & ( (Q04 & Q05) | (Q09 & Q10) ) ) | Q15			-- (Q1 + ((Q4 + Q5) OR (Q9 + Q10))) OR Q15
		,E03 =	(Q01 & ( (Q04 & Q06) | (Q09 & Q11) ) ) | Q16			-- (Q1 + ((Q4 + Q6) OR (Q9 + Q11))) OR Q16
		,E04 =	(Q02 & ( (Q04 & Q07) | (Q09 & Q12) ) ) | Q17			-- (Q2 + ((Q4 + Q7) OR (Q9 + Q12))) OR Q17
		,E05 =	(Q03 & ( (Q04 & Q08) | (Q09 & Q13) ) ) | Q18			-- (Q3 + ((Q4 + Q8) OR (Q9 + Q13))) OR Q18
		
	UPDATE #EventQual
	SET	 E01 =	E02 | E03 | E04 | E05 | Q14 							-- E2 OR E3 OR E4 OR E5 OR Q14
																						  
	DELETE FROM #EventQual
	WHERE ( 
			~Q01  & ~Q02 & ~Q03 & ~Q04 & ~Q05 & ~Q06  & ~Q07 & ~Q08 & ~Q09 & ~Q10 &
			~Q11  & ~Q12 & ~Q13 & ~Q14 & ~Q15 &	~Q16  & ~Q17 & ~Q18 & ~Q19 & ~Q20 &
			~Q21  & ~Q22 & ~Q23 & ~Q24 & ~Q25 &	~Q26  & ~Q27 & ~Q28 & ~Q29 & ~Q30 &
			~Q31  & ~Q32 & ~Q33 & ~Q34 & ~Q35 &	~Q36  & ~Q37 & ~Q38 & ~Q39 & ~Q40 &
			~Q41  & ~Q42 & ~Q43 & ~Q44 & ~Q45 &	~Q46  & ~Q47 & ~Q48 & ~Q49 & ~Q50 
			)= 1				  


	--WRK tables
	DROP INDEX IF EXISTS [IX_WRK_AUNZVacation2026_PK_Distributor] ON [dbo].[WRK_AUNZVacation2026];

	IF OBJECT_ID('WRK_AUNZVacation2026', 'U') IS NOT NULL 
		TRUNCATE TABLE dbo.WRK_AUNZVacation2026
				
	INSERT INTO dbo.WRK_AUNZVacation2026(PK_Distributor, COPFreeze, IsAddedFromLists, IsFQSNonTABFreeze, IsGETMillFreeze, IsPTFreeze, Total_ROCOP, Total_ROWW, Total_TVP, Local_VacationPoints, WW_VacationPoints
										,FirstTimerBonus, HPLBonus, MarchBonus, MayBonus, Total_BonusesOnly, Total_Local, Total_WW)
	SELECT PK_Distributor, COPFreeze, IsAddedFromLists, IsFQSNonTABFreeze, IsGETMillFreeze, IsPTFreeze, Total_ROCOP, Total_ROWW, Total_TVP, Local_VacationPoints, WW_VacationPoints
		  ,FirstTimerBonus, HPLBonus, MarchBonus, MayBonus, Total_BonusesOnly, Total_Local, Total_WW			  
	FROM #MBIDsSummary
				
	CREATE CLUSTERED INDEX [IX_WRK_AUNZVacation2026_PK_Distributor] ON [dbo].[WRK_AUNZVacation2026] ([PK_Distributor])


	DROP INDEX IF EXISTS [IX_WRK_AUNZVacation2026_Points_PK_Distributor] ON [dbo].[WRK_AUNZVacation2026_Points];

	IF OBJECT_ID('WRK_AUNZVacation2026_Points', 'U') IS NOT NULL 
		TRUNCATE TABLE dbo.WRK_AUNZVacation2026_Points
				
	INSERT INTO dbo.WRK_AUNZVacation2026_Points(PK_Distributor, RoyaltyMonth, ROWW, ROCOP, TVP)
	SELECT PK_Distributor, RoyaltyMonth, ROWW, ROCOP, TVP				  
	FROM #TotalVolumePoints
				
	CREATE CLUSTERED INDEX [IX_WRK_AUNZVacation2026_Points_PK_Distributor] ON [dbo].[WRK_AUNZVacation2026_Points] ([PK_Distributor])

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
