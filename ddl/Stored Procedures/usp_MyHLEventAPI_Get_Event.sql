CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_Event]
	-- Mandatory Parameters
	@UserID VARCHAR(30) -- Security
	,@PK_Event INT

	-- Optional Parameters
	,@LocaleCode CHAR(5)	-- Making it optional as we pass back the event details pertaining to the default locale if the actual requested localeCode is not passed
	,@FilterBreakoutSessions bit = 0	-- 1 will filter all breakout sessions (Sub events with PK_SubEventType = 5)

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:   dbo.usp_MyHLEventAPI_Get_Event

USE:
		DECLARE @e int, @em varchar(4000)

		EXEC dbo.usp_MyHLEventAPI_Get_Event
			@UserID = 'ivanci'
			,@PK_Event = 23560
			,@LocaleCode = 'es-MX'
			,@FilterBreakoutSessions = 0
			,@Error = @e OUTPUT  /* @e must be defined in the local call */
			,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
			,@IsDevQA = 0

		SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION: Retrieves all the records for event passed

NOTES:

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.EventLocaleADesc, dbo.EventURL, dbo.EventDSTeamTypes, dbo.EventImage,
dbo.Subevent, dbo.SubeventLocaleDesc, dbo.EventGuestSpeakers, dbo.EventImageLocaleDesc

VERSIONS
----------------------------------------------------------------------------------
1	2010-11-24	Prabhu		Intitial
2	2013-01-16	Sushma		Changes made for Title columns of EventGuestSpeakers
							Changes made for retrieval of EVentAudio File location
3	2013-04-20	Juan		Not display for deleted events
4	2013-07-03	Sushma		Target Market CR Changes
5	2015-02-22	Sushma		Add Tickets CR Changes
6	2015-05-08	Sushma		Admin Tool CR Changes
7	2017-03-31	Prashanth	Publish hide Bizwork report
8	2017-04-28	RogelioR	Add a flag to display a PDF instead of a page on EventExtn
9	2017-06-01	Prashanth	Select sub events to display in Bizworks Report
10	2017-07-05	RogelioR	Add IsDisplayDV to result set
11  2017-08-09	Sandhyap	Add IsUmbracoHosted to 1st result set
12  2017-10-09	SandhyaP	Add HasDownlineTable field
13	2018-06-18	Rogelior	Add @FilterBreakoutSessions to include/exclude breakout sessions on the Sub Event record set
13	2018-08-07	RogelioR	Add [HideToPM] from [SubEventExtn]
14	2018-08-13	RogelioR	Added [IsDisplayPMPPV] column to [EventExtn]
15	2019-01-14	NoeG		TimeZoneDesc Field Added to the SP Results
16	2019-02-13	NoeG		Fix on Getting Guest Speakers. Filter added to get Speakers for Non SubEventType = 5 SubEvents
17	2019-08-14	NoeG		Refactor code (SRE)
18	2020-04-	GustavoGra	Adding timezone columns and Add to calendar flag.
19	2020-05-04	NoeG		Add Flag to hide events on Events Landing Page
20	2020-05-28	NoeG		Add features IsMajorEvent, IsVirtualEvent and IsInPersonEvent to Events, also the Link and data for Virtual Event Type
21	2020-06-11  SergioAlv   sCountryCodeISO change
22	2020-09-01	puertac		T 341289 : Adding AudioLanguagesList (dbo.EventExtn) & AudioLanguagesDesc (dbo.EventLocaleDesc)
23	2021-01-26	puertac		T 546643 : Adding DisplayVirtualQualifiedOnly flag from dbo.EventExtn
24	2022-02-22	ivanci		Adding HideDates flag from dbo.EventExtn
25	2022-03-28	puertac		US 1003446 : Adding HasAutomatedQuals, IsProcessingQuals & IsAutoProcessEnabled
26  2023-05-20	ivanci	    US 1260167 - Admin tool - Display DS team levels - Capability to publish/unpublish DS levels on Events
27  2023-07-13	ivanci	    US 1275783 - Events Admin - Testing Tracker Feature - Display Downline Table
28  2024-09-25	ivanci	    US 1365212 - Events Admin - Tickets Display at Track your progress (My Events Qualifications) Page
29  2026-01-22	gustavogra  Add HideQualifiedBadge property to EventExtn table and stored procedures
******************************************************************************/

/* DECLARE THE REQUIRED VARIABLES */
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
DECLARE @PK_Locale INT
DECLARE @PK_DefaultLocale INT
DECLARE @HasQualifications INT
DECLARE @HasAccess INT
DECLARE @DisplayPDFType int = 12
DECLARE @OnlineEventLink int = 9

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

		SELECT @Error = 0, @ErrorMessage = '';
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event  WITH (NOLOCK) WHERE PK_Event = @PK_Event
		SELECT @HasQualifications = CASE WHEN COUNT(PK_SubEvent) > 0 THEN 1 ELSE 0 END FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_Event

		/*Hide Deleted Events*/
		IF EXISTS (SELECT 1 FROM dbo.EventDeleteQueue WITH (NOLOCK) WHERE PK_Event = @PK_Event)
		BEGIN
		 RETURN
		END

		/*Custom Tracking Code */
		DECLARE @CustomCode NVARCHAR(MAX) = ISNULL((select CustomTrackingCode from EventLocaleDesc WITH (NOLOCK) where PK_Event = @PK_Event AND PK_Locale = @PK_locale),
		(select CustomTrackingCode from EventLocaleDesc WITH (NOLOCK) where PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale))

		/******************************************************************************
		Check Staff has the permissions to the passed locale
		******************************************************************************/

		SELECT @HasAccess =
		 CASE WHEN COUNT(DISTINCT E.PK_Event) > 0 THEN 1 ELSE 0 END
		FROM
		(
		 SELECT DISTINCT E.PK_Event
		 FROM
		  dbo.EventATAccessUser EU WITH (NOLOCK)
		 INNER JOIN
		  dbo.EventATAccessUserModules EUM WITH (NOLOCK)
		  ON
		   EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
		 INNER JOIN
		  dbo.Locales L WITH (NOLOCK)
		  ON
		   L.PK_Locale = EUM.PK_Locale
		 INNER JOIN
		  dbo.v_Countries C
		  ON
		   SUBSTRING(L.LocaleCode, CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = C.sCountryCodeISO
		 INNER JOIN
		  dbo.EventDistributorCountry EC WITH (NOLOCK)
		  ON
		   C.nCountryID = EC.PK_Country
		 INNER JOIN
		  dbo.Event E WITH (NOLOCK)
		  ON
		   EC.PK_Event = E.PK_Event
		   AND
		   E.PK_Event = @PK_Event
		 WHERE
		  EU.EventATAccessUserName = @UserID
		  AND
		  E.PK_EventType !=3
		 UNION
		 SELECT DISTINCT E.PK_Event
		 FROM dbo.EventATAccessUser EU WITH (NOLOCK)
		INNER JOIN
		  dbo.EventATAccessUserModules EUM WITH (NOLOCK)
		  ON
		   EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
		 INNER JOIN
		  dbo.Locales L WITH (NOLOCK)
		  ON
		   L.PK_Locale = EUM.PK_Locale
		 INNER JOIN
		  dbo.EventLocaleDesc ELD WITH (NOLOCK)
		  ON
		   L.PK_Locale = ELD.PK_Locale
		 INNER JOIN
		  dbo.Event E WITH (NOLOCK)
		  ON
		   ELD.PK_Event = E.PK_Event
		   AND
		   E.PK_Event = @PK_Event
		 WHERE
		  EU.EventATAccessUserName = @UserID
		  AND
		  E.PK_EventType = 3
		)E

		/* SELECT EVENT DETAILS FOR THE PASSED PK_EVENT */
		IF EXISTS (SELECT PK_Locale FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Locale = @PK_Locale AND PK_Event = @PK_Event)
		BEGIN
		SELECT
		  E.PK_EventType
		 ,ED.EventName
		 ,ED.EventVenueName
		 ,ED.EventLocation
		 ,ED.EventAddress
		 ,ED.EventCity
		 ,ED.EventState
		 ,E.EventZipCode
		 ,E.dStartUTC EventStartDate
		 ,E.dEndUTC EventEndDate
         ,E.EventTimeZone AS [TimezoneOffset]
         ,EE.TimeZoneDesc AS [TimezoneDesc]
         ,EE.EnabledAddToCalendar
		 ,E.DisplayStartDate
		 ,E.DisplayEndDate
		 ,E.MakePublic
		 ,E.IsActive
		 ,E.IsPublish
		 ,COALESCE(ED.EventSummary, '') EventSummary
		 ,COALESCE(ED.EventDesc, '') EventDesc
		 ,COALESCE(ED.EventRules,'') EventRules
		 ,COALESCE(ED.KeyWords,'') Keywords
		 ,E.CanPurchaseTicketOnline
		 ,E.CanAssignTickets
		 ,E.CanShowCurrentQualOnline
		 ,E.IsPreRegistrationRequired
		 ,E.CanRegisterOnline
		 ,E.QualPeriodStart
		 ,E.QualPeriodEnd
		 ,E.CanDisplayQualPeriod
		 ,E.IsQualifytoPurchaseTickets
		 ,E.IsPublishQualTracking
		 ,COALESCE(ED.Keywords, '') Keywords
		 ,COALESCE(ED.EventDisplayAddress, '') EventDisplayAddress
		 ,EC.PK_Country
		 ,CASE WHEN ISNULL(C.sCountryCodeISO,'') = '' THEN C.sCountryCode
			ELSE C.sCountryCodeISO
		 END AS EventCountry
		 ,ISNULL(EI.PK_EventImageType,0) PK_EventImageType
		 ,ISNULL(EI.PK_EventImage,'') PK_EventImage
		 ,ISNULL(EI.EventImageLocation,'')EventImageLocation
		 ,L.LocaleCode
		 ,L.LanguageCountryRegion
		 ,L1.LocaleCode DefaultLocale
		 ,L1.LanguageCountryRegion DefaultLanguageCountryRegion
		 ,E.IsSocialNetworkEnabled
		 ,@HasQualifications HasQualifications
		 ,@HasAccess HasAccess
		 ,CASE WHEN E.IsPublish = 1 AND E.DisplayEndDate >= CONVERT(DATE,GETUTCDATE(), 110) THEN 4
				  WHEN (E.IsPublish = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
			 END AS [EventStatus]
			,SUBSTRING(CONVERT(NVARCHAR(30),E.dStartUTC, 108), 1, 5) AS EventStartTime
		 ,SUBSTRING(CONVERT(NVARCHAR(30),E.dEndUTC, 108), 1, 5) AS EventEndTime
		 ,E.CanDisplayTicketDetails
		 ,E.IsTicketforQualifiedDS [TicketPurchaseforQualifiedDSOnly]
		 ,E.TicketThirdPartyLink [IsThirdPartyTicketPurchaseLink]
		 ,CASE WHEN E.CustomTrackingSiteSPName IS NOT NULL THEN 1 ELSE 0 END [IsCustomTrackerEvent]
		 ,@PK_Locale [PK_Locale]
		 ,EUL.EventURL ThirdPartyLink
		 ,ED.ParticipatingCountries
		 ,ISNULL(EE.IsDisplayTVP, 0) IsDisplayTVP
		 ,ISNULL(EE.IsDisplayRO, 0) IsDisplayRO
		 ,ISNULL(EE.IsDisplayPPV, 0) IsDisplayPPV
		 ,ISNULL(EE.IsDisplayPB, 0) IsDisplayPB
		 ,ISNULL(EE.IsDisplayDLV, 0) IsDisplayDLV
		 ,ISNULL(EE.IsDisplayPPVDLV, 0) IsDisplayPPVDLV
		 ,ISNULL(EE.IsDisplayPMPPV, 0) IsDisplayPMPPV
		 ,E.Latitude
		 ,E.Longitude
		 ,COALESCE(ED.TicketRules, EDD.TicketRules) TicketRules
		 ,ISNULL(EE.IsDisplayAWT, 0) IsDisplayAWT
		 ,ISNULL(EE.IsDisplayAWTQualPeriod, 0) IsDisplayAWTQualPeriod
		 ,ISNULL(EE.IsDisplayAWTFirstTime, 0) IsDisplayAWTFirstTime
		 ,EE.AWTStartDate
		 ,EE.AWTEndDate
		 ,E.IsBizworkReportEnabled
		 ,ISNULL(EE.IsDisplayPDF, 0) AS IsDisplayPDF
		 ,EE.IsDisplayDV
		 ,EE.IsUmbracoHosted
		 ,@CustomCode AS [CustomTrackingCode]
		 ,E.[PK_Event]
		 ,ISNULL(EE.IsLanguageGrouped,0) as [IsLanguageGrouped]
		 ,ISNULL(EE.PK_DefaultMasterLocale,0) as [PK_DefaultMasterLocale]
		 ,ISNULL(LE.MasterLocaleLanguage,'') as [MasterLocaleLanguage]
		 ,ISNULL(LE.MasterLocaleCode,'') as [MasterLocaleCode]
		 ,ISNULL(EE.HideLandingPage,0) as [HideLandingPage]
		 ,ISNULL(EE.IsInPersonEvent,0) as [IsInPersonEvent]
		 ,ISNULL(EE.IsVirtualEvent,0) as [IsVirtualEvent]
		 ,ISNULL(EE.IsMajorEvent,0) as [IsMajorEvent]
		 ,EE.AudioLanguagesList												-- T 341289 : Adding AudioLanguages
		 ,ED.AudioLanguagesDesc												-- T 341289 : Adding AudioLanguages
 		 ,ISNULL(EE.DisplayVirtualQualifiedOnly,0) AS DisplayVirtualQualifiedOnly  --T 546643 : Adding DisplayVirtualQualifiedOnly flag
         ,ISNULL(EE.DisplayDates, 1) as DisplayDates
 		 ,IIF(S.PK_Event IS NOT NULL , 1, 0) AS HasAutomatedQuals						-- US 1003446
		 ,IIF(S.IsProcessingQuals = 1, 1,0) AS IsProcessingQuals						-- US 1003446
		 ,IIF(S.IsAutoProcessEnabled = 1, 1, 0) AS IsAutoProcessEnabled					-- US 1003446
         ,ISNULL(EE.HideTeamLevelInfo, 0)  as HideTeamLevelsInfo
		 ,ISNULL(EE.EnableTesting, 0)  as EnableTesting
         ,ISNULL(EE.IsDisplayDownline, 0)  as IsDisplayDownline
         ,ISNULL(EE.IsDisplayTicketsTypPage, 0)  as IsDisplayTicketsTypPage
		 ,ISNULL(EE.IsDisplayGtaLink, 0)  as IsDisplayGtaLink
		 ,ISNULL(EE.HideQualifiedBadge, 0)  as HideQualifiedBadge
		FROM
		 dbo.Event E WITH (NOLOCK)
		INNER JOIN
		 dbo.EventLocaleDesc ED WITH (NOLOCK)
		ON
		 E.PK_Event = ED.PK_Event
		 AND ED.PK_Locale = @PK_Locale
		INNER JOIN
		 dbo.Locales L  WITH (NOLOCK)
		ON
		 ED.PK_Locale = L.PK_Locale
		INNER JOIN
		 dbo.Locales L1  WITH (NOLOCK)
		ON
		 E.PK_DefaultLocale = L1.PK_Locale
		INNER JOIN
		 dbo.EventCountry EC  WITH (NOLOCK)
		ON
		 E.PK_Event = EC.PK_Event
		INNER JOIN
		 dbo.v_Countries C
		ON
		 EC.PK_Country = C.nCountryID
		LEFT JOIN
		 dbo.EventExtn EE  WITH (NOLOCK)
		ON
		 E.PK_Event = EE.PK_Event
		LEFT JOIN
		 dbo.EventImage EI  WITH (NOLOCK)
		ON
		 EI.PK_Event = E.PK_Event
		LEFT JOIN
		 dbo.EventURL EUL WITH (NOLOCK)
		ON
		 E.PK_Event = EUL.PK_Event
		AND
		 EUL.PK_EventURLType = 5 -- for third party link
		AND
		 EUL.PK_Locale = @PK_Locale
		LEFT JOIN
		 dbo.EventLocaleDesc EDD  WITH (NOLOCK)
		ON
		 E.PK_Event = EDD.PK_Event
		 AND EDD.PK_Locale = @PK_DefaultLocale
		LEFT JOIN
			(	SELECT 	LE.PK_Locale, LE.PK_MasterLocale, LE.MasterLocaleLanguage, LE.IsMasterlocale, ML.LanguageCountryRegion MasterLanguageCountryRegion, ML.LocaleCode MasterLocaleCode
				FROM	LocalesExtn LE WITH (NOLOCK)
						inner join Locales ML WITH (NOLOCK)
							ON LE.PK_MasterLocale = ML.PK_Locale
			) LE
			ON EE.PK_DefaultMasterLocale = LE.PK_Locale
		LEFT JOIN [eventpromo].[Settings] S WITH (NOLOCK)											-- US 1003446
			ON E.PK_Event = S.PK_Event
		WHERE
		 E.PK_Event = @PK_Event
		END

		ELSE

		BEGIN
		SELECT
		  E.PK_EventType
		 ,ED.EventName
		 ,ED.EventVenueName
		 ,ED.EventLocation
		 ,ED.EventAddress
		 ,ED.EventCity
		 ,ED.EventState
		 ,E.EventZipCode
		 ,E.dStartUTC EventStartDate
		 ,E.dEndUTC EventEndDate
         ,E.EventTimeZone AS [TimezoneOffset]
         ,EE.TimeZoneDesc AS [TimezoneDesc]
         ,EE.EnabledAddToCalendar
		 ,E.DisplayStartDate
		 ,E.DisplayEndDate
		 ,E.MakePublic
		 ,E.IsActive
		 ,E.IsPublish
		 ,COALESCE(ED.EventSummary, '') EventSummary
		 ,COALESCE(ED.EventDesc, '') EventDesc
		 ,COALESCE(ED.EventRules,'') EventRules
		 ,COALESCE(ED.KeyWords,'') Keywords
		 ,E.CanPurchaseTicketOnline
		 ,E.CanAssignTickets
		 ,E.CanShowCurrentQualOnline
		 ,E.CanRegisterOnline
		 ,E.IsPreRegistrationRequired
		 ,E.QualPeriodStart
		 ,E.QualPeriodEnd
		 ,E.CanDisplayQualPeriod
		 ,E.IsQualifytoPurchaseTickets
		 ,E.IsPublishQualTracking
		 ,COALESCE(ED.Keywords, '') Keywords
		 ,COALESCE(ED.EventDisplayAddress, '') EventDisplayAddress
		 ,EC.PK_Country
		 ,CASE WHEN ISNULL(C.sCountryCodeISO,'') = '' THEN C.sCountryCode
			ELSE C.sCountryCodeISO
		 END AS EventCountry
		 ,ISNULL(EI.PK_EventImageType,0) PK_EventImageType
		 ,ISNULL(EI.PK_EventImage,'') PK_EventImage
		 ,ISNULL(EI.EventImageLocation,'')EventImageLocation
		 ,L.LocaleCode
		 ,L.LanguageCountryRegion
		 ,L1.LocaleCode DefaultLocale
		 ,L1.LanguageCountryRegion DefaultLanguageCountryRegion
		 ,E.IsSocialNetworkEnabled
		 ,@HasQualifications HasQualifications
		 ,@HasAccess HasAccess
		 ,CASE WHEN E.IsPublish = 1 AND E.DisplayEndDate >= CONVERT(DATE,GETUTCDATE(), 110) THEN 4
				  WHEN (E.IsPublish = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
			 END AS [EventStatus]
			,SUBSTRING(CONVERT(NVARCHAR(30),E.dStartUTC, 108), 1, 5) AS EventStartTime
		 ,SUBSTRING(CONVERT(NVARCHAR(30),E.dEndUTC, 108), 1, 5) AS EventEndTime
		 ,E.CanDisplayTicketDetails
		 ,E.IsTicketforQualifiedDS [TicketPurchaseforQualifiedDSOnly]
		 ,E.TicketThirdPartyLink [IsThirdPartyTicketPurchaseLink]
		 ,CASE WHEN E.CustomTrackingSiteSPName IS NOT NULL THEN 1 ELSE 0 END [IsCustomTrackerEvent]
		 ,@PK_Locale [PK_Locale]
		 ,EUL.EventURL ThirdPartyLink
		 ,ED.ParticipatingCountries
		 ,ISNULL(EE.IsDisplayTVP, 0) IsDisplayTVP
		 ,ISNULL(EE.IsDisplayRO, 0) IsDisplayRO
		 ,ISNULL(EE.IsDisplayPPV, 0) IsDisplayPPV
		 ,ISNULL(EE.IsDisplayPB, 0) IsDisplayPB
		 ,ISNULL(EE.IsDisplayDLV, 0) IsDisplayDLV
		 ,ISNULL(EE.IsDisplayPPVDLV, 0) IsDisplayPPVDLV
		 ,E.Latitude
		 ,E.Longitude
		 ,ED.TicketRules
		 ,ISNULL(EE.IsDisplayAWT, 0) IsDisplayAWT
		 ,ISNULL(EE.IsDisplayAWTQualPeriod, 0) IsDisplayAWTQualPeriod
		 ,ISNULL(EE.IsDisplayAWTFirstTime, 0) IsDisplayAWTFirstTime
		 ,EE.AWTStartDate
		 ,EE.AWTEndDate
		 ,E.IsBizworkReportEnabled
		 ,ISNULL(EE.IsDisplayPDF, 0) AS IsDisplayPDF
		 ,EE.IsDisplayDV
		 ,EE.IsUmbracoHosted
		 --,EE.HasDownlineTable
		 ,ISNULL(EE.[IsDisplayPMPPV], 0) AS [IsDisplayPMPPV]
		 ,ISNULL(EE.[TimeZoneDesc],'') AS [TimeZoneDesc]
		 ,ISNULL(EE.IsLanguageGrouped,0) as [IsLanguageGrouped]
		 ,ISNULL(EE.PK_DefaultMasterLocale,0) as [PK_DefaultMasterLocale]
		 ,ISNULL(LE.MasterLocaleLanguage,'') as [MasterLocaleLanguage]
		 ,ISNULL(LE.MasterLocaleCode,'') as [MasterLocaleCode]
		 ,ISNULL(EE.HideLandingPage,0) as [HideLandingPage]
		 ,ISNULL(EE.IsInPersonEvent,0) as [IsInPersonEvent]
		 ,ISNULL(EE.IsVirtualEvent,0) as [IsVirtualEvent]
		 ,ISNULL(EE.IsMajorEvent,0) as [IsMajorEvent]
		 ,EE.AudioLanguagesList												-- T 341289 : Adding AudioLanguages
		 ,ED.AudioLanguagesDesc												-- T 341289 : Adding AudioLanguages
		 ,ISNULL(EE.DisplayVirtualQualifiedOnly,0) AS DisplayVirtualQualifiedOnly  --T 546643 : Adding DisplayVirtualQualifiedOnly flag
         ,ISNULL(EE.DisplayDates, 1) as DisplayDates
		 ,IIF(S.PK_Event IS NOT NULL , 1, 0) AS HasAutomatedQuals						-- US 1003446
		 ,IIF(S.IsProcessingQuals = 1, 1,0) AS IsProcessingQuals						-- US 1003446
		 ,IIF(S.IsAutoProcessEnabled = 1, 1, 0) AS IsAutoProcessEnabled					-- US 1003446
         ,ISNULL(EE.HideTeamLevelInfo, 0)  as HideTeamLevelsInfo
		 ,ISNULL(EE.EnableTesting, 0)  as EnableTesting
         ,ISNULL(EE.IsDisplayDownline, 0)  as IsDisplayDownline
         ,ISNULL(EE.IsDisplayTicketsTypPage, 0)  as IsDisplayTicketsTypPage
		 ,ISNULL(EE.IsDisplayGtaLink, 0)  as IsDisplayGtaLink
		 ,ISNULL(EE.HideQualifiedBadge, 0)  as HideQualifiedBadge
		FROM
		 dbo.Event E WITH (NOLOCK)
		INNER JOIN
		 dbo.EventLocaleDesc ED WITH (NOLOCK)
		ON
		 E.PK_Event = ED.PK_Event
		 AND ED.PK_Locale = @PK_DefaultLocale
		INNER JOIN
		 dbo.Locales L  WITH (NOLOCK)
		ON
		 ED.PK_Locale = L.PK_Locale
		INNER JOIN
		 dbo.Locales L1  WITH (NOLOCK)
		ON
		 E.PK_DefaultLocale = L1.PK_Locale
		INNER JOIN
		 dbo.EventCountry EC  WITH (NOLOCK)
		ON
		 E.PK_Event = EC.PK_Event
		INNER JOIN
		 dbo.v_Countries C
		ON
		 EC.PK_Country = C.nCountryID
		LEFT JOIN
		 dbo.EventExtn EE  WITH (NOLOCK)
		ON
		 E.PK_Event = EE.PK_Event
		LEFT JOIN
		 dbo.EventImage EI  WITH (NOLOCK)
		ON
		 EI.PK_Event = E.PK_Event
		LEFT JOIN
		 dbo.EventURL EUL WITH (NOLOCK)
		ON
		 E.PK_Event = EUL.PK_Event
		AND
		 EUL.PK_EventURLType = 5 -- for third party link
		AND
		 EUL.PK_Locale = @PK_Locale
		LEFT JOIN
			(	SELECT 	LE.PK_Locale, LE.PK_MasterLocale, LE.MasterLocaleLanguage, LE.IsMasterlocale, ML.LanguageCountryRegion MasterLanguageCountryRegion, ML.LocaleCode MasterLocaleCode
				FROM	LocalesExtn LE WITH (NOLOCK)
						inner join Locales ML WITH (NOLOCK)
							ON LE.PK_MasterLocale = ML.PK_Locale
			) LE
			ON EE.PK_DefaultMasterLocale = LE.PK_Locale
		LEFT JOIN [eventpromo].[Settings] S WITH (NOLOCK)											-- US 1003446
			ON E.PK_Event = S.PK_Event
		WHERE
		 E.PK_Event = @PK_Event
		END


		/* SELECT THE SUBEVENTS FOR THE PASSED PK_EVENT */
		IF EXISTS (SELECT PK_Locale FROM dbo.SubEventLocaleDesc WITH (NOLOCK) WHERE PK_Locale = @PK_Locale AND PK_Event = @PK_Event)
		BEGIN
		SELECT
			   SE.SubEventNumber
			  ,SE.PK_Subevent
			  ,SE.SubEventName
			  ,COALESCE(SEL.SubEventQualDesc, SED.SubEventQualDesc) [SubEventQualDesc]
			  ,SEL.QualDesc [QualificationDesc]
			  ,SE.PK_SubEventGroup
		   ,SEG.SubEventGroup [SubEventGroup]
		   ,COALESCE(CASE WHEN SEL.SubEventGroupNameLocale = '' THEN NULL ELSE SEL.SubEventGroupNameLocale END, CASE WHEN SED.SubEventGroupNameLocale = '' THEN NULL ELSE SED.SubEventGroupNameLocale END ) SubEventGroupNameLocale
		   ,SEE.Icon
		   ,SEE.Color
		   ,COALESCE(CASE WHEN SEL.[Image] = '' THEN NULL ELSE SEL.[Image] END, CASE WHEN SED.[Image] = '' THEN NULL ELSE SED.[Image] END) As [Image]
		   ,CASE WHEN (ISNULL(SEE.Icon,' ') = ' ') THEN 1 ELSE 0 END [PK_IdentityType]
		   ,SE.IsTrackingVisible
		   ,SEG.SubEventGroupName
		   ,SE.IncludeInBizworkReport
		   ,SEE.[HideToPM]
		FROM
			  dbo.SubEvent SE WITH (NOLOCK)
		LEFT JOIN
			  dbo.SubEventLocaleDesc SEL WITH (NOLOCK)
		ON
			  SE.PK_Event = SEL.PK_Event
			  AND
			  SEL.PK_SubEvent = SE.PK_SubEvent
			  AND
			  SEL.PK_Locale = @PK_Locale
		LEFT JOIN
			  dbo.SubEventLocaleDesc SED WITH (NOLOCK)
		ON
			  SE.PK_Event = SED.PK_Event
			  AND
			  SED.PK_SubEvent = SE.PK_SubEvent
			  AND
			  SED.PK_Locale = @PK_DefaultLocale
		LEFT JOIN
		   dbo.SubEventGroup SEG WITH (NOLOCK)
		ON
		   SE.PK_SubEventGroup = SEG.PK_SubEventGroup
		LEFT JOIN
		   dbo.SubEventExtn SEE WITH (NOLOCK)
		ON
		   SE.PK_Event = SEE.PK_Event
		AND
		   SE.PK_SubEvent = SEE.PK_SubEvent
		WHERE
		  SE.PK_Event = @PK_Event
		  AND (@FilterBreakoutSessions = 0 OR PK_SubEventType != 5)
		ORDER BY
		 SEG.DisplayOrder
		END
		ELSE
		BEGIN
		SELECT
			   SE.SubEventNumber
			  ,SE.PK_Subevent
			  ,SE.SubEventName
			  ,SEL.SubEventQualDesc
			  ,SEL.QualDesc [QualificationDesc]
			  ,SE.PK_SubEventGroup
		   ,SEG.SubEventGroup [SubEventGroup]
		   ,SEL.SubEventGroupNameLocale
			  ,SEE.Icon
		   ,SEE.Color
		   ,SEL.[Image] As [Image]
		   ,CASE WHEN (ISNULL(SEE.Icon,' ') = ' ') THEN 1 ELSE 0 END [PK_IdentityType]
		   ,SE.IsTrackingVisible
		   ,SEG.SubEventGroupName
		   ,SE.IncludeInBizworkReport
		   ,SEE.[HideToPM]
		FROM
			  dbo.SubEvent SE WITH (NOLOCK)
		LEFT JOIN
			  dbo.SubEventLocaleDesc SEL WITH (NOLOCK)
		ON
			  SE.PK_Event = SEL.PK_Event
			  AND
			  SEL.PK_SubEvent = SE.PK_SubEvent
			  AND
			  SEL.PK_Locale = @PK_DefaultLocale
		LEFT JOIN
		   dbo.SubEventGroup SEG WITH (NOLOCK)
		ON
		   SE.PK_SubEventGroup = SEG.PK_SubEventGroup
		LEFT JOIN
		   dbo.SubEventExtn SEE WITH (NOLOCK)
		ON
		   SE.PK_SubEvent = SEE.PK_SubEvent
		WHERE
		  SE.PK_Event = @PK_Event
		  AND (@FilterBreakoutSessions = 0 OR PK_SubEventType != 5)
		ORDER BY
		 SEG.DisplayOrder
		END

		/* SELECT EVENT URLs IF AVAILABLE */
		SELECT
		  E.PK_Event
		 ,PK_EventURL
		 ,EU.EventURL
		 ,EU.EventURLDesc
		 ,EU.PK_EventURLType
		 ,EU.ModifiedDateUTC AS LastUpdatedDate
		FROM
		 dbo.EventURL EU WITH (NOLOCK)
		INNER JOIN
		 dbo.Event E WITH (NOLOCK)
		ON
		 EU.PK_Event = E.PK_Event

		WHERE
		 E.PK_Event = @PK_Event
		AND
		 EU.PK_Locale = @PK_Locale
		AND
		 (LTRIM(RTRIM(EventURL)) != '' OR EventURL IS NOT NULL)
		AND
		 EU.PK_EventURLType in (1, @DisplayPDFType, @OnlineEventLink)

		/* GET THE EVENT SUBTYPES FOR THE PASSED EVENT */

		SELECT
		  EST.PK_Event
		 ,EST.PK_EventSubType
		 ,COALESCE(ELD.EventSubTypeDesc ,ES.EventSubType) EventSubType
		FROM
		 dbo.EventEventSubType EST WITH (NOLOCK)
		INNER JOIN
		 dbo.EventSubTypes ES WITH (NOLOCK)
		ON
		 ES.PK_EventSubType = EST.PK_EventSubType
		AND
		 EST.PK_Event = @PK_Event
		LEFT JOIN
		 dbo.EventSubTypeLocaleDesc ELD WITH (NOLOCK)
		ON
		 ES.PK_EventSubType = ELD.PK_EventSubType
		AND
		 ELD.PK_Locale = @PK_Locale

		/* GET THE QUALIFIED COUNTRIES FOR THE PASSED EVENT */

		SELECT
		 E.PK_Event
		 ,EDC.PK_Country
		 ,C.sCountryCodeISO As QualifiedCountryCode
		FROM
		 dbo.Event E WITH (NOLOCK)
		LEFT JOIN
		 dbo.EventDistributorCountry EDC WITH (NOLOCK)
		ON
		 E.PK_Event = EDC.PK_Event
		INNER JOIN
		 dbo.v_Countries C
		ON
		 EDC.PK_Country = C.nCountryID
		WHERE
		 E.PK_Event = @PK_Event

		/* GET THE EVENTDSTEAMTYPES FOR THE PASSED PK_Event */
		SELECT
			   ET.DSTeamTypeCode
			   ,COALESCE(DT.DSTeamTypeDesc, DTD.DSTeamTypeDesc) DSTeamTypeDesc
		FROM
			   dbo.EventDSTeamType ET WITH (NOLOCK)
		LEFT JOIN
			   dbo.DSTeamTypeLocaleDesc DT WITH (NOLOCK)
		ON
			   ET.DSTeamTypeCode = DT.DSTeamTypeCode
			   AND
			   DT.PK_Locale = @PK_Locale
		LEFT JOIN
			   dbo.DSTeamTypeLocaleDesc DTD WITH (NOLOCK)
		ON
			   ET.DSTeamTypeCode = DTD.DSTeamTypeCode
			   AND
			   DTD.PK_Locale = @PK_DefaultLocale
		WHERE
			   ET.PK_Event = @PK_Event

		/* GET THE GUEST SPEAKERS FOR AN EVENT */

		SELECT  COALESCE(EGL.PK_EventGuestSpeakerLocale, ESD.PK_EventGuestSpeakerLocale) PK_EventGuestSpeakerLocale
				,COALESCE(EGL.PK_Event, ESD.PK_Event, EGS.PK_Event) PK_Event
				,COALESCE(EGL.PK_EventGuestSpeaker, ESD.PK_EventGuestSpeaker, EGS.PK_EventGuestSpeaker) PK_EventGuestSpeaker
				,EGS.PK_GuestSpeaker
				,COALESCE(CASE WHEN CONVERT(varchar,EGL.EventSpeakerName) = '' THEN NULL ELSE EGL.EventSpeakerName END
						,CASE WHEN CONVERT(varchar,ESD.EventSpeakerName) = '' THEN NULL ELSE ESD.EventSpeakerName END
						,EGS.EventSpeakerName) [EventSpeakerName]
				,COALESCE(CASE WHEN CONVERT(varchar,EGL.EventSpeakerTitle) = '' THEN NULL ELSE EGL.EventSpeakerTitle END
						,CASE WHEN CONVERT(varchar,ESD.EventSpeakerTitle) = '' THEN NULL ELSE ESD.EventSpeakerTitle END
						,EGS.EventSpeakerTitle) [EventSpeakerTitle]
				,COALESCE(CASE WHEN CONVERT(varchar,EGL.EventSpeakerTeamLevel) = '' THEN NULL ELSE EGL.EventSpeakerTeamLevel END
						,CASE WHEN CONVERT(varchar,ESD.EventSpeakerTeamLevel) = '' THEN NULL ELSE ESD.EventSpeakerTeamLevel END
						,EGS.EventSpeakerTeamLevel) EventSpeakerTeamLevel
				,COALESCE(CASE WHEN CONVERT(varchar,EGL.EventSpeakerBio) = '' THEN NULL ELSE EGL.EventSpeakerBio END
						,CASE WHEN CONVERT(varchar,ESD.EventSpeakerBio) = '' THEN NULL ELSE ESD.EventSpeakerBio END
						, EGS.EventSpeakerBio) [EventSpeakerBio]
				,EI.EventImageLocation [EventSpeakerImage]
				,CASE WHEN EGL.PK_EventGuestSpeakerLocale IS NOT NULL THEN EUL.EventURL ELSE EUD.EventURL END [EventSpeakerURL]

		FROM	dbo.EventGuestSpeakers EGS WITH (NOLOCK)
				LEFT JOIN dbo.EventGuestSpeakerLocale EGL WITH (NOLOCK)
					ON EGS.PK_EventGuestSpeaker = EGL.PK_EventGuestSpeaker
						AND EGS.PK_Event = EGL.PK_Event
						AND EGL.PK_Locale = @PK_Locale
				LEFT JOIN dbo.EventGuestSpeakerLocale ESD WITH (NOLOCK)
					ON EGS.PK_EventGuestSpeaker = ESD.PK_EventGuestSpeaker
						AND EGS.PK_Event = ESD.PK_Event
						AND ESD.PK_Locale = @PK_DefaultLocale
				LEFT JOIN dbo.EventImage EI WITH (NOLOCK)
					ON EGS.PK_EventImage = EI.PK_EventImage
						AND EGS.PK_Event = EI.PK_Event
				LEFT JOIN dbo.EventURL EUL WITH (NOLOCK)
					ON EUL.PK_EventURL = EGL.PK_EventURL
						AND EGS.PK_Event = EUL.PK_Event
						AND EGL.PK_Locale = @PK_Locale
				LEFT JOIN dbo.EventURL EUD WITH (NOLOCK)
					ON EUD.PK_EventURL = ESD.PK_EventURL
						AND EGS.PK_Event = EUD.PK_Event
						AND ESD.PK_Locale = @PK_DefaultLocale
				LEFT JOIN dbo.SubEvent SE WITH (NOLOCK)
					ON SE.PK_Event = EGS.PK_Event
						AND SE.PK_SubEvent = EGS.PK_SubEvent
		WHERE	EGS.PK_Event = @PK_Event
				AND COALESCE(CASE WHEN EGL.EventSpeakerName = '' THEN NULL ELSE EGL.EventSpeakerName END
							,CASE WHEN ESD.EventSpeakerName = '' THEN NULL ELSE ESD.EventSpeakerName END
							,EGS.EventSpeakerName) IS NOT NULL
				AND (isnull(SE.PK_SubEventType,0) <> 5)

		/* SELECT THE EVENTSKU DATA IF AVAILABLE FOR THE EVENT */

		;WITH SKU (PK_EventSKU, HasTickets)
		AS
		(SELECT PK_EventSKU, COUNT(*) HasTickets
		 FROM
		 dbo.SKUPurchased  WITH (NOLOCK)
		 WHERE
		 PK_Event = @PK_Event
		 GROUP BY
		 PK_EventSKU
		 HAVING COUNT(*) >= 1
		)
		SELECT
		  EK.PK_EventSKU
		 ,EK.PK_Event
		 ,EL.PK_EventSKULocaleDesc
		 ,EK.SKUCode
		 ,COALESCE(EK.SKUDesc, '') [SKUDescriptionEnglish]
		 ,COALESCE(EL.SKUDesc, '') [SKUDescriptionTranslation]
		 ,EK.SKUValidBeginUTC
		 ,EK.SKUValidEndUTC
		 ,EK.IsEventTicketSKU
		 ,@PK_Locale [PK_Locale]
		 ,EK.PK_Country
		 ,EK.PK_EventSKUType
		 ,C.sCountryCodeISO
		 ,C.sCountryName
		 ,CASE WHEN SP.PK_EventSKU IS NOT NULL THEN 1 ELSE 0 END [HasTickets]
		 ,EK.IsTrackingVisible
		FROM
		 dbo.EventSKU EK WITH (NOLOCK)
		INNER JOIN
		 dbo.v_Countries C WITH (NOLOCK)
		ON
		 EK.PK_Country = C.nCountryID
		LEFT JOIN
		 dbo.EventSKULocaleDesc EL WITH (NOLOCK)
		ON
		 EK.PK_EventSKU = EL.PK_EventSKU
		AND
		 EL.PK_Locale = @PK_Locale
		LEFT JOIN
		 SKU SP
		ON
		 EK.PK_EventSKU = SP.PK_EventSKU
		WHERE
		 EK.PK_Event = @PK_Event


		/*Select the EventAudio data for the event*/

		SELECT
		  EA.PK_EventAudio
		 ,EA.PK_Event
		 ,COALESCE(EAL.AudioName, EALD.AudioName, EA.AudioName) [MediaName]
		 ,COALESCE(EAL.AudioDesc, EALD.AudioDesc, EA.AudioDesc) [MediaDesc]
		 ,COALESCE(EAL.AudioHTML, EALD.AudioHTML, EA.AudioHTML) [MediaHTML]
		 ,MT.[MediaTypeDesc] MediaType
		FROM
		 dbo.EventAudio EA  WITH (NOLOCK)
		INNER JOIN
		 dbo.[MediaType] MT  WITH (NOLOCK)
		ON
		 EA.PK_MediaType = MT.PK_MediaType
		LEFT JOIN
		 dbo.EventAudioLocaleDesc EAL WITH (NOLOCK)
		ON
		 EA.PK_Event = EAL.PK_Event
		AND
		 EA.PK_EventAudio = EAL.PK_EventAudio
		AND
		 EAL.PK_Locale = @PK_Locale
		LEFT JOIN
		 dbo.EventAudioLocaleDesc EALD WITH (NOLOCK)
		ON
		 EA.PK_Event = EALD.PK_Event
		AND
		 EA.PK_EventAudio = EALD.PK_EventAudio
		AND
		 EALD.PK_Locale = @PK_DefaultLocale
		WHERE
		 EA.PK_Event = @PK_Event


		/*Retrieve the target markets*/

		SELECT
		  E.PK_Event
		 ,E.PK_EventDistributorCountryLocales
		 ,E.PK_Locale
		 ,L.LocaleCode
		 ,E.IsDefault
		FROM
		 dbo.EventDistributorCountryLocales  E WITH (NOLOCK)
		INNER JOIN
		 dbo.Locales L WITH (NOLOCK)
		ON
		 E.PK_Locale = L.PK_Locale
		WHERE
		 E.PK_Event = @PK_Event

		/*All the locales that the User belongs to*/

		SELECT DISTINCT
		  L.PK_Locale
		 ,L.LanguageCountryRegion
		 ,L.LocaleCode
		 ,CASE WHEN EAM.PK_Locale IS NOT NULL THEN 1 ELSE 0 END AS [HasUserAccess]
		 ,LE.PK_MasterLocale
		 ,LE.IsMasterLocale
		 ,LE.MasterLanguageCountryRegion
		 ,LE.MasterLocaleCode
		 ,LE.MasterLocaleLanguage
		FROM
		 dbo.Locales L WITH (NOLOCK)
		LEFT JOIN
			(	SELECT 	LE.PK_Locale, LE.PK_MasterLocale, LE.MasterLocaleLanguage, LE.IsMasterlocale, ML.LanguageCountryRegion MasterLanguageCountryRegion, ML.LocaleCode MasterLocaleCode
				FROM	LocalesExtn LE WITH (NOLOCK)
						inner join Locales ML WITH (NOLOCK)
							ON LE.PK_MasterLocale = ML.PK_Locale
			) LE
			ON L.PK_Locale = LE.PK_Locale
		INNER JOIN
		 dbo.EventLocaleDesc ED WITH (NOLOCK)
		ON
		 ED.PK_Locale = L.PK_Locale
		AND
		 ED.PK_Event = @PK_Event
		LEFT JOIN
		(
		 SELECT
		  EAM.PK_Locale
		 FROM
		  dbo.EventATAccessUserModules EAM WITH (NOLOCK)
		 JOIN
		  dbo.EventATAccessUser EAU WITH (NOLOCK)
		 ON
		  EAM.PK_EventATAccessUser = EAU.PK_EventATAccessUser
		 WHERE
		  EAU.EventATAccessUserName = @UserID
		)EAM
		ON
		 L.PK_Locale = EAM.PK_Locale
		ORDER BY
		 L.LanguageCountryRegion


		/*All the EventImage and Localised Images*/

		SELECT
		  EI.PK_Event
		 ,EI.PK_EventImage
		 ,EI.PK_EventImageType
		 ,EIL.PK_EventImageLocaleDesc
		 ,EIL.EventImageLocation
		 ,@PK_Locale [PK_Locale]
		FROM
		 dbo.EventImage EI WITH (NOLOCK)
		LEFT JOIN
		 dbo.EventImageLocaleDesc EIL WITH (NOLOCK)
		ON
		 EI.PK_Event = EIL.PK_Event
		AND
		 EI.PK_EventImage = EIL.PK_EventImage
		AND
		 EIL.PK_Locale = @PK_Locale
		WHERE
		 EI.PK_Event = @PK_Event


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
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;