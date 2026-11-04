
CREATE PROCEDURE dbo.usp_MyHLEventAPI_Get_EventPreOrderQualifiers
         -- Mandatory Parameters      
		@PK_Event INT
		 -- Optional Parameters
		,@DistributorID varchar(20) = NULL
	
		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS

BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_EventPreOrderQualifiers

USE:	        
			DECLARE @e int, @em varchar(4000)
                 EXEC dbo.usp_MyHLEventAPI_Get_EventPreOrderQualifiers
					 	@PK_Event = 1160
						,@DistributorID = null --'W1098839'										
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
1	2010-11-24	Prabhu	Intitial
2	2019-08-14	NoeG	Refactor code (SRE)
3	2019-11-04	NoeG	SRE Hardcode changed
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
		,@ValidDate DATETIME = '2049-12-31'
	
SELECT @Error = 0, @ErrorMessage = '';


BEGIN TRY
	/******************************************************************************
	 Get the DS record if qualified
	******************************************************************************/

	IF @DistributorID IS NOT NULL
	BEGIN
		SELECT DISTINCT 
			SEQ.DistributorID, D.sSubTeam DSTeam, C.sCountryCodeISO COPISO, D.sType DSType,
			CASE WHEN SKU.PK_Distributor_Purchaser IS NOT NULL THEN 1 ELSE 0 END HasEventTicket 
		FROM
			dbo.EventPreOrder EP WITH(NOLOCK)
		INNER JOIN 
			dbo.SubEvent SE WITH(NOLOCK)
			ON
				EP.PK_Event = @PK_Event
				AND
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
				SEQ.RemovedUTC = @ValidDate
		INNER JOIN
			dbo.v_Distributor D
		ON
			D.sDistributorID = SEQ.DistributorID
		INNER JOIN
			dbo.v_Countries C
		ON
			D.nDistributorCountryProcessingID = C.nCountryID
		LEFT JOIN
		(
			SELECT DISTINCT 
				SKU.PK_Event,PK_Distributor_Purchaser
			FROM dbo.SKUPurchased SKU WITH (NOLOCK)
			INNER JOIN
				dbo.EventSKU ES  WITH(NOLOCK) 
			ON
				SKU.PK_Event = @PK_Event 
				AND
				SKU.PK_Event = ES.PK_Event
				AND
				SKU.PK_EventSKU = ES.PK_EventSKU
				AND
				ES.IsSKUUsedInPreOrder = 1
		) SKU
		ON
			SEQ.PK_Event = SKU.PK_Event
			AND
			SEQ.PK_Distributor = SKU.PK_Distributor_Purchaser
		WHERE
			SEQ.DistributorID = COALESCE(@DistributorID, SEQ.DistributorID)
	END
	ELSE
	BEGIN 
		SELECT  
			SEQ.DistributorID, D.SubTypeCode DSTeam, C.sCountryCodeISO COPISO, D.TypeCode DSType,
			CASE WHEN SKU.PK_Distributor_Purchaser IS NOT NULL THEN 1 ELSE 0 END HasEventTicket 
		FROM
			dbo.SubEventQualifier SEQ WITH(NOLOCK)
		INNER JOIN
			PubEvents.dbo.dimDistributor D WITH(NOLOCK)
		ON
			D.PK_Distributor = SEQ.PK_Distributor
		INNER JOIN
			dbo.v_Countries C
		ON
			D.PK_COP = C.nCountryID
		LEFT JOIN
		(
			SELECT DISTINCT 
				SKU.PK_Event,PK_Distributor_Purchaser
			FROM dbo.SKUPurchased SKU WITH(NOLOCK)
			INNER JOIN
				dbo.EventSKU ES WITH (NOLOCK) 
			ON
				SKU.PK_Event = @PK_Event 
				AND
				SKU.PK_Event = ES.PK_Event
				AND
				SKU.PK_EventSKU = ES.PK_EventSKU
				AND
				ES.IsSKUUsedInPreOrder = 1
		) SKU
		ON
			SEQ.PK_Event = SKU.PK_Event
			AND
			SEQ.PK_Distributor = SKU.PK_Distributor_Purchaser
		WHERE
			SEQ.PK_Event = 60406 
			AND 
			PK_SubEvent IN (16479)  
			AND 
			RemovedUTC = @ValidDate

	END

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