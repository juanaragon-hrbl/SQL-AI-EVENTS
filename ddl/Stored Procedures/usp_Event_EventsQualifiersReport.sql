CREATE PROCEDURE [dbo].[usp_Event_EventsQualifiersReport]
		--OPTIONAL
		@Error	int = 0 OUTPUT,
	    @ErrorMessage varchar(4000) = NULL OUTPUT,
		@IsDevQA tinyint = 0
	
AS
BEGIN
-- =======================================================================================
-- Author:		Jair Lira Garcia
-- Create date: October 10th,2025
-- Object:      usp_Event_EventsQualifiersReport   
-- Use:         EXEC dbo.usp_Event_EventsQualifiersReport 
-- Description:	Get Events Qualifiers Report information 
-- Parameters :  
--               @Error  OUT Error number
--               @ErrorMessage OUT Error message
--              QA/DEV
--       	     @IsDevQA tinyint = 0 
--------------------------------------------------------------------
--    VERSIONS
--------------------------------------------------------------------
--    1.0.0       2025-10-10      Jair Lira        Initial
--    1.1.0       2026-01-26      jairli           Removing dstype filter
--    1.2.0       2026-07-07      jairli           Adding Merge just for Active Events(Performance)
-- ========================================================================================

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @StoredProcedure varchar(255) = 'usp_Event_EventsQualifiersReport'
	,@StartTime datetime2 = GETUTCDATE();

	SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	IF (@IsDevQA = 2)
	BEGIN
		SELECT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END

DROP TABLE IF EXISTS #TimeLog;  

		CREATE TABLE #TimeLog(
			[Milestone]		varchar(255)
		   ,[Step]	tinyint
		   ,[StepStart]	datetime2
		   ,[Duration]		int
		);

/******************************************************************************
	Select Available Events
******************************************************************************/
INSERT INTO #TimeLog VALUES ('Creating Events temp table', 1, GETUTCDATE(), NULL);

IF OBJECT_ID('tempdb..#Event') IS NOT NULL DROP TABLE #Event
CREATE TABLE #Event  (
    [PK_Event] 	[INT] NOT NULL
)

CREATE INDEX IX_tEvent_PK_Event ON #Event(PK_Event);

INSERT INTO #Event(PK_Event)
SELECT DISTINCT E.PK_Event 
FROM dbo.[Event] E WITH (NOLOCK)    
INNER JOIN [dbo].[EventExtn] AS EX WITH (NOLOCK)
		ON E.PK_Event = EX.PK_Event
INNER JOIN dbo.[EventSchedule] AS ES WITH (NOLOCK)
		ON E.PK_Event = ES.PK_Event	 AND es.PK_Schedule = 6
WHERE CAST(dEndUTC  AS DATE) >=  CAST(GETUTCDATE() AS DATE)
	AND EnableTesting = 0
	AND EventName NOT LIKE '%est%'
	AND EventDesc NOT LIKE '%est%'
	AND E.PK_Event IS NOT NULL;

UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [Step] = 1;

/******************************************************************************
	Select Event Tickets Purchasers
******************************************************************************/
INSERT INTO #TimeLog VALUES ('Creating Event Tickets Purchasers temp table', 2, GETUTCDATE(), NULL);

IF OBJECT_ID('tempdb..#EventTP') IS NOT NULL DROP TABLE #EventTP

CREATE TABLE #EventTP  (
    [PK_Distributor] 			[INT] NOT NULL ,	
	[PK_Event] 					[INT] NULL,
	[ORDERINFORMATION]			[VARCHAR] (MAX) NULL,
	[QUANTITY]					[INT] NULL,
	[PK_SUBEVENT]				[INT] NULL,
	[ISEVENTQUALIFIER]			[BIT] NULL
)

CREATE INDEX IX_tEventTP_PK_Events ON #EventTP(PK_Event);
CREATE INDEX IX_tEventTP_PK_Distributor ON #EventTP(PK_Distributor);
CREATE INDEX IX_tEventTP_PK_Distributor_PK_Event ON #EventTP(PK_Distributor,PK_Event);

INSERT #EventTP
   (PK_Distributor,	
	[PK_Event],
	[ORDERINFORMATION],
	[QUANTITY],
	[PK_SUBEVENT],
	[ISEVENTQUALIFIER]
	)
SELECT PK_Distributor, 
E.PK_Event,
ORDERINFORMATION  ,
QUANTITY  ,
PK_SUBEVENT  ,
CASE WHEN ISEVENTQUALIFIER <> 1 THEN 0 
		ELSE 1 
		END
FROM PubEvents.[dbo].[v_EventQualifiersTicketPurchasers] Q
INNER JOIN #Event E ON Q.PK_Event = E.PK_Event
WHERE NOT (DistributorId = '2222222222' AND Quantity = 0)
GROUP BY PK_DISTRIBUTOR, E.PK_Event, [ORDERINFORMATION], [QUANTITY],[PK_SUBEVENT],[ISEVENTQUALIFIER]

UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [Step] = 2;

/******************************************************************************
	Create EventsQualifiersReport temp table
******************************************************************************/
INSERT INTO #TimeLog VALUES ('Creating Qualifiers temp table', 3, GETUTCDATE(), NULL);

IF OBJECT_ID('tempdb..#EventsQualifiersReport') IS NOT NULL DROP TABLE #EventsQualifiersReport

CREATE TABLE #EventsQualifiersReport  (
    [PK_Subevent] 			[INT]  NULL ,
	[SubEventName] 			[VARCHAR] (200) NULL,
	[PK_Distributor] 		[INT] NULL,
	[DistributorId] 		[VARCHAR] (30) NULL,
	[FirstName]				[NVARCHAR] (150) NULL,
	[LastName] 				[NVARCHAR] (150) NULL,
	[PK_Country] 			[INT] NULL,
	[CountryCode] 			[VARCHAR] (2) NULL,
	[CountryName] 			[VARCHAR] (200) NULL,
	[PK_Region] 			[INT] NOT NULL,
	[RegionName] 			[VARCHAR] (100) NULL,
	[PK_DsTeam] 			[INT] NULL,
	[TeamDesc] 				[VARCHAR] (80) NULL,
	[PK_DsType] 			[INT] NULL,
	[TypeDesc] 				[VARCHAR] (30) NULL,
	[PK_Distributor0] 		[INT] NULL,
	[DistributorId0] 		[VARCHAR] (30) NULL,
	[FirstName0] 			[NVARCHAR] (150) NULL,
	[LastName0] 			[NVARCHAR] (150) NULL,
	[CustCol_32] 			[NVARCHAR] (300) NULL,
	[PK_Distributor1] 		[INT] NULL,
	[DistributorId1] 		[VARCHAR] (30) NULL,
	[FirstName1] 			[NVARCHAR] (150) NULL,
	[LastName1] 			[NVARCHAR] (150) NULL,
	[CustCol_33] 			[NVARCHAR] (300) NULL,
	[PK_DSContactInfo] 		[INT] NULL,
	[Address01] 			[NVARCHAR] (240) NULL,
	[Address02] 			[NVARCHAR] (240) NULL,
	[Address03] 			[NVARCHAR] (240) NULL,
	[Address04] 			[NVARCHAR] (240) NULL,
	[City] 					[NVARCHAR] (60) NULL,
	[County] 				[NVARCHAR] (60) NULL,
	[PostalCode] 			[NVARCHAR] (60) NULL,
	[State] 				[NVARCHAR] (60) NULL,
	[OrderInformation] 		[VARCHAR] (MAX) NULL,
	[Quantity] 				[INT] NULL,
	[IsTicketPurchaser] 	[BIT] NULL,
	[PK_Distributor2] 		[BIGINT] NULL,
	[DistributorId2] 		[VARCHAR] (30) NULL,
	[FirstName2] 			[NVARCHAR] (150) NULL,
	[LastName2] 			[NVARCHAR] (150) NULL,
	[CustCol_2] 			[NVARCHAR] (300) NULL,
	[DSSpouseFirstName] 	[NVARCHAR] (150) NULL,
	[DSSpouseLastName] 		[NVARCHAR] (150) NULL,
	[CustCol_3] 			[NVARCHAR] (300) NULL,
	[CellPhone2] 			[NVARCHAR] (200) NULL,
	[DayPhone2] 			[NVARCHAR] (200) NULL,
	[EvePhone2] 			[NVARCHAR] (200) NULL,
	[Email2] 				[NVARCHAR] (250) NULL,
	[PK_Event] 				[INT]  NULL,
	[EventName] 			[NVARCHAR] (200) NULL,
	[PK_Day] 				[INT] NULL,
	[SPQualDate] 			[DATETIME] NULL,
	[PK_Day2] 				[INT] NULL,
	[SPReQualDate] 			[DATETIME] NULL,
	[PK_DsSubType] 			[INT] NULL,
	[SubTypeCode] 			[VARCHAR] (5) NULL,
	[SubTypeDesc] 			[VARCHAR] (80) NULL,
	[PK_Day1] 				[INT] NULL,
	[DayDate9] 				[DATETIME] NULL,
	[PK_Language] 			[INT] NULL,
	[LanguageName] 			[VARCHAR] (100) NULL,
	[PK_Country0] 			[INT] NULL,
	[CountryName0] 			[VARCHAR] (200) NULL,
	[MainId] 				[VARCHAR] (30) NULL,
	[TeamQualDate] 			[DATETIME] NULL,
	[SubTeamQualDate] 		[DATETIME] NULL,
	[FirstTimeAwtYear] 		[INT] NULL,
	[IsEventQualifier] 		[INT] NULL,
	[EventQualified] 		[INT] NULL,
	[PK_Distributor_Mill] 	[INT] NULL,
	[DistributorId_Mill] 	[VARCHAR] (30) NULL,
	[FirstName_Mill] 		[NVARCHAR] (150) NULL,
	[LastName_Mill] 		[NVARCHAR] (150) NULL,
	[Name_Mill] 			[NVARCHAR] (300) NULL,
	[PK_Distributor_Tab] 	[INT] NULL,
	[DistributorId_Tab] 	[VARCHAR] (30) NULL,
	[FirstName_Tab] 		[NVARCHAR] (150) NULL,
	[LastName_Tab] 			[NVARCHAR] (150) NULL,
	[Name_Tab] 				[NVARCHAR] (300) NULL
)

CREATE INDEX IX_tEventsQualifiersReport_PK_Distributor2_PK_Event_PK_SubEvent ON #EventsQualifiersReport(PK_Distributor2 , PK_Event,PK_SubEvent );

UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [Step] = 3;
/******************************************************************************
	Insert Data on #EventsQualifiersReport Table
******************************************************************************/

INSERT INTO #TimeLog VALUES ('Getting temp table and prepare insert', 4, GETUTCDATE(), NULL);

;WITH V_DIMDISTRIBUTOR(PK_DISTRIBUTOR,DISTRIBUTORID, FIRSTNAME,LASTNAME)
AS
(SELECT DS.PK_DISTRIBUTOR, 
		DISTRIBUTORID,
		ISNULL(NULLIF(FirstName, ' '), 'Unknown') AS FirstName,
	    ISNULL(NULLIF(LastName, ' '), 'Unknown') AS LastName
	FROM PubEvents.dbo.dimDistributor DS (NOLOCK)
WHERE
	DS.PK_Distributor NOT IN (SELECT DL.PK_Distributor FROM DBLists.dbo.DSList D (NOLOCK) INNER JOIN DBLists.dbo.DSListDetail DL (NOLOCK) ON D.PK_DSList = DL.PK_DSList WHERE D.DSListName IN ('Test IDs','MSTR Reporting Exclude')) AND
	(DS.PK_DSType <>  (SELECT PK_DSType FROM PubEvents.dbo.dimDSType (NOLOCK) WHERE TypeCode = 'CS'))
UNION
SELECT DS.PK_DISTRIBUTOR, 
		DISTRIBUTORID,
		ISNULL(NULLIF(FirstName, ' '), 'Unknown') AS FirstName,
	    ISNULL(NULLIF(LastName, ' '), 'Unknown') AS LastName
	FROM PubEvents.dbo.dimDistributor DS (NOLOCK)
WHERE
	DS.PK_Distributor NOT IN (SELECT DL.PK_Distributor FROM DBLists.dbo.DSList D (NOLOCK) INNER JOIN DBLists.dbo.DSListDetail DL (NOLOCK) ON D.PK_DSList = DL.PK_DSList WHERE D.DSListName IN ('Test IDs','MSTR Reporting Exclude')) AND
	DS.PK_Distributor IN (1,2)
)
INSERT #EventsQualifiersReport
   (
		PK_Subevent,
		SubEventName,
		PK_Distributor,
		DistributorId,
		FirstName,
		LastName,
		PK_Country,
		CountryCode,
		CountryName,
		PK_Region,
		RegionName,
		PK_DsTeam,
		TeamDesc,
		PK_DsType,
		TypeDesc,
		PK_Distributor0,
		DistributorId0,
		FirstName0,
		LastName0,
		CustCol_32,
		PK_Distributor1,
		DistributorId1,
		FirstName1,
		LastName1,
		CustCol_33,
		PK_DSContactInfo,
		Address01,
		Address02,
		Address03,
		Address04,
		City,
		County,
		PostalCode,
		State,
		ORderInformation,
		Quantity,
		IsTicketPurchaser,
		PK_Distributor2,
		DistributorId2,
		FirstName2,
		LastName2,
		CustCol_2,
		DSSpouseFirstName,
		DSSpouseLastName,
		CustCol_3,
		CellPhone2,
		DayPhone2,
		EvePhone2,
		Email2,
		PK_Event,
		EventName,
		PK_Day,
		SPQualDate,
		PK_Day2,
		SPReQualDate,
		PK_DsSubType,
		SubTypeCode,
		SubTypeDesc,
		PK_Day1,
		DayDate9,
		PK_Language,
		LanguageName,
		PK_Country0,
		CountryName0,
		MainId,
		TeamQualDate,
		SubTeamQualDate,
		FirstTimeAwtYear,
		IsEventQualifier,
		EventQualified,
		PK_Distributor_Mill,
		DistributorId_Mill,
		FirstName_Mill,
		LastName_Mill,
		Name_Mill,
		PK_Distributor_Tab,
		DistributorId_Tab,
		FirstName_Tab,
		LastName_Tab,
		Name_Tab
   )


SELECT	
        a15.PK_SUBEVENT  PK_SUBEVENT,
		MAX(a16.SUBEVENTNAME)  SUBEVENTNAME,
		a18.FIRSTUPLINECC  PK_DISTRIBUTOR,
		MAX(a115.DISTRIBUTORID)  DISTRIBUTORID,
		MAX(a115.FIRSTNAME)  FIRSTNAME,
		MAX(a115.LASTNAME)  LASTNAME,
		a12.PK_COP  PK_COUNTRY,
		MAX(a128.COUNTRYCODE)  COUNTRYCODE,
		MAX(a128.COUNTRYNAME)  COUNTRYNAME,
		a111.PK_REGION  PK_REGION,
		MAX(a133.RegionName)  RegionName,
		a12.PK_DSTEAM  PK_DSTEAM,
		MAX(a134.TEAMDESC)  TEAMDESC,
		a112.PK_DSTYPE  PK_DSTYPE,
		MAX(a131.TYPEDESC)  TYPEDESC,
		a18.FIRSTUPLINEPRES  PK_DISTRIBUTOR0,
		MAX(a116.DISTRIBUTORID)  DISTRIBUTORID0,
		MAX(a116.FIRSTNAME)  FIRSTNAME0,
		MAX(a116.LASTNAME)  LASTNAME0,
		MAX(((UPPER(SUBSTRING(a116.LASTNAME, 1, 1)) + LOWER(SUBSTRING(a116.LASTNAME, 2, len(a116.LASTNAME) - 1))) + ' , ' + (UPPER(SUBSTRING(a116.FIRSTNAME, 1, 1)) + LOWER(SUBSTRING(a116.FIRSTNAME, 2, LEN(a116.FIRSTNAME) - 1)))))  CustCol_32,
		a18.FIRSTUPLINESP  PK_DISTRIBUTOR1,
		MAX(a117.DISTRIBUTORID)  DISTRIBUTORID1,
		MAX(a117.FIRSTNAME)  FIRSTNAME1,
		MAX(a117.LASTNAME)  LASTNAME1,
		MAX(((UPPER(SUBSTRING(a117.LASTNAME, 1, 1)) + LOWER(SUBSTRING(a117.LASTNAME, 2, len(a117.LASTNAME) - 1))) + ' , ' + (UPPER(SUBSTRING(a117.FIRSTNAME, 1, 1)) + LOWER(SUBSTRING(a117.FIRSTNAME, 2, LEN(a117.FIRSTNAME) - 1)))))  CustCol_33,
		a110.PK_DISTRIBUTOR  PK_DSContactInfo,
		MAX(a110.ADDRESS01)  ADDRESS01,
		MAX(a110.ADDRESS02)  ADDRESS02,
		MAX(a110.ADDRESS03)  ADDRESS03,
		MAX(a110.ADDRESS04)  ADDRESS04,
		MAX(a110.CITY)  CITY,
		MAX(a110.COUNTY)  COUNTY,
		MAX(a110.POSTALCODE)  POSTALCODE,
		MAX(a110.STATE)  STATE,
		a15.ORDERINFORMATION  ORDERINFORMATION,
		a15.QUANTITY  QUANTITY,
		CASE WHEN a15.QUANTITY > 0 THEN 1 
		ELSE 0 
		END as isTicketPurchaser,
        a11.nDistributorID PK_DISTRIBUTOR2,
		MAX(a11.sDistributorID)  DISTRIBUTORID2,
		MAX(a11.sFirstName)  FIRSTNAME2,
		MAX(a11.sLastName)  LASTNAME2,
		MAX(((UPPER(SUBSTRING(a12.LASTNAME, 1, 1)) + LOWER(SUBSTRING(a12.LASTNAME, 2, LEN(a12.LASTNAME) - 1))) + ' , ' + (UPPER(SUBSTRING(a12.FIRSTNAME, 1, 1)) + LOWER(SUBSTRING(a12.FIRSTNAME, 2, LEN(a12.FIRSTNAME) - 1)))))  CustCol_2,
		a12.SPOUSEFIRSTNAME as DSSPOUSEFIRSTNAME,
		a12.SPOUSELASTNAME as DSSPOUSELASTNAME,
		MAX(((UPPER(SUBSTRING(a12.SPOUSELASTNAME, 1, 1)) + LOWER(SUBSTRING(a12.SPOUSELASTNAME, 2, LEN(a12.SPOUSELASTNAME) - 1))) + ' , ' + (UPPER(SUBSTRING(a12.SPOUSEFIRSTNAME, 1, 1)) + LOWER(SUBSTRING(a12.SPOUSEFIRSTNAME, 2, LEN(a12.SPOUSEFIRSTNAME) - 1)))))  CustCol_3,
		MAX(a110.CELLPHONE)  CellPhone2,
		MAX(a110.DayPhone)  DayPhone2,
		MAX(a110.EvePhone)  EvePhone2,
		MAX(a110.PRIMARYEMAIL)  EMAIL2,
		a15.PK_EVENT  PK_EVENT,
		MAX(a114.EventName)  EventName,
		a12.SPQUALDATE  PK_DAY,
		MAX(a113.DAYDATE)  SPQUALDATE,
		a12.SPReQualDate PK_DAY2,
		MAX(a140.DAYDATE)  SPReQUALDATE,
		a12.PK_DSSUBTYPE  PK_DSSUBTYPE,
		MAX(a130.SUBTYPECODE)  SUBTYPECODE,
		MAX(a130.SUBTYPEDESC)  SUBTYPEDESC,
		a12.APPLICATIONDATE  PK_DAY1,
		MAX(a118.DAYDATE)  DAYDATE9,
		a12.PK_LANGUAGE  PK_LANGUAGE,
		MAX(a122.LANGUAGENAME)  LANGUAGENAME,
		a110.PK_COUNTRYAVS  PK_COUNTRY0,
		MAX(a132.COUNTRYNAME)  COUNTRYNAME0, 
        MAX(D2.sMainDistributorID) MAINID,
		CASE WHEN a112.PK_DSSUBTYPE in (220010,200010,120010,160010, 190010,300023,300022,40010,10,9,8)  THEN CONVERT(DATETIME,LEFT(CONVERT(VARCHAR(10), MAX(a19.FROMDATE),101),6)+'01',101) 
		END TEAMQUALDATE,
		CASE WHEN a112.PK_DSSUBTYPE in (3,4,5,6,7) THEN CONVERT(DATETIME,LEFT(CONVERT(VARCHAR(10), MAX(a19.FROMDATE),101),6)+'01',101) 
		END SUBTEAMQUALDATE,    
        MIN(awt.AWTYEAR) as FirstTimeAwtYear,
		a15.ISEVENTQUALIFIER as isEventQualifier,
		a15.ISEVENTQUALIFIER as EVENTQUALIFIED,	
		a18.FirstUplineMill PK_DISTRIBUTOR_Mill,
		MAX(a142.DISTRIBUTORID)  DISTRIBUTORID_Mill,
		MAX(a142.FIRSTNAME)  FIRSTNAME_Mill,
		MAX(a142.LASTNAME)  LASTNAME_Mill,
		MAX(((UPPER(SUBSTRING(a142.LASTNAME, 1, 1)) + LOWER(SUBSTRING(a142.LASTNAME, 2, LEN(a142.LASTNAME) - 1))) + ' , ' + (UPPER(SUBSTRING(a142.FIRSTNAME, 1, 1)) + LOWER(SUBSTRING(a142.FIRSTNAME, 2, LEN(a142.FIRSTNAME) - 1)))))  Name_Mill,	
		a18.FirstUplineTAB PK_DISTRIBUTOR_TAB,
		MAX(a141.DISTRIBUTORID)  DISTRIBUTORID_TAB,
		MAX(a141.FIRSTNAME)  FIRSTNAME_TAB,
		MAX(a141.LASTNAME)  LASTNAME_TAB,
		MAX(((UPPER(SUBSTRING(a141.LASTNAME, 1, 1)) + LOWER(SUBSTRING(a141.LASTNAME, 2, LEN(a141.LASTNAME) - 1))) + ' , ' + (UPPER(SUBSTRING(a141.FIRSTNAME, 1, 1)) + LOWER(SUBSTRING(a141.FIRSTNAME, 2, LEN(a141.FIRSTNAME) - 1)))))  Name_TAB	
FROM	
		(SELECT PK_DISTRIBUTOR,PK_Event,COUNT (*) Cnt 
		 FROM #EventTP
		 GROUP BY PK_DISTRIBUTOR, PK_Event) Evnt_Quals
INNER JOIN  PubEvents.dbo.v_DistributorUnionTemp a11 (nolock)  
		ON Evnt_Quals.PK_Distributor = a11.nDistributorID 
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDISTRIBUTOR	a12
	    ON 	(a11.nDistributorID = a12.PK_DISTRIBUTOR)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDSSUBTYPE	a112
	    ON 	(a12.PK_DSSUBTYPE = a112.PK_DSSUBTYPE)
LEFT OUTER JOIN	#EventTP	a15
	    ON 	(a11.nDistributorID = a15.PK_DISTRIBUTOR AND
            Evnt_Quals.PK_Event = a15.PK_Event)
LEFT OUTER JOIN	PubEvents.dbo.V_SUBEVENT	a16
	    ON 	(a15.PK_EVENT = a16.PK_EVENT AND 
	         a15.PK_SUBEVENT = a16.PK_SUBEVENT)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDSLNGUPLINE	a18
	    ON 	(a12.PK_DISTRIBUTOR = a18.PK_DISTRIBUTOR)
LEFT OUTER JOIN PubEvents.dbo.DIMDSHISTORY a19 (NOLOCK)
        ON 	(a12.PK_DISTRIBUTOR = a19.PK_DISTRIBUTOR)
LEFT OUTER JOIN PubEvents.dbo.DIMDSLIFECYCLE  LC (NOLOCK)
        ON a19.THROUGHDATE = '20491231' AND (
		CASE
		    WHEN CONCAT(REPLACE(LC.LIFECYCLENAME, 'Qual ',''),' Member') = a112.SubTypeDesc THEN CONCAT(replace(LC.LIFECYCLENAME, 'Qual ',''),' Member')
		    WHEN REPLACE(LC.LIFECYCLENAME, 'Qual ','') = a112.SubTypeDesc THEN REPLACE(LC.LIFECYCLENAME, 'Qual ','')
		    WHEN REPLACE(LC.LIFECYCLENAME, 'Qual ','') = 'Get Team' THEN 'Global Expansion Team Member' 
                                    WHEN REPLACE(LC.LIFECYCLENAME, 'Qual ','') = 'GET Plus' THEN 'GET 2500 Team Member' 
                                    WHEN REPLACE(LC.LIFECYCLENAME, 'Qual ','') = 'Pres Team' THEN 'President''s Team Member'
                                    WHEN REPLACE(LC.LIFECYCLENAME, 'Qual ','')  = 'Pres A Team' THEN 'President''s ''A'' Team'
                                    WHEN REPLACE(LC.LIFECYCLENAME, 'Qual ','')  = 'Pres B Team' THEN 'President''s ''B'' Team'
                                    WHEN REPLACE(LC.LIFECYCLENAME, 'Qual ','')  = 'Pres C Team' THEN 'President''s ''C'' Team'
                                    WHEN REPLACE(LC.LIFECYCLENAME, 'Qual ','')  = 'Chairman Club' THEN 'Chairmans Club Member'   
                                    WHEN REPLACE(LC.LIFECYCLENAME, 'Qual ','')  = 'Founders Circle' THEN 'Founders Club Member'  
                                    WHEN REPLACE(LC.LIFECYCLENAME, 'Qual ','')  = 'Mill Team' THEN 'Millionaire Team Member'  
                                    WHEN REPLACE(LC.LIFECYCLENAME, 'Qual ','')  = 'Mill Plus' THEN 'MILL 7500 Team Member'  
        END =  a112.SubTypeDesc 
        OR  a112.SubTypeCode = REPLACE(LC.LIFECYCLENAME, 'Qual ','')
		)	
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDSCONTACTINFO	a110
		ON 	(a12.PK_DISTRIBUTOR = a110.PK_DISTRIBUTOR)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMCOUNTRYREGION_XREF_CORP	a111
	    ON 	(a12.PK_COP = a111.PK_COUNTRY)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDAYALL	a113
	    ON 	(a12.SPQUALDATE = a113.PK_DAY)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDAYALL	a140
	    ON 	(a12.SPReQualDate = a140.PK_DAY)  
LEFT OUTER JOIN	PubEvents.dbo.V_EVENT	a114
	    ON 	(a15.PK_EVENT = a114.PK_EVENT)
LEFT OUTER JOIN	V_DIMDISTRIBUTOR	a115
	    ON 	(a18.FIRSTUPLINECC = a115.PK_DISTRIBUTOR)
LEFT OUTER JOIN	V_DIMDISTRIBUTOR	a116
	    ON 	(a18.FIRSTUPLINEPRES = a116.PK_DISTRIBUTOR)
LEFT OUTER JOIN	V_DIMDISTRIBUTOR	a117
	    ON 	(a18.FIRSTUPLINESP = a117.PK_DISTRIBUTOR)	  
LEFT OUTER JOIN	V_DIMDISTRIBUTOR	a142
	    ON 	(a18.FirstUplineMill = a142.PK_DISTRIBUTOR)	  
LEFT OUTER JOIN	V_DIMDISTRIBUTOR	a141
	    ON 	(a18.FirstUplineTAB = a141.PK_DISTRIBUTOR) 
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDAYALL	a118
	    ON 	(a12.APPLICATIONDATE = a118.PK_DAY)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDSLANGUAGE	a122
	    ON 	(a12.PK_LANGUAGE = a122.PK_LANGUAGE)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMCOUNTRY	a128
	    ON 	(a12.PK_COP = a128.PK_COUNTRY)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDAYALL	a129
	    ON 	(a12.QPQUALDATE = a129.PK_DAY)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDSSUBTYPE	a130
	    ON 	(a12.PK_DSSUBTYPE = a130.PK_DSSUBTYPE)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDSTYPE	a131
	    ON 	(a112.PK_DSTYPE = a131.PK_DSTYPE)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMCOUNTRYALL	a132
	    ON 	(a110.PK_COUNTRYAVS = a132.PK_COUNTRY)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMREGION_CORP	a133
	    ON 	(a111.PK_REGION = a133.PK_REGION)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDSTEAM	a134
	    ON 	(a12.PK_DSTEAM = a134.PK_DSTEAM)
LEFT OUTER JOIN PubEventManagement.dbo.V_AWT awt
	    ON (a12.PK_DISTRIBUTOR = awt.PK_DISTRIBUTOR)
LEFT OUTER JOIN PubEventManagement.dbo.v_DistributorAssociate2 D2
                  ON ( Evnt_Quals.pk_distributor = D2.nDistributorID AND D2.transfer=0 AND D2.dthrough = '2049-12-31')	
WHERE	(a11.PK_EventDSClass in (1, 2) and a111.pk_region in (3, 4, 5, 8, 6, 7) )
GROUP BY	
		a15.PK_SUBEVENT,
		a18.FIRSTUPLINECC,
		a12.PK_COP,
		a111.PK_REGION,
		a12.PK_DSTEAM,
		a112.PK_DSTYPE,
		a18.FIRSTUPLINEPRES,
		a18.FIRSTUPLINESP,
		a110.PK_DISTRIBUTOR,
		a15.ORDERINFORMATION,
		a15.QUANTITY,
		a12.PK_DISTRIBUTOR,
		a11.nDistributorID,
		a15.PK_EVENT,
		a12.SPQUALDATE,
		a12.PK_DSSUBTYPE,	
		a12.APPLICATIONDATE,
		a12.PK_LANGUAGE,
		a110.PK_COUNTRYAVS,
		a112.PK_DSSUBTYPE,    
		a15.ISEVENTQUALIFIER,
		a12.SPOUSEFIRSTNAME,
		a12.SPOUSELASTNAME,
		a12.SPReQualDate,
		a18.FirstUplineMill,
		a18.FirstUplineTAB
		OPTION (RECOMPILE)

	UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
	WHERE [Step] = 4;

/******************************************************************************
	Merge Data on EventsQualifiersReport Table
******************************************************************************/

INSERT INTO #TimeLog VALUES ('Merge data on EventQualifiersReport Table', 5, GETUTCDATE(), NULL);

; WITH Quals As
	(
		SELECT 
			PK_Subevent,
			SubEventName,
			PK_Distributor,
			DistributorId,
			FirstName,
			LastName,
			PK_Country,
			CountryCode,
			CountryName,
			PK_Region,
			RegionName,
			PK_DsTeam,
			TeamDesc,
			PK_DsType,
			TypeDesc,
			PK_Distributor0,
			DistributorId0,
			FirstName0,
			LastName0,
			CustCol_32,
			PK_Distributor1,
			DistributorId1,
			FirstName1,
			LastName1,
			CustCol_33,
			PK_DSContactInfo,
			Address01,
			Address02,
			Address03,
			Address04,
			City,
			County,
			PostalCode,
			State,
			ORderInformation,
			Quantity,
			IsTicketPurchaser,
			PK_Distributor2,
			DistributorId2,
			FirstName2,
			LastName2,
			CustCol_2,
			DSSpouseFirstName,
			DSSpouseLastName,
			CustCol_3,
			CellPhone2,
			DayPhone2,
			EvePhone2,
			Email2,
			PK_Event,
			EventName,
			PK_Day,
			SPQualDate,
			PK_Day2,
			SPReQualDate,
			PK_DsSubType,
			SubTypeCode,
			SubTypeDesc,
			PK_Day1,
			DayDate9,
			PK_Language,
			LanguageName,
			PK_Country0,
			CountryName0,
			MainId,
			TeamQualDate,
			SubTeamQualDate,
			FirstTimeAwtYear,
			IsEventQualifier,
			EventQualified,
			PK_Distributor_Mill,
			DistributorId_Mill,
			FirstName_Mill,
			LastName_Mill,
			Name_Mill,
			PK_Distributor_Tab,
			DistributorId_Tab,
			FirstName_Tab,
			LastName_Tab,
			Name_Tab	
		FROM [dbo].[EventsQualifiersReport] EQR
		WHERE EXISTS(SELECT 1 FROM #Event E WHERE EQR.PK_Event = E.PK_Event))
	
	MERGE Quals Q
	USING #EventsQualifiersReport EQR
	ON 
		Q.PK_DISTRIBUTOR2 = EQR.PK_DISTRIBUTOR2 and Q.PK_Event = EQR.PK_Event and Q.PK_SubEvent = EQR.PK_SubEvent 
    WHEN MATCHED  THEN
		UPDATE
		SET
		Q.SubEventName			= EQR.SubEventName ,
		Q.PK_Distributor		= EQR.PK_Distributor,
		Q.DistributorId			= EQR.DistributorId,
		Q.FirstName				= EQR.FirstName,
		Q.LastName				= EQR.LastName,
		Q.PK_Country			= EQR.PK_Country,
		Q.CountryCode			= EQR.CountryCode,
		Q.CountryName			= EQR.CountryName,
		Q.PK_Region				= EQR.PK_Region,
		Q.RegionName			= EQR.RegionName,
		Q.PK_DsTeam				= EQR.PK_DsTeam,
		Q.TeamDesc				= EQR.TeamDesc,
		Q.PK_DsType				= EQR.PK_DsType,
		Q.TypeDesc				= EQR.TypeDesc,
		Q.PK_Distributor0		= EQR.PK_Distributor0,
		Q.DistributorId0		= EQR.DistributorId0,
		Q.FirstName0			= EQR.FirstName0,
		Q.LastName0				= EQR.LastName0,
		Q.CustCol_32			= EQR.CustCol_32,
		Q.PK_Distributor1		= EQR.PK_Distributor1,
		Q.DistributorId1		= EQR.DistributorId1,
		Q.FirstName1			= EQR.FirstName1,
		Q.LastName1				= EQR.LastName1,
		Q.CustCol_33			= EQR.CustCol_33,
		Q.PK_DSContactInfo		= EQR.PK_DSContactInfo,
		Q.Address01				= EQR.Address01,
		Q.Address02				= EQR.Address02,
		Q.Address03				= EQR.Address03,
		Q.Address04				= EQR.Address04,
		Q.City					= EQR.City,
		Q.County				= EQR.County,
		Q.PostalCode			= EQR.PostalCode,
		Q.State					= EQR.State,
		Q.ORderInformation		= EQR.ORderInformation,
		Q.Quantity				= EQR.Quantity,
		Q.IsTicketPurchaser		= EQR.IsTicketPurchaser,
		Q.DistributorId2		= EQR.DistributorId2,
		Q.FirstName2			= EQR.FirstName2,
		Q.LastName2				= EQR.LastName2,
		Q.CustCol_2				= EQR.CustCol_2,
		Q.DSSpouseFirstName		= EQR.DSSpouseFirstName,
		Q.DSSpouseLastName		= EQR.DSSpouseLastName,
		Q.CustCol_3				= EQR.CustCol_3,
		Q.CellPhone2			= EQR.CellPhone2,
		Q.DayPhone2				= EQR.DayPhone2,
		Q.EvePhone2				= EQR.EvePhone2,
		Q.Email2				= EQR.Email2,
		Q.EventName				= EQR.EventName,
		Q.PK_Day				= EQR.PK_Day,
		Q.SPQualDate			= EQR.SPQualDate,
		Q.PK_Day2				= EQR.PK_Day2,
		Q.SPReQualDate			= EQR.SPReQualDate,
		Q.PK_DsSubType			= EQR.PK_DsSubType,
		Q.SubTypeCode			= EQR.SubTypeCode,
		Q.SubTypeDesc			= EQR.SubTypeDesc,
		Q.PK_Day1				= EQR.PK_Day1,
		Q.DayDate9				= EQR.DayDate9,
		Q.PK_Language			= EQR.PK_Language,
		Q.LanguageName			= EQR.LanguageName,
		Q.PK_Country0			= EQR.PK_Country0,
		Q.CountryName0			= EQR.CountryName0,
		Q.MainId				= EQR.MainId,
		Q.TeamQualDate			= EQR.TeamQualDate,
		Q.SubTeamQualDate		= EQR.SubTeamQualDate,
		Q.FirstTimeAwtYear		= EQR.FirstTimeAwtYear,
		Q.IsEventQualifier		= EQR.IsEventQualifier,
		Q.EventQualified		= EQR.EventQualified,
		Q.PK_Distributor_Mill	= EQR.PK_Distributor_Mill,
		Q.DistributorId_Mill	= EQR.DistributorId_Mill,
		Q.FirstName_Mill		= EQR.FirstName_Mill,
		Q.LastName_Mill			= EQR.LastName_Mill,
		Q.Name_Mill				= EQR.Name_Mill,
		Q.PK_Distributor_Tab	= EQR.PK_Distributor_Tab,
		Q.DistributorId_Tab		= EQR.DistributorId_Tab,
		Q.FirstName_Tab			= EQR.FirstName_Tab,
		Q.LastName_Tab			= EQR.LastName_Tab,
		Q.Name_Tab				= EQR.Name_Tab
    
	WHEN NOT MATCHED BY SOURCE THEN DELETE

   	WHEN NOT MATCHED BY TARGET THEN
		INSERT (PK_Subevent
				,SubEventName
				,PK_Distributor
				,DistributorId
				,FirstName
				,LastName
				,PK_Country
				,CountryCode
				,CountryName
				,PK_Region
				,RegionName
				,PK_DsTeam
				,TeamDesc
				,PK_DsType
				,TypeDesc
				,PK_Distributor0
				,DistributorId0
				,FirstName0
				,LastName0
				,CustCol_32
				,PK_Distributor1
				,DistributorId1
				,FirstName1
				,LastName1
				,CustCol_33
				,PK_DSContactInfo
				,Address01
				,Address02
				,Address03
				,Address04
				,City
				,County
				,PostalCode
				,State
				,ORderInformation
				,Quantity
				,IsTicketPurchaser
				,PK_Distributor2
				,DistributorId2
				,FirstName2
				,LastName2
				,CustCol_2
				,DSSpouseFirstName
				,DSSpouseLastName
				,CustCol_3
				,CellPhone2
				,DayPhone2
				,EvePhone2
				,Email2
				,PK_Event
				,EventName
				,PK_Day
				,SPQualDate
				,PK_Day2
				,SPReQualDate
				,PK_DsSubType
				,SubTypeCode
				,SubTypeDesc
				,PK_Day1
				,DayDate9
				,PK_Language
				,LanguageName
				,PK_Country0
				,CountryName0
				,MainId
				,TeamQualDate
				,SubTeamQualDate
				,FirstTimeAwtYear
				,IsEventQualifier
				,EventQualified
				,PK_Distributor_Mill
				,DistributorId_Mill
				,FirstName_Mill
				,LastName_Mill
				,Name_Mill
				,PK_Distributor_Tab
				,DistributorId_Tab
				,FirstName_Tab
				,LastName_Tab
				,Name_Tab	
				)
		VALUES (EQR.PK_Subevent
				,EQR.SubEventName
				,EQR.PK_Distributor
				,EQR.DistributorId
				,EQR.FirstName
				,EQR.LastName
				,EQR.PK_Country
				,EQR.CountryCode
				,EQR.CountryName
				,EQR.PK_Region
				,EQR.RegionName
				,EQR.PK_DsTeam
				,EQR.TeamDesc
				,EQR.PK_DsType
				,EQR.TypeDesc
				,EQR.PK_Distributor0
				,EQR.DistributorId0
				,EQR.FirstName0
				,EQR.LastName0
				,EQR.CustCol_32
				,EQR.PK_Distributor1
				,EQR.DistributorId1
				,EQR.FirstName1
				,EQR.LastName1
				,EQR.CustCol_33
				,EQR.PK_DSContactInfo
				,EQR.Address01
				,EQR.Address02
				,EQR.Address03
				,EQR.Address04
				,EQR.City
				,EQR.County
				,EQR.PostalCode
				,EQR.State
				,EQR.ORderInformation
				,EQR.Quantity
				,EQR.IsTicketPurchaser
				,EQR.PK_Distributor2
				,EQR.DistributorId2
				,EQR.FirstName2
				,EQR.LastName2
				,EQR.CustCol_2
				,EQR.DSSpouseFirstName
				,EQR.DSSpouseLastName
				,EQR.CustCol_3
				,EQR.CellPhone2
				,EQR.DayPhone2
				,EQR.EvePhone2
				,EQR.Email2
				,EQR.PK_Event
				,EQR.EventName
				,EQR.PK_Day
				,EQR.SPQualDate
				,EQR.PK_Day2
				,EQR.SPReQualDate
				,EQR.PK_DsSubType
				,EQR.SubTypeCode
				,EQR.SubTypeDesc
				,EQR.PK_Day1
				,EQR.DayDate9
				,EQR.PK_Language
				,EQR.LanguageName
				,EQR.PK_Country0
				,EQR.CountryName0
				,EQR.MainId
				,EQR.TeamQualDate
				,EQR.SubTeamQualDate
				,EQR.FirstTimeAwtYear
				,EQR.IsEventQualifier
				,EQR.EventQualified
				,EQR.PK_Distributor_Mill
				,EQR.DistributorId_Mill
				,EQR.FirstName_Mill
				,EQR.LastName_Mill
				,EQR.Name_Mill
				,EQR.PK_Distributor_Tab
				,EQR.DistributorId_Tab
				,EQR.FirstName_Tab
				,EQR.LastName_Tab
				,EQR.Name_Tab	
				);

	UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
	WHERE [Step] = 5;

/******************************************************************************
	Freeze Events and remove data
******************************************************************************/

INSERT INTO #TimeLog ([Milestone],[Step],[StepStart],[Duration])
SELECT 'Trunc Temp Table', 6 , GETUTCDATE(), NULL

DROP TABLE IF EXISTS #fzEvents

SELECT DISTINCT E.PK_Event 
INTO #fzEvents
FROM dbo.[Event] E WITH (NOLOCK)    
INNER JOIN [dbo].[EventExtn] AS EX WITH (NOLOCK)
		ON E.PK_Event = EX.PK_Event
INNER JOIN dbo.[EventSchedule] AS ES WITH (NOLOCK)
		ON E.PK_Event = ES.PK_Event	 AND es.PK_Schedule = 6
WHERE E.dEndUTC BETWEEN DATEADD(MM,-3,GETUTCDATE()) AND  GETUTCDATE()
	AND EnableTesting = 0
	AND EventName NOT LIKE '%est%'
	AND EventDesc NOT LIKE '%est%'
	AND E.PK_Event IS NOT NULL
	AND NOT EXISTS(SELECT 1 FROM #Event ET WHERE E.PK_Event = ET.PK_Event)

DELETE EQR
FROM [dbo].[EventsQualifiersReport] EQR
WHERE NOT EXISTS(SELECT 1 FROM #fzEvents FE WHERE EQR.PK_Event = FE.PK_Event)
AND NOT EXISTS(SELECT 1 FROM #Event E WHERE EQR.PK_Event = E.PK_Event)

	UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
	WHERE [Step] = 6;
-- Update processing Log
EXEC [dbo].[usp_Utility_UpdateProcessingLog]
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime;

		IF @IsDevQA = 1
		BEGIN
			SELECT 
				[Milestone]		
				,[Step]					
				,[StepStart]	
				,[Duration]		
			FROM #TimeLog
		END	

END TRY

/******************************************************************************
	End procedure
******************************************************************************/
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 1
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
	END CATCH;
/**************************************************************************************************************
									END OF STORED PROCEDURE									
***************************************************************************************************************/

END