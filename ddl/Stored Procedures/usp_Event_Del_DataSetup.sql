CREATE PROCEDURE dbo.usp_Event_Del_DataSetup
@Pk_Event INT
AS


/******************************************************************************

OBJECT:			dbo.usp_Event_Del_DataSetup
USE:			EXEC usp_Event_Del_DataSetup @Pk_Event

DESCRIPTION:	Delete Event Data Setup

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2017-12-07	Juan	Initial

******************************************************************************/

IF EXISTS (SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event)
BEGIN
	DELETE FROM dbo.EventTicketAssignment WHERE PK_EventTicket IN 
	(SELECT PK_EventTicket FROM   dbo.EventTickets WITH (NOLOCK) WHERE  PK_Event = @PK_Event)

	DELETE FROM dbo.EventTickets WHERE  PK_Event = @PK_Event 

	DELETE FROM dbo.SKUPurchased WHERE  PK_Event = @PK_Event 

	DELETE FROM dbo.SKUPurchasedPivot WHERE PK_Event = @PK_Event 

	DELETE FROM dbo.EventSchedule WHERE  PK_Event = @PK_Event 

	DELETE FROM dbo.SubEventQualification WHERE   	PK_Event = @PK_Event 

	DELETE FROM dbo.SubEventQualificationFormula WHERE    PK_Event = @PK_Event 

	DELETE FROM dbo.SubEventQualifier WHERE  PK_Event = @PK_Event 

	 /***** Used for Tracking Site *********/
	DELETE FROM dbo.SubEventLocaleDesc WHERE PK_Event = @PK_Event  

	DELETE FROM dbo.EventLocaleDesc WHERE  PK_Event = @PK_Event --Used for Tracking Site

	DELETE FROM dbo.EventURL WHERE PK_Event = @PK_Event 
	
	DELETE EIL from dbo.eventImageLocaleDesc EIL Join EventImage EI	ON EIL.PK_EVENTIMAGE=EI.PK_Eventimage Where EI.PK_EVENT=@PK_Event
	
	DELETE EIL from dbo.EventGuestSpeakers EIL Join EventImage EI	ON EIL.PK_EVENTIMAGE=EI.PK_Eventimage Where EI.PK_EVENT=@PK_Event

	DELETE FROM dbo.EventImage WHERE  PK_Event = @PK_Event	

	DELETE FROM dbo.EventDSTeamType WHERE  PK_Event = @PK_Event

	DELETE FROM dbo.EventEventSubType WHERE   PK_Event = @PK_Event 
	/**************************************/

	DELETE FROM dbo.EventQualifier WHERE PK_Event = @PK_Event  -- Distributors that qualify for the event

	DELETE FROM dbo.SubEventRegistration WHERE  PK_EventsRegistration IN 
	(SELECT PK_EventsRegistration FROM   dbo.EventsRegistration WITH (NOLOCK)  WHERE  PK_Event = @PK_Event) --Event Registration

	DELETE FROM dbo.EventsRegistration WHERE   PK_Event = @PK_Event 

	DELETE FROM dbo.EventDistributorCountry WHERE  PK_Event = @PK_Event

	DELETE FROM dbo.EventCountry WHERE  PK_Event = @PK_Event 

	DELETE FROM dbo.SubEventExtn WHERE  PK_Event = @PK_Event 

	DELETE FROM dbo.SubEvent WHERE  PK_Event = @PK_Event 

	DELETE FROM EventSKULocaleDesc where pk_Event = @Pk_Event

	DELETE FROM dbo.EventSKU WHERE   PK_Event = @PK_Event 
	
	DELETE FROM dbo.EventGroupMembers WHERE   PK_Event = @PK_Event 

	DELETE FROM dbo.EventDistributorNotes WHERE  PK_Event = @PK_Event 

	DELETE FROM dbo.EventCoordinatorDetail WHERE   PK_Event = @PK_Event 

	DELETE FROM dbo.EventSecurityRoles WHERE  PK_Event = @PK_Event 

	DELETE FROM dbo.SecurityUsers WHERE UserID LIKE 'S%-' + CAST(@PK_Event as varchar(6))

	DELETE FROM dbo.SecurityUsers WHERE UserID LIKE 'A%-' + CAST(@PK_Event as varchar(6))
	
	DELETE FROM dbo.EventDistributorCountryLocales WHERE  PK_Event = @PK_Event 
	
	DELETE FROM dbo.SubEventLocaleDesc WHERE PK_Event = @PK_Event
	
	DELETE FROM dbo.EventPreOrder WHERE PK_Event = @Pk_Event

	DELETE FROM dbo.EventExtn WHERE PK_Event = @Pk_Event

	DELETE FROM dbo.Event WHERE  PK_Event = @PK_Event 
END