CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_SearchEvents]
				-- Mandatory Parameters
				  @UserID VARCHAR(30) -- Pass the UserID value to perform actions based on the user access level.
				 ,@SearchByEvent INT  -- Pass 1 if it is "Search By Event" option is selcted in the UI and 0 if it is Advanced Search Options
				 ,@Status VARCHAR(20)-- Status field in the UI; If ALL is opted, then the status will be passed as '0;1;2;3;4;5;' FROM "Event ADMIN". If it is from MY HL then always pass NULL
				 ,@LocaleCode CHAR(5) = NULL-- This is a mandatory field from MY HL and optional from Events Manager 
				 ,@PK_EventType VARCHAR(10) -- Atleast 1 value have to be passed ----> e.g. '1,2,3,'
				 ,@TargetLocales udt_EventDistributorCountryLocales READONLY -- Search Events by their Target Locale
				-- Optional Parameters	
				 ,@PK_Event INT	= NULL -- If "Search by EventID" is opted, then this should be returned a value
				 ,@DistributorID VARCHAR(10)= NULL -- DistributorID	
				 ,@StartDate DATETIME = NULL -- "Date From" field maps to to this field. If "AllDates" is checked on frontend StartDate & EndDate will not be passed.
				 ,@Enddate DATETIME = NULL -- "Date To" field maps to to this field. If "AllDates" is checked on frontend StartDate & EndDate will not be passed.
				 ,@EventCity nVARCHAR(100) = NULL -- This field is a freeform text field and maps to EventCity from Event table.
				 ,@EventState nVARCHAR(100) = NULL -- This field is a freeform text field and maps to EventState from Event table.	 
				 ,@CountryCode CHAR(3) = NULL -- Region/Country Code field maps to this field 
				 ,@PostalCode nVARCHAR(20) = NULL -- Zip/Postal Code maps to this field
				 ,@Miles MONEY = 50 -- If from the drop down they select Kilometers, then the conversion from Kilometers to Miles should happen at the UI; (1 KM = 0.62137 miles)
				 ,@EventSubType nVARCHAR(400) = NULL -- If "All" is opted from the drop down in UI please pass NULL else pass the right SubTypeCode
				 ,@DSTeamType VARCHAR(100) = NULL -- Mandatory on MY HL and optional on Events Manager
				 --,@KeyWords nVARCHAR(4000) = NULL --Corresponds to Keywords text field in the wireframe
				 ,@IsActive BIT = 1 -- This parameter maps to "Include Inactive Records" in the UI; Pass 0 when the check box is selected
				 ,@IsPublic BIT = 0 -- This flag will be sent to return the event results that are based on the IsPublic Flag. By default it is set to 0
		
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_SearchEvents

USE:

			DECLARE @e int, @em varchar(4000)
				Declare @Locales_UDT udt_EventDistributorCountryLocales
				INSERT INTO @Locales_UDT VALUES (77,1),(46,0)

                 EXEC dbo.usp_MyHLEventAPI_SearchEvents

							-- Mandatory Parameters
							 @UserID = 'SandhyaP'
							 ,@SearchByEvent = 0
							 ,@PK_Event = 0
							 ,@Status = '0;1;2;3;4;5;'
							 ,@LocaleCode = 'en-US'
							 ,@PK_EventType = '1,2,3,'
							 ,@StartDate = '2018-11-01'
							 ,@Enddate = '2019-04-01'
							 ,@TargetLocales = @Locales_UDT
							 
							-- Optional Parameters	
							 
							 ,@DistributorID = NULL
							 ,@CountryCode = NULL
							 ,@PostalCode = NULL
							 ,@Miles = NULL
							 --,@PK_EventSubType = NULL
							 ,@DSTeamType = NULL
							 --,@KeyWords = NULL
							 ,@IsActive = 0
							 ,@IsPublic = 0
							 
							-- Error Parameters
							 ,@Error = @e OUTPUT
							 ,@ErrorMessage = @em OUTPUT
							,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves all the events based on the input search criteria

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------


VERSIONS
----------------------------------------------------------------------------------
1.0.0	2011-01-17		Prabhu				Intitial
1.1.0	2011-01-31		Prabhu & Sandhya	Next version
1.2.0   2012-09-06		Sandhya             Added optional parameters EventCity & EventState. When "AllDates" checkbox is on, StartDate & EndDate will be blank values and they will be Optional parameters 
1.3.0   2013-02-28		Sandhya             Added IsPreRegistrationrequired, HasQualifications, HasAccess fields to the select, added @UserID parameter & exclude the events that are marked as deleted
1.4.0	2013-07-01		Juan				Added Target Locales Search 
1.5.0	2013-10-24		Juan				Added Details for Monthly View. (Guest,Coordinator and Available Translations)
1.6.0	2015-02-12		Sandhya				Changes made for Recurring Events
1.7.0	2019-02-14		SandhyaP/MiguelF    Rewrite the code to resolve performance issue and fix duplicates
1.8.0	2019-08-14		NoeG				Refactor code (SRE)
1.9.0   2019-10-17      puertac				SRE Implementation 
1.10.0  2019-10-17      puertac				SRE Implementation - Hardcode Review 
1.11.0  2021-06-03		puertac				BUG 608581 : Team Level not display in Admin - Search Events
1.11.1	2021-07-22		puertac				BUG 718089 : Events Admin Tool - Search by ID is not retrieving information  	
											+ Default DSTeamTypeCode to DS when MakePublic = 1
1.11.2	2023-05-30		puertac				BUG 1189794 - Search Country-Audience-Team Level-State-City-Event Type - Region issue
1.11.3	2023-05-31		puertac				BUG 1261843 - Display Event when team level is not selected for example GET2500
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	/* DECLARE THE LOCAL PARAMETERS */
	DECLARE @Postal_Latitude FLOAT
	DECLARE @Postal_Longitude FLOAT 
	DECLARE @PK_Locale INT
	DECLARE @PK_Country INT
	DECLARE @PK_DefaultLocale INT
	DECLARE @Len INT
	DECLARE @Len1 INT
	DECLARE @tbl TABLE(PK_EventType INT)
	DECLARE @Stbl TABLE([Status] INT)
	DECLARE @IsMyHL INT = 0
	DECLARE @HasQualifications INT
	DECLARE @HasAccess INT
	DECLARE @Subtbl TABLE(PK_EventSubType INT)
	DECLARE @SearchByPostalCodeOnly BIT

	DECLARE @Distance FLOAT = 57.2958
			,@Distance2 INT  = 3963



	IF OBJECT_ID ('tempdb..#SearchResults') IS NOT NULL
		DROP TABLE #SearchResults


	CREATE TABLE #SearchResults 
	(
	PK_Event	int	
	,EventName	nvarchar (1000)
	,EventDate	nvarchar(43)
	,EventStartDate	smalldatetime	
	,EventEndDate	smalldatetime
	,PK_EventType	int	
	,PK_EventSubType	int	
	,EventSubType	nvarchar(400)
	,EventVenueName	nvarchar (400)
	,EventDisplayAddress	nvarchar (MAX)
	,DSTeamTypeCode	varchar	(5)
	,DSTeamTypeDesc	nvarchar (4000)
	,EventAddress	nvarchar (2000)
	,EventCity	nvarchar	(500)
	,EventState	nvarchar	(500)
	,EventZipCode	varchar	(10)
	,EventCountry	varchar	(2)
	,EventCountryName	varchar	(200)
	,EventImageType	int	
	,EventImageLocation	nvarchar (MAX)
	,EventDesc	nvarchar(MAX)
	,[STATUS]	int	
	,DisplayStartDate	datetime
	,DisplayEndDate	datetime
	,IsActive	bit	
	,CreatedDate	datetime	
	,LastUpdatedDate	datetime
	,LastUpdatedBy	varchar	(50)
	,LocaleCode	varchar		(5)
	,IsPublish	bit	
	,IsPublic	bit	
	,IsPreRegistrationRequired	bit	
	,HasAccess	int
	,HasQualifications	int
	,PK_OldEventAPP INT
	,IsRecurring BIT
	,Latitude NUMERIC(18,10)
	,Longitude NUMERIC(18,10)
	)

	IF OBJECT_ID ('tempdb..#FinalResults') IS NOT NULL
		DROP TABLE #FinalResults
	
	CREATE TABLE #FinalResults 
	(
	 PK_Event	int	
	,EventName	nvarchar (1000)
	,EventDate	nvarchar(43)
	,EventStartDate	smalldatetime	
	,EventEndDate	smalldatetime
	,PK_EventType	int	
	,PK_EventSubType	int	
	,EventSubType	nvarchar(400)
	,EventVenueName	nvarchar (400)
	,EventDisplayAddress	nvarchar (MAX)
	,DSTeamTypeCode	varchar	(5)
	,DSTeamTypeDesc	nvarchar (4000)
	,EventAddress	nvarchar (2000)
	,EventCity	nvarchar	(500)
	,EventState	nvarchar	(500)
	,EventZipCode	varchar	(10)
	,EventCountry	varchar	(2)
	,EventCountryName	varchar	(200)
	,EventImageType	int	
	,EventImageLocation	nvarchar (MAX)
	,EventDesc	nvarchar(MAX)
	,[STATUS]	int	
	,DisplayStartDate	datetime
	,DisplayEndDate	datetime
	,IsActive	bit	
	,CreatedDate	datetime	
	,LastUpdatedDate	datetime
	,LastUpdatedBy	varchar	(50)
	,LocaleCode	varchar		(5)
	,IsPublish	bit	
	,IsPublic	bit	
	,IsPreRegistrationRequired	bit	
	,HasAccess	int
	,HasQualifications	int
	,PK_OldEventAPP INT
	,IsRecurring BIT
	,Latitude NUMERIC(18,10)
	,Longitude NUMERIC(18,10)
	)

	IF OBJECT_ID ('tempdb..#EventImage') IS NOT NULL
		DROP TABLE #EventImage

	--New table for EventImage subquery 
	CREATE TABLE #EventImage (
		PK_Event int,
		EventImageLocation nvarchar(max),
		PK_EventImageType int,
		RowNo int
	)

	CREATE NONCLUSTERED INDEX [IXT_EventImage_RowNo]
		ON #EventImage ([PK_Event], [RowNo])
		INCLUDE ([EventImageLocation],[PK_EventImageType])

	IF OBJECT_ID ('tempdb..#DSTeamType') IS NOT NULL
		DROP TABLE #DSTeamType

	--New table for DSTeamType subquery
	CREATE TABLE #DSTeamType (
		PK_Event int,
		DSTeamTypeCode varchar(5),
		TeamOrder int,
		DSTeamTypeDesc nvarchar(4000)
	)

	CREATE NONCLUSTERED INDEX [IXT_DSTeamType_PK_Event]
		ON #DSTeamType ([PK_Event])
		INCLUDE ([DSteamTypeCode],[DSTeamTypeDesc], TeamOrder)

	DECLARE @Metro TABLE
	(
		PK_Country			INT,
		CountryCode			VARCHAR(10),
		Distance			FLOAT,
		PostalCode			VARCHAR(20)
	)


	/******************************************************************************
	Check passed event has Qualification
	******************************************************************************/

	INSERT @Subtbl (PK_EventSubType) SELECT PK_EventSubType FROM dbo.EventSubTypes WITH (NOLOCK) WHERE EventSubType = COALESCE(@EventSubType, EventSubType)


	/******************************************************************************
	Check Staff has the permissions to the passed locale
	******************************************************************************/

	
	/* SET DATES IF ALL DATES SELECTED */

	IF @StartDate IS NULL AND @Enddate IS NULL
	BEGIN
		SET @StartDate = GETUTCDATE()
		SET @Enddate = '2049-12-31'
	END	

	DECLARE @RegionCode VARCHAR(3) = 'XXX'

	IF LEN(@CountryCode)>2
	BEGIN
	SET @RegionCode = SUBSTRING(@CountryCode,2,2)
	SET @CountryCode = 'XX'
	END


	SELECT @PK_Country = nCountryID FROM dbo.v_Countries WHERE sCountryCodeISO = @CountryCode

	IF @Status IS NULL
	BEGIN
		SET @Status = '1;4;'
		SET @IsMyHL = 1
	END

	IF @PostalCode IS NOT NULL
	BEGIN
		IF @CountryCode IS NULL
		BEGIN
			SET @Error = 1
			SET @ErrorMessage = 'Country Code is required'
			RETURN
		END

		IF ISNULL(@Miles,0) = 0
			SET @Miles = 50

		--SET @PostalCode = RTRIM(SUBSTRING(@PostalCode,1,CHARINDEX(' ',@PostalCode+ ' '))) --UK
	--	print @PostalCode

		IF NOT EXISTS (SELECT 1 FROM PubEvents.dbo.dimPostalCode WITH(NOLOCK) WHERE PostalCode = @PostalCode )
		BEGIN
			SET @Error = 1
			SELECT @ErrorMessage = 'Postal Code Entered is Not Valid'
			RETURN
		END	


		SELECT 
			@Postal_Latitude = LatitudeHrs
			,@Postal_Longitude = LongitudeHrs 
		FROM
			PubEvents.dbo.dimPostalCode WITH(NOLOCK)
		WHERE
			PostalCode = @PostalCode 
			AND 
			PK_Country = @PK_Country

		
		-- Find ALL Metros for the Country and Distance of Postal Code from the Metro
		INSERT INTO @Metro
		(
			PK_Country,
			CountryCode,
			Distance,
			PostalCode
		)
		SELECT
			PK_Country,
			V.sCountryCodeISO,
			FLOOR(@Distance2 * ACOS(COS(LatitudeHrs/@Distance) * COS(@Postal_Latitude/@Distance) * COS(@Postal_Longitude/@Distance - LongitudeHrs/@Distance) 
			+ SIN(LatitudeHrs/@Distance) * SIN(@Postal_Latitude/@Distance))) Distance,
			PostalCode
		FROM 
			PubEvents.dbo.dimPostalCode P WITH(NOLOCK)
		INNER JOIN
			dbo.v_Countries V
		ON 
			P.PK_Country = V.nCountryID
			AND
			(V.sCountryCodeISO = ISNULL(@CountryCode,V.sCountryCodeISO) OR V.sRegionCode = ISNULL(@RegionCode,V.sRegionCode))			
		WHERE 
			FLOOR(@Distance2 * ACOS(COS(LatitudeHrs/@Distance) * COS(@Postal_Latitude/@Distance) * COS(@Postal_Longitude/@Distance - LongitudeHrs/@Distance) 
			+ SIN(LatitudeHrs/@Distance) * SIN(@Postal_Latitude/@Distance))) <= @Miles

	END

	SET @Len1 = LEN(@Status)

	WHILE @Len1 > 0
	BEGIN
		INSERT @Stbl ([Status]) SELECT CONVERT (INT,LEFT(@Status, CHARINDEX(';',@Status)-1))
		SET @Status = REPLACE(@Status,LEFT(@Status, CHARINDEX(';',@Status)),'')
		SET @Len1 = LEN(@Status)
	END
	

	/*SET THE VALUES FOR THE LOCAL PARAMETERS */

	IF @SearchByEvent = 1
	BEGIN
			--EXEC dbo.usp_EventsAT_SearchEventsByID

			--					-- Mandatory Parameters
			--					 @UserID = @UserID
			--					 ,@PK_Event = @PK_Event
							
			--					-- Error Parameters
			--					 ,@Error = @Error OUTPUT
			--					 ,@ErrorMessage = @ErrorMessage OUTPUT
			--					 ,@IsDevQA = 0

			--					 RETURN

	/******************************************************************************
	Check passed event has Qualification
	******************************************************************************/

		SELECT @HasQualifications = CASE WHEN COUNT(PK_SubEvent) > 0 THEN 1 ELSE 0 END FROM dbo.SubEventQualification  WITH (NOLOCK) WHERE PK_Event = @PK_Event

		SELECT @HasAccess = CASE WHEN COUNT(DISTINCT E.PK_Event) > 0 THEN 1 ELSE 0 END
		   FROM (SELECT DISTINCT E.PK_Event	
				   FROM dbo.EventATAccessUser EU WITH (NOLOCK)
						INNER JOIN dbo.EventATAccessUserModules EUM WITH (NOLOCK) ON EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
						INNER JOIN dbo.Locales L WITH (NOLOCK) ON L.PK_Locale = EUM.PK_Locale
						INNER JOIN dbo.v_Countries C ON SUBSTRING(L.LocaleCode, CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = C.sCountryCodeISO
						INNER JOIN dbo.EventDistributorCountry EC WITH (NOLOCK) ON C.nCountryID = EC.PK_Country
						INNER JOIN dbo.Event E WITH (NOLOCK) ON EC.PK_Event = E.PK_Event 
														AND E.PK_Event = @PK_Event                                        
				  WHERE EU.EventATAccessUserName = @UserID
					AND E.PK_EventType !=3 
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



		SELECT @PK_DefaultLocale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = 'en-US'

		--Populate #EventImage for main query
		INSERT INTO #EventImage
		 SELECT EI.PK_Event, 
				COALESCE(ELD.EventImageLocation, EL.EventImageLocation, EI.EventImageLocation) EventImageLocation, 
				EI.PK_EventImageType,
				ROW_NUMBER() OVER (Partition BY EI.PK_Event ORDER BY EI.PK_EventImageType) RowNo
		   FROM dbo.EventImage EI  WITH (NOLOCK) 
				LEFT JOIN dbo.EventImageLocaleDesc ELD WITH (NOLOCK) ON EI.PK_Event = ELD.PK_Event 
																AND EI.PK_EventImage = ELD.PK_EventImage 
																AND ELD.PK_Locale = @PK_Locale
				LEFT JOIN dbo.EventImageLocaleDesc EL WITH (NOLOCK) ON EI.PK_Event = EL.PK_Event 
																AND EI.PK_EventImage = ELD.PK_EventImage 
																AND EL.PK_Locale = @PK_DefaultLocale	
		-- BUG 608581 
		--Populate #DSTeamType for main query
		---------------------------  BUG 718089  -----------------------------------------------
		;WITH cte_TeamOrder AS(
				SELECT X.PK_Event 
					  ,ISNULL(X.TeamOrder_DS, X.TeamOrder_PM) AS TeamOrder
				FROM (										  
						SELECT A.PK_Event,
							MAX(IIF(E.MakePublic =1 ,23,IIF(B.PK_DSTeamType <= 38, B.TeamOrder,NULL))) TeamOrder_DS,		-- BUG 718089 : Hardcode Distributor Level for MakePublic = 1 Events
							MAX(B.TeamOrder) TeamOrder_PM
						FROM dbo.EventDSTeamType A  WITH (NOLOCK)
						INNER JOIN dbo.DSTeamType B  WITH (NOLOCK) 
							ON A.DSTeamTypeCode = B.DSteamTypeCode 
							AND PK_Event = @PK_Event
						INNER JOIN [Event] E WITH (NOLOCK) 
							ON A.PK_Event = E.PK_Event
						GROUP BY A.PK_Event 
				) X
			)
			,cte_PrimaryLevel AS (
				SELECT   A.PK_Event
						,MIN(pl.PK_PMPrimaryLevel) AS PrimaryLevel
				FROM cte_TeamOrder A
				INNER JOIN dbo.DSTeamType DT  WITH (NOLOCK)
					ON DT.TeamOrder = A.TeamOrder
				INNER JOIN PubEvents.dbo.dimDSSubType ST WITH (NOLOCK) 
					ON DT.DSTeamTypeCode = ST.SubTypeCode
				LEFT JOIN [PMPrimaryLevel] pl WITH (NOLOCK)
						ON st.SubTypeCode = pl.PrimaryLevelCode
				GROUP BY A.PK_Event
			)

			INSERT INTO #DSTeamType (PK_Event, DSTeamTypeCode, DSTeamTypeDesc)
			SELECT CT.PK_Event,
					DT.DSTeamTypeCode,
					ISNULL(ISNULL(LT.DSTeamTypeDesc,LT1.DSTeamTypeDesc),ST.SubTypeDesc) AS DSTeamTypeDesc
			FROM cte_TeamOrder CT
			INNER JOIN cte_PrimaryLevel CP
				ON CT.PK_Event = CP.PK_Event
			INNER JOIN dbo.DSTeamType DT  WITH (NOLOCK)
				ON DT.TeamOrder = CT.TeamOrder
				AND DT.TransitionLevelGroup IS NULL		-- Do not show Transition Levels
			INNER JOIN dbo.Event E  WITH (NOLOCK) 
				ON CT.PK_Event = E.PK_Event
			LEFT JOIN dbo.DSTeamTypeLocaleDesc LT  WITH (NOLOCK) 
				ON DT.DSTeamTypeCode = LT.DSTeamTypeCode
				AND LT.PK_Locale = @PK_Locale
			LEFT JOIN dbo.DSTeamTypeLocaleDesc LT1  WITH (NOLOCK) 
				ON DT.DSTeamTypeCode = LT1.DSTeamTypeCode
				AND LT1.PK_Locale = E.PK_DefaultLocale 
			INNER JOIN PubEvents.dbo.dimDSSubType ST WITH (NOLOCK) 
				ON DT.DSTeamTypeCode = ST.SubTypeCode
			LEFT JOIN [PMPrimaryLevel] pl WITH (NOLOCK)
					ON st.SubTypeCode = pl.PrimaryLevelCode
			WHERE ( (pl.PK_PMPrimaryLevel = CP.PrimaryLevel) OR (pl.PK_PMPrimaryLevel IS NULL AND CP.PrimaryLevel IS NULL) )


		---------------------------  BUG 718089 END -----------------------------------------------
	
	
		INSERT INTO #SearchResults
		SELECT TOP 1 
			 E.PK_Event
			,ED.EventName
			,CASE WHEN E.dStartUTC = E.dEndUTC THEN CONVERT(VARCHAR,E.dStartUTC,101) ELSE CONVERT(VARCHAR(20),E.dStartUTC) + ' - ' + CONVERT(VARCHAR(20),E.dEndUTC) END EventDate
			,E.dStartUTC EventStartDate
			,E.dEndUTC EventEndDate
			,E.PK_EventType
			,EST.PK_EventSubType
			,EST.EventSubType
			,ISNULL(ED.EventVenuename,'') EventVenueName
			,ISNULL(ED.EventDisplayAddress, '') EventDisplayAddress
			,B.DSTeamTypeCode
			,B.DSTeamTypeDesc
			,ISNULL(ED.EventAddress, '') EventAddress
			,ISNULL(ED.EventCity, E.EventCity) EventCity
			,ISNULL(ED.EventState, E.EventState) EventState
			,ISNULL(E.EventZipCode , '') EventZipCode
			,C.sCountryCodeISO EventCountry
			,C.sCountryName EventCountryName 
			,ISNULL(EI.PK_EventImageType,'') EventImageType 
			,ISNULL(EI.EventImageLocation, '') EventImageLocation
			,CASE WHEN ED.EventSummary IS NULL THEN (SELECT ISNULL(EventSummary,EventDesc) FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale) ELSE ED.EventSummary END EventDesc
			,CASE WHEN E.PK_EventType = 3 AND (E.IsActive = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 0 THEN 0
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 1 THEN 1
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 2 THEN 2
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 3 THEN 3
				  WHEN E.PK_EventType IN (1,2) AND E.IsPublish = 1 AND E.DisplayEndDate >= CONVERT(DATE,GETUTCDATE(), 110) THEN 4
				  WHEN E.PK_EventType IN (1,2) AND (E.IsPublish = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
				  END STATUS
			,NULL DisplayStartDate
			,NULL DisplayEndDate
			,E.IsActive
			,E.CreatedDateUTC CreatedDate
			,E.ModifiedDateUTC LastUpdatedDate
			,E.ModifiedBy LastUpdatedBy		
			,L.LocaleCode
			,E.IsPublish
			,E.MakePublic IsPublic
			,E.IsPreRegistrationRequired
			,@HasAccess HasAccess
			,@HasQualifications HasQualifications 
			,E.PK_OldEventAPP 
			,E.IsRecurring
			,E.Latitude
			,E.Longitude
		FROM dbo.Event E  WITH (NOLOCK)	
			INNER JOIN dbo.EventCountry EC  WITH (NOLOCK) ON E.PK_Event = EC.PK_Event
			INNER JOIN dbo.v_Countries C ON EC.PK_Country = C.nCountryID
			INNER JOIN dbo.Locales L  WITH (NOLOCK) ON E.PK_DefaultLocale = L.PK_Locale
			INNER JOIN dbo.EventLocaleDesc ED  WITH (NOLOCK) ON E.PK_Event = ED.PK_Event
			LEFT JOIN dbo.EventEventSubType EEST  WITH (NOLOCK) ON E.PK_Event = EEST.PK_Event
			LEFT JOIN dbo.EventSubTypes EST  WITH (NOLOCK) ON EST.PK_EventSubType = EEST.PK_EventSubType
			INNER JOIN #DSTeamType B ON E.PK_Event = B.PK_Event	
			LEFT JOIN #EventImage EI ON E.PK_Event = EI.PK_Event AND EI.RowNo = 1
	  WHERE E.PK_Event = @PK_Event
		AND (COALESCE(E.IsRecurring, 0) <> 1 OR (E.IsRecurring = 1 AND E.EventApprovalStatus = 3))

	END
	ELSE
	BEGIN
	/* IF PK_Event IS NOT PASSED PERFORM THE FOLLOWING SELECTS */

	/* GET THE PK_EventType VALUES PASSED */
	SET @Len = LEN(@PK_EventType)

	WHILE @Len > 0
	BEGIN
		INSERT @tbl (PK_EventType) SELECT LEFT(@PK_EventType, CHARINDEX(',',@PK_EventType)-1)
		SET @PK_EventType = REPLACE(@PK_EventType,LEFT(@PK_EventType, CHARINDEX(',',@PK_EventType)),'')
		SET @Len = LEN(@PK_EventType)
	END


	/* SET THE VALUE FOR THE LOCALE CODE PARAMETER AGAIN */
	SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode

	/* PERFORM THE MAIN SELECT NOW */

	BEGIN
		--Populate #EventImage for main query
		INSERT INTO #EventImage
		 SELECT EI.PK_Event, 
				COALESCE(ELD.EventImageLocation, EL.EventImageLocation, EI.EventImageLocation) EventImageLocation,
				EI.PK_EventImageType,
				ROW_NUMBER() OVER (Partition BY EI.PK_Event ORDER BY EI.PK_EventImageType) RowNo
		   FROM dbo.EventImage EI  WITH (NOLOCK) 
				LEFT JOIN dbo.EventImageLocaleDesc ELD WITH (NOLOCK) ON EI.PK_Event = ELD.PK_Event 
																AND EI.PK_EventImage = ELD.PK_EventImage 
																AND ELD.PK_Locale = @PK_Locale
				LEFT JOIN dbo.EventImageLocaleDesc EL WITH (NOLOCK) ON EI.PK_Event = EL.PK_Event 
																AND EI.PK_EventImage = ELD.PK_EventImage 
																AND EL.PK_Locale = @PK_DefaultLocale
		OPTION(MAXDOP 1)	--Set MAXDOP = 1 to prevent paralelism

		-- BUG 608581
		--Populate #DSTeamType for main query
		---------------------------  BUG 718089  -----------------------------------------------	
			;WITH cte_TeamOrder AS(
				SELECT X.PK_Event 				 
					  ,ISNULL(X.TeamOrder_DS, X.TeamOrder_PM) AS TeamOrder
				FROM (
						SELECT A.PK_Event,
							MAX(IIF(E.MakePublic =1 ,23,IIF(B.PK_DSTeamType <= 38, B.TeamOrder,NULL))) TeamOrder_DS,		-- BUG 718089 : Hardcode Distributor Level for MakePublic = 1 Events
							MAX(B.TeamOrder) TeamOrder_PM
						FROM dbo.EventDSTeamType A  WITH (NOLOCK)
						INNER JOIN dbo.DSTeamType B  WITH (NOLOCK) 
							ON A.DSTeamTypeCode = B.DSteamTypeCode 
							--AND PK_Event = @PK_Event		--ALL PK_Events
						INNER JOIN [Event] E WITH (NOLOCK) 
							ON A.PK_Event = E.PK_Event
						GROUP BY A.PK_Event 
				) X
			)
			,cte_PrimaryLevel AS (
				SELECT   A.PK_Event
						,MIN(pl.PK_PMPrimaryLevel) AS PrimaryLevel
				FROM cte_TeamOrder A
				INNER JOIN dbo.DSTeamType DT  WITH (NOLOCK)
					ON DT.TeamOrder = A.TeamOrder
				INNER JOIN PubEvents.dbo.dimDSSubType ST WITH (NOLOCK) 
					ON DT.DSTeamTypeCode = ST.SubTypeCode
				LEFT JOIN [PMPrimaryLevel] pl WITH (NOLOCK)
						ON st.SubTypeCode = pl.PrimaryLevelCode
				GROUP BY A.PK_Event
			)

			INSERT INTO #DSTeamType (PK_Event, DSTeamTypeCode, DSTeamTypeDesc)
			SELECT CT.PK_Event,
					DT.DSTeamTypeCode,
					ISNULL(ISNULL(LT.DSTeamTypeDesc,LT1.DSTeamTypeDesc),ST.SubTypeDesc) AS DSTeamTypeDesc
			FROM cte_TeamOrder CT
			INNER JOIN cte_PrimaryLevel CP
				ON CT.PK_Event = CP.PK_Event
			INNER JOIN dbo.DSTeamType DT  WITH (NOLOCK)
				ON DT.TeamOrder = CT.TeamOrder
				AND DT.TransitionLevelGroup IS NULL		-- Do not show Transition Levels
			INNER JOIN dbo.Event E  WITH (NOLOCK) 
				ON CT.PK_Event = E.PK_Event
			LEFT JOIN dbo.DSTeamTypeLocaleDesc LT  WITH (NOLOCK) 
				ON DT.DSTeamTypeCode = LT.DSTeamTypeCode
				AND LT.PK_Locale = @PK_Locale
			LEFT JOIN dbo.DSTeamTypeLocaleDesc LT1  WITH (NOLOCK) 
				ON DT.DSTeamTypeCode = LT1.DSTeamTypeCode
				AND LT1.PK_Locale = E.PK_DefaultLocale 
			INNER JOIN PubEvents.dbo.dimDSSubType ST WITH (NOLOCK) 
				ON DT.DSTeamTypeCode = ST.SubTypeCode
			LEFT JOIN [PMPrimaryLevel] pl WITH (NOLOCK)
					ON st.SubTypeCode = pl.PrimaryLevelCode
			WHERE ( (pl.PK_PMPrimaryLevel = CP.PrimaryLevel) OR (pl.PK_PMPrimaryLevel IS NULL AND CP.PrimaryLevel IS NULL) )

																			   
		---------------------------  BUG 718089 END -----------------------------------------------

	INSERT INTO #SearchResults
	SELECT
		 E.PK_Event
		,ISNULL(ED.EventName, ED1.EventName)EventName
		,CASE WHEN E.dStartUTC IS NULL AND E.dEndUTC IS NULL THEN ' - '
			  WHEN E.dStartUTC IS NULL THEN ' - ' +  CONVERT(VARCHAR(20),E.dEndUTC) 
			  WHEN E.dEndUTC IS NULL THEN CONVERT(VARCHAR(20),E.dStartUTC) + ' - '    
			  WHEN E.dStartUTC = E.dEndUTC THEN CONVERT(VARCHAR,E.dStartUTC,101) 
			  ELSE CONVERT(VARCHAR(20),E.dStartUTC) + ' - ' + CONVERT(VARCHAR(20),E.dEndUTC) 
			  END EventDate
		,E.dStartUTC EventStartDate
		,E.dEndUTC EventEndDate
		,E.PK_EventType
		,D.PK_EventSubType
		,D.EventSubType
		,ISNULL(ED.EventVenuename,ED1.EventVenuename) EventVenueName
		,ISNULL(ED.EventDisplayAddress, ED1.EventDisplayAddress) EventDisplayAddress
		,M.DSTeamTypeCode
		,M.DSTeamTypeDesc
		,ISNULL(ED.EventAddress, ED1.EventAddress) EventAddress
		,ISNULL(ED.EventCity, ED1.EventCity) EventCity
		,ISNULL(ED.EventState, ED1.EventState) EventState
		,ISNULL(E.EventZipCode , '') EventZipCode
		,C.sCountryCodeISO EventCountry
		,C.sCountryName EventCountryName  
		,ISNULL(EI.PK_EventImageType,'') EventImageType 
		,ISNULL(EI.EventImageLocation, '') EventImageLocation
		--,CASE WHEN ED.EventDesc IS NULL THEN (SELECT ISNULL(EDD.EventDesc,EventSummary) FROM dbo.EventLocaleDesc EDD WITH (NOLOCK) WHERE EDD.PK_Event = @PK_Event AND EDD.PK_Locale = ED.PK_DefaultLocale) ELSE ED.EventDesc END EventDesc
		,COALESCE(ED.EventSummary,ED1.EventSummary,ED.EventDesc,ED1.EventDesc)EventDesc
		,CASE WHEN E.PK_EventType = 3 AND (E.IsActive = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
			  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 0 THEN 0
			  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 1 THEN 1
			  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 2 THEN 2
			  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 3 THEN 3
			  WHEN E.PK_EventType IN (1,2) AND E.IsPublish = 1 AND E.DisplayEndDate >= CONVERT(DATE,GETUTCDATE(), 110) THEN 4
			  WHEN E.PK_EventType IN (1,2) AND (E.IsPublish = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
			  END STATUS
	   ,E.DisplayStartDate 
	   ,E.DisplayEndDate
	   ,E.IsActive
	   ,E.CreatedDateUTC CreatedDate
	   ,E.ModifiedDateUTC LastUpdatedDate
	   ,E.ModifiedBy LastUpdatedBy
	   ,L.LocaleCode
	   ,E.IsPublish
	   ,E.MakePublic IsPublic
	   ,E.IsPreRegistrationRequired
	   ,CASE WHEN E.PK_Event = EUM.PK_Event THEN 1 ELSE 0 END AS HasAccess
	   ,CASE WHEN E.PK_Event = SE.PK_Event THEN 1 ELSE 0 END AS HasQualifications
	   ,E.PK_OldEventAPP 
	   ,E.IsRecurring
	   ,E.Latitude
	   ,E.Longitude

		   FROM dbo.Event E  WITH (NOLOCK)
				INNER JOIN dbo.EventLocaleDesc ED1  WITH (NOLOCK) ON E.PK_Event = ED1.PK_Event 
															AND COALESCE(E.CreatedDistributorID, '') = CASE WHEN @DistributorID IS NOT NULL THEN @DistributorID ELSE COALESCE(E.CreatedDistributorID, '') END
															AND ED1.PK_Locale = E.PK_DefaultLocale		
				LEFT JOIN dbo.EventLocaleDesc ED   WITH (NOLOCK) ON E.PK_Event = ED.PK_Event 
															AND ED.PK_Locale = @PK_Locale
				INNER JOIN dbo.EventDistributorCountryLocales EDCL  WITH (NOLOCK) ON E.PK_Event = EDCL.PK_Event
				INNER JOIN @TargetLocales TL ON TL.PK_Locale = EDCL.PK_Locale
				INNER JOIN dbo.Locales L  WITH (NOLOCK) ON E.PK_DefaultLocale = L.PK_Locale	
				INNER JOIN dbo.EventCountry AS EC WITH (NOLOCK)		-- Get Country Where event takes place			-- 1.11.2
					ON EC.PK_Event = E.PK_Event	
				INNER JOIN v_Countries ER							-- Get Region Where event takes place			-- 1.11.2
					on ER.nCountryID = EC.PK_Country
				INNER JOIN dbo.v_Countries C  WITH (NOLOCK)															-- 1.11.2
							ON C.nCountryID = ER.nCountryID 
							AND C.sRegionCode = ER.sRegionCode
							AND C.sCountryCodeISO = IIF(@CountryCode = 'XX' OR @CountryCode IS NULL OR @CountryCode = '',C.sCountryCodeISO,@CountryCode) 
							AND C.sRegionCode = IIF(@RegionCode = 'XXX',C.sRegionCode, @RegionCode)
				INNER JOIN (SELECT R.PK_Event
									,R.PK_EventSubType
									,COALESCE(ELD.EventSubTypeDesc , ESD.EventSubType) EventSubType
							   FROM (SELECT EST.PK_Event
											,MIN(EST.PK_EventSubType) PK_EventSubType
									   FROM dbo.EventEventSubType EST  WITH (NOLOCK)
											INNER JOIN @Subtbl ST ON ST.PK_EventSubType = EST.PK_EventSubType 
									GROUP BY EST.PK_Event )R
									INNER JOIN dbo.Event E1  WITH (NOLOCK) ON R.PK_Event = E1.PK_Event 
									INNER JOIN dbo.EventSubTypes ESD  WITH (NOLOCK) ON R.PK_EventSubType = ESD.PK_EventSubType
									LEFT JOIN dbo.EventSubTypeLocaleDesc ELD WITH (NOLOCK) ON ESD.PK_EventSubType = ELD.PK_EventSubType
																					AND ELD.PK_Locale = @PK_Locale ) D ON D.PK_Event = E.PK_Event
				INNER JOIN #DSTeamType M ON E.PK_Event = M.PK_Event	
				INNER JOIN dbo.DSTeamType DTL  WITH (NOLOCK) ON DTL.DSTeamTypeCode = M.DSTeamTypeCode 	
				LEFT JOIN #EventImage EI ON E.PK_Event = EI.PK_Event AND EI.RowNo = 1
				LEFT JOIN (SELECT DISTINCT E.PK_Event 
							   FROM dbo.EventATAccessUser EU WITH (NOLOCK)
									INNER JOIN dbo.EventATAccessUserModules EUM WITH (NOLOCK) ON EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
									INNER JOIN dbo.Locales L WITH (NOLOCK) ON L.PK_Locale = EUM.PK_Locale
									INNER JOIN dbo.EventLocaleDesc ELD WITH (NOLOCK) ON L.PK_Locale = ELD.PK_Locale
									INNER JOIN dbo.Event E WITH (NOLOCK) ON ELD.PK_Event = E.PK_Event
							  WHERE EU.EventATAccessUserName = @UserID
								--AND --E.PK_EventType = 3
							)EUM ON EUM.PK_Event = E.PK_Event 			
				LEFT JOIN (SELECT PK_Event
							   FROM dbo.SubEventQualification E  WITH (NOLOCK)) SE ON E.PK_Event = SE.PK_Event
				INNER JOIN dbo.EventDSTeamType  AS EDT WITH (NOLOCK)													-- 1.11.3
					ON E.PK_Event = EDT.PK_Event
					AND (EDT.DSTeamTypeCode = @DSTeamType OR ISNULL(@DSTeamType,'') = '' )
		  WHERE E.PK_EventType IN(SELECT PK_EventType FROM @tbl)
			AND D.PK_EventSubType IN (SELECT PK_EventSubType FROM @Subtbl)	
			AND ( ISNULL(E.dStartUTC,E.DisplayStartDate) BETWEEN @StartDate AND @Enddate OR ISNULL(E.dEndUTC,E.DisplayEndDate) BETWEEN @StartDate AND @Enddate OR (ISNULL(E.dStartUTC,E.DisplayStartDate) < @StartDate AND ISNULL(E.dEndUTC,E.DisplayEndDate) > @EndDate))
			AND (CASE WHEN @EventState IS NULL THEN ISNULL(E.EventState,'') END = ISNULL(E.EventState,'') OR E.EventState LIKE '%' + @EventState +'%')
			AND (CASE WHEN @EventCity IS NULL THEN ISNULL(E.EventCity,'') END = ISNULL(E.EventCity,'') OR E.EventCity LIKE '%' + @EventCity +'%')		
	
		IF @DistributorID IS NOT NULL
		BEGIN
		DELETE FROM #SearchResults WHERE PK_EventType !=3
		END


	END


	CREATE CLUSTERED INDEX IX_SearchResults_PK_Event ON #SearchResults(PK_Event)
	CREATE INDEX IX_SearchResults_Status ON #SearchResults(Status) INCLUDE(PK_Event)
	CREATE INDEX IX_SearchResults_PK_OldEventAPP ON #SearchResults(PK_OldEventAPP) INCLUDE(PK_Event, EventDate, EventName)

	/* SELECT THE RESULT SET ONLY FOR THE APPLIED STATUSES */

	IF @IsMyHL = 1
	BEGIN
		DELETE 
		FROM
			#SearchResults
		WHERE
			GETDATE() NOT BETWEEN DisplayStartDate AND (DisplayEndDate+1)

			
		DELETE 
		FROM
			#SearchResults
		WHERE
			IsActive = 0
		
	END
	ELSE
	BEGIN
		DELETE 
		FROM
			#SearchResults
		WHERE
			IsActive != CASE WHEN @IsActive = 0 THEN IsActive ELSE 1 END
			
		IF @IsActive = 1
		BEGIN
		
		DELETE 
		FROM
			#SearchResults
		WHERE
			Status = 5
			
		END
			
	END

	IF @IsPublic = 1
	BEGIN
		DELETE 
		FROM
			#SearchResults
		WHERE
				IsPublic != @IsPublic
	END

	END			 


	/* HIDE DELETED EVENTS */
	DELETE FROM #SearchResults
	WHERE PK_Event IN (SELECT PK_Event FROM dbo.EventDeleteQueue)


	IF @SearchByEvent = 1 
	BEGIN

	SELECT 	 T.PK_Event		
			,T.EventName	
			,T.EventDate	
			,T.EventStartDate		
			,T.EventEndDate	
			,T.PK_EventType		
			,T.PK_EventSubType		
			,T.EventSubType	
			,T.EventVenueName	
			,T.EventDisplayAddress	
			,T.DSTeamTypeCode	
			,T.DSTeamTypeDesc	
			,T.EventAddress	
			,T.EventCity	
			,T.EventState	
			,T.EventZipCode	
			,T.EventCountry	
			,T.EventCountryName	
			,T.EventImageType		
			,T.EventImageLocation	
			,T.EventDesc	
			,T.[STATUS]		
			,T.DisplayStartDate	
			,T.DisplayEndDate	
			,T.IsActive		
			,T.CreatedDate		
			,T.LastUpdatedDate	
			,T.LastUpdatedBy
			,T.LocaleCode
			,T.IsPublish		
			,T.IsPublic		
			,T.IsPreRegistrationRequired	
			,T.HasAccess	
			,T.HasQualifications	
			,T.PK_OldEventAPP 
			,T.IsRecurring 
			,T.Latitude
			,T.Longitude
			,L.LanguageCountryRegion 
			,SUBSTRING(CONVERT(NVARCHAR(30),T.EventStartDate, 108), 1, 5) AS EventStartTime
			,SUBSTRING(CONVERT(NVARCHAR(30),T.EventEndDate, 108), 1, 5) AS EventEndTime		
	FROM
		#SearchResults T
	INNER JOIN
		dbo.Locales L  WITH (NOLOCK)
	ON 
		T.LocaleCode = L.LocaleCode

	END

	ELSE

	BEGIN

	INSERT INTO #FinalResults --for regular events
	SELECT 
		 T.PK_Event		
		,T.EventName	
		,T.EventDate	
		,T.EventStartDate		
		,T.EventEndDate	
		,T.PK_EventType		
		,T.PK_EventSubType		
		,T.EventSubType	
		,T.EventVenueName	
		,T.EventDisplayAddress	
		,T.DSTeamTypeCode	
		,T.DSTeamTypeDesc	
		,T.EventAddress	
		,T.EventCity	
		,T.EventState	
		,T.EventZipCode	
		,T.EventCountry	
		,T.EventCountryName	
		,T.EventImageType		
		,T.EventImageLocation	
		,T.EventDesc	
		,T.[STATUS]		
		,T.DisplayStartDate	
		,T.DisplayEndDate	
		,T.IsActive		
		,T.CreatedDate		
		,T.LastUpdatedDate	
		,T.LastUpdatedBy
		,T.LocaleCode
		,T.IsPublish		
		,T.IsPublic		
		,T.IsPreRegistrationRequired	
		,T.HasAccess	
		,T.HasQualifications	
		,T.PK_OldEventAPP 
		,T.IsRecurring 
		,T.Latitude
		,T.Longitude 
	FROM
		#SearchResults T
	INNER JOIN
		@Stbl S
	ON
		T.Status = S.Status
	WHERE
		COALESCE(T.IsRecurring, 0) = 0
	AND
		T.PK_OldEventAPP IS NULL
	


	INSERT INTO #FinalResults--for event instances
	SELECT 
		T.PK_Event		
		,T.EventName	
		,T.EventDate	
		,T.EventStartDate		
		,T.EventEndDate	
		,T.PK_EventType		
		,T.PK_EventSubType		
		,T.EventSubType	
		,T.EventVenueName	
		,T.EventDisplayAddress	
		,T.DSTeamTypeCode	
		,T.DSTeamTypeDesc	
		,T.EventAddress	
		,T.EventCity	
		,T.EventState	
		,T.EventZipCode	
		,T.EventCountry	
		,T.EventCountryName	
		,T.EventImageType		
		,T.EventImageLocation	
		,T.EventDesc	
		,T.[STATUS]		
		,T.DisplayStartDate	
		,T.DisplayEndDate	
		,T.IsActive		
		,T.CreatedDate		
		,T.LastUpdatedDate	
		,T.LastUpdatedBy
		,T.LocaleCode
		,T.IsPublish		
		,T.IsPublic		
		,T.IsPreRegistrationRequired	
		,T.HasAccess	
		,T.HasQualifications	
		,T.PK_OldEventAPP 
		,T.IsRecurring 
		,T.Latitude
		,T.Longitude 
	FROM
		#SearchResults T
	INNER JOIN
		@Stbl S
	ON
		T.Status = S.Status
	WHERE
		COALESCE(T.IsRecurring, 0) = 0
	AND
		T.PK_OldEventAPP IS NOT NULL 

	INSERT INTO #FinalResults--for event instances' parent
	SELECT 
		P.PK_Event		
		,P.EventName	
		,P.EventDate	
		,P.EventStartDate		
		,P.EventEndDate	
		,P.PK_EventType		
		,P.PK_EventSubType		
		,P.EventSubType	
		,P.EventVenueName	
		,P.EventDisplayAddress	
		,P.DSTeamTypeCode	
		,P.DSTeamTypeDesc	
		,P.EventAddress	
		,P.EventCity	
		,P.EventState	
		,P.EventZipCode	
		,P.EventCountry	
		,P.EventCountryName	
		,P.EventImageType		
		,P.EventImageLocation	
		,P.EventDesc	
		,P.[STATUS]		
		,P.DisplayStartDate	
		,P.DisplayEndDate	
		,P.IsActive		
		,P.CreatedDate		
		,P.LastUpdatedDate	
		,P.LastUpdatedBy
		,P.LocaleCode
		,P.IsPublish		
		,P.IsPublic		
		,P.IsPreRegistrationRequired	
		,P.HasAccess	
		,P.HasQualifications	
		,P.PK_OldEventAPP 
		,P.IsRecurring 
		,P.Latitude
		,P.Longitude 
	FROM
		#SearchResults T
	INNER JOIn
		#SearchResults P
	ON
		T.PK_OldEventAPP = P.PK_Event
	INNER JOIN
		@Stbl S
	ON
		T.Status = S.Status
	WHERE
		P.IsRecurring = 1
	
	INSERT INTO #FinalResults --for parent events that have no children (saved as draft status)
	SELECT P.PK_Event		
		,P.EventName	
		,P.EventDate	
		,P.EventStartDate		
		,P.EventEndDate	
		,P.PK_EventType		
		,P.PK_EventSubType		
		,P.EventSubType	
		,P.EventVenueName	
		,P.EventDisplayAddress	
		,P.DSTeamTypeCode	
		,P.DSTeamTypeDesc	
		,P.EventAddress	
		,P.EventCity	
		,P.EventState	
		,P.EventZipCode	
		,P.EventCountry	
		,P.EventCountryName	
		,P.EventImageType		
		,P.EventImageLocation	
		,P.EventDesc	
		,P.[STATUS]		
		,P.DisplayStartDate	
		,P.DisplayEndDate	
		,P.IsActive		
		,P.CreatedDate		
		,P.LastUpdatedDate	
		,P.LastUpdatedBy
		,P.LocaleCode
		,P.IsPublish		
		,P.IsPublic		
		,P.IsPreRegistrationRequired	
		,P.HasAccess	
		,P.HasQualifications	
		,P.PK_OldEventAPP 
		,P.IsRecurring 
		,P.Latitude
		,P.Longitude
	FROM
		#SearchResults P
	INNER JOIN
		@Stbl S
	ON
		P.Status = S.Status
	WHERE
		P.IsRecurring = 1
	AND
		P.PK_OldEventAPP IS NULL
	AND
		P.PK_Event NOT IN (SELECT PK_Event FROM #FinalResults WHERE PK_Event IS NOT NULL)
	
	CREATE INDEX IX_FinalResults_PK_Event ON #FinalResults(PK_Event)
	CREATE INDEX IX_FinalResults_Status ON #FinalResults(Status)
	CREATE INDEX IX_FinalResults_PK_OldEventApp ON #FinalResults(PK_OldEventApp)


	/* SELECT THE EVENTS FOR DISPLAY AS PER SEARCH CRITERIA */


	SELECT 
			T.PK_Event		
			,T.EventName	
			,T.EventDate	
			,T.EventStartDate		
			,T.EventEndDate	
			,T.PK_EventType		
			,T.PK_EventSubType		
			,T.EventSubType	
			,T.EventVenueName	
			,T.EventDisplayAddress	
			,T.DSTeamTypeCode	
			,T.DSTeamTypeDesc	
			,T.EventAddress	
			,T.EventCity	
			,T.EventState	
			,T.EventZipCode	
			,T.EventCountry	
			,T.EventCountryName	
			,T.EventImageType		
			,T.EventImageLocation	
			,T.EventDesc	
			,T.[STATUS]		
			,T.DisplayStartDate	
			,T.DisplayEndDate	
			,T.IsActive		
			,T.CreatedDate		
			,T.LastUpdatedDate	
			,T.LastUpdatedBy
			,T.LocaleCode
			,T.IsPublish		
			,T.IsPublic		
			,T.IsPreRegistrationRequired	
			,T.HasAccess	
			,T.HasQualifications	
			,T.PK_OldEventAPP 
			,T.IsRecurring 
			,T.Latitude
			,T.Longitude
			,L.LanguageCountryRegion 
			,SUBSTRING(CONVERT(NVARCHAR(30),T.EventStartDate, 108), 1, 5) AS EventStartTime
			,SUBSTRING(CONVERT(NVARCHAR(30),T.EventEndDate, 108), 1, 5) AS EventEndTime		
	FROM
		#FinalResults T
	INNER JOIN
		dbo.Locales L  WITH (NOLOCK)
	ON 
		T.LocaleCode = L.LocaleCode
	EXCEPT
	SELECT 
			T.PK_Event		
			,T.EventName	
			,T.EventDate	
			,T.EventStartDate		
			,T.EventEndDate	
			,T.PK_EventType		
			,T.PK_EventSubType		
			,T.EventSubType	
			,T.EventVenueName	
			,T.EventDisplayAddress	
			,T.DSTeamTypeCode	
			,T.DSTeamTypeDesc	
			,T.EventAddress	
			,T.EventCity	
			,T.EventState	
			,T.EventZipCode	
			,T.EventCountry	
			,T.EventCountryName	
			,T.EventImageType		
			,T.EventImageLocation	
			,T.EventDesc	
			,T.[STATUS]		
			,T.DisplayStartDate	
			,T.DisplayEndDate	
			,T.IsActive		
			,T.CreatedDate		
			,T.LastUpdatedDate	
			,T.LastUpdatedBy
			,T.LocaleCode
			,T.IsPublish		
			,T.IsPublic		
			,T.IsPreRegistrationRequired	
			,T.HasAccess	
			,T.HasQualifications	
			,T.PK_OldEventAPP 
			,T.IsRecurring 
			,T.Latitude
		,T.Longitude
			,L.LanguageCountryRegion 
			,SUBSTRING(CONVERT(NVARCHAR(30),T.EventStartDate, 108), 1, 5) AS EventStartTime
			,SUBSTRING(CONVERT(NVARCHAR(30),T.EventEndDate, 108), 1, 5) AS EventEndTime		
	FROM 
	#SearchResults T
	INNER JOIN
		dbo.Locales L  WITH (NOLOCK)
	ON 
		T.LocaleCode = L.LocaleCode
	WHERE
		IsRecurring = 1 AND T.PK_EVENT NOT IN (SELECT DISTINCT PK_OLDEVENTAPP FROM #FinalResults WHERE PK_OldEventAPP IS NOT NULL) AND Status !=3
	ORDER BY
		T.EventStartDate ASC
		,T.EventEnddate ASC
		,T.EventName ASC


	END

	-- SELECT THE GUEST SPEAKERS FOR THE RESULT SET FROM THE ABOVE SELECT 
	SELECT 
		 T.PK_Event
		,PK_EventGuestSpeaker
		,PK_GuestSpeaker
		,EventSpeakerName
		,EventSpeakerTeamLevel
		,EG.EventSpeakerTitle

	FROM
		#SearchResults T
	LEFT JOIN
		dbo.EventGuestSpeakers EG  WITH (NOLOCK)
	ON
		EG.PK_Event = T.PK_Event
	WHERE
		T.[Status] IN (SELECT [Status] FROM @Stbl)
		AND
		COALESCE(EventSpeakerName, '') <> ''
		
	/* GET COORDINATOR DETAILS*/
	SELECT 
		 ECD.PK_Event
		,ECD.CreatedDistributorID
		,ECD.CoordinatorName --Contact name/WebSite
		,ECD.CoordinatorPhone
		,ECD.CoordinatorEmail	
		,ECD.CoordinatorWebsite
	FROM
		dbo.EventCoordinatorDetail ECD  WITH (NOLOCK)
	INNER JOIN
		#SearchResults T
	ON
		ECD.PK_Event = T.PK_Event
	WHERE
		T.[Status]IN (SELECT [Status] FROM @Stbl)

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
	 
END CATCH

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END