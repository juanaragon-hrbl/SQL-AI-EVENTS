
CREATE VIEW [dbo].[v_DistributorSet]
AS
SELECT        DLD.PK_DSListDetail AS nDistributorListID, DLD.PK_DSList AS nTypeLID, D.PK_Distributor AS nDistributorID, D.DistributorID, DLD.ValidFromDateUTC AS dAdded, 
                         DLD.CreatedDateUTC AS dCreated, DLD.ValidThroughDateUTC AS dThrough, DLD.Date01 AS dQualified
FROM            DBLists.dbo.DSListDetail AS DLD WITH (NOLOCK) INNER JOIN
                DBLists.dbo.DSList AS DL WITH (NOLOCK) ON DLD.PK_DSList = DL.PK_DSList INNER JOIN
                pubEvents.dbo.dimDistributor AS D WITH (NOLOCK) ON DLD.DistributorID = D.DistributorID
WHERE        (DL.PK_DSListType = 1)
