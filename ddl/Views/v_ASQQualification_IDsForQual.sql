CREATE VIEW dbo.v_ASQQualification_IDsForQual 
AS

SELECT
	A.PK_Distributor
	,A.DistributorID
	,A.Qual_SP
	,A.PinType
	,A.Qual_Pin
	,ID.PK_Distributor 'PK_DistributorUsedForQual'
	,ID.DistributorID 'DistributorUsedForQualID'
FROM
	dbo.ASQQualification A
LEFT JOIN
	dbo.ASQQualification_IDsForQual ID
	ON
		A.DistributorID = ID.FirstUplineSPID
		AND A.Qual_Pin = ID.Qual_Pin
WHERE
	A.PinType > 3