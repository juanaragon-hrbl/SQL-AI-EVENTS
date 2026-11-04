CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventAvailableLocales]
		 @PK_Event INT
		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_EventAvailableLocales

USE:	        
			Declare @e int, @em varchar(4000)
			EXEC dbo.usp_MyHLEventAPI_Get_EventAvailableLocales
				@PK_Event = 23560
				,@Error = @e OUTPUT  /* @e must be defined in the local call */
				,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
				,@IsDevQA = 0
			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves all available locales for the passed PK_Event

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.EventLocaleADesc

VERSIONS
----------------------------------------------------------------------------------
1.0.1		2011-01-04		Prabhu		Intitial
1.0.2		2013-04-20  	Juan		Not display for deleted events
1.0.3		2019-08-14		NoeG		Refactor code (SRE)
1.0.4		2019-09-17		NoeG		Add Master Locales information
1.0.5 		2020-10-06		puertac		US 33768 : Languages & Locales in the eventsadmin tool should be aligned with myHL (Locales cleanup)
1.0.6		2021-10-05		ivanci		US 793980 - Self Organized events - Request Access Page - Enable/Disable feature 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
            ,@IsLanguageGrouped bit = 0
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		/*Hide Deleted Events*/
		IF EXISTS (SELECT 1 FROM dbo.EventDeleteQueue WITH (NOLOCK) WHERE PK_Event = @PK_Event)
		BEGIN
			RETURN
		END

        SELECT @IsLanguageGrouped = IsLanguageGrouped FROM EventExtn WITH (NOLOCK) WHERE PK_Event = @PK_Event

		/* SELECT THE DISTINCT LOCALES FOR PASSED PK_EVENT */
		SELECT
			DISTINCT
			 ED.PK_Locale
			,L.LocaleCode
			,L.LanguageCountryRegion
			,LE.PK_MasterLocale
			,LE.IsMasterLocale
			,LE.MasterLanguageCountryRegion 
			,LE.MasterLocaleCode
			,LE.MasterLocaleLanguage 
            ,CASE WHEN ED.PK_Locale = ED.PK_DefaultLocale THEN 1 ELSE 0 END AS [IsDefault]
            ,@IsLanguageGrouped AS [IsLanguageGrouped]
		FROM
			dbo.EventLocaleDesc ED WITH (NOLOCK)
		INNER JOIN
			dbo.Locales L WITH (NOLOCK)
		ON
			ED.PK_Locale = L.PK_Locale
		LEFT JOIN 
			(	SELECT 	LE.PK_Locale, LE.PK_MasterLocale, LE.MasterLocaleLanguage, LE.IsMasterlocale, ML.LanguageCountryRegion MasterLanguageCountryRegion, ML.LocaleCode MasterLocaleCode
				FROM	LocalesExtn LE WITH (NOLOCK)
						inner join Locales ML WITH (NOLOCK)
							ON LE.PK_MasterLocale = ML.PK_Locale
			) LE
			ON L.PK_Locale = LE.PK_Locale
		WHERE
			ED.PK_Event = @PK_Event

		/* SELECT THE LOCALES FOR EVENT TO BE COPIED */
		SELECT
			 L.LocaleCode
			,L.LanguageCountryRegion
			,C.sRegionCode As RegionCode
			,C.sRegionLabel As RegionName
			,LE.PK_MasterLocale
			,LE.IsMasterLocale
			,LE.MasterLanguageCountryRegion 
			,LE.MasterLocaleCode
			,LE.MasterLocaleLanguage 
		FROM dbo.Locales L WITH (NOLOCK)
		LEFT JOIN 
			(	SELECT 	LE.PK_Locale, LE.PK_MasterLocale, LE.MasterLocaleLanguage, LE.IsMasterlocale, ML.LanguageCountryRegion MasterLanguageCountryRegion, ML.LocaleCode MasterLocaleCode
				FROM	LocalesExtn LE WITH (NOLOCK)
						inner join Locales ML WITH (NOLOCK)
							ON LE.PK_MasterLocale = ML.PK_Locale
			) LE
			ON L.PK_Locale = LE.PK_Locale
		INNER JOIN dbo.v_Countries C
			ON SUBSTRING(L.LocaleCode, CHARINDEX('-', L.LocaleCode)+1, 2) = C.sCountryCodeISO
	/* ***************** SonarQube check 38 - Nullable subqueries should not be used in "NOT IN" conditions */
		WHERE L.PK_Locale NOT IN(SELECT DISTINCT PK_Locale FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event and PK_Locale IS NOT NULL)
		AND	C.sRegionLabel IS NOT NULL
		AND  L.EnabledOnMyHL = 1						-- 33768 : Return only Locales aligned with myHL	
	/* ***************** SonarQube check 38 */
		ORDER BY L.LanguageCountryRegion

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


/******************************************************************************
	END PROCEDURE
******************************************************************************/
END