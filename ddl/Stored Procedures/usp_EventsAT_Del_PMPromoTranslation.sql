CREATE PROCEDURE [dbo].[usp_EventsAT_Del_PMPromoTranslation]
	-- REQUIRED
	@PK_Event		int
	,@LocaleCode		nvarchar(5)

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS

BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Del_PMPromoTranslation

	USE:			
					DECLARE @e int, @em varchar(4000)

					EXEC dbo.usp_EventsAT_Del_PMPromoTranslation
							@PK_Event = 48019
							,@LocaleCode = 'en-PF'
							
							-- Errors
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	Delete a translation in a preferred member promotion
	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.EventLocaleDesc, dbo.EventImage, dbo.EventImageLocaleDesc, dbo.EventURL

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-04		RogelioR		Initial
	1.0.1		2019-08-15		NoeG			Refactor code (SRE)
	1.0.2		2019-10-15		alejandramed	SRE Compliance 
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@PK_Locale	varchar(5) = (SELECT TOP 1 PK_Locale FROM Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode)
			,@PK_DefaultLocale int = (SELECT TOP 1 PK_DefaultLocale FROM Event WITH (NOLOCK) WHERE PK_Event = @PK_Event);

	BEGIN TRY
		IF (@PK_Locale = @PK_DefaultLocale)
		BEGIN
			RAISERROR('The default language can not be deleted.', 11, 1);
			SELECT 0 AS PK_Event;
		END

		BEGIN TRANSACTION
			DELETE FROM [dbo].[EventLocaleDesc] WHERE [PK_Event] = @PK_Event AND [PK_Locale] = @PK_Locale;

			DELETE FROM	[dbo].[EventImageLocaleDesc] WHERE [PK_Event] = @PK_Event AND [PK_Locale] = @PK_Locale;
			
			DELETE FROM [dbo].[EventURL] WHERE [PK_Event] = @PK_Event AND [PK_Locale] = @PK_Locale;
			
			DELETE FROM [dbo].[EventMedia] WHERE [PK_Event] = @PK_Event AND [PK_Locale] = @PK_Locale;
		COMMIT TRANSACTION

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

	END TRY
	
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

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
GO

