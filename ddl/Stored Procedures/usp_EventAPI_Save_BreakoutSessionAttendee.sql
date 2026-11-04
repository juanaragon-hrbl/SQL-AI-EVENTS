CREATE PROCEDURE [dbo].[usp_EventAPI_Save_BreakoutSessionAttendee]

		@EventID INT 
		,@SessionID INT 
		,@DistributorID VARCHAR(20) 

		-- Optional Parameters
		,@RegisterOwner BIT = NULL
		,@RegisterPartner BIT = NULL
		,@PreferredLanguage varchar(5) = NULL

		-- Output Values
		,@AvailablePlaces INT OUTPUT

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_EventAPI_Save_BreakoutSessionAttendee]
	
	USE:			
			DECLARE @e int, @em varchar(4000), @ap int = 0

			EXEC [dbo].[usp_EventAPI_Save_BreakoutSessionAttendee]
				 @EventID =	63002		
				,@SessionID = 24882
				,@DistributorID = 'C100023219'
				,@RegisterOwner = 1 
				,@RegisterPartner = NULL
				,@PreferredLanguage = NULL
				,@Error = @e output
				,@ErrorMessage = @em output
				,@AvailablePlaces = @ap output
				,@IsDevQA = 1
			SELECT @e AS [Error], @em AS [ErrorMessage], @ap [AvailablePlaces]

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2018-05-22		OrlandoL		Initial
	1.0.1		2019-01-08		OrlandoL,NoeG	Changes to manage:
													- Owner and Partner registration
													- Available Places validation
													- Code Errors to return
														50001: Session is full
														50002: Owner is already registered
														50003: Partner is already registered
	1.0.2		2019-01-09		NoeG			Changes to manage:
													- Optional parameters to allow Registration Insert and Delete
														@RegisterOwner: null (No change), 0 (Delete), 1 (Insert) 
														@RegisterPartner: null (No change), 0 (Delete), 1 (Insert)
													- Transaction implemented
													- Session concurrency validation. Code errors to return
														50004: DS session overlap
														50005: Partner session schedule overlaps 
	1.0.3		2019-01-11		NoeG			Change to manage:
													- DS Qualification Evaluation. Code errors to return
														50007: DS Not qualified 
													- RegistrationDeadlineDate Validation. Code errors to return
														50006: Session deadline 
	1.0.4		2019-01-16		NoeG			Change to manage:
													- Transaction implementation removed
	1.0.5		2019-01-17		NoeG			Change to manage:
													- Partner Registration validation. Code error to return
														50008: Partner Registration not allowed
	1.0.6		2019-01-22		NoeG			PreferredLanguage parameter added
	1.0.7		2019-01-28		NoeG			Changes to manage the Qualification Override
	1.0.8		2019-09-05		NoeG			SRE template applied
	1.0.9		2019-11-04		NoeG			SRE Hardcode changed
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'

	DECLARE @MaxCapacity INT
			, @TotalRegistered INT
			, @TotalToRegister INT
			, @AllowPartnerRegistration BIT

	/* Get Default Locale for @PreferredLanguage in case of Null value */
	DECLARE @DefaultLocale varchar(5);

	SELECT @DefaultLocale = (SELECT LocaleCode
							FROM	[Event] e WITH (NOLOCK)
									INNER JOIN [Locales] l WITH (NOLOCK)
										on e.PK_DefaultLocale = l.PK_Locale 
							WHERE	[PK_Event] = @EventID	
							)
        
    SELECT @PreferredLanguage = ISNULL(@PreferredLanguage, @DefaultLocale);


	/* local variables defined to validate the Session Overlapping*/
	DECLARE @BeginTime DATETIME 
	DECLARE @EndTime DATETIME

	/* Local variable defined to validate the DS qualification */
	DECLARE @SubEventsNotQualifiedCounter INT
	DECLARE @Override_IsQualified bit

	/* Local variable to validate the Registration Deadline Date */
	DECLARE @RegistrationDeadlineSeconds BIGINT

	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		SELECT	@MaxCapacity = MaxCapacity, @AllowPartnerRegistration = isnull(sevx.AllowPartnerRegistration,0) 
		FROM	dbo.SubEvent se WITH (NOLOCK)
				left join dbo.subEventExtn sevx WITH (NOLOCK)
					on se.PK_SubEvent = sevx.PK_SubEvent
		WHERE	se.PK_Event = @EventID AND se.PK_SubEvent = @SessionID AND se.PK_SubEventType = 5

		SELECT @TotalRegistered = COUNT(1) FROM [BreakoutSessionAttendees] WITH (NOLOCK) WHERE PK_Event = @EventID AND PK_SubEvent = @SessionID

		SELECT @TotalToRegister = isnull(cast(@RegisterOwner as int),0) + isnull(cast(@RegisterPartner as int),0)

		SELECT @AvailablePlaces = @MaxCapacity - @TotalRegistered

		IF @IsDevQA = 1 
			SELECT @PreferredLanguage PreferredLanguage, @MaxCapacity MaxCapacity, @TotalRegistered TotalRegistered, @TotalToRegister TotalToRegister, @AvailablePlaces [AvailablePlacesBeforeRegister]

		/* Deadline date validation */
		SELECT	@RegistrationDeadlineSeconds = Datediff(SECOND,GETUTCDATE(), isnull(se.RegistrationDeadlineDate, ev.dStartUTC))
		FROM	dbo.[Event] ev WITH (NOLOCK)
				LEFT JOIN dbo.[SubEventExtn] se WITH (NOLOCK)
					on ev.PK_Event = se.PK_Event
					and PK_SubEvent = @SessionID
		where ev.PK_Event = @EventID 

		IF @IsDevQA = 1 
			SELECT @RegistrationDeadlineSeconds RegistrationDeadlineSeconds

		IF @RegistrationDeadlineSeconds <= 0 
		BEGIN
			SET @Error = 50006
			RAISERROR('Session deadline', 16, 1);
			RETURN;
		END

		/* Max Capacity validation */

		IF @TotalRegistered + @TotalToRegister > @MaxCapacity
		BEGIN
			SET @Error = 50001
			RAISERROR('Session is full', 16, 1);
			RETURN;
		END

		/* Variables to determine Qualification Status */

		SELECT	@SubEventsNotQualifiedCounter = sum(case when isnull(SEQ.PK_SubEvent,0) = 0 then 1 else 0 end )  /* increment in 1 when for each session where DS is not qualified */
				, @Override_IsQualified = cast(max(cast (bsor.IsQualified as int)) as bit) 
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
		group by bse.BreakoutSession

		SELECT	@BeginTime = BeginTime, @EndTime = DATEADD(SECOND,-1,EndTime)
		FROM	SubEvent WITH (NOLOCK) 
		WHERE	PK_Event = @EventID and PK_SubEvent = @SessionID 

		IF @IsDevQA = 1 
			SELECT @SubEventsNotQualifiedCounter SubEventsNotQualifiedCounter, @Override_IsQualified Override_IsQualified, @BeginTime BeginTime, @EndTime EndTime;

		IF @RegisterOwner is not null		-- No change the Owner Registration
		BEGIN

			IF @RegisterOwner = 0			-- Delete Owner Registration
			BEGIN
				DELETE 
				FROM
					dbo.BreakoutSessionAttendees
				WHERE
					PK_SubEvent = @SessionID AND DistributorID = @DistributorID AND IsOwner = 1	
			END

			IF @RegisterOwner = 1			-- Insert Owner Registration
			BEGIN

				IF (@Override_IsQualified is null and @SubEventsNotQualifiedCounter > 0) OR @Override_IsQualified = 0
				BEGIN
					SET @Error = 50007
					RAISERROR('DS Not qualified', 16, 1);
					RETURN;
				END

				IF EXISTS (SELECT 1 FROM [dbo].[BreakoutSessionAttendees] WITH (NOLOCK) WHERE PK_SubEvent = @SessionID AND DistributorID = @DistributorID AND IsOwner = 1)
				BEGIN
					SET @Error = 50002
					RAISERROR('Owner is already registered', 16, 1);
					RETURN;
				END
				ELSE
				BEGIN
					IF EXISTS (SELECT 1 FROM	SubEvent SE WITH (NOLOCK) 
										inner join BreakoutSessionAttendees BS WITH (NOLOCK)
											on SE.PK_Event = BS.PK_Event 
												and SE.PK_SubEvent = BS.PK_SubEvent  
								WHERE	BS.DistributorID = @DistributorID
										and	(@BeginTime between SE.BeginTime and DATEADD(SECOND, -1, SE.EndTime)
											or @EndTime between SE.BeginTime and DATEADD(SECOND, -1, SE.EndTime)) 
										and BS.IsOwner = 1
								)
					BEGIN
						SET @Error = 50004
						RAISERROR('DS session overlap', 16, 1);
						RETURN;
					END
					ELSE
					BEGIN
						INSERT INTO dbo.BreakoutSessionAttendees
						(
							[PK_Event]
							,[PK_SubEvent]
							,[DistributorID]
							,[DistributorName]
							,[DistributorEmail]
							,[IsOwner]
							,[PreferredLanguage]
						)
						SELECT
							@EventID,
							@SessionID,
							sDistributorID,
							COALESCE(D.sFirstName,'') +' '+COALESCE(D.sLastName,''),
							sEmail,
							@RegisterOwner,
							@PreferredLanguage
						FROM
							dbo.v_Distributor D
						WHERE
							D.sDistributorID = @DistributorID	
					END
				END	
			END				
			
		END

		IF @RegisterPartner is not null		-- No change the Partner Registration
		BEGIN

			IF @RegisterPartner = 0			-- Delete Partner Registration
			BEGIN
				DELETE 
				FROM
					dbo.BreakoutSessionAttendees  
				WHERE
					PK_SubEvent = @SessionID AND DistributorID = @DistributorID AND IsOwner = 0	
			END

			IF @RegisterPartner = 1			-- Insert Partner Registration
			BEGIN

				IF @AllowPartnerRegistration = 0
				BEGIN
					SET @Error = 50008
					RAISERROR('Partner Registration not allowed', 16, 1);
					RETURN;
				END

				IF (@Override_IsQualified is null and @SubEventsNotQualifiedCounter > 0) OR @Override_IsQualified = 0
				BEGIN
					SET @Error = 50007
					RAISERROR('DS Not qualified', 16, 1);
					RETURN;
				END

				IF EXISTS (SELECT 1 FROM [dbo].[BreakoutSessionAttendees] WITH (NOLOCK) WHERE PK_SubEvent = @SessionID AND DistributorID = @DistributorID AND IsOwner = 0)
				BEGIN
					SET @Error = 50003
					RAISERROR('Partner is already registered', 16, 1);
					RETURN;
				END
				ELSE
				BEGIN
					IF EXISTS (SELECT 1
								FROM	SubEvent SE WITH (NOLOCK) 
										inner join BreakoutSessionAttendees BS WITH (NOLOCK)
											on SE.PK_Event = BS.PK_Event 
												and SE.PK_SubEvent = BS.PK_SubEvent  
								WHERE	BS.DistributorID = @DistributorID
										and	(@BeginTime between SE.BeginTime and DATEADD(SECOND, -1, SE.EndTime)
											or @EndTime between SE.BeginTime and DATEADD(SECOND, -1, SE.EndTime)) 
										and BS.IsOwner = 0
								)
					BEGIN
						SET @Error = 50005
						RAISERROR('Partner session overlap', 16, 1);
						RETURN;
					END
					ELSE
					BEGIN
						INSERT INTO dbo.BreakoutSessionAttendees
						(
								[PK_Event]
							,[PK_SubEvent]
							,[DistributorID]
							,[DistributorName]
							,[DistributorEmail]
							,[IsOwner]
							,[PreferredLanguage]
						)
						SELECT
							@EventID,
							@SessionID,
							D.sDistributorID,
							COALESCE(sSpouseFirstName,'') +' '+ COALESCE(sSpouseLastName,''),
							'',
							0,
							@PreferredLanguage

						FROM
							dbo.[v_DistributorSpouse] D
						WHERE
							D.sDistributorID = @DistributorID			
					END
				END
			END
			
		END

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];
			
	-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;
	
	END TRY
	BEGIN CATCH
			
		SET @Error = case when @Error between 50001 and 50010 then @Error else ERROR_NUMBER() end
 		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message], @AvailablePlaces [AvailablePlaces];

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
GO

