CREATE TABLE [dbo].[RequestedManageEventAccessLog](
	[PK_AccessLog] [int] IDENTITY(1,1) NOT NULL,
	[DistributorID] [varchar](10) NOT NULL,
	[Locale] [varchar](10) NOT NULL,
	[PK_Locale] [int] NULL
) ON [PRIMARY]

