CREATE TABLE [dbo].[MapLanguageCode] (
    [PK_MapLanguageCode] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [LanguageCode]       VARCHAR (10)  NOT NULL,
    [LocaleCode]         VARCHAR (10)  NOT NULL,
    [CreatedBy]          NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]     SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]         NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]    SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_MapLanguageCode] PRIMARY KEY CLUSTERED ([PK_MapLanguageCode] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_MapLanguageCode_LanguageCode]
    ON [dbo].[MapLanguageCode]([LanguageCode] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MapLanguageCode_LocaleCode]
    ON [dbo].[MapLanguageCode]([LocaleCode] ASC);

