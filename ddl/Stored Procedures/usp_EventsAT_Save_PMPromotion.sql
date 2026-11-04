CREATE PROCEDURE [dbo].[usp_EventsAT_Save_PMPromotion]

	-- REQUIRED
	@UserName			nvarchar(255)
	,@DefaultLocale		nvarchar(5)	
	,@TargetAudience	xml
	,@TeamLevels		xml

	-- Optional
	,@PK_Event			int = NULL
	,@EventName			nvarchar(400) = NULL 
	,@dStartUTC			datetime2 = NULL
	,@dEndUTC			datetime2 = NULL
	--,@Timezone			nvarchar(255) = NULL	-- Using Event.Location in PM Promotion to save the timezone as string
	--,@EventTimeZone		decimal(5, 2) = NULL
	
	--Defaults
	,@PK_EventType		int = 15
	,@NamePrefix		varchar(50) = 'DRAFT'
	,@Separator			varchar(5) = '_'

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Save_PMPromotion

	USE:			
					DECLARE @sTeamLevels varchar(max) = N'
						<TeamLevels>
							<SubLevel>BCM</SubLevel>
							<SubLevel>SCM</SubLevel>
						</TeamLevels>'
						,@sTargetAudience varchar(max) = N'
							<TargetAudience>
								<Locale>en-US</Locale>
								<Locale>es-US</Locale>
							</TargetAudience>'
						,@TeamLevels xml, @TargetAudience xml;

				DECLARE @e int, @em varchar(4000)			

				SELECT @TeamLevels = cast(@sTeamLevels as xml), @TargetAudience = cast(@sTargetAudience as xml);

				EXEC dbo.usp_EventsAT_Save_PMPromotion
						@UserName = 'RogelioR'
						,@DefaultLocale = 'es-US'
						,@TargetAudience = @TargetAudience
						,@TeamLevels = @TeamLevels
						,@EventName = 'Nueva Promoción Para Miembros'
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	Insert/Updates a Preferred Member Promotion on Event

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event, dbo.EventLocaleDesc, dbo.EventExtn, dbo.EventDSTeamType, dbo.EventDistributorCountryLocales

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-03-28		RogelioR		Initial
	2.0.0		2019-08-08		NoeG			Refactor code (SRE)
	2.0.1		2019-10-17		alejandramed	SRE Compliance 
	2.0.2		2020-01-28		NoeG			Manage Preferred Members Configured Information for Primary Levels

******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	DECLARE @t table ([action] nvarchar(15), PK_Key int);

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@PK_EventExtn		int
			--,@PK_Locale			int
			,@PK_DefaultLocale	int;
			
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		-- Promotion ending date must be greater than start date
		IF ((@dStartUTC IS NOT NULL) AND (@dEndUTC IS NOT NULL))
		BEGIN
			IF (@dEndUTC <= @dStartUTC)
			BEGIN
				RAISERROR('Event not added. The start date cannot be greater than the end date.', 11, 1);
				SELECT 0 AS PK_Event;
			END
		END
		
		SELECT @PK_DefaultLocale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @DefaultLocale;
	
		-----------------------------------------------------------------------------------------------------------------------
		-- Merge promotion
		--
		MERGE dbo.[Event] AS t
			USING (	SELECT
						@PK_Event AS [PK_Event]
						,0 AS [IsTicketPurchaseRequired]
						,0 AS [IsPreRegistrationRequired]
						,0 AS [CanAssignTickets]
						,0 AS [CanPurchaseTicketOnline]
						,0 AS [IsRFIDRequired]
						,0 AS [CanRegisterOnline]
						,0 AS [IsHotelEnabled]
						,0 AS [CanShowCurrentQualOnline]
						,0 AS [MaxNoOfGuest]
						,0 AS [MaxNoOfPrimaryGuest]
						,0 AS [MaxCapacity]
						,0 AS [ExpectedCapacity]
						,1 AS [IsPromotion]
						,1 AS [IsActive]
						--,@TimeZone AS [Location]
						--,@EventTimeZone AS [EventTimeZone]
						,@PK_EventType AS [PK_EventType]
						,@EventName AS [EventName]
						,@dStartUTC AS [dStartUTC]
						,@dEndUTC AS [dEndUTC]
						,0 AS [IsInventoryEnabled]
						,0 AS [IsTrackLogoAvail]
						,@PK_DefaultLocale AS [PK_DefaultLocale]
						,0 AS [IsPublish]
						,@UserName AS [CreatedBy]
						,GETUTCDATE() AS [CreatedDateUTC]
						,@UserName AS [ModifiedBy]
						,GETUTCDATE() AS [ModifiedDateUTC]
					) AS s
					ON (t.PK_Event = s.PK_Event)
			WHEN MATCHED THEN
				UPDATE SET
					[EventName] = ISNULL(s.[EventName], t.[EventName])
					--,[Location] = s.[Location]
					--,[EventTimeZone] = s.[EventTimeZone]
					,[ModifiedBy] = s.[ModifiedBy]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
			WHEN NOT MATCHED THEN
				INSERT (
					[IsTicketPurchaseRequired]
					,[IsPreRegistrationRequired]
					,[CanAssignTickets]
					,[CanPurchaseTicketOnline]
					,[IsRFIDRequired]
					,[CanRegisterOnline]
					,[IsHotelEnabled]
					,[CanShowCurrentQualOnline]
					,[MaxNoOfGuest]
					,[MaxNoOfPrimaryGuest]
					,[MaxCapacity]
					,[ExpectedCapacity]
					,[IsPromotion]
					,[IsActive]
					--,[Location]		-- Used in PM Promotion to save the timezone as string
					--,[EventTimeZone]
					,[PK_EventType]
					,[EventName]
					,[dStartUTC]
					,[dEndUTC]
					,[IsInventoryEnabled]
					,[IsTrackLogoAvail]
					,[PK_DefaultLocale]
					,[IsPublish]
					,[CreatedBy]
					,[CreatedDateUTC]
					,[ModifiedBy]
					,[ModifiedDateUTC]
				)
				VALUES (
					s.[IsTicketPurchaseRequired]
					,s.[IsPreRegistrationRequired]
					,s.[CanAssignTickets]
					,s.[CanPurchaseTicketOnline]
					,s.[IsRFIDRequired]
					,s.[CanRegisterOnline]
					,s.[IsHotelEnabled]
					,s.[CanShowCurrentQualOnline]
					,s.[MaxNoOfGuest]
					,s.[MaxNoOfPrimaryGuest]
					,s.[MaxCapacity]
					,s.[ExpectedCapacity]
					,s.[IsPromotion]
					,s.[IsActive]
					--,s.[Location]
					--,s.[EventTimeZone]
					,s.[PK_EventType]
					,s.[EventName]
					,s.[dStartUTC]
					,s.[dEndUTC]
					,s.[IsInventoryEnabled]
					,s.[IsTrackLogoAvail]
					,s.[PK_DefaultLocale]
					,s.[IsPublish]
					,s.[CreatedBy]
					,s.[CreatedDateUTC]
					,s.[ModifiedBy]
					,s.[ModifiedDateUTC]
				)
			OUTPUT $action, inserted.PK_Event INTO @t
		;	-- MERGE Event

		SELECT @PK_Event = PK_Key FROM @t;	-- Return the New/Updated Event Id

		IF @EventName IS NULL
			UPDATE [dbo].[Event] SET 
				[EventName] = @NamePrefix + @Separator + CAST(@PK_Event AS varchar(255)) + @Separator + (SELECT CONVERT(varchar(10),[CreatedDateUTC], 120) FROM @t WHERE PK_Event = @PK_Event)
				WHERE PK_Event = @PK_Event;
			
		IF(@IsDevQA = 1)	-- Show event
			SELECT 'Record in Event ---' FROM [Event] AS e WHERE e.PK_Event = (@PK_Event);
		

		-----------------------------------------------------------------------------------------------------------------------
		-- Merge dbo.EventLocaleDesc
		--
		MERGE [dbo].[EventLocaleDesc] AS t
			USING ( SELECT
						@PK_Event AS [PK_Event]
						,@PK_EventType AS [PK_EventType]
						,@PK_DefaultLocale AS [PK_Locale]
						,@PK_DefaultLocale AS [PK_DefaultLocale]
						,@UserName AS [CreatedBy]
						,GETUTCDATE() AS [CreatedDateUTC]
						,@UserName AS [ModifiedBy]
						,GETUTCDATE() AS [ModifiedDateUTC]
				) AS s
				ON (t.[PK_event] = @PK_Event AND t.[PK_EventType] = @PK_EventType)
			WHEN NOT MATCHED BY TARGET THEN
				INSERT (
					[PK_Event]
					,[PK_EventType]
					,[PK_Locale]
					,[PK_DefaultLocale]
				)
				VALUES (
					s.[PK_Event]
					,s.[PK_EventType]
					,s.[PK_Locale]
					,s.[PK_DefaultLocale]
				)
			WHEN MATCHED THEN
				UPDATE SET
					[PK_DefaultLocale] = s.[PK_DefaultLocale]
		;

		IF(@IsDevQA = 1)	-- Show EventLocaleDesc
			SELECT 'Record in EventLocaleDesc ---' FROM [EventLocaleDesc] AS eld WHERE eld.PK_Event = (@PK_Event);
		

		-----------------------------------------------------------------------------------------------------------------------
		-- Merge EventExtn
		--
		MERGE dbo.EventExtn AS t
			USING ( SELECT
						(SELECT TOP 1 [PK_EventExtn] FROM [dbo].[EventExtn] WITH(NOLOCK) WHERE [PK_Event] = @PK_Event) AS [PK_EventExtn]
						,@UserName AS [UserName]
						,@PK_Event AS [PK_Event]
						,1 AS [IsDisplayTVP]
						,1 AS [IsDisplayRO]
						,1 AS [IsDisplayPPV]
						,1 AS [IsDisplayPB]
						,@UserName AS [CreatedBy]
						,GETUTCDATE() AS [CreatedDateUTC]
						,@UserName AS [ModifiedBy]
						,GETUTCDATE() AS [ModifiedDateUTC]
				) AS s
				ON ( t.[PK_EventExtn] = s.[PK_EventExtn] )
			WHEN MATCHED THEN
				UPDATE SET
					[ModifiedBy] = s.[ModifiedBy]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
			WHEN NOT MATCHED THEN
				INSERT (
					[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
					,[PK_Event]
					,[IsDisplayTVP]
					,[IsDisplayRO]
					,[IsDisplayPPV]
					,[IsDisplayPB]
				)
				VALUES (
					s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
					,s.[PK_Event]
					,s.[IsDisplayTVP]
					,s.[IsDisplayRO]
					,s.[IsDisplayPPV]
					,s.[IsDisplayPB]
				)
			OUTPUT $action, inserted.PK_EventExtn INTO @t
		; -- Merge EventExtn
		
		SELECT @PK_EventExtn = PK_Key FROM @t;

		IF(@IsDevQA = 1)	-- Show EventExtn
		BEGIN
			SELECT 'Record in EventExtn ---' FROM [EventExtn] AS ee WHERE ee.[PK_EventExtn] = (@PK_EventExtn);
		END;


		-----------------------------------------------------------------------------------------------------------------------
		-- Merge EventDistributorCountryLocales
		--
		WITH cte_Locales AS (
			SELECT Locale.query('.').value('Locale[1]', 'varchar(20)') AS LocaleCode
				FROM @TargetAudience.nodes('/TargetAudience/*') AS TargetAudience(Locale)
		)
		MERGE [dbo].[EventDistributorCountryLocales] AS t
			USING ( SELECT
							l.[PK_Locale] AS [PK_Locale]
							,sl.[LocaleCode] AS [LocaleCode]
							,CASE WHEN sl.[LocaleCode] = @DefaultLocale THEN 1 ELSE 0 END AS [IsDefault]
						FROM cte_Locales AS sl WITH(NOLOCK)
							INNER JOIN [dbo].[Locales] AS l WITH(NOLOCK) ON l.[LocaleCode] = sl.[LocaleCode]
				) AS s
				ON ( t.[PK_Event] = @PK_Event AND t.[PK_Locale] = s.[PK_Locale])
			WHEN MATCHED THEN
				UPDATE SET
					[IsDefault] = s.[IsDefault]
					,[ModifiedDateUTC] = GETUTCDATE()
					,[ModifiedBy] = @UserName
			WHEN NOT MATCHED BY TARGET THEN
				INSERT (
					[PK_Event]
					,[PK_Locale]
					,[IsDefault]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
				)
				VALUES (
					@PK_Event
					,s.[PK_Locale]
					,s.[IsDefault]
					,GETUTCDATE()
					,@UserName
					,GETUTCDATE()
					,@UserName
				)
			WHEN NOT MATCHED BY SOURCE AND t.PK_Event = @PK_Event THEN
				DELETE
			OUTPUT $action, inserted.PK_EventDistributorCountryLocales INTO @t
		; -- Merge EventDistributorCountryLocales
		
		IF(@IsDevQA = 1)	-- Show EventDistributorCountryLocales
		BEGIN
			SELECT 'Results in EventDistributorCountryLocales';
			SELECT 	[PK_EventDistributorCountryLocales],
					[PK_Event],
					[PK_Locale],
					[IsDefault],
					[CreatedDateUTC],
					[CreatedBy],
					[ModifiedDateUTC],
					[ModifiedBy] 
					FROM [EventDistributorCountryLocales] AS edcl 
					WHERE edcl.PK_Event = (@PK_Event);
		END;
		
		-----------------------------------------------------------------------------------------------------------------------
		-- Merge EventDSTeamType
		--	
		WITH cte_SubLevel AS (
			SELECT SubLevel.query('.').value('SubLevel[1]', 'varchar(20)') AS SubLevel
				FROM @TeamLevels.nodes('/TeamLevels/*') AS TeamLevels(SubLevel)
		)
		MERGE dbo.EventDSTeamType AS t
			USING ( 
					SELECT	ST.SubTypeCode AS [DSTeamTypeCode]
							,@PK_Event AS [PK_Event]
					FROM	cte_SubLevel sl
							INNER JOIN PubEvents..dimDSSubType ST WITH (NOLOCK)
								ON sl.SubLevel = ST.SubTypeCode
							LEFT JOIN dbo.DSTeamType mt WITH (NOLOCK)
								ON ST.SubTypeCode = mt.DSTeamTypeCode
					Union
					SELECT	ST.SubTypeCode AS [DSTeamTypeCode]
							,@PK_Event AS [PK_Event]
					FROM	PubEvents..dimDSSubType ST WITH (NOLOCK)
							INNER JOIN PMPrimaryLevelDSSubType PLST WITH (NOLOCK)
								ON ST.PK_DSSubType = PLST.PK_DSSubType
							INNER JOIN PMPrimaryLevel PL WITH (NOLOCK)
								ON PLST.PK_PMPrimaryLevel = PL.PK_PMPrimaryLevel
							INNER JOIN cte_SubLevel sl
								ON sl.SubLevel = PL.PrimaryLevelCode
							LEFT JOIN dbo.DSTeamType mt WITH (NOLOCK)
								ON ST.SubTypeCode = mt.DSTeamTypeCode
				) AS s
				ON (t.[PK_Event] = @PK_Event AND t.[DSTeamTypeCode] = s.[DSTeamTypeCode])
			WHEN NOT MATCHED THEN
				INSERT (
					[DSTeamTypeCode]
					,[PK_Event]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
				)
				VALUES (
					s.[DSTeamTypeCode]
					,s.[PK_Event]
					,GETUTCDATE()
					,@UserName
					,GETUTCDATE()
					,@UserName
				)
			WHEN NOT MATCHED BY SOURCE AND t.[PK_Event] = @PK_Event THEN
				DELETE
			OUTPUT $action, inserted.PK_EventDSTeamType INTO @t
		;
		
		IF(@IsDevQA = 1)	-- Show EventDSTeamType
		BEGIN
			SELECT 'Results in EventDSTeamType';
			SELECT	[PK_EventDSTeamType],
					[DSTeamTypeCode],
					[PK_Event],
					[CreatedDateUTC],
					[CreatedBy],
					[ModifiedDateUTC],
					[ModifiedBy]
			FROM [EventDSTeamType] AS edt WHERE edt.PK_Event = (@PK_Event);
		END;

		SELECT @PK_Event AS PK_Event;

		-----------------------------------------------------------------------------------------------------------------------
		-- UPDATE PROCESSING LOG
		EXEC dbo.usp_Utility_UpdateProcessingLog 
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
GO

