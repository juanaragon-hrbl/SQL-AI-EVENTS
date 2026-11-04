

CREATE VIEW [dbo].[v_SupervisorLineage]
AS
WITH LatestMonth (RoyaltyMonth) AS
(
	SELECT
		MAX(RoyaltyMonth)
	FROM
		PubEvents.dbo.dimSPLngUpline WITH (NOLOCK)
)
SELECT
	CONVERT(DATETIME,CONVERT(VARCHAR, ((SP.RoyaltyMonth*100)+1)),112) AS dRoyaltyMonth
	,SP.CreatedDate AS dCreateDate
	,SP.PK_Supervisor AS nDistributorID
	,SP.PK_Sponsor AS nSponsorID
	,SP.LineageTree AS vcLineage
	,DS.IsMainID AS nDistributorIsMainID
	,CASE WHEN DS.IsMainID = 1 THEN SP.PK_Supervisor ELSE DA.PK_MainDistributor END AS nDistributorMain
	,SP.Level AS nSPLevel
	,DT.TypeCode AS sDistributorType
	,ST.TeamCode AS sDistributorTeam
	,CONVERT(DATETIME,CONVERT(VARCHAR, DS.ApplicationDate),112) AS dAppDate
	,CASE WHEN DS.SPQualDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.SPQualDate),112) END AS dQualDate
	,CASE WHEN DS.SPRequalDate = 19000101 THEN NULL ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DS.SPRequalDate),112) END AS sReQualDate
	,DC.CountryCode AS sDistributorProcessingCountry
	,SP.FirstUplineSP AS nFirstUplineSP
	,SP.FirstUplineSPMain AS nFirstUplineSPMain
	,SP1.FirstUplineSP AS nSecondUplineSP
	,SP1.FirstUplineSPMain AS nSecondUplineSPMain
	,SP2.FirstUplineSP AS nThirdUplineSP
	,SP2.FirstUplineSPMain AS nThirdUplineSPMain
	,SP.FirstUplineGet AS nFirstUplineGet
	,SP.FirstUplineGetMain AS nFirstUplineGetMain
	,SP.FirstUplineMill AS nFirstUplineMill
	,SP.FirstUplineMillMain AS nFirstUplineMillMain
	,SP.FirstUplinePres AS nFirstUplinePres
	,SP.FirstUplinePresmain AS nFirstUplinePresMain
	,SP.FirstUplineTAB AS nFirstUplineTAB
	,SP.FirstUplineTABMain AS nFirstUplineTABMain
	,SP.FirstUplineCC AS nFirstUplineChairman
	,SP.FirstUplineCCMain AS nFirstUplineChairmanMain
FROM
	PubEvents.dbo.dimSPLngUpline SP (NOLOCK)
INNER JOIN
	LatestMonth M
ON	
	SP.RoyaltyMonth = M.RoyaltyMonth
INNER JOIN
	PubEvents.dbo.dimSPLngUpline SP1 (NOLOCK)
ON
	SP1.PK_Supervisor = SP.FirstUplineSP
	AND
	SP1.RoyaltyMonth = SP.RoyaltyMonth
INNER JOIN
	PubEvents.dbo.dimSPLngUpline SP2 (NOLOCK)
ON
	SP2.PK_Supervisor = SP1.FirstUplineSP
	AND
	SP2.RoyaltyMonth = SP.RoyaltyMonth
INNER JOIN
	PubEvents.dbo.dimDistributor DS (NOLOCK)
ON
	DS.PK_Distributor = SP.PK_Supervisor
LEFT JOIN
	PubEvents.dbo.dimCountry DC (NOLOCK)
ON
	DC.PK_Country = DS.PK_COP
LEFT JOIN
	PubEvents.dbo.dimDSType DT (NOLOCK)
ON
	DT.PK_DSType = DS.PK_DSType
LEFT JOIN
	PubEvents.dbo.dimDSTeam ST (NOLOCK)
ON
	ST.PK_DSTeam = DS.PK_DSTeam
LEFT JOIN
	PubEvents.dbo.dimDSAssociate DA (NOLOCK)
ON
	DA.PK_Distributor = SP.PK_Supervisor
	AND
	DA.ThroughDate = '2049-12-31'
