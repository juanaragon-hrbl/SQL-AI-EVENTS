CREATE TABLE [dbo].[Locales] (
    [PK_Locale]             INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [LanguageCountryRegion] NVARCHAR (500) NOT NULL,
    [LocaleCode]            VARCHAR (5)    NOT NULL,
    [CreatedDateUTC]        SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]             NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]       SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]            NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
	[EnabledOnMyHL]			BIT DEFAULT 0 ,
    CONSTRAINT [PK_Locale] PRIMARY KEY CLUSTERED ([PK_Locale] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Locale_PK_Locale]
    ON [dbo].[Locales]([PK_Locale] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_LangCntryRegion]
    ON [dbo].[Locales]([LanguageCountryRegion] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Locale_LocaleCode]
    ON [dbo].[Locales]([LocaleCode] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Locale_ModifiedDateUTC]
    ON [dbo].[Locales]([ModifiedDateUTC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Locale_ModifiedBy]
    ON [dbo].[Locales]([ModifiedBy] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Locale_CreatedDateUTC]
    ON [dbo].[Locales]([CreatedDateUTC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Locale_CreatedBy]
    ON [dbo].[Locales]([CreatedBy] ASC);

