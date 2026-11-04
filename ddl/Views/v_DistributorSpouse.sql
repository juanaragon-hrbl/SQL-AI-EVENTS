
CREATE VIEW [dbo].[v_DistributorSpouse]
AS
SELECT
	PK_Distributor AS nDistributorSpouseID
	,PK_Distributor AS nDistributorID
	,DistributorID AS sDistributorID
	,SpouseFirstName AS sSpouseFirstName
	,SpouseLastName AS sSpouseLastName
FROM
	PubEvents.dbo.dimDistributor (NOLOCK)
WHERE 
	(COALESCE(SpouseFirstName, NULL) <> '' OR COALESCE(SpouseLastName, NULL) <> '')