CREATE PROCEDURE [dbo].[usp_SubEventQualEngine_ProcessFormula]
	@SubEventID int
	,@IsDevQA bit = 0
AS
BEGIN

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE
	@SubEventFormula varchar(4000)
	,@Counter int
	,@c char(2)
	,@MaxRows int
	,@MaxNestLvl int
	,@MinPK int
	,@MaxPK int
	,@CurrentNest int
	,@ProcName varchar(100)
	,@ProcParam varchar(100)
	,@StartTime datetime
	,@EventID int

SET @ProcName = 'uspSubEventQualEngine_ProcessFormula'
SET @ProcParam = CONVERT(varchar,@SubEventID)
SET @StartTime = GETUTCDATE()

/******************************************************************************
	get the subevent formula
******************************************************************************/
DECLARE @SubEventFormulaTable TABLE (
		PK int IDENTITY(1,1)
		,Value varchar(3)
		,NestLevel int DEFAULT 1
		,IndentLevel int DEFAULT 0
	)

SELECT 
	@SubEventFormula = SubEventFormula
FROM
	dbo.SubEvent WITH (NOLOCK)
WHERE
	PK_SubEvent = @SubeventID

SET @SubEventFormula = '(' + @SubEventFormula + ')'

SET @SubEventFormula = REPLACE(@SubEventFormula,'AND','A')
SET @SubEventFormula = REPLACE(@SubEventFormula,'+','A')
SET @SubEventFormula = REPLACE(@SubEventFormula,'OR','O')

/******************************************************************************
	set up formula table
******************************************************************************/
SET @Counter = 1
WHILE @Counter <= LEN(@SubEventFormula)
BEGIN
	SET @c = SUBSTRING(@SubEventFormula,@Counter,2) 

	/* if the value isn't [()AO],[0-9],[0-9][0-9] it's ignored */
	IF @c LIKE '[0-9][0-9]'
	BEGIN
		INSERT @SubEventFormulaTable (Value) VALUES (@c)
		SET @Counter = @Counter + 2

	END ELSE BEGIN

		IF LEFT(@c,1) IN ('(',')','O','A') OR LEFT(@c,1) LIKE '[0-9]'
			INSERT @SubEventFormulaTable (Value) VALUES (LEFT(@c,1))

		SET @Counter = @Counter + 1
	END
END

/******************************************************************************
	set nest level
******************************************************************************/
SELECT @MaxRows = COUNT(*) FROM @SubEventFormulaTable
SELECT @MaxNestLvl = COUNT(*) FROM @SubEventFormulaTable WHERE Value = '('

DECLARE @NestStartTable TABLE (PK int, NestLevel int IDENTITY(1,1))

INSERT @NestStartTable (PK)
SELECT PK FROM @SubEventFormulaTable WHERE Value = '('

UPDATE S
SET NestLevel = N.NestLevel
FROM @SubEventFormulaTable S
INNER JOIN @NestStartTable N ON S.PK = N.PK

SET @CurrentNest = @MaxNestLvl

WHILE @CurrentNest > 0
BEGIN
	/* get first row of nest */
	SELECT
		@MinPK = MIN(PK)
	FROM
		@SubEventFormulaTable
	WHERE
		NestLevel = @CurrentNest

	/* get last row of nest */
	SELECT
		@MaxPK = MIN(PK)
	FROM
		@SubEventFormulaTable
	WHERE
		Value = ')'
		AND
		PK > @MinPK
		AND
		NestLevel <= @CurrentNest

	/* update nest level */
	UPDATE
		S
	SET
		NestLevel = @CurrentNest
	FROM
		@SubEventFormulaTable S
	WHERE
		S.PK BETWEEN @MinPK AND @MaxPK
		AND
		S.NestLevel <= @CurrentNest

	SET @CurrentNest = @CurrentNest - 1
END

/******************************************************************************
	set indent level
******************************************************************************/
DECLARE 
	@PK int
	,@NestLevel int
	,@PrevNestLevel int
	,@IndentLevel int

SET @PrevNestLevel = 1
SET @IndentLevel = 0

DECLARE eq_cursor CURSOR STATIC FOR 
	SELECT
		PK
		,NestLevel
	FROM
		@SubEventFormulaTable
	ORDER BY
		PK
	
OPEN eq_cursor
FETCH NEXT FROM eq_cursor INTO  @PK,@NestLevel

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @IndentLevel = 
		CASE 
			WHEN @NestLevel = 1 THEN 0
			WHEN @NestLevel > @PrevNestLevel THEN @IndentLevel + 1
			WHEN @NestLevel < @PrevNestLevel THEN @IndentLevel - 1
			ELSE @IndentLevel
		END

	UPDATE @SubEventFormulaTable 
		SET IndentLevel = @IndentLevel WHERE PK = @PK

	SET @PrevNestLevel = @NestLevel
	FETCH NEXT FROM eq_cursor INTO  @PK,@NestLevel
END

CLOSE eq_cursor
DEALLOCATE eq_cursor

/******************************************************************************
	update dbo.SubEventQualificationFormula
******************************************************************************/
DELETE FROM dbo.SubEventQualificationFormula WHERE PK_SubEvent = @SubEventID

SELECT @EventID = PK_Event FROM dbo.SubEvent WITH (NOLOCK) WHERE PK_SubEvent = @SubEventID

INSERT
	dbo.SubEventQualificationFormula
(
	PK_Event
	,PK_SubEvent
	,Value
	,NestLevel
	,IndentLevel
)
SELECT
	@EventID
	,@SubEventID
	,Value
	,NestLevel
	,IndentLevel
FROM
	@SubEventFormulaTable 


/******************************************************************************
	end procedure
******************************************************************************/
EXEC usp_Utility_UpdateProcessingLog
	@StoredProcedureName = @ProcName
	,@StoredProcedureParameters = @ProcParam
	,@StartTime = @StartTime

END
GO

