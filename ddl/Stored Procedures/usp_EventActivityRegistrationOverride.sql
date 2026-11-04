CREATE PROCEDURE dbo.usp_EventActivityRegistrationOverride
	@PK_EventActivityTransaction Int, 
	@TotalQty Int, 
	@CompQty Int, 
	@TotalPrice Numeric(17,4), 
	@OverrideBy NVarchar(50) = Null
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_EventActivityRegistrationNext

USE:	        EXEC dbo.usp_EventActivityRegistrationNext
					@PK_EventActivityTransaction = 1, 
					@TotalQty = 2, 
					@CompQty = 2, 
					@TotalPrice = 0, 
					@OverrideBy = 'NameOfSysAdmin'

DESCRIPTION:	Override quantities and price logging override person

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------


VERSIONS
----------------------------------------------------------------------------------
1	2015-07-05	ThomasG		Intitial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

Begin Try
Begin Transaction Main

	Declare @AuditOn Bit, @PK_EventActivity Int, @NumParticipant Int, @CurrentTotalQty Int, 
		@QtyToAdd Int, @QtyToAddNeg Int, @PK_TS_Register Int = 1, 
		@User NVarchar(50) = Replace(suser_sname(),'HERBALIFECORP\','')

	-- Ensure that transaction is in registration
	If (Select PK_TransactionStatus From dbo.EventActivityTransaction (NoLock) Where PK_EventActivityTransaction = @PK_EventActivityTransaction) <> @PK_TS_Register
	Begin
		If @@TRANCOUNT > 0 Rollback
		Raiserror(50101,16,1,@PK_EventActivityTransaction,'Register')
	End

	-- Set flag to write to Audit table
	Select @AuditOn = AuditOn
	From dbo.TransactionAuditControl (NoLock) 
	Where AuditType = 'Event Activity Transaction'

	-- Set variables using PK_EventActivityTransaction ID
	Select @PK_EventActivity = T.PK_EventActivity, 
		@CurrentTotalQty = T.TotalQty
	From dbo.EventActivityTransaction T (NoLock)
	Where PK_EventActivityTransaction = @PK_EventActivityTransaction

	-- Update with override numbers
	Begin Transaction ManualOverride

		-- Write to Audit
		If @AuditOn = 1
		Begin 
			Exec dbo.usp_Insert_EventActivityTransactionAudit
				@PK_EventActivityTransaction = @PK_EventActivityTransaction, 
				@PK_TransactionStatus = @PK_TS_Register, 
				@TotalQty = @TotalQty, 
				@CompQty = @CompQty, 
				@TotalPrice = @TotalPrice
		End

		Set @QtyToAdd = @CurrentTotalQty - @TotalQty
		Set @QtyToAddNeg = -@QtyToAdd

		-- Update Inventory
		Exec dbo.usp_Update_ActivityInventory
			@PK_EventActivity = @PK_EventActivity, 
			@MaxVar = 0, 
			@SoldVar = 0, 
			@ProcessingVar = @QtyToAdd, 
			@AvailableVar = @QtyToAddNeg

		Update dbo.EventActivityTransaction
		Set TotalQty = @TotalQty, 
			CompQty = @CompQty, 
			TotalPrice = @TotalPrice, 
			ManualOverride = 1, 
			OverrideBy = IsNull(@OverrideBy,@User), 
			ModifiedUTC = GetUTCDate(), 
			ModifiedBy = @User
		Where PK_EventActivityTransaction = @PK_EventActivityTransaction

	Commit Transaction ManualOverride

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
	From dbo.EventActivityTransaction T (NoLock)
		Inner Join dbo.TransactionStatus S (NoLock)
			On T.PK_TransactionStatus = S.PK_TransactionStatus
		Inner Join dbo.EventActivity A (NoLock)
			On A.PK_EventActivity = T.PK_EventActivity
	Where T.PK_EventActivityTransaction = @PK_EventActivityTransaction
Commit Transaction Main
End Try
Begin Catch
	If @@TRANCOUNT > 0 Rollback

	Declare @ErrorNumber Int, @ErrorMessage NVarchar(4000), @DB Varchar(256), @MessageOutput NVarchar(4000)
	Select @ErrorNumber = Error_Number(), @ErrorMessage = Error_Message(), @DB = db_Name()
	
	Exec ChangeRepository.dbo.usp_LogError 
		@ErrorNumber = @ErrorNumber, 
		@ErrorMessage = @ErrorMessage, 
		@DatabaseName = @DB, 
		@MessageOutput = @MessageOutput Out
	
	Raiserror(@ErrorMessage,16,1) With NoWait
	Return @ErrorNumber
End Catch
END