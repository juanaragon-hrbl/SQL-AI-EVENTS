CREATE VIEW [dbo].[v_DistributorEmail]
AS
SELECT
	PK_Distributor AS nDistributorIDFK
	,CASE WHEN LEN(COALESCE(PrimaryEmail,'Unknown')) = 0 THEN 'Unknown' ELSE COALESCE(PrimaryEmail,'Unknown') END AS sString
FROM
	pubEVENTS.dbo.dimDSContactInfo (NOLOCK)