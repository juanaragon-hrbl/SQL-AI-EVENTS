CREATE PROCEDURE [dbo].[usp_EventQual_NAM_GetawayVacation2024]
       -- Error Parameters
		 @Error	INT = NULL OUTPUT
		,@ErrorMessage VARCHAR(4000) = NULL OUTPUT

		-- QA/DEV
		,@IsDevQA TINYINT = 0
AS
BEGIN

/*********************************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_NAM_GetawayVacation2024
	USE:		EXEC dbo.usp_EventQual_NAM_GetawayVacation2024
				@IsDevQA = 1
	DESCRIPTION:
	NOTES:		
	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1.0.0		2022-11-17	   puertac  		Initial 
	2.0.0		2024-02-10	   juangue			BRD v2
	2.0.1		2024-02-13	   juangue			Toatl vacation points fix
	2.0.2		2024-03-08	   juangue			Bug fix #1330096 - Incorrect E4. AWT qualifiers
***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID) 
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

/* VARIABLE DECLARATION */
DECLARE  @PK_Event1 INT = 193112  						   			   
		,@Country1  VARCHAR (5) = 'US'
		,@Country2  VARCHAR (5) = 'PR'
		,@Country3  VARCHAR (5) = 'CA'	
		,@Month1  DATETIME = '2023-01-01'				
		,@Month12 DATETIME = '2023-12-01'
		,@Month13 DATETIME = '2024-01-01'
		,@ValidDate DATETIME = '2049-12-31' 
		,@Points1 MONEY = 80000
		,@Points2 MONEY = 90000
		,@Points3 MONEY = 100000
		,@PK_TABVacation INT = 193219 

BEGIN TRY   

	IF @IsDevQA= 2 THROW 60000, N'Unit test Error', 1;

	/*****************************************************************  
			Drop Temporary tables in case they already exist
	******************************************************************/
	IF OBJECT_ID('tempdb..#Events') IS NOT NULL DROP TABLE #Events
	IF OBJECT_ID('tempdb..#EventQual') IS NOT NULL DROP TABLE #EventQual												 
	IF OBJECT_ID('tempdb..#MBIDs') IS NOT NULL DROP TABLE #MBIDs								   																   
	IF OBJECT_ID('tempdb..#MBIDsPoints') IS NOT NULL DROP TABLE #MBIDsPoints
	IF OBJECT_ID('tempdb..#LIST')    IS NOT NULL DROP TABLE #LIST
		
	CREATE TABLE #Events
	(
		PK_Event INT
	)

	CREATE TABLE #LIST
	(
		 PK_Distributor INT
		,ListID INT
	)



	CREATE TABLE #EventQual
	(
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

	CREATE TABLE #MBIDs
	(
		 PK_Distributor	         INT
		,sDistributorID			 VARCHAR (20)												   
		,DSCurrentTeam	         CHAR(5)
		,DSSubTeam	             CHAR(5)
		,DSSPTeam	             CHAR(5)
		,ApplicationDate		 DATETIME
		,SPQualDate	             DATETIME		
		,CountryCode             CHAR(2)
		,TAB2023				 BIT DEFAULT 0
		,TABQualDate			 DATETIME
		,TotalTVP	             MONEY DEFAULT 0
		,TotalRO	             MONEY DEFAULT 0																																	  
		,TotalVacationPoints	 MONEY DEFAULT 0
	)

	 CREATE TABLE #MBIDsPoints
	(
		 PK_Distributor				INT
		,mVolumePoints				MONEY
		,mRoyaltyOverrides			MONEY
		,mMainRoyaltyOverrides		MONEY			   
	)	

	INSERT INTO #Events(PK_Event)
	VALUES   (193112)   	-- Main Tracker 			   		
			,(193114)		-- Minneapolis, MN 
			,(193116)		-- Orlando, FL 
			,(193118)		-- Philadelphia, PA 
			,(193120)		-- Chicago, IL 
			,(193122)		-- San Antonio, TX 
			,(193124)		-- Las Vegas, NV 
			,(193126)		-- San Juan, PR 


	INSERT INTO #LIST(PK_Distributor, ListID)
	SELECT nDistributorID, nTypeLID 
	FROM dbo.v_DistributorSet 
	WHERE nTypeLID IN (52162, 52163, 52164, 52165,58721,58722,58723,58724,58725,58726,58727,58728,58729,58730,58731,58732,58733,58734,58735,58736,58737,58738,58739,58740,58741) AND dThrough = '2049-12-31'


	--Exception list ID 58721 ("24003 Level 1 Orlando FL")
	-- IDs with Ticket
	DROP TABLE IF EXISTS #DSSKUs

	CREATE TABLE #DSSKUs (
		PK_Distributor INT
		,PK_EventSKU INT
		,SKUCode VARCHAR(10)
	)	

	INSERT INTO #DSSKUs(PK_Distributor,PK_EventSKU,SKUCode)
	SELECT DISTINCT et.PK_Distributor_Purchaser,esku.PK_EventSKU, esku.SKUCode  
	FROM EventSKU AS esku WITH (NOLOCK)
	INNER JOIN [dbo].[SKUPurchased] et WITH (NOLOCK)
		ON et.PK_EventSKU = esku.PK_EventSKU
	INNER JOIN #Events AS E
		ON et.PK_Event = E.PK_Event
	WHERE esku.IsEventTicketSKU = 1

	CREATE INDEX IX_DSSKUs_PK_Distributor ON #DSSKUs(PK_Distributor)
	
	/*****************************************************************  
				Insert all the potential qualifiers
	******************************************************************/
	INSERT INTO	#MBIDs(	PK_Distributor, sDistributorID, DSCurrentTeam, DSSubTeam, DSSPTeam, ApplicationDate, SPQualDate, CountryCode)
	SELECT DISTINCT
		D.nDistributorID AS PK_Distributor,
		D.sDistributorID,							
		CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,
		D.sSubteam AS DSSubTeam,
		D.sType AS DSSPTeam,
		D.dApplication,
		D.dSupervisorqualification AS SPQualDate,
		D.sDistributorCountryProcessingCode AS CountryCode
	FROM dbo.v_Distributor D WITH (NOLOCK)									
	INNER JOIN dbo.v_Countries C WITH (NOLOCK) 
			ON D.sDistributorCountryProcessingCode = C.sCountryCode		
	LEFT JOIN #LIST (NOLOCK) DS
		ON	D.nDistributorID = DS.PK_Distributor
	WHERE D.StatusCode = 'COMPLETE'
	AND ((D.sType = 'SP' AND D.dSupervisorqualification < @Month13	
	AND	C.sCountryCode IN (@Country1,  @Country2,  @Country3)) 
		OR DS.PK_Distributor IS NOT NULL)


	-- Exception IDs from SKUs
	INSERT INTO	#MBIDs(	PK_Distributor, sDistributorID, DSCurrentTeam, DSSubTeam, DSSPTeam, ApplicationDate, SPQualDate, CountryCode)
	SELECT DISTINCT
		D.nDistributorID AS PK_Distributor,
		D.sDistributorID,							
		CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,
		D.sSubteam AS DSSubTeam,
		D.sType AS DSSPTeam,
		D.dApplication,
		D.dSupervisorqualification AS SPQualDate,
		D.sDistributorCountryProcessingCode AS CountryCode
	FROM dbo.v_Distributor D WITH (NOLOCK)									
	INNER JOIN #DSSKUs SKU WITH (NOLOCK)
			ON SKU.PK_Distributor = D.nDistributorID	
	WHERE D.sType IN ('DS', 'SP') 
	AND D.StatusCode = 'COMPLETE'  
	AND NOT EXISTS (SELECT 1 FROM #MBIDs M WHERE M.PK_Distributor = D.nDistributorID) 


	-- Exception IDs from Lists 
	INSERT INTO	#MBIDs(	PK_Distributor, sDistributorID, DSCurrentTeam, DSSubTeam, DSSPTeam, ApplicationDate, SPQualDate, CountryCode)
	SELECT DISTINCT
		D.nDistributorID AS PK_Distributor,
		D.sDistributorID,							
		CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam,
		D.sSubteam AS DSSubTeam,
		D.sType AS DSSPTeam,
		D.dApplication,
		D.dSupervisorqualification AS SPQualDate,
		D.sDistributorCountryProcessingCode AS CountryCode				
	FROM #LIST L
	INNER JOIN dbo.v_Distributor D 
		ON L.PK_Distributor = D.nDistributorID
	WHERE D.sType IN ('DS', 'SP') 
	AND D.StatusCode = 'COMPLETE'  
	AND NOT EXISTS (SELECT 1 FROM #MBIDs M WHERE M.PK_Distributor = D.nDistributorID) 


	CREATE INDEX IX_#MBIDs_PK_Distributor ON #MBIDs(PK_Distributor)
													 
	/****************************************************************************  
		Insert into #EventQual all the potential qualifiers from #MBIDs 
	*****************************************************************************/	
	INSERT INTO #EventQual(
		PK_Event,
		PK_Distributor,
		CreatedDate,
		UpdatedDate)
	SELECT 
		@PK_Event1,
		B.PK_Distributor INT,
		GETUTCDATE() AS CreatedDate,
		GETUTCDATE() AS UpdatedDate
	FROM #MBIDs B


	/*****************************************************************************************  
		  Get the Points achieved by each distributor in #MBIDs on certain period of time
	******************************************************************************************/																				 
	INSERT INTO #MBIDsPoints(
		 PK_Distributor
		,mVolumePoints				
		,mRoyaltyOverrides			
		,mMainRoyaltyOverrides		
	)
	SELECT  T.PK_Distributor
		,SUM(ISNULL(A.mVolumePoints,0))
		,SUM(ISNULL(A.mRoyaltyOverrides,0))
		,SUM(ISNULL(A.mMainRoyaltyOverrides,0))	
	FROM #MBIDs T
	INNER JOIN dbo.v_aggFQS_ID A WITH (NOLOCK)
		ON 	T.PK_Distributor = A.nDistributorID
	AND A.dRoyaltyMonth BETWEEN @Month1 AND @Month12
	GROUP BY	
		PK_Distributor

	CREATE INDEX IX_#MBIDsPoints_PK_Distributor ON #MBIDsPoints(PK_Distributor)


	/***************************************************  
		  Update Points Columns on #MBIDs
	****************************************************/

	UPDATE
		T
	SET
		T.TotalTVP				=	ISNULL((SELECT A.mVolumePoints								 FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor),0),
		T.TotalRO				=	ISNULL((SELECT (A.mRoyaltyOverrides+A.mMainRoyaltyOverrides) FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor),0),
		T.TotalVacationPoints	=	ISNULL((SELECT (A.mVolumePoints+A.mRoyaltyOverrides+A.mMainRoyaltyOverrides) FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor),0)
	FROM
		#MBIDs T																   	  
						
	
	/*****************************************************  
		Update TAB2023 & TABQualDate Columns on #MBIDs
	******************************************************/
	;WITH cte_TABs (PK_Distributor, QualDate)
	AS (
		SELECT DISTINCT M.PK_Distributor,MIN(H.dFrom)  
		 FROM #MBIDs M  
		 INNER JOIN dbo.v_DistributorHistory H 
			ON M.PK_Distributor = H.nDistributorIDFK 
		 INNER JOIN dbo.v_dimDSLifeCycle LC
			ON LC.LifeCycleCode = 225						-- V3
			AND H.SortOrder = LC.SortOrder					-- V3
			AND H.dThrough = @ValidDate 
			AND H.dFrom BETWEEN @Month1 AND @Month12
		GROUP BY M.PK_Distributor
	)														 

	UPDATE A
	 SET A.TAB2023 = 1
		,A.TABQualDate = CT.QualDate
	 FROM #MBIDs A
	 INNER JOIN cte_TABs  CT
		ON A.PK_Distributor = CT.PK_Distributor	

/********************************* QUALIFICATIONS ************************************/
	UPDATE A
	SET	 A.Q01 = CASE WHEN (C.DSSPTeam = 'SP' AND C.DSCurrentTeam NOT IN ('G','M','P','A','B','C')) THEN 1 ELSE 0 END -- FQS (Non TAB) (SP Qual Date before Jan 2024)
		,A.Q02 = C.TAB2023																							  -- TAB team (Team Qual Date Jan 2023 to Dec 2023)									 
	FROM #EventQual A
	LEFT JOIN  #MBIDs C
		ON A.PK_Distributor = C.PK_Distributor


	/*****************************************************  
		Update TABQualDate for TABs 2023 on #MBIDs
	******************************************************/
	;WITH cte_TABs23 (PK_Distributor, QualDate)
	AS (
		SELECT DISTINCT M.PK_Distributor,MIN(H.dFrom)  
		 FROM #MBIDs M  
		 INNER JOIN dbo.v_DistributorHistory H 
			ON M.PK_Distributor = H.nDistributorIDFK 
		 INNER JOIN dbo.v_dimDSLifeCycle LC
			ON LC.LifeCycleCode BETWEEN 225 AND 241
		 WHERE H.SortOrder >= LC.SortOrder 
		AND H.dThrough = @ValidDate 
		AND H.dFrom >= @Month13
		GROUP BY M.PK_Distributor
	)
		
	 UPDATE A
	 SET A.TABQualDate = CT.QualDate
	 FROM #MBIDs A
	 INNER JOIN cte_TABs23 CT
		ON A.PK_Distributor = CT.PK_Distributor
	 WHERE A.TABQualDate IS NULL
			   		 	  	  	   	

	/********************************************************************************  
		Update Q01 for TABs in 2024 (Became TAB on 2024, but were Non-TAB all 2023)
	*********************************************************************************/
	;WITH cte_NonTABs (PK_Distributor)
	AS (
		SELECT DISTINCT M.PK_Distributor
		 FROM #MBIDs M  
		 INNER JOIN dbo.v_DistributorHistory H 
			ON M.PK_Distributor = H.nDistributorIDFK 
			AND M.DSCurrentTeam IN ('G','M','P','A','B','C')
			AND TABQualDate >= @Month13							--Current team in 2023														   
		 INNER JOIN dbo.v_dimDSLifeCycle LC
			ON LC.LifeCycleCode BETWEEN 223 AND 224				-- SP (noteam) and WT
		 WHERE @Month12 BETWEEN H.dFrom  AND H.dThrough
	)
		
	 UPDATE A
	 SET A.Q01 = 1
	 FROM #EventQual A
	 INNER JOIN cte_NonTABs CNT
		ON A.PK_Distributor = CNT.PK_Distributor
	 WHERE Q01 = 0 AND Q02 = 0
			
			
	/***************************************************************************************************  
									UPDATE Q03, Q04 & Q05 
	****************************************************************************************************/
	UPDATE EQ
	SET  EQ.Q03 = CASE WHEN TotalVacationPoints > = @Points1 THEN 1 ELSE 0 END
		,EQ.Q04 = CASE WHEN TotalVacationPoints > = @Points2 THEN 1 ELSE 0 END
		,EQ.Q05 = CASE WHEN TotalVacationPoints > = @Points3 THEN 1 ELSE 0 END
	FROM #EventQual EQ
	INNER JOIN #MBIDs M
		ON EQ.PK_Distributor = M.PK_Distributor

	UPDATE EQ
	SET  EQ.Q07 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 52162

	UPDATE EQ
	SET  EQ.Q08 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 52163

	UPDATE EQ
	SET  EQ.Q09 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 52164

	-- Q10 - AWT 2023 	
	UPDATE EQ
	SET  EQ.Q10 = 1
	FROM #EventQual EQ
	INNER JOIN dbo.AWT A WITH (NOLOCK)
		ON EQ.PK_Distributor = A.PK_Distributor AND A.AWTYear = '2023' 

	UPDATE EQ
	SET  EQ.Q11 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 52165

	UPDATE EQ
	SET  EQ.Q12 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58721

	UPDATE EQ
	SET  EQ.Q13 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58722

	UPDATE EQ
	SET  EQ.Q14 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58723

	UPDATE EQ
	SET  EQ.Q15 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58724

	UPDATE EQ
	SET  EQ.Q16 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58725

	UPDATE EQ
	SET  EQ.Q17 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58726

	UPDATE EQ
	SET  EQ.Q18 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58727

	UPDATE EQ
	SET  EQ.Q19 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58728

	UPDATE EQ
	SET  EQ.Q20 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58729

	UPDATE EQ
	SET  EQ.Q21 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58730

	UPDATE EQ
	SET  EQ.Q22 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58731

	UPDATE EQ
	SET  EQ.Q23 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58732

	UPDATE EQ
	SET  EQ.Q24 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58733

	UPDATE EQ
	SET  EQ.Q25 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58734
		
	UPDATE EQ
	SET  EQ.Q26 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58735

	UPDATE EQ
	SET  EQ.Q27 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58736

	UPDATE EQ
	SET  EQ.Q28 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58737

	UPDATE EQ
	SET  EQ.Q29 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58738

	UPDATE EQ
	SET  EQ.Q30 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58739

	UPDATE EQ
	SET  EQ.Q31 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58740

	UPDATE EQ
	SET  EQ.Q32 = 1
	FROM #EventQual EQ
	INNER JOIN #LIST L
		ON EQ.PK_Distributor = L.PK_Distributor
	WHERE L.ListID = 58741


	/***************************************************************************************************  
			Q06:  Qualified to Project "24004 - TAB Team Vacation 2024" (PK ID 193219)
	****************************************************************************************************/
	 UPDATE EQ
	 SET EQ.Q06 = 1
	 FROM #EventQual EQ						   
	 INNER JOIN dbo.SubEventQualifier SEQ WITH (NOLOCK) 
		ON EQ.PK_Distributor = SEQ.PK_Distributor
		AND SEQ.PK_Event = @PK_TABVacation
		AND RemovedUTC = @ValidDate

  
/**********************************************************************************
							UPDATE EVENT FLAGS
**********************************************************************************/
	
	/****************************  UPDATE E3   *******************************/	
	UPDATE #EventQual
	SET	E03 = (((Q01 | Q02) & Q05 & ~Q06) | Q09)							-- ((Q1 OR Q2) + Q5 AND NOT IN Q6) OR Q9   												


	/****************************  UPDATE E2   *******************************/	
	UPDATE #EventQual
	SET	E02 = (((Q01 | Q02) & Q04 & ~Q06) | Q08) & ~E03					  -- ((Q1 OR Q2) + Q4 AND NOT IN Q6) OR Q8   
																			
 
	/****************************  UPDATE E1   *******************************/
	UPDATE #EventQual
	SET	E01 = (((Q01 | Q02) & Q03 & ~Q06) | Q07) & ~E03 & ~E02            -- ((Q1 OR Q2) + Q3 AND NOT IN Q6) OR Q7    
																			

	UPDATE #EventQual
	SET	 E04 = ( ((E01 | E02 | E03) & Q10) | Q11 )           -- ((E1 OR E2 OR E3) + Q10) OR Q11    
  
	DELETE FROM #EventQual
	WHERE ( 
			~Q01  & ~Q02 & ~Q03 & ~Q04 & ~Q05 & ~Q06  & ~Q07 & ~Q08 & ~Q09 & ~Q10 &
			~Q11  & ~Q12 & ~Q13 & ~Q14 & ~Q15 &	~Q16  & ~Q17 & ~Q18 & ~Q19 & ~Q20 &
			~Q21  & ~Q22 & ~Q23 & ~Q24 & ~Q25 &	~Q26  & ~Q27 & ~Q28 & ~Q29 & ~Q30 &
			~Q31  & ~Q32 & ~Q33 & ~Q34 & ~Q35 &	~Q36  & ~Q37 & ~Q38 & ~Q39 & ~Q40 &
			~Q41  & ~Q42 & ~Q43 & ~Q44 & ~Q45 &	~Q46  & ~Q47 & ~Q48 & ~Q49 & ~Q50 
			)= 1					  


	/***************************************************************************
						INSERT ON WORKTABLES
	***************************************************************************/

	/***************************  Event WorkTable from #MBIDs *************************/	
	IF OBJECT_ID('WRK_NAMGetaway_Vacation2024', 'U') IS NOT NULL 
		TRUNCATE TABLE dbo.WRK_NAMGetaway_Vacation2024
	ELSE
	 BEGIN
			 CREATE TABLE dbo.WRK_NAMGetaway_Vacation2024(
				 CreatedDateUTC			DATETIME	 NULL DEFAULT (GETUTCDATE())
				,CreatedBy				VARCHAR (50) NULL DEFAULT (REPLACE(SUSER_SNAME(),'HERBALIFECORP\','')) 
				,ModifiedDateUTC		DATETIME	 NULL DEFAULT (GETUTCDATE())
				,ModifiedBy				VARCHAR (50) NULL DEFAULT (REPLACE(SUSER_SNAME(),'HERBALIFECORP\','')) 
				,PK_Distributor	         INT
				,sDistributorID			 VARCHAR (20)	
				,DSCurrentTeam	         CHAR(5)
				,DSSubTeam	             CHAR(5)
				,DSSPTeam	             CHAR(5)
				,ApplicationDate		 DATETIME
				,SPQualDate	             DATETIME		
				,CountryCode             CHAR(2)
				,TAB2023				 BIT DEFAULT 0
				,TABQualDate			 DATETIME
				,TotalTVP				 MONEY DEFAULT 0
				,TotalRO 				 MONEY DEFAULT 0
				,TotalVacationPoints	 MONEY DEFAULT 0
			);

		 CREATE CLUSTERED INDEX IX_WRK_NAMGetaway_Vacation2024_PK_Distributor ON dbo.WRK_NAMGetaway_Vacation2024 (PK_Distributor)

	 END
	
	INSERT INTO dbo.WRK_NAMGetaway_Vacation2024
    (
         PK_Distributor	
		,sDistributorID
		,DSCurrentTeam	    
		,DSSubTeam	        
		,DSSPTeam	
		,ApplicationDate
		,SPQualDate	        
		,CountryCode        
		,TAB2023			
		,TABQualDate	
		,TotalTVP 
		,TotalRO  	
		,TotalVacationPoints
    )
    SELECT PK_Distributor	
		,sDistributorID
		,DSCurrentTeam	    
		,DSSubTeam	        
		,DSSPTeam
		,ApplicationDate
		,SPQualDate	        
		,CountryCode        
		,TAB2023			
		,TABQualDate	
		,TotalTVP 
		,TotalRO  			
		,TotalVacationPoints	 
    FROM #MBIDs     

	/***************************  EventQual WorkTable  *************************/	
	-- Table used to save on SubventQualifier
	IF OBJECT_ID('WRK_EventQual', 'U') IS NOT NULL 
		DELETE WEQ
			FROM [WRK_EventQual] AS WEQ 
			INNER JOIN #Events AS E
				ON WEQ.PK_Event = E.PK_Event

	INSERT INTO dbo.WRK_EventQual(PK_Event   ,            
		PK_Distributor ,            
		CreatedDate  ,            
		UpdatedDate  ,            
		Q01 , Q02 , Q03 , Q04 , Q05 ,            
		Q06 , Q07 , Q08 , Q09 , Q10 ,            
		Q11 , Q12 , Q13 , Q14 , Q15 ,            
		Q16 , Q17 , Q18 , Q19 , Q20 ,            
		Q21 , Q22 , Q23 , Q24 , Q25 ,            
		Q26 , Q27 , Q28 , Q29 , Q30 ,            
		Q31 , Q32 , Q33 , Q34 , Q35 ,            
		Q36 , Q37 , Q38 , Q39 , Q40 ,            
		Q41 , Q42 , Q43 , Q44 , Q45 ,            
		Q46 , Q47 , Q48 , Q49 , Q50 ,            
            
		E01 , E02 , E03 , E04 , E05 ,          
		E06 , E07 , E08 , E09 , E10 ,            
		E11 , E12 , E13 , E14 , E15 ,            
		E16 , E17 , E18 , E19 , E20 ,            
		E21 , E22 , E23 , E24 , E25 ,            
		E26 , E27 , E28 , E29 , E30 ,            
		E31 , E32 , E33 , E34 , E35 ,            
		E36 , E37 , E38 , E39 , E40 ,            
		E41 , E42 , E43 , E44 , E45 ,            
		E46 , E47 , E48 , E49 , E50   )  
	SELECT E.PK_Event   ,            
		PK_Distributor ,            
		CreatedDate  ,            
		UpdatedDate  ,            
		Q01 , Q02 , Q03 , Q04 , Q05 ,            
		Q06 , Q07 , Q08 , Q09 , Q10 ,            
		Q11 , Q12 , Q13 , Q14 , Q15 ,            
		Q16 , Q17 , Q18 , Q19 , Q20 ,            
		Q21 , Q22 , Q23 , Q24 , Q25 ,            
		Q26 , Q27 , Q28 , Q29 , Q30 ,            
		Q31 , Q32 , Q33 , Q34 , Q35 ,            
		Q36 , Q37 , Q38 , Q39 , Q40 ,            
		Q41 , Q42 , Q43 , Q44 , Q45 ,            
		Q46 , Q47 , Q48 , Q49 , Q50 ,                 
		CASE 
			WHEN E.PK_Event = 193114 THEN Q.Q27
			WHEN E.PK_Event = 193116 THEN Q.Q12
			WHEN E.PK_Event = 193118 THEN Q.Q15
			WHEN E.PK_Event = 193120 THEN Q.Q24
			WHEN E.PK_Event = 193122 THEN Q.Q21
			WHEN E.PK_Event = 193124 THEN Q.Q30
			WHEN E.PK_Event = 193126 THEN Q.Q18
			ELSE Q.E01
		END AS E01,
		CASE 
			WHEN E.PK_Event = 193114 THEN Q.Q28
			WHEN E.PK_Event = 193116 THEN Q.Q13
			WHEN E.PK_Event = 193118 THEN Q.Q16
			WHEN E.PK_Event = 193120 THEN Q.Q25
			WHEN E.PK_Event = 193122 THEN Q.Q22
			WHEN E.PK_Event = 193124 THEN Q.Q31
			WHEN E.PK_Event = 193126 THEN Q.Q19
			ELSE Q.E02
		END AS E02,
		CASE 
			WHEN E.PK_Event = 193114 THEN Q.Q29
			WHEN E.PK_Event = 193116 THEN Q.Q14
			WHEN E.PK_Event = 193118 THEN Q.Q17
			WHEN E.PK_Event = 193120 THEN Q.Q26
			WHEN E.PK_Event = 193122 THEN Q.Q23
			WHEN E.PK_Event = 193124 THEN Q.Q32
			WHEN E.PK_Event = 193126 THEN Q.Q20
			ELSE Q.E03
		END AS E03,
		CASE 
			WHEN E.PK_Event = 193114 THEN ((Q.Q27 | Q.Q28 | Q.Q29 & Q.Q10) | Q.Q11)
			WHEN E.PK_Event = 193116 THEN ((Q.Q12 | Q.Q13 | Q.Q14 & Q.Q10) | Q.Q11)
			WHEN E.PK_Event = 193118 THEN ((Q.Q15 | Q.Q16 | Q.Q17 & Q.Q10) | Q.Q11)
			WHEN E.PK_Event = 193120 THEN ((Q.Q24 | Q.Q25 | Q.Q26 & Q.Q10) | Q.Q11)
			WHEN E.PK_Event = 193122 THEN ((Q.Q21 | Q.Q22 | Q.Q23 & Q.Q10) | Q.Q11)
			WHEN E.PK_Event = 193124 THEN ((Q.Q30 | Q.Q31 | Q.Q32 & Q.Q10) | Q.Q11)
			WHEN E.PK_Event = 193126 THEN ((Q.Q18 | Q.Q19 | Q.Q20 & Q.Q10) | Q.Q11)
			ELSE Q.E04
		END AS E04, E05 ,            
		E06 , E07 , E08 , E09 , E10 ,            
		E11 , E12 , E13 , E14 , E15 ,            
		E16 , E17 , E18 , E19 , E20 ,            
		E21 , E22 , E23 , E24 , E25 ,            
		E26 , E27 , E28 , E29 , E30 ,            
		E31 , E32 , E33 , E34 , E35 ,            
		E36 , E37 , E38 , E39 , E40 ,            
		E41 , E42 , E43 , E44 , E45 ,            
		E46 , E47 , E48 , E49 , E50     
		FROM #EventQual  AS Q  
		CROSS APPLY (SELECT PK_Event FROM #Events) AS E

	DELETE D
	FROM [WRK_DSQual] AS D 
	INNER JOIN #Events AS E
		ON D.PK_Event = E.PK_Event

	INSERT INTO dbo.[WRK_DSQual]				
	(E.PK_Event   ,          
	 PK_Distributor ,          
	 CreatedDate  ,          
	 UpdatedDate  ,          
	 Q01 , Q02 , Q03 , Q04 , Q05 ,          
	 Q06 , Q07 , Q08 , Q09 , Q10 ,          
	 Q11 , Q12 , Q13 , Q14 , Q15 ,          
	 Q16 , Q17 , Q18 , Q19 , Q20 ,          
	 Q21 , Q22 , Q23 , Q24 , Q25 ,          
	 Q26 , Q27 , Q28 , Q29 , Q30 ,          
	 Q31 , Q32 , Q33 , Q34 , Q35 ,          
	 Q36 , Q37 , Q38 , Q39 , Q40 ,          
	 Q41 , Q42 , Q43 , Q44 , Q45 ,          
	 Q46 , Q47 , Q48 , Q49 , Q50 ,          
          
	 E01 , E02 , E03 , E04 , E05 ,          
	 E06 , E07 , E08 , E09 , E10 ,          
	 E11 , E12 , E13 , E14 , E15 ,          
	 E16 , E17 , E18 , E19 , E20 ,          
	 E21 , E22 , E23 , E24 , E25 ,          
	 E26 , E27 , E28 , E29 , E30 ,          
	 E31 , E32 , E33 , E34 , E35 ,          
	 E36 , E37 , E38 , E39 , E40 ,          
	 E41 , E42 , E43 , E44 , E45 ,          
	 E46 , E47 , E48 , E49 , E50   
	)
	SELECT
		 E.PK_Event   ,          
		 PK_Distributor ,          
		 CreatedDate  ,          
		 UpdatedDate  ,          
		 Q01 , Q02 , Q03 , Q04 , Q05 ,          
		 Q06 , Q07 , Q08 , Q09 , Q10 ,          
		 Q11 , Q12 , Q13 , Q14 , Q15 ,          
		 Q16 , Q17 , Q18 , Q19 , Q20 ,          
		 Q21 , Q22 , Q23 , Q24 , Q25 ,          
		 Q26 , Q27 , Q28 , Q29 , Q30 ,          
		 Q31 , Q32 , Q33 , Q34 , Q35 ,          
		 Q36 , Q37 , Q38 , Q39 , Q40 ,          
		 Q41 , Q42 , Q43 , Q44 , Q45 ,          
		 Q46 , Q47 , Q48 , Q49 , Q50 ,              
		CASE 
			WHEN E.PK_Event = 193114 THEN Q.Q27
			WHEN E.PK_Event = 193116 THEN Q.Q12
			WHEN E.PK_Event = 193118 THEN Q.Q15
			WHEN E.PK_Event = 193120 THEN Q.Q24
			WHEN E.PK_Event = 193122 THEN Q.Q21
			WHEN E.PK_Event = 193124 THEN Q.Q30
			WHEN E.PK_Event = 193126 THEN Q.Q18
			ELSE Q.E01
		END AS E01,
		CASE 
			WHEN E.PK_Event = 193114 THEN Q.Q28
			WHEN E.PK_Event = 193116 THEN Q.Q13
			WHEN E.PK_Event = 193118 THEN Q.Q16
			WHEN E.PK_Event = 193120 THEN Q.Q25
			WHEN E.PK_Event = 193122 THEN Q.Q22
			WHEN E.PK_Event = 193124 THEN Q.Q31
			WHEN E.PK_Event = 193126 THEN Q.Q19
			ELSE Q.E02
		END AS E02,
		CASE 
			WHEN E.PK_Event = 193114 THEN Q.Q29
			WHEN E.PK_Event = 193116 THEN Q.Q14
			WHEN E.PK_Event = 193118 THEN Q.Q17
			WHEN E.PK_Event = 193120 THEN Q.Q26
			WHEN E.PK_Event = 193122 THEN Q.Q23
			WHEN E.PK_Event = 193124 THEN Q.Q32
			WHEN E.PK_Event = 193126 THEN Q.Q20
			ELSE Q.E03
		END AS E03,
		CASE 
			WHEN E.PK_Event = 193114 THEN ((Q.Q27 | Q.Q28 | Q.Q29 & Q.Q10) | Q.Q11)
			WHEN E.PK_Event = 193116 THEN ((Q.Q12 | Q.Q13 | Q.Q14 & Q.Q10) | Q.Q11)
			WHEN E.PK_Event = 193118 THEN ((Q.Q15 | Q.Q16 | Q.Q17 & Q.Q10) | Q.Q11)
			WHEN E.PK_Event = 193120 THEN ((Q.Q24 | Q.Q25 | Q.Q26 & Q.Q10) | Q.Q11)
			WHEN E.PK_Event = 193122 THEN ((Q.Q21 | Q.Q22 | Q.Q23 & Q.Q10) | Q.Q11)
			WHEN E.PK_Event = 193124 THEN ((Q.Q30 | Q.Q31 | Q.Q32 & Q.Q10) | Q.Q11)
			WHEN E.PK_Event = 193126 THEN ((Q.Q18 | Q.Q19 | Q.Q20 & Q.Q10) | Q.Q11)
			ELSE Q.E04
		END AS E04, E05 ,         
		 E06 , E07 , E08 , E09 , E10 ,          
		 E11 , E12 , E13 , E14 , E15 ,          
		 E16 , E17 , E18 , E19 , E20 ,          
		 E21 , E22 , E23 , E24 , E25 ,          
		 E26 , E27 , E28 , E29 , E30 ,          
		 E31 , E32 , E33 , E34 , E35 ,          
		 E36 , E37 , E38 , E39 , E40 ,          
		 E41 , E42 , E43 , E44 , E45 ,          
		 E46 , E47 , E48 , E49 , E50			
	FROM #EventQual AS Q
	CROSS APPLY (SELECT PK_Event FROM #Events) AS E


	/******************************************************************************
					INSERT ON SubEventQualifier
	******************************************************************************/

	DECLARE @PK_Events NVARCHAR(MAX) = (SELECT STRING_AGG(PK_Event,',') FROM #Events)

	EXEC dbo.usp_UpdateSubEventQualifierByWRKTBL @Event = @PK_Events
		
	/******************************************************************************
		DROP THE TEMP TABLE BEFORE ENDING THE PROCEDURE
	******************************************************************************/
	IF OBJECT_ID('tempdb..#Events') IS NOT NULL DROP TABLE #Events
	IF OBJECT_ID('tempdb..#EventQual') IS NOT NULL DROP TABLE #EventQual												 
	IF OBJECT_ID('tempdb..#MBIDs') IS NOT NULL DROP TABLE #MBIDs								   																   
	IF OBJECT_ID('tempdb..#MBIDsPoints') IS NOT NULL DROP TABLE #MBIDsPoints
	IF OBJECT_ID('tempdb..#LIST')    IS NOT NULL DROP TABLE #LIST

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