CREATE PROCEDURE [dbo].[usp_Event_EventsTicketsReport]
		--OPTIONAL
		@Error	int = 0 OUTPUT,
	    @ErrorMessage varchar(4000) = NULL OUTPUT,
		@IsDevQA tinyint = 0
	
AS
BEGIN
-- =======================================================================================
-- Author:		Jair Lira Garcia
-- Create date: October 10th,2025
-- Object:      usp_Event_EventsTicketsReport   
-- Use:         EXEC dbo.usp_Event_EventsTicketsReport
-- Description:	Get CEA Events Tickets Report information 
-- Parameters :  @Error  OUT Error number
--               @ErrorMessage OUT Error message
--              QA/DEV
--       	     @IsDevQA tinyint = 0 
--------------------------------------------------------------------
--    VERSIONS
--------------------------------------------------------------------
--    1.0.0       2022-11-20      Jair Lira        Initial
--    1.1.0       2026-01-26      jairli           Removing dstype filter
-- ========================================================================================

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @StoredProcedure varchar(255) = 'usp_Event_EventsTicketsReport'
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
WHERE ( E.dEndUTC >=  GETUTCDATE()  OR E.dEndUTC BETWEEN DATEADD(MM,-3,GETUTCDATE()) AND  GETUTCDATE())
AND EnableTesting = 0
AND EventName NOT LIKE '%est%'
AND EventDesc NOT LIKE '%est%';

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
WHERE Quantity > 0
GROUP BY PK_DISTRIBUTOR, E.PK_Event, [ORDERINFORMATION], [QUANTITY],[PK_SUBEVENT],[ISEVENTQUALIFIER]

UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [Step] = 2;

/******************************************************************************
	Create dbo.usp_Event_EventsTicketsReport Table
******************************************************************************/
INSERT INTO #TimeLog VALUES ('Creating Tickets temp table', 3, GETUTCDATE(), NULL);

IF OBJECT_ID('tempdb..#EventsTicketsReport') IS NOT NULL DROP TABLE #EventsTicketsReport

CREATE TABLE #EventsTicketsReport  (
    [PK_Distributor2] 			[INT] NOT NULL ,
	[DistributorId2] 			[VARCHAR] (30) NULL,
	[FirstName2] 				[NVARCHAR] (150) NULL,
	[LastName2] 				[NVARCHAR] (150) NULL,
	[CustCol_2] 				[NVARCHAR] (300) NULL,
	[SpouseFirstName] 			[NVARCHAR] (150) NULL,
	[SpouseLastName] 			[NVARCHAR] (150) NULL,
	[PK_DSType] 				[INT] NULL,
	[TypeDesc] 					[VARCHAR] (30) NULL,
	[PK_Day] 					[INT] NULL,
	[DayDate] 					[DATETIME] NULL,
	[PK_Day1] 					[INT] NULL,
	[SPReQualdate] 				[DATETIME] NULL,
	[PK_DSTeam] 				[INT] NULL,
	[TeamDesc] 					[VARCHAR] (80) NULL,
	[TeamQualDate] 				[DATETIME] NULL,
	[PK_DSSubType] 				[INT] NULL,
	[SubTypeCode] 				[VARCHAR] (5) NULL,
	[SubTypeDesc] 				[VARCHAR] (80) NULL,
	[OrderInformationSKU] 		[VARCHAR] (MAX) NULL,
	[QuantityPurchased] 		[INT] NULL,
	[PK_Country] 				[INT] NULL,
	[CountryCode] 				[VARCHAR] (2) NULL,
	[CountryName] 				[VARCHAR] (200) NULL,
	[PK_Region] 				[INT] NULL,
	[RegionName] 				[VARCHAR] (100) NULL,
	[PK_DSContactInfo] 			[INT] NULL,
	[Address01] 				[NVARCHAR] (240) NULL,
	[Address02] 				[NVARCHAR] (240) NULL,
	[Address03] 				[NVARCHAR] (240) NULL,
	[Address04] 				[NVARCHAR] (240) NULL,
	[City] 						[NVARCHAR] (60) NULL,
	[State] 					[NVARCHAR] (60) NULL,
	[County] 					[NVARCHAR] (60) NULL,
	[PostalCode] 				[NVARCHAR] (60) NULL,
	[Email2] 					[VARCHAR] (250) NULL,
	[CellPhone] 				[VARCHAR] (200) NULL,
	[DayPhone] 					[VARCHAR] (200) NULL,
	[EveningPhone] 				[VARCHAR] (200) NULL,
	[PK_Distributor1] 			[INT] NULL,
	[DistributorId1] 			[VARCHAR] (30) NULL,
	[FirstName1] 				[NVARCHAR] (150) NULL,
	[LastName1] 				[NVARCHAR] (150) NULL,
	[CustCol_33] 				[NVARCHAR] (300) NULL,
	[PK_Distributor0] 			[INT] NULL,
	[DistributorId0] 			[VARCHAR] (30) NULL,
	[FirstName0] 				[NVARCHAR] (150) NULL,
	[LastName0] 				[NVARCHAR] (150) NULL,
	[CustCol_32] 				[NVARCHAR] (300) NULL,
	[PK_Distributor] 			[INT] NULL,
	[DistributorId] 			[VARCHAR] (30) NULL,
	[FirstName] 				[NVARCHAR] (150) NULL,
	[LastName] 					[NVARCHAR] (150) NULL,
	[PK_SubEvent] 				[INT] NULL,
	[SubEventName] 				[VARCHAR] (200) NULL,
	[PK_Event] 					[INT] NULL,
	[EventName] 				[NVARCHAR] (200) NULL,
	[Qualified] 				[BIT] NULL,
	[PK_Distributor_Mill] 		[INT] NULL,
	[DistributorId_Mill] 		[VARCHAR] (30) NULL,
	[FirstName_Mill] 			[NVARCHAR] (150) NULL,
	[LastName_Mill] 			[NVARCHAR] (150) NULL,
	[Name_Mill] 				[NVARCHAR] (300) NULL,
	[PK_Distributor_Tab] 		[INT] NULL,
	[DistributorId_Tab] 		[VARCHAR] (30) NULL,
	[FirstName_Tab] 			[NVARCHAR] (150) NULL,
	[LastName_Tab] 				[NVARCHAR] (150) NULL,
	[Name_Tab] 					[NVARCHAR] (300) NULL
)

UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
		WHERE [Step] = 3;

/******************************************************************************
	Insert Events Qualifiers Information into dbo.EventsTicketsReport
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
INSERT #EventsTicketsReport
   (
		PK_Distributor2,
		DistributorId2,
		FirstName2,
		LastName2,
		CustCol_2,
		SpouseFirstName,
		SpouseLastName,
		PK_DSType,
		TypeDesc,
		PK_Day,
		DayDate,
		PK_Day1,
		SPReQualdate,
		PK_DSTeam,
		TeamDesc,
		TeamQualDate,
		PK_DSSubType,
		SubTypeCode,
		SubTypeDesc,
		OrderInformationSKU,
		QuantityPurchased,
		PK_Country,
		CountryCode,
		CountryName,
		PK_Region,
		RegionName,
		PK_DSContactInfo,
		Address01,
		Address02,
		Address03,
		Address04,
		City,
		State,
		County,
		PostalCode,
		Email2,
		CellPhone,
		DayPhone,
		EveningPhone,
		PK_Distributor1,
		DistributorId1,
		FirstName1,
		LastName1,
		CustCol_33,
		PK_Distributor0,
		DistributorId0,
		FirstName0,
		LastName0,
		CustCol_32,
		PK_Distributor,
		DistributorId,
		FirstName,
		LastName,
		PK_SubEvent,
		SubEventName,
		PK_Event,
		EventName,
		Qualified,
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
		a11.nDISTRIBUTORID  PK_DISTRIBUTOR2,
		MAX(a11.SDISTRIBUTORID)  DISTRIBUTORID2,
		MAX(a11.SFIRSTNAME)  FIRSTNAME2,
		MAX(a11.SLASTNAME)  LASTNAME2,
		MAX(((UPPER(SUBSTRING(a12.LASTNAME, 1, 1)) + LOWER(SUBSTRING(a12.LASTNAME, 2, Len(a12.LASTNAME) - 1))) + ' , ' + (UPPER(SUBSTRING(a12.FIRSTNAME, 1, 1)) + LOWER(SUBSTRING(a12.FIRSTNAME, 2, Len(a12.FIRSTNAME) - 1)))))  CustCol_2,
		MAX(a12.SPOUSEFIRSTNAME) SPOUSEFIRSTNAME,
		MAX(a12.SPOUSELASTNAME) SPOUSELASTNAME,
		a112.PK_DSTYPE  PK_DSTYPE,
		MAX(a129.TYPEDESC)  TYPEDESC,
		a12.SPQUALDATE  PK_DAY,
		MAX(a113.DAYDATE)  DAYDATE,
		a12.SPReQualDate  PK_DAY1,
		MAX(a124.DAYDATE)  SPReQUALDATE,
		a12.PK_DSTEAM  PK_DSTEAM,
		MAX(a131.TEAMDESC)  TEAMDESC,
		CASE WHEN a112.pk_dsteam in (5,6,7) THEN CONVERT(DATETIME,LEFT(CONVERT(VARCHAR(10), MAX(a19.FROMDATE),101),6)+'01',112)
		END TEAMQUALDATE, 
		a12.PK_DSSUBTYPE  PK_DSSUBTYPE,
		MAX(a128.SUBTYPECODE)  SUBTYPECODE,
		MAX(a128.SUBTYPEDESC)  SUBTYPEDESC,
		a15.ORDERINFORMATION  ORDERINFORMATIONSKU,
		a15.QUANTITY  QUANTITYPURCHASED,
		a12.PK_COP  PK_COUNTRY,
		MAX(a126.COUNTRYCODE)  COUNTRYCODE,
		MAX(a126.COUNTRYNAME)  COUNTRYNAME,
		a111.PK_REGION  PK_REGION,
		MAX(a130.RegionName)  RegionName,
		a110.PK_DISTRIBUTOR  PK_DSContactInfo,
		MAX(a110.ADDRESS01)  ADDRESS01,
		MAX(a110.ADDRESS02)  ADDRESS02,
		MAX(a110.ADDRESS03)  ADDRESS03,
		MAX(a110.ADDRESS04)  ADDRESS04,
		MAX(a110.CITY)  CITY,
		MAX(a110.STATE)  STATE,
		MAX(a110.COUNTY)  COUNTY,
		MAX(a110.POSTALCODE)  POSTALCODE,
		MAX(a110.PRIMARYEMAIL)  EMAIL2,
		MAX(a110.CELLPHONE)  CellPhone,
		MAX(a110.DayPhone)  DayPhone,
		MAX(a110.EvePhone)  EveningPhone,
		a18.FIRSTUPLINESP  PK_DISTRIBUTOR1,
		MAX(a117.DISTRIBUTORID)  DISTRIBUTORID1,
		MAX(a117.FIRSTNAME)  FIRSTNAME1,
		MAX(a117.LASTNAME)  LASTNAME1,
		MAX(((UPPER(SUBSTRING(a117.LASTNAME, 1, 1)) + LOWER(SUBSTRING(a117.LASTNAME, 2, LEN(a117.LASTNAME) - 1))) + ' , ' + (UPPER(SUBSTRING(a117.FIRSTNAME, 1, 1)) + LOWER(SUBSTRING(a117.FIRSTNAME, 2, LEN(a117.FIRSTNAME) - 1)))))  CustCol_33,
		a18.FIRSTUPLINEPRES  PK_DISTRIBUTOR0,
		MAX(a116.DISTRIBUTORID)  DISTRIBUTORID0,
		MAX(a116.FIRSTNAME)  FIRSTNAME0,
		MAX(a116.LASTNAME)  LASTNAME0,
		MAX(((UPPER(SUBSTRING(a116.LASTNAME, 1, 1)) + LOWER(SUBSTRING(a116.LASTNAME, 2, LEN(a116.LASTNAME) - 1))) + ' , ' + (UPPER(SUBSTRING(a116.FIRSTNAME, 1, 1)) + LOWER(SUBSTRING(a116.FIRSTNAME, 2, LEN(a116.FIRSTNAME) - 1)))))  CustCol_32,
		a18.FIRSTUPLINECC  PK_DISTRIBUTOR,
		MAX(a115.DISTRIBUTORID)  DISTRIBUTORID,
		MAX(a115.FIRSTNAME)  FIRSTNAME,
		MAX(a115.LASTNAME)  LASTNAME,
		a15.PK_SUBEVENT  PK_SUBEVENT,
		MAX(a16.SUBEVENTNAME)  SUBEVENTNAME,
		a15.PK_EVENT  PK_EVENT,
		MAX(a114.EventName)  EventName,	
		CASE WHEN a15.ISEVENTQUALIFIER <> 1 THEN 0 
		ELSE 1 
		END QUALIFIED,
		a18.FirstUplineMill PK_DISTRIBUTOR_Mill,
		MAX(a142.DISTRIBUTORID)  DISTRIBUTORID_Mill,
		MAX(a142.FIRSTNAME)  FIRSTNAME_Mill,
		MAX(a142.LASTNAME)  LASTNAME_Mill,
		MAX(((UPPER(SUBSTRING(a142.LASTNAME, 1, 1)) + LOWER(SUBSTRING(a142.LASTNAME, 2, len(a142.LASTNAME) - 1))) + ' , ' + (UPPER(SUBSTRING(a142.FIRSTNAME, 1, 1)) + LOWER(SUBSTRING(a142.FIRSTNAME, 2, LEN(a142.FIRSTNAME) - 1)))))  Name_Mill,	
		a18.FirstUplineTAB PK_DISTRIBUTOR_TAB,
		MAX(a141.DISTRIBUTORID)  DISTRIBUTORID_TAB,
		MAX(a141.FIRSTNAME)  FIRSTNAME_TAB,
		MAX(a141.LASTNAME)  LASTNAME_TAB,
		MAX(((UPPER(SUBSTRING(a141.LASTNAME, 1, 1)) + LOWER(SUBSTRING(a141.LASTNAME, 2, len(a141.LASTNAME) - 1))) + ' , ' + (UPPER(SUBSTRING(a141.FIRSTNAME, 1, 1)) + LOWER(SUBSTRING(a141.FIRSTNAME, 2, LEN(a141.FIRSTNAME) - 1)))))  Name_TAB
FROM
		(SELECT PK_DISTRIBUTOR,PK_Event,COUNT (*) Cnt 
		 FROM #EventTP
		 GROUP BY PK_DISTRIBUTOR, PK_Event) Evnt_Quals
INNER JOIN PubEvents.dbo.v_DistributorUnionTemp a11 (nolock)  
        ON Evnt_Quals.PK_Distributor = a11.nDistributorID 		
LEFT OUTER JOIN PubEvents.dbo.V_DIMDISTRIBUTOR	a12
	    ON 	(a11.nDistributorID = a12.PK_DISTRIBUTOR)	
LEFT OUTER JOIN PubEvents.dbo.V_DIMDSSUBTYPE	a112
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
        ON a19.THROUGHDATE = '20491231'  AND
                        (
		CASE
		    WHEN CONCAT(REPLACE(LC.LIFECYCLENAME, 'Qual ',''),' Member') = a112.SubTypeDesc THEN CONCAT(REPLACE(LC.LIFECYCLENAME, 'Qual ',''),' Member')
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
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDAYALL	a124
	    ON 	(a12.SPReQualDate = a124.PK_DAY)
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
LEFT OUTER JOIN	PubEvents.dbo.V_DIMCOUNTRY	a126
	    ON 	(a12.PK_COP = a126.PK_COUNTRY)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDSSUBTYPE	a128
	    ON 	(a12.PK_DSSUBTYPE = a128.PK_DSSUBTYPE)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDSTYPE	a129
	    ON 	(a112.PK_DSTYPE = a129.PK_DSTYPE)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMREGION_CORP	a130
	    ON 	(a111.PK_REGION = a130.PK_REGION)
LEFT OUTER JOIN	PubEvents.dbo.V_DIMDSTEAM	a131
	    ON 	(a12.PK_DSTEAM = a131.PK_DSTEAM)
WHERE	( a11.PK_EventDSClass IN (1, 2) AND a15.Quantity > 0)
GROUP BY a15.PK_SUBEVENT,
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
		 a15.ISEVENTQUALIFIER,
		 a12.SPReQualDate,
		 a18.FirstUplineMill,
		 a18.FirstUplineTAB,
         a112.pk_dsteam
		 OPTION (RECOMPILE)

	UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
	WHERE [Step] = 4;

/******************************************************************************
	Tuncate dbo.usp_Event_EventsTicketsReport Table
******************************************************************************/

INSERT INTO #TimeLog ([Milestone],[Step],[StepStart],[Duration])
SELECT 'Trunc Temp Table', 5 , GETUTCDATE(), NULL

TRUNCATE TABLE [dbo].[EventsTicketsReport];

	UPDATE #TimeLog SET [Duration] = DATEDIFF(second, [StepStart], GETUTCDATE()) 
	WHERE [Step] = 5;

/******************************************************************************
	Insert Events Tickets Information into dbo.EventsTicketsReport
******************************************************************************/
INSERT INTO #TimeLog ([Milestone],[Step],[StepStart],[Duration])
SELECT 'Insert Final Table', 6 , GETUTCDATE(), NULL

INSERT INTO [dbo].[EventsTicketsReport]
   (
		PK_Distributor2,
		DistributorId2,
		FirstName2,
		LastName2,
		CustCol_2,
		SpouseFirstName,
		SpouseLastName,
		PK_DSType,
		TypeDesc,
		PK_Day,
		DayDate,
		PK_Day1,
		SPReQualdate,
		PK_DSTeam,
		TeamDesc,
		TeamQualDate,
		PK_DSSubType,
		SubTypeCode,
		SubTypeDesc,
		OrderInformationSKU,
		QuantityPurchased,
		PK_Country,
		CountryCode,
		CountryName,
		PK_Region,
		RegionName,
		PK_DSContactInfo,
		Address01,
		Address02,
		Address03,
		Address04,
		City,
		State,
		County,
		PostalCode,
		Email2,
		CellPhone,
		DayPhone,
		EveningPhone,
		PK_Distributor1,
		DistributorId1,
		FirstName1,
		LastName1,
		CustCol_33,
		PK_Distributor0,
		DistributorId0,
		FirstName0,
		LastName0,
		CustCol_32,
		PK_Distributor,
		DistributorId,
		FirstName,
		LastName,
		PK_SubEvent,
		SubEventName,
		PK_Event,
		EventName,
		Qualified,
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
		PK_Distributor2,
		DistributorId2,
		FirstName2,
		LastName2,
		CustCol_2,
		SpouseFirstName,
		SpouseLastName,
		PK_DSType,
		TypeDesc,
		PK_Day,
		DayDate,
		PK_Day1,
		SPReQualdate,
		PK_DSTeam,
		TeamDesc,
		TeamQualDate,
		PK_DSSubType,
		SubTypeCode,
		SubTypeDesc,
		OrderInformationSKU,
		QuantityPurchased,
		PK_Country,
		CountryCode,
		CountryName,
		PK_Region,
		RegionName,
		PK_DSContactInfo,
		Address01,
		Address02,
		Address03,
		Address04,
		City,
		State,
		County,
		PostalCode,
		Email2,
		CellPhone,
		DayPhone,
		EveningPhone,
		PK_Distributor1,
		DistributorId1,
		FirstName1,
		LastName1,
		CustCol_33,
		PK_Distributor0,
		DistributorId0,
		FirstName0,
		LastName0,
		CustCol_32,
		PK_Distributor,
		DistributorId,
		FirstName,
		LastName,
		PK_SubEvent,
		SubEventName,
		PK_Event,
		EventName,
		Qualified,
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
	FROM #EventsTicketsReport;

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