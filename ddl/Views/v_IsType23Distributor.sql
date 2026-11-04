
CREATE VIEW [dbo].[v_IsType23Distributor] AS
WITH 
       Type23Main (nMainDistributorID) AS
       (
              SELECT
                     nMainDistributorID
              FROM
                     dbo.v_DistributorAssociate2 A (NOLOCK)
              WHERE
                     dThrough = '2049-12-31'
                     AND Transfer = 0
              GROUP BY
                     nMainDistributorID
              HAVING 
                     COUNT(*) < 3
       ),
       Type23Associate (nDistributorID) AS
       (
              SELECT
                     DISTINCT nDistributorID
              FROM
                     dbo.v_DistributorAssociate2 A (NOLOCK)
              INNER JOIN
                     Type23Main M
                     ON
                           A.nMainDistributorID = M.nMainDistributorID
              WHERE
                     dThrough = '2049-12-31'
                     AND Transfer = 0     
       )

SELECT 
       DISTINCT A.nDistributorID 
FROM 
       dbo.v_DistributorAssociate2 A 
WHERE 
       NOT EXISTS (SELECT * FROM Type23Associate B WHERE B.nDistributorID = A.nDistributorID)
       AND A.dThrough = '2049-12-31'
       AND A.Transfer = 0
