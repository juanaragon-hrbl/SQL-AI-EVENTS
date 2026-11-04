CREATE TABLE [dbo].[EventGuestSpeakers] (
    [PK_EventGuestSpeaker]  INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_GuestSpeaker]       INT            NULL,
    [EventSpeakerName]      NVARCHAR (100) NULL,
    [CreatedDateUTC]        DATETIME       DEFAULT (getutcdate()) NULL,
    [CreatedBy]             VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]       DATETIME       DEFAULT (getutcdate()) NULL,
    [ModifiedBy]            VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]              INT            NULL,
    [EventSpeakerTitle]     NVARCHAR (100) NULL,
    [EventSpeakerPhone]     VARCHAR (20)   NULL,
    [EventSpeakerEmail]     NVARCHAR (50)  NULL,
    [EventSpeakerTeamLevel] NVARCHAR (100) NULL,
    [EventSpeakerBio]       NVARCHAR (MAX) NULL,
    [PK_EventImage]         INT            NULL,
    [PK_SubEvent]           INT            NULL,
    CONSTRAINT [PK_EventGuestSpeakers_PK_EventGuestSpeaker] PRIMARY KEY CLUSTERED ([PK_EventGuestSpeaker] ASC) WITH (FILLFACTOR = 80),
    FOREIGN KEY ([PK_EventImage]) REFERENCES [dbo].[EventImage] ([PK_EventImage]),
    CONSTRAINT [FK_EventGuestSpeakers_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [FK_EventGuestSpeakers_PK_SubEvent] FOREIGN KEY ([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);
GO

CREATE NONCLUSTERED INDEX [IX_EventGuestSpeakers_PK_Event]
    ON [dbo].[EventGuestSpeakers]([PK_Event] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_EventGuestSpeakers_PK_SubEvent] ON [dbo].[EventGuestSpeakers]([PK_SubEvent] ASC);
GO