CREATE PROCEDURE [dbo].[usp_EventAPI_Save_Agenda]
		-- Mandatory Parameters
		@PK_Event int
		,@Agenda xml

		-- Optional Paramenters
		,@User nvarchar(255) = NULL

		-- Error Parameters
		,@Error	int OUTPUT
		,@ErrorMessage varchar(MAX) OUTPUT
		
		-- Defaults
		,@PK_AgendaItemType int = 2

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			dbo.usp_EventAPI_Save_Agenda
	
	USE:			
				DECLARE @s varchar(max) = N'
								<Agenda>
									<PK_AgendaItem></PK_AgendaItem>
									<Locale>en-US</Locale>
									<StartDate>2017-09-30 08:00:00</StartDate>
									<EndDate>2017-09-30 10:00:00</EndDate>
									<Title>Breakfast</Title>
									<Description>Breakfast in McDonalds</Description>
									<IsSubEvent>1</IsSubEvent>
								</Agenda>
								<Agenda>
									<PK_AgendaItem></PK_AgendaItem>
									<Locale>en-US</Locale>
									<StartDate>2017-09-30 11:00:00</StartDate>
									<EndDate>2017-09-30 12:00:00</EndDate>
									<Title>Conference</Title>
									<Description>Conference in venue</Description>
									<IsSubEvent>0</IsSubEvent>
								</Agenda>								'
						,@Agenda xml = null
						,@e int
						,@em varchar(max)

				SELECT @Agenda = CAST(@s as xml);

				EXEC dbo.usp_EventAPI_Save_Agenda
						@PK_Event = 53844
						,@Agenda = @Agenda
						,@IsDevQA = 1
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					
				SELECT @e, @em

				SELECT <all> FROM Agenda WHERE pk_event = 53844
				SELECT <all> FROM AgendaiTEM WHERE pk_AGENDA IN (SELECT pk_aGENDA FROM Agenda WHERE pk_event = 53844)
				
	DESCRIPTION:	Save guest speakers

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.EventGuestSpeakers, dbo.EventGuestSpeakersLocale, dbo.EventURL, dbo.EventImage, dbo.EventImageLocaleDesc

	VERSIONS (PROD)
	--------------------------------------------------------------------
	1.0.0		2017-10-02		RogelioR		Initial
	1.0.1		2019-11.04		NoeG			SRE changes applied
	1.0.2		2020-06-19		puertac			Bug 278695 Russian Characters shown as '??????????' change type from varchar to nvarchar
	
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255)
			,@Rows int;

	SELECT @User = ISNULL(@User, REPLACE(SYSTEM_USER, 'HERBALIFECORP\', ''));

	DECLARE @AgendaPK table([Action] varchar(10), [PK_Agenda] int);

	DECLARE @AgendaItemMerge table([Action] varchar(10), [PK_Agenda] int, [PK_AgendaItem] int);

	BEGIN TRY	
		IF OBJECT_ID('tempdb.dbo.#Agenda') IS NOT NULL
			DROP TABLE #Agenda;
	
		WITH cte_xml AS (
			SELECT 
					Agenda.col.value('PK_AgendaItem[1]', 'int') AS [PK_AgendaItem]
					,@PK_Event AS [PK_Event]
					,UPPER(SUBSTRING(Agenda.col.value('Locale[1]', 'varchar(5)'), 1, 2)) AS [AgendaLanguage]
					,Agenda.col.value('StartDate[1]', 'datetime2') AS [LocalStartDate]
					,Agenda.col.value('EndDate[1]', 'datetime2') AS [LocalEndDate]
					,NULLIF(Agenda.col.value('Title[1]', 'nvarchar(max)'), '') AS [Title]				--Bug 278695
					,NULLIF(Agenda.col.value('Description[1]', 'nvarchar(max)'), '') AS [Description]	--Bug 278695
					,Agenda.col.value('IsSubEvent[1]', 'bit') AS [IsSubEvent]
				FROM @Agenda.nodes('/Agenda') AS Agenda(col)
		)
		SELECT
				c.[PK_AgendaItem]
				,ISNULL(a.[PK_Agenda], (SELECT TOP 1 [PK_Agenda] FROM [Agenda] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)) AS [PK_Agenda]
				,c.[PK_Event]
				,c.[AgendaLanguage]
				,e.[EventName]
				,ISNULL(c.[Title], ai.[DisplayDescription]) AS [DisplayDescription]
				,ISNULL(c.[Description], ai.[DisplayLocation]) AS [DisplayLocation]
				,c.[LocalStartDate]
				,c.[LocalEndDate]
				,@User AS [CreatedBy]
				,GETUTCDATE() AS [CreatedUTC]
				,@User AS [UpdatedBy]
				,GETUTCDATE() AS [UpdatedUTC]
				,c.[IsSubEvent]
			INTO #Agenda
			FROM cte_xml AS c
				INNER JOIN [dbo].[Event] AS e WITH (NOLOCK) ON e.[PK_Event] = @PK_Event
				LEFT JOIN [dbo].[AgendaItem] AS ai WITH (NOLOCK) ON ai.[PK_AgendaItem] = c.[PK_AgendaItem]
				LEFT JOIN [dbo].[Agenda] AS a WITH (NOLOCK) ON a.[PK_Agenda] = ai.[PK_Agenda];
		
		--IF @IsDevQA = 1 SELECT <all> FROM #Agenda;
				
		MERGE [dbo].[Agenda] AS t
			USING (
					SELECT TOP 1
							[PK_AgendaItem]
							,[PK_Agenda]
							,[PK_Event]
							,[AgendaLanguage]
							,[EventName]
							,[DisplayDescription]
							,[DisplayLocation]
							,[LocalStartDate]
							,[LocalEndDate]
							,[CreatedBy]
							,[CreatedUTC]
							,[UpdatedBy]
							,[UpdatedUTC]
						FROM #Agenda
				) AS s ON s.[PK_Agenda] = t.[PK_Agenda]
			WHEN NOT MATCHED THEN
				INSERT(
					[PK_Event]
					,[AgendaLanguage]
					,[AgendaDescription]
					,[CreatedUTC]
					,[CreatedBy]
					,[UpdatedUTC]
					,[UpdatedBy]
				)
				VALUES(
					[PK_Event]
					,[AgendaLanguage]
					,[EventName]
					,[CreatedUTC]
					,[CreatedBy]
					,[UpdatedUTC]
					,[UpdatedBy]
				)
			WHEN MATCHED THEN
				UPDATE SET
					[AgendaDescription] = s.[EventName]
					,[AgendaLanguage] = s.[AgendaLanguage]
					,[UpdatedUTC] = s.[UpdatedUTC]
					,[UpdatedBy] = s.[UpdatedBy]
			OUTPUT $action, inserted.[PK_Agenda] INTO @AgendaPK;
		; -- MERGE Agenda

		UPDATE #Agenda SET
			[PK_Agenda] = (SELECT TOP 1 [PK_Agenda] FROM @AgendaPK)

		--IF @IsDevQA = 1
		--BEGIN
		--	SELECT 'AgendaPK', <all> FROM @AgendaPK;

		--	SELECT '#Agenda', <all> FROM #Agenda;
		--END;
		
		---- 
		MERGE [dbo].[AgendaItem] AS t
			USING (
				SELECT 
						[PK_AgendaItem]
						,[PK_Agenda]
						,@PK_AgendaItemType AS [PK_AgendaItemType]
						,[DisplayDescription]
						,[DisplayLocation]
						,[LocalStartDate]
						,[LocalEndDate]
						,[CreatedUTC]
						,[CreatedBy]
						,[UpdatedUTC]
						,[UpdatedBy]
						,[IsSubEvent]
					FROM #Agenda
				) AS s ON s.[PK_AgendaItem] = t.[PK_AgendaItem]
			WHEN NOT MATCHED THEN
				INSERT(
					[PK_Agenda]
					,[PK_AgendaItemType]
					,[DisplayDescription]
					,[DisplayLocation]
					,[LocalStartDate]
					,[LocalEndDate]
					,[CreatedUTC]
					,[CreatedBy]
					,[UpdatedUTC]
					,[UpdatedBy]
					,[IsSubEvent]
				)
				VALUES(
					s.[PK_Agenda]
					,s.[PK_AgendaItemType]
					,s.[DisplayDescription]
					,s.[DisplayLocation]
					,s.[LocalStartDate]
					,s.[LocalEndDate]
					,s.[CreatedUTC]
					,s.[CreatedBy]
					,s.[UpdatedUTC]
					,s.[UpdatedBy]
					,s.[IsSubEvent]
				)
			WHEN MATCHED THEN
				UPDATE SET
					[DisplayDescription] = s.[DisplayDescription]
					,[DisplayLocation] = s.[DisplayLocation]
					,[UpdatedUTC] = s.[UpdatedUTC]
					,[UpdatedBy] = s.[UpdatedBy]
					,[IsSubEvent] = s.[IsSubEvent]
					,[LocalStartDate] = s.[LocalStartDate]
			WHEN NOT MATCHED BY SOURCE AND t.[PK_Agenda] IN (SELECT [PK_Agenda] FROM [Agenda] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event) THEN
				DELETE
			OUTPUT $action, inserted.[PK_Agenda], inserted.[PK_AgendaItem] INTO @AgendaItemMerge
		; -- MERGE AgendaItem

		IF @IsDevQA = 1
				SELECT DISTINCT
						a.[PK_AgendaItem]
					FROM [dbo].[AgendaItem] AS a WITH (NOLOCK) 	
						LEFT JOIN @AgendaItemMerge AS m ON a.[PK_AgendaItem] = m.[PK_AgendaItem]
					WHERE a.[PK_Agenda] IN (SELECT [PK_Agenda] FROM @AgendaItemMerge)
						AND m.[PK_Agenda] IS NULL;

		DELETE FROM [dbo].[AgendaItem] WHERE [PK_AgendaItem] IN (
				SELECT DISTINCT
						a.[PK_AgendaItem]
					FROM [dbo].[AgendaItem] AS a WITH (NOLOCK) 	
						LEFT JOIN @AgendaItemMerge AS m ON a.[PK_AgendaItem] = m.[PK_AgendaItem]
					WHERE a.[PK_Agenda] IN (SELECT [PK_Agenda] FROM @AgendaItemMerge)
						AND m.[PK_Agenda] IS NULL
			);

		SELECT 
				[PK_Agenda]
				,COUNT(*) AS [AgendaItems]
			INTO #AgendaEvent
			FROM [dbo].[AgendaItem] WITH (NOLOCK) 
			WHERE [PK_Agenda] IN (SELECT [PK_Agenda] FROM @AgendaItemMerge)
			GROUP BY [PK_Agenda];
		
		SELECT @Rows = @@ROWCOUNT;

		--IF @IsDevQA = 1
		--BEGIN
		--	SELECT @Rows AS NumberOfRows;
		--	SELECT <all> FROM #AgendaEvent
		--END;

		IF @Rows = 0
			DELETE FROM [dbo].[Agenda] WHERE [PK_Event] = @PK_Event;
		ELSE
			DELETE FROM [dbo].[Agenda] WHERE [PK_Agenda] IN (SELECT [PK_Agenda] FROM #AgendaEvent WHERE [AgendaItems] = 0);

		--IF @IsDevQA = 1
		--BEGIN
		--	SELECT <all> FROM @AgendaItemMerge;	
		--END;

		SELECT @Error = 0, @ErrorMessage = 'No Error';
	END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error, @ErrorMessage;

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage 
	END CATCH;
END;
