CREATE PROCEDURE [dbo].[usp_SetEventHeader]
	@UserName			VARCHAR(25),
	@PK_Event			INT,
	@ProjectID			INT,
	@RFID				VARCHAR(3) = NULL,
	@CountryCode		VARCHAR(2),
	@RegionCode			VARCHAR(20),
	@CountryList		VARCHAR(500),
	@Location			VARCHAR(100),
	@EventTimeZone		DECIMAL(5,2),
	@EventType			VARCHAR(25),
	@SubEventType		VARCHAR(50),
	@EventName			VARCHAR(100),
	@StartUTC			DATE,
	@EndUTC				DATE,
	@QualPeriodStart	DATE,
	@QualPeriodEnd		DATE,
	@DisplayStartDate	DATE,
	@DisplayEndDate		DATE,

	--Optional
	@DSTeam VARCHAR(5) = 'FQS', -- FQS or ALL 
	@IsTicketPurchaseRequired BIT = 1,
	@IsPreRegistrationRequired BIT = 0,
	@CanAssignTickets BIT = 0,
	@CanPurchaseTicketOnline BIT = 0,
	@CanRegisterOnline BIT = 1,
	@IsHotelEnabled BIT = 0,
	@CanShowCurrentQualOnline BIT =  1,
	@IsRecordLocked BIT =  0,
	@MaxNoOfGuest INT = 1,
	@MaxNoOfPrimaryGuest INT = 1,
	@MaxCapacity INT = 20000,
	@ExpectedCapacity INT = 16000,
	@EventNamePositionID INT = NULL,
	@PK_OldEventApp INT = NULL,
	@StoredProcedureName VARCHAR(200) = NULL,
	@LocalName NVARCHAR(300) = NULL,
	@IsPromotion INT = NULL,
	@IsInventoryEnabled BIT = 1,
	@IsTrackLogoAvail BIT = 0,
	@EventImageURL NVARCHAR(1000) = NULL,
	@IsQualifytoPurchaseTickets INT = 0,
	@EventZipCode VARCHAR(10) = '00000',
	@IsDisplayEvent BIT = 0,
	@IsRecurring BIT = NULL,
	@EventCity NVARCHAR(100) = '',
	@EventState NVARCHAR(100) = '',
	@IsActive BIT = 1,
	@MakePublic BIT = 1,
	@EventCostDetails NVARCHAR(2000) = NULL,
	@EventApprovalStatus INT = 1,
	@IsPublish BIT = 0,
	@CanDisplayQualPeriod BIT = 1,
	@IsPublishQualTracking BIT = 1,
	@IsBizworkReportEnabled BIT = 1,
	
	
	@IsCustomTrackingSiteAvailable BIT = 0,
	@CustomTrackingSiteSPName  NVARCHAR(150) = NULL,

	@PK_DefaultLocale			INT = NULL

	-- Error Parameters
	,@Error	INT = 0 OUTPUT
	,@ErrorMessage VARCHAR(4000) = '' OUTPUT
	-- QA/DEV
	,@IsDevQA BIT = 0
AS
BEGIN

/******************************************************************************
	OBJECT:			[dbo].[usp_SetEventHeader]
	
	USE:			
			

	DESCRIPTION: 	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	
	REFERNCES
	--------------------------------------------------------------------
	NUMBER		TABLE/VIEW						FIELD							
	1			dbo.[v_Countries]				sCountryCode						
	2			dbo.[v_Countries]				sRegionCode							
	3			dbo.[EventType]					EventType,EventTypeCode					
	4			dbo.[EventSubTypes]				EventSubType						

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2019-04-29		alejandramed		Initial
	1.0.1		2019-06-05		alejandramed		Removing @DeleteDev param
	1.0.2		2019-07-28		alejandramed		Including IsCustomTrackingSiteAvailable and CustomTrackingSiteSPName
	1.0.3		2019-08-27		alejandramed		@IsPublish = 1 by default, PK_DefaultLocale not updated and @PK_DefaultLocale included
	1.0.4		2019-09-19		alejandramed		@EventType takes value from EventType or EventTypeCode on dbo.[EventType]
													If is a promotion records are not included on EventEventSubType 
													Change @Location length from 20 to 100 
													If is a promotion setting NULL to EventVenueName, EventAddress, EventCity and EventState 	
													If the Event already exist, do not replace information when its a promotion
													If it is a promotion, do not insert EventDSTeamType
	1.1.0		2019-10-17      puertac				SRE Implementation 
	1.1.1		2020-06-16		alejandramed		@IsPublish = 0 by default
	1.1.2		2020-12-08		alejandramed		Removing update over IsPublish field
	1.1.3		2021-10-18		alejandramed		Including IsBadgePrinting field
******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

		--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		/* VARIABLE DECLARATION */
		BEGIN

			DECLARE @PK_SubEvent		INT
			DECLARE @PK_Country			INT
			DECLARE @PK_EventType		INT
			DECLARE @PK_EventSubType	INT
			DECLARE @IsRFIDRequired		BIT = 0
			DECLARE @VendorEventID		VARCHAR(15) = NULL
			DECLARE @RFID_dllFileName	VARCHAR(15)
			DECLARE @RFID_dllNamespace	VARCHAR(15)
			DECLARE @PK_DefaultLocale_PROD		INT = NULL
			DECLARE @EventCountries AS TABLE
			(
				PK_Event INT,
				PK_Country INT,
				CountryCode VARCHAR(2)
			)
			DECLARE @IsBadgePrinting BIT = 0
			
		END

		IF ((@RegionCode IS NULL AND @CountryList IS NULL) OR (@RegionCode IS NOT NULL AND @CountryList IS NOT NULL))
		BEGIN

			SELECT @Error = 10001, @ErrorMessage = 'RegionCode and CountryList, these two variable cannot be NULL or have a value at the same time';
		
		END
		ELSE
		BEGIN
		
			/* GETTING COUNTRIES */
			BEGIN

				IF(@RegionCode IS NOT NULL)
					INSERT INTO @EventCountries(PK_Event,PK_Country,CountryCode) 
					SELECT @PK_Event,nCountryID,sCountryCodeISO
					FROM dbo.v_Countries
					WHERE sRegionCode = @RegionCode

				IF(@CountryList IS NOT NULL)
					INSERT INTO @EventCountries(PK_Event,PK_Country,CountryCode) 
						SELECT @PK_Event,nCountryID, sCountryCodeISO
						FROM dbo.v_Countries
						WHERE sCountryCode IN (SELECT [String] FROM dbo.[udf_SplitVarchar](@CountryList, ','))
			END
			
			/* GETTING MAIN VALUES */
			BEGIN

			--Locale
			IF @PK_DefaultLocale IS NULL
			SELECT @PK_DefaultLocale = MAX(L.PK_Locale) FROM dbo.v_CountryLocale CL INNER JOIN dbo.Locales L ON CL.sLocaleCode = L.LocaleCode WHERE sCountryCode = @CountryCode

			SELECT @PK_DefaultLocale_PROD = PK_DefaultLocale FROM dbo.[Event] WITH (NOLOCK) WHERE PK_Event = @PK_Event

			IF @PK_DefaultLocale_PROD IS NOT NULL
					SET @PK_DefaultLocale = @PK_DefaultLocale_PROD

 			--Country
			SELECT @PK_Country = nCountryID FROM dbo.v_Countries  WHERE sCountryCode = @CountryCode

			--EventType
			SELECT @PK_EventType = et.PK_EventType FROM EventType et WITH (NOLOCK) WHERE LTRIM(RTRIM(et.EventType)) = LTRIM(RTRIM(@EventType)) OR  LTRIM(RTRIM(et.EventTypeCode)) = LTRIM(RTRIM(@EventType))

			--EventSubType
			SELECT @PK_EventSubType = PK_EventSubType FROM dbo.EventSubTypes WITH (NOLOCK) WHERE PK_EventType = @PK_EventType AND RTRIM(LTRIM(EventSubType)) = LTRIM(RTRIM(@SubEventType)) AND IsActive = 1   

			END

			IF ( @PK_DefaultLocale IS NULL OR  @PK_Country IS NULL OR @PK_EventType IS NULL OR (@PK_EventSubType IS NULL AND (@IsPromotion IS NULL OR @IsPromotion = 0 )))
			BEGIN
				SELECT @Error = 10002, @ErrorMessage = 'PK_DefaultLocale, PK_Country, PK_EventType and PK_EventSubType cannot be NULL';
			END
			ELSE
			BEGIN

				/*	GETTING RFID CONFIG*/
				BEGIN
					
					IF @RFID = 'HLF' OR @RFID = 'ITN'
					BEGIN
						SET @IsRFIDRequired		= 1 
						SET @VendorEventID		= 'E' + LTRIM(RTRIM(CAST(@PK_Event AS VARCHAR(10))))
					END
					
					IF @RFID = 'HLF'
					BEGIN							
						SET @RFID_dllFileName  	= 'HLF_RFID'
						SET @RFID_dllNamespace 	= 'HLFTag'
					END

					IF @RFID = 'ITN'
					BEGIN
						SET @IsBadgePrinting = 1
						SET @RFID_dllFileName  	= 'bcardCLSK'
						SET @RFID_dllNamespace 	= 'NFCtag'
					END
				END

				/* INSERT THE RECORD INTO THE MAIN Event TABLE */
				BEGIN

					IF NOT EXISTS (SELECT PK_Event FROM dbo.[Event] WITH (NOLOCK) WHERE PK_Event = @PK_Event)
					BEGIN

						SET IDENTITY_INSERT dbo.[Event] ON

						INSERT INTO dbo.[Event](
						PK_Event,
						CreatedDateUTC, 
						CreatedBy, 
						ModifiedDateUTC,
						ModifiedBy,
						IsTicketPurchaseRequired, 
						IsPreRegistrationRequired, 
						CanAssignTickets, 
						CanPurchaseTicketOnline, 
						IsRFIDRequired, 
						CanRegisterOnline, 
						IsHotelEnabled, 
						CanShowCurrentQualOnline, 
						IsRecordLocked, 
						MaxNoOfGuest, 
						MaxNoOfPrimaryGuest, 
						MaxCapacity, 
						ExpectedCapacity, 
						EventNamePositionID, 
						EventTimeZone, 
						PK_EventType, 
						PK_OldEventApp, 
						EventName, 
						dStartUTC, 
						dEndUTC, 
						StoredProcedure, 
						[Location], 
						LocalName,
						IsPromotion,
						VendorEventID,
						IsInventoryEnabled,
						IsTrackLogoAvail,
						EventImageURL,
						EventDesc,
						IsQualifytoPurchaseTickets,
						EventZipCode,
						QualPeriodStart,
						QualPeriodEnd,
						IsDisplayEvent,
						IsRecurring,
						EventVenueName,
						EventAddress,
						EventCity,
						EventState,
						DisplayStartDate,
						DisplayEndDate,
						IsActive,
						MakePublic,
						EventCostDetails,
						EventApprovalStatus,
						PK_DefaultLocale,
						IsPublish,
						CanDisplayQualPeriod,
						IsPublishQualTracking,
						IsBizworkReportEnabled,
						IsCustomTrackingSiteAvailable,
						CustomTrackingSiteSPName,
						IsBadgePrinting
						)
					SELECT
						PK_Event						= @PK_Event,
						CreatedDateUTC					= GETUTCDATE(),
						CreatedBy						= @UserName,
						ModifiedDateUTC					= GETUTCDATE(),
						ModifiedBy						= @UserName,
						IsTicketPurchaseRequired		= @IsTicketPurchaseRequired,
						IsPreRegistrationRequired		= @IsPreRegistrationRequired,
						CanAssignTickets				= @CanAssignTickets,
						CanPurchaseTicketOnline			= @CanPurchaseTicketOnline,
						IsRFIDRequired					= @IsRFIDRequired,
						CanRegisterOnline				= @CanRegisterOnline,
						IsHotelEnabled					= @IsHotelEnabled,
						CanShowCurrentQualOnline		= @CanShowCurrentQualOnline,
						IsRecordLocked					= @IsRecordLocked,
						MaxNoOfGuest					= @MaxNoOfGuest,
						MaxNoOfPrimaryGuest				= @MaxNoOfPrimaryGuest,
						MaxCapacity						= @MaxCapacity,
						ExpectedCapacity				= @ExpectedCapacity,
						EventNamePositionID				= @EventNamePositionID,
						EventTimeZone					= @EventTimeZone,
						PK_EventType					= @PK_EventType,
						PK_OldEventApp					= @PK_OldEventApp,
						EventName						= @EventName,
						dStartUTC						= @StartUTC,
						dEndUTC							= @EndUTC,
						StoredProcedure					= @StoredProcedureName,
						[Location]						= @Location,
						LocalName						= @LocalName,
						IsPromotion						= @IsPromotion,
						VendorEventID					= @VendorEventID,
						IsInventoryEnabled				= @IsInventoryEnabled,
						IsTrackLogoAvail				= @IsTrackLogoAvail,
						EventImageURL					= @EventImageURL,
						EventDesc						= CAST(@ProjectID AS VARCHAR(10)) + ' - ' + @EventName ,
						IsQualifytoPurchaseTickets		= @IsQualifytoPurchaseTickets,
						EventZipCode					= @EventZipCode,
						QualPeriodStart					= @QualPeriodStart,
						QualPeriodEnd					= @QualPeriodEnd,
						IsDisplayEvent					= @IsDisplayEvent,
						IsRecurring						= @IsRecurring,
						EventVenueName					= @Location,
						EventAddress					= @Location,
						EventCity						= @EventCity,
						EventState						= @EventState,
						DisplayStartDate				= @DisplayStartDate,
						DisplayEndDate					= @DisplayEndDate,
						IsActive						= @IsActive,
						MakePublic						= @MakePublic,
						EventCostDetails				= @EventCostDetails,
						EventApprovalStatus				= @EventApprovalStatus,
						PK_DefaultLocale				= @PK_DefaultLocale,
						IsPublish						= @IsPublish,
						CanDisplayQualPeriod			= @CanDisplayQualPeriod,
						IsPublishQualTracking			= @IsPublishQualTracking,
						IsBizworkReportEnabled			= @IsBizworkReportEnabled,
						IsCustomTrackingSiteAvailable	= @IsCustomTrackingSiteAvailable,
						CustomTrackingSiteSPName		= @CustomTrackingSiteSPName,
						IsBadgePrinting					= @IsBadgePrinting

						SET IDENTITY_INSERT  dbo.[Event]  OFF 
					END
					ELSE
					BEGIN						
						IF (@IsPromotion IS NULL OR @IsPromotion = 0 )
						BEGIN
							UPDATE dbo.[Event]
							SET 
								ModifiedDateUTC					= GETUTCDATE(),
								ModifiedBy						= @UserName,
								IsTicketPurchaseRequired		= @IsTicketPurchaseRequired,
								IsPreRegistrationRequired		= @IsPreRegistrationRequired,
								CanAssignTickets				= @CanAssignTickets,
								CanPurchaseTicketOnline			= @CanPurchaseTicketOnline,
								IsRFIDRequired					= @IsRFIDRequired,
								CanRegisterOnline				= @CanRegisterOnline,
								IsHotelEnabled					= @IsHotelEnabled,
								CanShowCurrentQualOnline		= @CanShowCurrentQualOnline,
								IsRecordLocked					= @IsRecordLocked,
								MaxNoOfGuest					= @MaxNoOfGuest,
								MaxNoOfPrimaryGuest				= @MaxNoOfPrimaryGuest,
								MaxCapacity						= @MaxCapacity,
								ExpectedCapacity				= @ExpectedCapacity,
								EventNamePositionID				= @EventNamePositionID,
								EventTimeZone					= @EventTimeZone,
								PK_EventType					= @PK_EventType,
								PK_OldEventApp					= @PK_OldEventApp,
								EventName						= @EventName,
								dStartUTC						= @StartUTC,
								dEndUTC							= @EndUTC,
								StoredProcedure					= @StoredProcedureName,
								[Location]						= @Location,
								LocalName						= @LocalName,
								IsPromotion						= @IsPromotion,
								VendorEventID					= @VendorEventID,
								IsInventoryEnabled				= @IsInventoryEnabled,
								IsTrackLogoAvail				= @IsTrackLogoAvail,
								EventImageURL					= @EventImageURL,
								EventDesc						= CAST(@ProjectID AS VARCHAR(10)) + ' - ' + @EventName ,
								IsQualifytoPurchaseTickets		= @IsQualifytoPurchaseTickets,
								EventZipCode					= @EventZipCode,
								QualPeriodStart					= @QualPeriodStart,
								QualPeriodEnd					= @QualPeriodEnd,
								IsDisplayEvent					= @IsDisplayEvent,
								IsRecurring						= @IsRecurring,
								EventVenueName					= @Location,
								EventAddress					= @Location,
								EventCity						= @EventCity,
								EventState						= @EventState,
								DisplayStartDate				= @DisplayStartDate,
								DisplayEndDate					= @DisplayEndDate,
								IsActive						= @IsActive,
								MakePublic						= @MakePublic,
								EventCostDetails				= @EventCostDetails,
								EventApprovalStatus				= @EventApprovalStatus,
								PK_DefaultLocale				= @PK_DefaultLocale,
								CanDisplayQualPeriod			= @CanDisplayQualPeriod,
								IsPublishQualTracking			= @IsPublishQualTracking,
								IsBizworkReportEnabled			= @IsBizworkReportEnabled,
								IsCustomTrackingSiteAvailable	= @IsCustomTrackingSiteAvailable,
								CustomTrackingSiteSPName		= @CustomTrackingSiteSPName,
								IsBadgePrinting					= @IsBadgePrinting
							WHERE PK_Event = @PK_Event
						END
					END

				END
		
				/* INSERT THE RECORD INTO EventEventSubType TABLE */
				BEGIN
					IF (@IsPromotion IS NULL OR @IsPromotion = 0 )
					BEGIN
						INSERT INTO dbo.EventEventSubType (PK_Event, PK_EventType, PK_EventSubType,CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy) 
						SELECT
							PK_Event		= @PK_Event,
							PK_EventType	= 1,
							PK_EventSubType	= @PK_EventSubType,
							CreatedDateUTC	= GETUTCDATE(),
							CreatedBy		= @UserName,
							ModifiedDateUTC	= GETUTCDATE(),
							ModifiedBy		= @UserName
						WHERE NOT EXISTS (SELECT 1 FROM dbo.EventEventSubType WITH (NOLOCK) WHERE PK_Event = @PK_Event) 
					END
				END

				/* INSERT RECORDS INTO EventCountry TABLE */
				BEGIN

					INSERT INTO dbo.EventCountry(CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_Event, PK_Country)
					SELECT
						CreatedDateUTC	= GETUTCDATE(),
						CreatedBy		= @UserName,
						ModifiedDateUTC	= GETUTCDATE(),
						ModifiedBy		= @UserName,
						PK_Event		= @PK_Event,
						PK_Country		= STUFF((SELECT ',' + CONVERT(VARCHAR,nCountryID) FROM dbo.v_Countries 
						WHERE sCountryCode= @CountryCode FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'), 1, 1, '')
					WHERE NOT EXISTS (SELECT 1 FROM dbo.EventCountry WITH (NOLOCK) WHERE PK_Event = @PK_Event)
				END

				/* INSERT RECORDS INTO EventDistributorCountry COUNTRY TABLE */
				BEGIN

					MERGE  
					 EventDistributorCountry AS [target]
					USING @EventCountries AS [source]  
					ON ([target].PK_Event = [source].PK_Event AND [target].PK_Country = [source].PK_Country)
					WHEN NOT MATCHED THEN
						INSERT (CreatedDateUTC,CreatedBy,ModifiedDateUTC,ModifiedBy,PK_Event,PK_Country) 
						VALUES (GETUTCDATE(),@UserName,GETUTCDATE(),@UserName,[source].PK_Event,[source].PK_Country);

				END

				/* INSERT RECORDS INTO EventDistributorCountryLocales TABLE */
				BEGIN

					MERGE  
					 EventDistributorCountryLocales AS [target]
					USING ( SELECT L.PK_Locale, C.PK_Event
								FROM dbo.Locales L WITH (NOLOCK) 
									INNER JOIN @EventCountries C 
										ON	SUBSTRING(L.LocaleCode,4,6) = C.CountryCode
						  ) AS [source]  
					ON ([target].PK_Event = [source].PK_Event 
							AND [target].PK_Locale = [source].PK_Locale)
					WHEN NOT MATCHED THEN
						INSERT (CreatedDateUTC,CreatedBy,ModifiedDateUTC,ModifiedBy,PK_Event,PK_Locale,IsDefault) 
						VALUES (GETUTCDATE(),@UserName,GETUTCDATE(),@UserName,[source].PK_Event,[source].PK_Locale,1);
		
				END

				/* INSERT RECORD INTO THE TABLE EventDSTeamType TABLE */
				BEGIN

					IF (@IsPromotion IS NULL OR @IsPromotion = 0 )
					BEGIN
						INSERT INTO	dbo.EventDSTeamType(DSTeamTypeCode,PK_Event,CreatedDateUTC,CreatedBy,ModifiedDateUTC,ModifiedBy) 
						SELECT
							DSTeamTypeCode = DSTeamTypeCode,
							PK_Event = @PK_Event,
							CreatedDateUTC = GETUTCDATE(),
							CreatedBy = @UserName,
							ModifiedDateUTC = GETUTCDATE(),
							ModifiedBy = @UserName
						FROM dbo.DSTeamType WITH (NOLOCK)
						WHERE Teamorder <= CASE @DSTeam WHEN 'FQS' THEN 18 
														WHEN 'ALL' THEN 19 
											END
						AND NOT EXISTS (SELECT 1 FROM dbo.EventDSTeamType WITH (NOLOCK) WHERE PK_Event = @PK_Event)
					END
				END

				/* INSERT RECORD INTO EventLocaleDesc TABLE FOR THE PK_EVENT */
				BEGIN

					IF NOT EXISTS (SELECT 1 FROM dbo.EventLocaleDesc WITH (NOLOCK) WHERE PK_Event = @PK_Event)
				BEGIN

					INSERT INTO	dbo.EventLocaleDesc(PK_Event,PK_EventType,PK_Locale,PK_DefaultLocale,PK_TeamSite,EventName,EventDesc,EventSummary,EventLocation,
					EventVenueName,EventAddress,EventCity,EventState,Keywords,EventCostDetails,EventDisplayAddress,EventTrainingLanguages,EventApprovalNotes,
					EventComments,EventRules,TeamSiteModifiedDate)
					SELECT
						PK_Event				= PK_Event,
						PK_EventType			= PK_EventType,
						PK_Locale				= PK_DefaultLocale,
						PK_DefaultLocale		= PK_DefaultLocale,
						PK_TeamSite				= NULL,
						EventName				= EventName,
						EventDesc				= EventDesc,
						EventSummary			= NULL,
						EventLocation			= [Location],
						EventVenueName			= EventVenueName,
						EventAddress			= EventAddress,
						EventCity				= EventCity,
						EventState				= EventState,
						Keywords				= NULL,
						EventCostDetails		= NULL,
						EventDisplayAddress		= EventAddress,
						EventTrainingLanguages	= NULL,
						EventApprovalNotes		= NULL,
						EventComments			= NULL,
						EventRules				= NULL,
						TeamSiteModifiedDate	= NULL
					FROM dbo.[Event] WITH (NOLOCK)
					WHERE PK_Event = @PK_Event

					END
			
				END

				/* INSERT RECORD INTO EventRFIDConfig TABLE FOR THE PK_EVENT */
				BEGIN

					IF NOT EXISTS (SELECT 1 FROM dbo.EventRFIDConfig WITH (NOLOCK) WHERE PK_Event = @PK_Event)
					BEGIN

						IF @IsRFIDRequired = 1
						INSERT INTO dbo.EventRFIDConfig(PK_Event,CreatedDate,CreatedBy,ModifiedDate,ModifiedBy,RFID_dllFileName,RFID_dllNamespace)
						SELECT
							PK_Event			= @PK_Event,
							CreatedDate			= GETUTCDATE(),
							CreatedBy			= @UserName,
							ModifiedDate		= GETUTCDATE(),
							ModifiedBy			= @UserName,
							RFID_dllFileName	= @RFID_dllFileName,
							RFID_dllNamespace	= @RFID_dllNamespace
					END
					ELSE BEGIN
					
						IF @IsRFIDRequired = 1
						BEGIN

							UPDATE EventRFIDConfig
							SET 
								PK_Event			= @PK_Event,
								CreatedDate			= GETUTCDATE(),
								CreatedBy			= @UserName,
								ModifiedDate		= GETUTCDATE(),
								ModifiedBy			= @UserName,
								RFID_dllFileName	= @RFID_dllFileName,
								RFID_dllNamespace	= @RFID_dllNamespace
							WHERE PK_Event = @PK_Event

						END
						ELSE
							DELETE dbo.EventRFIDConfig
							WHERE PK_Event= @PK_Event
						
					END
	
		
				END
			END
		
		END

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;
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
	END CATCH;
END