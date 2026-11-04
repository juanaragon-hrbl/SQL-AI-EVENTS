CREATE TABLE [dbo].[LocalesExtn] (
    [PK_Locale]				INT				NOT NULL,
    [PK_MasterLocale]		INT				NOT NULL,
	[MasterLocaleLanguage]	NVARCHAR(50)	NOT NULL,
    [IsMasterLocale]        BIT DEFAULT 0	NOT NULL, 
    [ReqAccessPageDsEvents] BIT DEFAULT 0  NULL,
    [CreatedDateUTC]        SMALLDATETIME  DEFAULT (getutcdate())								NOT NULL,
    [CreatedBy]             NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]       SMALLDATETIME  DEFAULT (getutcdate())								NOT NULL,
    [ModifiedBy]            NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
   CONSTRAINT [PK_LocaleExtn] PRIMARY KEY CLUSTERED ([PK_Locale] ASC)
);

GO
CREATE NONCLUSTERED INDEX [IX_LocalesExtn_PK_Locale]
    ON [dbo].[LocalesExtn]([PK_Locale] ASC);

GO