CREATE TABLE [dbo].[AWT_Metrics] (
    [PK_AWT_Metrics] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC] DATETIME      DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]      VARCHAR (100) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [Flg1]           INT           DEFAULT ((1)) NULL,
    [PK_Distributor] INT           NULL,
    [DistributorID]  VARCHAR (30)  NULL,
    [COP]            VARCHAR (2)   NULL,
    [isType23]       TINYINT       DEFAULT ((0)) NULL,
    [Qual_SP]        SMALLDATETIME NULL,
    [RoyaltyMonth]   SMALLDATETIME NULL,
    [TV]             MONEY         DEFAULT ((0)) NULL,
    [TV_Accelerator] MONEY         DEFAULT ((0)) NULL,
    [RO]             MONEY         DEFAULT ((0)) NULL,
    [did2500KTV]     AS            (case when [TV]>=(2500) then (1) else (0) end),
    [did10KTV]       AS            (case when ([TV]+[TV_Accelerator])>=(10000) then (1) else (0) end),
    [did500RO]       AS            (case when [RO]>=(500) then (1) else (0) end),
    [did2500KTVL6M]  TINYINT       DEFAULT ((0)) NULL,
    [did10KTVL6M]    TINYINT       DEFAULT ((0)) NULL,
    [did500ROL6M]    TINYINT       DEFAULT ((0)) NULL,
    [didAWTJanFeb]   TINYINT       DEFAULT ((0)) NULL,
    [AWTYear]        INT           NULL,
    [did5KTV]        AS            (case when [TV]>=(5000) then (1) else (0) end),
    [did5KTVL6M]     TINYINT       NULL,
    [didAWT]         INT           CONSTRAINT [DF_AWT_Metrics_didAWT] DEFAULT ((0)) NULL,
    [didAcc10KTV2CM]    TINYINT       DEFAULT ((0)) NULL,
    [didAcc10KTV2CML6M]    TINYINT       DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([PK_AWT_Metrics] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Metrics_Qual_SP]
    ON [dbo].[AWT_Metrics]([Qual_SP] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Metrics_Royaltymonth]
    ON [dbo].[AWT_Metrics]([RoyaltyMonth] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Metrics_DistributorID]
    ON [dbo].[AWT_Metrics]([DistributorID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Metrics_PK_Distributor]
    ON [dbo].[AWT_Metrics]([PK_Distributor] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_AWT_Metrics_Composite1] ON [dbo].[AWT_Metrics]
(
	[PK_Distributor] ASC,
	[RoyaltyMonth] ASC
)
INCLUDE ( 	[COP],[did5KTV],[did2500KTV],[did10KTV],[did500RO]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
GO


