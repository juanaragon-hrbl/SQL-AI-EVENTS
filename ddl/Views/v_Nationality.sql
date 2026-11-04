
CREATE VIEW [dbo].[v_Nationality]
AS
SELECT 
	PK_Country AS nCountryID
	,CountryCode AS sCountryCode
	,CountryCodeISO AS sCountryCodeISO
	,CountryName AS sCountryName
	,IsProcCtry
FROM
	PubEvents.dbo.dimCountry (NOLOCK) 
