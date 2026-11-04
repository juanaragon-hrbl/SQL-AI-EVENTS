CREATE PROCEDURE [dbo].[usp_EventsAT_Save_PMPromoEventURL]
	-- Required
	@PK_Event					int
	,@LocaleCode				varchar(5)

	-- Optional
	,@PK_EventURL				int = NULL
	,@EventURL					varchar(max) = NULL
	,@EventURLDesc				nvarchar(max) = NULL     -- Type change 
	,@Flyer						varchar(max) = NULL
	,@PK_EventURLType			int = 1
	,@UserName					varchar(255) = NULL
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS

BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Save_PMPromoEventURL

	USE:			
					DECLARE @e int, @em varchar(4000)
					EXEC dbo.usp_EventsAT_Save_PMPromoEventURL
							@PK_Event = 48019
							,@LocaleCode = 'en-PF'

							-- Optional
							,@PK_EventURL = NULL
							,@EventURL = 'http://URLdePK_Event'
							,@EventURLDesc = NULL
							,@Flyer = NULL
							,@PK_EventURLType = NULL

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
	2.0.1		2019-10-17		alejandramed	SRE Compliance 
	2.0.2		2020-06-17		Ivanci			Change @EventURLDesc type to nvarchar for special characters
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '', @UserName = ISNULL(@UserName, (REPLACE(SUSER_SNAME(),'HERBALIFECORP\','')));

	BEGIN TRY
		MERGE dbo.EventURL AS t
			USING (SELECT
						@PK_EventURL AS PK_EventURL
						,@PK_Event AS PK_Event
						,(SELECT PK_Locale FROM Locales WITH(NOLOCK) WHERE LocaleCode = @LocaleCode) AS PK_Locale
						,@EventURL AS EventURL
						,@EventURLDesc AS EventURLDesc
						,@Flyer AS Flyer
						,GETUTCDATE() AS CreatedDateUTC
						,@UserName AS CreatedBy
						,GETUTCDATE() AS ModifiedDateUTC
						,@UserName AS ModifiedBy
						,@PK_EventURLType AS PK_EventURLType
				) AS s
				ON (t.PK_EventURL = s.PK_EventURL)
			WHEN MATCHED THEN
				UPDATE SET
					[PK_Event] = s.PK_Event
					,[PK_Locale] = s.PK_Locale
					,[EventURL] = s.EventURL
					,[EventURLDesc] = s.EventURLDesc
					,[Flyer] = s.Flyer
					,[ModifiedDateUTC] = s.ModifiedDateUTC
					,[ModifiedBy] = s.ModifiedBy
					,[PK_EventURLType] = s.PK_EventURLType
			WHEN NOT MATCHED THEN
				INSERT(
					[PK_Event]
					,[PK_Locale]
					,[EventURL]
					,[EventURLDesc]
					,[Flyer]
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
					,s.[Flyer]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
					,s.[PK_EventURLType]
				)
			OUTPUT $action, inserted.[PK_Event]
					,inserted.[PK_Locale]
					,inserted.[EventURL]
					,inserted.[EventURLDesc]
					,inserted.[Flyer]
					,inserted.[CreatedDateUTC]
					,inserted.[CreatedBy]
					,inserted.[ModifiedDateUTC]
					,inserted.[ModifiedBy]
					,inserted.[PK_EventURLType]
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
	END CATCH
END;
