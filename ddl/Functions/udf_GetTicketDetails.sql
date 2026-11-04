CREATE FUNCTION [dbo].[udf_GetTicketDetails](@PK_Event int, @PK_Distributor INT)
RETURNS @TicketDetails TABLE 
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
	,SKUValidBeginUTC DATETIME
	,SKUValidEndUTC DATETIME
	,IsTrackingVisible BIT
)
AS 
BEGIN
/******************************************************************************
OBJECT:			dbo.udf_GetTicketDetails

USE:	       select * from dbo.udf_GetTicketDetails (1222, 4243971)

DESCRIPTION:	Retrieves all the ticket purchase details for a DS ID and all the associated events 
				and promotions parameters

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.EventSKU, dbo.EventTicketAssignment, dbo.EventTickets

VERSIONS
----------------------------------------------------------------------------------
1	2015-01-12	SushmaA	   Intitial
******************************************************************************/
DECLARE @StartDate SMALLDATETIME
SET @StartDate = GETDATE()

DECLARE @Events AS TABLE (PK_Event INT)

/*** Pick all the events and promotions that are active in case fn called from SP usp_MyHLEventAPI_Get_EventsandPromotionsListView ***/
IF @PK_Event IS NULL
INSERT INTO @Events (PK_Event)
	SELECT E.PK_Event
	FROM
		dbo.Event(NOLOCK) E
	WHERE	
	@StartDate <= E.dEndUTC+1
	AND
		GETUTCDATE() BETWEEN E.DisplayStartDate AND (E.DisplayEndDate+1)
	AND
		E.PK_EventType IN (1,2)
	AND
		E.IsActive = 1
	AND
		E.IsPublish = 1
ELSE
/*** Pick the eventid in case fn called from SP usp_MyHLEventAPI_Get_DSEventDetails ***/
INSERT INTO @Events (PK_Event)
SELECT @PK_Event

/***Derive the basic logic of tikcets information ***/
INSERT INTO @TicketDetails (PK_Event, PK_Distributor, PK_EventSKU, TicketsPurchased, TicketsWithMe, TicketsAssignedByMe, TicketsAssignedToMe
							, CanAssignTickets, IsEventTicketSKU,SKUValidBeginUTC,SKUValidEndUTC,IsTrackingVisible)
SELECT
	   E.PK_Event
	  ,@PK_Distributor [PK_Distributor]
	  ,ESK.PK_EventSKU
	  ,ET.TicketsPurchased 
	  ,CASE WHEN ESK.IsEventTicketSKU = 0 THEN ET.TicketsPurchased ELSE ETT.TicketsWithMe END TicketsWithMe
	  ,ETB.TicketsAssignedByMe
	  ,ETM.TicketsAssignedToMe
	  ,E.CanAssignTickets
	  ,ESK.IsEventTicketSKU		
	  ,ESK.SKUValidBeginUTC
	  ,ESK.SKUValidEndUTC
	  ,ESK.IsTrackingVisible
	FROM
		dbo.Event(NOLOCK) E
	INNER JOIN
		@Events EVT
	ON
		E.PK_Event = EVT.PK_Event	
	INNER JOIN
		dbo.EventSKU (NOLOCK) ESK
	ON	
		E.PK_Event = ESK.PK_Event
	LEFT JOIN
	( SELECT ES.PK_EventSKU, SP.PK_Distributor_Purchaser, SUM(ISNULL(SP.Quantity * ES.NumberOfTicketsPerSKU,0)) [TicketsPurchased] FROM dbo.SKUPurchased(NOLOCK) SP
		INNER JOIN dbo.EventSKU (NOLOCK) ES
		ON  SP.PK_Event = ES.PK_Event
	    AND SP.PK_EventSKU = ES.PK_EventSKU
		WHERE SP.PK_Distributor_Purchaser = @PK_Distributor 
		GROUP BY ES.PK_EventSKU, SP.PK_Distributor_Purchaser) ET
	ON
		ESK.PK_EventSKU = ET.PK_EventSKU
	LEFT JOIN
	( SELECT ETA.PK_EventSKU, PK_ToDistributor, COUNT(0) [TicketsWithMe] FROM dbo.EventTicketAssignment (NOLOCK) ETA 
		WHERE ETA.ValidToDateUTC = '2049-12-31'  AND ETA.PK_FromDistributor = @PK_Distributor
		AND ETA.PK_FromDistributor = ETA.PK_ToDistributor GROUP BY ETA.PK_EventSKU, ETA.PK_ToDistributor) ETT
	ON
		ESK.PK_EventSKU = ETT.PK_EventSKU	
	LEFT JOIN
	( SELECT ETA.PK_EventSKU, PK_FromDistributor, COUNT(0) [TicketsAssignedByMe] FROM dbo.EventTicketAssignment (NOLOCK) ETA 
		WHERE ETA.PK_FromDistributor = @PK_Distributor
		AND ETA.PK_FromDistributor <> ETA.PK_ToDistributor GROUP BY ETA.PK_EventSKU, ETA.PK_FromDistributor) ETB
	ON
		ESK.PK_EventSKU = ETB.PK_EventSKU
	LEFT JOIN
	( SELECT ETA.PK_EventSKU, PK_ToDistributor, COUNT(0) [TicketsAssignedToMe] FROM dbo.EventTicketAssignment (NOLOCK) ETA 
		WHERE ETA.PK_ToDistributor = @PK_Distributor
		AND ETA.PK_FromDistributor <> ETA.PK_ToDistributor GROUP BY ETA.PK_EventSKU, ETA.PK_ToDistributor) ETM
	ON
		ESK.PK_EventSKU = ETM.PK_EventSKU
		
RETURN;
	
END