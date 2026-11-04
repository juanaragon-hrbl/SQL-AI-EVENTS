CREATE PROCEDURE [dbo].[usp_Event_UpdateEventTickets]
	@DistributorID varchar(10) = NULL

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
	OBJECT NAME		: usp_Event_UpdateEventTickets
	INPUT PARAMS	: NONE
	OUT PARAMS		: NONE
	EXEC Statement	: 
						DECLARE @e int, @em varchar(4000)
						
						EXEC dbo.usp_Event_UpdateEventTickets
							@Error = @e OUTPUT
							,@ErrorMessage = @em OUTPUT
							,@IsDevQA = 1

						SELECT @e AS [Error], @em AS [Error Message]

	SOURCE TABLES	: dbo.EventSKU
					  dbo.Schedule
					  dbo.EventSchedule
					  dbo.SKUPurchased
					  dbo.EventTickets
					  dbo.v_EventCurrentQualificationToUpdate

	TARGET TABLES	: dbo.EventTickets
					  dbo.EventTicketAssignment
												
	VERSION HISTORY:
	VER	DATE       		DEVELOPER			COMMENTS
	===	========  		=========			=================
	1.0	04-Feb-2009		Ini Ukporo			First Version
	1.1 25-Mar-2011		Ini	Ukporo			Added code to distingush EventSKU Tickets from NonEventSKU Tickets via EventSKU.IsEventTicketSKU column
	1.2 06-Dec-2011     Sandhya Pendyala    Commented Delete Temps who converted to Distributors section for reporting purpose
	1.3 20-May-2013		Ini Ukporo			Added code to exclude 'Dummy" SKUs from being processed so that it does not wipe out its data
	2.0 30-SEP-2019		Noe Gonzalez		SRE template applied
	2.1 05-SEP-2022     Jair Lira           Sync CEA Tickets and Update processing Log was added

	This procedure uses SKUPurchased, which contains which distributors
	ordered ticket skus for the event to populate EventTickets and EventTicketsAssignment table.
	
	The procedure checks the quantity difference between SKUPurchased and EventTickets table by 
	Event, SKU and Distributor and uses the difference or surplus to create additional entry(ies)
	EventTickets and EventTicketAssignment.

******************************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

		DECLARE
			@PK_Event int
			,@PK_EventSKU int
			,@PK_Distributor int
			,@PK_SKUPurchased int
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
			,@DSID varchar(20)

		SET @AppProgram = 'uspEvent_UpdateEventTickets'
		SET @AppDate = GETUTCDATE()
		SET @ToDate = '2049-12-31'
		SET @DSID = @DistributorID 

		/******************************************************************************
			get orders/tickets that were cancelled
		******************************************************************************/
		IF OBJECT_ID('dbo.wrk_SKUPurchased','U') IS NOT NULL DROP TABLE dbo.wrk_SKUPurchased
		CREATE TABLE dbo.wrk_SKUPurchased (
			PK_Event int
			,PK_EventSKU int
			,PK_SKUPurchased int
			,PK_EventTicket int
			,PK_Distributor_Purchaser int
			,DistributorID varchar(10)
			,isDeleted bit DEFAULT 0
			,IsRegistered bit DEFAULT 0
		)
		INSERT
			dbo.wrk_SKUPurchased
		(
			PK_Event
			,PK_EventSKU
			,PK_SKUPurchased
			,PK_EventTicket
			,PK_Distributor_Purchaser
			,DistributorID
			,isDeleted
			,IsRegistered
		)
		SELECT
			SKU.PK_Event
			,SKU.PK_EventSKU
			,SKU.PK_SKUPurchased
			,E.PK_EventTicket
			,SKU.PK_Distributor_Purchaser
			,SKU.DistributorID
			,CASE WHEN SKUExt.PK_Distributor_Purchaser IS NULL 
				   AND SKUExt.OrderNumber IS NULL 
				   AND SKUExt.PK_Event IS NULL 
				   AND SKUExt.PK_EventSKU IS NULL 
				   THEN 1 ELSE 0 END
			,CASE WHEN E.IsTicketUsed = 1 THEN 1 ELSE 0 END     
		FROM
			dbo.SKUPurchased_Extract SKUExt WITH(NOLOCK)
		RIGHT JOIN
			dbo.SKUPurchased SKU WITH(NOLOCK)
			ON
				SKUExt.PK_EventSKU = SKU.PK_EventSKU
				AND SKUExt.PK_Event = SKU.PK_Event
				AND SKUExt.PK_Distributor_Purchaser = SKU.PK_Distributor_Purchaser
				AND SKUExt.OrderNumber = SKU.OrderNumber
		INNER JOIN 
			 dbo.EventSchedule C (NOLOCK)
			 ON
			   SKU.PK_Event = C.PK_Event
			   AND
			   C.PK_Schedule = 6
			   AND
			   @AppDate BETWEEN C.BeginUTC AND C.EndUTC 
		INNER JOIN
			 dbo.EventSKU ES (NOLOCK)
		ON
			SKU.PK_Event = ES.PK_Event 
			AND
			SKU.PK_EventSKU = ES.PK_EventSKU 
			AND
			@AppDate BETWEEN ES.SKUValidBeginUTC AND ES.SKUValidEndUTC  		
		INNER JOIN
			dbo.EventTickets E WITH(NOLOCK)
			ON
				SKU.PK_SKUPurchased = E.PK_SKUPurchased
				AND SKU.PK_Event = E.PK_Event
				AND SKU.PK_EventSKU = E.PK_EventSKU	
				AND SKU.PK_Distributor_Purchaser = E.PK_Purchaser	
		WHERE
			SKUExt.PK_Distributor_Purchaser IS NULL 
			AND SKUExt.OrderNumber IS NULL 
			AND SKUExt.PK_Event IS NULL 
			AND SKUExt.PK_EventSKU IS NULL
			AND SKU.IsManual = 0
			AND ES.ProcessSKU = 1
	
		Update W
		SET IsRegistered = 1
		FROM dbo.wrk_SKUPurchased W
		INNER JOIN  (SELECT PK_SKUPurchased, COUNT(1) As RegisteredCount
					 FROM dbo.wrk_SKUPurchased WITH(NOLOCK)
					 WHERE IsRegistered > 0
					 GROUP BY PK_SKUPurchased)S
		ON W.PK_SKUPurchased = S.PK_SKUPurchased    
	

		/******************************************************************************
			Delete orders/tickets except for registered
		******************************************************************************/

		DELETE ETA
		FROM dbo.EventTicketAssignment ETA
		INNER JOIN dbo.wrk_SKUPurchased SKU WITH (NOLOCK)
		ON ETA.PK_Event = SKU.PK_Event
		   AND ETA.PK_SKUPurchased = SKU.PK_SKUPurchased 
		   AND ETA.PK_EventTicket = SKU.PK_EventTicket
		   --AND ETA.ValidToDateUTC = '2049-12-31'
		   AND SKU.isDeleted = 1
		   AND SKU.IsRegistered = 0
   
   
		DELETE ET 
		FROM dbo.EventTickets ET
		INNER JOIN dbo.wrk_SKUPurchased SKU WITH (NOLOCK)
		ON ET.PK_Event = SKU.PK_Event
		   AND ET.PK_SKUPurchased = SKU.PK_SKUPurchased 
		   AND ET.PK_EventTicket = SKU.PK_EventTicket
		   AND SKU.isDeleted = 1
		   AND SKU.IsRegistered = 0 
     
		DELETE S 
		FROM dbo.SKUPurchased S
		INNER JOIN dbo.wrk_SKUPurchased SKU WITH (NOLOCK)
		ON S.PK_SKUPurchased = SKU.PK_SKUPurchased 
		   AND SKU.isDeleted = 1
		   AND SKU.IsRegistered = 0 
   
		--DELETE SP 
		--FROM dbo.SKUPurchasedPivot SP
		--INNER JOIN dbo.wrk_SKUPurchased SKU
		--ON SP.PK_Distributor_Purchaser = SKU.PK_Distributor_Purchaser 
		--   AND SP.PK_Event = SKU.PK_Event
		--   AND SKU.isDeleted = 1
		--   AND SKU.IsRegistered = 0   

		/*******************************************************************************************************************
			Get SKUs that were manually enterred but have now flowed in from Oracle and have not been used to register yet
		*******************************************************************************************************************/
		IF OBJECT_ID('tempdb..#del_SKUPurchased', 'U') IS NOT NULL 
			DROP TABLE #del_SKUPurchased

		CREATE TABLE #del_SKUPurchased
		(
			PK int IDENTITY(1,1) PRIMARY KEY,
			PK_Event	int,
			PK_EventSKU int,
			PK_SKUPurchased int
		)

		INSERT INTO #del_SKUPurchased
			(PK_SKUPurchased,
			 PK_EventSKU,
			 PK_Event)
		SELECT 
			SKU.PK_SKUPurchased,
			SKU.PK_EventSKU,
			SKU.PK_Event 	
		FROM
			dbo.SKUPurchased SKU (NOLOCK)
		INNER JOIN 
			 dbo.EventSchedule C (NOLOCK)
			 ON
			   SKU.PK_Event = C.PK_Event
			   AND
			   C.PK_Schedule = 6
			   AND
			   @AppDate BETWEEN C.BeginUTC AND C.EndUTC 
		INNER JOIN
			 dbo.EventSKU ES (NOLOCK)
		ON
			SKU.PK_Event = ES.PK_Event 
			AND
			SKU.PK_EventSKU = ES.PK_EventSKU 
			AND
			@AppDate BETWEEN ES.SKUValidBeginUTC AND ES.SKUValidEndUTC  
		INNER JOIN
			dbo.SKUPurchased_Extract SKUExt WITH(NOLOCK)
		ON
			SKUExt.PK_EventSKU = SKU.PK_EventSKU
			AND SKUExt.PK_Event = SKU.PK_Event
			AND SKUExt.PK_Distributor_Purchaser = SKU.PK_Distributor_Purchaser
			AND SKUExt.OrderNumber = SKU.OrderNumber
		WHERE
			SKU.IsManual = 1
		AND
			NOT EXISTS (SELECT ET.PK_SKUPurchased FROM dbo.EventTickets ET WITH(NOLOCK) WHERE ET.PK_SKUPurchased = SKU.PK_SKUPurchased AND ET.IsTicketUsed = 1)

		/***********************************************************************************
			Delete corresponding data sets from Assignment, Ticket and SKUPurchased tables
		***********************************************************************************/	
		DELETE
			ETA
		FROM 
			dbo.EventTicketAssignment ETA
		INNER JOIN 
			#del_SKUPurchased SKD
		ON 
			ETA.PK_SKUPurchased = SKD.PK_SKUPurchased 
			AND
			ETA.PK_Event = SKD.PK_Event
			AND
			ETA.PK_EventSKU = SKD.PK_EventSKU
	
		DELETE
			ET
		FROM 
			dbo.EventTickets ET
		INNER JOIN 
			#del_SKUPurchased SKD
		ON 
			ET.PK_SKUPurchased = SKD.PK_SKUPurchased 
			AND
			ET.PK_Event = SKD.PK_Event
			AND
			ET.PK_EventSKU = SKD.PK_EventSKU
	
		DELETE
			SKP
		FROM 
			dbo.SKUPurchased SKP
		INNER JOIN 
			#del_SKUPurchased SKD
		ON 
			SKP.PK_SKUPurchased = SKD.PK_SKUPurchased 
			AND
			SKP.PK_Event = SKD.PK_Event
			AND
			SKP.PK_EventSKU = SKD.PK_EventSKU
	
		/******************************************************************************
			get changed/new sku purchased
		******************************************************************************/
		IF OBJECT_ID('wrk_SKUExt','U') IS NOT NULL DROP TABLE wrk_SKUExt
		CREATE TABLE dbo.wrk_SKUExt (
			PK_Event int
			,PK_EventSKU int
			,PK_Distributor_Purchaser int
			,DistributorID varchar(10)
			,OrderDate smalldatetime
			,NTSDate smalldatetime
			,OrderNumber varchar(10)
			,OrderType varchar(2)
			,isNew bit DEFAULT 0
			,NewQty int
			,OldQty int
			,QtyDiff int

		)
		INSERT
			dbo.wrk_SKUExt
		(
			PK_Event
			,PK_EventSKU
			,PK_Distributor_Purchaser
			,DistributorID
			,OrderDate
			,NTSDate
			,OrderNumber
			,OrderType
			,isNew
			,NewQty
			,OldQty
			,QtyDiff
		)
		SELECT
			SKUExt.PK_Event
			,SKUExt.PK_EventSKU
			,SKUExt.PK_Distributor_Purchaser
			,SKUExt.DistributorID
			,SKUExt.OrderDate
			,SKUExt.NTSDate
			,SKUExt.OrderNumber
			,SKUExt.OrderType
			,CASE WHEN SKU.PK_SKUPurchased IS NULL THEN 1 ELSE 0 END
			,SUM(SKUExt.Quantity) 'NewQty'
			,COALESCE(SUM(SKU.Quantity),0) 'OldQty'
			,SUM(SKUExt.Quantity) - COALESCE(SUM(SKU.Quantity),0)  'QtyDiff'

		FROM
			dbo.SKUPurchased_Extract SKUExt WITH(NOLOCK)
		LEFT JOIN
			dbo.SKUPurchased SKU WITH(NOLOCK)
			ON
				SKUExt.PK_EventSKU = SKU.PK_EventSKU
				AND SKUExt.PK_Event = SKU.PK_Event
				AND SKUExt.PK_Distributor_Purchaser = SKU.PK_Distributor_Purchaser
				AND SKUExt.OrderNumber = SKU.OrderNumber
		WHERE
			SKUExt.PK_Distributor_Purchaser IS NOT NULL
		GROUP BY
			SKUExt.PK_Event
			,SKUExt.PK_EventSKU
			,SKUExt.PK_Distributor_Purchaser
			,SKUExt.DistributorID
			,SKUExt.OrderDate
			,SKUExt.NTSDate
			,SKUExt.OrderNumber
			,SKUExt.OrderType
			,CASE WHEN SKU.PK_SKUPurchased IS NULL THEN 1 ELSE 0 END
		HAVING
			SUM(SKUExt.Quantity) != COALESCE(SUM(SKU.Quantity),0)
	
   	
		/******************************************************************************
			update changed rows
		******************************************************************************/
		UPDATE
			SKU
		SET
			SKU.Quantity = SKUExt.NewQty
		FROM
			dbo.SKUPurchased SKU
		INNER JOIN
			dbo.wrk_SKUExt SKUExt WITH (NOLOCK)
			ON
				SKUExt.PK_EventSKU = SKU.PK_EventSKU
				AND SKUExt.PK_Event = SKU.PK_Event
				AND SKUExt.PK_Distributor_Purchaser = SKU.PK_Distributor_Purchaser
				AND SKUExt.OrderNumber = SKU.OrderNumber
				AND SKUExt.isNew = 0
		INNER JOIN
			dbo.Event EV WITH (NOLOCK)
			ON
				EV.PK_Event = SKU.PK_Event
		WHERE
			NOT EXISTS (SELECT ER.PK_Event FROM dbo.EventsRegistration ER WITH(NOLOCK) WHERE ER.PK_Event = SKU.PK_Event AND ER.HasCheckedIn = 1
									  AND ER.PK_Distributor = CASE WHEN EV.CanAssignTickets = 0 THEN SKU.PK_Distributor_Purchaser ELSE 0 END)
		-- The Not Exists Clause is added so that if it is not a group ticket type event, then once a DS registers, it should not process any further SKUs
		-- in SKU purchase table

		/******************************************************************************
			insert new rows
		******************************************************************************/
		INSERT
			dbo.SKUPurchased
		(
			PK_Event
			,PK_EventSKU
			,PK_Distributor_Purchaser
			,DistributorID
			,OrderDate
			,NTSDate
			,OrderNumber
			,OrderType
			,Quantity
			,isManual
		)
		SELECT
			Ext.PK_Event
			,PK_EventSKU
			,PK_Distributor_Purchaser
			,DistributorID
			,OrderDate
			,NTSDate
			,OrderNumber
			,OrderType
			,NewQty
			,0
		FROM
			dbo.wrk_SKUExt Ext WITH(NOLOCK)
			INNER JOIN
			dbo.Event EV WITH(NOLOCK)
		ON
			Ext.PK_Event = EV.PK_Event
		WHERE
			isNew = 1 AND NOT EXISTS (SELECT ER.PK_Event FROM dbo.EventsRegistration ER WITH(NOLOCK) WHERE ER.PK_Event = Ext.PK_Event AND ER.HasCheckedIn = 1
									  AND ER.PK_Distributor = CASE WHEN EV.CanAssignTickets = 0 THEN Ext.PK_Distributor_Purchaser ELSE 0 END)
		-- The Not Exists Clause is added so that if it is not a group ticket type event, then once a DS registers, it should not process any further SKUs
		-- in SKU purchase table
	
	
		/******************************************************************************
			PIVOT INFORMATION FOR dbo.SKUPurchasedPivot
		******************************************************************************/
		DECLARE
			@Timestamp datetime
			,@ScheduleID int
			,@SKUCode char(4)
			,@OrderDate smalldatetime
			,@OrderNumber varchar(10)
			,@OrderType varchar(2)
			,@Quantity int
			,@OrderInformation varchar(4000)
			,@NextPK_Event int
			,@NextPK_EventSKU int 
			,@NextPK_Distributor_Purchaser int
			,@NextDistributorID varchar(10)
			,@NextSKUCode char(4)
			,@NextOrderDate smalldatetime
			,@NextOrderNumber varchar(10)
			,@NextOrderType varchar(2)
			,@NextQuantity int
			,@NextOrderInformation varchar(4000)
			,@AddLastRecord bit
			,@ProgName varchar(30)
	
		/******************************************************************************
			create table to stored pivoted information
		******************************************************************************/
		IF OBJECT_ID('tempdb..#SKUPurchasedPivot') IS NOT NULL 
			DROP TABLE #SKUPurchasedPivot

		CREATE TABLE #SKUPurchasedPivot(
			PK_Event int,
			PK_Distributor_Purchaser int,
			DistributorID varchar(10),
			Quantity int,
			OrderInformation varchar(4000)
		)

		/******************************************************************************
			get total ticket counts for each distributor for each event
		******************************************************************************/
		IF OBJECT_ID('tempdb..#TotalTicketCounts') IS NOT NULL 
			DROP TABLE #TotalTicketCounts

		CREATE TABLE #TotalTicketCounts (
			PK_Event int
			,PK_Distributor_Purchaser int
			,Quantity int
			,OrderCount int
		)

		INSERT
			#TotalTicketCounts
		(
			PK_Event
			,PK_Distributor_Purchaser
			,Quantity
			,OrderCount
		)
		SELECT
			P.PK_Event
			,P.PK_Distributor_Purchaser
			,SUM(P.Quantity)
			,COUNT(P.OrderNumber)
		FROM
			dbo.SKUPurchased P (NOLOCK)
		INNER JOIN 
			 dbo.EventSchedule C (NOLOCK)
			 ON
			   P.PK_Event = C.PK_Event
			   AND
			   C.PK_Schedule = 6
			   AND
			   @AppDate BETWEEN C.BeginUTC AND C.EndUTC 
		INNER JOIN
			 dbo.EventSKU ES (NOLOCK)
		ON
			P.PK_Event = ES.PK_Event 
			AND
			P.PK_EventSKU = ES.PK_EventSKU 
			AND
			@AppDate BETWEEN ES.SKUValidBeginUTC AND ES.SKUValidEndUTC
		GROUP BY
			P.PK_Event
			,P.PK_Distributor_Purchaser
		HAVING
			SUM(P.Quantity) > 0
		ORDER BY
			P.PK_Event
			,P.PK_Distributor_Purchaser
	

		/******************************************************************************
			write info to cursor for sku purchasers' data
		******************************************************************************/
		DECLARE sku_purchased CURSOR FAST_FORWARD FOR 
		SELECT
			P.PK_Event
			,P.PK_EventSKU
			,P.PK_Distributor_Purchaser
			,P.DistributorID
			,ES.SKUCode
			,P.OrderDate
			,P.OrderNumber
			,P.OrderType
			,P.Quantity
		FROM
			dbo.SKUPurchased P WITH(NOLOCK)
		INNER JOIN
			dbo.EventSKU ES WITH(NOLOCK)
			ON
			  P.PK_EventSKU	= ES.PK_EventSKU
			  AND
			  P.PK_Event = ES.PK_Event
		INNER JOIN
			#TotalTicketCounts T
			ON
				T.PK_Event = P.PK_Event
				AND
				T.PK_Distributor_Purchaser = P.PK_Distributor_Purchaser
		ORDER BY
			P.PK_Event
			,P.PK_Distributor_Purchaser
			,P.OrderDate DESC

		OPEN sku_purchased

		/******************************************************************************
			get first record
		******************************************************************************/
		FETCH NEXT FROM sku_purchased INTO 
			@PK_Event
			,@PK_EventSKU
			,@PK_Distributor
			,@DistributorID
			,@SKUCode
			,@OrderDate
			,@OrderNumber
			,@OrderType
			,@Quantity

		SET @OrderInformation = 
			'[' +
				REPLACE(CONVERT(varchar,@OrderDate,106),' ','') + ',' +
				@OrderNumber + ',' +
				@SKUCode + ',' +
				CONVERT(varchar,@Quantity) + ']'

		WHILE @@FETCH_STATUS = 0
		BEGIN

		/******************************************************************************
			get next record
		******************************************************************************/
		FETCH NEXT FROM sku_purchased INTO 
			@NextPK_Event
			,@NextPK_EventSKU
			,@NextPK_Distributor_Purchaser
			,@NextDistributorID
			,@NextSKUCode
			,@NextOrderDate
			,@NextOrderNumber
			,@NextOrderType
			,@NextQuantity

		SET @NextOrderInformation = 
			'[' +
				REPLACE(CONVERT(varchar,@NextOrderDate,106),' ','') + ',' +
				@NextOrderNumber + ',' +
				@NextSKUCode + ',' +
				CONVERT(varchar,@NextQuantity) + ']'

		/******************************************************************************
			start pivoting
		******************************************************************************/
		IF @NextPK_Distributor_Purchaser != @PK_Distributor OR @NextPK_Event != @PK_Event

		BEGIN
			/* 1. write info from current distributor to temp table */
			INSERT
				#SKUPurchasedPivot
			(
				PK_Event,
				PK_Distributor_Purchaser,
				DistributorID,
				Quantity,
				OrderInformation
			)
			SELECT
				@PK_Event
				,@PK_Distributor
				,@DistributorID
				,(SELECT Quantity 
					FROM #TotalTicketCounts 
					WHERE PK_Event = @PK_Event AND PK_Distributor_Purchaser = @PK_Distributor)
				,@OrderInformation
	
			/* 2. reset pivot information */
			SET @PK_Event = @NextPK_Event
			SET @PK_EventSKU = @NextPK_EventSKU
			SET @PK_Distributor = @NextPK_Distributor_Purchaser
			SET @DistributorID = @NextDistributorID
			SET @SKUCode = @NextSKUCode
			SET @OrderDate = @NextOrderDate
			SET @OrderNumber = @NextOrderNumber
			SET @OrderType = @NextOrderType
			SET @Quantity = @NextQuantity
			SET @OrderInformation = @NextOrderInformation

			SET @AddLastRecord = 0
		END

		ELSE

		BEGIN
			/* 1. add current info to next info */
			SET @OrderInformation = @OrderInformation + @NextOrderInformation
			SET @AddLastRecord = 1
		END

		END

		/******************************************************************************
			insert last record
		******************************************************************************/
		IF @AddLastRecord = 1
		BEGIN
			INSERT
				#SKUPurchasedPivot
			(
				PK_Event,
				PK_Distributor_Purchaser,
				DistributorID,
				Quantity,
				OrderInformation
			)
			SELECT
				@NextPK_Event
				,@NextPK_Distributor_Purchaser
				,@NextDistributorID
				,(SELECT Quantity 
					FROM #TotalTicketCounts 
					WHERE PK_Event = @NextPK_Event AND PK_Distributor_Purchaser = @NextPK_Distributor_Purchaser)
				,@NextOrderInformation
		END

		/******************************************************************************
			end pivoting
		******************************************************************************/
		CLOSE sku_purchased
		DEALLOCATE sku_purchased

		/******************************************************************************
			Delete dbo.SKUPurchasedPivot
		******************************************************************************/

		DELETE SP 
		FROM dbo.SKUPurchasedPivot SP
		INNER JOIN #SKUPurchasedPivot SKU
		ON SP.PK_Event = SKU.PK_Event


		/******************************************************************************
			insert updated records into
			dbo.SKUPurchasedPivot
		******************************************************************************/
		INSERT
			dbo.SKUPurchasedPivot
		(
			PK_Event
			,PK_Distributor_Purchaser
			,DistributorID
			,Quantity
			,OrderInformation
		)
		SELECT
			PK_Event
			,PK_Distributor_Purchaser
			,DistributorID
			,Quantity
			,OrderInformation
		FROM
			#SKUPurchasedPivot
	

		/******************************************************************************
			update ticket
		******************************************************************************/

		IF @DistributorID IS NOT NULL
		   SELECT @PK_Distributor = nDistributorID FROM dbo.v_DistributorUnionTemp WHERE sDistributorID = @DistributorID

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
				AND @AppDate BETWEEN ES.SKUValidBeginUTC AND ES.SKUValidEndUTC
			INNER JOIN 
				dbo.EventSchedule C (NOLOCK)
			ON
			   S.PK_Event = C.PK_Event
			   AND
			   C.PK_Schedule = 6
			   AND
			   @AppDate BETWEEN C.BeginUTC AND C.EndUTC 
			group by S.PK_Event
				,S.PK_EventSKU
				,S.PK_Distributor_Purchaser
				,S.DistributorID
				,S.PK_SKUPurchased) sk
			FULL OUTER JOIN
				(SELECT T.PK_Event,T.PK_EventSKU,PK_Purchaser, PK_SKUPurchased, count(1) AS Ticket_Qty
				 FROM 
					dbo.EventTickets T WITH (NOLOCK)
				 INNER JOIN 
					dbo.EventSchedule C (NOLOCK)
				 ON
					T.PK_Event = C.PK_Event
					AND
					C.PK_Schedule = 6
					AND
					@AppDate BETWEEN C.BeginUTC AND C.EndUTC 
				 INNER JOIN
					dbo.EventSKU ES (NOLOCK)
				 ON
					T.PK_Event = ES.PK_Event
					AND T.PK_EventSKU = ES.PK_EventSKU
					AND ES.IsEventTicketSKU = 1
					AND @AppDate BETWEEN ES.SKUValidBeginUTC AND ES.SKUValidEndUTC	
				GROUP BY
					T.PK_Event,T.PK_EventSKU,PK_Purchaser,PK_SKUPurchased) ET
			ON
				Sk.PK_Event = ET.PK_Event
				AND
				Sk.PK_EventSKU = ET.PK_EventSKU
				AND
				Sk.PK_Distributor_Purchaser = ET.PK_Purchaser
				AND
				Sk.PK_SKUPurchased = ET.PK_SKUPurchased
			--WHERE
		--		Sk.PK_Distributor_Purchaser IS NOT NULL
		--		AND 
		--		Sk.DistributorID = ISNULL(@DistributorID,Sk.DistributorID)
				--ISNULL(Sk.PK_Distributor_Purchaser,ET.PK_Purchaser) = CASE WHEN @DistributorID IS NOT NULL THEN @PK_Distributor ELSE ISNULL(Sk.PK_Distributor_Purchaser,ET.PK_Purchaser) END

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

					SELECT @PK_EventTicket = MAX(PK_EventTicket) FROM dbo.EventTickets 

					INSERT INTO dbo.EventTicketAssignment(PK_FromDistributor, PK_ToDistributor, CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_EventTicket, Ticketed, ValidFromDateUTC, ValidToDateUTC, PK_Event, PK_EventSKU,PK_SKUPurchased)
					VALUES(@PK_Distributor,@PK_Distributor,@AppDate,@AppProgram,@AppDate,@AppProgram,@PK_EventTicket,1,@AppDate,@ToDate,@PK_Event,@PK_EventSKU,@PK_SKUPurchased)

					SET @TicketCount = @TicketCount - 1
				END

			WHILE  @TicketsToRemove > 0
				BEGIN
					SELECT @PK_EventTicketToRemove = MAX(E.PK_EventTicket) FROM dbo.EventTickets E INNER JOIN dbo.EventTicketAssignment EA ON E.PK_EventTicket = EA.PK_EventTicket
					WHERE E.PK_Purchaser = @PK_Distributor AND E.PK_Event = @PK_Event AND E.PK_EventSKU = @PK_EventSKU AND E.IsTicketUsed = 0 AND EA.PK_FromDistributor = EA.PK_ToDistributor AND EA.ValidToDateUTC = '2049-12-31' -- Group Ticket changes (SandhyaP)

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

		-- Get temps that were initially created but now exist in distributor table 
		IF OBJECT_ID('tempdb..#TempIDs', 'U') IS NOT NULL 
			DROP TABLE #TempIDs

		CREATE TABLE #TempIDs
		(
			PK int IDENTITY(1,1) PRIMARY KEY,
			PK_Temp int,
			PK_Distributor int,
			DistributorID varchar(10)
		)

		INSERT INTO #TempIDs
			(PK_Temp,
			 PK_Distributor,
			 DistributorID)
		SELECT 
			T.PK_Temp,
			DS.nDistributorID,
			DS.sDistributorID 
		FROM
			dbo.TempDistributors T WITH(NOLOCK)
		INNER JOIN
			dbo.v_Distributor DS
		ON
			DS.sDistributorID = T.DistributorID
	
		-- Update DistributorNotes Table
		UPDATE
			EDN 
		SET
			EDN.PK_Distributor = T.PK_Distributor
		FROM
			dbo.EventDistributorNotes EDN
		INNER JOIN
			dbo.v_EventCurrentQualificationToUpdate C
		ON
			 EDN.PK_Event = C.PK_Event
		INNER JOIN
			#TempIDs T
		ON
			T.PK_Temp = EDN.PK_Distributor 
	
		-- Update SubEventQualifier Table
		UPDATE
			SEQ 
		SET
			SEQ.PK_Distributor = T.PK_Distributor
		FROM
			dbo.SubEventQualifier SEQ
		INNER JOIN
			dbo.v_EventCurrentQualificationToUpdate C
		ON
			 SEQ.PK_Event = C.PK_Event
		INNER JOIN
			#TempIDs T
		ON
			T.PK_Temp = SEQ.PK_Distributor 	
			AND
			T.DistributorID = SEQ.DistributorID
	
		-- Update EventTicketAssignment Table
		UPDATE
			ETA 
		SET
			ETA.PK_FromDistributor = T.PK_Distributor
		FROM
			dbo.EventTicketAssignment ETA
		INNER JOIN
			dbo.v_EventCurrentQualificationToUpdate C
		ON
			 ETA.PK_Event = C.PK_Event
		INNER JOIN
			#TempIDs T
		ON
			T.PK_Temp = ETA.PK_FromDistributor 	
	
		UPDATE
			ETA 
		SET
			ETA.PK_ToDistributor = T.PK_Distributor
		FROM
			dbo.EventTicketAssignment ETA
		INNER JOIN
			dbo.v_EventCurrentQualificationToUpdate C
		ON
			 ETA.PK_Event = C.PK_Event
		INNER JOIN
			#TempIDs T
		ON
			T.PK_Temp = ETA.PK_ToDistributor 
	
		-- Update EventTickets Table
		UPDATE
			ET 
		SET
			ET.PK_Purchaser = T.PK_Distributor
		FROM
			dbo.EventTickets ET
		INNER JOIN
			dbo.v_EventCurrentQualificationToUpdate C
		ON
			 ET.PK_Event = C.PK_Event
		INNER JOIN
			#TempIDs T
		ON
			T.PK_Temp = ET.PK_Purchaser 
	
		-- Update SKUPurchased Table
		UPDATE
			SKP 
		SET
			SKP.PK_Distributor_Purchaser = T.PK_Distributor
		FROM
			dbo.SKUPurchased SKP
		INNER JOIN
			dbo.v_EventCurrentQualificationToUpdate C
		ON
			 SKP.PK_Event = C.PK_Event
		INNER JOIN
			#TempIDs T
		ON
			T.PK_Temp = SKP.PK_Distributor_Purchaser 
			AND
			T.DistributorID = SKP.DistributorID 		
	
	
		-- Update EventRegistration Table
		UPDATE
			ER 
		SET
			ER.PK_Distributor = T.PK_Distributor
		FROM
			dbo.EventsRegistration ER
		INNER JOIN
			dbo.v_EventCurrentQualificationToUpdate C
		ON
			 ER.PK_Event = C.PK_Event
		INNER JOIN
			#TempIDs T
		ON
			T.PK_Temp = ER.PK_Distributor  
			AND
			T.DistributorID = ER.DistributorID 
	
		-- delete Temps that have become distributors 

		/*** NOTE: WE NEED TO RETAIN THE PK_TEMP FOR ANALYSIS & REPORTING  (Sandhya Pendyala) */

		--DELETE
		--	T
		--FROM
		--	dbo.TempDistributors T
		--INNER JOIN
		--	dbo.v_Distributor D 
		--ON
		--	D.sDistributorID = T.DistributorID
		--WHERE
		--	NOT EXISTS (SELECT CE.PK_Event FROM dbo.EventTickets ET 
		--				INNER JOIN 
		--				dbo.v_EventCurrentQualificationToUpdate CE 
		--				ON
		--					CE.PK_Event = ET.PK_Event
		--				WHERE 
		--					T.PK_Temp = ET.PK_Purchaser
		--				AND
		--					ET.IsTicketUsed = 1)

		/* END PROCEDURE */

		IF @AppDate < '2014-02-27' -- Just to update Quantity in GiveAway table for HK Spectacular
		BEGIN
			EXEC dbo.usp_EventQual_HK_Spectacular_GiveAway 
		END

		-- Generate SKU Notes as applicable
		EXEC dbo.usp_Event_GenerateNote @DSID  

		-- Sync CEA Tickets
		EXEC [z_evp_cea_maintenance].[spcea_Event_ProgramTickets]

		-- CEA Tickets General LP Temp 
		EXEC [z_evp_cea_maintenance].[spcea_Event_Ins_GeneralAttendeeTickets]

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
	END CATCH

END