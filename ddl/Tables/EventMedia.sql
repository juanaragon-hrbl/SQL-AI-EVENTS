CREATE TABLE [dbo].[EventMedia] (
    [PK_EventMedia]   INT            IDENTITY (1, 1) NOT NULL,
    [PK_Event]        INT            NOT NULL,
    [PK_MediaType]    INT            NOT NULL,
    [PK_Locale]       INT            NOT NULL,
    [MediaName]       NVARCHAR (100) NULL,
    [MediaDesc]       NVARCHAR (MAX) NULL,
    [MediaHTML]       NVARCHAR (MAX) NULL,
    [CreatedBy]       NVARCHAR (100) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [CreatedDateUTC]  DATETIME2 (7)  DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      NVARCHAR (100) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME2 (7)  DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_EventMedia_PK_EventMedia] PRIMARY KEY CLUSTERED ([PK_EventMedia] ASC),
    CONSTRAINT [FK_EventMedia_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [FK_EventMedia_PK_Locale] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale]),
    CONSTRAINT [FK_EventMedia_PK_MediaType] FOREIGN KEY ([PK_MediaType]) REFERENCES [dbo].[MediaType] ([PK_MediaType])
);

