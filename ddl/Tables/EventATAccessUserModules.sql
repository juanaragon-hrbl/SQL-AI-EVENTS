CREATE TABLE [dbo].[EventATAccessUserModules] (
    [PK_EventATAccessUserModule] INT           IDENTITY (1, 1) NOT NULL,
    [PK_EventATAccessUser]       INT           NOT NULL,
    [PK_Locale]                  INT           NOT NULL,
    [CreatedDateUTC]             SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                  NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]            SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                 NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventATAccessUserModule] PRIMARY KEY CLUSTERED ([PK_EventATAccessUserModule] ASC),
    CONSTRAINT [EventATAccessUserModules_PK_EventATAccessUser] FOREIGN KEY ([PK_EventATAccessUser]) REFERENCES [dbo].[EventATAccessUser] ([PK_EventATAccessUser]),
    CONSTRAINT [EventATAccessUserModules_PK_Locale] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessUserModules_PK_EventATAccessUser]
    ON [dbo].[EventATAccessUserModules]([PK_EventATAccessUser] ASC) WITH (FILLFACTOR = 80);


GO

CREATE NONCLUSTERED INDEX [IX_EventATAccessUserModules_PK_Locale_Covering] 
	ON [dbo].[EventATAccessUserModules] ([PK_Locale])
	INCLUDE(PK_EventATAccessUSer)