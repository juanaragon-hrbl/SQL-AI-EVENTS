CREATE PROCEDURE [dbo].[usp_MYHLEventAPI_Home_TicketDetails]
	-- REQUIRED
	@PK_Event INT
   ,@DistributorID VARCHAR(20)	

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_MYHLEventAPI_Home_TicketDetails

USE:
				DECLARE @e int, @em varchar(4000)
				EXEC usp_MYHLEventAPI_Home_TicketDetails 
					@PK_Event = 3507
					,@DistributorID = '100845914'
					-- Error Parameters
					,@Error = @e OUTPUT  
					,@ErrorMessage = @em OUTPUT 
					-- QA/DEV
					,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]


DESCRIPTION:	Once Member clicks on the Tickets link (on landing Page), this API is called to check whether the member qualifies and allowed for ticket purchase for the eventid passed.

NOTES:			

VERSIONS
--------------------------------------------------------------------
1	2016-05-25		SandhyaP			Initial
2	2019-08-14		NoeG		Refactor code (SRE)
3	2019-10-30		NoeG		SRE Hardcode changed

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE()
		,@ValidDate DATETIME = '2049-12-31'

DECLARE @PK_Distributor INT
DECLARE @StartDate DATETIME

/* SET THE VALUES FOR THE DECLARED VARIABLES */
	
SELECT @Error = 0, @ErrorMessage = '';

SET @StartDate  = GETUTCDATE()

	BEGIN TRY

		SELECT 
			@PK_Distributor = nDistributorID 
		FROM 
			dbo.v_Distributor 
		WHERE 
			sDistributorID = @DistributorID

		/******************************************************************************
		select record
		******************************************************************************/

			SELECT
				 E.PK_Event
				,ISNULL(D.Qualified, 0) IsQualified
				,EK.SKUCode
				,ISNULL(T.TotalTickets, 0) TotalTickets
			FROM 
				dbo.Event E WITH(NOLOCK) 
			LEFT JOIN
				(SELECT PK_Event, MIN(SKUValidBeginUTC) SKUDate, MIN(PK_EventSKU) EventSKU 
				 FROM dbo.EventSKU WITH(NOLOCK)
				 WHERE @StartDate BETWEEN SKUValidBeginUTC AND SKUValidEndUTC AND PK_Event = @PK_Event
				 GROUP BY PK_Event) F
			ON
				F.PK_Event = E.PK_Event
			LEFT JOIN
				dbo.EventSKU EK WITH(NOLOCK)
			ON
				E.PK_Event = EK.PK_Event AND F.EventSKU = EK.PK_EventSKU
			LEFT JOIN
				(SELECT SKU.PK_Event, SKU.DistributorID, SUM(ISNULL(SKU.Quantity * ES.NumberOfTicketsPerSKU,0)) TicketsPurchased
				 FROM dbo.SKUPurchased SKU WITH(NOLOCK) INNER JOIN dbo.EventSKU ES WITH(NOLOCK) 
				 ON ES.PK_EventSKU = SKU.PK_EventSKU 
				 WHERE SKU.PK_Event = @PK_Event AND SKU.PK_Distributor_Purchaser = @PK_Distributor
				 GROUP BY SKU.PK_Event, SKU.DistributorID )A
			ON
				E.PK_Event = A.PK_Event
			LEFT JOIN
				(SELECT ETA.PK_Event, COUNT(1) TotalTickets FROM dbo.EventTicketAssignment ETA WITH(NOLOCK) WHERE ETA.PK_ToDistributor = @PK_Distributor GROUP BY ETA.PK_Event) T
			ON
				E.PK_Event = T.PK_Event
			LEFT JOIN
				(SELECT DISTINCT SQ.PK_Event, DistributorID, SQ.Qualified
				 FROM dbo.SubEventQualifier SQ WITH(NOLOCK) 
				 INNER JOIN dbo.SubEvent SE WITH(NOLOCK) ON SQ.PK_SubEvent = SE.PK_SubEvent
				 WHERE SQ.PK_Distributor = @PK_Distributor AND SQ.RemovedUTC = @ValidDate AND SE.IsMainEventQual = 1)D
			ON
				E.PK_Event = D.PK_Event     
			WHERE 
				E.PK_Event = @PK_Event

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
	END CATCH

/******************************************************************************
	end procedure
******************************************************************************/
END
GO

	