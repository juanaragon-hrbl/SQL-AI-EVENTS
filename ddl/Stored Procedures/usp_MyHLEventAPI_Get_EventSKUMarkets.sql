
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventSKUMarkets]
	@SKUCode varchar(5) 
	,@CountryCode varchar(2)
	,@Error INT OUTPUT
	,@ErrorMessage VARCHAR(200) OUTPUT
	,@IsDevQA bit = 0 --[optional]

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Get_EventSKUMarkets
USE:
			declare @e int
			declare @em varchar(200)
			declare @IsDevQA int

			EXEC usp_MyHLEventAPI_Get_EventSKUMarkets
					@SKUCode = 'C042'
					,@CountryCode = 'CA'
					,@Error = @e OUTPUT  /* @e must be defined in the local call */
					,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */					
					-- OPTIONAL
					,@IsDevQA = 0

DESCRIPTION: RETREIVES AVAILABLE MARKETS/LOCALES FOR A SPECIFIC SKUCODE AND COUNTRY

NOTES:	THIS API IS INVOKED ON MYHL APP (Add Corporate Event page ->Qualification section),
		TO GET THE LOCALES FOR A SPECIFIC SKU AND COUNTRY PASSED. SKU AND COUNTRY INFORMATION 
		IS VALIDATED FIRST FROM HMS SYSTEM THROUGH usp_MyHLEventAPI_Get_EventSKU API.

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2013-01-30			SandhyaP		Initial
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON		
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SET @Error = 0
SET @ErrorMessage = 'No Error.'

/******************************************************************************
	Get the Locales/Markets for a specific SKUCode and CountryCode
******************************************************************************/

SELECT DISTINCT
	S.ECM_SKU_ID, L.COUNTRY_CODE_ISO, C.COUNTRY_NAME, S.LOCALE, LO.LanguageCountryRegion
FROM 
	InternetECM.dbo.INT_Product P
INNER JOIN
	InternetECM.dbo.INT_ProductSKU PS
	ON 
		P.PRODUCT_ID = PS.PRODUCT_ID
INNER JOIN
	InternetECM.dbo.INT_SKU S
	ON
		PS.SKU_ID = S.SKU_ID
		AND
		P.LOCALE = S.LOCALE	
INNER JOIN
	InternetECM.dbo.LuLocale L
	ON
		S.LOCALE = L.LOCALE	
		AND
		P.LOCALE = L.LOCALE
INNER JOIN
	InternetECM.dbo.LuCountry C
	ON
		L.COUNTRY_CODE_ISO = C.COUNTRY_CODE_ISO		
LEFT JOIN
	dbo.Locales LO
	ON
		REPLACE(L.LOCALE,'_','-') = LO.LocaleCode			
WHERE 
	P.HL_PRODUCT_TYPE = 'E'
	AND PS.PLATFORM_CODE = '001'
	AND S.ECM_SKU_ID = @SKUCode
	AND C.COUNTRY_CODE_ISO = @CountryCode
		

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END
