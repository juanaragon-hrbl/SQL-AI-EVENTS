
CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_PublicEventsPreRegistration]
    --Mandatory Parameter
	 @FirstName VARCHAR(250)
	,@LastName VARCHAR(250)
	,@EmailAddress nVARCHAR(100) 
	,@PK_Event INT
	--Optional Parameters
	,@Phone nVARCHAR(100) = NULL
	-- Output Parameter
	,@ConfirmationNumber nVARCHAR(25) OUTPUT
	,@ConfirmationDate DATETIME OUTPUT
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0	

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Ins_PublicEventsPreRegistration

USE:		

DECLARE @e int, @em varchar(4000)
declare @cm nVARCHAR(25)
declare @cd DATETIME
declare @IsDevQA int

				EXEC dbo.usp_EventAPI_Ins_PublicEventsPreRegistration
					 @FirstName = 'Juan'
					,@LastName = 'H'
					,@EmailAddress = 'juanah@herbalife.com'
					,@PK_Event = 5661
					--Optional Parameters
					,@Phone = '9999900000'
					-- Output Parameter
					,@ConfirmationNumber = @cm output
					,@ConfirmationDate = @cd output
					-- Error Parameters
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					-- QA/DEV
					,@IsDevQA = 1
					
				SELECT @CM, @e AS [Error], @em AS [Error Message]


DESCRIPTION:	Inserts record into dbo.EventRegistration as PreRegistrants

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventRegistration

VERSIONS
--------------------------------------------------------------------
1	2013-02-14	SushmaB		Initial
2	2019-09-05	NoeG		SRE template applied
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @PK_EventsRegistration INT
DECLARE @PK_TempDistributorID INT

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	/*Validate if Public and Allow preregistration*/
	IF NOT EXISTS (SELECT 1 FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event AND IsPreRegistrationRequired = 1 )
	BEGIN
		--Error msg
		RETURN
	END

	/*Validate if the Email is existing and already used to pre-register for the same DS Event*/
	IF EXISTS(SELECT 1 FROM dbo.EventsRegistration WITH (NOLOCK) WHERE EmailAddress = @EmailAddress AND PK_Event = @PK_Event AND IsPublicUser = 1 AND IsPreRegistered = 1)
	BEGIN

		SET @Error = 410
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT	
	END

	/******************************************************************************
	INSERT Public Preregistration Record
	******************************************************************************/
	ELSE
	--IF NOT EXISTS (SELECT 1 FROM dbo.EventsRegistration(NOLOCK) WHERE EmailAddress = @EmailAddress)
	BEGIN
		INSERT 
			dbo.[TempDistributors]
		(
			 CreatedDateUTC
			,ModifiedDateUTC
			,DistributorID
			,FirstName
			,LastName
			,DayPhone
		
		)
		SELECT
			 GETUTCDATE()
			,GETUTCDATE()
			,'PUBLICUSER'
			,@FirstName
			,@LastName
			,@Phone

		SET @PK_TempDistributorID = SCOPE_IDENTITY()
	END

	BEGIN TRY
	
		MERGE dbo.EventsRegistration ER
		USING
		(
			SELECT @PK_TempDistributorID AS [PK_Distributor], @PK_Event AS [PK_Event], @FirstName AS [FirstName]
			, @LastName AS [LastName], @Phone AS [Phone], @EmailAddress AS [EmailAddress], 0 AS [IsDistributor]
		) AS M
		ON ER.PK_Event = @PK_Event
		AND ER.[EmailAddress] = M.[EmailAddress] AND M.[PK_Event] = ER.[PK_Event] AND ER.IsPublicUser = 1
		WHEN NOT MATCHED THEN INSERT (PK_Distributor, DistributorID, PK_Event, FirstName, LastName, Phones, EmailAddress, IsDistributor, IsPreregistered, IsPublicUser)
		VALUES(M.PK_Distributor, 'PUBLICUSER', M.PK_Event, M.FirstName, M.LastName, M.Phone, M.EmailAddress, M.IsDistributor, 1, 1)
		WHEN MATCHED THEN UPDATE
		SET 
			 FirstName = M.FirstName
			,LastName = M.LastName
			,Phones = M.Phone
			,IsDistributor = M.IsDistributor
			,IsPreRegistered = 1
		;	
	
		SELECT @PK_EventsRegistration = SCOPE_IDENTITY()

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

	/*SELECT THE CONFIRMATION NUMBER UPON SUCCESS */
	IF @Error = 0
	BEGIN
		SELECT @ConfirmationNumber = CONVERT(VARCHAR, @PK_EventsRegistration) + '-' + CONVERT(VARCHAR, @PK_Event)
		SELECT @ConfirmationDate = CreatedDateUTC FROM dbo.EventsRegistration WITH (NOLOCK) WHERE PK_EventsRegistration = @PK_EventsRegistration
	END

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
