CREATE PROCEDURE dbo.usp_fix_duplicates_SKUPurchased
       @IsDevQA		BIT = 0,   
	   @Error	int = 0 OUTPUT,
	   @ErrorMessage varchar(4000) = NULL OUTPUT


AS
BEGIN
 
/*********************************************************************************************************************
	OBJECT:		dbo.usp_fix_duplicates_SKUPurchased
		
	USE:			
			DECLARE @e int, @em varchar(max)
			
			EXEC dbo.usp_fix_duplicates_SKUPurchased 
				
				@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
	NOTES:		

	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	SQL SERVER 2010
	
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1	
	2	2019-10-16   JonathanO  	Initial 

***********************************************************************************************************************************/
/***********************************************************************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = 'usp_fix_duplicates_SKUPurchased'
	,@StartTime datetime2 = GETUTCDATE();

	SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

SELECT ETA.PK_EventTicketAssignment
	  ,ETA.PK_FromDistributor
	  ,ETA.PK_ToDistributor
	  ,ETA.CreatedDateUTC
	  ,ETA.CreatedBy
	  ,ETA.ModifiedDateUTC
	  ,ETA.ModifiedBy
	  ,ETA.PK_EventTicket
	  ,ETA.Ticketed
	  ,ETA.ValidFromDateUTC
	  ,ETA.ValidToDateUTC
	  ,ETA.PK_Event
	  ,ETA.PK_EventSKU
	  ,ETA.PK_SKUPurchased
into #AssignedTickets
FROM dbo.EventTicketAssignment ETA WITH (NOLOCK)
INNER JOIN
	dbo.EventTickets ET WITH (NOLOCK)
ON
	ETA.PK_EventTicket = ET.PK_EventTicket
	AND
	ETA.PK_SKUPurchased = ET.PK_SKUPurchased
	AND
	ET.PK_Event = ETA.PK_Event		
INNER JOIN
	dbo.SKUPurchased SP WITH (NOLOCK)
ON
	SP.PK_Event = ET.PK_Event
	AND
	SP.PK_EventSKU = ET.PK_EventSKU	
	AND
	SP.PK_SKUPurchased = ET.PK_SKUPurchased	
WHERE ETA.PK_Event = 732 and PK_FromDistributor = 4383787 
AND PK_FromDistributor = PK_ToDistributor and ValidToDateUTC = '2049-12-31' 
AND ETA.PK_SKUPurchased in (28023865,28023868, 28023869, 28023870)
AND ET.IsTicketUsed = 0


/* DELETE FROM dbo.EventTicketAssignment */

DELETE ETA 
FROM dbo.EventTicketAssignment ETA
INNER JOIN
#AssignedTickets AT
ON
 ETA.PK_EventTicketAssignment = AT.PK_EventTicketAssignment
 AND
 ETA.PK_Event = AT.PK_Event
 AND
 ETA.PK_EventTicket = AT.PK_EventTicket


SELECT et.PK_EventTicket, PK_Event, PK_SKUPurchased
INTO #EventTickets
FROM EventTickets et WITH (NOLOCK)
WHERE PK_Event = 732 
AND PK_Purchaser = 4383787
AND PK_SKUPurchased in (28023865,28023868, 28023869, 28023870)
AND IsTicketUsed = 0
INTERSECT
SELECT et.PK_EventTicket, PK_Event, PK_SKUPurchased
FROM #AssignedTickets et
WHERE PK_FromDistributor = 4383787



/* DELETE FROM dbo.EventTickets*/

DELETE ET 
FROM dbo.EventTickets ET
INNER JOIN
#EventTickets AT
ON
 ET.PK_EventTicket = AT.PK_EventTicket
 AND
 ET.PK_Event = AT.PK_Event
 AND
 ET.PK_SKUPurchased = AT.PK_SKUPurchased




SELECT PK_FromDistributor, PK_SKUPurchased, PK_Event, COUNT(*) AS SKU_Quantity
INTO #SKU_Quantity
FROM EventTicketAssignment ETA WITH (NOLOCK)
WHERE ETA.PK_Event = 732 and PK_FromDistributor = 4383787 
AND PK_FromDistributor != PK_ToDistributor and ValidToDateUTC = '2049-12-31' 
AND ETA.PK_SKUPurchased in (28023865,28023868, 28023869, 28023870)
GROUP BY PK_FromDistributor, PK_SKUPurchased, PK_Event


/* UPDATE SKUPurchased */

UPDATE S
SET
	Quantity = SQ.SKU_Quantity
FROM dbo.SKUPurchased S
INNER JOIN 
#SKU_Quantity SQ
ON
	S.PK_SKUPurchased = SQ.PK_SKUPurchased
	AND
	S.PK_Distributor_Purchaser = SQ.PK_FromDistributor
	AND
	S.PK_Event = SQ.PK_Event


		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;
	
	

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

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;