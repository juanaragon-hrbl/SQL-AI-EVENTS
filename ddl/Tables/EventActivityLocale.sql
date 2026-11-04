CREATE TABLE [dbo].[EventActivityLocale] (
    [PK_EventactivityLocale] INT            IDENTITY (1, 1) NOT NULL,
    [PK_EventActivity]       INT            NOT NULL,
    [PK_Locale]              INT            NOT NULL,
    [ActivityName]           NVARCHAR (200) NOT NULL,
    [ActivityDesc]           NVARCHAR (MAX) NULL,
    [Location]               NVARCHAR (200) NULL,
    [Address1]               NVARCHAR (100) NULL,
    [Address2]               NVARCHAR (100) NULL,
    [City]                   NVARCHAR (100) NULL,
    [StateProvince]          NVARCHAR (100) NULL,
    [PostalCode]             VARCHAR (25)   NULL,
    [CreatedUTC]             DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]              NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC]            DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]             NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventactivityLocale] PRIMARY KEY CLUSTERED ([PK_EventactivityLocale] ASC),
    CONSTRAINT [FK_PK_EventActivityLocale_EventActivity] FOREIGN KEY ([PK_EventActivity]) REFERENCES [dbo].[EventActivity] ([PK_EventActivity]),
    CONSTRAINT [FK_PK_EventActivityLocale_Locale] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityLocale_ActivityName]
    ON [dbo].[EventActivityLocale]([ActivityName] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityLocale_Location]
    ON [dbo].[EventActivityLocale]([Location] ASC);

