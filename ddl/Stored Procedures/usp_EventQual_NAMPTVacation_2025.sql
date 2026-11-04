CREATE PROCEDURE [dbo].[usp_EventQual_NAMPTVacation_2025]
	   @PK_Event	 INT = 198704,
       @IsDevQA		 INT = 0,   
	   @Error		 INT = 0 OUTPUT,
	   @ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN

/*********************************************************************************************************************
	OBJECT:		dbo.usp_EventQual_NAMPTVacation_2025
		
	USE:			
			DECLARE @e int, @em varchar(max)
			
			EXEC dbo.usp_EventQual_NAMPTVacation_2025 
				
				@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 0

			SELECT @e AS [Error], @em AS [Error Message]
	NOTES:		

	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	SQL SERVER 2010
	
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1			2024-01-19   JuanGue  		Initial
	1.0.1		2024-02-01   JuanGue  		Fixing the bug #1323340
	1.0.2		2024-02-13   JuanGue		New DS and New SP Bonuses rules changes
	1.0.3		2024-02-19   JuanGue		Fixing issues
	1.0.4		2024-02-23	 JuanGue		Points per month due to CustomTracker requirement
	1.0.5		2024-02-26	 JuanGue		Adding the WRK_NAMLDWFSL_Apr2024_BonusJanToDec to get the valid DS with bonus
	2			2024-04-12	 JuanGue		BRD v2
	2.0.1		2024-04-19	 JuanGue		Bug fix #1337791
	2.0.2		2024-04-19	 JuanGue		Removing Code Smells marked by SonarQube
	2.0.3		2024-04-24	 JuanGue		Changing the ASP Recognition months for the right ones Jun 2024 - Jan 2025
	2.0.4		2024-05-14	 JuanGue		Bug fix #1341095 - The Downlines with conversion date out of the lastest ones were not contribuiting to uplines.
	2.0.5		2024-06-11	 JuanGue		Removing code smells "List the columns to be set in this "INSERT" statement"
	2.0.6		2024-06-20	 JuanGue		BugFix #1350249 Some downlines points were not counting
												   #1350346 PM Bonus Downline Empty
	2.0.7		2024-06-24	 JuanGue		#1350249 #1350346 Wrong amount of downlines fix
	3.0.0		2024-07-04	 JuanGue		BRD V3
	3.0.1		2024-07-15	 JuanGue		Change of ASP double march bonus to June, due to recognition month
	3.0.2		2024-08-08	 JuanGue		Remove restriction of day 1st each month to change the DS status
	5.0.0		2024-09-25	 JuanGue		BRD V5 Double March Bonus SPQualDate change to 202404 intead of 202403
	5.0.1		2024-10-18	 JuanGue		+ C.[New PM Bonus] + [Double March Bonus] added to the Q4
	6.0.0		2024-11-05	 JuanGue		#1382447 BRD V6 and getting the right PM_PPV and DS_PPV
	6.0.1		2024-11-06	 JuanGue		@KeepNegativeVolume = 0 to remove all negative values
	6.0.2		2024-11-22	 JuanGue		New list added 
	6.0.3		2024-11-22	 JuanGue		More PTs to consider
	6.0.4		2024-11-22	 JuanGue		Remove the active = 1 condition in the ASP and FQS
	6.0.5		2024-11-23	 JuanGue		Including tables to overwrite contributors
	6.0.6		2024-11-28	 alejandramed	Including option to remove contributors
	6.0.7		2024-11-29	 alejandramed	Removing double bonus duplication
***********************************************************************************************************************************/
/***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

	DECLARE	
		 @Month1  DATETIME = '2024-01-01'				
	    ,@Month2  DATETIME = '2024-02-01'				
	    ,@Month3  DATETIME = '2024-03-01'				
	    ,@Month4  DATETIME = '2024-04-01'				
	    ,@Month5  DATETIME = '2024-05-01'				
		,@Month6  DATETIME = '2024-06-01'				
	    ,@Month7  DATETIME = '2024-07-01'				
	    ,@Month8  DATETIME = '2024-08-01'				
	    ,@Month9  DATETIME = '2024-09-01'				
		,@Month10 DATETIME = '2024-10-01'				
	    ,@Month11 DATETIME = '2024-11-01'	
		,@Month12 DATETIME = '2024-12-01'

	SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY	

/*****************************************************************  
		Drop Temporary tables in case they already exist
******************************************************************/
IF OBJECT_ID('tempdb..#EventQual')		IS NOT NULL DROP TABLE #EventQual												 							   																   
IF OBJECT_ID('tempDB..#MBIDs')			IS NOT NULL DROP TABLE #MBIDs																  
IF OBJECT_ID('tempdb..#MBIDsPoints')	IS NOT NULL DROP TABLE #MBIDsPoints

DROP TABLE IF EXISTS [dbo].[##WRK_25006_NewASPBonusContributors] 
DROP TABLE IF EXISTS [dbo].[##WRK_25006_NewFQSBonusContributors] 

CREATE TABLE #EventQual
(
	PK_Event 		INT,
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

DROP TABLE IF EXISTS	#wrk_T1 

CREATE TABLE #wrk_T1  
(
	PK_Distributor	INT
) 

INSERT INTO #wrk_T1(PK_Distributor)   
SELECT DISTINCT nMainDistributorID  
FROM [Shared].[DistributorAssociation]  WITH (NOLOCK)	
WHERE	AssociationType = 3 

CREATE INDEX IX_#wrk_T1_PK_Distributor ON #wrk_T1(PK_Distributor)

DROP TABLE IF EXISTS	#MBIDs

	CREATE TABLE #MBIDs
	(
		 PK_Distributor			INT
		,DistributorID			VARCHAR (20)
		,sMainDistributorID		VARCHAR(15)											   
		,CurrentTeam			CHAR(5)
		,SubTeam				CHAR(5)
		,DSPTeam				CHAR(5)
		,sCountryCode			CHAR(3)
		,QSQualDate				DATETIME
		,SPQualDate				DATETIME
		,HasTicket				BIT DEFAULT 0
		,IsNewPT				BIT DEFAULT 0
		,IsFromList				BIT DEFAULT 0
		,PTQualDate				DATETIME
		
		,TVPJan24	            MONEY DEFAULT 0
		,TVPFeb24	            MONEY DEFAULT 0
		,TVPMar24	            MONEY DEFAULT 0
		,TVPApr24	            MONEY DEFAULT 0
		,TVPMay24	            MONEY DEFAULT 0
		,TVPJun24	            MONEY DEFAULT 0
		,TVPJul24	            MONEY DEFAULT 0
		,TVPAug24	            MONEY DEFAULT 0
		,TVPSep24	            MONEY DEFAULT 0
		,TVPOct24	            MONEY DEFAULT 0
		,TVPNov24	            MONEY DEFAULT 0
		,TVPDec24	            MONEY DEFAULT 0
		,ROJan24	            MONEY DEFAULT 0
		,ROFeb24	            MONEY DEFAULT 0
		,ROMar24	            MONEY DEFAULT 0
		,ROApr24	            MONEY DEFAULT 0
		,ROMay24	            MONEY DEFAULT 0
		,ROJun24	            MONEY DEFAULT 0
		,ROJul24	            MONEY DEFAULT 0
		,ROAug24	            MONEY DEFAULT 0
		,ROSep24	            MONEY DEFAULT 0
		,ROOct24	            MONEY DEFAULT 0
		,RONov24	            MONEY DEFAULT 0
		,RODec24	            MONEY DEFAULT 0

		,TotalTVP		AS	    (TVPJan24 + TVPFeb24 + TVPMar24 + TVPApr24 + TVPMay24 + TVPJun24 + TVPJul24 + TVPAug24 + TVPSep24 + TVPOct24 + TVPNov24 + TVPDec24)
		,TotalRO		AS		(ROJan24 + ROFeb24 + ROMar24 + ROApr24 + ROMay24 + ROJun24 + ROJul24 + ROAug24 + ROSep24 + ROOct24 + RONov24 + RODec24)

		,[New DS Bonus]			MONEY DEFAULT 0.00
		,[New SP Bonus]			MONEY DEFAULT 0.00
		,[New ASP Bonus]		MONEY DEFAULT 0.00
		,[New PM Bonus]			MONEY DEFAULT 0.00
		,[Double March Bonus]	MONEY DEFAULT 0.00
	)

	 CREATE TABLE #MBIDsPoints
	(
		 PK_Distributor				INT
		 ,dRoyaltyMonth				SMALLDATETIME
		 ,TVP						MONEY
		 ,RO						MONEY		   
	)	

	/******************************************************************************
		Create temp Lists
	******************************************************************************/
	DROP TABLE IF EXISTS #List

	CREATE TABLE #List
	(
		 PK_Distributor	INT
		,DistributorID	VARCHAR(20)
		,nTypeLID		INT
	)	
	INSERT
		#List
	(
		PK_Distributor
		,DistributorID
		,nTypeLID
	)
	SELECT 
		D.nDistributorID,
		D.DistributorID,
		D.nTypeLID
	FROM
		dbo.v_DistributorSet D
	WHERE
		nTypeLID IN (62181,62431)
	AND
		dThrough = '2049-12-31'	


/* INSERT ALL THE QUALIFIERS TO THE TEAM TABLE THAT WAS CREATED ABOVE */
INSERT
	#MBIDs
(
	PK_Distributor
	,DistributorID							   
	,CurrentTeam
	,SubTeam	
	,SPQualDate
	,QSQualDate
	,sCountryCode
	,IsFromList
)
SELECT 
	D.nDistributorID,
	D.sDistributorID,
	CASE WHEN D.sTeam IS NULL AND sType = 'SP' THEN 'SP' ELSE D.sTeam END,
	sSubTeam,
	D.dSupervisorqualification,
	D.dQSQualification,
	sDistributorCountryProcessingCode,
	0 IsFromList
FROM
	dbo.v_Distributor D (NOLOCK)
WHERE
	D.StatusCode = 'COMPLETE'
	AND 
	D.sDistributorCountryProcessingCode IN ('US','PR','JM','CA','TT')
	AND
	D.sType = 'SP' 
	AND D.sTeam IN ('P','A','B','C')

INSERT
	#MBIDs
(
	 PK_Distributor
	,DistributorID
	,CurrentTeam
	,SPQualDate
	,QSQualDate
	,SCountryCode
	,SubTeam
	,HasTicket
)
SELECT
	D.nDistributorID,
	D.sDistributorID,
	CASE WHEN D.sTeam IS NULL AND sType = 'SP' THEN 'SP' ELSE D.sTeam END, 
	D.dSupervisorqualification,
	D.dQSQualification,
	sDistributorCountryProcessingCode,
	sSubTeam,
	1 HasTicket
FROM
	dbo.SKUPurchased SKU WITH (NOLOCK)
INNER JOIN
	dbo.v_Distributor D
ON
	SKU.PK_Distributor_Purchaser = D.nDistributorID
WHERE
	D.StatusCode = 'COMPLETE'
	AND 
	SKU.PK_Event = @PK_Event
AND NOT EXISTS (SELECT 1 FROM #MBIDs AS m WHERE D.nDistributorID = m.PK_Distributor)

UPDATE M 
SET M.HasTicket = 1
FROM #MBIDs M
INNER JOIN 	dbo.SKUPurchased SKU WITH (NOLOCK)
ON
	SKU.PK_Distributor_Purchaser = M.PK_Distributor
AND
	SKU.PK_Event = @PK_Event


INSERT
	#MBIDs
(
	 PK_Distributor
	,DistributorID
	,CurrentTeam
	,SPQualDate
	,QSQualDate
	,SCountryCode
	,SubTeam
	,HasTicket
)
SELECT   
	D.nDistributorID,
	D.sDistributorID,
	CASE WHEN D.sTeam IS NULL AND sType = 'SP' THEN 'SP' ELSE D.sTeam END,
	sSubTeam,
	D.dSupervisorqualification,
	D.dQSQualification,
	sDistributorCountryProcessingCode,
	1 IsFromList
FROM	#List	B
INNER JOIN
		dbo.v_Distributor D
ON
	B.PK_Distributor = D.nDistributorID
	AND 
	NOT EXISTS (SELECT 1 FROM #MBIDs WHERE PK_Distributor = B.PK_Distributor)

UPDATE M 
SET M.IsFromList = 1
FROM #MBIDs M
INNER JOIN #List L ON M.PK_Distributor = L.PK_Distributor

CREATE INDEX IX_#MBIDs_PK_Distributor ON #MBIDs(PK_Distributor)   


/*****************************************************************************************  
	  Get the Points achieved by each distributor in #MBIDs on certain period of time
******************************************************************************************/																				 
INSERT INTO #MBIDsPoints(
	 PK_Distributor
	 ,dRoyaltyMonth
	 ,TVP				
	 ,RO				
)
SELECT  T.PK_Distributor
	,D.dRoyaltyMonth
	,SUM(ISNULL(D.mVolumePoints,0))
	,SUM(ISNULL(D.mRoyaltyOverrides,0)) + SUM(ISNULL(D.mMainRoyaltyOverrides,0))
FROM #MBIDs T
INNER JOIN dbo.v_aggFQS_ID D WITH (NOLOCK)
	ON 	T.PK_Distributor = D.nDistributorID
AND D.dRoyaltyMonth BETWEEN '2024-01-01' AND '2024-12-01'
GROUP BY	
	T.PK_Distributor,D.dRoyaltyMonth

CREATE INDEX IX_#MBIDsPoints_PK_Distributor ON #MBIDsPoints(PK_Distributor)

/******************************************************************************
	UPDATE HasTicket
******************************************************************************/

UPDATE
	T
SET
	T.HasTicket = 1
FROM
	#MBIDs T
INNER JOIN
	dbo.SKUPurchased S WITH (NOLOCK)
ON 
	T.PK_Distributor = S.PK_Distributor_Purchaser
	AND	
	S.PK_Event = @PK_Event

/***************************************************  
	  Update Points Columns on #MBIDs
****************************************************/

UPDATE
	T
SET	 T.TVPJan24	 = ISNULL((SELECT A.TVP FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month1 ),0)
	,T.TVPFeb24	 = ISNULL((SELECT A.TVP FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month2 ),0)
	,T.TVPMar24	 = ISNULL((SELECT A.TVP FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month3 ),0)
	,T.TVPApr24	 = ISNULL((SELECT A.TVP FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month4 ),0)
	,T.TVPMay24	 = ISNULL((SELECT A.TVP FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month5 ),0)
	,T.TVPJun24	 = ISNULL((SELECT A.TVP FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month6 ),0)
	,T.TVPJul24	 = ISNULL((SELECT A.TVP FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month7 ),0)
	,T.TVPAug24	 = ISNULL((SELECT A.TVP FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month8 ),0)
	,T.TVPSep24	 = ISNULL((SELECT A.TVP FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month9 ),0)
	,T.TVPOct24	 = ISNULL((SELECT A.TVP FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month10),0)
	,T.TVPNov24	 = ISNULL((SELECT A.TVP FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month11),0)
	,T.TVPDec24	 = ISNULL((SELECT A.TVP FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month12),0)
	,T.ROJan24	 = ISNULL((SELECT A.RO  FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month1 ),0)
	,T.ROFeb24	 = ISNULL((SELECT A.RO  FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month2 ),0)
	,T.ROMar24	 = ISNULL((SELECT A.RO  FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month3 ),0)
	,T.ROApr24	 = ISNULL((SELECT A.RO  FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month4 ),0)
	,T.ROMay24	 = ISNULL((SELECT A.RO  FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month5 ),0)
	,T.ROJun24	 = ISNULL((SELECT A.RO  FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month6 ),0)
	,T.ROJul24	 = ISNULL((SELECT A.RO  FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month7 ),0)
	,T.ROAug24	 = ISNULL((SELECT A.RO  FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month8 ),0)
	,T.ROSep24	 = ISNULL((SELECT A.RO  FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month9 ),0)
	,T.ROOct24	 = ISNULL((SELECT A.RO  FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month10),0)
	,T.RONov24	 = ISNULL((SELECT A.RO  FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month11),0)
	,T.RODec24	 = ISNULL((SELECT A.RO  FROM #MBIDsPoints A WHERE T.PK_Distributor = A.PK_Distributor AND A.dRoyaltyMonth = @Month12),0)
FROM
	#MBIDs T															   
	  		  
/******************************************************************************
	New Member bonuses preparation
******************************************************************************/

	IF (@IsDevQA = 3)
	BEGIN

		DROP TABLE IF EXISTS ##tmp_DS_jgue

		CREATE TABLE ##tmp_DS_jgue
		(
			[PK_Event] INT NULL,
			[PK_Distributor]  INT NULL, 
			[StartDate]  INT NULL,
			[EndDate]  INT NULL,
			[PK_DSType] INT NULL
		)

		DROP TABLE IF EXISTS ##Event_DSPoints_jgue

		CREATE TABLE ##Event_DSPoints_jgue(
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


		DROP TABLE IF EXISTS ##Event_SetupEventQualification_jgue

		CREATE TABLE ##Event_SetupEventQualification_jgue(
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

	END


	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_jgue') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetDSVolume_jgue] is missing, create it manually' AS [ErrorMessage]
	END

	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetQualifier_Points_jgue') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetQualifier_Points_jgue] is missing, create it manually' AS [ErrorMessage]
	END

	IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##usp_GetDSConversionDates_jgue') IS NULL
	BEGIN
		SELECT 'Object [dbo].[##usp_GetDSConversionDates_jgue] is missing, create it manually' AS [ErrorMessage]
	END

	IF @IsDevQA = 3 AND ( OBJECT_ID('tempdb.dbo.##tmp_DS_jgue') IS NULL OR
		OBJECT_ID('tempdb.dbo.##Event_SetupEventQualification_jgue') IS NULL OR
		OBJECT_ID('tempdb.dbo.##Event_DSPoints_jgue') IS NULL)
	BEGIN
		SELECT 'Temp tables are missing, create them manually' AS [Error]
		SET @ErrorMessage = 'Temp tables are missing, create them manually'
	END



	--Qual periods 
	DECLARE 
		@DSQualPeriodStart DATE = '2024-01-01'
		,@DSQualPeriodEnd DATE = '2024-12-01'
		,@AppDateStart INT = 202401 
		,@AppDateEnd INT = 202412  
		,@DSAppDateStart INT = 202401
		,@DSAppDateEnd INT = 202412  
		,@PMAppDateStart INT = 202403
		,@PMAppDateEnd INT = 202412 		  
		,@iStartDate int
		,@dStartDate datetime
		,@iEndDate int
		,@dEndDate datetime

	DROP TABLE IF EXISTS #WRK_25006_BonusPerMonth

	CREATE TABLE #WRK_25006_BonusPerMonth
	(
		PK_Distributor BIGINT DEFAULT 0,
		ApplicationDate INT DEFAULT 0,
		[Total DS Bonus] MONEY DEFAULT 0,
		[Total New DS] INT DEFAULT 0,
		[Total PM Bonus] MONEY DEFAULT 0,
		[Total New PM] INT DEFAULT 0,
		[Total FQS Bonus] MONEY DEFAULT 0,
		[Total New FQS] INT DEFAULT 0,
		[Total ASP Bonus] MONEY DEFAULT 0,
		[Total New ASP] INT DEFAULT 0
	)

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

	--// Prepare the SetupEventQualification
	--DS and PM points
	INSERT INTO #Event_SetupEventQualification([PK_Event],QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,[QSVolume],[PeriodType],[MetricTypeDefinition])											 
	SELECT 
		@PK_Event	AS [PK_Event],
		51					AS QualificationNumber,
		1					AS Part, 
		'DS_PPV,PM_PPV,DLV_DV'		AS [MetricType], 
		@DSQualPeriodStart	AS [dStartDate], 
		@DSQualPeriodEnd	AS [dEndDate],  
		NULL				AS [Frequency], 
		NULL				AS [Consecutive], 
		NULL				AS [Accumulated], 
		NULL				AS [MinPoints], 
		NULL				AS [GoalPoints], 
		NULL				AS [Countries],
		0					AS [QSVolume], 
		NULL				AS [PeriodType], 
		NULL				AS [MetricTypeDefinition]


		IF @IsDevQA = 0
		BEGIN	

			DELETE s FROM [Event].[SetupEventQualification] AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
			INSERT INTO [Event].[SetupEventQualification](PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition 
			FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event

		END
		ELSE
		IF @IsDevQA = 3
		BEGIN	

			DELETE s FROM ##Event_SetupEventQualification_jgue AS s WITH (NOLOCK) WHERE PK_Event = @PK_Event
	 
			INSERT INTO ##Event_SetupEventQualification_jgue(PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition)
			SELECT PK_Event,QualificationNumber,Part,MetricType, [dStartDate],[dEndDate],Frequency,Consecutive,Accumulated,MinPoints,GoalPoints,Countries,MetricTypeDefinition
			FROM #Event_SetupEventQualification WHERE PK_Event = @PK_Event

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


		IF (@IsDevQA = 2)
		BEGIN
			PRINT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1 
		END

		DROP INDEX IF EXISTS IX_#tmp_DS_PK_Distributor ON #tmp_DS;
		DELETE #tmp_DS WHERE PK_Event = @PK_Event

		INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate])
		SELECT 
			@PK_Event AS [PK_Event],
			D.PK_Distributor AS PK_Distributor,
			DD.sDistributorID AS DistributorID,
			@iStartDate AS [iStartDate],
			@iEndDate AS [iEndDate],
			@dStartDate AS [dStartDate],
			@dEndDate AS [dEndDate],
			DD.dSupervisorQualification 
		FROM #MBIDs AS D
		INNER JOIN v_Distributor AS DD
			ON D.PK_Distributor = DD.nDistributorID

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
						
			DROP INDEX IF EXISTS [IX_##tmp_DS_jgue_PK_Distributor]
				ON ##tmp_DS_jgue;

			DELETE d FROM ##tmp_DS_jgue AS d WHERE d.PK_Event = @PK_Event  

			INSERT INTO ##tmp_DS_jgue([PK_Event],[PK_Distributor],[StartDate],[EndDate])
			SELECT 
				D.[PK_Event],
				D.PK_Distributor,
				D.[iStartDate],
				D.[iEndDate]
			FROM #tmp_DS AS D 
											 
			CREATE INDEX IX_##tmp_DS_jgue_PK_Distributor ON ##tmp_DS_jgue(PK_Distributor) INCLUDE(PK_Event);

		END

		DROP TABLE IF EXISTS #DSDownlines

		SELECT
			DL.PK_Distributor,
			DL.PK_DSDownLine
		INTO #DSDownlines
		FROM #MBIDs AS DS --Uplines from All NAM Countries 
			INNER JOIN dbo.v_dimDSLngDownline AS DL
				ON DS.PK_Distributor = DL.PK_Distributor
		WHERE DL.DSLevelFromUL = 2 
									
		DROP TABLE IF EXISTS #DSAssociatedDownlines

		SELECT  DA.PK_Distributor,
				DA.PK_AssociatedID,
				DL.PK_DSDownLine 
		INTO #DSAssociatedDownlines
		FROM #MBIDs AS D --Uplines from All NAM Countries 
		INNER JOIN [Shared].[DistributorAssociation] AS DA WITH (NOLOCK)
			ON D.PK_Distributor = DA.PK_Distributor
		INNER JOIN dbo.v_dimDSLngDownline AS DL
			ON DA.PK_AssociatedID = DL.PK_Distributor
		WHERE DL.DSLevelFromUL = 2  
				
		DROP TABLE IF EXISTS #DSDownlinesSummary

		CREATE TABLE #DSDownlinesSummary (PK_Distributor INT,PK_DSDownLine INT)

		INSERT INTO #DSDownlinesSummary(PK_Distributor,PK_DSDownLine)
			SELECT 
				D.PK_Distributor,
				D.PK_DSDownLine 
			FROM #DSDownlines AS D
					
		INSERT INTO #DSDownlinesSummary(PK_Distributor,PK_DSDownLine)
			SELECT 
				A.PK_Distributor,
				A.PK_DSDownLine 
			FROM #DSAssociatedDownlines AS A
		WHERE NOT EXISTS (SELECT 1 FROM #DSDownlinesSummary AS S WHERE A.PK_Distributor = S.PK_Distributor AND A.PK_DSDownline = S.PK_DSDownLine)

		CREATE INDEX IX_#DSDownlinesSummary_PK_Distributor ON #DSDownlinesSummary(PK_Distributor) INCLUDE (PK_DSDownLine)


		IF @IsDevQA = 0
		BEGIN
			DROP TABLE IF EXISTS [tmp].[DSForConversionEvaluation] -- This tabls must be created within qualification if [dbo].[usp_GetDSConversionDates] will be executed

			SELECT
				@PK_Event AS PK_Event, 
				PK_DSDownLine AS [PK_Distributor]
			INTO [tmp].[DSForConversionEvaluation]
			FROM #DSDownlinesSummary  AS L WITH (NOLOCK)
		END
		ELSE IF @IsDevQA = 3
		BEGIN

			DROP TABLE IF EXISTS ##tmp_DSForConversionEvaluation  

			SELECT
				@PK_Event AS PK_Event, 
				PK_DSDownLine AS [PK_Distributor]
			INTO ##tmp_DSForConversionEvaluation  
			FROM #DSDownlinesSummary  AS L WITH (NOLOCK)

		END


		DROP TABLE IF EXISTS #MemberLastestConversionResult

		CREATE TABLE #MemberLastestConversionResult
		(
			[PK_Event] INT, 
			PK_Distributor BIGINT,
			LastDSConversionMonth INT,
			LastPMConversionMonth INT,
			LatestConversionMonth INT,
			LatestConversionType VARCHAR(25)
		)


			IF @IsDevQA = 0
			BEGIN
						
				--Input [tmp].[DSForConversionEvaluation]
				EXEC dbo.usp_GetDSConversionDates @PK_Event = @PK_Event, @IsDevQA = @IsDevQA, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
				--Output  [tmp].[MemberLastestConversion]

				INSERT INTO #MemberLastestConversionResult([PK_Event],
					PK_Distributor,
					LastDSConversionMonth,
					LastPMConversionMonth,
					LatestConversionMonth,
					LatestConversionType)
				SELECT  
					[PK_Event],
					PK_Distributor,
					LastDSConversionMonth,
					LastPMConversionMonth,
					LatestConversionMonth,
					LatestConversionType
				FROM [tmp].[MemberLastestConversion] WITH (NOLOCK)

				IF @Error <> 0
				BEGIN
					SET @Error = @Error
					SET @ErrorMessage = @ErrorMessage
					RETURN;
				END
		
			END
			ELSE IF @IsDevQA = 3
			BEGIN
	
				--Input
				--##tmp_DSForConversionEvaluation

				EXEC [dbo].[##usp_GetDSConversionDates_jgue] @PK_Event = @PK_Event, @IsDevQA = @IsDevQA, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
				IF @Error <> 0
				BEGIN
					SET @Error = @Error
					SET @ErrorMessage = @ErrorMessage

					SELECT @ErrorMessage
					RETURN;
				END

				--Output
				--##tmp_MemberLastestConversion
		
				INSERT INTO #MemberLastestConversionResult([PK_Event],
					PK_Distributor,
					LastDSConversionMonth,
					LastPMConversionMonth,
					LatestConversionMonth,
					LatestConversionType)
				SELECT  
					[PK_Event],
					PK_Distributor,
					LastDSConversionMonth,
					LastPMConversionMonth,
					LatestConversionMonth,
					LatestConversionType 
				FROM ##tmp_MemberLastestConversion							 
		
			END 

			DROP TABLE IF EXISTS #DownlineApplicationDateEval

			;WITH cte_DownlineApplicationDateEval AS
			(
				SELECT D.PK_Distributor
					,d.PK_DSDownLine 
					,DD.SPQualDate 
					,DD.QSQualDate 		 
					,DD.PK_DSType
					,DD.MBContractAcceptanceDate
					,DD.ConversionDate					  
					,DD.initialAppDate
					,DD.SPRequalDate
					,IIF(PK_DSType IN (4,5),IIF(ISNULL(LatestConversionMonth,190001) > LEFT(ApplicationDate,6), LatestConversionMonth,LEFT(ApplicationDate,6)),
					IIF(PK_DSType IN (6,7), IIF (ISNULL(LatestConversionMonth,190001) > LEFT(MBApplicationDate,6), LatestConversionMonth,LEFT(MBApplicationDate,6)), LEFT(ApplicationDate,6))) AS ApplicationDate
					,ISNULL(LatestConversionMonth,190001) AS LatestConversionMonth
					,LEFT(ApplicationDate,6) DSApplicationDate
					,LEFT(MBApplicationDate,6) MBApplicationDate
				FROM #DSDownlinesSummary  AS d -- Source of DS for evaluation
				INNER JOIN [PubEvents].[dbo].[dimDistributor] AS DD WITH (NOLOCK)
					ON d.PK_DSDownLine = DD.PK_Distributor
				LEFT JOIN #MemberLastestConversionResult AS dc WITH (NOLOCK)
					ON d.PK_DSDownLine = dc.PK_Distributor
				WHERE dc.PK_Event = @PK_Event
			)

			SELECT DISTINCT PK_Distributor
				,PK_DSDownLine 
				,SPQualDate 
				,QSQualDate 		 
				,PK_DSType
				,MBContractAcceptanceDate
				,ConversionDate					  
				,initialAppDate
				,SPRequalDate
				,ApplicationDate
				,LatestConversionMonth
				,DSApplicationDate
				,MBApplicationDate
			INTO #DownlineApplicationDateEval
			FROM cte_DownlineApplicationDateEval   
			WHERE ApplicationDate BETWEEN @AppDateStart AND @AppDateEnd

			--// Freezing DS status
			IF @IsDevQA = 0
			BEGIN

				IF NOT EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25006_DSDownlines' and type='U')
				BEGIN
					CREATE TABLE [dbo].[WRK_25006_DSDownlines]
					(
						PK_Distributor INT
						,PK_DSDownLine INT	 
						,PK_DSType INT
						,ConversionDate INT					  
						,initialAppDate INT
						,ApplicationDate INT
						,LatestConversionMonth INT
						,DSApplicationDate INT
						,MBApplicationDate INT
					) 
				END

				MERGE [dbo].[WRK_25006_DSDownlines] AS T
					USING #DownlineApplicationDateEval	AS S
					ON S.PK_Distributor = T.PK_Distributor AND S.PK_DSDownLine = T.PK_DSDownLine AND S.ApplicationDate = T.ApplicationDate   
					WHEN NOT MATCHED BY Target THEN
						INSERT (PK_Distributor
								,PK_DSDownLine 	 
								,PK_DSType
								,ConversionDate					  
								,initialAppDate
								,ApplicationDate
								,LatestConversionMonth
								,DSApplicationDate
								,MBApplicationDate) 
						VALUES (S.PK_Distributor
							,S.PK_DSDownLine 	 
							,S.PK_DSType
							,S.ConversionDate					  
							,S.initialAppDate
							,S.ApplicationDate
							,S.LatestConversionMonth
							,S.DSApplicationDate
							,S.MBApplicationDate )    
					WHEN MATCHED
						THEN UPDATE SET
						 T.PK_DSType				= S.PK_DSType
						,T.ConversionDate			= S.ConversionDate					  
						,T.initialAppDate			= S.initialAppDate
						,T.ApplicationDate			= S.ApplicationDate
						,T.LatestConversionMonth	= S.LatestConversionMonth
						,T.DSApplicationDate		= S.DSApplicationDate
						,T.MBApplicationDate 		= S.MBApplicationDate 
					;		 
					
			END
			ELSE IF @IsDevQA = 3
			BEGIN

				
				IF OBJECT_ID('tempdb.dbo.##WRK_25006_DSDownlines') IS NULL 
				BEGIN			 

					CREATE TABLE [dbo].[##WRK_25006_DSDownlines]
					(
						PK_Distributor INT
						,PK_DSDownLine INT	 
						,PK_DSType INT
						,ConversionDate INT					  
						,initialAppDate INT
						,ApplicationDate INT
						,LatestConversionMonth INT
						,DSApplicationDate INT
						,MBApplicationDate INT
					)

				END

				 MERGE [dbo].[##WRK_25006_DSDownlines] AS T
					USING #DownlineApplicationDateEval	AS S
					ON S.PK_Distributor = T.PK_Distributor AND S.PK_DSDownLine = T.PK_DSDownLine AND S.ApplicationDate = T.ApplicationDate   
					WHEN NOT MATCHED BY Target THEN
						INSERT (PK_Distributor
								,PK_DSDownLine 	 
								,PK_DSType
								,ConversionDate					  
								,initialAppDate
								,ApplicationDate
								,LatestConversionMonth
								,DSApplicationDate
								,MBApplicationDate) 
						VALUES (S.PK_Distributor
							,S.PK_DSDownLine 	 
							,S.PK_DSType
							,S.ConversionDate					  
							,S.initialAppDate
							,S.ApplicationDate
							,S.LatestConversionMonth
							,S.DSApplicationDate
							,S.MBApplicationDate )    
					WHEN MATCHED
						THEN UPDATE SET
						 T.PK_DSType				= S.PK_DSType
						,T.ConversionDate			= S.ConversionDate					  
						,T.initialAppDate			= S.initialAppDate
						,T.ApplicationDate			= S.ApplicationDate
						,T.LatestConversionMonth	= S.LatestConversionMonth
						,T.DSApplicationDate		= S.DSApplicationDate
						,T.MBApplicationDate 		= S.MBApplicationDate 
					;

			END

	--// Getting all DS conversions history
		IF NOT EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25006_DSDownlinesPreviousPeriods' and type='U')
		BEGIN
			--// #tmp_DSConversions gets all conversions by DS found in #DSDownlinesSummary which contains all downlines from all uplines
			DROP TABLE IF EXISTS dbo.#tmp_DSConversions

			;WITH cte_DSMaxConversionPerMonth AS
			(
				SELECT DMC.PK_Distributor,DMC.RoyaltyMonth,MAX(DMC.ConversionDateLocal) ConversionDateLocal 
				FROM PubEvents.dbo.dimMemberConversion DMC (NOLOCK)
				INNER JOIN #DSDownlinesSummary DSDS ON DMC.PK_Distributor = DSDS.PK_DSDownLine
				WHERE 
					DMC.RoyaltyMonth BETWEEN @AppDateStart AND @AppDateEnd
				GROUP BY DMC.PK_Distributor,DMC.RoyaltyMonth
			)
			SELECT 
				ROW_NUMBER() OVER (PARTITION BY DMC.PK_Distributor ORDER BY DMC.PK_Distributor,DMC.RoyaltyMonth, DMC.ConversionDateLocal) AS row_num
			,DMC.PK_Distributor
			,DMC.RoyaltyMonth
			,DMC.RoyaltyMonth StartDate
				,CASE
					WHEN LEAD(DMC.RoyaltyMonth, 1) OVER (PARTITION BY DMC.PK_Distributor ORDER BY DMC.RoyaltyMonth) IS NOT NULL
					THEN CONVERT(VARCHAR(6), DATEADD(MONTH, -1, CONVERT(DATE, CONCAT(CAST(LEAD(DMC.RoyaltyMonth, 1) OVER (PARTITION BY DMC.PK_Distributor ORDER BY DMC.RoyaltyMonth) AS VARCHAR(6)), '01'), 112)), 112)
					ELSE NULL
				END AS EndDate
			,DMC.ConversionType
			,DMC.FromSubType
			,DMC.ToSubType
			,DST.PK_DSType
			,DMC.ConversionDateLocal
			,DMC.IsLatest
			INTO #tmp_DSConversions
			FROM cte_DSMaxConversionPerMonth CTED
			INNER JOIN PubEvents.dbo.dimMemberConversion DMC (NOLOCK) 
				ON CTED.PK_Distributor = DMC.PK_Distributor AND CTED.RoyaltyMonth = DMC.RoyaltyMonth AND CTED.ConversionDateLocal = DMC.ConversionDateLocal
			INNER JOIN PubEvents.[dbo].[dimDSSubType] DST (NOLOCK) 
				ON DMC.PK_ToSubType = DST.PK_DSSubType
			ORDER BY DMC.PK_Distributor,DMC.RoyaltyMonth, DMC.ConversionDateLocal

			--// #DSConversions contains all conversions from #tmp_DSConversions except the latest (IsLatest = 0) and the RoyaltyMonth is greater or equal to the StartDate

			DROP TABLE IF EXISTS dbo.#DSConversions

			SELECT PK_Distributor PK_DSDownLine,RoyaltyMonth,StartDate,EndDate,ConversionType,FromSubType,ToSubType,PK_DSType,ConversionDateLocal
			INTO #DSConversions
			FROM #tmp_DSConversions
			WHERE 
				RoyaltyMonth >= @AppDateStart
			AND 
				IsLatest = 0
				
			--// Add the first DS period before the first conversion found

			INSERT INTO #DSConversions
			SELECT 
				DSC.PK_Distributor
				,IIF(DSC.RoyaltyMonth > @AppDateStart,@AppDateStart,DSC.RoyaltyMonth) RoyaltyMonth 
				,IIF(DSC.RoyaltyMonth > @AppDateStart,@AppDateStart,DSC.RoyaltyMonth) StartDate 
				,CONVERT(VARCHAR(6), DATEADD(MONTH, -1, CONVERT(DATE, CONCAT(CAST(DSC.RoyaltyMonth AS VARCHAR(6)), '01'), 112)), 112) EndDate
				,NULL ConversionType
				,NULL FromSubType
				,DSC.FromSubType ToSubType
				,DST.PK_DSType PK_DSType
				,NULL ConversionDateLocal	 
			FROM #tmp_DSConversions DSC
			INNER JOIN PubEvents.[dbo].[dimDSSubType] DST (NOLOCK) 
				ON DSC.FromSubType = DST.SubTypeCode
			WHERE 
				DSC.row_num = 1
			AND
				DSC.RoyaltyMonth >= @AppDateStart
			
			CREATE TABLE dbo.WRK_25006_DSDownlinesPreviousPeriods
			(
				PK_Distributor INT
				,PK_DSDownline INT
				,PK_DSType INT
				,ApplicationDate INT
				,StartMonth  INT
				,EndMonth INT
			)
		--// Insert all #DSConversions in WRK_25006_DSDownlinesPreviousPeriods with their uplines
		INSERT INTO dbo.WRK_25006_DSDownlinesPreviousPeriods(
				PK_Distributor
				,PK_DSDownline
				,PK_DSType
				,ApplicationDate
				,StartMonth
				,EndMonth)
			SELECT 
				DSDS.PK_Distributor
				,DSC.PK_DSDownLine PK_DSDownline
				,DSC.PK_DSType
				,DSC.RoyaltyMonth ApplicationDate
				,DSC.StartDate StartMonth
				,DSC.EndDate EndMonth
			FROM #DSConversions DSC
			INNER JOIN #DSDownlinesSummary DSDS 
				ON DSC.PK_DSDownLine = DSDS.PK_DSDownLine
			ORDER BY DSDS.PK_Distributor,DSC.PK_DSDownLine,DSC.RoyaltyMonth

			--// Mixing all downlines without any conversion to dbo.WRK_25006_DSDownlinesPreviousPeriods except those that already added
			INSERT INTO dbo.WRK_25006_DSDownlinesPreviousPeriods
			(	
				PK_Distributor
				,PK_DSDownline
				,PK_DSType
				,ApplicationDate
				,StartMonth
				,EndMonth
			)
			SELECT 
				DSDS.PK_Distributor
				,DSDS.PK_DSDownLine
				,dD.PK_DSType PK_DSType
				,LEFT(dD.ApplicationDate,6) ApplicationDate
				,@AppDateStart StartDate
				,@AppDateEnd EndDate
			FROM  #DSDownlinesSummary DSDS
			INNER JOIN Pubevents.[dbo].[dimDistributor] dD (NOLOCK)
				ON DSDS.PK_DSDownLine = dD.PK_Distributor
			WHERE 
				NOT EXISTS (SELECT 1 
							FROM dbo.WRK_25006_DSDownlinesPreviousPeriods DSDP (NOLOCK) 
							WHERE DSDS.PK_Distributor = DSDP.PK_Distributor AND DSDP.PK_DSDownLine = DSDS.PK_DSDownLine)

		END

				DROP INDEX IF EXISTS IX_#tmp_DS_PK_Distributor ON #tmp_DS;
				DELETE #tmp_DS WHERE PK_Event = @PK_Event
					
					IF @IsDevQA = 0
					BEGIN

						
						;WITH cte_WRK_25006_DSDownlines AS
						(
							SELECT d.PK_Distributor,d.PK_DSDownLine,ApplicationDate,PK_DSType 
										,ROW_NUMBER() OVER (PARTITION BY d.PK_Distributor,d.PK_DSDownLine ORDER BY d.ApplicationDate DESC) StatusOrder
							FROM [dbo].[WRK_25006_DSDownlines] AS d WITH (NOLOCK)
						)


						INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate],[PK_DSType])
						SELECT 
							@PK_Event AS [PK_Event],
							D.PK_DSDownLine AS PK_Distributor,
							DD.DistributorID,
							@iStartDate AS [iStartDate],
							@iEndDate AS [iEndDate],
							@dStartDate AS [dStartDate],
							@dEndDate AS [dEndDate],
							CASE WHEN DD.SPQualDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DD.SPQualDate),112) END, 
							D.PK_DSType -- Frezee type
						FROM cte_WRK_25006_DSDownlines AS D WITH (NOLOCK)
						INNER JOIN [PubEvents].[dbo].dimDistributor AS DD WITH (NOLOCK)
							ON D.PK_DSDownLine = DD.PK_Distributor
						WHERE D.StatusOrder = 1

					END 
					ELSE IF @IsDevQA = 3
					BEGIN

						;WITH cte_WRK_25006_DSDownlines AS
						(
							SELECT d.PK_Distributor,d.PK_DSDownLine,ApplicationDate,PK_DSType 
										,ROW_NUMBER() OVER (PARTITION BY d.PK_Distributor,d.PK_DSDownLine ORDER BY d.ApplicationDate DESC) StatusOrder
							FROM [dbo].[##WRK_25006_DSDownlines] AS d WITH (NOLOCK)
						)

						INSERT INTO #tmp_DS([PK_Event],[PK_Distributor],DistributorID,[iStartDate],[iEndDate],[dStartDate],[dEndDate],[dSPQualDate],[PK_DSType])
						SELECT 
							@PK_Event AS [PK_Event],
							D.PK_DSDownLine AS PK_Distributor,
							DD.DistributorID,
							@iStartDate AS [iStartDate],
							@iEndDate AS [iEndDate],
							@dStartDate AS [dStartDate],
							@dEndDate AS [dEndDate],
							CASE WHEN DD.SPQualDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DD.SPQualDate),112) END, 
							D.PK_DSType -- Frezee type
						FROM cte_WRK_25006_DSDownlines AS D
						INNER JOIN [PubEvents].[dbo].dimDistributor AS DD WITH (NOLOCK)
							ON D.PK_DSDownLine = DD.PK_Distributor
						WHERE D.StatusOrder = 1

					END
					
					IF (@IsDevQA = 0)
					BEGIN
						
						DROP INDEX IF EXISTS [IX_DS_PK_Distributor]
							ON [tmp].[DS];

						DELETE d FROM [tmp].[DS] AS d WHERE d.PK_Event = @PK_Event  

						INSERT INTO [tmp].[DS]([PK_Event],[PK_Distributor],[StartDate],[EndDate],[PK_DSType]) 
						SELECT 
							D.[PK_Event],
							D.PK_Distributor,
							D.[iStartDate],
							D.[iEndDate],
							D.[PK_DSType]
						FROM #tmp_DS AS D 
											 
						CREATE INDEX IX_DS_PK_Distributor ON [tmp].[DS](PK_Distributor) INCLUDE(PK_Event);

					END
					ELSE IF (@IsDevQA = 3)
					BEGIN
						
						DROP INDEX IF EXISTS [IX_##tmp_DS_jgue_PK_Distributor]
							ON ##tmp_DS_jgue;

						DELETE d FROM ##tmp_DS_jgue AS d WHERE d.PK_Event = @PK_Event  

						INSERT INTO ##tmp_DS_jgue([PK_Event],[PK_Distributor],[StartDate],[EndDate],[PK_DSType])
						SELECT 
							D.[PK_Event],
							D.PK_Distributor,
							D.[iStartDate],
							D.[iEndDate],
							D.[PK_DSType]
						FROM #tmp_DS AS D 
											 
						CREATE INDEX IX_##tmp_DS_jgue_PK_Distributor ON ##tmp_DS_jgue(PK_Distributor) INCLUDE(PK_Event);

					END



			------------------------------------------------------------------------------------------------
			-- Getting [Event].[DSPoints]
			------------------------------------------------------------------------------------------------

			IF (@IsDevQA = 0)
			BEGIN
				--Input
				--[tmp].[DS]
				--[Event].[SetupEventQualification]
				--IF @EnableConversionDates = 1 [tmp].[MemberLastestConversion]

				--SourceType 3: Getting points from [PubEventManagement].[dbo].[v_aggFQS_ID]
				EXEC dbo.usp_GetDSVolume @PK_Event = @PK_Event, @SourceType = 1, @QualFilter = '51', @EnableConversionDates = 1,@KeepNegativeVolume = 0, @Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
				
				--Output [Event].[DSPoints]
				--Output [tmp].[DSSummary] 

				IF @Error <> 0
				BEGIN
					SET @Error = @Error
					SET @ErrorMessage = @ErrorMessage
					RETURN;
				END
		
			END
			ELSE
			IF (@IsDevQA = 3) AND OBJECT_ID('tempdb.dbo.##usp_GetDSVolume_jgue') IS NOT NULL
			BEGIN

				--Input
				--##tmp_DS_jgue
				--##Event_SetupEventQualification_jgue
				--IF @EnableConversionDates = 1 ##tmp_MemberLastestConversion

				--SourceType 3: Getting points from [PubEventManagement].[dbo].[v_aggFQS_ID]
				EXEC [dbo].[##usp_GetDSVolume_jgue] @PK_Event = @PK_Event, @SourceType = 1,@QualFilter = '51', @EnableConversionDates = 1,@KeepNegativeVolume = 0,@Error = @Error OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT
					
				IF @Error <> 0
				BEGIN
					SET @Error = @Error
					SET @ErrorMessage = @ErrorMessage

					SELECT @ErrorMessage
					RETURN;
				END

				--Output
				--##Event_DSPoints_jgue
				--##tmp_DSSummary 
		
			END

			------------------------------------------------------------------------------------------------
			-- Getting #Event_DownlinesPoints  
			------------------------------------------------------------------------------------------------

				--Allocating volume for downlines.

				DROP TABLE IF EXISTS #Event_DownlinesPoints

				CREATE TABLE #Event_DownlinesPoints
				(
					[PK_Distributor] [int] NULL,
					[PK_Event] [int] NULL,
					[PK_Country] [int] NULL,
					[RoyaltyMonth] [int] NULL,
					[MetricType] [varchar](20) NULL,
					[PersonalPoints] [money] NULL DEFAULT(0),
					[TransferPoints] [money] NULL DEFAULT(0),
					[MainPoints] [money] NULL DEFAULT(0),
					[Points] [money] NULL DEFAULT(0) 
				)

				IF @IsDevQA = 0
				BEGIN
					INSERT INTO #Event_DownlinesPoints(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points])
					SELECT 
						PK_Distributor,
						[PK_Event],
						PK_Country,
						[RoyaltyMonth],
						MetricType,
						[PersonalPoints] AS [PersonalPoints],
						[TransferPoints] AS [TransferPoints],
						[MainPoints] AS [MainPoints], 
						ROUND([Points],2) AS [Points] 
					FROM [Event].[DSPoints] WITH (NOLOCK)
					WHERE PK_Event = @PK_Event


					DROP TABLE IF EXISTS [dbo].[WRK_25006_DownlinesPoints]

					SELECT 
						PK_Distributor,
						[PK_Event],
						PK_Country,
						[RoyaltyMonth],
						MetricType,
						[PersonalPoints] AS [PersonalPoints],
						[TransferPoints] AS [TransferPoints],
						[MainPoints] AS [MainPoints], 
						ROUND([Points],2) AS [Points] 
					INTO [dbo].[WRK_25006_DownlinesPoints]
					FROM [Event].[DSPoints] WITH (NOLOCK)
					WHERE PK_Event = @PK_Event


				END
				ELSE IF @IsDevQA = 3
				BEGIN

					INSERT INTO #Event_DownlinesPoints(PK_Distributor,[PK_Event],PK_Country,RoyaltyMonth,MetricType,[PersonalPoints],[TransferPoints],[MainPoints],[Points])
					SELECT 
						PK_Distributor,
						[PK_Event],
						PK_Country,
						[RoyaltyMonth],
						MetricType,
						[PersonalPoints] AS [PersonalPoints],
						[TransferPoints] AS [TransferPoints],
						[MainPoints] AS [MainPoints],  
						ROUND([Points],2) AS [Points] 
					FROM ##Event_DSPoints_jgue

				END

				CREATE CLUSTERED INDEX [IX_#Event_DownlinesPoints_PK_Distributor] ON #Event_DownlinesPoints ([PK_Distributor]) 
				CREATE NONCLUSTERED INDEX [IX_#Event_DownlinesPoints_MetricType] ON #Event_DownlinesPoints ([MetricType])


			/******************************************************************************
				New DS Bonus Promotion
			******************************************************************************/

			------------------------------------------------------------------------------------------------
			-- Getting #Event_DownlinesPoints  
			------------------------------------------------------------------------------------------------

			DROP TABLE IF EXISTS #DSDownlinesPeriod

			CREATE TABLE #DSDownlinesPeriod
			(
				PK_Distributor INT,
				PK_DSDownline INT,
				PK_DSType INT,
				ApplicationDate INT,
				StartMonth INT,
				EndMonth INT
			)

			IF @IsDevQA = 0
			BEGIN
				INSERT INTO #DSDownlinesPeriod(PK_Distributor,
					PK_DSDownline,
					PK_DSType,
					ApplicationDate, 
					StartMonth, 
					EndMonth)
				SELECT 
					PK_Distributor,
					PK_DSDownline,
					PK_DSType,
					ApplicationDate, 
					ApplicationDate AS StartMonth, 
					IIF( ApplicationDate+1 > @AppDateEnd,@AppDateEnd, ApplicationDate+1 )  AS EndMonth
				FROM [dbo].[WRK_25006_DSDownlines] AS D WITH (NOLOCK)
				WHERE ApplicationDate BETWEEN @DSAppDateStart AND @DSAppDateEnd

			END ELSE IF @IsDevQA = 3
			BEGIN
				INSERT INTO #DSDownlinesPeriod(PK_Distributor,
					PK_DSDownline,
					PK_DSType,
					ApplicationDate, 
					StartMonth, 
					EndMonth)
				SELECT 
					PK_Distributor,
					PK_DSDownline,
					PK_DSType,
					ApplicationDate, 
					ApplicationDate AS StartMonth, 
					IIF( ApplicationDate+1 > @AppDateEnd,@AppDateEnd, ApplicationDate+1 )  AS EndMonth
				FROM [dbo].[##WRK_25006_DSDownlines] AS D
				WHERE ApplicationDate BETWEEN @DSAppDateStart AND @DSAppDateEnd

			END

			-- Setting up DS temp tables

			DROP TABLE IF EXISTS #NewDSPerMonth

			CREATE TABLE #NewDSPerMonth
			(
				PK_Distributor INT,
				ApplicationDate INT,
				[TotalNewDS] INT,
				[TotalBonusNewDS] MONEY
			)

			DROP TABLE IF EXISTS #NewDSSSummary

			CREATE TABLE #NewDSSSummary
			(
				PK_Distributor INT,
				[TotalNewDS] INT,
				[TotalBonusNewDS] MONEY
			)


			IF @IsDevQA = 0 AND NOT EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25006_NewDSBonusContributors' and type='U')
			BEGIN
				CREATE TABLE [dbo].[WRK_25006_NewDSBonusContributors] 
				(
					[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
					PK_Distributor BIGINT,
					PK_DSDownLine  BIGINT,
					ApplicationDate INT,
					[ContributionCount] INT DEFAULT (1),
					[Active] BIT DEFAULT 1
				)
			END
			ELSE
			IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##WRK_25006_NewDSBonusContributors') IS NULL 
			BEGIN
				CREATE TABLE [dbo].[##WRK_25006_NewDSBonusContributors] 
				(
					[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
					PK_Distributor BIGINT,
					PK_DSDownLine  BIGINT,
					ApplicationDate INT,
					[ContributionCount] INT DEFAULT (1),
					[Active] BIT DEFAULT 1
				)
			END

			--// Getting contributors
			DROP TABLE IF EXISTS #NewDS
				
			SELECT d.PK_Distributor,d.PK_DSDownline,d.ApplicationDate 
			INTO #NewDS
			FROM #DSDownlinesPeriod AS d
			INNER JOIN #Event_DownlinesPoints AS p
				ON d.PK_DSDownline = p.PK_Distributor  AND p.RoyaltyMonth BETWEEN d.StartMonth AND d.EndMonth
			WHERE d.PK_DSType IN (5,4) AND p.MetricType IN ('DS_PPV','DLV_DV')
			GROUP BY d.PK_Distributor, d.PK_DSDownline,d.ApplicationDate
			HAVING SUM(Points) >= 100

			--// If there are DS's Previous Periods to check, process them just once and store them and create WRK_25006_DSDownlinesPreviousPeriods_DS as a flag to know they were already processed
			IF EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25006_DSDownlinesPreviousPeriods' and type='U')
				AND NOT EXISTS(SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25006_DSDownlinesPreviousPeriods_DS' and type='U')
			BEGIN
				INSERT INTO #NewDS
				SELECT d.PK_Distributor,d.PK_DSDownline,d.ApplicationDate 
				FROM dbo.WRK_25006_DSDownlinesPreviousPeriods d (NOLOCK)
				INNER JOIN #Event_DownlinesPoints AS p
					ON d.PK_DSDownline = p.PK_Distributor  AND p.RoyaltyMonth BETWEEN d.StartMonth AND d.EndMonth
				WHERE d.PK_DSType IN (5,4) AND p.MetricType IN ('DS_PPV','DLV_DV')
					AND d.StartMonth BETWEEN @DSAppDateStart AND @DSAppDateEnd
				GROUP BY d.PK_Distributor, d.PK_DSDownline,d.ApplicationDate
				HAVING SUM(Points) >= 100

				CREATE TABLE [dbo].[WRK_25006_DSDownlinesPreviousPeriods_DS] 
				(
					[CreatedDate] DATETIME DEFAULT GETDATE()
				)

			END
			
			DROP TABLE IF EXISTS #NewDS_Source
				
			CREATE TABLE #NewDS_Source
			(
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ApplicationDate INT,
				[Active] BIT  
			)

			INSERT INTO #NewDS_Source(PK_Distributor,PK_DSDownline,ApplicationDate,[Active])
			SELECT DISTINCT PK_Distributor,PK_DSDownline,ApplicationDate ,1 
			FROM #NewDS				 
			
				--Overwriting contributors 
				DROP TABLE IF EXISTS #NewDSOverwrite
				 
				SELECT 
					U.nDistributorID AS PK_Distributor,
					D.nDistributorID AS PK_DSDownLine,
					o.ContributionMonth AS ApplicationDate,
					 MAX(CONVERT(int,o.Active)) AS [Active]
				INTO #NewDSOverwrite
				FROM [dbo].[WRK_25006_NAMPT_NEWDS_Overwrite] AS o WITH (NOLOCK)
					INNER JOIN v_Distributor AS U
						ON o.UL_DistributorID = U.sDistributorID
					INNER JOIN v_Distributor AS D
						ON o.DL_DistributorID = D.sDistributorID			 
				GROUP BY U.nDistributorID,
					D.nDistributorID,
					o.ContributionMonth 

				MERGE #NewDS_Source AS t
				USING #NewDSOverwrite  AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active);

			--// Freezing contributors
			IF @IsDevQA = 0
			BEGIN
				
				MERGE [dbo].[WRK_25006_NewDSBonusContributors] AS t
				USING #NewDS_Source AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate)
				WHEN NOT MATCHED BY SOURCE
					THEN UPDATE SET 
						t.Active = 0 
				WHEN MATCHED
					THEN UPDATE SET 
						t.Active = 1; 	

				UPDATE t
				SET Active = s.Active
				FROM [dbo].[WRK_25006_NewDSBonusContributors] AS t
					INNER JOIN #NewDSOverwrite AS s
						ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
	 
				-- Add contributor by report  
				;WITH cte_NewDSContributorsReport AS
				(
					SELECT 
						U.nDistributorID AS PK_Distributor,
						D.nDistributorID AS PK_DSDownLine,
						o.ContributionMonth AS ApplicationDate,
						1 AS Active,
						o.ContributionsCount
					FROM [dbo].[WRK_25006_DSBonusContributors] AS o WITH (NOLOCK)
						INNER JOIN v_Distributor AS U
							ON o.UL_DistributorID = U.sDistributorID
						INNER JOIN v_Distributor AS D
							ON o.DL_DistributorID = D.sDistributorID
				)

				MERGE [dbo].[WRK_25006_NewDSBonusContributors] AS t
				USING cte_NewDSContributorsReport  AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active,ContributionCount)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active,ContributionsCount)
				WHEN MATCHED THEN 
				UPDATE SET 
						t.ContributionCount = t.ContributionCount + s.ContributionsCount; 

				--// Getting contributors per month
				INSERT INTO #NewDSPerMonth(PK_Distributor,ApplicationDate,[TotalNewDS],[TotalBonusNewDS])
				SELECT 
					F.PK_Distributor,
					F.ApplicationDate,
					SUM([ContributionCount]) AS [TotalNewDS],
					(SUM([ContributionCount]) * 1000) AS [TotalBonusNewDS]
				FROM [dbo].[WRK_25006_NewDSBonusContributors]   AS F WITH (NOLOCK)
				WHERE Active = 1
				GROUP BY F.PK_Distributor,F.ApplicationDate
				 
			END
			ELSE IF @IsDevQA = 3
			BEGIN
				
				MERGE [dbo].[##WRK_25006_NewDSBonusContributors] AS t
				USING #NewDS_Source AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate)
				WHEN NOT MATCHED BY SOURCE
					THEN UPDATE SET 
						t.Active = 0
				WHEN MATCHED
					THEN UPDATE SET 
						t.Active = 1; 

				-- Add contributor by report  
				;WITH cte_NewDSContributorsReport AS
				(
					SELECT 
						U.nDistributorID AS PK_Distributor,
						D.nDistributorID AS PK_DSDownLine,
						o.ContributionMonth AS ApplicationDate,
						1 AS Active,
						o.ContributionsCount
					FROM [dbo].[WRK_25006_DSBonusContributors] AS o WITH (NOLOCK)
						INNER JOIN v_Distributor AS U
							ON o.UL_DistributorID = U.sDistributorID
						INNER JOIN v_Distributor AS D
							ON o.DL_DistributorID = D.sDistributorID
				)

				MERGE [##WRK_25006_NewDSBonusContributors] AS t
				USING cte_NewDSContributorsReport  AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active,ContributionCount)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active,ContributionsCount)
				WHEN MATCHED THEN 
				UPDATE SET 
						t.ContributionCount = t.ContributionCount + s.ContributionsCount; 


	 
				--// Getting contributors per month
				INSERT INTO #NewDSPerMonth(PK_Distributor,ApplicationDate,[TotalNewDS],[TotalBonusNewDS])
				SELECT 
					F.PK_Distributor,
					F.ApplicationDate,
					SUM([ContributionCount]) AS [TotalNewDS],
					(SUM([ContributionCount]) * 1000) AS [TotalBonusNewDS]
				FROM [dbo].[##WRK_25006_NewDSBonusContributors]  AS F WITH (NOLOCK)
				WHERE Active = 1
				GROUP BY F.PK_Distributor,F.ApplicationDate
				 
			END

			--// Getting totals per Distributor
			INSERT INTO #NewDSSSummary(PK_Distributor,[TotalNewDS],[TotalBonusNewDS])
			SELECT 
				PK_Distributor,
				SUM(TotalNewDS) [TotalNewDS],
				SUM(TotalBonusNewDS) [TotalBonusNewDS]
			FROM #NewDSPerMonth WITH (NOLOCK)
			GROUP BY PK_Distributor


			/******************************************************************************
				New PM Bonus Promotion
			******************************************************************************/

			------------------------------------------------------------------------------------------------
			-- Getting #Event_DownlinesPoints  
			------------------------------------------------------------------------------------------------

			DROP TABLE IF EXISTS #PMDownlinesPeriod

			CREATE TABLE #PMDownlinesPeriod
			(
				PK_Distributor INT,
				PK_DSDownline INT,
				PK_DSType INT,
				ApplicationDate INT,
				StartMonth INT,
				EndMonth INT
			)

			IF @IsDevQA = 0
			BEGIN
				INSERT INTO #PMDownlinesPeriod(PK_Distributor,
					PK_DSDownline,
					PK_DSType,
					ApplicationDate, 
					StartMonth, 
					EndMonth)
				SELECT 
					PK_Distributor,
					PK_DSDownline,
					PK_DSType,
					ApplicationDate, 
					ApplicationDate AS StartMonth, 
					IIF( ApplicationDate+1 > @AppDateEnd,@AppDateEnd, ApplicationDate+1 )  AS EndMonth
				FROM [dbo].[WRK_25006_DSDownlines] AS D WITH (NOLOCK)
				WHERE ApplicationDate BETWEEN @PMAppDateStart AND @PMAppDateEnd

			END ELSE IF @IsDevQA = 3
			BEGIN
				INSERT INTO #PMDownlinesPeriod(PK_Distributor,
					PK_DSDownline,
					PK_DSType,
					ApplicationDate, 
					StartMonth, 
					EndMonth)
				SELECT 
					PK_Distributor,
					PK_DSDownline,
					PK_DSType,
					ApplicationDate, 
					ApplicationDate AS StartMonth, 
					IIF( ApplicationDate+1 > @AppDateEnd,@AppDateEnd, ApplicationDate+1 )  AS EndMonth
				FROM [dbo].[##WRK_25006_DSDownlines] AS D
				WHERE ApplicationDate BETWEEN @PMAppDateStart AND @PMAppDateEnd

			END

			-- Setting up PM temp tables

			DROP TABLE IF EXISTS #NewPMPerMonth

			CREATE TABLE #NewPMPerMonth
			(
				PK_Distributor INT,
				ApplicationDate INT,
				[TotalNewPM] INT,
				[TotalBonusNewPM] MONEY
			)

			DROP TABLE IF EXISTS #NewPMSummary

			CREATE TABLE #NewPMSummary
			(
				PK_Distributor INT,
				[TotalNewPM] INT,
				[TotalBonusNewPM] MONEY
			)


			IF @IsDevQA = 0 AND NOT EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25006_NewPMBonusContributors' and type='U')
			BEGIN
				CREATE TABLE [dbo].[WRK_25006_NewPMBonusContributors] 
				(
					[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
					PK_Distributor BIGINT,
					PK_DSDownLine  BIGINT,
					ApplicationDate INT,
					[ContributionCount] INT DEFAULT (1),
					[Active] BIT DEFAULT 1
				)
			END
			ELSE
			IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##WRK_25006_NewPMBonusContributors') IS NULL 
			BEGIN
				CREATE TABLE [dbo].[##WRK_25006_NewPMBonusContributors] 
				(
					[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
					PK_Distributor BIGINT,
					PK_DSDownLine  BIGINT,
					ApplicationDate INT,
					[ContributionCount] INT DEFAULT (1),
					[Active] BIT DEFAULT 1
				)
			END

			--// Getting contributors
			DROP TABLE IF EXISTS #NewPM
				
			SELECT d.PK_Distributor,d.PK_DSDownline,d.ApplicationDate 
			INTO #NewPM
			FROM #PMDownlinesPeriod AS d
			INNER JOIN #Event_DownlinesPoints AS p
				ON d.PK_DSDownline = p.PK_Distributor  AND p.RoyaltyMonth BETWEEN d.StartMonth AND d.EndMonth
			WHERE d.PK_DSType IN (6,7) AND p.MetricType = 'PM_PPV'
			GROUP BY d.PK_Distributor, d.PK_DSDownline,d.ApplicationDate
			HAVING SUM(Points) >= 100

			--// If there are PM's Previous Periods to check, process them just once and store them and create WRK_25006_DSDownlinesPreviousPeriods_PM as a flag to know they were already processed
			IF EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25006_DSDownlinesPreviousPeriods' and type='U')
				AND NOT EXISTS(SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25006_DSDownlinesPreviousPeriods_PM' and type='U')
			BEGIN
				INSERT INTO #NewPM
				SELECT d.PK_Distributor,d.PK_DSDownline,d.ApplicationDate 
				FROM dbo.WRK_25006_DSDownlinesPreviousPeriods d (NOLOCK)
				INNER JOIN #Event_DownlinesPoints AS p
					ON d.PK_DSDownline = p.PK_Distributor  AND p.RoyaltyMonth BETWEEN d.StartMonth AND d.EndMonth
				WHERE d.PK_DSType IN (6,7) AND p.MetricType = 'PM_PPV'
					AND d.StartMonth BETWEEN @PMAppDateStart AND @PMAppDateEnd
				GROUP BY d.PK_Distributor, d.PK_DSDownline,d.ApplicationDate
				HAVING SUM(Points) >= 100

				CREATE TABLE [dbo].[WRK_25006_DSDownlinesPreviousPeriods_PM] 
				(
					[CreatedDate] DATETIME DEFAULT GETUTCDATE()
				)

			END

			DROP TABLE IF EXISTS #NewPM_Source
				
			CREATE TABLE #NewPM_Source
			(
				PK_Distributor BIGINT,
				PK_DSDownLine  BIGINT,
				ApplicationDate INT,
				[Active] BIT  
			)

			INSERT INTO #NewPM_Source(PK_Distributor,PK_DSDownline,ApplicationDate,[Active])
			SELECT DISTINCT PK_Distributor,PK_DSDownline,ApplicationDate ,1 
			FROM #NewPM

			--Overwriting contributors 
				 
			DROP TABLE IF EXISTS #NewPMOverwrite

				SELECT 
					U.nDistributorID AS PK_Distributor,
					D.nDistributorID AS PK_DSDownLine,
					o.ContributionMonth AS ApplicationDate,
					 MAX(CONVERT(int,o.Active)) AS [Active]
				INTO #NewPMOverwrite
				FROM [dbo].[WRK_25006_NAMPT_NEWPM_Overwrite] AS o WITH (NOLOCK)
					INNER JOIN v_Distributor AS U
						ON o.UL_DistributorID = U.sDistributorID
					INNER JOIN v_Distributor AS D
						ON o.DL_DistributorID = D.sDistributorID
 				GROUP BY U.nDistributorID,
					D.nDistributorID,
					o.ContributionMonth 

			 
				MERGE #NewPM_Source AS t
				USING #NewPMOverwrite  AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,s.Active);

			--// Freezing contributors
			IF @IsDevQA = 0
			BEGIN
					
				MERGE [dbo].[WRK_25006_NewPMBonusContributors] AS t
				USING #NewPM_Source AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate)
				WHEN NOT MATCHED BY SOURCE
					THEN UPDATE SET 
						t.Active = 0 
				WHEN MATCHED
					THEN UPDATE SET 
						t.Active = 1; 

				UPDATE t
				SET Active = s.Active
				FROM [dbo].[WRK_25006_NewPMBonusContributors] AS t
					INNER JOIN #NewPMOverwrite AS s
						ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate

				-- Add contributor by report  
				;WITH cte_NewPMContributorsReport AS
				(
					SELECT 
						U.nDistributorID AS PK_Distributor,
						D.nDistributorID AS PK_DSDownLine,
						o.ContributionMonth AS ApplicationDate,
						1 AS Active,
						o.ContributionsCount
					FROM [dbo].[WRK_25006_PMBonusContributors] AS o WITH (NOLOCK)
						INNER JOIN v_Distributor AS U
							ON o.UL_DistributorID = U.sDistributorID
						INNER JOIN v_Distributor AS D
							ON o.DL_DistributorID = D.sDistributorID
				)

				MERGE [dbo].[WRK_25006_NewPMBonusContributors] AS t
				USING cte_NewPMContributorsReport  AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active,ContributionCount)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active,ContributionsCount)
				WHEN MATCHED THEN 
				UPDATE SET 
						t.ContributionCount = t.ContributionCount + s.ContributionsCount; 
						
				--// Getting contributors per month
				INSERT INTO #NewPMPerMonth(PK_Distributor,ApplicationDate,[TotalNewPM],[TotalBonusNewPM])
				SELECT 
					F.PK_Distributor,
					F.ApplicationDate,
					SUM([ContributionCount]) AS [TotalNewPM],
					(SUM([ContributionCount]) * 500) AS [TotalBonusNewPM]
				FROM [dbo].[WRK_25006_NewPMBonusContributors]   AS F WITH (NOLOCK)
				WHERE Active = 1
				GROUP BY F.PK_Distributor,F.ApplicationDate
				 
			END
			ELSE IF @IsDevQA = 3
			BEGIN
				
				MERGE [dbo].[##WRK_25006_NewPMBonusContributors] AS t
				USING #NewPM_Source AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate)
				WHEN NOT MATCHED BY SOURCE
					THEN UPDATE SET 
						t.Active = 0
				WHEN MATCHED
					THEN UPDATE SET 
						t.Active = 1; 

				-- Add contributor by report  
				;WITH cte_NewPMContributorsReport AS
				(
					SELECT 
						U.nDistributorID AS PK_Distributor,
						D.nDistributorID AS PK_DSDownLine,
						o.ContributionMonth AS ApplicationDate,
						1 AS Active,
						o.ContributionsCount
					FROM [dbo].[WRK_25006_PMBonusContributors] AS o WITH (NOLOCK)
						INNER JOIN v_Distributor AS U
							ON o.UL_DistributorID = U.sDistributorID
						INNER JOIN v_Distributor AS D
							ON o.DL_DistributorID = D.sDistributorID
				)

				MERGE [##WRK_25006_NewPMBonusContributors] AS t
				USING cte_NewPMContributorsReport  AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active,ContributionCount)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active,ContributionsCount)
				WHEN MATCHED THEN 
				UPDATE SET 
						t.ContributionCount = t.ContributionCount + s.ContributionsCount; 	
						
				--// Getting contributors per month
				INSERT INTO #NewPMPerMonth(PK_Distributor,ApplicationDate,[TotalNewPM],[TotalBonusNewPM])
				SELECT 
					F.PK_Distributor,
					F.ApplicationDate,
					SUM([ContributionCount]) AS [TotalNewPM],
					(SUM([ContributionCount]) * 500) AS [TotalBonusNewPM]
				FROM [dbo].[##WRK_25006_NewPMBonusContributors]  AS F WITH (NOLOCK)
				WHERE Active = 1
				GROUP BY F.PK_Distributor,F.ApplicationDate
				 
			END

			--// Getting totals per Distributor
			INSERT INTO #NewPMSummary(PK_Distributor,[TotalNewPM],[TotalBonusNewPM])
			SELECT 
				PK_Distributor,
				SUM(TotalNewPM) [TotalNewPM],
				SUM(TotalBonusNewPM) [TotalBonusNewPM]
			FROM #NewPMPerMonth WITH (NOLOCK)
			GROUP BY PK_Distributor


		/******************************************************************************
			New FQS Bonus Promotion
		******************************************************************************/


		DECLARE 	
			@FQSAppDateStart DATETIME  = '2024-02-01' 
			,@FQSAppDateEnd DATETIME = '2025-01-31'

			-- Setting up temp tables
			DROP TABLE IF EXISTS #NewFQSPerMonth

			CREATE TABLE #NewFQSPerMonth
			(
				PK_Distributor INT,
				ApplicationDate INT,
				[TotalNewFQS] INT,
				[TotalBonusNewFQS] MONEY
			)

			DROP TABLE IF EXISTS #NewFQSSummary

			CREATE TABLE #NewFQSSummary
			(
				PK_Distributor INT,
				[TotalNewFQS] INT,
				[TotalBonusNewFQS] MONEY
			)

			IF @IsDevQA = 0 AND NOT EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25006_NewFQSBonusContributors' and type='U')
			BEGIN
				CREATE TABLE [dbo].[WRK_25006_NewFQSBonusContributors] 
				(
					[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
					PK_Distributor BIGINT,
					PK_DSDownLine  BIGINT,
					ApplicationDate INT,
					[ContributionCount] INT DEFAULT (1),
					[Active] BIT DEFAULT 1
				)
			END
			ELSE
			IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##WRK_25006_NewFQSBonusContributors') IS NULL  
			BEGIN
				CREATE TABLE [dbo].[##WRK_25006_NewFQSBonusContributors] 
				(
					[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
					PK_Distributor BIGINT,
					PK_DSDownLine  BIGINT,
					ApplicationDate INT,
					[ContributionCount] INT DEFAULT (1),
					[Active] BIT DEFAULT 1
				)

				INSERT INTO [dbo].[##WRK_25006_NewFQSBonusContributors]([CreatedDate],PK_Distributor,PK_DSDownLine,ApplicationDate,[Active])
				SELECT [CreatedDate],PK_Distributor,PK_DSDownLine,ApplicationDate,[Active] FROM [dbo].[WRK_25006_NewFQSBonusContributors] WITH (NOLOCK)

				UPDATE [dbo].[##WRK_25006_NewFQSBonusContributors]
				SET Active = 1	

			END

			--// Getting contributors				
			DROP TABLE IF EXISTS #NewFQS

			SELECT
				DL.PK_Distributor,
				DL.PK_DSDownLine,
				SUBSTRING(CAST(CONVERT(VARCHAR, DD.dSupervisorQualification, 112) AS VARCHAR), 1, 6) ApplicationDate,
				1 AS [Active]
			INTO #NewFQS
			FROM #DSDownlinesSummary AS DL
				INNER JOIN v_Distributor AS DD
					ON DL.PK_DSDownLine = DD.nDistributorID
			WHERE
				DD.StatusCode = 'COMPLETE'
				AND
				DD.dSupervisorQualification BETWEEN @FQSAppDateStart AND @FQSAppDateEnd
				AND
				(DD.sType = 'SP' AND (DD.sTeam IS NULL OR DD.sTeam = 'W')) 

			--Overwriting contributors 
			DROP TABLE IF EXISTS #NewFQSOverwrite
			 
			SELECT 
				U.nDistributorID AS PK_Distributor,
				D.nDistributorID AS PK_DSDownLine,
				o.ContributionMonth AS ApplicationDate,
				MAX(CONVERT(int,o.Active)) AS [Active]
			INTO #NewFQSOverwrite
			FROM [dbo].[WRK_25006_NAMPT_NEWFQS_Overwrite] AS o
				INNER JOIN v_Distributor AS U
					ON o.UL_DistributorID = U.sDistributorID
				INNER JOIN v_Distributor AS D
					ON o.DL_DistributorID = D.sDistributorID				 
			GROUP BY U.nDistributorID,
					D.nDistributorID,
					o.ContributionMonth 

				MERGE #NewFQS AS t
				USING #NewFQSOverwrite  AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active);

			-- Freezing contributors							
			IF @IsDevQA = 0
			BEGIN

				MERGE [dbo].[WRK_25006_NewFQSBonusContributors] AS t
				USING #NewFQS AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate); 
				
				UPDATE t
				SET Active = s.Active
				FROM [dbo].[WRK_25006_NewFQSBonusContributors] AS t
					INNER JOIN #NewFQSOverwrite AS s
						ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate

				--Add contributor by report : Not applicable

	 			--// Getting contributors per month
				INSERT INTO #NewFQSPerMonth(PK_Distributor,ApplicationDate,[TotalNewFQS],[TotalBonusNewFQS])
				SELECT 
					F.PK_Distributor,
					F.ApplicationDate,
					SUM([ContributionCount]) AS [TotalNewFQS],
					(SUM([ContributionCount]) * 2000) AS [TotalBonusNewFQS]
				FROM [dbo].[WRK_25006_NewFQSBonusContributors]  AS F WITH (NOLOCK)
				WHERE F.Active = 1
				GROUP BY F.PK_Distributor,F.ApplicationDate

				 
			END
			ELSE IF @IsDevQA = 3
			BEGIN
							
				MERGE [dbo].[##WRK_25006_NewFQSBonusContributors] AS t
				USING #NewFQS AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate); 
	 
				--Add contributor by report: Not Applicable

	 			--// Getting contributors per month
				INSERT INTO #NewFQSPerMonth(PK_Distributor,ApplicationDate,[TotalNewFQS],[TotalBonusNewFQS])
				SELECT 
					F.PK_Distributor,
					F.ApplicationDate,
					SUM([ContributionCount]) AS [TotalNewFQS],
					(SUM([ContributionCount]) * 2000) AS [TotalBonusNewFQS]
				FROM [dbo].[##WRK_25006_NewFQSBonusContributors]  AS F WITH (NOLOCK)
				WHERE F.Active = 1
				GROUP BY F.PK_Distributor,F.ApplicationDate
				 
			END

			--// Getting totals per Distributor
			INSERT INTO #NewFQSSummary(PK_Distributor,[TotalNewFQS],[TotalBonusNewFQS])
			SELECT 
				PK_Distributor,
				SUM(TotalNewFQS) [TotalNewFQS],
				SUM(TotalBonusNewFQS) [TotalBonusNewFQS]
			FROM #NewFQSPerMonth WITH (NOLOCK)
			GROUP BY PK_Distributor


		/******************************************************************************
			New ASP Bonus Promotion
		******************************************************************************/

		--New ASP Bonus Variables
		DECLARE 
			@RecognitionMonthStart INT  = 202402 -- Vol Month Start
			,@RecognitionMonthEnd INT = 202501 -- Vol Month End
			,@QualifiersLevelSubEvents VARCHAR(10) = '1'
			,@ASPPromoID INT = 36884 

			-- Setting up temp tables

			DROP TABLE IF EXISTS #NewASPPerMonth

			CREATE TABLE #NewASPPerMonth
			(
				PK_Distributor INT,
				ApplicationDate INT,
				[TotalNewASP] INT,
				[TotalBonusNewASP] MONEY
			)

			DROP TABLE IF EXISTS #NewASPSummary

			CREATE TABLE #NewASPSummary
			(
				PK_Distributor INT,
				[TotalNewASP] INT,
				[TotalBonusNewASP] MONEY
			)		


			IF @IsDevQA = 0 AND NOT EXISTS (SELECT 1 FROM sys.objects WITH (NOLOCK) WHERE name='WRK_25006_NewASPBonusContributors' and type='U')
			BEGIN
				CREATE TABLE [dbo].[WRK_25006_NewASPBonusContributors] 
				(
					[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
					PK_Distributor BIGINT,
					PK_DSDownLine  BIGINT,
					ApplicationDate INT,
					[ContributionCount] INT DEFAULT (1),
					[Active] BIT DEFAULT 1
				)
			END
			ELSE
			IF @IsDevQA = 3 AND OBJECT_ID('tempdb.dbo.##WRK_25006_NewASPBonusContributors') IS NULL  
			BEGIN
				CREATE TABLE [dbo].[##WRK_25006_NewASPBonusContributors] 
				(
					[CreatedDate] DATETIME DEFAULT GETUTCDATE(),
					PK_Distributor BIGINT,
					PK_DSDownLine  BIGINT,
					ApplicationDate INT,
					[ContributionCount] INT DEFAULT (1),
					[Active] BIT DEFAULT 1
				)

				INSERT INTO [dbo].[##WRK_25006_NewASPBonusContributors]([CreatedDate],PK_Distributor,PK_DSDownLine,ApplicationDate,[Active])
				SELECT [CreatedDate],PK_Distributor,PK_DSDownLine,ApplicationDate,[Active] FROM [dbo].[WRK_25006_NewASPBonusContributors] WITH (NOLOCK)

				UPDATE [dbo].[##WRK_25006_NewASPBonusContributors]
				SET Active = 1

			END	

			--// Getting contributors				
			DROP TABLE IF EXISTS #NewASP 

			;WITH cte_ASPQualifiers AS
			(
				SELECT DISTINCT PK_Distributor,DateQualified
				FROM [pubeventmanagement].[Promo].[DSSubEvent] AS d WITH (NOLOCK)
					INNER JOIN ( SELECT [value] AS [SubEvent] FROM STRING_SPLIT(@QualifiersLevelSubEvents, ',')  ) AS se
						ON d.SubEvent = se.SubEvent
				WHERE PK_Event = @ASPPromoID AND DateQualified  BETWEEN  @RecognitionMonthStart AND @RecognitionMonthEnd
			), cte_ASPPrevQualifiers AS
			( 
				SELECT DISTINCT PK_Distributor,DateQualified
				FROM [pubeventmanagement].[Promo].[DSSubEvent] AS d WITH (NOLOCK)
					INNER JOIN ( SELECT [value] AS [SubEvent] FROM STRING_SPLIT(@QualifiersLevelSubEvents, ',')  ) AS se
						ON d.SubEvent = se.SubEvent
				WHERE PK_Event = @ASPPromoID AND DateQualified < @RecognitionMonthStart 
		 	) 

			SELECT DISTINCT
				DLS.PK_DSDownLine,
				DLS.PK_Distributor,
				M.DateQualified AS ApplicationDate,
				1 AS [Active]
			INTO #NewASP
			FROM #DSDownlinesSummary AS DLS
			INNER JOIN cte_ASPQualifiers AS M
				ON DLS.PK_DSDownLine = M.PK_Distributor
			LEFT JOIN cte_ASPPrevQualifiers AS p
				ON M.PK_Distributor = p.PK_Distributor
			WHERE p.PK_Distributor IS NULL
	  
			--Overwriting contributors 

			DROP TABLE IF EXISTS #NewASPOverwrite

				SELECT 
					U.nDistributorID AS PK_Distributor,
					D.nDistributorID AS PK_DSDownLine,
					o.ContributionMonth AS ApplicationDate,
					 MAX(CONVERT(int,o.Active)) AS [Active]
				INTO #NewASPOverwrite
				FROM [dbo].[WRK_25006_NAMPT_NEWASP_Overwrite] AS o WITH (NOLOCK)
					INNER JOIN v_Distributor AS U
						ON o.UL_DistributorID = U.sDistributorID
					INNER JOIN v_Distributor AS D
						ON o.DL_DistributorID = D.sDistributorID
				GROUP BY U.nDistributorID,
					D.nDistributorID,
					o.ContributionMonth 
		 

				MERGE #NewASP AS t
				USING #NewASPOverwrite  AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate,Active)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate,Active);

			-- Freezing contributors							
			IF @IsDevQA = 0
			BEGIN

				MERGE [dbo].[WRK_25006_NewASPBonusContributors] AS t
				USING #NewASP AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate); 

				UPDATE t
				SET Active = s.Active
				FROM [dbo].[WRK_25006_NewASPBonusContributors] AS t
					INNER JOIN #NewASPOverwrite AS s
						ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate

				--Add contributor by report: Not Applicable

	 			--// Getting contributors per month
				INSERT INTO #NewASPPerMonth(PK_Distributor,ApplicationDate,[TotalNewASP],[TotalBonusNewASP])
				SELECT 
					F.PK_Distributor,
					F.ApplicationDate,
					SUM([ContributionCount]) AS [TotalNewASP],
					(SUM([ContributionCount]) * 7500) AS [TotalBonusNewASP]
				FROM [dbo].[WRK_25006_NewASPBonusContributors]  AS F WITH (NOLOCK)
				WHERE F.Active = 1
				GROUP BY F.PK_Distributor,F.ApplicationDate
				 
			END
			ELSE IF @IsDevQA = 3
			BEGIN
							
				MERGE [dbo].[##WRK_25006_NewASPBonusContributors] AS t
				USING #NewASP AS s
				ON t.PK_Distributor = s.PK_Distributor AND t.PK_DSDownLine = s.PK_DSDownLine AND t.ApplicationDate = s.ApplicationDate
				WHEN NOT MATCHED
					THEN INSERT (PK_Distributor, PK_DSDownLine, ApplicationDate)
							VALUES (s.PK_Distributor, s.PK_DSDownLine, s.ApplicationDate);
	 
				--Add contributor by report: Not Applicable
	 			
				--// Getting contributors per month
				INSERT INTO #NewASPPerMonth(PK_Distributor,ApplicationDate,[TotalNewASP],[TotalBonusNewASP])
				SELECT 
					F.PK_Distributor,
					F.ApplicationDate,
					SUM([ContributionCount]) AS [TotalNewASP],
					(SUM([ContributionCount]) * 7500) AS [TotalBonusNewASP]
				FROM [dbo].[##WRK_25006_NewASPBonusContributors]  AS F WITH (NOLOCK)
				WHERE F.Active = 1
				GROUP BY F.PK_Distributor,F.ApplicationDate
				 
			END


			--// Getting totals per Distributor
			INSERT INTO #NewASPSummary(PK_Distributor,[TotalNewASP],[TotalBonusNewASP])
			SELECT 
				PK_Distributor,
				SUM(TotalNewASP) [TotalNewASP],
				SUM(TotalBonusNewASP) [TotalBonusNewASP]
			FROM #NewASPPerMonth WITH (NOLOCK)
			GROUP BY PK_Distributor


		/******************************************************************************
			Mergin temp members tables DS, FQS, ASP and PM
		******************************************************************************/
							
		IF @IsDevQA = 0 
		BEGIN
			DROP TABLE IF EXISTS [dbo].[WRK_25006_NewMemberPerMonth]

			;WITH cte_DS AS
			(
				SELECT PK_Distributor,ApplicationDate 
				FROM #NewDSPerMonth
				UNION 
				SELECT PK_Distributor,ApplicationDate 
				FROM #NewPMPermonth
				UNION 
				SELECT PK_Distributor,ApplicationDate   
				FROM #NewFQSPermonth
				UNION 
				SELECT PK_Distributor,ApplicationDate
				FROM #NewASPPermonth
			)
			 SELECT 
				ds.PK_Distributor,
				ds.ApplicationDate,
				ISNULL(TotalNewDS,0) AS TotalNewDS,
				ISNULL(TotalBonusNewDS,0) AS TotalBonusNewDS,
				ISNULL(TotalNewPM,0) AS TotalNewPM,
				ISNULL(TotalBonusNewPM,0) AS TotalBonusNewPM,
				ISNULL(TotalNewFQS,0) AS TotalNewFQS,
				ISNULL(TotalBonusNewFQS,0) AS TotalBonusNewFQS,
				ISNULL(TotalNewASP,0) AS TotalNewASP,
				ISNULL(TotalBonusNewASP,0) AS TotalBonusNewASP 
			INTO [dbo].[WRK_25006_NewMemberPerMonth] 
			 FROM cte_DS AS ds
				LEFT JOIN #NewDSPerMonth AS d
					ON ds.PK_Distributor = d.PK_Distributor AND ds.ApplicationDate = d.ApplicationDate
				LEFT JOIN #NewPMPermonth AS p
					ON ds.PK_Distributor = p.PK_Distributor AND ds.ApplicationDate = p.ApplicationDate
				LEFT JOIN #NewFQSPermonth AS f
					ON ds.PK_Distributor = f.PK_Distributor AND ds.ApplicationDate = f.ApplicationDate
				LEFT JOIN #NewASPPermonth AS a
					ON ds.PK_Distributor = a.PK_Distributor AND ds.ApplicationDate = a.ApplicationDate
			 
		END
		ELSE IF @IsDevQA = 3
		BEGIN
			DROP TABLE IF EXISTS ##WRK_25006_NewMemberPerMonth

			;WITH cte_DS AS
			(
				SELECT PK_Distributor,ApplicationDate 
				FROM #NewDSPerMonth
				UNION  
				SELECT PK_Distributor,ApplicationDate 
				FROM #NewPMPermonth
				UNION  
				SELECT PK_Distributor,ApplicationDate   
				FROM #NewFQSPermonth
				UNION  
				SELECT PK_Distributor,ApplicationDate
				FROM #NewASPPermonth
			)
			 
			 SELECT 
				ds.PK_Distributor,
				ds.ApplicationDate,
				ISNULL(TotalNewDS,0) AS TotalNewDS,
				ISNULL(TotalBonusNewDS,0) AS TotalBonusNewDS,
				ISNULL(TotalNewPM,0) AS TotalNewPM,
				ISNULL(TotalBonusNewPM,0) AS TotalBonusNewPM,
				ISNULL(TotalNewFQS,0) AS TotalNewFQS,
				ISNULL(TotalBonusNewFQS,0) AS TotalBonusNewFQS,
				ISNULL(TotalNewASP,0) AS TotalNewASP,
				ISNULL(TotalBonusNewASP,0) AS TotalBonusNewASP 
			INTO ##WRK_25006_NewMemberPerMonth
			 FROM #MBIDs as MB 
				INNER JOIN cte_DS AS ds
					ON MB.PK_Distributor = ds.PK_Distributor
				LEFT JOIN #NewDSPerMonth AS d
					ON ds.PK_Distributor = d.PK_Distributor AND ds.ApplicationDate = d.ApplicationDate
				LEFT JOIN #NewPMPermonth AS p
					ON ds.PK_Distributor = p.PK_Distributor AND ds.ApplicationDate = p.ApplicationDate
				LEFT JOIN #NewFQSPermonth AS f
					ON ds.PK_Distributor = f.PK_Distributor AND ds.ApplicationDate = f.ApplicationDate
				LEFT JOIN #NewASPPermonth AS a
					ON ds.PK_Distributor = a.PK_Distributor AND ds.ApplicationDate = a.ApplicationDate

		END


		/******************************************************************************
			Bonus per month
		******************************************************************************/

		IF @IsDevQA = 0 
		BEGIN	

			INSERT INTO [dbo].[#WRK_25006_BonusPerMonth]
			SELECT 
				D.PK_Distributor,
				DS.ApplicationDate,
				SUM(ISNULL(DS.[TotalBonusNewDS],0)) AS [Total DS Bonus],
				SUM(ISNULL(DS.[TotalNewDS],0)) AS [Total New DS],
				SUM(ISNULL(DS.[TotalBonusNewPM],0)) AS [Total PM Bonus],
				SUM(ISNULL(DS.[TotalNewPM],0)) AS [Total New PM],
				SUM(ISNULL(DS.[TotalBonusNewFQS],0)) AS [Total FQS Bonus],
				SUM(ISNULL(DS.[TotalNewFQS],0)) AS [Total New FQS],
				SUM(ISNULL(DS.[TotalBonusNewASP],0)) AS [Total ASP Bonus],
				SUM(ISNULL(DS.[TotalNewASP],0)) AS [Total New ASP]
			FROM #MBIDs AS D	
				LEFT JOIN [dbo].[WRK_25006_NewMemberPerMonth] AS DS (NOLOCK)
					ON D.PK_Distributor = DS.PK_Distributor		
								 		
			GROUP BY  D.PK_Distributor,DS.ApplicationDate

			CREATE INDEX IX_#WRK_25006_BonusPerMonth_PK_Distributor ON #WRK_25006_BonusPerMonth(PK_Distributor)
		END
		ELSE IF @IsDevQA = 3
		BEGIN
			INSERT INTO [dbo].[#WRK_25006_BonusPerMonth]
			SELECT 
				D.PK_Distributor,
				DS.ApplicationDate,
				SUM(ISNULL(DS.[TotalBonusNewDS],0)) AS [Total DS Bonus],
				SUM(ISNULL(DS.[TotalNewDS],0)) AS [Total New DS],
				SUM(ISNULL(DS.[TotalBonusNewPM],0)) AS [Total PM Bonus],
				SUM(ISNULL(DS.[TotalNewPM],0)) AS [Total New PM],
				SUM(ISNULL(DS.[TotalBonusNewFQS],0)) AS [Total FQS Bonus],
				SUM(ISNULL(DS.[TotalNewFQS],0)) AS [Total New FQS],
				SUM(ISNULL(DS.[TotalBonusNewASP],0)) AS [Total ASP Bonus],
				SUM(ISNULL(DS.[TotalNewASP],0)) AS [Total New ASP]
			FROM #MBIDs AS D	
				LEFT JOIN [dbo].[##WRK_25006_NewMemberPerMonth] AS DS  
					ON D.PK_Distributor = DS.PK_Distributor		
								 		
			GROUP BY  D.PK_Distributor,DS.ApplicationDate

			CREATE INDEX IX_#WRK_25006_BonusPerMonth_PK_Distributor ON #WRK_25006_BonusPerMonth(PK_Distributor)
		END

		/******************************************************************************
			Bonus Summary
		******************************************************************************/							

		DROP TABLE IF EXISTS #WRK_25006_BonusSummary

		SELECT 
			PK_Distributor,
			SUM(ISNULL([Total DS Bonus],0)) AS [Total DS Bonus],
			SUM(ISNULL([Total New DS],0)) AS [Total New DS],
			SUM(ISNULL([Total PM Bonus],0)) AS [Total PM Bonus],
			SUM(ISNULL([Total New PM],0)) AS [Total New PM],
			SUM(ISNULL([Total FQS Bonus],0)) AS [Total FQS Bonus],
			SUM(ISNULL([Total New FQS],0)) AS [Total New FQS],
			SUM(ISNULL([Total ASP Bonus],0)) AS [Total ASP Bonus],
			SUM(ISNULL([Total New ASP],0)) AS [Total New ASP]
		INTO #WRK_25006_BonusSummary
		FROM #WRK_25006_BonusPerMonth			 		
		GROUP BY PK_Distributor	

		CREATE INDEX IX_#WRK_25006_BonusSummary_PK_Distributor ON #WRK_25006_BonusSummary(PK_Distributor)

	/******************************************************************************
		UPDATE Bonus Promotions in #MBIDs
	******************************************************************************/


	UPDATE
		T
	SET	 
		T.[New DS Bonus] = WBS.[Total DS Bonus],
		T.[New PM Bonus] = WBS.[Total PM Bonus],
		T.[New SP Bonus] = WBS.[Total FQS Bonus],
		T.[New ASP Bonus] = WBS.[Total ASP Bonus]
	FROM
		#MBIDs T
		LEFT JOIN #WRK_25006_BonusSummary WBS ON T.PK_Distributor = WBS.PK_Distributor	


	/******************************************************************************
		UPDATE Double March Bonus Promotion in #MBIDs
	******************************************************************************/

	-- FQS BONUS 
	UPDATE
		T
	SET	 
		T.[Double March Bonus] = (WBPM.[Total FQS Bonus])
	FROM
		#MBIDs T
		LEFT JOIN #WRK_25006_BonusPerMonth WBPM ON T.PK_Distributor = WBPM.PK_Distributor	
		WHERE 
			WBPM.ApplicationDate = 202404
	
	-- PM AND DS BONUS 
	UPDATE
		T
	SET	 
		T.[Double March Bonus] = T.[Double March Bonus] + (WBPM.[Total DS Bonus] + WBPM.[Total PM Bonus])
	FROM
		#MBIDs T
		LEFT JOIN #WRK_25006_BonusPerMonth WBPM ON T.PK_Distributor = WBPM.PK_Distributor	
		WHERE 
			WBPM.ApplicationDate = 202403

	-- ASP BONUS
	UPDATE
		T
	SET	 
		T.[Double March Bonus] = T.[Double March Bonus] + (WBPM.[Total ASP Bonus]) 
	FROM
		#MBIDs T
		LEFT JOIN #WRK_25006_BonusPerMonth WBPM ON T.PK_Distributor = WBPM.PK_Distributor	
		WHERE 
			WBPM.ApplicationDate = 202406
						
/*****************************************************  
	Update IsNewPT & PTQualDate Column on #MBIDs
******************************************************/
;WITH cte_PTs (PK_Distributor, QualDate)
AS (
	SELECT DISTINCT M.PK_Distributor,MIN(H.dFrom)  
	 FROM #MBIDs M  
	 INNER JOIN dbo.v_DistributorHistory H 
		ON M.PK_Distributor = H.nDistributorIDFK 
		AND (H.nEventTypeLID BETWEEN 229 AND 241 OR H.nEventTypeLID >= 271 AND H.nEventTypeLID <= 300)
	 WHERE 
		H.dThrough = '2049-12-31' 
		AND H.dFrom BETWEEN '2024-02-01' AND '2025-01-01'
		GROUP BY M.PK_Distributor
)													 
		
 UPDATE A
 SET A.IsNewPT = 1
	,A.PTQualDate = CP.QualDate
 FROM #MBIDs A
 INNER JOIN cte_PTs  CP
	ON A.PK_Distributor = CP.PK_Distributor


/******************************************************************************
	DELETE MainIDs - Dequalify all MainIDs because of divorce
******************************************************************************/

DELETE D FROM #MBIDs D 
INNER JOIN #wrk_T1 x ON x.PK_Distributor = D.PK_Distributor 


/******************************************************************************
	INSERT #EventQual
******************************************************************************/


INSERT INTO #EventQual(
	PK_Event,
	PK_Distributor,
	CreatedDate,
	UpdatedDate
	)
SELECT 
	@PK_Event,
	B.PK_Distributor INT,
	GETUTCDATE() AS CreatedDate,
	GETUTCDATE() AS UpdatedDate
FROM	
	#MBIDs B

CREATE INDEX IX_#EventQual_PK_Distributor ON #EventQual(PK_Distributor)


/******************************************************************************
	UPDATE Sub Events
******************************************************************************/

UPDATE A
SET 
A.Q01 = IIF(CurrentTeam IN ('P','A','B','C') AND IsNewPT = 0,1,0),
A.Q02 = C.IsNewPT,
A.Q03 = CASE WHEN	C.TotalTVP				>= 40000															THEN 1 ELSE 0 END,
A.Q04 = CASE WHEN	C.TotalTVP + C.TotalRO + C.[New DS Bonus] + C.[New SP Bonus] + C.[New ASP Bonus]  + C.[New PM Bonus] + [Double March Bonus] >= 200000	THEN 1 ELSE 0 END,
A.Q05 =  ISNULL((SELECT 1 FROM #List WHERE nTypeLID = 62181 AND PK_Distributor = C.PK_Distributor),0),
A.Q06 =  ISNULL((SELECT 1 FROM #List WHERE nTypeLID = 62431 AND PK_Distributor = C.PK_Distributor),0)
FROM
	#EventQual A
INNER JOIN  
	#MBIDs C
ON 
	A.PK_Distributor = C.PK_Distributor


UPDATE 
	A
SET
	E01 = (Q02 | Q05 | ((Q01 | Q06) & (Q03 & Q04))),
	E02 = (Q02 | Q05)
FROM 
	#EventQual A


DELETE FROM #EventQual
WHERE (
		~Q01 & ~Q02 & ~Q03 & ~Q04 & ~Q05 & ~Q06 & ~Q07 & ~Q08 & ~Q09 & ~Q10 & 
		~Q11 & ~Q12 & ~Q13 & ~Q14 & ~Q15 & ~Q16 & ~Q17 & ~Q18 & ~Q19 & ~Q20 &
		~Q21 & ~Q22 & ~Q23 & ~Q24 & ~Q25 & ~Q26 & ~Q27 & ~Q28 & ~Q29 & ~Q30 & 
		~Q31 & ~Q32 & ~Q33 & ~Q34 & ~Q35 & ~Q36 & ~Q37 & ~Q38 & ~Q39 & ~Q40 &
		~Q41 & ~Q42 & ~Q43 & ~Q44 & ~Q45 & ~Q46 & ~Q47 & ~Q48 & ~Q49 & ~Q50 
		)= 1
				
			--WRK_NAMPTVacation_2025
			DROP TABLE IF EXISTS dbo.WRK_NAMPTVacation_2025 

			SELECT 
				 PK_Distributor				
				,DistributorID				
				,sMainDistributorID														   
				,CurrentTeam				
				,SubTeam					
				,DSPTeam					
				,sCountryCode				
				,QSQualDate					
				,SPQualDate					
				,HasTicket					
				,IsNewPT
				,PTQualDate	
				,TVPJan24	        
				,TVPFeb24	        
				,TVPMar24	        
				,TVPApr24	        
				,TVPMay24	        
				,TVPJun24	        
				,TVPJul24	        
				,TVPAug24	        
				,TVPSep24	        
				,TVPOct24	        
				,TVPNov24	        
				,TVPDec24	        
				,ROJan24	        
				,ROFeb24	        
				,ROMar24	        
				,ROApr24	        
				,ROMay24	        
				,ROJun24	        
				,ROJul24	        
				,ROAug24	        
				,ROSep24	        
				,ROOct24	        
				,RONov24	        
				,RODec24								
				,TotalTVP					
				,TotalRO					
				,[New DS Bonus]
				,[New PM Bonus]		
				,[New SP Bonus]	
				,[New ASP Bonus]	
				,[Double March Bonus]
			INTO dbo.WRK_NAMPTVacation_2025  
			FROM #MBIDs
						
			CREATE INDEX [IX_WRK_NAMPTVacation_2025_PK_Distributor] ON [dbo].[WRK_NAMPTVacation_2025] ([PK_Distributor])
			
			--WRK_EventQual
			IF OBJECT_ID('WRK_EventQual', 'U') IS NOT NULL DROP TABLE dbo.WRK_EventQual 
					
			SELECT
				PK_Event		
				,PK_Distributor	
				,CreatedDate	
				,UpdatedDate	
				,Q01,Q02,Q03,Q04,Q05
				,Q06,Q07,Q08,Q09,Q10
				,Q11,Q12,Q13,Q14,Q15
				,Q16,Q17,Q18,Q19,Q20
				,Q21,Q22,Q23,Q24,Q25
				,Q26,Q27,Q28,Q29,Q30
				,Q31,Q32,Q33,Q34,Q35
				,Q36,Q37,Q38,Q39,Q40			
				,Q41,Q42,Q43,Q44,Q45			
				,Q46,Q47,Q48,Q49,Q50
				
				,E01,E02,E03,E04,E05			
				,E06,E07,E08,E09,E10			
				,E11,E12,E13,E14,E15			
				,E16,E17,E18,E19,E20			
				,E21,E22,E23,E24,E25			
				,E26,E27,E28,E29,E30			
				,E31,E32,E33,E34,E35			
				,E36,E37,E38,E39,E40
				,E41,E42,E43,E44,E45
				,E46,E47,E48,E49,E50
				INTO dbo.WRK_EventQual FROM #EventQual 

				CREATE CLUSTERED INDEX [IX_WRK_EventQual_PK_Distributor] ON [dbo].[WRK_EventQual] ([PK_Distributor])


				DELETE dq			
				FROM [Event].[DSQual] AS dq
				WHERE PK_Event = @PK_Event

				DROP INDEX IF EXISTS [IX_Event_DSQual_PK_Distributor_PK_Event]
				ON [Event].[DSQual];

				INSERT INTO [Event].[DSQual](
				PK_Event		
				,PK_Distributor	
				,CreatedDate	
				,UpdatedDate	
				,Q01,Q02,Q03,Q04,Q05
				,Q06,Q07,Q08,Q09,Q10
				,Q11,Q12,Q13,Q14,Q15
				,Q16,Q17,Q18,Q19,Q20
				,Q21,Q22,Q23,Q24,Q25
				,Q26,Q27,Q28,Q29,Q30
				,Q31,Q32,Q33,Q34,Q35
				,Q36,Q37,Q38,Q39,Q40			
				,Q41,Q42,Q43,Q44,Q45			
				,Q46,Q47,Q48,Q49,Q50
				
				,E01,E02,E03,E04,E05			
				,E06,E07,E08,E09,E10			
				,E11,E12,E13,E14,E15			
				,E16,E17,E18,E19,E20			
				,E21,E22,E23,E24,E25			
				,E26,E27,E28,E29,E30			
				,E31,E32,E33,E34,E35			
				,E36,E37,E38,E39,E40
				,E41,E42,E43,E44,E45
				,E46,E47,E48,E49,E50
				)
				SELECT
				PK_Event		
				,PK_Distributor	
				,CreatedDate	
				,UpdatedDate	
				,Q01,Q02,Q03,Q04,Q05
				,Q06,Q07,Q08,Q09,Q10
				,Q11,Q12,Q13,Q14,Q15
				,Q16,Q17,Q18,Q19,Q20
				,Q21,Q22,Q23,Q24,Q25
				,Q26,Q27,Q28,Q29,Q30
				,Q31,Q32,Q33,Q34,Q35
				,Q36,Q37,Q38,Q39,Q40			
				,Q41,Q42,Q43,Q44,Q45			
				,Q46,Q47,Q48,Q49,Q50
				
				,E01,E02,E03,E04,E05			
				,E06,E07,E08,E09,E10			
				,E11,E12,E13,E14,E15			
				,E16,E17,E18,E19,E20			
				,E21,E22,E23,E24,E25			
				,E26,E27,E28,E29,E30			
				,E31,E32,E33,E34,E35			
				,E36,E37,E38,E39,E40
				,E41,E42,E43,E44,E45
				,E46,E47,E48,E49,E50
				FROM #EventQual

		CREATE INDEX [IX_Event_DSQual_PK_Distributor_PK_Event] ON [Event].[DSQual](PK_Distributor) INCLUDE(PK_Event);
 
		EXEC [Shared].[usp_EventPromo_UpdateSubEventQualifier]
		@Events = @PK_Event,
		@Source = 2,
		@EvaluateFormula = 0


/******************************************************************************
	DROP THE TEMP TABLE BEFORE ENDING THE PROCEDURE
******************************************************************************/
IF @isDevQA = 0
BEGIN
	IF OBJECT_ID('tempdb..#EventQual')		IS NOT NULL DROP TABLE #EventQual												 							   																   
	IF OBJECT_ID('tempDB..#MBIDs')			IS NOT NULL DROP TABLE #MBIDs																  
	IF OBJECT_ID('tempdb..#MBIDsPoints')	IS NOT NULL DROP TABLE #MBIDsPoints

	TRUNCATE TABLE [tmp].[DS] 	
	TRUNCATE TABLE [tmp].[DSQualDef]
	TRUNCATE TABLE [tmp].[DSPointsSummary]
	TRUNCATE TABLE [tmp].[DSForConversionEvaluation]
	TRUNCATE TABLE [tmp].[MemberLastestConversion]

	DROP TABLE IF EXISTS #wrk_T1  
	DROP TABLE IF EXISTS ##tmp_DS_jgue  
	DROP TABLE IF EXISTS ##Event_DSPoints_jgue  
	DROP TABLE IF EXISTS ##Event_SetupEventQualification_jgue  
	DROP TABLE IF EXISTS #Event_SetupEventQualification  
	DROP TABLE IF EXISTS #tmp_DS  
	DROP TABLE IF EXISTS #Event_DSPoints  
	DROP TABLE IF EXISTS #DSDownlines  
	DROP TABLE IF EXISTS #DSAssociatedDownlines  
	DROP TABLE IF EXISTS #DSDownlinesSummary  
	DROP TABLE IF EXISTS ##tmp_DSForConversionEvaluation  
	DROP TABLE IF EXISTS #MemberLastestConversionResult 
	DROP TABLE IF EXISTS #DownlineApplicationDateEval 
	DROP TABLE IF EXISTS ##WRK_25006_DSDownlines 
	DROP TABLE IF EXISTS #Event_DownlinesPoints 
	DROP TABLE IF EXISTS #DSDownlinesPeriod
	DROP TABLE IF EXISTS #NewDSPerMonth
	DROP TABLE IF EXISTS #NewDSSSummary
	DROP TABLE IF EXISTS ##WRK_25006_NewDSBonusContributors
	DROP TABLE IF EXISTS #NewDS
	DROP TABLE IF EXISTS #PMDownlinesPeriod
	DROP TABLE IF EXISTS #NewPMPerMonth
	DROP TABLE IF EXISTS #NewPMSummary
	DROP TABLE IF EXISTS ##WRK_25006_NewPMBonusContributors
	DROP TABLE IF EXISTS #NewPM
	DROP TABLE IF EXISTS #NewFQSPerMonth
	DROP TABLE IF EXISTS #NewFQSSummary
	DROP TABLE IF EXISTS ##WRK_25006_NewFQSBonusContributors
	DROP TABLE IF EXISTS #NewFQS
	DROP TABLE IF EXISTS #NewASPPerMonth
	DROP TABLE IF EXISTS #NewASPSummary
	DROP TABLE IF EXISTS ##WRK_25006_NewASPBonusContributors
	DROP TABLE IF EXISTS #NewASP 
	DROP TABLE IF EXISTS #WRK_25006_BonusPerMonth 
	DROP TABLE IF EXISTS #WRK_25006_BonusSummary 
	DROP TABLE IF EXISTS ##WRK_25006_NewMemberPerMonth
END


	-- Update processing Log
	EXEC [dbo].[usp_Utility_UpdateProcessingLog]
			@StoredProcedureName = @StoredProcedure
			,@StartTime = @StartTime;
	
END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 3 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;