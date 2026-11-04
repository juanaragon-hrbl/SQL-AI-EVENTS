
CREATE VIEW [dbo].[v_MailingAddress]
AS
SELECT
	PK_DSContactInfo AS nContactID
	,PK_Distributor AS nDistributorID
	,'C' AS sStatus
	,Address01 AS sAddress1
	,Address02 AS sAddress2
	,Address03 AS sAddress3
	,Address04 AS sAddress4
	,City AS sCity
	,State AS sState
	,PostalCode AS sPostalCode
	,County AS sCounty
	,ISNULL(CountryCode,'00') AS sCountry
	,'' AS sBadAddressFlag
FROM
	pubEvents.dbo.dimDSContactInfo (NOLOCK)
