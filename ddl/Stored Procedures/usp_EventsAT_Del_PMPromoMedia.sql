
CREATE PROCEDURE [dbo].[usp_EventsAT_Del_PMPromoMedia]
	-- Required
	@PK_Event					int = null

	-- Optional
	,@LocaleCode				varchar(5) = null
	,@PK_EventMedia				int = null
	,@PK_MediaType				int = null

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS

BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Del_PMPromoMedia

	USE:			
					DECLARE @e int, @em varchar(4000);

					EXEC dbo.usp_EventsAT_Del_PMPromoMedia
							@PK_Event = 777795
							,@LocaleCode = null
							,@PK_EventMedia = 3
							,@PK_MediaType = null

							-- Errors
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

					SELECT @e, @em;
					select <all> from EventMedia
	DESCRIPTION:	Deletes a record in EventURL
	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.EventURL

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-06		RogelioR		Initial
	1.0.1		2019-08-15		NoeG			Refactor code (SRE)
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	DECLARE @PK_Locale int = (SELECT PK_Locale FROM Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode);

	BEGIN TRY

		DELETE FROM dbo.EventMedia
			OUTPUT deleted.[PK_EventMedia], deleted.[PK_Event], deleted.[PK_MediaType], deleted.[PK_Locale], deleted.[MediaName], 
			       deleted.[MediaDesc], deleted.[MediaHTML], deleted.[CreatedBy], deleted.[CreatedDateUTC], deleted.[ModifiedBy], deleted.[ModifiedDateUTC]
			WHERE PK_Event = @PK_Event
				AND (PK_EventMedia = @PK_EventMedia OR ISNULL(@PK_EventMedia, 0) = 0)
				AND (PK_MediaType = @PK_MediaType OR ISNULL(@PK_MediaType, 0) = 0)
				AND (PK_Locale = @PK_Locale OR ISNULL(@LocaleCode, '') = '')
			;

		--IF @@ROWCOUNT = 0
		--BEGIN
		--	RAISERROR('The media does not exists', 11, 1);
		--END;

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

