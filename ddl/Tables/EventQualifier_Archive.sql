CREATE TABLE [dbo].[EventQualifier_Archive](
	[PK_EventQualifier] [bigint] NOT NULL,
	[CreatedDateUTC] [datetime] NULL,
	[CreatedBy] [varchar](50) NULL,
	[ModifiedDateUTC] [datetime] NULL,
	[ModifiedBy] [varchar](50) NULL,
	[PK_Event] [int] NULL,
	[PK_Distributor] [int] NULL,
	[DistributorID] [varchar](30) NULL,
	[Qualified] [int] NOT NULL
) ON [PRIMARY]
GO