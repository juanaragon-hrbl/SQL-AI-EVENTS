
CREATE PROCEDURE [dbo].[usp_EventAPI_Save_BreakoutSession]
		-- Mandatory
		@PK_Event int
		,@StartTime datetime
		,@EndTime datetime
		,@Capacity int
		,@RegistrationDeadlineDate datetime
		,@AllowPartnerRegistration bit
		,@ManageLanguages bit

		-- Optional
		,@PK_SubEvent int = null
		,@SessionLocales xml = null
		,@GuestSpeakers xml = null
		,@Qualifications xml = null
		,@SessionPreferredLanguages xml = null

		-- Defaults
		,@GuestSpeakerImageType int = 3

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_EventAPI_Save_BreakoutSession]
	
	USE:
			DECLARE @e int, @em varchar(4000)
			
			DECLARE @sl varchar(max) = 
							'<SessionLocale>
								<PK_SubEventLocaleDesc></PK_SubEventLocaleDesc>
								<Locale>es-MX</Locale>
								<Title>Prueba nueva Breakout Session para es-MX</Title>
								<Description>Test New SubEvent es-MX</Description>
								<Location>Sala de entrenamiento 5</Location>
							</SessionLocale>
							<SessionLocale>
                                <PK_SubEventLocaleDesc></PK_SubEventLocaleDesc>
                                <Locale>en-GB</Locale>
                                <Title>Test New BreakoutSession en-GB</Title>
                                <Description>Test New SubEvent en-GB</Description>
                                <Location>Training room 5</Location>
                            </SessionLocale>'
			,@gs varchar(max) = 
							'<Speaker>
								<PK_EventGuestSpeaker></PK_EventGuestSpeaker>
								<SpeakerName>Katy Perry</SpeakerName>
								<PK_EventImageLocaleDesc></PK_EventImageLocaleDesc>
								<EventImageLocation>katyperry2.jpg</EventImageLocation>
								<SpeakerLocales>
									<SpeakerLocale>
										<Locale>es-MX</Locale>
										<Title>Srta</Title>
									</SpeakerLocale>
									<SpeakerLocale>
										<Locale>en-GB</Locale>
										<Title>Miss</Title>
									</SpeakerLocale>
								</SpeakerLocales>
							</Speaker>
							<Speaker>
								<PK_EventGuestSpeaker></PK_EventGuestSpeaker>
								<SpeakerName>Liam Neeson</SpeakerName>
								<PK_EventImageLocaleDesc></PK_EventImageLocaleDesc>
								<EventImageLocation>liam.jpg</EventImageLocation>
								<SpeakerLocales>
									<SpeakerLocale>
										<Locale>es-MX</Locale>
										<Title>Sr.</Title>
									</SpeakerLocale>
									<SpeakerLocale>
										<Locale>en-GB</Locale>
										<Title>Sr.</Title>
									</SpeakerLocale>
								</SpeakerLocales>
							</Speaker>'
			,@gq varchar(max) = 
							'
							<SubEventQualifications>
								<SubEventQualification>88098</SubEventQualification>
								<SubEventQualification>88099</SubEventQualification>
								<SubEventQualification>88100</SubEventQualification>
							</SubEventQualifications>'

			,@gl varchar(max) = 
							--'
							--<SubEventLanguages>
							--</SubEventLanguages>'
							'
							<SubEventLanguages>
								<SubEventLanguage>es-MX</SubEventLanguage>
							</SubEventLanguages>'
							--'
							--<SubEventLanguages>
							--	<SubEventLanguage>en-GB</SubEventLanguage>
							--	<SubEventLanguage>en-US</SubEventLanguage>
							--	<SubEventLanguage>es-MX</SubEventLanguage>
							--</SubEventLanguages>'

			,@SessionLocales xml
			,@GuestSpeakers xml
			,@Qualifications xml
			,@SessionPreferredLanguages xml
			,@IsDevQA bit = 1;
			
			SELECT @SessionLocales = cast(@sl as xml)
					,@GuestSpeakers = cast(@gs as xml)
					,@Qualifications = cast(@gq as xml)
					,@SessionPreferredLanguages = cast(@gl as xml);

			SELECT	@SessionLocales AS [SessionLocales]
					,@GuestSpeakers AS [GuestSpeakers]
					,@Qualifications AS [Qualifications]
					,@SessionPreferredLanguages AS [SubEventLanguages]
			
			EXEC [dbo].[usp_EventAPI_Save_BreakoutSession]
						@PK_Event = 63002
						,@StartTime = '20180630'
						,@EndTime = '20180730'
						,@Capacity = 320
						,@RegistrationDeadlineDate = '20180630'
						,@AllowPartnerRegistration = 1
						,@ManageLanguages = 1
						
						-- Optional
						,@PK_SubEvent = null
						,@SessionLocales = @SessionLocales
						,@GuestSpeakers = @GuestSpeakers
						,@Qualifications = @Qualifications
						,@SessionPreferredLanguages = @SessionPreferredLanguages
						,@Error = @e OUTPUT
						,@ErrorMessage = @em OUTPUT
						,@IsDevQA = 1

			SELECT @e, @em;

			select * from SubEvent where PK_Event = 63002 and PK_SubEventType = 5
			select * from EventImage where PK_Event = 63002
			select * from EventImageLocaleDesc where PK_Event = 63002
			select * from EventGuestSpeakers where PK_Event = 63002
			select * from EventGuestSpeakerLocale where PK_Event = 63002
			SELECT * FROM [BreakoutSessionSubEvent] where PK_Event = 63002
			select * form [BreakoutSessionPreferredLanguages] where PK_Event = 63002

			--delete from SubEvent where PK_Event = 63002 and PK_SubEventType = 5
			--delete from EventGuestSpeakerLocale where PK_Event = 63002
			--delete from EventGuestSpeakers where PK_Event = 63002
			--delete from EventImageLocaleDesc where PK_Event = 63002
			--delete from EventImage where PK_Event = 63002
			--delete FROM [BreakoutSessionSubEvent] where PK_Event = 63002

			select * from SubEvent
	DESCRIPTION: Save/Update a breakout session

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	[SubEvent], [EventGuestSpeakerLocale], [EventGuestSpeakers], [EventGuestSpeakerLocale], [EventImage], [EventImageLocaleDesc], [SubEventExtn], [BreakoutSessionPreferredLanguages]

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2018-05-24		RogelioR		Initial
	1.0.1		2019-01-16		NoeG			Process added to Save/Update the RegistrationDeadlineDate data to the SubEventExtn table.
	1.0.2		2019-01-21		NoeG			Process added to:
													- Save/Update the BreakoutSession Preferred Languages data
													- Save/Update the ManageLanguages Flag
	1.0.3		2019-09-05		NoeG			SRE template applied
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@PK_DefaultLocale int = (SELECT [PK_DefaultLocale] FROM [Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event);

	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		----------------------------------------------------------------------------------------------------------------------------
		-- Breakout session data
		--
		IF OBJECT_ID('tempdb..#BreakoutSessions') IS NOT NULL
			DROP TABLE #BreakoutSessions;

		WITH c AS (
			SELECT 
					@PK_Event AS [PK_Event]
					,@PK_SubEvent AS [PK_SubEvent]
					,@StartTime AS [BeginTime]
					,@EndTime AS [EndTime]
					,@Capacity AS [MaxCapacity]
					,@RegistrationDeadlineDate AS [RegistrationDeadlineDate]
					,@AllowPartnerRegistration AS [AllowPartnerRegistration]
					,@PK_DefaultLocale AS [PK_DefaultLocale]
					,(SELECT [LocaleCode] FROM [Locales] WITH (NOLOCK) WHERE [PK_Locale] = @PK_DefaultLocale) AS [DefaultLocale]
					,@ManageLanguages AS [ManageLanguages]
				
					-- Defaults
					,@Capacity AS [ExpectedCapacity]
					,100 AS [SubEventNumber]
					,NULL AS [SubEventFormula]
					,5 AS [PK_SubEventType]
					,1 AS [IncludeInBizworkReport]
					,0 AS [CanProcessQual]
					,0 AS [IsMainEventQual]
					,3 AS [PK_EventImageType]
					,GETUTCDATE() AS [CreatedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [ModifiedBy]
		)
		,cl AS (
			SELECT
					NULLIF(bs.col.value('PK_SubEventLocaleDesc[1]', 'int'), 0) AS [PK_SubEventLocaleDesc]
					,bs.col.value('Locale[1]', 'varchar(5)') AS [Locale]
					,l.[PK_Locale]
					,bs.col.value('Title[1]', 'varchar(255)') AS [SubEventName]
					,bs.col.value('Description[1]', 'varchar(MAX)') AS [SubEventQualDesc]
					,NULLIF(bs.col.value('QualDesc[1]', 'varchar(MAX)'), '') AS [QualDesc]
					,NULLIF(bs.col.value('Image[1]', 'varchar(MAX)'), '') AS [Image]
					,bs.col.value('Location[1]', 'varchar(255)') AS [Location]
				FROM @SessionLocales.nodes('/SessionLocale') AS bs(col)
					INNER JOIN [dbo].[Locales] AS l WITH (NOLOCK) ON l.[LocaleCode] = bs.col.value('Locale[1]', 'varchar(5)')
		)
		SELECT
				ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS [n]
				,c.[PK_Event]
				,c.[PK_SubEvent]
				,c.[BeginTime]
				,c.[EndTime]
				,c.[MaxCapacity]
				,c.[RegistrationDeadlineDate]
				,c.[AllowPartnerRegistration]
				,c.[PK_DefaultLocale]
				,c.[DefaultLocale]
				,c.[ManageLanguages]
				,c.[ExpectedCapacity]
				,c.[SubEventNumber]
				,c.[SubEventFormula]
				,c.[PK_SubEventType]
				,c.[IncludeInBizworkReport]
				,c.[CanProcessQual]
				,c.[IsMainEventQual]
				,c.[PK_EventImageType]
				,c.[CreatedDateUTC]
				,c.[CreatedBy]
				,c.[ModifiedDateUTC]
				,c.[ModifiedBy]
				,CASE WHEN cl.PK_Locale = c.[PK_DefaultLocale] THEN 1 ELSE 0 END AS [IsDefaultLocale]
				,cl.[PK_SubEventLocaleDesc]
				,cl.[Locale]
				,cl.[PK_Locale]
				,cl.[SubEventName]
				,cl.[SubEventQualDesc]
				,cl.[QualDesc]
				,cl.[Image]
				,cl.[Location]
			INTO #BreakoutSessions
			FROM c
				CROSS JOIN cl
		
		-- Check there is default locale on <SessionLocale> entries
		
		IF NOT EXISTS (SELECT [IsDefaultLocale] FROM #BreakoutSessions WHERE [IsDefaultLocale] = 1)
			RAISERROR('<SessionLocale> does not include Default Locale.', 12, 1, 'Custom Error');

		-- ************************************************************ Show ******************************
		IF @IsDevQA = 1
		BEGIN
			SELECT 'Starting #BreakoutSessions', n
												,PK_Event
												,PK_SubEvent
												,BeginTime
												,EndTime
												,MaxCapacity
												,RegistrationDeadlineDate
												,AllowPartnerRegistration
												,PK_DefaultLocale
												,DefaultLocale
												,ManageLanguages
												,ExpectedCapacity
												,SubEventNumber
												,SubEventFormula
												,PK_SubEventType
												,IncludeInBizworkReport
												,CanProcessQual
												,IsMainEventQual
												,PK_EventImageType
												,CreatedDateUTC
												,CreatedBy
												,ModifiedDateUTC
												,ModifiedBy
												,IsDefaultLocale
												,PK_SubEventLocaleDesc
												,Locale
												,PK_Locale
												,SubEventName
												,SubEventQualDesc
												,QualDesc
												,Image
												,Location FROM #BreakoutSessions
		END;


		----------------------------------------------------------------------------------------------------------------------------
		-- Guest speakers data
		--
		IF OBJECT_ID('tempdb..#GuestSpeakers') IS NOT NULL
			DROP TABLE #GuestSpeakers;

		WITH c AS (
			SELECT 
					ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS [n]
					,bs.col.value('PK_EventGuestSpeaker[1]', 'int') AS [PK_EventGuestSpeaker]
					,@PK_Event AS [PK_Event]
					,@PK_SubEvent AS [PK_SubEvent]
					,NULL AS [PK_EventImage]
					,(SELECT [PK_DefaultLocale] FROM Event WITH (NOLOCK) WHERE [PK_Event] = @PK_Event) AS [PK_DefaultLocale]
					,NULLIF(bs.col.value('EventSpeakerTitle[1]', 'varchar(255)'), '') AS [EventSpeakerTitle]
					,NULLIF(bs.col.value('SpeakerName[1]', 'varchar(255)'), '') AS [EventSpeakerName]
					,NULLIF(bs.col.value('PK_EventImageLocaleDesc[1]', 'int'), 0) AS [PK_EventImageLocaleDesc]
					,NULLIF(bs.col.value('EventImageLocation[1]', 'varchar(255)'), '') AS [EventImageLocation]
					,NULLIF(bs.col.value('EventSpeakerPhone[1]', 'varchar(255)'), '') AS [EventSpeakerPhone]
					,NULLIF(bs.col.value('EventSpeakerEmail[1]', 'varchar(255)'), '') AS [EventSpeakerEmail]
					,NULLIF(bs.col.value('EventSpeakerTeamLevel[1]', 'varchar(255)'), '') AS [EventSpeakerTeamLevel]
					,NULLIF(bs.col.value('EventSpeakerBio[1]', 'varchar(255)'), '') AS [EventSpeakerBio]
					,col.query('SpeakerLocales') AS [SpeakerLocales]
					,GETUTCDATE() AS [CreatedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [ModifiedBy]
				FROM @GuestSpeakers.nodes('/Speaker') AS bs(col)
		)
		SELECT
				c.[n]
				,ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS [i]
				,c.[PK_Event]
				,c.[PK_SubEvent]
				,c.[PK_EventImage]
				,t.[Locale]
				,l.[PK_Locale]
				,c.[PK_EventGuestSpeaker]
				,c.[EventSpeakerName]
				,t.[PK_EventGuestSpeakerLocale]
				,c.[EventSpeakerTitle]
				,c.[PK_EventImageLocaleDesc]
				,c.[EventImageLocation]
				,c.[EventSpeakerPhone]
				,c.[PK_DefaultLocale]
				,c.[EventSpeakerEmail]
				,c.[EventSpeakerTeamLevel]
				,c.[EventSpeakerBio]
				,CASE WHEN c.[PK_DefaultLocale] = l.[PK_Locale] THEN 1 ELSE 0 END AS [IsDefaultLocale]
				,t.[PK_EventURL]
				,t.[EventSpeakerTitle] AS [L_EventSpeakerTitle]
				,t.[EventSpeakerName] AS [L_EventSpeakerName]
				,t.[EventSpeakerTeamLevel] AS [L_EventSpeakerTeamLevel]
				,t.[EventSpeakerBio] AS [L_EventSpeakerBio]
				,c.[CreatedDateUTC]
				,c.[CreatedBy]
				,c.[ModifiedDateUTC]
				,c.[ModifiedBy]
			INTO #GuestSpeakers
			FROM c
				CROSS APPLY (SELECT 
									NULLIF(bs.col.value('PK_EventGuestSpeakerLocale[1]', 'int'), 0) AS [PK_EventGuestSpeakerLocale]
									,NULLIF(bs.col.value('Locale[1]', 'varchar(5)'), '') AS [Locale]
									,NULLIF(bs.col.value('Title[1]', 'varchar(255)'), '') AS [EventSpeakerTitle]
									,NULLIF(bs.col.value('EventSpeakerName[1]', 'varchar(255)'), '') AS [EventSpeakerName]
									,NULLIF(bs.col.value('EventSpeakerTeamLevel[1]', 'varchar(255)'), '') AS [EventSpeakerTeamLevel]
									,NULLIF(bs.col.value('EventSpeakerBio[1]', 'varchar(255)'), '') AS [EventSpeakerBio]
									,NULLIF(bs.col.value('PK_EventURL[1]', 'varchar(255)'), '') AS [PK_EventURL]
								FROM c.SpeakerLocales.nodes('/SpeakerLocales/SpeakerLocale') AS bs(col)) AS t
				INNER JOIN [Locales] AS l WITH (NOLOCK) ON l.[LocaleCode] = t.[Locale];
		
		-- Check if there are default locales for <SpeakerLocale>
		DECLARE @GuestSpeakersDefault int;
	
		WITH c AS (
			SELECT [n] FROM #GuestSpeakers GROUP BY [n]
		)
		SELECT
				@GuestSpeakersDefault = c.[n]
			FROM c
				LEFT JOIN #GuestSpeakers AS g ON c.n = g.n
					AND g.[IsDefaultLocale] = 1
			WHERE g.[n] IS NULL;

		IF @GuestSpeakersDefault IS NOT NULL
			RAISERROR('<SpeakerLocale> does not include Default Locale.', 12, 1, 'Custom Error');


		-- ************************************************************ Show ******************************
		IF @IsDevQA = 1 
		BEGIN
			SELECT n
				  ,i
				  ,PK_Event
				  ,PK_SubEvent
				  ,PK_EventImage
				  ,Locale
				  ,PK_Locale
				  ,PK_EventGuestSpeaker
				  ,EventSpeakerName
				  ,PK_EventGuestSpeakerLocale
				  ,EventSpeakerTitle
				  ,PK_EventImageLocaleDesc
				  ,EventImageLocation
				  ,EventSpeakerPhone
				  ,PK_DefaultLocale
				  ,EventSpeakerEmail
				  ,EventSpeakerTeamLevel
				  ,EventSpeakerBio
				  ,IsDefaultLocale
				  ,PK_EventURL
				  ,L_EventSpeakerTitle
				  ,L_EventSpeakerName
				  ,L_EventSpeakerTeamLevel
				  ,L_EventSpeakerBio
				  ,CreatedDateUTC
				  ,CreatedBy
				  ,ModifiedDateUTC
				  ,ModifiedBy FROM #GuestSpeakers WHERE [n] = @GuestSpeakersDefault;
			SELECT 'Source #GuestSpeakers:' AS [#GuestSpeakers], n
																,i
																,PK_Event
																,PK_SubEvent
																,PK_EventImage
																,Locale
																,PK_Locale
																,PK_EventGuestSpeaker
																,EventSpeakerName
																,PK_EventGuestSpeakerLocale
																,EventSpeakerTitle
																,PK_EventImageLocaleDesc
																,EventImageLocation
																,EventSpeakerPhone
																,PK_DefaultLocale
																,EventSpeakerEmail
																,EventSpeakerTeamLevel
																,EventSpeakerBio
																,IsDefaultLocale
																,PK_EventURL
																,L_EventSpeakerTitle
																,L_EventSpeakerName
																,L_EventSpeakerTeamLevel
																,L_EventSpeakerBio
																,CreatedDateUTC
																,CreatedBy
																,ModifiedDateUTC
																,ModifiedBy FROM #GuestSpeakers;
		END;


		----------------------------------------------------------------------------------------------------------------------------
		-- Save to SubEvent
		--
		DECLARE @SubEventTbl TABLE (
			[action] varchar(15)
			,[n] int
			,[PK_SubEvent] int
			,[CreatedDateUTC] datetime2
			,[CreatedBy] varchar(255)
			,[ModifiedDateUTC] datetime2
			,[ModifiedBy] varchar(255)
			,[PK_Event] int
			,[PK_SubEventType] int
			,[MaxCapacity] int
			,[ExpectedCapacity] int
			,[SubEventName] nvarchar(200)
			,[SubEventNumber] int
			,[Location] nvarchar(600)
			,[LocalName] nvarchar(600)
			,[BeginTime] datetime
			,[EndTime] datetime
			,[IsMainEventQual] bit
			,[CanProcessQual] bit
			,[IncludeInBizworkReport] bit
			,[PK_SubEventLocaleDesc] int
			,[PK_Locale] int
			,[PK_DefaultLocale] int
		);

		MERGE [dbo].[SubEvent] AS t
			USING (
				SELECT
						[PK_SubEvent]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
						,[PK_Event]
						,[PK_SubEventType]
						,[MaxCapacity]
						,[ExpectedCapacity]
						,[SubEventName]
						,[SubEventNumber]
						,[SubEventFormula]
						,[Location]
						,[BeginTime]
						,[EndTime]
						,[IsMainEventQual]
						,[CanProcessQual]
						,[IncludeInBizworkReport]
						,[PK_Locale]
						,[PK_DefaultLocale]
						,[n]
						,[PK_SubEventLocaleDesc]
					FROM #BreakoutSessions
					WHERE [IsDefaultLocale] = 1
				) AS s ON s.[PK_SubEvent] = t.[PK_SubEvent]
			WHEN NOT MATCHED THEN
				INSERT (
						[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
						,[PK_Event]
						,[PK_SubEventType]
						,[MaxCapacity]
						,[ExpectedCapacity]
						,[SubEventName]
						,[SubEventNumber]
						,[SubEventFormula]
						,[Location]
						,[BeginTime]
						,[EndTime]
						,[IsMainEventQual]
						,[CanProcessQual]
						,[IncludeInBizworkReport]
				)
				VALUES (
						s.[CreatedDateUTC]
						,s.[CreatedBy]
						,s.[ModifiedDateUTC]
						,s.[ModifiedBy]
						,s.[PK_Event]
						,s.[PK_SubEventType]
						,s.[MaxCapacity]
						,s.[ExpectedCapacity]
						,s.[SubEventName]
						,s.[SubEventNumber]
						,s.[SubEventFormula]
						,s.[Location]
						,s.[BeginTime]
						,s.[EndTime]
						,s.[IsMainEventQual]
						,s.[CanProcessQual]
						,s.[IncludeInBizworkReport]
				)
			WHEN MATCHED THEN
				UPDATE SET
					[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
					,[MaxCapacity] = s.[MaxCapacity]
					,[ExpectedCapacity] = s.[ExpectedCapacity]
					,[SubEventName] = s.[SubEventName]
					,[Location] = s.[Location]
					,[BeginTime] = s.[BeginTime]
					,[EndTime] = s.[EndTime]
			OUTPUT 
					$action
					,s.[n]
					,inserted.[PK_SubEvent]
					,inserted.[CreatedDateUTC]
					,inserted.[CreatedBy]
					,inserted.[ModifiedDateUTC]
					,inserted.[ModifiedBy]
					,inserted.[PK_Event]
					,inserted.[PK_SubEventType]
					,inserted.[MaxCapacity]
					,inserted.[ExpectedCapacity]
					,inserted.[SubEventName]
					,inserted.[SubEventNumber]
					,inserted.[Location]
					,inserted.[LocalName]
					,inserted.[BeginTime]
					,inserted.[EndTime]
					,inserted.[IsMainEventQual]
					,inserted.[CanProcessQual]
					,inserted.[IncludeInBizworkReport]
					,s.[PK_SubEventLocaleDesc]
					,s.[PK_Locale]
					,s.[PK_DefaultLocale]
				INTO @SubEventTbl
		;	-- MERGE [SubEvent]

		UPDATE t SET
				[PK_SubEvent] = s.[PK_SubEvent]
			FROM #BreakoutSessions AS t
				CROSS JOIN @SubEventTbl AS s;

		UPDATE t SET
				[PK_SubEvent] = s.[PK_SubEvent]
			FROM #GuestSpeakers AS t
				CROSS JOIN @SubEventTbl AS s;

		SELECT @PK_SubEvent = ISNULL(@PK_SubEvent, (SELECT DISTINCT [PK_SubEvent] FROM @SubEventTbl));

		-- ************************************************************ Show ******************************
		IF @IsDevQA = 1 
			BEGIN
				SELECT 'MERGE', action
							   ,n
							   ,PK_SubEvent
							   ,CreatedDateUTC
							   ,CreatedBy
							   ,ModifiedDateUTC
							   ,ModifiedBy
							   ,PK_Event
							   ,PK_SubEventType
							   ,MaxCapacity
							   ,ExpectedCapacity
							   ,SubEventName
							   ,SubEventNumber
							   ,Location
							   ,LocalName
							   ,BeginTime
							   ,EndTime
							   ,IsMainEventQual
							   ,CanProcessQual
							   ,IncludeInBizworkReport
							   ,PK_SubEventLocaleDesc
							   ,PK_Locale
							   ,PK_DefaultLocale FROM @SubEventTbl;
				SELECT '#BreakoutSessions [SubEvent]', n
													  ,PK_Event
													  ,PK_SubEvent
													  ,BeginTime
													  ,EndTime
													  ,MaxCapacity
													  ,RegistrationDeadlineDate
													  ,AllowPartnerRegistration
													  ,PK_DefaultLocale
													  ,DefaultLocale
													  ,ManageLanguages
													  ,ExpectedCapacity
													  ,SubEventNumber
													  ,SubEventFormula
													  ,PK_SubEventType
													  ,IncludeInBizworkReport
													  ,CanProcessQual
													  ,IsMainEventQual
													  ,PK_EventImageType
													  ,CreatedDateUTC
													  ,CreatedBy
													  ,ModifiedDateUTC
													  ,ModifiedBy
													  ,IsDefaultLocale
													  ,PK_SubEventLocaleDesc
													  ,Locale
													  ,PK_Locale
													  ,SubEventName
													  ,SubEventQualDesc
													  ,QualDesc
													  ,Image
													  ,Location FROM #BreakoutSessions;
			END;

		----------------------------------------------------------------------------------------------------------------------------
		-- Save to [SubEventExt]
		--

		DECLARE @SubEventExtn table (
			[action] varchar(15)
			,[PK_SubEventExtn] [int]
			,[PK_Event] [int]
			,[PK_SubEvent] [int]
			,[CreatedDateUTC] [datetime]
			,[CreatedBy] [varchar](50)
			,[ModifiedDateUTC] [datetime]
			,[ModifiedBy] [varchar](50)
			,[AllowPartnerRegistration] [bit]
			,[ManageLanguages] [bit]
			,[RegistrationDeadlineDate] [datetime]
		);
	
		MERGE [dbo].[SubEventExtn] AS t
			USING(
				SELECT
						(SELECT [PK_SubEventExtn]
							FROM [dbo].[SubEventExtn] AS t WITH (NOLOCK)
							WHERE t.[PK_Event] = s.[PK_Event]
									AND t.[PK_SubEvent] = s.[PK_SubEvent])
						AS [PK_SubEventExtn]
						,s.[PK_Event]
						,s.[PK_SubEvent]
						,s.[CreatedDateUTC]
						,s.[CreatedBy]
						,s.[ModifiedDateUTC]
						,s.[ModifiedBy]
						,s.[AllowPartnerRegistration]
						,s.[ManageLanguages]
						,s.[RegistrationDeadlineDate]
					FROM #BreakoutSessions AS s
					WHERE [IsDefaultLocale] = 1
				) AS s ON s.[PK_SubEventExtn] = t.[PK_SubEventExtn]
			WHEN MATCHED THEN
				UPDATE SET
					[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
					,[AllowPartnerRegistration] = s.[AllowPartnerRegistration]
					,[ManageLanguages] = s.[ManageLanguages]
					,[RegistrationDeadlineDate] = s.[RegistrationDeadlineDate]
			WHEN NOT MATCHED THEN
				INSERT(
					[PK_Event]
					,[PK_SubEvent]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
					,[AllowPartnerRegistration]
					,[ManageLanguages]
					,[RegistrationDeadlineDate]
				)
				VALUES(
					s.[PK_Event]
					,s.[PK_SubEvent]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
					,s.[AllowPartnerRegistration]
					,s.[ManageLanguages]
					,s.[RegistrationDeadlineDate]
				)

			OUTPUT
					$action
					,inserted.[PK_SubEventExtn]
					,inserted.[PK_Event]
					,inserted.[PK_SubEvent]

					,inserted.[CreatedDateUTC]
					,inserted.[CreatedBy]
					,inserted.[ModifiedDateUTC]
					,inserted.[ModifiedBy]
					,inserted.[AllowPartnerRegistration]
					,inserted.[ManageLanguages]
					,inserted.[RegistrationDeadlineDate]
				INTO @SubEventExtn
		;	-- MERGE [SubEventExtn]

		-- ************************************************************ Show ******************************
		IF @IsDevQA = 1 
			BEGIN
				SELECT 'MERGE', action
							   ,PK_SubEventExtn
							   ,PK_Event
							   ,PK_SubEvent
							   ,CreatedDateUTC
							   ,CreatedBy
							   ,ModifiedDateUTC
							   ,ModifiedBy
							   ,AllowPartnerRegistration
							   ,ManageLanguages
							   ,RegistrationDeadlineDate FROM @SubEventExtn;
			END;

		----------------------------------------------------------------------------------------------------------------------------
		-- Save to [SubEventLocaleDesc]
		--
		DECLARE @SubEventLocaleTbl table (
			[action] varchar(15)
			,[PK_SubEventLocaleDesc] [int]
			,[PK_Subevent] [int]
			,[PK_Event] [int]
			,[PK_Locale] [int]
			,[PK_DefaultLocale] [int]
			,[SubEventName] [nvarchar](max)
			,[SubEventQualDesc] [nvarchar](max)
			,[CreatedDateUTC] [smalldatetime]
			,[CreatedBy] [nvarchar](50)
			,[ModifiedDateUTC] [smalldatetime]
			,[ModifiedBy] [nvarchar](50)
			,[QualDesc] [nvarchar](max)
			,[Image] [nvarchar](max)
			,[n] [int]
		);
	
		MERGE [SubEventLocaleDesc] AS t
			USING (
				SELECT
						[PK_SubEventLocaleDesc]
						,[PK_Subevent]
						,[PK_Event]
						,[PK_Locale]
						,[PK_DefaultLocale]
						,[SubEventName]
						,[SubEventQualDesc]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
						,[QualDesc]
						,[Image]
						,[n]
					FROM #BreakoutSessions
				) AS s ON s.[PK_SubEventLocaleDesc] = t.[PK_SubEventLocaleDesc]
			WHEN NOT MATCHED THEN
				INSERT (
						[PK_Subevent]
						,[PK_Event]
						,[PK_Locale]
						,[PK_DefaultLocale]
						,[SubEventName]
						,[SubEventQualDesc]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
						,[QualDesc]
						,[Image]
				)
				VALUES (
						s.[PK_Subevent]
						,s.[PK_Event]
						,s.[PK_Locale]
						,s.[PK_DefaultLocale]
						,s.[SubEventName]
						,s.[SubEventQualDesc]
						,s.[CreatedDateUTC]
						,s.[CreatedBy]
						,s.[ModifiedDateUTC]
						,s.[ModifiedBy]
						,s.[QualDesc]
						,s.[Image]
				)
			WHEN MATCHED THEN
				UPDATE SET
					[PK_Locale] = s.[PK_Locale]
					,[PK_DefaultLocale] = s.[PK_DefaultLocale]
					,[SubEventName] = s.[SubEventName]
					,[SubEventQualDesc] = s.[SubEventQualDesc]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
					,[QualDesc] = s.[QualDesc]
					,[Image] = s.[Image]
			OUTPUT
					$action
					,inserted.[PK_SubEventLocaleDesc]
					,inserted.[PK_Subevent]
					,inserted.[PK_Event]
					,inserted.[PK_Locale]
					,inserted.[PK_DefaultLocale]
					,inserted.[SubEventName]
					,inserted.[SubEventQualDesc]
					,inserted.[CreatedDateUTC]
					,inserted.[CreatedBy]
					,inserted.[ModifiedDateUTC]
					,inserted.[ModifiedBy]
					,inserted.[QualDesc]
					,inserted.[Image]
					,s.[n]
				INTO @SubEventLocaleTbl
		;	-- MERGE [SubEventLocaleDesc]


		UPDATE t SET
				[PK_SubEventLocaleDesc] = s.[PK_SubEventLocaleDesc]
			FROM #BreakoutSessions AS t
				INNER JOIN @SubEventLocaleTbl AS s ON s.[n] = t.[n];

		--
		DELETE FROM [SubEventLocaleDesc]
			WHERE [PK_SubEventLocaleDesc] IN (
					SELECT
							sl.[PK_SubEventLocaleDesc]
						FROM [SubEventLocaleDesc] AS sl WITH (NOLOCK)
							INNER JOIN [SubEvent] AS s  WITH (NOLOCK) ON sl.[PK_SubEvent] = s.[PK_SubEvent]
								AND s.[PK_SubEventType] = 5
							LEFT JOIN #BreakoutSessions AS b ON s.[PK_Subevent] = b.[PK_SubEvent]
								AND sl.[PK_Locale] = b.[PK_Locale]
								AND s.[PK_Event] = @PK_Event
						WHERE b.[PK_SubEvent] IS NULL
							AND sl.[PK_SubEvent] IN (SELECT DISTINCT [PK_SubEvent] FROM #BreakoutSessions)
		);

		-- Return INSERTED/UPDATED breakout sessions
		--
		SELECT
				n
			   ,PK_Event
			   ,PK_SubEvent
			   ,BeginTime
			   ,EndTime
			   ,MaxCapacity
			   ,RegistrationDeadlineDate
			   ,AllowPartnerRegistration
			   ,PK_DefaultLocale
			   ,DefaultLocale
			   ,ManageLanguages
			   ,ExpectedCapacity
			   ,SubEventNumber
			   ,SubEventFormula
			   ,PK_SubEventType
			   ,IncludeInBizworkReport
			   ,CanProcessQual
			   ,IsMainEventQual
			   ,PK_EventImageType
			   ,CreatedDateUTC
			   ,CreatedBy
			   ,ModifiedDateUTC
			   ,ModifiedBy
			   ,IsDefaultLocale
			   ,PK_SubEventLocaleDesc
			   ,Locale
			   ,SubEventName
			   ,SubEventQualDesc
			   ,QualDesc
			   ,Image
			   ,Location
			FROM #BreakoutSessions;


		DECLARE @gs table (
			[action] varchar(10)
			,[PK_Event] int
			,[EventSpeakerName] varchar(max)
			,[PK_EventGuestSpeaker] int
			,[DelEventSpeakerName] varchar(max)
			,[PK_DelEventGuestSpeaker] int
			,[n] int
		);

		
		------------------------------------------------------------------------------------------------------------------
		-- Add/update guest speakers from source #GuestSpeakers
		--
		MERGE [dbo].[EventGuestSpeakers] AS t
			USING (
				SELECT
						[PK_EventGuestSpeaker]
						,[PK_Event]
						,[PK_SubEvent]
						,[PK_Locale]
						,[EventSpeakerName]
						,[EventSpeakerTitle]
						,[EventSpeakerPhone]
						,[EventSpeakerEmail]
						,[EventSpeakerTeamLevel]
						,[EventSpeakerBio]
						,[PK_EventImageLocaleDesc]
						,[EventImageLocation]
						,@GuestSpeakerImageType AS [PK_EventImageType]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
						,[n]
					FROM #GuestSpeakers
					WHERE [IsDefaultLocale] = 1
				) AS s ON s.[PK_EventGuestSpeaker] = t.[PK_EventGuestSpeaker]
			WHEN NOT MATCHED THEN
				INSERT (
					[PK_Event]
					,[EventSpeakerName]
					,[EventSpeakerTitle]
					,[EventSpeakerPhone]
					,[EventSpeakerEmail]
					,[EventSpeakerTeamLevel]
					,[EventSpeakerBio]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
					,[PK_SubEvent]
				)
				VALUES (
					s.[PK_Event]
					,s.[EventSpeakerName]
					,s.[EventSpeakerTitle]
					,s.[EventSpeakerPhone]
					,s.[EventSpeakerEmail]
					,s.[EventSpeakerTeamLevel]
					,s.[EventSpeakerBio]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
					,s.[PK_SubEvent]
				)
			WHEN MATCHED THEN
				UPDATE SET
					[EventSpeakerName] = s.[EventSpeakerName]
					,[EventSpeakerTitle] = s.[EventSpeakerTitle]
					,[EventSpeakerPhone] = s.[EventSpeakerPhone]
					,[EventSpeakerEmail] = s.[EventSpeakerEmail]
					,[EventSpeakerTeamLevel] = s.[EventSpeakerTeamLevel]
					,[EventSpeakerBio] = s.[EventSpeakerBio]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
			OUTPUT	$action
					,inserted.[PK_Event]
					,inserted.[EventSpeakerName]
					,inserted.[PK_EventGuestSpeaker]
					,deleted.[EventSpeakerName]	-- [DelEventSpeakerName]
					,deleted.[PK_EventGuestSpeaker] -- [PK_DelEventGuestSpeaker]
					,s.[n]
				INTO @gs
		; -- MERGE [EventGuestSpeakers]


		-- Update the input to add [PK_EventGuestSpeaker] for the new inserted rows for guest speakers
		UPDATE t SET
				[PK_EventGuestSpeaker] = s.[PK_EventGuestSpeaker] 
			FROM  #GuestSpeakers AS t
				INNER JOIN @gs AS s ON s.[n] = t.[n];

		-- ************************************************************ Show ******************************
		IF @IsDevQA = 1 
		BEGIN
			SELECT 'Merge EventGuestSpeaker', action
											 ,PK_Event
											 ,EventSpeakerName
											 ,PK_EventGuestSpeaker
											 ,DelEventSpeakerName
											 ,PK_DelEventGuestSpeaker
											 ,n FROM @gs;
			SELECT '#GuestSpeakers', n
									,i
									,PK_Event
									,PK_SubEvent
									,PK_EventImage
									,Locale
									,PK_Locale
									,PK_EventGuestSpeaker
									,EventSpeakerName
									,PK_EventGuestSpeakerLocale
									,EventSpeakerTitle
									,PK_EventImageLocaleDesc
									,EventImageLocation
									,EventSpeakerPhone
									,PK_DefaultLocale
									,EventSpeakerEmail
									,EventSpeakerTeamLevel
									,EventSpeakerBio
									,IsDefaultLocale
									,PK_EventURL
									,L_EventSpeakerTitle
									,L_EventSpeakerName
									,L_EventSpeakerTeamLevel
									,L_EventSpeakerBio
									,CreatedDateUTC
									,CreatedBy
									,ModifiedDateUTC
									,ModifiedBy FROM #GuestSpeakers;
		END;

		------------------------------------------------------------------------------------------------------------------
		-- Save guest speaker in [EventGuestSpeakerLocale]
		--
		DECLARE @GuestSpeakerLocale table(
			[action] varchar(10)
			,[PK_EventGuestSpeaker] int
			,[PK_EventGuestSpeakerLocale] int
			,[i] int
		);
	
		MERGE [dbo].[EventGuestSpeakerLocale] AS t
			USING(
				SELECT
						(SELECT [PK_EventGuestSpeakerLocale]
							FROM [dbo].[EventGuestSpeakerLocale] AS t WITH (NOLOCK)
							WHERE t.[PK_EventGuestSpeaker] = s.[PK_EventGuestSpeaker] 
								AND t.[PK_Locale] = s.[PK_Locale]
								AND t.[PK_Event] = s.[PK_Event])
						AS [PK_EventGuestSpeakerLocale]
						,s.[PK_EventGuestSpeaker]
						,s.[L_EventSpeakerName] AS [EventSpeakerName]
						,s.[L_EventSpeakerTitle] AS [EventSpeakerTitle]
						,s.[EventSpeakerPhone]
						,s.[EventSpeakerEmail]
						,s.[L_EventSpeakerTeamLevel] AS [EventSpeakerTeamLevel]
						,s.[L_EventSpeakerBio] AS [EventSpeakerBio]
						,s.[CreatedDateUTC]
						,s.[CreatedBy]
						,s.[ModifiedDateUTC]
						,s.[ModifiedBy]
						,s.[PK_Event]
						,s.[PK_Locale]
						,s.[PK_SubEvent]
						,s.[i]
					FROM #GuestSpeakers AS s
				) AS s ON s.[PK_EventGuestSpeakerLocale] = t.[PK_EventGuestSpeakerLocale]
			WHEN MATCHED THEN
				UPDATE SET
					[EventSpeakerName] = s.[EventSpeakerName]
					,[EventSpeakerTitle] = s.[EventSpeakerTitle]
					,[EventSpeakerBio] = s.[EventSpeakerBio]
					,[EventSpeakerTeamLevel] = s.[EventSpeakerTeamLevel]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
			WHEN NOT MATCHED THEN
				INSERT(
					[PK_EventGuestSpeaker]
					,[EventSpeakerName]
					,[EventSpeakerTitle]
					,[EventSpeakerTeamLevel]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
					,[PK_Event]
					,[PK_Locale]
					,[EventSpeakerBio]
				)
				VALUES(
					s.[PK_EventGuestSpeaker]
					,s.[EventSpeakerName]
					,s.[EventSpeakerTitle]
					,s.[EventSpeakerTeamLevel]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
					,S.[PK_Event]
					,s.[PK_Locale]
					,s.[EventSpeakerBio]
				)
			OUTPUT	$action
					,inserted.[PK_EventGuestSpeaker]
					,inserted.[PK_EventGuestSpeakerLocale]
					,s.[i]
				INTO @GuestSpeakerLocale
		;	-- MERGE [EventGuestSpeakerLocale]

		UPDATE t SET
				[PK_EventGuestSpeakerLocale] = s.[PK_EventGuestSpeakerLocale]
			FROM #GuestSpeakers AS t
				INNER JOIN @GuestSpeakerLocale AS s ON s.[i] = t.[i];

		--IF @IsDevQA = 1 
		--BEGIN
		--	SELECT 'Delete from [EventGuestSpeakerLocale]', e.[PK_EventGuestSpeakerLocale], g.[n], *
		--	FROM	[EventGuestSpeakers] egs WITH (NOLOCK)
		--			Inner join  [EventGuestSpeakerLocale] AS e WITH (NOLOCK)
		--				on  egs.PK_EventGuestSpeaker = e.PK_EventGuestSpeaker
		--			LEFT JOIN #GuestSpeakers AS g ON e.[PK_EventGuestSpeakerLocale] = g.[PK_EventGuestSpeakerLocale]
		--	WHERE e.[PK_Event] = @PK_Event and egs.[PK_SubEvent] = @PK_SubEvent
		--		AND g.[n] IS NULL
		--END;

		DELETE FROM [EventGuestSpeakerLocale]
			WHERE [PK_EventGuestSpeakerLocale] IN (
					SELECT	e.[PK_EventGuestSpeakerLocale]
					FROM	[EventGuestSpeakers] egs WITH (NOLOCK)
							Inner join  [EventGuestSpeakerLocale] AS e WITH (NOLOCK)
								on  egs.PK_EventGuestSpeaker = e.PK_EventGuestSpeaker
							LEFT JOIN #GuestSpeakers AS g ON e.[PK_EventGuestSpeakerLocale] = g.[PK_EventGuestSpeakerLocale]
					WHERE	e.[PK_Event] = @PK_Event 
							AND egs.[PK_SubEvent] = @PK_SubEvent
							AND g.[n] IS NULL
			);
					

		-- ************************************************************ Show ******************************
		IF @IsDevQA = 1 
		BEGIN
			SELECT 'Merge [EventGuestSpeakerLocale]' AS [EventGuestSpeakerLocale], action
																				  ,PK_EventGuestSpeaker
																				  ,PK_EventGuestSpeakerLocale
																				  ,i FROM @GuestSpeakerLocale;
			SELECT 'Updated Source' AS [#GuestSpeakers], n
														,i
														,PK_Event
														,PK_SubEvent
														,PK_EventImage
														,Locale
														,PK_Locale
														,PK_EventGuestSpeaker
														,EventSpeakerName
														,PK_EventGuestSpeakerLocale
														,EventSpeakerTitle
														,PK_EventImageLocaleDesc
														,EventImageLocation
														,EventSpeakerPhone
														,PK_DefaultLocale
														,EventSpeakerEmail
														,EventSpeakerTeamLevel
														,EventSpeakerBio
														,IsDefaultLocale
														,PK_EventURL
														,L_EventSpeakerTitle
														,L_EventSpeakerName
														,L_EventSpeakerTeamLevel
														,L_EventSpeakerBio
														,CreatedDateUTC
														,CreatedBy
														,ModifiedDateUTC
														,ModifiedBy FROM #GuestSpeakers;
		END;


		--------------------------------------------------------------------------------------------------------------------
		---- Save guest speaker image
		----
		DECLARE @EventImage table(
			[action] varchar(10)
			,[PK_EventImage] int
			,[EventImageLocation] varchar(255)
			,[PK_EventImageType] int
			,[n] int
		);


		-- ************************************************************ Show ******************************
		IF @IsDevQA = 1
			SELECT
					'Guest speaker image' AS [Step]
					,(SELECT [PK_EventImage] FROM [dbo].[EventImageLocaleDesc] WITH (NOLOCK) WHERE [PK_EventImageLocaleDesc] = s.[PK_EventImageLocaleDesc]) AS [PK_EventImage]
					,s.[EventImageLocation]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
					,s.[PK_Event]
					,@GuestSpeakerImageType AS [PK_EventImageType]
				FROM #GuestSpeakers AS s
				WHERE EventImageLocation IS NOT NULL
					AND s.[IsDefaultLocale] = 1;
				
		-- Save main image info
		--
		MERGE [dbo].[EventImage] AS t
			USING(
					SELECT
							(SELECT [PK_EventImage] FROM [dbo].[EventImageLocaleDesc] WITH (NOLOCK) WHERE [PK_EventImageLocaleDesc] = g.[PK_EventImageLocaleDesc]) AS [PK_EventImage]
							,g.[EventImageLocation]
							,g.[CreatedDateUTC]
							,g.[CreatedBy]
							,g.[ModifiedDateUTC]
							,g.[ModifiedBy]
							,g.[PK_Event]
							,@GuestSpeakerImageType AS [PK_EventImageType]
							,g.[n]
						FROM #GuestSpeakers AS g
						WHERE ISNULL(EventImageLocation, '') != ''
							AND g.[IsDefaultLocale] = 1
				) AS s ON t.[PK_EventImage] = s.[PK_EventImage]
			WHEN NOT MATCHED THEN
				INSERT (
					[EventImageLocation]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
					,[PK_Event]
					,[PK_EventImageType]
				)
				VALUES (
					s.[EventImageLocation]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
					,s.[PK_Event]
					,s.[PK_EventImageType]
				)
			WHEN MATCHED THEN
				UPDATE SET
					[EventImageLocation] = s.[EventImageLocation]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
			OUTPUT	$action
					,inserted.[PK_EventImage]
					,inserted.[EventImageLocation]
					,inserted.[PK_EventImageType]
					,s.[n]
				INTO @EventImage
		; -- MERGE EventImage


		UPDATE t SET
				[PK_EventImage] = i.[PK_EventImage]
			FROM #GuestSpeakers AS t
				INNER JOIN @EventImage AS i ON i.[n] = t.[n]
		
		UPDATE g SET
				[PK_EventImage] = t.[PK_EventImage]
			FROM [EventGuestSpeakers] AS g
				INNER JOIN #GuestSpeakers AS t ON g.[PK_EventGuestSpeaker] = t.[PK_EventGuestSpeaker]

				
		-- ************************************************************ Show ******************************
		IF @IsDevQA = 1 
		BEGIN
			SELECT 'EventImage' AS [@EventImage], action
												 ,PK_EventImage
												 ,EventImageLocation
												 ,PK_EventImageType
												 ,n FROM @EventImage;
			SELECT 'Updated Source (images)' AS [#GuestSpeakers], n
																 ,i
																 ,PK_Event
																 ,PK_SubEvent
																 ,PK_EventImage
																 ,Locale
																 ,PK_Locale
																 ,PK_EventGuestSpeaker
																 ,EventSpeakerName
																 ,PK_EventGuestSpeakerLocale
																 ,EventSpeakerTitle
																 ,PK_EventImageLocaleDesc
																 ,EventImageLocation
																 ,EventSpeakerPhone
																 ,PK_DefaultLocale
																 ,EventSpeakerEmail
																 ,EventSpeakerTeamLevel
																 ,EventSpeakerBio
																 ,IsDefaultLocale
																 ,PK_EventURL
																 ,L_EventSpeakerTitle
																 ,L_EventSpeakerName
																 ,L_EventSpeakerTeamLevel
																 ,L_EventSpeakerBio
																 ,CreatedDateUTC
																 ,CreatedBy
																 ,ModifiedDateUTC
																 ,ModifiedBy	 FROM #GuestSpeakers;

			SELECT
					g.[PK_EventImageLocaleDesc]
					,g.[EventImageLocation]
					,g.[CreatedDateUTC]
					,g.[CreatedBy]
					,g.[ModifiedDateUTC]
					,g.[ModifiedBy]
					,ei.[PK_EventImage]
					,g.[PK_Event]
					,g.[PK_Locale]
					,@GuestSpeakerImageType AS [PK_EventImageType]
					,g.[n]
				FROM #GuestSpeakers AS g
					INNER JOIN @EventImage AS ei ON ei.[n] = g.[n]
				WHERE ISNULL(g.[EventImageLocation], '') != ''
					AND g.[IsDefaultLocale] = 1;
		END;
		

		-- Save image locale
		--
		DECLARE @EventImageLocaleDesc Table(
			[action] nvarchar(10)
			,[PK_Event] int
			,[PK_Locale] int
			,[PK_EventImage] int
			,[PK_EventImageLocaleDesc] int
			,[PK_DelEventImageLocaleDesc] int
			,[PK_DelEventImage] int
			,[PK_DelLocale] int
			,[n] int
		);

		MERGE [dbo].[EventImageLocaleDesc] AS t
			USING(
				SELECT
						g.[PK_EventImageLocaleDesc]
						,g.[EventImageLocation]
						,g.[CreatedDateUTC]
						,g.[CreatedBy]
						,g.[ModifiedDateUTC]
						,g.[ModifiedBy]
						,ei.[PK_EventImage]
						,g.[PK_Event]
						,g.[PK_Locale]
						,@GuestSpeakerImageType AS [PK_EventImageType]
						,g.[n]
					FROM #GuestSpeakers AS g
						INNER JOIN @EventImage AS ei ON ei.[n] = g.[n]
					WHERE ISNULL(g.[EventImageLocation], '') != ''
						AND g.[IsDefaultLocale] = 1
				) AS s ON s.[PK_EventImageLocaleDesc] = t.[PK_EventImageLocaleDesc]
			WHEN NOT MATCHED THEN
				INSERT(
					[PK_EventImage]
					,[PK_Event]
					,[PK_Locale]
					,[EventImageLocation]
					,[CreatedBy]
					,[CreatedDateUTC]
					,[ModifiedBy]
					,[ModifiedDateUTC]
				)
				VALUES(
					s.[PK_EventImage]
					,s.[PK_Event]
					,s.[PK_Locale]
					,s.[EventImageLocation]
					,s.[CreatedBy]
					,s.[CreatedDateUTC]
					,s.[ModifiedBy]
					,s.[ModifiedDateUTC]
				)
			WHEN MATCHED THEN
				UPDATE SET
					[EventImageLocation] = s.[EventImageLocation]
					,[PK_Locale] = s.[PK_Locale]
					,[ModifiedBy] = s.[ModifiedBy]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
			--WHEN NOT MATCHED BY SOURCE AND t.[PK_Event] = @PK_Event AND t.[PK_EventImage] = s.[PK_EventImage] THEN
			--	DELETE
			OUTPUT	$action
					,inserted.[PK_Event]
					,inserted.[PK_Locale]
					,inserted.[PK_EventImage]
					,inserted.[PK_EventImageLocaleDesc]
					,deleted.[PK_EventImageLocaleDesc]	-- [PK_DelEventImageLocaleDesc]
					,deleted.[PK_EventImage]	-- [PK_DelEventImage]
					,deleted.[PK_Locale]	-- [PK_DelLocale]
					,s.[n]
				INTO @EventImageLocaleDesc
		; -- MERGE EventImageLocaleDesc

		UPDATE t SET
				[PK_EventImageLocaleDesc] = i.[PK_EventImageLocaleDesc]
			FROM #GuestSpeakers AS t
				INNER JOIN @EventImageLocaleDesc AS i ON i.[n] = t.[n];

		-- Delete images from deleted guest speakers from [EventGuestSpeakers]
		DECLARE @DelImages table ([PK_EventImage] int);	

		INSERT INTO @DelImages -- Get PK_EventImage rows to be deleted
			SELECT
					i.[PK_EventImage]
				FROM [EventImage] AS i WITH (NOLOCK)
					LEFT JOIN [EventGuestSpeakers] AS g WITH (NOLOCK) ON g.[PK_EventImage] = i.[PK_EventImage]
				WHERE i.[PK_Event] = @PK_Event
					AND i.[PK_EventImageType] = @GuestSpeakerImageType
					AND g.[PK_EventImage] IS NULL;

		UPDATE [EventGuestSpeakers] SET [PK_EventImage] = NULL where [PK_EventImage] IN (SELECT [PK_EventImage] FROM @DelImages);
		
		DELETE FROM [EventImageLocaleDesc] WHERE [PK_EventImage] IN (SELECT [PK_EventImage] FROM @DelImages);
		
		DELETE FROM [EventImage] WHERE [PK_EventImage] IN (SELECT [PK_EventImage] FROM @DelImages);

		-- ************************************************************ Show ******************************
		IF @IsDevQA = 1
		BEGIN
			SELECT 'EventImage to delete' AS [Del_EventImage], PK_EventImage FROM @DelImages;
			SELECT 'EventImageLocaleDesc' AS [@EventImageLocaleDesc], action
																	 ,PK_Event
																	 ,PK_Locale
																	 ,PK_EventImage
																	 ,PK_EventImageLocaleDesc
																	 ,PK_DelEventImageLocaleDesc
																	 ,PK_DelEventImage
																	 ,PK_DelLocale
																	 ,n FROM @EventImageLocaleDesc;
			SELECT 'Updated Image Locale' AS [#GuestSpeakers], n
															  ,i
															  ,PK_Event
															  ,PK_SubEvent
															  ,PK_EventImage
															  ,Locale
															  ,PK_Locale
															  ,PK_EventGuestSpeaker
															  ,EventSpeakerName
															  ,PK_EventGuestSpeakerLocale
															  ,EventSpeakerTitle
															  ,PK_EventImageLocaleDesc
															  ,EventImageLocation
															  ,EventSpeakerPhone
															  ,PK_DefaultLocale
															  ,EventSpeakerEmail
															  ,EventSpeakerTeamLevel
															  ,EventSpeakerBio
															  ,IsDefaultLocale
															  ,PK_EventURL
															  ,L_EventSpeakerTitle
															  ,L_EventSpeakerName
															  ,L_EventSpeakerTeamLevel
															  ,L_EventSpeakerBio
															  ,CreatedDateUTC
															  ,CreatedBy
															  ,ModifiedDateUTC
															  ,ModifiedBy FROM #GuestSpeakers;
		END;

		-- Save breakout sessions with subevents qualifiers
		--
		DECLARE @Qualifiers table (
			[action] varchar(10)
			,[PK_Event] int
			,[BreakoutSession] int
			,[PK_SubEvent]	int
		);

		WITH c AS (
			SELECT
					@PK_Event AS [PK_Event]
					,@PK_SubEvent AS [BreakoutSession]
					,bs.col.query('./text()').value('.[1]', 'int') AS [PK_SubEvent]
					,GETUTCDATE() AS [CreatedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [ModifiedBy]
				FROM @Qualifications.nodes('/SubEventQualifications/SubEventQualification') AS bs(col)
		)
		MERGE [BreakoutSessionSubEvent] AS t
			USING (
				SELECT
						[PK_Event]
						,[BreakoutSession]
						,[PK_SubEvent]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
					FROM c
				) AS s ON s.[PK_Event] = t.[PK_Event]
					AND s.[BreakoutSession] = t.[BreakoutSession]
					AND s.[PK_SubEvent] = t.[PK_SubEvent]
			WHEN NOT MATCHED THEN
				INSERT (
					[PK_Event]
					,[BreakoutSession]
					,[PK_SubEvent]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
				)
				VALUES (
					s.[PK_Event]
					,s.[BreakoutSession]
					,s.[PK_SubEvent]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
				)
			WHEN NOT MATCHED BY SOURCE AND t.[PK_Event] = @PK_Event AND t.[BreakoutSession] = @PK_SubEvent THEN
				DELETE
			OUTPUT	$action
					,inserted.[PK_Event]
					,inserted.[BreakoutSession]
					,inserted.[PK_SubEvent]
				INTO @Qualifiers

		;	-- MERGE [BreakoutSessionSubEvent]

		-- ************************************************************ Show ******************************
		IF @IsDevQA = 1
		BEGIN
			SELECT @PK_SubEvent AS [PK_SubEvent];

			SELECT
					'QA Qualifiers:'
					,@PK_Event AS [PK_Event]
					,@PK_SubEvent AS [BreakoutSession]
					,bs.col.query('./text()').value('.[1]', 'int') AS [PK_SubEvent]
					,GETUTCDATE() AS [CreatedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [ModifiedBy]
				FROM @Qualifications.nodes('/SubEventQualifications/SubEventQualification') AS bs(col);

			SELECT 
					'QA Qual Merge'
					,action
					,PK_Event
					,BreakoutSession
					,PK_SubEvent
				FROM @Qualifiers;
		END;

		/* Save Session Preferred Languages */

		DECLARE @PreferredLanguages table (
			[action] varchar(10)
			,[PK_Event] int
			,[PK_SubEvent]	int
			,[PreferredLanguage] varchar(5)
			,[PK_Event_Deleted] int
			,[PK_SubEvent_Deleted]	int
			,[PreferredLanguage_Deleted] varchar(5)

		);

		WITH l AS (
			SELECT 	@PK_Event AS [PK_Event]
					,@PK_SubEvent AS [PK_SubEvent]
					,(SELECT [LocaleCode] FROM [Locales] WITH (NOLOCK) WHERE [PK_Locale] = @PK_DefaultLocale) AS [PreferredLanguage]
					,GETUTCDATE() AS [CreatedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [ModifiedBy]
			UNION
			SELECT
					@PK_Event AS [PK_Event]
					,@PK_SubEvent AS [PK_SubEvent]
					,bs.col.query('./text()').value('.[1]', 'varchar(5)') AS [PreferredLanguage]
					,GETUTCDATE() AS [CreatedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [ModifiedBy]
				FROM @SessionPreferredLanguages.nodes('/SubEventLanguages/SubEventLanguage') AS bs(col)
		)
		MERGE [BreakoutSessionPreferredLanguages] AS t
			USING (
				SELECT
						[PK_Event]
						,[PK_SubEvent]
						,[PreferredLanguage]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
					FROM l
				) AS s ON s.[PK_Event] = t.[PK_Event]
					AND s.[PK_SubEvent] = t.[PK_SubEvent]
					AND s.[PreferredLanguage] = t.[PreferredLanguage]
			WHEN NOT MATCHED THEN
				INSERT (
					[PK_Event]
					,[PK_SubEvent]
					,[PreferredLanguage]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
				)
				VALUES (
					s.[PK_Event]
					,s.[PK_SubEvent]
					,s.[PreferredLanguage]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
				)
			WHEN NOT MATCHED BY SOURCE AND t.[PK_Event] = @PK_Event AND t.[PK_SubEvent] = @PK_SubEvent  THEN
				DELETE
			OUTPUT	$action
					,inserted.[PK_Event]
					,inserted.[PK_SubEvent]
					,inserted.[PreferredLanguage]
					,deleted.[PK_Event]
					,deleted.[PK_SubEvent]
					,deleted.[PreferredLanguage]
				INTO @PreferredLanguages

		;	-- MERGE [BreakoutSessionPreferredLanguages]


		-- ************************************************************ Show ******************************
		IF @IsDevQA = 1
		BEGIN
			SELECT @PK_SubEvent AS [PK_SubEvent];

			SELECT 	@PK_Event AS [PK_Event]
					,@PK_SubEvent AS [PK_SubEvent]
					,(SELECT [LocaleCode] FROM [Locales] WITH (NOLOCK) WHERE [PK_Locale] = @PK_DefaultLocale) AS [PreferredLanguage]
					,GETUTCDATE() AS [CreatedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [ModifiedBy]
			--UNION
			SELECT
					@PK_Event AS [PK_Event]
					,@PK_SubEvent AS [PK_SubEvent]
					,bs.col.query('./text()').value('.[1]', 'varchar(5)') AS [PreferredLanguage]
					,GETUTCDATE() AS [CreatedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,REPLACE(SUSER_NAME(),'HERBALIFECORP\','') AS [ModifiedBy]
				FROM @SessionPreferredLanguages.nodes('/SubEventLanguages/SubEventLanguage') AS bs(col)


			SELECT 
					'QA PreferredLanguages Merge'
					,action
					,PK_Event
					,PK_SubEvent
					,PreferredLanguage
					,PK_Event_Deleted
					,PK_SubEvent_Deleted
					,PreferredLanguage_Deleted
				FROM @PreferredLanguages;

			SELECT 
					'BreakoutSessionPreferredLanguages'
					,PK_Event
					,PK_SubEvent
					,PreferredLanguage
					,CreatedDateUTC
					,CreatedBy
					,ModifiedDateUTC
					,ModifiedBy
				FROM BreakoutSessionPreferredLanguages WITH (NOLOCK)
				WHERE PK_Event = @PK_Event and PK_SubEvent = @PK_SubEvent;

		END;
		
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
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;
