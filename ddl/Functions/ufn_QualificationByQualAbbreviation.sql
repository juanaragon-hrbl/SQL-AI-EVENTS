CREATE FUNCTION [dbo].[ufn_QualificationByQualAbbreviation](
	@CreatedBy VARCHAR(50),
	@SortOrder INT, 
	@IsQualMember BIT,
	@QualAbbreviation VARCHAR(50),
	@PK_Qualification INT = NULL,
	@SubEventQualTxt VARCHAR(4000) = NULL,
	@QualificationValue VARCHAR(500) = NULL,
	@SubEventQualFilter VARCHAR(500) = NULL,
	@ValidFromDateUTC DATETIME = NULL,
	@ValidThroughDateUTC DATETIME = NULL,
	@ExtValidFromDate DATETIME = NULL,
	@ExtValidThroughDate DATETIME = NULL,
	@DateType VARCHAR(20)= NULL,
	@MetricType VARCHAR(10)= NULL,
	@ExtSubEventQualFilter VARCHAR (500)= NULL,
	@MonthFrequency SMALLINT= NULL



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

	IF @PK_Qualification IS NULL
	SELECT @PK_Qualification = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = @QualAbbreviation


	INSERT INTO @Seed(
		CreatedDateUTC,
		CreatedBy,
		ModifiedDateUTC,
		ModifiedBy,
		SortOrder, 
		PK_Qualification,
		SubEventQualTxt,
		IsQualMember,
		QualificationValue,
		SubEventQualFilter,
		ValidFromDateUTC,
		ValidThroughDateUTC,
		ExtValidFromDate,
		ExtValidThroughDate,
		DateType,
		MetricType,
		ExtSubEventQualFilter,
		MonthFrequency
	)

	SELECT
		GETUTCDATE()		AS CreatedDateUTC,
		@CreatedBy			AS CreatedBy,
		GETUTCDATE()		AS ModifiedDateUTC,
		@CreatedBy			AS ModifiedBy,
		@SortOrder			AS SortOrder, 
		@PK_Qualification	AS PK_Qualification,
		CASE WHEN @SubEventQualTxt IS NULL 
		THEN @QualAbbreviation 
		ELSE @SubEventQualTxt END AS SubEventQualTxt,
		@IsQualMember			AS IsQualMember,
		@QualificationValue		AS QualificationValue,
		@SubEventQualFilter		AS SubEventQualFilter,
		@ValidFromDateUTC		AS ValidFromDateUTC,
		@ValidThroughDateUTC	AS ValidThroughDateUTC,
		@ExtValidFromDate		AS ExtValidFromDate,
		@ExtValidThroughDate	AS ExtValidThroughDate,
		@DateType				AS DateType,
		@MetricType				AS MetricType,
		@ExtSubEventQualFilter	AS ExtSubEventQualFilter,
		@MonthFrequency			AS MonthFrequency
	WHERE
		@PK_Qualification IS NOT NULL
RETURN;
END ;
GO

