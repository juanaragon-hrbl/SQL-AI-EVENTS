CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_SKUPurchased]
	@ModifiedBy varchar(50)
	,@PK_Event int
	,@PK_EventSKU int
	,@PK_Distributor_Purchaser int
	,@DistributorID varchar(10)
	,@OrderDate datetime
	,@OrderNumber varchar(10)
	,@OrderType varchar(2)
	,@Quantity int
	,@NTSDate datetime
	,@IsManual bit

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_EventAPI_Ins_SKUPurchased

USE:
		DECLARE @e int, @em varchar(4000)

		EXEC usp_EventAPI_Ins_SKUPurchased
					@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@ModifiedBy = ''
					,@PK_Event = 1
					,@PK_EventSKU  = 1
					,@PK_Distributor_Purchaser = 1
					,@DistributorID = 1
					,@OrderDate = ''
					,@OrderNumber = ''
					,@OrderType = ''
					,@Quantity = 1
					,@NTSDate = ''
					,@IsManual = 0
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Inserts record into dbo.SKUPurchased

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SKUPurchased

VERSIONS
--------------------------------------------------------------------
1	2008-10-16	Aarti			Initial
1.1 2011-03-25	IniU			Added code to filter out non event ticket SKUs. That is, only EventSKU.IsEventTicketSKU = 1
1.2	2019-09-05	NoeG			SRE template applied
1.3	2022-09-09	alejandramed	Removing EventQRCode references
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

DECLARE @GetIdentity int
DECLARE @PK_MemberQRCode int
DECLARE @MemberQRCode varchar(50)
DECLARE @SKUCode varchar(10)
DECLARE @PK_EventSKUQRCode int
DECLARE @PK_EventTicketQRCode int
DECLARE @PK_SKUPurchasedQRCode int
DECLARE @PK_EventTicketToRemoveQRCode int


/******************************************************************************
Check and get PK Distributor ID
******************************************************************************/
IF EXISTS (SELECT nDistributorID FROM dbo.v_DistributorUnionTemp WHERE sDistributorID = @DistributorID)
  BEGIN
   SELECT @PK_Distributor_Purchaser = nDistributorID FROM dbo.v_DistributorUnionTemp WHERE sDistributorID = @DistributorID
  END
ELSE
  BEGIN
	SET @Error = 8
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
  END

/******************************************************************************
be sure record is unique
******************************************************************************/
IF EXISTS(SELECT PK_SKUPurchased FROM dbo.SKUPurchased with (nolock) WHERE PK_Event = @PK_Event AND PK_EventSKU = @PK_EventSKU AND 
          PK_Distributor_Purchaser = @PK_Distributor_Purchaser AND DistributorID = @DistributorID AND 
		  OrderDate = @OrderDate AND OrderNumber = @OrderNumber AND OrderType = @OrderType AND Quantity = @Quantity AND NTSDate = @NTSDate)
BEGIN
	SET @Error = 239
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
		  ISNULL(OrderNumber,'X') = ISNULL(@OrderNumber,'X'))
BEGIN
	SET @Error = 239
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

/******************************************************************************
be sure the value of FK exists in referenced table
******************************************************************************/
IF NOT EXISTS(SELECT PK_Event FROM dbo.Event with (nolock) WHERE PK_Event = @PK_Event)
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
IF NOT EXISTS(SELECT PK_EventSKU FROM dbo.EventSKU with (nolock) WHERE PK_EventSKU = @PK_EventSKU AND PK_Event = @PK_Event AND IsEventTicketSKU = 1)
BEGIN
	SET @Error = 58
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN
END

/******************************************************************************
insert record
******************************************************************************/
BEGIN TRY

	INSERT
		dbo.SKUPurchased
	(
		[ModifiedBy]
		,[PK_Event]
		,[PK_EventSKU]
		,[PK_Distributor_Purchaser]
		,[DistributorID]
		,[OrderDate]
		,[OrderNumber]
		,[OrderType]
		,[Quantity]
		,[NTSDate]
		,[IsManual]
	)
	SELECT
		@ModifiedBy 
		,@PK_Event 
		,@PK_EventSKU 
		,@PK_Distributor_Purchaser 
		,@DistributorID 
		,@OrderDate 
		,@OrderNumber 
		,@OrderType
		,@Quantity 
		,@NTSDate
		,@IsManual

	---- Call Stored Procedure to explode sku purchased data into event tickets and event ticket assignment tables for this distributor
	--	EXEC dbo.usp_Event_UpdateEventTickets @DistributorID

	/******************************************************************************
		Update Tickets in EventTickets & EventTicketAssignment
	******************************************************************************/

	DECLARE
		 @PK_SKUPurchased int
		,@QuantityDiff int
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
			dbo.SKUPurchased S  WITH (NOLOCK)
		INNER JOIN
			dbo.EventSKU ES  WITH (NOLOCK)
		ON
			S.PK_Event = ES.PK_Event
			AND S.PK_EventSKU = ES.PK_EventSKU
			AND ES.IsEventTicketSKU = 1
		INNER JOIN
			dbo.v_EventCurrentQualificationToUpdate EC
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
				dbo.EventTickets T  WITH (NOLOCK)
			 INNER JOIN
				dbo.v_EventCurrentQualificationToUpdate CE
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
			AND
			Sk.PK_Event = @PK_Event

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

				SELECT @PK_EventTicket = MAX(PK_EventTicket) FROM dbo.EventTickets WITH (NOLOCK)

				INSERT INTO dbo.EventTicketAssignment(PK_FromDistributor, PK_ToDistributor, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_EventTicket, Ticketed, ValidFromDateUTC, ValidToDateUTC, PK_Event, PK_EventSKU,PK_SKUPurchased)
				VALUES(@PK_Distributor_Purchaser,@PK_Distributor_Purchaser,@AppDate,@AppProgram,@AppDate,@AppProgram,@PK_EventTicket,1,@AppDate,@ToDate,@PK_Event,@PK_EventSKU,@PK_SKUPurchased)

				SET @GetIdentity = @@IDENTITY 

				SET @TicketCount = @TicketCount - 1
			END

		WHILE  @TicketsToRemove > 0
			BEGIN
				SELECT @PK_EventTicketToRemove = MAX(E.PK_EventTicket) FROM dbo.EventTickets E WITH (NOLOCK) INNER JOIN dbo.EventTicketAssignment EA WITH (NOLOCK) ON E.PK_EventTicket = EA.PK_EventTicket
				WHERE E.PK_Purchaser = @PK_Distributor_Purchaser AND E.PK_Event = @PK_Event AND E.PK_EventSKU = @PK_EventSKU AND E.IsTicketUsed = 0 AND EA.PK_FromDistributor = EA.PK_ToDistributor AND EA.ValidToDateUTC = '2049-12-31' -- Group Ticket changes (SandhyaP)

				DELETE FROM dbo.EventTicketAssignment WHERE PK_EventTicket = @PK_EventTicketToRemove 

				DELETE FROM dbo.EventTickets WHERE PK_EventTicket = @PK_EventTicketToRemove
           
				SET @TicketsToRemove = @TicketsToRemove - 1
			END
        
	PRINT @PK_SKUPurchased
	PRINT @PK_EventSKU
	PRINT @PK_Distributor_Purchaser
	PRINT @DistributorID
	PRINT @QuantityDiff
	PRINT @TicketDiff        

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
	end procedure
******************************************************************************/
END
GO

