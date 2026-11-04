CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventSKU]
         -- Mandatory Parameters
		  @SKUCode VARCHAR(4)
		 --,@CountryCode CHAR(2)
		-- Error Parameters
		,@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_EventSKU

USE:
			DECLARE @e int, @em varchar(4000)
                 EXEC dbo.usp_MyHLEventAPI_Get_EventSKU
						 @SKUCode = 'E090'
						--,@CountryCode = 'US'
						,@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Retrieves all the records for event passed

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------------------
dbo.EventSKU
This procedure validates if a SKUCode that is passed is a VALID SKU and EXISTS IN HMS

VERSIONS
----------------------------------------------------------------------------------------------
1	2011-02-25	Prabhu			Intitial
2	2019-08-14	NoeG			Refactor code (SRE)
3	2025-06-26	alejandramed	Including SKU Description
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @FinalQuery VARCHAR(4000)
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
/* ***************** SonarQube check 99 and 100 - Output parameters should be assigned 
	SRE changes added
*/
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	/* CREATE THE TEMP TABLE TO HOLD THE DATA */
	CREATE TABLE #Temp
	(
		SKUCode			VARCHAR(10),
		CountryCode		VARCHAR(10),
		FromDate		DATETIME,
		ThroughDate		DATETIME
	)

	/*
	/* WRITE THE OPEN QUERY TO SEE IF THE SKUCODE - COUNTRYCODE COMBINATION EXISTS IN HMS */
	SET @FinalQuery= 'INSERT INTO #Temp (SKUCode,CountryCode,FromDate,ThroughDate) SELECT SELLING_SKU,CTRY_ISO,FROM_DT,THRU_DT FROM OPENQUERY(LS_ORA_HLPRD_XXHC, ''SELECT 
		MSI.INVENTORY_ITEM_ID,
		QLL.LIST_LINE_ID,
		MSI.SEGMENT1 STOCKING_SKU,
		QLL.PRODUCT_UOM_CODE UOM,
		MCR.CROSS_REFERENCE_TYPE XREF,
		MCR.CROSS_REFERENCE SELLING_SKU,
		QLH.ATTRIBUTE1 CTRY_ISO,
		XDCM.HLIFE_COUNTRY_CODE CTRY_HLIFE,    
		QLL.START_DATE_ACTIVE FROM_DT,
		QLL.END_DATE_ACTIVE THRU_DT,
		QLL.OPERAND LOCALRETAILAMOUNT,                        
		QLL.ATTRIBUTE1 LOCALEARNBASE,
		QLL.ATTRIBUTE2 TAXBASE,
		QLL.CREATION_DATE,
		QLL.LAST_UPDATE_DATE
	FROM 
		APPS.QP_SECU_LIST_HEADERS_V QLH
	INNER JOIN 
		APPS.QP_LIST_LINES_V QLL
		ON QLH.LIST_HEADER_ID = QLL.LIST_HEADER_ID
	INNER JOIN 
		APPS.MTL_SYSTEM_ITEMS_B MSI
		ON QLL.PRODUCT_ATTR_VALUE = TO_CHAR(MSI.INVENTORY_ITEM_ID)
	INNER JOIN APPS.XHL_DM_COUNTRY_MAPPING XDCM
		ON XDCM.ISO_COUNTRY_CODE= QLH.ATTRIBUTE1
		AND XDCM.DEF_RES_COUNTRY = ''''Y''''  
	LEFT JOIN
		APPS.MTL_CROSS_REFERENCES MCR
		ON MSI.INVENTORY_ITEM_ID = MCR.INVENTORY_ITEM_ID AND
		   MCR.ATTRIBUTE2 = QLL.PRODUCT_UOM_CODE AND       
		   MCR.CROSS_REFERENCE_TYPE LIKE 
		   CASE 
				WHEN XDCM.HLIFE_COUNTRY_CODE = ''''HE'''' THEN ''''GR'''' 
				ELSE XDCM.HLIFE_COUNTRY_CODE 
		   END || ''''%_XREF''''
	WHERE
		(QLH.NAME LIKE ''''%DISTRIBUTOR ORDER PRICELIST'''' OR QLH.NAME LIKE ''''%DIST% ORD% PRICELIST'''' OR QLH.NAME LIKE ''''%EVENT% PRICELIST''''  ) AND  
		QLL.PRODUCT_ATTRIBUTE_CONTEXT = ''''ITEM'''' AND
		MSI.ORGANIZATION_ID = 86
		AND MCR.CROSS_REFERENCE = ''''' + @SKUCode  + '''''' + ''')'
	EXEC (@FinalQuery)
	*/


	SELECT 
		[SKUCode],
		[SKUDesc]
	FROM
		PubEvents.dbo.dimSellingSKU WITH(NOLOCK)
	WHERE
		[SKUCode] = @SKUCode
		AND
		[ObsoleteDate] = 20491231
	

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

	--/* SELECT THE RECORDS */
	--SELECT Distinct * FROM #Temp WHERE CONVERT(DATETIME,CONVERT(VARCHAR(10),GETDATE(),120),120) BETWEEN FromDate AND ThroughDate

	--/* DROP TABLE AFTER THE SELECT IS DONE */
	--DROP TABLE #Temp

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END