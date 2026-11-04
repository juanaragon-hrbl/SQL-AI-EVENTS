CREATE TABLE [dbo].[WRK_TaiwanActiveSPPromo](
	[PK] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PK_Distributor] [int] NOT NULL,
	[LastRunTotalSP] [int] NULL,
	[AcviteSupervisor_QualDate] [datetime] NULL,
	[Stone1_QualDate] [datetime] NULL,
	[TotalStone1] [int] NULL,
	[Stone2_QualDate] [datetime] NULL,
	[TotalStone2] [int] NULL,
	[Stone3_QualDate] [datetime] NULL,
	[TotalStone3] [int] NULL,
	[Stone4_QualDate] [datetime] NULL,
	[TotalStone4] [int] NULL,
	[Stone5_QualDate] [datetime] NULL,
	[TotalStone5] [int] NULL,
	[Stone6_QualDate] [datetime] NULL,
	[TotalStone6] [int] NULL,
	[Stone7_QualDate] [datetime] NULL,
	[TotalStone7] [int] NULL,
	[Stone8_QualDate] [datetime] NULL,
	[TotalStone8] [int] NULL,
	[Stone9_QualDate] [datetime] NULL,
	[TotalStone9] [int] NULL,
	[Stone10_QualDate] [datetime] NULL,
	[TotalStone10] [int] NULL,
	[StoneAbove10_QualDate] [datetime] NULL,
	[TotalStoneAbove10] [int] NULL,
	[nYear] [int] NULL,
	[CreatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[PK] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT ((0)) FOR [LastRunTotalSP]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT ((0)) FOR [TotalStone1]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT ((0)) FOR [TotalStone2]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT ((0)) FOR [TotalStone3]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT ((0)) FOR [TotalStone4]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT ((0)) FOR [TotalStone5]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT ((0)) FOR [TotalStone6]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT ((0)) FOR [TotalStone7]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT ((0)) FOR [TotalStone8]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT ((0)) FOR [TotalStone9]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT ((0)) FOR [TotalStone10]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT ((0)) FOR [TotalStoneAbove10]
GO

ALTER TABLE [dbo].[WRK_TaiwanActiveSPPromo] ADD  DEFAULT (getutcdate()) FOR [CreatedDate]
GO


