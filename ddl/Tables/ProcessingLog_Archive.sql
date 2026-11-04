CREATE TABLE [dbo].[ProcessingLog_Archive](
	[PK_ProcessingLog] [int] NOT NULL,
	[CreatedDateUTC] [datetime] NULL,
	[CreatedBy] [varchar](50) NULL,
	[ModifiedDateUTC] [datetime] NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ProcedureName] [varchar](100) NULL,
	[ProcedureParameters] [varchar](100) NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[RunTime] [varchar](10) NULL
) ON [PRIMARY]
GO
