CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Unpublish_Event]
	--Required
	@PK_Event VARCHAR (200)
	,@UserID VARCHAR(30)
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Unpublish_Event

USE:		
			DECLARE @e int, @em varchar(4000)

			EXEC usp_MyHLEventAPI_Unpublish_Event
				@PK_Event = '4276'
				,@UserID = '2222222222'
				-- Error Parameters
				,@Error = @e OUTPUT  
				,@ErrorMessage = @em OUTPUT 
				-- QA/DEV
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
	
DESCRIPTION:	Unpublish one or more events (Marks Event.Ispublish & IsActive to 0)

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.Event
VERSIONS
--------------------------------------------------------------------
1	2013-02-05			SandhyaP				Initial
2	2019-08-14			NoeG					Refactor code (SRE)

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @Len INT
DECLARE @tbl TABLE(PK_Event INT)

SELECT @Error = 0, @ErrorMessage = '';

/******************************************************************************
Seperate PK_Events id's
******************************************************************************/

SET @PK_Event = replace(replace(REPLACE(@PK_Event, CHAR(10), ''), CHAR(13), ''), CHAR(9), '') + ','

SET @Len = LEN(@PK_Event)

WHILE @Len > 0
BEGIN
      INSERT @tbl (PK_Event) SELECT LEFT(@PK_Event, CHARINDEX(',',@PK_Event)-1)
      SET @PK_Event = REPLACE(@PK_Event,LEFT(@PK_Event, CHARINDEX(',',@PK_Event)),'')
      SET @Len = LEN(@PK_Event)
END


/******************************************************************************
Check IF @UserID is a Staff or DistributorID
******************************************************************************/

IF EXISTS (SELECT DISTINCT EventATAccessUserName FROM dbo.EventATAccessUser WITH(NOLOCK) WHERE EventATAccessUserName = @UserID)

BEGIN 
/******************************************************************************
Check Staff/Distributor has the permissions to delete
******************************************************************************/

IF (
SELECT COUNT(PK_Event)
FROM
(	
/* IF USERID IS ADMIN/STAFF ON ADMIN TOOL */
	SELECT PK_Event
	FROM @tbl
	EXCEPT
	(SELECT DISTINCT E.PK_Event		/* CORP EVENTS/PROMOTIONS */
	FROM dbo.EventATAccessUser EU WITH(NOLOCK)
	INNER JOIN 
		dbo.EventATAccessUserModules EUM WITH(NOLOCK)
		ON 
			EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
	INNER JOIN 
		dbo.Locales L WITH(NOLOCK)
		ON 
			L.PK_Locale = EUM.PK_Locale
	INNER JOIN 
		dbo.v_Countries C
		ON 
			SUBSTRING(L.LocaleCode, CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = C.sCountryCodeISO
	INNER JOIN 
		dbo.EventDistributorCountry EC WITH(NOLOCK)
		ON
			C.nCountryID = EC.PK_Country
	INNER JOIN 
		dbo.Event E WITH(NOLOCK)
		ON 
			EC.PK_Event = E.PK_Event				
	WHERE
		EU.EventATAccessUserName = @UserID
		AND 
		E.PK_Event IN (SELECT PK_Event FROM @tbl)
		AND
		E.PK_EventType <> 3           
	UNION
	SELECT DISTINCT E.PK_Event		/* Distributor Events */
	FROM dbo.EventATAccessUser EU WITH(NOLOCK)
	INNER JOIN 
		dbo.EventATAccessUserModules EUM WITH(NOLOCK)
		ON 
			EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
	INNER JOIN 
		dbo.Locales L WITH(NOLOCK)
		ON 
			L.PK_Locale = EUM.PK_Locale
	INNER JOIN 
		dbo.EventLocaleDesc ELD WITH(NOLOCK)
		ON
			L.PK_Locale = ELD.PK_Locale
	INNER JOIN 
		dbo.Event E WITH(NOLOCK)
		ON 
			ELD.PK_Event = E.PK_Event				
	WHERE
		EU.EventATAccessUserName = @UserID
		AND 
		E.PK_Event IN (SELECT PK_Event FROM @tbl)
		AND
		E.PK_EventType = 3 )         
)a		
	) > 0 
BEGIN
	SET @Error = 295
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END		
		
END

ELSE IF EXISTS (SELECT DISTINCT DistributorID FROM dbo.EventDSAccess WITH(NOLOCK) WHERE DistributorID = @UserID)

BEGIN	

IF (
SELECT COUNT(PK_Event)
FROM
(	
/* IF USERID IS A DISTRIBUTOR ID ON MYHL */	
	SELECT PK_Event
	FROM @tbl
	EXCEPT
	SELECT DISTINCT E.PK_Event 
	FROM dbo.EventDSAccess EDA WITH(NOLOCK)
	INNER JOIN 
		dbo.EventSubTypeLocaleDesc ESL WITH(NOLOCK)
		ON 
			EDA.PK_EventSubTypeLocaleDesc= ESL.PK_EventSubTypeLocaleDesc
	INNER JOIN 
		dbo.Locales L WITH(NOLOCK)
		ON 
			L.PK_Locale = ESL.PK_Locale
	INNER JOIN 
		dbo.v_Countries C
		ON 
			SUBSTRING(L.LocaleCode, CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = C.sCountryCodeISO
	--INNER JOIN	
	--	dbo.EventLocaleDesc ELD
	--	ON
	--		ELD.PK_Locale = EDA.PK_Locale		
	INNER JOIN 
		dbo.Event E WITH(NOLOCK)
		ON 
			EDA.DistributorID = E.CreatedDistributorID				
	WHERE
		EDA.DistributorID = @UserID
		AND 
		E.PK_Event IN (SELECT PK_Event FROM @tbl)
		AND
		E.PK_EventType = 3	
)a
	) > 0
BEGIN
	SET @Error = 295
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

END

/******************************************************************************
    Unpublish Event by marking Ispublish column to 0 
******************************************************************************/
	
BEGIN TRY

	BEGIN TRAN	
	/* Unpublish Event */

	UPDATE E
	SET
		IsPublish = 0
		,IsActive = 0
	FROM
		dbo.Event E
	WHERE
		PK_Event IN (SELECT PK_Event FROM @tbl) 	

	COMMIT TRAN
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
	IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION			
	RETURN 
END CATCH

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

/******************************************************************************
	end procedure
******************************************************************************/
END
GO

