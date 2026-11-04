
CREATE PROCEDURE dbo.usp_AWT_ins_Accelerators
	@AWTYear int
	,@IsDevQA int = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_AWT_ins_Accelerators

USE:			dbo.usp_AWT_ins_Accelerators
					@AWTYear = 2009

DESCRIPTION:	updates accelerator information in AWT_Metrics


DEPENDENCIES
--------------------------------------------------------------------
everything

VERSIONS
--------------------------------------------------------------------
1	2010-01-05	Scott	Initial
2   2019-10-17  SushmaA	SRE updates for NOLOCK, NOCOUNT, SELECT *

******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	PK_AWT_AcceleratorType
	1	5-Get-5
	2	Double Volume 10K
	3	Double Volume 5K New SP
	4	Double Volume 10K New SP
******************************************************************************/

/******************************************************************************
	1	5-Get-5
	If an SP earns 5K TV then a 5k accelerator bonus is added to TV
	for the months defined in dbo.AWT_Accelerator
******************************************************************************/
UPDATE
	M
SET
	TV_Accelerator = M.TV_Accelerator + 5000
FROM
	dbo.AWT_Metrics M
INNER JOIN
	dbo.AWT_Accelerator A with (nolock)
	ON
		A.AWTYear = @AWTYear
		AND A.PK_AWT_AcceleratorType = 1
		AND M.Royaltymonth = A.RoyaltyMonth
		AND M.COP = A.COP
WHERE
	M.TV >= 5000

/******************************************************************************
	2	Double Volume 10K
	An SPs TV up to 10K is doubled for the months defined in AWT_Accelerator
******************************************************************************/
UPDATE
	M
SET
	TV_Accelerator = 
		M.TV_Accelerator + CASE 
								WHEN M.TV <= 0 THEN 0
								WHEN M.TV < 10000 THEN M.TV 
								ELSE 10000 END
FROM
	dbo.AWT_Metrics M
INNER JOIN
	dbo.AWT_Accelerator A with (nolock)
	ON
		A.AWTYear = @AWTYear
		AND A.PK_AWT_AcceleratorType = 2
		AND M.Royaltymonth = A.RoyaltyMonth
		AND M.COP = A.COP

/******************************************************************************
	3	Double Volume 5K New SP
	An SPs TV up to 5K is doubled for the months defined in AWT_Accelerator
	and Qual_SP is the same as the month in AWT_Accelerator
******************************************************************************/
UPDATE
	M
SET
	TV_Accelerator = 
		M.TV_Accelerator + CASE 
								WHEN M.TV <= 0 THEN 0
								WHEN M.TV < 5000 THEN M.TV
								ELSE 5000 END
FROM
	dbo.AWT_Metrics M
INNER JOIN
	dbo.AWT_Accelerator A with (nolock)
	ON
		A.AWTYear = @AWTYear
		AND A.PK_AWT_AcceleratorType = 3
		AND M.Royaltymonth = A.RoyaltyMonth
		AND M.COP = A.COP
WHERE
	M.Qual_SP = M.RoyaltyMonth

/******************************************************************************
	4	Double Volume 10K New SP
	An SPs TV up to 10K is doubled for the months defined in AWT_Accelerator
	and Qual_SP is the same as the month in AWT_Accelerator
******************************************************************************/
UPDATE
	M
SET
	TV_Accelerator = 
		M.TV_Accelerator + CASE 
								WHEN M.TV <= 0 THEN 0
								WHEN M.TV < 10000 THEN M.TV
								ELSE 10000 END
FROM
	dbo.AWT_Metrics M
INNER JOIN
	dbo.AWT_Accelerator A with (nolock)
	ON
		A.AWTYear = @AWTYear
		AND A.PK_AWT_AcceleratorType = 4
		AND M.Royaltymonth = A.RoyaltyMonth
		AND M.COP = A.COP
WHERE
	M.Qual_SP = M.RoyaltyMonth

/******************************************************************************
	end procedure
******************************************************************************/
END