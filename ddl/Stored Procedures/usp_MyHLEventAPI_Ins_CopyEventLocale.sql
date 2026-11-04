CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Ins_CopyEventLocale]
				  @FromLocale CHAR(5)
				 ,@ToLocales nVARCHAR(MAX)
				 ,@PK_Event INT

				 -- Error Parameters
				,@Error	int = 0 OUTPUT
				,@ErrorMessage varchar(4000) = '' OUTPUT	
				
				-- QA/DEV				 
				,@IsDevQA BIT = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Ins_CopyEventLocale

USE:	        USE [PubEventManagement]
				GO

				DECLARE	@Error int,
				@ErrorMessage varchar(4000)

                 EXEC usp_MyHLEventAPI_Ins_CopyEventLocale
				      @FromLocale = 'en-US'
				     ,@ToLocales = 'es-PR;'
				     ,@PK_Event = 195752
					 ,@Error = @Error OUTPUT  /* @Error must be defined in the local call */
					 ,@ErrorMessage = @ErrorMessage OUTPUT /* @ErrorMessage must be defined in the local call */
					 -- OPTIONAL
				     ,@IsDevQA = 1

				SELECT	@Error as N'@Error',
						@ErrorMessage as N'@ErrorMessage'		

DESCRIPTION:	Copies the event record from one locale to various other locales

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
dbo.EventTicketAssignment

VERSIONS
--------------------------------------------------------------------
1.0		2011-01-04	Prabhu			Intitial
2.0		2015-05-12	SushmaA			Admin Tool CR Changes
3.0		2019-05-21	alejandramed	Homologating of standard error handling
4.0		2019-07-15	alejandramed	Setting error parameters as optionals
5.0		2019-08-14	NoeG			Refactor code (SRE)
6.0     2019-10-17  SushmaA			SRE updates for NOLOCK, NOCOUNT, SELECT *
6.0     2023-05-02  ivanci			Change logic to update or Insert
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

/*VARIABLE DECLARATION */
DECLARE @PK_FromLocale INT
DECLARE @PK_ToLocale INT
DECLARE @strlen INT
DECLARE @START INT
DECLARE @COUNTERMIN INT
DECLARE @COUNTERMAX INT
DECLARE @PK_FirstLocale INT

/* SET THE VALUE FOR PK_FromLocale BASED ON THE PASSED FROMLOCALE PARAMETER */
SELECT @PK_FromLocale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @FromLocale

/* SPLIT THE STRING VALUE OF THE TO LOCALES AS SEPARATE LOCALES INTO A TEMP TABLE */

DECLARE @ToLocale TABLE (
       PK_ToLocale INT IDENTITY(1,1)
      ,ToLocale CHAR(5)
      ,PK_Locale INT
      )

SET @ToLocales = REPLACE(@ToLocales,';','')
SET @strlen = LEN(@ToLocales)

WHILE @strlen > 0
BEGIN

      INSERT @ToLocale (ToLocale) SELECT LEFT(@ToLocales,5)
      SET @ToLocales = REPLACE(@ToLocales,LEFT(@ToLocales,5),'')
      SET @strlen = LEN(@ToLocales)
END

/* UPDATE THE PK_ToLocales VALUE IN THE TEMP TABLE */
UPDATE
	T
SET
	T.PK_Locale = L.PK_Locale
FROM
	@ToLocale T
INNER JOIN
	dbo.Locales L
ON
	T.ToLocale = L.LocaleCode
	

/* SET THE VALUE FOR THE COUNTER */

SELECT @COUNTERMIN = MIN(PK_ToLocale) FROM @ToLocale 
SELECT @COUNTERMAX = MAX(PK_ToLocale) FROM @ToLocale

WHILE @COUNTERMIN <= @COUNTERMAX
BEGIN

SELECT @PK_FirstLocale = PK_Locale FROM @ToLocale WHERE PK_ToLocale = @COUNTERMIN

BEGIN TRY


MERGE dbo.EventLocaleDesc as t
    USING ( SELECT 
        [PK_Event]
        ,[PK_EventType]
        ,[PK_Locale]
        ,[PK_DefaultLocale]
        ,[EventName]
        ,[EventDesc]
        ,[EventLocation]
        ,[EventVenueName]
        ,[EventAddress]
        ,[EventCity]
        ,[EventState]
        ,[Keywords]
        ,[EventDisplayAddress]
        ,[EventSummary]
        ,[EventCostDetails]
        ,[EventTrainingLanguages]
        ,[EventApprovalNotes]
        ,[EventComments]
        ,[EventRules]
        ,[ParticipatingCountries]
        ,[TicketRules]
    FROM dbo.EventLocaleDesc
        WHERE pk_event = @PK_Event AND PK_Locale = @PK_FromLocale
    ) as s

    ON s.pk_event = t.pk_Event
    AND t.pk_locale = @PK_FirstLocale

    WHEN NOT MATCHED THEN
    INSERT (
        [PK_Event]
    	,[PK_EventType]
    	,[PK_Locale]
    	,[PK_DefaultLocale]
    	,[EventName]
    	,[EventDesc]
    	,[EventLocation]
    	,[EventVenueName]
    	,[EventAddress]
    	,[EventCity]
    	,[EventState]
    	,[Keywords]
    	,[EventDisplayAddress]
    	,[EventSummary]
    	,[EventCostDetails]
    	,[EventTrainingLanguages]
    	,[EventApprovalNotes]
    	,[EventComments]
    	,[EventRules]
    	,[ParticipatingCountries]
    	,[TicketRules]
    ) VALUES (
         s.[PK_Event]
    	,s.[PK_EventType]
    	,@PK_FirstLocale
    	,s.[PK_DefaultLocale]
    	,s.[EventName]
    	,s.[EventDesc]
    	,s.[EventLocation]
    	,s.[EventVenueName]
    	,s.[EventAddress]
    	,s.[EventCity]
    	,s.[EventState]
    	,s.[Keywords]
    	,s.[EventDisplayAddress]
    	,s.[EventSummary]
    	,s.[EventCostDetails]
    	,s.[EventTrainingLanguages]
    	,s.[EventApprovalNotes]
    	,s.[EventComments]
    	,s.[EventRules]
    	,s.[ParticipatingCountries]
    	,s.[TicketRules]
    )
    WHEN MATCHED THEN
    UPDATE SET
    	[EventName] = s.[EventName]
    	,[EventDesc] = s.[EventDesc]
    	,[EventLocation] = s.[EventLocation]
    	,[EventVenueName] = s.[EventVenueName]
    	,[EventAddress] = s.[EventAddress]
    	,[EventCity] = s.[EventCity]
    	,[EventState] = s.[EventState]
    	,[Keywords] = s.[Keywords]
    	,[EventDisplayAddress] = s.[EventDisplayAddress]
    	,[EventSummary] = s.[EventSummary]
    	,[EventCostDetails] = s.[EventCostDetails]
    	,[EventTrainingLanguages] = s.[EventTrainingLanguages]
    	,[EventApprovalNotes] = s.[EventApprovalNotes]
    	,[EventComments] = s.[EventComments]
    	,[EventRules] = s.[EventRules]
    	,[ParticipatingCountries] = s.[ParticipatingCountries]
    	,[TicketRules] = s.[TicketRules];




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
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH



BEGIN TRY

MERGE dbo.SubEventLocaleDesc as t
    USING ( SELECT 
        [PK_SubEvent]
        ,[PK_Event]
        ,[PK_Locale]
        ,[PK_DefaultLocale]
        ,[SubEventName]
        ,[SubEventQualDesc]
        ,[QualDesc]
        ,[SubEventGroupNameLocale]
    FROM dbo.SubEventLocaleDesc
        WHERE pk_event = @PK_Event AND PK_Locale = @PK_FromLocale
    ) as s

    ON s.pk_event = t.pk_Event
    AND s.PK_SubEvent = t.PK_SubEvent
    AND t.pk_locale = @PK_FirstLocale

    WHEN NOT MATCHED THEN
    INSERT (
        [PK_SubEvent]
        ,[PK_Event]
        ,[PK_Locale]
        ,[PK_DefaultLocale]
        ,[SubEventName]
        ,[SubEventQualDesc]
        ,[QualDesc]
        ,[SubEventGroupNameLocale]
    ) VALUES (
         s.[PK_SubEvent]
        ,s.[PK_Event]
        ,@PK_FirstLocale
        ,s.[PK_DefaultLocale]
        ,s.[SubEventName]
        ,s.[SubEventQualDesc]
        ,s.[QualDesc]
        ,s.[SubEventGroupNameLocale]
    )
    WHEN MATCHED THEN
    UPDATE SET
        [SubEventName] = s.[SubEventName]
        ,[SubEventQualDesc] = s.[SubEventQualDesc]
        ,[QualDesc] = s.[QualDesc]
        ,[SubEventGroupNameLocale] = s.[SubEventGroupNameLocale];




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
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH


BEGIN TRY

MERGE dbo.EventImageLocaleDesc as t
    USING ( SELECT 
         [PK_EventImage]
        ,[PK_Event]
        ,[PK_Locale]
        ,[EventImageLocation]
    FROM dbo.EventImageLocaleDesc
        WHERE pk_event = @PK_Event AND PK_Locale = @PK_FromLocale
    ) as s

    ON s.pk_event = t.pk_Event
    AND s.PK_EventImage = t.PK_EventImage
    AND t.pk_locale = @PK_FirstLocale

    WHEN NOT MATCHED THEN
    INSERT (
        [PK_EventImage]
        ,[PK_Event]
        ,[PK_Locale]
        ,[EventImageLocation]
    ) VALUES (
         s.[PK_EventImage]
        ,s.[PK_Event]
        ,@PK_FirstLocale
        ,s.[EventImageLocation]
    )
    WHEN MATCHED THEN
    UPDATE SET
        [EventImageLocation] = s.[EventImageLocation];


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
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH


BEGIN TRY

MERGE dbo.EventGuestSpeakerLocale as t
    USING ( SELECT 
         PK_EventGuestSpeaker
        ,EventSpeakerName
        ,EventSpeakerTitle
        ,EventSpeakerTeamLevel
        ,PK_Event
        ,PK_Locale
        ,EventSpeakerBio
        ,PK_EventURL
    FROM dbo.EventGuestSpeakerLocale
        WHERE pk_event = @PK_Event AND PK_Locale = @PK_FromLocale
    ) as s

    ON s.pk_event = t.pk_Event
    AND s.PK_EventGuestSpeaker = t.PK_EventGuestSpeaker
    AND t.pk_locale = @PK_FirstLocale

    WHEN NOT MATCHED THEN
    INSERT (
         PK_EventGuestSpeaker
        ,EventSpeakerName
        ,EventSpeakerTitle
        ,EventSpeakerTeamLevel
        ,PK_Event
        ,PK_Locale
        ,EventSpeakerBio
        ,PK_EventURL
    ) VALUES (
          s.PK_EventGuestSpeaker
        ,s.EventSpeakerName
        ,s.EventSpeakerTitle
        ,s.EventSpeakerTeamLevel
        ,s.PK_Event
        ,@PK_FirstLocale
        ,s.EventSpeakerBio
        ,s.PK_EventURL
    )
    WHEN MATCHED THEN
    UPDATE SET
        EventSpeakerName = s.EventSpeakerName
        ,EventSpeakerTitle = s.EventSpeakerTitle
        ,EventSpeakerTeamLevel = s.EventSpeakerTeamLevel
        ,EventSpeakerBio = s.EventSpeakerBio
        ,PK_EventURL = s.PK_EventURL;


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
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH

BEGIN TRY

MERGE dbo.EventAudioLocaleDesc as t
    USING ( SELECT 
         PK_Event
    	,PK_EventAudio
    	,AudioName
    	,AudioDesc
    	,AudioHTML
    	,PK_Locale
    FROM dbo.EventAudioLocaleDesc
        WHERE pk_event = @PK_Event AND PK_Locale = @PK_FromLocale
    ) as s

    ON s.pk_event = t.pk_Event
    AND s.PK_EventAudio = t.PK_EventAudio
    AND t.pk_locale = @PK_FirstLocale

    WHEN NOT MATCHED THEN
    INSERT (
         PK_Event
    	,PK_EventAudio
    	,AudioName
    	,AudioDesc
    	,AudioHTML
    	,PK_Locale
    ) VALUES (
         s.PK_Event
    	,s.PK_EventAudio
    	,s.AudioName
    	,s.AudioDesc
    	,s.AudioHTML
        ,@PK_FirstLocale
    )
    WHEN MATCHED THEN
    UPDATE SET
        AudioName = s.AudioName
        ,AudioDesc = s.AudioDesc
        ,AudioHTML = s.AudioHTML;


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
			,@ErrorMessage = @ErrorMessage OUTPUT
			,@SQLErrorCode = @Error
			,@SQLErrorMsg = @ErrorMessage
	RETURN 
END CATCH

SET @COUNTERMIN = @COUNTERMIN + 1

END

-- UPDATE PROCESSING LOG
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
