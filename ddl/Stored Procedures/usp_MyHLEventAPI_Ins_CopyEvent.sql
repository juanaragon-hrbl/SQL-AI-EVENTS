CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Ins_CopyEvent]
				  @PK_FromEvent INT
				 ,@PK_Event INT OUTPUT
				-- Error Parameters
				,@Error int = 0 OUTPUT
				,@ErrorMessage varchar(4000) = '' OUTPUT

				-- QA/DEV
				,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Ins_CopyEvent

USE:	         
				DECLARE @e int, @em varchar(4000), @EventID int
                EXEC usp_MyHLEventAPI_Ins_CopyEvent
				      @PK_FromEvent = 5442
				     ,@PK_Event = @EventID OUTPUT
					 ,@Error = @e OUTPUT  /* @e must be defined in the local call */
					 ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Copies the event record from one locale to various other locales

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
dbo.EventTicketAssignment

VERSIONS
--------------------------------------------------------------------
1.0	2011-01-04	Prabhu	   Intitial
2.0	2013-01-22	Sushma	   Changes made to accomodate table changes made on dbo.Event, dbo.EventGuestSpeakers, dbo.EventCoordinatorDetail, dbo.EventAudio
3.0	2013-07-03	Sushma	   Target Market CR Changes	
4.0	2019-08-14	NoeG		Refactor code (SRE)

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/*VARIABLE DECLARATION */
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

/* INSERT THE RECORD TO THE EVENT TABLE FROM THE SOURCE EVENT */
BEGIN TRY

	INSERT 
		dbo.Event
	(
		 [IsTicketPurchaseRequired]
		  ,[IsPreRegistrationRequired]
		  ,[CanAssignTickets]
		  ,[CanPurchaseTicketOnline]
		  ,[IsRFIDRequired]
		  ,[CanRegisterOnline]
		  ,[IsHotelEnabled]
		  ,[CanShowCurrentQualOnline]
		  ,[IsRecordLocked]
		  ,[MaxNoOfGuest]
		  ,[MaxNoOfPrimaryGuest]
		  ,[MaxCapacity]
		  ,[ExpectedCapacity]
		  ,[EventNamePositionID]
		  ,[EventTimeZone]
		  ,[ModifiedBy]
		  ,[PK_EventType]
		  ,[PK_OldEventApp]
		  ,[EventName]
		  --,[dStartUTC]
		  --,[dEndUTC]
		  ,[StoredProcedure]
		  ,[Location]
		  ,[LocalName]
		  ,[IsPromotion]
		  ,[VendorEventID]
		  ,[IsInventoryEnabled]
		  ,[IsTrackLogoAvail]
		  ,[EventImageURL]
		  ,[EventDesc]
		  ,[IsQualifytoPurchaseTickets]
		  ,[EventZipCode]
		  --,[QualPeriodStart]
		 -- ,[QualPeriodEnd]
		  ,[IsDisplayEvent]
		  ,[EventVenueName]
		  ,[EventAddress]
		  ,[EventCity]
		  ,[EventState]
		  --,[DisplayStartDate]
		  --,[DisplayEndDate]
		  ,[IsActive]
		  ,[MakePublic]
		  ,[EventCostDetails]
		  ,[EventApprovalStatus]
		  ,[PK_DefaultLocale]
		  ,[IsPublish]
		  ,[CanDisplayQualPeriod]
		  ,[IsPublishQualTracking]
		  ,[CreatedDateUTC]
		  ,[ModifiedDateUTC]
		  ,[IsAlwaysVisible]
		  ,[IsSocialNetworkEnabled]
		  --,[IsDeleted]
		  ,[CreatedDistributorID]
		  ,[latitude]
		  ,[longitude]
	)
	SELECT
		 [IsTicketPurchaseRequired]
		  ,[IsPreRegistrationRequired]
		  ,[CanAssignTickets]
		  ,[CanPurchaseTicketOnline]
		  ,[IsRFIDRequired]
		  ,[CanRegisterOnline]
		  ,[IsHotelEnabled]
		  ,[CanShowCurrentQualOnline]
		  ,[IsRecordLocked]
		  ,[MaxNoOfGuest]
		  ,[MaxNoOfPrimaryGuest]
		  ,[MaxCapacity]
		  ,[ExpectedCapacity]
		  ,[EventNamePositionID]
		  ,[EventTimeZone]
		  ,[ModifiedBy]
		  ,[PK_EventType]
		  ,[PK_OldEventApp]
		  ,'COPY OF' + ' - ' + [EventName]
		  --,[dStartUTC]
		  --,[dEndUTC]
		  ,[StoredProcedure]
		  ,[Location]
		  ,[LocalName]
		  ,[IsPromotion]
		  ,[VendorEventID]
		  ,[IsInventoryEnabled]
		  ,[IsTrackLogoAvail]
		  ,[EventImageURL]
		  ,[EventDesc]
		  ,[IsQualifytoPurchaseTickets]
		  ,ISNULL([EventZipCode],'')
		 -- ,[QualPeriodStart]
		 --,[QualPeriodEnd]
		  ,[IsDisplayEvent]
		  ,[EventVenueName]
		  ,ISNULL([EventAddress],'')
		  ,ISNULL([EventCity],'')
		  ,ISNULL([EventState],'')
		  --,[DisplayStartDate]
		  --,[DisplayEndDate]
		  ,[IsActive]
		  ,[MakePublic]
		  ,[EventCostDetails]
		  ,CASE WHEN PK_EventType = 3 THEN 3 ELSE [EventApprovalStatus] END [EventApprovalStatus]
		  ,[PK_DefaultLocale]
		  ,0
		  ,[CanDisplayQualPeriod]
		  --,[IsPublishQualTracking]
		  ,0
		  ,GETUTCDATE()
		  ,GETUTCDATE()
		  ,[IsAlwaysVisible]
		  ,[IsSocialNetworkEnabled]
		  --,[IsDeleted]
		  ,[CreatedDistributorID]
		  ,[latitude]
		  ,[longitude]
	FROM
		dbo.Event WITH (NOLOCK) 
	WHERE
		PK_Event = @PK_FromEvent
	
	SET @PK_Event = SCOPE_IDENTITY()

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

/* INSERT THE RECORD INTO EVENTLOCALEDESC TABLE */
BEGIN TRY
	INSERT 
		dbo.EventLocaleDesc
	(
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
		  ,[CreatedDateUTC]
		  ,[ModifiedDateUTC]
		  ,[ParticipatingCountries]
	)
	SELECT
		   @PK_Event
		  ,[PK_EventType]
		  ,[PK_Locale]
		  ,[PK_DefaultLocale]
		  ,[PK_TeamSite]
		  ,'COPY OF' + ' - ' + [EventName]
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
		  ,NULL
		  ,NULL
		  ,[EventRules]
		  ,[TeamSiteModifiedDate]
		  ,GETUTCDATE()
		  ,GETUTCDATE()
		  ,[ParticipatingCountries]
	FROM
		dbo.EventLocaleDesc WITH (NOLOCK) 
	WHERE
		PK_Event = @PK_FromEvent	

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


/* INSERT RECORDS INTO EVENT COUNTRY TABLE */
BEGIN TRY
	INSERT
		dbo.EventCountry
	(
		 [CreatedDateUTC]
		,[CreatedBy]
		,[ModifiedDateUTC]
		,[ModifiedBy]
		,[PK_Event]
		,[PK_Country]
	)
	SELECT
		 GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_Event
		,PK_Country
	FROM
		dbo.EventCountry WITH (NOLOCK) 
	WHERE
		PK_Event = @PK_FromEvent

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

/* INSERT RECORDS INTO EVENT DISTRIBUTOR COUNTRY TABLE */
BEGIN TRY
	INSERT
		dbo.EventDistributorCountry
	(
		 [CreatedDateUTC]
		,[CreatedBy]
		,[ModifiedDateUTC]
		,[ModifiedBy]
		,[PK_Event]
		,[PK_Country]
	)
	SELECT
		 GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_Event
		,PK_Country
	FROM
		dbo.EventDistributorCountry WITH (NOLOCK) 
	WHERE
		PK_Event = @PK_FromEvent

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

/*
/* INSERT THE RECORD INTO SUBEVENT TABLE */
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
)
SELECT
	 @PK_Event
	,PK_SubEventType
	,MaxCapacity
	,ExpectedCapacity
	,SubEventName
	,SubeventNumber
FROM
	dbo.SubEvent
WHERE
	PK_Event = @PK_FromEvent
	
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

/* INSERT THE RECORD INTO SUBEVENTLOCALEDESC TABLE */
BEGIN TRY
INSERT 
	dbo.SubEventLocaleDesc
(
	 [PK_Subevent]
	,[PK_Event]
	,[PK_Locale]
	,[PK_DefaultLocale]
	,[SubEventName]
	,[SubEventQualDesc]
)
SELECT
	 B.PK_Subevent
	,@PK_Event
	,[PK_Locale]
	,[PK_DefaultLocale]
	,[SubEventName]
	,[SubEventQualDesc]
FROM
	dbo.SubEventLocaleDesc SEL
INNER JOIN
	(SELECT
		 PK_Subevent
		,PK_Event
		,SubEventNumber
	FROM 
		dbo.SubEvent	
	WHERE
		PK_Event = @PK_FromEvent
	)A
ON A.PK_Event = SEL.PK_Event
AND A.PK_SubEvent = SEL.PK_Subevent
INNER JOIN
	(SELECT
		 PK_Subevent
		,PK_Event
		,SubEventNumber
	FROM 
		dbo.SubEvent	
	WHERE
		PK_Event = @PK_Event
	)B
ON
	A.SubEventNumber = B.SubEventNumber
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
*/

/* INSERT INTO GUEST SPEAKERS TABLE */
BEGIN TRY 

	INSERT 
		dbo.EventGuestSpeakers
	  (
	   [EventSpeakerName]
	  ,[PK_Event]
	  ,[CreatedDateUTC]
	  ,[ModifiedDateUTC]
	  ,[EventSpeakerTitle]
	  ,EventSpeakerTeamLevel
	  )
	SELECT 
		EventSpeakerName
		,@PK_Event
		,GETUTCDATE()
		,GETUTCDATE()
		,[EventSpeakerTitle]
		,[EventSpeakerTeamLevel]
	FROM
		dbo.EventGuestSpeakers WITH (NOLOCK) 
	WHERE
		PK_Event = @PK_FromEvent

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

/* INSERT INTO EVENTURL TABLE */
BEGIN TRY
	INSERT 
		dbo.EventURL
	(
		 PK_Event
		,PK_Locale
		,EventURL
		,EventURLDesc
		,CreatedDateUTC
		,ModifieddateUTC
		,PK_EventURLType
	)
	SELECT
		 @PK_Event
		,PK_Locale
		,EventURL
		,EventURLDesc
		,GETUTCDATE()
		,GETUTCDATE()
		,PK_EventURLType
	FROM
		dbo.EventURL WITH (NOLOCK) 
	WHERE
		PK_Event = @PK_FromEvent

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

/* INSERT INTO THE EVENTIMAGE TABLE */
BEGIN TRY

	INSERT 
		[dbo].[EventImage]
		(
		 [EventImageLocation]
		,[PK_Event]
		,[PK_EventImageType]
		,[CreatedDateUTC]
		,[ModifieddateUTC]
		 )
	SELECT
		EventImageLocation
		,@PK_Event
		,PK_EventImageType
		,GETUTCDATE()
		,GETUTCDATE()
	FROM
		dbo.EventImage WITH (NOLOCK) 
	WHERE
		PK_Event = @PK_FromEvent
     
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

BEGIN TRY
	INSERT 
		dbo.EventCoordinatorDetail
	(
		 [PK_Event]
		,[CreatedDistributorID]
		,[Coordinatorname]
		,[CoordinatorPhone]
		,[CoordinatorEmail]
		,[CreatedDateUTC]
		,[ModifieddateUTC]
		,[CoordinatorTitle]
	)
	SELECT
		 @PK_Event
		,CreatedDistributorID
		,CoordinatorName
		,CoordinatorPhone
		,CoordinatorEmail
		,GETUTCDATE()
		,GETUTCDATE()
		,[CoordinatorTitle]
	FROM
		dbo.EventCoordinatorDetail WITH (NOLOCK) 
	WHERE
		PK_Event = @PK_FromEvent
	
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

/* COPY ALL THE DS TEAM TYPES FOR THE EVENT TO THE NEW EVENT */
BEGIN TRY
	INSERT 
		dbo.EventDSTeamType
	(

		 [DSTeamTypeCode]
		,[PK_Event]
		,[CreatedDateUTC]
		,[CreatedBy]
		,[ModifieddateUTC]
		,[ModifiedBy]
	)
	SELECT
		 DSTeamTypeCode
		,@PK_Event
		,GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
	FROM
		dbo.EventDSTeamType WITH (NOLOCK) 
	WHERE
		PK_Event = @PK_FromEvent
	
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

/* COPY ALL THE DS TEAM TYPES FOR THE EVENT TO THE NEW EVENT */
BEGIN TRY
	INSERT 
		dbo.EventEventSubType
	(
		 [PK_Event]
		,[PK_EventType]
		,[PK_EventSubType]
		,[CreatedDateUTC]
		,[CreatedBy]
		,[ModifiedDateUTC]
		,[ModifiedBy]

	)
	SELECT
		 @PK_Event
		,PK_EventType
		,PK_EventSubType
		,GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
	FROM
		dbo.EventEventSubType WITH (NOLOCK) 
	WHERE
		PK_Event = @PK_FromEvent
	
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

/* COPY ALL THE AUDIO FILES FOR THE EVENT TO THE NEW EVENT */
BEGIN TRY
	INSERT 
		dbo.EventAudio
	(
		 PK_Event
		,AudioName
		,AudioDesc
		,AudioHTML
		,CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_MediaType
	)
	SELECT
		 @PK_Event
		,AudioName
		,AudioDesc
		,AudioHTML
		,CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_MediaType
	FROM
		dbo.EventAudio WITH (NOLOCK) 
	WHERE
		PK_Event = @PK_FromEvent
	
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

/* COPY ALL THE TARGET MARKETS FOR THE EVENT TO THE NEW EVENT */
BEGIN TRY
	INSERT 
		dbo.EventDistributorCountryLocales
	(
		 PK_Event
		,PK_Locale
		,IsDefault
		,CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
	)
	SELECT
		 @PK_Event
		,PK_Locale
		,IsDefault
		,CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
	FROM
		dbo.EventDistributorCountryLocales WITH (NOLOCK) 
	WHERE
		PK_Event = @PK_FromEvent
	AND
	NOT EXISTS(SELECT PK_Locale FROM dbo.EventDistributorCountryLocales E WITH (NOLOCK) WHERE E.PK_Event = @PK_Event)
	
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

-- UPDATE PROCESSING LOG
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
GO

