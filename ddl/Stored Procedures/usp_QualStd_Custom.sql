
CREATE PROCEDURE [dbo].[usp_QualStd_Custom]
	@IsDevQA bit = 0
AS
BEGIN

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE 
	@PK_QualificationType int
	,@ProcName varchar(100)
	,@ProcParam varchar(100)
	,@StartTime datetime

SET @ProcName = 'usp_QualStd_Custom'
SET @ProcParam = ''
SET @StartTime = GETUTCDATE()
SET @PK_QualificationType = 6

/******************************************************************************************
	only do custom qualifications that are needed with current events
	ALL CUSTOM QUAL PROCEDURES MUST HAVE @PK_Qualification AS A PARAMETER
******************************************************************************************/
DECLARE
	@PK_Qualification int
	,@StoredProcedureName varchar(100)

DECLARE customqual_cursor CURSOR STATIC FOR
	SELECT
		DISTINCT
		Q.PK_Qualification
		,Q.StoredProcedureName
	FROM
		dbo.SubEventQualification E WITH (NOLOCK) 
	INNER JOIN 
		dbo.v_EventCurrentQualificationToUpdate V WITH (NOLOCK)
		ON
			E.PK_Event = V.PK_Event
	INNER JOIN
		dbo.Qualification Q WITH (NOLOCK)
		ON
			E.PK_Qualification = Q.PK_Qualification
			AND
			Q.PK_QualificationType = @PK_QualificationType
	ORDER BY
			Q.PK_Qualification

OPEN customqual_cursor
FETCH NEXT FROM customqual_cursor INTO @PK_Qualification, @StoredProcedureName

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRAN CustomQual

	IF @IsDevQA = 1 PRINT @StoredProcedureName + ' ' + CONVERT(varchar,@PK_Qualification)
	EXEC @StoredProcedureName @PK_Qualification

	IF @@ERROR = 0
		COMMIT TRAN CustomQual
	ELSE
		ROLLBACK TRAN CustomQual

	FETCH NEXT FROM customqual_cursor INTO @PK_Qualification, @StoredProcedureName
END 

CLOSE customqual_cursor
DEALLOCATE customqual_cursor

/******************************************************************************
	end procedure
******************************************************************************/
EXEC usp_Utility_UpdateProcessingLog
	@StoredProcedureName = @ProcName
	,@StoredProcedureParameters = @ProcParam
	,@StartTime = @StartTime

END
GO

