CREATE PROCEDURE [dbo].[usp_StonePromo_UpdateSubEventQualifier]
	 @PK_InEvent INT
	 ,@TabName varchar(200)
	 ,@IsDevQA bit = 0	-- optional
AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_StonePromo_UpdateSubEventQualifier

USE:		EXEC dbo.usp_StonePromo_UpdateSubEventQualifier

DESCRIPTION:    Write Star Promotion Qualifiers to SubEventQualifier table in IA for Event ID given.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2012-03-12  OrlandoL  	Initial

******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/******************************************************************************
	VARIABLE DECLARETION
******************************************************************************/
DECLARE @PK_SubEvent1 INT
		,@PK_SubEvent2 INT
		,@PK_SubEvent3 INT
		,@PK_SubEvent4 INT
		,@PK_SubEvent5 INT
		,@PK_SubEvent6 INT
		,@PK_SubEvent7 INT
		,@PK_SubEvent8 INT
		,@PK_SubEvent9 INT
		,@PK_SubEvent10 INT
		,@PK_SubEvent11 INT
		,@PK_SubEvent12 INT
		,@PK_SubEvent13 INT
		,@PK_SubEvent14 INT
		,@PK_SubEvent15 INT
		,@PK_SubEvent16 INT
		,@PK_SubEvent17 INT
		,@PK_SubEvent18 INT
		,@PK_SubEvent19 INT
		,@PK_SubEvent20 INT
		,@PK_SubEvent21 INT
		,@SQLStatement nVarchar(1000)


/******************************************************************************
	SELECT PK_SubEvent for each subevent 
******************************************************************************/
SELECT @PK_SubEvent1 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 1
SELECT @PK_SubEvent2 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 2
SELECT @PK_SubEvent3 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 3
SELECT @PK_SubEvent4 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 4
SELECT @PK_SubEvent5 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 5
SELECT @PK_SubEvent6 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 6
SELECT @PK_SubEvent7 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 7
SELECT @PK_SubEvent8 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 8
SELECT @PK_SubEvent9 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 9
SELECT @PK_SubEvent10 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 10
SELECT @PK_SubEvent11 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 11
SELECT @PK_SubEvent12 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 12
SELECT @PK_SubEvent13 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 13
SELECT @PK_SubEvent14 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 14
SELECT @PK_SubEvent15 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 15
SELECT @PK_SubEvent16 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 16
SELECT @PK_SubEvent17 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 17
SELECT @PK_SubEvent18 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 18
SELECT @PK_SubEvent19 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 19
SELECT @PK_SubEvent20 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 20
SELECT @PK_SubEvent21 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 21


--IF OBJECT_ID('WRK_StonePromo','U') IS NOT NULL DROP TABLE dbo.WRK_StonePromo

SET @SQLStatement = 'SELECT * INTO dbo.WRK_StonePromo FROM dbo.'+@TabName

IF OBJECT_ID('WRK_StonePromo','U') IS NOT NULL DROP TABLE dbo.WRK_StonePromo

EXEC sp_executesql @SQLStatement

CREATE INDEX IX_WRK_StonePromo_PK_Distributor ON dbo.WRK_StonePromo(PK_Distributor)

/**********************************************************************************************
UPDATE THE RECORDS IN THE SUBEVENT QUALIFIERS IF THE RECORDS DOES NOT EXIST IN THE TEMP TABLE
***********************************************************************************************/
IF @PK_SubEvent1 IS NOT NULL 
BEGIN
	/* Star 1 */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ  WITH (NOLOCK)
	LEFT JOIN
		dbo.WRK_StonePromo T WITH (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND SQ.PK_Event = @PK_InEvent 
		AND SQ.PK_SubEvent = @PK_SubEvent1
		AND T.IsASP = 1
	LEFT JOIN
		dbo.EventsRegistration ER  WITH (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent 
	AND
		SQ.PK_SubEvent = @PK_SubEvent1
END

IF @PK_SubEvent2 IS NOT NULL 
BEGIN
	/* Star 2 */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ  WITH (NOLOCK)
	LEFT JOIN
		dbo.WRK_StonePromo T WITH (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent2
		AND T.IsStone1 = 1
	LEFT JOIN
		dbo.EventsRegistration ER  WITH (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent2
END

IF @PK_SubEvent3 IS NOT NULL 
BEGIN
	/* Star 3 */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ  WITH (NOLOCK)
	LEFT JOIN
		dbo.WRK_StonePromo T WITH (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent3
		AND CASE WHEN @PK_InEvent = 66565 THEN T.IsStone2 ELSE T.IsStone3 END  = 1
	LEFT JOIN
		dbo.EventsRegistration ER  WITH (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent3
END

IF @PK_SubEvent4 IS NOT NULL 
BEGIN
	/* Star 4 */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ  WITH (NOLOCK)
	LEFT JOIN
		dbo.WRK_StonePromo T WITH (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent4
		AND CASE WHEN @PK_InEvent = 66565 THEN T.IsStone3 ELSE T.IsStone5 END  = 1
	LEFT JOIN
		dbo.EventsRegistration ER  WITH (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent4
END

IF @PK_SubEvent5 IS NOT NULL 
BEGIN
	/* Star 5 */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ  WITH (NOLOCK)
	LEFT JOIN
		dbo.WRK_StonePromo T WITH (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent5
		AND CASE WHEN @PK_InEvent = 66565 THEN T.IsStone4 ELSE T.IsStone7 END  = 1
	LEFT JOIN
		dbo.EventsRegistration ER  WITH (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent5
END

IF @PK_SubEvent6 IS NOT NULL 
BEGIN
	/* Star 6 */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ  WITH (NOLOCK)
	LEFT JOIN
		dbo.WRK_StonePromo T WITH (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent6
		AND CASE WHEN @PK_InEvent = 66565 THEN T.IsStone5 ELSE T.IsStone10 END  = 1
	LEFT JOIN
		dbo.EventsRegistration ER  WITH (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent6
END

IF @PK_SubEvent7 IS NOT NULL 
BEGIN
	/* Star 7 */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ  WITH (NOLOCK)
	LEFT JOIN
		dbo.WRK_StonePromo T WITH (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent7
		AND T.IsStone6 = 1
	LEFT JOIN
		dbo.EventsRegistration ER  WITH (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent7
END

IF @PK_SubEvent8 IS NOT NULL 
BEGIN
	/* Star 8 */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ  WITH (NOLOCK)
	LEFT JOIN
		dbo.WRK_StonePromo T WITH (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent8
		AND T.IsStone7 = 1
	LEFT JOIN
		dbo.EventsRegistration ER  WITH (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent8
END

IF @PK_SubEvent9 IS NOT NULL 
BEGIN
	/* Star 9 */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ  WITH (NOLOCK)
	LEFT JOIN
		dbo.WRK_StonePromo T WITH (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent9
		AND T.IsStone8 = 1
	LEFT JOIN
		dbo.EventsRegistration ER  WITH (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent9
END

IF @PK_SubEvent10 IS NOT NULL 
BEGIN
	/* Star 10 */
	UPDATE
		SQ
	SET
		 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
		,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
		,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
	FROM
		dbo.SubEventQualifier SQ  WITH (NOLOCK)
	LEFT JOIN
		dbo.WRK_StonePromo T WITH (NOLOCK) 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent10
		AND T.IsStone9 = 1
	LEFT JOIN
		dbo.EventsRegistration ER  WITH (NOLOCK)
	ON
		ER.PK_Event = @PK_InEvent 
		AND
		ER.PK_Distributor = T.PK_Distributor
	WHERE
		SQ.PK_Event = @PK_InEvent
	AND
		SQ.PK_SubEvent = @PK_SubEvent10
END

IF @PK_SubEvent11 IS NOT NULL 
BEGIN
/* Star 11 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ  WITH (NOLOCK)
LEFT JOIN
	dbo.WRK_StonePromo T WITH (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent11
	AND T.IsStone10 = 1
LEFT JOIN
	dbo.EventsRegistration ER  WITH (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent11
END


IF @PK_SubEvent12 IS NOT NULL 
BEGIN
/* Star 11 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ  WITH (NOLOCK)
LEFT JOIN
	dbo.WRK_StonePromo T WITH (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent12
	AND T.IsStone11 = 1
LEFT JOIN
	dbo.EventsRegistration ER  WITH (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent12
END

IF @PK_SubEvent13 IS NOT NULL 
BEGIN
/* Star 11 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ  WITH (NOLOCK)
LEFT JOIN
	dbo.WRK_StonePromo T WITH (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent13
	AND T.IsStone12 = 1
LEFT JOIN
	dbo.EventsRegistration ER  WITH (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent13
END

IF @PK_SubEvent14 IS NOT NULL 
BEGIN
/* Star 11 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ  WITH (NOLOCK)
LEFT JOIN
	dbo.WRK_StonePromo T WITH (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent14
	AND T.IsStone13 = 1
LEFT JOIN
	dbo.EventsRegistration ER  WITH (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent14
END

IF @PK_SubEvent15 IS NOT NULL 
BEGIN
/* Star 11 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ  WITH (NOLOCK)
LEFT JOIN
	dbo.WRK_StonePromo T WITH (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent15
	AND T.IsStone14 = 1
LEFT JOIN
	dbo.EventsRegistration ER  WITH (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent15
END

IF @PK_SubEvent16 IS NOT NULL 
BEGIN
/* Star 11 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ  WITH (NOLOCK)
LEFT JOIN
	dbo.WRK_StonePromo T WITH (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent16
	AND T.IsStone15 = 1
LEFT JOIN
	dbo.EventsRegistration ER  WITH (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent16
END

IF @PK_SubEvent17 IS NOT NULL 
BEGIN
/* Star 11 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ  WITH (NOLOCK)
LEFT JOIN
	dbo.WRK_StonePromo T WITH (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent17
	AND T.IsStone16 = 1
LEFT JOIN
	dbo.EventsRegistration ER  WITH (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent17
END

IF @PK_SubEvent18 IS NOT NULL 
BEGIN
/* Star 11 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ  WITH (NOLOCK)
LEFT JOIN
	dbo.WRK_StonePromo T WITH (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent18
	AND T.IsStone17 = 1
LEFT JOIN
	dbo.EventsRegistration ER  WITH (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent18
END

IF @PK_SubEvent19 IS NOT NULL 
BEGIN
/* Star 11 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ  WITH (NOLOCK)
LEFT JOIN
	dbo.WRK_StonePromo T WITH (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent19
	AND T.IsStone18 = 1
LEFT JOIN
	dbo.EventsRegistration ER  WITH (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent19
END

IF @PK_SubEvent20 IS NOT NULL 
BEGIN
/* Star 11 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ  WITH (NOLOCK)
LEFT JOIN
	dbo.WRK_StonePromo T WITH (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent20
	AND T.IsStone19 = 1
LEFT JOIN
	dbo.EventsRegistration ER  WITH (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent20
END

IF @PK_SubEvent21 IS NOT NULL 
BEGIN
/* Star 21 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ  WITH (NOLOCK)
LEFT JOIN
	dbo.WRK_StonePromo T WITH (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent21
	AND T.IsStone20 = 1
LEFT JOIN
	dbo.EventsRegistration ER  WITH (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent21
END


/**********************************************************************************************
	INSERT THE NEW QUALIFIERS THAT ARE NOT ALREADY IN THE SUBEVENT QUALIFIER TABLE 
***********************************************************************************************/
IF @PK_SubEvent1 IS NOT NULL 
BEGIN
	/*Star 1*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent1
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent1 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsASP = 1
		AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent2 IS NOT NULL 
BEGIN
	/*Star 2*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent2
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent2 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone1 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent3 IS NOT NULL 
BEGIN
	/*Star 3*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent3
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent3 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		CASE WHEN @PK_InEvent = 66565 THEN T.IsStone2 ELSE T.IsStone3 END = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent4 IS NOT NULL 
BEGIN
	/*Star 4*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent4
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent4 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		CASE WHEN @PK_InEvent = 66565 THEN T.IsStone3 ELSE T.IsStone5 END = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent5 IS NOT NULL 
BEGIN
	/*Star 5*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent5
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent5 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		CASE WHEN @PK_InEvent = 66565 THEN T.IsStone4 ELSE T.IsStone7 END = 1
	AND
		SQ1.PK_Distributor IS NULL
END
	
IF @PK_SubEvent6 IS NOT NULL 
BEGIN
	/*Star 6*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent6
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent6 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		CASE WHEN @PK_InEvent = 66565 THEN T.IsStone5 ELSE T.IsStone10 END = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent7 IS NOT NULL 
BEGIN
	/*Star 7*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent7
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent7 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone6 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent8 IS NOT NULL 
BEGIN
	/*Star 8*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent8
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent8 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone7 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent9 IS NOT NULL 
BEGIN
	/*Star 9*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent9
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent9 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone8 = 1
	AND
		SQ1.PK_Distributor IS NULL
END	

IF @PK_SubEvent10 IS NOT NULL 
BEGIN
	/*Star 10*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent10
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent10 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone9 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent11 IS NOT NULL 
BEGIN
	/*Star 11*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent11
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent11 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone10 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent12 IS NOT NULL 
BEGIN
	/*Star 11*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent12
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent12 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone11 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent13 IS NOT NULL 
BEGIN
	/*Star 11*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent13
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent13 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone12 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent14 IS NOT NULL 
BEGIN
	/*Star 11*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent14
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent14 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone13 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent15 IS NOT NULL 
BEGIN
	/*Star 11*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent15
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent15 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone14 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent16 IS NOT NULL 
BEGIN
	/*Star 11*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent16
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent16 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone15 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent17 IS NOT NULL 
BEGIN
	/*Star 11*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent17
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent17 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone16 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent18 IS NOT NULL 
BEGIN
	/*Star 11*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent18
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent18 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone17 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent19 IS NOT NULL 
BEGIN
	/*Star 11*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent19
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent19 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone18 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent20 IS NOT NULL 
BEGIN
	/*Star 11*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent20
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent20 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone19 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent21 IS NOT NULL 
BEGIN
	/*Star 21*/
	INSERT
		dbo.SubEventQualifier
	(
		CreatedDateUTC
		,CreatedBy
		,ModifiedDateUTC
		,ModifiedBy
		,PK_Event
		,PK_SubEvent
		,PK_Distributor
		,DistributorID
		,QualDate
		,AddedUTC
		,RemovedUTC
		,IsManualOverride
		,IsDeleted
		,IsDNR
		,IsType23
		,Qualified
		,Quantity
	)
	SELECT DISTINCT
		GETUTCDATE()
		,'UsrSQLProd'
		,GETUTCDATE()
		,'UsrSQLProd'
		,@PK_InEvent
		,@PK_SubEvent21
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,'2049-12-31'
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StonePromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK) 
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent21 
		 AND SQ1.RemovedUTC = '2049-12-31' 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStone20 = 1
	AND
		SQ1.PK_Distributor IS NULL
END


/******************************************************************************
	UPDATE EVENT QUALIFIER
******************************************************************************/	
EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = @PK_InEvent

/******************************************************************************
	END PROCEDURE
******************************************************************************/	
END
GO

