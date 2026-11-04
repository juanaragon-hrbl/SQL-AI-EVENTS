CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Ins_DSEvent]
        --Mandatory Parameters
		 @LocaleCode CHAR(5)
		,@EventName nVARCHAR(250)
		,@PK_EventSubType varchar(100) -- This is a semicolon separated value and end with a semi colon e.g.'1;2;3;4;' 
		,@CountryCode nVARCHAR(MAX)-- (Select Eligible Countries) --> Comma separated string e.g. 'US,MX,JM,CA,'	
		,@EventStartDate SMALLDATETIME 
		,@EventEnddate SMALLDATETIME
		,@RecurringEventEnddate SMALLDATETIME = NULL -- This is the End Date for Recurring Events
		,@EventAddress nVARCHAR(500)
		,@EventCity nVARCHAR(250)
		,@EventState nVARCHAR(200)
		,@EventCountry CHAR(2)
		,@EventZipCode nVARCHAR(20)
		,@ApprovalFlag INT --TO BE PASSED FROM FRONT END---> 0 = Under review; 1 = Approved; 2 = Rejected; 3 = Saved as Draft
		,@DisplayStartDate DATETIME --> If not selected by the user then we need the default value passed
		,@DisplayEndDate DATETIME --> If not selected by the user then we need the default value passed
		,@IsActive BIT = 1 --> Will be defaulted to 1 unless otherwise specified by the UI
		,@IsPublish BIT = 0 --> Will be defaulted to 0 unless otherwise specified by the UI
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
		,@EventDistributorCountryLocales [udt_EventDistributorCountryLocales] READONLY	
		,@EventGuestSpeakers [udt_EventGuestSpeakers] READONLY
		,@MakePublic BIT = 1 -- Make Public --> Defaulted to "Yes" always in the UI
		,@DSTeamTypes VARCHAR(1000) -- Team Level --> Semicolon separated string e.g. 'PT;MT;GT;WT;SP;'
		,@CreatedDistributorID VARCHAR(10) = NULL
		,@IsRecurring BIT = 0 -- Default 0; Will be 1 for Recurring Events only
		,@Repeat VARCHAR(1) = '' -- Default ''; Repeat Options: W - WEEKLY, M - MONTHLY, B - BIWEEKLY for Recurring Events only
		,@Latitude NUMERIC(18,10) = NULL
		,@Longitude NUMERIC(18,10) = NULL
		-- Output Parameter
	    ,@PK_Event INT OUTPUT
		
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN	

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Ins_DSEvent
USE:
			DECLARE @e int, @em varchar(4000)
			declare @EventID INT
			declare @IsDevQA int
						
			EXEC [usp_MyHLEventAPI_Ins_DSEvent]
			@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@PK_EventSubType = '10;11;12;'
					,@CountryCode = 'US,CA,MX,JM,'
					,@PK_Event = @EventID OUTPUT /* @EventID must be defined in the local call */
					,@LocaleCode  = 'en-US'
					,@EventName = 'Sandhya Recurring Event'
					,@EventStartDate = '2014-12-24 01:07:00'
					,@EventEnddate = '2014-12-26 23:29:00'
					,@RecurringEventEndDate = '2015-02-19'
					,@EventAddress = '17200 Canoga Ave'
					,@EventCity = 'Canoga Park'
					,@EventState = 'California'
					,@EventCountry = 'US'
					,@EventZipCode = '91316'
					,@EventDisplayAddress = ''
					,@EventTrainingLanguages = ''
					,@EventCostDetails = '1000 Dollars per attendee'
					,@Flyer = 'http://hlc.myherbalife.com'
					,@EventURL = 'Test URL'
					,@EventDesc = 'This Event is a DS Event and is being added only for test purposes only'
					,@PK_GuestSpeaker1 = 12
					,@PK_GuestSpeaker2 = 10
					,@SpeakerName1 = 'Tom Zimmer'
					,@SpeakerTitle1 = 'Title1'
					,@SpeakerName2 = 'Bill Rahn'
					,@PK_EventImageType = 1
					,@EventImageLocation = ''
					,@ModifiedBy = 'SandhyaP'
					,@ApprovalFlag = 0
			        ,@DisplayStartDate = '12-01-2010'
		            ,@DisplayEndDate = '12-01-2011'
		           	,@IsActive = 1 
		            ,@IsPublish = 0
				    ,@ApprovalNotes = NULL
		            ,@Comments = NULL
					,@IsDevQA = 0
					,@EventVenueName = 'Canoga Ave'
					,@EventSummary = 'Summary'
					,@IsSocialNetworksEnabled = 0
					,@IsPreRegistrationRequired = 0
					,@SpeakerTeamLevel1 = 'DS'
					,@MakePublic = 0
					,@DSTeamTypes = 'DS;'
					,@CreatedDistributorID = '1111111111'
					,@IsRecurring = 0
					,@Repeat = 'b'

			SELECT @e AS [Error], @em AS [Error Message]
					
DESCRIPTION:	Inserts record into dbo.Event, dbo.EventLocaleDesc, dbo.EventEventSubType, 
                dbo.EventURL, dbo.EventCountry, dbo.EventGuestSpeakers, dbo.EventDSTeamType

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.Event, dbo.EventLocaleDesc, dbo.EventEventSubType, dbo.EventURL, dbo.EventCountry, dbo.EventGuestSpeakers 

VERSIONS
--------------------------------------------------------------------
1	2010-12-01	PrabhuS	Initial
2	2013-01-16	Sushma	Changes made for Title columns of EventGuestSpeakers
3	2013-01-22	Sushma	Changes made for EventVenueName, SocialNetwork
4	2013-01-29	Sushma	Changes made for EventSummary
5	2013-01-30	Sushma	Changes made for EventDistributorCountry
6	2013-07-03	Sushma	Target Market CR Changes
7	2013-08-19	Sushma	Manage Tab CR Changes
8	2014-02-14	Sushma	Guest Speaker CR Changes
9	2014-06-10	Sushma	Team Level Incorporation Changes
10	2015-02-12	Sandhya	Changes made for Recurring Events
11	2019-08-14	NoeG	Refactor code (SRE)
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
DECLARE @tbl table (PK_Event int, PK_EventSubType int, PK_EventType int)
DECLARE @Len int
DECLARE @TeamOrder INT
DECLARE @str NVARCHAR(MAX)
DECLARE @team TABLE (DSTeamTypeCode VARCHAR(5), PK_Order INT)
DECLARE @Len1 int

SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_DefaultLocale = PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode = @LocaleCode
SELECT @PK_EventType = PK_EventType FROM dbo.EventType WITH(NOLOCK) WHERE EventTypeCode = 'DE'
--SET @EventImage = (SELECT <all> FROM OPENROWSET(BULK N'C:\Image.gif', SINGLE_BLOB))
SELECT @TeamOrder = MAX(TeamOrder) FROM dbo.DSTeamType WITH(NOLOCK)

SELECT @Error = 0, @ErrorMessage = '';
SET @EventName = LTRIM(RTRIM(@EventName))
SET @EventAddress = LTRIM(RTRIM(@EventAddress))
SET @EventCity = CASE WHEN LTRIM(RTRIM(@EventCity)) = '' THEN NULL ELSE LTRIM(RTRIM(@EventCity)) END
SET @EventState = CASE WHEN LTRIM(RTRIM(@EventState)) = '' THEN NULL ELSE LTRIM(RTRIM(@EventState)) END
SET @EventZipCode = CASE WHEN LTRIM(RTRIM(@EventZipCode)) = '' THEN NULL ELSE LTRIM(RTRIM(@EventZipCode)) END
SET @EventCountry = LTRIM(RTRIM(@EventCountry))
SET @EventCostDetails = LTRIM(RTRIM(@EventCostDetails))
SET @Flyer = LTRIM(RTRIM(@Flyer))
SET @EventURL = LTRIM(RTRIM(@EventURL))
SET @EventDisplayAddress = LTRIM(RTRIM(@EventDisplayAddress))
SET @EventDesc = LTRIM(RTRIM(@EventDesc))
SET @ApprovalNotes = LTRIM(RTRIM(@ApprovalNotes))
SET @Comments = LTRIM(RTRIM(@Comments))
SET @EventVenueName = LTRIM(RTRIM(@EventVenueName))
SET @EventSummary = LTRIM(RTRIM(@EventSummary))

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
	dbo.DSTeamType DT WITH(NOLOCK)
ON
	T.DSTeamTypeCode = DT.DSTeamTypeCode

SELECT @TeamOrder = MAX(PK_Order) FROM @team

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

/* INSERT THE RECORD INTO EVENT TABLE */
BEGIN TRY

	INSERT 
		dbo.Event
	(
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
	)
	SELECT
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
		,0
		,0
		,@IsPreRegistrationRequired
		,0
		,0
		,0
		,@MakePublic
		,@IsActive
		,@IsPublish
		,0
		,0
		,0
		,@PK_DefaultLocale
		,@DisplayStartDate
		,(CASE WHEN @IsRecurring = 1 THEN @RecurringEventEnddate ELSE @DisplayEndDate END) -- IF ITS PARENT USE THE END DATE OF RECURRENCE
		,@ModifiedBy
		,@ModifiedBy
		,@EventVenueName
		,@IsSocialNetworksEnabled
		,@CreatedDistributorID
		,@IsRecurring
		,(SELECT R.PK_RecurrenceType FROM dbo.RecurrenceType R WITH(NOLOCK) WHERE R.RecurrenceCode = @Repeat)
		,@RecurringEventEnddate
		,@Latitude
		,@Longitude
	
	SET @PK_Event = @@Identity

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
		 @PK_Event
		,@PK_EventType
		,@PK_Locale
		,@PK_DefaultLocale
		,@EventName
		,@EventDesc
		,@EventAddress
		,@EventCity
		,@EventState
		,@EventDisplayAddress
		,@EventCostDetails	
		,@EventTrainingLanguages
		,@ModifiedBy
		,@ModifiedBy
		,@ApprovalNotes
		,@Comments
		,@EventSummary
	
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

/* INSERT THE RECORD INTO EVENTURL TABLE */

BEGIN TRY
	INSERT 
		dbo.EventURL
	(
		 [PK_Event]
		,[PK_Locale]
		,[EventURL]
		,[Flyer]
	)
	SELECT
		 @PK_Event
		,@PK_Locale
		,@EventURL
		,@Flyer

	
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

/* INSERT THE RECORD INTO EVENTCOUNTRY TABLE */
BEGIN TRY
	INSERT 
		dbo.EventCountry
	(
		 [PK_Event]
		,[PK_Country]
	)
	SELECT
		 @PK_Event
		,C.nCountryID
	FROM
		dbo.v_Countries C
	WHERE
		C.sCountryCodeISO = @EventCountry

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


/* INSERT THE RECORD INTO EVENTGUESTSPEAKERS TABLE ONLY IF A RECORD FOR THE EVENT DOES NOT EXIST */
BEGIN
BEGIN TRY

	IF EXISTS(SELECT 1 FROM @EventGuestSpeakers E WHERE E.PK_GuestSpeaker = 0 and E.EventSpeakerName IS NOT NULL)
	BEGIN

		INSERT 
			dbo.TempGuestSpeakers
		(
			 TempSpeakerName
			,CreatedDateUTC
			,ModifiedDateUTC
		)
		SELECT DISTINCT
			 E.EventSpeakerName
			,@StartTime
			,@ModifiedBy
		FROM 
			@EventGuestSpeakers E
		WHERE 
			E.PK_GuestSpeaker = 0 
		AND 
			E.EventSpeakerName IS NOT NULL
		AND
			E.EventSpeakerName NOT IN (SELECT TempSpeakerName FROM TempGuestSpeakers WHERE TempSpeakerName IS NOT NULL)

	END	

	INSERT INTO dbo.EventGuestSpeakers
	  (	
		PK_GuestSpeaker, 
		EventSpeakerName, 
		CreatedDateUTC, 
		CreatedBy, 
		ModifiedDateUTC, 
		ModifiedBy, 
		PK_Event, 
		EventSpeakerTitle, 
		EventSpeakerPhone, 
		EventSpeakerEmail, 
		EventSpeakerTeamLevel
	   )
	 SELECT 
		 TGS.PK_TempGuestSpeaker
		,E.EventSpeakerName
		,@StartTime
		,@ModifiedBy
		,@StartTime
		,@ModifiedBy
		,@PK_Event
		,E.EventSpeakerTitle
		,E.EventSpeakerPhone
		,E.EventSpeakerEmail
		,E.EventSpeakerTeamLevel	
	 FROM 
		@EventGuestSpeakers E
	 LEFT JOIN
		dbo.TempGuestSpeakers TGS WITH(NOLOCK)
	 ON
		E.EventSpeakerName = TGS.TempSpeakerName
	 WHERE 
		COALESCE(E.EventSpeakerName, '') != ''
	
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
END

BEGIN
/* INSERT THE RECORD INTO EVENTIMAGE TABLE */
BEGIN TRY

	INSERT INTO [dbo].[EventImage]
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
	RETURN 
END CATCH
END

/******************************************************************************
	INSERT INTO EVENTDSTeamType TABLE
******************************************************************************/
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
	dbo.DSTeamType DT WITH(NOLOCK)
WHERE
	DT.TeamOrder <=@TeamOrder

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
	dbo.EventSubTypes L WITH(NOLOCK)
	ON
		T.PK_EventSubType = L.PK_EventSubType

/*******  INSERT INTO dbo.EVentEventSubType Table *********/

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
	,@PK_EventType
	,T.PK_EventSubType
	,@StartTime
	,@ModifiedBy
	,@StartTime
	,@ModifiedBy
FROM
	@tbl T
/* Insert the record into EventDistributorCountry TABLE */

BEGIN TRY

	 INSERT INTO dbo.EventDistributorCountry
	  (CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_Event, PK_Country)
	 SELECT 
		DISTINCT @StartTime, @ModifiedBy, @StartTime, @ModifiedBy, @PK_Event, C.nCountryID
	 FROM 
		@EventDistributorCountryLocales E
	 INNER JOIN
		dbo.Locales L WITH(NOLOCK) ON E.PK_Locale = L.PK_Locale
	 INNER JOIN
		dbo.v_Countries C WITH(NOLOCK) 
	 ON 
		sCountryCodeISO = SUBSTRING(L.LocaleCode, 4, 2)
	 WHERE
		NOT EXISTS(SELECT 1 FROM dbo.EventDistributorCountry EDC WITH(NOLOCK) WHERE EDC.PK_Event = @PK_Event and EDC.PK_Country = C.nCountryID)

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
	
/*Insert target locales*/	

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
		NOT EXISTS(SELECT 1 FROM EventDistributorCountryLocales DS WITH(NOLOCK) WHERE DS.PK_Event = @PK_Event AND DS.PK_Locale = E.PK_Locale)


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

/* For recurring Events create the Instance records (child records) */	
-- If User clicks 'Submit' then EventStatus (@ApprovalFlag) passed as 'Under Review' (0) and instances are created
-- If User clicks 'Save' then EventStatus (@ApprovalFlag) passed as 'Saved As Draft' (3) and instances ARE NOT created

IF @IsRecurring = 1 AND 
(	@ApprovalFlag = 0 --incase of MyHL
	OR (@ApprovalFlag = 1 and @IsPublish = 1 AND @IsActive = 1) --Incase of Admin
)
BEGIN

	Declare @e int, @em varchar(200)
	EXEC dbo.usp_MyHLEventAPI_Ins_DSEventInstances
		 @ModifiedBy = @ModifiedBy
		,@PK_Event = @PK_Event
		,@LocaleCode = @LocaleCode
		,@DistributorID = @CreatedDistributorID
		,@StartDate = @EventStartDate
		,@EndDate = @EventEnddate
		,@EventEndDate = @RecurringEventEnddate
		,@Repeat = @Repeat
		,@Error = @e OUTPUT  /* @e must be defined in the local call */
		,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */


END

	
/* RETURN THE NEW EVENT CREATED */

SELECT @PK_Event PK_Event


-- UPDATE PROCESSING LOG
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime
	

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
GO

