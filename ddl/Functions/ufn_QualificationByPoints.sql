CREATE 
FUNCTION [dbo].[ufn_QualificationByPoints](
	@CreatedBy VARCHAR(50),
	@SortOrder INT,
	@IsQualMember BIT,
	@StartDate DATE,
	@EndDate DATE,
	@FrequencyType VARCHAR(20), --Accumulated,Single,Consecutive
	@QualificationType VARCHAR(5), --RO,TVP, PPV,DLV
	@QualificationMetric INT,
	@QualificationFrequency SMALLINT,
	@QualificationDuration SMALLINT
)

RETURNS @Seed TABLE(
    [CreatedDateUTC]           DATETIME       DEFAULT (getutcdate()) NULL,
    [CreatedBy]                VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]          DATETIME       DEFAULT (getutcdate()) NULL,
    [ModifiedBy]               VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Qualification]         INT            NULL,
    [IsQualMember]             BIT            DEFAULT ((1)) NULL,
    [ValidFromDateUTC]         SMALLDATETIME  NULL,
    [ValidThroughDateUTC]      SMALLDATETIME  NULL,
    [QualificationValue]       VARCHAR (500)  NULL,
    [SortOrder]                INT            NULL,
    [SubEventQualFilter]       VARCHAR (100)  NULL,
    [SubEventQualTxt]          VARCHAR (4000) NULL,
    [PK_PromotionAccelerator]  INT            NULL,
    [PK_SubEventQualGroup]     INT            NULL,
    [ExtValidFromDate]         SMALLDATETIME  NULL,
    [ExtValidThroughDate]      SMALLDATETIME  NULL,
    [DateType]                 VARCHAR (30)   NULL,
    [MetricType]               VARCHAR (10)   NULL,
    [LevelType]                VARCHAR (10)   NULL,
    [BeginLevel]               SMALLINT       NULL,
    [EndLevel]                 SMALLINT       NULL,
    [ExtSubEventQualFilter]    VARCHAR (500)  NULL,
    [MonthFrequency]           SMALLINT       NULL,
    [CountLimit]               SMALLINT       NULL,
    [CountMax]                 SMALLINT       NULL
)
	 

AS
BEGIN


DECLARE @PK_QualificationType INT
		,@PK_QualificationFrequencyType INT
		,@PK_Qualification INT
		,@SubEventQualTxt VARCHAR(500)

SELECT @PK_QualificationType = 
	CASE @QualificationType 
	WHEN 'RO' THEN
			(SELECT PK_QualificationType FROM QualificationType (NOLOCK) WHERE QualType = 'Sales: Royalty Overrides')
	WHEN 'TVP' THEN
			(SELECT PK_QualificationType FROM QualificationType (NOLOCK) WHERE QualType = 'Sales: Volume Points')
	WHEN 'PPV' THEN
			(SELECT PK_QualificationType FROM QualificationType (NOLOCK) WHERE QualType = 'Sales: Personal Purchase Volume')
	WHEN 'DLV' THEN
			(SELECT PK_QualificationType FROM QualificationType (NOLOCK) WHERE QualType = 'Sales: Downline Volume')
	END

SELECT @PK_QualificationFrequencyType = PK_QualificationFrequencyType FROM QualificationFrequencyType (NOLOCK) WHERE FrequencyType = @FrequencyType

SELECT @PK_Qualification = PK_Qualification 
FROM [dbo].[Qualification] (NOLOCK)
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

SET @StartDate = DATEADD(d, -DATEPART(d, @StartDate) + 1, @StartDate)
SET @EndDate = DATEADD(d, -DATEPART(d, @EndDate) + 1, @EndDate)

SELECT @SubEventQualTxt = CASE @FrequencyType 
WHEN 'Accumulated' THEN

	'Accumulated ' + CAST(@QualificationMetric AS VARCHAR(25)) + ' ' + @QualificationType 
	+ ' from ' + DATENAME(month,@StartDate) + ' ' + CAST(DATEPART(YEAR,@StartDate) AS VARCHAR(5))
	+ ' to ' + DATENAME(month,@EndDate) + ' ' + CAST(DATEPART(YEAR,@EndDate) AS VARCHAR(5))
		
WHEN 'Single' THEN 
	
	'Achieve ' + CAST(@QualificationMetric AS VARCHAR(25)) + ' ' + @QualificationType 
	+ ' in any ' + CAST(@QualificationFrequency AS VARCHAR(5)) + ' month in the last ' + CAST(@QualificationDuration AS VARCHAR(5)) + ' months'

WHEN 'Consecutive' THEN
	
	'Achieve ' + CAST(@QualificationMetric AS VARCHAR(25)) + ' ' + @QualificationType 
	+ ' in ' + CAST(@QualificationFrequency AS VARCHAR(5)) + ' consecutive months'
	+ ' in the last ' + CAST(@QualificationDuration AS VARCHAR(5)) + ' months'

END

INSERT INTO @Seed(
	CreatedDateUTC,
	CreatedBy,
	ModifiedDateUTC,
	ModifiedBy,
	SortOrder, 
	[IsQualMember],
	PK_Qualification,
	ValidFromDateUTC,
	ValidThroughDateUTC,
	SubEventQualTxt
)

SELECT
	GETUTCDATE()							AS CreatedDateUTC,
	@CreatedBy								AS CreatedBy,
	GETUTCDATE()							AS ModifiedDateUTC,
	@CreatedBy								AS ModifiedBy,
	@SortOrder								AS SortOrder, 
	@IsQualMember							AS IsQualMember,
	@PK_Qualification						AS PK_Qualification,
	CASE @FrequencyType 
		WHEN 'Accumulated' THEN @StartDate	
		WHEN 'Single' THEN @StartDate
		WHEN 'Consecutive' THEN @StartDate 
		END									AS ValidFromDateUTC,
	CASE @FrequencyType 
		WHEN 'Accumulated' THEN @EndDate	
		WHEN 'Single' THEN @EndDate
		WHEN 'Consecutive' THEN @EndDate 
		END									AS ValidThroughDateUTC,
	@SubEventQualTxt						AS SubEventQualTxt 

RETURN;
END ;
GO


