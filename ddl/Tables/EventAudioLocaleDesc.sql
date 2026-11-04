CREATE TABLE [dbo].[EventAudioLocaleDesc] (
    [PK_EventAudioLocaleDesc] INT             IDENTITY (1, 1) NOT NULL,
    [PK_Event]                INT             NULL,
    [PK_EventAudio]           INT             NULL,
    [AudioName]               NVARCHAR (100)  NULL,
    [AudioDesc]               NVARCHAR (200)  NULL,
    [AudioHTML]               NVARCHAR (4000) NULL,
    [CreatedDateUTC]          DATETIME        DEFAULT (getutcdate()) NULL,
    [CreatedBy]               VARCHAR (50)    DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]         DATETIME        DEFAULT (getutcdate()) NULL,
    [ModifiedBy]              VARCHAR (50)    DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Locale]               INT             NULL,
    CONSTRAINT [PK_EventAudioLocaleDesc_PK_EventAudioLocaleDesc] PRIMARY KEY CLUSTERED ([PK_EventAudioLocaleDesc] ASC) WITH (FILLFACTOR = 80),
    FOREIGN KEY ([PK_EventAudio]) REFERENCES [dbo].[EventAudio] ([PK_EventAudio]),
    FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale]),
    CONSTRAINT [FK_EventAudioLocaleDesc_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);

