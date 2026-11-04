CREATE PROCEDURE [dbo].[usp_Event_OnsiteReport_bberry]
 @PK_Event INT

-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = NULL OUTPUT

-- QA/DEV
,@IsDevQA bit = 0

----WITH EXECUTE AS 'dbo'
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_Event_OnsiteReport_bberry

USE:		declare @e int
                   ,@em varchar(200)

        EXEC usp_Event_OnsiteReport_bberry
                    @PK_Event = 2493
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 0

					SELECT @e,@em

DESCRIPTION:	Inserts record into dbo.BlackberryReport

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.BlackBerryReport

VERSIONS
--------------------------------------------------------------------
--   2.0		08-AUG-2019		NoeG					Refactor code (SRE)
--	 1.9		28-MAR-2016		Sandhya Pendyala		Breakdown to include SP, WT, GP, MP & added BY REGION section
--	 1.8		16-FEB-2016		Ini Ukporo				Added configurable Pres Team breakdown by subevent and Diamonds inclusion for applicable subevent(s).
--   1.2        2010-07-28      Sandhya Pendyala        Re-written to use live tables
--   1.1        2010-03-31      Sandhya Pendyala        Changes to Event level info & removed Q,U fields 
--   1.0        2009-04-06      Sandhya 	            Initial
--   2.0		2014-04-27		IniU					Expanded TeamStatus to SubTeam 
--   2.1		2014-07-14		IniU					Changed group by and sort by from created date to modified date due to pre-registration
--   3.0		2015-07-01		Sandhya Pendyala		Potential to account for non event ticket SKUs
--	 3.1        2015-08-13		Sandhya Pendyala		Added 'Registration by COP' section
--	 3.2		2019-08-01		alejandramed			Including error handling and processing log	
--   3.3        2020-02-14      IniU					Changed the references of tables that are being acted upon by application realtime or scheduled batch jobs 
                                                        to improve performance and reduce the chances of this job failing. Especially for tables that are referenced multiple times
														within the code. This job anyway is a point in time/snapshot report of the system.
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE 
	@StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
	,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

	DECLARE @MaxTickets INT
	DECLARE @RunSequence INT
	DECLARE @CMD Varchar(max)

	SELECT @RunSequence = MAX(COALESCE(RunSequence,0)) + 1 FROM dbo.BlackberryReport WITH(NOLOCK) WHERE PK_Event = @PK_Event

	IF @RunSequence IS NULL 
	BEGIN
	SET @RunSequence = 1
	END

	/******************************************************************************
		Get Max Tickets a Distributor could Use
	******************************************************************************/
	SELECT @MaxTickets = MaxNoOfPrimaryGuest+1
	FROM dbo.Event (NOLOCK)
	WHERE PK_Event = @PK_Event

	/****************************************************************************
	Drop temp tables/snapshots of objects
	****************************************************************************/
	IF OBJECT_ID('tempdb..#SEQ') IS NOT NULL DROP TABLE #SEQ
	IF OBJECT_ID('tempdb..#SER') IS NOT NULL DROP TABLE #SER
	IF OBJECT_ID('tempdb..#ER') IS NOT NULL DROP TABLE #ER
	IF OBJECT_ID('tempdb..#SKUP') IS NOT NULL DROP TABLE #SKUP
	IF OBJECT_ID('tempdb..#ET') IS NOT NULL DROP TABLE #ET
	IF OBJECT_ID('tempdb..#ETA') IS NOT NULL DROP TABLE #ETA
	IF OBJECT_ID('tempdb..#Stars') IS NOT NULL DROP TABLE #Stars

	/******************************************************************************
		get subevents
	******************************************************************************/
	IF OBJECT_ID('tempdb..#SubEvents') IS NOT NULL DROP TABLE #SubEvents CREATE TABLE #SubEvents (
		PK_SubEvent int
		,SubEventNumber varchar(3)
		,EventSubEventCode varchar(3)
		,SubEventName varchar(100)
		,PK_SubEventType int
		,PK_Event int
		,IsBBBreakDownReqd BIT
		,IsDiamondRptReqd BIT
	)

	INSERT
		#SubEvents
	(
		PK_SubEvent
		,SubEventNumber
		,EventSubEventCode
		,SubEventName
		,PK_SubEventType
		,PK_Event
		,IsBBBreakDownReqd
		,IsDiamondRptReqd
	)
	SELECT
		PK_SubEvent
		,SE.SubEventNumber
		,'E' + RIGHT(REPLACE(SE.SubEventNumber,'E','0'),2)
		,SE.SubEventName	
		,PK_SubEventType
		,PK_Event
		,IsBBBreakDownReqd
		,IsDiamondRptReqd
	FROM
		dbo.SubEvent SE (NOLOCK)
	WHERE
		SE.PK_Event = @PK_Event
	ORDER BY
		SE.PK_SubEvent

	CREATE INDEX IX_tSubEvents_PK_SubEvent ON #SubEvents (PK_SubEvent) 
	CREATE INDEX IX_tSubEvents_SubEventNumber ON #SubEvents (SubEventNumber) 
	CREATE INDEX IX_tSubEvents_EventSubEventCode ON #SubEvents (EventSubEventCode)

	/*
		Running SubEventRegistration refresh in case the event has mailout program.

		Refresing the records according to the qualification at the moment to create the mobile report.
	*/


	IF EXISTS (SELECT 1 FROM [dbo].[EventExtn] WITH (NOLOCK) WHERE PK_Event = @PK_Event AND [HasMailout] = 1)
	BEGIN
		  EXEC dbo.usp_EventAPI_Upd_RegisterAttendee @PK_Event = @PK_Event
	END

	/**********************************************************************************************************************************
	Build temp tables/snapshots especially for objects that are being populated real time or batch processes to reduces chances of 
	failure and improve processing time. 
	**********************************************************************************************************************************/

   SELECT SEQ.* INTO #SEQ FROM #SubEvents SE INNER JOIN dbo.SubEventQualifier SEQ WITH (NOLOCK)
   ON SE.PK_Event = SEQ.PK_Event AND SE.PK_SubEvent = SEQ.PK_SubEvent

   CREATE INDEX IX_#SEQ_PK_Event ON #SEQ (PK_Event) 
   CREATE INDEX IX_#SEQ_PK_SubEvent ON #SEQ (PK_SubEvent) 
   CREATE INDEX IX_#SEQ_PK_SubEventQualifier ON #SEQ (PK_SubEventQualifier) 
   CREATE INDEX IX_#SEQ_PK_Distributor ON #SEQ (PK_Distributor) 
   CREATE INDEX IX_#SEQ_RemovedUTC ON #SEQ (RemovedUTC)

   SELECT SER.* INTO #SER FROM #SEQ SEQ INNER JOIN dbo.SubEventRegistration SER WITH (NOLOCK)
   ON SER.PK_SubEventQualifier = SEQ.PK_SubEventQualifier

   CREATE INDEX IX_#SER_PK_EventsRegistration ON #SER (PK_EventsRegistration) 
   CREATE INDEX IX_#SER_PK_SubEventQualifier ON #SER (PK_SubEventQualifier) 

   SELECT ER.* INTO #ER FROM dbo.EventsRegistration ER WITH (NOLOCK)
   WHERE ER.PK_Event = @PK_Event

   CREATE INDEX IX_#ER_PK_EventsRegistration ON #ER (PK_EventsRegistration) INCLUDE (HasCheckedIn, Registered)

   SELECT SKP.* INTO #SKUP FROM dbo.SKUPurchased SKP WITH (NOLOCK)
   WHERE SKP.PK_Event = @PK_Event

   CREATE INDEX IX_#SKUP_PK_Event ON #SKUP (PK_Event) 
   CREATE INDEX IX_#SKUP_PK_EventSKU ON #SKUP (PK_EventSKU) 
   CREATE INDEX IX_#SKUP_PK_Distributor_Purchaser ON #SKUP (PK_Distributor_Purchaser)
   CREATE INDEX IX_#SKUP_PK_SKuPurchased ON #SKUP (PK_SKuPurchased) 

   SELECT ET.* INTO #ET FROM dbo.EventTickets ET WITH (NOLOCK)
   WHERE ET.PK_Event = @PK_Event

   CREATE INDEX IX_#ET_PK_Event ON #ET (PK_Event) 
   CREATE INDEX IX_#ET_PK_EventTicket ON #ET (PK_EventTicket) 
   CREATE INDEX IX_#ET_PK_SKuPurchased ON #ET (PK_SKuPurchased)

   SELECT ETA.* INTO #ETA FROM dbo.EventTicketAssignment ETA WITH (NOLOCK)
   WHERE ETA.PK_Event = @PK_Event

   CREATE INDEX IX_#ETA_PK_Event ON #ETA (PK_Event) 
   CREATE INDEX IX_#ETA_PK_EventTicket ON #ETA (PK_EventTicket) 
   CREATE INDEX IX_#ETA_ValidToDateUTC ON #ETA (ValidToDateUTC)

   SELECT * INTO #Stars FROM pubEvents.dbo.dimDSDiamonds DP (NOLOCK)

   CREATE INDEX IX_#Stars_PK_Distributor ON #Stars (PK_Distributor) INCLUDE(CurrentDiamondLvl)

   	/******************************************************************************
		Get SubEvent Registrants data
	******************************************************************************/

	IF OBJECT_ID('tempdb..#CurrentSubEventRegistrants') IS NOT NULL DROP TABLE #CurrentSubEventRegistrants

	CREATE TABLE
		#CurrentSubEventRegistrants
	(
		PK_Event int
		,PK_SubEvent int
		,PK_Distributor int
		,Registered int
		,TeamStatus varchar(10)
	)

	INSERT INTO
		#CurrentSubEventRegistrants
	(
		PK_Event 
		,PK_SubEvent
		,PK_Distributor
		,TeamStatus
		,Registered
	)
	SELECT
			SEQ.PK_Event
			,SEQ.PK_SubEvent
			,SEQ.PK_Distributor
			,ISNULL(NULLIF(D.sSubTeam,''),'N') AS DistributorTeam
			,COUNT(1)
	FROM
		#SER SER
	INNER JOIN
		#SEQ SEQ
	ON
		SER.PK_SubEventQualifier = SEQ.PK_SubEventQualifier
		AND
		SEQ.RemovedUTC = '12-31-2049'
	INNER JOIN
		#SubEvents S 
	ON
		SEQ.PK_Event = S.PK_Event 
		AND 
		SEQ.PK_SubEvent = S.PK_SubEvent
		AND
		S.PK_SubEventType <> 1 
	INNER JOIN
		dbo.v_EventCurrentQualificationToUpdate CE
	ON
		S.PK_Event = CE.PK_Event
	INNER JOIN
		#ER ER
	ON
		ER.PK_EventsRegistration = SER.PK_EventsRegistration
		AND
		ER.HasCheckedIn = 1
	INNER JOIN
		(SELECT DISTINCT nDistributorID, sSubTeam FROM dbo.v_DistributorUnionTemp (NOLOCK)) D
	ON
		D.nDistributorID = SEQ.PK_Distributor
	GROUP BY
		SEQ.PK_Event
		,SEQ.PK_SubEvent
		,SEQ.PK_Distributor
		,ISNULL(NULLIF(D.sSubTeam,''),'N')
	UNION
	SELECT
			S.PK_Event
			,S.PK_SubEvent
			,ER.PK_Distributor
			,ISNULL(NULLIF(D.sSubTeam,''),'N') AS DistributorTeam
			,COUNT(1)
	FROM
		#ER ER 
	INNER JOIN
		#SubEvents S 
	ON
		ER.PK_Event = S.PK_Event
		AND
		S.PK_SubEventType = 1
		AND
		ER.Registered = 1
		AND
		ER.HasCheckedIn = 1
	INNER JOIN
		#SEQ SEQ
	ON
		ER.PK_Distributor = SEQ.PK_Distributor
		AND
		SEQ.PK_Event = S.PK_Event 
		AND 
		SEQ.PK_SubEvent = S.PK_SubEvent
		AND
		SEQ.RemovedUTC = '12-31-2049'
	INNER JOIN
		dbo.v_EventCurrentQualificationToUpdate CE
	ON
		S.PK_Event = CE.PK_Event
	INNER JOIN
		(SELECT DISTINCT nDistributorID, sSubTeam FROM dbo.v_DistributorUnionTemp (NOLOCK)) D
	ON
		D.nDistributorID = ER.PK_Distributor
	GROUP BY
		S.PK_Event
		,S.PK_SubEvent
		,ER.PK_Distributor
		,ISNULL(NULLIF(D.sSubTeam,''),'N')

	CREATE INDEX IX_tCurrentSubEventRegistrants_PK_SubEvent ON #CurrentSubEventRegistrants (PK_SubEvent) 
	CREATE INDEX IX_tCurrentSubEventRegistrants_PK_Distributor ON #CurrentSubEventRegistrants (PK_Distributor) 
	CREATE INDEX IX_tCurrentSubEventRegistrants_TeamStatus ON #CurrentSubEventRegistrants (TeamStatus)	

		/******************************************************************************
		Get Tickets data by SubEvent
	******************************************************************************/


	IF OBJECT_ID('tempdb..#CurrentEventTickets') IS NOT NULL DROP TABLE #CurrentEventTickets

	CREATE TABLE
		#CurrentEventTickets
	(
		PK_Event int
		,PK_SubEvent int
		,PK_Distributor int
		,TicketsPurchased int
		,MaxNoTicketsCanUse int
		,TeamStatus varchar(10)
	)

	--IF OBJECT_ID('tblDSMailingAddress','U') IS NULL
	-- WAITFOR DELAY '00:02:00';


	;WITH 
		EventTickets (PK_Event, PK_Distributor, MaxTicketsCanUse, TicketsPurchased) AS
		(
			SELECT  
				ETA.PK_Event
				,ETA.PK_ToDistributor
				,E.MaxNoOfGuest
				,COUNT(ETA.PK_EventTicket)
			FROM 
				#ETA ETA 
			INNER JOIN
				dbo.Event E (NOLOCK)
			 ON
				E.PK_Event = ETA.PK_Event
			INNER JOIN
				dbo.v_EventCurrentQualificationToUpdate CE
			 ON
				CE.PK_Event = E.PK_Event
				AND
				E.PK_Event = @PK_Event
			WHERE
				ETA.ValidToDateUTC = '2049-12-31'
			GROUP BY
				ETA.PK_Event 
			   ,ETA.PK_ToDistributor
			   ,E.MaxNoOfGuest
		)
	,	SKUExclusive (PK_Event, PK_SubEvent, PK_Distributor, MaxTicketsCanUse, TicketsPurchased) AS
		(
			SELECT  
				SP.PK_Event
				,SC.PK_SubEvent
				,SP.PK_Distributor_Purchaser
				,E.MaxNoOfGuest
				,SUM(SP.Quantity)
			FROM 
				#SKUP SP 
			INNER JOIN
				dbo.Event E (NOLOCK)
			ON
				E.PK_Event = SP.PK_Event
			INNER JOIN
				dbo.SubEventSKUConfig SC (NOLOCK)
			ON
				SC.PK_Event = SP.PK_Event
				AND
				SC.PK_EventSKU = SP.PK_EventSKU
				AND
				SC.isSKUExclusive = 1
			INNER JOIN
				dbo.v_EventCurrentQualificationToUpdate CE
			 ON
				CE.PK_Event = E.PK_Event
				AND
				E.PK_Event = @PK_Event
			GROUP BY
				SP.PK_Event
				,SC.PK_SubEvent
				,SP.PK_Distributor_Purchaser
				,E.MaxNoOfGuest
		)
	,   SKUNonExclusive (PK_Event, PK_SubEvent, PK_Distributor, MaxTicketsCanUse, TicketsPurchased) AS
		(
		SELECT 
			SEQ.PK_Event, S.PK_SubEvent, SEQ.PK_Distributor,  COALESCE(SUM(SP.Quantity), CASE WHEN SUM(SPE.Quantity) > 1 THEN 2 ELSE SUM(SPE.Quantity) END) MaxTicketsCanUse, COALESCE(SUM(SP.Quantity), CASE WHEN SUM(SPE.Quantity) > 1 THEN 2 ELSE SUM(SPE.Quantity) END) Tickets
		FROM
			#SEQ SEQ 
		INNER JOIN
			dbo.SubEvent S (NOLOCK)
		ON
			SEQ.PK_SubEvent = S.PK_SubEvent
			AND
			SEQ.PK_Event = S.PK_Event
		INNER JOIN
			dbo.SubEventSKUConfig SC (NOLOCK)
		ON
			SC.PK_Event = S.PK_Event
			AND
			SC.PK_SubEvent = S.PK_SubEvent
			AND
			SC.isSKUExclusive = 0
		LEFT JOIN
			#SKUP SP   
		ON
			SP.PK_Event = SEQ.PK_Event
			AND
			SP.PK_Distributor_Purchaser = SEQ.PK_Distributor
			AND
			SC.PK_EventSKU = SP.PK_EventSKU
		LEFT JOIN
			dbo.EventSKU ES (NOLOCK)
		ON
			ES.PK_Event = S.PK_Event
			AND
			ES.isEventTicketSKU = 1
		LEFT JOIN
			#SKUP SPE 
		ON
			SPE.PK_Event = SEQ.PK_Event
			AND
			SPE.PK_Distributor_Purchaser = SEQ.PK_Distributor
			AND
			SPE.PK_EventSKU = ES.PK_EventSKU -- Event Ticket SKU
		WHERE
			SEQ.RemovedUTC = '2049-12-31'
			AND
			SEQ.PK_Event = @PK_Event
		GROUP BY 
			SEQ.PK_Event, S.PK_SubEvent, SEQ.PK_Distributor
		)

	INSERT INTO
		#CurrentEventTickets
	(
		PK_Event 
		,PK_SubEvent
		,PK_Distributor
		,TicketsPurchased 
		,MaxNoTicketsCanUse 
		,TeamStatus
	)	
	SELECT
			T.PK_Event
			,SEQ.PK_SubEvent
			,T.PK_Distributor
			,T.TicketsPurchased
			,CASE WHEN T.TicketsPurchased >= T.MaxTicketsCanUse 
					   AND T.TicketsPurchased > 1 
					   AND S.PK_SubEventType <> 1
				  THEN T.MaxTicketsCanUse + 1
				  ELSE COALESCE(T.TicketsPurchased,0) END AS MaxNoTicketsCanUse
			,ISNULL(NULLIF(D.sSubTeam,''),'N') AS Team
	FROM
		 EventTickets T
	LEFT JOIN
		#SEQ SEQ 
	ON
		SEQ.PK_Event = T.PK_Event
		AND
		SEQ.PK_Distributor = T.PK_Distributor
		AND
		SEQ.RemovedUTC = '2049-12-31'
	INNER JOIN
		#SubEvents S (NOLOCK)
	ON
		S.PK_Event = T.PK_Event
		AND
		S.PK_SubEvent = SEQ.PK_SubEvent
	INNER JOIN
		(SELECT DISTINCT nDistributorID, sSubTeam FROM dbo.v_DistributorUnionTemp (NOLOCK)) D
	ON
		T.PK_Distributor = D.nDistributorID
	LEFT JOIN
		dbo.SubEventSKUConfig SC (NOLOCK)
	ON
		SC.PK_SubEvent = SEQ.PK_SubEvent 
		AND
		SC.PK_Event = T.PK_Event
	WHERE 
		SC.PK_SubEvent IS NULL
	UNION
	SELECT
			T.PK_Event
			,T.PK_SubEvent
			,T.PK_Distributor
			,T.TicketsPurchased
			,T.TicketsPurchased AS MaxNoTicketsCanUse
			,ISNULL(NULLIF(D.sSubTeam,''),'N') AS Team
	FROM
		SKUExclusive T
	INNER JOIN
		#SEQ SEQ 
	ON
		SEQ.PK_Event = T.PK_Event
		AND
		SEQ.PK_SubEvent = T.PK_SubEvent
		AND
		SEQ.PK_Distributor = T.PK_Distributor
		AND
		SEQ.RemovedUTC = '2049-12-31'
	INNER JOIN
		#SubEvents S (NOLOCK)
	ON
		S.PK_Event = SEQ.PK_Event
		AND
		S.PK_SubEvent = SEQ.PK_SubEvent
	INNER JOIN
		(SELECT DISTINCT nDistributorID, sSubTeam FROM dbo.v_DistributorUnionTemp (NOLOCK)) D
	ON
		T.PK_Distributor = D.nDistributorID
	UNION
	SELECT
			SP.PK_Event
			,SP.PK_SubEvent
			,SP.PK_Distributor
			,SP.TicketsPurchased
			,SP.TicketsPurchased AS MaxNoTicketsCanUse
			,ISNULL(NULLIF(D.sSubTeam,''),'N') AS Team
	FROM
		SKUNonExclusive SP (NOLOCK)
	INNER JOIN
		#SubEvents S 
	ON
		--S.PK_Event = S.PK_Event
		SP.PK_Event = S.PK_Event --Sonarqube report #15
		AND
		--S.PK_SubEvent = S.PK_SubEvent
		SP.PK_SubEvent = S.PK_SubEvent --Sonarqube report #16
	INNER JOIN
		(SELECT DISTINCT nDistributorID, sSubTeam FROM dbo.v_DistributorUnionTemp (NOLOCK)) D
	ON
		SP.PK_Distributor = D.nDistributorID

	CREATE INDEX IX_tCurrentEventTickets_PK_SubEvent ON #CurrentEventTickets (PK_SubEvent) 
	CREATE INDEX IX_tCurrentEventTickets_PK_Distributor ON #CurrentEventTickets (PK_Distributor) 
	CREATE INDEX IX_tCurrentEventTickets_TeamStatus ON #CurrentEventTickets (TeamStatus)	
	
	/******************************************************************************
		Get Registered and Potential data by SubEvent
	******************************************************************************/
	
	IF OBJECT_ID('tempdb..#SubEventFact') IS NOT NULL DROP TABLE #SubEventFact 

	CREATE TABLE #SubEventFact (
		 PK_SubEvent int
		,PK_Distributor int
		,TeamStatus varchar(10)
		,RegisteredDS int DEFAULT 0
		,MaxTicketCanUse int DEFAULT 0
	)

	INSERT INTO #SubEventFact
	(
		 PK_SubEvent 
		,PK_Distributor
		,TeamStatus 
	)	
	SELECT DISTINCT
		 PK_SubEvent
		,PK_Distributor 
		,TeamStatus 
	FROM
		#CurrentSubEventRegistrants	
	UNION
	SELECT DISTINCT
		 PK_SubEvent
		,PK_Distributor 
		,TeamStatus 
	FROM
		#CurrentEventTickets	   
   
    
	UPDATE
		SEF	
	SET 
		SEF.RegisteredDS = CSER.Registered
	FROM
		#SubEventFact SEF
	INNER JOIN
		#CurrentSubEventRegistrants CSER
	ON
		 SEF.PK_SubEvent = CSER.PK_SubEvent
		 AND
		 SEF.PK_Distributor = CSER.PK_Distributor
		 AND
		 ISNULL(SEF.TeamStatus,'ZZ') = ISNULL(CSER.TeamStatus,'ZZ')
 
    	 
	UPDATE
		SEF	
	SET 
		SEF.MaxTicketCanUse = CSET.MaxNoTicketsCanUse
	FROM
		#SubEventFact SEF
	INNER JOIN
		#CurrentEventTickets CSET
	ON
		 SEF.PK_SubEvent = CSET.PK_SubEvent
		 AND
		 SEF.PK_Distributor = CSET.PK_Distributor
		 AND
		 ISNULL(SEF.TeamStatus,'ZZ') = ISNULL(CSET.TeamStatus,'ZZ')	 
	
	CREATE INDEX IX_tSubEventFact_PK_SubEvent ON #SubEventFact (PK_SubEvent) 
	CREATE INDEX IX_tSubEventFact_PK_Distributor ON #SubEventFact (PK_Distributor) 
	CREATE INDEX IX_tSubEventFact_TeamStatus ON #SubEventFact (TeamStatus)	

	/******************************************************************************
		Get Diamonds for Pres Teams
	******************************************************************************/
	IF OBJECT_ID('tempdb..#Diamonds') IS NOT NULL DROP TABLE #Diamonds 

	CREATE TABLE #Diamonds (
		PK_SubEvent int
		,PK_Distributor int
		,TeamStatus varchar(10)
		,Diamonds int DEFAULT 0
	)

	INSERT INTO #Diamonds(
		PK_SubEvent
		,PK_Distributor
		,TeamStatus
		,Diamonds
	)
	SELECT
		E.PK_SubEvent
		,D.nDistributorID
		,D.sSubTeam 
		,DP.CurrentDiamondLvl
	FROM
		#Stars DP
	INNER JOIN
		dbo.v_Distributor D
	ON
		DP.PK_Distributor = D.nDistributorID
		AND
		ISNULL(CurrentDiamondLvl,0) > 0
	INNER JOIN 
		#SubEvents E 
	ON
		E.IsDiamondRptReqd = 1

	CREATE INDEX IX_#Diamonds_PK_Distributor ON #Diamonds (PK_Distributor) 
	CREATE INDEX IX_#Diamonds_TeamStatus ON #Diamonds (TeamStatus)		
	/******************************************************************************

		Get Aggregate data at Team level - Registered and Potential count
	
	******************************************************************************/
	 
	IF OBJECT_ID('tempdb..#SubEventMetricsByTeam') IS NOT NULL DROP TABLE #SubEventMetricsByTeam

	CREATE TABLE #SubEventMetricsByTeam (
		 PK_SubEvent int
		,TeamStatus varchar(10)
		,SortBy int default 99
		,Diamonds int default 0
		,RegisteredDS int DEFAULT 0
		,VerifiedAttendees int DEFAULT 0
		,PotentialAttendees int DEFAULT 0
	)

	INSERT INTO #SubEventMetricsByTeam(PK_SubEvent,TeamStatus,SortBy,Diamonds,RegisteredDS,VerifiedAttendees,PotentialAttendees)
	SELECT
		 SEF.PK_SubEvent
		,CASE ISNULL(SE.IsBBBreakDownReqd,0) 
			WHEN 1 THEN
				CASE SEF.TeamStatus 
					WHEN 'PY' THEN 'P'
					WHEN 'P' THEN 'P'
					WHEN 'PT' THEN 'PT'
					WHEN 'A'  THEN 'A'
					WHEN '15K'  THEN '15K'
					WHEN 'B'  THEN 'B'
					WHEN '20K'  THEN '20K'
					WHEN 'C'  THEN 'C'
					WHEN '30K'  THEN '30K'
					WHEN '40K'  THEN '40K'
					WHEN '50K'  THEN '50K'
					WHEN '60K'  THEN '60K'
					WHEN '70K'  THEN '70K'
					WHEN '80K'  THEN '80K'
					WHEN '90K'  THEN '90K'
					WHEN 'CC'  THEN 'CC'
					WHEN 'FC'  THEN 'FC'
					WHEN 'M'  THEN 'M'
					WHEN 'MT'  THEN 'M'
					WHEN 'MY' THEN 'M'
					WHEN 'MP' THEN 'MP'
					WHEN 'G'  THEN 'G'
					WHEN 'GT'  THEN 'G'
					WHEN 'GY' THEN 'G'
					WHEN 'GP' THEN 'GP'
					WHEN 'W'  THEN 'W'
					WHEN 'WT'  THEN 'W'
					WHEN 'WY' THEN 'W'
					WHEN 'SP' THEN 'SP'
					WHEN 'X'  THEN '-'
					WHEN 'XY' THEN '-'
					WHEN ''   THEN '-'
					WHEN 'N'  THEN '-'
				ELSE '-' END 
			ELSE 
				CASE SEF.TeamStatus 
					WHEN 'PY' THEN 'P'
					WHEN 'P' THEN 'P'
					WHEN 'PT' THEN 'P'
					WHEN 'A'  THEN 'P'
					WHEN '15K'  THEN 'P'
					WHEN 'B'  THEN 'P'
					WHEN '20K'  THEN 'P'
					WHEN 'C'  THEN 'P'
					WHEN '30K'  THEN 'P'
					WHEN '40K'  THEN 'P'
					WHEN '50K'  THEN 'P'
					WHEN '60K'  THEN 'P'
					WHEN '70K'  THEN 'P'
					WHEN '80K'  THEN 'P'
					WHEN '90K'  THEN 'P'
					WHEN 'CC'  THEN 'P'
					WHEN 'FC'  THEN 'P'
					WHEN 'M'  THEN 'M'
					WHEN 'MT'  THEN 'M'
					WHEN 'MY' THEN 'M'
					WHEN 'MP' THEN 'M'
					WHEN 'G'  THEN 'G'
					WHEN 'GT'  THEN 'G'
					WHEN 'GY' THEN 'G'
					WHEN 'GP' THEN 'G'
					WHEN 'W'  THEN '-'
					WHEN 'WT'  THEN '-'
					WHEN 'WY' THEN '-'
					WHEN 'SP' THEN '-'
					WHEN 'X'  THEN '-'
					WHEN 'XY' THEN '-'
					WHEN ''   THEN '-'
					WHEN 'N'  THEN '-'
				ELSE '-' END 
			END AS Team	
		,CASE ISNULL(SE.IsBBBreakDownReqd,0) 
			WHEN 1 THEN
				CASE SEF.TeamStatus 
					WHEN 'PY' THEN 12
					WHEN 'P' THEN 12
					WHEN 'PT' THEN 12
					WHEN 'A' THEN 10
					WHEN '15K' THEN 11
					WHEN 'B' THEN 9
					WHEN '20K' THEN 10
					WHEN 'C' THEN 7
					WHEN '30K' THEN 9
					WHEN '40K' THEN 8
					WHEN '50K' THEN 7
					WHEN '60K' THEN 6
					WHEN '70K' THEN 5
					WHEN '80K' THEN 4
					WHEN '90K' THEN 3
					WHEN 'CC' THEN 2
					WHEN 'FC' THEN 1
					WHEN 'M' THEN 13
					WHEN 'MT' THEN 13
					WHEN 'MY' THEN 13
					WHEN 'MP' THEN 13
					WHEN 'G' THEN 14
					WHEN 'GT' THEN 14
					WHEN 'GY' THEN 14
					WHEN 'GP' THEN 14
					WHEN 'W' THEN 15
					WHEN 'WT' THEN 15
					WHEN 'WY' THEN 15
					WHEN 'SP' THEN 16
					WHEN 'X'  THEN 17
					WHEN 'XY' THEN 17
					WHEN ''   THEN 17
					WHEN 'N'  THEN 17
				ELSE 17 END  
			ELSE 
				CASE SEF.TeamStatus 
					WHEN 'PY' THEN 1
					WHEN 'P' THEN 1
					WHEN 'PT' THEN 1
					WHEN 'A' THEN 1
					WHEN '15K' THEN 1
					WHEN 'B' THEN 1
					WHEN '20K' THEN 1
					WHEN 'C' THEN 1
					WHEN '30K' THEN 1
					WHEN '40K' THEN 1
					WHEN '50K' THEN 1
					WHEN '60K' THEN 1
					WHEN '70K' THEN 1
					WHEN '80K' THEN 1
					WHEN '90K' THEN 1
					WHEN 'CC' THEN 1
					WHEN 'FC' THEN 1
					WHEN 'M' THEN 2
					WHEN 'MT' THEN 2
					WHEN 'MY' THEN 2
					WHEN 'MP' THEN 2
					WHEN 'G' THEN 3
					WHEN 'GT' THEN 3
					WHEN 'GY' THEN 3
					WHEN 'GP' THEN 3
					WHEN 'W' THEN 4
					WHEN 'WT' THEN 4
					WHEN 'WY' THEN 4
					WHEN 'SP' THEN 4
					WHEN 'X'  THEN 4
					WHEN 'XY' THEN 4
					WHEN ''   THEN 4
					WHEN 'N'  THEN 4
				ELSE 4 END 
			END AS SortBy
		,ISNULL(D.Diamonds,0)
		,COUNT(SEF.RegisteredDS) As RegisteredDS
		,SUM(SEF.RegisteredDS) As VerifiedAttendees	
		,SUM(SEF.MaxTicketCanUse) As PotentialAttendees
	FROM
		#SubEventFact (NOLOCK) SEF
	INNER JOIN
		#SubEvents (NOLOCK) SE
		ON SEF.PK_SubEvent = SE.PK_SubEvent
	LEFT JOIN
		#Diamonds D 
	ON
		SEF.PK_Distributor = D.PK_Distributor 
		AND
		SEF.TeamStatus = D.TeamStatus
		AND
		SEF.PK_SubEvent = D.PK_SubEvent 
	GROUP BY
		 SEF.PK_SubEvent
		,SEF.TeamStatus
		,ISNULL(D.Diamonds,0)
		,CASE ISNULL(SE.IsBBBreakDownReqd,0) 
			WHEN 1 THEN
				CASE SEF.TeamStatus 
					WHEN 'PY' THEN 'P'
					WHEN 'P' THEN 'P'
					WHEN 'PT' THEN 'PT'
					WHEN 'A'  THEN 'A'
					WHEN '15K'  THEN '15K'
					WHEN 'B'  THEN 'B'
					WHEN '20K'  THEN '20K'
					WHEN 'C'  THEN 'C'
					WHEN '30K'  THEN '30K'
					WHEN '40K'  THEN '40K'
					WHEN '50K'  THEN '50K'
					WHEN '60K'  THEN '60K'
					WHEN '70K'  THEN '70K'
					WHEN '80K'  THEN '80K'
					WHEN '90K'  THEN '90K'
					WHEN 'CC'  THEN 'CC'
					WHEN 'FC'  THEN 'FC'
					WHEN 'M'  THEN 'M'
					WHEN 'MT'  THEN 'M'
					WHEN 'MY' THEN 'M'
					WHEN 'MP' THEN 'MP'
					WHEN 'G'  THEN 'G'
					WHEN 'GT'  THEN 'G'
					WHEN 'GY' THEN 'G'
					WHEN 'GP' THEN 'GP'
					WHEN 'W'  THEN 'W'
					WHEN 'WT'  THEN 'W'
					WHEN 'WY' THEN 'W'
					WHEN 'SP' THEN 'SP'
					WHEN 'X'  THEN '-'
					WHEN 'XY' THEN '-'
					WHEN ''   THEN '-'
					WHEN 'N'  THEN '-'
				ELSE '-' END 
			ELSE 
				CASE SEF.TeamStatus 
					WHEN 'PY' THEN 'P'
					WHEN 'P' THEN 'P'
					WHEN 'PT' THEN 'P'
					WHEN 'A'  THEN 'P'
					WHEN '15K'  THEN 'P'
					WHEN 'B'  THEN 'P'
					WHEN '20K'  THEN 'P'
					WHEN 'C'  THEN 'P'
					WHEN '30K'  THEN 'P'
					WHEN '40K'  THEN 'P'
					WHEN '50K'  THEN 'P'
					WHEN '60K'  THEN 'P'
					WHEN '70K'  THEN 'P'
					WHEN '80K'  THEN 'P'
					WHEN '90K'  THEN 'P'
					WHEN 'CC'  THEN 'P'
					WHEN 'FC'  THEN 'P'
					WHEN 'M'  THEN 'M'
					WHEN 'MT'  THEN 'M'
					WHEN 'MY' THEN 'M'
					WHEN 'MP' THEN 'M'
					WHEN 'G'  THEN 'G'
					WHEN 'GT'  THEN 'G'
					WHEN 'GY' THEN 'G'
					WHEN 'GP' THEN 'G'
					WHEN 'W'  THEN '-'
					WHEN 'WT' THEN '-'
					WHEN 'WY' THEN '-'
					WHEN 'SP' THEN '-'
					WHEN 'X'  THEN '-'
					WHEN 'XY' THEN '-'
					WHEN ''   THEN '-'
					WHEN 'N'  THEN '-'
				ELSE '-' END 
			END 	
		,CASE ISNULL(SE.IsBBBreakDownReqd,0) 
			WHEN 1 THEN
				CASE SEF.TeamStatus 
					WHEN 'PY' THEN 12
					WHEN 'P' THEN 12
					WHEN 'PT' THEN 12
					WHEN 'A' THEN 10
					WHEN '15K' THEN 11
					WHEN 'B' THEN 9
					WHEN '20K' THEN 10
					WHEN 'C' THEN 7
					WHEN '30K' THEN 9
					WHEN '40K' THEN 8
					WHEN '50K' THEN 7
					WHEN '60K' THEN 6
					WHEN '70K' THEN 5
					WHEN '80K' THEN 4
					WHEN '90K' THEN 3
					WHEN 'CC' THEN 2
					WHEN 'FC' THEN 1
					WHEN 'M' THEN 13
					WHEN 'MT' THEN 13
					WHEN 'MY' THEN 13
					WHEN 'MP' THEN 13
					WHEN 'G' THEN 14
					WHEN 'GT' THEN 14
					WHEN 'GY' THEN 14
					WHEN 'GP' THEN 14
					WHEN 'W' THEN 15
					WHEN 'WT' THEN 15
					WHEN 'WY' THEN 15
					WHEN 'SP' THEN 16
					WHEN 'X'  THEN 17
					WHEN 'XY' THEN 17
					WHEN ''   THEN 17
					WHEN 'N'  THEN 17
				ELSE 17 END
			ELSE 
				CASE SEF.TeamStatus 
					WHEN 'PY' THEN 1
					WHEN 'P' THEN 1
					WHEN 'PT' THEN 1
					WHEN 'A' THEN 1
					WHEN '15K' THEN 1
					WHEN 'B' THEN 1
					WHEN '20K' THEN 1
					WHEN 'C' THEN 1
					WHEN '30K' THEN 1
					WHEN '40K' THEN 1
					WHEN '50K' THEN 1
					WHEN '60K' THEN 1
					WHEN '70K' THEN 1
					WHEN '80K' THEN 1
					WHEN '90K' THEN 1
					WHEN 'CC' THEN 1
					WHEN 'FC' THEN 1
					WHEN 'M' THEN 2
					WHEN 'MT' THEN 2
					WHEN 'MY' THEN 2
					WHEN 'MP' THEN 2
					WHEN 'G' THEN 3
					WHEN 'GT' THEN 3
					WHEN 'GY' THEN 3
					WHEN 'GP' THEN 3
					WHEN 'W' THEN 4
					WHEN 'WT' THEN 4
					WHEN 'WY' THEN 4
					WHEN 'SP' THEN 4
					WHEN 'X'  THEN 4
					WHEN 'XY' THEN 4
					WHEN ''   THEN 4
					WHEN 'N'  THEN 4
				ELSE 4 END 
			END
	ORDER BY
		 SEF.PK_SubEvent

	
	CREATE INDEX IX_tSubEventMetricsByTeam_PK_SubEvent ON #SubEventMetricsByTeam (PK_SubEvent) 
	CREATE INDEX IX_tSubEventMetricsByTeam_TeamStatus ON #SubEventMetricsByTeam (TeamStatus)		
	CREATE INDEX IX_tSubEventMetricsByTeam_SortBy ON #SubEventMetricsByTeam (SortBy)
	
	/******************************************************************************

		Get Aggregate data at SubEvent level - Registered and Potential count
	
	******************************************************************************/

	IF OBJECT_ID('tempdb..#SubEventMetricsBySubEvent') IS NOT NULL DROP TABLE #SubEventMetricsBySubEvent

	CREATE TABLE #SubEventMetricsBySubEvent(
		 PK_SubEvent int
		,RegisteredDS int DEFAULT 0
		,VerifiedAttendees int DEFAULT 0
		,PotentialAttendees int DEFAULT 0
	)
	INSERT
		#SubEventMetricsBySubEvent
	(
		 PK_SubEvent
		,RegisteredDS
		,VerifiedAttendees
		,PotentialAttendees
	)
	SELECT
		 PK_SubEvent
		,SUM(COALESCE(RegisteredDS,0)) AS RegisteredDS
		,SUM(COALESCE(VerifiedAttendees,0)) AS VerifiedAttendees
		,SUM(COALESCE(PotentialAttendees,0)) AS PotentialAttendees
	FROM
		#SubEventMetricsByTeam
	GROUP BY
		PK_SubEvent
	ORDER BY
		PK_SubEvent	
    
	CREATE INDEX IX_tSubEventMetricsBySubEvent_PK_SubEvent ON #SubEventMetricsBySubEvent (PK_SubEvent)   

	/******************************************************************************
	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
						 BLACKBERRY FORMATTED REPORT
	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	*******************************************************************************/

	/******************************************************************************
		EVENT LEVEL INFORMATION
	******************************************************************************/
	DECLARE 
		 @EventName varchar(50)
		,@RegisteredDS varchar(7)
		,@VerifiedAttendees varchar(7)
		,@TicketsSold varchar(7)
		,@UnVerifiedAttendees  varchar(7)
		,@EventLocalTimestamp smalldatetime
		,@TicketsSoldPriorReg varchar(7)
		,@VerifiedAttendeesPriorReg varchar(7)
		,@TicketsSoldOnsite varchar(7)
		,@VerifiedAttendeesOnsite varchar(7)
		,@TotalRegistrants varchar(7)
		,@TotalVerifiedRegistrants varchar(7)


	SELECT @EventName = EventName, @EventLocalTimestamp = DATEADD(hour,EventTimeZone,GETUTCDATE()) FROM dbo.Event (NOLOCK) WHERE PK_Event = @PK_Event 

	/* Pre-registrants: */

	SELECT @TicketsSoldPriorReg = COALESCE(COUNT(PK_EventTicket),0)
	FROM
		  #ET ET
		  INNER JOIN
		  #SKUP SP 
		  ON 
		  ET.PK_Event = SP.PK_Event
		  AND
		  ET.PK_SKUPurchased = SP.PK_SKUPurchased
		  AND 
		  SP.IsManual = 0
		  AND
		  ET.PK_Event = @PK_Event  
		  INNER JOIN
		  dbo.EventSKU EK (NOLOCK)
		  ON
		  SP.PK_EventSKU = EK.PK_EventSKU
		  AND
		  EK.IsEventTicketSKU = 1

	/* Verified Pre-registrants:  */
      
	SELECT @VerifiedAttendeesPriorReg = COALESCE(COUNT(DISTINCT ER.PK_EventTicket),0)
	FROM 
		   #ER ER
	INNER JOIN
		   #ET ET 
	 ON
		ER.PK_EventTicket = ET.PK_EventTicket
	INNER JOIN
		   #SKUP SP 	
	 ON
		ET.PK_SKUPurchased = SP.PK_SKUPurchased
	INNER JOIN
		  dbo.EventSKU EK (NOLOCK)
	 ON
		  SP.PK_EventSKU = EK.PK_EventSKU
		  AND
		  EK.IsEventTicketSKU = 1
	WHERE 
		ER.PK_Event = @PK_Event
		AND
		SP.IsManual = 0 
		AND
		ER.HasCheckedIn = 1  
 
	/* On-site Registrations:  */
    
	SELECT @TicketsSoldOnsite = COALESCE(SUM(SKP.Quantity * ES.NumberOfTicketsPerSKU),0)
	FROM
		  #SKUP SKP 
	INNER JOIN
		dbo.EventSKU ES (NOLOCK)
	ON
		SKP.PK_Event = ES.PK_Event 
		AND
		SKP.PK_EventSKU = ES.PK_EventSKU 
	WHERE SKP.PK_Event = @PK_Event 
		  AND 
		  IsManual = 1   
      
	/* Verified On-site registrants:  */
      
	SELECT @VerifiedAttendeesOnsite = COALESCE(COUNT(DISTINCT ER.PK_EventTicket),0)
	FROM 
		   #ER ER 
	INNER JOIN
		   #ET ET 
	 ON
		ER.PK_EventTicket = ET.PK_EventTicket
	INNER JOIN
		   #SKUP SP 	
	 ON
		ET.PK_SKUPurchased = SP.PK_SKUPurchased
	WHERE 
		ER.PK_Event = @PK_Event
		AND
		SP.IsManual = 1  
		AND
		ER.HasCheckedIn = 1     

	/* Total Registrants */    

	SELECT @TotalRegistrants = CONVERT(INTEGER,@TicketsSoldPriorReg) + CONVERT(INTEGER,@TicketsSoldOnsite)

	/* Total Verified Registrants */

	SELECT @TotalVerifiedRegistrants = CONVERT(INTEGER,@VerifiedAttendeesPriorReg) + CONVERT(INTEGER,@VerifiedAttendeesOnsite)
         
 	/* Event Info */
	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, 'Last Run: ' + CONVERT(CHAR(20),@EventLocalTimestamp)

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, 'EventName: ' + CONVERT(CHAR(50),@EventName)

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, REPLICATE(' ',35)

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, 'Event Information'

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, 'Pre-Event Ticket Sales: ' + CONVERT(CHAR(6),@TicketsSoldPriorReg)

	--INSERT INTO BlackberryReport
	--SELECT @PK_Event, @RunSequence, 'Verified Pre-registrants: ' + CONVERT(CHAR(6),@VerifiedAttendeesPriorReg)

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, 'On-site Ticket Sales: ' + CONVERT(CHAR(6),@TicketsSoldOnsite)

	--INSERT INTO BlackberryReport
	--SELECT @PK_Event, @RunSequence, 'Verified On-site Registrants: ' + CONVERT(CHAR(6),@VerifiedAttendeesOnsite)

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, REPLICATE(' ',35)

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, 'Total Tickets: ' + CONVERT(CHAR(6),@TotalRegistrants)

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, 'Total Verified Attendees(bodies): ' + CONVERT(CHAR(6),@TotalVerifiedRegistrants)

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, REPLICATE('-',35)

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, (CONVERT(VARCHAR(3),'#') + 
	REPLICATE(' ',10 - LEN(CONVERT(VARCHAR,'#'))) + 
	CONVERT(VARCHAR(10),'SubEvent'))

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, REPLICATE('-',35)

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence,  
	(CONVERT(VARCHAR(3),EventSubEventCode) +
		REPLICATE(' ',10 - LEN(CONVERT(VARCHAR,EventSubEventCode))) + 
		CONVERT(varchar(50),SubEventName)) SubEvent
	FROM 
		#SubEvents 
	ORDER BY 
		CAST(SubEventNumber AS INT)

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, REPLICATE(' ',35)

	/******************************************************************************
		SUB-EVENT LEVEL INFORMATION
	******************************************************************************/

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, (CONVERT(VARCHAR(3),'#') + 
									REPLICATE(' ',10 - LEN(CONVERT(VARCHAR,'#'))) + 
									CONVERT(VARCHAR(10),'Potential') +
									REPLICATE(' ',10 - LEN(CONVERT(VARCHAR,'Potential'))) + 
									CONVERT(VARCHAR(10),'Verified'))
	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, REPLICATE('-',35)

	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence, 
		 (CONVERT(VARCHAR(3),SE.EventSubEventCode) + REPLICATE(' ',10 - LEN(CONVERT(VARCHAR,EventSubEventCode))) + 
		  CONVERT(varchar(6),SEM.PotentialAttendees) + REPLICATE(' ',10 - LEN(CONVERT(VARCHAR,SEM.PotentialAttendees))) + 
		  CONVERT(varchar(6),SEM.VerifiedAttendees))
	FROM
		#SubEventMetricsBySubEvent SEM
	INNER JOIN
		#SubEvents SE
		ON 
		SE.PK_SubEvent = SEM.PK_SubEvent  
	ORDER BY 
		 CAST(SubEventNumber AS INT)

	INSERT INTO BlackberryReport
	SELECT @PK_Event, @RunSequence, REPLICATE(' ',35)

	/******************************************************************************
		SUB-EVENT LEVEL BY TEAM INFORMATION
	******************************************************************************/

	DECLARE 
		@PK_SubEvent int
		,@EventSubEventCode varchar(3)
		,@SubEventName varchar(50)

	DECLARE subevent_cursor CURSOR FOR

	SELECT
		PK_SubEvent
	  , EventSubEventCode
	  , SubEventName
	FROM
		#SubEvents
	ORDER BY
		CAST(SubEventNumber AS INT)

	OPEN subevent_cursor
	FETCH NEXT FROM subevent_cursor INTO @PK_SubEvent,@EventSubEventCode,@SubEventName

	WHILE @@FETCH_STATUS = 0
	BEGIN

		INSERT INTO BlackberryReport 
		SELECT @PK_Event, @RunSequence,  REPLICATE('-',35)

		INSERT INTO BlackberryReport 
		SELECT @PK_Event, @RunSequence,  @EventSubEventCode + ' - ' + @SubEventName 

		INSERT INTO BlackberryReport 
		SELECT @PK_Event, @RunSequence,  REPLICATE('-',35)

		INSERT INTO BlackberryReport 
		SELECT @PK_Event, @RunSequence, (CONVERT(VARCHAR(3),'T') + 
									REPLICATE(' ',10 - LEN(CONVERT(VARCHAR,'T'))) + 
									CONVERT(VARCHAR(10),'Potential') +
									REPLICATE(' ',10 - LEN(CONVERT(VARCHAR,'Potential'))) + 
									CONVERT(VARCHAR(10),'Verified'))

		INSERT INTO BlackberryReport 
		SELECT @PK_Event, @RunSequence,
			 CONVERT(varchar(8),S.TeamStatus) + REPLICATE(' ',10 - LEN(CONVERT(varchar(8),S.TeamStatus))) + 
			 CONVERT(varchar(10),S.PotentialAttendees)  + 
			 CONVERT(varchar(10),S.VerifiedAttendees)
		FROM
		(
			SELECT
				CASE ISNULL(SE.IsDiamondRptReqd,0)  
					WHEN 0 THEN CONVERT(VARCHAR(8),S.TeamStatus) 
				ELSE 
					CONVERT(VARCHAR(8),S.TeamStatus) + ' ' + CONVERT(VARCHAR(2),S.Diamonds) + 'D' 
				END AS TeamStatus
				,CONVERT(CHAR(10),SUM(S.PotentialAttendees)) AS PotentialAttendees
				,CONVERT(CHAR(10),SUM(S.VerifiedAttendees)) AS VerifiedAttendees
				,S.SortBy 
			FROM
				#SubEventMetricsByTeam S
			INNER JOIN
				#SubEvents SE ON S.PK_SubEvent = SE.PK_SubEvent
			WHERE
				S.PK_SubEvent = @PK_SubEvent
			GROUP BY
				CASE ISNULL(SE.IsDiamondRptReqd,0)  
					WHEN 0 THEN CONVERT(VARCHAR(8),S.TeamStatus) 
				ELSE 
					CONVERT(VARCHAR(8),S.TeamStatus) + ' ' + CONVERT(VARCHAR(2),S.Diamonds) + 'D' 
				END
				,S.SortBy 	
			UNION
			SELECT
					'Tot' 
					,CONVERT(CHAR(10),sum(S.PotentialAttendees))            
					,CONVERT(CHAR(10),sum(S.VerifiedAttendees))
					,99 AS SortBy
			  FROM
					#SubEventMetricsByTeam S
			  INNER JOIN
					#SubEvents SE ON S.PK_SubEvent = SE.PK_SubEvent
			  WHERE
					S.PK_SubEvent = @PK_SubEvent
		) S
		ORDER BY
			SortBy 

		FETCH NEXT FROM subevent_cursor INTO @PK_SubEvent,@EventSubEventCode,@SubEventName
	END

	CLOSE subevent_cursor
	DEALLOCATE subevent_cursor

	/******************************************************************************
		  Registration By REGION
	******************************************************************************/

	INSERT INTO BlackberryReport 
		SELECT @PK_Event, @RunSequence,  REPLICATE('-',45)

	INSERT INTO BlackberryReport 
		SELECT @PK_Event, @RunSequence, (CONVERT(VARCHAR(20),'Region') + 
									REPLICATE(' ',25 - LEN(CONVERT(VARCHAR,'Region'))) + 
									CONVERT(VARCHAR(10),'Potential') +
									REPLICATE(' ',10 - LEN(CONVERT(VARCHAR,'Potential'))) + 
									CONVERT(VARCHAR(10),'Verified'))

	INSERT INTO BlackberryReport 
		SELECT @PK_Event, @RunSequence,  REPLICATE('-',45)


	;WITH RegByCOP (PK_Distributor, RegisteredDS, MaxTicketCanUse)
	AS
	(
	SELECT PK_Distributor, MAX(RegisteredDS) AS RegisteredDS, MAX(MaxTicketCanUse) AS MaxTicketCanUse
	FROM #SubEventFact 
	GROUP BY PK_Distributor
	)
	,CountryRegion (CountryCode, Region)
	AS
	(SELECT sCountryCode, CASE WHEN sCountryCode = 'BR' THEN 'Brazil' ELSE sRegionLabel END sRegionLabel
	 FROM dbo.v_Countries 
	)
	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence,
			CONVERT(varchar(20),CASE WHEN (GROUPING(CASE WHEN R.PK_Distributor < 0 THEN '-' ELSE C.Region END ) = 1) THEN 'Tot' ELSE (CASE WHEN R.PK_Distributor < 0 THEN '-' ELSE C.Region END) END) + REPLICATE(' ',25 - LEN(CONVERT(varchar(20),CASE WHEN (GROUPING(CASE WHEN R.PK_Distributor < 0 THEN '-' ELSE C.Region END ) = 1) THEN 'Tot' ELSE (CASE WHEN R.PK_Distributor < 0 THEN '-' ELSE C.Region END) END))) + 
			CONVERT(varchar(6),SUM(R.MaxTicketCanUse))  +  REPLICATE(' ',10 - LEN(CONVERT(varchar(6),SUM(R.MaxTicketCanUse)))) + 
			CONVERT(varchar(6),SUM(R.RegisteredDS))
	FROM
		  RegByCOP R 
	LEFT JOIN
		  dbo.v_Distributor D
	ON
		  R.PK_Distributor = D.nDistributorID
	LEFT JOIN
		  CountryRegion C
	ON
		  D.sDistributorCountryProcessingCode = C.CountryCode
	GROUP BY ROLLUP
		  (CASE WHEN PK_Distributor < 0 THEN '-' ELSE C.Region END)


	/******************************************************************************
		  Registration By COP
	******************************************************************************/

	INSERT INTO BlackberryReport 
		SELECT @PK_Event, @RunSequence,  REPLICATE('-',45)

	INSERT INTO BlackberryReport 
		SELECT @PK_Event, @RunSequence, (CONVERT(VARCHAR(20),'Country') + 
									REPLICATE(' ',25 - LEN(CONVERT(VARCHAR,'Country'))) + 
									CONVERT(VARCHAR(10),'Potential') +
									REPLICATE(' ',10 - LEN(CONVERT(VARCHAR,'Potential'))) + 
									CONVERT(VARCHAR(10),'Verified'))

	INSERT INTO BlackberryReport 
		SELECT @PK_Event, @RunSequence,  REPLICATE('-',45)

	;WITH RegByCOP (PK_Distributor, RegisteredDS, MaxTicketCanUse)
	AS
	(
	SELECT PK_Distributor, MAX(RegisteredDS) AS RegisteredDS, MAX(MaxTicketCanUse) AS MaxTicketCanUse
	FROM #SubEventFact 
	GROUP BY PK_Distributor
	)
	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence,
			CONVERT(varchar(20),CASE WHEN (GROUPING(CASE WHEN R.PK_Distributor < 0 THEN '-' ELSE C.sCountryName END ) = 1) THEN 'Tot' ELSE (CASE WHEN R.PK_Distributor < 0 THEN '-' ELSE C.sCountryName END) END) + REPLICATE(' ',25 - LEN(CONVERT(varchar(20),CASE WHEN (GROUPING(CASE WHEN R.PK_Distributor < 0 THEN '-' ELSE C.sCountryName END ) = 1) THEN 'Tot' ELSE (CASE WHEN R.PK_Distributor < 0 THEN '-' ELSE C.sCountryName END) END))) + 
			CONVERT(varchar(6),SUM(R.MaxTicketCanUse))  +  REPLICATE(' ',10 - LEN(CONVERT(varchar(6),SUM(R.MaxTicketCanUse)))) + 
			CONVERT(varchar(6),SUM(R.RegisteredDS)) 
	FROM
		  RegByCOP R 
	LEFT JOIN
		  dbo.v_Distributor D
	ON
		  R.PK_Distributor = D.nDistributorID
	LEFT JOIN
		  dbo.v_Countries C
	ON
		  D.sDistributorCountryProcessingCode = C.sCountryCode
	GROUP BY ROLLUP
		  (CASE WHEN PK_Distributor < 0 THEN '-' ELSE C.sCountryName END)

	/******************************************************************************
		  Registration By Day
	******************************************************************************/

	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence, REPLICATE('-',35)

	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence,'Registration By Day'

	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence, REPLICATE('-',35)

	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence, (CONVERT(VARCHAR(20),'Date') + 
									REPLICATE(' ',20 - LEN(CONVERT(VARCHAR,'Date'))) + 
									CONVERT(VARCHAR(10),'Registered'))


	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence,
		   CONVERT(varchar(18),DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC),107) + 
		   REPLICATE(' ',20 - LEN(CONVERT(varchar(18),DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC),107))) +
		   CONVERT(varchar(6),COUNT(ER.PK_EventsRegistration))
	FROM
		  #ER ER 
	INNER JOIN
		  dbo.Event E (NOLOCK)
	ON 
		  ER.PK_Event = E.PK_Event
	WHERE
		  ER.PK_Event = @PK_Event
		  AND
		  ER.HasCheckedIn = 1 
	GROUP BY
		  CONVERT(varchar(18),DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC),107)
	ORDER BY
		  datepart("yyyy",CONVERT(varchar(18),DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC),107))
		 ,datepart("mm",CONVERT(varchar(18),DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC),107)) desc
		 ,datepart("dd",CONVERT(varchar(18),DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC),107)) desc


 
	/******************************************************************************
		  Registration By Hour
	******************************************************************************/

	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence, REPLICATE('-',35)

	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence, 'Registration By Hour'

	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence, REPLICATE('-',35)

	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence, (CONVERT(VARCHAR(10),'LocDate') + 
									REPLICATE(' ',15 - LEN(CONVERT(VARCHAR,'LocDate'))) + 
									CONVERT(VARCHAR(7),'LocHour') + 
									REPLICATE(' ',10 - LEN(CONVERT(VARCHAR,'LocHour'))) + 
									CONVERT(VARCHAR(10),'PSTDate') + 
									REPLICATE(' ',15 - LEN(CONVERT(VARCHAR,'PSTDate'))) + 
									CONVERT(VARCHAR(7),'PSTHour') + 
									REPLICATE(' ',10 - LEN(CONVERT(VARCHAR,'PSTHour'))) + 
									CONVERT(VARCHAR(10),'Registered')) 

	INSERT INTO BlackberryReport 
	SELECT @PK_Event, @RunSequence,
		   CONVERT(varchar(10),DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC),110) + 
		   REPLICATE(' ',15 - LEN(CONVERT(varchar(10),DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC),110))) +
		   CONVERT(varchar(7),DATEPART(hh,DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC))) + 
		   REPLICATE(' ',10 - LEN(CONVERT(varchar(7),DATEPART(hh,DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC))))) +
		   CONVERT(varchar(10),DATEADD(hour,-8,ER.ModifiedDateUTC),110) +
		   REPLICATE(' ',15 - LEN(CONVERT(varchar(10),DATEADD(hour,-8,ER.ModifiedDateUTC),110))) +
		   CONVERT(varchar(7),DATEPART(hh,DATEADD(hour,-8,ER.ModifiedDateUTC))) +
		   REPLICATE(' ',10 - LEN(CONVERT(varchar(7),DATEPART(hh,DATEADD(hour,-8,ER.ModifiedDateUTC))))) +
		   CONVERT(varchar(6),COUNT(ER.PK_EventsRegistration))
	FROM
		  #ER ER 
	INNER JOIN
		  dbo.Event E (NOLOCK)
	ON 
		  ER.PK_Event = E.PK_Event
	WHERE
		  ER.PK_Event = @PK_Event
		  AND
		  ER.HasCheckedIn = 1 
	GROUP BY
		  CONVERT(varchar(10),DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC),110)
		 ,CONVERT(int,DATEPART(hh,DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC)))
		 ,CONVERT(varchar(10),DATEADD(hour,-8,ER.ModifiedDateUTC),110)
		 ,CONVERT(int,DATEPART(hh,DATEADD(hour,-8,ER.ModifiedDateUTC)))     
	ORDER BY
		  datepart("yyyy",CONVERT(varchar(10),DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC),110)) desc
		 ,datepart("mm",CONVERT(varchar(10),DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC),110)) desc
		 ,datepart("dd",CONVERT(varchar(10),DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC),110)) desc
		 ,CONVERT(int,DATEPART(hh,DATEADD(hour,E.EventTimeZone,ER.ModifiedDateUTC))) desc

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
		RETURN 
	END CATCH;
END;
GO

