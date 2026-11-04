CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_OverrideEventTickets]
--REQUIRED
@DistributorID varchar(10)
,@PK_Event int
,@PK_SKUPurchased int
,@NTSDate datetime
,@OrderNumber varchar(20)
,@SKU varchar(5)
,@Quantity int
,@IsManual bit = 1
-- Error Parameters
,@Error	INT = 0 OUTPUT
,@ErrorMessage VARCHAR(4000) = NULL OUTPUT
-- QA/DEV
,@IsDevQA BIT = 0
  
AS
BEGIN
/******************************************************************************
	OBJECT NAME		: usp_EventAPI_Ins_OverrideEventTickets
	INPUT PARAMS	: NONE
	OUT PARAMS		: NONE
	EXEC Statement	: declare @e int, @em varchar(200)
            EXEC dbo.usp_EventAPI_Ins_OverrideEventTickets @DistributorID = '16036394'
                                                       ,@PK_Event = 30
                                                       ,@PK_SKUPurchased = 1347767
                                                       ,@NTSDate = '2009-06-06'
													   ,@OrderNumber ='123456789'
													   ,@SKU = '987X'
													   ,@Quantity = 1
                                                       ,@IsManual = 1
                                                       ,@error = @e
                                                       ,@errormessage = @em     
													   


	SOURCE TABLES	: dbo.EventSKU
			  dbo.SKUPurchased
			  dbo.EventTickets
			  dbo.v_EventCurrentQualificationToUpdate

	TARGET TABLES	: dbo.EventTickets
			  dbo.EventTicketAssignment
												
	VERSION HISTORY:
	VER	    DATE       		DEVELOPER			COMMENTS
	===	   ========  		=========			=================
   	1.0.0    06-JUN-2009	Sandhya Pendyala    First Version
	1.1.0    31-AUG-2009    Sandhya Pendyala    Update the Eventtickets & Assignment tables instead of repopulating them (group ticket module) 
	1.2.0    25-Mar-2011	Ini Ukporo			Added code to filter for only Event Ticket SKUs. That is, EventSKU.IsEventTicketSKU = 1
	1.3.0    2019-10-14     puertac				SRE Implementation 
	1.4.0	 2019-10-30		puertac				SRE Implementation - Hardcode Review

	This procedure is called on clicking the edit link under Order Information on the registration page.
    This is used to modify order information in SKUPurchased, which contains which distributors
	ordered ticket skus for the event to populate EventTickets and EventTicketsAssignment table.
	
	The procedure updates the ticket different the EventTickets and EventTicketAssignment
    based on the modifications in SKUPurchased.
******************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

DECLARE
	 @PK_EventSKU int
    ,@MaxQualCount int
	,@Quantitydiff int
	,@TicketDiff int
	,@TicketCount int
    ,@TicketsToRemove int
    ,@PK_EventTicketToRemove int
	,@PK_EventTicket int
	,@AppProgram varchar(30)
	,@AppDate datetime
	,@ToDate datetime
	,@PK_Distributor int

SET @AppProgram = 'usp_EventAPI_Ins_OverrideEventTickets'
SET @AppDate = GETUTCDATE()
SET @ToDate = '2049-12-31'

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();

SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'

IF @DistributorID IS NOT NULL
   SELECT @PK_Distributor = nDistributorID FROM dbo.v_DistributorUnionTemp WHERE sDistributorID = @DistributorID

BEGIN TRY

/*
/* Delete the dbo.EventTickets & EventTicketAssignment  */

DELETE FROM dbo.EventTicketAssignment 
WHERE PK_EventTicket IN (SELECT PK_EventTicket FROM dbo.EventTickets WHERE PK_Purchaser = @PK_Distributor AND PK_Event = @PK_Event)

DELETE FROM dbo.EventTickets WHERE PK_Purchaser = @PK_Distributor AND PK_Event = @PK_Event
*/

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

/* Get the SKU Quantity */
DECLARE eq_cursor CURSOR STATIC FOR 
	select ISNULL(Sk.PK_SKUPurchased,ET.PK_SKUPurchased) As PK_SKUPurchased
        ,ISNULL(Sk.PK_Event,ET.PK_Event) AS PK_Event
		,ISNULL(Sk.PK_EventSKU,ET.PK_EventSKU) AS PK_EventSKU
		,ISNULL(Sk.PK_Distributor_Purchaser,ET.PK_Purchaser) AS PK_Distributor_Purchaser
		,sk.DistributorID
		,sk.sku_qty - ISNULL(ET.Ticket_Qty,0) AS QuantityDiff
		,ISNULL(ET.Ticket_Qty,0) - ISNULL(sk.sku_qty,0) AS TicketDiff
from (SELECT
        S.PK_SKUPurchased
		,S.PK_Event
		,S.PK_EventSKU
		,S.DistributorID
		,S.PK_Distributor_Purchaser
		,sum(ISNULL(S.Quantity,0)) as sku_qty     --- ISNULL(ET.Ticket_Qty,0) AS Quantity
	FROM
		dbo.SKUPurchased S WITH (NOLOCK)
	INNER JOIN
		dbo.v_EventCurrentQualificationToUpdate EC
	ON
		S.PK_Event = EC.PK_Event
	INNER JOIN
		dbo.EventSKU ES WITH (NOLOCK)
	ON
		S.PK_Event = ES.PK_Event
		AND S.PK_EventSKU = ES.PK_EventSKU
		AND ES.IsEventTicketSKU = 1
    group by S.PK_Event
		,S.PK_EventSKU
		,S.PK_Distributor_Purchaser
		,S.DistributorID
        ,S.PK_SKUPurchased) sk
	FULL OUTER JOIN
		(SELECT T.PK_Event,PK_EventSKU,PK_Purchaser,count(1) AS Ticket_Qty, PK_SKUPurchased
		 FROM 
			dbo.EventTickets T WITH (NOLOCK)
		 INNER JOIN
			dbo.v_EventCurrentQualificationToUpdate CE
		ON
			T.PK_Event = CE.PK_Event
		GROUP BY
			T.PK_Event,PK_EventSKU,PK_Purchaser, PK_SKUPurchased) ET
	ON
		Sk.PK_Event = ET.PK_Event
		AND
		Sk.PK_EventSKU = ET.PK_EventSKU
		AND
		Sk.PK_Distributor_Purchaser = ET.PK_Purchaser
	WHERE
--		Sk.PK_Distributor_Purchaser IS NOT NULL
--		AND 
--		Sk.DistributorID = ISNULL(@DistributorID,Sk.DistributorID)
		ISNULL(Sk.PK_Distributor_Purchaser,ET.PK_Purchaser) = CASE WHEN @DistributorID IS NOT NULL THEN @PK_Distributor ELSE ISNULL(Sk.PK_Distributor_Purchaser,ET.PK_Purchaser) END

OPEN eq_cursor

SET @MaxQualCount = @@CURSOR_ROWS

FETCH NEXT FROM eq_cursor INTO  
    @PK_SKUPurchased
	,@PK_Event
	,@PK_EventSKU
	,@PK_Distributor
	,@DistributorID
	,@QuantityDiff
	,@TicketDiff

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @TicketCount = @QuantityDiff
	SET @TicketsToRemove = @TicketDiff
	WHILE  @TicketCount > 0
		IF @PK_Distributor IS NOT NULL
		BEGIN
			INSERT INTO dbo.EventTickets(PK_Purchaser, IsTicketUsed, CanAssignTicket, IsTicketReserved, ReservedFor, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_Event, PK_EventSKU,PK_SKUPurchased)
			VALUES(@PK_Distributor,0,1,0,NULL,@AppDate,@AppProgram,@AppDate,@AppProgram,@PK_Event,@PK_EventSKU,@PK_SKUPurchased)

			SELECT @PK_EventTicket = MAX(PK_EventTicket) FROM dbo.EventTickets WITH (NOLOCK)

			INSERT INTO dbo.EventTicketAssignment(PK_FromDistributor, PK_ToDistributor, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_EventTicket, Ticketed, ValidFromDateUTC, ValidToDateUTC, PK_Event, PK_EventSKU,PK_SKUPurchased)
			VALUES(@PK_Distributor,@PK_Distributor,@AppDate,@AppProgram,@AppDate,@AppProgram,@PK_EventTicket,1,@AppDate,@ToDate,@PK_Event,@PK_EventSKU,@PK_SKUPurchased)

			SET @TicketCount = @TicketCount - 1
        END

	WHILE  @TicketsToRemove > 0
		BEGIN
			SELECT @PK_EventTicketToRemove = MAX(E.PK_EventTicket) FROM dbo.EventTickets E WITH (NOLOCK) INNER JOIN dbo.EventTicketAssignment EA WITH (NOLOCK) ON E.PK_EventTicket = EA.PK_EventTicket
			WHERE E.PK_Purchaser = @PK_Distributor AND E.PK_Event = @PK_Event AND E.PK_EventSKU = @PK_EventSKU AND E.IsTicketUsed = 0 AND EA.PK_FromDistributor = EA.PK_ToDistributor AND EA.ValidToDateUTC = @ToDate -- Group Ticket changes (SandhyaP)

			DELETE FROM dbo.EventTicketAssignment WHERE PK_EventTicket = @PK_EventTicketToRemove 

			DELETE FROM dbo.EventTickets WHERE PK_EventTicket = @PK_EventTicketToRemove
           
			SET @TicketsToRemove = @TicketsToRemove - 1
        END

FETCH NEXT FROM eq_cursor INTO  
     @PK_SKUPurchased
	,@PK_Event
	,@PK_EventSKU
	,@PK_Distributor
	,@DistributorID
	,@QuantityDiff
	,@TicketDiff
        
END

CLOSE eq_cursor
DEALLOCATE eq_cursor

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