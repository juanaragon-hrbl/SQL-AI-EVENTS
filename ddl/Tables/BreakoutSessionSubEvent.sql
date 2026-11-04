CREATE TABLE [dbo].[BreakoutSessionSubEvent]
(
	[PK_Event] [int] NOT NULL,
	[BreakoutSession] [int] NOT NULL,
	[PK_SubEvent] [int] NOT NULL,
	[CreatedDateUTC] [datetime2](7) NOT NULL,
	[CreatedBy] [varchar](255) NOT NULL,
	[ModifiedDateUTC] [datetime2](7) NOT NULL,
	[ModifiedBy] [varchar](255) NOT NULL,
	CONSTRAINT [FK_BreakoutSessionSubEvent_PK_Event] FOREIGN KEY([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
	CONSTRAINT [FK_BreakoutSessionSubEvent_BreakoutSession] FOREIGN KEY([BreakoutSession]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent]),
	CONSTRAINT [FK_BreakoutSessionSubEvent_PK_SubEvent] FOREIGN KEY([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);

GO
CREATE NONCLUSTERED INDEX [IX_BreakoutSessionSubEvent_PK_Event]
    ON [dbo].[BreakoutSessionSubEvent]([PK_Event] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

GO
CREATE NONCLUSTERED INDEX [IX_BreakoutSessionSubEvent_BreakoutSession]
    ON [dbo].[BreakoutSessionSubEvent]([BreakoutSession] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

GO
CREATE NONCLUSTERED INDEX [IX_BreakoutSessionSubEvent_PK_SubEvent]
    ON [dbo].[BreakoutSessionSubEvent]([PK_SubEvent] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

GO
