CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventItemFulfillmentCountryStates]
 -- Mandatory
    @PK_Event INT
 -- Optional
 	,@PK_MarketType INT = NULL

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Get_EventItemFulfillmentCountryStates

USE:
			DECLARE @e int, @em varchar(4000)

             EXEC dbo.usp_MyHLEventAPI_Get_EventItemFulfillmentCountryStates
					@PK_Event = 1217
				 -- Optional
					,@PK_MarketType = 1
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
1	2012-09-29	SandhyaP 		Initial
2	2019-08-14	NoeG			Refactor code (SRE)
3   2019-10-17	alejandramed	SRE Compliance 

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	/******************************************************************************
	 Get the Region_Country list based on the User Access
	******************************************************************************/

	IF OBJECT_ID('tempdb..#EventMarketLocation') IS NOT NULL DROP TABLE #EventMarketLocation
	CREATE TABLE #EventMarketLocation
	(
		PK INT IDENTITY(1,1)
		,PK_EventMarketLocation INT
		,CountryCodeISO VARCHAR(2)
		,PK_Country INT
		,CountryName VARCHAR(100)
		,State NVARCHAR(120)
		,City NVARCHAR(120)
		,Location NVARCHAR(60)
		,StartDate SMALLDATETIME
		,EndDate SMALLDATETIME
	)

	INSERT INTO #EventMarketLocation (PK_EventMarketLocation, CountryCodeISO, PK_Country, CountryName, State, City, Location, StartDate, EndDate)
	SELECT
		 EML.PK_EventMarketLocation
		,EML.CountryCodeISO
		,C.PK_Country
		,C.CountryName 
		,EML.State
		,EML.City
		,EML.Location
		,EML.StartDate
		,EML.EndDate
	FROM
		dbo.EventMarketLocation EML WITH (NOLOCK)
	INNER JOIN
		PubEvents.dbo.dimCountry C WITH (NOLOCK)
	ON
		EML.CountryCodeISO = C.CountryCodeISO
	WHERE
		EML.PK_EventMarketType = COALESCE(@PK_MarketType, EML.PK_EventMarketType)
	AND
	EML.PK_Event = @PK_Event
	AND
	EML.IsActive = 1
		
	--to get the distinct list of states
	SELECT	DISTINCT 
	 E.CountryCodeISO
	,E.PK_Country
	,E.CountryName
	,E.State
	FROM 
		#EventMarketLocation E
	ORDER BY
		E.CountryCodeISO, E.State
		
	SELECT
		 E.PK_EventMarketLocation
		,E.CountryCodeISO
		,E.PK_Country
		,E.CountryName
		,E.State
		,CASE WHEN COALESCE(E.Location, '') = '' THEN  E.City + ', ' + E.State + ' ' + 
		CASE WHEN StartDate IS NOT NULL THEN SUBSTRING(CONVERT(VARCHAR(7),StartDate, 113), 4, 3)  + ' ' 
		+ CASE WHEN StartDate = EndDate THEN CONVERT(VARCHAR(2), DATEPART(DD, EndDate)) 
			ELSE CONVERT(VARCHAR(2), DATEPART(DD, StartDate)) + ' - ' + SUBSTRING(CONVERT(VARCHAR(7),EndDate, 113), 4, 3)  + ' ' + CONVERT(VARCHAR(2), DATEPART(DD, EndDate)) END ELSE '' END
		ELSE E.City + ', ' + E.State + ' - ' + E.Location + ' ' + CASE WHEN StartDate IS NOT NULL THEN SUBSTRING(CONVERT(VARCHAR(7),StartDate, 113), 4, 3)  + ' ' 
		+ CASE WHEN StartDate = EndDate THEN CONVERT(VARCHAR(2), DATEPART(DD, EndDate)) 
			ELSE CONVERT(VARCHAR(2), DATEPART(DD, StartDate)) + ' - ' + SUBSTRING(CONVERT(VARCHAR(7),EndDate, 113), 4, 3)  + ' ' + CONVERT(VARCHAR(2), DATEPART(DD, EndDate)) END ELSE '' END END [Event]	
	FROM	
		#EventMarketLocation E
	ORDER BY
		2, 5, 6

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime
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

SET NOCOUNT OFF

END
GO

