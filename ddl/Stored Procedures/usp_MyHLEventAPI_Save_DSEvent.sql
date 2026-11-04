CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Save_DSEvent]
		-- Mandatory Parameters
		@LocaleCode					char(5)
		
		-- Optional Parameters
		,@EventName					nvarchar(250) = NULL
		,@EventStartDate			smalldatetime = NULL
		,@EventEnddate				smalldatetime = NULL
		,@RecurringEventEnddate		smalldatetime = NULL -- This is the End Date for Recurring Events
		,@EventAddress				nvarchar(500) = NULL
		,@EventAddress2				nvarchar(500) = NULL
		,@EventCity					nvarchar(250) = NULL
		,@EventState				nvarchar(200) = NULL
		,@EventCountry				char(2) = NULL
		,@EventZipCode				nvarchar(20) = NULL
		,@EventKeywords				nvarchar(1000) = NULL
		,@ApprovalFlag				int = 0 --TO BE PASSED FROM FRONT END---> 0 = Under review; 1 = Approved; 2 = Rejected; 3 = Saved as Draft
		,@DisplayStartDate			datetime = NULL --> If not selected by the user then we need the default value passed
		,@DisplayEndDate			datetime = NULL --> If not selected by the user then we need the default value passed
		,@IsActive					bit = 1 --> Will be defaulted to 1 unless otherwise specified by the UI
		,@IsPublish					bit = 0 --> Will be defaulted to 0 unless otherwise specified by the UI
		,@EventDisplayAddress		nvarchar(4000) = NULL
		,@EventTrainingLanguages	nvarchar(4000) = NULL
		,@EventCostDetails			nvarchar(1000) = NULL
		,@EventDesc					nvarchar(MAX) = NULL
		,@EventURL					XML = NULL
		,@EventBanner				nvarchar(MAX) = NULL
		,@EventLogo					nvarchar(MAX) = NULL
		,@ModifiedBy				varchar(30) = NULL
		,@ApprovalNotes				nvarchar(MAX) = NULL
		,@Comments					nvarchar(MAX) = NULL
		,@EventVenueName			nvarchar(250) = NULL -- Event Venue Name
		,@EventSummary				nvarchar(MAX) = NULL -- Event Summary
		,@IsSocialNetworksEnabled	bit = 0
		,@IsPreRegistrationRequired	bit = 0
		,@MakePublic				bit = 1 -- Make Public --> Defaulted to "Yes" always in the UI
		,@CreatedDistributorID		varchar(10) = NULL
		,@IsRecurring				bit = 0 -- Default 0; Will be 1 for Recurring Events only
		,@Repeat					varchar(1) = '' -- Default ''; Repeat Options: W - WEEKLY, M - MONTHLY, B - BIWEEKLY for Recurring Events only
		,@Latitude					numeric(18,10) = NULL
		,@Longitude					numeric(18,10) = NULL
		,@PK_EventSubType			int = NULL
		,@CoordinatorID				xml = NULL
		,@GuestSpeakers				xml = NULL
		,@EventMedia				xml = NULL
		,@Coordinators				xml = NULL
		,@Agenda					xml = NULL
		,@Tickets					xml = NULL
		,@TeamLevels				xml = NULL
		,@Audience					nvarchar(4000) = NULL
		,@TimeZone					nvarchar(255) = NULL
		,@RSVPRegistrations			int = NULL
		,@RSVPGuests				int = NULL
		,@DisplayDates				bit = 1
		,@IsInPersonEvent			BIT = 1
		,@IsVirtualEvent			BIT = 0
		,@IsMajorEvent				BIT = 0

		-- Defaults
		,@EventType					varchar(10) = 'DE'
		,@PK_TicketEventSKUType int = 7	-- Distributor Event Tickets
		,@PK_TicketEventURLType int = 5	-- Ticket Purchase Third Party Link
		,@Version				int = 2 -- New version for events
		
		-- Output Parameter
		,@PK_Event					int = NULL OUTPUT
		
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:     dbo.usp_MyHLEventAPI_Save_DSEvent
USE:
		begin transaction
				DECLARE @e int, @em varchar(4000)
				DECLARE @EventID INT = 78052
				DECLARE @IsDevQA INT
				DECLARE @EventURL XML;
				DECLARE @links varchar(max) = N'
					<URL>
						<PK_EventURL></PK_EventURL>
						<PK_Event></PK_Event>
						<Locale>es-MX</Locale>
						<EventURL>http://www.herbalife.com/VirtualEventLink</EventURL>
						<EventURLDesc>Virtual Event</EventURLDesc>
						<Flyer></Flyer>
						<PK_EventURLType>9</PK_EventURLType>
					</URL>
					<URL>
						<PK_EventURL></PK_EventURL>
						<PK_Event></PK_Event>
						<Locale>es-MX</Locale>
						<EventURL>http://newfirstlink.com/</EventURL>
						<EventURLDesc>First description</EventURLDesc>
						<Flyer></Flyer>
						<PK_EventURLType>5</PK_EventURLType>
					</URL>
					<URL>
						<PK_EventURL></PK_EventURL>
						<PK_Event></PK_Event>
						<Locale>es-MX</Locale>
						<EventURL>http://newsecondlink.com/</EventURL>
						<EventURLDesc>Second description</EventURLDesc>
						<Flyer></Flyer>
						<PK_EventURLType>1</PK_EventURLType>
					</URL>'
				DECLARE @GuestSpeakers xml;
				DECLARE @Speakers varchar(max) = N'
								<Speaker>
									<Locale>es-MX</Locale>
									<PK_EventGuestSpeaker></PK_EventGuestSpeaker>
									<SpeakerName>Liam Neeson</SpeakerName>
									<Title>Mr</Title>
									<Phone>1122334455</Phone>
									<Email>liam@neeson.com</Email>
									<TeamLevel>President</TeamLevel>
									<Bio>Mr Neesons Bio</Bio>
									<PK_EventImageLocaleDesc></PK_EventImageLocaleDesc>
									<EventImageLocation>http://t.com/neeson_image.jpg</EventImageLocation>
									<PK_EventImageType>3</PK_EventImageType>
									<PK_EventURL></PK_EventURL>
									<EventURL>http://twitter/gaga_link</EventURL>
									<EventURLDesc>Gagas Twitter feed</EventURLDesc>
									<PK_EventURLType>6</PK_EventURLType>
								</Speaker>
								<Speaker>
									<Locale>es-MX</Locale>
									<PK_EventGuestSpeaker></PK_EventGuestSpeaker>
									<SpeakerName>Justin Bieber</SpeakerName>
									<Title>Dr</Title>
									<Phone>5544332211</Phone>
									<Email>Bieber@Bieber.com</Email>
									<TeamLevel>President</TeamLevel>
									<Bio>Biebers bio</Bio>
									<PK_EventImageLocaleDesc></PK_EventImageLocaleDesc>
									<EventImageLocation>http://t.com/Bieber_image.jpg</EventImageLocation>
									<PK_EventImageType>3</PK_EventImageType>
									<PK_EventURL></PK_EventURL>
									<EventURL>http://twitter/Bieber</EventURL>
									<EventURLDesc>Twitter feed</EventURLDesc>
									<PK_EventURLType>6</PK_EventURLType>
								</Speaker>';
				DECLARE @EventMedia xml;
				DECLARE @Media varchar(max) = N'
									<Media>
										<PK_EventMedia></PK_EventMedia>
										<PK_MediaType>2</PK_MediaType>
										<Locale>es-MX</Locale>
										<MediaName>Video del Evento 54138</MediaName>
										<MediaDesc>Descripción del video del evento 54138</MediaDesc>
										<MediaHTML><video>HTML video 54138</video></MediaHTML>
									</Media>';
				DECLARE @Coord varchar(max) = N'
									<Coordinator>
										<PK_EventCoordinatorDetail>75717</PK_EventCoordinatorDetail>
										<CoordinatorID>staff</CoordinatorID>
										<EventOwner>1</EventOwner>
										<Email>staff@staff.com</Email>
										<Name>Staff de Herbalife</Name>
										<Website>http://staffwebsite.com/</Website>
									</Coordinator>
									<Coordinator>
										<PK_EventCoordinatorDetail>75718</PK_EventCoordinatorDetail>
										<CoordinatorID>1111111111</CoordinatorID>
										<CoordinatorTitle>Sr</CoordinatorTitle>
										<Email>1111111111@herb.com</Email>
										<Name>1111.. de Herbalife</Name>
										<Website>http://111website.com/</Website>
									</Coordinator>
									<Coordinator>
										<PK_EventCoordinatorDetail>75721</PK_EventCoordinatorDetail>
										<CoordinatorID>2222222222</CoordinatorID>
										<Email>2222222222@herb.com</Email>
										<Name>222... de Herbalife</Name>
										<Website>http://222website.com/</Website>
									</Coordinator>'
							,@Coordinators xml;
				DECLARE @Ag varchar(max) = N'<Agenda>
									<PK_AgendaItem></PK_AgendaItem>
									<Locale>en-US</Locale>
									<StartDate>2017-09-30 08:00:00</StartDate>
									<EndDate>2017-09-30 10:00:00</EndDate>
									<Title>Breakfast</Title>
									<Description>Breakfast in McDonalds</Description>
								</Agenda>
								<Agenda>
									<PK_AgendaItem></PK_AgendaItem>
									<Locale>en-US</Locale>
									<StartDate>2017-09-30 11:00:00</StartDate>
									<EndDate>2017-09-30 12:00:00</EndDate>
									<Title>Conference</Title>
									<Description>Conference in venue</Description>
								</Agenda>'
							,@Agenda xml;
				DECLARE @st nvarchar(max) = N'<Ticket>
									<PK_EventSKU>11283</PK_EventSKU>
									<Name>Entrada</Name>
									<Desc>Entrada al evento</Desc>
									<PK_EventURL></PK_EventURL>
									<Link>http://herbalife.com/boleto</Link>
									<Qty>200</Qty>
									<Price>100</Price>
									<Currency>484</Currency>
								</Ticket>
								<Ticket>
									<PK_EventSKU></PK_EventSKU>
									<Name>Desayuno</Name>
									<Desc>Desayuno en el evento</Desc>
									<PK_EventURL></PK_EventURL>
									<Link>http://herbalife.com/desayuno</Link>
									<Qty>100</Qty>
									<Price>60</Price>
									<Currency>484</Currency>
								</Ticket>'
						,@t xml;
				DECLARE @sTeamLevels varchar(max) = N'
						<TeamLevels>
							<SubLevel>BCM</SubLevel>
							<SubLevel>SCM</SubLevel>
						</TeamLevels>'
						,@TeamLevels xml;
						

				SELECT @EventURL = cast(@links as xml);
				SELECT @GuestSpeakers = cast(@Speakers as xml);
				SELECT @EventMedia = cast(@Media as xml);
				SELECT @Coordinators = cast(@Coord as xml);
				SELECT @Agenda = cast(@Ag as xml);
				SELECT @t = cast(@st as xml);
				SELECT @TeamLevels = cast(@sTeamLevels as xml);

				EXEC [dbo].[usp_MyHLEventAPI_Save_DSEvent]
					@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

					,@PK_Event = @EventID OUTPUT /* @EventID must be defined in the local call */
					,@LocaleCode  = 'es-MX'
					,@Audience = 'es-MX,en-US'
					,@EventName = 'Event without recurrence'
					,@EventStartDate = '2017-08-01'
					,@EventEnddate = '2017-08-02'
					,@RecurringEventEndDate = '2017-08-30'
					,@EventAddress = 'Camino al Iteso 8900'
					,@EventAddress2 = 'Sin Nombre'
					,@EventCity = 'San Pedro Tlaquepaque'
					,@EventState = 'Jalisco'
					,@EventCountry = 'MX'
					,@EventZipCode = '45609'
					,@EventDisplayAddress = 'Camino al Iteso 8900 Sin Nombre'
					,@EventTrainingLanguages = ''
					,@EventCostDetails = '1200 Dollars per attendee'
					,@EventKeywords = 'modified,test,event,url'
					,@EventDesc = 'This Event is a DS Event and is being added/modified only for test purposes only'
					,@EventURL = @EventURL
					,@EventBanner = 'bannerimagenew_1.jpg'
					,@EventLogo = 'logoimagenew_1.jpg'
					,@ModifiedBy = 'rarg'
					,@ApprovalFlag = 1
					,@DisplayStartDate = '2017-08-01'
					,@DisplayEndDate = '2017-08-30'
					,@IsActive = 1 
					,@IsPublish = 0
					,@ApprovalNotes = NULL
					,@Comments = NULL
					,@EventVenueName = 'Herbalife'
					,@EventSummary = 'Summary of the test event'
					,@IsSocialNetworksEnabled = 0
					,@IsPreRegistrationRequired = 0
					,@MakePublic = 0
					,@CreatedDistributorID = '2222222222'
					,@IsRecurring = 0
					,@Repeat = 'B'
					,@Latitude = 20.615734
					,@Longitude = -103.419349
					,@GuestSpeakers = @GuestSpeakers
					,@EventMedia = @EventMedia
					,@Coordinators = @Coordinators
					,@Agenda = @Agenda
					,@TeamLevels = @TeamLevels
					,@Tickets = @t
					,@TimeZone = 'PACIFIC'
					,@RSVPRegistrations = 0
					,@RSVPGuests = 0
					,@IsInPersonEvent = 1
					,@IsVirtualEvent = 1
					,@IsMajorEvent = 0

		SELECT @e AS [Error], @em AS [Error Message]
		select @EventID
		select * from EventImage where pk_event = @EventID
		select * from sUBeVENT where pk_event = @EventID
		Select * from EventURL where pk_Event = @EventID	
		
		rollback transaction

DESCRIPTION: Inserts record into dbo.Event, dbo.EventLocaleDesc, dbo.EventEventSubType, 
                dbo.EventURL, dbo.EventCountry, dbo.EventGuestSpeakers, dbo.EventDSTeamType
				
NOTES:              


DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.Event, dbo.EventLocaleDesc, dbo.EventEventSubType, dbo.EventURL, dbo.EventCountry, dbo.EventGuestSpeakers

VERSIONS
--------------------------------------------------------------------
1.0.0		2016-11-03		RogelioR		Initial
2.0.0		2017-09-16		RogelioR		Changes to include coordinators, agenda and media
2.1.0		2018-02-15		RogelioR		Agenda can include items with same name/description, include <name> and <website> for coordinators
2.2.0		2018-09-19		RogelioR		Added [DisplayDates] functionality
2.3.0		2019-08-14		NoeG			Refactor code (SRE)
2.4.0		2020-01-28		NoeG			Manage Preferred Members Configured Information for Primary Levels
2.5.0		2020-05-28		NoeG			Add features IsMajorEvent, IsVirtualEvent and IsInPersonEvent to Events, also the Link and data for Virtual Event Type 
2.5.1		2020-06-19		puertac			Bug 278695 Russian Characters shown as '??????????' change type from varchar to nvarchar
2.5.2		2020-06-22		puertac			Bug 266825 Virtual Events-DS Events with same name than a Corporate Event is not showed  (issue: PK_Country is NULL in EventCountry )
2.5.3		2020-06-29		puertac			BUG 288018 - Distributor Events page - Online Link Issues - Delete Record from EventURL (PK_EventURLType = 9) when @IsVirtualEvent = 0 
2.5.4		2020-08-10		puertac			BUG 320336 - Cannot save changes on DS event. Rollback root cause: Bug 266825 bug fix
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON      
	
------------------------------------------------------------------------------------------------------------------
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@PK_EventType int = (SELECT [PK_EventType] FROM [dbo].[EventType] WITH (NOLOCK) WHERE [EventTypeCode] = @EventType)
			,@PK_Locale int
			,@PK_DefaultLocale int
			,@PK_EventImageLocaleDesc int
			,@PK_EventImage int
	
	SELECT	@PK_Locale = PK_Locale
			,@PK_DefaultLocale = PK_Locale  
		FROM [dbo].[Locales] WITH (NOLOCK)
		WHERE LocaleCode = @LocaleCode;

	SELECT @Error = 0, @ErrorMessage = ''
			,@EventName = LTRIM(RTRIM(@EventName))
			,@EventAddress = LTRIM(RTRIM(@EventAddress))
			,@EventCity = CASE WHEN LTRIM(RTRIM(@EventCity)) = '' THEN NULL ELSE LTRIM(RTRIM(@EventCity)) END
			,@EventState = CASE WHEN LTRIM(RTRIM(@EventState)) = '' THEN NULL ELSE LTRIM(RTRIM(@EventState)) END
			,@EventZipCode = CASE WHEN LTRIM(RTRIM(@EventZipCode)) = '' THEN NULL ELSE LTRIM(RTRIM(@EventZipCode)) END
			,@EventCountry = LTRIM(RTRIM(@EventCountry))
			,@EventCostDetails = LTRIM(RTRIM(@EventCostDetails))
			,@EventDisplayAddress = LTRIM(RTRIM(@EventDisplayAddress))
			,@EventDesc = LTRIM(RTRIM(@EventDesc))
			,@ApprovalNotes = LTRIM(RTRIM(@ApprovalNotes))
			,@Comments = LTRIM(RTRIM(@Comments))
			,@EventVenueName = LTRIM(RTRIM(@EventVenueName))
			,@EventSummary = LTRIM(RTRIM(@EventSummary))
			,@ModifiedBy = ISNULL(@ModifiedBy, (replace(suser_sname(),'HERBALIFECORP\','')));

	
	------------------------------------------------------------------------------------------------------------------
	-- Save/Update Event
	--
	BEGIN TRY
		MERGE Event AS e
			USING (
				SELECT	@PK_Event AS PK_Event
						,@PK_EventType AS PK_EventType
						,@EventStartDate AS EventStartDate
						,@EventEndDate AS EventEndDate
						,@EventName AS EventName
						,@EventDesc AS EventDesc
						,@EventCity AS EventCity
						,@EventState AS EventState
						,@EventZipCode AS EventZipCode
						,@EventAddress AS EventAddress
						,@EventCostDetails AS EventCostDetails
						,@ApprovalFlag AS EventApprovalStatus
						,0 AS IsHotelEnabled
						,0 AS IsInventoryEnabled
						,@IsPreRegistrationRequired AS IsPreRegistrationRequired
						,0 AS CanAssignTickets
						,0 AS CanPurchaseTicketOnline
						,0 AS CanRegisterOnline
						,@MakePublic AS MakePublic
						,@IsActive AS IsActive
						,@IsPublish AS IsPublish
						,0 AS IsTicketPurchaseRequired
						,0 AS CanDisplayQualPeriod
						,0 AS CanShowCurrentQualOnline
						,@PK_DefaultLocale AS PK_DefaultLocale
						,@DisplayStartDate AS DisplayStartDate
						,(CASE WHEN @IsRecurring = 1 THEN @RecurringEventEnddate ELSE @DisplayEndDate END) AS DisplayEndDate-- IF ITS PARENT USE THE END DATE OF RECURRENCE
						,@ModifiedBy AS ModifiedBy
						,@EventVenueName AS EventVenueName
						,@IsSocialNetworksEnabled AS IsSocialNetworksEnabled
						,@CreatedDistributorID AS CreatedDistributorID
						,@IsRecurring AS IsRecurring
						,(SELECT R.PK_RecurrenceType FROM dbo.RecurrenceType R WITH (NOLOCK) WHERE R.RecurrenceCode = @Repeat) AS PK_RecurrenceType
						,@RecurringEventEnddate AS RecurringEventEnddate
						,@Latitude AS Latitude
						,@Longitude AS Longitude
						,@TimeZone AS [Location]
						,@Version AS [Version]
				) AS s ON (e.PK_Event = @PK_Event)
			WHEN MATCHED AND @PK_Event IS NOT NULL THEN
				UPDATE SET
						e.[PK_EventType] = s.[PK_EventType]
						,e.[dStartUTC] = s.[EventStartDate]
						,e.[dEndUTC] = s.[EventEndDate]
						,e.[EventName] = s.[EventName]
						,e.[EventDesc] = s.[EventDesc]
						,e.[EventCity] = s.[EventCity]
						,e.[EventState] = s.[EventState]
						,e.[EventZipCode] = s.[EventZipCode]
						,e.[EventAddress] = s.[EventAddress]
						,e.[EventCostDetails] = s.[EventCostDetails]
						,e.[EventApprovalStatus] = s.[EventApprovalStatus]
						,e.[IsHotelEnabled] = s.[IsHotelEnabled]
						,e.[IsInventoryEnabled] = s.[IsInventoryEnabled]
						,e.[IsPreRegistrationRequired] = s.[IsPreRegistrationRequired]
						,e.[CanAssignTickets] = s.[CanAssignTickets]
						,e.[CanPurchaseTicketOnline] = s.[CanPurchaseTicketOnline]
						,e.[CanRegisterOnline] = s.[CanRegisterOnline]
						,e.[MakePublic] = s.[MakePublic]
						,e.[IsActive] = s.[IsActive]
						,e.[IsPublish] = s.[IsPublish]
						,e.[IsTicketPurchaseRequired] = s.[IsTicketPurchaseRequired]
						,e.[CanDisplayQualPeriod] = s.[CanDisplayQualPeriod]
						,e.[CanShowCurrentQualOnline] = s.[CanShowCurrentQualOnline]
						,e.[PK_DefaultLocale] = s.[PK_DefaultLocale]
						,e.[DisplayStartDate] = s.[DisplayStartDate]
						,e.[DisplayEndDate] = s.[DisplayEndDate]
						,e.[ModifiedBy] = s.[ModifiedBy]
						,e.[EventVenueName] = s.[EventVenueName]
						,e.[IsSocialNetworkEnabled] = [IsSocialNetworkEnabled]
						,e.[CreatedDistributorID] = s.[CreatedDistributorID]
						,e.[IsRecurring] = s.[IsRecurring]
						,e.[PK_RecurrenceType] = s.[PK_RecurrenceType]
						,e.[RecurrenceEndDate] = s.[RecurringEventEnddate]
						,e.[Latitude] = s.[Latitude]
						,e.[Longitude] = s.[Longitude]
						,e.[Location] = s.[Location]
						,e.[ModifiedDateUTC] = @StartTime
						,e.[Version] = s.[Version]
			WHEN NOT MATCHED THEN
				INSERT (	
						[PK_EventType]
						,[dStartUTC]
						,[dEndUTC]
						,[EventName]
						,[EventDesc]
						,[EventCity]
						,[EventState]
						,[EventZipCode]
						,[EventAddress]
						,[EventCostDetails]
						,[EventApprovalStatus]
						,[IsHotelEnabled]
						,[IsInventoryEnabled]
						,[IsPreRegistrationRequired]
						,[CanAssignTickets]
						,[CanPurchaseTicketOnline]
						,[CanRegisterOnline]
						,[MakePublic]
						,[IsActive]
						,[IsPublish]
						,[IsTicketPurchaseRequired]
						,[CanDisplayQualPeriod]
						,[CanShowCurrentQualOnline]
						,[PK_DefaultLocale]
						,[DisplayStartDate]
						,[DisplayEndDate]
						,[CreatedBy]
						,[ModifiedBy]
						,[EventVenueName]
						,[IsSocialNetworkEnabled]
						,[CreatedDistributorID]
						,[IsRecurring]
						,[PK_RecurrenceType]
						,[RecurrenceEndDate]
						,[Latitude]
						,[Longitude]
						,[Location]
						,[Version]
				)
				VALUES (	
						@PK_EventType
						,@EventStartDate
						,@EventEndDate
						,@EventName
						,@EventDesc
						,@EventCity
						,@EventState
						,@EventZipCode
						,@EventAddress
						,@EventCostDetails
						,@ApprovalFlag
						,0	-- [IsHotelEnabled]
						,0	-- [IsInventoryEnabled]
						,@IsPreRegistrationRequired
						,0	-- [CanAssignTickets]
						,0	-- [CanPurchaseTicketsOnline]
						,0	-- [CanRegisterOnline]
						,@MakePublic
						,@IsActive
						,@IsPublish
						,0	-- [IsTicketPurchaseRequired]
						,0	-- [CanDisplayQualPeriod]
						,0	-- [CanShowCurrentQualOnline]
						,@PK_DefaultLocale
						,@DisplayStartDate
						,(CASE WHEN @IsRecurring = 1 THEN @RecurringEventEnddate ELSE @DisplayEndDate END) -- IF ITS PARENT USE THE END DATE OF RECURRENCE
						,@ModifiedBy
						,@ModifiedBy
						,@EventVenueName
						,@IsSocialNetworksEnabled
						,@CreatedDistributorID
						,@IsRecurring
						,(SELECT R.PK_RecurrenceType FROM dbo.RecurrenceType R WITH (NOLOCK) WHERE R.RecurrenceCode = @Repeat)
						,@RecurringEventEnddate
						,@Latitude
						,@Longitude
						,@TimeZone
						,@Version
				)
		; -- MERGE Event

		SELECT @PK_Event = ISNULL(@PK_Event, @@IDENTITY);
		
		IF @IsDevQA = 1	SELECT 'Save/Update Event :' + CAST(@PK_Event AS varchar(255));

	END TRY
	BEGIN CATCH
       SET @Error = ERROR_NUMBER();
       SET @ErrorMessage = 'Save/Update Event ' + ERROR_MESSAGE();
       SET @StoredProcedure = ERROR_PROCEDURE();
		
		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

       -- UPDATE ERROR LOG
       EXEC dbo.usp_Utility_UpdateErrorLog 
                    @ProcedureName = @StoredProcedure
                    ,@ErrorNumber = 3
                    ,@ErrorMessage = @ErrorMessage
                    ,@SQLErrorCode = @Error
                    ,@SQLErrorMsg = @ErrorMessage; 
		RETURN
	END CATCH;

	------------------------------------------------------------------------------------------------------------------
	-- Save/Update EventExtn (RSVP fields)
	-- 	
	BEGIN TRY;
		WITH cte AS (
			SELECT
					(SELECT [PK_EventExtn] FROM [dbo].[EventExtn] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event) AS [PK_EventExtn]
					,@PK_Event AS [PK_Event]
					,@RSVPRegistrations AS [RSVPRegistrations]
					,@RSVPGuests AS [RSVPGuests]
		)
		MERGE [dbo].[EventExtn] AS t
			USING(
				SELECT
						[PK_EventExtn]
						,[PK_Event]
						,[RSVPRegistrations]
						,[RSVPGuests]
						,@StartTime AS [CreatedDateUTC]
						,@ModifiedBy As [CreatedBy]
						,@StartTime AS [ModifiedDateUTC]
						,@ModifiedBy As [ModifiedBy]
						,@DisplayDates AS [DisplayDates]
						,@IsInPersonEvent AS [IsInPersonEvent]						
						,@IsVirtualEvent AS [IsVirtualEvent]
						,@IsMajorEvent AS [IsMajorEvent]
					FROM cte
				) AS s ON s.[PK_EventExtn] = t.[PK_EventExtn]
			WHEN MATCHED THEN
				UPDATE SET
					[RSVPRegistrations] = s.[RSVPRegistrations]
					,[RSVPGuests] = s.[RSVPGuests]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
					,[DisplayDates] = s.[DisplayDates]
					,[IsInPersonEvent] = s.[IsInPersonEvent]
					,[IsVirtualEvent] = s.[IsVirtualEvent]
					,[IsMajorEvent] = s.[IsMajorEvent]
			WHEN NOT MATCHED THEN
				INSERT (
					[PK_Event]
					,[RSVPRegistrations]
					,[RSVPGuests]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
					,[DisplayDates]
					,[IsInPersonEvent]
					,[IsVirtualEvent]
					,[IsMajorEvent]
				)
				VALUES (
					s.[PK_Event]
					,s.[RSVPRegistrations]
					,s.[RSVPGuests]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
					,s.[DisplayDates]
					,s.[IsInPersonEvent]
					,s.[IsVirtualEvent]
					,s.[IsMajorEvent]
				)
		; -- MERGE [EventExtn]
	END TRY
	BEGIN CATCH
       SET @Error = ERROR_NUMBER();
       SET @ErrorMessage = 'Save/Update EventExtn ' + ERROR_MESSAGE();
       SET @StoredProcedure = ERROR_PROCEDURE();
		
		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

       -- UPDATE ERROR LOG
       EXEC dbo.usp_Utility_UpdateErrorLog 
                    @ProcedureName = @StoredProcedure
                    ,@ErrorNumber = 3
                    ,@ErrorMessage = @ErrorMessage
                    ,@SQLErrorCode = @Error
                    ,@SQLErrorMsg = @ErrorMessage; 
		RETURN
	END CATCH;

	------------------------------------------------------------------------------------------------------------------
	-- Save/Update EventCountry
	-- 
	BEGIN TRY
		MERGE EventCountry AS t
			USING (
				SELECT
						@PK_Event AS PK_Event
						,(	SELECT	nCountryID 
							FROM	v_countries WITH (NOLOCK) 
							WHERE	sCountryCodeISO = @EventCountry
									OR (sCountryCode in ('-1','-2','-V','-W') and sCountryCode = @EventCountry)		-- BUG 320336 - Cannot save changes on DS event. Rollback root cause: Bug 266825 bug fix
						) AS PK_Country
						,@ModifiedBy AS CreatedBy
						,@ModifiedBy AS ModifiedBy
				) AS s ON (t.PK_Event = @PK_Event)
			WHEN MATCHED THEN
				UPDATE SET
						t.[PK_Event] = s.PK_Event
						,t.[PK_Country] = s.PK_Country
						,t.[ModifiedDateUTC] = @StartTime
						,t.[ModifiedBy] = s.ModifiedBy
			WHEN NOT MATCHED THEN
				INSERT (
						[PK_Event]
						,[PK_Country]
				)
				VALUES (
						@PK_Event
						,s.PK_Country
				)
		;	-- MERGE EventCountry

		IF @IsDevQA = 1	SELECT 'Save/Update EventCountry';

	END TRY
	BEGIN CATCH
       SET @Error = ERROR_NUMBER();
       SET @ErrorMessage = 'Save/Update EventCountry ' + ERROR_MESSAGE();
       SET @StoredProcedure = ERROR_PROCEDURE();

	   IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

       -- UPDATE ERROR LOG
       EXEC dbo.usp_Utility_UpdateErrorLog 
                    @ProcedureName = @StoredProcedure
                    ,@ErrorNumber = 3
                    ,@ErrorMessage = @ErrorMessage
                    ,@SQLErrorCode = @Error
                    ,@SQLErrorMsg = @ErrorMessage;
		RETURN
	END CATCH;

	------------------------------------------------------------------------------------------------------------------
	-- Save/Update EventLocaleDesc
	-- 
	BEGIN TRY
		MERGE EventLocaleDesc AS el
			USING (
				SELECT
						@PK_Event AS PK_Event
						,@PK_EventType AS PK_EventType
						,@PK_Locale AS PK_Locale
						,@PK_DefaultLocale AS PK_DefaultLocale
						,@EventName AS EventName
						,@EventDesc AS EventDesc
						,@EventAddress AS EventAddress
						,@EventAddress2 AS EventAddress2
						,@EventCity AS EventCity
						,@EventState AS EventState
						,@EventDisplayAddress AS EventDisplayAddress
						,@EventCostDetails AS EventCostDetails
						,@EventTrainingLanguages AS EventTrainingLanguages
						,@ModifiedBy AS CreatedBy
						,@ModifiedBy AS ModifiedBy
						,@ApprovalNotes AS ApprovalNotes
						,@Comments AS Comments
						,@EventKeywords AS EventKeywords
						,@EventSummary AS EventSummary
				) AS s ON (el.PK_Event = @PK_Event)
			WHEN MATCHED THEN
				UPDATE SET
						el.[PK_EventType] = s.PK_EventType
						,el.[PK_Locale] = s.PK_Locale
						,el.[PK_DefaultLocale] = s.PK_DefaultLocale
						,el.[EventName] = s.EventName
						,el.[EventDesc] = s.EventDesc
						,el.[EventSummary] = s.EventSummary
						,el.[EventAddress] = s.EventAddress
						,el.[EventAddress2] = s.EventAddress2
						,el.[EventCity] = s.EventCity
						,el.[EventState] = s.EventState
						,el.[Keywords] = s.EventKeywords
						,el.[EventCostDetails] = s.EventCostDetails
						,el.[EventDisplayAddress] = s.EventDisplayAddress
						,el.[EventTrainingLanguages] = s.EventTrainingLanguages
						,el.[EventApprovalNotes] = s.ApprovalNotes
						,el.[EventComments] = s.Comments
						,el.[ModifiedDateUTC] = @StartTime
						,el.[ModifiedBy] = s.ModifiedBy
			WHEN NOT MATCHED THEN
				INSERT (
						[PK_Event]
						,[PK_EventType]
						,[PK_Locale]
						,[PK_DefaultLocale]
						,[EventName]
						,[EventDesc]
						,[EventSummary]
						,[EventAddress]
						,[EventAddress2]
						,[EventCity]
						,[EventState]
						,[Keywords]
						,[EventCostDetails]
						,[EventDisplayAddress]
						,[EventTrainingLanguages]
						,[EventApprovalNotes]
						,[EventComments]
				)
				VALUES (
						@PK_Event
						,@PK_EventType
						,@PK_Locale
						,@PK_DefaultLocale
						,@EventName
						,@EventDesc
						,@EventSummary
						,@EventAddress
						,@EventAddress2
						,@EventCity
						,@EventState
						,@EventKeywords
						,@EventCostDetails
						,@EventDisplayAddress
						,@EventTrainingLanguages
						,@ApprovalNotes
						,@Comments
				)
		;	-- MERGE EventLocaleDesc

		IF @IsDevQA = 1	SELECT 'Save/Update EventLocaleDesc';

	END TRY
	BEGIN CATCH
       SET @Error = ERROR_NUMBER();
       SET @ErrorMessage = 'Save/Update EventLocaleDesc ' + ERROR_MESSAGE();
       SET @StoredProcedure = ERROR_PROCEDURE();

	   IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

       -- UPDATE ERROR LOG
       EXEC dbo.usp_Utility_UpdateErrorLog 
                    @ProcedureName = @StoredProcedure
                    ,@ErrorNumber = 3
                    ,@ErrorMessage = @ErrorMessage
                    ,@SQLErrorCode = @Error
                    ,@SQLErrorMsg = @ErrorMessage;
		RETURN
	END CATCH;

	------------------------------------------------------------------------------------------------------------------
	-- Save/Update EventURL
	-- 
	BEGIN TRY	
		IF OBJECT_ID('tempdb.dbo.#EventURL') IS NOT NULL
			DROP TABLE #EventURL;

		SELECT 
				Links.col.value('PK_EventURL[1]', 'int') AS [PK_EventURL]
				,(CASE WHEN Links.col.value('PK_Event[1]', 'int') = 0 THEN @PK_Event ELSE Links.col.value('PK_Event[1]', 'int') END) AS [PK_Event]
				,Links.col.value('Locale[1]', 'varchar(5)') AS [LocaleCode]
				,l.[PK_Locale]
				,Links.col.value('EventURL[1]', 'varchar(255)') AS [EventURL]
				,Links.col.value('EventURLDesc[1]', 'nvarchar(max)') AS [EventURLDesc]				-- Bug 278695
				,Links.col.value('Flyer[1]', 'varchar(max)') AS [Flyer]
				,Links.col.value('PK_EventURLType[1]', 'int') AS [PK_EventURLType]
			INTO #EventURL
			FROM @EventURL.nodes('/URL') AS Links(col)
				INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[LocaleCode] = Links.col.value('Locale[1]', 'varchar(5)');

		IF @IsDevQA = 1	SELECT 'Save/Update EventURL' AS [Step] FROM #EventURL;

		DECLARE @Urls table (
			[action] varchar(25)
			,[PK_EventURL] int
			,[PK_Event] int
			,[PK_Locale] int
			,[EventURL] nvarchar(255)
			,[EventURLDesc] nvarchar(max)
			,[Flyer] nvarchar(255)
			,[PK_EventURLType] int
		);

		--
		MERGE [dbo].[EventURL] AS t
			USING (
				SELECT
						[PK_EventURL]
						,[PK_Event]
						,[LocaleCode]
						,[PK_Locale]
						,[EventURL]
						,[EventURLDesc]
						,[Flyer]
						,[PK_EventURLType]
						,@StartTime AS [CreatedBy]
						,@StartTime AS [ModifiedBy]
					FROM #EventURL
				) AS s ON (s.[PK_EventURL] = t.[PK_EventURL])
			WHEN MATCHED THEN
				UPDATE SET
						[PK_Event] = s.[PK_Event]
						,[PK_Locale] = s.[PK_Locale]
						,[EventURL] = s.[EventURL]
						,[EventURLDesc] = s.[EventURLDesc]
						,[Flyer] = s.[Flyer]
						,[PK_EventURLType] = s.[PK_EventURLType]
						,[ModifiedBy] = s.[ModifiedBy]
			WHEN NOT MATCHED THEN
				INSERT (
						[PK_Event]
						,[PK_Locale]
						,[EventURL]
						,[EventURLDesc]
						,[Flyer]
						,[PK_EventURLType]
				)
				VALUES (
						s.[PK_Event]
						,s.[PK_Locale]
						,s.[EventURL]
						,s.[EventURLDesc]
						,s.[Flyer]
						,s.[PK_EventURLType]
				)
			WHEN NOT MATCHED BY SOURCE
				AND t.[PK_Event] = @PK_Event
				AND t.[PK_EventURLType] IN (1, 9)
			THEN
				DELETE
			OUTPUT	$action
					,inserted.[PK_EventURL]
					,inserted.[PK_Event]
					,inserted.[PK_Locale]
					,inserted.[EventURL]
					,inserted.[EventURLDesc]
					,inserted.[Flyer]
					,inserted.[PK_EventURLType]
				INTO @Urls
		; -- MERGE EventURL
		
		/*************** BUG 288018 - Distributor Events page - Online Link Issues **************************/
		IF EXISTS (SELECT PK_Event FROM dbo.EventURL WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_EventURLType = 9) AND @IsVirtualEvent = 0
		BEGIN
				DELETE FROM EventURL 
				WHERE PK_Event = @PK_Event
				AND PK_EventURLType = 9
		END

		
		IF @IsDevQA = 1
		BEGIN
			SELECT PK_Event FROM @Urls
			SELECT PK_Event FROM dbo.EventURL (NOLOCK) WHERE PK_Event = @PK_Event
		END;
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'Save/Update EventURL ' + ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog
						@ProcedureName = @StoredProcedure
						,@ErrorNumber = 3
						,@ErrorMessage = @ErrorMessage
						,@SQLErrorCode = @Error
						,@SQLErrorMsg = @ErrorMessage
			RETURN
	END CATCH;
	
	------------------------------------------------------------------------------------------------------------------
	-- Save/Update EventImage (Event)
	-- 
	BEGIN TRY
		DECLARE @EventImageMerge table (
				[action] varchar(10)
				,[PK_EventImage] int
				,[EventImageLocation] varchar(255)
				,[CreatedDateUTC] datetime2
				,[CreatedBy] varchar(50)
				,[ModifiedDateUTC] datetime2
				,[ModifiedBy] varchar(50)
				,[PK_Event] int
				,[PK_EventImageType] int
			);
			
		WITH c AS (
			SELECT @PK_Event AS [PK_Event], @EventLogo AS [EventImageLocation], 1 AS [PK_EventImageType]
			UNION ALL
			SELECT @PK_Event AS [PK_Event], @EventBanner AS [EventImageLocation], 2 AS [PK_EventImageType]
		)
		,i AS (
		SELECT
				ei.[PK_EventImage]
				,c.[EventImageLocation]
				,ISNULL(CreatedDateUTC, GETUTCDATE()) AS [CreatedDateUTC]
				,ISNULL(CreatedBy, (replace(suser_sname(),'HERBALIFECORP\',''))) AS [CreatedBy]
				,c.[PK_Event]
				,c.[PK_EventImageType]
			FROM c
				LEFT JOIN [dbo].[EventImage] AS ei WITH (NOLOCK) ON ei.[PK_Event] = c.[PK_Event]
					AND ei.[PK_EventImageType] = c.[PK_EventImageType]
					AND ei.PK_EventImageType IN (1, 2)	-- Only banners and logos
		)
		MERGE [dbo].[EventImage] AS t
			USING (
					SELECT
							[PK_EventImage]
							,[EventImageLocation]
							,[CreatedDateUTC]
							,[CreatedBy]
							,[CreatedDateUTC] AS [ModifiedDateUTC]
							,[CreatedBy] AS [ModifiedBy]
							,[PK_Event]
							,[PK_EventImageType]
						FROM i
				) AS s ON (s.[PK_EventImage] = t.[PK_EventImage])
			WHEN MATCHED THEN
				UPDATE SET
					[EventImageLocation] = s.[EventImageLocation]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
			WHEN NOT MATCHED THEN
				INSERT (
						[EventImageLocation]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
						,[PK_Event]
						,[PK_EventImageType]
				)
				VALUES (
						s.[EventImageLocation]
						,s.[CreatedDateUTC]
						,s.[CreatedBy]
						,s.[ModifiedDateUTC]
						,s.[ModifiedBy]
						,s.[PK_Event]
						,s.[PK_EventImageType]
				)
			OUTPUT $action
					,inserted.[PK_EventImage]
					,inserted.[EventImageLocation]
					,inserted.[CreatedDateUTC]
					,inserted.[CreatedBy]
					,inserted.[ModifiedDateUTC]
					,inserted.[ModifiedBy]
					,inserted.[PK_Event]
					,inserted.[PK_EventImageType]
				INTO @EventImageMerge
			; -- EventImage Merge

		IF @IsDevQA = 1 SELECT PK_EventImage FROM @EventImageMerge;

		WITH c AS (
			SELECT
					l.[PK_EventImageLocaleDesc]
					,m.[EventImageLocation]
					,ISNULL(l.CreatedBy, m.CreatedBy) AS [CreatedBy]
					,ISNULL(l.CreatedDateUTC, m.CreatedDateUTC) AS [CreatedDateUTC]
					,m.[ModifiedBy]
					,m.[ModifiedDateUTC]
					,m.[PK_EventImage]
					,m.[PK_Event]
					,@PK_Locale AS [PK_Locale]
				FROM @EventImageMerge AS m
					LEFT JOIN [dbo].[EventImageLocaleDesc] AS l WITH (NOLOCK) ON l.[PK_EventImage] = m.[PK_EventImage]
						AND l.[PK_Locale] = @PK_Locale
		)
		MERGE [dbo].[EventImageLocaleDesc] AS t
			USING(
					SELECT
							[PK_EventImageLocaleDesc]
							,[EventImageLocation]
							,[CreatedDateUTC]
							,[CreatedBy]
							,[ModifiedDateUTC]
							,[ModifiedBy]
							,[PK_EventImage]
							,[PK_Event]
							,[PK_Locale]
						FROM c
				) AS s ON (s.[PK_EventImageLocaleDesc] = t.[PK_EventImageLocaleDesc])
			WHEN MATCHED THEN
				UPDATE SET
					[EventImageLocation] = s.[EventImageLocation]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
			WHEN NOT MATCHED THEN
				INSERT(
					[EventImageLocation]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
					,[PK_EventImage]
					,[PK_Event]
					,[PK_Locale]
				)
				VALUES (
					s.[EventImageLocation]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
					,s.[PK_EventImage]
					,s.[PK_Event]
					,s.[PK_Locale]
				)
			OUTPUT $action, inserted.[EventImageLocation]
					,inserted.[CreatedDateUTC]
					,inserted.[CreatedBy]
					,inserted.[ModifiedDateUTC]
					,inserted.[ModifiedBy]
					,inserted.[PK_EventImage]
					,inserted.[PK_Event]
					,inserted.[PK_Locale]
		; -- EventImageLocaleDesc Merge
	
		DECLARE @DelImage table ([PK_EventImage] int);
		DECLARE @Image table ([PK_EventImage] int);

		DELETE FROM [dbo].[EventImageLocaleDesc]
			OUTPUT deleted.[PK_EventImage]
				INTO @DelImage
			WHERE [PK_Event] = @PK_Event
				AND [EventImageLocation] IS NULL;

		/* ***************** SonarQube check 107 - Nullable subqueries should not be used in "NOT IN" conditions */
		DELETE FROM [dbo].[EventImage]
			OUTPUT deleted.[PK_EventImage]
				INTO @Image
			WHERE [PK_Event] = @PK_Event
				----AND PK_EventImage NOT IN (SELECT [PK_EventImage] FROM [dbo].[EventImageLocaleDesc] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)
				AND PK_EventImage NOT IN (SELECT [PK_EventImage] FROM [dbo].[EventImageLocaleDesc] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event AND [PK_EventImage] IS NOT NULL)
		/* ***************** SonarQube check 107 */
		
		IF @IsDevQA = 1	
		BEGIN
			SELECT 'Save/Update EventImage (Event)';
			SELECT 'Deleted Image Locale' FROM @DelImage;
			SELECT 'Deleted Event Image' FROM @Image;
		END;
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'Save/Update EventImage (Event) ' + ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog
						@ProcedureName = @StoredProcedure
						,@ErrorNumber = 3
						,@ErrorMessage = @ErrorMessage
						,@SQLErrorCode = @Error
						,@SQLErrorMsg = @ErrorMessage
		RETURN
	END CATCH;

	
	------------------------------------------------------------------------------------------------------------------
	-- Save/Update EVentEventSubType 
	-- 
	BEGIN TRY
		IF @PK_EventSubType IS NOT NULL
		BEGIN
			MERGE [dbo].[EVentEventSubType] AS t
				USING (
					SELECT
							@PK_Event AS [PK_Event]
							,@PK_EventType AS [PK_EventType]
							,@PK_EventSubType AS [PK_EventSubType]
							,@StartTime AS [CreatedDateUTC]
							,@ModifiedBy As [CreatedBy]
							,@StartTime AS [ModifiedDateUTC]
							,@ModifiedBy As [ModifiedBy]
					) AS s ON (s.[PK_Event] = t.[PK_Event] AND s.[PK_EventType] = t.[PK_EventType])
				WHEN MATCHED THEN
					UPDATE SET
							[PK_EventSubType] = s.[PK_EventSubType]
							,[ModifiedDateUTC] = s.[ModifiedDateUTC]
							,[ModifiedBy] = s.[ModifiedBy]
				WHEN NOT MATCHED THEN
					INSERT (
							[PK_Event]
							,[PK_EventType]
							,[PK_EventSubType]
							,[CreatedDateUTC]
							,[CreatedBy]
							,[ModifiedDateUTC]
							,[ModifiedBy]
					)
					VALUES (
							s.[PK_Event]
							,s.[PK_EventType]
							,s.[PK_EventSubType]
							,s.[CreatedDateUTC]
							,s.[CreatedBy]
							,s.[ModifiedDateUTC]
							,s.[ModifiedBy]
					)
				--	OUTPUT $action, inserted.*, deleted.*
			; -- MERGE EventEventSubType			
		END;

		IF @IsDevQA = 1	SELECT 'Save/Update dbo.EVentEventSubType';
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'Save/Update dbo.EVentEventSubType ' + ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog
						@ProcedureName = @StoredProcedure
						,@ErrorNumber = 3
						,@ErrorMessage = @ErrorMessage
						,@SQLErrorCode = @Error
						,@SQLErrorMsg = @ErrorMessage
		RETURN
	END CATCH;


	------------------------------------------------------------------------------------------------------------------
	-- Save/Update Recurring Events (Requires @IsRecurring = 1 And a valid @Repeat value
	-- This section saves the new recurring events to EventLocaleDesc, EventImage, EventImageLocaleDesc and EventURL
	-- 
	IF @IsRecurring = 1 AND @Repeat IN ('W', 'B', 'M')
	BEGIN
		BEGIN TRY
			IF @IsDevQA = 1 SELECT @PK_Event AS PK_Event, @EventStartDate AS EventStartDate, @EventEnddate AS EventEnddate, @RecurringEventEndDate AS RecurringEventEndDate;

			DECLARE @Instances AS TABLE ([action] varchar(10), [PK_Event] int, [dEndUTC] datetime2, [IsActive] int);

			WITH cte_event AS (
				SELECT
						e.PK_EventType
						,d.[NewStartDate] AS [dStartUTC]
						,d.[NewEndDate] AS [dEndUTC]
						,e.[EventName]
						,e.[EventDesc]
						,e.[EventCity]
						,e.[EventState]
						,e.[EventZipCode]
						,e.[EventAddress]
						,e.[EventCostDetails]
						,e.[EventApprovalStatus]
						,e.[IsHotelEnabled]
						,e.[IsInventoryEnabled]
						,e.[IsPreRegistrationRequired]
						,e.[CanAssignTickets]
						,e.[CanPurchaseTicketOnline]
						,e.[CanRegisterOnline]
						,e.[MakePublic]
						,1 AS [IsActive]
						,e.[IsPublish]
						,e.[IsTicketPurchaseRequired]
						,e.[CanDisplayQualPeriod]
						,e.[CanShowCurrentQualOnline]
						,e.[PK_DefaultLocale]
						,e.[DisplayStartDate]
						,d.[NewEndDate] AS [DisplayEndDate] -- Each instance has the event end date as the instance end date
						,e.[ModifiedBy] AS [CreatedBy]
						,e.[ModifiedBy]
						,e.[EventVenueName]
						,e.[IsSocialNetworkEnabled]
						,@PK_Event AS [PK_OldEventApp]
						,0 AS [IsRecurring]
						,e.[CreatedDistributorID]
						,e.[Latitude]
						,e.[Longitude] 
					FROM [dbo].[Event] AS e WITH (NOLOCK)
						CROSS JOIN [dbo].[udf_Get_RecurringEventInstances](@PK_Event, @EventStartDate, @EventEnddate, @RecurringEventEndDate, @Repeat) AS d
					WHERE e.PK_Event = @PK_Event
						AND d.Number > 0
			)
			,cte_instances AS (
				/* ***************** SonarQube check 108 - Identical expressions should not be used on both sides of a binary operator */
				SELECT
						e.[PK_Event]
						,c.*
					FROM cte_event AS c
						LEFT JOIN [dbo].[Event] AS e WITH (NOLOCK) ON e.[PK_OldEventApp] = @PK_Event 
							AND e.[dStartUTC] = c.[dStartUTC]
							AND e.[dEndUTC] = c.[dEndUTC]
							----AND e.[PK_OldEventApp] = @PK_Event
				/* ***************** SonarQube check 108 */
			)
			MERGE INTO [dbo].[Event] AS t
				USING(SELECT
							[PK_Event]
							,[PK_EventType]
							,[dStartUTC]
							,[dEndUTC]
							,[EventName]
							,[EventDesc]
							,[EventCity]
							,[EventState]
							,[EventZipCode]
							,[EventAddress]
							,[EventCostDetails]
							,[EventApprovalStatus]
							,[IsHotelEnabled]
							,[IsInventoryEnabled]
							,[IsPreRegistrationRequired]
							,[CanAssignTickets]
							,[CanPurchaseTicketOnline]
							,[CanRegisterOnline]
							,[MakePublic]
							,[IsActive]
							,[IsPublish]
							,[IsTicketPurchaseRequired]
							,[CanDisplayQualPeriod]
							,[CanShowCurrentQualOnline]
							,[PK_DefaultLocale]
							,[DisplayStartDate]
							,[DisplayEndDate]
							,[CreatedBy]
							,[ModifiedBy]
							,[EventVenueName]
							,[IsSocialNetworkEnabled]
							,[PK_OldEventApp]
							,[IsRecurring]
							,[CreatedDistributorID]
							,[Latitude]
							,[Longitude]
						FROM cte_instances
					) AS s
					ON (s.PK_Event = t.PK_Event AND t.PK_OldEventApp = @PK_Event)
				WHEN NOT MATCHED THEN
					INSERT(
							[PK_EventType]
							,[dStartUTC]
							,[dEndUTC]
							,[EventName]
							,[EventDesc]
							,[EventCity]
							,[EventState]
							,[EventZipCode]
							,[EventAddress]
							,[EventCostDetails]
							,[EventApprovalStatus]
							,[IsHotelEnabled]
							,[IsInventoryEnabled]
							,[IsPreRegistrationRequired]
							,[CanAssignTickets]
							,[CanPurchaseTicketOnline]
							,[CanRegisterOnline]
							,[MakePublic]
							,[IsActive]
							,[IsPublish]
							,[IsTicketPurchaseRequired]
							,[CanDisplayQualPeriod]
							,[CanShowCurrentQualOnline]
							,[PK_DefaultLocale]
							,[DisplayStartDate]
							,[DisplayEndDate]
							,[CreatedBy]
							,[ModifiedBy]
							,[EventVenueName]
							,[IsSocialNetworkEnabled]
							,[PK_OldEventApp]
							,[IsRecurring]
							,[CreatedDistributorID]
							,[Latitude]
							,[Longitude]
					)
					VALUES (
							s.[PK_EventType]
							,s.[dStartUTC]
							,s.[dEndUTC]
							,s.[EventName]
							,s.[EventDesc]
							,s.[EventCity]
							,s.[EventState]
							,s.[EventZipCode]
							,s.[EventAddress]
							,s.[EventCostDetails]
							,s.[EventApprovalStatus]
							,s.[IsHotelEnabled]
							,s.[IsInventoryEnabled]
							,s.[IsPreRegistrationRequired]
							,s.[CanAssignTickets]
							,s.[CanPurchaseTicketOnline]
							,s.[CanRegisterOnline]
							,s.[MakePublic]
							,s.[IsActive]
							,s.[IsPublish]
							,s.[IsTicketPurchaseRequired]
							,s.[CanDisplayQualPeriod]
							,s.[CanShowCurrentQualOnline]
							,s.[PK_DefaultLocale]
							,s.[DisplayStartDate]
							,s.[DisplayEndDate]
							,s.[CreatedBy]
							,s.[ModifiedBy]
							,s.[EventVenueName]
							,s.[IsSocialNetworkEnabled]
							,s.[PK_OldEventApp]
							,s.[IsRecurring]
							,s.[CreatedDistributorID]
							,s.[Latitude]
							,s.[Longitude]
					)
				WHEN MATCHED THEN
					UPDATE SET
						[PK_EventType] = s.[PK_EventType]
						,[dStartUTC] = s.[dStartUTC]
						,[dEndUTC] = s.[dEndUTC]
						,[EventName] = s.[EventName]
						,[EventDesc] = s.[EventDesc]
						,[EventCity] = s.[EventCity]
						,[EventState] = s.[EventState]
						,[EventZipCode] = s.[EventZipCode]
						,[EventAddress] = s.[EventAddress]
						,[EventCostDetails] = s.[EventCostDetails]
						,[EventApprovalStatus] = s.[EventApprovalStatus]
						,[IsHotelEnabled] = s.[IsHotelEnabled]
						,[IsInventoryEnabled] = s.[IsInventoryEnabled]
						,[IsPreRegistrationRequired] = s.[IsPreRegistrationRequired]
						,[CanAssignTickets] = s.[CanAssignTickets]
						,[CanPurchaseTicketOnline] = s.[CanPurchaseTicketOnline]
						,[CanRegisterOnline] = s.[CanRegisterOnline]
						,[MakePublic] = s.[MakePublic]
						,[IsActive] = s.[IsActive]
						,[IsPublish] = s.[IsPublish]
						,[IsTicketPurchaseRequired] = s.[IsTicketPurchaseRequired]
						,[CanDisplayQualPeriod] = s.[CanDisplayQualPeriod]
						,[CanShowCurrentQualOnline] = s.[CanShowCurrentQualOnline]
						,[PK_DefaultLocale] = s.[PK_DefaultLocale]
						,[DisplayStartDate] = s.[DisplayStartDate]
						,[DisplayEndDate] = s.[DisplayEndDate]
						,[CreatedBy] = s.[CreatedBy]
						,[ModifiedBy] = s.[ModifiedBy]
						,[EventVenueName] = s.[EventVenueName]
						,[IsSocialNetworkEnabled] = s.[IsSocialNetworkEnabled]
						,[PK_OldEventApp] = s.[PK_OldEventApp]
						,[IsRecurring] = s.[IsRecurring]
						,[CreatedDistributorID] = s.[CreatedDistributorID]
						,[Latitude] = s.[Latitude]
						,[Longitude] = s.[Longitude]
				WHEN NOT MATCHED BY SOURCE AND t.PK_OldEventAPP = @PK_Event THEN
					UPDATE SET IsActive = 0
				OUTPUT $action, inserted.[PK_Event], inserted.[dEndUTC], inserted.[IsActive] INTO @Instances
			;	-- Merge instances to [Event]

			IF @IsDevQA = 1 SELECT PK_Event FROM @Instances;
		
			WITH cte_max AS (
				SELECT MAX([dEndUTC]) AS [dEndUTC] FROM @Instances WHERE [IsActive] = 1
			)
			UPDATE [dbo].[Event] SET 
					[dEndUTC] = (SELECT dEndUTC FROM cte_max)
					,[RecurrenceEndDate] = (SELECT dEndUTC FROM cte_max)
				WHERE [PK_Event] = @PK_Event;

			IF @IsDevQA = 1	SELECT 'Save/Update Event Instances';
		END TRY
		BEGIN CATCH
			SET @Error = ERROR_NUMBER()
			SET @ErrorMessage = 'Save/Update Recurring Events (Event) ' + ERROR_MESSAGE()
			SET @StoredProcedure = ERROR_PROCEDURE()

			IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

			-- UPDATE ERROR LOG
			EXEC dbo.usp_Utility_UpdateErrorLog
							@ProcedureName = @StoredProcedure
							,@ErrorNumber = 3
							,@ErrorMessage = @ErrorMessage
							,@SQLErrorCode = @Error
							,@SQLErrorMsg = @ErrorMessage
				RETURN
		END CATCH;

		------------------------------------------------------------------------------------------------------------------
		-- Save/Update/Delete Recurring Events in EventLocaleDesc
		-- 
		BEGIN TRY
			DELETE FROM [dbo].[EventLocaleDesc] WHERE [PK_Event] IN (SELECT PK_Event FROM @Instances WHERE IsActive = 0);

			INSERT INTO	dbo.EventLocaleDesc	(
					 [PK_Event]
					,[PK_EventType]
					,[PK_Locale]
					,[PK_DefaultLocale]
					,[EventName]
					,[EventDesc]
					,[EventAddress]
					,[EventCity]
					,[EventState]
					,[EventDisplayAddress]
					,[EventCostDetails]	
					,[EventTrainingLanguages]
					,[CreatedBy]
					,[ModifiedBy]
					,[EventApprovalNotes]
					,[EventComments]
					,[EventSummary]
				)
				SELECT
						 i.[PK_Event]
						,e.[PK_EventType]
						,e.[PK_Locale]
						,e.[PK_DefaultLocale]
						,e.[EventName]
						,e.[EventDesc]
						,e.[EventAddress]
						,e.[EventCity]
						,e.[EventState]
						,e.[EventDisplayAddress]
						,e.[EventCostDetails]
						,e.[EventTrainingLanguages]
						,e.[CreatedBy]
						,e.[ModifiedBy]
						,e.[EventApprovalNotes]
						,e.[EventComments]
						,e.[EventSummary]
					FROM @Instances AS i
						CROSS JOIN [dbo].[EventLocaleDesc] e WITH (NOLOCK)
					WHERE e.[PK_Event] = @PK_Event
						AND i.[IsActive] = 1;

			IF @IsDevQA = 1	SELECT 'Save/Update EventLocaleDesc for Instances';
		END TRY
		BEGIN CATCH
			SET @Error = ERROR_NUMBER()
			SET @ErrorMessage = 'Save/Update EventLocaleDesc for Instances' + ERROR_MESSAGE()
			SET @StoredProcedure = ERROR_PROCEDURE()

			IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

			-- UPDATE ERROR LOG
			EXEC dbo.usp_Utility_UpdateErrorLog 
					@ProcedureName = @StoredProcedure
					,@ErrorNumber = 3
					,@ErrorMessage = @ErrorMessage
					,@SQLErrorCode = @Error
					,@SQLErrorMsg = @ErrorMessage
			RETURN
		END CATCH;

		------------------------------------------------------------------------------------------------------------------
		-- Save/Update/Delete Recurring Events in EventURL
		-- 
		BEGIN TRY
			DELETE FROM [dbo].[EventURL] WHERE [PK_Event] IN (SELECT PK_Event FROM @Instances WHERE IsActive = 0);

			INSERT INTO [dbo].[EventURL] (
				[PK_Event]
				,[PK_Locale]
				,[EventURL]
				,[Flyer]
				,[PK_EventURLType]
			)
			SELECT
					i.[PK_Event]
					,e.[PK_Locale]
					,e.[EventURL]
					,e.[Flyer]
					,e.[PK_EventURLType]
				FROM @Instances i
					CROSS JOIN [dbo].[EventURL] e WITH (NOLOCK)
				WHERE e.[PK_Event] = @PK_Event
					AND i.[IsActive] = 1

			IF @IsDevQA = 1	SELECT 'Save/Update EventURL for Instances';
		END TRY
		BEGIN CATCH
			SET @Error = ERROR_NUMBER()
			SET @ErrorMessage = 'Save/Update EventURL for Instances' + ERROR_MESSAGE()
			SET @StoredProcedure = ERROR_PROCEDURE()

			IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

			-- UPDATE ERROR LOG
			EXEC dbo.usp_Utility_UpdateErrorLog 
					@ProcedureName = @StoredProcedure
					,@ErrorNumber = 3
					,@ErrorMessage = @ErrorMessage
					,@SQLErrorCode = @Error
					,@SQLErrorMsg = @ErrorMessage
			RETURN
		END CATCH;

		------------------------------------------------------------------------------------------------------------------
		-- Save/Update/Delete Recurring Events in EventImage, EventImageLocaleDesc
		-- 
		BEGIN TRY;
			WITH cte_i AS (
				SELECT [PK_EventImage] 
					FROM [dbo].[EventImage] WITH (NOLOCK)
					WHERE [PK_Event] IN (SELECT [PK_Event] FROM @Instances)
						AND [PK_EventImageType] IN (1, 2)
			)
			DELETE FROM [dbo].[EventImageLocaleDesc] 
				WHERE [PK_EventImage] IN (SELECT [PK_EventImage] FROM cte_i);
			
			--
			DELETE FROM [dbo].[EventImage]
				WHERE [PK_Event] IN (SELECT PK_Event FROM @Instances)
					AND [PK_EventImageType] IN (1, 2);
	
			--
			INSERT INTO [dbo].[EventImage] (
				[EventImageLocation]
				,[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
				,[PK_Event]
				,[PK_EventImageType]
			)
			SELECT
					e.[EventImageLocation]
					,@StartTime
					,@ModifiedBy
					,@StartTime
					,@ModifiedBy
					,i.[PK_Event]
					,e.[PK_EventImageType]
				FROM @Instances i
					CROSS JOIN [dbo].[EventImage] e WITH (NOLOCK)
				WHERE e.[PK_Event] = @PK_Event;
			
			--
			WITH cte_i AS (
				SELECT [PK_EventImage] 
					FROM [dbo].[EventImage] WITH (NOLOCK)
					WHERE [PK_Event] IN (SELECT [PK_Event] FROM @Instances)
						AND [PK_EventImageType] IN (1, 2)
			)
			INSERT INTO [dbo].[EventImageLocaleDesc] (
					[EventImageLocation]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
					,[PK_EventImage]
					,[PK_Event]
					,[PK_Locale]
			)
			SELECT
					[EventImageLocation]
					,@StartTime
					,@ModifiedBy
					,@StartTime
					,@ModifiedBy
					,[PK_EventImage]
					,[PK_Event]
					,@PK_Locale
				FROM [dbo].[EventImage] WITH (NOLOCK)
				WHERE [PK_EventImage] IN (SELECT [PK_EventImage] FROM cte_i)

			IF @IsDevQA = 1	SELECT 'Save/Update EventImage/EventImageLocaleDesc for Instances';
		END TRY
		
		BEGIN CATCH
			SET @Error = ERROR_NUMBER()
			SET @ErrorMessage = 'Save/Update EventImage/EventImageLocaleDesc for Instances' + ERROR_MESSAGE()
			SET @StoredProcedure = ERROR_PROCEDURE()

			IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

			-- UPDATE ERROR LOG
			EXEC dbo.usp_Utility_UpdateErrorLog 
					@ProcedureName = @StoredProcedure
					,@ErrorNumber = 3
					,@ErrorMessage = @ErrorMessage
					,@SQLErrorCode = @Error
					,@SQLErrorMsg = @ErrorMessage
			RETURN
		END CATCH;
		
		------------------------------------------------------------------------------------------------------------------
		-- Save/Update recurring EventCountry
		-- 
		BEGIN TRY
			IF @IsDevQA = 1	SELECT 'Save/Update Recurring EventCountry';
			
			MERGE EventCountry AS t
				USING (
					SELECT
							[PK_EventCountry]
							,i.[PK_Event]
							,(	SELECT [nCountryID] 
								FROM	v_Countries WITH (NOLOCK) 
								WHERE	sCountryCodeISO = @EventCountry
										OR (sCountryCode in ('-1','-2','-V','-W') and sCountryCode = @EventCountry)			-- BUG 320336 - Cannot save changes on DS event. Rollback root cause: Bug 266825 bug fix
							) AS PK_Country
							,@ModifiedBy AS CreatedBy
							,@ModifiedBy AS ModifiedBy
						FROM @Instances AS i
							LEFT JOIN EventCountry AS e WITH (NOLOCK) ON e.PK_Event = i.PK_Event 
								AND e.[PK_Country] = (	SELECT	nCountryID 
														FROM	v_countries WITH (NOLOCK) 
														WHERE	sCountryCodeISO = @EventCountry
																OR (sCountryCode in ('-1','-2','-V','-W') and sCountryCode = @EventCountry)       -- BUG 320336 - Cannot save changes on DS event. Rollback root cause: Bug 266825 bug fix
													)
					) AS s ON (t.[PK_EventCountry] = s.[PK_EventCountry])
				WHEN MATCHED THEN
					UPDATE SET
							t.[PK_Event] = s.[PK_Event]
							,t.[PK_Country] = s.[PK_Country]
							,t.[ModifiedDateUTC] = @StartTime
							,t.[ModifiedBy] = s.ModifiedBy
				WHEN NOT MATCHED THEN
					INSERT (
							[PK_Event]
							,[PK_Country]
					)
					VALUES (
							s.[PK_Event]
							,s.PK_Country
					)
			;	-- MERGE EventCountry

		END TRY
		BEGIN CATCH
		   SET @Error = ERROR_NUMBER();
		   SET @ErrorMessage = 'Save/Update EventCountry ' + ERROR_MESSAGE();
		   SET @StoredProcedure = ERROR_PROCEDURE();

		   IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		   -- UPDATE ERROR LOG
		   EXEC dbo.usp_Utility_UpdateErrorLog 
						@ProcedureName = @StoredProcedure
						,@ErrorNumber = 3
						,@ErrorMessage = @ErrorMessage
						,@SQLErrorCode = @Error
						,@SQLErrorMsg = @ErrorMessage;
			RETURN
		END CATCH;

	END; -- Recurring event section

	------------------------------------------------------------------------------------------------------------------
	-- Save/Update/Delete Event guest speakers
	-- 
	BEGIN TRY
		
		EXEC dbo.usp_EventAPI_Save_GuestSpeakers
				@PK_Event = @PK_Event
				,@GuestSpeakers = @GuestSpeakers
				,@IsDevQA = @IsDevQA
				,@Error = @Error OUTPUT /* @e must be defined in the local call */
				,@ErrorMessage = @ErrorMessage OUTPUT /* @em must be defined in the local call */

		IF @Error != 0 RAISERROR(@Error, @ErrorMessage, 15600, 1);
		
		IF @IsDevQA = 1	SELECT 'Save/Update Event guest speakers';
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'Save/Update Event guest speakers' + ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage 
		RETURN
	END CATCH;

	------------------------------------------------------------------------------------------------------------------
	-- Save/Update/Delete Media
	-- 
	BEGIN TRY
		
		EXEC dbo.usp_EventAPI_Save_EventMedia
				@PK_Event = @PK_Event
				,@EventMedia = @EventMedia
				,@IsDevQA = @IsDevQA
				,@Error = @Error OUTPUT  /* @e must be defined in the local call */
				,@ErrorMessage = @ErrorMessage OUTPUT /* @em must be defined in the local call */
					
		IF @Error != 0 RAISERROR(@Error, @ErrorMessage, 15600, 1);

		IF @IsDevQA = 1	SELECT 'Save/Update Event media';
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'Save/Update Event media' + ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN
	END CATCH;
	
	------------------------------------------------------------------------------------------------------------------
	-- Save/Update/Delete Coordinators
	-- 
	BEGIN TRY
		IF @IsDevQA = 1 SELECT 'Save/Update/Delete Coordinators';

		IF OBJECT_ID('tempdb.dbo.#Coords') IS NOT NULL
			DROP TABLE #Coords;

		DECLARE @CoordMerge table([action] varchar(10), [PK_EventCoordinatorDetail] int, [PK_Event] int, [CreatedDistributorID] varchar(50), [CoordinatorName] varchar(255));
		
		SELECT 
				Coords.col.value('PK_EventCoordinatorDetail[1]', 'int') AS [PK_EventCoordinatorDetail]
				,Coords.col.value('CoordinatorID[1]', 'varchar(20)') AS [CoordinatorID]
				,Coords.col.value('EventOwner[1]', 'bit') AS [EventOwner]
				,Coords.col.value('Email[1]', 'nvarchar(255)') AS [Email]
				,Coords.col.value('tel[1]', 'nvarchar(200)') AS [Phone]
				,Coords.col.value('Name[1]', 'nvarchar(255)') AS [Name]
				,Coords.col.value('Website[1]', 'nvarchar(255)') AS [Website]
				,@PK_Event AS PK_Event
			INTO #Coords
			FROM @Coordinators.nodes('/Coordinator') AS Coords(col);
			
		IF @IsDevQA = 1 SELECT PK_Event FROM #Coords;
		
		WITH cte_dis AS(
			SELECT
				c.[PK_EventCoordinatorDetail]
				,c.[EventOwner]
				,ds.[PK_Distributor] AS [CoordinatorID]
				,ds.[DistributorID] AS [CreatedDistributorID]
				,ds.[FirstName] AS [FirstName]
				,ds.[LastName] AS [LastName]
				,c.[Email]
				,t.[TeamDesc] AS [CoordinatorTeamLevel]
				,c.[Phone]
				,ISNULL(c.[Name], (ds.[FirstName] + ' ' + ds.[LastName])) AS [Name]
				,c.[Website]
			FROM #Coords AS c
				INNER JOIN [PubEvents].[dbo].[dimDistributor] AS ds WITH (NOLOCK) ON c.[CoordinatorID] = ds.[DistributorID]
				LEFT JOIN [PubEvents].[dbo].[dimDSContactInfo] AS ci WITH (NOLOCK) ON ds.[PK_Distributor] = ci.[PK_Distributor]
				LEFT JOIN [PubEvents].[dbo].[dimDSTeam] AS t WITH (NOLOCK) ON ds.[PK_DSTeam] = t.[PK_DSTeam]
		) 
		,cte_coord AS (
			SELECT
					NULLIF(ISNULL(d.[PK_EventCoordinatorDetail], e.[PK_EventCoordinatorDetail]), 0) AS [PK_EventCoordinatorDetail]
					,d.[CreatedDistributorID]
					,@PK_Event AS [PK_Event]
					,d.[CoordinatorID]
					,d.[EventOwner] AS [CoordinatorTitle]
					,d.[CoordinatorTeamLevel]
					,d.[Name] AS [CoordinatorName]
					,d.[Phone] AS [CoordinatorPhone]
					,d.[Email] AS [CoordinatorEmail]
					,d.[Website] AS [CoordinatorWebsite]
					,GETUTCDATE() AS [CreatedDateUTC]
					,'rogelior' As [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,'rogelior' As [ModifiedBy]
				FROM cte_dis AS d
					LEFT JOIN [dbo].[EventCoOrdinatorDetail] AS e WITH (NOLOCK) ON e.[PK_Event] = @PK_Event
						AND e.[CreatedDistributorID] = d.[CreatedDistributorID]
		) 
		MERGE [dbo].[EventCoordinatorDetail] AS t
			USING (
				SELECT
						[PK_EventCoordinatorDetail]
						,[PK_Event]
						,[CreatedDistributorID]
						,[CoordinatorID]
						,[CoordinatorName]
						,[CoordinatorEmail]
						,[CoordinatorPhone]
						,[CoordinatorTeamLevel]
						,[CoordinatorTitle]
						,[CoordinatorWebsite]
						,[CreatedBy]
						,[CreatedDateUTC]
						,[ModifiedBy]
						,[ModifiedDateUTC]
					FROM cte_coord
				) AS s ON t.[PK_EventCoordinatorDetail] = s.[PK_EventCoordinatorDetail]
			WHEN MATCHED THEN
				UPDATE SET
					[CoordinatorName] = s.[CoordinatorName]
					,[CoordinatorEmail] = s.[CoordinatorEmail]
					,[CoordinatorTeamLevel] = s.[CoordinatorTeamLevel]
					,[CoordinatorPhone] = s.[CoordinatorPhone]
					,[CoordinatorTitle] = s.[CoordinatorTitle]
					,[CoordinatorWebsite] = s.[CoordinatorWebsite]
					,[ModifiedBy] = s.[ModifiedBy]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
			WHEN NOT MATCHED THEN
				INSERT(
						[PK_Event]
						,[CreatedDistributorID]
						,[CoordinatorID]
						,[CoordinatorName]
						,[CoordinatorEmail]
						,[CoordinatorPhone]
						,[CoordinatorTeamLevel]
						,[CoordinatorTitle]
						,[CoordinatorWebsite]
						,[CreatedBy]
						,[CreatedDateUTC]
						,[ModifiedBy]
						,[ModifiedDateUTC]
				)
				VALUES(
					s.[PK_Event]
					,s.[CreatedDistributorID]
					,s.[CoordinatorID]
					,s.[CoordinatorName]
					,s.[CoordinatorEmail]
					,s.[CoordinatorPhone]
					,s.[CoordinatorTeamLevel]
					,s.[CoordinatorTitle]
					,s.[CoordinatorWebsite]
					,s.[CreatedBy]
					,s.[CreatedDateUTC]
					,s.[ModifiedBy]
					,s.[ModifiedDateUTC]
				)
			WHEN NOT MATCHED BY SOURCE AND t.PK_Event = @PK_Event THEN
				DELETE
			OUTPUT $action, inserted.[PK_EventCoordinatorDetail], inserted.[PK_Event], inserted.[CreatedDistributorID], inserted.[CoordinatorName] INTO @CoordMerge
		; -- MERGE [EventCorrdinatorDetail]

		IF @IsDevQA = 1	SELECT PK_Event FROM @CoordMerge;

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'Save/Update coordinators' + ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage 
		RETURN
	END CATCH;


	------------------------------------------------------------------------------------------------------------------
	-- Save/Update	Agenda
	-- 
	BEGIN TRY
		IF @IsDevQA = 1	SELECT 'Save/Update Agenda';

		EXEC dbo.usp_EventAPI_Save_Agenda
				@PK_Event = @PK_Event
				,@Agenda = @Agenda
				,@IsDevQA = 0
				,@Error = @Error OUTPUT  /* @e must be defined in the local call */
				,@ErrorMessage = @ErrorMessage OUTPUT /* @em must be defined in the local call */
			
		IF @Error != 0 RAISERROR(@Error, @ErrorMessage, 15600, 1);

		IF @ApprovalFlag = 1
		BEGIN
			
			IF OBJECT_ID('tempdb.dbo.#AgendaItems') IS NOT NULL
				DROP TABLE #AgendaItems;

			--
			SELECT 
					ai.[PK_AgendaItem]
					,ai.[PK_SubEvent]
					,a.[PK_Event]
					,2 AS [PK_SubEventType]
					,1 AS [MaxCapacity]
					,1 AS [ExpectedCapacity]
					,ai.DisplayDescription AS [SubEventName]
					,(ROW_NUMBER() OVER (ORDER BY (SELECT NULL))) + ISNULL((SELECT MAX(SubEventNumber) FROM SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_Event), 0) AS [SubEventNumber]
					,ai.LocalStartDate AS [BeginTime]
					,ai.LocalEndDate AS [EndTime]
					,ai.DisplayLocation AS [Location]
					,getutcdate() AS [CreatedDateUTC]
					,replace(suser_sname(),'HERBALIFECORP\','') AS [CreatedBy]
					,getutcdate() AS [ModifiedDateUTC]
					,replace(suser_sname(),'HERBALIFECORP\','') AS [ModifiedBy]
				INTO #AgendaItems
				FROM Agenda AS a WITH (NOLOCK)
					INNER JOIN AgendaItem AS ai WITH (NOLOCK) ON ai.PK_Agenda = a.PK_Agenda
				WHERE a.[PK_Event] = @PK_Event
					AND [IsSubEvent] = 1;
			
			IF @IsDevQA = 1 SELECT '#AgendaItems Start' FROM #AgendaItems;

			DECLARE @SubEvents table(
						[action] varchar(20)
						,[PK_SubEvent] int
						,[SubEventName] varchar(max)
						,[SubEventNumber] int
						,[PK_DelSubEvent] int);

			WITH c AS (
				SELECT
						[PK_SubEvent]
						,[PK_Event]
						,[PK_SubEventType]
						,[MaxCapacity]
						,[ExpectedCapacity]
						,[SubEventName]
						,[SubEventNumber]
						,[BeginTime]
						,[EndTime]
						,[Location]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
					FROM #AgendaItems
			)	
			MERGE [dbo].[SubEvent] AS t
				USING (
					SELECT
							[PK_SubEvent]
							,[CreatedDateUTC]
							,[CreatedBy]
							,[ModifiedDateUTC]
							,[ModifiedBy]
							,[PK_Event]
							,[PK_SubEventType]
							,[MaxCapacity]
							,[ExpectedCapacity]
							,[SubEventName]
							,[SubEventNumber]
							,[BeginTime]
							,[EndTime]
							,[Location]
						FROM c
					) AS s ON s.[PK_SubEvent] = t.[PK_SubEvent]
				WHEN MATCHED THEN
					UPDATE SET
						[ModifiedDateUTC] = s.[ModifiedDateUTC]
						,[ModifiedBy] = s.[ModifiedBy]
						,[SubEventName] = s.[SubEventName]
						,[SubEventNumber] = s.[SubEventNumber]
						,[BeginTime] = s.[BeginTime]
						,[EndTime] = s.[EndTime]
						,[Location] = s.[Location]
				WHEN NOT MATCHED THEN
					INSERT (
							[CreatedDateUTC]
							,[CreatedBy]
							,[ModifiedDateUTC]
							,[ModifiedBy]
							,[PK_Event]
							,[PK_SubEventType]
							,[MaxCapacity]
							,[ExpectedCapacity]
							,[SubEventName]
							,[SubEventNumber]
							,[BeginTime]
							,[EndTime]
							,[Location]
					)
					VALUES (
							s.[CreatedDateUTC]
							,s.[CreatedBy]
							,s.[ModifiedDateUTC]
							,s.[ModifiedBy]
							,s.[PK_Event]
							,s.[PK_SubEventType]
							,s.[MaxCapacity]
							,s.[ExpectedCapacity]
							,s.[SubEventName]
							,s.[SubEventNumber]
							,s.[BeginTime]
							,s.[EndTime]
							,s.[Location]
					)
				WHEN NOT MATCHED BY SOURCE AND t.[PK_Event] = @PK_Event THEN
					DELETE
				OUTPUT	$action
						,inserted.[PK_SubEvent]
						,inserted.[SubEventName]
						,inserted.[SubEventNumber]
						,deleted.[PK_SubEvent]
					INTO @SubEvents
				;
				
				IF @IsDevQA = 1
				BEGIN
					SELECT '@SubEvents' FROM @SubEvents
				
					SELECT '#AgendaItems' FROM #AgendaItems
				
					SELECT [PK_DelSubEvent] AS 'DeleteList' 
						FROM @SUbEvents 
						WHERE [PK_DelSubEvent] IN (SELECT [PK_DelSubEvent] FROM @SubEvents WHERE [Action] = 'DELETE') 
				END;
				
				IF @IsDevQA = 1 SELECT 'Update AgendaItem';

				UPDATE ai SET
						ai.[SubEventNumber] = CAST(t.[SubEventNumber] AS varchar(200))
					FROM [dbo].[AgendaItem] AS ai WITH (NOLOCK)
						INNER JOIN #AgendaItems AS t ON t.[PK_AgendaItem] = ai.[PK_AgendaItem]
					WHERE ai.[PK_Agenda] = (SELECT [PK_Agenda] FROM [dbo].[Agenda] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)

				IF @IsDevQA = 1 SELECT 'Update AgendaItem/SubEvent';

				UPDATE ai SET
						ai.[PK_SubEvent] = s.[PK_SubEvent]
					FROM [dbo].[AgendaItem] AS ai WITH (NOLOCK)
						INNER JOIN [dbo].[SubEvent] AS s WITH (NOLOCK) ON s.[SubEventName] = ai.[DisplayDescription]
							AND s.[SubEventNumber] = CAST(ai.[SubEventNumber] AS int)
					WHERE s.[PK_Event] = @PK_Event
						AND ai.[PK_Agenda] IN (SELECT [PK_Agenda] FROM [dbo].[Agenda] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event);

				-- If there were deleted subevents, update the LocalSubEventQualifier to remove any qualified distributors to those subevents
				DELETE FROM [LocalSubEventQualifier] 
					WHERE [PK_Event] = @PK_Event
						AND [PK_SubEvent] IN (SELECT [PK_DelSubEvent] FROM @SubEvents WHERE [Action] = 'DELETE');
		END;
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'Save/Update Agenda' + ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN
	END CATCH;
	
	------------------------------------------------------------------------------------------------------------------
	-- Save/Update	Audience ([EventDistributorCountryLocales])
	-- 
	BEGIN TRY;
		WITH cte_Audience AS (
			SELECT
					E.[PK_EventDistributorCountryLocales]
					,@PK_Event AS [PK_Event]
					,l.[PK_Locale]
					,CASE WHEN l.[LocaleCode] = @LocaleCode THEN 1 ELSE 0 END AS [IsDefault]
					,ISNULL(e.[CreatedDateUTC], GETUTCDATE()) AS [CreatedDateUTC]
					,ISNULL(e.[CreatedBy], @ModifiedBy) AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,@ModifiedBy AS [ModifiedBy]
				FROM [dbo].[udf_SplitVarchar](@Audience, ',') AS a
					INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[LocaleCode] = a.[String]
					LEFT JOIN [dbo].[EventDistributorCountryLocales] AS e WITH (NOLOCK) ON e.PK_Event = @PK_Event
						AND l.[PK_Locale] = e.[PK_Locale]
		)
		MERGE [dbo].[EventDistributorCountryLocales] AS t
			USING (SELECT 
							[PK_EventDistributorCountryLocales]
							,[PK_Event]
							,[PK_Locale]
							,[IsDefault]
							,[CreatedDateUTC]
							,[CreatedBy]
							,[ModifiedDateUTC]
							,[ModifiedBy]
						FROM cte_Audience
				) AS s ON s.[PK_EventDistributorCountryLocales] = t.[PK_EventDistributorCountryLocales]
			WHEN MATCHED THEN
				UPDATE SET
					[IsDefault] = s.[IsDefault]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
			WHEN NOT MATCHED THEN
				INSERT (
					[PK_Event]
					,[PK_Locale]
					,[IsDefault]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
				)
				VALUES (
					s.[PK_Event]
					,s.[PK_Locale]
					,s.[IsDefault]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
				)
			WHEN NOT MATCHED BY SOURCE AND [PK_Event] = @PK_Event THEN
				DELETE
		; -- MERGE [EventDistributorCountryLocales]

	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'Save/Update audience' + ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN
	END CATCH;
	;	-- MERGE [EventDistributorCountryLocales]


	------------------------------------------------------------------------------------------------------------------
	-- Save/Update	Tickets
	-- 
	BEGIN TRY
		IF @IsDevQA = 1	SELECT 'Save/Update Tickets', @PK_Event, @LocaleCode;

		EXEC [dbo].[usp_EventAPI_Save_DSTickets]
							@PK_Event = @PK_Event
							,@LocaleCode = @LocaleCode
							,@Tickets = @Tickets
							,@IsDevQA = 0
							,@Error = @Error OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @ErrorMessage OUTPUT /* @em must be defined in the local call */
			
		IF @Error != 0 RAISERROR(@Error, @ErrorMessage, 15600, 1);
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'Save/Update Tickets' + ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN
	END CATCH;

	-----------------------------------------------------------------------------------------------------------------------
	-- Merge EventDSTeamType
	--	
	BEGIN TRY;
		WITH cte_SubLevel AS (
			SELECT SubLevel.query('.').value('SubLevel[1]', 'varchar(20)') AS SubLevel
				FROM @TeamLevels.nodes('/TeamLevels/*') AS TeamLevels(SubLevel)
		)
		MERGE dbo.EventDSTeamType AS t
			USING ( 
					SELECT	ST.SubTypeCode AS [DSTeamTypeCode]
							,@PK_Event AS [PK_Event]
							,ST.TYPECODE
					FROM	cte_SubLevel sl
							INNER JOIN PubEvents..dimDSSubType ST WITH (NOLOCK)
								ON sl.SubLevel = ST.TYPECODE
					UNION
					SELECT	STREL.[DSTeamTypeCode]
							,@PK_Event AS [PK_Event]
							,ST.TYPECODE
					FROM	cte_SubLevel sl
							INNER JOIN 
								(
									SELECT	PL.PrimaryLevelCode
											,ST.SubTypeCode AS [DSTeamTypeCode]
											,@PK_Event AS [PK_Event]
											,'PM' AS [TYPECODE]
									FROM	PubEvents..dimDSSubType ST WITH (NOLOCK)
											INNER JOIN PMPrimaryLevelDSSubType PLST WITH (NOLOCK)
												ON ST.PK_DSSubType = PLST.PK_DSSubType
											INNER JOIN PMPrimaryLevel PL WITH (NOLOCK)
												ON PLST.PK_PMPrimaryLevel = PL.PK_PMPrimaryLevel
								) STREL
								ON sl.SubLevel = STREL.TYPECODE
							INNER JOIN PubEvents..dimDSSubType ST WITH (NOLOCK)
								ON ST.SubTypeCode = STREL.PrimaryLevelCode
				) AS s
				ON (t.[PK_Event] = @PK_Event AND t.[DSTeamTypeCode] = s.[DSTeamTypeCode])
			WHEN NOT MATCHED THEN
				INSERT (
					[DSTeamTypeCode]
					,[PK_Event]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
				)
				VALUES (
					s.[DSTeamTypeCode]
					,s.[PK_Event]
					,GETUTCDATE()
					,@ModifiedBy
					,GETUTCDATE()
					,@ModifiedBy
				)
			WHEN NOT MATCHED BY SOURCE AND t.[PK_Event] = @PK_Event THEN
				DELETE
		;
		
		IF(@IsDevQA = 1)	-- Show EventDSTeamType
		BEGIN
			SELECT 'Save/Update EventDSTeamType';
		END;
		END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = 'Save/Update EventDSTeamType' + ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage 
		RETURN
	END CATCH;
	
	--
	SELECT @PK_Event PK_Event	-- Event created/updated

	-- UPDATE PROCESSING LOG
	EXEC dbo.usp_Utility_UpdateProcessingLog 
			 @StoredProcedureName = @StoredProcedure
			 ,@StartTime = @StartTime

END;