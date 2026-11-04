CREATE TABLE [dbo].[EventGroupImageLocale] (
    [PK_EventGroupImageLocale] INT            IDENTITY (1, 1) NOT NULL,
    [PK_EventGroup]            INT            NOT NULL,
    [PK_EventImageType]        INT            NOT NULL,
    [PK_Locale]                INT            NOT NULL,
    [ImageTitle]               NVARCHAR (50)  NULL,
    [ImageLocation]            NVARCHAR (250) NOT NULL,
    [CreatedDateUTC]           DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]          DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]               VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventGroupImageLocale] PRIMARY KEY CLUSTERED ([PK_EventGroupImageLocale] ASC),
    CONSTRAINT [FK_EventGroupImageLocale_EventGroups] FOREIGN KEY ([PK_EventGroup]) REFERENCES [dbo].[EventGroups] ([PK_EventGroup]),
    CONSTRAINT [FK_EventGroupImageLocale_EventImageType] FOREIGN KEY ([PK_EventImageType]) REFERENCES [dbo].[EventImageType] ([PK_EventImageType]),
    CONSTRAINT [FK_EventGroupImageLocale_Locales] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventGroupImageLocale_ImageLocation]
    ON [dbo].[EventGroupImageLocale]([ImageLocation] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventGroupImageLocale_PK_Locale]
    ON [dbo].[EventGroupImageLocale]([PK_Locale] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventGroupImageLocale_PK_EventGroup]
    ON [dbo].[EventGroupImageLocale]([PK_EventGroup] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventGroupImageLocale_PK_EventImageType]
    ON [dbo].[EventGroupImageLocale]([PK_EventImageType] ASC);

