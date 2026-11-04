CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventsandPromotionsListView]
    --Mandatory Parameters
	 @DistributorID varchar(10)
	,@Locale char(5) = NULL
	,@TargetLocales udt_EventDistributorCountryLocales READONLY -- Search Events by their Target Locale
	--Optional Parameters
	,@EventSubType NVARCHAR(400)

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_EventsandPromotionsListView

USE:	        
		DECLARE @e int, @em varchar(4000)
		, @TargetLocales udt_EventDistributorCountryLocales
				insert into @TargetLocales VALUES(74,0), (73,0)
				
                 EXEC dbo.usp_MyHLEventAPI_Get_EventsandPromotionsListView
					 	 @DistributorID = '2222222222'
						,@Locale = 'es-MX'
						,@TargetLocales = @TargetLocales
						,@EventSubType = NULL
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves all the qualified events for a DS ID and all the associated events 
				and promotions parameters

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.Subevent, dbo.SubeventQualification, dbo.SubeventQualifier

VERSIONS
----------------------------------------------------------------------------------
1	2010-10-05	Prabhu	   Intitial
2   2013-07-25  Juan       @PK_EventSubType -> @EventSubType
3   2014-09-22  SandhyaP   IsQualified logic is calculated based on Subevents that has IsMainEventQual flagged as 1 when publishTracking is enabled
4	2014-12-22	SushmaA	   Ticket Details CR		
5	2019-08-14	NoeG		Refactor code (SRE)
6	2019-10-30	NoeG		SRE Hardcode changed

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE()
		,@ValidDate DATETIME = '2049-12-31'
	
/* ***************** SonarQube check 101 and 102 - Output parameters should be assigned 
	SRE changes added
*/
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

		DECLARE @StartDate SMALLDATETIME
		DECLARE @PK_EventType INT
		DECLARE @PK_Distributor INT
		DECLARE @PK_Event INT
		DECLARE @PK_Locale INT
		DECLARE @StartRoyaltyMonth DATETIME
		DECLARE @EndRoyaltyMonth DATETIME
		DECLARE @QualPeriodStart DATETIME
		DECLARE @QualPeriodEnd DATETIME
		DECLARE @CountryCode CHAR(2)
		DECLARE @PK_Country INT
		DECLARE @SubTypeCode VARCHAR(5)
		DECLARE @PK_Order INT
		DECLARE @PK_EventSubType INT
		DECLARE @tblEventSubTypes TABLE (PK_EventSubType INT)
		DECLARE @Country VARCHAR(5) = NULL
		DECLARE @Events AS TABLE (PK_Event INT)
		DECLARE @PK_DefaultLocale INT

		/******************************************************************************
			SET VALUES FOR THE REQUIRED VARIABLES
		******************************************************************************/

		INSERT @tblEventSubTypes 
		SELECT PK_EventSubType FROM dbo.EventSubTypes WITH(NOLOCK) WHERE EventSubType = COALESCE(@EventSubType, EventSubType) 

		SET @StartDate = GETDATE()
		--SET @PK_EventSubType = CASE WHEN ISNULL(@PK_EventSubType,'') = '' THEN NULL ELSE @PK_EventSubType END
		--SET @Region= CASE WHEN ISNULL(@Region,'') = '' THEN NULL ELSE @Region END

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode = @Locale
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event WITH(NOLOCK) WHERE PK_Event = @PK_Event
		SET @CountryCode = SUBSTRING(@Locale,4,2)

		SELECT @PK_Country = nCountryID FROM dbo.v_Countries WHERE sCountryCodeISO = @CountryCode

		SELECT
			@SubTypeCode = S.SubTypeCode
		FROM
			PubEvents.dbo.dimDistributor D  WITH(NOLOCK)
		INNER JOIN
			PubEvents.dbo.dimDSSubType S  WITH(NOLOCK)
		ON
			D.PK_DSSubType = S.PK_DSSubType
		WHERE
			D.DistributorID = @DistributorID

		SELECT @PK_Order = TeamOrder FROM dbo.DSTeamType WITH(NOLOCK) WHERE DSTeamTypeCode = @SubTypeCode

		/******************************************************************************
			CREATE ALL THE NEEDED TEMP TABLES
		******************************************************************************/
		IF OBJECT_ID('tempdb..#Tickets') IS NOT NULL
			DROP TABLE #Tickets

		CREATE TABLE #Tickets
		(
			 PK INT IDENTITY(1,1)
			,PK_Event INT
			,PK_Distributor INT
			,PK_EventSKU INT
			,TicketsPurchased INT
			,TicketsWithMe INT
			,TicketsAssignedByMe INT
			,TicketsAssignedToMe INT
			,CanAssignTickets INT
			,IsEventTicketSKU BIT
		)


		IF OBJECT_ID('tempdb..#Events') IS NOT NULL
			DROP TABLE #Events

		CREATE TABLE #Events
		(
			 PK INT IDENTITY(1,1)
			,PK_Event INT 
			,EventName nVARCHAR(400)
			,IsTicketPurchaseRequired BIT
			,EventVenueName	nVARCHAR(1000)
			,EventLocation nVARCHAR(MAX)
			,QualPeriod VARCHAR(200)
			,SKUCode VARCHAR(100)
			,TotalTicketsPurchased INT
			,IsQualified BIT
			,IsQualifytoPurchaseTickets BIT
			,EventDate VARCHAR(100)
			,sCountryName VARCHAR(100)
			,sCountryCodeISO VARCHAR(10)
			,sRegionCode VARCHAR(10)
			,sRegionLabel VARCHAR(100)
			,EventStartDate SMALLDATETIME
			,EventEnddate SMALLDATETIME
			,QualPeriodStartDate DATETIME
			,QualPeriodEndDate DATETIME
			,CanDisplayTicketDetails BIT
			,IsTicketforQualifiedDS BIT
			,TicketThirdPartyLink BIT
			,ThirdPartyLink nVARCHAR(MAX)
		)



		/* SELECT ALL THE QUALIFIED EVENTS DETAILS FOR THE DISTRIBUTORS THAT WAS PASSED */
		INSERT INTO #Events (PK_Event, EventName, IsTicketPurchaseRequired, EventVenueName, EventLocation, QualPeriod, SKUCode, TotalTicketsPurchased, IsQualified, IsQualifytoPurchaseTickets
								,EventDate, sCountryName, sCountryCodeISO, sRegionCode, sRegionLabel, EventStartDate, EventEnddate, QualPeriodStartDate, QualPeriodEndDate, CanDisplayTicketDetails 
								,IsTicketforQualifiedDS, TicketThirdPartyLink, ThirdPartyLink)

		SELECT
			 DISTINCT 
			 E.PK_Event
			,COALESCE(ED.EventName, ED1.EventName, E.EventName) EventName
			,E.CanPurchaseTicketOnline IsTicketPurchaseRequired
			,ISNULL(ED.EventLocation, E.EventVenueName) EventVenueName
			,CASE WHEN ISNULL(ED.EventCity,E.EventCity) IS NULL THEN '' ELSE ISNULL(ED.EventCity,E.EventCity) END  + CASE WHEN (ISNULL(ED.EventCity,E.EventCity) IS NOT NULL AND ISNULL(ED.EventState,E.EventState) IS NOT NULL)  THEN  ', ' ELSE '' END + CASE WHEN ISNULL(ED.EventState,E.EventState) IS NULL THEN '' ELSE ISNULL(ED.EventState,E.EventState) END EventLocation
			,CASE WHEN E.QualPeriodStart = E.QualPeriodEnd THEN CONVERT(VARCHAR(10),E.QualPeriodStart,110) ELSE CONVERT(VARCHAR(10),E.QualPeriodStart,110) + ' - ' + CONVERT(VARCHAR(10), E.QualPeriodEnd, 110) END QualPeriod
			,EK.SKUCode
			,ISNULL(S.TotalTicketsPurchased, 0) TotalTicketsPurchased
			,CASE WHEN E.IsPublishQualTracking = 1 THEN ISNULL(B.Qualified,0) ELSE NULL END IsQualified
			,ISNULL(E.IsQualifytoPurchaseTickets,0) IsQualifytoPurchaseTickets
			,CASE WHEN E.dStartUTC = E.dEndUTC THEN CONVERT(VARCHAR(10),E.dStartUTC,110) ELSE CONVERT(VARCHAR(10),E.dStartUTC,110) + ' - ' + CONVERT(VARCHAR(10), E.dEndUTC, 110) END EventDate
			,EC.sCountryName
			,EC.sCountryCodeISO
			,EC.sRegionCode
			,EC.sRegionLabel
			,E.dStartUTC EventStartDate
			,E.dEndUTC EventEnddate
			,E.QualPeriodStart QualPeriodStartDate
			,E.QualPeriodEnd QualPeriodEndDate
			,E.CanDisplayTicketDetails
			,E.IsTicketforQualifiedDS
			,E.TicketThirdPartyLink
			,COALESCE(EUL.EventURL, EUD.EventURL) ThirdPartyLink
		FROM
			dbo.Event E  WITH(NOLOCK)
		INNER JOIN
			(SELECT SE.PK_Event, COUNT(0) AS [Count] FROM dbo.SubEvent SE WITH(NOLOCK) GROUP BY SE.PK_Event)	SE
		ON 
			E.PK_Event = SE.PK_Event
		INNER JOIN
			dbo.EventDistributorCountryLocales EDLC  WITH(NOLOCK)
			--E.PK_Event = EC.PK_Event
		ON
			E.PK_Event = EDLC.PK_Event
		INNER JOIN
			@TargetLocales TL
		ON
			EDLC.PK_Locale = TL.PK_Locale
		INNER JOIN
		(
			SELECT EC.PK_Event, C.sCountryName , C.sCountryCode, C.sCountryCodeISO, C.sRegionCode, C.sRegionLabel
			 FROM dbo.EventCountry EC WITH(NOLOCK) INNER JOIN v_Countries C ON EC.PK_Country = C.nCountryID
		)EC
		ON
			EDLC.PK_Event = EC.PK_Event
		INNER JOIN
			dbo.EventEventSubType EST  WITH(NOLOCK)
		ON
			E.PK_Event = EST.PK_Event
		INNER JOIN
			@tblEventSubTypes T
		ON
			T.PK_EventSubType = EST.PK_EventSubType
			--AND
			--EST.PK_EventSubType = COALESCE(@PK_EventSubType,EST.PK_EventSubType)
		INNER JOIN
		(
		SELECT
			   M.PK_Event
			  ,M.DSteamTypeCode
			  ,M.TeamOrder
			  ,M.DSTeamTypeDesc
		FROM
		 (
			  SELECT
					 C.PK_Event
					,DT.DSteamTypeCode
					,C.TeamOrder
					,COALESCE(LT.DSTeamTypeDesc,LT1.DSTeamTypeDesc,LT2.DSTeamTypeDesc)DSTeamTypeDesc
			  FROM
					dbo.EventDSteamType EDT WITH(NOLOCK)
			  INNER JOIN
					dbo.DSTeamType DT WITH(NOLOCK)
			  ON
					EDT.DSTeamTypeCode = COALESCE(@SubTypeCode,DT.DSteamTypeCode)
			  INNER JOIN
					(SELECT
						   PK_Event PK_Event
						  ,MAX(B.TeamOrder) TeamOrder
					 FROM
						  dbo.EventDSteamType A WITH(NOLOCK)
					 INNER JOIN
						  dbo.DSTeamType B WITH(NOLOCK)
					 ON
						  A.DSTeamTypeCode = B.DSTeamTypeCode
					 GROUP BY
						   PK_Event
					)C
			  ON
					EDT.PK_Event = C.PK_Event
			  AND
					DT.TeamOrder = C.TeamOrder
			  INNER JOIN
					dbo.Event E WITH(NOLOCK)
				ON
					EDT.PK_Event = E.PK_Event
			  LEFT JOIN
					dbo.DSTeamTypeLocaleDesc LT WITH(NOLOCK)
			 ON
					DT.DSTeamTypeCode = LT.DSTeamTypeCode
					AND LT.PK_Locale = @PK_Locale
			  LEFT JOIN
					dbo.DSTeamTypeLocaleDesc LT1 WITH(NOLOCK)
			 ON
					DT.DSTeamTypeCode = LT1.DSTeamTypeCode
					AND LT1.PK_Locale = E.PK_DefaultLocale
			  LEFT JOIN
					dbo.DSTeamTypeLocaleDesc LT2 WITH(NOLOCK)
			 ON
					DT.DSTeamTypeCode = LT2.DSTeamTypeCode
					AND LT2.PK_Locale = (SELECT PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode ='en-US')
		)m)m
		ON
			E.PK_Event = M.PK_Event	
		INNER JOIN
			dbo.DSTeamType DTL WITH(NOLOCK)	
		ON
			DTL.DSTeamTypeCode = M.DSTeamTypeCode
		LEFT JOIN
			dbo.EventDSTeamType EDT WITH(NOLOCK)
		ON
			E.PK_Event = EDT.PK_Event
			AND EDT.DSTeamTypeCode = @SubTypeCode
		LEFT JOIN
			dbo.EventLocaleDesc ED  WITH(NOLOCK)
		ON
			E.PK_Event = ED.PK_Event
			AND
			ED.PK_Locale = @PK_Locale
		LEFT JOIN
			dbo.EventLocaleDesc ED1  WITH(NOLOCK)
		ON
			E.PK_Event = ED1.PK_Event
			AND
			ED1.PK_Locale = E.PK_DefaultLocale
		LEFT JOIN
			(SELECT DISTINCT SQ.PK_Event, DistributorID, SQ.Qualified
			 FROM dbo.SubEventQualifier SQ  WITH(NOLOCK) 
			 INNER JOIN dbo.SubEvent SE WITH(NOLOCK) ON SQ.PK_SubEvent = SE.PK_SubEvent  AND SE.IsMainEventQual = 1
			 WHERE DistributorID = @DistributorID AND SQ.RemovedUTC = @ValidDate)B
		ON
			E.PK_Event = B.PK_Event
		LEFT JOIN
			(SELECT PK_Event, MIN(SKUValidBeginUTC) SKUDate, MIN(PK_EventSKU) EventSKU 
			 FROM dbo.EventSKU WITH(NOLOCK) 
			 WHERE @StartDate BETWEEN SKUValidBeginUTC AND SKUValidEndUTC
			 AND IsEventTicketSKU = 1
			 --AND PK_Country = @PK_Country
			 GROUP BY PK_Event) D
		ON
			E.PK_Event = D.PK_Event
		LEFT JOIN
			dbo.EventSKU EK  WITH(NOLOCK)
		ON
			D.PK_Event = EK.PK_Event AND D.EventSKU = EK.PK_EventSKU				
		LEFT JOIN
			--(SELECT PK_Event, SUM(Quantity) TotalTicketsPurchased FROM dbo.SKUPurchased (NOLOCK)WHERE DistributorID = @DistributorID GROUP BY PK_Event) S
			(SELECT ETA.PK_Event, COUNT(0) as [TotalTicketsPurchased] 
				FROM dbo.EventTicketAssignment ETA WITH(NOLOCK)  
				INNER JOIN dbo.EventTickets ET WITH(NOLOCK) ON ETA.PK_EventTicket = ET.PK_EventTicket  AND ETA.PK_Event = ET.PK_Event
				WHERE ETA.ValidToDateUTC = @ValidDate AND ETA.PK_ToDistributor = @PK_Distributor 
				GROUP BY ETA.PK_Event) S
		ON
			E.PK_Event = S.PK_Event	
		LEFT JOIN
			dbo.EventURL EUL WITH(NOLOCK)
		ON
			E.PK_Event = EUL.PK_Event
		AND 
			EUL.PK_EventURLType = 5 -- for third party link
		AND
			EUL.PK_Locale = @PK_Locale
		LEFT JOIN
			dbo.EventURL EUD WITH(NOLOCK)
		ON
			E.PK_Event = EUD.PK_Event
		AND 
			EUD.PK_EventURLType = 5
		AND
			EUD.PK_Locale = E.PK_DefaultLocale
		WHERE
			@StartDate <= E.dEndUTC +1
		AND
			GETUTCDATE() BETWEEN E.DisplayStartDate AND (E.DisplayEndDate+1)
		AND
			E.PK_EventType = 1
		AND
			E.IsActive = 1
		AND
			E.IsPublish = 1
	
		ORDER BY
			IsQualified DESC
			,E.dStartUTC DESC
			,E.dEndUTC DESC
			,EventName ASC
	
		SELECT	PK, PK_Event, EventName, IsTicketPurchaseRequired, EventVenueName, EventLocation
				, QualPeriod, SKUCode, TotalTicketsPurchased, IsQualified, IsQualifytoPurchaseTickets
				, EventDate, sCountryName, sCountryCodeISO, sRegionCode, sRegionLabel, EventStartDate
				, EventEnddate, QualPeriodStartDate, QualPeriodEndDate, CanDisplayTicketDetails
				, IsTicketforQualifiedDS, TicketThirdPartyLink, ThirdPartyLink 
		FROM	#Events ORDER BY 1

		INSERT INTO @Events (PK_Event) SELECT E.PK_Event FROM #Events E

		TRUNCATE TABLE #Events 

		/* SELECT ALL THE QUALIFIED PROMOTIONS DETAILS FOR THE DISTRIBUTORS THAT WAS PASSED */
		INSERT INTO #Events (PK_Event, EventName, IsTicketPurchaseRequired, EventVenueName, EventLocation, QualPeriod, SKUCode, TotalTicketsPurchased, IsQualified, IsQualifytoPurchaseTickets
								,EventDate, sCountryName, sCountryCodeISO, sRegionCode, sRegionLabel, EventStartDate, EventEnddate, QualPeriodStartDate, QualPeriodEndDate, CanDisplayTicketDetails 
								,IsTicketforQualifiedDS, TicketThirdPartyLink, ThirdPartyLink)

		SELECT 
			 DISTINCT 
			 E.PK_Event
			,COALESCE(ED.EventName, ED1.EventName, E.EventName) EventName
			,E.CanPurchaseTicketOnline IsTicketPurchaseRequired
			,ISNULL(ED.EventLocation, E.EventVenueName) EventVenueName
			,CASE WHEN ISNULL(ED.EventCity,E.EventCity) IS NULL THEN '' ELSE ISNULL(ED.EventCity,E.EventCity) END  + CASE WHEN (ISNULL(ED.EventCity,E.EventCity) IS NOT NULL AND ISNULL(ED.EventState,E.EventState) IS NOT NULL)  THEN  ', ' ELSE '' END + CASE WHEN ISNULL(ED.EventState,E.EventState) IS NULL THEN '' ELSE ISNULL(ED.EventState,E.EventState) END EventLocation
			,CASE WHEN E.QualPeriodStart = E.QualPeriodEnd THEN CONVERT(VARCHAR(10),E.QualPeriodStart,110) ELSE CONVERT(VARCHAR(10),E.QualPeriodStart,110) + ' - ' + CONVERT(VARCHAR(10), E.QualPeriodEnd, 110) END QualPeriod
			,EK.SKUCode
			,ISNULL(S.TotalTicketsPurchased, 0) TotalTicketsPurchased
			,CASE WHEN E.IsPublishQualTracking = 1 THEN ISNULL(B.Qualified,0) ELSE NULL END IsQualified
			,ISNULL(E.IsQualifytoPurchaseTickets,0) IsQualifytoPurchaseTickets
			,CASE WHEN E.dStartUTC = E.dEndUTC THEN CONVERT(VARCHAR(10),E.dStartUTC,110) ELSE CONVERT(VARCHAR(10),E.dStartUTC,110) + ' - ' + CONVERT(VARCHAR(10), E.dEndUTC, 110) END EventDate
			,EC.sCountryName
			,EC.sCountryCodeISO
			,EC.sRegionCode
			,EC.sRegionLabel
			,E.dStartUTC EventStartDate
			,E.dEndUTC EventEnddate
			,E.QualPeriodStart QualPeriodStartDate
			,E.QualPeriodEnd QualPeriodEndDate
			,E.CanDisplayTicketDetails
			,E.IsTicketforQualifiedDS
			,E.TicketThirdPartyLink
			,COALESCE(EUL.EventURL, EUD.EventURL) ThirdPartyLink	
		FROM
			dbo.Event E WITH(NOLOCK)
		INNER JOIN
			(SELECT SE.PK_Event, COUNT(0) AS [Count] FROM dbo.SubEvent SE WITH(NOLOCK) GROUP BY SE.PK_Event)	SE
		ON 
			E.PK_Event = SE.PK_Event
		INNER JOIN
			dbo.EventDistributorCountryLocales EDLC  WITH(NOLOCK)
			--E.PK_Event = EC.PK_Event
		ON
			E.PK_Event = EDLC.PK_Event
		INNER JOIN
			@TargetLocales TL
		ON
			EDLC.PK_Locale = TL.PK_Locale
		INNER JOIN
		(
			SELECT EC.PK_Event, C.sCountryName , C.sCountryCode, C.sCountryCodeISO, C.sRegionCode, C.sRegionLabel
			 FROM dbo.EventCountry EC WITH(NOLOCK) INNER JOIN v_Countries C ON EC.PK_Country = C.nCountryID
		)EC
		ON
			EDLC.PK_Event = EC.PK_Event
		INNER JOIN
			dbo.EventEventSubType EST WITH(NOLOCK)
		ON
			E.PK_Event = EST.PK_Event
		INNER JOIN
			@tblEventSubTypes T
		ON
			T.PK_EventSubType = EST.PK_EventSubType

			--AND
			--EST.PK_EventSubType = COALESCE(@PK_EventSubType,EST.PK_EventSubType)
		INNER JOIN
		(
		SELECT
			   M.PK_Event
			  ,M.DSteamTypeCode
			  ,M.TeamOrder
			  ,M.DSTeamTypeDesc
		FROM
		 (
			  SELECT
					 C.PK_Event
					,DT.DSteamTypeCode
					,C.TeamOrder
					,COALESCE(LT.DSTeamTypeDesc,LT1.DSTeamTypeDesc,LT2.DSTeamTypeDesc)DSTeamTypeDesc
			  FROM
					dbo.EventDSteamType EDT WITH(NOLOCK)
			  INNER JOIN
					dbo.DSTeamType DT WITH(NOLOCK)
			  ON
					EDT.DSTeamTypeCode = COALESCE(@SubTypeCode,DT.DSteamTypeCode)
			  INNER JOIN
					(SELECT
						   PK_Event PK_Event
						  ,MAX(B.TeamOrder) TeamOrder
					 FROM
						  dbo.EventDSteamType A WITH(NOLOCK)
					 INNER JOIN
						  dbo.DSTeamType B WITH(NOLOCK)
					 ON
						  A.DSTeamTypeCode = B.DSTeamTypeCode
					 GROUP BY
						   PK_Event
					)C
			  ON
					EDT.PK_Event = C.PK_Event
			  AND
					DT.TeamOrder = C.TeamOrder
			  INNER JOIN
					dbo.Event E WITH(NOLOCK)
				ON
					EDT.PK_Event = E.PK_Event
			  LEFT JOIN
					dbo.DSTeamTypeLocaleDesc LT WITH(NOLOCK)
			 ON
					DT.DSTeamTypeCode = LT.DSTeamTypeCode
					AND LT.PK_Locale = @PK_Locale
			  LEFT JOIN
					dbo.DSTeamTypeLocaleDesc LT1 WITH(NOLOCK)
			 ON
					DT.DSTeamTypeCode = LT1.DSTeamTypeCode
					AND LT1.PK_Locale = E.PK_DefaultLocale
			  LEFT JOIN
					dbo.DSTeamTypeLocaleDesc LT2 WITH(NOLOCK)
			 ON
					DT.DSTeamTypeCode = LT2.DSTeamTypeCode
					AND LT2.PK_Locale = (SELECT PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode ='en-US')
		)m)m
		ON
			E.PK_Event = M.PK_Event	
		INNER JOIN
			dbo.DSTeamType DTL	 WITH(NOLOCK)
		ON
			DTL.DSTeamTypeCode = M.DSTeamTypeCode
		LEFT JOIN
			dbo.EventDSTeamType EDT  WITH(NOLOCK)
		ON
			E.PK_Event = EDT.PK_Event
			AND EDT.DSTeamTypeCode = @SubTypeCode
		LEFT JOIN
			dbo.EventLocaleDesc ED  WITH(NOLOCK)
		ON
			E.PK_Event = ED.PK_Event
			AND
			ED.PK_Locale = @PK_Locale
		LEFT JOIN
			dbo.EventLocaleDesc ED1  WITH(NOLOCK)
		ON
			E.PK_Event = ED1.PK_Event
			AND
			ED1.PK_Locale = E.PK_DefaultLocale
		LEFT JOIN
			(SELECT DISTINCT SQ.PK_Event, DistributorID, SQ.Qualified
			 FROM dbo.SubEventQualifier SQ  WITH(NOLOCK) 
			 INNER JOIN dbo.SubEvent SE WITH(NOLOCK) ON SQ.PK_SubEvent = SE.PK_SubEvent  AND SE.IsMainEventQual = 1 
			 WHERE DistributorID = @DistributorID AND SQ.RemovedUTC = @ValidDate)B
		ON
			E.PK_Event = B.PK_Event
		LEFT JOIN
			(SELECT PK_Event, MIN(SKUValidBeginUTC) SKUDate, MIN(PK_EventSKU) EventSKU 
			 FROM dbo.EventSKU  WITH(NOLOCK)
			 WHERE @StartDate BETWEEN SKUValidBeginUTC AND SKUValidEndUTC
			-- AND PK_Country = @PK_Country
			 AND IsEventTicketSKU = 1
			 GROUP BY PK_Event) D
		ON
			E.PK_Event = D.PK_Event
		LEFT JOIN
			dbo.EventSKU EK WITH(NOLOCK)
		ON
			D.PK_Event = EK.PK_Event AND D.EventSKU = EK.PK_EventSKU	
		LEFT JOIN
			--(SELECT PK_Event, SUM(Quantity) TotalTicketsPurchased FROM dbo.SKUPurchased (NOLOCK)WHERE DistributorID = @DistributorID GROUP BY PK_Event) S
			(SELECT ETA.PK_Event, COUNT(0) as [TotalTicketsPurchased] 
				FROM dbo.EventTicketAssignment ETA WITH(NOLOCK)  
				INNER JOIN dbo.EventTickets ET WITH(NOLOCK) ON ETA.PK_EventTicket = ET.PK_EventTicket  AND ETA.PK_Event = ET.PK_Event
				WHERE ETA.ValidToDateUTC = @ValidDate AND ETA.PK_ToDistributor = @PK_Distributor 
				GROUP BY ETA.PK_Event) S
		ON
			E.PK_Event = S.PK_Event
		LEFT JOIN
			dbo.EventURL EUL WITH(NOLOCK)
		ON
			E.PK_Event = EUL.PK_Event
		AND 
			EUL.PK_EventURLType = 5 -- for third party link
		AND
			EUL.PK_Locale = @PK_Locale
		LEFT JOIN
			dbo.EventURL EUD WITH(NOLOCK)
		ON
			E.PK_Event = EUD.PK_Event
		AND 
			EUD.PK_EventURLType = 5
		AND
			EUD.PK_Locale = E.PK_DefaultLocale
		WHERE
			@StartDate <= E.dEndUTC+1
		AND
			GETUTCDATE() BETWEEN E.DisplayStartDate AND (E.DisplayEndDate+1)
		AND
			E.PK_EventType = 2
		AND
			E.IsActive = 1
		AND
			E.IsPublish = 1
		ORDER BY
			IsQualified DESC
			,E.dStartUTC DESC
			,E.dEndUTC DESC
			,EventName ASC

		SELECT	PK, PK_Event, EventName, IsTicketPurchaseRequired, EventVenueName, EventLocation
				, QualPeriod, SKUCode, TotalTicketsPurchased, IsQualified, IsQualifytoPurchaseTickets
				, EventDate, sCountryName, sCountryCodeISO, sRegionCode, sRegionLabel, EventStartDate
				, EventEnddate, QualPeriodStartDate, QualPeriodEndDate, CanDisplayTicketDetails
				, IsTicketforQualifiedDS, TicketThirdPartyLink, ThirdPartyLink  
		FROM	#Events ORDER BY 1

		INSERT INTO @Events (PK_Event) SELECT E.PK_Event FROM #Events E

		TRUNCATE TABLE #Events 

		/****  Logic to display the event ticket details  ****/

		--pick all the ticket information SKU wise - event wise
		INSERT INTO #Tickets(PK_Event, PK_Distributor, PK_EventSKU, TicketsPurchased, TicketsWithMe, TicketsAssignedByMe, TicketsAssignedToMe, CanAssignTickets, IsEventTicketSKU)
		SELECT
			  E.PK_Event
			, PK_Distributor
			, PK_EventSKU
			, TicketsPurchased
			, TicketsWithMe
			, TicketsAssignedByMe
			, TicketsAssignedToMe
			, CanAssignTickets
			, IsEventTicketSKU
		FROM	
			dbo.udf_GetTicketDetails(@PK_Event, @PK_Distributor) TF
		INNER JOIN
			@Events E
		ON
			TF.PK_Event = E.PK_Event

		--All the event tickets for Group Ticket Assignment events - eventtickets
		SELECT 
			   T.PK_Event
			 , T.PK_Distributor
			 , NULL PK_EventSKU 
			 , NULL SKUCode
			 , COALESCE(ELD.EventName, E.EventName, '') + ' - Event Ticket'   SKUDesc
			 , SUM(ISNULL(T.TicketsPurchased, 0)) TicketsPurchased
			 , SUM(ISNULL(T.TicketsAssignedByMe, 0)) TicketsAssignedByMe
			 , SUM(ISNULL(T.TicketsAssignedToMe, 0)) TicketsAssignedToMe
			 , SUM(ISNULL(T.TicketsPurchased, 0) + ISNULL(T.TicketsAssignedToMe, 0) - ISNULL(T.TicketsAssignedByMe, 0)) AS [MyTickets] 
			 , T.CanAssignTickets
		FROM 
			#Tickets T
		INNER JOIN
			dbo.Event E WITH(NOLOCK)
		ON
			T.PK_Event = E.PK_Event
		INNER JOIN
			dbo.EventSKU ESK WITH(NOLOCK)
		ON
			T.PK_EventSKU = ESK.PK_EventSKU
		LEFT JOIN
			dbo.EventLocaleDesc ELD WITH(NOLOCK)
		ON
			E.PK_Event = ELD.PK_Event
		AND
			ELD.PK_Locale = @PK_Locale
		WHERE
			T.IsEventTicketSKU = 1 AND T.CanAssignTickets = 1
		GROUP BY
			T.PK_Event, T.PK_Distributor, ELD.EventName, E.EventName, T.CanAssignTickets
	
		UNION ALL

		--All the event tickets for Group Ticket Assignment events - non eventtickets
		SELECT 
			   T.PK_Event
			 , T.PK_Distributor
			 , T.PK_EventSKU
			 , ESK.SKUCode
			 , COALESCE(ESL.SKUDesc, ESD.SKUDesc, ESK.SKUDesc) SKUDesc
			 , ISNULL(T.TicketsPurchased, 0) TicketsPurchased
			 , ISNULL(T.TicketsAssignedByMe, 0) TicketsAssignedByMe
			 , ISNULL(T.TicketsAssignedToMe, 0) TicketsAssignedToMe
			 , ISNULL(T.TicketsWithMe, 0) AS [MyTickets] 
			 , T.CanAssignTickets
		FROM 
			#Tickets T
		INNER JOIN
			dbo.EventSKU ESK WITH(NOLOCK)
		ON
			T.PK_EventSKU = ESK.PK_EventSKU
		LEFT JOIN
			dbo.EventSKULocaleDesc ESL WITH(NOLOCK)
		ON
			ESK.PK_EventSKU = ESL.PK_EventSKU
		AND 
			ESL.PK_Locale = @PK_Locale
		LEFT JOIN
			dbo.EventSKULocaleDesc ESD WITH(NOLOCK)
		ON
			ESK.PK_EventSKU = ESD.PK_EventSKU
		AND 
			ESD.PK_Locale = @PK_DefaultLocale 
		WHERE
			T.IsEventTicketSKU = 0 AND T.CanAssignTickets = 1

	
		UNION ALL

		--All the event tickets for Normal Events
		SELECT 
			   T.PK_Event
			 , T.PK_Distributor
			 , T.PK_EventSKU
			 , ESK.SKUCode
			 , COALESCE(ESL.SKUDesc, ESD.SKUDesc, ESK.SKUDesc) SKUDesc
			 , ISNULL(T.TicketsPurchased, 0) TicketsPurchased
			 , ISNULL(T.TicketsAssignedByMe, 0) TicketsAssignedByMe
			 , ISNULL(T.TicketsAssignedToMe, 0) TicketsAssignedToMe
			 , ISNULL(T.TicketsWithMe, 0)  AS [MyTickets] 
			 , T.CanAssignTickets
		FROM 
			#Tickets T
		INNER JOIN
			dbo.EventSKU ESK WITH(NOLOCK)
		ON
			T.PK_EventSKU = ESK.PK_EventSKU
		LEFT JOIN
			dbo.EventSKULocaleDesc ESL WITH(NOLOCK)
		ON
			ESK.PK_EventSKU = ESL.PK_EventSKU
		AND 
			ESL.PK_Locale = @PK_Locale
		LEFT JOIN
			dbo.EventSKULocaleDesc ESD WITH(NOLOCK)
		ON
			ESK.PK_EventSKU = ESD.PK_EventSKU
		AND 
			ESD.PK_Locale = @PK_DefaultLocale 
		WHERE
			T.CanAssignTickets = 0	

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
	END CATCH	

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
GO

