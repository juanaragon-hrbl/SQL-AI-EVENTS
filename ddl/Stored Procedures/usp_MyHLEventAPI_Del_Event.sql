CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Del_Event]
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
OBJECT:		dbo.usp_MyHLEventAPI_Del_Event

USE:		
			DECLARE @e int
					,@em varchar(200)
					,@IsDevQA int

			EXEC usp_MyHLEventAPI_Del_Event
					@PK_Event = '188091'
					,@UserID = 'SandhyaP'
					-- Error Parameters
					,@Error = @e OUTPUT  
					,@ErrorMessage = @em OUTPUT 
					-- QA/DEV
					,@IsDevQA = 1		
						
			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	This Delete Event API can be used from Admin Tool only for deleting events that are inactive and unpublished.

NOTES:	Queue the event (MyHbl/AT) to be deleted by the backend job 

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.Event
ALL Child Tables

VERSIONS (d)
--------------------------------------------------------------------
1	2013-01-28	Juan/Sandhya		Initial
2	2018-04-09	RogelioR			DS Events are erased with [usp_MyHLEventAPI_Del_DSEvent
3	2019-05-21	alejandramed		Homologating of standard error handling
4	2019-07-15	alejandramed		Setting error parameters as optionals
5	2019-08-14	NoeG				Refactor code (SRE)
6	2019-10-17	alejandramed		SRE Compliance 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	/******************************************************************************
		variable declaration
	******************************************************************************/
	DECLARE @Len INT
	DECLARE @tbl TABLE(PK_Event INT)
	DECLARE @DSEvents table([PK_Event] int);

	/******************************************************************************
	Seperate PK_Events id's
	******************************************************************************/
	IF SUBSTRING(@PK_Event, LEN(@pk_eVENT), 1) <> ','
	SET @PK_Event = @PK_Event + ','

	SET @Len = LEN(@PK_Event)

	WHILE @Len > 0
	BEGIN
		  INSERT @tbl (PK_Event) SELECT LEFT(@PK_Event, CHARINDEX(',',@PK_Event)-1)
		  SET @PK_Event = REPLACE(@PK_Event,LEFT(@PK_Event, CHARINDEX(',',@PK_Event)),'')
		  SET @Len = LEN(@PK_Event)
	END

	-- DELETE DS Events using another sp.
	INSERT INTO @DSEvents
	SELECT e.PK_Event
		FROM @tbl as t
		INNER JOIN [Event] AS e WITH (NOLOCK) ON e.[PK_Event] = t.[PK_Event]
			AND e.[PK_EventType] = 3

	DELETE FROM @tbl WHERE [PK_Event] IN (SELECT [PK_Event] FROM @DSEvents);

	DECLARE @DS_PK_Events varchar(max);

	SELECT @DS_PK_Events = COALESCE(@DS_PK_Events + ',', '') + CAST([PK_Event] AS varchar(max)) FROM @DSEvents;

	DECLARE @e1 int, @em1 varchar(max);

	EXEC [usp_MyHLEventAPI_Del_DSEvent] 
		@PK_Event = @DS_PK_Events
		,@Error = @e1
		,@ErrorMessage = @em1; 

	IF @IsDevQA = 1 
	BEGIN
		SELECT PK_Event FROM @tbl
		SELECT [PK_Event] FROM @DSEvents
		SELECT @DS_PK_Events AS DSEventParamenter
	END

	IF NOT EXISTS (SELECT 1 FROM @tbl)
	BEGIN
		RETURN
	END

	/******************************************************************************
	Check Staff/Distributor has the permissions to delete
	******************************************************************************/

	IF (
	SELECT COUNT(*)
	FROM
	(	
	/* CHECK FOR THE CORPORATE EVENTS */
		SELECT PK_Event
		FROM @tbl
		EXCEPT
		(
		SELECT DISTINCT E.PK_Event 
		FROM dbo.EventATAccessUser EU WITH (NOLOCK)
		INNER JOIN 
			dbo.EventATAccessUserModules EUM WITH (NOLOCK)
			ON 
				EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
		INNER JOIN 
			dbo.Locales L WITH (NOLOCK)
			ON 
				L.PK_Locale = EUM.PK_Locale
		INNER JOIN 
			dbo.v_Countries C
			ON 
				SUBSTRING(L.LocaleCode, CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = C.sCountryCodeISO
		INNER JOIN 
			dbo.EventDistributorCountry EC WITH (NOLOCK)
			ON
				C.nCountryID = EC.PK_Country
		INNER JOIN 
			dbo.Event E WITH (NOLOCK)
			ON 
				EC.PK_Event = E.PK_Event				
		WHERE
			EU.EventATAccessUserName = @UserID
			AND 
			E.PK_Event IN (SELECT PK_Event FROM @tbl)
			AND
			E.PK_EventType != 3
		UNION
	/* CHECK FOR THE DISTRIBUTOR EVENTS */	
		--SELECT PK_Event
		--FROM @tbl
		--EXCEPT
		SELECT DISTINCT E.PK_Event 
		FROM dbo.EventATAccessUser EU WITH (NOLOCK)
		INNER JOIN 
			dbo.EventATAccessUserModules EUM WITH (NOLOCK)
			ON 
				EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
		INNER JOIN 
			dbo.Locales L WITH (NOLOCK)
		ON 
			L.PK_Locale = EUM.PK_Locale
		INNER JOIN 
			dbo.EventLocaleDesc ELD WITH (NOLOCK)
			ON
				L.PK_Locale = ELD.PK_Locale
		INNER JOIN 
			dbo.Event E WITH (NOLOCK)
			ON 
				ELD.PK_Event = E.PK_Event				
		WHERE
			EU.EventATAccessUserName = @UserID
			AND 
			E.PK_Event IN (SELECT PK_Event FROM @tbl)
			AND
			E.PK_EventType = 3	
		)
	)a
		) > 0
	BEGIN
		SET @Error = 293
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END


	/******************************************************************************
	Check if Event is Active
	******************************************************************************/
	IF NOT EXISTS(SELECT 1 FROM dbo.Event E WITH (NOLOCK) INNER JOIN @tbl T ON E.PK_Event = T.PK_Event WHERE ISNULL(IsPublish,1) = 0 AND ISNULL(IsActive,1) = 0)
	BEGIN
		SET @Error = 406 
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END


	/******************************************************************************
	Check if Event has Qualifiers and SKU
	******************************************************************************/
	IF EXISTS(SELECT DISTINCT E.PK_Event FROM dbo.SubEventQualification E WITH (NOLOCK) INNER JOIN @tbl T ON E.PK_Event = T.PK_Event 
				UNION ALL SELECT DISTINCT E.PK_Event FROM dbo.SKUPurchased  E WITH (NOLOCK) INNER JOIN @tbl T ON E.PK_Event = T.PK_Event
				UNION ALL SELECT DISTINCT E.PK_Event FROM dbo.Event E WITH (NOLOCK) INNER JOIN @tbl T ON E.PK_Event = T.PK_Event WHERE IsCustomTrackingSiteAvailable = 1)
	BEGIN		
		SET @Error = 408 
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	END

		INSERT INTO dbo.EventDeleteQueue (PK_Event)
		SELECT PK_Event FROM @tbl
		EXCEPT
			SELECT PK_Event FROM dbo.EventDeleteQueue WITH (NOLOCK)

		/*Delete from eventeventsubtype in realtime*/
		DELETE FROM dbo.EventEventSubType WHERE PK_Event IN (SELECT PK_Event FROM @tbl)
	
END TRY
BEGIN CATCH
	IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION			
	IF @IsDevQA = 1
		SELECT ERROR_MESSAGE()
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

/******************************************************************************
	end procedure
******************************************************************************/
--Deployment: 20180423
END
GO

