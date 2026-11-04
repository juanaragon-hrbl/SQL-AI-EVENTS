CREATE PROCEDURE [dbo].[usp_GetQualification]
	@PK_Event							INT				= NULL,
	@Category							VARCHAR(50)		= NULL, --Abbreviation, points
    @CreatedDateUTC						DATETIME		= NULL,
    @CreatedBy							VARCHAR (50)	= NULL,
    @ModifiedDateUTC					DATETIME		= NULL,
    @ModifiedBy							VARCHAR (50)	= NULL,
    @PK_Qualification					INT				= NULL,
    @IsQualMember						BIT				= NULL,
    @ValidFromDateUTC					SMALLDATETIME	= NULL,
    @ValidThroughDateUTC				SMALLDATETIME	= NULL,
    @QualificationValue					VARCHAR (500)	= NULL,
    @SortOrder							INT				= NULL,
    @SubEventQualFilter					VARCHAR (100)	= NULL,
    @SubEventQualTxt					VARCHAR (4000)	= NULL,
    @PK_PromotionAccelerator			INT				= NULL,
    @PK_SubEventQualGroup				INT				= NULL,
    @ExtValidFromDate					SMALLDATETIME	= NULL,
    @ExtValidThroughDate				SMALLDATETIME	= NULL,
    @DateType							VARCHAR (30)	= NULL,
    @MetricType							VARCHAR (10)	= NULL,
    @LevelType							VARCHAR (10)	= NULL,
    @BeginLevel							SMALLINT		= NULL,
    @EndLevel							SMALLINT		= NULL,
    @ExtSubEventQualFilter				VARCHAR (500)	= NULL,
    @MonthFrequency						SMALLINT		= NULL,
    @CountLimit							SMALLINT		= NULL,
    @CountMax							SMALLINT		= NULL,
	@QualificationAbbreviation			VARCHAR(30)		= NULL,
	@QualificationType					VARCHAR(12)		= NULL,	--RO,TVP, PPV,DLV, BPP
	@PK_QualificationType				INT				= NULL,	
	@FrequencyType						VARCHAR(20)		= NULL,	--Accumulated,Single,Consecutive
	@PK_QualificationFrequencyType		INT				= NULL,
	@QualificationMetric				VARCHAR(50)		= NULL,
	@QualificationFrequency				INT				= NULL,
	@QualificationDuration				INT				= NULL
	
	-- Error Parameters
	,@Error	int OUTPUT
	,@ErrorMessage varchar(4000) OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN
/******************************************************************************
	OBJECT:			[dbo].[usp_GetQualification]
		
	USE:			
			

	DESCRIPTION:	

	NOTES:

	DEPENDENCIES
	--------------------------------------------------------------------
	

	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2019-05-28		alejandramed		Initial
	1.0.1		2019-07-16		puertac				Adding BPP QualificationType 
	1.0.2		2021-03-11		SushmaA				Adding PLV QualificationType
	
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

--Variables for logging
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

BEGIN TRY

IF @Category = 'Abbreviation'
BEGIN

IF @PK_Qualification IS NULL
	SELECT @PK_Qualification = PK_Qualification FROM dbo.Qualification (NOLOCK) 
	WHERE QualificationAbbreviation = @QualificationAbbreviation

END

IF @Category = 'Points'
BEGIN

	SELECT @PK_QualificationType = 	CASE @QualificationType 
										WHEN 'RO' THEN
												(SELECT PK_QualificationType FROM QualificationType (NOLOCK) WHERE QualType = 'Sales: Royalty Overrides')
										WHEN 'TVP' THEN
												(SELECT PK_QualificationType FROM QualificationType (NOLOCK) WHERE QualType = 'Sales: Volume Points')
										WHEN 'PPV' THEN
												(SELECT PK_QualificationType FROM QualificationType (NOLOCK) WHERE QualType = 'Sales: Personal Purchase Volume')
										WHEN 'DLV' THEN
												(SELECT PK_QualificationType FROM QualificationType (NOLOCK) WHERE QualType = 'Sales: Downline Volume')
										WHEN 'BPP' THEN			-- Bonus Promotion Points    PK_QualificationType = 18
												(SELECT PK_QualificationType FROM QualificationType (NOLOCK) WHERE QualType = 'Sales: TV Double Volume and New FQS Months')
										WHEN 'PLV' THEN   -- PPV + DLV    PK_QualificationType = 37  
												(SELECT PK_QualificationType FROM QualificationType (NOLOCK) WHERE QualType = 'Combined PPV and DLV') 
										END
	
	IF @QualificationType = 'BPP'
		SET @QualificationType = 'TVP + Bonus'  -- for better description in @SubEventQualTxt
	

	SELECT @PK_QualificationFrequencyType = PK_QualificationFrequencyType FROM QualificationFrequencyType (NOLOCK) WHERE FrequencyType = @FrequencyType

	SELECT @PK_Qualification = PK_Qualification FROM [dbo].[Qualification] (NOLOCK)
	WHERE 
		PK_QualificationType = @PK_QualificationType
		AND 
		PK_QualificationFrequencyType = @PK_QualificationFrequencyType
		AND 
		QualificationMetric = @QualificationMetric
		AND 
		QualificationFrequency = @QualificationFrequency
		AND 
		QualificationDuration = @QualificationDuration

	SET @ValidFromDateUTC = DATEADD(d, -DATEPART(d, @ValidFromDateUTC) + 1, @ValidFromDateUTC)
	SET @ValidThroughDateUTC = DATEADD(d, -DATEPART(d, @ValidThroughDateUTC) + 1, @ValidThroughDateUTC)
	
	SELECT @SubEventQualTxt = CASE @FrequencyType 
								WHEN 'Accumulated' THEN

									'Accumulated ' + CAST(@QualificationMetric AS VARCHAR(25)) + ' ' + @QualificationType 
									+ ' from ' + DATENAME(month,@ValidFromDateUTC) + ' ' + CAST(DATEPART(YEAR,@ValidFromDateUTC) AS VARCHAR(5))
									+ ' to ' + DATENAME(month,@ValidThroughDateUTC) + ' ' + CAST(DATEPART(YEAR,@ValidThroughDateUTC) AS VARCHAR(5))
		
								WHEN 'Single' THEN 
	
									'Achieve ' + CAST(@QualificationMetric AS VARCHAR(25)) + ' ' + @QualificationType 
									+ ' in any ' + CAST(@QualificationFrequency AS VARCHAR(5)) + ' month in the last ' + CAST(@QualificationDuration AS VARCHAR(5)) + ' months'

								WHEN 'Consecutive' THEN
	
									'Achieve ' + CAST(@QualificationMetric AS VARCHAR(25)) + ' ' + @QualificationType 
									+ ' in ' + CAST(@QualificationFrequency AS VARCHAR(5)) + ' consecutive months'
									+ ' in the last ' + CAST(@QualificationDuration AS VARCHAR(5)) + ' months'

	END

	SELECT @ValidFromDateUTC = CASE @FrequencyType 
							WHEN 'Accumulated' THEN  @ValidThroughDateUTC
							WHEN 'Single' THEN 								
							CASE WHEN @QualificationFrequency > 1 THEN 
									@ValidThroughDateUTC
									ELSE
									@ValidFromDateUTC
								END
							WHEN 'Consecutive' THEN
								DATEADD(m, @QualificationFrequency -1, @ValidFromDateUTC)
	END
END

	SELECT
			CASE WHEN @CreatedDateUTC IS NULL THEN GETUTCDATE() ELSE @CreatedDateUTC END								AS CreatedDateUTC,
			CASE WHEN @CreatedBy IS NULL THEN REPLACE(SUSER_SNAME(),'HERBALIFECORP\','') ELSE @CreatedBy END 			AS CreatedBy,
			CASE WHEN @ModifiedDateUTC IS NULL THEN GETUTCDATE() ELSE @ModifiedDateUTC END								AS ModifiedDateUTC,
			CASE WHEN @ModifiedBy IS NULL THEN REPLACE(SUSER_SNAME(),'HERBALIFECORP\','') ELSE @ModifiedBy END			AS ModifiedBy,
			@PK_Qualification																							AS PK_Qualification,
			@IsQualMember																								AS IsQualMember,
			@ValidFromDateUTC																							AS ValidFromDateUTC,
			@ValidThroughDateUTC																						AS ValidThroughDateUTC,
			@QualificationValue																							AS QualificationValue,
			@SortOrder																									AS SortOrder, 
			@SubEventQualFilter																							AS SubEventQualFilter,
			CASE WHEN @SubEventQualTxt IS NULL	THEN @QualificationAbbreviation ELSE @SubEventQualTxt END				AS SubEventQualTxt,
			@PK_PromotionAccelerator																					AS PK_PromotionAccelerator,
			@PK_SubEventQualGroup																						AS PK_SubEventQualGroup,
			@ExtValidFromDate																							AS ExtValidFromDate,
			@ExtValidThroughDate																						AS ExtValidThroughDate,
			@DateType																									AS DateType,
			@MetricType																									AS MetricType,
			@LevelType																									AS LevelType,		
			@BeginLevel																									AS BeginLevel,
			@EndLevel																									AS EndLevel,		
			@ExtSubEventQualFilter																						AS ExtSubEventQualFilter,
			@MonthFrequency																								AS MonthFrequency,
			@CountLimit																									AS CountLimit,
			@CountMax																									AS CountMax		
		WHERE
			@PK_Qualification IS NOT NULL

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
END;
GO

