CREATE PROCEDURE [dbo].[usp_EventsAT_Copy_PMPromotion]
	-- Required
	@PK_Event			int
	,@dStartUTC			datetime2
	,@dEndUTC			datetime2
	,@TimeZone			varchar(255)
	,@UserName			varchar(255)

	-- Defaults
	,@PK_EventType		int = 15
	,@OnlyValidEvents	int = 1
	,@Transaction		bit = 0
	,@NamePrefix		varchar(50) = 'DRAFT'
	,@Separator			varchar(5) = '_'

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************

	OBJECT:			dbo.usp_EventsAT_Copy_PMPromotion

	USE:			
				DECLARE @e int, @em varchar(4000)
				
				EXEC dbo.usp_EventsAT_Copy_PMPromotion
						@PK_Event = 48251
						,@dStartUTC = '2019-07-07'
						,@dEndUTC = '2019-07-10'
						,@TimeZone = 'CENTRAL'
						,@UserName = 'Rogelio'
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
				
	DESCRIPTION:	Insert/Updates a Preferred Member Promotion on Event

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	dbo.Event, dbo.EventDSTeamType, dbo.EventDistributorCountryLocales, dbo.EventLocaleDesc, dbo.EventExtn

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2017-05-22		RogelioR		Initial
	1.0.1		2019-08-15		NoeG			Refactor code (SRE)
	1.0.2		2021-06-22		ivanci			BUG 703303 - Copied promotion, calendar not display complete calendar
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	DECLARE @t table ([action] nvarchar(15), PK_Key int);

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@PK_NewEvent		int
			,@ValidEvent		int
			,@CopyingTable		varchar(255) = '';
			
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		IF (@dEndUTC <= @dStartUTC) --OR (@dStartUTC < GETUTCDATE())       --BUG 703303
		BEGIN
			RAISERROR('The start date cannot be greater than the end date.', 11, 1);
		END

		SELECT @ValidEvent = CASE WHEN n > 0 AND n = ValidSections THEN 1 ELSE 0 END FROM dbo.udf_EventsAT_Get_PMPromoStatus(@PK_Event, default, default, default, default, default, default, default);

		IF @OnlyValidEvents = 1 AND @ValidEvent = 0
		BEGIN
			RAISERROR('Event not copied. The source event is not completed yet.', 11, 1);
			SELECT 0 AS PK_Event;
		END;
		
		IF @Transaction = 1 BEGIN TRANSACTION
		
			-----------------------------------------------------------------------------------------------------------------------------------
			-- Copy the new event
			--
			INSERT INTO Event (
				[IsTicketPurchaseRequired]
				,[IsPreRegistrationRequired]
				,[CanAssignTickets]
				,[CanPurchaseTicketOnline]
				,[IsRFIDRequired]
				,[CanRegisterOnline]
				,[IsHotelEnabled]
				,[CanShowCurrentQualOnline]
				,[MaxNoOfGuest]
				,[MaxNoOfPrimaryGuest]
				,[MaxCapacity]
				,[ExpectedCapacity]
				,[IsPromotion]
				,[PK_EventType]
				,[EventName]
				,[dStartUTC]
				,[dEndUTC]
				,[IsInventoryEnabled]
				,[IsTrackLogoAvail]
				,[PK_DefaultLocale]
				,[IsPublish]
				,[IsActive]
				,[Location]
				,[CreatedDateUTC]
				,[CreatedBy]
				,[ModifiedDateUTC]
				,[ModifiedBy]
			)
			OUTPUT 'INSERT', inserted.PK_Event INTO @t
			SELECT
					0 AS [IsTicketPurchaseRequired]
					,0 AS [IsPreRegistrationRequired]
					,0 AS [CanAssignTickets]
					,0 AS [CanPurchaseTicketOnline]
					,0 AS [IsRFIDRequired]
					,0 AS [CanRegisterOnline]
					,0 AS [IsHotelEnabled]
					,0 AS [CanShowCurrentQualOnline]
					,0 AS [MaxNoOfGuest]
					,0 AS [MaxNoOfPrimaryGuest]
					,0 AS [MaxCapacity]
					,0 AS [ExpectedCapacity]
					,1 AS [IsPromotion]
					,e.[PK_EventType]
					,NULL	-- [EventName]
					,@dStartUTC AS [dStartUTC]
					,@dEndUTC AS [dEndUTC]
					,0 AS [IsInventoryEnabled]
					,0 AS [IsTrackLogoAvail]
					,e.[PK_DefaultLocale]
					,0 AS [IsPublish]
					,1 AS [IsActive]
					,@TimeZone AS [Location]
					,GETUTCDATE() AS [CreatedDateUTC]
					,@UserName AS [CreatedBy]
					,GETUTCDATE() AS [ModifiedDateUTC]
					,@UserName AS [ModifiedBy]
				FROM [Event] AS e
				WHERE e.[PK_Event] = @PK_Event;

			SELECT @PK_NewEvent = @@IDENTITY;

			UPDATE [dbo].[Event] SET 
					[EventName] = @NamePrefix + @Separator + CAST(@PK_NewEvent AS varchar(255)) + @Separator + (SELECT CONVERT(varchar(10),[CreatedDateUTC], 120) FROM @t WHERE PK_Event = @PK_NewEvent)
				WHERE PK_Event = @PK_NewEvent;

			SELECT @PK_NewEvent

			IF @IsDevQA = 1 SELECT @CopyingTable = '[Event]';
			-----------------------------------------------------------------------------------------------------------------------------------
			-- Copy the EventDSTeamType
			--
			INSERT INTO [dbo].[EventDSTeamType] (
				[DSTeamTypeCode]
				,[PK_Event]
			)
			SELECT 
					[DSTeamTypeCode]
					,@PK_NewEvent AS [PK_Event]
				FROM [EventDSTeamType] WITH (NOLOCK)
				WHERE [PK_Event] = @PK_Event;

			IF @IsDevQA = 1 SELECT @CopyingTable = '[DSTeamTypeCode]';

			-----------------------------------------------------------------------------------------------------------------------------------
			-- Copy the EventDistributorCountryLocales
			--
			INSERT INTO [dbo].[EventDistributorCountryLocales](
				[PK_Event]
				,[PK_Locale]
				,[IsDefault]
			)
			SELECT 
					@PK_NewEvent AS [PK_Event]
					,[PK_Locale]
					,[IsDefault]
				FROM [dbo].[EventDistributorCountryLocales] WITH (NOLOCK)
				WHERE [PK_Event] = @PK_Event;

			IF @IsDevQA = 1 SELECT @CopyingTable = '[EventDistributorCountryLocales]'

			
			-----------------------------------------------------------------------------------------------------------------------------------
			-- Copy the dbo.EventLocaleDesc
			--
			INSERT INTO [dbo].[EventLocaleDesc] (
				[PK_Event]
				,[PK_EventType]
				,[PK_Locale]
				,[PK_DefaultLocale]
				,[PK_TeamSite]
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
				,[TeamSiteModifiedDate]
				,[DistributorNotes]
				,[ParticipatingCountries]
				,[TicketRules]
			)
			SELECT
					@PK_NewEvent AS [PK_Event]
					,[PK_EventType]
					,[PK_Locale]
					,[PK_DefaultLocale]
					,[PK_TeamSite]
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
					,[TeamSiteModifiedDate]
					,[DistributorNotes]
					,[ParticipatingCountries]
					,[TicketRules]
				FROM [dbo].[EventLocaleDesc] WITH (NOLOCK)
				WHERE [PK_Event] = @PK_Event;

			IF @IsDevQA = 1 SELECT @CopyingTable = '[EventLocaleDesc]'

			-----------------------------------------------------------------------------------------------------------------------------------
			-- Copy the dbo.EventExtn
			--
			INSERT INTO [dbo].[EventExtn] (
				[PK_Event]
				,[IsDisplayTVP]
				,[IsDisplayRO]
				,[IsDisplayPPV]
				,[IsDisplayPB]
				,[IsDisplayDLV]
				,[IsDisplayPPVDLV]
				,[IsDisplayAWT]
				,[IsDisplayAWTQualPeriod]
				,[IsDisplayAWTFirstTime]
				,[AWTStartDate]
				,[AWTEndDate]
				,[IsUmbracoHosted]
				,[IsDisplayPDF]
			)
			SELECT
					@PK_NewEvent AS [PK_Event]
					,[IsDisplayTVP]
					,[IsDisplayRO]
					,[IsDisplayPPV]
					,[IsDisplayPB]
					,[IsDisplayDLV]
					,[IsDisplayPPVDLV]
					,[IsDisplayAWT]
					,[IsDisplayAWTQualPeriod]
					,[IsDisplayAWTFirstTime]
					,[AWTStartDate]
					,[AWTEndDate]
					,[IsUmbracoHosted]
					,[IsDisplayPDF]
				FROM [dbo].[EventExtn] WITH (NOLOCK)
				WHERE [PK_Event] = @PK_Event;

			IF @IsDevQA = 1 SELECT @CopyingTable = '[EventExtn]'

			-----------------------------------------------------------------------------------------------------------------------------------
			-- Copy the dbo.EventURL
			--
			INSERT INTO [dbo].[EventURL] (
				[PK_Event]
				,[PK_Locale]
				,[EventURL]
				,[EventURLDesc]
				,[Flyer]
				,[PK_EventURLType]
			)
			SELECT
					@PK_NewEvent AS [PK_Event]
					,[PK_Locale]
					,[EventURL]
					,[EventURLDesc]
					,[Flyer]
					,[PK_EventURLType]
				FROM [dbo].[EventURL] WITH (NOLOCK)
				WHERE [PK_Event] = @PK_Event;

			IF @IsDevQA = 1 SELECT @CopyingTable = '[EventURL]'

			-----------------------------------------------------------------------------------------------------------------------------------
			-- Copy the dbo.EventImage
			--
			DECLARE @img TABLE(PK_EventImage int, PK_Event int, PK_EventImageType int);

			INSERT INTO [dbo].[EventImage] (
				[EventImageLocation]
				,[PK_Event]
				,[PK_EventImageType]
				,[CreatedDateUTC]
				,[ModifiedDateUTC]
			)
			OUTPUT inserted.PK_EventImage, inserted.PK_Event, inserted.PK_EventImageType INTO @img
			SELECT 
					[EventImageLocation]
					,@PK_NewEvent AS [PK_Event]
					,[PK_EventImageType]
					,GETUTCDATE() AS [CreatedDateUTC]
					,GETUTCDATE() AS [ModifiedDateUTC]
				FROM [dbo].[EventImage] WITH (NOLOCK)
				WHERE [PK_Event] = @PK_Event;
		
			IF @IsDevQA = 1 SELECT @CopyingTable = '[EventImage]'

			-----------------------------------------------------------------------------------------------------------------------------------
			-- Copy the dbo.EventImageLocaleDesc
			--
			INSERT INTO [dbo].[EventImageLocaleDesc] (
				[PK_EventImage]
				,[EventImageLocation]
				,[PK_Event]
				,[PK_Locale]
			)
			SELECT
					i.[PK_EventImage]
					,eil.[EventImageLocation]
					,@PK_NewEvent AS [PK_Event]
					,eil.[PK_Locale]
				FROM [dbo].[EventImage] AS ei WITH (NOLOCK)
					INNER JOIN [dbo].[EventImageLocaleDesc] AS eil WITH (NOLOCK) ON eil.[PK_EventImage] = ei.[PK_EventImage]
					INNER JOIN @img AS i ON i.[PK_EventImageType] = ei.[PK_EventImageType]
				WHERE ei.[PK_Event] = @PK_Event;

			IF @IsDevQA = 1 SELECT @CopyingTable = '[EventImageLocaleDesc]'

			-----------------------------------------------------------------------------------------------------------------------------------
			-- Copy the dbo.EventMedia
			--
			INSERT INTO [dbo].[EventMedia] (
				[PK_Event]
				,[PK_MediaType]
				,[PK_Locale]
				,[MediaName]
				,[MediaDesc]
				,[MediaHTML]
			)
			SELECT
					@PK_NewEvent AS [PK_Event]
					,[PK_MediaType]
					,[PK_Locale]
					,[MediaName]
					,[MediaDesc]
					,[MediaHTML]
				FROM [EventMedia] WITH (NOLOCK)
				WHERE PK_Event = @PK_Event;
		
		IF @IsDevQA = 1 SELECT @CopyingTable = '[EventMedia]'
		
		IF @Transaction = 1 COMMIT TRANSACTION

	END TRY
	BEGIN CATCH

		IF @Transaction = 1 
		BEGIN
			IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		END;

		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @CopyingTable;
		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage

		SELECT 0 AS PK_Event;

	END CATCH;


END;