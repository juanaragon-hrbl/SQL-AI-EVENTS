
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_BreakoutSessionList]
        @PK_Event int = 13310
        ,@LocaleCode varchar(5) = 'es-MX'
 
		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
    OBJECT:            [dbo].[usp_EventAPI_Get_BreakoutSessionList]
    
    USE:            
            DECLARE @e int, @em varchar(4000)
 
            EXEC [dbo].[usp_EventAPI_Get_BreakoutSessionList]
                @PK_Event = 63001
                ,@LocaleCode = 'es-MX'
                ,@IsDevQA = 1
                ,@Error = @e output
                ,@ErrorMessage = @em output
 
            SELECT @e AS [Error], @em AS [ErrorMessage]
 
    DESCRIPTION: Delete the list of attendees in @Attendees
 
    NOTES:
 
    DEPENDENCIES
    --------------------------------------------------------------------
    [BreakoutSessionAttendees]
 
    VERSIONS
    --------------------------------------------------------------------
    1.0.0		2018-05-28		RogelioR		Initial
 	1.0.1		2019-01-10		NoeG			Changes to get the TimeZoneDesc value
	1.0.2		2019-01-15		NoeG			Changes to get the RegistrationStartDate and RegistrationDeadlineDate values
	1.0.3		2019-01-28		NoeG			Changes to get the HasQualifications value correctly
	1.0.4		2019-09-05		NoeG			SRE template applied
******************************************************************************/
    SET ANSI_NULLS ON
    SET QUOTED_IDENTIFIER ON
    SET NOCOUNT ON
 
 	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
	
	SELECT @Error = 0, @ErrorMessage = ''

    BEGIN TRY

        DECLARE @PK_Locale int = (SELECT [PK_Locale] FROM [Locales] WITH (NOLOCK) WHERE [LocaleCode] = @LocaleCode);
        DECLARE    @PK_DefaultLocale int = (SELECT PK_DefaultLocale FROM [Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)
                ,@DefaultLocale varchar(5);
        
        SELECT @PK_Locale = ISNULL(@PK_Locale, @PK_DefaultLocale);
        SELECT @DefaultLocale = [LocaleCode] FROM [Locales] WITH (NOLOCK) WHERE [PK_Locale] = @PK_Locale;
 
 		IF NOT EXISTS (SELECT PK_SubEventLocaleDesc
							 ,PK_Subevent
							 ,PK_Event
							 ,PK_Locale
							 ,PK_DefaultLocale
							 ,SubEventName
							 ,SubEventQualDesc
							 ,CreatedDateUTC
							 ,CreatedBy
							 ,ModifiedDateUTC
							 ,ModifiedBy
							 ,PK_TeamSite
							 ,TeamSiteModifiedDate
							 ,QualDesc
							 ,Image
							 ,SubEventGroupNameLocale FROM SubEventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Locale = @PK_Locale)
					SET @PK_Locale = @PK_DefaultLocale

        IF @IsDevQA = 1
            SELECT    @PK_Event AS [PK_Event]
                    ,@PK_Locale AS [PK_Locale]
                    ,@LocaleCode AS [LocaleCode]
                    ,@PK_DefaultLocale AS [PK_DefaultLocale]
                    ,@DefaultLocale AS [DefaultLocale];
 
        -- Breakout sessions by Event
        SELECT
                se.[PK_Event]
                ,se.[PK_SubEvent]
                ,se.[SubEventName]
                ,@LocaleCode AS [CurrentLocale]
                ,SUBSTRING(@DefaultLocale, 4, 2) AS [DefaultLanguage]
                ,se.[BeginTime] AS [SessionStartTime]
                ,se.[EndTime] AS [SessionEndTime]
                ,sel.[SubEventName] AS [Title]
                ,se.[Location]
                ,sel.[SubEventQualDesc]
                ,se.[MaxCapacity] AS [Capacity]
				,CASE WHEN B.PK_SubEvent IS NOT NULL THEN B.TotalAttendees ELSE 0 END AS Attendees
				,isnull(sevx.RegistrationStartDate, (SELECT CreatedDateUTC from [Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)) AS [RegistrationStartDate]
				,isnull(sevx.RegistrationDeadlineDate, (SELECT [dStartUTC] from [Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)) AS [RegistrationDeadlineDate]
				,CASE WHEN SEQ.Qualifications > 0 THEN 1 ELSE 0 END AS [HasQualifications]
				,sevx.AllowPartnerRegistration AS AllowPartnerRegistration 
				, evx.[TimeZoneDesc] 
            FROM [dbo].[SubEvent] AS se WITH (NOLOCK)
                INNER JOIN [dbo].[SubEventLocaleDesc] AS sel  WITH (NOLOCK) ON se.[PK_SubEvent] = sel.[PK_SubEvent]
                    AND sel.[PK_Locale] = @PK_Locale
				INNER JOIN [dbo].[EventExtn] as evx WITH (NOLOCK)
					on evx.[PK_Event] = se.[PK_Event]
				LEFT JOIN [dbo].[SubEventExtn] as sevx WITH (NOLOCK)
					on se.[PK_SubEvent] = sevx.[PK_SubEvent]
				LEFT JOIN (
							/* Has qualifications */
							SELECT	SE.PK_Event, SE.PK_SubEvent, 
									count(BSE.PK_SubEvent) Qualifications 
							FROM	[SubEvent] AS SE WITH (NOLOCK)
									LEFT JOIN dbo.[BreakoutSessionSubEvent] BSE WITH (NOLOCK)
										ON SE.PK_Event = BSE.PK_Event
										AND SE.PK_SubEvent = BSE.BreakoutSession
							WHERE	SE.PK_Event = @PK_Event
									AND SE.PK_SubEventType = 5
							GROUP BY SE.PK_Event, SE.PK_SubEvent				
							) SEQ
					ON se.PK_Event = SEQ.PK_Event
						AND se.PK_SubEvent = SEQ.PK_SubEvent
				LEFT JOIN
				(
					SELECT 
						PK_SubEvent,
						COUNT(1) AS TotalAttendees 
					FROM 
						dbo.[BreakoutSessionAttendees] WITH (NOLOCK)
					GROUP BY
						PK_SubEvent
				) B
			ON se.PK_SubEvent = B.PK_SubEvent
            WHERE se.[PK_Event] = @PK_Event
                AND [PK_SubEventType] = 5;
 
 
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
