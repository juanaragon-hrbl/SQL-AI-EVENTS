CREATE PROCEDURE dbo.usp_EventActivityRegistrationStop
	@PK_EventActivityTransaction Int, 
	@PK_TransactionStatus Int,	-- 4 User Cancelled, 5 System Cancelled, 6 User Timeout, 7 System Timeout



		@IsDevQA		BIT = 0,   
	    @Error			int = 0 OUTPUT,
	    @ErrorMessage	varchar(4000) = NULL OUTPUT
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_EventActivityRegistrationStop

USE:	        EXEC dbo.usp_EventActivityRegistrationStop
					@PK_EventActivityTransaction = 3, 
					@PK_TransactionStatus = 4

DESCRIPTION:	Stop registration either due to cancellation or timeout

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------


VERSIONS
----------------------------------------------------------------------------------
1	2015-07-05	ThomasG		Intitial
2	2019-10-14	JonathanO	Refactor code (SRE)

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE  @StoredProcedure varchar(255) = 'usp_EventActivityRegistrationStop'
		,@StartTime datetime2 = GETUTCDATE();

BEGIN TRY

Begin Transaction Main

	Declare @AuditOn Bit, @PK_EventActivity Int, 
		@TotalQty Int, @CompQty Int, @TotalPrice Numeric(17,4), @ConfirmationNumber NVarchar(50), 
		@TotalQtyNeg Int, @PK_TS_Register Int = 1, @PK_TS_SendToPG Int = 2, @PK_TS_Confirm Int = 3

	-- Ensure that transaction is in registration
	If (Select PK_TransactionStatus From dbo.EventActivityTransaction WITH (NoLock) Where PK_EventActivityTransaction = @PK_EventActivityTransaction) <> @PK_TS_Register
	Begin
		If @@TRANCOUNT > 0 Rollback
		Raiserror(50101,16,1,@PK_EventActivityTransaction,'Register') With NoWait
	End

	-- Set flag to write to Audit table
	Select @AuditOn = AuditOn
	From dbo.TransactionAuditControl WITH (NoLock)
	Where AuditType = 'Event Activity Transaction'

	-- Set variables using PK_EventActivityTransaction ID
	Select @PK_EventActivity = PK_EventActivity, 
		@TotalQty = TotalQty, 
		@CompQty = CompQty, 
		@TotalPrice = TotalPrice
	From dbo.EventActivityTransaction WITH (NoLock)
	Where PK_EventActivityTransaction = @PK_EventActivityTransaction

	-- Ensure that status is either cancelled or timed out
	If @PK_TransactionStatus Not Between 4 and 7
	Begin
		If @@TRANCOUNT > 0 Rollback
		Raiserror(50102,16,1,@PK_TransactionStatus) With NoWait
	End

	Begin Transaction StopRegistration
		-- Update transaction status
		Update dbo.EventActivityTransaction
		Set PK_TransactionStatus = @PK_TransactionStatus, 
			ModifiedUTC = GetUTCDate(), 
			ModifiedBy = Replace(suser_sname(),'HERBALIFECORP\','')
		Where PK_EventActivityTransaction = @PK_EventActivityTransaction

		-- Write to Audit
		If @AuditOn = 1
		Begin 
			Exec dbo.usp_Insert_EventActivityTransactionAudit
				@PK_EventActivityTransaction = @PK_EventActivityTransaction, 
				@PK_TransactionStatus = @PK_TransactionStatus, 
				@TotalQty = @TotalQty, 
				@CompQty = @CompQty, 
				@TotalPrice = @TotalPrice
		End

		Set @TotalQtyNeg = -@TotalQty

		-- Update Inventory
		Exec dbo.usp_Update_ActivityInventory
			@PK_EventActivity = @PK_EventActivity, 
			@MaxVar = 0, 
			@SoldVar = 0, 
			@ProcessingVar = @TotalQtyNeg, 
			@AvailableVar = @TotalQty

	Commit Transaction StopRegistration

	-- Output transaction
	Select T.PK_EventActivityTransaction,
		T.PK_EventActivity,
		T.PK_TransactionStatus,
		S.StatusDesc,
		T.DistributorID,
		T.TotalQty,
		T.CompQty,
		T.TotalPrice,
		A.CurrencyType, 
		T.ConfirmationNumber,
		T.Timeout
	From dbo.EventActivityTransaction T WITH (NoLock)
		Inner Join dbo.TransactionStatus S WITH (NoLock)
			On T.PK_TransactionStatus = S.PK_TransactionStatus
		Inner Join dbo.EventActivity A WITH (NoLock)
			On A.PK_EventActivity = T.PK_EventActivity
	Where T.PK_EventActivityTransaction = @PK_EventActivityTransaction
Commit Transaction Main



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

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;