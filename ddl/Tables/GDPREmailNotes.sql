CREATE TABLE [dbo].[GDPREmailNotes](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Pk_Distributor] [int] NOT NULL,
	[DistributorId] [nvarchar](30) NOT NULL,
	[DistributorStatus] [bit] NOT NULL,
	[Note] [nvarchar](1000) NOT NULL,
	[CreatedDateUTC] [datetime] DEFAULT (getutcdate()) NULL,
	[CreatedBy] [nvarchar](50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,	
	[ModifiedDateUTC] [datetime] DEFAULT (getutcdate()) NULL,
	[ModifiedBy] [nvarchar](50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
 CONSTRAINT [PK_Notes] PRIMARY KEY CLUSTERED ([Id] ASC));
 GO
 CREATE NONCLUSTERED INDEX [IX_GDPREmailNotes_DistributorId] ON [dbo].[GDPREmailNotes]
(
	[DistributorId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_GDPREmailNotes_Pk_Distributor] ON [dbo].[GDPREmailNotes]
(
	[Pk_Distributor] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO