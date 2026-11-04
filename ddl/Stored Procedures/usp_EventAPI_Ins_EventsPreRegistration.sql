CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_EventsPreRegistration]
    --Mandatory Parameter
	 @DistributorID VARCHAR(10)
	,@IsPartnerAttending INT
	,@PK_Event INT
	--Optional Parameters
	,@DSName nVARCHAR(40)= NULL
	,@PartnerName nVARCHAR(40) = NULL
	,@PartnerPreferredName nVARCHAR(40) = NULL
	,@PrimaryPhone nVARCHAR(100) = NULL
	,@MobilePhone nVARCHAR(100) = NULL
	,@EmailAddress nVARCHAR(100) = NULL
	,@Address nVARCHAR(200) = NULL
	,@Address2 nVARCHAR(200) = NULL
	,@Apartment nVARCHAR(10) = NULL
	,@City nVARCHAR(60) = NULL
	,@ZipCode nVARCHAR(60) = NULL
	,@State nVARCHAR(60) = NULL
	,@Country nVARCHAR(60) = NULL
	,@IsUsingVolume BIT = 0
	,@PK_PreferredLanguage INT = NULL
	,@PK_HotelInfo INT = NULL
	,@MemberCustomValue VARCHAR(100) = NULL
	,@PartnerCustomValue VARCHAR(100) = NULL
	,@IsMemberNotAttending BIT = 0

	-- Output Parameter
	,@ConfirmationNumber nVARCHAR(25) OUTPUT
	,@ConfirmationDate DATETIME OUTPUT
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
--
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Ins_EventsPreRegistration

USE:		

DECLARE @e int, @em varchar(max)

DECLARE @cm nVARCHAR(25)
DECLARE @cd DATETIME
DECLARE @IsDevQA int
EXEC dbo.usp_EventAPI_Ins_EventsPreRegistration
					@DistributorID = 'staff'
					,@DSName = 'Mark'
					,@IsPartnerAttending = 1
					,@PartnerName = 'Amy Hughes'
					,@PartnerPreferredName = 'Amy'
					,@PrimaryPhone = '310-410-9600'
					,@MobilePhone = '310-410-9600'
					,@EmailAddress = 'MarkH@herbalife.com'
					,@PK_Event = 4800
					,@IsMemberNotAttending = 0
					,@PK_PreferredLanguage = NULL
					--,@HotelName = ''
					,@PK_HotelInfo =283					
					,@ConfirmationNumber = @cm OUTPUT
					,@ConfirmationDate = @cd OUTPUT
					,@IsDevQA = 0
					,@Error = @e OUTPUT
					,@ErrorMessage = @em OUTPUT

					SELECT @e AS [Error], @em AS [Error Message],@CM, @CD

DESCRIPTION:	Inserts record into dbo.EventRegistration as PREREGISTRANTS

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventRegistration

VERSIONS
--------------------------------------------------------------------
1		2010-11-24		PRABHU				INITIAL
1.1		2013-02-10		Sushma				Added partnername/confirmation of registration outputnumber
1.2		2017-01-30		RogelioR			Parter can register without member attending
1.3		2019-05-10		alejandramed		Homologating of standard error handling
1.4		2019-07-15		alejandramed		Setting error parameters as optionals
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

		/******************************************************************************
			VARIABLE DECLARATION
		******************************************************************************/
		DECLARE @PK_Distributor INT
		DECLARE @FirstName VARCHAR(250)
		DECLARE @LastName VARCHAR(250)
		DECLARE @SpouseName VARCHAR(250)
		DECLARE @PK_EventsRegistration INT
		DECLARE @PK_EventHotel INT
		DECLARE @DSState nVARCHAR(10)
		DECLARE @HasPreRegistrationRules BIT = 0
		DECLARE @DSTeam VARCHAR(20)
		DECLARE @TotalPreRegistered INT

		SELECT @PK_Distributor = nDistributorID, @DSTeam = sSubTeam FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @FirstName = LTRIM(RTRIM(sFirstName)), @LastName = LTRIM(RTRIM(sLastName)) FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		SELECT @DSState = sState FROM dbo.v_MailingAddress WHERE nDistributorID = @PK_Distributor
		--SELECT @PK_EventHotel = PK_EventHotel FROM dbo.EventHotel WHERE PK_Event = @PK_Event AND PK_HotelInfo = @PK_HotelInfo

		SELECT
			@SpouseName = LTRIM(RTRIM(sSpouseFirstName)) +' '+ LTRIM(RTRIM(sSpouseLastName))
		FROM
			dbo.v_DistributorSpouse DS WITH (NOLOCK)
		WHERE
			DS.nDistributorID = @PK_Distributor
	
	
		SELECT @TotalPreRegistered = COUNT(1) FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_Event = @PK_Event AND IsPreRegistered = 1  
		IF ((@TotalPreRegistered >= 4000 OR GETUTCDATE() >= '2015-06-29') AND @PK_Event = 2493)
		BEGIN
			UPDATE dbo.Event SET IsPreRegistrationRequired = 0 WHERE PK_Event = @PK_Event

			SET @ErrorMessage =  '2500 MB Pre-Registered'
			SET @Error = 1 
			
			RETURN @Error
		END

		/******************************************************************************
		INSERT DISTRIBUTOR & PARTNER RECORDS
		******************************************************************************/
		BEGIN TRY
		-- Delete row for member/partner not attending
		--
		IF @IsMemberNotAttending = 1
			DELETE FROM EventsRegistration WHERE PK_Event = @PK_Event AND PK_Distributor = @PK_Distributor AND IsPrimaryGuest = 1

		IF @IsPartnerAttending = 0
			DELETE FROM EventsRegistration WHERE PK_Event = @PK_Event AND PK_Distributor = @PK_Distributor AND IsPrimaryGuest = 0

		IF NOT EXISTS (SELECT PK_Distributor FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Distributor = @PK_Distributor AND IsPrimaryGuest = 1 )
			AND @IsMemberNotAttending = 0
		BEGIN
			INSERT
				dbo.EventsRegistration
			(
				 [PK_Distributor]
				,[DistributorID]
				,[DSPreferredName]
				,[FirstName]
				,[LastName]
				,[Phones]
				,[EmailAddress]
				,[DistributorTeam]
				,[IsPrimaryGuest]
				,[HasCheckedIn]
				,[IsPreRegistered]
				,[PK_Event]
				,[PK_PrimaryLanguage]
				,[PK_EventHotel]
				,[IsUsingVolume]
				,[Apartment]
				,[CustomValue]
			)
			SELECT
				@PK_Distributor
				,@DistributorID
				,@DSName
				,@FirstName
				,@LastName
				,ISNULL(@PrimaryPhone,'') +  ' ' + ';' + ' ' + ISNULL(@MobilePhone,'')
				,@EmailAddress
				,@DSTeam
				,1
				,0
				,1
				,@PK_Event
				,@PK_PreferredLanguage
				,@PK_HotelInfo
				,@IsUsingVolume
				,@Apartment
				,ISNULL(@MemberCustomValue, '')
	
			SELECT @PK_EventsRegistration = @@IDENTITY
		END
		ELSE
			SELECT TOP 1 @PK_EventsRegistration = PK_EventsRegistration FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Distributor = @PK_Distributor

		IF @IsPartnerAttending = 1 AND NOT EXISTS (SELECT PK_Distributor FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_Event = @PK_Event AND PK_Distributor = @PK_Distributor AND IsPrimaryGuest = 0)
		BEGIN
			INSERT
				dbo.EventsRegistration
			(
				 [PK_Distributor]
				,[DistributorID]
				,[DSPreferredname]
				,[FirstName]
				,[Phones]
				,[EmailAddress]
				,[DistributorTeam]
				,[IsPrimaryGuest]
				,[HasCheckedIn]
				,[IsPreRegistered]
				,[PK_Event]
				,[PK_PrimaryLanguage]
				,[PK_EventHotel]
				,[IsUsingVolume]
				,[Apartment]
				,[CustomValue]
			)
			SELECT
				@PK_Distributor
				,@DistributorID
				,@PartnerPreferredName
				,@PartnerName
				,ISNULL(@PrimaryPhone,'') +  ' ' + ';' + ' ' + ISNULL(@MobilePhone,'')
				,@EmailAddress
				,@DSTeam
				,0
				,0
				,1
				,@PK_Event
				,@PK_PreferredLanguage
				,@PK_HotelInfo
				,@IsUsingVolume
				,@Apartment
				,ISNULL(@PartnerCustomValue, '')
		END
		/******************************************************************************
		UPDATE ADDRESS INFORMATION
		******************************************************************************/
		UPDATE
				T
		SET
				[DSPreferredName] = CASE WHEN T.IsPrimaryGuest = 1 THEN @DSName ELSE @PartnerPreferredName END
				,[FirstName] = CASE WHEN T.IsPrimaryGuest = 1 THEN @FirstName ELSE @PartnerName END
				,[LastName] = CASE WHEN T.IsPrimaryGuest = 1 THEN @LastName ELSE NULL END
				,[CustomValue] = CASE WHEN T.IsPrimaryGuest = 1 THEN @MemberCustomValue ELSE @PartnerCustomValue END
				,[DistributorTeam] = @DSTeam
				,[PK_EventHotel] = @PK_HotelInfo
				,[PK_PrimaryLanguage] = @PK_PreferredLanguage
				,[AddressLine1] = ISNULL(@Address,M.sAddress1)
				,[AddressLine2] = ISNULL(@Address2,M.sAddress2)
				,[City] = ISNULL(@City,M.sCity)
				,[State] = ISNULL(@State,M.sState)
				,[ZipCode] = ISNULL(@ZipCode,M.sPostalCode)
				,[Country] = ISNULL(@Country,M.sCountry)
				,[EmailAddress] = ISNULL(@EmailAddress,'')
				,[Phones] = ISNULL(@PrimaryPhone,'') +  ' ' + ';' + ' ' + ISNULL(@MobilePhone,'')
				,[Apartment] = ISNULL(@Apartment,Apartment)
				,[ModifiedDateUTC] = GETUTCDATE()
		FROM
				dbo.EventsRegistration T
		LEFT JOIN
				dbo.v_MailingAddress M
		ON
				T.PK_Distributor = M.nDistributorID
		WHERE
				T.PK_Event = @PK_Event
				AND
				T.PK_Distributor = @PK_Distributor

		END TRY

		BEGIN CATCH
			SET @Error = ERROR_NUMBER()
			SET @ErrorMessage = ERROR_MESSAGE()
			SET @StoredProcedure = ERROR_PROCEDURE()
			-- Update ErrorLog
			EXEC dbo.usp_Utility_UpdateErrorLog 
					@ProcedureName = @StoredProcedure
					,@ErrorNumber = 3
					,@ErrorMessage = @ErrorMessage OUTPUT
					,@SQLErrorCode = @Error
					,@SQLErrorMsg = @ErrorMessage
			RETURN 
		END CATCH

		/*SELECT THE CONFIRMATION NUMBER UPON SUCCESS */
		IF @Error = 0
		BEGIN
		SELECT @ConfirmationNumber = @DistributorID + '-' + CONVERT(VARCHAR, @PK_Event)
		SELECT @ConfirmationDate = CreatedDateUTC FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_EventsRegistration = @PK_EventsRegistration
		END

		-- Update processing Log
		EXEC dbo.usp_Utility_UpdateProcessingLog 
			@StoredProcedureName = @StoredProcedure
			,@StartTime = @StartTime

		/******************************************************************************
			END PROCEDURE
		******************************************************************************/

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