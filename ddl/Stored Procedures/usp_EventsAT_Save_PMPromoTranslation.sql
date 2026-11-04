CREATE PROCEDURE [dbo].[usp_EventsAT_Save_PMPromoTranslation]
	-- Required
	@PK_Event					int
	,@Locale					varchar(5)
	,@UserName					varchar(255)

	-- Optional
	,@EventThumbnailLocation	varchar(255) = NULL
	,@EventName					nvarchar(1000) = NULL
	,@EventDesc					nvarchar(max) = NULL
	,@EventSummary				nvarchar(max) = NULL
	,@EventLocation				nvarchar(400) = NULL
	,@EventVenueName			nvarchar(400) = NULL
	,@EventAddress				nvarchar(2000) = NULL
	,@EventCity					nvarchar(500) = NULL
	,@EventState				nvarchar(500) = NULL
	,@Keywords					nvarchar(1000) = NULL
	,@EventCostDetails			nvarchar(max) = NULL
	,@EventDisplayAddress		nvarchar(max) = NULL
	,@EventTrainingLanguages	nvarchar(max) = NULL
	,@EventApprovalNotes		nvarchar(max) = NULL
	,@EventComments				nvarchar(max) = NULL
	,@EventRules				nvarchar(max) = NULL
	,@DistributorNotes			nvarchar(max) = NULL
	,@ParticipatingCountries	nvarchar(max) = NULL
	,@TicketRules				nvarchar(max) = NULL
	,@EventBannerLocation		varchar(255) = NULL
	,@LinkURL					varchar(255) = NULL
	,@ButtonText				nvarchar(255) = NULL
	,@IsPublish					bit = NULL
	,@IsCTAEnabledOnUpcoming	bit = NULL

	-- Defaults
	,@PK_EventType				int = 15
	,@BannerType				int = NULL	 -- BUG 359780	
	,@LogoType					int = NULL	 -- BUG 359780
	,@OnlineEventLink			int = 11
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS

BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Save_PMPromoTranslation

	USE:			
					DECLARE @e int, @em varchar(4000)

					EXEC dbo.usp_EventsAT_Save_PMPromoTranslation
							@UserName = 'RogelioR'
							,@PK_Event = 48016
							,@Locale = 'es-MX'
							,@EventThumbnailLocation = 'http://thumbnail.com/48036_es-MX'
							,@EventBannerLocation = 'http://banner.com/48036_es-MX'
							-- Errors
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

					SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	Insert/Updates a translation for a preferred member promotion
	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.EventLocaleDesc, dbo.EventImage, dbo.EventImageLocaleDesc, dbo.EventURL

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-03		RogelioR		Initial
	2.0.0		2019-08-08		NoeG			Refactor code (SRE)
	2.1.0		2020-09-25	    puertac			BUG 359780: Wrong PK_EventImage saved on EventImageLocaleDesc for Banner
******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	DECLARE @t table ([action] varchar(15), PK_Key int);

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@PK_EventExtn			int
			,@PK_Locale				int
			,@PK_DefaultLocale		int
			,@PK_EventLocaleDesc	int
			,@PK_EventImageLogo		int
			,@PK_EventImageBanner	int
			,@PK_EventImageKey		int
			,@PK_EventURL			int;

	SELECT @Error = 0, @ErrorMessage = '';

			
	BEGIN TRY
		
		SELECT  @BannerType	 = 2	-- BUG 359780 
				,@LogoType	 = 1	-- BUG 359780
				
		-- Check if the Event exists and get default locale
		SELECT @PK_DefaultLocale = PK_DefaultLocale FROM Event WITH	(NOLOCK) WHERE PK_Event = @PK_Event;

		IF @PK_DefaultLocale IS NULL
		BEGIN
			RAISERROR('Default locale is mandatory.', 11, 1);
			SELECT 0 AS PK_Event;
		END

		SELECT @PK_Locale = PK_Locale FROM Locales WITH	(NOLOCK)  WHERE LocaleCode = @Locale;


		-----------------------------------------------------------------------------------------------------------------------
		-- Merge translation
		--
		MERGE dbo.EventLocaleDesc AS t
			USING ( SELECT
						@PK_Event	AS [PK_Event]
						,@PK_EventType AS [PK_EventType]
						,@PK_Locale AS [PK_Locale]
						,@PK_DefaultLocale AS [PK_DefaultLocale]
						,@EventName AS [EventName]
						,@EventDesc	AS [EventDesc]
						,@EventSummary AS [EventSummary]
						,@EventLocation AS [EventLocation]
						,@EventVenueName AS [EventVenueName]
						,@EventAddress AS [EventAddress]
						,@EventCity AS [EventCity]
						,@EventState AS [EventState]
						,@Keywords AS [Keywords]
						,@EventCostDetails AS [EventCostDetails]
						,@EventDisplayAddress AS [EventDisplayAddress]
						,@EventTrainingLanguages AS [EventTrainingLanguages]
						,@EventApprovalNotes AS [EventApprovalNotes]
						,@EventComments AS [EventComments]
						,@EventRules AS [EventRules]
						,GETUTCDATE() AS [CreatedDateUTC]
						,@UserName AS [CreatedBy]
						,GETUTCDATE() AS [ModifiedDateUTC]
						,@UserName AS [ModifiedBy]
						,@DistributorNotes AS [DistributorNotes]
						,@ParticipatingCountries AS [ParticipatingCountries]
						,@TicketRules AS [TicketRules]
						,@IsCTAEnabledOnUpcoming AS [IsCTAEnabledOnUpcoming]
					) AS s
					ON (t.[PK_Event] = s.[PK_Event] AND t.[PK_Locale] = s.[PK_Locale])
				WHEN MATCHED THEN
					UPDATE SET
						[PK_DefaultLocale] = s.[PK_DefaultLocale]
						,[EventName] = s.[EventName]
						,[EventDesc] = s.[EventDesc]
						,[EventSummary] = s.[EventSummary]
						,[EventLocation] = s.[EventLocation]
						,[EventVenueName] = s.[EventVenueName]
						,[EventAddress] = s.[EventAddress]
						,[EventCity] = s.[EventCity]
						,[EventState] = s.[EventState]
						,[Keywords] = s.[Keywords]
						,[EventCostDetails] = s.[EventCostDetails]
						,[EventDisplayAddress] = s.[EventDisplayAddress]
						,[EventTrainingLanguages] = s.[EventTrainingLanguages]
						,[EventApprovalNotes] = s.[EventApprovalNotes]
						,[EventComments] = s.[EventComments]
						,[EventRules] = s.[EventRules]
						,[ModifiedDateUTC] = s.[ModifiedDateUTC]
						,[ModifiedBy] = s.[ModifiedBy]
						,[DistributorNotes] = s.[DistributorNotes]
						,[ParticipatingCountries] = s.[ParticipatingCountries]
						,[TicketRules] = s.[TicketRules]
						,[IsCTAEnabledOnUpcoming] = s.[IsCTAEnabledOnUpcoming]
				WHEN NOT MATCHED THEN
					INSERT (
						[PK_Event]
						,[PK_EventType]
						,[PK_Locale]
						,[PK_DefaultLocale]
						,[EventName]
						,[EventDesc]
						,[EventSummary]
						,[EventLocation]
						,[EventVenueName]
						,[EventAddress]
						,[EventCity]
						,[EventState]
						,[Keywords]
						,[EventCostDetails]
						,[EventDisplayAddress]
						,[EventTrainingLanguages]
						,[EventApprovalNotes]
						,[EventComments]
						,[EventRules]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
						,[DistributorNotes]
						,[ParticipatingCountries]
						,[TicketRules]
						,[IsCTAEnabledOnUpcoming]
					)
					VALUES (
						s.[PK_Event]
						,s.[PK_EventType]
						,s.[PK_Locale]
						,s.[PK_DefaultLocale]
						,s.[EventName]
						,s.[EventDesc]
						,s.[EventSummary]
						,s.[EventLocation]
						,s.[EventVenueName]
						,s.[EventAddress]
						,s.[EventCity]
						,s.[EventState]
						,s.[Keywords]
						,s.[EventCostDetails]
						,s.[EventDisplayAddress]
						,s.[EventTrainingLanguages]
						,s.[EventApprovalNotes]
						,s.[EventComments]
						,s.[EventRules]
						,s.[CreatedDateUTC]
						,s.[CreatedBy]
						,s.[ModifiedDateUTC]
						,s.[ModifiedBy]
						,s.[DistributorNotes]
						,s.[ParticipatingCountries]
						,s.[TicketRules]
						,s.[IsCTAEnabledOnUpcoming]
					)
				OUTPUT $action, inserted.[PK_EventLocaleDesc] INTO @t
			;	-- Merge

		SELECT @PK_EventLocaleDesc = [PK_Key] FROM @t;	-- Return the New/Updated EventLocaleDesc Id

		IF(@IsDevQA = 1)	-- Show event
		BEGIN
			SELECT 
				'EventLocaleDesc ' + CAST(@PK_EventLocaleDesc AS nvarchar(255)) FROM [EventLocaleDesc] AS eld  WITH	(NOLOCK) WHERE eld.[PK_Event] = (@PK_Event);
		END

		-----------------------------------------------------------------------------------------------------------------------
		-- Merge logo in EventImageLocaleDesc
		--
		SELECT @PK_EventImageKey = [PK_EventImage] FROM [EventImage] WHERE [PK_Event] = @PK_Event AND [PK_EventImageType] = @LogoType;	-- Check if there's an image in EventImage
		
		IF @IsDevQA = 1 SELECT @PK_EventImageKey AS LogoExists;
		
		IF @PK_EventImageKey IS NULL AND @EventThumbnailLocation IS NOT NULL	-- Theres no image, insert this one as the default for the logo
		BEGIN
			INSERT INTO EventImage (
				[EventImageLocation]
				,[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
				,[PK_Event]
				,[PK_EventImageType]
			)
			VALUES (
				@EventThumbnailLocation
				,GETUTCDATE()
				,@UserName
				,GETUTCDATE()
				,@UserName
				,@PK_Event
				,@LogoType
			)

			SELECT @PK_EventImageKey = PK_EventImage FROM EventImage WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_EventImageType = @LogoType;	--BUG 359780 Get the PK_EventImage just inserted
		
			IF @IsDevQA = 1 SELECT @PK_EventImageKey AS LogoInsert;

		END	-- Inserted image on EventImage for the logo

		MERGE EventImageLocaleDesc AS t
			USING (SELECT
						@EventThumbnailLocation AS EventImageLocation
						,GETUTCDATE() AS CreatedDateUTC
						,@UserName AS CreatedBy
						,GETUTCDATE() AS ModifiedDateUTC
						,@UserName AS ModifiedBy
						,@PK_EventImageKey AS PK_EventImage
						,@PK_Event AS PK_Event
						,@PK_Locale AS PK_Locale
						,@LogoType AS PK_EventImageType
					) AS s
					ON (t.PK_Event = s.PK_Event AND t.PK_Locale = s.PK_Locale AND t.PK_EventImage = s.PK_EventImage AND s.PK_EventImageType = @LogoType) --BUG 359780 Verify the ImageType is Logo
				WHEN MATCHED THEN
					UPDATE SET
						[EventImageLocation] = s.[EventImageLocation]
						,[ModifiedDateUTC] = s.[ModifiedDateUTC]
						,[ModifiedBy] = s.[ModifiedBy]
				WHEN NOT MATCHED THEN
					INSERT (
						[EventImageLocation]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
						,[PK_EventImage]
						,[PK_Event]
						,[PK_Locale]
					)
					VALUES (
						s.[EventImageLocation]
						,s.[CreatedDateUTC]
						,s.[CreatedBy]
						,s.[ModifiedDateUTC]
						,s.[ModifiedBy]
						,s.[PK_EventImage]
						,s.[PK_Event]
						,s.[PK_Locale]
					)
				OUTPUT $action, inserted.[PK_EventImage] INTO @t
		;	-- Merge Logo

		IF @IsDevQA = 1 
			SELECT 'Logo Merge' + CAST(@PK_EventImageKey AS nvarchar(255)) 
	 
		-----------------------------------------------------------------------------------------------------------------------
		-- Merge Banner in EventImageLocaleDesc
		--
		SELECT @PK_EventImageKey = NULL;

		SELECT @PK_EventImageKey = PK_EventImage FROM EventImage  WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_EventImageType = @BannerType;	-- Check if there's a banner in EventImage
		
		IF @IsDevQA = 1 SELECT @PK_EventImageKey AS BannerExists

		IF @PK_EventImageKey IS NULL AND @EventBannerLocation IS NOT NULL	-- Theres no image, insert this one as the default for the banner
		BEGIN
			INSERT INTO EventImage (
				[EventImageLocation]
				,[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
				,[PK_Event]
				,[PK_EventImageType]
			)
			VALUES (
				@EventBannerLocation
				,GETUTCDATE()
				,@UserName
				,GETUTCDATE()
				,@UserName
				,@PK_Event
				,@BannerType
			)

			SELECT @PK_EventImageKey = PK_EventImage FROM EventImage  WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_EventImageType = @BannerType; --BUG 359780 Get the PK_EventImage just inserted

			IF @IsDevQA = 1 SELECT @PK_EventImageKey AS BannerInsert
		
		END	-- Inserted image on EventImage for the banner

		MERGE [dbo].[EventImageLocaleDesc] AS t
			USING (SELECT
						@EventBannerLocation AS [EventImageLocation]
						,GETUTCDATE() AS [CreatedDateUTC]
						,@UserName AS [CreatedBy]
						,GETUTCDATE() AS [ModifiedDateUTC]
						,@UserName AS [ModifiedBy]
						,@PK_EventImageKey AS [PK_EventImage]
						,@PK_Event AS [PK_Event]
						,@PK_Locale AS [PK_Locale]
						,(SELECT PK_EventImageType FROM EventImage  WITH (NOLOCK) WHERE PK_EventImage = @PK_EventImageKey) AS PK_EventImageType
					) AS s
					ON (t.[PK_Event] = s.[PK_Event] AND t.[PK_Locale] = s.[PK_Locale] AND t.[PK_EventImage] = s.[PK_EventImage] AND s.[PK_EventImageType] = @BannerType)
				WHEN MATCHED AND @EventBannerLocation IS NULL AND [PK_EventImageType] = @BannerType THEN
					DELETE
				WHEN MATCHED THEN
					UPDATE SET
						[EventImageLocation] = s.[EventImageLocation]
						,[ModifiedDateUTC] = s.[ModifiedDateUTC]
						,[ModifiedBy] = s.[ModifiedBy]
				WHEN NOT MATCHED AND @EventBannerLocation IS NOT NULL THEN
					INSERT (
						[EventImageLocation]
						,[CreatedDateUTC]
						,[CreatedBy]
						,[ModifiedDateUTC]
						,[ModifiedBy]
						,[PK_EventImage]
						,[PK_Event]
						,[PK_Locale]
					)
					VALUES (
						s.[EventImageLocation]
						,s.[CreatedDateUTC]
						,s.[CreatedBy]
						,s.[ModifiedDateUTC]
						,s.[ModifiedBy]
						,s.[PK_EventImage]
						,s.[PK_Event]
						,s.[PK_Locale]
					)
				OUTPUT $action, inserted.[PK_EventImageLocaleDesc] INTO @t
		;	-- Merge Logo


		IF @IsDevQA = 1 
				SELECT 'Banner merge' + CAST(@PK_EventImageKey AS nvarchar(255))
	 

		-----------------------------------------------------------------------------------------------------------------------
		-- Merge link/Button text
		--
		MERGE EventURL AS t
			USING (SELECT
						@PK_Event AS [PK_Event]
						,@PK_Locale AS [PK_Locale]
						,@LinkURL AS [EventURL]
						,@ButtonText AS [EventURLDesc]
						,GETUTCDATE() AS [CreatedDateUTC]
						,@UserName AS [CreatedBy]
						,GETUTCDATE() AS [ModifiedDateUTC]
						,@UserName AS [ModifiedBy]
						,@OnlineEventLink AS [PK_EventURLType]
				) AS s
				ON (t.[PK_Event] = s.[PK_Event] AND t.[PK_Locale] = s.[PK_locale] AND t.[PK_EventURLType] = s.[PK_EventURLType])
			WHEN MATCHED AND @LinkURL IS NULL THEN
				DELETE
			WHEN MATCHED THEN
				UPDATE SET
					[EventURL] = s.[EventURL]
					,[EventURLDesc] = s.[EventURLDesc]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
			WHEN NOT MATCHED THEN
				INSERT(
					[PK_Event]
					,[PK_Locale]
					,[EventURL]
					,[EventURLDesc]
					,[CreatedDateUTC]
					,[CreatedBy]
					,[ModifiedDateUTC]
					,[ModifiedBy]
					,[PK_EventURLType]
				)
				VALUES(
					s.[PK_Event]
					,s.[PK_Locale]
					,s.[EventURL]
					,s.[EventURLDesc]
					,s.[CreatedDateUTC]
					,s.[CreatedBy]
					,s.[ModifiedDateUTC]
					,s.[ModifiedBy]
					,s.[PK_EventURLType]
				)
			OUTPUT $action, inserted.[PK_EventURL] INTO @t
			;	-- Merge link/Button text

			SELECT @PK_EventURL = [PK_Key] FROM @t;

			IF(@IsDevQA = 1)	-- Show event
			BEGIN
				SELECT 'Banner ' + CAST(@PK_EventURL AS nvarchar(255)) FROM [EventURL] AS ei  WITH (NOLOCK) WHERE ei.PK_Event = @PK_Event;
			END

		-----------------------------------------------------------------------------------------------------------------------
		-- Change IsPublish state in the event
		--
		IF ISNULL(@IsPublish, 0) = 1
		BEGIN
			UPDATE [dbo].[Event] SET
					[IsPublish] = @IsPublish
				WHERE PK_Event = @PK_Event;
		END;

		-- Update event "modified*" fields
		UPDATE [dbo].[Event] SET
				[ModifiedDateUTC] = GETUTCDATE()
				,[ModifiedBy] = @UserName
			WHERE [PK_Event] = @PK_Event;

		SELECT @PK_Event AS [PK_Event];
	
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
 
	END CATCH

END