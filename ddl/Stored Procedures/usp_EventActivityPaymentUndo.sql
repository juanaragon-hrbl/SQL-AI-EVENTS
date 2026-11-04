CREATE PROCEDURE dbo.usp_EventActivityPaymentUndo
	@PK_EventActivityTransaction Int, 
	@PK_TransactionStatus Int = 10,	-- 10 Cancelled, 11 Timeout
	@Comment NVarchar(1000) = NULL
	
	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_EventActivityPaymentUndo

USE:	        EXEC dbo.usp_EventActivityPaymentUndo
					@PK_EventActivityTransaction = 2, 
					@PK_TransactionStatus = 10,
					@Comment = 'Cancel Payment'

DESCRIPTION:	Undo Payment and move tickets from Sold to Available

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
VERSIONS
----------------------------------------------------------------------------------
	1.0.0	  2015-09-28	  ThomasG		 Intitial
	1.1.0     2019-10-11      puertac	     SRE Implementation 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)

BEGIN TRY
BEGIN TRANSACTION Main

	DECLARE @AuditOn Bit, @PK_EventActivity Int, 
		@TotalQty Int, @CompQty Int, @TotalPrice Numeric(17,4), 
		@TotalQtyNeg Int, @AvailableQty Int, @PK_TS_Approved Int = 8, @PK_TS_Declined Int = 9, @PK_TS_Cancelled Int = 10, @PK_TS_Timeout Int = 11

	-- Ensure that transaction is in approved payment status
	IF (SELECT PK_TransactionStatus FROM dbo.EventActivityTransaction WITH (NOLOCK) WHERE PK_EventActivityTransaction = @PK_EventActivityTransaction) Not In (@PK_TS_Approved)
	BEGIN
		IF @@TRANCOUNT > 0 ROLLBACK
		RAISERROR(50101,16,1,@PK_EventActivityTransaction,'Payment Approved') WITH NOWAIT
	END

	-- Ensure that status is either declined, cancelled, timed out
	IF @PK_TransactionStatus Not In (@PK_TS_Declined,@PK_TS_Cancelled,@PK_TS_Timeout)
	BEGIN
		IF @@TRANCOUNT > 0 ROLLBACK
		RAISERROR(50102,16,1,@PK_TransactionStatus) WITH NOWAIT
	END

	-- Set flag to write to Audit table
	SELECT @AuditOn = AuditOn
	FROM dbo.TransactionAuditControl WITH (NOLOCK)
	WHERE AuditType = 'Event Activity Transaction'

	-- Set variables using PK_EventActivityTransaction ID
	SELECT @PK_EventActivity = PK_EventActivity, 
		@TotalQty = TotalQty, 
		@CompQty = CompQty, 
		@TotalPrice = TotalPrice
	FROM dbo.EventActivityTransaction WITH (NOLOCK)
	WHERE PK_EventActivityTransaction = @PK_EventActivityTransaction

	BEGIN TRANSACTION PaymentUndo
		-- Update transaction status
		UPDATE dbo.EventActivityTransaction
		SET PK_TransactionStatus = @PK_TransactionStatus, 
			ErrorMsg = @Comment, 
			ModifiedUTC = GetUTCDate(), 
			ModifiedBy = Replace(suser_sname(),'HERBALIFECORP\','')
		WHERE PK_EventActivityTransaction = @PK_EventActivityTransaction

		-- Write to Audit
		IF @AuditOn = 1
		BEGIN 
			EXEC dbo.usp_Insert_EventActivityTransactionAudit
				@PK_EventActivityTransaction = @PK_EventActivityTransaction, 
				@PK_TransactionStatus = @PK_TransactionStatus, 
				@TotalQty = @TotalQty, 
				@CompQty = @CompQty, 
				@TotalPrice = @TotalPrice
		END

		SET @TotalQtyNeg = -@TotalQty

		-- Update Inventory
		EXEC dbo.usp_Update_ActivityInventory
			@PK_EventActivity = @PK_EventActivity, 
			@MaxVar = 0, 
			@SoldVar = @TotalQtyNeg, 
			@ProcessingVar = 0, 
			@AvailableVar = @TotalQty
	COMMIT TRANSACTION PaymentUndo
COMMIT TRANSACTION Main
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