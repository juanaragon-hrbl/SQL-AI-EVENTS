CREATE PROCEDURE [dbo].[usp_SetSubEventQualification]
	@PK_Event INT,
	@SubEventNumber INT,
	@SubEventFormula VARCHAR(MAX),
	@SubEventQualificationSeed dbo.udt_Setup_SubEventQualification READONLY
	
	-- Error Parameters
	,@Error	int OUTPUT
	,@ErrorMessage varchar(4000) OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
	OBJECT:			[dbo].[usp_SetSubEventQualification]
	
	USE:			
			
	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2019-05-03		alejandramed		Initial
	19			2019-11-01		SushmaA				Hard Coded Values - SRE
	2			2022-04-19		JonathanO			Adding TAB on the formula
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
DECLARE @DefaultDate DATETIME = '1900-01-01'
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

	DECLARE @PK_SubEvent INT
	DECLARE @Formula VARCHAR(MAX)
	DECLARE @CurrentSortOrder INT = 1
	DECLARE @PreviusSortOrder INT
	DECLARE @MaxSortOrder INT
	DECLARE @sCurrentSortOrder VARCHAR(50)
	DECLARE @sPreviusSortOrder VARCHAR(50)
	DECLARE @FormulaLen INT 
	DECLARE @index INT 
	DECLARE @item VARCHAR(10)
	DECLARE @SubEventFormulaFormat VARCHAR(2000)
	DECLARE @wasNumber BIT

	DECLARE @QualificationList TABLE
	(
		NewSortOrder INT IDENTITY(1,1),
		SortOrder INT
	)

	SET @Formula = @SubEventFormula
	
	SET @Formula = REPLACE(@Formula, '(', '')
	SET @Formula = REPLACE(@Formula, ')', '')
	SET @Formula = REPLACE(@Formula, 'OR', ',')
	SET @Formula = REPLACE(@Formula, 'AND', ',')
	SET @Formula = REPLACE(@Formula, ' ', '')
	SET @Formula = REPLACE(@Formula, CHAR(9), '')

	INSERT INTO @QualificationList (SortOrder)
	SELECT DISTINCT
		CAST(String AS INT)
	FROM dbo.udf_SplitVarchar(@Formula, ',')

	/* Format formula*/
	
	IF @SubEventFormula IS NOT NULL
	BEGIN

		SET @FormulaLen = LEN (@SubEventFormula)
		SET @index = 1
		SET @SubEventFormulaFormat = ''
		SET @wasNumber = 0

		WHILE @index <= @FormulaLen
		BEGIN

		SET @item = SUBSTRING( @SubEventFormula, @index, 1 )

		IF @item LIKE '[0-9]'
		BEGIN

			IF @wasNumber = 0
					SET @SubEventFormulaFormat = @SubEventFormulaFormat + '|' + @item  
			ELSE 
				SET @SubEventFormulaFormat = @SubEventFormulaFormat + @item  

			SET @wasNumber = 1
		END
		ELSE 
		BEGIN

		IF @wasNumber = 1 
		BEGIN
			SET @SubEventFormulaFormat = @SubEventFormulaFormat + '|' + @item 
			SET @wasNumber = 0
		END
		ELSE
			SET @SubEventFormulaFormat = @SubEventFormulaFormat + @item
		END

		SET @index = @index + 1
		END
		
		SELECT @MaxSortOrder = MAX(NewSortOrder) FROM @QualificationList

		WHILE @CurrentSortOrder <= @MaxSortOrder
				BEGIN
				
					SELECT @sPreviusSortOrder = CONCAT('|', SortOrder, '|') FROM @QualificationList WHERE NewSortOrder = @CurrentSortOrder
					SET @sCurrentSortOrder = CONCAT('|', @CurrentSortOrder, '|')

					SET @SubEventFormulaFormat = REPLACE(@SubEventFormulaFormat,@sPreviusSortOrder,@sCurrentSortOrder)

					SET @CurrentSortOrder = @CurrentSortOrder + 1


				END

				SET @SubEventFormula = REPLACE(@SubEventFormulaFormat,'|','')
	END
			
	SELECT @PK_SubEvent = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_Event AND SubEventNumber = @SubEventNumber
	
	;WITH SourceSubEventQualification(
			CreatedDateUTC,
			CreatedBy,
			ModifiedDateUTC,
			ModifiedBy,
			PK_Event,
			PK_SubEvent,
			PK_Qualification,
			IsQualMember,
			ValidFromDateUTC,
			ValidThroughDateUTC,
			QualificationValue,
			SortOrder,
			SubEventQualFilter,
			SubEventQualTxt,
			PK_PromotionAccelerator,
			PK_SubEventQualGroup,
			ExtValidFromDate,
			ExtValidThroughDate,
			DateType,
			MetricType,
			LevelType,
			BeginLevel,
			EndLevel,
			ExtSubEventQualFilter,
			MonthFrequency,
			CountLimit,
			CountMax
		)
	AS
	(
	SELECT
		seq.CreatedDateUTC,
		seq.CreatedBy,
		seq.ModifiedDateUTC,
		seq.ModifiedBy,
		@PK_Event AS PK_Event,
		@PK_SubEvent AS PK_SubEvent,
		seq.PK_Qualification,
		seq.IsQualMember,
		seq.ValidFromDateUTC,
		seq.ValidThroughDateUTC,
		seq.QualificationValue,
		QL.NewSortOrder,
		seq.SubEventQualFilter,
		seq.SubEventQualTxt,
		seq.PK_PromotionAccelerator,
		seq.PK_SubEventQualGroup,
		seq.ExtValidFromDate,
		seq.ExtValidThroughDate,
		seq.DateType,
		seq.MetricType,
		seq.LevelType,
		seq.BeginLevel,
		seq.EndLevel,
		seq.ExtSubEventQualFilter,
		seq.MonthFrequency,
		seq.CountLimit,
		seq.CountMax
	FROM @SubEventQualificationSeed seq
	INNER JOIN @QualificationList QL
	ON seq.SortOrder = QL.SortOrder
	)
		MERGE dbo.SubEventQualification AS Target
		USING SourceSubEventQualification AS Source
		ON (Target.PK_Event = Source.PK_Event
			AND
			Target.PK_SubEvent = @PK_SubEvent
			AND
			Target.SortOrder = Source.SortOrder)
		WHEN MATCHED
			AND (
					(Target.PK_Qualification							!= Source.PK_Qualification) OR
					(Target.IsQualMember								!= Source.IsQualMember) OR
					(ISNULL(Target.ValidFromDateUTC, @DefaultDate)		!= ISNULL(Source.ValidFromDateUTC, @DefaultDate)) OR
					(ISNULL(Target.ValidThroughDateUTC, @DefaultDate)	!= ISNULL(Source.ValidThroughDateUTC, @DefaultDate)) OR
					(ISNULL(Target.QualificationValue, '')				!= ISNULL(Source.QualificationValue, '')) OR
					(ISNULL(Target.SubEventQualFilter, '')				!= ISNULL(Source.SubEventQualFilter, '')) OR
					(ISNULL(Target.SubEventQualTxt, '')					!= ISNULL(Source.SubEventQualTxt, '')) OR
					(ISNULL(Target.PK_PromotionAccelerator, 0)			!= ISNULL(Source.PK_PromotionAccelerator, 0)) OR
					(ISNULL(Target.PK_SubEventQualGroup, 0)				!= ISNULL(Source.PK_SubEventQualGroup, 0)) OR
					(ISNULL(Target.ExtValidFromDate, @DefaultDate)		!= ISNULL(Source.ExtValidFromDate, @DefaultDate)) OR
					(ISNULL(Target.ExtValidThroughDate, @DefaultDate)	!= ISNULL(Source.ExtValidThroughDate, @DefaultDate)) OR
					(ISNULL(Target.DateType, '')						!= ISNULL(Source.DateType, '')) OR
					(ISNULL(Target.MetricType, '')						!= ISNULL(Source.MetricType, '')) OR
					(ISNULL(Target.LevelType, '')						!= ISNULL(Source.LevelType, '')) OR
					(ISNULL(Target.BeginLevel, 0)						!= ISNULL(Source.BeginLevel, 0)) OR
					(ISNULL(Target.EndLevel, 0)							!= ISNULL(Source.EndLevel, 0)) OR
					(ISNULL(Target.ExtSubEventQualFilter, '')			!= ISNULL(Source.ExtSubEventQualFilter, '')) OR
					(ISNULL(Target.MonthFrequency, 0)					!= ISNULL(Source.MonthFrequency, 0)) OR
					(ISNULL(Target.CountLimit, 0)						!= ISNULL(Source.CountLimit, 0)) OR
					(ISNULL(Target.CountMax, 0)							!= ISNULL(Source.CountMax, 0))
			)
		THEN
			UPDATE
				SET
					Target.ModifiedDateUTC			= GETUTCDATE(),
					Target.ModifiedBy				= Source.ModifiedBy,
					Target.PK_Qualification			= Source.PK_Qualification,
					Target.IsQualMember				= Source.IsQualMember,
					Target.ValidFromDateUTC		    = Source.ValidFromDateUTC,
					Target.ValidThroughDateUTC	    = Source.ValidThroughDateUTC,
					Target.QualificationValue		= Source.QualificationValue,
					Target.SubEventQualFilter		= Source.SubEventQualFilter,
					Target.SubEventQualTxt			= Source.SubEventQualTxt,
					Target.PK_PromotionAccelerator	= Source.PK_PromotionAccelerator,
					Target.PK_SubEventQualGroup		= Source.PK_SubEventQualGroup,
					Target.ExtValidFromDate		    = Source.ExtValidFromDate,
					Target.ExtValidThroughDate	    = Source.ExtValidThroughDate,
					Target.DateType					= Source.DateType,
					Target.MetricType				= Source.MetricType,
					Target.LevelType				= Source.LevelType,
					Target.BeginLevel				= Source.BeginLevel,
					Target.EndLevel					= Source.EndLevel,
					Target.ExtSubEventQualFilter	= Source.ExtSubEventQualFilter,
					Target.MonthFrequency			= Source.MonthFrequency,
					Target.CountLimit				= Source.CountLimit,
					Target.CountMax					= Source.CountMax
		WHEN NOT MATCHED BY Target AND @PK_SubEvent IS NOT NULL THEN 
			INSERT (CreatedDateUTC, CreatedBy, ModifiedDateUTC, ModifiedBy, PK_Event, PK_SubEvent,SortOrder,IsQualMember,SubEventQualTxt,PK_Qualification,QualificationValue,ValidFromDateUTC,ValidThroughDateUTC,SubEventQualFilter,ExtValidFromDate, ExtValidThroughDate, DateType, MetricType, LevelType, BeginLevel, EndLevel, ExtSubEventQualFilter, MonthFrequency, CountLimit)
			VALUES(Source.CreatedDateUTC, Source.CreatedBy, Source.ModifiedDateUTC, Source.ModifiedBy, Source.PK_Event, @PK_SubEvent, Source.SortOrder, Source.IsQualMember, Source.SubEventQualTxt, Source.PK_Qualification, Source.QualificationValue, Source.ValidFromDateUTC, Source.ValidThroughDateUTC, Source.SubEventQualFilter, Source.ExtValidFromDate, Source.ExtValidThroughDate, Source.DateType, Source.MetricType, Source.LevelType, Source.BeginLevel, Source.EndLevel, Source.ExtSubEventQualFilter, Source.MonthFrequency, Source.CountLimit)
		WHEN NOT MATCHED BY Source AND Target.PK_Event = @PK_Event AND Target.PK_SubEvent = @PK_SubEvent THEN
			DELETE;


	UPDATE dbo.SubEvent
	SET
		SubEventFormula = @SubEventFormula
	WHERE
		PK_Event = @PK_Event
		AND
		PK_SubEvent = @PK_SubEvent
		AND
		ISNULL(SubEventFormula, '') != @SubEventFormula

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
END