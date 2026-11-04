CREATE PROCEDURE dbo.usp_Get_ActivityInventory
	@PK_EventActivity Int		-- Identifier for EventActivity
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_Get_ActivityInventory

USE:	        EXEC dbo.usp_Get_ActivityInventory
					@PK_EventActivity = 1

DESCRIPTION:	Get the available inventory for a specific EventActivity

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

	Select AvailableQty
	From dbo.EventActivity With (XLOCK,ROWLOCK)
	Where PK_EventActivity = @PK_EventActivity
END