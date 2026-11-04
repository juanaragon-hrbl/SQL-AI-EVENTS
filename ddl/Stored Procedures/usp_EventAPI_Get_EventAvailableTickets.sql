CREATE PROCEDURE [dbo].[usp_EventAPI_Get_EventAvailableTickets]
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
OBJECT:		dbo.usp_EventAPI_Get_EventAvailableTickets

USE:	DECLARE @e int, @em varchar(max)
	
		EXEC usp_EventAPI_Get_EventAvailableTickets
				@DistributorID = '36080141'
				,@EventID = 88
				,@Error = @e OUTPUT  /* @e must be defined in the local call */
				,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
				,@IsDevQA = 0

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves record from dbo.EventTickets and EventTicketAssignment for Ticket Metrics

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.EventTickets
dbo.EventTicketAssignment

VERSIONS
--------------------------------------------------------------------
1.5 2025-06-24	jairli      	Improve performance for input parameter 
1.4 2019-10-08	alejandramed	SRE Compliance 
1.3	2019-07-15	alejandramed	Setting error parameters as optionals
1.2	2019-05-21	alejandramed	Homologating of standard error handling
1.1 2009-08-27  SandhyaP		Group ticket changes
1	2009-02-25	Ini Ukporo		Initial

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	/******************************************************************************
		variable declaration
	******************************************************************************/
	DECLARE @TicketPurchased int
	DECLARE @TicketsAssignedTo int
	DECLARE @TicketsAvailable int
	DECLARE @TicketsUsed int
	DECLARE @MaxTicketsAllowed int
	DECLARE @PK_Distributor int
	DECLARE @ValidToDateUTC DATETIME = '2049-12-31'

	SET @TicketsAvailable = 0
	SET @TicketsUsed = 0
	SET @TicketPurchased = 0
	SET @TicketsAssignedTo = 0
	SET @MaxTicketsAllowed = 0

	/******************************************************************************
	be sure the value of FK exists in referenced table
	******************************************************************************/
	IF NOT EXISTS(SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @EventID)
	BEGIN
		SET @Error = 169
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN
	END

	IF EXISTS (SELECT nDistributorID FROM dbo.v_DistributorUnionTemp WHERE sDistributorID = @DistributorID)
	BEGIN
	/******************************************************************************
	Get nDistributorID
	******************************************************************************/
	SELECT @PK_Distributor = nDistributorID FROM dbo.v_DistributorUnionTemp WHERE sDistributorID = @DistributorID

	/******************************************************************************
	Get Total tickets purchased for event
	******************************************************************************/
	SELECT @TicketPurchased = COUNT(1) 
	FROM 
		dbo.EventTickets WITH (NOLOCK)
	WHERE 
		PK_Purchaser = @PK_Distributor 
		AND 
		PK_Event = @EventID

	/******************************************************************************
	Get Total tickets ASSIGNED TO DISTRIBUTOR
	******************************************************************************/
	SELECT 
		@TicketsAssignedTo = COUNT(DISTINCT ETA.PK_EventTicket)
	FROM
		dbo.EventTicketAssignment ETA WITH (NOLOCK)
	INNER JOIN
		dbo.EventTickets ET WITH (NOLOCK)
		ON
			ETA.PK_EventTicket = ET.PK_EventTicket
			AND ET.PK_Event = @EventID
	WHERE
		ETA.PK_ToDistributor = @PK_Distributor
		AND ETA.PK_FromDistributor != ETA.PK_ToDistributor
		AND ETA.ValidToDateUTC = @ValidToDateUTC
    OPTION (RECOMPILE)


	/******************************************************************************
	Get Total tickets Available
	******************************************************************************/
	SELECT 
		@TicketsAvailable = COUNT(ETA.PK_EventTicket)
	FROM
		dbo.EventTicketAssignment ETA WITH (NOLOCK)
	INNER JOIN
		dbo.EventTickets ET WITH (NOLOCK)
		ON
			ETA.PK_EventTicket = ET.PK_EventTicket
			AND ET.IsTicketUsed = 0
			AND ET.PK_Event = @EventID
	INNER JOIN
		dbo.EventSKU  ES WITH (NOLOCK)
		ON
			ET.PK_Event = ES.PK_Event
			AND
			ET.PK_EventSKU = ES.PK_EventSKU
			AND
			ES.SKUValidEndUTC >= GETDATE()
	WHERE
		ETA.PK_ToDistributor = @PK_Distributor
		AND ETA.ValidToDateUTC = @ValidToDateUTC
	OPTION (RECOMPILE)

	/******************************************************************************
	Get Total tickets Used
	******************************************************************************/
	SELECT 
		@TicketsUsed = COUNT(1) 
	FROM 
		dbo.EventTicketAssignment TA WITH (NOLOCK)
	INNER JOIN
		dbo.EventTickets ET WITH (NOLOCK)
	ON
		ET.PK_EventTicket = TA.PK_EventTicket
	WHERE 
		TA.PK_ToDistributor = @PK_Distributor
		AND
		ET.PK_Event = @EventID
		AND
		ET.IsTicketUsed = 1
		AND
		TA.ValidToDateUTC = @ValidToDateUTC
	OPTION (RECOMPILE)

	/******************************************************************************
	Get Max Tickets Allowed For this event per distributorship
	******************************************************************************/
	SELECT 
		@MaxTicketsAllowed = ISNULL(MaxNoOfGuest,0)+1 
	FROM 
		dbo.Event WITH (NOLOCK)
	WHERE 
		PK_Event = @EventID

	END

	/******************************************************************************
	select record
	******************************************************************************/
		SELECT
			 ISNULL(@TicketPurchased,0) AS TicketsPurchased
			,ISNULL(@TicketsAssignedTo,0) AS TicketsAssignedTo
			,ISNULL(@TicketsUsed,0) AS TicketsUsed
	--        ,CASE WHEN @TicketsAssignedTo >= @MaxTicketsAllowed THEN ISNULL((@MaxTicketsAllowed - @TicketsUsed),0)
	--         ELSE ISNULL((@TicketPurchased - @TicketsUsed),0) END As TicketsAvailable  /* Group ticket changes (SandhyaP) */
			,CASE WHEN @TicketsAvailable >= @MaxTicketsAllowed THEN ISNULL((@MaxTicketsAllowed - @TicketsUsed),0)
				  WHEN @TicketsAvailable < @MaxTicketsAllowed AND ISNULL((@MaxTicketsAllowed - @TicketsUsed),0) <= 0 THEN 0
				  WHEN @TicketsAvailable < @MaxTicketsAllowed AND ISNULL((@MaxTicketsAllowed - @TicketsUsed),0) > 0 THEN ISNULL(@TicketsAvailable,0)
			 END As TicketsAvailable   
			,@MaxTicketsAllowed AS MaxTicketsAllowed		

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

/******************************************************************************
	end procedure
******************************************************************************/
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
		
	END CATCH;
END;


