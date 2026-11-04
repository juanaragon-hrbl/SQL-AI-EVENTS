CREATE PROCEDURE [dbo].[usp_EventAPI_Upd_UpdateOrder]
 @DistributorID varchar(10)
,@PK_Event int
,@PK_SKUPurchased int
,@NTSDate datetime
,@IsManual bit = 1
,@OrderNumber varchar(20)
,@SKU varchar(5)
,@Quantity int
,@UserID varchar(50)
,@GroupTickets bit = 0
,@HasCheckedIn bit = 1

-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT

-- QA/DEV
,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
	OBJECT NAME		: usp_EventAPI_Upd_UpdateOrder
	INPUT PARAMS	: NONE
	OUT PARAMS		: NONE
	EXEC Statement	: 
		DECLARE @e int, @em varchar(4000)
       EXEC dbo.usp_EventAPI_Upd_UpdateOrder @DistributorID = '1111111111'
        ,@PK_Event = 30
        ,@PK_SKUPurchased = 1415582
        ,@NTSDate = '2009-06-10'
        ,@OrderNumber = null
        ,@SKU = 'D061'
        ,@Quantity = 3
        ,@IsManual = 1
        ,@UserID = 'scottb'
        ,@GroupTickets = 0
        ,@HasCheckedIn = 1
        ,@error = @e OUTPUT
        ,@errormessage = @em OUTPUT
        ,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]

	SOURCE TABLES	: LS_USLAXBIDB02.dbo.EventSKU
					  LS_USLAXBIDB02.dbo.Schedule
					  LS_USLAXBIDB02.dbo.EventSchedule
					  LS_USLAXBIDB02.dbo.SKUPurchased
					  LS_USLAXBIDB02.dbo.EventTickets
					  LS_USLAXBIDB02.dbo.v_EventCurrentQualificationToUpdate

	TARGET TABLES	: LS_USLAXBIDB02.dbo.EventTickets
					  LS_USLAXBIDB02.dbo.EventTicketAssignment
												
	VERSION HISTORY:
	VER	DATE       		DEVELOPER			COMMENTS
	===	========  		=========			=================
	1.2	15-Jul-2019		Alejandra Medina	Setting error parameters as optionals
    1.1 31-AUG-09       Sandhya Pendyala    group tickets changes
	1.0	05-Jun-2009		Sandhya Pendyala	First Version

	This procedure uses SKUPurchased, which contains which distributors
	ordered ticket skus for the event to populate EventTickets and EventTicketsAssignment table.
	
	The procedure checks the quantity difference between SKUPurchased and EventTickets table by 
	Event, SKU and Distributor and uses the difference or surplus to create additional entry(ies)
	EventTickets and EventTicketAssignment.

******************************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

DECLARE
  @PK_Distributor int
 ,@PK_SubEvent int
 ,@AppProgram varchar(100)
 ,@AppDate datetime
 ,@PK_EventsRegistration int
 ,@IsTicketUsed int
 ,@IsTicketAssigned int
 ,@PK_EventSKU int

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

IF @DistributorID IS NOT NULL
   SELECT @PK_Distributor = nDistributorID FROM dbo.v_DistributorUnionTemp WHERE sDistributorID = @DistributorID

BEGIN TRY 

   SELECT @IsTicketAssigned = CASE WHEN  count(eta.pk_eventticket) >= 1 THEN 1 ELSE 0 END
   FROM eventticketassignment eta WITH (NOLOCK)
        INNER JOIN
        eventtickets et WITH (NOLOCK)
         ON eta.pk_eventticket = et.pk_eventticket
         AND eta.pk_event = @PK_Event
         AND eta.PK_SKUPurchased = @PK_SKUPurchased
         AND eta.pk_fromdistributor = @PK_Distributor 
         AND eta.pk_fromdistributor != pk_Todistributor
         --AND eta.ValidToDateUTC = '2049-12-31'

	 If @IsTicketAssigned = 0
	 BEGIN 

	  /* To modify an order, Check if any of the tickets has already been used to register for that order. 
	   If any ticket has been used, cannot modify the order.  */ 
	  SELECT @IsTicketUsed = CASE 
							   WHEN Count(IsTicketUsed) >= 1 THEN 1 
							   ELSE 0 
							 END 
	  FROM   dbo.eventtickets WITH (NOLOCK)
	  WHERE  pk_event = @PK_Event 
			 AND pk_skupurchased = @PK_SKUPurchased 
			 AND pk_purchaser = @PK_Distributor 
			 AND isticketused = 1 
  
 
	  /********* Modify the order if the ticket has not been used otherwise order cannot be modified *************/ 
	  IF @IsTicketUsed = 0 
		BEGIN 
		  /* 
	  DELETE FROM SubEventRegistration WHERE PK_EventsRegistration IN (SELECT PK_EventsRegistration FROM EventsRegistration WHERE PK_Event = @PK_Event AND PK_Distributor = @PK_Distributor) 
	  DELETE FROM EventsRegistration WHERE PK_Event = @PK_Event AND PK_Distributor = @PK_Distributor 
	  END 
		  */ 
		  --DECLARE  @e  INT, 
		  --         @em VARCHAR(200) 
       
		  --/* Update ticket information */ 
		  --EXEC dbo.Usp_eventapi_ins_overrideeventtickets 
		  --  @DistributorID = @DistributorID , 
		  --  @PK_Event = @PK_Event , 
		  --  @PK_SKUPurchased = @PK_SKUPurchased , 
		  --  @NTSDate = @NtsDate , 
		  --  @OrderNumber = @OrderNumber , 
		  --  @SKU = @SKU , 
		  --  @Quantity = @Quantity , 
		  --  @IsManual = @IsManual , 
		  --  @Error = @e OUTPUT  /* @e must be defined in the local call */ , 
		  --  @ErrorMessage = @em OUTPUT /* @em must be defined in the local call */ 
        
			/* Get the PK of SKU Value */
	SELECT @PK_EventSKU = PK_EventSKU FROM dbo.EventSKU WITH (NOLOCK) WHERE PK_Event = @PK_Event AND SKUCode = @SKU

	/* Modify the Order information in SKUPurchasedtable */
	DECLARE @e int, @em varchar(200)
	EXEC usp_EventAPI_Upd_SKUPurchased @PK_SKUPurchased = @PK_SKUPurchased
									  ,@NTSDate = @NtsDate
									  ,@IsManual = @IsManual
									  ,@OrderNumber = @OrderNumber
									  ,@PK_EventSKU = @PK_EventSKU
									  ,@Quantity = @Quantity
									  ,@Error = @e OUTPUT  /* @e must be defined in the local call */
									  ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */ 

		END 
	  ELSE 
		BEGIN 
		  SET @Error = 269 
       
		  -- Update ErrorLog 
		  EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure , 
			@ErrorNumber = @Error , 
			@ErrorMessage = @ErrorMessage OUTPUT 
       
		  RETURN 
		END 
	 END
	  ELSE 
		BEGIN 
		  SET @Error = 270 
       
		  -- Update ErrorLog 
		  EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure , 
			@ErrorNumber = @Error , 
			@ErrorMessage = @ErrorMessage OUTPUT 
       
		  RETURN 
		END 
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
END CATCH

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime

/******************************************************************************
                    End Procedure
******************************************************************************/

END
GO

