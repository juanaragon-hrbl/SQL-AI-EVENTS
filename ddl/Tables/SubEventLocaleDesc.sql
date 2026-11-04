CREATE TABLE [dbo].[SubEventLocaleDesc] (
    [PK_SubEventLocaleDesc]   INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Subevent]             INT            NOT NULL,
    [PK_Event]                INT            NOT NULL,
    [PK_Locale]               INT            NOT NULL,
    [PK_DefaultLocale]        INT            NOT NULL,
    [SubEventName]            NVARCHAR (MAX) NULL,
    [SubEventQualDesc]        NVARCHAR (MAX) NULL,
    [CreatedDateUTC]          SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]               NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]         SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]              NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [PK_TeamSite]             INT            NULL,
    [TeamSiteModifiedDate]    SMALLDATETIME  DEFAULT (getutcdate()) NULL,
    [QualDesc]                NVARCHAR (MAX) NULL,
    [Image]                   NVARCHAR (MAX) NULL,
    [SubEventGroupNameLocale] NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_SubEventLocaleDesc] PRIMARY KEY CLUSTERED ([PK_SubEventLocaleDesc] ASC),
    CONSTRAINT [SubEventLocaleDesc_Event_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [SubEventLocaleDesc_SubEvent_FK] FOREIGN KEY ([PK_Subevent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent]),
    CONSTRAINT [SubEventLocaleDescPK_Locale_FK] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale])
);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventLocaleDesc_PK_SubEventLocaleDesc]
    ON [dbo].[SubEventLocaleDesc]([PK_SubEventLocaleDesc] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventLocaleDesc_PK_SubEvent]
    ON [dbo].[SubEventLocaleDesc]([PK_Subevent] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventLocaleDesc_PK_Event]
    ON [dbo].[SubEventLocaleDesc]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventLocaleDesc_PK_Locale]
    ON [dbo].[SubEventLocaleDesc]([PK_Locale] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventLocaleDesc_CreatedDateUTC]
    ON [dbo].[SubEventLocaleDesc]([CreatedDateUTC] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventLocaleDesc_CreatedBy]
    ON [dbo].[SubEventLocaleDesc]([CreatedBy] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventLocaleDesc_ModifiedDateUTC]
    ON [dbo].[SubEventLocaleDesc]([ModifiedDateUTC] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventLocaleDesc_ModifiedBy]
    ON [dbo].[SubEventLocaleDesc]([ModifiedBy] ASC) WITH (FILLFACTOR = 80);

