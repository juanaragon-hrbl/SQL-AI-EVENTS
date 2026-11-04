CREATE PROCEDURE [dbo].[usp_EventsAT_Upd_EventATAccessUserModules]	
	-- REQUIRED
	@UserAccess udt_UserAccess READONLY        /* UserID & Market */	
	,@ModifiedBy nvarchar(50)                   /* User who modified */
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:	dbo.usp_EventsAT_Upd_EventATAccessUserModules

USE:		
		USE [PubEventManagement]
		GO

		DECLARE	@Error int,
				@ErrorMessage varchar(4000),
				@UserAccess udt_userAccess

		INSERT INTO @UserAccess 
		VALUES  
		('kulsumR','Kulsum','R','Canada','kulsumR@Herbalife.com','en-Au',3,1),
		('kulsumR','Kulsim','R','Canada','kulsumR@Herbalife.com','zh-HK',3,1),
		('kulsumR','Kulsim','R','Canada','kulsumR@Herbalife.com','es-MX',3,1)	
		
		EXEC usp_EventsAT_Upd_EventATAccessUserModules  @UserAccess,
			'juanah',
			@Error = @Error OUTPUT,
			@ErrorMessage = @ErrorMessage OUTPUT,
			@IsDevQA = 1

			SELECT	@Error as N'@Error',
			@ErrorMessage as N'@ErrorMessage'

DESCRIPTION:	Update of dbo.EventATAccessUserModules

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventATAccessUserModules

VERSIONS
--------------------------------------------------------------------
1.0.0		2012-09-19	SandhyaP		Initial
1.1.0		2019-05-21	alejandramed	Including standard error handling
1.2.0		2019-07-15	alejandramed	Setting error parameters as optionals
1.3.0		2021-12-17	ivanci      	Reset deleted columns (US 882107)

*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';


/******************************************************************************
	variable declaration
******************************************************************************/

DECLARE @UserExists TABLE (
	PK_EventATAccessUser INT, 
	EventATAccessUserName nvarchar(50)
)

DECLARE @tblUserAccess TABLE (
	[UserID] [nvarchar](50),
	[UserFirstName] [nvarchar](50) NULL,
	[UserLastName] [nvarchar](50) NULL,
	[Country] [nvarchar](50) NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[Locale] [nvarchar](4000),
	[AccessLevel] [INT],
	[CheckedYN] [INT] 
)

INSERT
	@tblUserAccess
(
	[UserID] 
	,[UserFirstName] 
	,[UserLastName] 
	,[Country]
	,[EmailAddress]
	,[Locale]
	,[AccessLevel]
	,[CheckedYN]
)
SELECT
	[UserID] 
	,[UserFirstName] 
	,[UserLastName] 
	,[Country]
	,[EmailAddress]
	,[Locale]
	,[AccessLevel]
	,[CheckedYN]
FROM
	@UserAccess	
	
/******************************************************************************
	LoggedUser Access Level
******************************************************************************/	
	
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
	dbo.EventATAccessUserModules EUM WITH (NOLOCK)
	ON
		EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
WHERE
	EventATAccessUserName = @ModifiedBy		
	
	
/******************************************************************************
	Insert if the user already not exists
******************************************************************************/

;WITH UserNotExists (UserID)
	AS (SELECT DISTINCT UserID
		FROM 
		@tblUserAccess
		EXCEPT
		SELECT DISTINCT EventATAccessUserName
		FROM 
		dbo.EventATAccessUser WITH (NOLOCK)
	)
INSERT 
	[dbo].[EventATAccessUser]
(
	[PK_EventATAccessUserType]
	,[EventATAccessUserName]
	,[EventATAccessUserFirstName]
	,[EventATAccessUserLastName]
	,[EventATAccessUserCountry]
	,[EventATAccessUserEmailAddress]
	,[CreatedBy]
	,[ModifiedBy]
)
SELECT DISTINCT
	EUT.PK_EventATAccessUserType
	,T.UserID
	,T.UserFirstName
	,T.UserLastName
	,T.Country
	,T.EmailAddress
	,@ModifiedBy
	,@ModifiedBy
FROM
	@tblUserAccess T
INNER JOIN
	UserNotExists U WITH (NOLOCK)
	ON
		T.UserID = U.UserID			
INNER JOIN
	dbo.EventATAccessUserTypes EUT WITH (NOLOCK)
	ON
		T.AccessLevel = EUT.PK_EventATAccessUserType
		
		
/**************************************************************************************
	Delete the assigned markets from UserModules table when Users access level is changed
****************************************************************************************/

;WITH UserExists (PK_EventATAccessUser, EventATAccessUserName)
	AS (SELECT DISTINCT EU.PK_EventATAccessUser, EU.EventATAccessUserName
		FROM 
		@tblUserAccess T
		INNER JOIN
		dbo.EventATAccessUser EU WITH (NOLOCK)
		ON
			EU.EventATAccessUserName = T.UserID
			AND
			EU.PK_EventATAccessUserType != T.AccessLevel		
		)
INSERT @UserExists(
	PK_EventATAccessUser, 
	EventATAccessUserName)
SELECT
	PK_EventATAccessUser, 
	EventATAccessUserName	 
FROM
	UserExists WITH (NOLOCK)

DELETE EUM
	FROM dbo.EventATAccessUserModules EUM
INNER JOIN
	@UserExists U
	ON
		EUM.PK_EventATAccessUser = U.PK_EventATAccessUser
	
/******************************************************************************
	Update the user access level when Users access level is changed
******************************************************************************/	 

UPDATE EU
SET   
	PK_EventATAccessUserType = EUT.PK_EventATAccessUserType
	,EventATAccessUserFirstName = T.UserFirstName
	,EventATAccessUserLastName = T.UserLastName
	,EventATAccessUserCountry = T.Country
	,EventATAccessUserEmailAddress = T.EmailAddress
	,ModifiedBy = @ModifiedBy
    ,IsDeleted = 0												-- 1.3.0
    ,DeletedBy = null                                           -- 1.3.0
    ,DeletedDateUTC = null                                      -- 1.3.0
FROM
	@tblUserAccess T
INNER JOIN
	@UserExists U
	ON
		T.UserID = U.EventATAccessUserName	
INNER JOIN
	dbo.EventATAccessUser EU
	ON
		T.UserID = EU.EventATAccessUserName			
INNER JOIN
	dbo.EventATAccessUserTypes EUT
	ON
		T.AccessLevel = EUT.PK_EventATAccessUserType	

/******************************************************************************
SET DELETE To False 											-- 1.3.0
******************************************************************************/

UPDATE EU
SET  IsDeleted = 0
    ,DeletedBy = null
    ,DeletedDateUTC = null
FROM dbo.EventATAccessUser EU 
INNER JOIN @tblUserAccess T
	ON	T.UserID = EU.EventATAccessUserName			

/******************************************************************************
UPDATE record
******************************************************************************/

	BEGIN TRY


	INSERT [dbo].[EventATAccessUserModules]
			   ([PK_EventATAccessUser]
			   ,[PK_Locale]
			   ,ModifiedBy)
	SELECT DISTINCT
		U.PK_EventATAccessUser
		,L.PK_Locale
		,@ModifiedBy
	FROM
		dbo.EventATAccessUser U WITH (NOLOCK)
	INNER JOIN
		@tblUserAccess UA
		ON
			U.EventATAccessUserName = UA.UserID	
			AND 
			UA.CheckedYN = 1	
			AND
			UA.AccessLevel = 1			
	CROSS JOIN
		dbo.Locales L WITH (NOLOCK)
	WHERE
		NOT EXISTS (SELECT EM.PK_EventATAccessUser FROM dbo.EventATAccessUserModules EM WITH (NOLOCK) WHERE U.PK_EventATAccessUser = PK_EventATAccessUser AND L.PK_Locale = EM.PK_Locale)
	
	

	INSERT [dbo].[EventATAccessUserModules]
			   ([PK_EventATAccessUser]
			   ,[PK_Locale]
			   ,ModifiedBy)
	SELECT DISTINCT
		U.PK_EventATAccessUser
		,L.PK_Locale
		,@ModifiedBy
	FROM
		dbo.EventATAccessUser U WITH (NOLOCK)
	INNER JOIN
		@tblUserAccess UA
		ON
			U.EventATAccessUserName = UA.UserID	
			AND 
			UA.CheckedYN = 1	
			AND
			UA.AccessLevel != 1					
	INNER JOIN
		dbo.Locales L WITH (NOLOCK)
		ON
			UA.Locale = L.LocaleCode
	INNER JOIN
		@LoggedUserAccess LA
		ON
			L.PK_Locale = LA.PK_Locale		
	WHERE
		NOT EXISTS (SELECT EM.PK_EventATAccessUser FROM dbo.EventATAccessUserModules EM WITH (NOLOCK) WHERE U.PK_EventATAccessUser = PK_EventATAccessUser AND L.PK_Locale = EM.PK_Locale)
	
	
	DELETE EUM
	FROM
		dbo.EventATAccessUserModules EUM
	INNER JOIN
		dbo.EventATAccessUser EU
		ON
			EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser	
	LEFT JOIN
		@tblUserAccess UA		
		ON
			EU.EventATAccessUserName = UA.UserID
	INNER JOIN
		dbo.Locales L
		ON
			EUM.PK_Locale = L.PK_Locale	
			AND
			UA.Locale = L.LocaleCode			
	WHERE
			UA.CheckedYN = 0	
	

	END TRY

	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		 
	END CATCH

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime

/******************************************************************************
	end procedure
******************************************************************************/
END
