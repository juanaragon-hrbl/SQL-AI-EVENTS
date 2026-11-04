CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Ins_Event]

    -- Mandatory Parameters
	 @LocaleCode CHAR(5) -- Language Selector Dropdown
	,@EventCountry CHAR(2)-- Country Where Event is taking place
	,@EventName nVARCHAR(200) -- Event/Promotion Name
	,@PK_EventSubType varchar(100)-- (Select EventTypes)--> Semicolon separated string e.g. '1;2;3;4;'
	,@CountryCode nVARCHAR(MAX)-- (Audience) --> Comma separated string e.g. 'en-US,es-MX,en-JM,es-CA,'
	,@EventSummary nVARCHAR(MAX)-- Summary part in the UI which is mandatory
	,@DisplayStartDate DATETIME -- Display Start Date in the UI
	,@DisplayEndDate DATETIME -- Display End Date in the UI
	,@DSTeamTypes VARCHAR(1000) -- Team Level --> Semicolon separated string e.g. 'PT;MT;GT;WT;SP;'
	,@EventRules nVARCHAR(MAX) -- Event/Promotion Rules in the UI
	,@IsPreRegistrationRequired BIT -- "Allow Pre-registration" in UI; If the Disable All options part is made NO then this will be 0
	,@CanShowCurrentQualsOnline BIT -- "Display Qualifications? Yes/No radio button entry" in UI;
	,@CanDisplayQualPeriod BIT -- "Display Qualification Dates" in UI; If the Disable All options part is made NO then this will be 0
	,@CanPurchaseTicketOnline BIT -- "Enable Online Ticket Purchase When Available" in UI; If the Disable All options part is made NO then this will be 0
	,@CanAssignTickets BIT -- "Can Assign Tickets: in UI; If the Disable All options part is made NO then this will be 0
	,@IsQualifytoPurchaseTickets BIT = 0 ---> "Enable Tickets Purchase for Qualified Distributors Only" filed in the UI;
	,@IsPublishQualTracking BIT = 1 ----> "Publish Qualification Tracking When Available" in UI; If the Disable All options part is made NO then this will be 0

	--Optional Parameters
	,@PK_Event1 INT = 0 -- Passed only during update action
	,@EventVenueName nVARCHAR(250) = NULL -- Event Venue Name
	,@EventAddress nVARCHAR(500) = NULL -- Street Address
	,@EventCity nVARCHAR(100) = NULL -- Event City
	,@EventState nVARCHAR(100) = NULL-- Event State
	,@EventZipCode VARCHAR(10)= NULL -- Zip/Postal Code
	,@EventDisplayAddress nVARCHAR(4000) = NULL -- Event Display Address
	,@EventStartDate DATETIME = NULL -- Start Date
	,@EventEndDate DATETIME = NULL -- End Date
	,@TimezoneOffset DECIMAL = -8.0 -- The Time Zone Offset
    ,@TimezoneDesc nVARCHAR(4000) = '' --The name of the timezone
    ,@EnabledAddToCalendar BIT = 0 -- This option indicates whether the event has a button to add the Event to the DS personal calendar, or not
	,@MakePublic BIT = 0 -- Make Public --> Defaulted to "NO" always in the UI
	,@IsPublish BIT = 0 -- Publish --> Defaulted to "NO always in the UI
	--,@SKUCountryCode [udt_SKUDetails] READONLY -- Added to support the SKU Insertion for an event per the latest requirement for adding SKUs to an event
	--,@IsActive BIT = 1 -- IsActive will be sent by the UI depending on what needs to be displayed. -- For now defaulted to 1 unless required by the user to make it it inactive
	,@PK_EventImageType INT = 1 --> Select Type of Image in the UI will be defaulted to 1
	,@EventImageLocation nVARCHAR(4000) = NULL --> Image File path in the UI
	,@EventImageLocationBanner nVARCHAR(4000) = NULL --> Image File path in the UI for Banner
	,@EventDetails nVARCHAR(MAX) = NULL --> Additional Details in the UI
	,@KeyWords nVARCHAR(4000) = NULL --> Keywords in the UI
	,@PK_EventGuestSpeaker1 INT = 0 --> This will have a value associated to it only during updates
	,@PK_GuestSpeaker1 INT = 0 ---> This will be passed only while guest speaker option is selected from the drop down
	,@SpeakerName1 nVARCHAR(100) = NULL ---> Name of the speaker corresponding to the PK_GuestSpeaker1
	,@SpeakerTitle1 nVARCHAR(100) = NULL ---> Title of the speaker corresponding to the PK_GuestSpeaker1
	,@SpeakerTeamLevel1 nVARCHAR(50) = NULL ---> Team Level of the speaker corresponding to the PK_GuestSpeaker1
	,@PK_EventGuestSpeaker2 INT = 0 --> This will have a value associated to it only during updates
	,@PK_GuestSpeaker2 INT = 0 ---> This will be passed only while guest speaker option is selected from the drop down
    ,@SpeakerName2 nVARCHAR(100)= NULL ---> Name of the speaker corresponding to the PK_GuestSpeaker1
	,@SpeakerTitle2 nVARCHAR(100) = NULL ---> Title of the speaker corresponding to the PK_GuestSpeaker2
	,@SpeakerTeamLevel2 nVARCHAR(50) = NULL ---> Team Level of the speaker corresponding to the PK_GuestSpeaker2
	,@QualPeriodStart DATETIME = NULL ---> "Qualification Period Start Date" field if the "Display Qualification Date" is elected as YES
	,@QualPeriodEnd DATETIME = NULL ---> "Qualification Period End Date" field if the "Display Qualification Date" is elected as YES
	,@ModifiedBy VARCHAR(30) = 'UsrSQLProd' --> During updates pass the session user that modifies the parameters
	,@IsSocialNetworksEnabled BIT = 0
	,@GalleryName nVARCHAR(4000) = NULL
	,@GalleryURL nVARCHAR(4000) = NULL
	,@LastUpdatedDate DATETIME = NULL --Date for the photo gallery
	,@EventDistributorCountryLocales [udt_EventDistributorCountryLocales] READONLY
	,@EventGuestSpeakers [udt_EventGuestSpeakers] READONLY
	,@CanDisplayTicketDetails BIT = 0
	,@IsTicketforQualifiedDS BIT = 0
	,@TicketThirdPartyLink BIT = 0
	,@ThirdPartyLink nVARCHAR(MAX) = NULL -- has to have a value when @TicketThirdPartyLink = 1
	,@SKUDetails [udt_EventSKU] READONLY
	,@ParticipatingCountries nVARCHAR(MAX) = NULL
	,@CustomTrackingCode nVARCHAR(MAX) = NULL
	-- Display PDF
	,@DisplayPDFLocation nvarchar(MAX) = NULL
	,@DisplayPDFDesc nvarchar(MAX) = NULL
	,@IsDisplayPDF bit = 0
	,@PK_DisplayPDF int = NULL	-- Corresponds to PK_EventURL in EventURL with type 'Display Event PDF' in EventURLType

	,@IsDisplayTVP BIT = 0
	,@IsDisplayRO BIT = 0
	,@IsDisplayPPV BIT = 0
	,@IsDisplayPB BIT = 0
	,@IsDisplayDLV BIT = 0
	,@IsDisplayPPVDLV BIT = 0
	,@IsDisplayDV BIT = 0
	,@Latitude NUMERIC(18,10) = NULL
	,@Longitude NUMERIC(18,10) = NULL
	,@TicketRules NVARCHAR(4000) = NULL
	,@IsDisplayAWT BIT = 0
	,@IsDisplayAWTQualPeriod BIT = 0
	,@IsDisplayAWTFirstTime BIT = 0
	,@AWTStartDate DATETIME = NULL
	,@AWTEndDate DATETIME = NULL
	,@IsBizworkReportEnabled BIT = 0
	,@IsUmbracoHosted BIT = 0
	,@HasDownlineTable BIT = 0
	,@IsDisplayPMPPV BIT = 0
	,@IsLanguageGrouped BIT = 0
	,@HideLandingPage BIT = 0
	,@IsInPersonEvent BIT = 1
	,@IsVirtualEvent BIT = 0
	,@VirtualEventLink nvarchar(max) = null
	,@VirtualEventLinkName nvarchar(max) = null
	,@IsMajorEvent BIT = 0
	,@AudioLanguagesList NVARCHAR(200) = NULL				-- T 341289 : Adding AudioLanguages
	,@AudioLanguagesDesc NVARCHAR(150) = NULL				-- T 341289 : Adding AudioLanguages
	,@DisplayVirtualQualifiedOnly BIT = 0					-- T 546643 : Adding DisplayVirtualQualifiedOnly flag
    ,@DisplayDates BIT = 1
	,@IsAutoProcessEnabled BIT  = 0							-- US 1003446
    ,@HideTeamLevelInfo BIT = 0
    ,@EnableTesting BIT = 0
    ,@IsDisplayDownline BIT = 0
    ,@IsDisplayTicketsTypPage BIT = 0
	,@IsDisplayGtaLink BIT = 0
	,@HideQualifiedBadge BIT = 0

    -- Output Parameters
	,@PK_Event INT OUTPUT -- Output parameter set as identity during insert that will be used during inserts/updates in other tables

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS

BEGIN
/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Ins_Event
USE:

			DECLARE @e int, @em varchar(4000)
			declare @IsDevQA int
			declare @EventID int
			declare @SKUDetails [udt_EventSKU]
			INSERT into @SKUDetails (PK_Event, PK_EventSKU, PK_EventSKULocaleDesc, SKUCode, SKUDesc, SKUValidBeginUTC, SKUValidEndUTC, PK_Country, SKUDescLocale, PK_Locale, PK_EventSKUType, IsDelete)
			VALUES (3121, 5694, 0, 'J111', 'Dummy SKU', '12-01-2015', '12-01-2016', 10, 'Dummy SKU Translated', 46, 1, 1)
			, (3121, 5695, 0, 'S666', 'Dummy SKU 2', '12-01-2015', '12-01-2017', 10, 'Dummy SKU Translated2', 46, 1, 0)

			declare @EventDistributorCountryLocales [udt_EventDistributorCountryLocales]
			INSERT INTO @EventDistributorCountryLocales VALUES (77, 0)

			declare @EventGuestSpeakers [udt_EventGuestSpeakers]
			INSERT INTO @EventGuestSpeakers (PK_GuestSpeaker, PK_Event, EventSpeakerName, EventSpeakerTitle, EventSpeakerTeamLevel, EventSpeakerBio, EventGuestSpeakerImage, EventGuestSpeakerURL, LocaleCode)
			VALUES (NULL, 3121, 'MOJ', 'CEO', '', 'test', '\\uslaxstor02\nutrition_club\EventsAndPromotions\EventImage\billythekid.jpg', '\\uslaxstor02\nutrition_club\EventsAndPromotions\Flyer\677bda45-6bc4-4afa-99c2-9a304a77223bDr_Nataniel_Viunski.pdf', 'en-US')

			EXEC usp_MyHLEventAPI_Ins_Event
					 @Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@PK_Event = @EventID OUTPUT /* @em must be defined in the local call */
					-- Mandatory Parameters
					,@LocaleCode = 'en-US'
					,@EventCountry = 'US'
					,@EventName = 'Another test Event'
					,@PK_EventSubType = '4;'
					,@CountryCode = 'en-US,es-MX,es-US,es-CA,'
					,@EventSummary = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam in malesuada leo, in blandit tellus. Donec auctor blandit lacus eu accumsan. Nulla non semper dolor.'
					,@DisplayStartDate = '2017-12-10'
					,@DisplayEndDate = '2017-12-20'
					,@DSTeamTypes = 'DS;PT;'
					,@EventRules = 'No rules'
					,@IsPreRegistrationRequired = 1
					,@CanShowCurrentQualsOnline = 1
					,@CanDisplayQualPeriod = 1
					,@CanPurchaseTicketOnline = 1
					,@CanAssignTickets = 0
					,@IsQualifytoPurchaseTickets = 0
					,@IsPublishQualTracking = 1

					--Optional Parameters
					,@PK_Event1 = NULL
					,@EventVenueName = 'Sal?n Trasloma'
					,@EventAddress = 'Camino al ITESO'
					,@EventCity = 'Guadalajara'
					,@EventState = 'Jalisco'
					,@EventZipCode = '11222'
					,@EventDisplayAddress = 'Avenida Trasloma'
					,@EventStartDate = '2017-12-10'
					,@EventEndDate = '2017-12-20'
                    ,@TimezoneOffset = -7.0
                    ,@TimezoneDesc = 'Pacific Standard Time'
                    ,@EnabledAddToCalendar = 0
					,@MakePublic = 0
					,@IsPublish = 1
					,@PK_EventImageType = 1
					,@EventImageLocation = '\\portal\sites\infotech\events\pdfwithlocale'
					,@EventDetails = 'Ut dictum, sapien vel accumsan mattis, tortor libero consequat enim, id mollis enim odio ac nibh. Donec pulvinar laoreet ornare.'
					,@KeyWords = NULL
					,@PK_EventGuestSpeaker1 = 0
					,@PK_GuestSpeaker1 = 0
					,@SpeakerName1 = 'Billy The Kid'
					,@SpeakerTitle1 = 'Mr.'
					,@SpeakerTeamLevel1 = 'DS'
					,@PK_EventGuestSpeaker2 = 0
					,@PK_GuestSpeaker2 = 0
					,@SpeakerName2 = NULL
					,@SpeakerTitle2 = NULL
					,@SpeakerTeamLevel2 = 'QS'
					,@QualPeriodStart = NULL
					,@QualPeriodEnd = NULL
					,@ModifiedBy = 'rogelior'
					,@IsSocialNetworksEnabled = 1
					,@GalleryName  = NULL
					,@GalleryURL  = NULL
					,@LastUpdatedDate  = NULL --Date for the photo gallery
					,@EventDistributorCountryLocales = @EventDistributorCountryLocales
					,@EventGuestSpeakers = @EventGuestSpeakers
					,@CanDisplayTicketDetails  = 1
					,@IsTicketforQualifiedDS  = 1
					,@TicketThirdPartyLink  = 1
					,@ThirdPartyLink  = 'www.herbalife.com\\thirdpartytickets' -- has to have a value when @TicketThirdPartyLink = 1
					,@SKUDetails = @SKUDetails
					,@IsDisplayTVP = 1
					,@IsDisplayRO = 0
					,@IsDisplayPPV = 0
					,@IsDisplayPB = 0
					,@IsDisplayAWT = 1
					,@IsDisplayAWTQualPeriod = 0
					,@IsDisplayAWTFirstTime = 1
					,@DisplayPDFLocation = '\\displaypdfwithlocale.com\pdf'
					,@DisplayPDFDesc = 'Display PDF for new Event'
					,@AWTStartDate = '2017-12-10'
					,@AWTEndDate = '2017-12-20'
					,@IsDisplayPMPPV = 1
				    ,@IsLanguageGrouped = 1
					,@HideLandingPage = 1
					,@IsInPersonEvent = 1
					,@IsVirtualEvent = 1
					,@VirtualEventLink = 'www.herbalife.com\\VirtualEventLink'
					,@VirtualEventLinkName = 'Virtual Event'
					,@IsMajorEvent = 0
					,@IsDevQA = 1

			SELECT @EventID, @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Inserts/Updates record into dbo.Event ,dbo.EventLocaleDesc, dbo.EventDSTeamType, dbo.EventImage, dbo.EventGuestSpeakers, dbo.EventEventSubType

NOTES:

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.Event ,dbo.EventLocaleDesc, dbo.EventDSTeamType, dbo.EventImage, dbo.EventGuestSpeakers, dbo.EventEventSubType

VERSIONS
--------------------------------------------------------------------
1.1.0	  2008-11-21	  PrabhuS		     Initial
1.2.0	  2013-01-16	  Sushma		     Changes made for Title columns of EventGuestSpeakers
1.3.0     2013-01-21	  Sushma		     Changes made for SocialNetworksEnabled bit
1.4.0     2013-02-07      Sandhya		     Changed the @SKUCountryCode parameter from comma seperated text field to table variable
		  									 that reads from udt_SKUDetails
1.5.0     2013-07-03	  Sushma		     Target Market CR Changes
1.6.0	  2014-02-14	  Sushma		     Guest Speaker CR Changes and Ticket Purchased Functionality Updated
1.7.0	  2015-01-22	  Sushma		     Add Tickets CR Changes
1.8.0	  2015-06-15	  Sushma		     Admin Tool CR Changes
1.9.0     2017-03-31      Prashanth	         Publish hide Bizwork report
1.10.0	  2017-04-28	  RogelioR	         Add a flag to display a PDF in @DisplayPDFLocation instead of a page on EventExtn
1.11.0	  2017-07-06	  RogelioR	         Add IsDisplayDV to sp
1.12.0    2017-08-09	  SandhyaP	         Add isUmbracoHosted for ins/upd
1.13.0	  2017-11-08	  RogelioR	         PDF links not saving properly
1.14.0	  2018-08-13	  RogelioR	         Added [IsDisplayPMPPV] column to [EventExtn]
1.15.0	  2019-08-14	  NoeG		         Refactor code (SRE)
1.16.0	  2019-09-17	  Noeg		         Add Master Locales information
1.17.0    2019-10-17      puertac	         SRE Implementation
1.18.0    2020-04-20      GustavoGra         Adding new fields to handle timezones.
1.19.0	  2020-05-04	  NoeG				 Add Flag to hide events on Events Landing Page
1.20.0	  2020-01-28	  NoeG				 Manage Preferred Members Configured Information for Primary Levels
1.21.0	  2020-05-28	  NoeG				 Add features IsMajorEvent, IsVirtualEvent and IsInPersonEvent to Events, also the Link and data for Virtual Event Type
1.22.0	  2020-06-23	  puertac			 BUG 279589 Remove Record from EventURL when Event is not Virtual
1.22.1	  2020-09-04	  puertac			 BUG 353730 Events Landing  and TYP Page - INC INC37736418 Tools are not displaying Promotions/Events for Distributors with Team Level PQP / 2QS / 5QS, SQS
1.22.2	  2020-09-17	  puertac			 BUG 366298 : PM Levels not saving correctly on Corporate Events. @Order didnt work for PM levels, because all PM Levels have order 25 in dbo.DSTeamType
											 Using @team to insert the right levels.
1.22.3	  2020-09-17	  puertac			 T 341289 : Adding AudioLanguagesList (dbo.EventExtn) & AudioLanguagesDesc (dbo.EventLocaleDesc)
1.22.4	  2020-10-06	  puertac			 BUG 395850 - Admin tool - Add/Update Corporate Event - Issue Creating Corp Event (Event Type Retreat)
1.22.5 	  2021-01-26	  puertac			 T 546643 : Adding DisplayVirtualQualifiedOnly flag from dbo.EventExtn
1.22.6    2022-02-22	  ivanci		     Adding HideDates flag from dbo.EventExtn
1.22.7	  2022-03-28	  puertac			 US 1003446 : Adding IsAutoProcessEnabled
1.22.8	  2022-06-07	  puertac			 BUG 1053991 : Add CreatedBy when inserting on dbo.Event  +   US 1050464: Remove Errorlog when no records are found on EventMedia,
1.22.9	  2022-06-21	  puertac			 US 1050464: Adding parameter information to @ErrorMessage (errorlog)
1.22.10	  2023-05-20	  ivanci			 US 1260167 - Admin tool - Display DS team levels  - Capability to publish/unpublish DS levels on Events
1.22.11   2023-07-13	  ivanci	         US 1275783 - Events Admin - Testing Tracker Feature - Display Downline Table
1.22.12   2024-09-25	  ivanci	         US 1365212 - Events Admin - Tickets Display at Track your progress (My Events Qualifications) Page
1.22.13	  2025-04-22	  alejandramed		 User Story 1407853: <Event Admin tool> - Add SKUs on New Event without any qualification rule (deployed)
											 Task 1407993: SQL - Ticket Report Sales 1 - add record on Schedule table: Including the Event Schedule once the  event SKUs are created and Bizworks report is enabled
1.22.14	  2025-06-26	  alejandramed		 User Story 1418801: <Event Admin tool> - Trigger Script and Create Default Sub-Event When Adding a Valid SKU
1.22.15	  2026-01-22	  gustavogra		 Add HideQualifiedBadge property to EventExtn table and stored procedures
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

DECLARE @PK_Locale INT
DECLARE @PK_Locale1 INT
DECLARE @PK_DefaultLocale INT
DECLARE @EventTypeCode CHAR(3)
DECLARE @str VARCHAR(MAX)
DECLARE @PK_Country INT
DECLARE @PK_EventCountry INT
DECLARE @EventDisplayTeam nVARCHAR(400)
DECLARE @tbl table (PK_Event int, PK_EventSubType int, PK_EventType int)
DECLARE @Len int
DECLARE @PK_EventType INT
DECLARE @team TABLE (DSTeamTypeCode VARCHAR(5), PK_Order INT)
--DECLARE @Order int						--BUG 366298 Use @team tbl to insert. @Order not needed anymore.
DECLARE @PK_EventImage1 INT
DECLARE @PK_EventImage2 INT
DECLARE @PK_EventImageType1 INT = 2
DECLARE @EventGuestSpeakers_Source [udt_EventGuestSpeakers]

SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_Locale1 = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_DefaultLocale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode

SELECT	@PK_EventCountry = nCountryID
FROM	dbo.v_Countries WITH (NOLOCK)
WHERE	sCountryCodeISO = @EventCountry
		OR (sCountryCode in ('-1','-2','-V','-W') and sCountryCode = @EventCountry)

SELECT @Error = 0, @ErrorMessage = '';

IF (@EnabledAddToCalendar IS NULL)
	SET  @EnabledAddToCalendar = 0

IF (@HideLandingPage IS NULL)
	SET  @HideLandingPage  = 0


SET @Len = LEN(@PK_EventSubType)

WHILE @Len > 0
BEGIN
	INSERT @tbl (PK_EventSubType) SELECT LEFT(@PK_EventSubType, CHARINDEX(';',@PK_EventSubType)-1)
	SET @PK_EventSubType = SUBSTRING(@PK_EventSubType, CHARINDEX(';',@PK_EventSubType)+1 , @Len)	-- BUG 395850 Remove Replace function and use Substring instead.
	SET @Len = LEN(@PK_EventSubType)
END

/****************************************************************************
	  BUG 353730 Hidden/Transition Team Levels, now linked to QS & QP
****************************************************************************/
DROP TABLE IF EXISTS #TeamCodes

SELECT val
INTO #TeamCodes
FROM  dbo.udf_SplitString(@DSTeamTypes,';')

IF EXISTS (SELECT 1 FROM #TeamCodes WHERE val = 'QP')
BEGIN
	INSERT INTO #TeamCodes
	SELECT DSTeamTypeCode FROM  DSTeamType WITH (NOLOCK)
	WHERE TransitionLevelGroup = 'QP'
END

IF EXISTS (SELECT 1 FROM #TeamCodes WHERE val = 'QS')
BEGIN
	INSERT INTO #TeamCodes
	SELECT DSTeamTypeCode FROM  DSTeamType WITH (NOLOCK)
	WHERE TransitionLevelGroup = 'QS'
END


SELECT @PK_EventType = PK_EventType FROM dbo.EventSubTypes WITH (NOLOCK) WHERE PK_EventSubType IN (SELECT DISTINCT PK_EventSubType FROM @tbl)

		INSERT INTO @team(DSTeamTypeCode, PK_Order)
		SELECT	T.VAL as DSTeamTypeCode, DT.TeamOrder
		FROM	#TeamCodes T								-- BUG 353730
				INNER JOIN PubEvents..dimDSSubType ST WITH (NOLOCK)
					ON T.VAL = ST.SubTypeCode
				LEFT JOIN dbo.DSTeamType DT WITH (NOLOCK)
					ON ST.SubTypeCode = DT.DSTeamTypeCode
		WHERE	ISNULL(T.VAL,'') <> ''
		Union
		SELECT	ST.SubTypeCode AS DSTeamTypeCode, DT.TeamOrder
		FROM	PubEvents..dimDSSubType ST WITH (NOLOCK)
				INNER JOIN PMPrimaryLevelDSSubType PLST WITH (NOLOCK)
					ON ST.PK_DSSubType = PLST.PK_DSSubType
				INNER JOIN PMPrimaryLevel PL WITH (NOLOCK)
					ON PLST.PK_PMPrimaryLevel = PL.PK_PMPrimaryLevel
				INNER JOIN #TeamCodes T							-- BUG 353730
					ON T.VAL = PL.PrimaryLevelCode
				LEFT JOIN dbo.DSTeamType DT WITH (NOLOCK)
					ON ST.SubTypeCode = DT.DSTeamTypeCode

SET @EventName = LTRIM(RTRIM(@EventName))
SET @EventVenueName = LTRIM(RTRIM(@EventVenueName))
SET @EventAddress = LTRIM(RTRIM(@EventAddress))
SET @EventCity = CASE WHEN LTRIM(RTRIM(@EventCity)) = '' THEN NULL ELSE LTRIM(RTRIM(@EventCity)) END
SET @EventState = CASE WHEN LTRIM(RTRIM(@EventState)) = '' THEN NULL ELSE LTRIM(RTRIM(@EventState)) END
SET @EventZipCode = CASE WHEN LTRIM(RTRIM(@EventZipCode)) = '' THEN NULL ELSE LTRIM(RTRIM(@EventZipCode)) END
--SET @EventSummary = LTRIM(RTRIM(@EventSummary))
--SET @EventDetails = LTRIM(RTRIM(@EventDetails))
--SELECT @Order = MAX(PK_Order) FROM @team					--BUG 366298 Use @team tbl to insert. @Order not needed anymore.



IF EXISTS (SELECT PK_Event, PK_Locale FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event1 AND PK_Locale = @PK_Locale1)
BEGIN

/* UPDATE THE Event Country FOR THE PASSED EVENT */
BEGIN TRY

	UPDATE
		dbo.EventCountry
	SET
		[PK_Country] = @PK_EventCountry
	FROM
		dbo.EventCountry
	WHERE
		PK_Event = @PK_Event1

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

BEGIN TRY
	/* UPDATE THE EXISTING RECORD IN THE EVENT TABLE FOR ALL THE FLAG AND DATE COLUMNS */
	UPDATE
		dbo.Event
	SET
		 [PK_EventType] = @PK_EventType
		,[dStartUTC] = @EventStartDate
		,[dEndUTC] = @EventEndDate
		,[DisplayStartDate] = @DisplayStartDate
		,[DisplayEndDate] = @DisplayEndDate
		,[QualPeriodStart] = @QualPeriodStart
		,[QualPeriodEnd] = @QualPeriodEnd
		,[MakePublic] = @MakePublic
		,[IsPublish] = @IsPublish
		,[IsBizworkReportEnabled] = @IsBizworkReportEnabled
		,[IsActive] = 1
		,[CanPurchaseTicketOnline] = @CanPurchaseTicketOnline
		--,[CanAssignTickets] = @CanAssignTickets
		,[CanShowCurrentQualOnline] = @CanShowCurrentQualsOnline
		,[IsPreRegistrationRequired] = @IsPreRegistrationRequired
		,[IsQualifytoPurchaseTickets] = @IsQualifytoPurchaseTickets
		,[CanDisplayQualPeriod] = @CanDisplayQualPeriod
		,[EventZipCode] = @EventZipCode
		,[ModifiedDateUTC] = @StartTime
		,[ModifiedBy] = @ModifiedBy
		,[IsPromotion] = CASE WHEN @PK_EventType = 2 THEN 1 ELSE 0 END
		,[EventApprovalStatus] = 1
		,[IsPublishQualTracking] = @IsPublishQualTracking
		,[IsSocialNetworkEnabled] = @IsSocialNetworksEnabled
		,[CanDisplayTicketDetails] = @CanDisplayTicketDetails
		,[IsTicketforQualifiedDS] = @IsTicketforQualifiedDS
		,[TicketThirdPartyLink] = @TicketThirdPartyLink
		,[Latitude] = @Latitude
		,[Longitude] = @Longitude
		,[CustomTrackingCode] = @CustomTrackingCode
	    ,[EventTimeZone] = @TimezoneOffset
WHERE
		PK_Event = @PK_Event1

	UPDATE
		dbo.EventExtn
	SET
		[IsDisplayTVP] = @IsDisplayTVP
		,[IsDisplayRO] = @IsDisplayRO
		,[IsDisplayPPV] = @IsDisplayPPV
		,[IsDisplayPB] = @IsDisplayPB
		,[IsDisplayDLV] = @IsDisplayDLV
		,[IsDisplayPPVDLV] = @IsDisplayPPVDLV
		,[IsDisplayPDF] = @IsDisplayPDF
		,[IsDisplayAWT] = @IsDisplayAWT
		,[IsDisplayAWTQualPeriod] = @IsDisplayAWTQualPeriod
		,[IsDisplayAWTFirstTime] = @IsDisplayAWTFirstTime
		,[AWTStartDate] = @AWTStartDate
		,[AWTEndDate] = @AWTEndDate
		,[ModifiedDateUTC] = @StartTime
		,[ModifiedBy] = @ModifiedBy
		,[IsDisplayDV] = @IsDisplayDV
		,[IsUmbracoHosted] = @IsUmbracoHosted
		--,[HasDownlineTable] = @HasDownlineTable
		,[IsDisplayPMPPV] = @IsDisplayPMPPV
        ,[TimezoneDesc] = @TimezoneDesc
        ,[EnabledAddToCalendar] = @EnabledAddToCalendar
		,[HideLandingPage] = @HideLandingPage
		,[IsInPersonEvent] = @IsInPersonEvent
		,[IsVirtualEvent] = @IsVirtualEvent
		,[IsMajorEvent] = @IsMajorEvent
		,[AudioLanguagesList] = @AudioLanguagesList					-- T 341289 : Adding AudioLanguages
		,[DisplayVirtualQualifiedOnly] = @DisplayVirtualQualifiedOnly	-- T 546643 : Adding DisplayVirtualQualifiedOnly flag
        ,[DisplayDates] = @DisplayDates
        ,[HideTeamLevelInfo] = @HideTeamLevelInfo
        ,[EnableTesting] = @EnableTesting
        ,[IsDisplayDownline] = @IsDisplayDownline
        ,[IsDisplayTicketsTypPage] = @IsDisplayTicketsTypPage
		,[IsDisplayGtaLink] = @IsDisplayGtaLink
		,[HideQualifiedBadge] = @HideQualifiedBadge
	WHERE
		PK_Event = @PK_Event1

	UPDATE
		dbo.Event
	SET
		 [EventName] = @EventName
		,[Location] = @EventVenueName
		,[EventVenueName] = @EventVenueName
		,[EventAddress] = @EventAddress
		,[EventCity] = @EventCity
		,[EventState] = @EventState
		,[EventZipCode] = @EventZipCode
	WHERE
		PK_Event = @PK_Event1
	AND
		PK_DefaultLocale = @PK_Locale

	UPDATE
		dbo.EventLocaleDesc
	SET
		 [EventAddress] = @EventAddress
		,[EventCity] = @EventCity
		,[EventState] = @EventState
		,[ModifiedDateUTC] = @StartTime
		,[ModifiedBy] = @ModifiedBy
	WHERE
		PK_Event = @PK_Event1


	-- US 1003446
	UPDATE S
	SET IsAutoProcessEnabled = ISNULL(@IsAutoProcessEnabled,0)
	FROM  [eventpromo].[Settings] AS S
	WHERE PK_Event = @PK_Event1

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

/* UPDATE THE RECORD INTO EVENTLOCALEDESC TABLE FOR THE PASSED PK_EVENT & PK_LOCALE */
BEGIN TRY

	UPDATE
		dbo.EventLocaleDesc
	SET
		 [PK_EventType] = @PK_EventType
		,[EventName] = @EventName
		,[EventDesc] = @EventDetails
		,[EventSummary] = @EventSummary
		,[EventLocation] = @EventVenueName
		,[EventVenueName] = @EventVenueName
		,[EventAddress] = @EventAddress
		,[EventCity] = @EventCity
		,[EventState] = @EventState
		,[EventDisplayAddress] = @EventDisplayAddress
		,[Keywords] = @KeyWords
		,[EventRules] = @EventRules
		,[ModifiedDateUTC] = @StartTime
		,[ModifiedBy] = @ModifiedBy
		,[ParticipatingCountries] =  @ParticipatingCountries
		,[TicketRules] = @TicketRules
		,[CustomTrackingCode] = @CustomTrackingCode
		,[AudioLanguagesDesc] = @AudioLanguagesDesc 					-- T 341289 : Adding AudioLanguages
	WHERE
		PK_Locale = @PK_Locale1
	AND
		PK_Event = @PK_Event1
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

/* UPDATE THE RECORD INTO EVENTDISPLAYTEAM TABLE */

BEGIN

	BEGIN TRY

		IF EXISTS (SELECT PK_Event FROM dbo.EventDSTeamType WITH (NOLOCK) WHERE PK_Event = @PK_Event1)
		DELETE FROM dbo.EventDSTeamType WHERE PK_Event = @PK_Event1

		INSERT
			dbo.EventDSTeamType
		(
			 [PK_Event]
			,[DSTeamTypeCode]
		)
		SELECT
			 @PK_Event1
			,T.DSTeamTypeCode
		FROM
			@team T

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
	/* UPDATE THE RECORD INTO EventDistributorCountry TABLE */

BEGIN TRY

	DELETE FROM dbo.EventDistributorCountry WHERE PK_Event = @PK_Event1

	INSERT INTO dbo.EventDistributorCountry
	  (CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_Event, PK_Country)
	 SELECT
		DISTINCT @StartTime, @ModifiedBy, @StartTime, @ModifiedBy, @PK_Event1, nCountryID
	 FROM
		@EventDistributorCountryLocales E
	 INNER JOIN
		dbo.Locales L WITH (NOLOCK) ON E.PK_Locale = L.PK_Locale
	 INNER JOIN
		dbo.v_Countries C WITH (NOLOCK)
	 ON
		sCountryCodeISO = SUBSTRING(L.LocaleCode, 4, 2)
	 WHERE
		NOT EXISTS(SELECT 1 FROM dbo.EventDistributorCountry EDC WITH (NOLOCK) WHERE EDC.PK_Event = @PK_Event1 and EDC.PK_Country = C.nCountryID)

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

/* UPDATE THE RECORD INTO EventEventSubType TABLE */

BEGIN TRY
	UPDATE
		@tbl
	SET
		PK_Event = @PK_Event1
		,PK_EventType = L.PK_EventType
	FROM
		@tbl T
	INNER JOIN
		dbo.EventSubTypes L
		ON
			T.PK_EventSubType = L.PK_EventSubType

	/* DELETE THE ALREADY EXISTING ENTRIES */
	DELETE FROM dbo.EventEventSubType WHERE PK_Event = @PK_Event1

	/* NOW INSERT AS FRESH ENTRIES */
	BEGIN
		INSERT
			dbo.EventEventSubType
		(
			 PK_Event
			,PK_EventType
			,PK_EventSubType
			,CreatedDateUTC
			,CreatedBy
			,ModifiedDateUTC
			,ModifiedBy
		)
		SELECT
			@PK_Event1
			,PK_EventType
			,PK_EventSubType
			,GETUTCDATE()
			,'UsrSQLProd'
			,GETUTCDATE()
			,'UsrSQLProd'
		FROM
			@tbl
	END

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

SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.Event E WITH (NOLOCK) WHERE E.PK_Event = @PK_Event1

BEGIN TRY
	/* UPDATE THE EXISTING RECORD IN THE EVENTIMAGE FOR LOGO*/

	IF EXISTS(SELECT PK_Event FROM dbo.EventImage WITH (NOLOCK) WHERE PK_Event = @PK_Event1 AND PK_EventImageType = @PK_EventImageType)
	BEGIN
		UPDATE
			dbo.EventImage
		SET
			 [EventImageLocation] = @EventImageLocation
			,[PK_EventImageType] = @PK_EventImageType
			,[ModifiedDateUTC] = @StartTime
			,[ModifiedBy] = @ModifiedBy
		WHERE
			PK_Event = @PK_Event1
		AND
			PK_EventImageType = @PK_EventImageType
	END
	ELSE
	BEGIN
		INSERT INTO dbo.EventImage
				([EventImageLocation]
			   ,[CreatedDateUTC]
			   ,[CreatedBy]
			   ,[ModifiedDateUTC]
			   ,[ModifiedBy]
			   ,[PK_Event]
			   ,[PK_EventImageType])
		 SELECT
				@EventImageLocation
			   ,@StartTime
			   ,@ModifiedBy
			   ,@StartTime
			   ,@ModifiedBy
			   ,@PK_Event1
			   ,@PK_EventImageType
	END
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

BEGIN TRY
	/* UPDATE THE EXISTING RECORD IN THE EVENTIMAGE FOR BANNER*/

	IF EXISTS(SELECT PK_Event FROM dbo.EventImage WITH (NOLOCK) WHERE PK_Event = @PK_Event1 AND PK_EventImageType = @PK_EventImageType1)
	BEGIN
		UPDATE
			dbo.EventImage
		SET
			 [EventImageLocation] = @EventImageLocationBanner
			,[PK_EventImageType] = @PK_EventImageType1
			,[ModifiedDateUTC] = @StartTime
			,[ModifiedBy] = @ModifiedBy
		WHERE
			PK_Event = @PK_Event1
		AND
			PK_EventImageType = @PK_EventImageType1

	END
	ELSE
	BEGIN
		INSERT INTO dbo.EventImage
				([EventImageLocation]
			   ,[CreatedDateUTC]
			   ,[CreatedBy]
			   ,[ModifiedDateUTC]
			   ,[ModifiedBy]
			   ,[PK_Event]
			   ,[PK_EventImageType])
		 SELECT
				@EventImageLocationBanner
			   ,@StartTime
			   ,@ModifiedBy
			   ,@StartTime
			   ,@ModifiedBy
			   ,@PK_Event1
			   ,@PK_EventImageType1

	END
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

SELECT
	@PK_EventImage1 = EI.PK_EventImage
FROM
	dbo.EventImage  EI WITH (NOLOCK)
WHERE
	EI.PK_Event = @PK_Event1
AND
	EI.PK_EventImageType = @PK_EventImageType

SELECT
	@PK_EventImage2 = EI.PK_EventImage
FROM
	dbo.EventImage EI WITH (NOLOCK)
WHERE
	EI.PK_Event = @PK_Event1
AND
	EI.PK_EventImageType = @PK_EventImageType1

/* UPDATE THE EXISTING RECORD/INSERT NEW RECORD IN THE EVENTIMAGELOCALEDESC FOR LOGO*/
BEGIN TRY

	IF EXISTS(SELECT PK_EventImage FROM dbo.EventImageLocaleDesc WITH (NOLOCK) WHERE PK_EventImage = @PK_EventImage1 AND @PK_Locale = PK_Locale AND PK_Event = @PK_Event1)
	BEGIN
		UPDATE dbo.EventImageLocaleDesc SET EventImageLocation = @EventImageLocation, [ModifiedDateUTC] = @StartTime, [ModifiedBy] = @ModifiedBy
			  WHERE PK_EventImage = @PK_EventImage1 AND PK_Locale = @PK_Locale AND PK_Event = @PK_Event1
	END
	ELSE
	BEGIN
		IF @EventImageLocation IS NOT NULL
		BEGIN
		INSERT INTO dbo.EventImageLocaleDesc (PK_Event, PK_EventImage, EventImageLocation, PK_Locale, [CreatedDateUTC], [CreatedBy], [ModifiedDateUTC], [ModifiedBy])
		SELECT
			 @PK_Event1, @PK_EventImage1, @EventImageLocation, @PK_Locale, @StartTime, @ModifiedBy, @StartTime, @ModifiedBy
		END
	END
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

/* UPDATE THE EXISTING RECORD/INSERT NEW RECORD IN THE EVENTIMAGELOCALEDESC FOR BANNER*/
BEGIN TRY

	IF EXISTS(SELECT PK_EventImage FROM dbo.EventImageLocaleDesc WITH (NOLOCK) WHERE PK_EventImage = @PK_EventImage2 AND @PK_Locale = PK_Locale AND PK_Event = @PK_Event1)
	BEGIN
		UPDATE dbo.EventImageLocaleDesc SET EventImageLocation = @EventImageLocationBanner, [ModifiedDateUTC] = @StartTime, [ModifiedBy] = @ModifiedBy
			  WHERE PK_EventImage = @PK_EventImage2 AND PK_Locale = @PK_Locale AND PK_Event = @PK_Event1
	END
	ELSE
	BEGIN
		IF @EventImageLocationBanner IS NOT NULL
		BEGIN
		INSERT INTO dbo.EventImageLocaleDesc (PK_Event, PK_EventImage, EventImageLocation, PK_Locale, [CreatedDateUTC], [CreatedBy], [ModifiedDateUTC], [ModifiedBy])
		SELECT
			 @PK_Event1, @PK_EventImage2, @EventImageLocationBanner, @PK_Locale, @StartTime, @ModifiedBy, @StartTime, @ModifiedBy
		END
	END
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



BEGIN TRY
	/* UPDATE THE EXISTING RECORD IN THE EventURL */

	IF EXISTS(SELECT PK_Event FROM dbo.EventURL WITH (NOLOCK) WHERE PK_Event = @PK_Event1 AND PK_EventURLType = 3)
	BEGIN
	IF @GalleryName IS NOT NULL
	UPDATE
		dbo.EventURL
	SET
		 EventURL = @GalleryURL
		,EventURLDesc = @GalleryName
		,[ModifiedDateUTC] = COALESCE(@LastUpdatedDate, GETUTCDATE())
		,[ModifiedBy] = @ModifiedBy
	WHERE
		PK_Event = @PK_Event1
		AND
		PK_EventURLType = 3
	END
	ELSE
	BEGIN
	IF @GalleryName IS NOT NULL
		INSERT INTO dbo.EventURL
		(
			 PK_Event
			,PK_Locale
			,PK_EventURLType
			,EventURLDesc
			,EventURL
			,CreatedDateUTC
			,CreatedBy
			,ModifiedDateUTC
			,ModifiedBy
		)

		SELECT
			 @PK_Event1
			,COALESCE(@PK_Locale, @PK_DefaultLocale)
			,3
			,@GalleryName
			,@GalleryURL
			,GETUTCDATE()
			,'UsrSQLProd'
			,COALESCE(@LastUpdatedDate, GETUTCDATE())
			,'UsrSQLProd'

	END

END TRY
BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = CONCAT('GalleryName - @PK_Event1: ',CAST(@PK_Event1 AS VARCHAR),', @PK_Locale: ',CAST(@PK_Locale AS VARCHAR),', @PK_DefaultLocale: ', CAST(@PK_DefaultLocale AS VARCHAR))
	-- = ERROR_MESSAGE()
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

/*insert/update target market locales*/

BEGIN TRY
	BEGIN

	IF EXISTS(SELECT 1 FROM EventDistributorCountryLocales WITH (NOLOCK) WHERE PK_Event = @PK_Event1)
	DELETE FROM EventDistributorCountryLocales WHERE PK_Event = @PK_Event1

	INSERT INTO EventDistributorCountryLocales
	(
		 PK_Event
		,PK_Locale
		,IsDefault
	)
	SELECT DISTINCT
		 @PK_Event1
		,E.PK_Locale
		,E.IsDefault
	FROM
		@EventDistributorCountryLocales E
	WHERE
		NOT EXISTS(SELECT 1 FROM EventDistributorCountryLocales DS WITH (NOLOCK) WHERE DS.PK_Event = @PK_Event1 AND DS.PK_Locale = E.PK_Locale)

	END
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

BEGIN TRY
/* UPDATE THE EXISTING RECORD IN THE EventURL For Third Party Link */

	IF EXISTS(SELECT PK_Event FROM dbo.EventURL WITH (NOLOCK) WHERE PK_Event = @PK_Event1 AND PK_EventURLType = 5 AND PK_Locale = COALESCE(@PK_Locale, @PK_DefaultLocale))
	BEGIN
	UPDATE
		dbo.EventURL
	SET
		 EventURL = @ThirdPartyLink
		,[ModifiedDateUTC] = COALESCE(@LastUpdatedDate, GETUTCDATE())
		,[ModifiedBy] = @ModifiedBy
	WHERE
		PK_Event = @PK_Event1
		AND
		PK_Locale = COALESCE(@PK_Locale, @PK_DefaultLocale)
		AND
		PK_EventURLType = 5
	END
	ELSE
	BEGIN
	IF @ThirdPartyLink IS NOT NULL
		INSERT INTO dbo.EventURL
		(
			 PK_Event
			,PK_Locale
			,PK_EventURLType
			,EventURL
			,CreatedDateUTC
			,CreatedBy
			,ModifiedDateUTC
			,ModifiedBy
		)

		SELECT
			 @PK_Event1
			,COALESCE(@PK_Locale, @PK_DefaultLocale)
			,5
			,@ThirdPartyLink
			,GETUTCDATE()
			,'UsrSQLProd'
			,COALESCE(@LastUpdatedDate, GETUTCDATE())
			,'UsrSQLProd'

	END

END TRY
BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = CONCAT('ThirdPartyLink - @PK_Event1: ',CAST(@PK_Event1 AS VARCHAR),', @PK_Locale: ',CAST(@PK_Locale AS VARCHAR),', @PK_DefaultLocale: ', CAST(@PK_DefaultLocale AS VARCHAR))
	-- ERROR_MESSAGE(),
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

-- UPDATE PROCESSING LOG
EXEC dbo.usp_Utility_UpdateProcessingLog
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime
END

/**************************** THIS PART HANDLES THE NEW INSERT FOR A NEW EVENT ENTRY *********************/

IF NOT EXISTS (SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event1)
BEGIN
	/* INSERT THE RECORD INTO EVENT TABLE */
	BEGIN TRY

		INSERT
			dbo.Event
		(
			 [PK_EventType]
			,[dStartUTC]
			,[dEndUTC]
            ,[EventTimeZone]
			,[EventName]
			,[EventDesc]
			,[EventCity]
			,[EventState]
			,[EventZipCode]
			,[EventAddress]
			,[DisplayStartDate]
			,[DisplayEndDate]
			,[QualPeriodStart]
			,[QualPeriodEnd]
			,[EventVenueName]
			,[MakePublic]
			,[IsPublish]
			,[IsActive]
			,[IsPromotion]
			,[EventApprovalStatus]
			,[CanPurchaseTicketOnline]
			,[CanRegisterOnline]
			,[CanAssignTickets]
			,[CanShowCurrentQualOnline]
			,[IsPreRegistrationRequired]
			,[IsQualifytoPurchaseTickets]
			,[CanDisplayQualPeriod]
			,[IsPublishQualTracking]
			,[PK_DefaultLocale]
			,[IsSocialNetworkEnabled]
			,[CanDisplayTicketDetails]
			,[IsTicketforQualifiedDS]
			,[TicketThirdPartyLink]
			,[Latitude]
			,[Longitude]
			,[IsBizworkReportEnabled]
			,[CustomTrackingCode]
			,CreatedBy						-- BUG 1053991
			,ModifiedBy						-- BUG 1053991
		)
		SELECT
			 @PK_EventType
			,@EventStartDate
			,@EventEndDate
            ,@TimezoneOffset
			,@EventName
			,@EventSummary
			,@EventCity
			,@EventState
			,@EventZipCode
			,ISNULL(@EventAddress,'')
			,@DisplayStartDate
			,@DisplayEndDate
			,@QualPeriodStart
			,@QualPeriodEnd
			,@EventVenueName
			,@MakePublic
			,@IsPublish
			,1
			,CASE WHEN @PK_EventType = 2 THEN 1 ELSE 0 END
			,1
			,@CanPurchaseTicketOnline
			,0
			,@CanAssignTickets
			,@CanShowCurrentQualsOnline
			,@IsPreRegistrationRequired
			,@IsQualifytoPurchaseTickets
			,@CanDisplayQualPeriod
			,@IsPublishQualTracking
			,@PK_DefaultLocale
			,@IsSocialNetworksEnabled
			,@CanDisplayTicketDetails
			,@IsTicketforQualifiedDS
			,@TicketThirdPartyLink
			,@Latitude
			,@Longitude
			,@IsBizworkReportEnabled
			,@CustomTrackingCode
			,ISNULL(@ModifiedBy,REPLACE(suser_sname(),'HERBALIFECORP\',''))		-- BUG 1053991
			,ISNULL(@ModifiedBy,REPLACE(suser_sname(),'HERBALIFECORP\',''))		-- BUG 1053991
		SET @PK_Event = SCOPE_IDENTITY()
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

-----------------------------------------------------------------------------------------------------------------------
--
BEGIN TRY
	IF @IsDevQA = 1
	BEGIN
		SELECT @PK_Locale AS PK_Locale, @PK_Event AS PK_Event, @DisplayPDFLocation AS DisplayPDFLocation

		SELECT
			'PDF EventURL'
			,COALESCE(@PK_Event, @PK_Event1) AS [PK_Event]
			,@PK_Locale AS [PK_Locale]
			,@DisplayPDFLocation AS [EventURL]
			,@DisplayPDFDesc AS [EventURLDesc]
			,NULL AS [Flyer]
			,@StartTime AS [CreatedDateUTC]
			,@StartTime AS [ModifiedDateUTC]
			,12 AS [PK_EventURLType]
	END;

	IF (@IsDisplayPDF = 1 AND @DisplayPDFLocation IS NULL)
	BEGIN
		SELECT @ErrorMessage = 'The Display PDF Location is mandatory if IsDisplayPDF = 1';
		RAISERROR(@ErrorMessage, 11, 1);
	END;

	IF (@DisplayPDFLocation IS NOT NULL)
	BEGIN
		MERGE dbo.EventURL AS t
			USING (SELECT
						COALESCE(@PK_Event, @PK_Event1) AS [PK_Event]
						,@PK_Locale AS [PK_Locale]
						,@DisplayPDFLocation AS [EventURL]
						,@DisplayPDFDesc AS [EventURLDesc]
						,NULL AS [Flyer]
						,@StartTime AS [CreatedDateUTC]
						,@StartTime AS [ModifiedDateUTC]
						,12 AS [PK_EventURLType]
				) AS s
				ON (t.PK_EventURL = @PK_DisplayPDF) OR (t.PK_Event = s.PK_Event AND t.PK_Locale = s.PK_Locale)
			WHEN MATCHED THEN
				UPDATE SET
					[PK_Event] = s.[PK_Event]
					,[PK_Locale] = s.[PK_Locale]
					,[EventURL] = s.[EventURL]
					,[EventURLDesc] = s.[EventURLDesc]
					,[Flyer] = s.[Flyer]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
			WHEN NOT MATCHED THEN
				INSERT(
					[PK_Event]
					,[PK_Locale]
					,[EventURL]
					,[EventURLDesc]
					,[Flyer]
					,[CreatedDateUTC]
					,[ModifiedDateUTC]
					,[PK_EventURLType]
				)
				VALUES(
					s.[PK_Event]
					,s.[PK_Locale]
					,s.[EventURL]
					,s.[EventURLDesc]
					,s.[Flyer]
					,s.[CreatedDateUTC]
					,s.[ModifiedDateUTC]
					,s.[PK_EventURLType]
				)
			;	-- Merge EventURL for Display PDF
	END
END TRY
BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = CONCAT('DisplayPDFLocation - @PK_Event1: ',CAST(@PK_Event1 AS VARCHAR),', @PK_Locale: ',CAST(@PK_Locale AS VARCHAR),', @PK_DefaultLocale: ', CAST(@PK_DefaultLocale AS VARCHAR)
								,', @PK_Event: ',CAST(@PK_Event AS VARCHAR))
	-- ERROR_MESSAGE()
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

BEGIN TRY

	/* Save New Record or Update the Existing record on EventURL for Virtual Link */
	IF (@VirtualEventLink IS NOT NULL)
	BEGIN
		MERGE dbo.EventURL AS t
			USING (SELECT
						COALESCE(@PK_Event, @PK_Event1) AS [PK_Event]
						,@PK_Locale AS [PK_Locale]
						,@VirtualEventLink AS [EventURL]
						,@VirtualEventLinkName AS [EventURLDesc]
						,NULL AS [Flyer]
						,@StartTime AS [CreatedDateUTC]
						,@StartTime AS [ModifiedDateUTC]
						,9 AS [PK_EventURLType]
				) AS s
				ON (t.PK_Event = s.PK_Event AND t.PK_Locale = s.PK_Locale AND t.PK_EventURLType = 9)
			WHEN MATCHED THEN
				UPDATE SET
					[PK_Event] = s.[PK_Event]
					,[PK_Locale] = s.[PK_Locale]
					,[EventURL] = s.[EventURL]
					,[EventURLDesc] = s.[EventURLDesc]
					,[Flyer] = s.[Flyer]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
			WHEN NOT MATCHED THEN
				INSERT(
					[PK_Event]
					,[PK_Locale]
					,[EventURL]
					,[EventURLDesc]
					,[Flyer]
					,[CreatedDateUTC]
					,[ModifiedDateUTC]
					,[PK_EventURLType]
				)
				VALUES(
					s.[PK_Event]
					,s.[PK_Locale]
					,s.[EventURL]
					,s.[EventURLDesc]
					,s.[Flyer]
					,s.[CreatedDateUTC]
					,s.[ModifiedDateUTC]
					,s.[PK_EventURLType]
				)
			;	-- Merge Virtual Event Link and Name
	END

END TRY
BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = CONCAT('VirtualEventLink: @PK_Event1: ',CAST(@PK_Event1 AS VARCHAR),', @PK_Locale: ',CAST(@PK_Locale AS VARCHAR),', @PK_DefaultLocale: ', CAST(@PK_DefaultLocale AS VARCHAR)
								,', @PK_Event: ',CAST(@PK_Event AS VARCHAR))
	-- ERROR_MESSAGE()
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

IF NOT EXISTS (SELECT PK_Event FROM dbo.EventExtn WITH(NOLOCK) WHERE PK_Event = @PK_Event1)
BEGIN
/* INSERT THE RECORD INTO EVENTCOUNTRY TABLE */
	BEGIN TRY
		INSERT INTO [dbo].[EventExtn]
				   ([CreatedDateUTC]
				   ,[CreatedBy]
				   ,[ModifiedDateUTC]
				   ,[ModifiedBy]
				   ,[PK_Event]
				   ,[IsDisplayTVP]
				   ,[IsDisplayRO]
				   ,[IsDisplayPPV]
				   ,[IsDisplayPB]
				   ,[IsDisplayDLV]
				   ,[IsDisplayPPVDLV]
				   ,[IsDisplayAWT]
				   ,[IsDisplayAWTQualPeriod]
				   ,[IsDisplayAWTFirstTime]
				   ,[AWTStartDate]
				   ,[AWTEndDate]
				   ,[IsDisplayPDF]
				   ,[IsDisplayDV]
				   ,[IsUmbracoHosted]
				   --,[HasDownlineTable]
				   ,[IsDisplayPMPPV]
				   ,[IsLanguageGrouped]
				   ,[PK_DefaultMasterLocale]
                   ,[EnabledAddToCalendar]
            	   ,[TimezoneDesc]
				   ,[HideLandingPage]
				   ,[IsInPersonEvent]
				   ,[IsVirtualEvent]
				   ,[IsMajorEvent]
				   ,[AudioLanguagesList]					-- T 341289 : Adding AudioLanguages
				   ,[DisplayVirtualQualifiedOnly]			-- T 546643 : Adding DisplayVirtualQualifiedOnly flag
                   ,[HideTeamLevelInfo]
                   ,[EnableTesting]
                   ,[IsDisplayDownline]
                   ,[IsDisplayTicketsTypPage]
				   ,[IsDisplayGtaLink]
				   ,[HideQualifiedBadge]
				   )
			 VALUES
				   (@StartTime
				   ,@ModifiedBy
				   ,@StartTime
				   ,@ModifiedBy
				   ,COALESCE(@PK_Event, @PK_Event1)
				   ,@IsDisplayTVP
				   ,@IsDisplayRO
				   ,@IsDisplayPPV
				   ,@IsDisplayPB
				   ,@IsDisplayDLV
				   ,@IsDisplayPPVDLV
				   ,@IsDisplayAWT
				   ,@IsDisplayAWTQualPeriod
				   ,@IsDisplayAWTFirstTime
				   ,@AWTStartDate
				   ,@AWTEndDate
				   ,@IsDisplayPDF
				   ,@IsDisplayDV
				   ,@IsUmbracoHosted
				   --,@HasDownlineTable
				   ,@IsDisplayPMPPV
				   ,@IsLanguageGrouped
				   ,@PK_DefaultLocale
                   ,@EnabledAddToCalendar
				   ,@TimezoneDesc
				   ,@HideLandingPage
				   ,@IsInPersonEvent
				   ,@IsVirtualEvent
				   ,@IsMajorEvent
				   ,@AudioLanguagesList						-- T 341289 : Adding AudioLanguages
				   ,@DisplayVirtualQualifiedOnly			-- T 546643 : Adding DisplayVirtualQualifiedOnly flag
                   ,@HideTeamLevelInfo
                   ,@EnableTesting
                   ,@IsDisplayDownline
                   ,@IsDisplayTicketsTypPage
				   ,@IsDisplayGtaLink
				   ,@HideQualifiedBadge
				   )
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

IF NOT EXISTS (SELECT PK_Event FROM dbo.EventCountry WITH(NOLOCK)  WHERE PK_Event = @PK_Event1)
BEGIN
	/* INSERT THE RECORD INTO EVENTCOUNTRY TABLE */
	BEGIN TRY
		INSERT INTO [dbo].[EventCountry]
				   ([CreatedDateUTC]
				   ,[CreatedBy]
				   ,[ModifiedDateUTC]
				   ,[ModifiedBy]
				   ,[PK_Event]
				   ,[PK_Country])
			 VALUES
				   (@StartTime
				   ,@ModifiedBy
				   ,@StartTime
				   ,@ModifiedBy
				   ,@PK_Event
				   ,@PK_EventCountry)
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


IF NOT EXISTS (SELECT PK_Event FROM dbo.EventLocaleDesc WITH(NOLOCK)  WHERE PK_Event = @PK_Event1 AND PK_Locale = @PK_Locale1)
BEGIN
/* INSERT THE RECORD INTO EVENTLOCALEDESC TABLE */
	BEGIN TRY
		INSERT
			dbo.EventLocaleDesc
		(
			 [PK_Event]
			,[PK_EventType]
			,[PK_Locale]
			,[PK_DefaultLocale]
			,[EventName]
			,[EventDesc]
			,[EventSummary]
			,[EventLocation]
			,[EventVenueName]
			,[EventAddress]
			,[EventCity]
			,[EventState]
			,[Keywords]
			,[EventDisplayAddress]
			,[EventRules]
			,[ParticipatingCountries]
			,[TicketRules]
			,[CustomTrackingCode]
			,[AudioLanguagesDesc]  					-- T 341289 : Adding AudioLanguages
		)
		SELECT
			 COALESCE(@PK_Event,@PK_Event1)
			,@PK_EventType
			,@PK_Locale
			,@PK_DefaultLocale
			,@EventName
			,@EventDetails
			,@EventSummary
			,ISNULL(@EventVenueName,'')
			,ISNULL(@EventVenueName,'')
			,ISNULL(@EventAddress,'')
			,@EventCity
			,@EventState
			,@KeyWords
			,@EventDisplayAddress
			,@EventRules
			,@ParticipatingCountries
			,@TicketRules
			,@CustomTrackingCode
			,@AudioLanguagesDesc					-- T 341289 : Adding AudioLanguages
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = CONCAT('Insert EventLocaleDesc - @PK_Event1: ',CAST(@PK_Event1 AS VARCHAR),', @PK_Locale: ',CAST(@PK_Locale AS VARCHAR),', @PK_DefaultLocale: ', CAST(@PK_DefaultLocale AS VARCHAR)
								,', @PK_Event: ',CAST(@PK_Event AS VARCHAR))
		-- ERROR_MESSAGE()
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

IF NOT EXISTS (SELECT PK_Event FROM dbo.EventDSTeamType WITH(NOLOCK) WHERE PK_Event = @PK_Event1)
AND NOT EXISTS (SELECT PK_Event FROM dbo.Event WITH(NOLOCK) WHERE PK_Event = @PK_Event1)

/* INSERT THE RECORD INTO EVENTDSTeamType TABLE ONLY IF A RECORD FOR THE EVENT DOES NOT EXIST */
BEGIN
	BEGIN TRY
		INSERT
			dbo.EventDSTeamType
		(
			 [PK_Event]
			,[DSTeamTypeCode]
		)
		SELECT
			 @PK_Event
			,DSTeamTypeCode
		FROM @team T						--BUG 366298 Use @team tbl to insert. @Order not needed anymore.

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


IF NOT EXISTS (SELECT PK_Event FROM dbo.EventDistributorCountry WITH(NOLOCK) WHERE PK_Event = @PK_Event1)
/* INSERT THE COUNTRY INTO EventDistributorCountry Table */
BEGIN
	BEGIN TRY

		INSERT INTO dbo.EventDistributorCountry
		  (CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_Event, PK_Country)
		 SELECT
			DISTINCT @StartTime, @ModifiedBy, @StartTime, @ModifiedBy, @PK_Event, nCountryID
		FROM
			@EventDistributorCountryLocales E
		 INNER JOIN
			dbo.Locales L WITH (NOLOCK) ON E.PK_Locale = L.PK_Locale
		 INNER JOIN
			dbo.v_Countries C WITH (NOLOCK)
		 ON
			sCountryCodeISO = SUBSTRING(L.LocaleCode, 4, 2)
		 WHERE
			NOT EXISTS(SELECT 1 FROM dbo.EventDistributorCountry EDC WITH (NOLOCK) WHERE EDC.PK_Event = @PK_Event and EDC.PK_Country = C.nCountryID)

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


IF NOT EXISTS (SELECT PK_Event FROM dbo.EventImage WITH (NOLOCK) WHERE PK_Event = @PK_Event1)
BEGIN
/* INSERT THE RECORD INTO EVENTIMAGE TABLE AND EVENTIMAGELOCALEDESC TABLE FOR LOGO AND BANNER*/
	BEGIN TRY
		INSERT INTO [dbo].[EventImage] --logo
			   ([EventImageLocation]
			   ,[CreatedDateUTC]
			   ,[CreatedBy]
			   ,[ModifiedDateUTC]
			   ,[ModifiedBy]
			   ,[PK_Event]
			   ,[PK_EventImageType])
		 SELECT
			    @EventImageLocation
			   ,@StartTime
			   ,@ModifiedBy
			   ,@StartTime
			   ,@ModifiedBy
			   ,@PK_Event
			   ,@PK_EventImageType
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

	BEGIN TRY
		 INSERT INTO [dbo].[EventImage]--banner
			   ([EventImageLocation]
			   ,[CreatedDateUTC]
			   ,[CreatedBy]
			   ,[ModifiedDateUTC]
			   ,[ModifiedBy]
			   ,[PK_Event]
			   ,[PK_EventImageType])
		 SELECT
				@EventImageLocationBanner
			   ,@StartTime
			   ,@ModifiedBy
			   ,@StartTime
			   ,@ModifiedBy
			   ,@PK_Event
			   ,@PK_EventImageType1
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

	BEGIN TRY
		 INSERT INTO [dbo].[EventImageLocaleDesc] --logo
			   ([EventImageLocation]
			   ,[PK_Event]
			   ,[CreatedDateUTC]
			   ,[CreatedBy]
			   ,[ModifiedDateUTC]
			   ,[ModifiedBy]
			   ,[PK_EventImage]
			   ,[PK_Locale]
			   )
		 SELECT
				@EventImageLocation
			   ,@PK_Event
			   ,@StartTime
			   ,@ModifiedBy
			   ,@StartTime
			   ,@ModifiedBy
			   ,EI.PK_EventImage
			   ,@PK_Locale
		 FROM
			dbo.EventImage EI WITH (NOLOCK)
		 WHERE
			EI.PK_EventImageType = @PK_EventImageType
		 AND
			EI.PK_Event = @PK_Event

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

	BEGIN TRY
		 INSERT INTO [dbo].[EventImageLocaleDesc] --banner
			   ([EventImageLocation]
			   ,[PK_Event]
			   ,[CreatedDateUTC]
			   ,[CreatedBy]
			   ,[ModifiedDateUTC]
			   ,[ModifiedBy]
			   ,[PK_EventImage]
			   ,[PK_Locale]
			   )
		 SELECT
				@EventImageLocationBanner
			   ,@PK_Event
			   ,@StartTime
			   ,@ModifiedBy
			   ,@StartTime
			   ,@ModifiedBy
			   ,EI.PK_EventImage
			   ,@PK_Locale
		 FROM
			dbo.EventImage EI WITH (NOLOCK)
		 WHERE
			EI.PK_EventImageType = @PK_EventImageType1
		 AND
			EI.PK_Event = @PK_Event

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

/******************************************************************************
	/* INSERT THE RECORD INTO EVENTSUBTYPE TABLE */
******************************************************************************/
IF NOT EXISTS (SELECT PK_Event FROM dbo.EventEventSubType WITH(NOLOCK) WHERE PK_Event = @PK_Event1)
BEGIN
	UPDATE
		@tbl
	SET
		PK_Event = @PK_Event
		,PK_EventType = L.PK_EventType
	FROM
		@tbl T
	INNER JOIN
		dbo.EventSubTypes L
		ON
			T.PK_EventSubType = L.PK_EventSubType

	/* NOW INSERT AS FRESH ENTRIES */
	BEGIN TRY
		BEGIN
			INSERT
				dbo.EventEventSubType
			(
				 PK_Event
				,PK_EventType
				,PK_EventSubType
				,CreatedDateUTC
				,CreatedBy
				,ModifiedDateUTC
				,ModifiedBy
			)
			SELECT
				 @PK_Event
				,PK_EventType
				,PK_EventSubType
				,GETUTCDATE()
				,'UsrSQLProd'
				,GETUTCDATE()
				,'UsrSQLProd'
			FROM
				@tbl
		END

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


IF NOT EXISTS (SELECT PK_Event FROM dbo.EventURL WITH(NOLOCK) WHERE PK_Event = @PK_Event1 AND PK_EventURLType = 3) AND @GalleryName IS NOT NULL
BEGIN
	INSERT INTO dbo.EventURL
	(
		 PK_Event
		,PK_Locale
		,PK_EventURLType
		,EventURLDesc
		,EventURL
		,CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
	)

	SELECT
		 @PK_Event
		,COALESCE(@PK_Locale, @PK_DefaultLocale)
		,3
		,@GalleryName
		,@GalleryURL
		,GETUTCDATE()
		,'UsrSQLProd'
		,COALESCE(@LastUpdatedDate, GETUTCDATE())
		,'UsrSQLProd'
END

/*INSERT THE NEWLY CREATED EVENT'S TARGET MARKET*/

IF NOT EXISTS(SELECT 1 FROM dbo.EventDistributorCountryLocales E WITH(NOLOCK) WHERE PK_Event = @PK_Event1)
BEGIN TRY

	INSERT INTO EventDistributorCountryLocales
	(
		 PK_Event
		,PK_Locale
		,IsDefault
	)
	SELECT DISTINCT
		 @PK_Event
		,E.PK_Locale
		,E.IsDefault
	FROM
		@EventDistributorCountryLocales E
	WHERE
		NOT EXISTS(SELECT 1 FROM EventDistributorCountryLocales DS WITH (NOLOCK) WHERE DS.PK_Event = @PK_Event AND DS.PK_Locale = E.PK_Locale)

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

IF NOT EXISTS (SELECT PK_Event FROM dbo.EventURL WITH(NOLOCK) WHERE PK_Event = @PK_Event1 AND PK_EventURLType = 5 AND PK_Locale = COALESCE(@PK_Locale, @PK_DefaultLocale)) --For Third Party Link
AND @ThirdPartyLink IS NOT NULL
BEGIN

	INSERT INTO dbo.EventURL
	(
		 PK_Event
		,PK_Locale
		,PK_EventURLType
		,EventURL
		,CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
	)

	SELECT
		 @PK_Event
		,COALESCE(@PK_Locale, @PK_DefaultLocale)
		,5
		,@ThirdPartyLink
		,GETUTCDATE()
		,'UsrSQLProd'
		,COALESCE(@LastUpdatedDate, GETUTCDATE())
		,'UsrSQLProd'
END

/* UPDATE THE EVENT GUEST SPEAKER IMAGE */


DECLARE @EventGuestSpeakers2 udt_EventGuestSpeakers

INSERT @EventGuestSpeakers2 (PK_EventGuestSpeaker, PK_GuestSpeaker, PK_EventGuestSpeakerLocale, PK_Event, EventSpeakerName, EventSpeakerTitle, EventSpeakerPhone, EventSpeakerEmail, EventSpeakerTeamLevel,	EventSpeakerBio, EventGuestSpeakerImage, EventGuestSpeakerURL, LocaleCode)
SELECT PK_EventGuestSpeaker, PK_GuestSpeaker, PK_EventGuestSpeakerLocale, CASE WHEN PK_Event = 0 THEN @PK_Event ELSE PK_Event END PK_Event, EventSpeakerName, EventSpeakerTitle, EventSpeakerPhone, EventSpeakerEmail, EventSpeakerTeamLevel,	EventSpeakerBio, EventGuestSpeakerImage, EventGuestSpeakerURL, LocaleCode
FROM @EventGuestSpeakers

BEGIN TRY

	SET @PK_EventImageType = 3


	MERGE dbo.EventImage EGI
	USING
		(
			SELECT DISTINCT PK_Event, EventGuestSpeakerImage FROM @EventGuestSpeakers2
		) AS GI
	ON GI.PK_Event = EGI.PK_Event
	AND GI.EventGuestSpeakerImage = EGI.EventImageLocation
	AND EGI.PK_EventImageType = @PK_EventImageType
	WHEN NOT MATCHED AND GI.EventGuestSpeakerImage <> '' THEN INSERT
				([EventImageLocation]
			   ,[CreatedDateUTC]
			   ,[CreatedBy]
			   ,[ModifiedDateUTC]
			   ,[ModifiedBy]
			   ,[PK_Event]
			   ,[PK_EventImageType])
	VALUES
			(
				GI.EventGuestSpeakerImage
			   ,@StartTime
			   ,@ModifiedBy
			   ,@StartTime
			   ,@ModifiedBy
			   ,GI.PK_Event
			   ,@PK_EventImageType
			)
	WHEN MATCHED THEN
	UPDATE
		SET
			 [EventImageLocation] = CASE WHEN GI.EventGuestSpeakerImage <> '' THEN GI.EventGuestSpeakerImage ELSE NULL END
			,[ModifiedDateUTC] = @StartTime
			,[ModifiedBy] = @ModifiedBy;

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


/* UPDATE THE EVENT GUEST SPEAKER Attachment/URL */

BEGIN TRY

	DECLARE @PK_EventURLGuestType INT
	SELECT @PK_EventURLGuestType = PK_EventURLType FROM dbo.EventURLType  WITH (NOLOCK) WHERE EventURLType = 'Event Guest Speaker Link'

	MERGE dbo.EventURL EU
	USING
		(
			SELECT DISTINCT PK_Event, EventGuestSpeakerURL, L.PK_Locale FROM @EventGuestSpeakers2 EG
			INNER JOIN dbo.Locales L WITH (NOLOCK) ON EG.LocaleCode = L.LocaleCode
			WHERE EventGuestSpeakerURL IS NOT NULL OR EventGuestSpeakerURL <> ''
		) AS GI
	ON EU.PK_Event = GI.PK_Event
	AND EU.EventURL = GI.EventGuestSpeakerURL
	AND EU.PK_EventURLType = @PK_EventURLGuestType
	AND EU.PK_Locale = GI.PK_Locale
	WHEN NOT MATCHED AND GI.EventGuestSpeakerURL <> '' THEN INSERT
			  ([EventURL]
			   ,[CreatedDateUTC]
			   ,[CreatedBy]
			   ,[ModifiedDateUTC]
			   ,[ModifiedBy]
			   ,[PK_Event]
			   ,[PK_EventURLType]
			   ,[PK_Locale])
	VALUES
			(
				GI.EventGuestSpeakerURL
			   ,@StartTime
			   ,@ModifiedBy
			   ,@StartTime
			   ,@ModifiedBy
			   ,GI.PK_Event
			   ,@PK_EventURLGuestType
			   ,GI.PK_Locale
			)
	WHEN MATCHED THEN
	UPDATE
		SET
			 [EventURL] = CASE WHEN GI.EventGuestSpeakerURL <> ''  THEN GI.EventGuestSpeakerURL ELSE NULL END
			,[ModifiedDateUTC] = @StartTime
			,[ModifiedBy] = @ModifiedBy
			;

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

/* UPDATE THE EVENT GUEST SPEAKERS TABLE WITH THE VALUES BEING PASSED */
BEGIN TRY

	MERGE dbo.[EventGuestSpeakers] EGS
		USING
		(
			SELECT EGS.PK_Event, EGS.PK_EventGuestSpeaker, EGS.EventSpeakerName, EGS.EventSpeakerTitle, EGS.EventSpeakerTeamLevel, EGS.EventSpeakerBio, EI.PK_EventImage, L.PK_Locale
			FROM @EventGuestSpeakers2 EGS
			INNER JOIN dbo.Locales L WITH (NOLOCK)
			ON EGS.LocaleCode = L.LocaleCode
			LEFT JOIN dbo.EventImage  EI WITH (NOLOCK)
			ON EI.PK_Event = EGS.PK_Event
			AND EI.EventImageLocation = EGS.EventGuestSpeakerImage
		) AS M
		ON M.PK_Event = EGS.PK_Event
		AND M.PK_EventGuestSpeaker = EGS.PK_EventGuestSpeaker
		WHEN NOT MATCHED THEN INSERT (PK_Event, EventSpeakerName, EventSpeakerTitle, EventSpeakerTeamLevel, EventSpeakerBio, PK_EventImage)
		VALUES(M.PK_Event, M.EventSpeakerName, M.EventSpeakerTitle, M.EventSpeakerTeamLevel, M.EventSpeakerBio, M.PK_EventImage)
		WHEN MATCHED AND M.PK_Locale = @PK_DefaultLocale THEN
		UPDATE
		SET EventSpeakerName = M.EventSpeakerName
		, EventSpeakerTitle = M.EventSpeakerTitle
		, EventSpeakerTeamLevel = M.EventSpeakerTeamLevel
		, EventSpeakerBio = M.EventSpeakerBio
		, PK_EventImage = M.PK_EventImage
		, ModifiedDateUTC = @StartTime
		, ModifiedBy = @ModifiedBy;

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

/* DELETE THE GUEST SPEAKER ENTRIES THAT ARE REMOVED */

BEGIN TRY

	;WITH SpeakerLocaleTarget As
		(SELECT
		  GSL.PK_EventGuestSpeakerLocale
		, GSL.PK_EventGuestSpeaker
		, GSL.EventSpeakerName
		, GSL.EventSpeakerTitle
		, GSL.CreatedDateUTC
		, GSL.CreatedBy
		, GSL.ModifiedDateUTC
		, GSL.ModifiedBy
		, GSL.PK_Event
		, GSL.PK_Locale
		, GSL.EventSpeakerBio
		, GSL.PK_EventURL
		FROM dbo.EventGuestSpeakerLocale GSL  WITH (NOLOCK)
		--INNER JOIN @EventGuestSpeakers P
	 --   ON GSL.PK_Event = P.PK_Event
		WHERE NOT EXISTS (SELECT 1 FROM @EventGuestSpeakers2 E INNER JOIN dbo.Locales L  WITH (NOLOCK) ON E.LocaleCode = L.LocaleCode WHERE GSL.PK_EventGuestSpeaker = E.PK_EventGuestSpeaker)
		AND GSL.PK_Event = COALESCE(@PK_Event, @PK_Event1)
		)
		MERGE SpeakerLocaleTarget EGL
		USING
		(
			SELECT EGS.PK_EventGuestSpeakerLocale, EGS.PK_Event, EGS.PK_EventGuestSpeaker, EGS.EventSpeakerName, EGS.EventSpeakerTitle, EGS.EventSpeakerTeamLevel, EGS.EventSpeakerBio, L.PK_Locale
			FROM @EventGuestSpeakers2 EGS
			INNER JOIN dbo.Locales L WITH (NOLOCK)
			ON EGS.LocaleCode = L.LocaleCode
		) AS M
		ON M.PK_Event = EGL.PK_Event
		AND M.PK_EventGuestSpeakerLocale = EGL.PK_EventGuestSpeakerLocale
		AND M.PK_Locale = EGL.PK_Locale
		WHEN NOT MATCHED BY SOURCE THEN DELETE;

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

/* UPDATE PK_EventGuestSpeaker IN THE TABLE VARIABLE  */

UPDATE EGS
SET
PK_EventGuestSpeaker = GS.PK_EventGuestSpeaker
FROM
@EventGuestSpeakers2 EGS
INNER JOIN
dbo.EventGuestSpeakers GS  WITH (NOLOCK)
ON EGS.PK_Event = GS.PK_Event
AND EGS.EventSpeakerName = GS.EventSpeakerName
AND EGS.PK_EventGuestSpeaker IS NULL


/* UPDATE/INSERT THE EVENT GUEST SPEAKER LOCALE TABLE WITH THE VALUES BEING PASSED */

BEGIN TRY

	;WITH SpeakerLocaleTarget As
	(SELECT
	  GSL.PK_EventGuestSpeakerLocale
	, GSL.PK_EventGuestSpeaker
	, GSL.EventSpeakerName
	, GSL.EventSpeakerTitle
	, GSL.EventSpeakerTeamLevel
	, GSL.CreatedDateUTC
	, GSL.CreatedBy
	, GSL.ModifiedDateUTC
	, GSL.ModifiedBy
	, GSL.PK_Event
	, GSL.PK_Locale
	, GSL.EventSpeakerBio
	, GSL.PK_EventURL
	FROM dbo.EventGuestSpeakerLocale GSL  WITH (NOLOCK)
	LEFT JOIN @EventGuestSpeakers2 P
	ON P.PK_EventGuestSpeakerLocale = GSL.PK_EventGuestSpeakerLocale
	AND P.PK_Event = GSL.PK_Event
	INNER JOIN dbo.Locales L WITH (NOLOCK)
	ON L.LocaleCode = P.LocaleCode
	AND GSL.PK_Locale = L.PK_Locale
	)
	MERGE SpeakerLocaleTarget EGL
	USING
	(
		SELECT EGS.PK_EventGuestSpeakerLocale, EGS.PK_Event, COALESCE(EGS.PK_EventGuestSpeaker, GS.PK_EventGuestSpeaker) PK_EventGuestSpeaker, EGS.EventSpeakerName, EGS.EventSpeakerTitle, EGS.EventSpeakerTeamLevel, EGS.EventSpeakerBio, L.PK_Locale, EU.PK_EventURL
		FROM @EventGuestSpeakers2 EGS
		INNER JOIN dbo.Locales L WITH (NOLOCK)
		ON EGS.LocaleCode = L.LocaleCode
		LEFT JOIN dbo.EventGuestSpeakers GS  WITH (NOLOCK)
		ON EGS.PK_Event = GS.PK_Event
		AND EGS.PK_EventGuestSpeaker = GS.PK_EventGuestSpeaker
		LEFT JOIN dbo.EventGuestSpeakerLocale EGL  WITH (NOLOCK)
		ON EGS.PK_Event = EGL.PK_Event
		AND EGS.PK_EventGuestSpeaker = EGL.PK_EventGuestSpeaker
		AND EGS.PK_EventGuestSpeakerLocale = EGL.PK_EventGuestSpeakerLocale
		LEFT JOIN dbo.EventURL  EU WITH (NOLOCK)
		ON EU.PK_Event = EGS.PK_Event
		AND EU.EventURL = EGS.EventGuestSpeakerURL
		AND EU.PK_EventURLType = @PK_EventURLGuestType
		AND EU.PK_Locale = L.PK_Locale
	) AS M
	ON M.PK_Event = EGL.PK_Event
	AND M.PK_EventGuestSpeakerLocale = EGL.PK_EventGuestSpeakerLocale
	AND M.PK_Locale = EGL.PK_Locale
	WHEN NOT MATCHED THEN INSERT (PK_EventGuestSpeaker, PK_Event, EventSpeakerName, EventSpeakerTitle, EventSpeakerTeamLevel, EventSpeakerBio, PK_EventURL, PK_Locale)
	VALUES(M.PK_EventGuestSpeaker, M.PK_Event, M.EventSpeakerName, M.EventSpeakerTitle, M.EventSpeakerTeamLevel, M.EventSpeakerBio, M.PK_EventURL, M.PK_Locale)
	WHEN MATCHED THEN
	UPDATE
	SET EventSpeakerName = M.EventSpeakerName
	, EventSpeakerTitle = M.EventSpeakerTitle
	, EventSpeakerTeamLevel = M.EventSpeakerTeamLevel
	, EventSpeakerBio = M.EventSpeakerBio
	, PK_EventURL = M.PK_EventURL
	, ModifiedDateUTC = @StartTime
	, ModifiedBy = @ModifiedBy;
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


/* REMOVE EVENT GUEST SPEAKER IF THERE ARE NO ASSOCIATIONS */

BEGIN TRY

	DELETE EGS FROM dbo.EventGuestSpeakers EGS
	LEFT JOIN dbo.EventGuestSpeakerLocale EG WITH (NOLOCK)
	ON EGS.PK_Event = EG.PK_Event
	AND EGS.PK_EventGuestSpeaker = EG.PK_EventGuestSpeaker
	WHERE EGS.PK_Event =  COALESCE(@PK_Event, @PK_Event1)
	AND EG.PK_EventGuestSpeaker IS NULL

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


/* DELETE THE IMAGE THAT IS NOT NEEDED ANYMORE */
BEGIN TRY

	;WITH EventImageTarget
	AS
	(SELECT EGI.PK_Event, EGI.PK_EventImage, EGI.EventImageLocation, EGI.PK_EventImageType, EGI.CreatedDateUTC, EGI.CreatedBy, EGI.ModifiedDateUTC, EGI.ModifiedBy
	 FROM dbo.EventImage  EGI WITH (NOLOCK)
	 INNER JOIN @EventGuestSpeakers EGS
	 ON EGS.PK_Event = EGI.PK_Event
	 AND EGI.PK_EventImageType = @PK_EventImageType
	 WHERE NOT EXISTS (SELECT 1 FROM @EventGuestSpeakers E WHERE EGI.EventImageLocation = E.EventGuestSpeakerImage AND EGI.PK_Event = E.PK_Event AND EGI.PK_EventImageType = @PK_EventImageType))
	MERGE EventImageTarget EGI
	USING
		(
			SELECT DISTINCT PK_Event, EventGuestSpeakerImage FROM @EventGuestSpeakers
		) AS GI
	ON GI.PK_Event = EGI.PK_Event
	AND GI.EventGuestSpeakerImage = EGI.EventImageLocation
	AND EGI.PK_EventImageType = @PK_EventImageType
	WHEN NOT MATCHED BY SOURCE THEN DELETE;

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

/* DELETE THE URL (ATTACHMENT/WEBSITE) THAT IS NOT NEEDED ANYMORE */
BEGIN TRY

	;WITH EventURLTarget
	AS
	(SELECT EU.PK_Event, EU.PK_EventURL, EU.EventURL, EU.PK_Locale, EU.PK_EventURLType, EU.CreatedDateUTC, EU.CreatedBy, EU.ModifiedDateUTC, EU.ModifiedBy
	 FROM dbo.EventURL  EU WITH (NOLOCK)
	 INNER JOIN @EventGuestSpeakers EGS
	 ON EGS.PK_Event = EU.PK_Event
	 AND EU.PK_EventURLType = @PK_EventURLGuestType
	 INNER join dbo.Locales L WITH (NOLOCK) ON EGS.LocaleCode = L.LocaleCode
	  AND EU.PK_Locale = L.PK_Locale
	 WHERE NOT EXISTS (SELECT 1 FROM @EventGuestSpeakers E INNER JOIN dbo.Locales L WITH (NOLOCK) ON E.LocaleCode = L.LocaleCode WHERE EU.EventURL = EGS.EventGuestSpeakerURL AND EU.PK_Locale = L.PK_Locale AND EGS.PK_Event = EU.PK_Event))
	MERGE EventURLTarget EU
	USING
		(
			SELECT DISTINCT PK_Event, EventGuestSpeakerURL, L.PK_Locale FROM @EventGuestSpeakers EG
			INNER JOIN dbo.Locales L WITH (NOLOCK) ON EG.LocaleCode = L.LocaleCode
			WHERE EventGuestSpeakerURL IS NOT NULL OR EventGuestSpeakerURL <> ''
		) AS GI
	ON EU.PK_Event = GI.PK_Event
	AND EU.EventURL = GI.EventGuestSpeakerURL
	AND EU.PK_EventURLType = @PK_EventURLGuestType
	AND EU.PK_Locale = GI.PK_Locale
	WHEN NOT MATCHED BY SOURCE THEN DELETE;

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

	DECLARE @e INT
	DECLARE @em VARCHAR(200)

/* EventSKU and EventSKULocaleDesc Tables Insert/Update/Delete*/
BEGIN TRY

	DECLARE @PK_EventForSKU INT
	SELECT @PK_EventForSKU = COALESCE(@PK_Event, @PK_Event1)

	EXEC usp_MyHLEventAPI_Upd_EventSKU
					 @PK_Event = @PK_EventForSKU
					,@SKUDetails = @SKUDetails
					,@ModifiedBy = @ModifiedBy
					,@IsFromAdmin = 1
					,@Error = @e
					,@ErrorMessage = @em
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


/* Creating schedule */
BEGIN TRY


	DECLARE @PK_EventSchedule INT = COALESCE(@PK_Event, @PK_Event1)

	IF EXISTS (SELECT 1 FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = @PK_EventSchedule)
	AND @IsBizworkReportEnabled = 1
	BEGIN

	EXEC dbo.usp_UpdateSchedule @PK_Event = @PK_EventSchedule,
								@User = @ModifiedBy,
								@IsPromotion = 0,
								@Error = @e OUTPUT,
								@ErrorMessage = @em OUTPUT,
								@IsDevQA = 0

		--Error details are is being logged within usp_UpdateSchedule
		IF @e != 0
		BEGIN
			--Return error details
			SET @Error = @e
			SET @ErrorMessage = @em
		END
	END
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

/* Creating subevent */
BEGIN TRY

	DECLARE @PK_EventSubEvent INT = ISNULL(@PK_Event, @PK_Event1)

	IF EXISTS (SELECT 1 FROM [dbo].[EventSKU] WITH (NOLOCK) WHERE PK_Event = @PK_EventSubEvent)
	AND NOT EXISTS (SELECT 1 FROM [dbo].[SubEvent] WITH (NOLOCK) WHERE PK_Event = @PK_EventSubEvent)
	AND @IsBizworkReportEnabled = 1
	BEGIN

		 DECLARE @params_subevents NVARCHAR(MAX) = (
			 SELECT
				@PK_EventSubEvent AS [pkEvent],
				(SELECT PK_SubEventType
				FROM SubEventType (NOLOCK)
				WHERE SubEventType = LTRIM(RTRIM('General Admission'))) AS [pKSubEventType],
				20000 AS [maxCapacity],
				16000 AS [expectedCapacity],
				1 AS [subEventNumber],
				'General Training' AS [subEventName],
				NULL AS [subEventFormula],
				1 AS [keepDNR],
				0 AS [keepDeleted],
				NULL AS [subEventNamePositionID],
				NULL AS [location],
				NULL AS [localName],
				NULL AS [beginTime],
				NULL AS [endTime],
				NULL AS [pKSubEventGroup],
				1 AS [isTrackingVisible],
				1 AS [isMainEventQual],
				NULL AS [canProcessQual],
				1 AS [isBBBreakDownReqd],
				0 AS [isDiamondRptReqd],
				1 AS [includeInBizworkReport]  FOR JSON PATH, INCLUDE_NULL_VALUES)

			------------------------------------------------------------------------------------------------------------------------------------
			-- [Event].[usp_SetupSubEvent]
			------------------------------------------------------------------------------------------------------------------------------------

			IF  @params_subevents IS NOT NULL
			BEGIN

				EXEC [Event].[usp_SetupSubEvent] @param = @params_subevents,
										@Error = @e OUTPUT,
										@ErrorMessage = @em OUTPUT,
										@IsDevQA = 0


				SELECT @PK_DefaultLocale = E.[PK_DefaultLocale]
				FROM dbo.[Event] E WITH (NOLOCK)
				WHERE E.PK_Event = @PK_EventSubEvent

				INSERT INTO dbo.SubEventLocaleDesc
				(
					PK_SubEvent,
					PK_Event,
					PK_Locale,
					PK_DefaultLocale,
					SubEventName,
					SubEventQualDesc,
					CreatedDateUTC,
					CreatedBy,
					ModifiedDateUTC,
					ModifiedBy,
					PK_TeamSite,
					TeamSiteModifiedDate
				)
				SELECT PK_SubEvent,
					   PK_Event,
					   @PK_DefaultLocale,
					   @PK_DefaultLocale,
					   SubEventName,
					   SubEventName,
					   CreatedDateUTC,
					   CreatedBy,
					   CreatedDateUTC,
					   CreatedBy,
					   NULL,
					   NULL
				FROM dbo.SubEvent AS S WITH (NOLOCK)
				WHERE PK_Event = @PK_EventSubEvent
					  AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.SubEventLocaleDesc AS SLD (NOLOCK)
					WHERE SLD.PK_Event = S.PK_Event
						  AND SLD.PK_SubEvent = S.PK_SubEvent
				)
					END


			--Error details are is being logged within [usp_SetupSubEvent]
			IF @e != 0
			BEGIN
				--Return error details
				SET @Error = @e
				SET @ErrorMessage = @em
			END
	END
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

/***************************************************************************************
		BUG 279589 Remove Record from EventURL when Event is not Virtual
****************************************************************************************/

BEGIN TRY

		IF EXISTS (SELECT PK_Event FROM dbo.EventURL WITH (NOLOCK) WHERE PK_Event = @PK_Event1 AND PK_EventURLType = 9) AND @IsVirtualEvent = 0
		BEGIN
				DELETE FROM EventURL
				WHERE PK_Event = @PK_Event1
				AND PK_EventURLType = 9
		END

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


/* RETURN THE NEW EVENT CREATED */

SELECT @PK_Event

-- UPDATE PROCESSING LOG
EXEC dbo.usp_Utility_UpdateProcessingLog
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime


/******************************************************************************
	END PROCEDURE
******************************************************************************/
END

