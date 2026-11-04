CREATE PROCEDURE [dbo].[usp_SubEventQualEngine_ProcessQualifiers]
	@SubEventID int
	,@DropTableSQL nvarchar(MAX) OUTPUT
	,@IsDevQA bit = 0
AS
BEGIN

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE
	@SQL nvarchar(max)
	,@MaxNestCount int
	,@NestCount int
	,@PrevNestLevel int
	,@MinPK int
	,@MaxPK int
	,@ProcName varchar(100)
	,@ProcParam varchar(100)
	,@StartTime datetime

SET @ProcName = 'usp_SubEventQualEngine_ProcessQualifiers'
SET @ProcParam = CONVERT(varchar,@SubEventID)
SET @StartTime = GETUTCDATE()

/******************************************************************************
	calculate subevent qualfiers based on formula
******************************************************************************/
DECLARE @SubEventFormula TABLE (
	PK int IDENTITY(1,1)
	,Value varchar(10)
	,NestLevel int
)

DECLARE @SubEventFormulaNext TABLE (
	PK int IDENTITY(1,1)
	,Value varchar(10)
	,NestLevel int
)

INSERT
	@SubEventFormula (Value, NestLevel)
SELECT
	CASE WHEN Value NOT IN ('O','A',')','(') THEN '##Q' + Value ELSE Value END
	,NestLevel
FROM
	dbo.SubEventQualificationFormula WITH (NOLOCK)
WHERE
	PK_SubEvent = @SubEventID
ORDER BY
	PK_SubEventQualificationFormula

/* get max nesting of formula */
SELECT @MaxNestCount = MAX(NestLevel) FROM dbo.SubEventQualificationFormula WITH (NOLOCK) WHERE PK_SubEvent = @SubEventID
SET @NestCount = @MaxNestCount

WHILE @NestCount > 0
BEGIN
	/* get min and max pk of range for nest level */
	SELECT
		@MinPK = MIN(PK)
		,@MaxPK = MAX(PK)
	FROM
		@SubEventFormula
	WHERE
		NestLevel = @NestCount

	/* get the nest level immediately before the current nest */
	SELECT @PrevNestLevel = NestLevel
	FROM @SubEventFormula
	WHERE PK = (SELECT MIN(PK)-1 FROM @SubEventFormula WHERE NestLevel = @NestCount)
	SET @PrevNestLevel = COALESCE(@PrevNestLevel,0)
	IF @IsDevQA = 1 BEGIN PRINT '@PrevNestLevel = ' + CONVERT(varchar,@PrevNestLevel) PRINT REPLICATE('-',80) END

	/* create table for nest */
	SET @SQL = 'IF OBJECT_ID(''tempdb..##N' + CONVERT(varchar,@NestCount) + ''') IS NOT NULL DROP TABLE ##N' + CONVERT(varchar,@NestCount)
	SET @DropTableSQL = @DropTableSQL + 'IF OBJECT_ID(''tempdb..##N' + CONVERT(varchar,@NestCount) + ''') IS NOT NULL DROP TABLE ##N' + CONVERT(varchar,@NestCount) + CHAR(13)
	IF @IsDevQA = 1 BEGIN PRINT @SQL PRINT REPLICATE('-',80) END
	EXEC sp_executesql @SQL

	SET @SQL = 'CREATE TABLE ##N' + CONVERT(varchar,@NestCount) + ' (PK_Distributor int, QualDate smalldatetime)'
	IF @IsDevQA = 1 BEGIN PRINT @SQL PRINT REPLICATE('-',80) END
	EXEC sp_executesql @SQL

	/******************************************************************************
		start: calculate the goods
	******************************************************************************/
	DECLARE @Value varchar(10)
	DECLARE @StartCursor bit
	SET @StartCursor = 0
	
	DECLARE formula_cursor CURSOR STATIC FOR
		SELECT Value
		FROM @SubEventFormula
		WHERE
			NestLevel = @NestCount
			AND
			Value NOT IN ('(',')')

	OPEN formula_cursor
	FETCH NEXT FROM formula_cursor INTO @Value

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @StartCursor = 0
		BEGIN
			SET @SQL = 'INSERT ##N' + CONVERT(varchar,@NestCount) + ' (PK_Distributor,QualDate)' + CHAR(13)
			SET @StartCursor = 1
		END

		IF @Value = 'A' -- and
		BEGIN
			FETCH NEXT FROM formula_cursor INTO @Value

			IF CHARINDEX('WHERE',@SQL) = 0
				SET @SQL = @SQL + CHAR(13) + 'WHERE' + CHAR(13) + 'PK_Distributor IN (SELECT PK_Distributor FROM ' + @Value + ')'
			ELSE
				SET @SQL = @SQL + CHAR(13) + ' AND PK_Distributor IN (SELECT PK_Distributor FROM ' + @Value + ')'
		END
		
		ELSE BEGIN
			IF @Value = 'O' -- or
			BEGIN
				FETCH NEXT FROM formula_cursor INTO @Value
				SET @SQL = @SQL + ' GROUP BY PK_Distributor' + CHAR(13) 
					+ 'UNION' + CHAR(13) 
					+ 'SELECT PK_Distributor, MIN(QualDate) FROM ' + @Value

			END ELSE BEGIN
				SET @SQL = @SQL + 'SELECT PK_Distributor, MIN(QualDate) FROM ' + @Value
			END			
		END

		FETCH NEXT FROM formula_cursor INTO @Value
	END 
	
	CLOSE formula_cursor
	DEALLOCATE formula_cursor

	SET @SQL = @SQL + ' GROUP BY PK_Distributor'
	IF @IsDevQA = 1 BEGIN PRINT @SQL PRINT REPLICATE('-',80) END
	EXEC sp_executesql @SQL

	/******************************************************************************
		end: calculate the goods
	******************************************************************************/
	/* update @SubEventFormulaNext with changes */
	DELETE FROM @SubEventFormulaNext
	INSERT
		@SubEventFormulaNext (Value, NestLevel)

		SELECT Value, NestLevel FROM @SubEventFormula WHERE PK < @MinPK
		UNION ALL
		SELECT '##N' + CONVERT(varchar,@NestCount), @PrevNestLevel
		UNION ALL
		SELECT Value, NestLevel FROM @SubEventFormula WHERE PK > @MaxPK

	/* update @SubEventFormula with changes */
	IF @IsDevQA = 1 SELECT PK, Value, NestLevel FROM @SubEventFormula
	DELETE FROM @SubEventFormula
	INSERT @SubEventFormula (Value, NestLevel) SELECT Value, NestLevel FROM @SubEventFormulaNext

	SET @NestCount = @NestCount - 1
END

/******************************************************************************
	check if index exist for global temp table ##N1 and create if not
******************************************************************************/
	IF NOT EXISTS (SELECT 1 FROM TEMPDB..SYSINDEXES WHERE NAME = 'IX_##N1_nDistributorID')
	BEGIN
		SET @SQL = 'CREATE INDEX IX_##N1_PK_Distributor ON ##N1(PK_Distributor)'
		IF @IsDevQA = 1 BEGIN PRINT @SQL PRINT REPLICATE('-',80) END
		EXEC sp_executesql @SQL
	END

/******************************************************************************
	update subevent qualifiers table
******************************************************************************/
EXEC usp_SubEventQualEngine_UpdateSubEventQualifier @SubEventID, '##N1', @IsDevQA

/******************************************************************************
	end procedure
******************************************************************************/
EXEC usp_Utility_UpdateProcessingLog
	@StoredProcedureName = @ProcName
	,@StoredProcedureParameters = @ProcParam
	,@StartTime = @StartTime

END