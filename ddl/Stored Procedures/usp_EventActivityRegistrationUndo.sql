CREATE PROCEDURE dbo.usp_EventActivityRegistrationUndo
	@PK_EventActivityTransaction Int, 
	@Comment NVarchar(1000)
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_EventActivityRegistrationUndo

USE:	        EXEC dbo.usp_EventActivityRegistrationUndo
					@PK_EventActivityTransaction = 1, 
					@Comment = 'Cancelled Registration due to reduction of Event Tickets'

DESCRIPTION:	Undo a confirmed registration.  
				This may require that the member get a refund from HDMS.

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------


VERSIONS
----------------------------------------------------------------------------------
1	2015-09-03	ThomasG		Intitial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

Begin Try
Begin Transaction Main

	-- Declaration of Variables
	Declare @AuditOn Bit, @PK_EventActivity Int, 
		@SoldQty Int, @SoldQtyNeg Int, @CompQty Int, @TotalPrice Numeric(17,4), 
		@PK_TS_Confirmed Int = 3, @PK_TS_SystemCancelled Int = 5	-- Status for Register and System Cancelled

	-- Set flag to write to Audit table
	Select @AuditOn = AuditOn
	From dbo.TransactionAuditControl (NoLock) 
	Where AuditType = 'Event Activity Transaction'

	-- If transaction is confirmed, cancel transaction and return tickets to inventory
	If Exists
	(
		Select 1 
		From dbo.EventActivityTransaction (NoLock) 
		Where PK_EventActivityTransaction = @PK_EventActivityTransaction
			And PK_TransactionStatus = @PK_TS_Confirmed	-- In Registration Status
	)
	Begin
		Begin Transaction SystemCancel

		-- Determine quanitity pending sale
		Select Top 1 @PK_EventActivity = PK_EventActivity, 
			@SoldQty = IsNull(TotalQty,0), 
			@CompQty = IsNull(CompQty,0), 
			@TotalPrice = IsNull(TotalPrice,0)
		From dbo.EventActivityTransaction (NoLock) 
		Where PK_EventActivityTransaction = @PK_EventActivityTransaction
			And PK_TransactionStatus = @PK_TS_Confirmed

		-- Get Negative of PendingQty
		Set @SoldQtyNeg = -@SoldQty

		-- Return sold qty to inventory
		Exec dbo.usp_Update_ActivityInventory
			@PK_EventActivity = @PK_EventActivity, 
			@MaxVar = 0, 
			@SoldVar = @SoldQtyNeg, 
			@ProcessingVar = 0, 
			@AvailableVar = @SoldQty

		Update dbo.EventActivityTransaction
		Set PK_TransactionStatus = @PK_TS_SystemCancelled,	-- System Cancelled
			ErrorMsg = @Comment, 
			ModifiedUTC = GetUTCDate(), 
			ModifiedBy = Replace(suser_sname(),'HERBALIFECORP\','')
		Where PK_EventActivityTransaction = @PK_EventActivityTransaction
		
		If @AuditOn = 1
		Begin 
			Exec dbo.usp_Insert_EventActivityTransactionAudit
				@PK_EventActivityTransaction = @PK_EventActivityTransaction, 
				@PK_TransactionStatus = @PK_TS_SystemCancelled, 
				@TotalQty = @SoldQty, 
				@CompQty = @CompQty, 
				@TotalPrice = @TotalPrice
		End
		
		Commit Transaction SystemCancel
	End
	-- Ensure that transaction is in a confirmed status
	Else If (Select PK_TransactionStatus From dbo.EventActivityTransaction (NoLock) Where PK_EventActivityTransaction = @PK_EventActivityTransaction) <> @PK_TS_Confirmed
	Begin
		If @@TRANCOUNT > 0 Rollback
		Raiserror(50101,16,1,@PK_EventActivityTransaction,'Confirmed')
	End
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