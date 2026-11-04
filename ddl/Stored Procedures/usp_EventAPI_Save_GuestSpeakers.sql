CREATE PROCEDURE [dbo].[usp_EventAPI_Save_GuestSpeakers]
		-- Mandatory Parameters
		@PK_Event int
		,@GuestSpeakers xml

		-- Optional Paramenters
		,@User nvarchar(255) = NULL
		,@DeleteGuestSpeakers bit = 1

		-- Defaults
		,@GuestSpeakerImageType int = 3
		,@GuestSpeakerURLType int = 6
		
		-- Error Parameters
		,@Error	int OUTPUT
		,@ErrorMessage varchar(MAX) OUTPUT
		
		-- QA/DEV
		,@IsDevQA bit = 1
AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventAPI_Save_GuestSpeakers
	
	USE:			
			DECLARE @e int
					,@em varchar(max)
					,@s nvarchar(max) = N'
						<Speaker>
							<PK_Event>54138</PK_Event>
							<Locale>es-US</Locale>
							<PK_EventGuestSpeaker></PK_EventGuestSpeaker>
							<SpeakerName>Ricardo Arjona</SpeakerName>
							<Title>Mr</Title>
							<Phone>1122334455</Phone>
							<Email>arjona22@arjona.com</Email>
							<TeamLevel>President</TeamLevel>
							<Bio>Arjonas Bio 22</Bio>
							<PK_EventImageLocaleDesc></PK_EventImageLocaleDesc>
							<EventImageLocation>http://t.com/arjona_image22.jpg</EventImageLocation>
							<PK_EventImageType>3</PK_EventImageType>
						</Speaker>
						<Speaker>
							<PK_Event>54138</PK_Event>
							<Locale>es-US</Locale>
							<PK_EventGuestSpeaker></PK_EventGuestSpeaker>
							<SpeakerName>Garza Garzas</SpeakerName>
							<Title>Dr</Title>
							<Phone>5544332211</Phone>
							<Email>garza22@garza.com</Email>
							<TeamLevel>President</TeamLevel>
							<Bio>Garzas bio 33</Bio>
							<PK_EventImageLocaleDesc></PK_EventImageLocaleDesc>
							<EventImageLocation>http://t.com/Garzas_image33.jpg</EventImageLocation>
							<PK_EventImageType>3</PK_EventImageType>
							<PK_EventURL></PK_EventURL>
							<EventURL>http://twitter/Garzas33</EventURL>
							<EventURLDesc>Twitter feed Garzas</EventURLDesc>
							<PK_EventURLType>6</PK_EventURLType>
						</Speaker>'
					,@Speakers xml;

			SELECT @Speakers = CAST(@s as xml);

			EXEC usp_EventAPI_Save_GuestSpeakers
					@PK_Event = 54138
					,@GuestSpeakers = @Speakers
					,@IsDevQA = 1
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					
			SELECT @e, @em

	DESCRIPTION:	Save guest speakers

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.EventGuestSpeakers, dbo.EventGuestSpeakersLocale, dbo.EventURL, dbo.EventImage, dbo.EventImageLocaleDesc, 

	VERSIONS (PROD)
	--------------------------------------------------------------------
	1.0.0		2017-09-26		RogelioR		Initial
	1.1.0		2018-01-25		RogelioR		The XML input can include duplicate guest speakers
	1.1.1		2019-09-05		NoeG			SRE template applied
	1.1.2		2021-06-14		puertac			BUG 693316 : Keep the speakers sequence as received on the XML
	1.1.3		2021-07-08		puertac			BUG 710380 : DS Event No Saved 8 speakers first time in Admin : PK_EventGuestSpeaker 7 already exists on the table 
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255), @TranCount int;

	SELECT @User = ISNULL(@User, REPLACE(SYSTEM_USER, 'HERBALIFECORP\', ''));

	-- Extract source data to #GuestSpeakers
	--
	IF OBJECT_ID('tempdb..#GuestSpeakers') IS NOT NULL
		DROP TABLE #GuestSpeakers;

	SELECT	 IDENTITY(INT,1,1) AS PK			--BUG 693316 : Workaround
			,ISNULL(NULLIF(Speakers.col.value('PK_Event[1]', 'int'), 0), @PK_Event) AS [PK_Event]
			,(SELECT [PK_Locale] FROM [dbo].[Locales] WITH (NOLOCK) WHERE [LocaleCode] = Speakers.col.value('Locale[1]', 'varchar(5)')) AS [PK_Locale]
			,NULLIF(Speakers.col.value('PK_EventGuestSpeaker[1]', 'int'), 0) AS [PK_EventGuestSpeaker]
			,CAST(NULL AS int) AS [PK_EventGuestSpeakerLocale]
			,NULLIF(Speakers.col.value('SpeakerName[1]', 'nvarchar(max)'), '') AS [SpeakerName]
			,NULLIF(Speakers.col.value('Title[1]', 'nvarchar(max)'), '') AS [Title]
			,NULLIF(Speakers.col.value('Phone[1]', 'nvarchar(20)'), '') AS [Phone]
			,NULLIF(Speakers.col.value('Email[1]', 'nvarchar(255)'), '') AS [Email]
			,NULLIF(Speakers.col.value('TeamLevel[1]', 'nvarchar(255)'), '') AS [TeamLevel]
			,NULLIF(Speakers.col.value('Bio[1]', 'nvarchar(max)'), '') AS [Bio]
			,(SELECT [PK_EventImage] FROM [EventImageLocaleDesc] WITH (NOLOCK) WHERE [PK_EventImageLocaleDesc] = Speakers.col.value('PK_EventImageLocaleDesc[1]', 'int')) AS [PK_EventImage]
			,Speakers.col.value('PK_EventImageLocaleDesc[1]', 'int') AS [PK_EventImageLocaleDesc]
			,Speakers.col.value('EventImageLocation[1]', 'nvarchar(255)') AS [EventImageLocation]
			,Speakers.col.value('PK_EventImageType[1]', 'int') AS [PK_EventImageType]
			,Speakers.col.value('PK_EventURL[1]', 'int') AS [PK_EventURL]
			,Speakers.col.value('PK_EventURLType[1]', 'int') AS [PK_EventURLType]
			,Speakers.col.value('EventURL[1]', 'nvarchar(255)') AS [EventURL]
			,Speakers.col.value('EventURLDesc[1]', 'nvarchar(max)') AS [EventURLDesc]
			,GETUTCDATE() AS [CreatedDateUTC]
			,@User AS [CreatedBy]
			,GETUTCDATE() AS [ModifiedDateUTC]
			,@User AS [ModifiedBy]
			,ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS [n]
			,CAST(NULL AS bit) AS [NewRow]
		INTO #GuestSpeakers
		FROM @GuestSpeakers.nodes('/Speaker') AS Speakers(col)
		ORDER BY [n]		--BUG 693316 : Workaround

		-- BUG 710380 : PK_EventGuestSpeaker 7 already exists on the table (reset values to NULL for new records)
		UPDATE G
		SET PK_EventGuestSpeaker = NULL
		FROM #GuestSpeakers G
		WHERE PK_EventGuestSpeaker <= 8																										   

	-- ************************************************************ Show ******************************
	--IF @IsDevQA = 1 SELECT 'Source' AS [#GuestSpeakers], * FROM #GuestSpeakers;

	BEGIN TRY
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
						,[PK_Locale]
						,[SpeakerName]
						,[Title]
						,[Phone]
						,[Email]
						,[TeamLevel]
						,[Bio]
						,[PK_EventImageLocaleDesc]
						,[EventImageLocation]
						,[PK_EventImageType]
						,[PK_EventURL]
						,@GuestSpeakerImageType AS [PK_EventURLType]
						,[EventURL]
						,[EventURLDesc]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
						,[n]
					FROM #GuestSpeakers
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
				)
				VALUES (
					s.[PK_Event]
					,s.[SpeakerName]
					,s.[Title]
					,s.[Phone]
					,s.[Email]
					,s.[TeamLevel]
					,s.[Bio]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
				)
			WHEN MATCHED THEN
				UPDATE SET
					[EventSpeakerName] = s.[SpeakerName]
					,[EventSpeakerTitle] = s.[Title]
					,[EventSpeakerPhone] = s.[Phone]
					,[EventSpeakerEmail] = s.[Email]
					,[EventSpeakerTeamLevel] = s.[TeamLevel]
					,[EventSpeakerBio] = s.[Bio]
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
				,[NewRow] = CASE [action] WHEN 'INSERT' THEN 1 ELSE 0 END
			FROM  #GuestSpeakers AS t
				INNER JOIN @gs AS s ON s.[n] = t.[n];


		-- ************************************************************ Show ******************************
		--IF @IsDevQA = 1 
		--BEGIN
		--	SELECT 'Merge EventGuestSpeaker', * FROM @gs;
		--	SELECT '#GuestSpeakers', * FROM #GuestSpeakers;
		--END;

		------------------------------------------------------------------------------------------------------------------
		-- Save guest speaker in [EventGuestSpeakerLocale]
		--
		DECLARE @GuestSpeakerLocale table([action] varchar(10), [PK_EventGuestSpeaker] int, [PK_EventGuestSpeakerLocale] int);
	
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
						,s.[SpeakerName]
						,s.[Title]
						,s.[Phone]
						,s.[Email]
						,s.[TeamLevel]
						,s.[Bio]
						,s.[CreatedDateUTC]
						,s.[CreatedBy]
						,s.[ModifiedDateUTC]
						,s.[ModifiedBy]
						,s.[PK_Event]
						,s.[PK_Locale]
					FROM #GuestSpeakers AS s
				) AS s ON s.[PK_EventGuestSpeakerLocale] = t.[PK_EventGuestSpeakerLocale]
			WHEN MATCHED THEN
				UPDATE SET
					[EventSpeakerName] = s.[SpeakerName]
					,[EventSpeakerTitle] = s.[Title]
					,[EventSpeakerTeamLevel] = s.[TeamLevel]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
					,[EventSpeakerBio] = s.[Bio]
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
					,s.[SpeakerName]
					,s.[Title]
					,s.[TeamLevel]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
					,S.[PK_Event]
					,s.[PK_Locale]
					,s.[Bio]
				)
			OUTPUT	$action
					,inserted.[PK_EventGuestSpeaker]
					,inserted.[PK_EventGuestSpeakerLocale]
				INTO @GuestSpeakerLocale
		;	-- MERGE [EventGuestSpeakerLocale]

		UPDATE t SET
				[PK_EventGuestSpeakerLocale] = s.[PK_EventGuestSpeakerLocale]
			FROM #GuestSpeakers AS t
				INNER JOIN @GuestSpeakerLocale AS s ON s.[PK_EventGuestSpeaker] = t.[PK_EventGuestSpeaker];
		

		-- ************************************************************ Show ******************************
		--IF @IsDevQA = 1 
		--BEGIN
		--	SELECT 'Merge' AS [EventGuestSpeakerLocale], * FROM @GuestSpeakerLocale;
		--	SELECT 'Updated Source' AS [#GuestSpeakers], * FROM #GuestSpeakers;
		--END;
		
		------------------------------------------------------------------------------------------------------------------
		-- Save guest speaker URL
		--
		DECLARE @URLMerge Table(
			[action] nvarchar(10)
			,[PK_EventURL] int
			,[PK_Locale] int
			,[PK_EventURLType] int
			,[EventURL] varchar(255)
			,[Flyer] varchar(255)
			,[n] int
		);

		MERGE [dbo].[EventURL] AS t
			USING (
				SELECT 
						[PK_EventURL]
						,[PK_Event]
						,[PK_Locale]
						,[EventURL]
						,[EventURLDesc]
						,@GuestSpeakerURLType AS [PK_EventURLType]
						,@User AS [CreatedBy]
						,GETUTCDATE() AS [CreatedDateUTC]
						,@User AS [ModifiedBy]
						,GETUTCDATE() AS [ModifiedDateUTC]
						,[n]
					FROM #GuestSpeakers
					WHERE [EventURL] IS NOT NULL
				) AS s
				ON s.[PK_EventURL] = t.[PK_EventURL]
			WHEN MATCHED THEN
				UPDATE SET
					[EventURL] = s.[EventURL]
					,[EventURLDesc] = s.[EventURLDesc]
					,[ModifiedBy] = s.[ModifiedBy]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT(
						[PK_Event]
						,[PK_Locale]
						,[EventURL]
						,[EventURLDesc]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
						,[PK_EventURLType]
				)
				VALUES(
						s.[PK_Event]
						,s.[PK_Locale]
						,s.[EventURL]
						,s.[EventURLDesc]
						,s.[CreatedDateUTC]
						,s.[CreatedBy]
						,s.[ModifiedDateUTC]
						,s.[ModifiedBy]
						,s.[PK_EventURLType]
				)
			OUTPUT	$action
					,inserted.[PK_EventURL]
					,inserted.[PK_Locale]
					,inserted.[PK_EventURLType]
					,inserted.[EventURL]
					,inserted.[Flyer]
					,s.[n]
				INTO @URLMerge;

		--IF @isDevQA = 1 SELECT * FROM @URLMerge;
		
		UPDATE t SET
				[PK_EventURL] = u.[PK_EventURL]
			FROM #GuestSpeakers AS t
				INNER JOIN @URLMerge AS u ON u.[n] = t.[n];

		UPDATE g SET
				[PK_EventURL] = t.[PK_EventURL]
			FROM [EventGuestSpeakerLocale] AS g
				INNER JOIN #GuestSpeakers AS t ON t.[PK_EventGuestSpeakerLocale] = g.[PK_EventGuestSpeakerLocale];

		-- ************************************************************ Show ******************************
		--IF @IsDevQA = 1 
		--BEGIN
		--	SELECT 'URLMerge' AS [EventURL], * FROM @URLMerge;
		--	SELECT 'Update URL' AS [#GuestSpeakers], * FROM #GuestSpeakers;
		--END;


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
				WHERE EventImageLocation IS NOT NULL;
				
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
		--IF @IsDevQA = 1 
		--BEGIN
		--	SELECT 'EventImage' AS [@EventImage], * FROM @EventImage;
		--	SELECT 'Updated Source (images)' AS [#GuestSpeakers], * FROM #GuestSpeakers;
		--END;
		

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
						INNER JOIN @EventImage AS ei ON ei.EventImageLocation = g.EventImageLocation
					WHERE ISNULL(g.[EventImageLocation], '') != ''
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
			WHEN NOT MATCHED BY SOURCE AND t.[PK_Event] = @PK_Event THEN
				DELETE
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

		-- ************************************************************ Show ******************************
		--IF @IsDevQA = 1
		--BEGIN
		--	SELECT 'EventImageLocaleDesc' AS [@EventImageLocaleDesc], * FROM @EventImageLocaleDesc;
		--	SELECT 'Updated Image Locale' AS [#GuestSpeakers], * FROM #GuestSpeakers;
		--END;

		
		------------------------------------------------------------------------------------------------------------------
		-- Purge unused URLs and Images
		--
		WITH c AS (	-- Delete PK_EventURL that was deleted from [EventGuestSpeakerLocale]
			SELECT
					u.[PK_EventURL]
				FROM [EventURL] AS u WITH (NOLOCK)
					LEFT JOIN [EventGuestSpeakerLocale] AS g WITH (NOLOCK) ON g.[PK_EventURL] = u.[PK_EventURL]
				WHERE u.[PK_Event] = @PK_Event
					AND u.[PK_EventURLType] = @GuestSpeakerURLType
					AND g.[PK_EventURL] IS NULL
		)
		DELETE FROM [EventURL]
			WHERE [PK_EventURL] IN (SELECT [PK_EventURL] FROM c);
		
		-- Delete images that was deleted from [EventGuestSpeakers]
		DECLARE @DelImages table ([PK_EventImage] int);	

		INSERT INTO @DelImages -- Get PK_EventImage rows to be deleted
			SELECT
					i.[PK_EventImage]
				FROM [EventImage] AS i WITH (NOLOCK)
					LEFT JOIN [EventGuestSpeakers] AS g WITH (NOLOCK) ON g.[PK_EventImage] = i.[PK_EventImage]
				WHERE i.[PK_Event] = @PK_Event
					AND i.[PK_EventImageType] = @GuestSpeakerImageType
					AND g.[PK_EventImage] IS NULL;

		DELETE FROM [EventImageLocaleDesc] WHERE [PK_EventImage] IN (SELECT [PK_EventImage] FROM @DelImages);
		
		DELETE FROM [EventImage] WHERE [PK_EventImage] IN (SELECT [PK_EventImage] FROM @DelImages);

		-- ************************************************************ Show ******************************
		--IF @IsDevQA = 1
		--BEGIN
		--	SELECT 'EventImage to delete' AS [Del_EventImage], * FROM @DelImages;
		--END;


		------------------------------------------------------------------------------------------------------------------
		-- Delete Guest Speaker
		--
		IF OBJECT_ID('tempdb..#Del') IS NOT NULL
			DROP TABLE #Del;

		SELECT
				eg.[PK_EventGuestSpeaker]
				,eg.[PK_Event]
				,eg.[PK_EventImage]
				,el.[PK_Locale]
				,el.[PK_EventURL]
			INTO #Del
			FROM [dbo].[EventGuestSpeakers] AS eg WITH (NOLOCK)
				LEFT JOIN [dbo].[EventGuestSpeakerLocale] AS el WITH (NOLOCK) ON el.[PK_EventGuestSpeaker] = eg.[PK_EventGuestSpeaker]
			WHERE eg.[PK_EventGuestSpeaker] NOT IN (SELECT [PK_EventGuestSpeaker] FROM #GuestSpeakers WHERE [PK_EventGuestSpeaker] IS NOT NULL)
				AND eg.[PK_Event] = @PK_Event;
		
		-- ************************************************************ Show ******************************
		--IF @IsDevQA = 1 SELECT 'Rows to delete', * FROM #Del;


		DELETE FROM [EventGuestSpeakerLocale] WHERE [PK_EventGuestSpeaker] IN (SELECT [PK_EventGuestSpeaker] FROM #Del);

		DELETE FROM [EventGuestSpeakers] WHERE [PK_EventGuestSpeaker] IN (SELECT [PK_EventGuestSpeaker] FROM #Del);

		DELETE FROM [EventImageLocaleDesc] WHERE [PK_EventImage] IN (SELECT [PK_EventImage] FROM #Del);

		DELETE FROM [EventURL] WHERE [PK_EventURL] IN (SELECT [PK_EventURL] FROM #Del);

		DELETE FROM [EventImageLocaleDesc] WHERE [PK_EventImage] IN (SELECT [PK_EventImage] FROM #Del);

		DELETE FROM [EventImage] WHERE [PK_EventImage] IN (SELECT [PK_EventImage] FROM #Del);

		IF @TranCount = 0 COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @StoredProcedure AS [Stored Procedure], @Error AS [Error], @ErrorMessage AS [Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		 
	END CATCH;
	-- Deployment : 20180424
END;