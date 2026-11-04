
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_BreakoutSessionDetails]
		@SessionID int

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_EventAPI_Get_BreakoutSessionDetails]
	
	USE:			
			DECLARE @e int, @em varchar(4000)

			EXEC [dbo].[usp_EventAPI_Get_BreakoutSessionDetails]
				@SessionID = 24873
				,@IsDevQA = 0
				,@Error = @e output
				,@ErrorMessage = @em output

			SELECT @e AS [Error], @em AS [ErrorMessage]

	DESCRIPTION: Get Breakout session details by @SessionID

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	[BreakoutSessionAttendees]

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2018-06-06		RogelioR		Initial
	1.0.1		2019-01-10		NoeG			Changes to get the TimeZoneDesc value
	1.0.2		2019-01-15		NoeG			Changes to get the RegistrationStartDate and RegistrationDeadlineDate values
	1.0.3		2019-01-22		NoeG			Changes to get:
													- ManageLanguages Sub Event configuration field
													- List of Preferred Languages selected for the Sub Event
	1.0.4		2019-01-24		NoeG			Changes to get the Guest Speakers Locales
	1.0.5		2019-09-05		NoeG			SRE template applied
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

 	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
	
	SELECT @Error = 0, @ErrorMessage = ''

    BEGIN TRY

		DECLARE @PK_Event int = (SELECT TOP 1 [PK_Event] FROM [SubEvent] WITH (NOLOCK) WHERE [PK_SubEvent] = @SessionID);
		DECLARE	@PK_DefaultLocale int = (SELECT PK_DefaultLocale FROM [Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)
				,@DefaultLocale varchar(5)
				,@PK_Locale int;
		
		SELECT @PK_Locale = ISNULL(@PK_Locale, @PK_DefaultLocale);
		SELECT @DefaultLocale = [LocaleCode] FROM [Locales]  WITH (NOLOCK) WHERE [PK_Locale] = @PK_Locale;
		
		IF @IsDevQA = 1
			SELECT	@PK_Event AS [PK_Event]
					,@PK_Locale AS [PK_Locale]
					,@PK_DefaultLocale AS [PK_DefaultLocale]
					,@DefaultLocale AS [DefaultLocale];
					
		-- Session details
		SELECT
				se.[PK_Event]
				,se.[PK_SubEvent]
				,se.[SubEventName]
				,se.[BeginTime] AS [StartTime]
				,se.[EndTime] AS [EndTime]
				,se.[MaxCapacity] AS [Capacity]
				,CASE WHEN B.PK_SubEvent IS NOT NULL THEN B.TotalAttendees ELSE 0 END AS Attendees
				,isnull(sevx.RegistrationStartDate, (SELECT CreatedDateUTC from [Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)) AS [RegistrationStartDate]
				,isnull(sevx.RegistrationDeadlineDate, (SELECT [dStartUTC] from [Event] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event)) AS [RegistrationDeadlineDate]
				,sevx.AllowPartnerRegistration AS [AllowPartnerRegistration]
				, evx.[TimeZoneDesc] 
				, sevx.[ManageLanguages]
			FROM [dbo].[SubEvent] AS se WITH (NOLOCK)
				INNER JOIN [dbo].[EventExtn] as evx WITH (NOLOCK)
					on evx.[PK_Event] = se.[PK_Event]
				LEFT JOIN [dbo].[SubEventExtn] as sevx WITH (NOLOCK)
					on se.[PK_SubEvent] = sevx.[PK_SubEvent]
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
			WHERE se.[PK_SubEvent] = @SessionID;
				
		
		-- Session data by Locale (Defaultlocale if @LocaleCode is not provided)
		SELECT
				(SELECT [LocaleCode] FROM [Locales] WITH (NOLOCK) WHERE [PK_Locale] = sl.[PK_Locale]) AS [Locale]
				,sl.[SubEventName] AS [Title]
				,sl.[SubEventQualDesc] AS [Description]
				,(SELECT [Location] FROM [dbo].[SubEvent] WITH (NOLOCK) WHERE [PK_SubEvent] = 12377) AS [Location]
			FROM [dbo].[SubEventLocaleDesc] AS sl WITH (NOLOCK)
			WHERE sl.[PK_SubEvent] = @SessionID
			
		-- Breakout sessions locales
		SELECT
				g.[PK_EventGuestSpeaker]
				,g.[EventSpeakerName]
				,gl.[EventSpeakerTitle]
				,(SELECT [EventImageLocation] FROM [EventImageLocaleDesc] WITH (NOLOCK) WHERE [PK_Event] = @PK_Event AND [PK_Locale] = @PK_Locale AND [PK_EventImage] = g.[PK_EventImage]) AS [Photo]
			FROM [dbo].[EventGuestSpeakers] AS g WITH (NOLOCK)
				LEFT JOIN [dbo].[EventGuestSpeakerLocale] AS gl WITH (NOLOCK) ON gl.[PK_EventGuestSpeaker] = g.[PK_EventGuestSpeaker]
					AND gl.[PK_Locale] = @PK_Locale
			WHERE g.[PK_Event] = @PK_event
				AND g.[PK_SubEvent] = @SessionID;

		-- Guest Speakers locales
		SELECT	g.[PK_EventGuestSpeaker]
				,g.[EventSpeakerName]
				,gl.[EventSpeakerTitle]			
				,l.[LocaleCode]
		FROM	[dbo].[EventGuestSpeakers] AS g WITH (NOLOCK)
				LEFT JOIN [dbo].[EventGuestSpeakerLocale] AS gl WITH (NOLOCK) 
					ON gl.[PK_EventGuestSpeaker] = g.[PK_EventGuestSpeaker]
				LEFT JOIN [dbo].[Locales] l WITH (NOLOCK)
					ON gl.[PK_Locale] = l.[PK_Locale]
		WHERE	g.[PK_Event] = @PK_event
				AND g.[PK_SubEvent] = @SessionID;

		-- Qualifications
		SELECT DISTINCT
				s.[PK_SubEvent]
				,s.[SubEventName]
			FROM [SubEvent] AS s WITH (NOLOCK)
				INNER JOIN [SubEventQualification] AS sq WITH (NOLOCK) ON sq.[PK_SubEvent] = s.[PK_SubEvent]
					AND sq.[PK_Event] = @PK_Event;

		-- Preferred Languages
		SELECT	L.PK_Locale, L.LocaleCode AS [Locale], CASE WHEN L.PK_Locale = @PK_DefaultLocale THEN 1 ELSE 0 END AS IsDefault
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

