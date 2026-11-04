CREATE PROCEDURE dbo.usp_EventActivityRegistrationNext 
	@PK_EventActivityTransaction INT,
	@Participant udt_Participant READONLY

	-- Error Parameters
	, @Error INT = 0 OUTPUT
	, @ErrorMessage VARCHAR(4000) = NULL OUTPUT
	-- QA/DEV
	, @IsDevQA BIT = 0

AS
BEGIN
	/******************************************************************************
	OBJECT:			dbo.usp_EventActivityRegistrationNext
	
	USE:	        Declare @P udt_Participant
					Insert Into @P (Name, Email, PhoneNumber, DOB, TourLanguage, IdentificationNumber, IsDistributor, PK_MealType, MealNote)
					Values('Bugs Bunny','BugsBunny@WB.com','123-456-7890','1985-10-01',37,Null,1,3,'No Peanuts') 
	
					EXEC dbo.usp_EventActivityRegistrationNext
						@PK_EventActivityTransaction = 2, 
						@Participant = @P
	
	DESCRIPTION:	Next step in process for event activity registration
					If TotalPrice > 0 send to Payment Gateway
					If TotalPrice = 0 confirm registration
	
	NOTES:			
	DEPENDENCIES
	----------------------------------------------------------------------------------
	VERSIONS
	----------------------------------------------------------------------------------
		1.1.0	2015-07-05	   ThomasG		 Intitial
		1.2.0   2017-07-17	   SandhyaP	     Added FlightOption for the member
		1.3.0   2019-10-14     puertac	     SRE Implementation 
	******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON
	
	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		BEGIN TRANSACTION Main

		DECLARE @AuditOn BIT
			   ,@PK_EventActivity INT
			   ,@NumParticipant INT
			   ,@TotalQty INT
			   ,@CompQty INT
			   ,@TotalPrice NUMERIC(17, 4)
			   ,@ConfirmationNumber NVARCHAR(50)
			   ,@TotalQtyNeg INT
			   ,@PK_TS_Register INT = 1
			   ,@PK_TS_SendToPG INT = 2
			   ,@PK_TS_Confirm INT = 3
			   ,@Timeout INT

		-- Ensure that transaction is in registration
		IF (SELECT
				PK_TransactionStatus
				FROM dbo.EventActivityTransaction WITH (NOLOCK)
				WHERE PK_EventActivityTransaction = @PK_EventActivityTransaction)
			<> @PK_TS_Register
		BEGIN
			IF @@trancount > 0
				ROLLBACK
			RAISERROR (50101, 16, 1, @PK_EventActivityTransaction, 'Register')
		END

		SELECT
			@NumParticipant = ISNULL(COUNT(1), 0)
		FROM @Participant

		-- Ensure that number of Participant equal total qty
		IF @NumParticipant <> @TotalQty
		BEGIN
			IF @@trancount > 0
				ROLLBACK
			RAISERROR (50105, -1, -1, @NumParticipant, @TotalQty)
		END

		-- Set flag to write to Audit table
		SELECT
			@AuditOn = AuditOn
		FROM dbo.TransactionAuditControl WITH (NOLOCK)
		WHERE AuditType = 'Event Activity Transaction'

		-- Set variables using PK_EventActivityTransaction ID
		SELECT
			@PK_EventActivity = T.PK_EventActivity
		   ,@TotalQty = T.TotalQty
		   ,@CompQty = T.CompQty
		   ,@TotalPrice = T.TotalPrice
		   ,@Timeout = A.PaymentTimeOut
		FROM dbo.EventActivityTransaction T WITH (NOLOCK)
		INNER JOIN dbo.EventActivity A WITH (NOLOCK)
			ON T.PK_EventActivity = A.PK_EventActivity
		WHERE PK_EventActivityTransaction = @PK_EventActivityTransaction

		-- Add participants
		INSERT INTO dbo.EventActivityParticipant (PK_EventActivityTransaction,
		Name,
		Email,
		PhoneNumber,
		DOB,
		TourLanguage,
		IdentificationNumber,
		IdentificationExpDate,
		IsDistributor,
		PK_MealType,
		MealNote,
		FlightOption)
			SELECT
				@PK_EventActivityTransaction
			   ,Name
			   ,Email
			   ,PhoneNumber
			   ,DOB
			   ,TourLanguage
			   ,IdentificationNumber
			   ,IdentificationExpDate
			   ,IsDistributor
			   ,ISNULL(PK_MealType, 1)
			   ,MealNote
			   ,FlightOption
			FROM @Participant

		-- Total price is equal to 0, confirm transaction
		IF @TotalPrice = 0
		BEGIN
			BEGIN TRANSACTION ConfirmRegistration

			-- Get confirmation ID
			SET @ConfirmationNumber = NEWID()

			-- Update Confirmation Number and transaction status
			UPDATE dbo.EventActivityTransaction
			SET ConfirmationNumber = @ConfirmationNumber
			   ,PK_TransactionStatus = @PK_TS_Confirm
			   ,ModifiedUTC = GETUTCDATE()
			   ,ModifiedBy = REPLACE(SUSER_SNAME(), 'HERBALIFECORP\', '')
			WHERE PK_EventActivityTransaction = @PK_EventActivityTransaction

			-- Write to Audit
			IF @AuditOn = 1
			BEGIN
				EXEC dbo.usp_Insert_EventActivityTransactionAudit @PK_EventActivityTransaction = @PK_EventActivityTransaction
																 ,@PK_TransactionStatus = @PK_TS_Confirm
																 ,@TotalQty = @TotalQty
																 ,@CompQty = @CompQty
																 ,@TotalPrice = @TotalPrice
			END

			SET @TotalQtyNeg = -@TotalQty

			-- Update Inventory
			EXEC dbo.usp_Update_ActivityInventory @PK_EventActivity = @PK_EventActivity
												 ,@MaxVar = 0
												 ,@SoldVar = @TotalQty
												 ,@ProcessingVar = @TotalQtyNeg
												 ,@AvailableVar = 0

			COMMIT TRANSACTION ConfirmRegistration
		END
		ELSE
		IF @TotalPrice > 0	-- Send to Payment Gateway
		BEGIN
			BEGIN TRANSACTION SendToPG

			-- Update transaction status
			UPDATE dbo.EventActivityTransaction
			SET PK_TransactionStatus = @PK_TS_SendToPG
			   ,Timeout = DATEADD(s, @Timeout, GETUTCDATE())
			   ,ModifiedUTC = GETUTCDATE()
			   ,ModifiedBy = REPLACE(SUSER_SNAME(), 'HERBALIFECORP\', '')
			WHERE PK_EventActivityTransaction = @PK_EventActivityTransaction

			-- Write to Audit
			IF @AuditOn = 1
			BEGIN
				EXEC dbo.usp_Insert_EventActivityTransactionAudit @PK_EventActivityTransaction = @PK_EventActivityTransaction
																 ,@PK_TransactionStatus = @PK_TS_SendToPG
																 ,@TotalQty = @TotalQty
																 ,@CompQty = @CompQty
																 ,@TotalPrice = @TotalPrice
			END

			COMMIT TRANSACTION SendToPG
		END

		-- Output transaction
		SELECT
			T.PK_EventActivityTransaction
		   ,T.PK_EventActivity
		   ,T.PK_TransactionStatus
		   ,S.StatusDesc
		   ,T.DistributorID
		   ,T.TotalQty
		   ,T.CompQty
		   ,T.TotalPrice
		   ,A.CurrencyType
		   ,T.ConfirmationNumber
		   ,T.Timeout
		FROM dbo.EventActivityTransaction T WITH (NOLOCK)
		INNER JOIN dbo.TransactionStatus S WITH (NOLOCK)
			ON T.PK_TransactionStatus = S.PK_TransactionStatus
		INNER JOIN dbo.EventActivity A WITH (NOLOCK)
			ON A.PK_EventActivity = T.PK_EventActivity
		WHERE T.PK_EventActivityTransaction = @PK_EventActivityTransaction
		COMMIT TRANSACTION Main

	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK

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
END