CREATE TABLE [dbo].[GDPRDistributors](
    [Id] [int] IDENTITY(1,1) NOT NULL,
	[DSRRequestId] [nvarchar](20) NOT NULL,
	[Pk_Distributor] [int] NOT NULL,
	[DistributorId] [nvarchar](30) NOT NULL,
	[SnowRequest] [nvarchar](20) NOT NULL,
	[Type] [bit] NOT NULL,
	[StatusCode] [int] NOT NULL,
	[RetrievalCount] [int] NOT NULL,
	[RetrievalProcess] [bit] NULL,
	[SubscriptionName] [nvarchar](150) NULL,
	[ErrorMessage] [nvarchar](1000) NULL,
	[AnonymizedDistributor] [bit] NULL,
	[DistributorEvent] [nvarchar](max) NULL,
	[CreatedDateUTC] [datetime] DEFAULT (getutcdate()) NULL,
	[CreatedBy] [nvarchar](50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,	
	[ModifiedDateUTC] [datetime] DEFAULT (getutcdate()) NULL,
	[ModifiedBy] [nvarchar](50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
 CONSTRAINT [PK_GDPRDistributors] PRIMARY KEY CLUSTERED ([Id] ASC));
 GO
 CREATE NONCLUSTERED INDEX [IX_GDPRDistributors_DistributorId] ON [dbo].[GDPRDistributors]
(
	[DistributorId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_GDPRDistributors_Pk_Distributor] ON [dbo].[GDPRDistributors]
(
	[Pk_Distributor] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO