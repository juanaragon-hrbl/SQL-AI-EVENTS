CREATE PROCEDURE [dbo].[usp_EventsAT_Get_RegionCountryLocale]
	-- Optional
	@UserID nVARCHAR(30) = NULL   /**** For Events Staff Admin Tool, UserID is mandatory to be passed to get the locales based on user credentials */ 
	,@RegionID INT = NULL

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventsAT_Get_RegionCountryLocale

USE:
			DECLARE @e int, @em varchar(4000)

             EXEC usp_EventsAT_Get_RegionCountryLocale
					 @UserID = NULL
                    ,@RegionID = null
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Get the Region - Country Dropdown based on the User Access Level

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	 2012-09-29	  SandhyaP 		  Initial
1.1  2013-07-29	  SandhyaP		  @UserID is changed to be nullable parameter
1.2  2019-07-15	  alejandramed	  Setting error parameters as optionals
1.3  2019-10-17	  alejandramed	  SRE Compliance 
1.4  2020-09-28	  puertac		  US 33768 : Languages & Locales in the eventsadmin tool should be aligned with myHL (Locales cleanup)
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	/******************************************************************************
	 Check if the UserID passed exists
	******************************************************************************/

	IF NOT EXISTS(SELECT TOP 1 PK_EventATAccessUser FROM dbo.EventATAccessUser WITH (NOLOCK)
				WHERE EventATAccessUserName = @UserID) AND @UserID IS NOT NULL
	BEGIN
		SET @Error = 280
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END


	/******************************************************************************
	 Get the Region_Country list based on the User Access
	******************************************************************************/

	IF @UserID IS NULL
	BEGIN 

		SELECT DISTINCT
				XREF.PK_Region,
				R.RegionName,
				L.LanguageCountryRegion, 
				L.PK_Locale, 
				L.LocaleCode 
		FROM dbo.Locales L WITH (NOLOCK)			
		INNER JOIN	dbo.v_Countries C	  
			ON 	SUBSTRING(L.LocaleCode, CHARINDEX('-', L.LocaleCode)+1, 2) = C.sCountryCodeISO   
		LEFT JOIN	PubEvents.dbo.dimCountry DC WITH (NOLOCK)	
			ON	SUBSTRING(L.LocaleCode,CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = DC.CountryCodeISO 	   
		LEFT JOIN PubEvents.dbo.dimCountryRegion_XREF XREF WITH (NOLOCK)
			ON XREF.PK_Country = DC.PK_Country 
		LEFT JOIN PubEvents.dbo.dimRegion R WITH (NOLOCK)
			ON R.PK_Region = XREF.PK_Region 
		LEFT JOIN PubEvents.dbo.dimRegionClass RC WITH (NOLOCK)
			ON R.PK_RegionClass = RC.PK_RegionClass 
	    WHERE RC.RegionClassCode = 'CORP'	   
		AND	XREF.ThroughDate = '2049-12-31'	
		AND L.EnabledOnMyHL = 1						-- 33768 : Return only Locales aligned with myHL		
		ORDER BY R.RegionName, L.LanguageCountryRegion

	END
	ELSE
	BEGIN

			SELECT  DISTINCT
				XREF.PK_Region,
				R.RegionName,
				L.LanguageCountryRegion, 
				AT.PK_Locale, 
				L.LocaleCode 
			FROM dbo.EventATAccessUserModules AT WITH (NOLOCK)
			INNER JOIN	dbo.EventATAccessUser ATU WITH (NOLOCK)
				ON	AT.PK_EventATAccessUser = ATU.PK_EventATAccessUser 
			INNER JOIN	dbo.Locales L WITH (NOLOCK)
				ON	AT.PK_Locale = L.PK_Locale 
			--INNER JOIN InternetCommon.dbo.CountryLocale CL (NOLOCK)
			--	ON CL.LocaleCode = L.LocaleCode 
			INNER JOIN PubEvents.dbo.dimCountry C WITH (NOLOCK)
				ON	SUBSTRING(L.LocaleCode,CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = C.CountryCodeISO 
			INNER JOIN	PubEvents.dbo.dimCountryRegion_XREF XREF WITH (NOLOCK)
				ON	XREF.PK_Country = C.PK_Country 
			INNER JOIN PubEvents.dbo.dimRegion R WITH (NOLOCK) 
				ON	R.PK_Region = XREF.PK_Region 
			INNER JOIN PubEvents.dbo.dimRegionClass RC WITH (NOLOCK)
				ON	R.PK_RegionClass = RC.PK_RegionClass 
			WHERE RC.RegionClassCode = 'CORP'
			AND XREF.ThroughDate = '2049-12-31'
			AND ATU.EventATAccessUserName = @UserID
			AND R.PK_Region = COALESCE(@RegionID, R.PK_Region)
			AND L.EnabledOnMyHL = 1						-- 33768 : Return only Locales aligned with myHL
			ORDER BY R.RegionName, L.LanguageCountryRegion

	END

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime

	SET NOCOUNT OFF

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
END