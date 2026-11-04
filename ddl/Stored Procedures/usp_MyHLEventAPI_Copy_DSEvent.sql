CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Copy_DSEvent]
	-- Required
	@PK_Event			int

	-- Optional
	,@EventDefaultNamePrefix varchar(255) = 'Copy of '

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************

	OBJECT:			[dbo].[usp_MyHLEventAPI_Copy_DSEvent]

	USE:			
				BEGIN TRANSACTION

				DECLARE @e int, @em varchar(4000)

				EXEC [dbo].usp_MyHLEventAPI_Copy_DSEvent
						@PK_Event = 78005
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

				ROLLBACK TRANSACTION
				

	DESCRIPTION:	Creates a new event and copies all the related information

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event, dbo.EventLocaleDesc, dbo.EventExtn, dbo.EventDSTeamType, dbo.EventDistributorCountryLocales

	VERSIONS (d)
	--------------------------------------------------------------------
	1.0.0		2017-11-14		RogelioR		Initial
	1.1.0		2019-08-14		NoeG			Refactor code (SRE)
	
******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@PK_NewEvent int 
			,@PK_DefaultLocale int
			,@LocaleCode varchar(5)
			,@ModifiedBy varchar(255) = (replace(suser_sname(),'HERBALIFECORP\',''))
			,@GuestSpeakersXML xml
			,@EventMedia xml
			,@EventVersion int;
			
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY
		------------------------------------------------------------------------------------------------------------------
		-- Copy Event
		-- 
		DECLARE @Event TABLE (
			[PK_Event] int
			,[PK_DefaultLocale] int
		);
		
		INSERT INTO [dbo].[Event] (
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
		OUTPUT inserted.[PK_Event], inserted.[PK_DefaultLocale] INTO @Event
		SELECT
				[PK_EventType]
				,NULL [dStartUTC]
				,NULL [dEndUTC]
				,@EventDefaultNamePrefix + [EventName]
				,[EventDesc]
				,[EventCity]
				,[EventState]
				,[EventZipCode]
				,[EventAddress]
				,[EventCostDetails]
				,3 AS [EventApprovalStatus]
				,[IsHotelEnabled]
				,[IsInventoryEnabled]
				,[IsPreRegistrationRequired]
				,[CanAssignTickets]
				,[CanPurchaseTicketOnline]
				,[CanRegisterOnline]
				,[MakePublic]
				,1 AS [IsActive]
				,0 AS [IsPublish]
				,[IsTicketPurchaseRequired]
				,[CanDisplayQualPeriod]
				,[CanShowCurrentQualOnline]
				,[PK_DefaultLocale]
				,NULL AS [DisplayStartDate]
				,NULL AS [DisplayEndDate]
				,@ModifiedBy AS [CreatedBy]
				,@ModifiedBy AS [ModifiedBy]
				,[EventVenueName]
				,[IsSocialNetworkEnabled]
				,[CreatedDistributorID]
				,0 AS [IsRecurring]
				,NULL AS [PK_RecurrenceType]
				,NULL AS [RecurrenceEndDate]
				,[Latitude]
				,[Longitude]
				,[Location]
				,2 AS [Version]
			FROM [dbo].[Event] WITH(NOLOCK)
			WHERE [PK_Event] = @PK_Event;
	
		SELECT	@PK_NewEvent = @@IDENTITY
				,@PK_DefaultLocale = (SELECT [PK_DefaultLocale] FROM @Event)
				,@EventVersion = ISNULL((SELECT [Version] FROM [Event] WITH(NOLOCK) WHERE [PK_Event] = @PK_Event), 1);

		SELECT	@LocaleCode = (SELECT [LocaleCode] FROM [dbo].[Locales] WITH(NOLOCK) WHERE [PK_Locale] = @PK_DefaultLocale);
		
		IF @IsDevQA = 1 SELECT @PK_DefaultLocale, @LocaleCode FROM [dbo].[Event] WITH(NOLOCK) WHERE PK_Event = @PK_Event;


		------------------------------------------------------------------------------------------------------------------
		-- Copy EventExtn (RSVP fields)
		-- 	
		INSERT INTO [dbo].[EventExtn] (
			[PK_Event]
			,[RSVPRegistrations]
			,[RSVPGuests]
			,[CreatedDateUTC]
			,[CreatedBy]
			,[ModifiedDateUTC]
			,[ModifiedBy]
		)
		SELECT
				@PK_NewEvent AS [PK_Event]
				,[RSVPRegistrations]
				,[RSVPGuests]
				,@StartTime AS [CreatedDateUTC]
				,@ModifiedBy As [CreatedBy]
				,@StartTime AS [ModifiedDateUTC]
				,@ModifiedBy As [ModifiedBy]
			FROM [dbo].[EventExtn] WITH(NOLOCK)
			WHERE PK_EVENT = @PK_Event;

		IF @IsDevQA = 1 SELECT PK_EventExtn FROM [dbo].[EventExtn] WITH(NOLOCK) WHERE PK_EventExtn = @@IDENTITY;

		------------------------------------------------------------------------------------------------------------------
		-- Copy EventCountry
		-- 
		INSERT INTO [dbo].[EventCountry] (
				[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
				,[PK_Event]
				,[PK_Country]			
		)
		SELECT
				@StartTime AS [CreatedDateUTC]
				,@ModifiedBy As [CreatedBy]
				,@StartTime AS [ModifiedDateUTC]
				,@ModifiedBy As [ModifiedBy]
				,@PK_NewEvent AS [PK_Event]
				,[PK_Country]
			FROM [dbo].[EventCountry] WITH(NOLOCK)
			WHERE [PK_Event] = @PK_Event;

		IF @IsDevQA = 1 SELECT PK_EventCountry FROM [dbo].[EventCountry] WITH(NOLOCK) WHERE [PK_Event] = @PK_NewEvent;


		------------------------------------------------------------------------------------------------------------------
		-- Copy EventLocaleDesc
		-- 
		INSERT INTO [dbo].[EventLocaleDesc] (
				[PK_Event]
				,[PK_EventType]
				,[PK_Locale]
				,[PK_DefaultLocale]
				,[EventName]
				,[EventDesc]
				,[EventSummary]
				,[EventAddress]
				,[EventCity]
				,[EventState]
				,[Keywords]
				,[EventCostDetails]
				,[EventDisplayAddress]
				,[EventTrainingLanguages]
				,[EventApprovalNotes]
				,[EventComments]
				,[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
		)
		SELECT
				@PK_NewEvent AS PK_Event
				,[PK_EventType]
				,[PK_Locale]
				,[PK_DefaultLocale]
				,@EventDefaultNamePrefix + [EventName] AS [EventName]
				,[EventDesc]
				,[EventSummary]
				,[EventAddress]
				,[EventCity]
				,[EventState]
				,[Keywords]
				,[EventCostDetails]
				,[EventDisplayAddress]
				,[EventTrainingLanguages]
				,[EventApprovalNotes]
				,[EventComments]
				,@StartTime AS [CreatedDateUTC]
				,@ModifiedBy As [CreatedBy]
				,@StartTime AS [ModifiedDateUTC]
				,@ModifiedBy As [ModifiedBy]
			FROM [dbo].[EventLocaleDesc] WITH(NOLOCK)
			WHERE [PK_Event] = @PK_Event;

		IF @IsDevQA = 1 SELECT PK_EventLocaleDesc FROM [dbo].[EventLocaleDesc] WITH(NOLOCK) WHERE [PK_Event] = @PK_NewEvent;


		------------------------------------------------------------------------------------------------------------------
		-- Copy EventURL
		-- 
		DECLARE @EventURL TABLE (
				[PK_Event] int
				,[PK_Locale] int
				,[EventURL] nvarchar(max)
				,[EventURLDesc] nvarchar(max)
				,[Flyer] nvarchar(max)
				,[PK_EventURLType] int
		);

		INSERT INTO [dbo].[EventURL] (
				[PK_Event]
				,[PK_Locale]
				,[EventURL]
				,[EventURLDesc]
				,[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
				,[Flyer]
				,[PK_EventURLType]
		)
		OUTPUT
				inserted.[PK_Event]
				,inserted.[PK_Locale]
				,inserted.[EventURL]
				,inserted.[EventURLDesc]
				,inserted.[Flyer]
				,inserted.[PK_EventURLType]
			INTO @EventURL
		SELECT
				@PK_NewEvent AS [PK_Event]
				,[PK_Locale]
				,[EventURL]
				,[EventURLDesc]
				,[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
				,[Flyer]
				,[PK_EventURLType]
			FROM [dbo].[EventURL] WITH(NOLOCK)
			WHERE [PK_Event] = @PK_Event
				AND [PK_EventURLType] != 5;

		IF @IsDevQA = 1 SELECT PK_EventURL FROM [dbo].[EventURL] WITH(NOLOCK) WHERE [PK_Event] = @PK_NewEvent;
		

		------------------------------------------------------------------------------------------------------------------
		-- Copy EventImage
		-- 
		IF OBJECT_ID('tempdb..#EventImage') IS NOT NULL
			DROP TABLE #EventImage;
		
		IF OBJECT_ID('tempdb..#NewEventImage') IS NOT NULL
			DROP TABLE #NewEventImage;

		CREATE TABLE #EventImage(
			PK_EventImage	int
			,EventImageLocation	nvarchar(max)
			,CreatedDateUTC	datetime
			,CreatedBy	varchar(50)
			,ModifiedDateUTC	datetime
			,ModifiedBy	varchar(50)
			,PK_Event	int
			,PK_EventImageType	int
			,PK_NewEventImage int
		);
				
		CREATE TABLE #NewEventImage(
			PK_EventImage	int
			,EventImageLocation	nvarchar(max)
			,CreatedDateUTC	datetime
			,CreatedBy	varchar(50)
			,ModifiedDateUTC	datetime
			,ModifiedBy	varchar(50)
			,PK_Event	int
			,PK_EventImageType	int
		);

		--
		INSERT INTO #EventImage(
			[PK_EventImage]
			,[EventImageLocation]
			,[CreatedDateUTC]
			,[CreatedBy]
			,[ModifiedDateUTC]
			,[ModifiedBy]
			,[PK_Event]
			,[PK_EventImageType]
		)
		SELECT
				[PK_EventImage]
				,[EventImageLocation]
				,@StartTime AS [CreatedDateUTC]
				,@ModifiedBy As [CreatedBy]
				,@StartTime AS [ModifiedDateUTC]
				,@ModifiedBy As [ModifiedBy]
				,@PK_NewEvent AS [PK_Event]
				,[PK_EventImageType]
			FROM [dbo].[EventImage] WITH(NOLOCK)
			WHERE PK_Event = @PK_Event;

		INSERT INTO [dbo].[EventImage] (
			[EventImageLocation]
			,[CreatedDateUTC]
			,[CreatedBy]
			,[ModifiedDateUTC]
			,[ModifiedBy]
			,[PK_Event]
			,[PK_EventImageType]
		)
		OUTPUT	inserted.[PK_EventImage]
				,inserted.[EventImageLocation]
				,inserted.[CreatedDateUTC]
				,inserted.[CreatedBy]
				,inserted.[ModifiedDateUTC]
				,inserted.[ModifiedBy]
				,inserted.[PK_Event]
				,inserted.[PK_EventImageType]
			INTO #NewEventImage
		SELECT
				[EventImageLocation]
				,@StartTime AS [CreatedDateUTC]
				,@ModifiedBy As [CreatedBy]
				,@StartTime AS [ModifiedDateUTC]
				,@ModifiedBy As [ModifiedBy]
				,@PK_NewEvent AS [PK_Event]
				,[PK_EventImageType]
			FROM [dbo].[EventImage] WITH(NOLOCK)
			WHERE PK_Event = @PK_Event;

		UPDATE t SET
				[PK_NewEventImage] = n.[PK_EventImage]
			FROM #EventImage AS t
				INNER JOIN #NewEventImage AS n ON n.[EventImageLocation] = t.[EventImageLocation];

		IF @IsDevQA = 1 SELECT PK_EventImage FROM [dbo].[EventImage] WITH(NOLOCK) WHERE PK_Event = @PK_NewEvent;

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
				d.[EventImageLocation]
				,@StartTime AS [CreatedDateUTC]
				,@ModifiedBy As [CreatedBy]
				,@StartTime AS [ModifiedDateUTC]
				,@ModifiedBy As [ModifiedBy]
				,e.PK_NewEventImage AS [PK_EventImage]
				,@PK_NewEvent AS [PK_Event]
				,d.[PK_Locale]
			FROM [dbo].[EventImageLocaleDesc] AS d WITH(NOLOCK)
				INNER JOIN #EventImage AS e ON e.[PK_EventImage] = d.[PK_EventImage]
			WHERE d.[PK_Event] = @PK_Event;

		IF @IsDevQA = 1 SELECT PK_EventImageLocaleDesc FROM [dbo].[EventImageLocaleDesc] WHERE PK_Event = @PK_NewEvent;


		------------------------------------------------------------------------------------------------------------------
		-- Copy EVentEventSubType
		-- 
		DECLARE @EventEventSubType TABLE(
			[PK_Event] int
			,[PK_EventType] int
			,[PK_EventSubType] int
		);
		
		INSERT INTO [dbo].[EventEventSubType](
			[PK_Event]
			,[PK_EventType]
			,[PK_EventSubType]
			,[CreatedDateUTC]
			,[CreatedBy]
			,[ModifiedDateUTC]
			,[ModifiedBy]
		)
		OUTPUT inserted.[PK_Event], inserted.[PK_EventType], inserted.[PK_EventSubType] INTO @EventEventSubType
		SELECT
				@PK_NewEvent AS [PK_Event]
				,[PK_EventType]
				,[PK_EventSubType]
				,@StartTime AS [CreatedDateUTC]
				,@ModifiedBy As [CreatedBy]
				,@StartTime AS [ModifiedDateUTC]
				,@ModifiedBy As [ModifiedBy]
			FROM [dbo].[EventEventSubType] WITH(NOLOCK)
			WHERE [PK_Event] = @PK_Event;
			
		IF @IsDevQA = 1 SELECT PK_Event FROM @EventEventSubType;


		------------------------------------------------------------------------------------------------------------------
		-- Copy Coordinators
		--
		DECLARE @Coordinators TABLE (
				[PK_EventCoordinatorDetail] int
				,[PK_Event] int
				,[CreatedDistributorID] varchar(10)
				,[CreatedDateUTC] datetime2
				,[CreatedBy] nvarchar(100)
				,[ModifiedDateUTC] datetime2
				,[ModifiedBy] nvarchar(100)
		);

		INSERT INTO [dbo].[EventCoordinatorDetail] (
				[PK_Event]
				,[CreatedDistributorID]
				,[CoordinatorID]
				,[CoordinatorName]
				,[CoordinatorPhone]
				,[CoordinatorEmail]
				,[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
				,[CoordinatorTitle]
				,[CoordinatorTeamLevel]
				,[CoordinatorWebsite]
		)
		OUTPUT	inserted.[PK_EventCoordinatorDetail]
				,inserted.[PK_Event]
				,inserted.[CreatedDistributorID]
				,inserted.[CreatedDateUTC]
				,inserted.[CreatedBy]
				,inserted.[ModifiedDateUTC]
				,inserted.[ModifiedBy]
			INTO @Coordinators
		SELECT 
				@PK_NewEvent AS [PK_Event]
				,[CreatedDistributorID]
				,[CoordinatorID]
				,[CoordinatorName]
				,[CoordinatorPhone]
				,[CoordinatorEmail]
				,@StartTime AS [CreatedDateUTC]
				,@ModifiedBy As [CreatedBy]
				,@StartTime AS [ModifiedDateUTC]
				,@ModifiedBy As [ModifiedBy]
				,[CoordinatorTitle]
				,[CoordinatorTeamLevel]
				,[CoordinatorWebsite]
			FROM [dbo].[EventCoordinatorDetail] WITH(NOLOCK)
			WHERE [PK_Event] = @PK_Event
				AND @EventVersion = 2
				;

		IF @IsDevQA = 1 SELECT PK_Event FROM @Coordinators;

		------------------------------------------------------------------------------------------------------------------
		-- Copy Audience ([EventDistributorCountryLocales])
		-- 
		DECLARE	@EventDistributorCountryLocales TABLE (
				[PK_EventDistributorCountryLocales] int
				,[PK_Event] int
				,[PK_Locale] int
				,[IsDefault] bit
		);

		INSERT INTO [dbo].[EventDistributorCountryLocales] (
				[PK_Event]
				,[PK_Locale]
				,[IsDefault]
				,[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
		)
		OUTPUT	inserted.[PK_EventDistributorCountryLocales]
				,inserted.[PK_Event]
				,inserted.[PK_Locale]
				,inserted.[IsDefault]
			INTO @EventDistributorCountryLocales
		SELECT
				@PK_NewEvent AS [PK_Event]
				,[PK_Locale]
				,[IsDefault]
				,@StartTime AS [CreatedDateUTC]
				,@ModifiedBy As [CreatedBy]
				,@StartTime AS [ModifiedDateUTC]
				,@ModifiedBy As [ModifiedBy]
			FROM [dbo].[EventDistributorCountryLocales] WITH(NOLOCK)
			WHERE [PK_Event] = @PK_Event;

		IF @IsDevQA = 1 SELECT PK_Event FROM @EventDistributorCountryLocales;

		------------------------------------------------------------------------------------------------------------------
		-- Copy DSTeams
		-- 
		DECLARE @DSTeams TABLE(
			PK_EventDSTeamType int
			,DSTeamTypeCode varchar(20)
			,PK_Event int
		);

		INSERT INTO [dbo].[EventDSTeamType] (
			[DSTeamTypeCode]
			,[PK_Event]
			,[CreatedDateUTC]
			,[CreatedBy]
			,[ModifiedDateUTC]
			,[ModifiedBy]
		)
		OUTPUT inserted.[PK_EventDSTeamType], inserted.[DSTeamTypeCode], inserted.[PK_Event] INTO @DSTeams
		SELECT
				[DSTeamTypeCode]
				,@PK_NewEvent
				,@StartTime AS [CreatedDateUTC]
				,@ModifiedBy As [CreatedBy]
				,@StartTime AS [ModifiedDateUTC]
				,@ModifiedBy As [ModifiedBy]
			FROM [dbo].[EventDSTeamType] WITH(NOLOCK)
			WHERE [PK_Event] = @PK_Event;
		
		IF @IsDevQA = 1 SELECT PK_Event FROM @DSTeams;

	END TRY
	BEGIN CATCH
		SELECT 
				@Error = ERROR_NUMBER()
				,@ErrorMessage = ERROR_MESSAGE()
				,@StoredProcedure = ERROR_PROCEDURE();

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage;

		SELECT @Error, @ErrorMessage;

		RETURN;
	END CATCH;
	
	------------------------------------------------------------------------------------------------------------------
	-- Copy Tickets
	-- 
	DECLARE @Tickets xml;
	
	SELECT	@Tickets = (
				SELECT
						e.[SKUDesc] AS [Name]
						,el.[SKUDesc] AS [Desc]
						,e.[QuantityInStock] AS [Qty]
						,e.[Price]
						,u.[EventURL] AS [Link]
						,el.[PK_Currency] AS [Currency]
					FROM [dbo].[EventSKU] AS e WITH(NOLOCK)
						INNER JOIN [dbo].[EventSKULocaleDesc] AS el WITH(NOLOCK) ON e.[PK_EventSKU] = el.[PK_EventSKU]
						LEFT JOIN EventURL u WITH(NOLOCK) ON u.PK_EventURL = el.PK_EventURL
							AND u.PK_EventURLType = 5
					WHERE e.[PK_Event] = @PK_Event
					FOR XML RAW('Ticket'), ELEMENTS
			);
	
	EXEC [dbo].[usp_EventAPI_Save_DSTickets]
						@PK_Event = @PK_NewEvent
						,@Tickets = @Tickets
						,@IsDevQA = @IsDevQA
						,@LocaleCode = @LocaleCode
						,@Error = @Error OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @ErrorMessage OUTPUT /* @em must be defined in the local call */

	IF @IsDevQA = 1 SELECT @Tickets;
	IF @Error != 0 RAISERROR(@Error, @ErrorMessage, 15600, 1);

	------------------------------------------------------------------------------------------------------------------
	-- Copy Agenda
	-- 
	DECLARE @Agenda xml;

	SELECT	@Agenda = (
				SELECT
						a.AgendaLanguage AS [Locale]
						,i.LocalStartDate AS [StartDate]
						,i.LocalEndDate AS [EndDate]
						,i.DisplayDescription AS [Title]
						,i.DisplayLocation AS [Description]
					FROM AgendaItem AS i
						INNER JOIN Agenda AS a ON a.PK_Agenda = i.PK_Agenda
					WHERE a.PK_Event = @PK_Event
					FOR XML RAW('Agenda'), ELEMENTS
			);

	EXEC dbo.usp_EventAPI_Save_Agenda
			@PK_Event = @PK_NewEvent
			,@Agenda = @Agenda
			,@IsDevQA = @IsDevQA
			,@Error =@Error OUTPUT  /* @e must be defined in the local call */
			,@ErrorMessage = @ErrorMessage OUTPUT /* @em must be defined in the local call */

	IF @IsDevQA = 1 SELECT @Agenda;
	IF @Error != 0 RAISERROR(@Error, @ErrorMessage, 15600, 1);

	------------------------------------------------------------------------------------------------------------------
	-- Copy Event guest speakers
	-- 
	SELECT @GuestSpeakersXML = (
				SELECT 
						@PK_NewEvent AS [PK_Event]
						,(SELECT [LocaleCode] FROM [dbo].[Locales] WHERE [PK_Locale] = el.[PK_Locale]) AS [Locale]
						,NULL AS [PK_EventGuestSpeaker]
						,el.[EventSpeakerName] AS [SpeakerName]
						,el.[EventSpeakerTitle] AS [Title]
						,e.[EventSpeakerPhone] AS [Phone]
						,e.[EventSpeakerEmail] AS [Email]
						,e.[EventSpeakerTeamLevel] AS [TeamLevel]
						,el.[EventSpeakerBio] AS [Bio]
						,NULL AS [PK_EventImageLocaleDesc]
						,i.[EventImageLocation]
						,i.[PK_EventImageType]
						,NULL AS [PK_EventURL]
						,u.[EventURL]
						,u.[EventURLDesc]
						,u.[PK_EventURLType]
					FROM [EventGuestSpeakers] AS e
						INNER JOIN [EventGuestSpeakerLocale] AS el ON e.[PK_EventGuestSpeaker] = el.[PK_EventGuestSpeaker]
						LEFT JOIN [dbo].[EventImage] AS i ON i.[PK_EventImage] = e.[PK_EventImage]
						LEFT JOIN [dbo].[EventImageLocaleDesc] AS il ON il.[PK_EventImage] = e.[PK_EventImage]
						LEFT JOIN [dbo].[EventURL] AS u ON u.[PK_EventURL] = el.[PK_EventURL]
					WHERE e.[PK_Event] = @PK_Event
					FOR XML RAW('Speaker'), ELEMENTS
			);

	EXEC dbo.usp_EventAPI_Save_GuestSpeakers
			@PK_Event = @PK_NewEvent
			,@GuestSpeakers = @GuestSpeakersXML
			,@IsDevQA = @IsDevQA
			,@Error = @Error OUTPUT  /* @e must be defined in the local call */
			,@ErrorMessage = @ErrorMessage OUTPUT /* @em must be defined in the local call */
					
	--IF @Error != 0 RAISERROR(@Error, @ErrorMessage, 15600, 1);

	IF @IsDevQA = 1 
	BEGIN
		SELECT @GuestSpeakersXML, @Error, @ErrorMessage;
	END

	
		------------------------------------------------------------------------------------------------------------------
		-- Copy Event Media
		-- 
		SELECT	@EventMedia = (
					SELECT
							@PK_NewEvent AS [PK_Event]
							,e.[PK_MediaType]
							,(SELECT [LocaleCode] FROM [dbo].[Locales] WHERE [PK_Locale] = e.[PK_Locale]) AS [Locale]
							,[MediaName]
							,[MediaDesc]
							,[MediaHTML]
						FROM [dbo].[EventMedia] AS e WHERE PK_Event = @PK_Event
						FOR XML RAW('Media'), ELEMENTS
				);

		EXEC dbo.usp_EventAPI_Save_EventMedia
						@PK_Event = @PK_NewEvent
						,@EventMedia = @EventMedia
						,@IsDevQA = @IsDevQA
						,@Error =@Error OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @ErrorMessage OUTPUT /* @em must be defined in the local call */
						;

		IF @IsDevQA = 1 SELECT PK_Event FROM [dbo].[EventMedia] WHERE [PK_Event] = @PK_NewEvent;
		IF @Error != 0 RAISERROR(@Error, @ErrorMessage, 15600, 1);

	-- Return new event
	SELECT @PK_NewEvent AS [NewEvent];
--Deployed: 20180423
END;
GO

