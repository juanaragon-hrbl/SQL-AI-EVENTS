CREATE TABLE [dbo].[EventAudio] (
    [PK_EventAudio]   INT             IDENTITY (1, 1) NOT NULL,
    [PK_Event]        INT             NULL,
    [AudioName]       NVARCHAR (100)  NULL,
    [AudioDesc]       NVARCHAR (200)  NULL,
    [AudioHTML]       NVARCHAR (4000) NULL,
    [CreatedDateUTC]  DATETIME        DEFAULT (getutcdate()) NULL,
    [CreatedBy]       VARCHAR (50)    DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME        DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      VARCHAR (50)    DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_MediaType]    INT             NULL,
    CONSTRAINT [PK_EventAudio_PK_EventAudio] PRIMARY KEY CLUSTERED ([PK_EventAudio] ASC) WITH (FILLFACTOR = 80),
    FOREIGN KEY ([PK_MediaType]) REFERENCES [dbo].[MediaType] ([PK_MediaType]),
    CONSTRAINT [FK_EventAudio_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventAudio_PK_Event]
    ON [dbo].[EventAudio]([PK_Event] ASC);

