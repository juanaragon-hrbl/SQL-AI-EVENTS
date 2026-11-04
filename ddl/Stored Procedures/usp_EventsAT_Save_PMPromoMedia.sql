CREATE PROCEDURE [dbo].[usp_EventsAT_Save_PMPromoMedia]
	-- Required
	@PK_Event		int
	,@LocaleCode	varchar(5)
	,@MediaHTML		nvarchar(MAX)
	
	-- Optional
	,@MediaDesc		nvarchar(MAX) = null
	,@MediaName		nvarchar(200) = null
	,@PK_MediaType	int = 2
	,@PK_EventMedia	int = NULL
	,@UserName		varchar(255) = NULL

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS

BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Save_PMPromoMedia

	USE:			
					DECLARE @e int, @em varchar(4000)
					
					EXEC dbo.usp_EventsAT_Save_PMPromoMedia
							@PK_Event = 48019
							,@LocaleCode = 'es-MX'
							,@PK_EventMedia = NULL

							-- Optional
							,@MediaName = 'Video de prueba'
							,@MediaDesc = 'Descripción del video de prueba'
							,@MediaHTML = 'HTML DEL VIDEO'

							-- Errors
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

					SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	Insert/Updates a record in EventURL
	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.EventURL

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-03		RogelioR		Initial
	2.0.0		2019-08-08		NoeG			Refactor code (SRE)
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = ''
			,@UserName = ISNULL(@UserName, (REPLACE(SUSER_SNAME(),'HERBALIFECORP\','')));
			
	BEGIN TRY
		MERGE dbo.EventMedia AS t
			USING (SELECT
						@PK_EventMedia AS PK_EventMedia
						,@PK_Event AS PK_Event
						,@PK_MediaType AS PK_MediaType
						,(SELECT PK_Locale FROM Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode) AS [PK_Locale]
						,@MediaName AS [MediaName]
						,@MediaDesc AS [MediaDesc]
						,@MediaHTML AS [MediaHTML]
						,GETUTCDATE() AS CreatedDateUTC
						,@UserName AS CreatedBy
						,GETUTCDATE() AS ModifiedDateUTC
						,@UserName AS ModifiedBy
				) AS s
				ON (t.PK_EventMedia = s.PK_EventMedia)
			WHEN MATCHED THEN
				UPDATE SET
					[PK_Event] = s.PK_Event
					,[PK_MediaType] = s.PK_MediaType
					,[PK_Locale] = s.PK_Locale
					,[MediaName] = s.[MediaName]
					,[MediaDesc] = s.MediaDesc
					,[MediaHTML] = s.MediaHTML
					,[ModifiedDateUTC] = s.ModifiedDateUTC
					,[ModifiedBy] = s.ModifiedBy
			WHEN NOT MATCHED THEN
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
			OUTPUT $action, inserted.[PK_Event]
					,inserted.[PK_MediaType]
					,inserted.[PK_Locale]
					,inserted.[MediaName]
					,inserted.[MediaDesc]
					,inserted.[MediaHTML]
					,inserted.[CreatedBy]
					,inserted.[CreatedDateUTC]
					,inserted.[ModifiedBy]
					,inserted.[ModifiedDateUTC]
			;	-- Merge EventURL

		-- Update event "modified*" fields
		UPDATE [dbo].[Event] SET
				[ModifiedDateUTC] = GETUTCDATE()
				,[ModifiedBy] = @UserName
			WHERE [PK_Event] = @PK_Event;
	
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

END;
GO

