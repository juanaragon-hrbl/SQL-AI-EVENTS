CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventBadgePrintingSubEvents]	
	-- MANDATORY
	@DistributorID VARCHAR(20)
	,@PK_ER INT
	,@EventID INT 
	-- OPTIONAL
	,@Error	int = 0 OUTPUT 
	,@ErrorMessage varchar(4000) = '' OUTPUT
	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN


/*
OBJECT:		dbo.usp_MyHLEventAPI_Get_EventBadgePrintingSubEvents

USE:		DECLARE @e int, @em varchar(200)	
			EXEC usp_MyHLEventAPI_Get_EventBadgePrintingSubEvents
					 @DistributorID = 'Staff'
					,@PK_ER = 454602 
					,@EventID = 951
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 0
			Print @em
DESCRIPTION: Get feature Badge Printing

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2013-01-15	OrlandoL	Initial
2	2019-08-14	NoeG		Refactor code (SRE)
3	2019-10-30	NoeG		SRE Hardcode changed

*/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE @PK_Distributor INT

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@ValidDate DATETIME = '2049-12-31'	

SELECT @Error = 0, @ErrorMessage = '';

/**************************************************************************************
 Validate if the DistributorID and Event ID are valid 
****************************************************************************************/
SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WITH(NOLOCK) WHERE sDistributorID = @DistributorID
IF @@ROWCOUNT = 0
BEGIN
	SET @Error = 8
	-- Update ErrorLosg
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END

IF NOT EXISTS (SELECT PK_Event FROM dbo.Event WITH(NOLOCK) WHERE PK_Event = @EventID AND IsBadgePrinting = 1)
BEGIN
	SET @Error = 409
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN 
END
	
	
/******************************************************************************
Get SubEvents that the DS has qualified for 
******************************************************************************/
BEGIN TRY
	
IF NOT EXISTS (SELECT PK_Distributor FROM dbo.EventBadgePrinting WITH(NOLOCK) WHERE PK_EventsRegistration = @PK_ER AND PK_Event = @EventID)
	BEGIN
		
		SELECT 
			ER.PK_EventsRegistration,
			ER.DistributorID,
			ER.FirstName,
			ER.LastName,
			C.sCountryName AS Country,
			ER.DistributorTeam AS TeamStatus
		FROM
			dbo.EventsRegistration ER WITH(NOLOCK)
		INNER JOIN
			dbo.v_Distributor D 
		ON
			ER.PK_Distributor = D.nDistributorID
		INNER JOIN
			dbo.v_Countries C
		ON
			D.sDistributorCountryProcessingCode = C.sCountryCode
		WHERE
			ER.PK_Distributor = @PK_Distributor
			AND
			ER.PK_Event = @EventID
			AND
			ER.PK_EventsRegistration = @PK_ER
			
		SELECT DISTINCT 
			SE.PK_SubEvent,
			SE.SubEventName,
			SE.SubEventNumber
		FROM
			dbo.SubEventQualifier SEQ WITH(NOLOCK)
		INNER JOIN		
			dbo.SubEvent SE WITH(NOLOCK)
		ON
			SEQ.PK_Event = SE.PK_Event
			AND
			SEQ.PK_SubEvent = SE.PK_SubEvent
		INNER JOIN
			dbo.EventsRegistration ER WITH(NOLOCK)
		ON
			SEQ.PK_Distributor = ER.PK_Distributor
			AND
			SEQ.PK_Event = ER.PK_Event
		WHERE
			SEQ.PK_Event = @EventID
			AND
			SEQ.Qualified = 1
			AND
			RemovedUTC = @ValidDate
			AND
			SEQ.PK_Distributor = @PK_Distributor
	END
ELSE
	BEGIN
	
		SELECT 
			EBP.PK_EventsRegistration,
			EBP.DistributorID,
			EBP.FirstName,
			EBP.LastName,
			EBP.COP AS Country,
			EBP.TeamStatus AS TeamStatus
		FROM
			dbo.EventBadgePrinting EBP WITH(NOLOCK)
		WHERE
			EBP.PK_Event = @EventID
			AND
			EBP.PK_EventsRegistration = @PK_ER
			
		SELECT 
			COALESCE(EBSE.PK_SubEvent,SEQ.PK_SubEvent) AS PK_SubEvent,
			COALESCE(EBSE.SubEventDisplayName,SE.SubEventName) AS SubEventName,
			COALESCE(EBSE.SequenceNo,SE.SubEventNumber) AS SubEventNumber
		FROM
			dbo.EventBadgePrinting EBP WITH(NOLOCK)
		INNER JOIN
			dbo.SubEventQualifier SEQ WITH(NOLOCK)
		ON
			SEQ.PK_Distributor = @PK_Distributor
			AND
			SEQ.RemovedUTC = @ValidDate
			AND
			SEQ.PK_Event = @EventID 
		LEFT JOIN
			dbo.EventBadgeSubEvents EBSE WITH(NOLOCK)
		ON
			EBP.PK_Event = EBSE.PK_Event
			AND
			EBP.PK_EventBadgePrinting = EBSE.PK_EventBadgePrinting
			AND
			SEQ.PK_Distributor = EBSE.PK_Distributor 
			AND
			SEQ.PK_Event = EBSE.PK_Event  
			AND
			SEQ.PK_SubEvent = EBSE.PK_SubEvent 
		INNER JOIN
			dbo.SubEvent SE WITH(NOLOCK)
		ON
			SE.PK_Event = SEQ.PK_Event 
			AND
			SE.PK_SubEvent = SEQ.PK_SubEvent
		WHERE
			EBP.PK_Event = @EventID
			AND
			EBP.PK_EventsRegistration = @PK_ER
	END

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
	END Procedure
******************************************************************************/
END
