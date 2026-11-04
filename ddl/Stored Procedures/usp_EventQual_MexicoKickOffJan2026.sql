CREATE PROCEDURE [dbo].[usp_EventQual_MexicoKickOffJan2026]
       -- Error Parameters
		 @Error	INT = NULL OUTPUT
		,@ErrorMessage VARCHAR(4000) = NULL OUTPUT

		-- QA/DEV
		,@IsDevQA TINYINT = 0
AS
BEGIN

/*********************************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_MexicoKickOffJan2026
	USE:		
				EXEC dbo.usp_EventQual_MexicoKickOffJan2026 
				@IsDevQA = 1
	DESCRIPTION:
	NOTES:		
	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1.0.0		2025-06-18	    puertac  		Initial 
	1.1.0		2025-07-07		juangue			BRD v1.1
	2.0.0		2025-08-05		juangue			BRD v2.0
	2.0.1		2025-08-11		juangue			#Bug 1423299 Downlines not recognized
	2.0.2		2025-08-13		juangue			Fix downlines issue
	2.0.3		2025-08-18		juangue			#1423847 Q20 not working as expected
	2.0.4		2025-08-20		juangue			#1423299 Downlines not recognized
	2.0.5		2025-08-25		juangue			Main and associates downlines addded
***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

DECLARE @PK_Event_TKR		INT = 203858,
		@PK_Event_GDL		INT = 203859,
		@PK_Event_CDMX		INT = 203860,
		@PK_Event_VER		INT = 203861,
		@PK_Event_ACP		INT = 203862,
		@PK_Event_TIJ		INT = 203863,
		@PK_Event_ZAC		INT = 203864,
		@PK_Event_MER		INT = 203865,
		@PK_Event_OAX		INT = 203866,
		@PK_Event_PUE		INT = 203868,
		@PK_Event_TOL		INT = 203869,
		@PK_Event_MTY		INT = 203870,
		@PK_Event_TEC		INT = 203871,
		@PK_Event_TXL		INT = 203872,
		@PK_Event_LEO		INT = 203873

DECLARE  @PK_MultipleEvents NVARCHAR(MAX) = NULL								  
		,@Month1 DATETIME  = '2025-09-01'
		,@Month2 DATETIME  = '2025-10-01'
		,@Month3 DATETIME  = '2025-11-01'
		,@Month4 DATETIME  = '2025-12-01'
		,@Month5 DATETIME  = '2026-01-01'
		,@TVP1 MONEY = 10000
		,@TVP2 MONEY = 20000
		,@TVP3 MONEY = 1500
		,@TVP4 MONEY = 2500
		,@TVP5 MONEY = 12000
		,@SubTypeFreezeDate  INT = 202509					  
									
	
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
	VALUES   (@PK_Event_TKR)
			,(@PK_Event_GDL)
			,(@PK_Event_CDMX)
			,(@PK_Event_VER)
			,(@PK_Event_ACP)
			,(@PK_Event_TIJ)
			,(@PK_Event_ZAC)
			,(@PK_Event_MER)
			,(@PK_Event_OAX)
			,(@PK_Event_PUE)
			,(@PK_Event_TOL)
			,(@PK_Event_MTY)
			,(@PK_Event_TEC)
			,(@PK_Event_TXL)
			,(@PK_Event_LEO)

	SELECT @PK_MultipleEvents = STRING_AGG(PK_Event, ',') FROM #Events
			   		
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
	VALUES (65928),(65929),(65930),(65931),(65932),(65943),(65944),(65945),(66158),(66159),(66160)

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

	CREATE TABLE #DSSKUs	(
		PK_Distributor INT
		,PK_EventSKU INT
		,PK_Event INT
		,SKUCode VARCHAR(10)
		,UniqueID NVARCHAR(MAX)
	)	
				
	DROP TABLE IF EXISTS #SKUs

	CREATE TABLE #SKUs	(
		ID INT IDENTITY(1,1),
		SKUCode VARCHAR(10),
		PK_Event INT
	)

	INSERT INTO #SKUs(PK_Event,SKUCode)
	SELECT DISTINCT s.PK_Event, s.SKUCode
	FROM [dbo].[EventSKU] AS s WITH (NOLOCK) 
	INNER JOIN #Events AS E
		ON E.PK_Event = s.PK_Event
	WHERE s.PK_EventSKUType = 1 AND s.IsEventTicketSKU = 1 


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
		,QSQualDate				DATETIME
		,CountryCode			CHAR(2)
		,IsTAB					BIT DEFAULT 0
		,IsFromTicket			BIT DEFAULT 0
		,IsAddedFromLists		BIT DEFAULT 0
		,IsNonTABFreeze			BIT DEFAULT 0
		,IsTABFreeze			BIT DEFAULT 0
	)

	INSERT INTO	#MBIDs (PK_Distributor,	DSCurrentTeam,DSSubTeam,DSSPTeam,ApplicationDate,SPQualDate,SPRequalDate,QSQualDate,CountryCode,IsTAB,IsFromTicket,IsAddedFromLists)
	SELECT DISTINCT
		D.nDistributorID AS PK_Distributor
		,CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam
		,D.sSubteam AS DSSubTeam
		,D.sType AS DSSPTeam
		,D.dApplication AS ApplicationDate 
		,D.dSupervisorqualification AS SPQualDate
		,D.dSupervisorReQualification AS SPRequalDate
		,D.dQSQualification AS QSQualDate
		,D.sDistributorCountryProcessingCode AS CountryCode	
		,IIF(D.sTeam IN ('G','M','P','A','B','C'), 1, 0) AS IsTAB
		,0 AS IsFromTicket
		,0 AS IsAddedFromLists
	FROM dbo.v_Distributor D 									
	WHERE (D.sType ='SP' OR D.sSubTeam IN ('QS', 'QS5', 'QV', 'PQS', 'SQS', '2QS', '5QS') )
	AND D.StatusCode = 'COMPLETE'   
	AND D.sDistributorCountryProcessingCode = 'MX'
	
	INSERT INTO	#MBIDs (PK_Distributor,	DSCurrentTeam,DSSubTeam,DSSPTeam,ApplicationDate,SPQualDate,SPRequalDate,QSQualDate,CountryCode,IsTAB,IsFromTicket,IsAddedFromLists)			
	SELECT DISTINCT
		 D.nDistributorID AS PK_Distributor
		,CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam
		,D.sSubteam AS DSSubTeam
		,D.sType AS DSSPTeam
		,D.dApplication AS ApplicationDate 
		,D.dSupervisorqualification AS SPQualDate
		,D.dSupervisorReQualification AS SPRequalDate
		,D.dQSQualification AS QSQualDate
		,D.sDistributorCountryProcessingCode AS CountryCode	
		,IIF(D.sTeam IN ('G','M','P','A','B','C'), 1, 0) AS IsTAB
		,0 AS IsFromTicket
		,0 AS IsAddedFromLists	
	FROM dbo.v_Distributor AS D  
	INNER JOIN #DSSKUs AS S
		ON D.nDistributorID = S.PK_Distributor
	WHERE NOT EXISTS (SELECT 1 FROM #MBIDs AS T WHERE T.PK_Distributor = S.PK_Distributor)

	INSERT INTO	#MBIDs (PK_Distributor,	DSCurrentTeam,DSSubTeam,DSSPTeam,ApplicationDate,SPQualDate,SPRequalDate,QSQualDate,CountryCode,IsTAB,IsFromTicket,IsAddedFromLists)-- Exception IDs from Lists 
	SELECT DISTINCT
		D.nDistributorID AS PK_Distributor
		,CASE WHEN D.sTeam IS NULL THEN CASE WHEN sType = 'DS' THEN sSubTeam ELSE 'SP' END ELSE D.sTeam END AS DSCurrentTeam
		,D.sSubteam AS DSSubTeam
		,D.sType AS DSSPTeam
		,D.dApplication AS ApplicationDate 
		,D.dSupervisorqualification AS SPQualDate
		,D.dSupervisorReQualification AS SPRequalDate
		,D.dQSQualification AS QSQualDate
		,D.sDistributorCountryProcessingCode AS CountryCode	
		,IIF(D.sTeam IN ('G','M','P','A','B','C'), 1, 0) AS IsTAB
		,0 AS IsFromTicket
		,1 AS IsAddedFromLists
	FROM #DSList L
	INNER JOIN  dbo.v_Distributor D 	
		ON L.PK_Distributor = D.nDistributorID
	WHERE NOT EXISTS (SELECT 1 FROM #MBIDs M WHERE M.PK_Distributor = L.PK_Distributor) 

	CREATE INDEX IX_#MBIDs_PK_Distributor ON #MBIDs(PK_Distributor)	

	UPDATE D
	SET 
		IsNonTABFreeze = IIF(S.PK_Distributor IS NOT NULL, 1, 0)
	FROM 
		#MBIDs D
	LEFT JOIN [PubEventManagement].[Shared].[DSSNAPSHOT] AS S WITH (NOLOCK)
		ON S.PK_DISTRIBUTOR = D.PK_Distributor
	WHERE S.RoyaltyMonth = @SubTypeFreezeDate
	AND S.TEAMCODE IN ('N','W')								
	AND S.StatusCode = 'COMPLETE'
	AND S.ISDS = 1

	UPDATE D
	SET 
		IsTABFreeze = IIF(S.PK_Distributor IS NOT NULL, 1, 0)
	FROM 
		#MBIDs D
	LEFT JOIN [PubEventManagement].[Shared].[DSSNAPSHOT] AS S WITH (NOLOCK)
		ON S.PK_DISTRIBUTOR = D.PK_Distributor
	WHERE S.RoyaltyMonth = @SubTypeFreezeDate
	AND S.TEAMCODE IN ('G','M','P')								
	AND S.StatusCode = 'COMPLETE'
	AND S.ISDS = 1

	INSERT INTO #EventQual(PK_Event, PK_Distributor, CreatedDate, UpdatedDate, Q01, Q02, Q03, Q04, Q12)		
	SELECT	A.PK_Event 
		   ,B.PK_Distributor 
		   ,GETUTCDATE() AS CreatedDate
		   ,GETUTCDATE() AS UpdatedDate
		   ,IIF((B.QSQualDate BETWEEN '2026-01-01' AND '2026-02-28' AND B.DSSubTeam = 'QS') OR B.DSSubTeam IN ('QS5', 'QV', 'PQS', 'SQS', '2QS', '5QS'), 1, 0)  AS Q01	
		   ,IIF(B.SPQualDate <= '2026-01-01', 1, 0)  AS Q02	
		   ,B.IsNonTABFreeze AS Q03
		   ,B.IsTABFreeze AS Q04
		   ,B.IsTAB AS Q12
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
		,PPV			MONEY DEFAULT 0
		,DLV			MONEY DEFAULT 0
		,PPV_DLV		MONEY DEFAULT 0
		,VPs			MONEY DEFAULT 0
		,SPQualDate		DATETIME
	)	

	INSERT INTO #MBIDsPoints(PK_Distributor, dRoyaltyMonth, TVP, RO, PPV, DLV, PPV_DLV, VPs, SPQualDate)		
	SELECT 	T.PK_Distributor,				   
			A.dRoyaltyMonth,
			A.mVolumePoints AS TVP,
			(A.mRoyaltyOverrides + A.mMainRoyaltyOverrides) AS RO,
			A.mPersonalPurchaseVolume AS PPV,			
			A.mDownLineVolume AS DLV,
			A.mPersonalPurchaseVolume + A.mDownLineVolume AS PPV_DLV,
			IIF(T.SPQualDate <= dRoyaltyMonth, A.mVolumePoints, A.mPersonalPurchaseVolume + A.mDownLineVolume) AS VPs,
			T.SPQualDate
	FROM #MBIDs T
	INNER JOIN dbo.v_aggFQS_ID A WITH (NOLOCK)
		ON 	T.PK_Distributor = A.nDistributorID
	AND A.dRoyaltyMonth BETWEEN @Month1 AND @Month4							--  Qual Period : Sep 2025 - Dec 2025
	ORDER BY PK_Distributor, dRoyaltyMonth
	
	CREATE INDEX IX_#MBIDsPoints_PK_Distributor ON #MBIDsPoints(PK_Distributor)
		

--------------------------------------------------------------------------------------------------------------------------------------
	-- Qualifications

	-- Q5 Accumulate 10,000 TVP from Sep 2025 - Dec 2025
		DROP TABLE IF EXISTS #AccumulatedQ05

		SELECT PK_Distributor, SUM(VPs) AS AccTVP, @Month1 AS FirstMonth, @Month4 AS LastMonth
		INTO #AccumulatedQ05																							 
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month4 GROUP BY PK_Distributor  
																																				  
		DROP TABLE IF EXISTS #Q05

		SELECT PK_Distributor, MIN(FirstMonth) AS FirstMonth, MIN(LastMonth) AS LastMonth
		INTO #Q05
		FROM #AccumulatedQ05
		WHERE AccTVP >= @TVP1
		GROUP BY PK_Distributor

		CREATE INDEX IX_#Q05_PK_Distributor ON #Q05(PK_Distributor)
			 
								  
	-- Q6 Accumulate 20,000 TVP from Sep 2025 to Dec 2025
		DROP TABLE IF EXISTS #AccumulatedQ06

		SELECT PK_Distributor, SUM(VPs) AS AccTVP, @Month1 AS FirstMonth, @Month4 AS LastMonth
		INTO #AccumulatedQ06																							 
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month4 GROUP BY PK_Distributor  

		DROP TABLE IF EXISTS #Q06

		SELECT PK_Distributor, MIN(FirstMonth) AS FirstMonth, MIN(LastMonth) AS LastMonth
		INTO #Q06
		FROM #AccumulatedQ06
		WHERE AccTVP >= @TVP2
		GROUP BY PK_Distributor

		CREATE INDEX IX_#Q06_PK_Distributor ON #Q06(PK_Distributor)

							   
	-- Q7 Achieve 1,500 TVP in each month from Sep 2025 - Dec 2025
		DROP TABLE IF EXISTS #AchievedMonthsQ07

		SELECT PK_Distributor, COUNT(VPs) AS TotalMonths
		INTO #AchievedMonthsQ07
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month4 AND VPs >= @TVP3 GROUP BY PK_Distributor
		
		
		DROP TABLE IF EXISTS #Q07

		SELECT DISTINCT PK_Distributor
		INTO #Q07
		FROM #AchievedMonthsQ07 WHERE TotalMonths = 4

		CREATE INDEX IX_#Q07_PK_Distributor ON #Q07(PK_Distributor)


	-- Q10 Achieve 2,500 TVP in each month from Sep 2025 - Dec 2025
		DROP TABLE IF EXISTS #AchievedMonthsQ10

		SELECT PK_Distributor, COUNT(VPs) AS TotalMonths
		INTO #AchievedMonthsQ10
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month4 AND VPs >= @TVP4 GROUP BY PK_Distributor
	
	
		DROP TABLE IF EXISTS #Q10	
		
		SELECT DISTINCT PK_Distributor
		INTO #Q10
		FROM #AchievedMonthsQ10 WHERE TotalMonths = 4
									
		CREATE INDEX IX_#Q10_PK_Distributor ON #Q10(PK_Distributor)
																			
  	-- Q20 Accumulate 12,000 TVP from Sep 2025 - Dec 2025
		DROP TABLE IF EXISTS #AccumulatedQ20

		SELECT PK_Distributor, SUM(VPs) AS AccTVP, @Month1 AS FirstMonth, @Month4 AS LastMonth
		INTO #AccumulatedQ20																							 
		FROM #MBIDsPoints WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month4 GROUP BY PK_Distributor  
																																				  
		DROP TABLE IF EXISTS #Q20

		SELECT PK_Distributor, MIN(FirstMonth) AS FirstMonth, MIN(LastMonth) AS LastMonth
		INTO #Q20
		FROM #AccumulatedQ20
		WHERE AccTVP >= @TVP5
		GROUP BY PK_Distributor

		CREATE INDEX IX_#Q20_PK_Distributor ON #Q20(PK_Distributor)

	-- Q29 Achieve 2,500 TVP in each month in 3 consecutive months from Sep 2025 - Dec 2025 (Sep 2025 - Nov 2025)
		DROP TABLE IF EXISTS #AchievedMonthsQ29

		SELECT PK_Distributor, COUNT(VPs) AS TotalMonths
		INTO #AchievedMonthsQ29
		FROM #MBIDsPoints 
		WHERE dRoyaltyMonth BETWEEN @Month1 AND @Month3 AND VPs >= @TVP4 
		GROUP BY PK_Distributor
	
		DROP TABLE IF EXISTS #Q29	
		
		SELECT DISTINCT PK_Distributor
		INTO #Q29
		FROM #AchievedMonthsQ29 WHERE TotalMonths = 3
									
		CREATE INDEX IX_#Q29_PK_Distributor ON #Q29(PK_Distributor)

	-- Q30 Achieve 2,500 TVP in each month in 3 consecutive months from Sep 2025 - Dec 2025 (Oct 2025 - Dec 2025)
		DROP TABLE IF EXISTS #AchievedMonthsQ30

		SELECT PK_Distributor, COUNT(VPs) AS TotalMonths
		INTO #AchievedMonthsQ30
		FROM #MBIDsPoints 
		WHERE dRoyaltyMonth BETWEEN @Month2 AND @Month4 AND VPs >= @TVP4 
		GROUP BY PK_Distributor
	
		DROP TABLE IF EXISTS #Q30	
		
		SELECT DISTINCT PK_Distributor
		INTO #Q30
		FROM #AchievedMonthsQ30 WHERE TotalMonths = 3
									
		CREATE INDEX IX_#Q30_PK_Distributor ON #Q30(PK_Distributor)

		-- Lists 
		UPDATE A
		SET  Q11 = ISNULL(L.[65928],0) 
			,Q13 = ISNULL(L.[65929],0)
			,Q14 = ISNULL(L.[65930],0) 
			,Q15 = ISNULL(L.[65931],0)
			,Q16 = ISNULL(L.[65932],0) 
			,Q17 = ISNULL(L.[65943],0) 
			,Q18 = ISNULL(L.[65944],0)
			,Q19 = ISNULL(L.[65945],0) 
			,Q23 = ISNULL(L.[66158],0) 
			,Q24 = ISNULL(L.[66159],0) 
			,Q25 = ISNULL(L.[66160],0) 
		FROM #EventQual A
		LEFT JOIN (
			SELECT  PK_Distributor, [65928],[65929],[65930],[65931],[65932],[65943],[65944],[65945],[66158],[66159],[66160]
			FROM (SELECT  PK_Distributor, ListID, CAST(PK_Distributor AS NVARCHAR(20))+ '-' + CAST(ListID AS NVARCHAR(20)) AS UniqueID	FROM #DSList) P
			PIVOT (COUNT (UniqueID)	FOR ListID IN ([65928],[65929],[65930],[65931],[65932],[65943],[65944],[65945],[66158],[66159],[66160])) AS pvt	
		) L
		ON A.PK_Distributor = L.PK_Distributor

	-- Downlines ------------------------------------------------------------------------------------------------------

		DROP TABLE IF EXISTS #DSDownlines

		SELECT 
			M.PK_Distributor PK_DSUpline,
			DL.PK_DSDownline
		INTO #DSDownlines
		FROM
			#MBIDs M
		INNER JOIN
			dbo.v_dimDSLngDownline DL WITH (NOLOCK)
		ON
			M.PK_Distributor = DL.PK_Distributor
			AND	DL.DSLevelFromUL = 2

		CREATE CLUSTERED INDEX [IX_#DSDownlines_PK_DSDownline] ON  dbo.[#DSDownlines] ([PK_DSDownline])

		DROP TABLE IF EXISTS #DSAssociatedDownlines

		SELECT DISTINCT
				DA.PK_Distributor PK_DSUpline,
				DA.PK_AssociatedID,
				DL.PK_DSDownLine,
				DA.nMainDistributorID,
				DA.AssociationType
		INTO #DSAssociatedDownlines
		FROM #MBIDs AS D --Uplines from COP
		INNER JOIN [Shared].[DistributorAssociation] AS DA WITH (NOLOCK)
			ON D.PK_Distributor = DA.PK_Distributor
		INNER JOIN dbo.v_dimDSLngDownline AS DL
			ON DA.PK_AssociatedID = DL.PK_Distributor
		WHERE DL.DSLevelFromUL = 2
		AND DA.PK_AssociatedID = DA.nMainDistributorID -- When the Individual Distributorship achieves additional contributor, only the Indiviudal Distributorship will gain the new contributor																

		CREATE CLUSTERED INDEX [IX_#DSAssociatedDownlines_PK_DSUpline] ON  dbo.[#DSAssociatedDownlines] ([PK_DSUpline])

		DROP TABLE IF EXISTS #WRK_26012_1LDownlines

		CREATE TABLE #WRK_26012_1LDownlines
		(
			PK_DSUpline			INT,   
			[PK_DSDownline]		INT,
			QualDate			DATETIME,
			PK_AssociatedID		INT,
			nMainDistributorID	INT,
			AssociationType		INT
		)

		INSERT INTO #WRK_26012_1LDownlines(PK_DSUpline,[PK_DSDownline],QualDate)
		SELECT DISTINCT
			D.PK_DSUpline,
			D.[PK_DSDownline],
			F.dSupervisorQualification
		FROM #DSDownlines AS D
		INNER JOIN v_Distributor AS F
			ON F.nDistributorID = D.PK_DSDownline
			AND F.StatusCode = 'COMPLETE'
			AND F.sDistributorCountryProcessingCode = 'MX'					
						
		INSERT INTO #WRK_26012_1LDownlines(PK_DSUpline,[PK_DSDownline],QualDate,PK_AssociatedID,nMainDistributorID,AssociationType)
			SELECT DISTINCT
				PK_DSUpline,
				[PK_DSDownline],
				F.dSupervisorQualification,
				PK_AssociatedID,
				nMainDistributorID,
				AssociationType
			FROM #DSAssociatedDownlines AS A
			INNER JOIN v_Distributor AS F
			ON F.nDistributorID = A.PK_DSDownline
				AND F.StatusCode = 'COMPLETE'
				AND F.sDistributorCountryProcessingCode = 'MX'	
		WHERE NOT EXISTS (SELECT 1 FROM #WRK_26012_1LDownlines (NOLOCK) AS S WHERE A.PK_DSUpline = S.PK_DSUpline AND A.PK_DSDownline = S.PK_DSDownline)

		CREATE CLUSTERED INDEX [IX_#WRK_26012_1LDownlines_PK_FirstLine] ON  #WRK_26012_1LDownlines (PK_DSDownline)

		DROP TABLE IF EXISTS #NewNonTABSPDownlines
							   
		SELECT M.PK_Distributor, V.PK_DSDownline,V.QualDate
		INTO #NewNonTABSPDownlines
		FROM #MBIDs AS M WITH (NOLOCK)
		INNER JOIN #WRK_26012_1LDownlines AS V WITH (NOLOCK)
			ON M.PK_Distributor = V.PK_DSUpline
			AND M.IsNonTABFreeze = 1
		WHERE 
			EXISTS (SELECT 1 FROM #Q29 WHERE PK_Distributor = V.PK_DSDownline)
			OR
			EXISTS (SELECT 1 FROM #Q30 WHERE PK_Distributor = V.PK_DSDownline)


		CREATE INDEX IX_#NewNonTABSPDownlines_PK_Distributor ON #NewNonTABSPDownlines(PK_Distributor)	

		DROP TABLE IF EXISTS #NewTABSPDownlines

		SELECT M.PK_Distributor, V.PK_DSDownline, V.QualDate
		INTO #NewTABSPDownlines
		FROM #MBIDs AS M WITH (NOLOCK)
		INNER JOIN #WRK_26012_1LDownlines AS V WITH (NOLOCK)
			ON M.PK_Distributor = V.PK_DSUpline
			AND M.IsTABFreeze = 1
		WHERE 
			(
				EXISTS (SELECT 1 FROM #Q29 WHERE PK_Distributor = V.PK_DSDownline)
				OR 
				EXISTS (SELECT 1 FROM #Q30 WHERE PK_Distributor = V.PK_DSDownline)
			)
			OR 
			(
				EXISTS (SELECT 1 FROM #EventQual WHERE PK_Distributor = M.PK_Distributor AND Q11 = 1)
				AND
				(
					EXISTS (SELECT 1 FROM #Q29 WHERE PK_Distributor = V.PK_DSDownline)
					OR 
					EXISTS (SELECT 1 FROM #Q30 WHERE PK_Distributor = V.PK_DSDownline)
				)
			)

		CREATE INDEX IX_#NewTABSPDownlines_PK_Distributor ON #NewTABSPDownlines(PK_Distributor)		

		DROP TABLE IF EXISTS #NewNonTABSPCount

		SELECT PK_Distributor, COUNT(PK_DSDownline) AS DownlineCount
		INTO #NewNonTABSPCount
		FROM #NewNonTABSPDownlines
		GROUP BY PK_Distributor
									
		CREATE INDEX IX_#NewNonTABSPCount_PK_Distributor ON #NewNonTABSPCount(PK_Distributor)	
	

		DROP TABLE IF EXISTS #NewTABSPCount

		SELECT PK_Distributor, COUNT(PK_DSDownline) AS DownlineCount
		INTO #NewTABSPCount
		FROM #NewTABSPDownlines
		GROUP BY PK_Distributor
									
		CREATE INDEX IX_#NewTABSPCount_PK_Distributor ON #NewTABSPCount(PK_Distributor)	
		
  
		-- Q21 Personally Sponsor One (1) Active Supervisors downline within the qual period 
		DROP TABLE IF EXISTS #Q21

		SELECT DISTINCT PK_Distributor								   
		INTO #Q21
		FROM #NewNonTABSPCount
		GROUP BY PK_Distributor

		CREATE INDEX IX_#Q21_PK_Distributor ON #Q21(PK_Distributor)	


		-- Q22 Personally Sponsor TWO (2) Active Supervisors downline within the qual period
		DROP TABLE IF EXISTS #Q22

		SELECT PK_Distributor
		INTO #Q22
		FROM #NewTABSPCount
		WHERE DownlineCount >= 2

		CREATE INDEX IX_#Q22_PK_Distributor ON #Q22(PK_Distributor)		
		
	UPDATE Q
	SET  Q05 = IIF(Q05.PK_Distributor IS NOT NULL, 1, 0) 
		,Q06 = IIF(Q06.PK_Distributor IS NOT NULL, 1, 0) 
		,Q07 = IIF(Q07.PK_Distributor IS NOT NULL, 1, 0)
		,Q10 = IIF(Q10.PK_Distributor IS NOT NULL, 1, 0)
		,Q20 = IIF(Q20.PK_Distributor IS NOT NULL, 1, 0)		
		,Q21 = IIF(Q21.PK_Distributor IS NOT NULL, 1, 0)	
		,Q22 = IIF(Q22.PK_Distributor IS NOT NULL, 1, 0)			
	FROM #EventQual AS Q
	LEFT JOIN #Q05 AS Q05
		ON Q.PK_Distributor = Q05.PK_Distributor						  
	LEFT JOIN #Q06 AS Q06
		ON Q.PK_Distributor = Q06.PK_Distributor						  
	LEFT JOIN #Q07 AS Q07
		ON Q.PK_Distributor = Q07.PK_Distributor					  
	LEFT JOIN #Q10 AS Q10
		ON Q.PK_Distributor = Q10.PK_Distributor
	LEFT JOIN #Q20 AS Q20
		ON Q.PK_Distributor = Q20.PK_Distributor
	LEFT JOIN #Q21 AS Q21
		ON Q.PK_Distributor = Q21.PK_Distributor
	LEFT JOIN #Q22 AS Q22
		ON Q.PK_Distributor = Q22.PK_Distributor	


	-- UPDATE SubEvents
	UPDATE #EventQual
	SET	 E01 =	(Q01 | Q02) | Q13													-- (Q1 OR Q2) OR Q13
		,E03 =	(Q03 & Q10 & Q20 & Q21) | ((Q04 | Q11) & Q06 & Q10 & Q22) | Q15		-- ((Q3 + Q5 Q10 + Q7 Q20 + Q8 Q21) OR  ((Q4 OR Q11) + Q6 + Q10 + Q9 Q22) OR Q15)
		,E04 =	Q12 | Q16															-- Q12 OR Q16
		,E05 =  Q17																	-- Q17
		,E06 =  Q18																	-- Q18
		,E07 =  Q19																	-- Q19
		,E08 =  Q23																	-- Q23
		,E09 =  Q24																	-- Q24
		,E10 =  Q25																	-- Q25

		
	UPDATE #EventQual
	SET	 E02 =	( ((Q01 | Q02 | Q13) & Q05 & Q07) | Q14 ) & ~E03				-- ((Q1 OR Q2 OR Q13) + Q5 + Q7) OR Q14      If DS qualifies to more than 1 level, show him qualified only to the highest one achieved (with VIP being the highest and Preferential the lowest)
		,E40 =	E01 															-- E1

																						  
	DELETE FROM #EventQual
	WHERE ( 
			~Q01  & ~Q02 & ~Q03 & ~Q04 & ~Q05 & ~Q06  & ~Q07 & ~Q08 & ~Q09 & ~Q10 &
			~Q11  & ~Q12 & ~Q13 & ~Q14 & ~Q15 &	~Q16  & ~Q17 & ~Q18 & ~Q19 & ~Q20 &
			~Q21  & ~Q22 & ~Q23 & ~Q24 & ~Q25 &	~Q26  & ~Q27 & ~Q28 & ~Q29 & ~Q30 &
			~Q31  & ~Q32 & ~Q33 & ~Q34 & ~Q35 &	~Q36  & ~Q37 & ~Q38 & ~Q39 & ~Q40 &
			~Q41  & ~Q42 & ~Q43 & ~Q44 & ~Q45 &	~Q46  & ~Q47 & ~Q48 & ~Q49 & ~Q50 
			)= 1				  


	--WRK tables
	DROP INDEX IF EXISTS [IX_WRK_MexicoKickOffJan2026_PK_Distributor] ON [dbo].[WRK_MexicoKickOffJan2026];

	DROP TABLE IF EXISTS dbo.WRK_MexicoKickOffJan2026

	CREATE TABLE dbo.WRK_MexicoKickOffJan2026(
		 PK_Distributor			INT
		,IsTAB					BIT DEFAULT 0
		,IsFromTicket			BIT DEFAULT 0
		,IsAddedFromLists		BIT DEFAULT 0
		,IsNonTABFreeze			BIT DEFAULT 0
		,IsTABFreeze			BIT DEFAULT 0
	)
		
	INSERT INTO dbo.WRK_MexicoKickOffJan2026(PK_Distributor, IsTAB, IsFromTicket, IsAddedFromLists, IsNonTABFreeze, IsTABFreeze)	
	SELECT PK_Distributor, IsTAB, IsFromTicket, IsAddedFromLists, IsNonTABFreeze, IsTABFreeze			  
	FROM #MBIDs
		
	CREATE CLUSTERED INDEX [IX_WRK_MexicoKickOffJan2026_PK_Distributor] ON [dbo].[WRK_MexicoKickOffJan2026] ([PK_Distributor])

	
	DROP INDEX IF EXISTS [IX_WRK_MexicoKickOffJan2026_Points_PK_Distributor] ON [dbo].[WRK_MexicoKickOffJan2026_Points];

	DROP TABLE IF EXISTS dbo.WRK_MexicoKickOffJan2026_Points

	CREATE TABLE dbo.WRK_MexicoKickOffJan2026_Points(
		  PK_Distributor	INT
		 ,RoyaltyMonth		DATETIME
		 ,VPs				MONEY
	)
		
	INSERT INTO dbo.WRK_MexicoKickOffJan2026_Points(PK_Distributor, RoyaltyMonth, VPs)
	SELECT PK_Distributor, dRoyaltyMonth, VPs				  
	FROM #MBIDsPoints
		
	CREATE CLUSTERED INDEX [IX_WRK_MexicoKickOffJan2026_Points_PK_Distributor] ON [dbo].[WRK_MexicoKickOffJan2026_Points] ([PK_Distributor])

	DROP INDEX IF EXISTS [IX_WRK_MexicoKickOffJan2026_Downlines_PK_Distributor] ON [dbo].[WRK_MexicoKickOffJan2026_Downlines];

	DROP TABLE IF EXISTS dbo.WRK_MexicoKickOffJan2026_Downlines

	CREATE TABLE dbo.WRK_MexicoKickOffJan2026_Downlines(
		  PK_Distributor	INT
		 ,PK_DSDownline		INT
		 ,QualDate			DATETIME
	)

	INSERT INTO dbo.WRK_MexicoKickOffJan2026_Downlines(PK_Distributor, PK_DSDownline, QualDate)
	SELECT PK_Distributor, PK_DSDownline, QualDate
	FROM #NewNonTABSPDownlines
	UNION
	SELECT PK_Distributor, PK_DSDownline, QualDate
	FROM #NewTABSPDownlines

	CREATE CLUSTERED INDEX [IX_WRK_MexicoKickOffJan2026_Downlines_PK_Distributor] ON [dbo].[WRK_MexicoKickOffJan2026_Downlines] ([PK_Distributor])

-------------------------------------------------------------------------------------------------------------
	-- WorkTables
	
	-- Insert into WRK_DSQual or Custom WorkTable as needed
	DELETE dbo.WRK_DSQual WHERE PK_Event IN (@PK_Event_TKR, @PK_Event_GDL, @PK_Event_CDMX, @PK_Event_VER, @PK_Event_ACP, @PK_Event_TIJ, @PK_Event_ZAC, @PK_Event_MER
		 ,@PK_Event_OAX, @PK_Event_PUE, @PK_Event_TOL, @PK_Event_MTY, @PK_Event_TEC, @PK_Event_TXL, @PK_Event_LEO)											 

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
                        
						
	DELETE dq			
	FROM [Event].[DSQual] AS dq
	WHERE PK_Event IN (@PK_Event_TKR, @PK_Event_GDL, @PK_Event_CDMX, @PK_Event_VER, @PK_Event_ACP, @PK_Event_TIJ, @PK_Event_ZAC, @PK_Event_MER
		 ,@PK_Event_OAX, @PK_Event_PUE, @PK_Event_TOL, @PK_Event_MTY, @PK_Event_TEC, @PK_Event_TXL, @PK_Event_LEO)

	DROP INDEX IF EXISTS [IX_Event_DSQual_PK_Distributor_PK_Event]	ON [Event].[DSQual];

	INSERT INTO [Event].[DSQual] (PK_Event					
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
		  ,E41, E42, E43, E44, E45, E46, E47, E48, E49, E50	)      
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

	CREATE INDEX [IX_Event_DSQual_PK_Distributor_PK_Event] ON [Event].[DSQual](PK_Distributor) INCLUDE(PK_Event);

-------------------------------------------------------------------------------------------------------------
	-- 	INSERT ON SubEventQualifier																				

	EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
		@Events = @PK_MultipleEvents,
		@Source = 2,
		@EvaluateFormula = 0
  

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