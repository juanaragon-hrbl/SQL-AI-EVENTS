CREATE TABLE [dbo].[PMPrimaryLevelDSSubtype] (
    [PK_PMPrimaryLevelDSSubtype]			INT					IDENTITY(1,1) NOT NULL,
    [PK_PMPrimaryLevel]						INT					NOT NULL,
    [PK_DSSubType]							INT					NOT NULL,
    [CreatedDateUTC]						DATETIME			DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]								VARCHAR (50)		DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]						DATETIME			DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]							VARCHAR (50)		DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
	CONSTRAINT [PK_PMPrimaryLevelDSSubtype] PRIMARY KEY CLUSTERED ([PK_PMPrimaryLevelDSSubtype] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE),
	CONSTRAINT [FK_PK_PMPrimaryLevel] FOREIGN KEY([PK_PMPrimaryLevel]) REFERENCES [dbo].[PMPrimaryLevel] ([PK_PMPrimaryLevel]),
);
GO

CREATE NONCLUSTERED INDEX [IX_PMPrimaryLevelDSSubtype_PK_PMPrimaryLevel] 
	ON [dbo].[PMPrimaryLevelDSSubtype] ([PK_PMPrimaryLevel] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_PMPrimaryLevelDSSubtype_PK_DSSubType] 
	ON [dbo].[PMPrimaryLevelDSSubtype] ([PK_DSSubType] ASC);

GO