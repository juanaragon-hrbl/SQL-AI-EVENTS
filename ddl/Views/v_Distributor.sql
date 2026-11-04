CREATE VIEW [dbo].[v_Distributor]
AS
SELECT 
	DS.PK_Distributor AS nDistributorID
	,DS.DistributorID AS sDistributorID
	,DS.FirstName AS sFirstName
	,DS.LastName AS sLastName
	,DS.SpouseFirstName
	,DS.SpouseLastName
	,DS.LP_First_name AS LPFirstName
	,DS.LP_Last_Name AS LPLastName
	,REPLACE(ISNULL(CI.Address01,''),'Unknown','')+' '+REPLACE(ISNULL(CI.Address02,''),'Unknown','')+' '+REPLACE(ISNULL(CI.Address03,''),'Unknown','')+' '+REPLACE(ISNULL(Address04,''),'Unknown','') AS sStreet
	,CI.City AS sCity
	,COALESCE(CI.State, CI.Province) AS sDistributorStateOrProvince 
	,CI.PostalCode AS sDistributorPostalCode
	,CR.CountryCode AS sDistributorCountryResidenceCode
	,CR.PK_Country AS nDistributorCountryResidenceID
	,CASE WHEN ST.StatusCode = 'COMPLETE' THEN '2049-12-31' ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.DeletedDateGMT),112) END AS dDeleted
	,ST.StatusCode AS StatusCode
	,CASE WHEN DM.TeamCode IN ('N','-1','-2') THEN NULL ELSE 
		CASE WHEN DST.SubTypeCode IN ('15K','PT') THEN 'P'
             WHEN DST.SubTypeCode = '20K' THEN 'A'
             WHEN DST.SubTypeCode IN ('30K','40K') THEN 'B' 
		     WHEN DST.SubTypeCode IN ('50K','60K','70K','80K','90K','100K','110K','120K','130K','140K','150K','160K','170K','180K','190K','200K','210K','220K','230K','240K','250K','260K','270K','280K','290K','300K','310K','320K','330K','340K','350K','360K','370K','380K','390K','400K') THEN 'C' 
             WHEN DST.SubTypeCode IN ('CC','FC') THEN CASE WHEN DSR.SubTypeCode IN ('15K','PT') THEN 'P'
														   WHEN DSR.SubTypeCode = '20K' THEN 'A'
                     						               WHEN DSR.SubTypeCode IN ('30K','40K') THEN 'B' 
		     						                       WHEN DSR.SubTypeCode IN ('50K','60K','70K','80K','90K','100K','110K','120K','130K','140K','150K','160K','170K','180K','190K','200K','210K','220K','230K','240K','250K','260K','270K','280K','290K','300K','310K','320K','330K','340K','350K','360K','370K','380K','390K','400K') THEN 'C' END
		ELSE DM.TeamCode END END AS sTeam
	,DT.TypeCode AS sType
	,DSL.LanguageCode As sLanguageCode
	,DSL.LanguageName AS sLanguagePreference
	,CI.PrimaryEmail AS sEmail
	,CASE 
		  WHEN LEN(CI.CellPhone) <> 0 THEN CI.CellPhone
		  WHEN LEN(CI.DayPhone) <> 0 THEN CI.DayPhone
	      WHEN LEN(CI.EvePhone) <> 0 THEN CI.EvePhone
	 END AS Phone
	,CONVERT(DATETIME,CONVERT(VARCHAR, DS.ApplicationDate),112) AS dApplication
	,CASE WHEN DS.SPQualDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.SPQualDate),112) END AS dSupervisorQualification
	,CASE WHEN DS.SPReQualDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.SPReQualDate),112) END AS dSupervisorReQualification
	,CASE WHEN DS.SBQualDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.SBQualDate),112) END AS dSBQualification
	--,CASE WHEN DS.SBReQualDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.SBReQualDate),112) END AS dSBRequalQualification
	,CASE WHEN DS.QPQualDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.QPQualDate),112) END AS dQPQualification
	,CASE WHEN DS.QSQualDate = 19000101 THEN NULL WHEN DS.QSQualDate IS NULL THEN NULL ELSE DATEADD(M,DATEDIFF(M,0,CONVERT(DATETIME,CONVERT(VARCHAR,DS.QSQualDate),112)),0) END AS dQSQualification
	,CASE WHEN DS.QSQualDate = 19000101 THEN NULL WHEN DS.QSQualDate IS NULL THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.QSQualDate),112) END AS dQSQualification_Actual
	,CASE WHEN DS.SPDemoteDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.SPDemoteDate),112) END AS dSPDemotion
	,CASE WHEN DS.QPDemoteDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.QPDemoteDate),112) END AS dQPDemotion
	,CASE WHEN DS.RenewalDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.RenewalDate),112) END AS dRenewal
	,CASE WHEN DS.APFDueDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.APFDueDate),112) END dAPFDue
	,CASE WHEN DS.BirthDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.BirthDate),112) END AS dDOB
	,CASE WHEN DS.BirthDate = 19000101 THEN NULL ELSE DS.PK_DSAge END AS nAge
	,CP.CountryCode AS sDistributorCountryProcessingCode
	,CP.PK_Country AS nDistributorCountryProcessingID
	,DS.PK_Sponsor AS nSponsorID
	,LEFT(DS.SponsorID,10) AS sSponsorID
	,CASE WHEN DST.SubTypeCode IN ('N','-1','-2') THEN NULL ELSE DST.SubTypeCode END AS sSubTeam
	,DS.IsCantBuy
	,DS.IsDoNotPay
	,DS.IsHapActive
	,DS.IsCashOnly
	,DS.IsHardCashOnly
	,DS.IsRetired
	,DS.CanEmail
	,CASE WHEN DS.ContractAcceptanceDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.ContractAcceptanceDate),112) END AS ContractAcceptanceDate
FROM
	PubEvents.dbo.dimDistributor DS (NOLOCK)
INNER JOIN
    PubEvents.dbo.dimDSType DT (NOLOCK)
ON
	DS.PK_DSType = DT.PK_DSType
INNER JOIN
	PubEvents.dbo.dimCountry CR (NOLOCK)
ON
	DS.PK_COR = CR.PK_Country
INNER JOIN
	PubEvents.dbo.dimDSTeam DM (NOLOCK)
ON
	DS.PK_DSTeam = DM.PK_DSTeam
INNER JOIN
	PubEvents.dbo.dimCountry CP (NOLOCK)
ON
	DS.PK_COP = CP.PK_Country
INNER JOIN
	PubEvents.dbo.dimDSStatus ST (NOLOCK)
ON
	DS.PK_DSStatus = ST.PK_DSStatus
LEFT JOIN
	PubEvents.dbo.dimDSContactInfo CI (NOLOCK)
ON
	DS.PK_Distributor = CI.PK_Distributor
LEFT JOIN
	PubEvents.dbo.dimDSLanguage DSL (NOLOCK)
ON
	DS.PK_Language = DSL.PK_Language
LEFT JOIN
	PubEvents.dbo.dimDSSubType DST (NOLOCK)
ON
	DS.PK_DSSubType = DST.PK_DSSubType
LEFT JOIN
	PubEvents.dbo.dimDSSubType DSR (NOLOCK)
ON
	DS.PK_SubTypeSrc = DSR.PK_DSSubType