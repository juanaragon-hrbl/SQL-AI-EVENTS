CREATE PROCEDURE [dbo].[usp_EventAPI_Save_DSTickets]
		-- Mandatory Parameters
		@PK_Event int
		,@Tickets xml
		,@LocaleCode varchar(5)

		-- Optional Paramenters
		,@User nvarchar(255) = NULL

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = NULL OUTPUT
		
		-- Defaults
		,@PK_TicketEventSKUType int = 7	-- Distributor Event Tickets
		,@PK_TicketEventURLType int = 5	-- Ticket Purchase Third Party Link
		
		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************

	OBJECT:			[dbo].[usp_EventAPI_Save_DSTickets]

	USE:			
		begin tran

			DECLARE @s nvarchar(max) = N'
										<Ticket>
										  <PK_EventSKU />
										  <Name>Entrada</Name>
										  <Desc>Entrada al evento</Desc>
										  <PK_EventURL />
										  <Link>http://herbalife.com/boleto2</Link>
										  <Qty>200</Qty>
										  <Price>100</Price>
										  <Currency>840</Currency>
										</Ticket>
										<Ticket>
										  <PK_EventSKU></PK_EventSKU>
										  <Name>Desayuno</Name>
										  <Desc>Desayuno en el evento</Desc>
										  <PK_EventURL />
										  <Link>http://herbalife.com/boleto2</Link>
										  <Qty>100</Qty>
										  <Price>60</Price>
										  <Currency>840</Currency>
										</Ticket>'
					,@t xml
					,@e int
					,@em varchar(max)

			SELECT @t = CAST(@s as xml);

			EXEC [dbo].[usp_EventAPI_Save_DSTickets]
					@PK_Event = 78006
					,@lOCALECODE = 'en-US'
					,@Tickets = @t
					,@IsDevQA = 1
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					
			SELECT @e, @em

		rollback tran
					
	DESCRIPTION:	Save Distributor Events tickets

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	[dbo].[EventSKU], [dbo].[EventSKULocaleDesc]

	VERSIONS (PROD)
	--------------------------------------------------------------------
	1.0.0		2017-10-25		RogelioR		Initial
	1.1.0		2018-03-14		RogelioR		Names, URLs and Ticket descriptions don't have to be unique
	1.2.0		2019-08-01		alejandramed	Including error handling and processing log
	2.1.0		2019-10-17		SushmaA			SRE updates for NOLOCK, NOCOUNT, SELECT *	
	2.1.1		2020-06-19		puertac			Bug 278695, Russian Characters shown as '???????' on Name and Description changed varchar to nvarchar
	2.1.2		2021-06-14		puertac			BUG 693316 : Keep the tickets sequence as received on the XML
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

	DECLARE @PK_Locale int = (SELECT [PK_Locale] FROM [dbo].[Locales] with (nolock) WHERE [LocaleCode] = @LocaleCode)

	SELECT	@User = ISNULL(@User, REPLACE(SYSTEM_USER, 'HERBALIFECORP\', ''));

	IF OBJECT_ID('tempdb..#Tickets') IS NOT NULL
		DROP TABLE #Tickets;

	SELECT  IDENTITY(INT,1,1) AS PK			--BUG 693316 : Workaround
			,@PK_Event AS [PK_Event]
			,NULLIF(Ticket.col.value('PK_EventSKU[1]', 'int'), 0) AS [PK_EventSKU]
			,@PK_Locale AS [PK_Locale]
			,@LocaleCode AS [LocaleCode]
			,Ticket.col.value('Name[1]', 'nvarchar(100)') AS [Name]				-- Bug 278695
			,Ticket.col.value('Desc[1]', 'nvarchar(max)') AS [Desc]				-- Bug 278695
			,NULLIF(Ticket.col.value('Link[1]', 'varchar(255)'), '') AS [Link]
			,Ticket.col.value('Qty[1]', 'int') AS [Qty]
			,Ticket.col.value('Price[1]', 'numeric(8,2)') AS [Price]
			,Ticket.col.value('Currency[1]', 'int') AS [Currency]
			,@PK_TicketEventSKUType AS [PK_EventSKUType]
			,@PK_TicketEventURLType AS [PK_EventURLType]
			,CAST(NULL AS INT) AS [PK_EventURL]					--BUG 693316 : Workaround
			,CAST(NULL AS INT) AS [PK_EventSKULocaleDesc]       --BUG 693316 : Workaround
			,GETUTCDATE() AS [CreatedDateUTC]                   --BUG 693316 : Workaround
			,@User AS [CreatedBy]                               --BUG 693316 : Workaround
			,GETUTCDATE() AS [ModifiedDateUTC]
			,@User AS [ModifiedBy]
			,ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS [n]
		INTO #Tickets
		FROM @Tickets.nodes('/Ticket') AS Ticket(col)
		ORDER BY [n]		--BUG 693316 : Workaround

	    --BUG 693316 : Workaround
		UPDATE T
		SET  T.CreatedDateUTC		 = ISNULL(e.CreatedDateUTC,T.CreatedDateUTC)
			,T.CreatedBy			 = ISNULL(e.[CreatedBy],T.CreatedBy)
			,T.PK_EventURL			 = el.[PK_EventURL]
			,T.PK_EventSKULocaleDesc = el.[PK_EventSKULocaleDesc]
		FROM #Tickets T
		LEFT JOIN [EventSKU] AS e WITH (NOLOCK) 
			ON e.[PK_EventSKU] = T.PK_EventSKU
		LEFT JOIN [EventSKULocaleDesc] AS el WITH (NOLOCK) 
			ON el.[PK_EventSKU] = T.PK_EventSKU

	--IF @IsDevQA = 1 SELECT '#Tickets', * FROM #Tickets

	--
	DECLARE @t table (
		[Action] varchar(10)
		,[PK_EventSKU] int
		,[SKUDesc] nvarchar(100)				-- Bug 278695
		,[n] int
	);

	--
	IF @IsDevQA = 1
		SELECT
				'#Tickets From Param'
				,t.[PK_EventSKU] AS [PK_EventSKU]
				,t.[CreatedDateUTC]
				,t.[CreatedBy]
				,t.[ModifiedDateUTC]
				,@User AS [ModifiedBy]
				,t.[PK_Event] AS [PK_Event]
				,RIGHT(CAST(@PK_Event AS varchar(255)), 4) AS [SKUCode]
				,t.[Name] AS [SKUDesc]
				,t.[Price] AS [Price]
				,t.[Qty] AS [QuantityInStock]
				,t.[PK_EventSKUType] AS [PK_EventSKUType]
				,t.[PK_Locale] AS [PK_Locale]
				,t.[PK_EventURL]
				,t.[PK_EventSKULocaleDesc]
				,t.[n]
			FROM #Tickets AS t
	--
	MERGE [dbo].[EventSKU] AS t
		USING( 
			SELECT
					t.[PK_EventSKU] AS [PK_EventSKU]
					,ISNULL(e.[CreatedDateUTC], GETUTCDATE()) AS [CreatedDateUTC]
					,ISNULL(e.[CreatedBy], @User) AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,@User AS [ModifiedBy]
					,t.[PK_Event] AS [PK_Event]
					,RIGHT(CAST(@PK_Event AS varchar(255)), 4) AS [SKUCode]
					,t.[Name] AS [SKUDesc]										-- Bug 278695 Modify on the Table
					,t.[Price] AS [Price]
					,t.[Qty] AS [QuantityInStock]
					,t.[PK_EventSKUType] AS [PK_EventSKUType]
					,t.[PK_Locale] AS [PK_Locale]
					,t.[n]
				FROM #Tickets AS t
					LEFT JOIN [dbo].[EventSKU] AS e with (nolock) ON e.[PK_EventSKU] = t.[PK_EventSKU]
			) AS s ON s.[PK_EventSKU] = t.[PK_EventSKU]
		WHEN MATCHED THEN
			UPDATE SET
				[SKUDesc] = s.[SKUDesc]
				,[Price] = s.[Price]
				,[QuantityInStock] = s.[QuantityInStock]
				,[ModifiedDateUTC] = s.[ModifiedDateUTC]
				,[ModifiedBy] = s.[ModifiedBy]
		WHEN NOT MATCHED THEN
			INSERT(
				[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
				,[PK_Event]
				,[SKUCode]
				,[SKUDesc]
				,[Price]
				,[QuantityInStock]
				,[PK_EventSKUType]
				,[PK_Locale]
			)
			VALUES(
				s.[CreatedDateUTC]
				,s.[CreatedBy]
				,s.[ModifiedDateUTC]
				,s.[ModifiedBy]
				,s.[PK_Event]
				,s.[SKUCode]
				,s.[SKUDesc]
				,s.[Price]
				,s.[QuantityInStock]
				,s.[PK_EventSKUType]
				,s.[PK_Locale]
			)
		OUTPUT 
				$action
				,inserted.[PK_EventSKU]
				,inserted.[SKUDesc]
				,s.[n]
			INTO @t
	; -- MERGE

	--IF @IsDevQA = 1 SELECT '[EventSKU]', * FROM @t;

	--
	UPDATE t SET
			[PK_EventSKU] = s.[PK_EventSKU]
		FROM #Tickets AS t
			INNER JOIN @t AS s ON s.[SKUDesc] = t.[Name]
				AND s.[n] = t.[n];

	--IF @IsDevQA = 1 SELECT 'Updated Tickets', * FROM #Tickets;
	
	DECLARE @tl table (
		[Action] varchar(10)
		,[PK_EventSKU] int
		,[PK_EventSKULocaleDesc] int
		,[PK_EventURL] int
		,[PK_EventSKU_Del] int
		,[PK_EventSKULocaleDesc_Del] int
		,[PK_EventURL_Del] int
	);
	
	IF @IsDevQA = 1
		SELECT
				'i LocaleDesc'
				,e.[PK_EventSKULocaleDesc]
				,t.[PK_EventSKU]
				,t.[PK_Event]
				,t.[Desc] AS [SKUDesc]
				,t.[PK_Locale]
				,ISNULL(e.[CreatedDateUTC], GETUTCDATE()) AS [CreatedDateUTC]
				,ISNULL(e.[CreatedBy], @User) AS [CreatedBy]
				,GETUTCDATE() AS [ModifiedDateUTC]
				,@User AS [ModifiedBy]
				,t.[n]
			FROM #Tickets AS t
				LEFT JOIN [dbo].[EventSKULocaleDesc] AS e with (nolock) ON e.[PK_EventSKU] = t.[PK_EventSKU]
					AND e.[PK_Locale] = t.[PK_Locale];
						
	--		
	MERGE [dbo].[EventSKULocaleDesc] AS t
		USING(
			SELECT
					t.[PK_EventSKULocaleDesc]
					,t.[PK_EventSKU]
					,t.[PK_Event]
					,t.[Desc] AS [SKUDesc]
					,t.[PK_Locale]
					,t.[Currency]
					,ISNULL(e.[CreatedDateUTC], GETUTCDATE()) AS [CreatedDateUTC]
					,ISNULL(e.[CreatedBy], @User) AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,@User AS [ModifiedBy]
				FROM #Tickets AS t
					LEFT JOIN [dbo].[EventSKULocaleDesc] AS e with (nolock) ON e.[PK_EventSKU] = t.[PK_EventSKU]
						AND e.[PK_Locale] = t.[PK_Locale]
			) AS s ON s.[PK_EventSKULocaleDesc] = t.[PK_EventSKULocaleDesc]
		WHEN MATCHED THEN
			UPDATE SET
				[SKUDesc] = s.[SKUDesc]
				,[PK_Currency] = s.[Currency]
				,[ModifiedDateUTC] = s.[ModifiedDateUTC]
				,[ModifiedBy] = s.[ModifiedBy]
		WHEN NOT MATCHED THEN
			INSERT (
				[PK_EventSKU]
				,[PK_Event]
				,[SKUDesc]
				,[PK_Locale]
				,[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
				,[PK_Currency]
			)
			VALUES (
				s.[PK_EventSKU]
				,s.[PK_Event]
				,s.[SKUDesc]
				,s.[PK_Locale]
				,s.[CreatedDateUTC]
				,s.[CreatedBy]
				,s.[ModifiedDateUTC]
				,s.[ModifiedBy]
				,s.[Currency]
			)
		WHEN NOT MATCHED BY SOURCE AND t.[PK_Event] = @PK_Event THEN
			DELETE
		OUTPUT 
				$action
				,inserted.[PK_EventSKU]
				,inserted.[PK_EventSKULocaleDesc]
				,inserted.[PK_EventURL]
				,deleted.[PK_EventSKU]
				,deleted.[PK_EventSKULocaleDesc]
				,deleted.[PK_EventURL]
			INTO @tl
	; -- MERGE

	--IF @IsDevQA = 1 SELECT '@tl', * FROM @tl;
	
	--
	DECLARE @eu table (
		[Action] varchar(10)
		,[PK_EventURL] int
		,[PK_Locale] int
		,[EventURL] varchar(255)
		,[PK_EventURL_Del] int
		,[EventURL_Del] varchar(255)
		,[n] int
	);

	--
	IF @IsDevQA = 1
		SELECT DISTINCT
				'PK_EventURL ->'
				,e.[PK_EventURL]
				,t.[PK_Event]
				,t.[PK_Locale]
				,t.[Link] AS [EventURL]
				,ISNULL(e.[CreatedDateUTC], GETUTCDATE()) AS [CreatedDateUTC]
				,ISNULL(e.[CreatedBy], @User) AS [CreatedBy]
				,GETUTCDATE() AS [ModifiedDateUTC]
				,@User AS [ModifiedBy]
				,t.[PK_EventURLType]
				,t.[n]
			FROM #Tickets AS t
				LEFT JOIN [dbo].[EventURL] AS e with (nolock) ON e.[PK_EventURL] = t.[PK_EventURL]
			WHERE t.[Link] IS NOT NULL;

	--
	WITH cte AS (
		SELECT DISTINCT
				e.[PK_EventURL]
				,t.[PK_Event]
				,t.[PK_Locale]
				,t.[Link] AS [EventURL]
				,ISNULL(e.[CreatedDateUTC], GETUTCDATE()) AS [CreatedDateUTC]
				,ISNULL(e.[CreatedBy], @User) AS [CreatedBy]
				,GETUTCDATE() AS [ModifiedDateUTC]
				,@User AS [ModifiedBy]
				,t.[PK_EventURLType]
				,t.[n]
			FROM #Tickets AS t
				LEFT JOIN [dbo].[EventURL] AS e with (nolock) ON e.[PK_EventURL] = t.[PK_EventURL]
			WHERE t.[Link] IS NOT NULL
	)
	MERGE [dbo].[EventURL] AS t
		USING(
			SELECT
					[PK_EventURL]
					,[PK_Event]
					,[PK_Locale]
					,[EventURL]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
					,[PK_EventURLType]
					,[n]
				FROM cte
			) AS s ON s.[PK_EventURL] = t.[PK_EventURL]
		WHEN MATCHED THEN
			UPDATE SET
				[EventURL] = s.[EventURL]
				,[ModifiedDateUTC] = s.[ModifiedDateUTC]
				,[ModifiedBy] = s.[ModifiedBy]
		WHEN NOT MATCHED THEN
			INSERT (
				[PK_Event]
				,[PK_Locale]
				,[EventURL]
				,[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
				,[PK_EventURLType]
			)
			VALUES (
				s.[PK_Event]
				,s.[PK_Locale]
				,s.[EventURL]
				,s.[CreatedDateUTC]
				,s.[CreatedBy]
				,s.[ModifiedDateUTC]
				,s.[ModifiedBy]
				,s.[PK_EventURLType]
			)
		WHEN NOT MATCHED BY SOURCE AND t.[PK_Event] = @PK_Event AND t.[PK_EventURLType] = 5 THEN
			DELETE
		OUTPUT 
				$action
				,inserted.[PK_EventURL]
				,inserted.[PK_Locale]
				,inserted.[EventURL]
				,deleted.[PK_EventURL]
				,deleted.[EventURL]
				,s.[n]
			INTO @eu
	; -- MERGE EventURL
	
	--IF @IsDevQA = 1 SELECT '@eu', * FROM @eu;

	--
	UPDATE t SET
			[PK_EventURL] = s.[PK_EventURL]
		FROM #Tickets AS t
			INNER JOIN @eu AS s ON s.[n] = t.[n]

	--IF @IsDevQA = 1 SELECT '#Tickets', * FROM #Tickets;

	UPDATE t SET
			[PK_EventURL] = s.[PK_EventURL]
		FROM [dbo].[EventSKULocaleDesc] AS t
			INNER JOIN #Tickets AS s ON s.[PK_EventSKU] = t.[PK_EventSKU];
			
/* ***************** SonarQube check 26 - Nullable subqueries should not be used in "NOT IN" conditions */
	DELETE FROM [dbo].[EventSKU] 
		WHERE [PK_EventSKU] NOT IN (SELECT [PK_EventSKU] FROM [dbo].[EventSKULocaleDesc] with (nolock) WHERE [PK_Event] = @PK_Event and [PK_EventSKU] IS NOT NULL)
			AND [PK_Event] = @PK_Event;
/* ***************** SonarQube check 26 */

	DELETE FROM [dbo].[EventURL]
		WHERE [PK_EventURL] IN (SELECT [PK_EventURL_Del] FROM @eu WHERE [Action] = 'DELETE');

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
	END CATCH;
END;