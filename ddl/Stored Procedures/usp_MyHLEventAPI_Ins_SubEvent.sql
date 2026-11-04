CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Ins_SubEvent]
	-- Mandatory Parameters
	 @PK_Event INT -- PK_Event to be sent after the event is created
	,@SubEvent udt_SubEvents READONLY  
		 /* Points to the user defined table that gets populated by the .NET layer for inserting and updating subevents
			Please pass these values -
			 PK_Event -- Required. Event ID 
			,PK_Subevent int -- Required. Please send value for updates and 0 for inserts
			,SubEventNumber int  -- Required. Sort Order has to be unique per subevent. No duplicate values to be sent
			,SubEventName nvarchar(1000) -- Optional. SubEventName
			,SubEventQualTxt nvarchar(4000) -- Optional. SubEvent Qual Description */
	,@LocaleCode CHAR(5) -- localeCode that has to be passed based on the MYHL page        
	-- Error Parameters
	,@Error INT OUTPUT
	,@ErrorMessage VARCHAR(200) OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:		usp_MyHLEventAPI_Ins_SubEvent
USE:
			DECLARE @e INT
			DECLARE @em VARCHAR(200)
			DECLARE @IsDevQA INT
			EXEC usp_MyHLEventAPI_Ins_SubEvent
					 @Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@PK_Event = 772
					,@tblSubEvent 
					,@LocaleCode = 'en-US'
					,@IsDevQA = 0

DESCRIPTION:	Inserts/Updates records in dbo.SubEvent & dbo.SubEventLocaleDesc

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

dbo.SubEvent, dbo.SubEventLocaleDesc

VERSIONS
--------------------------------------------------------------------
1	2011-01-06	PrabhuS	Initial
2	2019-10-16	 JonathanO		Refactor code (SRE)
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @PK_Locale INT
DECLARE @StoredProcedure VARCHAR(100)
DECLARE @StartTime DATETIME
DECLARE @tblSubEvent TABLE (
	PK_Event int
	,PK_Subevent int
	,SubEventNumber int
	,SubEventName nvarchar(1000)
	,SubEventQualTxt nvarchar(4000)
)

INSERT
	@tblSubEvent
(
	PK_Event
	,PK_Subevent
	,SubEventNumber
	,SubEventName
	,SubEventQualTxt
)
SELECT
	PK_Event
	,PK_Subevent
	,SubEventNumber
	,SubEventName
	,SubEventQualTxt
FROM
	@SubEvent

/* SET THE VALUE FOR PK_LOCALE */
SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode

SET @Error = 0
SET @ErrorMessage = 'No Error.'
SET @StoredProcedure = 'usp_MyHLEventAPI_Ins_SubEvent'
SET @StartTime = GETUTCDATE()

/* PERFORM THE INSERT IF THE PK_SUBEVENT IS PASSED AS 0 */


/******************************************************************************
	FIRST INSERT IS TO THE SUBEVENT TABLE
******************************************************************************/
BEGIN TRY
	INSERT 
		dbo.SubEvent
	(
		 [PK_Event]
		,[PK_SubEventType]
		,[MaxCapacity]
		,[ExpectedCapacity]
		,[SubEventName]
		,[SubEventNumber]
		,[KeepDNR]
		,[KeepDeleted]
	)
	SELECT
		 @PK_Event
		,CASE WHEN T.SubeventNumber = 1 THEN 1 ELSE 2 END
		,20000
		,20000
		,T.SubeventName
		,T.SubeventNumber
		,1
		,0	
	FROM
		@tblSubEvent T
	WHERE
		T.PK_Subevent = 0

END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	-- UPDATE ERROR LOG
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH

/******************************************************************************
	SECONDLY, UPDATE SUBEVENT TABLE
******************************************************************************/
BEGIN TRY
	UPDATE 
		S
	SET
		 [SubEventName] = T.SubeventName
		,[SubEventNumber] = T.SubeventNumber
	FROM
		dbo.SubEvent S
	INNER JOIN
		@tblSubEvent T
	ON
		S.PK_SubEvent = T.PK_Subevent
END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	-- UPDATE ERROR LOG
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH
/******************************************************************************
	UPDATE KEYS IN TABLE PARAMETER
******************************************************************************/
UPDATE
	SE
SET
	PK_Subevent = S.PK_SubEvent
FROM
	@tblSubEvent SE
INNER JOIN
	dbo.SubEvent S WITH (NOLOCK)
	ON
		SE.SubEventNumber = S.SubEventNumber
		AND SE.PK_Event = S.PK_Event

/******************************************************************************
	UPDATE LOCALE SUBEVENT TABLE
******************************************************************************/
BEGIN TRY
	UPDATE
		L 
	SET
		[SubEventName] = T.SubeventName
		,[SubEventQualDesc] = T.SubeventQualTxt
	FROM
		@tblSubEvent T
	INNER JOIN
		SubEventLocaleDesc L
		ON
			T.PK_Subevent = L.PK_Subevent
			AND L.PK_Locale = @PK_Locale
END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	-- UPDATE ERROR LOG
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH
	

/******************************************************************************
	INSERT LOCALE SUBEVENT TABLE
******************************************************************************/
BEGIN TRY
	INSERT 
		dbo.SubEventLocaleDesc
	(
		 [PK_Subevent]
		,[PK_Event]
		,[PK_Locale]
		,PK_DefaultLocale
		,[SubEventName]
		,[SubEventQualDesc]
	)
	SELECT
		 T.PK_SubEvent
		,@PK_Event
		,@PK_Locale
		,@PK_Locale
		,T.SubEventName
		,T.SubeventQualTxt
	FROM
		@tblSubEvent T
	LEFT JOIN
		SubEventLocaleDesc L WITH (NOLOCK)
		ON
			T.PK_Subevent = L.PK_Subevent
			AND L.PK_Locale = @PK_Locale
	WHERE
		L.PK_Subevent IS NULL
END TRY

BEGIN CATCH
	SET @Error = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	SET @StoredProcedure = ERROR_PROCEDURE()

	-- UPDATE ERROR LOG
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH


/******************************************************************************
	UPDATE PROCESSING LOG
******************************************************************************/
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END