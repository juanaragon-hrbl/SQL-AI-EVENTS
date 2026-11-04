
CREATE PROCEDURE [dbo].[usp_EventsAT_Del_PMPromoEventURL]
	-- Required
	@PK_Event					int

	-- Optional
	,@LocaleCode				varchar(5) = null
	,@PK_EventURL				int = null
	,@PK_EventURLType			int = 11

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS

BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Del_PMPromoEventURL

	USE:			
					DECLARE @e int, @em varchar(4000);

					EXEC dbo.usp_EventsAT_Del_PMPromoEventURL
							@PK_Event = 777795
							,@LocaleCode = null
							,@PK_EventURL = null
							,@PK_EventURLType = 11

							-- Errors
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

					SELECT @e, @em;
					
	DESCRIPTION:	Deletes a record in EventURL
	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.EventURL

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-03		RogelioR		Initial
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
		DELETE FROM dbo.EventURL 
			OUTPUT deleted.[PK_EventURL], deleted.[PK_Event], deleted.[PK_Locale], deleted.[EventURL], deleted.[EventURLDesc], deleted.[Flyer], deleted.[CreatedDateUTC], deleted.[CreatedBy], deleted.[ModifiedDateUTC], deleted.[ModifiedBy], deleted.[PK_EventURLType]
			WHERE PK_Event = @PK_Event
				AND PK_EventURLType = @PK_EventURLType
				AND (PK_EventURL = @PK_EventURL OR ISNULL(@PK_EventURL, 0) = 0)
				AND (PK_Locale = @PK_Locale OR ISNULL(@LocaleCode, '') = '')
		--IF @@ROWCOUNT = 0
		--BEGIN
		--	RAISERROR('The link does not exists', 11, 1);
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

