
CREATE FUNCTION [dbo].[udf_GetCountryCodes](@CountryCodes varchar(max))
RETURNS TABLE
AS
/******************************************************************************
	OBJECT:			[dbo].[udf_GetCountryCodes]
	
	USE:	
			SELECT * FROM [dbo].[udf_GetCountryCodes]('LT;LS;SZ;CH;GE;DE;AU;AT')

	DESCRIPTION:	
		Get country numeric code from string with country codes

	NOTES:
		The @CountryCodes string will have the form '<code-1>;<code-2>;...<code-n>'
		** IMPORTANT ** - If the string ends in ';', you will get 'Unknown' and 'N.A.' in the results

	DEPENDENCIES
	--------------------------------------------------------------------
	v_Countries

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2019-03-04		RogelioR		Initial
	
******************************************************************************/
RETURN
	WITH cops AS (
		SELECT [String] FROM udf_SplitVarchar(@CountryCodes, ';')
	)
	SELECT DISTINCT
			c.[nCountryID] AS [PK_COP]
			,c.[sCountryCode] AS [CountryCode]
			,c.[sCountryCodeISO] AS [CountryCodeISO]
		FROM [v_Countries] AS c
			INNER JOIN cops AS s ON (c.[sCountryCode] = s.[String] OR c.[sCountryCodeISO] = s.[String])