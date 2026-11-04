CREATE PROCEDURE [dbo].[usp_EventsAT_Get_PMPromoRegionCountryLocale]
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

	OBJECT:			dbo.usp_EventsAT_Get_PMPromoRegionCountryLocale

	USE:			
					DECLARE @e int, @em varchar(4000);

					EXEC dbo.usp_EventsAT_Get_PMPromoRegionCountryLocale
						@UserID = NULL	
						,@RegionID = null
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */					
						,@IsDevQA = 1

					SELECT @e, @em;

	DESCRIPTION:	Get the Region - Country Dropdown based on the User Access Level in locales with bifurcation

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Locales, dbo.

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-08		RogelioR		Initial
	1.1.0		2018-07-25		RogelioR		Added functionality to grant distributor access according to [CountryPM]
	2.0.0		2019-08-08		NoeG			Refactor code (SRE)
	3.0.0		2020-04-27		Noeg			Changes added for features management

******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		SELECT 
				@StoredProcedure = 'usp_EventsAT_Get_PMPromoRegionCountryLocale'
				,@StartTime = GETUTCDATE()
				,@Error = 0
				,@ErrorMessage = 'No Error.'

		IF OBJECT_ID('tempdb.dbo.#Locales') IS NOT NULL
			DROP TABLE #Locales;

		CREATE TABLE #Locales (
			PK_Region				int
			,RegionName				varchar(255)
			,LanguageCountryRegion	nvarchar(255)
			,PK_Locale				int
			,LocaleCode				varchar(255)
		)
		INSERT INTO #Locales
		EXEC usp_EventsAT_Get_RegionCountryLocale
				@UserID = @UserID
				,@RegionID = null
				,@Error = @Error OUTPUT  /* @e must be defined in the local call */
				,@ErrorMessage = @ErrorMessage OUTPUT /* @em must be defined in the local call */

		SELECT	l.PK_Region
				,l.RegionName
				,l.LanguageCountryRegion
				,l.PK_Locale
				,l.LocaleCode
				,ISNULL(c.[AllowPmPromos],0) HasDSAccess
		FROM	#Locales AS l
				INNER JOIN v_CountryLocale AS cl 
					ON l.LocaleCode = cl.sLocaleCode
				INNER JOIN [CountryPM] AS c WITH (NOLOCK) 
					ON c.[PK_Country] = cl.[nCountryID]
		--WHERE	c.AllowPmPromos = 1
	
		-- Update processing Log
		EXEC dbo.usp_Utility_UpdateProcessingLog 
			@StoredProcedureName = @StoredProcedure
			,@StartTime = @StartTime

		SET NOCOUNT OFF
		-- DEPLOY

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

END
GO
