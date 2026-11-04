CREATE FUNCTION dbo.ufn_QualificationByTicket(
	@CreatedBy VARCHAR(50),
	@SortOrder INT, 
	@IsQualMember BIT
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

	DECLARE @PK_Qualification INT
	DECLARE @QualificationValue VARCHAR(10)

	SELECT @PK_Qualification = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'EventTicketAvailable'


INSERT INTO @Seed(
	CreatedDateUTC,
	CreatedBy,
	ModifiedDateUTC,
	ModifiedBy,
	SortOrder, 
	PK_Qualification,
	SubEventQualTxt,
	IsQualMember,
	QualificationValue
)

SELECT
	GETUTCDATE()		AS CreatedDateUTC,
	@CreatedBy			AS CreatedBy,
	GETUTCDATE()		AS ModifiedDateUTC,
	@CreatedBy			AS ModifiedBy,
	@SortOrder			AS SortOrder, 
	@PK_Qualification	AS PK_Qualification,
	'Distributor Has Event Ticket Available'
						AS SubEventQualTxt,
	@IsQualMember		AS IsQualMember,
	@QualificationValue AS QualificationValue
WHERE
	@PK_Qualification IS NOT NULL

RETURN;
END ;