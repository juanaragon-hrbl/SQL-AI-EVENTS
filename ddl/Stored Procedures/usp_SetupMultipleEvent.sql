CREATE PROCEDURE [dbo].[usp_SetupMultipleEvent]
	 @Events						dbo.udt_Setup_EventGeneral	READONLY		
	,@EventSKU_Items				dbo.udt_Setup_EventSKU		READONLY	
	,@SubEvent_Items				dbo.udt_Setup_SubEvent		READONLY	
	,@MainEvent						VARCHAR(200)		
	
	-- Error Parameters
	,@Error	int OUTPUT
	,@ErrorMessage varchar(4000) OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_SetupEvent]
		
	USE:						

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2019-06-18		alejandramed		Initial
	1.0.1		2019-12-12		alejandramed		Including step to insert fresh entries into the SubEventLocaleDesc table
	1.0.2		2019-12-16		alejandramed		Including GTA, if @CanAssignTickets NULL set 0 as default value, if GTA is required @CanAssignTickets must be sent
	
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

/* VARIABLE DECLARATION */
BEGIN

	DECLARE  @UserName						VARCHAR(20)	
			,@PK_Event						INT
			,@ProjectID						INT	
			,@RFID							VARCHAR(3)
			,@CountryCode					VARCHAR(5)
			,@PK_Country					INT
			,@RegionCode					VARCHAR(20)
			,@CountryList					VARCHAR(500)
			,@Location						VARCHAR(300)
			,@EventTimeZone					DECIMAL(5,2)
			,@EventType						VARCHAR(25)
			,@SubEventType					VARCHAR(50)
			,@EventName						VARCHAR(100)
			,@StartUTC						DATETIME
			,@EndUTC						DATETIME
			,@QualPeriodStart				DATETIME
			,@QualPeriodEnd					DATETIME
			,@DisplayStartDate				DATETIME
			,@DisplayEndDate				DATETIME
			,@IsCustomTrackingSiteAvailable	BIT
			,@CustomTrackingSiteSPName		VARCHAR(300)
			,@PK_DefaultLocale				INT
			,@CanAssignTickets				BIT
END

IF OBJECT_ID('tempdb..#EventsProcessing') IS NOT NULL DROP TABLE #EventsProcessing
IF OBJECT_ID('tempdb..#Errors') IS NOT NULL DROP TABLE #Errors

CREATE TABLE #EventsProcessing
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	[PK_Event] INT,
	[Processed] BIT NULL DEFAULT (0)
)

CREATE TABLE #Errors
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	PK_Event INT,
	Error INT DEFAULT 0,
	ErrorMessage VARCHAR(4000)
)

BEGIN TRY

INSERT INTO #EventsProcessing ([PK_Event])
SELECT [PK_Event] FROM @Events

WHILE EXISTS (SELECT 1 FROM #EventsProcessing WHERE [Processed] = 0)
BEGIN

	/* Getting general information */
	BEGIN
	
		SELECT	TOP 1
				
					 @UserName						= [CreatedBy]
					,@PK_Event						= E.[PK_Event]
					,@ProjectID						= [ProjectID]
					,@RFID							= [RFID]
					,@CountryCode					= [CountryCode]
					,@PK_Country					= [PK_Country]
					,@RegionCode					= [RegionCode]
					,@CountryList					= [CountryList]
					,@Location						= [Location]
					,@EventTimeZone					= [EventTimeZone]
					,@EventType						= [EventType]
					,@SubEventType					= [SubEventType] 
					,@EventName						= [EventName]
					,@StartUTC						= [StartUTC]
					,@EndUTC						= [EndUTC]
					,@QualPeriodStart				= [QualPeriodStart]
					,@QualPeriodEnd					= [QualPeriodEnd]
					,@DisplayStartDate				= [DisplayStartDate]
					,@DisplayEndDate				= [DisplayEndDate]
					,@IsCustomTrackingSiteAvailable = [IsCustomTrackingSiteAvailable]
					,@CustomTrackingSiteSPName		= [CustomTrackingSiteSPName]
					,@CanAssignTickets				= [CanAssignTickets]
				FROM @Events E
				INNER JOIN #EventsProcessing EP
					ON E.PK_Event = EP.PK_Event
				WHERE EP.[Processed] = 0
				ORDER BY E.PK_Event DESC	
	END

	/* CALLING usp_SetEventHeader */
	BEGIN

		SET @CanAssignTickets = CASE WHEN @CanAssignTickets IS NULL THEN 0 ELSE @CanAssignTickets END

		EXEC dbo.usp_SetEventHeader
		 @UserName
		,@PK_Event
		,@ProjectID
		,@RFID
		,@CountryCode
		,@RegionCode
		,@CountryList
		,@Location
		,@EventTimeZone
		,@EventType
		,@SubEventType
		,@EventName
		,@StartUTC
		,@EndUTC
		,@QualPeriodStart
		,@QualPeriodEnd
		,@DisplayStartDate
		,@DisplayEndDate
		,@IsCustomTrackingSiteAvailable = @IsCustomTrackingSiteAvailable
		,@CustomTrackingSiteSPName = @CustomTrackingSiteSPName
		,@CanAssignTickets = @CanAssignTickets
		,@Error = @Error OUTPUT
		,@ErrorMessage = @ErrorMessage OUTPUT
		,@IsDevQA = 0

		INSERT INTO #Errors (PK_Event,Error,ErrorMessage)
		VALUES (@PK_Event,@Error,@ErrorMessage)

	END
	

	IF NOT EXISTS (SELECT 1 FROM #Errors WHERE Error != 0 )
	BEGIN
		/* CALLING usp_UpdateSchedule */
		BEGIN

			IF(@Error = 0)
				EXEC dbo.usp_UpdateSchedule @PK_Event, @UserName
				,@Error = @Error OUTPUT
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@IsDevQA = 0

		END

		/* CALLING usp_EventAPI_Ins_Eventusers  */
		BEGIN

			IF(@Error = 0)
				EXEC dbo.usp_EventAPI_Ins_Eventusers @PK_Event

		END
	END

	UPDATE #EventsProcessing
	SET [Processed] = 1
	WHERE PK_Event = @PK_Event

END

	IF NOT EXISTS (SELECT 1 FROM #Errors WHERE Error != 0 )
	BEGIN

		/* CALLING usp_SetEventSKU */
		BEGIN

			IF EXISTS ( SELECT 1 FROM @EventSKU_Items)
			BEGIN

				EXEC dbo.usp_SetEventSKU 
					 @EventSKU_Items 
					,@Error = @Error OUTPUT
					,@ErrorMessage = @ErrorMessage OUTPUT
					,@IsDevQA = 0
			END

		END

		/* CALLING usp_SetSubEvent */
		IF(@Error = 0)
		BEGIN
					
			BEGIN

				EXEC dbo.usp_SetSubEvent 
				@SubEvent_Items
				,@Error = @Error OUTPUT
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@IsDevQA = 0
			END	
		END

		/* INSERT FRESH ENTRIES INTO THE SUBEVENTLOCALEDESC TABLE */
		IF(@Error = 0)
		BEGIN
			UPDATE #EventsProcessing
			SET [Processed] = 0
		
			WHILE EXISTS (SELECT 1 FROM #EventsProcessing WHERE [Processed] = 0)
			BEGIN

				SELECT	TOP 1
					 @PK_Event						= E.[PK_Event]
					,@PK_DefaultLocale				= E.[PK_DefaultLocale]
				FROM dbo.[Event] E
				INNER JOIN #EventsProcessing EP
					ON E.PK_Event = EP.PK_Event
				WHERE EP.[Processed] = 0
				ORDER BY E.PK_Event DESC	
						
			SELECT @PK_DefaultLocale = PK_DefaultLocale FROM dbo.[Event] (NOLOCK) WHERE PK_Event = @PK_Event
		
			IF NOT EXISTS (SELECT  1
			FROM dbo.SubEventLocaleDesc (NOLOCK)
			WHERE PK_Event = @PK_Event)
			BEGIN
				INSERT INTO dbo.SubEventLocaleDesc (PK_SubEvent, PK_Event, PK_Locale, PK_DefaultLocale, SubEventName, SubEventQualDesc, CreatedDateUTC, CreatedBy,
					ModifiedDateUTC, ModifiedBy, PK_TeamSite, TeamSiteModifiedDate)
				SELECT
					PK_SubEvent, PK_Event, @PK_DefaultLocale, @PK_DefaultLocale, SubEventName, SubEventName, CreatedDateUTC, CreatedBy, CreatedDateUTC, CreatedBy,NULL,NULL
				FROM dbo.SubEvent (NOLOCK)
				WHERE PK_Event = @PK_Event	
			END

			UPDATE #EventsProcessing
			SET [Processed] = 1
			WHERE PK_Event = @PK_Event

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
END;