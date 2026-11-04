CREATE PROCEDURE [dbo].[usp_EventAPI_Upd_Attendee]
    -- REQUIRED
   @DistributorID varchar(10)
  ,@EventID int
  ,@UserID varchar(50)
  ,@PK_EventsRegistration int

	-- OPTIONAL
  ,@FirstName nvarchar(40) = NULL
  ,@LastName nvarchar(40) = NULL
  ,@AddressLine1 nvarchar(500) = NULL
  ,@AddressLine2 nvarchar(500) = NULL
  ,@City nvarchar(100) = NULL
  ,@State nvarchar(100) = NULL
  ,@ZipCode varchar(20) = NULL
  ,@Country varchar(100) = NULL
  ,@Phones varchar(100) = NULL
  ,@FaxNo varchar(100) = NULL
  ,@EmailAddress varchar(100) = NULL
  ,@IsPrimaryGuest bit = 1
  ,@HasCheckedIn bit = NULL
  ,@IsDistributor bit = 1
  ,@IsPreRegistered bit = 0
  ,@UnRegister bit = 0
  ,@DistributorTeam varchar(50) = NULL
  ,@PK_EventTicket INT = NULL
  ,@PK_PrimaryLanguage INT = NULL
  ,@PK_SecondaryLanguage INT = NULL
  ,@PK_EventHotel INT = NULL
  ,@Registered INT = 0
  ,@ModifiedBy varchar(50) = NULL

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Upd_Attendee

USE:			
			DECLARE @e int, @em varchar(4000)
               EXEC usp_EventAPI_Upd_Attendee @DistributorID = '14349799'
                                                       ,@EventID=8 
                                                       ,@UserID = 'SandhyaP'
                                                       ,@PK_EventsRegistration = 40991
                                                       ,@FirstName = 'Bret'
                                                       ,@LastName = 'Adams'
                                                       ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                               ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
														,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Add an Attendee to the EventRegistration, SubEventRegistration tables

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1		2009-02-06	Sandhya			Initial
1.2		2019-07-15	alejandramed	Setting error parameters as optionals
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON


/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	

DECLARE @PK_Distributor int

SELECT @Error = 0, @ErrorMessage = '';
SET @FirstName = LTRIM(RTRIM(@FirstName))
SET @LastName = LTRIM(RTRIM(@LastName))

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF EXISTS(SELECT PK_EventsRegistration FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_EventsRegistration = @PK_EventsRegistration)
 BEGIN
  (SELECT @PK_Distributor = @PK_Distributor FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_EventsRegistration = @PK_EventsRegistration) 
 END
ELSE
 BEGIN
	SET @Error = 87
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
 END

/******************************************************************************
set variables for update
******************************************************************************/
SELECT
	 @PK_Distributor = COALESCE(@PK_Distributor, PK_Distributor)
	,@FirstName = COALESCE(@FirstName, FirstName)
	,@LastName = COALESCE(@LastName, LastName)
	,@AddressLine1 = COALESCE(@AddressLine1, AddressLine1)
	,@AddressLine2 = COALESCE(@AddressLine2, AddressLine2)
	,@City = COALESCE(@City, City)
	,@State = COALESCE(@State, State)
	,@ZipCode = COALESCE(@ZipCode, ZipCode)
	,@Phones = COALESCE(@Phones, Phones)
	,@FaxNo = COALESCE(@FaxNo, FaxNo)
	,@EmailAddress = COALESCE(@EmailAddress, EmailAddress)
	,@IsPrimaryGuest = COALESCE(@IsPrimaryGuest, IsPrimaryGuest) 
    ,@HasCheckedIn = COALESCE(@HasCheckedIn, HasCheckedIn) 
    ,@IsDistributor = COALESCE(@IsDistributor, IsDistributor) 
    ,@IsPreRegistered = COALESCE(@IsPreRegistered, IsPreRegistered) 
    ,@UnRegister = COALESCE(@UnRegister, UnRegister) 
    ,@DistributorTeam = COALESCE(@DistributorTeam, DistributorTeam) 
	,@PK_EventTicket = COALESCE(@PK_EventTicket, PK_EventTicket)
	,@PK_PrimaryLanguage = COALESCE(@PK_PrimaryLanguage, PK_PrimaryLanguage)
	,@PK_SecondaryLanguage = COALESCE(@PK_SecondaryLanguage, PK_SecondaryLanguage)
	,@PK_EventHotel = COALESCE(@PK_EventHotel, PK_EventHotel)
    ,@ModifiedBy = COALESCE(@UserID, ModifiedBy)
FROM 
	dbo.EventsRegistration WITH (NOLOCK)
WHERE 
	PK_EventsRegistration = @PK_EventsRegistration
	

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @EventID)
BEGIN
	SET @Error = 5
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

/******************************************************************************
update record
******************************************************************************/
BEGIN TRY
	UPDATE ER
	SET
	 PK_Distributor = @PK_Distributor
	,FirstName = @FirstName
	,LastName = @LastName
	,AddressLine1 = @AddressLine1
	,AddressLine2 = @AddressLine2
	,City = @City
	,State = @State
	,ZipCode = @ZipCode
	,Phones = @Phones
	,FaxNo = @FaxNo
	,EmailAddress = @EmailAddress
	,IsPrimaryGuest = @IsPrimaryGuest 
    ,HasCheckedIn = @HasCheckedIn 
    ,IsDistributor = @IsDistributor 
    ,IsPreRegistered = @IsPreRegistered 
    ,UnRegister = @UnRegister 
    ,DistributorTeam = @DistributorTeam 
	,ModifiedBy = @ModifiedBy
	,PK_EventTicket = @PK_EventTicket
	,PK_PrimaryLanguage = @PK_PrimaryLanguage
	,PK_SecondaryLanguage = @PK_SecondaryLanguage
	,PK_EventHotel = @PK_EventHotel
	FROM 
		dbo.EventsRegistration ER WITH (NOLOCK)
	WHERE 
		PK_EventsRegistration = @PK_EventsRegistration

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

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

END
GO

