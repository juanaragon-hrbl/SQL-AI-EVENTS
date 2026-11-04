CREATE PROCEDURE [dbo].[usp_MyHL_AT_EventAPI_Get_DSEvent]
        -- Mandatory Parameters
		@PK_Event INT
		,@LocaleCode CHAR(5)
		,@DistributorID VARCHAR(10)	-- Not used
		,@IsSummary bit = 0

		-- Defaults
		,@OnlineEventLink INT = 9
		,@PK_EventMediaType int = 2
		,@PK_TicketEventURLType int = 5
		,@AudiencesTable bit = 0
		
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
OBJECT:			dbo.[usp_MyHL_AT_EventAPI_Get_DSEvent]

USE:
			DECLARE @e int, @em varchar(4000)
            
			EXEC dbo.[usp_MyHL_AT_EventAPI_Get_DSEvent]
					 	@PK_Event = 78102
						,@LocaleCode = 'en-US'
						,@DistributorID = 'staff'
						,@IsDevQA = 1
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsSummary = 0

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves all the records for associated DS Event based on the PK_Event passed

NOTES: 

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.EventLocaleADesc, dbo.EventCoordinatorDetail, dbo.EventURL

ERSIONS (PROD)
----------------------------------------------------------------------------------
1.0.0	2017-08-11		RogelioR	Get Distributor Event
1.1.0	2018-03-09		RogelioR	Add [CoordinatorPhone] to dataset
1.2.0	2018-05-08		RogelioR	Add [EventSubTypeDesc] to first dataset
1.3.0	2018-09-19		RogelioR	Added [DisplayDates] functionality
1.4.0	2019-08-14		NoeG		Refactor code (SRE)
1.5.0	2019-10-16      puertac		SRE Implementation 
1.6.0	2020-05-28		NoeG		Add features IsMajorEvent, IsVirtualEvent and IsInPersonEvent to Events, also the Link and data for Virtual Event Type 

*******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@PK_Locale INT
			,@PK_DefaultLocale INT
			,@PK_EventType INT
			,@HasAccess INT
			,@IsRecurringChild BIT = 0
			,@IsMYHL BIT = 0
			,@Audiences VARCHAR(MAX);
	
	SELECT @Error = 0, @ErrorMessage = '';
	BEGIN TRY
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH	(NOLOCK) WHERE LocaleCode = @LocaleCode;

		SELECT 
				@PK_DefaultLocale = [PK_DefaultLocale]
				,@PK_EventType = [PK_EventType]
				,@IsRecurringChild = CASE WHEN IsRecurring = 0 AND PK_OldEventApp IS NOT NULL THEN 1 ELSE 0 END
			FROM [dbo].[Event] WITH	(NOLOCK)
			WHERE [PK_Event] = @PK_Event;

		/*Hide Deleted Events*/
		IF EXISTS (SELECT 1 FROM dbo.EventDeleteQueue WITH (NOLOCK) WHERE PK_Event = @PK_Event)
		BEGIN
			RETURN
		END;

		SELECT @IsMYHL = CASE WHEN COALESCE(@DistributorID, '') <> '' THEN 1 ELSE 0 END;

		IF @IsDevQA = 1 SELECT @PK_Event;
	
		--IF (@DistributorID <> '' ) AND  NOT EXISTS (SELECT  1 FROM dbo.Event E WITH (NOLOCK) WHERE E.CreatedDistributorID = @DistributorID)
		--BEGIN
		--	SET @Error = 411;
		
		--	-- Update ErrorLog
		--	EXEC dbo.usp_Utility_UpdateErrorLog 
		--		@ProcedureName = @StoredProcedure 
		--		,@ErrorNumber = @Error
		--		,@ErrorMessage = @ErrorMessage OUTPUT;

		--	RETURN;
		--END

		IF @PK_EventType !=3
		BEGIN
			SELECT	@Error = 1
					,@ErrorMessage = 'This is not a Distributor Event'
		END
		ELSE
		BEGIN
			/* SELECT EVENT DETAILS FOR THE PASSED PK_EVENT */
				
				SELECT @PK_Locale = CASE WHEN EXISTS (SELECT [PK_Locale] FROM [dbo].[EventLocaleDesc] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event AND [PK_Locale] = @PK_Locale) THEN @PK_Locale ELSE  @PK_DefaultLocale END;
		
				IF @IsDevQA = 1 SELECT @PK_Event AS PK_Event, @PK_Locale AS PK_Locale;
			
				SELECT @Audiences = COALESCE(@Audiences + ',', '') + l.[LocaleCode]
					FROM [dbo].[EventDistributorCountryLocales] AS e WITH (NOLOCK)
						INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = e.[PK_Locale]
					WHERE PK_Event = @PK_Event

				SELECT DISTINCT	
						e.[PK_Event]
						,ed.[EventName]
						,e.[dStartUTC] AS [EventStartDate]
						,e.[dEndUTC] AS [EventEndDate]
						,ed.[EventAddress]
						,ed.[EventCity]
						,ed.[EventState]
						,ec.[PK_Country]
						,c.[sCountryCodeISO] As [EventCountry]
						,e.[EventZipCode]
						,e.[EventApprovalStatus] -- 0 = Under review; 1 = Approved; 2 = Rejected; 3 = Save As Draft
						,e.[IsActive]
						,e.[IsPublish]
						,e.[DisplayStartDate] AS [DisplayStartDate]
						,e.[DisplayEndDate] AS [DisplayEndDate]
						,ISNULL(ed.[EventDisplayAddress],'') AS [EventDisplayAddress]
						,ISNULL(ed.[EventTrainingLanguages], '') AS [EventTrainingLanguages]
						,ISNULL(ed.[EventCostDetails], '') AS [EventCostDetails]
						,COALESCE(eu.[Flyer], '') AS [Flyer]
						,ei.[PK_EventImage]
						,ISNULL(NULLIF(RTRIM(LTRIM((SELECT TOP 1 [EventImageLocation] FROM [EventImage] WITH (NOLOCK) WHERE [PK_EventImageType] = 1 AND [PK_Event] = E.[PK_Event]))), ''), ESLD.[Image])
						AS [Logo]
						,ISNULL(ed.[EventDesc],'') AS [EventDesc]
						,ISNULL(ed.[EventApprovalNotes], '') AS [ApprovalNotes]
						,ISNULL(ed.[EventComments], '') AS [Comments]
						,l.[LocaleCode]
						,l.[LanguageCountryRegion]
						,e.[CreatedDistributorID] AS [DistributorID]
						,e.[EventVenueName]
						,e.[IsSocialNetworkEnabled]
						,e.[IsAlwaysVisible]
						,e.[IsPreRegistrationRequired]
						,ed.[EventSummary]
						,@HasAccess AS [HasAccess]
						,CASE WHEN e.[PK_EventType] = 3 AND e.[IsActive] = 0 THEN 5 
							  WHEN e.[PK_EventType] != 3 AND (e.[IsActive] = 0 OR e.[DisplayEndDate] < CONVERT(DATE,GETUTCDATE(), 110) OR COALESCE(e.[RecurrenceEndDate], e.[dEndUTC]) < CONVERT(DATE,GETUTCDATE(), 110)) THEN 5
							  ELSE e.[EventApprovalStatus] END
						 AS [EventStatus]
						,SUBSTRING(CONVERT(NVARCHAR(30), e.[dStartUTC], 108), 1, 5) AS [EventStartTime]
						,SUBSTRING(CONVERT(NVARCHAR(30), e.[dEndUTC], 108), 1, 5) AS [EventEndTime]
						,e.[MakePublic]
						,r.[RecurrenceCode] AS [Repeat]
						,e.[RecurrenceEndDate] AS [RecurringEventEnddate]
						,e.[IsRecurring]
						,e.[PK_OldEventApp]
						,e.[Latitude]
						,e.[Longitude]
						,ed.[Keywords]
						,eest.[PK_EventSubType]
						,eu.[PK_EventURL] AS [PK_EventOnlineURL]
						,eu.[EventURL] AS [EventOnlineURL]
						,eu.[EventURLDesc] AS [EventOnlineURLName]
						,re.IsChild
						,re.IsParent
						,(SELECT EventImageLocation FROM EventImage WITH (NOLOCK) WHERE PK_Event = e.PK_Event AND PK_EventImageType = 2) AS [Banner]
						,e.[Location] AS [TimeZone]
						,@Audiences AS [Audiences]
						,ex.[RSVPRegistrations]
						,ex.[RSVPGuests]
						,c.[sCountryName] As [Country]
						,ISNULL(e.[Version], 1) AS [Version]
						,esld.[LocaleDescription] AS [EventSubTypeDesc]
						,ISNULL(ex.[DisplayDates], 1) AS [DisplayDates]
						,ISNULL(ex.IsInPersonEvent,0) as [IsInPersonEvent]
						,ISNULL(ex.IsVirtualEvent,0) as [IsVirtualEvent]
						,ISNULL(ex.IsMajorEvent,0) as [IsMajorEvent]

					FROM [dbo].[Event] AS e WITH (NOLOCK)
						INNER JOIN [dbo].[EventLocaleDesc] AS ed WITH (NOLOCK) ON e.[PK_Event] = ed.[PK_Event]
							AND ed.[PK_Locale] = @PK_Locale
						INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON	ed.[PK_Locale] = l.[PK_Locale]
						LEFT JOIN [dbo].[EventCountry] AS ec WITH (NOLOCK) ON e.[PK_Event] = ec.[PK_Event]
						LEFT JOIN [dbo].[v_Countries] AS c ON	ec.[PK_Country] = c.[nCountryID]
						LEFT JOIN [dbo].[EventURL] AS eu WITH (NOLOCK) ON e.[PK_Event] = eu.[PK_Event]
							AND eu.[PK_Locale] = @PK_Locale
							AND eu.[PK_EventURLType] = @OnlineEventLink
						LEFT JOIN [dbo].[EventImage] AS ei WITH (NOLOCK) ON ei.[PK_Event] = e.[PK_Event]
							AND ei.[PK_EventImageType] = 1
						LEFT JOIN [dbo].[EventExtn] AS ex WITH (NOLOCK) ON ex.[PK_Event] = e.[PK_Event]
						LEFT JOIN [dbo].[RecurrenceType] AS r WITH (NOLOCK) ON e.[PK_RecurrenceType] = r.[PK_RecurrenceType]
						LEFT JOIN (SELECT TOP 1 ee.[PK_Event], ee.[PK_EventSubType]
									FROM [dbo].[EventEventSubType] AS ee WITH (NOLOCK)
									WHERE ee.[PK_Event] = @PK_Event) AS eest ON eest.[PK_Event] = e.[PK_Event]
						LEFT JOIN [EventSubTypes] AS es WITH (NOLOCK) ON es.[PK_EventSubType] = eest.[PK_EventSubType]
						LEFT JOIN [dbo].[EventSubTypeLocaleDesc] esld WITH (NOLOCK) ON eest.[PK_EventSubType] = esld.[PK_EventSubType]	
							AND esld.[PK_Locale] = e.[PK_DefaultLocale]
						LEFT JOIN udf_Get_RecurringEvents(@PK_Event) AS re ON re.PK_Event = @PK_Event
					WHERE e.[PK_Event] = @PK_Event
		END;

			IF @IsSummary = 0
			BEGIN
				------------------------------------------------------------------------------------------------------------------
				-- Get Event URLs
				--
				SELECT 
						eu.[PK_EventURL]
						,eu.[PK_Event]
						,eu.[PK_Locale]
						,l.[LocaleCode]
						,eu.[EventURL]
						,eu.[EventURLDesc]
						,eu.[Flyer]
						,eu.[PK_EventURLType]
						,eut.[EventURLType]
					FROM [dbo].[EventURL] AS eu WITH (NOLOCK)
						INNER JOIN [dbo].[EventURLType] AS eut  WITH (NOLOCK) ON eut.PK_EventURLType = eu.PK_EventURLType
						INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.PK_Locale = eu.PK_Locale
					WHERE eu.[PK_Event] = @PK_Event
						AND eu.[PK_Locale] = @PK_Locale
						AND eu.[PK_EventURLType] != @OnlineEventLink;


				------------------------------------------------------------------------------------------------------------------
				-- Get recurring events
				--
				SELECT [PK_Event], [PK_EventType], [StartDate], [EndDate], [EventApprovalStatus], [PK_RecurrenceType], [IsActive], [IsChild], [IsParent] 
					FROM udf_Get_RecurringEvents(@PK_Event);


				------------------------------------------------------------------------------------------------------------------
				-- Get event media
				--
				SELECT
						[PK_EventMedia]
						,[PK_Locale]
						,[MediaName]
						,[MediaDesc]
						,[MediaHTML]
					FROM [dbo].[EventMedia] WITH (NOLOCK)
					WHERE [PK_Event] = @PK_Event
						AND [PK_MediaType] = @PK_EventMediaType;


				------------------------------------------------------------------------------------------------------------------
				-- Get Coordinators
				--
				SELECT 
						[PK_EventCoordinatorDetail]
						,[PK_Event]
						,[CreatedDistributorID]
						,[CoordinatorName]
						,[CoordinatorTeamLevel] AS [TeamLevel]
						,[CoordinatorEmail]
						,[CoordinatorPhone]
						,[CoordinatorWebsite]
						,CASE WHEN [CoordinatorTitle] = '1' THEN 1 ELSE 0 END AS [EventOwner]
					FROM [dbo].[EventCoordinatorDetail] WITH (NOLOCK)
					WHERE [PK_Event] = @PK_Event;


				------------------------------------------------------------------------------------------------------------------
				-- Get Speakers
				-- 
				SELECT DISTINCT
						eg.[PK_EventGuestSpeaker]
						,eg.[EventSpeakerName]
						,egl.[EventSpeakerTitle]
						,egl.[EventSpeakerBio]
						,tl.[DSTeamTypeCode]
						,egl.[EventSpeakerTeamLevel]
						,u.[EventURL] AS [SocialMediaLink]
						,il.[PK_EventImageLocaleDesc]
						,i.[EventImageLocation] AS [Photo]
					FROM [dbo].[EventGuestSpeakers] AS eg WITH (NOLOCK)
						LEFT JOIN [dbo].[EventGuestSpeakerLocale] egl WITH (NOLOCK) ON eg.[PK_EventGuestSpeaker] = egl.[PK_EventGuestSpeaker]
						LEFT JOIN [dbo].[EventURL] AS u WITH (NOLOCK) ON u.[PK_EventURL] = egl.[PK_EventURL]
						LEFT JOIN [dbo].[EventImage] AS i WITH (NOLOCK) ON i.[PK_EventImage] = eg.[PK_EventImage]
						LEFT JOIN [dbo].[EventImageLocaleDesc] AS il WITH (NOLOCK) ON il.[PK_EventImage] = i.[PK_EventImage]
						LEFT JOIN [dbo].[DSTeamTypeLocaleDesc] AS tl WITH (NOLOCK) ON tl.[DSTeamTypeDesc] = egl.[EventSpeakerTeamLevel]
					WHERE eg.[PK_Event] =@PK_Event;
	
				------------------------------------------------------------------------------------------------------------------
				-- Get Agenda
				--
				SELECT
						ai.[PK_AgendaItem]
						,ai.[DisplayDescription] AS [Title]
						,ai.[DisplayLocation] AS [Description]
						,ai.[LocalStartDate]
						,ai.[LocalEndDate]
						,ai.[IsSubEvent]
						,ai.[PK_SubEvent]
					FROM Agenda AS a WITH (NOLOCK)
						INNER JOIN AgendaItem AS ai WITH (NOLOCK) ON ai.[PK_Agenda] = a.[PK_Agenda]
					WHERE a.[PK_Event] = @PK_Event;
				------------------------------------------------------------------------------------------------------------------
				-- Get Audience
				--
				IF @AudiencesTable = 1
					SELECT
							e.PK_Locale
							,l.LocaleCode
						FROM [dbo].[EventDistributorCountryLocales] AS e WITH (NOLOCK)
							INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[PK_Locale] = e.[PK_Locale]
						WHERE PK_Event = @PK_Event;

				------------------------------------------------------------------------------------------------------------------
				-- Get Tickets
				-- 
				SELECT	es.[PK_EventSKU]
							,es.[PK_Event]
							,es.[SKUDesc] AS [TicketName]
							,es.[Price]
							,es.[QuantityInStock]
							,es.[PK_EventSKUType]
							,esl.[SKUDesc] AS [TicketDescription]
							,esl.[PK_Currency]
							,c.[AlphaCode] AS [Currency]
							,eu.[PK_EventURL]
							,eu.[EventURL]
						FROM [EventSKU] AS es WITH (NOLOCK)
							INNER JOIN [EventSKULocaleDesc] AS esl WITH (NOLOCK) ON esl.[PK_EventSKU] = es.[PK_EventSKU]
							LEFT JOIN [EventURL] AS eu WITH (NOLOCK) ON eu.[PK_EventURL] = esl.[PK_EventURL]
								AND eu.PK_EventURLType = @PK_TicketEventURLType
							LEFT JOIN [Currency] AS c WITH (NOLOCK) ON c.[PK_Currency] = esl.[PK_Currency]
						WHERE es.[PK_Event] = @PK_Event;

				------------------------------------------------------------------------------------------------------------------
				-- Get Team Levels
				--
				SELECT
						[DSTeamTypeCode]
					FROM EventDSTeamType WITH (NOLOCK) 
					WHERE [PK_Event] = @PK_Event;
		
			END;	-- @IsSummary IF


			------------------------------------------------------------------------------------------------------------------
			-- Get SubEvents
			--
			SELECT     
					se.[SubEventNumber]
					,se.[PK_Subevent] 
					,se.[SubEventName]    
					,COALESCE(sed.[SubEventQualDesc], sel.[SubEventQualDesc], se.[Location]) AS [SubEventQualDesc]
					,sel.[QualDesc] AS [QualificationDesc]    
					,se.[PK_SubEventGroup]    
					,seg.[SubEventGroup] AS [SubEventGroup]    
					,COALESCE(
								CASE WHEN sel.[SubEventGroupNameLocale] = '' THEN NULL 
									ELSE sel.[SubEventGroupNameLocale] END
								,CASE WHEN sed.[SubEventGroupNameLocale] = '' THEN NULL 
									ELSE sed.[SubEventGroupNameLocale] END
					) AS [SubEventGroupNameLocale]
					,see.[Icon]
					,see.[Color]
					,COALESCE(CASE WHEN sel.[Image] = '' THEN NULL ELSE sel.[Image] END, CASE WHEN sed.[Image] = '' THEN NULL ELSE sed.[Image] END) AS [Image]    
					,CASE WHEN (ISNULL(see.[Icon], ' ') = ' ') THEN 1 ELSE 0 END AS [PK_IdentityType]    
					,se.[IsTrackingVisible]
					,seg.[SubEventGroupName]
					,se.[IncludeInBizworkReport]
					,estld.[LocaleDescription]
				FROM [dbo].[SubEvent] AS se WITH (NOLOCK)
					LEFT JOIN [dbo].[SubEventLocaleDesc] AS sel (NOLOCK) ON se.[PK_Event] = sel.[PK_Event]
						AND sel.[PK_SubEvent] = se.[PK_SubEvent]
						AND sel.[PK_Locale] = @PK_Locale    
					LEFT JOIN [dbo].[SubEventLocaleDesc] AS sed (NOLOCK) ON se.PK_Event = sed.PK_Event    
						AND sed.PK_SubEvent = se.PK_SubEvent    
						AND sed.PK_Locale = @PK_DefaultLocale
					LEFT JOIN [dbo].[SubEventGroup] (NOLOCK) AS seg ON se.[PK_SubEventGroup] = seg.[PK_SubEventGroup]    
					LEFT JOIN [dbo].[SubEventExtn] (NOLOCK) AS see ON se.[PK_Event] = see.[PK_Event]
						AND se.[PK_SubEvent] = see.[PK_SubEvent]
					LEFT JOIN [dbo].[EventEventSubType] AS eest WITH (NOLOCK) ON eest.[PK_Event] = @PK_Event
						AND eest.[PK_EventType] = (SELECT [PK_EventType] FROM [Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)
					LEFT JOIN [dbo].[EventSubTypes] AS est WITH (NOLOCK) ON est.[PK_EventSubType] = eest.[PK_EventSubType]
					LEFT JOIN [dbo].[EventSubTypeLocaleDesc] AS estld WITH (NOLOCK) ON estld.[PK_EventSubType] = eest.[PK_EventSubType]
						AND estld.[PK_Locale] = @PK_DefaultLocale
				WHERE se.[PK_Event] = @PK_Event
				ORDER BY SEG.[DisplayOrder]
		
			IF @IsSummary = 1 
			BEGIN
				------------------------------------------------------------------------------------------------------------------
				-- Is the Distributor a coordinator?
				SELECT CASE WHEN 
					EXISTS(SELECT PK_EventCoordinatorDetail FROM EventCoordinatorDetail WITH (NOLOCK) WHERE PK_Event = @PK_Event AND CreatedDistributorID = @DistributorID) 
						THEN 1 
						ELSE 0 
					END AS IsCoordinator
			END;


			-- UPDATE PROCESSING LOG
			EXEC dbo.usp_Utility_UpdateProcessingLog 
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime
	
			/******************************************************************************
				END PROCEDURE
			******************************************************************************/
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