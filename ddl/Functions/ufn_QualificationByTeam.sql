CREATE FUNCTION dbo.ufn_QualificationByTeam(
	@CreatedBy VARCHAR(50),
	@SortOrder INT, 
	@Team VARCHAR(5),
	@GreaterThan BIT,
	@StartDate DATE,
	@EndDate DATE
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

DECLARE @QualificationDuration SMALLINT
DECLARE @PK_QualificationType INT
DECLARE @PK_QualificationFrequencyType INT
DECLARE @Accumulated_Achieve VARCHAR(11)
DECLARE @Consecutive_Any VARCHAR(11)
DECLARE @SubEventQualTxt VARCHAR(500)


SET @StartDate = DATEADD(d, -DATEPART(d, @StartDate) + 1, @StartDate)
SET @EndDate = DATEADD(d, -DATEPART(d, @EndDate) + 1, @EndDate)


SET @SubEventQualTxt = @Team




INSERT INTO @Seed(
	CreatedDateUTC,
	CreatedBy,
	ModifiedDateUTC,
	ModifiedBy,
	SortOrder, 
	PK_Qualification,
	QualificationValue,
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
	CASE @Team
		WHEN 'FQS' THEN 1 
		WHEN 'TAB' THEN 300 + CAST(@GreaterThan AS INT)
		WHEN 'PT'  THEN 300 + CAST(@GreaterThan AS INT)
		ELSE 0
	END										AS PK_Qualification,

	CASE @Team
		WHEN 'FQS' THEN NULL 
		WHEN 'TAB' THEN (SELECT LifeCycleCode FROM PubEvents.dbo.dimDSLifeCycle (NOLOCK) WHERE LifeCycleName = 'Qual Get Team')
		WHEN 'PT'  THEN (SELECT LifeCycleCode FROM PubEvents.dbo.dimDSLifeCycle (NOLOCK) WHERE LifeCycleName = 'Qual Pres Team')
		ELSE 0
	END										AS QualificationValue,

	@StartDate								AS ValidFromDateUTC,
	@EndDate								AS ValidThroughDateUTC,
	@SubEventQualTxt						AS SubEventQualTx 

RETURN;
END ;