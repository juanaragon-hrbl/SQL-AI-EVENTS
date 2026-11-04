CREATE VIEW [dbo].[v_DistributorLifeTimePartner]
AS
SELECT
	PK_Distributor AS nLPID
	,PK_Distributor AS nDistributorID
	,DistributorID AS sDistributorID
	,LP_First_Name AS sLPFirstName
	,LP_Last_Name AS sLPLastName
FROM
	PubEvents.dbo.dimDistributor WITH (NOLOCK)
WHERE 
	LEN(LP_First_Name) > 0 OR LEN(LP_Last_Name) > 0