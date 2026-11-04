CREATE TABLE [dbo].[EventATAccessModuleActions] (
    [PK_EventATAccessModuleAction]  INT             IDENTITY (1, 1) NOT NULL,
    [PK_EventATAccessModule]        INT             NOT NULL,
    [EventATAccessModuleActionName] NVARCHAR (500)  NOT NULL,
    [EventATAccessModuleActionDesc] NVARCHAR (2000) NOT NULL,
    [CreatedDateUTC]                SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                     NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]               SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                    NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventATAccessModuleAction] PRIMARY KEY CLUSTERED ([PK_EventATAccessModuleAction] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventATAccessModuleActions_PK_EventATAccessModule] FOREIGN KEY ([PK_EventATAccessModule]) REFERENCES [dbo].[EventATAccessModules] ([PK_EventATAccessModule])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessModuleActions_PK_EventATAccessModuleAction]
    ON [dbo].[EventATAccessModuleActions]([PK_EventATAccessModuleAction] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessModuleActions_PK_EventATAccessModule]
    ON [dbo].[EventATAccessModuleActions]([PK_EventATAccessModule] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessModuleActions_EventATAccessModuleActionName]
    ON [dbo].[EventATAccessModuleActions]([EventATAccessModuleActionName] ASC);

