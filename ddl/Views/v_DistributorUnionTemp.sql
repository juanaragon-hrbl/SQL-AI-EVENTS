CREATE VIEW [dbo].[v_DistributorUnionTemp]  
AS
SELECT  
	nDistributorID  
	,sDistributorID  
	,sFirstName
	,sLastName
	,sTeam
	,sType
	,sAddress
	,sCity
	,sState
	,sPostalCode
	,Phone AS sPhone
	,'Distributor' AS DSClass
    ,sdistributorcountryprocessingcode
	,nDistributorCountryProcessingID
	,StatusCode
	,sSubTeam
FROM  
	dbo.v_DistributorContactDetails 
UNION
SELECT
	D.PK_Temp AS nDistributorID
	,D.DistributorID AS sDistributorID
	,D.FirstName AS sFirstName
	,D.LastName AS sLastName
	,'' AS sTeam
	,'' AS sType
	,ISNULL(COALESCE(D.Address1,''),'') + ' ' + ISNULL(COALESCE(D.Address2,''),'') + ' ' + ISNULL(COALESCE(D.Address3,''),'') AS sAddress
	,D.City AS sCity
	,D.State as sState
	,D.ZipCode AS sPostalCode
	,ISNULL(COALESCE(D.DayPhone,''),'') + ' ' + ISNULL(COALESCE(D.EveningPhone,''),'') + ' ' + ISNULL(COALESCE(D.MobilePhone,''),'') AS sPhone
	,'Temp' AS DSClass
	,'' AS sdistributorcountryprocessingcode
	,'' AS nDistributorCountryProcessingID
	,'COMPLETE' AS StatusCode
	,'' AS sSubTeam
FROM
	dbo.TempDistributors D (NOLOCK) WHERE NOT EXISTS (SELECT * FROM dbo.v_Distributor C WHERE D.DistributorID = C.sDistributorID)
UNION
SELECT
	D.nDistributorID
	,D.sDistributorID
	,D.SpouseFirstName AS sFirstName
	,D.SpouseLastName AS sLastName
	,D.sTeam
	,D.sType
	,D.sAddress
	,D.sCity
	,D.sState
	,D.sPostalCode
	,D.Phone AS sPhone
	,'Spouse' AS DSClass
	,D.sdistributorcountryprocessingcode
	,D.nDistributorCountryProcessingID
	,D.StatusCode
	,D.sSubTeam
FROM
	dbo.v_DistributorContactDetails D
WHERE 
	CASE WHEN D.SpouseName = ' ' THEN NULL ELSE D.SpouseName END IS NOT NULL