


CREATE VIEW [dbo].[v_Countries]
AS
SELECT   
       C.PK_Country AS nCountryID  
      ,C.CountryCode AS sCountryCode  
      ,C.CountryCodeISO AS sCountryCodeISO  
      ,CASE	
		WHEN C.CountryName = 'Macedonia' THEN 'FYR of Macedonia' 
		WHEN C.CountryName = 'Republic of Peru' THEN 'Peru'
		ELSE C.CountryName END AS sCountryName 
      ,R.RegionCode AS sRegionCode  
      ,R.RegionName AS sRegionLabel  
      ,'' AS sSubRegion  
FROM  
      PubEvents.dbo.dimCountry C (NOLOCK)   
LEFT JOIN  
      PubEvents.dbo.dimCountryRegion_XREF CR (NOLOCK)  
      ON  
      C.PK_Country = CR.PK_Country  AND
      CR.PK_Region IN (SELECT PK_Region FROM pubEvents.dbo.dimRegion (NOLOCK) WHERE PK_RegionClass IN (SELECT PK_RegionClass FROM pubEvents.dbo.dimRegionClass (NOLOCK) WHERE RegionClassCode = 'CORP')) AND
      ThroughDate = '2049-12-31'
LEFT JOIN
      pubEvents.dbo.dimRegion R (NOLOCK)
      ON CR.PK_Region = R.PK_Region
WHERE 
	C.CountryCode NOT IN ('GR','CH','RS')


