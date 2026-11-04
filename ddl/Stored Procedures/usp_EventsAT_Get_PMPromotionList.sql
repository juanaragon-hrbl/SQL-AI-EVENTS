CREATE PROCEDURE [dbo].[usp_EventsAT_Get_PMPromotionList]
	-- Optional
	@PK_Event			int = NULL
	,@dStartUTC			datetime2 = NULL
	,@dEndUTC			datetime2 = NULL
	,@PMLevel			varchar(15) = NULL
	,@LocaleCode		varchar(5) = NULL
	,@UserName			varchar(255) = NULL
	,@EventName			varchar(255) = NULL
	,@DefaultLocale		bit = 0
	,@UserLevel			bit = 0
	,@OnlyPublished		bit = 0
	,@EventStatus		varchar(255) = NULL
	,@SortBy			varchar(255) = NULL
	,@DistributorID		varchar(30) = NULL

	-- Defaults
	,@PK_EventType		int = 15
	,@PK_EventImageType	int = 1

	-- Pagination
	,@Start				int = NULL
	,@Rows				int = NULL OUTPUT
	,@Total				int = NULL OUTPUT

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0
AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Get_PMPromotionList
	
	USE:			
					DECLARE @e int, @em varchar(4000)
					, @r int, @s int = 1, @t int;

					EXEC dbo.usp_EventsAT_Get_PMPromotionList
							@LocaleCode = 'en-US'
							--,@UserName = 'rogelior'
							,@PMLevel = 'GPM'
							,@DistributorID = 'QAARVN0004'
							,@DefaultLocale = null
							,@UserLevel = 0
							,@OnlyPublished = 1
							--,@PK_Event = 48019
							--,@Start = @s
							--,@Rows = @r OUTPUT
							--,@EventStatus = 'DRAFT'
							--,@SortBy = 3
							,@Total = @t OUTPUT
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message], @r, @t
					
	DESCRIPTION:	Gets preferred member promotions

	NOTES:
			@Start -> Sets the starting point of the result set
			@Rows -> Number of rows that will be returned
			@SortBy ->	1 by StartDate, ModifiedDateUTC, EndDate
						2 by EndDate, StartDate, ModifiedDateUTC
						3 by ModifiedDateUTC, StartDate, EndDate
	
	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event, dbo.EventLocaleDesc, dbo.EventDSTeamType, dbo.EventImage, dbo.EventImageLocaleDesc, dbo.EventImageType, dbo.Locales

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-05-08		RogelioR		Initial
	2.0.0		2019-08-08		NoeG			Refactor code (SRE)
	2.0.1		2020-05-27		NoeG			Filter only DefaultLocale if Locale provided doesnt fit with Event Locales
	2.0.2		2020-08-13		puertac			T 327639 : Adding DisplayDate, + Filter the list when called from DS side (when @OnlyPublished = 1)
												to only show the promos with displaydates null or @Today BETWEEN DisplayStartdate AND DisplayEndDate
	2.0.3		2022-09-07		ivanci			BUG 1115303 - usp_EventsAT_Get_PMPromotionList has hardcode subtypes  (Vietnam)
	2.0.4		2023-11-30		ivanci			Return TestingEnabled Flag and Owners list
	2.0.5		2025-03-27		ivanci			Compare Displat Dates using the timezone specified for promotion
******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@Today				datetime2 = GETUTCDATE()
			,@PK_Locale			int = (SELECT PK_Locale FROM [dbo].[Locales] WITH (NOLOCK) WHERE [LocaleCode] = @LocaleCode)
			,@IsPM				bit = ISNULL((SELECT CAST(1 AS bit) FROM [v_Distributor] WHERE [sDistributorID] = @DistributorID AND [sType] in ('MB', 'PM')), 0);

	SELECT @Error = 0, @ErrorMessage = '';
	
	-- Preferred/Charter Member patch
    SELECT @PMLevel = ISNULL(PL.PrimaryLevelCode, @PMLevel)
    FROM dbo.PMPrimaryLevel PL WITH (NOLOCK)
     INNER JOIN PubEvents.dbo.dimDSSubType DSS WITH (NOLOCK)
        ON DSS.SubTypeCode = @PMLevel
    INNER JOIN dbo.PMPrimaryLevelDSSubtype PLS WITH (NOLOCK)
        ON PLS.PK_PMPrimaryLevel = PL.PK_PMPrimaryLevel AND PLS.PK_DSSubType = DSS.PK_DSSubType

	BEGIN TRY;

		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1
		END

		-- Get all events that @UserName has access to
		--
		IF OBJECT_ID('tempdb.dbo.#Access') IS NOT NULL
			DROP TABLE #Access;

		WITH cte_locale_access AS (
			SELECT DISTINCT 
					em.[PK_Locale]
				FROM EventATAccessUserModules AS em  WITH (NOLOCK) 
					INNER JOIN EventATAccessUser AS eu  WITH (NOLOCK) ON eu.[PK_EventATAccessUser] = em.[PK_EventATAccessUser]
					INNER JOIN Locales AS l  WITH (NOLOCK) ON l.PK_Locale = em.PK_Locale
				WHERE (ISNULL(@UserName, '') = '' OR eu.[EventATAccessUserName] = @UserName)
		)
		,cte_chk_access AS (
			SELECT 
					e.[PK_Event]
					,CASE WHEN c.[PK_Locale] IS NOT NULL THEN 1 ELSE 0 END AS [HasAccess]
				FROM [dbo].[Event] AS e WITH (NOLOCK) 
					INNER JOIN [EventDistributorCountryLocales] AS el  WITH (NOLOCK) ON el.[PK_Event] = e.[PK_Event]
					LEFT JOIN cte_locale_access AS c ON c.[PK_Locale] = el.[PK_Locale]
				WHERE e.[PK_EventType] = 15
		)
		SELECT 
				PK_Event
				,MAX(HasAccess) AS HasAccess
			INTO #Access
			FROM cte_chk_access
			GROUP BY PK_Event;

		CREATE INDEX ix_tmp_access_pk_event ON #Access(PK_Event);

		-- Generate Preferred Member Promotions list
		--
		IF OBJECT_ID('tempdb.dbo.#PromoList') IS NOT NULL
			DROP TABLE #PromoList;

		WITH cte_auth_locales AS (			
			SELECT 
					[PK_Locale]
					,[LocaleCode]
				FROM Locales WITH (NOLOCK) 
				WHERE ((ISNULL(@LocaleCode, '') = '') OR [LocaleCode] = @LocaleCode)
					AND (ISNULL(@UserName, '') = '' 
						OR PK_Locale IN (SELECT DISTINCT em.[PK_Locale]
											FROM EventATAccessUserModules AS em WITH (NOLOCK) 
												INNER JOIN EventATAccessUser AS eu WITH (NOLOCK)  ON eu.[PK_EventATAccessUser] = em.[PK_EventATAccessUser]
											WHERE eu.[EventATAccessUserName] = @UserName))					
		),
		own AS 
        (
            SELECT  
                STRING_AGG(au.EventATAccessUserName, ',') AS Owners,
                eo.PK_Event
            FROM [dbo].[EventOwners] eo WITH (NOLOCK)
            INNER JOIN [dbo].[EventATAccessUser] au WITH (NOLOCK) ON au.PK_EventATAccessUser = eo.PK_EventATAccessUser
            where eo.pk_event = @PK_Event
            GROUP BY eo.PK_Event
        )
		,cte_level AS (
			SELECT 
					e.[PK_Event]
					,edt.[DSTeamTypeCode]
					,CASE WHEN e.[PK_DefaultLocale] = eld.PK_Locale THEN 1 ELSE 0 END AS [DefaultLocale]
					,e.[PK_DefaultLocale]
					,a.[HasAccess]
					,e.[dStartUTC] AS StartDate
					,e.[dEndUTC] AS EndDate
					,e.DisplayStartDate									-- T 327639 : Adding DisplayDate, + Filter the list when called from DS side
					,e.DisplayEndDate									-- T 327639 : Adding DisplayDate, + Filter the list when called from DS side 					
					,e.[CreatedBy]
					,e.[CreatedDateUTC]
					,e.[ModifiedBy]
					,e.[ModifiedDateUTC]
					,e.[IsPublish]
					,ISNULL(eld.[EventName], 'DRAFT ' + CAST(e.[PK_Event] AS VARCHAR(100))) AS [EventName]
					,eld.[EventDesc]
					,eld.[PK_Locale]
					,l.[LocaleCode]
					,CASE WHEN @PK_Locale IN (SELECT [PK_Locale] FROM [EventDistributorCountryLocales] (NOLOCK) WHERE [PK_Event] = e.[PK_Event]) THEN 1 ELSE 0 END AS ShowLocale
					,e.[Location]
					,e.[EventTimeZone]
					,CASE WHEN @PK_Locale IN (SELECT [PK_Locale] FROM [EventLocaleDesc] (NOLOCK) WHERE [PK_Event] = e.[PK_Event]) THEN 0 ELSE 1 END AS [RenderDeafultLocale]
					,ISNULL(ext.EnableTesting,0) AS [EnableTesting]
					,eo.Owners
				FROM [dbo].[EventDSTeamType] edt WITH (NOLOCK) 
					INNER JOIN [Event] AS e WITH (NOLOCK)  ON edt.[PK_Event] = e.[PK_Event]
					INNER JOIN [EventLocaleDesc] AS eld  WITH (NOLOCK) ON eld.[PK_Event] = e.[PK_Event]
					INNER JOIN [Locales] AS l  WITH (NOLOCK) ON l.[PK_Locale] = eld.[PK_Locale]
					INNER JOIN [#Access] AS a ON a.[PK_Event] = e.[PK_Event]
					INNER JOIN [EventExtn] AS ext WITH (NOLOCK)  ON ext.[PK_Event] = e.[PK_Event]
                    LEFT JOIN own AS eo ON eo.PK_Event = e.PK_Event
				WHERE e.[PK_EventType] = @PK_EventType
					AND (ISNULL(@EventName, '') = '' OR eld.[EventName] LIKE '%' + @EventName + '%')
					AND (ISNULL(@PMLevel, '') = '' OR [DSTeamTypeCode] = @PMLevel)
					AND (e.[IsActive] = 1)
		)
		,cte_default_locale_img AS (
			SELECT DISTINCT
					eild.[PK_Event]
					,eild.[EventImageLocation]
					,eild.[PK_Locale]
				FROM [dbo].[EventImage] AS ei WITH (NOLOCK) 
						LEFT JOIN [dbo].[EventImageLocaleDesc] AS eild  WITH (NOLOCK) ON eild.[PK_EventImage] = ei.[PK_EventImage]
						INNER JOIN cte_level AS c  WITH (NOLOCK) ON c.[PK_Event] = eild.[PK_Event]
					WHERE ei.[PK_EventImageType] = @PK_EventImageType
						AND eild.[PK_Locale] = c.[PK_DefaultLocale]
		)
		,cte_img AS (
			SELECT DISTINCT
					ei.[PK_Event]
					,ei.[PK_EventImage]
					,eild.[PK_EventImageLocaleDesc]
					,ei.[PK_EventImageType]
					,eit.[EventImageType]
					,eild.[PK_Locale]
					,l.[LocaleCode]
					,eild.[EventImageLocation]
				FROM [dbo].[EventImage] AS ei WITH (NOLOCK) 
					LEFT JOIN [dbo].[EventImageLocaleDesc] AS eild  WITH (NOLOCK) ON eild.[PK_EventImage] = ei.[PK_EventImage]
					INNER JOIN cte_level AS c ON c.[PK_Event] = eild.[PK_Event]
					INNER JOIN cte_auth_locales AS l ON l.[PK_Locale] = eild.[PK_Locale]
					INNER JOIN [dbo].[EventImageType] AS eit  WITH (NOLOCK) ON eit.[PK_EventImageType] = ei.[PK_EventImageType]
				WHERE ei.[PK_EventImageType] = @PK_EventImageType
		)
		,cte_output AS (
			SELECT DISTINCT
					c.[PK_Event]
					,c.[PK_Locale]
					,CASE WHEN @UserLevel = 1 THEN c.[DSTeamTypeCode] ELSE '' END AS [DSTeamTypeCode]
					,c.[LocaleCode]
					,c.[EventName]
					,c.[EventDesc]
					,i.[EventImageLocation] AS [Thumbnail]
					,c.[StartDate]
					,c.[EndDate]
					,c.DisplayStartDate					-- T 327639 : Adding DisplayDate, + Filter the list when called from DS side
					,c.DisplayEndDate					-- T 327639 : Adding DisplayDate, + Filter the list when called from DS side					
					,c.[CreatedBy]
					,c.[CreatedDateUTC]
					,uc.[EventATAccessUserFirstName] + uc.[EventATAccessUserLastName] AS [CreatedByUserName]
					,c.[ModifiedBy]
					,uu.[EventATAccessUserFirstName] + uu.[EventATAccessUserLastName] AS [ModifiedByUserName]
					,c.[ModifiedDateUTC]
					,c.[IsPublish]
					,c.[Location]
					,c.[EventTimeZone]
					,c.[DefaultLocale]
					,s.[ValidSections]
					,s.[n]
					,c.EnableTesting
                    ,c.Owners
					,ROW_NUMBER() OVER (PARTITION BY c.PK_Event ORDER BY (CASE WHEN c.PK_Locale = @PK_Locale THEN 0
						WHEN c.PK_Locale IS NULL THEN 2 
						ELSE 3 END) ASC) 
					AS [LocaleOrder]
					,CASE WHEN c.PK_Locale = @PK_Locale THEN 0
						WHEN c.PK_Locale IS NULL THEN 2 
						ELSE 3 END AS LocaleFilter
				FROM cte_level AS c
					LEFT JOIN cte_img AS i ON i.[PK_Event] = c.[PK_Event]
						AND i.[PK_Locale] = c.[PK_Locale]
					LEFT JOIN [dbo].[EventATAccessUser] AS uc  WITH (NOLOCK) ON uc.[EventATAccessUserName] = c.[CreatedBy]
					LEFT JOIN [dbo].[EventATAccessUser] AS uu  WITH (NOLOCK) ON uu.[EventATAccessUserName] = c.[ModifiedBy]
					CROSS APPLY dbo.udf_EventsAT_Get_PMPromoStatus(c.[PK_Event], default, default, default, default, default, default, default) AS s
				WHERE ((ISNULL(@PK_Event, 0) = 0) OR c.[PK_Event] = @PK_Event)
					AND (((ISNULL(@dStartUTC, '19500101') = '19500101') OR (ISNULL(@dEndUTC, '19500101') = '19500101')) OR (c.[StartDate] BETWEEN @dStartUTC AND @dEndUTC))
					AND ((c.[DefaultLocale] = 1 AND c.[HasAccess] = 1) OR @DefaultLocale = 0)
					AND (c.ShowLocale = 1 OR @DefaultLocale = 1 OR ISNULL(@LocaleCode, '') = '')
					AND (@OnlyPublished = 0 OR ((c.IsPublish = @OnlyPublished) 
												 AND (c.DisplayStartDate IS NULL OR c.DisplayStartDate <= (SYSDATETIMEOFFSET()  AT TIME ZONE 'UTC' AT TIME ZONE c.location) )  -- T 327639 : Adding DisplayDate, + Filter the list when called from DS side
												 AND (c.DisplayEndDate IS NULL OR c.DisplayEndDate >=(SYSDATETIMEOFFSET()  AT TIME ZONE 'UTC' AT TIME ZONE c.location) )		-- T 327639 : Adding DisplayDate, + Filter the list when called from DS side										 
												)
						)
					AND (c.PK_Locale = Case when c.RenderDeafultLocale = 0 then c.PK_Locale else c.PK_DefaultLocale end)
			
		)			
		SELECT 
				c.[PK_Event]
				,c.[DSTeamTypeCode]
				,c.[PK_Locale]
				,c.[LocaleCode]
				,c.[EventName]
				,c.[EventDesc]
				,ISNULL(c.[Thumbnail], (SELECT [EventImageLocation] FROM cte_default_locale_img WHERE [PK_Event] = c.PK_Event)) AS [Thumbnail]
				,c.[StartDate]
				,c.[EndDate]
				,c.DisplayStartDate				-- T 327639 : Adding DisplayDate, + Filter the list when called from DS side
				,c.DisplayEndDate				-- T 327639 : Adding DisplayDate, + Filter the list when called from DS side					
				,c.[CreatedBy]
				,c.[CreatedDateUTC]
				,c.[CreatedByUserName]
				,c.[ModifiedBy]
				,c.[ModifiedByUserName]
				,c.[ModifiedDateUTC]
				,c.[IsPublish]
				,c.[DefaultLocale]
				,c.[Location]
				,c.[EventTimeZone]
				,c.EnableTesting
                ,c.Owners
				,STUFF(( SELECT  ', ' + [DSTeamTypeCode] 
							FROM [dbo].[EventDSTeamType] WITH (NOLOCK) 
							WHERE PK_Event = c.PK_Event
							FOR XML PATH(''), TYPE
						).value('.', 'NVARCHAR(MAX)'), 1, 2, '')
				AS [LevelAudience]
				,STUFF(( SELECT  ', ' + [LanguageCountryRegion]
							FROM [dbo].[EventDistributorCountryLocales] AS e WITH (NOLOCK) 
								INNER JOIN [dbo].[Locales] AS l  WITH (NOLOCK) ON e.[PK_Locale] = l.[PK_Locale]
							WHERE [PK_Event] = c.[PK_Event]
			                FOR XML PATH(''), TYPE
						).value('.', 'NVARCHAR(MAX)'), 1, 2, '') 
				AS [CountryAudience]
				,CASE WHEN (ValidSections IS NULL) OR (ValidSections != n) THEN 'DRAFT'
					WHEN (ISNULL(c.EnableTesting, 0) = 1) THEN 'TEST'
					WHEN c.[StartDate] > @Today THEN 'UPCOMING'
					WHEN @Today > c.[EndDate] THEN 'ENDED'
					ELSE 'ACTIVE' 
				END AS [EventStatus]
				,ROW_NUMBER() OVER (ORDER BY (CASE WHEN (ValidSections IS NULL) OR (ValidSections != n) THEN 4 --DRAFT
													WHEN c.[StartDate] > @Today THEN 2 -- UPCOMING
													WHEN @Today > c.[EndDate] THEN 3 -- ENDED
													ELSE 1 -- ACTIVE
												END) ASC
												,ISNULL(c.[StartDate], '2079-06-06') DESC
												,ISNULL(c.[ModifiedDateUTC], '2079-06-06') DESC
												,ISNULL(c.[EndDate], '2079-06-06') DESC
				) AS [r1]
				,ROW_NUMBER() OVER (ORDER BY (CASE WHEN (ValidSections IS NULL) OR (ValidSections != n) THEN 4 --DRAFT
													WHEN c.[StartDate] > @Today THEN 2 -- UPCOMING
													WHEN @Today > c.[EndDate] THEN 3 -- ENDED
													ELSE 1 -- ACTIVE
												END) ASC
												,ISNULL(c.[EndDate], '2079-06-06') DESC
												,ISNULL(c.[StartDate], '2079-06-06') DESC
												,ISNULL(c.[ModifiedDateUTC], '2079-06-06') DESC
				) AS [r2]
				,ROW_NUMBER() OVER (ORDER BY (CASE WHEN (ValidSections IS NULL) OR (ValidSections != n) THEN 4 --DRAFT
													WHEN c.[StartDate] > @Today THEN 2 -- UPCOMING
													WHEN @Today > c.[EndDate] THEN 3 -- ENDED
													ELSE 1 -- ACTIVE
												END) ASC
												,ISNULL(c.[ModifiedDateUTC], '2079-06-06') DESC
												,ISNULL(c.[StartDate], '2079-06-06') DESC
												,ISNULL(c.[EndDate], '2079-06-06') DESC
				) AS [r3]
				,CASE WHEN (ValidSections IS NULL) OR (ValidSections != n) THEN 4 -- DRAFT
					WHEN c.[StartDate] > @Today THEN 2 -- UPCOMING
					WHEN @Today > c.[EndDate] THEN 3 -- ENDED
					ELSE 1 -- ACTIVE
				END AS [StatusOrder]
				,LocaleOrder
				,LocaleFilter
			INTO #PromoList
			FROM cte_output AS c
			WHERE ((ISNULL(@EventStatus, '') = '' 
					OR (CASE WHEN (ValidSections IS NULL) OR (ValidSections != n) THEN 'DRAFT'
							WHEN (ISNULL(c.EnableTesting, 0) = 1) THEN 'TEST'
							WHEN c.[StartDate] > @Today THEN 'UPCOMING'
							WHEN @Today > c.[EndDate] THEN 'ENDED'
							ELSE 'ACTIVE' 
						END) = @EventStatus)
					)
				AND LocaleOrder = 1;

		CREATE INDEX ix_#promolist_PK_Event on #promolist(PK_Event)

		-- If @UserName is provided, check UploadedMember table
		IF(@DistributorID IS NOT NULL AND @OnlyPublished = 1 AND @IsPM = 1)
        BEGIN
            WITH cte_event_um AS (
                SELECT [PK_Event] FROM [UploadedMember]  WITH (NOLOCK) WHERE [PK_Event] IN (SELECT [PK_Event] FROM #PromoList) GROUP BY [PK_Event]
            )
            ,cte_filterpm AS (
                SELECT
                        [PK_Event]
                        ,(SELECT DistributorID from UploadedMember  WITH (NOLOCK) where PK_Event = U.PK_Event AND DistributorID = @DistributorID) AS [DistributorID]
                    FROM cte_event_um as U
            )
            DELETE p
                FROM #PromoList as p
                WHERE p.PK_Event IN (SELECT PK_Event FROM cte_filterpm WHERE DistributorID is null)
        END;

		-- Return data columns
		SELECT DISTINCT
				[PK_Event]
				,[DSTeamTypeCode]
				,[LocaleCode]
				,[EventName]
				,[EventDesc]
				,[Thumbnail]
				,[StartDate]
				,[EndDate]
				,[CreatedBy]
				,[CreatedDateUTC]
				,[CreatedByUserName]
				,[ModifiedBy]
				,[ModifiedByUserName]
				,[ModifiedDateUTC]
				,[IsPublish]
				,[DefaultLocale]
				,[Location]
				,[LevelAudience]
				,[CountryAudience]
				,[EventTimeZone]
				,[EventStatus]
				,(CASE @SortBy
					WHEN 1 THEN [r1]
					WHEN 2 THEN [r2]
					ELSE [r3]
				END) AS [Row]
				,[StatusOrder]
                ,EnableTesting
                ,Owners
			FROM #PromoList 
			WHERE ((ISNULL(@Start, 0) = 0 OR ISNULL(@Rows, 0) = 0) 
						OR ((CASE @SortBy WHEN 1 THEN [r1] WHEN 2 THEN [r2] ELSE [r3] END) BETWEEN @Start AND (@Start + @Rows - 1)))
			ORDER BY [Row];

		-- Return pagination variables
		SELECT	@Rows = @@ROWCOUNT, @Total = (SELECT COUNT(1) FROM #PromoList);


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
END;
