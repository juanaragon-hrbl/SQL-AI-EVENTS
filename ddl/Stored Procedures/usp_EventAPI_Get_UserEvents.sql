CREATE PROCEDURE [dbo].[usp_EventAPI_Get_UserEvents]
-- REQUIRED
@EventID int

-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT

-- QA/DEV
,@IsDevQA bit = 0 
	
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_UserEvents

USE:			DECLARE @e int
                       ,@em varchar(200)
                EXEC usp_EventAPI_Get_UserEvents @EventID = 376
                                               , @Error = @e OUTPUT  /* @e must be defined in the local call */
						                       , @ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						                       , @IsDevQA = 0

					SELECT @e AS [Error], @em AS [Error Message]


DESCRIPTION:	Retrieves record from dbo.SubEvent

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent

VERSIONS
--------------------------------------------------------------------
1		2009-01-21	Sandhya			Initial
1.1		2019-05-10	alejandramed	Homologating of standard error handling	

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
	 Check if the Event Exists
	******************************************************************************/
	IF NOT EXISTS (SELECT PK_Event FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @EventID)
	  BEGIN
		SET @Error = 169
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
			@ProcedureName = @StoredProcedure 
			,@ErrorNumber = @Error
			,@ErrorMessage = @ErrorMessage OUTPUT
		RETURN 
	  END
 
	/******************************************************************************
	  Get Event Details
	******************************************************************************/


	BEGIN 

	/* Event Details */

	SELECT  
			 E.[PK_Event] 
			,E.[CreatedDateUTC] 
			,E.[CreatedBy] 
			,E.[ModifiedDateUTC] 
			,E.[IsTicketPurchaseRequired] 
			,E.[IsPreRegistrationRequired]
			,E.[CanAssignTickets] 
			,E.[IsRFIDRequired]
			,E.[IsHotelEnabled]
			,E.[MaxNoOfGuest]
			,E.[MaxNoOfPrimaryGuest] 
			,E.[MaxCapacity] 
			,E.[ExpectedCapacity]
			,E.[EventTimeZone]
			,E.[EventNamePositionID] 
			,E.[ModifiedBy] 
			,E.[PK_EventType]
			,ET.[EventType]
			,E.[PK_OldEventApp]
			,E.[EventName] 
			,E.[dStartUTC] 
			,E.[dEndUTC]
			,E.[StoredProcedure] 
			,E.[Location]
			,E.[LocalName]
			,CASE WHEN AG.PK_Event IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS DisplayAgenda
	FROM 
	   dbo.Event E WITH (NOLOCK)
	INNER JOIN
	   dbo.EventType ET WITH (NOLOCK)
	ON 
	   E.PK_EventType = ET.PK_EventType
	LEFT JOIN
		(SELECT TOP 1 PK_Event FROM dbo.Agenda WITH (NOLOCK) WHERE PK_Event = @EventID) AG
	ON
		AG.PK_Event = @EventID 
	WHERE
	   E.PK_Event = @EventID
  

	/******************************************************************************
	  Get Event SKUs
	******************************************************************************/

	SELECT
	   ES.[PK_EventSKU]
	  ,ES.[SKUCode]
	  ,ES.[SKUDesc]
	  ,ES.[Price]
	  ,ES.[VolumePoints]
	  ,ES.[QuantityInStock]
	  ,ES.[QuantitySold]
	  ,ES.[WarehouseID]
	  ,ES.[SKUValidBeginUTC]
	  ,ES.[SKUValidEndUTC]
	  ,ES.[NumberOfTicketsPerSKU]
	  ,ES.[PK_EventSKUType]
	FROM 
	  dbo.EventSKU ES WITH (NOLOCK)
	INNER JOIN
	  dbo.Event E WITH (NOLOCK)
	 ON
	   ES.PK_Event = E.PK_Event
	WHERE
	   E.PK_Event = @EventID
	 AND
		ES.IsEventTicketSKU = 1


	/******************************************************************************
	  Get Qualified Countries list for this Event
	******************************************************************************/

	SELECT
	  EDC.[PK_EventDistributorCountry]
	 ,EDC.[PK_Country]
	 ,C.[sCountryName]
	 ,C.[sCountryCode]
	FROM 
	  dbo.EventDistributorCountry EDC WITH (NOLOCK)
	INNER JOIN
	  dbo.v_Countries C
	ON 
	  EDC.PK_Country = C.nCountryID
	WHERE
	  EDC.PK_Event = @EventID


	/******************************************************************************
	  Get SubEvent Info for this Event
	******************************************************************************/

	SELECT [PK_SubEvent]
		  ,[PK_Event]
		  ,[PK_SubEventType]
		  ,[MaxCapacity]
		  ,[ExpectedCapacity]
		  ,[SubEventName]
		  ,[SubEventNumber]
		  ,[SubEventFormula]
		  ,[SubEventNamePositionID]
		  ,[Location]
		  ,[LocalName]
		  ,[BeginTime]
		  ,[EndTime]
	  FROM 
		   [dbo].[SubEvent] WITH (NOLOCK)
	  WHERE
		   PK_Event = @EventID
  

	END

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
	RETURN 
END CATCH;
END
GO

