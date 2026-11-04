
CREATE VIEW [dbo].[v_DistributorTestIDs]
AS
SELECT
	DISTINCT DD.PK_Distributor 
FROM
	DBLists.dbo.DSList DL (NOLOCK)
INNER JOIN
	DBLists.dbo.DSListDetail DD (NOLOCK)
ON
	DL.PK_DSList = DD.PK_DSList
WHERE
	DL.DSListName = 'Test IDs'
	AND
	GETDATE() BETWEEN DL.ValidFromDateUTC AND DL.ValidThroughDateUTC