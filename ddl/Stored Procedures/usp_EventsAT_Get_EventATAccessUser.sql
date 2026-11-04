CREATE PROCEDURE [dbo].[usp_EventsAT_Get_EventATAccessUser]	
	-- MANDATORY
	 @LoggedUser nVARCHAR(30)        /* Logged User */
	-- OPTIONAL
	,@UserID nVARCHAR(30) = NULL     /* Pass the UserID for search */
	,@Locale nVARCHAR(200) = NULL    /* Pass the Locale(Market) values  for search */
	,@FirstName nVARCHAR(50) = NULL
	,@LastName nVARCHAR(50) = NULL
	,@Country nVARCHAR(50) = NULL

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN


/*
OBJECT:			dbo.usp_EventsAT_Get_EventATAccessUser

USE:		
			DECLARE @e int, @em varchar(4000)
			EXEC usp_EventsAT_Get_EventATAccessUser
			         @LoggedUser = N'muralip'
					,@UserID  = 'kulsumr'
					,@Locale =  N''				
					,@FirstName = ''
					,@LastName = ''
					,@Country = '' 
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
	                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves record from dbo.EventATAccessUser

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventATAccessUser

VERSIONS
--------------------------------------------------------------------
1	2012-08-07	OrlandoL		Initial
2	2019-08-08	OrlandoL		Refactor code (SRE)
3	2019-10-15	alejandramed	SRE Compliance 
*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

SET @LoggedUser = LTRIM(RTRIM(@LoggedUser))
SET @UserID = LTRIM(RTRIM(@UserID))

/**************************************************************************************
 Verify if the LoggedUser is a valid User
****************************************************************************************/

IF NOT EXISTS (SELECT PK_EventATAccessUser FROM dbo.EventATAccessUser ET WITH (NOLOCK) WHERE EventATAccessUserName = @LoggedUser)
BEGIN
		SET @Error = 280
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END
	
/**************************************************************************************
 Staff User cannot access Staff Access Page. Verify LoggedUser is not a HL staff 
****************************************************************************************/

IF (SELECT PK_EventATAccessUserType FROM dbo.EventATAccessUser ET WITH (NOLOCK) WHERE EventATAccessUserName = @LoggedUser) = 3
BEGIN
		SET @Error = 278
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END
			
	
/**************************************************************************************
Make sure if the LoggedUser has visibility to same access level or below
****************************************************************************************/

DECLARE @LoggedUserType INT
DECLARE @UserIDType INT

SELECT @LoggedUserType = PK_EventATAccessUserType FROM dbo.EventATAccessUser ET WITH (NOLOCK) WHERE EventATAccessUserName = @LoggedUser
SELECT @UserIDType = PK_EventATAccessUserType FROM dbo.EventATAccessUser ET WITH (NOLOCK) WHERE EventATAccessUserName = @UserID

IF @LoggedUserType > @UserIDType
BEGIN
		SET @Error = 281
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END	
	

/**************************************************************
 Declare a table to get the loggeduser access level 
***************************************************************/


DECLARE @LoggedUserAuthority TABLE
(
	PK INT IDENTITY(1,1)
	,PK_EventATAccessUserType INT
)


;WITH UserAuthority (PK_EventATAccessUserType)
 AS (SELECT 
		PK_EventATAccessUserType
    FROM
		dbo.EventATAccessUser WITH (NOLOCK)
	WHERE
		EventATAccessUserName = @LoggedUser)
INSERT @LoggedUserAuthority 
(
	PK_EventATAccessUserType
)
SELECT
	PK_EventATAccessUserType
FROM
	UserAuthority WITH (NOLOCK)

/*****************************************************************
 Declare a table to get the loggeduser assigned locales 
******************************************************************/	

DECLARE @LoggedUserAccess TABLE
(
	PK_EventATAccessUser INT
	,PK_Locale INT
)	
	
INSERT @LoggedUserAccess
(
	PK_EventATAccessUser
	,PK_Locale
)				
SELECT DISTINCT
	EU.PK_EventATAccessUser, EUM.PK_Locale
FROM	
	dbo.EventATAccessUser EU WITH (NOLOCK)
INNER JOIN
	dbo.EventATAccessUserModules EUM	WITH (NOLOCK)
	ON
		EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
WHERE
	EventATAccessUserName = @LoggedUser		
	

/******************************************************************************
 Declare a table to parse the locale string into seperate entries
******************************************************************************/	

DECLARE @tbl TABLE
(
	PK INT IDENTITY(1,1)
	,PK_Locale INT
	,LocaleCode varchar(10)
)
DECLARE @pos INT
DECLARE @piece VARCHAR(4000)
DECLARE @PK_Locale INT

SET @pos =  PATINDEX('%,%' , @Locale)
WHILE @pos <> 0
BEGIN
SET @piece = LEFT(@Locale,@pos-1)

SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @piece

INSERT
	@tbl
(
	PK_Locale
	,LocaleCode
)
SELECT
	@PK_Locale
	,@piece

SET @Locale = STUFF(@Locale, 1, @pos, '')
SET @pos =  PATINDEX('%,%' , @Locale)

END


/**************************************************************************************
 IF A SPECIFIC USERID IS SELECTED, GET THE USER ACCESS BASED ON THEIR ACCESS LEVEL
****************************************************************************************/


IF @UserID <> '' AND @LoggedUserType <> 3


BEGIN TRY


/**************************************************************************************
 Verify if the UserID is a valid User
****************************************************************************************/	
	
IF NOT EXISTS(SELECT TOP 1 PK_EventATAccessUser FROM dbo.EventATAccessUser WITH (NOLOCK)
			WHERE EventATAccessUserName = @UserID)
BEGIN
	SET @Error = 280
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END	
			
		SELECT DISTINCT
			 AU.PK_EventATAccessUser
			,COALESCE(AU.EventATAccessUserName, @UserID) AS UserID
			,COALESCE(AU.EventATAccessUserFirstName, @FirstName) AS FirstName
			,COALESCE(AU.EventATAccessUserLastName, @LastName) AS LastName
			,COALESCE(AU.EventATAccessUserCountry, @Country) AS Country	
			,AU.EventATAccessUserEmailAddress
		FROM 
			dbo.EventATAccessUser AU WITH (NOLOCK)
		INNER JOIN
			dbo.EventATAccessUserTypes AUT WITH (NOLOCK)	
			ON
				AU.PK_EventATAccessUserType = AUT.PK_EventATAccessUserType								
		INNER JOIN
			dbo.EventATAccessUserModules AUM WITH (NOLOCK)
			ON
				AUM.PK_EventATAccessUser = AU.PK_EventATAccessUser
		INNER JOIN
			@LoggedUserAccess UA
			ON
				AUM.PK_Locale = UA.PK_Locale						
		WHERE
				AU.EventATAccessUserName = @UserID
				AND
				AU.PK_EventATAccessUserType >= (SELECT PK_EventATAccessUserType FROM @LoggedUserAuthority)
				
		SELECT DISTINCT
			AUM.PK_EventATAccessUserModule
			,AUM.PK_EventATAccessUser
			,AUM.PK_Locale	
		    ,L.LocaleCode
		    ,L.LanguageCountryRegion
			,XREF.PK_Region
			,R.RegionName
		FROM
			dbo.EventATAccessUser AU WITH (NOLOCK)
		INNER JOIN
			dbo.EventATAccessUserTypes AUT WITH (NOLOCK)
			ON
				AU.PK_EventATAccessUserType = AUT.PK_EventATAccessUserType	
		INNER JOIN
			dbo.EventATAccessUserModules AUM WITH (NOLOCK)
			ON
				AUM.PK_EventATAccessUser = AU.PK_EventATAccessUser
		INNER JOIN
			@LoggedUserAccess UA
			ON
				AUM.PK_Locale = UA.PK_Locale				
		INNER JOIN
			dbo.Locales L	 WITH (NOLOCK)
			ON
				AUM.PK_Locale = L.PK_Locale
		--LEFT JOIN
		--	InternetCommon.dbo.CountryLocale CL (NOLOCK)
		--ON
		--	CL.LocaleCode = L.LocaleCode 
		LEFT JOIN
			PubEvents.dbo.dimCountry C WITH (NOLOCK)
		ON
			SUBSTRING(L.LocaleCode,CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = C.CountryCodeISO 
		LEFT JOIN
			PubEvents.dbo.dimCountryRegion_XREF XREF WITH (NOLOCK)
		ON
			XREF.PK_Country = C.PK_Country 
		LEFT JOIN
			PubEvents.dbo.dimRegion R WITH (NOLOCK) 
		ON
			R.PK_Region = XREF.PK_Region 
		LEFT JOIN
			PubEvents.dbo.dimRegionClass RC WITH (NOLOCK)
		ON
			R.PK_RegionClass = RC.PK_RegionClass 
		WHERE
				RC.RegionClassCode = 'CORP'
				AND
				XREF.ThroughDate = '2049-12-31'
				AND
				AU.EventATAccessUserName = @UserID	
				AND
				AU.PK_EventATAccessUserType >= (SELECT PK_EventATAccessUserType FROM @LoggedUserAuthority)							
			
			
		SELECT DISTINCT 
			 AU.PK_EventATAccessUser
			,AUT.PK_EventATAccessUserType			 	
			,AUT.EventATAccessUserType
		FROM 
			dbo.EventATAccessUser AU WITH (NOLOCK)	
		INNER JOIN
			dbo.EventATAccessUserTypes AUT WITH (NOLOCK)	
			ON
				AU.PK_EventATAccessUserType = AUT.PK_EventATAccessUserType	
		--INNER JOIN
		--	dbo.EventATAccessUserModules AUM
		--	ON
		--		AUM.PK_EventATAccessUser = AU.PK_EventATAccessUser
		--INNER JOIN
		--	@LoggedUserAccess UA
		--	ON
		--		AUM.PK_Locale = UA.PK_Locale				
		WHERE
				AU.EventATAccessUserName = @UserID		
				AND
				AU.PK_EventATAccessUserType >= (SELECT PK_EventATAccessUserType FROM @LoggedUserAuthority)									
					
	
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

ELSE 								

/*****************************************************************************************************
 IF LOCALES ARE SELECTED, BELOW SELECTS BRINGS ALL THE USERS THAT HAS ACCESS TO THE LOCALES SELECTED
*******************************************************************************************************/	

BEGIN TRY	
   
		
	SELECT DISTINCT
		AU.PK_EventATAccessUser
		,COALESCE(AU.EventATAccessUserName, @UserID) AS UserID
		,COALESCE(AU.EventATAccessUserFirstName, @FirstName) AS FirstName
		,COALESCE(AU.EventATAccessUserLastName, @LastName) AS LastName
		,AU.EventATAccessUserCountry AS Country	
		,AU.EventATAccessUserEmailAddress
	FROM 
		dbo.EventATAccessUser AU WITH (NOLOCK)
	INNER JOIN
		dbo.EventATAccessUserTypes AUT WITH (NOLOCK)	
		ON
			AU.PK_EventATAccessUserType = AUT.PK_EventATAccessUserType	
	INNER JOIN
		dbo.EventATAccessUserModules AUM WITH (NOLOCK)
		ON
			AUM.PK_EventATAccessUser = AU.PK_EventATAccessUser
	INNER JOIN
		@LoggedUserAccess UA
		ON
			AUM.PK_Locale = UA.PK_Locale		
	INNER JOIN
		dbo.Locales L WITH (NOLOCK)
		ON
			L.PK_Locale = AUM.PK_Locale 
	WHERE
			L.LocaleCode IN (SELECT LocaleCode FROM @tbl)
			AND
			AU.PK_EventATAccessUserType >= (SELECT PK_EventATAccessUserType FROM @LoggedUserAuthority)
			AND
			AU.EventATAccessUserName <> @LoggedUser	
	ORDER BY
			COALESCE(AU.EventATAccessUserFirstName, @FirstName), COALESCE(AU.EventATAccessUserLastName, @LastName)	
			
	
	;WITH AllUsers (PK_EventATAccessUser)  --- This brings All the Users who fall under the selected locale(s)
	AS (SELECT DISTINCT
			EUM.PK_EventATAccessUser
		FROM
			dbo.EventATAccessUserModules EUM WITH (NOLOCK)
			INNER JOIN
			@tbl T
			ON
				EUM.PK_Locale = T.PK_Locale
		)		
		SELECT
			AUM.PK_EventATAccessUserModule
			,AUM.PK_EventATAccessUser
			,AUM.PK_Locale	
		    ,L.LocaleCode
		    ,L.LanguageCountryRegion
			,XREF.PK_Region
			,R.RegionName
		FROM
			dbo.EventATAccessUser AU WITH (NOLOCK)
		INNER JOIN
			dbo.EventATAccessUserTypes AUT WITH (NOLOCK)
			ON
				AU.PK_EventATAccessUserType = AUT.PK_EventATAccessUserType	
		INNER JOIN
			dbo.EventATAccessUserModules AUM WITH (NOLOCK)
			ON
				AU.PK_EventATAccessUser = AUM.PK_EventAtAccessUser	
		INNER JOIN
			AllUsers AL
			ON
				AL.PK_EventATAccessUser = AUM.PK_EventATAccessUser			
		INNER JOIN
			@LoggedUserAccess UA
		ON
			AUM.PK_Locale = UA.PK_Locale					
		INNER JOIN
			dbo.Locales L	 WITH (NOLOCK)
			ON
				AUM.PK_Locale = L.PK_Locale
		--LEFT JOIN
		--	InternetCommon.dbo.CountryLocale CL (NOLOCK)
		--ON
		--	CL.LocaleCode = L.LocaleCode 
		LEFT JOIN
			PubEvents.dbo.dimCountry C WITH (NOLOCK)
		ON
			SUBSTRING(L.LocaleCode,CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = C.CountryCodeISO 
		LEFT JOIN
			PubEvents.dbo.dimCountryRegion_XREF XREF WITH (NOLOCK)
		ON
			XREF.PK_Country = C.PK_Country 
		LEFT JOIN
			PubEvents.dbo.dimRegion R WITH (NOLOCK) 
		ON
			R.PK_Region = XREF.PK_Region 
		LEFT JOIN
			PubEvents.dbo.dimRegionClass RC WITH (NOLOCK)
		ON
			R.PK_RegionClass = RC.PK_RegionClass 
		WHERE
				RC.RegionClassCode = 'CORP'
				AND
				XREF.ThroughDate = '2049-12-31'
				--AND
				--L.LocaleCode IN (SELECT LocaleCode FROM @tbl)
				AND
				AU.PK_EventATAccessUserType >= (SELECT PK_EventATAccessUserType FROM @LoggedUserAuthority)			
				AND
				AU.EventATAccessUserName <> @LoggedUser
		ORDER BY
			AUM.PK_EventATAccessUser, XREF.PK_Region, AUM.PK_Locale	
			
			
		SELECT DISTINCT
			 AU.PK_EventATAccessUser
			,AUT.PK_EventATAccessUserType			 	
			,AUT.EventATAccessUserType
		FROM
			dbo.EventATAccessUser AU WITH (NOLOCK)
		INNER JOIN
			dbo.EventATAccessUserTypes AUT WITH (NOLOCK)
			ON
				AU.PK_EventATAccessUserType = AUT.PK_EventATAccessUserType	
		INNER JOIN
			dbo.EventATAccessUserModules AUM WITH (NOLOCK)
			ON
				AU.PK_EventATAccessUser = AUM.PK_EventAtAccessUser	
		INNER JOIN
			@LoggedUserAccess UA
		ON
			AUM.PK_Locale = UA.PK_Locale					
		 INNER JOIN
			dbo.Locales L	 WITH (NOLOCK)
			ON
				AUM.PK_Locale = L.PK_Locale
		WHERE
				L.LocaleCode IN (SELECT LocaleCode FROM @tbl)
				AND
				AU.PK_EventATAccessUserType >= (SELECT PK_EventATAccessUserType FROM @LoggedUserAuthority)						
				AND
				AU.EventATAccessUserName <> @LoggedUser
		ORDER BY
			AU.PK_EventATAccessUser		
							
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

/******************************************************************************
	end procedure
******************************************************************************/

-- Update processing Log
EXEC [dbo].[usp_Utility_UpdateProcessingLog]
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime;


END
GO

