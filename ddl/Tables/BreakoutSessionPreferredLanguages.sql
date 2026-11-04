CREATE TABLE [dbo].[BreakoutSessionPreferredLanguages]
(
	[PK_Event]				[int]			NOT NULL,
	[PK_SubEvent]			[int]			NOT NULL,
	[PreferredLanguage]		[varchar](5)	NOT NULL,	
	[CreatedDateUTC]		[datetime]		DEFAULT (getutcdate()) NULL,
	[CreatedBy]				[varchar](50)	DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
	[ModifiedDateUTC]		[datetime]		DEFAULT (getutcdate()) NULL,
	[ModifiedBy]			[varchar](50)	DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
	CONSTRAINT [BreakoutSessionPreferredLanguage_Event_FK] FOREIGN KEY([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
	CONSTRAINT [BreakoutSessionPreferredLanguage_SubEvent_FK] FOREIGN KEY([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);

GO
CREATE NONCLUSTERED INDEX [IX_BreakoutSessionPreferredLanguage_PK_Event]
    ON [dbo].[BreakoutSessionPreferredLanguages]([PK_Event] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

GO
CREATE NONCLUSTERED INDEX [IX_BreakoutSessionPreferredLanguage_PK_SubEvent]
    ON [dbo].[BreakoutSessionPreferredLanguages]([PK_SubEvent] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

