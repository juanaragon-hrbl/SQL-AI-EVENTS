
CREATE PROCEDURE dbo.usp_AWT_upd_DateAdded
	@AWTYear int
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_AWT_upd_DateAdded

USE:			dbo.usp_AWT_upd_DateAdded
					@AWTYear = 2009
					,@IsDevQA = 1

DESCRIPTION:	updates the dateadded column

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

DECLARE @Timestamp smalldatetime = GETUTCDATE()

/******************************************************************************
	order of precedence:
		dateAdded from dbo.AWT_ManualOverride
		dateAdded from dbo.AWT_Qualifiers
		anything else uses today's date
******************************************************************************/

/******************************************************************************
	dateAdded from dbo.AWT_ManualOverride
******************************************************************************/
UPDATE
	A
SET
	DateAdded = M.DateAdded
FROM
	dbo.AWT A
INNER JOIN
	dbo.AWT_ManualOverride M with (nolock)
	ON
		A.PK_Distributor = M.PK_Distributor
		AND A.AWTYear = M.AWTYear
WHERE
	A.AWTYear = @AWTYear

/******************************************************************************
	dateAdded from dbo.AWT_Qualifiers
******************************************************************************/
UPDATE
	A
SET
	DateAdded = M.DateAdded
FROM
	dbo.AWT A
INNER JOIN
	dbo.AWT_Qualifiers M with (nolock)
	ON
		A.PK_Distributor = M.PK_Distributor
		AND A.AWTYear = M.AWTYear
WHERE
	A.AWTYear = @AWTYear
	AND A.DateAdded IS NULL

/******************************************************************************
	dateAdded from current date
******************************************************************************/
UPDATE
	A
SET
	DateAdded = @Timestamp
FROM
	dbo.AWT A
WHERE
	A.AWTYear = @AWTYear
	AND A.DateAdded IS NULL

/******************************************************************************
	end procedure
******************************************************************************/
END