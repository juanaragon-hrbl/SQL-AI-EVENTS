CREATE TABLE [dbo].[EventATAccessModules] (
    [PK_EventATAccessModule]  INT             IDENTITY (1, 1) NOT NULL,
    [EventATAccessModuleName] NVARCHAR (500)  NOT NULL,
    [EventATAccessModuleDesc] NVARCHAR (2000) NOT NULL,
    [CreatedDateUTC]          SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]               NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]         SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]              NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventATAccessModule] PRIMARY KEY CLUSTERED ([PK_EventATAccessModule] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessModules_PK_EventATAccessModule]
    ON [dbo].[EventATAccessModules]([PK_EventATAccessModule] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessModules_EventATAccessModuleName]
    ON [dbo].[EventATAccessModules]([EventATAccessModuleName] ASC);

