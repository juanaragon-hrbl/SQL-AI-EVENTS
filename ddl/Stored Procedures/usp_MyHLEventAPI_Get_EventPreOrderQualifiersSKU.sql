CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventPreOrderQualifiersSKU]
         -- Mandatory Parameters      
		@PK_Event INT 
		,@DistributorID varchar(20) = NULL

		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_EventPreOrderQualifiersSKU

USE:
				DECLARE @e int, @em varchar(4000)
                EXEC dbo.usp_MyHLEventAPI_Get_EventPreOrderQualifiersSKU
					 	@PK_Event = 51696
						,@DistributorID = 'W1098839'
						,@Error = @e OUTPUT
						,@ErrorMessage = @em OUTPUT
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves all the records for event passed

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.SubEvent, dbo.SubEventQualifiers

VERSIONS
----------------------------------------------------------------------------------
1	2017-09-01	OrlandoL		Intitial
2	2019-08-14	NoeG			Refactor code (SRE)
3	2026-06-03	alejandramed	Including all the SKUs used in PreOrder in the result, even if the distributor is not qualified for any subevent, including only EventTicketSKUs and excluding DMMY SKU.
******************************************************************************/

/* DECLARE THE REQUIRED VARIABLES */
DECLARE @PK_Locale INT
DECLARE @PK_DefaultLocale INT
DECLARE @HasQualifications INT
DECLARE @HasAccess INT

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE()
		,@RemovedUTC SMALLDATETIME = '2049-12-31'
	
SELECT @Error = 0, @ErrorMessage = '';

IF OBJECT_ID ('tempDB..#GetInfo', 'U')IS NOT NULL DROP TABLE #GetInfo


BEGIN TRY

	/******************************************************************************
	 Get the DS record if qualified
	******************************************************************************/

	IF @DistributorID IS NOT NULL
	BEGIN
	;WITH GetInfo AS 
	(
		SELECT
			SEQ.DistributorID, D.sSubTeam DSTeam, C.sCountryCodeISO COPISO, D.sType DSType,
			ES.SKUCode,
			CASE WHEN SKU.PK_Distributor_Purchaser IS NOT NULL THEN SKU.Total ELSE 0 END TotalTickets 
		FROM
			dbo.EventPreOrder EP WITH(NOLOCK)
		INNER JOIN 
			dbo.SubEvent SE WITH(NOLOCK)
			ON
				EP.PK_Event = SE.PK_Event
				AND
				EP.SubEventNumber = SE.SubEventNumber
		INNER JOIN
			dbo.SubEventQualifier SEQ WITH(NOLOCK)
			ON
				SEQ.PK_Event = SE.PK_Event
				AND
				SEQ.PK_SubEvent = SE.PK_SubEvent 
				AND
				SEQ.RemovedUTC = @RemovedUTC
		INNER JOIN
			dbo.v_Distributor D
		ON
			D.sDistributorID = SEQ.DistributorID
		INNER JOIN
			dbo.v_Countries C
		ON
			D.nDistributorCountryProcessingID = C.nCountryID
		INNER JOIN
			dbo.EventSKU ES WITH(NOLOCK)
		ON
			SE.PK_Event = ES.PK_Event
			AND
			ES.SubEventAssociated = SE.SubEventNumber
		LEFT JOIN
			(
				SELECT DISTINCT 
					SKU.PK_Event,PK_Distributor_Purchaser, SUM(Quantity) AS Total
				FROM dbo.SKUPurchased SKU WITH(NOLOCK)
				INNER JOIN
					dbo.EventSKU ES WITH(NOLOCK) 
				ON
					SKU.PK_Event = @PK_Event 
					AND
					SKU.PK_Event = ES.PK_Event
					AND
					SKU.PK_EventSKU = ES.PK_EventSKU
					AND
					ES.IsSKUUsedInPreOrder = 1
				GROUP BY
					SKU.PK_Event,PK_Distributor_Purchaser
			) SKU
			ON
				SEQ.PK_Event = SKU.PK_Event
				AND
				SEQ.PK_Distributor = SKU.PK_Distributor_Purchaser
		WHERE
			SEQ.DistributorID = COALESCE(@DistributorID, SEQ.DistributorID)
			AND
			EP.PK_Event = @PK_Event
	)

	SELECT DistributorID
		  ,DSTeam
		  ,COPISO
		  ,DSType
		  ,SKUCode
		  ,TotalTickets INTO #GetInfo FROM GetInfo


	IF EXISTS (SELECT DistributorID
					 ,DSTeam
					 ,COPISO
					 ,DSType
					 ,SKUCode
					 ,TotalTickets FROM #GetInfo)
	BEGIN
	SELECT
		DistributorID, 
		DSTeam, 
		COPISO, 
		DSType,
		TotalTickets,
		STUFF((SELECT ', ' + SKUCode
				FROM #GetInfo B 
				WHERE G.DistributorID = B.DistributorID
				FOR XML PATH('')), 1, 2, '') AS EligibleSKU
	FROM
		#GetInfo G
	GROUP BY
		DistributorID, 
		DSTeam, 
		COPISO, 
		DSType,
		TotalTickets
	END
	ELSE
	BEGIN 
		SELECT DISTINCT
		sDistributorID AS DistributorID, 
		sTeam AS DSTeam, 
		sDistributorCountryProcessingCode AS COPISO, 
		sType AS DSType,
		0 AS TotalTickets, 
		STRING_AGG(SKUCode, ',') AS EligibleSKU
		FROM
			dbo.EventSKU ES WITH(NOLOCK)
		CROSS APPLY (SELECT sDistributorID, sTeam, sDistributorCountryProcessingCode, sType  FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID) D
		WHERE
			ES.PK_Event = @PK_Event
			AND es.IsSKUUsedInPreOrder = 1  
			AND es.IsEnabledForNonQualifiers = 1
			AND es.SKUCode != 'DMMY'
		GROUP BY sDistributorID, sTeam, sDistributorCountryProcessingCode, sType
	END

	END
	ELSE
	BEGIN

	SELECT DISTINCT
		'' AS DistributorID, 
		'' AS DSTeam, 
		'' AS COPISO, 
		'' AS DSType,
		0 AS TotalTickets,
		STUFF((SELECT ', ' + SKUCode
				FROM EventSKU B WITH(NOLOCK)
				WHERE ES.PK_Event = B.PK_Event
				AND B.SKUCode != 'DMMY'
				FOR XML PATH('')), 1, 2, '') AS EligibleSKU
	FROM
		dbo.EventSKU ES WITH(NOLOCK)
	WHERE
		ES.PK_Event = @PK_Event


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
	END PROCEDURE
******************************************************************************/
END