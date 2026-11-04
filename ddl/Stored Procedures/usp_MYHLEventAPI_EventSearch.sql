CREATE PROCEDURE [dbo].[usp_MYHLEventAPI_EventSearch]
	@SearchByEvent INT = 0 -- Pass 1 if it is "Search By Event" option is selcted in the UI and 0 if it is Advanced Search Options
	,@LocaleCode CHAR(5)  -- This is a mandatory field from MY HL and optional from Events Manager 
	,@EventType udt_EventType READONLY -- Atleast 1 value have to be passed ----> e.g. 1,2,3
	,@DistributorID VARCHAR(10)  -- DistributorID	
	-- Optional Parameters	
	,@PK_Event INT	= NULL -- If "Search by EventID" is opted, then this should be returned a value
	,@EventName nVARCHAR(50)  = N'' -- If "Search by EventID" is opted, then this should be returned a value
	,@TargetLocales udt_EventAudience READONLY -- Search Events by selected Audience
	,@StartDate DATETIME = NULL -- "Date From" field maps to to this field. If "AllDates" is checked on frontend StartDate & EndDate will not be passed.
	,@Enddate DATETIME = NULL -- "Date To" field maps to to this field. If "AllDates" is checked on frontend StartDate & EndDate will not be passed.
	,@EventCity nVARCHAR(100) = NULL -- This field is a freeform text field and maps to EventCity from Event table.
	,@EventState nVARCHAR(100) = NULL -- This field is a freeform text field and maps to EventState from Event table.	 
	,@CountryCode CHAR(3) = NULL -- Region/Country Code field maps to this field 
	,@EventSubType udt_EventSubTypes READONLY -- If "All" is opted from the drop down in UI please pass NULL else pass the right SubTypeCode
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MYHLEventAPI_EventSearch

USE:	        
			DECLARE @e int, @em varchar(4000)
				Declare @TargetLocales udt_EventAudience
				INSERT INTO @TargetLocales VALUES (NULL) --(77),(10), (11), (39), (59), (102), (74), (103)
				Declare @EventType udt_EventType
				INSERT INTO @EventType  VALUES (1),(2),(3)
				Declare @EventSubType udt_EventSubTypes
				INSERT INTO @EventSubType (PK_SubType) VALUES (null) --(1),(2),(3), (10),(12),(13), (15),(22),(25), (30),(32),(33)

                 EXEC dbo.usp_MYHLEventAPI_EventSearch
						-- Mandatory
						 @SearchByEvent = 0
						,@LocaleCode = 'en-AT'
					 	,@DistributorID = '1111111111'
						,@TargetLocales = @TargetLocales
						,@EventType = @EventType
						-- Optional
						,@PK_Event = null
						,@EventName = NULL
						,@StartDate = '2014-11-11'
						,@Enddate = '2014-05-11'
						,@EventCity = NULL
						,@EventState = NULL
						,@CountryCode = NULL
						,@EventSubType = @EventSubType
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	For Search criteria on MYHL Events

NOTES:			

VERSIONS
----------------------------------------------------------------------------------
1	2014-11-11			SandhyaP			   MYHL Event Search 
2	2019-08-14			NoeG					Refactor code (SRE)
******************************************************************************/
				 
/* DECLARE THE LOCAL PARAMETERS */
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
/* ***************** SonarQube check 83 and 84 - Output parameters should be assigned 
	SRE changes added
*/
	
SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		DECLARE @PK_Locale INT
		DECLARE @PK_Country INT
		DECLARE @PK_DefaultLocale INT
		DECLARE @Len INT
		DECLARE @Len1 INT
		DECLARE @DSTeamType VARCHAR(10)

				 
		/* DEFINE THE TABLE THAT STORES THE FINAL RESULTS */

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
		,PK_OldEventAPP INT
		,IsRecurring BIT
		,Latitude NUMERIC(18,10)
		,Longitude NUMERIC(18,10)
		)


		/******************************************************************************
		   SET THE VALUES FOR THE LOCAL PARAMETERS
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

		SELECT @DSTeamType = sSubTeam FROM dbo.v_Distributor where sDistributorid = @DistributorID

		/* SET THE VALUE FOR THE LOCALE CODE PARAMETER AGAIN */
		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode = @LocaleCode

		/*temp table to be handled*/

		IF OBJECT_ID('tempdb..#TargetLocalesFinal') IS NOT NULL
			DROP TABLE #TargetLocalesFinal

		IF OBJECT_ID('tempdb..#E') IS NOT NULL
			DROP TABLE #E

		IF OBJECT_ID('tempdb..#EDT') IS NOT NULL
			DROP TABLE #EDT

		IF OBJECT_ID('tempdb..#FinalResults') IS NOT NULL
			DROP TABLE #FinalResults
    
		--DECLARE @TargetLocalesFinal udt_EventAudience
		CREATE Table #TargetLocalesFinal 
		(
			PK_Locale Int 
		)

		IF (SELECT COUNT(1) FROM @TargetLocales) = 0
		BEGIN

			INSERT INTO #TargetLocalesFinal (PK_Locale) VALUES (NULL)

		END
		ELSE
		BEGIN

			INSERT INTO #TargetLocalesFinal (PK_Locale) SELECT PK_Locale FROM @TargetLocales

		END

		Create Index IX_PK_Locale On #TargetLocalesFinal(PK_Locale)

		DECLARE @EventSubTypesFinal udt_EventSubTypes

		IF (SELECT COUNT(1) FROM @EventSubType) = 0
		BEGIN

			INSERT INTO @EventSubTypesFinal (PK_SubType) VALUES (NULL)

		END
		ELSE
		BEGIN

			INSERT INTO @EventSubTypesFinal (PK_SubType) SELECT PK_SubType FROM @EventSubType

		END


		/*SET THE VALUES FOR THE LOCAL PARAMETERS */

		IF @SearchByEvent = 1 
		BEGIN

			SELECT @PK_DefaultLocale =  PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = 'en-US'

			INSERT INTO #SearchResults
			SELECT DISTINCT
				 E.PK_Event
				,ISNULL(ED.EventName, ED1.EventName)EventName
				,CASE WHEN E.dStartUTC = E.dEndUTC THEN CONVERT(VARCHAR,E.dStartUTC,101) ELSE CONVERT(VARCHAR(20),E.dStartUTC) + ' - ' + CONVERT(VARCHAR(20),E.dEndUTC) END EventDate
				,E.dStartUTC EventStartDate
				,E.dEndUTC EventEndDate
				,E.PK_EventType
				,EST.PK_EventSubType
				,EST.EventSubType
				,ISNULL(ED.EventVenuename,'') EventVenueName
				,ISNULL(ED.EventDisplayAddress, '') EventDisplayAddress
				,'' DSTeamTypeCode
				,'' DSTeamTypeDesc
				,ISNULL(ED.EventAddress, '') EventAddress
				,ISNULL(ED.EventCity, E.EventCity) EventCity
				,ISNULL(ED.EventState, E.EventState) EventState
				,ISNULL(E.EventZipCode , '') EventZipCode
				,C.sCountryCodeISO EventCountry
				,C.sCountryName EventCountryName 
				,ISNULL(EI.PK_EventImageType,'') EventImageType 
				,ISNULL(EI.EventImageLocation, '') EventImageLocation
				,CASE WHEN ED.EventSummary IS NULL THEN (SELECT ISNULL(EventSummary,EventDesc) FROM dbo.EventLocaleDesc WHERE PK_Event = @PK_Event AND PK_Locale = @PK_DefaultLocale) ELSE ED.EventSummary END EventDesc
				,CASE WHEN E.PK_EventType = 3 AND (E.IsActive = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
					  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 0 THEN 0
					  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 1 THEN 1
					  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 2 THEN 2
					  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 3 THEN 3
					  WHEN E.PK_EventType IN (1,2) AND E.IsPublish = 1 AND E.DisplayEndDate >= CONVERT(DATE,GETUTCDATE(), 110) THEN 4
					  WHEN E.PK_EventType IN (1,2) AND (E.IsPublish = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5
					  END STATUS
				,E.DisplayStartDate DisplayStartDate
				,E.DisplayEndDate DisplayEndDate
				,E.IsActive
				,E.CreatedDateUTC CreatedDate
				,E.ModifiedDateUTC LastUpdatedDate
				,E.ModifiedBy LastUpdatedBy		
				,L.LocaleCode
				,E.IsPublish
				,E.MakePublic IsPublic
				,E.IsPreRegistrationRequired
				,E.PK_OldEventAPP 
				,E.IsRecurring
				,E.Latitude
				,E.Longitude
			FROM		
				dbo.Event E  WITH (NOLOCK)	
			INNER JOIN
				dbo.EventCountry EC  WITH (NOLOCK)
			ON
				E.PK_Event = EC.PK_Event
			INNER JOIN
				dbo.v_Countries C  WITH (NOLOCK)
			ON
				EC.PK_Country = C.nCountryID
			INNER JOIN
				dbo.Locales L  WITH (NOLOCK)
			ON
				E.PK_DefaultLocale = L.PK_Locale
			INNER JOIN 
				dbo.EventLocaleDesc ED1   WITH (NOLOCK)
			ON 
				E.PK_Event = ED1.PK_Event 
			AND 
				ED1.PK_Locale = E.PK_DefaultLocale	
			INNER JOIN
				@EventType ET
			ON 
				ET.PK_EventType = E.PK_EventType				
			LEFT JOIN 
				dbo.EventLocaleDesc ED  WITH (NOLOCK)
			ON 
				E.PK_Event = ED.PK_Event 
			AND 
				ED.PK_Locale = @PK_Locale
			LEFT JOIN
			(
				SELECT
				R.PK_Event
				,R.PK_EventSubType
				,COALESCE(ELD.EventSubTypeDesc , ESD.EventSubType) EventSubType
				FROM
				(SELECT
					 EST.PK_Event
					,MIN(EST.PK_EventSubType) PK_EventSubType
				 FROM
					dbo.EventEventSubType EST  WITH (NOLOCK)
				  GROUP BY
					EST.PK_Event
				)R
				 INNER JOIN
				dbo.EventSubTypes ESD  WITH (NOLOCK)
				ON
				R.PK_EventSubType = ESD.PK_EventSubType
				 LEFT JOIN
				dbo.EventSubTypeLocaleDesc ELD WITH (NOLOCK)
				ON 
					ESD.PK_EventSubType = ELD.PK_EventSubType
				AND
					ELD.PK_Locale = @PK_Locale	
			)EEST
			ON
				E.PK_Event = EEST.PK_Event
			LEFT JOIN
				dbo.EventSubTypes EST  WITH (NOLOCK)
			ON
				EST.PK_EventSubType = EEST.PK_EventSubType
			INNER JOIN
				(
			SELECT
				 A.PK_Event
				,DT.DSTeamTypeCode
				,DTL.DSTeamTypeDesc
			FROM
				dbo.DSTeamType DT WITH (NOLOCK)
			INNER JOIN
				(SELECT 
					 EDT.PK_Event
					,MAX(DT.TeamOrder) TeamOrder
				FROM 
					dbo.EventDSTeamType EDT  WITH (NOLOCK)
				INNER JOIN
					dbo.DSTeamType DT  WITH (NOLOCK)
				ON
					EDT.DSTeamTypeCode = COALESCE(@DSTeamType,DT.DSteamTypeCode)
			 
				GROUP BY 	
					 EDT.PK_Event	
				)A
				ON
				DT.TeamOrder = A.TeamOrder
			LEFT JOIN dbo.DSTeamTypeLocaleDesc DTL  WITH (NOLOCK)
					ON
				DTL.DSTeamTypeCode = DT.DSTeamTypeCode
				AND
				PK_Locale = @PK_DefaultLocale

			) B
			ON
				E.PK_Event = B.PK_Event	
			LEFT JOIN
			(
				SELECT EI.PK_Event, COALESCE(ELD.EventImageLocation, EL.EventImageLocation, EI.EventImageLocation) EventImageLocation, EI.PK_EventImageType 
					,ROW_NUMBER() OVER (Partition BY EI.PK_Event ORDER BY EI.PK_EventImageType) RowNo
				FROM	dbo.EventImage EI  WITH (NOLOCK) 
				LEFT JOIN dbo.EventImageLocaleDesc ELD WITH (NOLOCK) ON EI.PK_Event = ELD.PK_Event AND EI.PK_EventImage = ELD.PK_EventImage AND ELD.PK_Locale = @PK_Locale
				LEFT JOIN dbo.EventImageLocaleDesc EL WITH (NOLOCK) ON EI.PK_Event = EL.PK_Event AND EI.PK_EventImage = ELD.PK_EventImage AND EL.PK_Locale = @PK_DefaultLocale
			)EI
			ON
				E.PK_Event = EI.PK_Event AND EI.RowNo = 1
			WHERE
				(E.PK_Event = @PK_Event OR E.EventName LIKE '%' + @EventName +'%')
			AND
				GETUTCDATE() BETWEEN E.DisplayStartDate and (E.DisplayEndDate+1)
			AND
				(COALESCE(E.IsRecurring, 0) <> 1 OR (E.IsRecurring = 1 AND E.EventApprovalStatus = 3))


		END
		ELSE
		BEGIN

		/* IF PK_Event IS NOT PASSED PERFORM THE FOLLOWING SELECTS */

		/* PERFORM THE MAIN SELECT NOW */

		Select E.PK_Event, 
			E.PK_DefaultLocale, 
			E.PK_RecurrenceType, 
			E.EventZipCode, 
			E.EventApprovalStatus, 
			E.CreatedDistributorID, 
			E.dStartUTC, 
			E.dEndUTC, 
			E.PK_EventType, 
			E.DisplayStartDate,
			E.DisplayEndDate,
			E.IsActive,
			E.CreatedDateUTC,
			E.ModifiedDateUTC,
			E.ModifiedBy,
			E.IsPublish,
			E.MakePublic,
			E.IsPreRegistrationRequired,
			E.PK_OldEventAPP, 
			E.IsRecurring,
			E.RecurrenceEndDate,
			E.Latitude,
			E.Longitude
		Into #E
		From dbo.Event E  WITH (NOLOCK)
		WHERE
		(E.DisplayStartDate BETWEEN @StartDate AND @Enddate OR E.DisplayEndDate BETWEEN @StartDate AND @Enddate OR (E.DisplayStartDate < @StartDate AND E.DisplayEndDate > @EndDate))
		AND
			(CASE WHEN @EventState IS NULL THEN ISNULL(E.EventState,'') END = ISNULL(E.EventState,'')
			 OR
			E.EventState LIKE '%' + @EventState +'%')
		AND
			(CASE WHEN @EventCity IS NULL THEN ISNULL(E.EventCity,'') END = ISNULL(E.EventCity,'')
			 OR
			E.EventCity LIKE '%' + @EventCity +'%')	
		AND
			(CASE WHEN @EventName IS NULL THEN ISNULL(E.EventName,'') END = ISNULL(E.EventName,'')
			 OR
			 E.EventName LIKE '%' + @EventName +'%')	 
		AND
			GETUTCDATE() BETWEEN DisplayStartDate AND (DisplayEndDate+1)

		Create Index IX_PK_Event On #E(PK_Event)

		/* -- Old Code
		SELECT
			E.PK_Event
			,DT.DSTeamTypeCode
			,C.TeamOrder
			,COALESCE(LT.DSTeamTypeDesc,LT1.DSTeamTypeDesc) DSTeamTypeDesc
		Into #EDT 
		FROM #E E 
			LEFT JOIN dbo.EventDSTeamType EDT (NOLOCK)
				ON EDT.PK_Event = E.PK_Event
			LEFT JOIN dbo.DSTeamType DT (NOLOCK)
				ON EDT.DSTeamTypeCode = COALESCE(@DSTeamType,DT.DSteamTypeCode)
			LEFT JOIN
			(
				SELECT A.PK_Event 
					,MAX(B.TeamOrder) TeamOrder
				FROM dbo.EventDSteamType A (NOLOCK)
					INNER JOIN dbo.DSTeamType B (NOLOCK)
						ON A.DSTeamTypeCode = B.DSTeamTypeCode
				GROUP BY A.PK_Event
			) C
				ON EDT.PK_Event = C.PK_Event
				AND DT.TeamOrder = C.TeamOrder
			LEFT JOIN dbo.DSTeamTypeLocaleDesc LT (NOLOCK)
				ON DT.DSTeamTypeCode = LT.DSTeamTypeCode
				AND LT.PK_Locale = @PK_Locale
			LEFT JOIN dbo.DSTeamTypeLocaleDesc LT1 (NOLOCK)
				ON DT.DSTeamTypeCode = LT1.DSTeamTypeCode
				AND LT1.PK_Locale = E.PK_DefaultLocale 
		*/
		SELECT
			E.PK_Event
			,IsNull(C.DSTeamTypeCode, 'FC') DSTeamTypeCode
			,IsNull(C.TeamOrder, 1) TeamOrder 
			,COALESCE(LT.DSTeamTypeDesc,LT1.DSTeamTypeDesc) DSTeamTypeDesc
		Into #EDT 
		FROM #E E 
			LEFT JOIN
			(
				SELECT A.PK_Event, A.TeamOrder, DST.DSTeamTypeCode
				FROM(
				SELECT A.PK_Event 
					,MAX(B.TeamOrder) TeamOrder
				FROM dbo.EventDSteamType A  WITH (NOLOCK)
					INNER JOIN dbo.DSTeamType B  WITH (NOLOCK)
						ON A.DSTeamTypeCode = B.DSTeamTypeCode
				WHERE B.DSTeamTypeCode <> 'RC'
				GROUP BY A.PK_Event
				) A
				INNER JOIN
					DBO.DSTeamType DST WITH (NOLOCK)
				ON
					A.TeamOrder = DST.TeamOrder
			) C
				On E.PK_Event = C.PK_Event
			LEFT JOIN (Select Top 1 DSTeamTypeCode, TeamOrder From dbo.DSTeamType  WITH (NOLOCK) Where DSTeamTypeCode = COALESCE(@DSTeamType,'FC')) DT
				ON C.TeamOrder >= DT.TeamOrder
			LEFT JOIN dbo.DSTeamTypeLocaleDesc LT  WITH (NOLOCK)
				ON C.DSTeamTypeCode = LT.DSTeamTypeCode
				AND LT.PK_Locale = @PK_Locale
			LEFT JOIN dbo.DSTeamTypeLocaleDesc LT1  WITH (NOLOCK)
				ON C.DSTeamTypeCode = LT1.DSTeamTypeCode
				AND LT1.PK_Locale = E.PK_DefaultLocale 
		Where C.TeamOrder >= DT.TeamOrder Or C.PK_Event Is Null

		Create Index IX_PK_Event On #EDT(PK_Event)

		--Delete all the team levels that cause a duplicate PK_Event due to the same TeamOrder
		DELETE E FROM #EDT E
		INNER JOIN(
			select PK_Event,DSTeamTypeCode, ROW_NUMBER() OVER (PARTITION BY PK_Event, TeamOrder ORDER BY DSTeamTypeCode) as RowNo 
			from #EDT e
		) F
		ON 
			E.PK_Event = F.PK_Event 
		AND 
			E.DSTeamTypeCode = F.DSTeamTypeCode
		WHERE 
			F.RowNo > 1

		INSERT INTO #SearchResults
		SELECT
			 DISTINCT
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
			,VC.sCountryCodeISO EventCountry
			,VC.sCountryName EventCountryName  
			,ISNULL(EI.PK_EventImageType,'') EventImageType 
			,ISNULL(EI.EventImageLocation, '') EventImageLocation
			--,CASE WHEN ED.EventDesc IS NULL THEN (SELECT ISNULL(EDD.EventDesc,EventSummary) FROM dbo.EventLocaleDesc EDD WHERE EDD.PK_Event = @PK_Event AND EDD.PK_Locale = ED.PK_DefaultLocale) ELSE ED.EventDesc END EventDesc
			,COALESCE(ED.EventSummary,ED1.EventSummary,ED.EventDesc,ED1.EventDesc)EventDesc
			,CASE WHEN E.PK_EventType = 3 AND (E.IsActive = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5 /* Inactive */
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 0 THEN 0 /* Pending Review */
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 1 THEN 1 /* Published */
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 2 THEN 2 /* Rejected */
				  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 3 THEN 3 /* Draft */
				  WHEN E.PK_EventType IN (1,2) AND E.IsPublish = 1 AND E.DisplayEndDate >= CONVERT(DATE,GETUTCDATE(), 110) THEN 4 /* Published */
				  WHEN E.PK_EventType IN (1,2) AND (E.IsPublish = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5 /* Inactive */
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
		   ,E.PK_OldEventAPP 
		   ,E.IsRecurring
		   ,E.Latitude
		   ,E.Longitude
		FROM
			#E E --dbo.Event E (NOLOCK)
			INNER JOIN dbo.EventCountry EC  WITH (NOLOCK) 
				ON E.PK_Event = EC.PK_Event
			INNER JOIN dbo.v_Countries VC  WITH (NOLOCK)
				ON EC.PK_Country = VC.nCountryID
			INNER JOIN dbo.EventLocaleDesc ED1  WITH (NOLOCK)
				ON E.PK_Event = ED1.PK_Event 
				AND ED1.PK_Locale = E.PK_DefaultLocale	
			INNER JOIN @EventType ET
				ON ET.PK_EventType = E.PK_EventType		
			LEFT JOIN dbo.EventLocaleDesc ED  WITH (NOLOCK)
				ON E.PK_Event = ED.PK_Event 
				AND ED.PK_Locale = @PK_Locale
			INNER JOIN dbo.EventDistributorCountryLocales EDCL  WITH (NOLOCK)
				ON E.PK_Event = EDCL.PK_Event
			INNER JOIN #TargetLocalesFinal TL
				ON COALESCE(TL.PK_Locale, EDCL.PK_Locale) = EDCL.PK_Locale
			INNER JOIN dbo.Locales L  WITH (NOLOCK)
				ON COALESCE(ED.PK_Locale,E.PK_DefaultLocale) = L.PK_Locale
			INNER JOIN dbo.v_Countries C  WITH (NOLOCK)
				ON SUBSTRING(L.LocaleCode, CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = C.sCountryCodeISO
				AND (C.sCountryCodeISO = COALESCE(@CountryCode,C.sCountryCodeISO) OR C.sRegionCode = COALESCE(@RegionCode,C.sRegionCode))
			INNER JOIN
			(
				SELECT
					R.PK_Event
					,R.PK_EventSubType
					,COALESCE(ELD.EventSubTypeDesc , ESD.EventSubType) EventSubType
				FROM
				(
					SELECT EST.PK_Event
						,MIN(EST.PK_EventSubType) PK_EventSubType
					FROM dbo.EventEventSubType EST  WITH (NOLOCK)
						INNER JOIN @EventSubTypesFinal ST
							ON EST.PK_EventSubType = COALESCE(ST.PK_SubType, EST.PK_EventSubType)
					GROUP BY EST.PK_Event
				) R
					INNER JOIN #E E1 
						ON R.PK_Event = E1.PK_Event
					INNER JOIN dbo.EventSubTypes ESD  WITH (NOLOCK)
						ON R.PK_EventSubType = ESD.PK_EventSubType
					LEFT JOIN dbo.EventSubTypeLocaleDesc ELD WITH (NOLOCK)
						ON ESD.PK_EventSubType = ELD.PK_EventSubType
						AND ELD.PK_Locale = @PK_Locale
			) D
				ON E.PK_Event = D.PK_Event
			INNER JOIN #EDT M
				ON E.PK_Event = M.PK_Event	
			INNER JOIN dbo.DSTeamType DTL WITH (NOLOCK)
				ON DTL.DSTeamTypeCode = M.DSTeamTypeCode		
			LEFT JOIN
			(
				SELECT EI.PK_Event, COALESCE(ELD.EventImageLocation, EL.EventImageLocation, EI.EventImageLocation) EventImageLocation, EI.PK_EventImageType 
					,ROW_NUMBER() OVER (Partition BY EI.PK_Event ORDER BY EI.PK_EventImageType) RowNo
				FROM	dbo.EventImage EI  WITH (NOLOCK) 
				LEFT JOIN dbo.EventImageLocaleDesc ELD WITH (NOLOCK) ON EI.PK_Event = ELD.PK_Event AND EI.PK_EventImage = ELD.PK_EventImage AND ELD.PK_Locale = @PK_Locale
				LEFT JOIN dbo.EventImageLocaleDesc EL WITH (NOLOCK) ON EI.PK_Event = EL.PK_Event AND EI.PK_EventImage = ELD.PK_EventImage AND EL.PK_Locale = @PK_DefaultLocale
			)EI
			ON
				E.PK_Event = EI.PK_Event AND EI.RowNo = 1
			--DELETE FROM #SearchResults WHERE PK_EventType !=3

		END

		CREATE INDEX IX_SearchResults_Status ON #SearchResults(Status)
		CREATE INDEX IX_SearchResults_LocaleCode ON #SearchResults(LocaleCode)
		CREATE INDEX IX_SearchResults_PK_Event ON #SearchResults(PK_Event)

		DELETE FROM #SearchResults
		WHERE Status NOT IN (1,4)
	 
		/* HIDE DELETED EVENTS */
		DELETE FROM #SearchResults
		WHERE PK_Event IN (SELECT PK_Event FROM dbo.EventDeleteQueue)

		/*hide the events that are not public, during public search*/
		IF COALESCE(@DistributorID, '') = ''
		BEGIN
			DELETE FROM #SearchResults
			WHERE IsPublic = 0
		END


		SELECT T.PK_Event		
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
		,T.PK_OldEventAPP 
		,T.IsRecurring 
		,T.Latitude 
		,T.Longitude 
		INTO #FinalResults
		FROM
			#SearchResults T

		/* SELECT THE EVENTS FOR DISPLAY AS PER SEARCH CRITERIA */

		SELECT DISTINCT
				 PK_Event,EventName,EventDate,EventStartDate,EventEndDate				
				,PK_EventType,PK_EventSubType,EventSubType,EventVenueName,EventDisplayAddress
				,DSTeamTypeCode,DSTeamTypeDesc,EventAddress,EventCity,EventState,EventZipCode
				,EventCountry,EventCountryName,EventImageType,EventImageLocation,EventDesc
				,[STATUS],DisplayStartDate,DisplayEndDate,IsActive,CreatedDate,LastUpdatedDate
				,LastUpdatedBy,T.LocaleCode,IsPublish,IsPublic,IsPreRegistrationRequired,PK_OldEventAPP
				,IsRecurring,Latitude,Longitude
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
		SELECT DISTINCT
				 PK_Event,EventName,EventDate,EventStartDate,EventEndDate				
				,PK_EventType,PK_EventSubType,EventSubType,EventVenueName,EventDisplayAddress
				,DSTeamTypeCode,DSTeamTypeDesc,EventAddress,EventCity,EventState,EventZipCode
				,EventCountry,EventCountryName,EventImageType,EventImageLocation,EventDesc
				,[STATUS],DisplayStartDate,DisplayEndDate,IsActive,CreatedDate,LastUpdatedDate
				,LastUpdatedBy,T.LocaleCode,IsPublish,IsPublic,IsPreRegistrationRequired,PK_OldEventAPP
				,IsRecurring,Latitude,Longitude
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


			
		/* SELECT THE GUEST SPEAKERS FOR THE RESULT SET FROM THE ABOVE SELECT */
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
			EventSpeakerName IS NOT NULL AND LTRIM(RTRIM(EventSpeakerName)) != ''

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
			ECD.CoordinatorName IS NOT NULL AND LTRIM(RTRIM(CoordinatorName)) != ''

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

