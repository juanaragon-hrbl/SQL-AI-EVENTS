CREATE TABLE [dbo].[BreakoutSessionAttendees]
(
	[PK_BreakoutSessionAttendees] [int] IDENTITY(1,1) NOT NULL,
	[PK_Event]				[int]			NOT NULL,
	[PK_SubEvent]			[int]			NOT NULL,
	[DistributorID]			[varchar](30)	NOT NULL,
	[DistributorName]		[varchar](255)	NOT NULL,
	[DistributorEmail]		[varchar](255)	NOT NULL,
	[CreatedDateUTC]		[datetime]		DEFAULT (getutcdate()) NULL,
	[CreatedBy]				[varchar](50)	DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
	[ModifiedDateUTC]		[datetime]		DEFAULT (getutcdate()) NULL,
	[ModifiedBy]			[varchar](50)	DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
	[IsOwner]				[bit]			NULL,
	[PreferredLanguage]		[varchar](5)	NULL,
	CONSTRAINT [PK_BreakoutSessionAttendees] PRIMARY KEY CLUSTERED ([PK_BreakoutSessionAttendees] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE),
	CONSTRAINT [FK_BreakoutSessionAttendees_Event] FOREIGN KEY([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
	CONSTRAINT [FK_BreakoutSessionAttendees_SubEvent] FOREIGN KEY([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);

GO
CREATE NONCLUSTERED INDEX [IX_BreakoutSessionAttendees_PK_Event]
    ON [dbo].[BreakoutSessionAttendees]([PK_Event] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

GO
CREATE NONCLUSTERED INDEX [IX_BreakoutSessionAttendees_PK_SubEvent]
    ON [dbo].[BreakoutSessionAttendees]([PK_SubEvent] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

GO
