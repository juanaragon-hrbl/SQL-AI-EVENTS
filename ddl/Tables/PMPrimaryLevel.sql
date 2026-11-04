CREATE TABLE [dbo].[PMPrimaryLevel] (
    [PK_PMPrimaryLevel]					INT					NOT NULL,
    [PrimaryLevelCode]					VARCHAR (5)			NOT NULL,
    [PrimaryLevelDescription]			VARCHAR (50)		NOT NULL,
	[Order]								INT					NOT NULL,
    [CreatedDateUTC]					DATETIME			DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]							VARCHAR (50)		DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]					DATETIME			DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]						VARCHAR (50)		DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_PMPrimaryLevel] PRIMARY KEY CLUSTERED ([PK_PMPrimaryLevel] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_PMPrimaryLevel_PK_PMPrimaryLevel]
    ON [dbo].[PMPrimaryLevel]([PK_PMPrimaryLevel] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_PMPrimaryLevel_PrimaryLevelCode_Covering] 
	ON [dbo].[PMPrimaryLevel] ([PrimaryLevelCode])
	INCLUDE([Order])
GO










