CREATE TABLE [dbo].[BreakoutSessionQualifierOverride]
(
	[PK_BreakoutSessionQualifierOverride] [bigint] IDENTITY(1,1) NOT NULL,
	[PK_Event]				[int]			NOT NULL,
	[PK_SubEvent]			[int]			NOT NULL,
	[DistributorID]			[varchar](30)	NOT NULL,
	[IsQualified]			[bit]			DEFAULT ((0))	NOT NULL,
	[Note]					[varchar](max)	NULL,
	[CreatedDateUTC]		[datetime]		DEFAULT (getutcdate()) NULL,
	[CreatedBy]				[varchar](50)	DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
	[ModifiedDateUTC]		[datetime]		DEFAULT (getutcdate()) NULL,
	[ModifiedBy]			[varchar](50)	DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
	CONSTRAINT [BreakoutSessionQualifierOverride_PK] PRIMARY KEY CLUSTERED ([PK_BreakoutSessionQualifierOverride] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE),
	CONSTRAINT [BreakoutSessionQualifierOverride_Event_FK] FOREIGN KEY([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
	CONSTRAINT [BreakoutSessionQualifierOverride_SubEvent_FK] FOREIGN KEY([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);

GO
CREATE NONCLUSTERED INDEX [IX_BreakoutSessionQualifierOverride_PK_Event]
    ON [dbo].[BreakoutSessionQualifierOverride]([PK_Event] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

GO
CREATE NONCLUSTERED INDEX [IX_BreakoutSessionQualifierOverride_PK_SubEvent]
    ON [dbo].[BreakoutSessionQualifierOverride]([PK_SubEvent] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

