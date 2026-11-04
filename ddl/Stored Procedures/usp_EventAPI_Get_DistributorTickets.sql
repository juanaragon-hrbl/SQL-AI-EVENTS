
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_DistributorTickets]
    -- REQUIRED
   @DistributorID varchar(10)
  ,@EventID int

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0

AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_DistributorTickets
USE:			

			DECLARE @e int, @em varchar(4000)
			EXEC usp_EventAPI_Get_DistributorTickets @DistributorID = '16533128'--'20234823'
					,@EventID=376
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves records from dbo.EventSKU AND dbo.SKUPurchased if the DS purchased the ticket
NOTES:			
DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent
VERSIONS
--------------------------------------------------------------------
1	2009-01-22	Sandhya		Initial
2	2019-09-30	NoeG		SRE template applied
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	/******************************************************************************
	 Check if Distributor exist
	******************************************************************************/

	IF EXISTS  (SELECT nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
				UNION
				SELECT PK_Temp FROM dbo.TempDistributors WITH(NOLOCK) WHERE DistributorID = @DistributorID)
   
	BEGIN

 
		/******************************************************************************
		select record from SubEventQualifiers
		******************************************************************************/

		BEGIN
    
				SELECT DISTINCT
					S.PK_SKUPurchased
				   ,S.DistributorID
				   ,S.Orderdate
				   ,S.OrderNumber
				   ,(S.Quantity * ES.NumberOfTicketsPerSKU) AS Quantity
				   ,ES.SKUCode
				   ,S.IsManual
				   ,CASE WHEN ET.IsTicketUsed >= 1 THEN 1 ELSE 0 END IsTicketUsed
				FROM 
				   dbo.SKUPurchased S WITH(NOLOCK)
				INNER JOIN
				   dbo.EventSKU ES WITH(NOLOCK)
				 ON 
				   S.PK_EventSKU = ES.PK_EventSKU
				   AND IsEventTicketSKU = 1
				INNER JOIN
				   dbo.Event E WITH(NOLOCK)
				 ON 
				   ES.PK_Event = E.PK_Event  
				LEFT JOIN
				   (SELECT PK_Event, PK_Purchaser, COUNT(IsTicketUsed) IsTicketUsed
					FROM EventTickets WITH(NOLOCK)
					WHERE IsTicketUsed = 1
					GROUP BY  PK_Event, PK_Purchaser) ET
				 ON 
				   ET.PK_Event = E.PK_Event 
				   AND
				   ET.PK_Purchaser = S.PK_Distributor_Purchaser 
				WHERE
				   E.PK_Event = @EventID
				   AND
				   S.DistributorID = @DistributorID

		 END
	END

	ELSE

	BEGIN
		SET @Error = 8
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN
	END

	-- Update processing Log
	EXEC dbo.usp_Utility_UpdateProcessingLog 
		@StoredProcedureName = @StoredProcedure
		,@StartTime = @StartTime  

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

/******************************************************************************
	end procedure
******************************************************************************/
END