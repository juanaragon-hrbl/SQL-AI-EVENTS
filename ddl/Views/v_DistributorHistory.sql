

CREATE VIEW [dbo].[v_DistributorHistory]
AS
SELECT
LC.LifeCycleCode AS nEventTypeLID
,DH.PK_Distributor AS nDistributorIDFK
,DS.DistributorID AS sDistributorID
,CONVERT(DATETIME,CONVERT(VARCHAR, DH.FromDate),112) AS dFrom
,CASE WHEN DS.PK_DSType = 5 AND LC.LifeCycleCode = 220 AND DH.FromDate = DS.SPQualDate AND DH.ThroughDate <> 20491231 THEN '2049-12-31' ELSE CONVERT(DATETIME,CONVERT(VARCHAR, DH.ThroughDate),112) END AS dThrough
,LC.SortOrder
FROM
pubEvents.dbo.dimDSHistory DH (NOLOCK)
INNER JOIN
dbo.v_dimDSLifeCycle LC 
ON
DH.PK_LifeCycle = LC.PK_LifeCycle
INNER JOIN
pubEvents.dbo.dimDistributor DS (NOLOCK)
ON
DH.PK_Distributor = DS.PK_Distributor

