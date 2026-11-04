CREATE PROCEDURE dbo.usp_EventActivityRegistrationAdd
	@PK_EventActivityTransaction Int, 
	@QtyToAdd Int = 1
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_EventActivityRegistrationAdd

USE:	        EXEC dbo.usp_EventActivityRegistrationAdd
					@PK_EventActivityTransaction = 2, 
					@QtyToAdd = 1

DESCRIPTION:	Add participant to an activity

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

	Declare @AuditOn Bit, @ErrorNum Int, @ErrorMsg NVarchar(1000), @PK_EventActivity Int, 
		@TotalQty Int, @CompQty Int, @TotalPrice Numeric(17,4), @ConfirmationNumber NVarchar(50), 
		@QtyToAddNeg Int, @AvailableQty Int, @PK_TS_Register Int = 1, @PK_TransactionStatus Int

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
	Select @PK_EventActivity = PK_EventActivity, 
		@PK_TransactionStatus = PK_TransactionStatus, 
		@TotalQty = TotalQty, 
		@CompQty = CompQty, 
		@TotalPrice = TotalPrice
	From dbo.EventActivityTransaction (NoLock)
	Where PK_EventActivityTransaction = @PK_EventActivityTransaction

	Begin Transaction AddRegistration
		-- Calculate new total price 
		Select @TotalPrice = ((@TotalQty + @QtyToAdd) - @CompQty) * UnitPrice, 
			@TotalQty = @TotalQty + @QtyToAdd, 
			@AvailableQty = AvailableQty
		From dbo.EventActivity With (NOLOCK)
		Where PK_EventActivity = @PK_EventActivity

		-- Check that quantities are available to add
		If @AvailableQty >= @QtyToAdd
		Begin 
			-- Update transaction status
			Update dbo.EventActivityTransaction
			Set TotalQty = @TotalQty, 
				TotalPrice = @TotalPrice, 
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

			Set @QtyToAddNeg = -@QtyToAdd

			-- Update Inventory
			Exec dbo.usp_Update_ActivityInventory
				@PK_EventActivity = @PK_EventActivity, 
				@MaxVar = 0, 
				@SoldVar = 0, 
				@ProcessingVar = @QtyToAdd, 
				@AvailableVar = @QtyToAddNeg
		End
		Else
		Begin
			If @@TRANCOUNT > 0 Rollback
			Raiserror(50104,16,1,@QtyToAdd,@AvailableQty)
		End

	Commit Transaction AddRegistration

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