CREATE PROCEDURE [dbo].[usp_EventsAT_Copy_PMPromoTranslation]

	-- REQUIRED
	@PK_Event					int
	,@Locale					varchar(5)
	,@NewLocale					varchar(5)
	,@UserName					varchar(255)

	-- OPTIONAL
	,@PK_EventType				int = 15
	,@BannerType				int = 2
	,@LogoType					int = 1
	,@OnlineEventLink			int = 11
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS

BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Copy_PMPromoTranslation

	USE:			
					
				--begin tran
					DECLARE @e int, @em varchar(4000)
					
					EXEC dbo.usp_EventsAT_Copy_PMPromoTranslation
							@UserName = 'RogelioR'
							,@PK_Event = 48314
							,@Locale = 'en-US'
							,@NewLocale = 'es-US'

							-- Errors
							,@Error = @e OUTPUT  /* @e must be defined in the local call */
							,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
							,@IsDevQA = 1

					SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	Copy a translation to a new locale
	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.EventLocaleDesc, dbo.EventImage, dbo.EventImageLocaleDesc, dbo.EventURL

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-04-24		RogelioR		Initial
	1.0.1		2019-08-15		NoeG			Refactor code (SRE)
******************************************************************************/
	
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @t table ([action] varchar(15), PK_Key int);

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@PK_EventExtn			int
			,@PK_Locale				int
			,@PK_NewLocale			int
			,@PK_DefaultLocale		int
			,@PK_EventLocaleDesc	int
			,@PK_EventImageLogo		int
			,@PK_EventImageBanner	int
			,@PK_EventImageKey		int
			,@PK_EventURL			int
	;

	SELECT @Error = 0, @ErrorMessage = '';
	
	BEGIN TRY
		SELECT @PK_Locale = PK_Locale FROM Locales WITH (NOLOCK) WHERE LocaleCode = @Locale;
		SELECT @PK_NewLocale = PK_Locale FROM Locales  WITH (NOLOCK) WHERE LocaleCode = @NewLocale;

		-- Describe the promotion (EventLocaleDesc)
		--
		MERGE dbo.EventLocaleDesc AS t
			USING ( SELECT
						PK_Event
						,PK_EventType
						,PK_Locale
						,@PK_NewLocale AS PK_NewLocale
						,PK_DefaultLocale
						,EventName
						,EventDesc
						,EventSummary
						,EventLocation
						,EventVenueName
						,EventAddress
						,EventCity
						,EventState
						,Keywords
						,EventCostDetails
						,EventDisplayAddress
						,EventTrainingLanguages
						,EventApprovalNotes
						,EventComments
						,EventRules
						,GETUTCDATE() AS CreatedDateUTC
						,@UserName AS CreatedBy
						,GETUTCDATE() AS ModifiedDateUTC
						,@UserName AS ModifiedBy
						,DistributorNotes
						,ParticipatingCountries
						,TicketRules
					FROM dbo.EventLocaleDesc  WITH (NOLOCK) 
					WHERE PK_Event = @PK_Event
						AND PK_Locale = @PK_Locale
					) AS s
					ON (t.PK_Event = s.PK_Event AND t.PK_Locale = s.PK_NewLocale)
				WHEN MATCHED THEN
					UPDATE SET
						PK_DefaultLocale = s.PK_DefaultLocale
						,EventName = s.EventName
						,EventDesc = s.EventDesc
						,EventSummary = s.EventSummary
						,EventLocation = s.EventLocation
						,EventVenueName = s.EventVenueName
						,EventAddress = s.EventAddress
						,EventCity = s.EventCity
						,EventState = s.EventState
						,Keywords = s.Keywords
						,EventCostDetails = s.EventCostDetails
						,EventDisplayAddress = s.EventDisplayAddress
						,EventTrainingLanguages = s.EventTrainingLanguages
						,EventApprovalNotes = s.EventApprovalNotes
						,EventComments = s.EventComments
						,EventRules = s.EventRules
						,ModifiedDateUTC = s.ModifiedDateUTC
						,ModifiedBy = s.ModifiedBy
						,DistributorNotes = s.DistributorNotes
						,ParticipatingCountries = s.ParticipatingCountries
						,TicketRules = s.TicketRules
				WHEN NOT MATCHED THEN
					INSERT (
						PK_Event
						,PK_EventType
						,PK_Locale
						,PK_DefaultLocale
						,EventName
						,EventDesc
						,EventSummary
						,EventLocation
						,EventVenueName
						,EventAddress
						,EventCity
						,EventState
						,Keywords
						,EventCostDetails
						,EventDisplayAddress
						,EventTrainingLanguages
						,EventApprovalNotes
						,EventComments
						,EventRules
						,CreatedDateUTC
						,CreatedBy
						,ModifiedDateUTC
						,ModifiedBy
						,DistributorNotes
						,ParticipatingCountries
						,TicketRules
					)
					VALUES (
						s.PK_Event
						,s.PK_EventType
						,s.PK_NewLocale
						,s.PK_DefaultLocale
						,s.EventName
						,s.EventDesc
						,s.EventSummary
						,s.EventLocation
						,s.EventVenueName
						,s.EventAddress
						,s.EventCity
						,s.EventState
						,s.Keywords
						,s.EventCostDetails
						,s.EventDisplayAddress
						,s.EventTrainingLanguages
						,s.EventApprovalNotes
						,s.EventComments
						,s.EventRules
						,s.CreatedDateUTC
						,s.CreatedBy
						,s.ModifiedDateUTC
						,s.ModifiedBy
						,s.DistributorNotes
						,s.ParticipatingCountries
						,s.TicketRules
					)
				OUTPUT $action, inserted.PK_EventLocaleDesc INTO @t
		;	-- Merge

		SELECT @PK_EventLocaleDesc = PK_Key FROM @t;	-- Return the New/Updated EventLocaleDesc Id
		
		-----------------------------------------------------------------------------------------------------------------------
		-- Merge Logo in EventImageLocaleDesc
		-- 
		SELECT @PK_EventImageKey = PK_EventImage FROM EventImage  WITH (NOLOCK)  WHERE PK_Event = @PK_Event AND PK_EventImageType = @LogoType
		
		IF @PK_EventImageKey IS NULL
		BEGIN
			RAISERROR('There is no default image for the logo.', 11, 1);
		END
	
		MERGE EventImageLocaleDesc AS t
			USING (SELECT
						EventImageLocation
						,GETUTCDATE() AS CreatedDateUTC
						,@UserName AS CreatedBy
						,GETUTCDATE() AS ModifiedDateUTC
						,@UserName AS ModifiedBy
						,@PK_EventImageKey AS PK_EventImage
						,PK_Event
						,PK_Locale
						,@PK_NewLocale AS PK_NewLocale
					FROM EventImageLocaleDesc WITH (NOLOCK) 
					WHERE PK_Event = @PK_Event
						AND PK_Locale = @PK_Locale
						AND PK_EventImage = @PK_EventImageKey
					) AS s
					ON (t.PK_Event = s.PK_Event AND t.PK_Locale = s.PK_NewLocale AND t.PK_EventImage = s.PK_EventImage)
				WHEN MATCHED THEN
					UPDATE SET
						EventImageLocation = s.EventImageLocation
						,ModifiedDateUTC = s.ModifiedDateUTC
						,ModifiedBy = s.ModifiedBy
				WHEN NOT MATCHED THEN
					INSERT (
						EventImageLocation
						,CreatedDateUTC
						,CreatedBy
						,ModifiedDateUTC
						,ModifiedBy
						,PK_EventImage
						,PK_Event
						,PK_Locale
					)
					VALUES (
						s.EventImageLocation
						,s.CreatedDateUTC
						,s.CreatedBy
						,s.ModifiedDateUTC
						,s.ModifiedBy
						,s.PK_EventImage
						,s.PK_Event
						,s.PK_NewLocale
					)
				OUTPUT $action, inserted.PK_EventImage INTO @t
		;	-- Merge Logo

		SELECT @PK_EventImageLogo = PK_Key FROM @t;

		-----------------------------------------------------------------------------------------------------------------------
		-- Merge Banner in EventImageLocaleDesc
		--
		SELECT @PK_EventImageKey = PK_EventImage FROM EventImage  WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_EventImageType = @BannerType;	-- Check if there's a banner in EventImage
		
		IF @PK_EventImageKey IS NULL
		BEGIN
			RAISERROR('There is no default banner for the logo.', 11, 1);
		END

		MERGE EventImageLocaleDesc AS t
			USING (SELECT
						EventImageLocation	-- Banner location
						,GETUTCDATE() AS CreatedDateUTC
						,@UserName AS CreatedBy
						,GETUTCDATE() AS ModifiedDateUTC
						,@UserName AS ModifiedBy
						,@PK_EventImageKey AS PK_EventImage
						,PK_Event
						,PK_Locale
						,@PK_NewLocale AS PK_NewLocale
						,(SELECT PK_EventImageType FROM EventImage  WITH (NOLOCK) WHERE PK_EventImage = @PK_EventImageKey) AS PK_EventImageType
					FROM EventImageLocaleDesc WITH (NOLOCK) 
					WHERE PK_Event = @PK_Event
						AND PK_Locale = @PK_Locale
						AND PK_EventImage = @PK_EventImageKey
					) AS s
					ON (t.PK_Event = s.PK_Event AND t.PK_Locale = s.PK_NewLocale AND t.PK_EventImage = s.PK_EventImage AND s.PK_EventImageType = @BannerType)
				WHEN MATCHED AND s.EventImageLocation IS NULL AND PK_EventImageType = @BannerType THEN
					DELETE
				WHEN MATCHED THEN
					UPDATE SET
						EventImageLocation = s.EventImageLocation
						,ModifiedDateUTC = s.ModifiedDateUTC
						,ModifiedBy = s.ModifiedBy
				WHEN NOT MATCHED AND s.EventImageLocation IS NOT NULL THEN
					INSERT (
						EventImageLocation
						,CreatedDateUTC
						,CreatedBy
						,ModifiedDateUTC
						,ModifiedBy
						,PK_EventImage
						,PK_Event
						,PK_Locale
					)
					VALUES (
						s.EventImageLocation
						,s.CreatedDateUTC
						,s.CreatedBy
						,s.ModifiedDateUTC
						,s.ModifiedBy
						,s.PK_EventImage
						,s.PK_Event
						,s.PK_NewLocale
					)
				OUTPUT $action, inserted.PK_EventImageLocaleDesc INTO @t
		;	-- Merge Logo

		SELECT @PK_EventImageBanner = PK_Key FROM @t;

		-----------------------------------------------------------------------------------------------------------------------
		-- Merge link/Button text
		-- 
		MERGE EventURL AS t
			USING (SELECT
						PK_Event
						,PK_Locale
						,@PK_NewLocale AS PK_NewLocale
						,EventURL
						,EventURLDesc
						,GETUTCDATE() AS CreatedDateUTC
						,@UserName AS CreatedBy
						,GETUTCDATE() AS ModifiedDateUTC
						,@UserName AS ModifiedBy
						,PK_EventURLType
					FROM EventURL WITH (NOLOCK) 
					WHERE PK_Event = @PK_Event
						AND PK_Locale = @PK_Locale
				) AS s
				ON (t.PK_Event = s.PK_Event AND t.PK_Locale = s.PK_NewLocale AND t.PK_EventURLType = s.PK_EventURLType)
			WHEN MATCHED AND s.EventURL IS NULL THEN
				DELETE
			WHEN MATCHED THEN
				UPDATE SET
					EventURL = s.EventURL
					,EventURLDesc = s.EventURLDesc
					,ModifiedDateUTC = s.ModifiedDateUTC
					,ModifiedBy = s.ModifiedBy
			WHEN NOT MATCHED THEN
				INSERT(
					PK_Event
					,PK_Locale
					,EventURL
					,EventURLDesc
					,CreatedDateUTC
					,CreatedBy
					,ModifiedDateUTC
					,ModifiedBy
					,PK_EventURLType
				)
				VALUES(
					s.PK_Event
					,s.PK_NewLocale
					,s.EventURL
					,s.EventURLDesc
					,s.CreatedDateUTC
					,s.CreatedBy
					,s.ModifiedDateUTC
					,s.ModifiedBy
					,s.PK_EventURLType
				)
			OUTPUT $action, inserted.PK_EventURL INTO @t
		;	-- Merge link/Button text

		SELECT @PK_EventURL = PK_Key FROM @t;


		-----------------------------------------------------------------------------------------------------------------------
		-- Merge EventMedia
		-- 
		MERGE dbo.EventMedia AS t
			USING (SELECT
						[PK_EventMedia]
						,[PK_Event]
						,[PK_MediaType]
						,[PK_Locale]
						,@PK_NewLocale AS [PK_NewLocale]
						,[MediaName]
						,[MediaDesc]
						,[MediaHTML]
						,GETUTCDATE() AS CreatedDateUTC
						,@UserName AS CreatedBy
						,GETUTCDATE() AS ModifiedDateUTC
						,@UserName AS ModifiedBy
					FROM EventMedia WITH (NOLOCK) 
					WHERE PK_Event = @PK_Event
						AND PK_Locale = @PK_Locale
				) AS s
				ON (t.PK_Event = s.PK_Event AND t.PK_Locale = s.PK_NewLocale)
			WHEN MATCHED THEN
				UPDATE SET
					[PK_Event] = s.[PK_Event]
					,[PK_MediaType] = s.[PK_MediaType]
					,[MediaName] = s.[MediaName]
					,[MediaDesc] = s.[MediaDesc]
					,[MediaHTML] = s.[MediaHTML]
					,[ModifiedDateUTC] = s.[ModifiedDateUTC]
					,[ModifiedBy] = s.[ModifiedBy]
			WHEN NOT MATCHED THEN
				INSERT(
					[PK_Event]
					,[PK_MediaType]
					,[PK_Locale]
					,[MediaName]
					,[MediaDesc]
					,[MediaHTML]
					,[CreatedBy]
					,[CreatedDateUTC]
					,[ModifiedBy]
					,[ModifiedDateUTC]
				) 
				VALUES(
					s.[PK_Event]
					,s.[PK_MediaType]
					,s.[PK_NewLocale]
					,s.[MediaName]
					,s.[MediaDesc]
					,s.[MediaHTML]
					,s.[CreatedBy]
					,s.[CreatedDateUTC]
					,s.[ModifiedBy]
					,s.[ModifiedDateUTC]
				)
			--OUTPUT $action, inserted.*
		;	-- Merge EventMedia

		-----------------------------------------------------------------------------------------------------------------------
		-- Merge SubEventLocaleDesc
		-- 
		MERGE SubEventLocaleDesc AS t  
			USING(SELECT  
						PK_SubEvent  
						,PK_Event   
						,PK_Locale  
						,PK_DefaultLocale
						,SubEventName 
						,@PK_NewLocale AS PK_NewLocale
						,SubEventQualDesc
						,[Image]
						,GETUTCDATE() AS CreatedDateUTC  
						,@UserName AS CreatedBy  
						,GETUTCDATE() AS ModifiedDateUTC  
						,@UserName AS ModifiedBy  
					FROM SubEventLocaleDesc WITH (NOLOCK) 
					WHERE PK_Event = @PK_Event
						AND PK_Locale = @PK_Locale
					) AS s
					ON (t.PK_Event = s.PK_Event AND t.PK_Locale = s.PK_NewLocale AND t.PK_SubEvent = s.PK_SubEvent)
				WHEN MATCHED THEN
					UPDATE SET
						SubEventQualDesc = s.SubEventQualDesc
						,ModifiedBy = s.ModifiedBy
						,[Image] = s.[Image]
						,ModifiedDateUTC = s.ModifiedDateUTC
				WHEN NOT MATCHED BY TARGET THEN
					INSERT(
						PK_SubEvent
						,PK_Event
						,PK_Locale
						,PK_DefaultLocale
						,SubEventName
						,SubEventQualDesc
						,[Image]
					)  
					VALUES(  
						s.PK_SubEvent  
						,s.PK_Event  
						,s.PK_NewLocale  
						,s.PK_DefaultLocale  
						,s.SubEventName  
						,s.SubEventQualDesc
						,s.[Image]
					)
			; -- Merge SubEventLocaleDesc
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

