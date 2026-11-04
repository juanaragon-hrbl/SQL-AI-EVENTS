CREATE PROCEDURE [dbo].[usp_EventAPI_Del_DeleteOrder]
--OPTIONAL
 @DistributorID varchar(10)
,@PK_Event int
,@PK_SKUPurchased int
-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT 
-- QA/DEV
,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
	OBJECT NAME		: usp_EventAPI_Del_DeleteOrder
	INPUT PARAMS	: NONE
	OUT PARAMS		: NONE
	EXEC Statement	: DECLARE @e int, @em varchar(200)
                      EXEC dbo.usp_EventAPI_Del_DeleteOrder @DistributorID = '26535780'
                                                       ,@PK_Event = 88
                                                       ,@PK_SKUPurchased = 4734705
                                                       ,@Error = @e OUTPUT
													   ,@ErrorMessage = @em OUTPUT
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
	VER	DATE       		     DEVELOPER			COMMENTS
	===	     ========  		=========			=================
	1.0.0 	06-Jun-2009		Sandhya Pendyala	First Version
	1.1.0   26-Aug-2009     Sandhya Pendyala    Changes for group tickets
	1.2.0   21-May-2019		Alejandra Medina	Homologating of standard error handling
	1.3.0   15-Jul-2019		Alejandra Medina	Setting error parameters as optionals
	1.4.0   2019-10-14      puertac				SRE Implementation 
	1.5.0	2022-09-09		alejandramed		Removing EventQRCode references

	The procedure is used to delete the distributor order on the registration page
******************************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

DECLARE
  @PK_Distributor int
 ,@PK_SubEvent int
 ,@AppProgram varchar(100)
 ,@AppDate datetime
 ,@SubEventID varchar(50)
 ,@PK_EventSKU int
 ,@MaxQualCount int
 ,@Quantity_diff int
 ,@TicketCount int
 ,@PK_EventTicket int
 ,@ToDate datetime
 ,@UserID varchar(50)
 ,@IsTicketUsed bit
 ,@IsTicketAssigned bit
 ,@IsTicketAssignedQRCode bit
 ,@PK_SKUPurchasedQRCode int
 ,@PK_EventSKUQRCode int
 ,@SKUCode varchar(10)


IF @DistributorID IS NOT NULL
   SELECT @PK_Distributor = nDistributorID FROM dbo.v_DistributorUnionTemp WITH (NOLOCK) WHERE sDistributorID = @DistributorID

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
                           WHEN Count(isticketused) >= 1 THEN 1 
                           ELSE 0 
                         END 
  FROM   dbo.eventtickets WITH (NOLOCK)
  WHERE  pk_event = @PK_Event 
         AND pk_skupurchased = @PK_SKUPurchased 
         AND pk_purchaser = @PK_Distributor 
         AND isticketused = 1 
   
  /* Delete the order if the tickets are not used otherwise cannot delete the order */ 
  IF @IsTicketUsed = 0 
    BEGIN 
 
      /* Delete the Registration entries */ 
      DELETE FROM subeventregistration 
      WHERE       pk_eventsregistration IN (SELECT pk_eventsregistration 
                                            FROM   eventsregistration WITH (NOLOCK)
                                            WHERE  pk_event = @PK_Event 
                                                   AND pk_distributor = @PK_Distributor
                                                   AND PK_EventTicket IN (SELECT PK_EventTicket 
                                                                          FROM dbo.eventtickets WITH (NOLOCK)
                                                                          WHERE pk_event = @PK_Event 
                                                                          AND pk_purchaser = @PK_Distributor 
                                                                          AND pk_skupurchased = @PK_SKUPurchased) )
       
      DELETE FROM eventsregistration 
      WHERE       pk_event = @PK_Event 
                  AND pk_distributor = @PK_Distributor 
                  AND PK_EventTicket IN (SELECT PK_EventTicket 
                                         FROM dbo.eventtickets WITH (NOLOCK)
                                         WHERE pk_event = @PK_Event 
                                         AND pk_purchaser = @PK_Distributor 
                                         AND pk_skupurchased = @PK_SKUPurchased) 
       

      /* Delete the dbo.EventTickets & EventTicketAssignment  */ 
      DELETE FROM dbo.eventticketassignment 
      WHERE       pk_event = @PK_Event 
                  AND pk_fromdistributor = @PK_Distributor 
                  AND pk_skupurchased = @PK_SKUPurchased 
--                  AND validtodateutc = '2049-12-31' 
       
      DELETE FROM dbo.eventtickets 
      WHERE       pk_purchaser = @PK_Distributor 
                  AND pk_event = @PK_Event 
                  AND pk_skupurchased = @PK_SKUPurchased 
       
		DECLARE  @e  INT, 
               @em VARCHAR(200) 
       
		  EXEC Usp_eventapi_del_skupurchased 
			@PK_SKUPurchased = @PK_SKUPurchased , 
			@Error = @e OUTPUT  /* @e must be defined in the local call */ , 
			@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */ 
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

	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure
			,@ErrorNumber = 3
			,@ErrorMessage = @ErrorMessage OUTPUT
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