CREATE FUNCTION dbo.ufn_GetDownlineBlockedByFTEASP(@PK_Distributor BIGINT, @LevelType CHAR(2), @Level INT = 0, @StartDate DATE, @EndDate DATE)
RETURNS @Downline TABLE
(
	UpLineID BIGINT,
	DownLineID BIGINT,
	LevelType CHAR(2),
	MainLeg VARCHAR(15),
	Level INT,
	FTEASP BIT,
	ColorValueFrom VARCHAR(10),
	ColorValueTo VARCHAR(10)
)
AS
BEGIN
	WITH Root AS 
	(
		SELECT
			CAST(NULL AS BIGINT) as UpLineID,
			nDistributorID AS DownlineID,
			CAST(nDistributorID AS BIGINT) AS MainLeg,
			0 AS Level,
			CAST(0 AS BIT) AS Blocks
		FROM
			dbo.v_Distributor Upline
		WHERE
			nDistributorID = @PK_Distributor   
 
		UNION ALL

		SELECT
			CAST(UplineOf.PK_Distributor AS BIGINT) AS PK_Distributor,
			CAST(UplineOf.PK_DSDownline AS BIGINT) AS PK_DSDownline,
			CAST(
					(ISNULL(NULLIF(1%(NULLIF(Root.Level + 1,0)),0),0) * MainLeg)
					+ 
					(ISNULL(NULLIF(1%(NULLIF(Root.Level + 1,0)),1) + 1,0) * UplineOf.PK_DSDownline)
			AS BIGINT),
			Root.Level+1,
			CASE WHEN ISNULL(D.QualDate,'1900-01-01') >= @StartDate THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END Blocks
		FROM 
			Root
		INNER JOIN
			dbo.v_dimDSLngDownline UplineOf
				ON
					Root.DownlineID = UplineOf.PK_Distributor
					AND (
							(@LevelType = 'DS' AND UplineOf.DSLevelFromUL = 2)
							OR
							(@LevelType = 'SP' AND UplineOf.SPLevelFromUL = 2)
						)
		OUTER APPLY
			dbo.ufn_QualByASP(UplineOf.PK_DSDownline, '1960-01-01', @EndDate) D
		WHERE
			((Level + 1 <= @Level) OR @Level = 0) AND Blocks = 0

	  )

		INSERT INTO @Downline (UpLineID, DownLineID, LevelType, MainLeg, Level, FTEASP, ColorValueFrom, ColorValueTo)
		SELECT
			a.UpLineID,
			a.DownLineID,
			LevelType = @LevelType,
			a.MainLeg,
			a.Level,
			a.Blocks AS FTEASP,
			ISNULL(b.ColorValue,'F4B084') AS ColorValueFrom,
			ISNULL(c.ColorValue,'F4B084') AS ColorValueTo
		FROM
			Root a
		LEFT JOIN
			dbo.ColorByLevel b WITH (NOLOCK)
				ON
				(a.Level-1) = b.Level
		LEFT JOIN
			dbo.ColorByLevel c WITH (NOLOCK)
				ON
				a.Level = c.Level
		WHERE
			UpLineID IS NOT NULL
		ORDER BY Level

	RETURN
END