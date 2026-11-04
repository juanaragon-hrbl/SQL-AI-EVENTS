CREATE FUNCTION dbo.ufn_GetFQSNoTeam(
@Date DATETIME
)
RETURNS @FQSNoTeam TABLE 
(
	PK_Distributor INT PRIMARY KEY,
	DistributorID VARCHAR(20),
	NoTeamDate DATETIME
)

AS
BEGIN

	INSERT INTO @FQSNoTeam
	SELECT 
	v.nDistributorIDFK AS PK_Distributor,
	v.sDistributorID AS DistributorID,
	@Date AS NoTeamDate

	FROM
		v_distributorhistory V (NOLOCK) 
	INNER JOIN 
		pubEvents.dbo.dimdslifecycle D WITH (NOLOCK)
	ON 
		d.lifecyclecode = v.nEventTypeLID
	WHERE
		d.Lifecyclename='Qual Supervisor'
		AND
		@Date BETWEEN v.dfrom and v.dThrough
		AND
			v.dThrough = '2049-12-31'
		AND NOT EXISTS
		(	SELECT 1 
			FROM
				dbo.v_distributorhistory h
			WHERE
				nEventTypeLID BETWEEN 224 AND 242
			AND
				dFrom <= @Date
			AND
				dThrough = '2049-12-31'
			AND
				v.nDistributorIDFK = h.nDistributorIDFK
		)
	GROUP BY v.nDistributorIDFK, v.sDistributorID
RETURN
END