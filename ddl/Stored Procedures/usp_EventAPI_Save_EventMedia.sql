CREATE PROCEDURE [dbo].[usp_EventAPI_Save_EventMedia]
		-- Mandatory Parameters
		@PK_Event int
		,@EventMedia xml

		-- Optional Paramenters
		,@User nvarchar(255) = NULL
		,@Delete bit = 1

		-- Error Parameters
		,@Error	int OUTPUT
		,@ErrorMessage varchar(MAX) OUTPUT
		
		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventAPI_Save_EventMedia
	
	USE:			
					DECLARE @e int
							,@em varchar(max)
							,@s nvarchar(max) = N'
									<Media>
										<PK_EventMedia></PK_EventMedia>
										<PK_Event>54138</PK_Event>
										<PK_MediaType>2</PK_MediaType>
										<Locale>es-MX</Locale>
										<MediaName>Video del Evento sp</MediaName>
										<MediaDesc>Descripción del video del evento cambio sp</MediaDesc>
										<MediaHTML><video>HTML video</video></MediaHTML>
									</Media>
									<Media>
										<PK_EventMedia></PK_EventMedia>
										<PK_Event>54138</PK_Event>
										<PK_MediaType>2</PK_MediaType>
										<Locale>es-US</Locale>
										<MediaName>Video del Evento EU cambio</MediaName>
										<MediaDesc>Descripción del video del evento EU cambio sp</MediaDesc>
										<MediaHTML><video>HTML video EU</video></MediaHTML>
									</Media>'
							,@Media xml;

					SELECT @Media = CAST(@s as xml);

					EXEC dbo.usp_EventAPI_Save_EventMedia
							@PK_Event = 54138
							,@EventMedia = @Media
							,@IsDevQA = 1
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					
					SELECT @e, @em

	DESCRIPTION:	Save an EventMedia record

	NOTES:
	
	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.EventMedia

	VERSIONS (PROD)
	--------------------------------------------------------------------
	1.0.0		2017-09-18		RogelioR		Initial	
	1.0.1		201p-11-04		NoeG			SRE chnages
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(MAX);
	
	DECLARE @MediaMerge Table([action] nvarchar(10), PK_EventMedia int, PK_MediaType int, PK_Locale int);

	SELECT @User = ISNULL(@User, REPLACE(SYSTEM_USER, 'HERBALIFECORP\', ''));

	BEGIN TRY;
		WITH cte_media AS (
			SELECT
					NULLIF(Media.col.value('PK_EventMedia[1]', 'int'), 0) AS [PK_EventMedia]
					,ISNULL(NULLIF(Media.col.value('PK_Event[1]', 'int'), 0), @PK_Event) AS [PK_Event]
					,Media.col.value('PK_MediaType[1]', 'int') AS [PK_MediaType]
					,(SELECT PK_Locale FROM [dbo].[Locales] WITH (NOLOCK) WHERE LocaleCode = Media.col.value('Locale[1]', 'varchar(5)')) AS [PK_Locale]
					,Media.col.value('MediaName[1]', 'nvarchar(255)') AS [MediaName]
					,Media.col.value('MediaDesc[1]', 'nvarchar(max)') AS [MediaDesc]
					,Media.col.value('MediaHTML[1]', 'nvarchar(max)') AS [MediaHTML]
				FROM @EventMedia.nodes('/Media') AS Media(col)
		)
		MERGE [dbo].[EventMedia] AS t
			USING (
				SELECT 
						c.[PK_EventMedia]
						,c.[PK_Event]
						,c.[PK_MediaType]
						,c.[PK_Locale]
						,c.[MediaName]
						,c.[MediaDesc]
						,c.[MediaHTML]
						,@User AS [CreatedBy]
						,GETUTCDATE() AS [CreatedDateUTC]
						,@User AS [ModifiedBy]
						,GETUTCDATE() AS [ModifiedDateUTC]
					FROM cte_media AS c
				) AS s
				ON s.[PK_EventMedia] = t.[PK_EventMedia]
			WHEN MATCHED THEN
				UPDATE SET
					[MediaName] = s.[MediaName]
					,[MediaDesc] = s.[MediaDesc]
					,[MediaHTML] = s.[MediaHTML]
					,[ModifiedBy] = s.[ModifiedBy]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
			WHEN NOT MATCHED BY TARGET THEN
				INSERT(
						[PK_Event]
						,[PK_MediaType]
						,[PK_Locale]
						,[MediaName]
						,[MediaDesc]
						,[MediaHTML]
						,[CreatedBy]
						,[CreatedDateUTC]
						,[ModifiedBy]
						,[ModifiedDateUTC]
				)
				VALUES(
						s.[PK_Event]
						,s.[PK_MediaType]
						,s.[PK_Locale]
						,s.[MediaName]
						,s.[MediaDesc]
						,s.[MediaHTML]
						,s.[CreatedBy]
						,s.[CreatedDateUTC]
						,s.[ModifiedBy]
						,s.[ModifiedDateUTC]
				)
			WHEN NOT MATCHED BY SOURCE AND t.[PK_Event] = @PK_Event AND @Delete = 1 THEN
				DELETE
			OUTPUT $action, inserted.PK_EventMedia, inserted.PK_MediaType, inserted.PK_Locale INTO @MediaMerge
		;	-- MERGE EventMedia

		--IF @IsDevQA = 1 SELECT <all> FROM @MediaMerge;

		SELECT @Error = 0, @ErrorMessage ='';

	END TRY
	BEGIN CATCH
			SET @Error = ERROR_NUMBER()
			SET @ErrorMessage = ERROR_MESSAGE()
			SET @StoredProcedure = ERROR_PROCEDURE()

			IF @IsDevQA = 1 SELECT @StoredProcedure, @Error, @ErrorMessage;

			-- UPDATE ERROR LOG
			EXEC dbo.usp_Utility_UpdateErrorLog 
					@ProcedureName = @StoredProcedure
					,@ErrorNumber = 3
					,@ErrorMessage = @ErrorMessage OUTPUT
					,@SQLErrorCode = @Error
					,@SQLErrorMsg = @ErrorMessage;

			RETURN;
	END CATCH;
END;
GO

