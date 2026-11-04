
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_BreakoutSession]
        @SessionID int
		,@DistributorID VARCHAR(30) = NULL
        ,@LocaleCode varchar(5) = NULL
 
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
    OBJECT:            [dbo].[usp_EventAPI_Get_BreakoutSession]
    
    USE:            
            DECLARE @e int, @em varchar(4000)
 
            EXEC [dbo].[usp_EventAPI_Get_BreakoutSession]
                @SessionID = 24882
                ,@DistributorID='C100023219'
				,@LocaleCode = 'es-MX'--'en-US'--'en-GB'
                ,@Error = @e output
                ,@ErrorMessage = @em output
                ,@IsDevQA = 1
                
            SELECT @e AS [Error], @em AS [ErrorMessage]
            
    DESCRIPTION: Get Breakout session details by @SessionID (PK_SubEvent) and/or @LocaleCode
 
    NOTES:
    
    DEPENDENCIES
    --------------------------------------------------------------------
    [BreakoutSessionAttendees]
 
    VERSIONS
    --------------------------------------------------------------------
    1.0.0		2018-05-28		RogelioR		Initial
	1.0.1		2019-01-10		NoeG			Changes to get the TimeZoneDesc value
	1.0.2		2019-01-15		NoeG			Changes to get the RegistrationStartDate and RegistrationDeadlineDate values
	1.0.3		2019-01-22		NoeG			Changes to get:
													- ManageLanguages Sub Event configuration field
													- List of Preferred Languages selected for the Sub Event
    1.0.5		2019-01-25		NoeG			Changes to get Information when LocalCode provided is not part of the SubEventLocaleDesc (will take the Event default LocaleCode)
    1.0.6		2019-01-28		NoeG			Changes to get Qualifications Information considering the Override Qualification
	1.0.7		2019-09-05		NoeG			SRE template applied
	1.0.8		2019-11-04		NoeG			SRE Hardcode changed

******************************************************************************/
    SET ANSI_NULLS ON
    SET QUOTED_IDENTIFIER ON
    SET NOCOUNT ON
 
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'
	
	SELECT @Error = 0, @ErrorMessage = ''

    BEGIN TRY

		DECLARE @PK_Event int = (SELECT TOP 1 [PK_Event] FROM [SubEvent] WITH (NOLOCK) WHERE [PK_SubEvent] = @SessionID);

		DECLARE	@cur_PK_Locale int = (SELECT [PK_Locale] FROM [Locales] WITH (NOLOCK) WHERE [LocaleCode] = @LocaleCode);
		DECLARE @ses_PK_Locale int, @ses_Locale varchar(5)
				, @def_PK_Locale int, @def_Locale varchar(5)

		/* Define Current and Default Locale */
 
		SELECT	@ses_PK_Locale = case when sl.[Order] = 0 then sl.PK_Locale else @ses_PK_Locale end
				, @ses_Locale = case when sl.[Order] = 0 then sl.LocaleCode else @ses_Locale end
				, @def_PK_Locale = case when sl.[Order] = 1 then sl.PK_Locale else @def_PK_Locale end
				, @def_Locale = case when sl.[Order] =1 then sl.LocaleCode else @def_Locale end
		FROM (	SELECT 0 as [Order], sel.PK_Locale, l.LocaleCode
				FROM	[SubEventLocaleDesc]  sel WITH (NOLOCK) 
						INNER JOIN [Locales] l WITH (NOLOCK) 
							on sel.PK_Locale = l.PK_Locale 
				WHERE	[PK_Subevent] = @SessionID
						and l.PK_Locale = @cur_PK_Locale
				UNION
				SELECT	1 as [Order], PK_Locale, LocaleCode
				FROM	[Event] e WITH (NOLOCK) 
						INNER JOIN [Locales] l WITH (NOLOCK) 
							on e.PK_DefaultLocale = l.PK_Locale 
				WHERE	[PK_Event] = @PK_Event	
			) sl

			SELECT	@ses_PK_Locale = isnull(@ses_PK_Locale, @def_PK_Locale), @ses_Locale = isnull(@ses_Locale, @def_Locale)

        IF @IsDevQA = 1
            SELECT  @PK_Event AS [PK_Event]
                    ,@cur_PK_Locale AS [cur_PK_Locale]  
					,@LocaleCode AS [cur_Locale]
                    ,@ses_PK_Locale AS [ses_PK_Locale]
                    ,@ses_Locale AS [ses_Locale]
					,@def_PK_Locale AS [def_PK_Locale]
                    ,@def_Locale AS [def_Locale]

        -- Session details by Locale (Defaultlocale if @LocaleCode is not provided)
        SELECT	se.[PK_Event]
                ,sel.[PK_SubEvent]
                ,se.[SubEventName]
				,@ses_Locale AS [CurrentLocale]
                ,SUBSTRING(@def_Locale, 4, 2) AS [DefaultLanguage]
                ,se.[BeginTime] AS [SessionStartTime]
                ,se.[EndTime] AS [SessionEndTime]
                ,sel.[SubEventName] AS [Title]
                ,se.[Location]
                ,sel.[SubEventQualDesc]
                ,se.[MaxCapacity] AS [Capacity]
				,CASE WHEN B.PK_SubEvent IS NOT NULL THEN B.TotalAttendees ELSE 0 END AS Attendees
				,isnull(sevx.RegistrationStartDate, (SELECT CreatedDateUTC from [Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)) AS [RegistrationStartDate]
				,isnull(sevx.RegistrationDeadlineDate, (SELECT [dStartUTC] from [Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)) AS [RegistrationDeadlineDate]
				,sevx.AllowPartnerRegistration AS AllowPartnerRegistration
				,CASE WHEN BSE.DistributorID IS NOT NULL THEN 1 ELSE 0 END AS HasRegistration
				, evx.[TimeZoneDesc] 
				, sevx.[ManageLanguages]
        FROM	[dbo].[SubEvent] AS se WITH (NOLOCK) 
				INNER JOIN [dbo].[SubEventLocaleDesc] AS sel  WITH (NOLOCK)
					ON se.[PK_SubEvent] = sel.[PK_SubEvent]
						AND sel.[PK_Locale] = @ses_PK_Locale
				INNER JOIN [dbo].[EventExtn] as evx WITH (NOLOCK)
					on evx.[PK_Event] = se.[PK_Event]
				LEFT JOIN [dbo].[SubEventExtn] as sevx WITH (NOLOCK)
					on se.[PK_SubEvent] = sevx.[PK_SubEvent]
				LEFT JOIN (
							SELECT PK_SubEvent, COUNT(1) AS TotalAttendees 
							FROM  dbo.[BreakoutSessionAttendees] WITH (NOLOCK)
							GROUP BY PK_SubEvent
							) B
					ON se.PK_SubEvent = B.PK_SubEvent
				LEFT JOIN dbo.[BreakoutSessionAttendees] BSE WITH (NOLOCK)
					ON se.PK_SubEvent = BSE.PK_SubEvent
						AND BSE.DistributorID = @DistributorID
		WHERE	se.[PK_SubEvent] = @SessionID
				AND se.[PK_SubEventType] = 5;
                
        -- Guest Speakers
        SELECT	gs.[PK_EventGuestSpeaker], gs.[EventSpeakerName]
                ,(SELECT [EventImageLocation] FROM [EventImageLocaleDesc] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event AND [PK_Locale] = @def_PK_Locale AND [PK_EventImage] = gs.[PK_EventImage]) AS [Photo]
				, isnull(gssl.EventSpeakerTitle,gsdl.EventSpeakerTitle) [EventSpeakerTitle]
        FROM	[dbo].[EventGuestSpeakers] AS gs WITH (NOLOCK)
                LEFT JOIN [dbo].[EventGuestSpeakerLocale] AS gssl WITH (NOLOCK) 
					ON	gssl.[PK_EventGuestSpeaker] = gs.[PK_EventGuestSpeaker]
						AND gssl.[PK_Locale] = @cur_PK_Locale
                LEFT JOIN [dbo].[EventGuestSpeakerLocale] AS gsdl WITH (NOLOCK) 
					ON	gsdl.[PK_EventGuestSpeaker] = gs.[PK_EventGuestSpeaker]
						AND gsdl.[PK_Locale] = @def_PK_Locale
            WHERE gs.[PK_Event] = @PK_event
                AND gs.[PK_SubEvent] = @SessionID;
                
        -- Qualifications
        SELECT	DISTINCT															
				se.[PK_SubEvent]
				, se.[SubEventName]
				,CASE 
					WHEN bsor.IsQualified IS NOT NULL THEN bsor.IsQualified 
					ELSE 
						CASE 
							WHEN seq.PK_SubEvent IS NOT NULL 
							THEN 1 ELSE 0 END 
					END AS IsQualified
		FROM	[SubEvent] AS se WITH (NOLOCK)
				INNER JOIN dbo.[BreakoutSessionSubEvent] bse WITH (NOLOCK) 
					ON se.PK_SubEvent = bse.PK_SubEvent
				LEFT JOIN dbo.SubEventQualifier seq WITH (NOLOCK)
					ON se.PK_SubEvent = seq.PK_SubEvent
						AND RemovedUTC = @ValidDate
						AND DistributorID = @DistributorID
				LEFT JOIN dbo.BreakoutSessionQualifierOverride bsor WITH (NOLOCK)
					ON bse.BreakoutSession = bsor.PK_SubEvent
						AND bsor.DistributorID = @DistributorID
		WHERE	bse.[BreakoutSession] = @SessionID

		-- Preferred Languages
		SELECT	L.PK_Locale, L.LocaleCode AS [Locale], L.LanguageCountryRegion as LocaleDesc
				, CASE WHEN L.PK_Locale = @def_PK_Locale THEN 1 ELSE 0 END AS IsDefault
		FROM	BreakoutSessionPreferredLanguages BL WITH (NOLOCK)
				LEFT JOIN Locales L WITH (NOLOCK)
					ON L.LocaleCode = BL.PreferredLanguage
		WHERE	BL.PK_SubEvent = @SessionID
	            
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
END;
GO

