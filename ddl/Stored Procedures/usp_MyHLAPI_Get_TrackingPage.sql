
CREATE PROCEDURE [dbo].[usp_MyHLAPI_Get_TrackingPage]
	-- Required
	@PK_Event int
	,@DistributorID varchar(10)
	,@IsTrackLogoAvail int = 0

	-- QA/DEV
       ,@IsDevQA		BIT = 0   
	   ,@Error	int = 0 OUTPUT
	   ,@ErrorMessage varchar(4000) = NULL OUTPUT


AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_MyHLAPI_Get_TrackingPage

USE:			DECLARE @e int, @em varchar(200)

				EXEC usp_MyHLAPI_Get_TrackingPage
					@PK_Event = 41
					,@DistributorID = '37128074'
					,@IsTrackLogoAvail  = 1

DESCRIPTION:	Gets subevent qualifications for @DistributorID for @PK_Event

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.Event

VERSIONS
--------------------------------------------------------------------
1	2009-07-28	ScottB	Initial
2	2019-10-16   JonathanO  	SRE 
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE 
	@StoredProcedure varchar(100) 
	,@StartTime datetime
	,@PK_Distributor int
	,@logoPath varchar(200)

SET @StoredProcedure = 'usp_MyHLAPI_Get_TrackingPage'
SET @StartTime = GETUTCDATE()

SELECT @PK_Distributor = nDistributorID FROM dbReport.dbo.tblDistributor WITH (NOLOCK) WHERE sDistributorID = @DistributorID
SELECT @IsTrackLogoAvail = IsTrackLogoAvail FROM dbo.Event WITH (NOLOCK) WHERE PK_Event = @PK_Event

BEGIN TRY


/******************************************************************************
	logo url
******************************************************************************/
SET @logoPath = '/Content/Global/assets/img/'

IF @IsTrackLogoAvail = 1
	SET @logoPath = @logoPath + 'logo' + RIGHT('0000' + CONVERT(varchar,@PK_Event),4) + '.jpg'
ELSE
	SET @logoPath = @logoPath + 'blank.png'

SELECT @logoPath 'logoPath'

/******************************************************************************
	tickets purchased
******************************************************************************/
SELECT
	COUNT(DISTINCT ET.PK_EventTicket) 'TicketsPurchased'
FROM
	dbo.EventTickets ET WITH (NOLOCK)
INNER JOIN
	dbo.EventSKU SKU WITH (NOLOCK)
	ON
		ET.PK_EventSKU = SKU.PK_EventSKU
INNER JOIN
	dbo.Event E WITH (NOLOCK)
	ON
		ET.PK_Event = E.PK_Event
		AND E.PK_Event = @pk_event
WHERE
	PK_Purchaser = @PK_Distributor

/******************************************************************************
	subevents
******************************************************************************/
SELECT DISTINCT
	SE.SubEventNumber
	,SE.SubEventName
	,CASE WHEN SEQ.DistributorID IS NULL THEN 0 ELSE 1 END 'isQualified'
	,E.EventName
    ,E.IsTrackLogoAvail 
FROM
	dbo.SubEvent SE WITH (NOLOCK)
LEFT JOIN
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
	ON
		SE.PK_SubEvent = SEQ.PK_SubEvent
		AND SEQ.DistributorID = @DistributorID
		AND SEQ.RemovedUTC = '2049-12-31' 
INNER JOIN
	dbo.Event E WITH (NOLOCK)
	ON
		SE.PK_Event = E.PK_Event
WHERE
	SE.PK_Event = @PK_Event
	AND SE.isTrackingVisible = 1
ORDER BY
	SE.SubEventNumber

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