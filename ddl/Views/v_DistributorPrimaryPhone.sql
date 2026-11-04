


CREATE VIEW [dbo].[v_DistributorPrimaryPhone]
AS
SELECT
	PK_Distributor AS nDistributorIDFK
	,CASE WHEN CellPhone = 'Unknown' THEN
	      CASE WHEN DayPhone = 'Unknown' THEN EvePhone 
	      ELSE DayPhone END
	 ELSE CellPhone END AS sString
FROM
	PubEvents.dbo.dimDSContactInfo (NOLOCK)
