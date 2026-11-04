CREATE PROCEDURE dbo.usp_Update_ActivityInventory
	@PK_EventActivity Int,	-- Identifier for EventActivity
	@MaxVar Int,			-- Variable for Max Qty to Add or Subtract, If @MaxVar is passed all other Qty should be 0 and vice versa
	@SoldVar Int,		-- Variable for Sold Qty to Add or Subtract
	@ProcessingVar Int,	-- Variable for Processing Qty to Add or Subtract
	@AvailableVar Int	-- Variable for Available Qty to Add or Subtract
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_Update_ActivityInventory

USE:	        EXEC dbo.usp_Update_ActivityInventory
					@PK_EventActivity = 1, 
					@MaxVar = 0, 
					@SoldVar = 0, 
					@ProcessingVar = 0, 
					@AvailableVar = 0

DESCRIPTION:	This stored procedure will update the inventory for a specific EventActivity

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------


VERSIONS
----------------------------------------------------------------------------------
1	2015-06-19	ThomasG		Intitial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

Declare @User NVarchar(50) = Replace(suser_sname(),'HERBALIFECORP\','')
Declare @Msg Varchar(256)
Declare @ErrorNum Int = 999
Declare 
	@MaxQty Int, 
	@SoldQty Int, 
	@ProcessingQty Int, 
	@AvailableQty Int

	-- Check to see if EventActivity is present
	If Not Exists (Select 1 From dbo.EventActivity (NoLock) Where PK_EventActivity = @PK_EventActivity And DeletedUTC Is Null)
	Begin
		If @@TRANCOUNT > 0 Rollback
		Raiserror(50108,16,1,@PK_EventActivity)
	End

Begin Try
Begin Transaction
	-- Obtain Qty values
	Select @MaxQty = MaxQty, 
		@SoldQty = SoldQty, 
		@ProcessingQty = ProcessingQty, 
		@AvailableQty = AvailableQty
	From dbo.EventActivity With (XLOCK,ROWLOCK)
	Where PK_EventActivity = @PK_EventActivity

	--Raiserror('Max: %i, Sold: %i, Processing: %i, Available: %i, MaxVar: %i, SoldVar: %i, ProcessingVar: %i, AvailableVar: %i',0,1,@MaxQty,@SoldQty,@ProcessingQty,@AvailableQty,@MaxVar,@SoldVar,@ProcessingVar,@AvailableVar) With NoWait

	-- Logic to Update MaxQty
	If @MaxVar <> 0 And (@SoldVar = 0 And @ProcessingVar = 0 And @AvailableVar = 0)
	Begin
		-- Check that @MaxQty + @MaxVar >= @SoldQty + @ProcessingQty then update @MaxQty and @AvailableQty
		If @MaxQty + @MaxVar >= @SoldQty + @ProcessingQty
		Begin
			Update dbo.EventActivity With (XLOCK,ROWLOCK)
			Set MaxQty = @MaxQty + @MaxVar, 
				AvailableQty = @AvailableQty + @MaxVar, 
				ModifiedUTC = GetUTCDate(), 
				ModifiedBy = @User
			Where PK_EventActivity = @PK_EventActivity
		End
		-- Return error because update of MaxQty would make Available go to negative
		Else
		Begin
			If @@TRANCOUNT > 0 Rollback
			Raiserror(50107,16,1,@MaxVar)
		End
	End
	Else If @MaxVar <> 0
	-- Execute addition of Max Qty and other Qty separately
	Begin
		Exec usp_Update_ActivityInventory 
			@PK_EventActivity = @PK_EventActivity, 
			@MaxVar = @MaxVar, 
			@SoldVar = 0, 
			@ProcessingVar = 0, 
			@AvailableVar = 0

		Exec usp_Update_ActivityInventory
			@PK_EventActivity = @PK_EventActivity, 
			@MaxVar = 0, 
			@SoldVar = @SoldVar, 
			@ProcessingVar = @ProcessingVar, 
			@AvailableVar = @AvailableVar
	End

	-- MaxQty is 0
	If @MaxVar = 0
	Begin
		-- Check that sold, processing, and available equals max before updating
		If @MaxQty = @SoldQty + @SoldVar + @ProcessingQty + @ProcessingVar + @AvailableQty + @AvailableVar
		Begin
			Update dbo.EventActivity With (XLOCK,ROWLOCK)
			Set SoldQty = @SoldQty + @SoldVar, 
				ProcessingQty = @ProcessingQty + @ProcessingVar, 
				AvailableQty = @AvailableQty + @AvailableVar, 
				ModifiedUTC = GetUTCDate(), 
				ModifiedBy = @User
			Where PK_EventActivity = @PK_EventActivity
		End
		-- Return error because quantities do not compute
		Else
		Begin
			If @@TRANCOUNT > 0 Rollback
			Raiserror(50106,16,1)
		End
	End
Commit Transaction
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
End