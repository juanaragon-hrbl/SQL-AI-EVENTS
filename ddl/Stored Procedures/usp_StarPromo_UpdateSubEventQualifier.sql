
CREATE PROCEDURE [dbo].[usp_StarPromo_UpdateSubEventQualifier]
	 @PK_InEvent INT
	 ,@TabName varchar(200)
--optional
       ,@IsDevQA		BIT = 0   
	   ,@Error	int = 0 OUTPUT
	   ,@ErrorMessage varchar(4000) = NULL OUTPUT


AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_StarPromo_UpdateSubEventQualifier

USE:		EXEC dbo.usp_StarPromo_UpdateSubEventQualifier 3375, 'WRK_HerbalifeHonorsMar2017'

DESCRIPTION:    Write Star Promotion Qualifiers to SubEventQualifier table in IA for Event ID given.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2012-03-12  OrlandoL  	Initial
2	2016-06-08  SushmaA  	2 new subevents added
3	2019-10-16	 JonathanO		Refactor code (SRE)

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
		,@SQLStatement nVarchar(1000)

		,@ValidDate DATETIME = '2049-12-31'
		,@UsrSQLProd VARCHAR(15) = 'UsrSQLProd'

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

			BEGIN TRY
/******************************************************************************
	SELECT PK_SubEvent for each subevent 
******************************************************************************/
SELECT @PK_SubEvent1 = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 1
SELECT @PK_SubEvent2 = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 2
SELECT @PK_SubEvent3 = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 3
SELECT @PK_SubEvent4 = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 4
SELECT @PK_SubEvent5 = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 5
SELECT @PK_SubEvent6 = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 6
SELECT @PK_SubEvent7 = PK_SubEvent FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 7

IF @PK_InEvent != 2462
BEGIN
	SELECT @PK_SubEvent8 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 8
	SELECT @PK_SubEvent9 = PK_SubEvent FROM dbo.SubEvent  WITH (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 9
	SELECT @PK_SubEvent10 = PK_SubEvent FROM dbo.SubEvent WITH  (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 10
	SELECT @PK_SubEvent11 = PK_SubEvent FROM dbo.SubEvent WITH  (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 11
	SELECT @PK_SubEvent12 = PK_SubEvent FROM dbo.SubEvent WITH  (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 12
	SELECT @PK_SubEvent13 = PK_SubEvent FROM dbo.SubEvent WITH  (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 13
END

IF OBJECT_ID('WRK_StarPromo','U') IS NOT NULL DROP TABLE dbo.WRK_StarPromo

SET @SQLStatement = 'SELECT * INTO dbo.WRK_StarPromo FROM dbo.'+@TabName

--IF OBJECT_ID('WRK_StarPromo','U') IS NOT NULL DROP TABLE dbo.WRK_StarPromo

EXEC sp_executesql @SQLStatement

CREATE INDEX IX_WRK_StarPromo_PK_Distributor ON dbo.WRK_StarPromo(PK_Distributor)

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
		dbo.SubEventQualifier SQ
	LEFT JOIN
		dbo.WRK_StarPromo T
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND SQ.PK_Event = @PK_InEvent 
		AND SQ.PK_SubEvent = @PK_SubEvent1
		AND T.IsStar1 = 1
	LEFT JOIN
		dbo.EventsRegistration ER
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
		dbo.SubEventQualifier SQ
	LEFT JOIN
		dbo.WRK_StarPromo T
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent2
		AND T.IsStar2 = 1
	LEFT JOIN
		dbo.EventsRegistration ER
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
		dbo.SubEventQualifier SQ
	LEFT JOIN
		dbo.WRK_StarPromo T
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent3
		AND T.IsStar3 = 1
	LEFT JOIN
		dbo.EventsRegistration ER
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
		dbo.SubEventQualifier SQ 
	LEFT JOIN
		dbo.WRK_StarPromo T 
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent4
		AND T.IsStar4 = 1
	LEFT JOIN
		dbo.EventsRegistration ER
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
		dbo.SubEventQualifier SQ
	LEFT JOIN
		dbo.WRK_StarPromo T
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent5
		AND T.IsStar5 = 1
	LEFT JOIN
		dbo.EventsRegistration ER
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
		dbo.SubEventQualifier SQ
	LEFT JOIN
		dbo.WRK_StarPromo T
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent6
		AND T.IsStar6 = 1
	LEFT JOIN
		dbo.EventsRegistration ER
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
		dbo.SubEventQualifier SQ
	LEFT JOIN
		dbo.WRK_StarPromo T
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent7
		AND T.IsStar7 = 1
	LEFT JOIN
		dbo.EventsRegistration ER
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
		dbo.SubEventQualifier SQ
	LEFT JOIN
		dbo.WRK_StarPromo T
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent8
		AND T.IsStar8 = 1
	LEFT JOIN
		dbo.EventsRegistration ER
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
		dbo.SubEventQualifier SQ
	LEFT JOIN
		dbo.WRK_StarPromo T
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent9
		AND T.IsStar9 = 1
	LEFT JOIN
		dbo.EventsRegistration ER
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
		dbo.SubEventQualifier SQ
	LEFT JOIN
		dbo.WRK_StarPromo T
	ON
		T.PK_Distributor = SQ.PK_Distributor 
		AND PK_Event = @PK_InEvent 
		AND PK_SubEvent = @PK_SubEvent10
		AND T.IsStar10 = 1
	LEFT JOIN
		dbo.EventsRegistration ER
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
	dbo.SubEventQualifier SQ
LEFT JOIN
	dbo.WRK_StarPromo T
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent10
	AND T.IsStar11 = 1
LEFT JOIN
	dbo.EventsRegistration ER
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
/* Star 12 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ
LEFT JOIN
	dbo.WRK_StarPromo T
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent12
	AND T.IsStar12 = 1
LEFT JOIN
	dbo.EventsRegistration ER
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
/* Star 13 */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ
LEFT JOIN
	dbo.WRK_StarPromo T
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent13
	AND T.IsStar13 = 1
LEFT JOIN
	dbo.EventsRegistration ER
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent13
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent1
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1 WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent1 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar1 = 1
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent2
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent2 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar2 = 1
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent3
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent3 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar3 = 1
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent4
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1 WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent4 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar4 = 1
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent5
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent5 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar5 = 1
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent6
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1 WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent6 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar6 = 1
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent7
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent7 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar7 = 1
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent8
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent8 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar8 = 1
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent9
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent9 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar9 = 1
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent10
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent10 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar10 = 1
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent11
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent11 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar11 = 1
	AND
		SQ1.PK_Distributor IS NULL
END


IF @PK_SubEvent12 IS NOT NULL 
BEGIN
	/*Star 12*/
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent12
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent12 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar12 = 1
	AND
		SQ1.PK_Distributor IS NULL
END

IF @PK_SubEvent13 IS NOT NULL 
BEGIN
	/*Star 13*/
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
		,@UsrSQLProd
		,GETUTCDATE()
		,@UsrSQLProd
		,@PK_InEvent
		,@PK_SubEvent13
		,T.PK_Distributor
		,DS.sDistributorID
		,GETUTCDATE()
		,GETUTCDATE()
		,@ValidDate
		,0
		,0
		,0
		,0
		,1
		,NULL
	FROM
		dbo.WRK_StarPromo T WITH (NOLOCK)
	INNER JOIN
		dbo.v_Distributor DS
	ON
		T.PK_Distributor = DS.nDistributorID
	LEFT JOIN
		 dbo.SubEventQualifier SQ1  WITH (NOLOCK)
	ON
		 SQ1.PK_Event = @PK_InEvent 
		 AND SQ1.PK_SubEvent = @PK_SubEvent13 
		 AND SQ1.RemovedUTC = @ValidDate 
		 AND T.PK_Distributor = SQ1.PK_Distributor
	WHERE
		T.IsStar13 = 1
	AND
		SQ1.PK_Distributor IS NULL
END


/******************************************************************************
	UPDATE EVENT QUALIFIER
******************************************************************************/	
EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = @PK_InEvent

IF OBJECT_ID('WRK_StarPromo','U') IS NOT NULL DROP TABLE dbo.WRK_StarPromo


		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;
	
	

END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;