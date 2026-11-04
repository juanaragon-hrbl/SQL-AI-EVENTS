CREATE TABLE [dbo].[DSTeamTypeLocaleDesc] (
    [PK_DSTeamTypeLocaleDesc] INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [DSTeamTypeCode]          VARCHAR (5)     NOT NULL,
    [DSTeamTypeDesc]          NVARCHAR (2000) NULL,
    [PK_Locale]               INT             NULL,
    [DSTeamTypeGroupCode]     VARCHAR (2)     NOT NULL,
    [DSTeamTypeGroupDesc]     NVARCHAR (2000) NULL,
    [CreatedDateUTC]          SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]               NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]         SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]              NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_DSTeamTypeLocaleDesc] PRIMARY KEY CLUSTERED ([PK_DSTeamTypeLocaleDesc] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [PK_Locale_FK_FK] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale])
);


GO
CREATE NONCLUSTERED INDEX [IX_DSTeamType_PK_DSTeamTypeLocaleDesc]
    ON [dbo].[DSTeamTypeLocaleDesc]([PK_DSTeamTypeLocaleDesc] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DSTeamTypeLocaleDesc_DSTeamTypeCode]
    ON [dbo].[DSTeamTypeLocaleDesc]([DSTeamTypeCode] ASC) WITH (FILLFACTOR = 80);

