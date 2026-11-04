CREATE VIEW [dbo].[v_DistributorCurrentChairmanClub]
AS
SELECT
	CC.PK_Distributor
	,DS.DistributorID AS DistributorID
	,DS.IsMainID AS IsMain
	,DSM.DistributorID AS MainDistributorID
	,convert(datetime, convert(char(8), CC.FromDate)) AS ChairmanQualificationDate
FROM
	PubEvents.dbo.dimDSHistory CC (NOLOCK)
INNER JOIN
	PubEvents.dbo.dimDSLifeCycle LC (NOLOCK)
ON
	CC.PK_LifeCycle = LC.PK_LifeCycle	
AND
	LC.LifeCycleName = 'Qual Chairman Club'
AND
	CC.ThroughDate = 20491231
INNER JOIN
	PubEvents.dbo.dimDistributor DS (NOLOCK)
ON
	CC.PK_Distributor = DS.PK_Distributor
INNER JOIN
	PubEvents.dbo.dimDistributor DSM (NOLOCK)
ON
	DS.PK_MainDistributor = DSM.PK_Distributor