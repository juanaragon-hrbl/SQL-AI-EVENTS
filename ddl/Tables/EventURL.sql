CREATE TABLE [dbo].[EventURL] (
    [PK_EventURL]     INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Event]        INT             NOT NULL,
    [PK_Locale]       INT             NOT NULL,
    [EventURL]        NVARCHAR (4000) NULL,
    [EventURLDesc]    NVARCHAR (4000) NULL,
    [Flyer]           NVARCHAR (4000) NULL,
    [CreatedDateUTC]  SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]       NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC] SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]      NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [PK_EventURLType] INT             DEFAULT ((1)) NULL,
    CONSTRAINT [PK_EventURL] PRIMARY KEY CLUSTERED ([PK_EventURL] ASC),
    CONSTRAINT [EventURLEvent_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [PK_Locale_FK] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventURL_PK_Event]
    ON [dbo].[EventURL]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_PK_Locale_PK_Locale]
    ON [dbo].[EventURL]([PK_Locale] ASC) WITH (FILLFACTOR = 80);

