CREATE PROCEDURE [dbo].[usp_EventsAT_Get_PMPromoTranslationList]
	-- Required
	@PK_Event			int

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Get_PMPromoTranslationList

	USE:			
					DECLARE @e int, @em varchar(4000);

					EXEC dbo.usp_EventsAT_Get_PMPromoTranslationList
							@PK_Event = 48018
							
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

					SELECT @e AS Error, @em AS ErrorMessage

	DESCRIPTION:	Get the list of the promotion translations

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event, dbo.EventLocaleDesc, dbo.Locales

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-06		RogelioR		Initial
	2.0.0		2019-08-08		NoeG			Refactor code (SRE)
	2.0.1		2022-06-20		puertac			US 1050464: Remove Errorlog when PK_event has been deleted
******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';
			
	BEGIN TRY
		-----------------------------------------------------------------------------------------------------------------------
		-- List of promotion translations
		SELECT
				e.PK_Event
				,eld.PK_Locale
				,l.LocaleCode
				,l.LanguageCountryRegion
			FROM Event AS e WITH (NOLOCK)
				INNER JOIN EventLocaleDesc AS eld WITH (NOLOCK) ON eld.PK_Event = e.PK_Event
				INNER JOIN Locales AS l WITH (NOLOCK) ON l.PK_Locale = eld.PK_Locale
			WHERE e.PK_Event = @PK_Event;


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

