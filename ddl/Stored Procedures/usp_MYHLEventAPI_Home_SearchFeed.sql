CREATE PROCEDURE [dbo].[usp_MYHLEventAPI_Home_SearchFeed]
-- Optional
	@DateFrom SMALLDATETIME = NULL
	,@DateTo SMALLDATETIME = NULL
	,@DisplayPDFType int = 12
	,@Event udt_Event READONLY

	-- Error Parameters
	,@Error int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MYHLEventAPI_Home_SearchFeed

USE:	        
				DECLARE @e int, @em varchar(4000)
				DECLARE @Event udt_Event 
				--Insert @Event (PK_Event) VALUES (2724), (3010), (3473), (45195)
				EXEC dbo.usp_MYHLEventAPI_Home_SearchFeed
						-- Optional
						 @DateFrom = null
						,@DateTo = null
						,@Event = @Event
						,@Error = @e OUTPUT
						,@ErrorMessage = @em OUTPUT
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	This is Landing Page of Events that provides brief info on approved and published events hapenning currently and hapenned in the past as long as they are within display dates.
				-- Public view is for members who logged in can see all the events based on their team level along with purchase ticket link where necessary (geo location sorting is applied on UI based on their primary address/IP address)
				-- Private view is for all users who can see events hapenning based on the location logged in as long as the events are made public (geo location sorting is applied on UI based on their location/IP address)

VERSIONS
----------------------------------------------------------------------------------
1	2016-03-23	SandhyaP		Landing Page
2	2017-04-28	RogelioR		Add a flag to display a PDF instead of a page
3	2017-09-13	RogelioR		Include [Keywords] and [IsUmbracoHosted] columns in result set
4	2019-08-14	NoeG			Refactor code (SRE)
******************************************************************************/
				 
-- DECLARE THE LOCAL VARIABLES 
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @PK_Locale INT
DECLARE @PK_DefaultLocale INT
DECLARE @DSTeam VARCHAR(10)
DECLARE @DSTeamOrder INT
DECLARE @PK_EnUSLocale INT
DECLARE @IsPublic BIT = 0
DECLARE @Result1 INT
DECLARE @CurrentDate DATE = CONVERT(DATE,GETUTCDATE(), 110)
DECLARE @DisplayStartUTC SMALLDATETIME
DECLARE @DisplayEndUTC SMALLDATETIME
-- SET THE VARIBALES

--IF @DateFrom IS NULL AND @DateTo IS NULL  -- When passed, list the events that were modified in this range
--BEGIN
--SET @DateFrom = GETUTCDATE()
--SET @DateTo = '2049-12-31'
--END

SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		SET @DisplayStartUTC = GETUTCDATE()
		SET @DisplayEndUTC = '2049-12-31'

		DECLARE @Events AS TABLE
		(PK_Event INT)

		IF EXISTS(SELECT 1 FROM @Event)
		BEGIN
			INSERT @Events (PK_Event) 
			SELECT PK_Event FROM @Event
		END
		ELSE
		BEGIN
			INSERT @Events (PK_Event) 
			SELECT NULL 
		END

		Select DISTINCT
			 E.PK_Event
			,E.CreatedDateUTC
			,E.CreatedBy 
			,E.ModifiedDateUTC 
			,E.ModifiedBy 
			,ELD.EventName 
			,ELD.EventDesc 
			,ELD.EventSummary
			,E.dStartUTC EventStartDate
			,E.dEndUTC EventEndDate
			,E.PK_EventType
			,ET.EventType
			,ELD.EventVenuename 
			,ELD.EventDisplayAddress 
			,ELD.EventAddress 
			,ELD.EventCity
			,ELD.EventState
			,E.EventZipCode 
			,VC.sCountryCodeISO EventCountry
			,VC.sCountryName EventCountryName  
			,COALESCE(CASE WHEN EID.EventImageLocation = '' THEN NULL ELSE EID.EventImageLocation END
					  ,EI.EventImageLocation) EventLogo
			,E.DisplayStartDate 
			,E.DisplayEndDate
			,E.PK_DefaultLocale
			,LO.LocaleCode
			,E.MakePublic 
			,E.Latitude
			,E.Longitude
			,E.CanPurchaseTicketOnline
			,E.CanDisplayTicketDetails
			,E.IsTicketforQualifiedDS 
			,EUT.EventURL TicketURL
			,DTL.DSTeamTypeCode
			,DTL.TeamOrder
			,STUFF((
				SELECT  
					',' + L.LocaleCode
				FROM 
					dbo.EventDistributorCountryLocales CL WITH (NOLOCK)
				INNER JOIN	
					dbo.Locales L WITH (NOLOCK) 
					ON	
						CL.PK_Locale = L.PK_Locale
				WHERE
					CL.PK_Event = E.PK_Event
				ORDER BY
					L.LocaleCode
				FOR XML PATH('')
			),1,1,'') AS [Audience]
			,DQ.DeletedDateUTC
			,STUFF((
				SELECT  
					',' + ES.EventSubType
				FROM 
					dbo.EventEventSubType  EES WITH (NOLOCK)
				INNER JOIN	
					dbo.EventSubTypes  ES WITH (NOLOCK) 
					ON	
						EES.PK_EventSubtype = ES.PK_EventSubtype
				WHERE
					EES.PK_Event = E.PK_Event
					AND 
					EES.PK_EventType = E.PK_EventType
				ORDER BY
					ES.EventSubType
				FOR XML PATH('')
			),1,1,'') AS [EventSubType]
			,ISNULL(ex.IsDisplayPDF, 0) AS IsDisplayPDF
			,(SELECT TOP 1
					ISNULL(eu.EventURL, dpdf.EventURL) AS DisplayPDFLocation
				FROM Event AS ee WITH (NOLOCK)
					LEFT JOIN EventURL AS eu WITH (NOLOCK) ON eu.PK_Event = ee.PK_Event
						AND eu.PK_EventURLType = @DisplayPDFType
						AND eu.PK_Locale = @PK_Locale
					LEFT JOIN EventURL AS dpdf WITH (NOLOCK) ON dpdf.PK_Event = ee.PK_Event
						AND dpdf.PK_EventURLType = @DisplayPDFType
						AND dpdf.PK_Locale = E.PK_DefaultLocale
				WHERE ee.PK_Event = E.PK_Event) 
			AS DisplayPDFLocation
			,ex.IsUmbracoHosted
		INTO #EventMasterList
		FROM dbo.Event E WITH (NOLOCK)
		LEFT JOIN
			dbo.EventExtn AS ex WITH (NOLOCK) ON ex.PK_Event = e.PK_Event
		INNER JOIN
			dbo.EventType ET WITH (NOLOCK)
		ON
			E.PK_EventType = ET.PK_EventType
		INNER JOIN
			@Events EV
		ON
			E.PK_Event = CASE WHEN EV.PK_Event IS NOT NULL THEN EV.PK_Event 
						 ELSE E.PK_Event END	
		INNER JOIN 
		dbo.EventCountry EC WITH (NOLOCK)
		ON 
			E.PK_Event = EC.PK_Event
		INNER JOIN 
		dbo.v_Countries VC WITH (NOLOCK) 
		ON 
			EC.PK_Country = VC.nCountryID	
		INNER JOIN 
		dbo.EventLocaleDesc ELD WITH (NOLOCK)
		ON 
			E.PK_Event = ELD.PK_Event 
		AND 
			ELD.PK_Locale = E.PK_DefaultLocale 	
		INNER JOIN
		dbo.Locales LO WITH (NOLOCK)
		ON
			E.PK_DefaultLocale 	= LO.PK_Locale
		INNER JOIN
			(
				SELECT A.PK_Event, A.TeamOrder, DST.DSTeamTypeCode
				FROM (
				SELECT A.PK_Event 
					,MAX(B.TeamOrder) TeamOrder
				FROM dbo.EventDSteamType A WITH (NOLOCK)
					INNER JOIN dbo.DSTeamType B WITH (NOLOCK)
						ON A.DSTeamTypeCode = B.DSTeamTypeCode
				WHERE B.DSTeamTypeCode <> 'RC'
				GROUP BY A.PK_Event
				) A
				INNER JOIN
					dbo.DSTeamType  DST WITH (NOLOCK)
				ON
					A.TeamOrder = DST.TeamOrder
			) C
		ON 
			E.PK_Event = C.PK_Event
		INNER JOIN 
		dbo.DSTeamType DTL	WITH (NOLOCK)
		ON 
			DTL.DSTeamTypeCode = C.DSTeamTypeCode		
		LEFT JOIN dbo.DSTeamTypeLocaleDesc LT WITH (NOLOCK)
		ON 
			C.DSTeamTypeCode = LT.DSTeamTypeCode
			AND 
			LT.PK_Locale = COALESCE(E.PK_DefaultLocale , 77)
		LEFT JOIN
		dbo.EventImage EI WITH (NOLOCK)
		ON
			E.PK_Event = EI.PK_Event
		AND
			EI.PK_EventImageType = 1		
		LEFT JOIN
		dbo.EventImageLocaleDesc EID WITH (NOLOCK)
		ON
			EI.PK_Event = EID.PK_Event
		AND
			EI.PK_EventImage = EID.PK_EventImage
		AND
			EID.PK_Locale = E.PK_DefaultLocale	
		LEFT JOIN
		dbo.EventURL EUT WITH (NOLOCK)
		ON 		
			E.PK_Event = EUT.PK_Event
		AND
			EUT.PK_EventURLType = 5		
		AND
			EUT.PK_Locale = E.PK_DefaultLocale
		LEFT JOIN
		dbo.EventDeleteQueue  DQ WITH (NOLOCK)
		ON
			E.PK_Event = DQ.PK_Event
		WHERE
		(E.DisplayStartDate BETWEEN @DisplayStartUTC AND @DisplayEndUTC OR (E.DisplayEndDate+1) BETWEEN @DisplayStartUTC AND @DisplayEndUTC OR (E.DisplayStartDate < @DisplayStartUTC AND (E.DisplayEndDate+1) > @DisplayEndUTC)) 
		AND
		@CurrentDate BETWEEN DisplayStartDate AND (DisplayEndDate+1)
		AND E.PK_EventType IN (1, 2, 3, 4)
		AND (CASE WHEN E.PK_EventType = 3 AND (E.IsActive = 0 OR E.DisplayEndDate < @CurrentDate OR E.dEndUTC < @CurrentDate)  THEN 5 /* Inactive */
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 0 THEN 0 /* Pending Review */
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 1 AND E.IsPublish = 1 THEN 1 /* Published */
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 2 THEN 2 /* Rejected */
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 3 THEN 3 /* Draft */
				  WHEN E.PK_EventType IN (1,2) AND E.IsPublish = 1 AND E.DisplayEndDate >= @CurrentDate THEN 4 /* Published */
				  WHEN E.PK_EventType IN (1,2) AND (E.IsPublish = 0 OR E.DisplayEndDate < @CurrentDate OR E.dEndUTC < @CurrentDate)  THEN 5 /* Inactive */
				  END) IN (1, 4)
		AND E.ModifiedDateUTC BETWEEN COALESCE(@DateFrom, E.ModifiedDateUTC) AND COALESCE(@DateTo, E.ModifiedDateUTC)


		DELETE E FROM #EventMasterList E
		INNER JOIN(
			select PK_Event,DSTeamTypeCode, ROW_NUMBER() OVER (PARTITION BY PK_Event, TeamOrder ORDER BY DSTeamTypeCode) as RowNo 
			from #EventMasterList E
		) F
		ON 
			E.PK_Event = F.PK_Event 
		AND 
			E.DSTeamTypeCode = F.DSTeamTypeCode
		WHERE 
			F.RowNo > 1

		/* Delete Parent records for DS recurring events */
		DELETE EM FROM #EventMasterList EM
		INNER JOIN dbo.Event E WITH (NOLOCK)
		ON EM.PK_Event = E.PK_Event
		WHERE E.IsRecurring = 1 AND E.PK_OldEventApp IS NULL


		/* LIST ALL THE MASTER EVENTS */
		SELECT PK_Event
			  ,CreatedDateUTC
			  ,CreatedBy
			  ,ModifiedDateUTC
			  ,ModifiedBy
			  ,EventName
			  ,EventDesc
			  ,EventSummary
			  ,EventStartDate
			  ,EventEndDate
			  ,PK_EventType
			  ,EventType
			  ,EventVenueName
			  ,EventDisplayAddress
			  ,EventAddress
			  ,EventCity
			  ,EventState
			  ,EventZipCode
			  ,EventCountry
			  ,EventCountryName
			  ,EventLogo
			  ,DisplayStartDate
			  ,DisplayEndDate
			  ,PK_DefaultLocale
			  ,LocaleCode
			  ,MakePublic
			  ,Latitude
			  ,Longitude
			  ,CanPurchaseTicketOnline
			  ,CanDisplayTicketDetails
			  ,IsTicketforQualifiedDS
			  ,TicketURL
			  ,DSTeamTypeCode
			  ,TeamOrder
			  ,Audience
			  ,DeletedDateUTC
			  ,EventSubType
			  ,IsDisplayPDF
			  ,DisplayPDFLocation
			  ,IsUmbracoHosted FROM #EventMasterList
		Order by PK_Event


		SELECT 
			ELD.PK_Event
		   ,ELD.PK_Locale
		   ,L.LocaleCode
		   ,ELD.PK_DefaultLocale
		   ,LO.LocaleCode DefaultLocaleCode
		   ,ELD.EventName
		   ,ELD.EventDesc
		   ,ELD.EventSummary
		   ,ELD.EventLocation
		   ,ELD.EventAddress
		   ,ELD.EventCity
		   ,ELD.EventState
		   ,ELD.EventDisplayAddress
		   ,ELD.EventVenueName
		   ,COALESCE(CASE WHEN EID.EventImageLocation = '' THEN NULL ELSE EID.EventImageLocation END, EI.EventImageLocation) EventLogo
		   ,EUT.EventURL TicketURL
		   ,STUFF((
				SELECT  
					',' + ES.EventSubTypeDesc
				FROM 
					dbo.EventEventSubType EES WITH (NOLOCK)
				INNER JOIN	
					dbo.EventSubTypeLocaleDesc ES WITH (NOLOCK)
					ON	
						EES.PK_EventSubtype = ES.PK_EventSubtype	
				WHERE
					EES.PK_Event = ELD.PK_Event
					AND 
					EES.PK_EventType = ELD.PK_EventType
					AND
					ES.PK_Locale = ELD.PK_Locale
				ORDER BY
					ES.EventSubTypeDesc
				FOR XML PATH('')
			),1,1,'') AS [EventSubType]
			,(SELECT TOP 1
					ISNULL(eu.EventURL, dpdf.EventURL) AS DisplayPDFLocation
				FROM Event AS ee WITH (NOLOCK)
					LEFT JOIN EventURL AS eu WITH (NOLOCK) ON eu.PK_Event = ee.PK_Event
						AND eu.PK_EventURLType = @DisplayPDFType
						AND eu.PK_Locale = ELD.PK_Locale
					LEFT JOIN EventURL AS dpdf WITH (NOLOCK) ON dpdf.PK_Event = ee.PK_Event
						AND dpdf.PK_EventURLType = @DisplayPDFType
						AND dpdf.PK_Locale = E.PK_DefaultLocale
				WHERE ee.PK_Event = E.PK_Event) AS DisplayPDFLocation
			,ELD.[Keywords] AS [Tags]
		FROM
		dbo.EventLocaleDesc ELD WITH (NOLOCK)
		INNER JOIN
		dbo.Event E WITH (NOLOCK)
		ON
			ELD.PK_Event = E.PK_Event
		INNER JOIN
		#EventMasterList EM
		ON
			E.PK_Event = EM.PK_Event
		LEFT JOIN
		dbo.Locales L WITH (NOLOCK)
		ON
			ELD.PK_Locale = L.PK_Locale	
		LEFT JOIN
		dbo.Locales LO WITH (NOLOCK)
		ON
			ELD.PK_DefaultLocale = LO.PK_Locale
		LEFT JOIN
		dbo.EventImage EI WITH (NOLOCK)
		ON
			E.PK_Event = EI.PK_Event
		AND
			EI.PK_EventImageType = 1		
		LEFT JOIN
		dbo.EventImageLocaleDesc EID WITH (NOLOCK)
		ON
			EI.PK_Event = EID.PK_Event
		AND
			EI.PK_EventImage = EID.PK_EventImage
		AND
			EID.PK_Locale = ELD.PK_Locale	
		LEFT JOIN
		dbo.EventURL EUT WITH (NOLOCK)
		ON 		
			E.PK_Event = EUT.PK_Event
		AND
			EUT.PK_EventURLType = 5		
		AND
			EUT.PK_Locale = ELD.PK_Locale	
		LEFT JOIN
			dbo.EventURL eup WITH (NOLOCK)
		ON 		
			E.PK_Event = eup.PK_Event
		AND
			eup.PK_EventURLType = 12
		AND
			eup.PK_Locale = ELD.PK_Locale	
		ORDER BY 
			ELD.PK_Event

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
		RETURN 
	END CATCH
	
END
GO

