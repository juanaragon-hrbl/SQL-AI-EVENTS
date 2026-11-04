CREATE PROCEDURE [dbo].[usp_EventActivityRegistration]
	@PK_EventActivity Int,		-- Identifier for EventActivity
	@DistributorID Varchar(30), 
	@TotalQty Int, 
	@CompQty Int, 
	@TotalPrice Numeric(17,4) = 0.0000
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_EventActivityRegistration

USE:	        EXEC dbo.usp_EventActivityRegistration
					@PK_EventActivity = 1, 
					@DistributorID = '1111111111', 
					@TotalQty = 1, 
					@CompQty = 1

DESCRIPTION:	Begin registration for DS to purchase Event Activity ticket

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------


VERSIONS
----------------------------------------------------------------------------------
1	2015-07-05	ThomasG		Intitial
1.1	2017-08-29	SandhyaP	Add validation to check if they are already registered before add/update the transaction
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

Begin Try
Begin Transaction Main

	-- Declaration of Variables
	Declare @AuditOn Bit, 
		@PK_EventActivityTransaction Int, @PendingQty Int, @PendingCompQty Int, @PendingPrice Numeric(17,4), 
		@PendingQtyNeg Int, @TotalQtyNeg Int, @ReserveTimeout Int, @AvailableQty Int, 
		@PK_TS_Register Int = 1, @PK_TS_SystemCancelled Int = 5,	-- Status for Register and System Cancelled
		@PK_TS_RegisterComplete Int = 3, @PK_TS_PaymentApproved Int = 8

	-- Set flag to write to Audit table
	Select @AuditOn = AuditOn
	From dbo.TransactionAuditControl (NoLock) 
	Where AuditType = 'Event Activity Transaction'

	If @TotalQty <=
	(
		Select COUNT(1) 
		From dbo.EventActivityTransaction (NoLock) ET
		Inner Join dbo.EventActivityParticipant (noLock) EP
		ON ET.PK_EventActivityTransaction = EP.PK_EventActivityTransaction
		--And EP.IsDistributor = 1
		Where PK_EventActivity = @PK_EventActivity 
			And DistributorID = @DistributorID 
			And PK_TransactionStatus in (@PK_TS_RegisterComplete, @PK_TS_PaymentApproved)	-- Registration complete/approved
	)
	Begin
		Raiserror('You are already registered...',0,1) With NoWait
		Return
	End


	-- Ensure that there is no pending transaction for DS
	-- If pending transaction exists, cancel transaction and start new transaction
	While Exists
	(
		Select 1 
		From dbo.EventActivityTransaction (NoLock) 
		Where PK_EventActivity = @PK_EventActivity 
			And DistributorID = @DistributorID 
			And PK_TransactionStatus = @PK_TS_Register	-- In Registration Status
	)
	Begin
		Raiserror('Cancelling Pending Registration...',0,1) With NoWait
		Begin Transaction SystemCancel

		-- Determine quanitity pending sale
		Select Top 1 @PK_EventActivityTransaction = PK_EventActivityTransaction, 
			@PendingQty = IsNull(TotalQty,0), 
			@PendingCompQty = IsNull(CompQty,0), 
			@PendingPrice = IsNull(TotalPrice,0)
		From dbo.EventActivityTransaction (NoLock) 
		Where PK_EventActivity = @PK_EventActivity 
			And DistributorID = @DistributorID 
			And PK_TransactionStatus = @PK_TS_Register

		-- Get Negative of PendingQty
		Set @PendingQtyNeg = -@PendingQty

		-- Return pending qty to inventory
		Exec dbo.usp_Update_ActivityInventory
			@PK_EventActivity = @PK_EventActivity, 
			@MaxVar = 0, 
			@SoldVar = 0, 
			@ProcessingVar = @PendingQtyNeg, 
			@AvailableVar = @PendingQty

		Update dbo.EventActivityTransaction
		Set PK_TransactionStatus = @PK_TS_SystemCancelled,	-- System Cancelled
			ModifiedUTC = GetUTCDate(), 
			ModifiedBy = Replace(suser_sname(),'HERBALIFECORP\','')
		Where PK_EventActivityTransaction = @PK_EventActivityTransaction
		
		If @AuditOn = 1
		Begin 
			Exec dbo.usp_Insert_EventActivityTransactionAudit
				@PK_EventActivityTransaction = @PK_EventActivityTransaction, 
				@PK_TransactionStatus = @PK_TS_SystemCancelled, 
				@TotalQty = @PendingQty, 
				@CompQty = @PendingCompQty, 
				@TotalPrice = @PendingPrice
		End
		
		Commit Transaction SystemCancel
	End

	Begin Transaction Register

		-- Initialize Variable
		Set @PK_EventActivityTransaction = Null

		-- Calculate total price and retrieve ReserveTimeout and AvailableQty
		Select @TotalPrice = (@TotalQty - @CompQty) * UnitPrice, 
			@TotalQtyNeg = -@TotalQty, 
			@ReserveTimeout = ReserveTimeout, 
			@AvailableQty = AvailableQty
		From dbo.EventActivity With (NOLOCK) 
		Where PK_EventActivity = @PK_EventActivity

		-- Check that total qty doesn't exceed available quantity
		If @AvailableQty >= @TotalQty
		Begin
			Insert Into dbo.EventActivityTransaction 
			(
				PK_EventActivity, 
				PK_TransactionStatus, 
				DistributorID, 
				TotalQty, 
				CompQty, 
				TotalPrice, 
				Timeout
			)
			Values
			(
				@PK_EventActivity, 
				@PK_TS_Register, -- Register
				@DistributorID, 
				@TotalQty, 
				@CompQty, 
				@TotalPrice, 
				DateAdd(s,@ReserveTimeout,GetUTCDate())
			)
		End
		Else
		Begin
			If @@Trancount > 1 Rollback
			Raiserror(50103,16,1,@TotalQty,@AvailableQty) With NoWait
		End

		Set @PK_EventActivityTransaction = Scope_Identity()

		-- Update Inventory
		Exec dbo.usp_Update_ActivityInventory
			@PK_EventActivity = @PK_EventActivity, 
			@MaxVar = 0, 
			@SoldVar = 0, 
			@ProcessingVar = @TotalQty, 
			@AvailableVar = @TotalQtyNeg

		-- Write to audit table
		If @AuditOn = 1
		Begin 
			Exec dbo.usp_Insert_EventActivityTransactionAudit
				@PK_EventActivityTransaction = @PK_EventActivityTransaction, 
				@PK_TransactionStatus = @PK_TS_Register, 
				@TotalQty = @TotalQty, 
				@CompQty = @CompQty, 
				@TotalPrice = @TotalPrice
		End

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
	Commit Transaction Register
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