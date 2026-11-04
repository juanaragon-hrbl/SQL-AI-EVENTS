CREATE TABLE [dbo].[EventGuestSpeakerLocale] (
    [PK_EventGuestSpeakerLocale] INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_EventGuestSpeaker]       INT            NULL,
    [EventSpeakerName]           NVARCHAR (100) NULL,
    [EventSpeakerTitle]          NVARCHAR (100) NULL,
    [EventSpeakerTeamLevel]      NVARCHAR (100) NULL,
    [CreatedDateUTC]             DATETIME       DEFAULT (getutcdate()) NULL,
    [CreatedBy]                  VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]            DATETIME       DEFAULT (getutcdate()) NULL,
    [ModifiedBy]                 VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]                   INT            NULL,
    [PK_Locale]                  INT            NULL,
    [EventSpeakerBio]            NVARCHAR (MAX) NULL,
    [PK_EventURL]                INT            NULL,
    CONSTRAINT [PK_EventGuestSpeakerLocale_PK_EventGuestSpeakerLocale] PRIMARY KEY CLUSTERED ([PK_EventGuestSpeakerLocale] ASC) WITH (FILLFACTOR = 80),
    FOREIGN KEY ([PK_EventGuestSpeaker]) REFERENCES [dbo].[EventGuestSpeakers] ([PK_EventGuestSpeaker]),
    FOREIGN KEY ([PK_EventURL]) REFERENCES [dbo].[EventURL] ([PK_EventURL]),
    FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale]),
    CONSTRAINT [FK_EventGuestSpeakerLocale_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventGuestSpeakerLocale_PK_Event_PK_Locale]
    ON [dbo].[EventGuestSpeakerLocale]([PK_Event] ASC, [PK_Locale] ASC)
    INCLUDE([PK_EventGuestSpeaker], [EventSpeakerName], [EventSpeakerTitle], [EventSpeakerTeamLevel], [EventSpeakerBio], [PK_EventURL]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventGuestSpeakerLocale_PK_EventGuestSpeaker_PK_Event_PK_Locale]
    ON [dbo].[EventGuestSpeakerLocale]([PK_EventGuestSpeaker] ASC, [PK_Event] ASC, [PK_Locale] ASC)
    INCLUDE([EventSpeakerName], [EventSpeakerTitle], [EventSpeakerTeamLevel], [EventSpeakerBio], [PK_EventURL]) WITH (FILLFACTOR = 80);

