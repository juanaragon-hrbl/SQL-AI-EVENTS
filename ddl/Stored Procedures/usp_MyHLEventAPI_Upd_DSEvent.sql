CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Upd_DSEvent]
        --Mandatory Parameters
         @PK_Event INT
		,@LocaleCode CHAR(5)--Editing of the LocaleCode from the UI will be disabled once the Event is PUBLISHED This has to be handled at the UI layer
		,@EventName nVARCHAR(250)
		,@PK_EventSubType varchar(100) -- This is a semicolon separated value and end with a semi colon e.g.'1;2;3;4;' 
		,@CountryCode nVARCHAR(MAX)-- (Select Eligible Countries) --> Comma separated string e.g. 'US,MX,JM,CA,'	
		,@EventStartDate SMALLDATETIME 
		,@EventEnddate SMALLDATETIME
		,@RecurringEventEnddate SMALLDATETIME = NULL -- This is the End Date for Recurring Events
		,@EventAddress nVARCHAR(500)
		,@EventCity nVARCHAR(250)
		,@EventState nVARCHAR(200)
		,@EventCountry nVARCHAR(100)
		,@EventZipCode nVARCHAR(20)
		,@ApprovalFlag INT --TO BE PASSED FROM FRONT END---> 0 = Under review; 1 = Approved; 2 = Rejected; 3 = Saved as Draft
		,@DisplayStartDate DATETIME --> If not selected by the user then we need the default value passed
		,@DisplayEndDate DATETIME --> If not selected by the user then we need the default value passed
		,@IsActive BIT --> Will be sent by the UI based on if the user wants to make the event active or inactive
		,@IsPublish BIT --> Will be sent by the UI based on if the user wants to publish the event or not
		-- Optional Parameters
		,@EventDisplayAddress nVARCHAR(4000) = NULL
		,@EventTrainingLanguages nVARCHAR(4000) = NULL
		,@EventCostDetails nVARCHAR(1000) = NULL
		,@Flyer nVARCHAR(2000) = NULL
		,@EventURL nVARCHAR(4000) = NULL
		,@EventDesc nVARCHAR(MAX) = NULL
		,@PK_GuestSpeaker1 INT = 0
		,@SpeakerName1 nVARCHAR(100) = NULL
		,@SpeakerTitle1 nVARCHAR(100) = NULL
		,@SpeakerPhone1 VARCHAR(20) = NULL
		,@SpeakerEmail1 nVarchar(100) = NULL
		,@SpeakerTeamLevel1 nVARCHAR(50) = NULL
		,@PK_GuestSpeaker2 INT = 0
		,@SpeakerName2 nVARCHAR(100) = NULL
		,@SpeakerTitle2 nVARCHAR(100) = NULL
		,@SpeakerPhone2 VARCHAR(20) = NULL
		,@SpeakerEmail2 nVarchar(100) = NULL
		,@SpeakerTeamLevel2 nVARCHAR(50) = NULL
		,@PK_EventImageType INT = 1 --- 1 = LOGO; 2 = BANNER;
		,@EventImageLocation nVARCHAR(4000) = NULL
		,@ModifiedBy VARCHAR(30) = 'UsrSQLProd'
		,@ApprovalNotes nVARCHAR(MAX) = NULL
		,@Comments nVARCHAR(MAX) = NULL
		,@EventVenueName nVARCHAR(250) = NULL -- Event Venue Name
		,@EventSummary nVARCHAR(MAX) = NULL -- Event Summary
		,@IsSocialNetworksEnabled BIT = 0
		,@IsPreRegistrationRequired BIT = 0
		-- Optional Parameters
		,@PK_EventGuestSpeaker1 INT = 0
		,@PK_EventGuestSpeaker2 INT = 0
		,@EventDistributorCountryLocales [udt_EventDistributorCountryLocales] READONLY
		,@EventGuestSpeakers [udt_EventGuestSpeakers] READONLY
		,@MakePublic BIT = 1 -- Make Public --> Defaulted to "Yes" always in the UI
		,@DSTeamTypes VARCHAR(1000) -- Team Level --> Semicolon separated string e.g. 'PT;MT;GT;WT;SP;'
		,@CreatedDistributorID VARCHAR(10) = NULL
		,@IsRecurring BIT = 0 -- Default 0; Will be 1 for Recurring Events only
		,@Repeat VARCHAR(1) = '' -- Default ''; Repeat Options: W - WEEKLY, M - MONTHLY, B - BIWEEKLY for Recurring Events only
		,@IsSeries BIT = 0 --By default opened in Instance, if opened in Series pass 1
		,@Latitude NUMERIC(18,10) = NULL
		,@Longitude NUMERIC(18,10) = NULL

		
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Upd_DSEvent
USE:
			DECLARE @e int, @em varchar(4000)
			declare @IsDevQA int
				
			EXEC usp_MyHLEventAPI_Upd_DSEvent
					 @Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@PK_Event = 10574
					,@LocaleCode  = 'en-US'
					,@EventName = 'Dec4 Recurring event'
					,@PK_EventSubType = '10;11;12;'
					,@CountryCode = 'US,CA,MX,'
					,@EventStartDate = '2014-12-25'
					,@EventEnddate = '2014-12-26'
					,@EventAddress = '950 W 190th Street'
					,@EventCity = 'Torrance'
					,@EventState = 'California'
					,@EventCountry = 'US'
					,@EventZipCode = '90503'
					,@EventCostDetails = '2000 Dollars per attendee'
					,@EventTrainingLanguages = ''
					,@Flyer = 'http://hlc.myherbalife.com'
					,@EventURL = 'This is website address'
					,@EventDesc = 'This Event is a DS Event and is being added only for test purposes only'
					,@PK_EventImageType =  1 
					,@EventImageLocation  = 'c:\documents\'
					,@PK_EventGuestSpeaker1 = 615
					,@PK_GuestSpeaker1 = 2
					,@SpeakerName1 = 'Alpesh Patel'
					,@PK_EventGuestSpeaker2 = 0
					,@PK_GuestSpeaker2 = 4
					,@SpeakerName2 = ''
					,@ApprovalFlag = 1
			        ,@DisplayStartDate = '2014-12-01'
		            ,@DisplayEndDate = '2015-05-01'
		  		    ,@IsActive = 1
					,@IsPublish = 1
					,@ModifiedBy = 'SandhyaP'
					,@ApprovalNotes = 'Alpesh Approves This event'
		            ,@Comments = 'Go on and go ahead with this event'
					,@EventVenueName = 'Event Venue Name'
					,@EventSummary = 'EventSummary'	
					,@IsSocialNetworksEnabled = 0
					,@IsPreRegistrationRequired = 0
					,@SpeakerPhone1 = '99999999'
					,@SpeakerEmail1 = 'abc@abc.com'
					,@SpeakerTeamLevel1 = 'DS'
					,@MakePublic = 0
					,@DSTeamTypes = 'FC;'
					,@CreatedDistributorID  = '1111111111'
					,@RecurringEventEnddate = '2015-04-30'
					,@IsRecurring = 1 
					,@Repeat = 'M' 
					,@IsSeries = 1
					,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]
					

DESCRIPTION:	Updates the respective Event record into dbo.Event, dbo.EventLocaleDesc, 
				dbo.EventCoordinator, dbo.EventURL

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.Event, dbo.EventLocaleDesc, dbo.EventCoordinator, dbo.EventURL

VERSIONS
--------------------------------------------------------------------
1	2008-12-06	           PrabhuS	              Initial
2	2013-01-16			   Sushma				Changes made for Title columns of EventGuestSpeakers 
3	2013-01-22			   Sushma				Changes made for EventVenueName, SocialNetwork, IsPreRegisteredRequired
4	2013-01-29			   Sushma				Changes made for EventSummary
5	2013-07-03			   Sushma				Target Market CR Changes
6	2014-02-14			   Sushma				Guest Speaker CR Changes
7	2014-06-10	           Sushma				Team Level Incorporation Changes
8	2015-02-12			   Sandhya				Changes made for Recurring Events
9	2019-08-14				NoeG				Refactor code (SRE)


******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON	

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @PK_EventType INT
DECLARE @PK_Locale INT
DECLARE @PK_DefaultLocale INT
DECLARE @PK_Country INT
DECLARE @ModifiedDate SMALLDATETIME
DECLARE @tbl table (PK_Event int, PK_EventSubType int, PK_EventType int)
DECLARE @Len int
DECLARE @str NVARCHAR(MAX)
DECLARE @TeamOrder INT
DECLARE @team TABLE (DSTeamTypeCode VARCHAR(3), PK_Order INT)
DECLARE @Len1 int
DECLARE @IsChildInstance BIT
DECLARE @ParentEvent INT
DECLARE @HasChild INT = 0

SELECT @PK_DefaultLocale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_Country = nCountryID FROM dbo.v_Countries WHERE sCountryCodeISO = @EventCountry
SELECT @PK_EventType = PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCODE = 'DE'
SET @ModifiedDate = GETUTCDATE()

SELECT @Error = 0, @ErrorMessage = '';

SET @EventName = LTRIM(RTRIM(@EventName))
SET @EventAddress = LTRIM(RTRIM(@EventAddress))
SET @EventCity = CASE WHEN LTRIM(RTRIM(@EventCity)) = '' THEN NULL ELSE LTRIM(RTRIM(@EventCity)) END
SET @EventState = CASE WHEN LTRIM(RTRIM(@EventState)) = '' THEN NULL ELSE LTRIM(RTRIM(@EventState)) END
SET @EventZipCode = CASE WHEN LTRIM(RTRIM(@EventZipCode)) = '' THEN NULL ELSE LTRIM(RTRIM(@EventZipCode)) END
SET @EventCountry = LTRIM(RTRIM(@EventCountry))
SET @EventCostDetails = LTRIM(RTRIM(@EventCostDetails))
SET @Flyer = LTRIM(RTRIM(@Flyer))
SET @EventDesc = LTRIM(RTRIM(@EventDesc))
SET @ApprovalNotes = LTRIM(RTRIM(@ApprovalNotes))
SET @Comments = LTRIM(RTRIM(@Comments))
SET @EventVenueName = LTRIM(RTRIM(@EventVenueName))
SET @EventSummary = LTRIM(RTRIM(@EventSummary))

/*Validate special characters for Title 1*/
--IF EXISTS (SELECT 1 WHERE REPLACE(REPLACE(REPLACE(REPLACE(@SpeakerTitle1, ',', ''), '.', ''), '-', ''), ' ', '') LIKE '%[^A-Za-z0-9]%') 
--BEGIN

--	SET @Error = 407
--	-- Update ErrorLog
--	EXEC dbo.usp_Utility_UpdateErrorLog 
--		@ProcedureName = @StoredProcedure 
--		,@ErrorNumber = @Error
--		,@ErrorMessage = @ErrorMessage OUTPUT
--	RETURN 
	
--END

/*Validate special characters for Title 2*/
--IF EXISTS (SELECT 1 WHERE REPLACE(REPLACE(REPLACE(REPLACE(@SpeakerTitle2, ',', ''), '.', ''), '-', ''), ' ', '') LIKE '%[^A-Za-z0-9]%') 
--BEGIN

--	SET @Error = 407
--	-- Update ErrorLog
--	EXEC dbo.usp_Utility_UpdateErrorLog 
--		@ProcedureName = @StoredProcedure 
--		,@ErrorNumber = @Error
--		,@ErrorMessage = @ErrorMessage OUTPUT
--	RETURN 
	
--END

/* UPDATE THE RECORD INTO EVENT TABLE */
BEGIN TRY

	UPDATE
		dbo.Event
	SET
		 [PK_EventType] = @PK_EventType
		,[dStartUTC] = @EventStartDate
		,[dEndUTC] = @EventEndDate
		,[EventName] = @EventName
		,[EventDesc] = @EventDesc
		,[EventCity] = @EventCity
		,[EventState] = @EventState
		,[EventZipCode] = @EventZipCode
		,[EventAddress] = @EventAddress
		,[EventCostDetails] = @EventCostDetails
		,[EventApprovalStatus] = @ApprovalFlag
		,[DisplayStartDate] = @DisplayStartDate
		,[DisplayEndDate] = (CASE WHEN @IsRecurring = 1 THEN @RecurringEventEnddate ELSE @DisplayEndDate END) -- IF ITS PARENT USE THE END DATE OF RECURRENCE
		,[IsActive] = @IsActive
		,[IsPublish] = @IsPublish
		,[PK_DefaultLocale] = @PK_Locale
		,[ModifiedDateUTC] = @ModifiedDate
		,[ModifiedBy] = @ModifiedBy
		,[EventVenueName] = @EventVenueName
		,[IsSocialNetworkEnabled] = @IsSocialNetworksEnabled
		,[IsPreRegistrationRequired] = @IsPreRegistrationRequired
		,[MakePublic] = @MakePublic
		,[CreatedDistributorID] = @CreatedDistributorID
		,[IsRecurring] = @IsRecurring
		,[PK_RecurrenceType] = (SELECT R.PK_RecurrenceType FROM dbo.RecurrenceType R WITH (NOLOCK) WHERE R.RecurrenceCode = @Repeat)
		,[RecurrenceEndDate] = @RecurringEventEnddate
		,[Latitude] = @Latitude
		,[Longitude] = @Longitude
	WHERE
		PK_Event = @PK_Event
	
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

/* UPDATE THE RECORD INTO EVENTLOCALEDESC TABLE */
BEGIN TRY
	UPDATE 
		dbo.EventLocaleDesc
	SET
		 [PK_EventType] = @PK_EventType
		,[EventName] = @EventName
		,[EventDesc] = @EventDesc
		,[EventAddress] = @EventAddress
		,[EventCity] = @EventCity
		,[EventState] = @EventState
		,[EventCostDetails] = @EventCostDetails
		,[EventTrainingLanguages] = @EventTrainingLanguages
		,[EventDisplayAddress] = @EventDisplayAddress
		,[PK_DefaultLocale] = @PK_DefaultLocale
		,[PK_Locale] = @PK_Locale
		,[ModifiedDateUTC] = @ModifiedDate
		,[ModifiedBy] = @ModifiedBy
		,[EventApprovalNotes] = @ApprovalNotes
		,[EventComments] = @Comments
		,[EventSummary] = @EventSummary
	WHERE
		PK_Event = @PK_Event

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

/* UPDATE THE RECORD INTO EVENTURL TABLE */

BEGIN TRY
	UPDATE 
		dbo.EventURL
	SET
		 [EventURL] = @EventURL
		,[PK_Locale] = @PK_Locale
		,[Flyer] = @Flyer
		,[ModifiedDateUTC] = @ModifiedDate
		,[ModifiedBy] = @ModifiedBy
	WHERE
		 PK_Event = @PK_Event
	 
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

/* UPDATE THE RECORD INTO EVENTCOUNTRY TABLE */

BEGIN TRY

	UPDATE 
		dbo.EventCountry
	SET
		 PK_Country = @PK_Country
		,ModifiedDateUTC = @ModifiedDate
	WHERE
		PK_Event = @PK_Event

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

BEGIN TRY
	/* UPDATE THE EXISTING RECORD IN THE EVENTIMAGE */
	UPDATE
		dbo.EventImage
	SET
		[EventImageLocation] = @EventImageLocation
		,[PK_EventImageType] = @PK_EventImageType
		,[ModifiedDateUTC] = @StartTime
		,[ModifiedBy] = @ModifiedBy
	WHERE
		PK_Event = @PK_Event
	
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

BEGIN TRY
	/* INSERT/UPDATE THE SPEAKERS  */

	DELETE EGS
	FROM 
		dbo.EventGuestSpeakers EGS
	LEFT JOIN 
		@EventGuestSpeakers E
	ON 
		EGS.PK_EventGuestSpeaker = E.PK_EventGuestSpeaker
	WHERE 
		E.PK_EventGuestSpeaker IS NULL 
	AND 
		EGS.PK_Event = @PK_Event


	MERGE dbo.EventGuestSpeakers EGS
	USING
	(
		 SELECT E.PK_GuestSpeaker, E.PK_EventGuestSpeaker, E.EventSpeakerName, @StartTime [StartTime]
		,@ModifiedBy [ModifiedBy], E.PK_Event, E.EventSpeakerTitle
		,E.EventSpeakerPhone, E.EventSpeakerEmail, E.EventSpeakerTeamLevel 
		FROM @EventGuestSpeakers E
		WHERE COALESCE(E.EventSpeakerName, '') != ''
	) AS E
	ON EGS.PK_Event = E.[PK_Event]
	AND EGS.PK_EventGuestSpeaker = E.PK_EventGuestSpeaker

	WHEN NOT MATCHED THEN INSERT (PK_GuestSpeaker,EventSpeakerName,ModifiedDateUTC,ModifiedBy, PK_Event, EventSpeakerTitle,EventSpeakerPhone,EventSpeakerEmail,EventSpeakerTeamLevel)
		VALUES(E.PK_GuestSpeaker,E.EventSpeakerName,E.[StartTime],E.ModifiedBy, E.PK_Event,E.EventSpeakerTitle,E.EventSpeakerPhone,E.EventSpeakerEmail,E.EventSpeakerTeamLevel)

	WHEN MATCHED THEN UPDATE SET
		 [EventSpeakerName] = E.[EventSpeakerName]
		,[EventSpeakerTitle] = E.[EventSpeakerTitle]
		,[EventSpeakerPhone]= E.[EventSpeakerPhone]
		,[EventSpeakerEmail] = E.[EventSpeakerEmail]
		,[EventSpeakerTeamLevel] = E.[EventSpeakerTeamLevel]
		,[ModifiedDateUTC] = E.[StartTime]
		,[ModifiedBy] = E.[ModifiedBy]
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
	RETURN 
END CATCH

/******************************************************************************
	INSERT INTO EVENTEVENTSUBTYPE TABLE
******************************************************************************/
SET @Len = LEN(@PK_EventSubType)

WHILE @Len > 0
BEGIN
	INSERT @tbl (PK_EventSubType) SELECT LEFT(@PK_EventSubType, CHARINDEX(';',@PK_EventSubType)-1)
	SET @PK_EventSubType = REPLACE(@PK_EventSubType,LEFT(@PK_EventSubType, CHARINDEX(';',@PK_EventSubType)),'')
	SET @Len = LEN(@PK_EventSubType)
END

UPDATE
	@tbl
SET
	PK_Event = @PK_Event
	,PK_EventType = L.PK_EventType
FROM
	@tbl T
INNER JOIN
	dbo.EventSubTypes L WITH (NOLOCK)
	ON
		T.PK_EventSubType = L.PK_EventSubType

/*******  parse @PK_EventSubType *********/

DELETE EST
FROM
	dbo.EventEventSubType EST
INNER JOIN
	@tbl T
ON 
	EST.PK_Event = T.PK_Event
	

INSERT dbo.EventEventSubType(
	PK_Event
	,PK_EventType
	,PK_EventSubType
)
SELECT 
	T.PK_Event
	,T.PK_EventType
	,T.PK_EventSubType
FROM
	@tbl T	
/*EventDistributorCountry Update*/
BEGIN TRY
	BEGIN

	DELETE FROM dbo.EventDistributorCountry WHERE PK_Event = @PK_Event

	INSERT INTO dbo.EventDistributorCountry
	  (PK_Event, PK_Country)
	 SELECT 
		DISTINCT @PK_Event, nCountryID
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
	RETURN 
END CATCH
	
/*EventDistributorCountryLocales Update*/
BEGIN TRY
	BEGIN

	IF EXISTS(SELECT 1 FROM EventDistributorCountryLocales WITH (NOLOCK) WHERE PK_Event = @PK_Event)
	DELETE FROM EventDistributorCountryLocales WHERE PK_Event = @PK_Event

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
	RETURN 
END CATCH

/******************************************************************************
	INSERT INTO EventDSTeamType TABLE
******************************************************************************/
	
SET @Len1 = LEN(@DSTeamTypes)

WHILE @Len1 > 0
BEGIN
	INSERT @team(DSTeamTypeCode) SELECT LEFT(@DSTeamTypes, CHARINDEX(';',@DSTeamTypes)-1)
	SET @DSTeamTypes = SUBSTRING(@DSTeamTypes, CHARINDEX(';',@DSTeamTypes)+1, LEN(@DSTeamTypes))
	SET @Len1 = LEN(@DSTeamTypes)
END

UPDATE 
	T
SET
	PK_Order = DT.TeamOrder
FROM
	@team T
INNER JOIN
	dbo.DSTeamType DT WITH (NOLOCK)
ON
	T.DSTeamTypeCode = DT.DSTeamTypeCode

SELECT @TeamOrder = MAX(PK_Order) FROM @team	

DELETE EDT
FROM 
	EventDSteamType EDT
WHERE
	EDT.PK_Event = @PK_Event

BEGIN TRY

	INSERT 
		dbo.EventDSteamType
	(
		 DSTeamTypeCode
		,PK_Event
		,CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
	)
	SELECT
		 DT.DSteamTypeCode
		,@PK_Event
		,GETUTCDATE()
		,@ModifiedBy
		,GETUTCDATE()
		,@ModifiedBy
	FROM
		dbo.DSTeamType DT WITH (NOLOCK)
	WHERE
		DT.TeamOrder <=@TeamOrder
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

SELECT @IsChildInstance = CASE WHEN E.PK_OldEventApp IS NOT NULL THEN 1 ELSE 0 END 
FROM
	dbo.Event E WITH (NOLOCK) 
WHERE 
	E.PK_Event = @PK_Event
	
IF @IsChildInstance = 0 AND @IsRecurring = 1
BEGIN
	SELECT @HasChild = CASE WHEN COUNT(0) > 0 THEN 1 ELSE 0 END	--ONLY IF THE EVENT INSTANCES ARE ALREADY CREATED UPDATE THEM
	FROM dbo.Event E WITH (NOLOCK)
	WHERE E.PK_OldEventApp = @PK_Event
END

IF 
(@IsChildInstance = 1 AND (@IsSeries = 1 
OR @IsRecurring = 1) AND
(
			(@ApprovalFlag = 0 -- 'Under review' incase of MyHL
			OR (@ApprovalFlag = 1 and @IsPublish = 1 AND @IsActive = 1) -- 'Approve' Incase of Admin
			OR (@ApprovalFlag = 2) -- 'Reject' incase of Admin
			OR (@ApprovalFlag = 3) -- 'Saved as Draft' incase of Admin
			OR (@ApprovalFlag = 5) -- 'Inactive' incase of MyHL
	)
))
OR 
(@IsChildInstance = 0 and @IsRecurring = 1 and
	(@ApprovalFlag = 0 OR (@ApprovalFlag = 1 and @IsPublish = 1 AND @IsActive = 1) OR @ApprovalFlag = 2 OR (@ApprovalFlag = 3 AND @HasChild = 1) OR @ApprovalFlag = 5)) -- for parent event update
BEGIN

/* Get the Recurrence Info in case of parent/child event  */
SELECT   @RecurringEventEnddate = COALESCE(PE.RecurrenceEndDate, E.RecurrenceEndDate)
		,@Repeat = RT.RecurrenceCode
		,@ParentEvent = COALESCE(PE.PK_Event, E.PK_Event)
FROM
	dbo.Event E WITH (NOLOCK)
LEFT JOIN
	dbo.Event PE WITH (NOLOCK)
	ON
		E.PK_OldEventApp = PE.PK_Event 
LEFT JOIN
	dbo.RecurrenceType RT WITH (NOLOCK)
	ON
	RT.PK_RecurrenceType = COALESCE(PE.PK_RecurrenceType, E.PK_RecurrenceType)
WHERE 
		E.PK_Event = @PK_Event	

/* Update Status first for ParentID when Event is opened in Series */

/* Retain the Status for ParentID only if it is saved as draft and has no children */
IF @IsChildInstance = 0 AND @IsRecurring = 1 
BEGIN
	UPDATE
		dbo.Event
	SET
		 [EventApprovalStatus] = CASE WHEN @ApprovalFlag = 3 THEN 3 ELSE [EventApprovalStatus] END
		,[ModifiedDateUTC] = @ModifiedDate
		,[ModifiedBy] = @ModifiedBy
	WHERE
		PK_Event = @ParentEvent
		
	SELECT @EventEnddate = E.dEndUTC
	FROM dbo.Event E WITH (NOLOCK) 
	WHERE E.PK_OldEventApp = @ParentEvent
	AND E.dStartUTC = @EventStartDate
END

/* Below SP call will update the status for all active child instances through the event id passed*/
Declare @e int, @em varchar(200)
EXEC dbo.usp_MyHLEventAPI_Upd_DSEventInstances
	 @ModifiedBy = @ModifiedBy
	,@PK_Event = @PK_Event
	,@LocaleCode = @LocaleCode
	,@DistributorID = @CreatedDistributorID
	,@StartDate = @EventStartDate
	,@EndDate = @EventEnddate
	,@EventEndDate = @RecurringEventEnddate
	,@ParentEvent = @ParentEvent
	,@Repeat = @Repeat
	,@Error = @e OUTPUT  /* @e must be defined in the local call */
	,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */

END

-- UPDATE PROCESSING LOG
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime
	
	
	

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
GO

