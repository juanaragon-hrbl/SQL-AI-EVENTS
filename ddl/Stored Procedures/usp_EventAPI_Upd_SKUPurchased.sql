CREATE PROCEDURE [dbo].[usp_EventAPI_Upd_SKUPurchased]
	-- REQUIRED
	@PK_SKUPurchased int
	-- OPTIONAL
	,@ModifiedBy varchar(50) = NULL
	,@ModifiedDateUTC smalldatetime = NULL
	,@PK_Event int = NULL
	,@PK_EventSKU int = NULL
	,@PK_Distributor_Purchaser int = NULL
	,@DistributorID varchar(10) = NULL
	,@OrderDate datetime = NULL
	,@OrderNumber varchar(10) = NULL
	,@OrderType varchar(2) = NULL
	,@Quantity int = NULL
	,@NTSDate datetime
	,@IsManual int
	,@Error int OUTPUT
	,@ErrorMessage varchar(200) OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Upd_SKUPurchased

USE:		EXEC usp_EventAPI_Upd_SKUPurchased
			@PK_SKUPurchased = 2
			,@Error = @e OUTPUT  /* @e must be defined in the local call */
			,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
			,@ModifiedBy = NULL
			,@ModifiedDateUTC = NULL
			,@PK_Event = 1
			,@PK_EventSKU  = 10
			,@PK_Distributor_Purchaser = 1
			,@DistributorID = 1
			,@OrderDate = ''
			,@OrderNumber = ''
			,@OrderType = ''
			,@Quantity = 1
			,@NTSDate = ''
			,@IsManual = 0
			,@IsDevQA = 0


DESCRIPTION:	Updates record in dbo.SKUPurchased

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SKUPurchased

VERSIONS
--------------------------------------------------------------------
1	2008-10-16	Aarti	Initial
1.1 2011-03-25	IniU	Added code to filter for only Event Ticket SKUs. That is, EventSKU.IsEventTicketSKU = 1

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime
DECLARE @GetIdentity int
DECLARE @PK_MemberQRCode int
DECLARE @MemberQRCode varchar(50)
DECLARE @SKUCode varchar(10)
DECLARE @NewSKUCode varchar(10)
DECLARE @PK_EventSKUQRCode int
DECLARE @PK_NewEventSKUQRCode int
DECLARE @PK_EventTicketQRCode int
DECLARE @PK_SKUPurchasedQRCode int
DECLARE @PK_EventTicketToRemoveQRCode int
DECLARE @DSID varchar(20)

SET @StoredProcedure = 'usp_EventAPI_Upd_SKUPurchased'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_SKUPurchased FROM dbo.SKUPurchased WITH(NOLOCK) WHERE PK_SKUPurchased = @PK_SKUPurchased)
BEGIN
	SET @Error = 106
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN
END

/******************************************************************************
set variables for update
******************************************************************************/
SELECT
	@PK_Event  = COALESCE(@PK_Event, PK_Event)
	,@PK_EventSKU  = COALESCE(@PK_EventSKU, PK_EventSKU)
	,@PK_Distributor_Purchaser = COALESCE(@PK_Distributor_Purchaser, PK_Distributor_Purchaser) 
	,@DistributorID  = COALESCE(@DistributorID, DistributorID)
	,@DSID  = COALESCE(@DistributorID, DistributorID)
	,@OrderDate  = COALESCE(@OrderDate, OrderDate)
	,@OrderNumber  = COALESCE(@OrderNumber, OrderNumber)
	,@OrderType = COALESCE(@OrderType, OrderType)
	,@Quantity  = COALESCE(@Quantity, Quantity)
	,@NTSDate = COALESCE(@NTSDate, NTSDate)
	,@IsManual = COALESCE(@IsManual, IsManual)
FROM 
	dbo.SKUPurchased WITH(NOLOCK)
WHERE 
	PK_SKUPurchased = @PK_SKUPurchased
	
/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_Event FROM dbo.Event WITH(NOLOCK) WHERE PK_Event = @PK_Event)
BEGIN
	SET @Error = 5
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN
END
/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_EventSKU FROM dbo.EventSKU WITH(NOLOCK) WHERE PK_EventSKU = @PK_EventSKU)
BEGIN
	SET @Error = 58
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN
END

/******************************************************************************
Duplicates of PK_Event, PK_EventSKU, DistributorID and OrderNumber Not Allowed
******************************************************************************/
IF EXISTS(SELECT PK_SKUPurchased FROM dbo.SKUPurchased with (nolock) WHERE PK_Event = @PK_Event AND PK_EventSKU = @PK_EventSKU AND 
          PK_Distributor_Purchaser = @PK_Distributor_Purchaser AND DistributorID = @DistributorID AND 
		  ISNULL(OrderNumber,'X') = ISNULL(@OrderNumber,'X') AND PK_SKUPurchased <> @PK_SKUPurchased)
BEGIN
	SET @Error = 239
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

/******************************************************************************
update record
******************************************************************************/
BEGIN TRY

	UPDATE SP
	SET
		[ModifiedBy] = ISNULL(@ModifiedBy,replace(suser_sname(),'HERBALIFECORP\',''))
		,[ModifiedDateUTC] = ISNULL(@ModifiedDateUTC,GetUTCdate())
		,[PK_Event] = @PK_Event
		,[PK_EventSKU] = @PK_EventSKU
		,[PK_Distributor_Purchaser] = @PK_Distributor_Purchaser
		,[DistributorID] = @DistributorID
		,[OrderDate] = @OrderDate
		,[OrderNumber] = @OrderNumber
		,[OrderType] = @OrderType
		,[Quantity] = @Quantity
		,[NTSDate] = @NTSDate
		,[IsManual] = @IsManual
	FROM 
		dbo.SKUPurchased SP
	WHERE 
	PK_SKUPurchased = @PK_SKUPurchased

---- Call Stored Procedure to explode sku purchased data into event tickets and event ticket assignment tables for this distributor
--	EXEC dbo.usp_Event_UpdateEventTickets @DistributorID

/******************************************************************************
	Update Tickets in EventTickets & EventTicketAssignment
******************************************************************************/

DECLARE
	 @QuantityDiff int
	,@MaxQualCount int
	,@TicketCount int
	,@TicketDiff int
	,@TicketsToRemove int
	,@PK_EventTicket int
	,@AppProgram varchar(30)
	,@AppDate datetime
	,@PK_EventTicketToRemove int
	,@ToDate datetime
	
	
SET @AppDate = @StartTime
SET @AppProgram = @StoredProcedure
SET @ToDate = '2049-12-31'

DECLARE eq_cursor CURSOR STATIC FOR 
	select Sk.PK_SKUPurchased As PK_SKUPurchased
        ,ISNULL(Sk.PK_Event,ET.PK_Event) AS PK_Event
		,ISNULL(Sk.PK_EventSKU,ET.PK_EventSKU) AS PK_EventSKU
		,ISNULL(Sk.PK_Distributor_Purchaser,ET.PK_Purchaser) AS PK_Distributor_Purchaser
		,sk.DistributorID
		,sk.sku_qty - ISNULL(ET.Ticket_Qty,0) AS Quantity
		,ISNULL(ET.Ticket_Qty,0) - ISNULL(sk.sku_qty,0) AS TicketDiff
from (SELECT
        S.PK_SKUPurchased
		,S.PK_Event
		,S.PK_EventSKU
		,S.DistributorID
		,S.PK_Distributor_Purchaser
		,sum(ISNULL(S.Quantity * ES.NumberOfTicketsPerSKU,0)) as sku_qty     --- ISNULL(ET.Ticket_Qty,0) AS Quantity
	FROM
		dbo.SKUPurchased S (NOLOCK)
	INNER JOIN
	    dbo.EventSKU ES (NOLOCK)
	ON
	    S.PK_Event = ES.PK_Event
	    AND S.PK_EventSKU = ES.PK_EventSKU
	    AND ES.IsEventTicketSKU = 1
	INNER JOIN
		dbo.v_EventCurrentQualificationToUpdate EC WITH (NOLOCK)
	ON
		S.PK_Event = EC.PK_Event
    group by S.PK_Event
		,S.PK_EventSKU
		,S.PK_Distributor_Purchaser
		,S.DistributorID
        ,S.PK_SKUPurchased) sk
	FULL OUTER JOIN
		(SELECT T.PK_Event,PK_EventSKU,PK_Purchaser, PK_SKUPurchased, count(1) AS Ticket_Qty
		 FROM 
			dbo.EventTickets T WITH(NOLOCK)
		 INNER JOIN
			dbo.v_EventCurrentQualificationToUpdate CE WITH (NOLOCK)
		ON
			T.PK_Event = CE.PK_Event
		GROUP BY
			T.PK_Event,PK_EventSKU,PK_Purchaser,PK_SKUPurchased) ET
	ON
		Sk.PK_Event = ET.PK_Event
		AND
		Sk.PK_EventSKU = ET.PK_EventSKU
		AND
		Sk.PK_Distributor_Purchaser = ET.PK_Purchaser
        AND
        Sk.PK_SKUPurchased = ET.PK_SKUPurchased
	WHERE
		ISNULL(Sk.PK_Distributor_Purchaser,ET.PK_Purchaser) = CASE WHEN @DistributorID IS NOT NULL THEN @PK_Distributor_Purchaser ELSE ISNULL(Sk.PK_Distributor_Purchaser,ET.PK_Purchaser) END

OPEN eq_cursor

SET @MaxQualCount = @@CURSOR_ROWS

FETCH NEXT FROM eq_cursor INTO  
    @PK_SKUPurchased
	,@PK_Event
	,@PK_EventSKU
	,@PK_Distributor_Purchaser
	,@DistributorID
	,@QuantityDiff
	,@TicketDiff

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @TicketCount = @QuantityDiff
	SET @TicketsToRemove = @TicketDiff
	WHILE  @TicketCount > 0
		IF @PK_Distributor_Purchaser IS NOT NULL
		BEGIN
			INSERT INTO dbo.EventTickets(PK_Purchaser, IsTicketUsed, CanAssignTicket, IsTicketReserved, ReservedFor, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_Event, PK_EventSKU,PK_SKUPurchased)
			VALUES(@PK_Distributor_Purchaser,0,1,0,NULL,@AppDate,@AppProgram,@AppDate,@AppProgram,@PK_Event,@PK_EventSKU,@PK_SKUPurchased)

			SELECT @PK_EventTicket = MAX(PK_EventTicket) FROM dbo.EventTickets (NOLOCK)

			INSERT INTO dbo.EventTicketAssignment(PK_FromDistributor, PK_ToDistributor, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_EventTicket, Ticketed, ValidFromDateUTC, ValidToDateUTC, PK_Event, PK_EventSKU,PK_SKUPurchased)
			VALUES(@PK_Distributor_Purchaser,@PK_Distributor_Purchaser,@AppDate,@AppProgram,@AppDate,@AppProgram,@PK_EventTicket,1,@AppDate,@ToDate,@PK_Event,@PK_EventSKU,@PK_SKUPurchased)

			SET @GetIdentity = @@IDENTITY 
			
			SET @TicketCount = @TicketCount - 1
        END
		
	WHILE  @TicketsToRemove > 0
		BEGIN
			SELECT @PK_EventTicketToRemove = MAX(E.PK_EventTicket) FROM dbo.EventTickets E (NOLOCK) INNER JOIN dbo.EventTicketAssignment (NOLOCK) EA ON E.PK_EventTicket = EA.PK_EventTicket
			WHERE E.PK_Purchaser = @PK_Distributor_Purchaser AND E.PK_Event = @PK_Event AND E.PK_EventSKU = @PK_EventSKU AND E.IsTicketUsed = 0 AND EA.PK_FromDistributor = EA.PK_ToDistributor AND EA.ValidToDateUTC = '2049-12-31' -- Group Ticket changes (SandhyaP)

			DELETE FROM dbo.EventTicketAssignment WHERE PK_EventTicket = @PK_EventTicketToRemove 

			DELETE FROM dbo.EventTickets WHERE PK_EventTicket = @PK_EventTicketToRemove
           
			SET @TicketsToRemove = @TicketsToRemove - 1
        END

FETCH NEXT FROM eq_cursor INTO  
    @PK_SKUPurchased
	,@PK_Event
	,@PK_EventSKU
	,@PK_Distributor_Purchaser
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
	end procedure
******************************************************************************/
END