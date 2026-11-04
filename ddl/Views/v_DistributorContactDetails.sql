
CREATE VIEW [dbo].[v_DistributorContactDetails]
AS
SELECT
      DS.PK_Distributor AS nDistributorID
      ,DS.DistributorID AS sDistributorID
      ,DS.FirstName AS sFirstName
      ,DS.LastName AS sLastName
      /*    ,CASE WHEN DT.TeamCode = 'N' THEN NULL ELSE 
            CASE WHEN DST.SubTypeCode IN ('15K','PT') THEN 'P'
                     WHEN DST.SubTypeCode = '20K' THEN 'A'
                     WHEN DST.SubTypeCode IN ('30K','40K') THEN 'B' 
                 WHEN DST.SubTypeCode IN ('50K','60K','70K','90K') THEN 'C' 
                     WHEN DST.SubTypeCode IN ('CC','FC') THEN CASE WHEN DSR.SubTypeCode IN ('15K','PT') THEN 'P'
                                                   WHEN DSR.SubTypeCode = '20K' THEN 'A'
                                                         WHEN DSR.SubTypeCode IN ('30K','40K') THEN 'B' 
                                                   WHEN DSR.SubTypeCode IN ('50K','60K','70K','90K') THEN 'C' END
            ELSE DT.TeamCode END END AS sTeam */
      ,DST.SubTypeCode AS sTeam
      ,DTY.TypeCode AS sType
      ,DST.SubTypeCode AS sSubTeam
	  ,DSS.StatusCode
      ,CONVERT(DATETIME,CONVERT(VARCHAR, DS.SPQualDate),112) AS dsupervisorqualification
      ,C.CountryCode AS sdistributorcountryprocessingcode
      ,ISNULL(NULLIF(COALESCE(CI.Address01,''),'UnKnown'),
              '') + ' ' + ISNULL(NULLIF(COALESCE(CI.Address02,''),'UnKnown'),
                                 '') + ' ' + ISNULL(NULLIF(COALESCE(CI.Address03,''),'UnKnown'),
                                                    '') AS saddress    
      ,CI.City AS sCity
      ,SP.StateProvinceCode
      ,SP.StateProvinceCode AS sStateCode
      ,ISNULL(NULLIF(COALESCE(SP.StateProvinceCode,''),'UnKnown'),'')                  AS sstate,
       ISNULL(NULLIF(COALESCE(PC.PostalCode,''),'UnKnown'),
              '')    AS spostalcode
      ,CC.CountryName AS sCountryName
      ,CASE WHEN CI.DayPhone IS NOT NULL THEN CI.DayPhone
            WHEN CI.EvePhone IS NOT NULL THEN CI.EvePhone
            WHEN CI.CellPhone IS NOT NULL THEN CI.CellPhone
      END AS phone
      ,Cc.PK_Country AS nCountryID
      ,COALESCE(DS.SpouseFirstName,'') + ' ' + COALESCE(DS.SpouseLastName,'') AS SpouseName
      ,C.PK_Country AS nDistributorCountryProcessingID
      ,DS.SpouseFirstName
      ,DS.SpouseLastName
      ,CASE WHEN CI.PrimaryEmail <> 'Unknown' THEN CI.PrimaryEmail ELSE NULL END AS Email
      ,DS.PK_Language
      ,LM.Language
	  ,C.CountryCodeISO AS DistributorCountryProcessingISO
      ,CC.CountryCodeISO AS CountryISO
FROM
      PubEvents.dbo.dimDistributor DS (NOLOCK)
LEFT JOIN
      PubEvents.dbo.dimDSTeam DT (NOLOCK) 
ON
      DS.PK_DSTeam = DT.PK_DSTeam
LEFT JOIN
      PubEvents.dbo.dimDSStatus DSS (NOLOCK) 
ON
      DS.PK_DSStatus = DSS.PK_DSStatus
LEFT JOIN
      PubEvents.dbo.dimDSType DTY (NOLOCK)
ON
      DS.PK_DSType = DTY.PK_DSType
LEFT JOIN
      PubEvents.dbo.dimCountry C (NOLOCK)
ON
      DS.PK_COP = C.PK_Country
LEFT JOIN
      PubEvents.dbo.dimDSContactInfo CI (NOLOCK)
ON
      DS.PK_Distributor = CI.PK_Distributor
LEFT JOIN
      PubEvents.dbo.dimStateProvince SP (NOLOCK)
ON
      CI.PK_StateProvinceAVS = SP.PK_StateProvince
LEFT JOIN
      PubEvents.dbo.dimPostalCode PC (NOLOCK)
ON
      CI.PK_PostalCodeAVS = PC.PK_PostalCode
LEFT JOIN
      PubEvents.dbo.dimCountry CC (NOLOCK)
ON
      CI.PK_CountryAVS = CC.PK_Country
LEFT JOIN
      PubEvents.dbo.dimDSSubType DST (NOLOCK)
ON
      DS.PK_DSSubType = DST.PK_DSSubType
LEFT JOIN
      PubEvents.dbo.dimDSSubType DSR (NOLOCK)
ON
      DS.PK_SubTypeSrc = DSR.PK_DSSubType
LEFT JOIN
      dbo.v_LanguageMapping LM
ON
      DS.PK_Language = LM.PK_Language
