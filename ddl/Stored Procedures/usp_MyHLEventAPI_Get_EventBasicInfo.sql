CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventBasicInfo]

		@PK_Event int
		,@Locale VARCHAR(5)

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_MyHLEventAPI_Get_EventBasicInfo]
	
	USE:			
			DECLARE @e int, @em varchar(max)

			EXEC [dbo].[usp_MyHLEventAPI_Get_EventBasicInfo]
				@PK_Event = 78108 
				,@Locale = 'en-US'
				,@Error = @e OUTPUT
				,@ErrorMessage = @em OUTPUT
				,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [ErrorMessage]

	DESCRIPTION: Get basic information for an Event 

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2020-03-04		NoeG			Initial
	1.0.1		2021-08-25		Ivanci			T 764371 - 21124 - Méx PC Inc Promo 2021 - Implement logic for PM, they should be able to see TYP Incremental tracker
	1.0.2		2022-04-18		puertac			US 1003446 : Adding HasAutomatedQuals flag     + TemplateType fix
******************************************************************************/																			   
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	DECLARE @PK_Locale INT,
			@StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@DisplayPDFType int = 12;

	SELECT @Error = 0, @ErrorMessage = '';

	SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH(NOLOCK) WHERE LocaleCode = @Locale;

	BEGIN TRY
					
		SELECT	ev.[PK_Event]
				, ISNULL(evx.IsUmbracoHosted,0) IsUmbracoHosted
				, ev.IsPublish
				, ev.MakePublic
				, ev.PK_EventType
				, L.LocaleCode as [DefaultLocale]
				, ISNULL(IIF(evpt.PK_EventPromoTemplateType IS NOT NULL, evpt.PK_EventPromoTemplateType , S.EventPromoTemplateID ),0) AS PK_EventPromoTemplateType		-- 1.0.2
				, ISNULL(evx.PK_DefaultMasterLocale,0) AS PK_DefaultMasterLocale
				, ISNULL(evx.IsLanguageGrouped,0) as [IsLanguageGrouped]
				, ML.LocaleCode MasterLocaleCode
				, ISNULL(evx.[IsDisplayPDF], 0) AS [IsDisplayPDF]
				,coalesce(eu.EventURL, dpdf.EventURL) [DisplayPDFLocation]
                ,op.[Value] AS [AllowPmDocker]								-- T 764371
				,CAST(IIF(S.PK_Event IS NOT NULL , 1, 0) AS BIT) AS HasAutomatedQuals	-- US 1003446
		FROM	[dbo].[Event] AS ev WITH (NOLOCK)
		INNER JOIN dbo.Locales L WITH (NOLOCK)    
			on ev.PK_DefaultLocale = L.PK_Locale 
		LEFT JOIN [dbo].[EventExtn] as evx WITH (NOLOCK)
			on ev.[PK_Event] = evx.[PK_Event]
		LEFT JOIN [dbo].[EventPromoTemplate] evpt WITH (NOLOCK)
			on ev.[PK_Event] = evpt.[PK_Event]
		LEFT JOIN Locales ML WITH (NOLOCK)
			ON evx.PK_DefaultMasterLocale = ML.PK_Locale
		LEFT JOIN [EventURL] AS eu WITH (NOLOCK) 
			ON eu.[PK_Event] = ev.[PK_Event]
			AND eu.[PK_EventURLType] = @DisplayPDFType
			AND eu.[PK_Locale] = @PK_Locale
		LEFT JOIN [EventURL] AS dpdf WITH (NOLOCK) 
			ON dpdf.[PK_Event] = ev.[PK_Event]
			AND dpdf.[PK_EventURLType] = @DisplayPDFType
			AND dpdf.[PK_Locale] = ev.[PK_DefaultLocale]
		LEFT JOIN [Promo].[Options] as op WITH (NOLOCK)						-- T 764371
			ON op.PK_Event = ev.PK_Event AND op.[Key] = 'AllowPMDocker'
		LEFT JOIN [eventpromo].[Settings] S WITH (NOLOCK)					-- US 1003446
			ON ev.PK_Event = S.PK_Event
		WHERE ev.[PK_Event] = @PK_Event;

		SELECT	ML.LocaleCode MasterLocaleCode, L.LocaleCode
		FROM    dbo.Locales L WITH (NOLOCK)     
				LEFT JOIN LocalesExtn LE WITH (NOLOCK)
					ON L.PK_Locale = LE.PK_Locale
				LEFT JOIN Locales ML WITH (NOLOCK)
					ON LE.PK_MasterLocale = ML.PK_Locale
				INNER JOIN dbo.EventLocaleDesc ED WITH (NOLOCK)    
					ON ED.PK_Locale = L.PK_Locale    
		WHERE	ED.PK_Event = @PK_Event    
			
		
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
	END CATCH;
END;