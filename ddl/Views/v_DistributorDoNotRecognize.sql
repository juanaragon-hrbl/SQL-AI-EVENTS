

CREATE VIEW [dbo].[v_DistributorDoNotRecognize]  
AS  
SELECT  
      DISTINCT D.PK_Distributor
	  ,DL.DistributorID  
FROM  
      DBLists.dbo.DSListDetail DL (NOLOCK)  
INNER JOIN  
      DBLists.dbo.DSList L (NOLOCK)  
ON  
      DL.PK_DSList = L.PK_DSList  
INNER JOIN
	  pubEvents.dbo.dimDistributor D (NOLOCK)
ON
	  D.DistributorID = DL.DistributorID
WHERE  
      L.DSListName = 'Do Not Recognize'  
      AND  
      GETDATE() BETWEEN DL.ValidFromDateUTC AND DL.ValidThroughDateUTC
