CREATE VIEW [dbo].[v_DistributorAssociate2]
AS
SELECT
       --DS.PK_DSAssociate AS nAssociatetransferID
       DS.CreatedDate AS dTimeStamp
       ,'N/A' AS sAssociateID
       ,D.DistributorID AS sDistributorID
       ,DR.DistributorID AS sMainDistributorID
       ,0 AS Transfer
       ,DS.FromDate AS dFrom
       ,DS.ThroughDate AS dThrough
       ,' ' AS sNotes
       ,DS.PK_Distributor AS nDistributorID
       ,DS.PK_MainDistributor AS nMainDistributorID
       ,DR.LastName AS sMainLastName
       ,DR.FirstName AS sMainFirstName
       ,'2' AS sCode
       ,'2' AS sType
       ,' ' AS AssocType
FROM
       pubEvents.dbo.dimDSAssociate DS (NOLOCK)
INNER JOIN
    pubEvents.dbo.dimDistributor D (NOLOCK)
ON
       DS.PK_Distributor = D.PK_Distributor
INNER JOIN
       pubEvents.dbo.dimDistributor DR (NOLOCK)
ON
       DS.PK_MainDistributor = DR.PK_Distributor
WHERE DS.GCASSOCID IS NULL
UNION
--GC Association
SELECT
       --DS.PK_DSAssociate AS nAssociatetransferID
       DS.CreatedDate AS dTimeStamp
       ,'N/A' AS sAssociateID
       ,D.DistributorID AS sDistributorID
       ,DR.DistributorID AS sMainDistributorID
       ,0 AS Transfer
       ,DS.FromDate AS dFrom
       ,DS.ThroughDate AS dThrough
       ,' ' AS sNotes
       ,DS.PK_Distributor AS nDistributorID
       ,DS.PK_MainDistributor AS nMainDistributorID
       ,DR.LastName AS sMainLastName
       ,DR.FirstName AS sMainFirstName
       ,'GC' AS sCode
       ,'GC' AS sType
       ,' ' AS AssocType
FROM
       pubEvents.dbo.dimDSAssociate DS (NOLOCK)
INNER JOIN
    pubEvents.dbo.dimDistributor D (NOLOCK)
ON
       DS.PK_Distributor = D.PK_Distributor
INNER JOIN
       pubEvents.dbo.dimDistributor DR (NOLOCK)
ON
       DS.PK_MainDistributor = DR.PK_Distributor
WHERE DS.GCASSOCID IS NOT NULL

UNION
SELECT
        --DS.PK_DSTransfers AS nAssociatetransferID
       DS.CreatedDate AS dTimeStamp
       ,'N/A' AS sAssociateID
       ,D.DistributorID AS sDistributorID
       ,DR.DistributorID AS sMainDistributorID
       ,1 AS Transfer
       ,CONVERT(DATETIME,'1900-01-01',120) AS dFrom
       ,CONVERT(DATETIME,'2049-12-31',120) AS dThrough
       ,' ' AS sNotes
       ,DS.PK_FromDistributor AS nDistributorID
       ,DS.PK_RollupDistributor AS nMainDistributorID
       ,DR.LastName AS sMainLastName
       ,DR.FirstName AS sMainFirstName
       ,' ' AS sCode
       ,TT.TransferTypeCode AS sType
       ,' ' AS AssocType
FROM
       pubEvents.dbo.dimDSTransfers DS 
INNER JOIN
    pubEvents.dbo.dimDistributor D (NOLOCK)
ON
       DS.PK_FromDistributor = D.PK_Distributor
INNER JOIN
       pubEvents.dbo.dimDistributor DR (NOLOCK)
ON
       DS.PK_RollupDistributor = DR.PK_Distributor
INNER JOIN
       pubEvents.dbo.dimDSTransferType TT (NOLOCK)
ON
       DS.PK_TransferType = TT.PK_TransferType
GO


