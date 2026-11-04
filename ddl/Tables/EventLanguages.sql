CREATE TABLE [dbo].[EventLanguages] (
    [PK_EventLanguage] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [LanguageName]     VARCHAR (100) NOT NULL,
    [CreatedDateUTC]   DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]        VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]  DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [EventLanguages_PK] PRIMARY KEY CLUSTERED ([PK_EventLanguage] ASC) WITH (FILLFACTOR = 80)
);

