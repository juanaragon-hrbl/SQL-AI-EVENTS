
CREATE VIEW dbo.v_ASQQualification 
AS
	SELECT
		PK_Distributor
		,DistributorID
		,Qual_SP
		,[3] 'Qual_3Pin'
		,[5] 'Qual_5Pin'
		,[10] 'Qual_10Pin'
	FROM
	(
		SELECT
			PK_Distributor
			,DistributorID
			,Qual_SP
			,PinType
			,Qual_Pin
		FROM
			dbo.ASQQualification
	)P1 PIVOT (
		MIN(Qual_Pin)
		FOR  PinType
			IN ([3],[5],[10])
	)P2