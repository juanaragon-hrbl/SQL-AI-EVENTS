
CREATE VIEW [dbo].[v_AWT_Qualifiers_Using_5Get5] AS

WITH cte_AWT AS 
(
      SELECT
			AWTYear,
            PK_Distributor,
            MIN(RoyaltyMonth) AS Qual_AWT
      FROM
            dbo.AWT_Metrics (NOLOCK)
      WHERE
            didAWT = 1
      GROUP BY
			AWTYear,
            PK_Distributor
),
cte_AWT_Did10K AS
(
      SELECT 
			A.AWTYear,
            A.PK_Distributor,
            A.Qual_AWT,
            MIN(RoyaltyMonth) AS First10KTV
      FROM
            cte_AWT A (NOLOCK)
      JOIN
            dbo.AWT_Metrics M (NOLOCK)
            ON
				  A.AWTYear = M.AWTYear 
				  AND
                  A.PK_Distributor = M.PK_Distributor
                  AND
                  M.RoyaltyMonth BETWEEN DATEADD(MM,-5,A.Qual_AWT) AND A.Qual_AWT
      WHERE
            did10KTV = 1
      GROUP BY 
			A.AWTYear,
            A.PK_Distributor,
            A.Qual_AWT
)

SELECT
	  A.AWTYear,
      A.PK_Distributor,
      A.Qual_AWT,
      A.First10KTV AS [5Get5Month]
FROM 
      cte_AWT_Did10K A
JOIN
      dbo.AWT_Metrics M (NOLOCK)
      ON
			A.AWTYear = M.AWTYear 
			AND
            A.PK_Distributor = M.PK_Distributor
            AND
            A.First10KTV = M.RoyaltyMonth
WHERE
      M.TV_Accelerator = 5000
      AND 
      M.TV < 10000