CREATE TYPE [dbo].[udt_Setup_SubEventQualification] AS TABLE(
	[CreatedDateUTC] [datetime] NULL DEFAULT (getutcdate()),
	[CreatedBy] [varchar](50) NULL DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')),
	[ModifiedDateUTC] [datetime] NULL DEFAULT (getutcdate()),
	[ModifiedBy] [varchar](50) NULL DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')),
	[PK_Qualification] [int] NULL,
	[IsQualMember] [bit] NULL DEFAULT ((1)),
	[ValidFromDateUTC] [smalldatetime] NULL,
	[ValidThroughDateUTC] [smalldatetime] NULL,
	[QualificationValue] [varchar](500) NULL,
	[SortOrder] [int] NULL,
	[SubEventQualFilter] [varchar](100) NULL,
	[SubEventQualTxt] [varchar](4000) NULL,
	[PK_PromotionAccelerator] [int] NULL,
	[PK_SubEventQualGroup] [int] NULL,
	[ExtValidFromDate] [smalldatetime] NULL,
	[ExtValidThroughDate] [smalldatetime] NULL,
	[DateType] [varchar](30) NULL,
	[MetricType] [varchar](10) NULL,
	[LevelType] [varchar](10) NULL,
	[BeginLevel] [smallint] NULL,
	[EndLevel] [smallint] NULL,
	[ExtSubEventQualFilter] [varchar](500) NULL,
	[MonthFrequency] [smallint] NULL,
	[CountLimit] [smallint] NULL,
	[CountMax] [smallint] NULL
)
GO


