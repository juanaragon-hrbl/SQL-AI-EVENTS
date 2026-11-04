
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_EventDistributorHotelInfo]
	-- REQUIRED
	@DistributorID varchar(40)
	,@PK_Event INT = 620
	-- OPTIONAL
		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************

OBJECT:			dbo.usp_EventAPI_Get_EventDistributorHotelInfo

	USE:			
			DECLARE @e int, @em varchar(4000)

			EXEC [dbo].[usp_EventAPI_Get_EventDistributorHotelInfo]
				@DistributorID = '38854317'  
				,@PK_Event = 59881
				,@Error = @e output
				,@ErrorMessage = @em output
				,@IsDevQA = 0

			SELECT @e AS [Error], @em AS [ErrorMessage]

DESCRIPTION:	Deletes record from dbo.EventHotel

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventHotel

VERSIONS
--------------------------------------------------------------------
1	2011-08-2	Jahnavi/chandan	Initial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		/******************************************************************************
		select record
		******************************************************************************/
			select
		a.PK_EventDistributorHotel,
		a.DistributorID,
		a.Nights,
		a.Rooms,
		a.GuestPerRoom,
		a.RoomType,
		a.checkedIn ,
		a.CheckInDate,
		a.CheckOutDate,
		c.hotelName,
		a.Comments
		from 
		dbo.EventDistributorHotel a WITH (NOLOCK)
		inner join dbo.EventHotel b WITH (NOLOCK) on a.pk_eventHotel= b.pk_eventHotel
		Inner join dbo.hotelinfo c WITH (NOLOCK) on b.PK_HotelInfo =c.PK_HotelInfo
		where DistributorID = @DistributorID
		and b.PK_Event = @PK_Event
		 
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

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime

	/******************************************************************************
		end procedure
	******************************************************************************/
END
GO

