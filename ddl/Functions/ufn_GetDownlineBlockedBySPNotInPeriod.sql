
CREATE FUNCTION [dbo].[ufn_GetDownlineBlockedBySPNotInPeriod](@PK_Distributor BIGINT, @LevelType CHAR(2), @Level INT = 0, @SPQualStartDate DATE, @SPQualEndDate DATE)
RETURNS @Downline TABLE
(
	UpLineID BIGINT,
	DownLineID BIGINT,
	LevelType CHAR(2),
	MainLeg VARCHAR(15),
	Level INT,
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
			0 AS Blocks
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
			CASE WHEN (D.sType = 'SP' AND NOT(D.dSupervisorQualification BETWEEN @SPQualStartDate AND @SPQualEndDate)) THEN 1 ELSE 0 END Blocks
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
			INNER JOIN dbo.v_Distributor D
				ON UplineOf.PK_DSDownline = D.nDistributorID
		WHERE
			((Level + 1 <= @Level) OR @Level = 0) AND Blocks = 0

	  )

		INSERT INTO @Downline (UpLineID, DownLineID, LevelType, MainLeg, Level, ColorValueFrom, ColorValueTo)
		SELECT
			a.UpLineID,
			a.DownLineID,
			LevelType = @LevelType,
			a.MainLeg,
			a.Level,
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
GO
