CREATE TABLE [dbo].[EventATAccessUserTypeModuleActions] (
    [PK_EventATAccessUserTypeModuleAction] INT           IDENTITY (1, 1) NOT NULL,
    [PK_EventATAccessUserType]             INT           NOT NULL,
    [PK_EventATAccessModule]               INT           NOT NULL,
    [PK_EventATAccessModuleAction]         INT           NOT NULL,
    [CreatedDateUTC]                       SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                            NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]                      SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                           NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventATAccessUserTypeModuleAction] PRIMARY KEY CLUSTERED ([PK_EventATAccessUserTypeModuleAction] ASC),
    CONSTRAINT [EventATAccessUserTypeModuleActions_PK_EventATAccessModule] FOREIGN KEY ([PK_EventATAccessModule]) REFERENCES [dbo].[EventATAccessModules] ([PK_EventATAccessModule]),
    CONSTRAINT [EventATAccessUserTypeModuleActions_PK_EventATAccessModuleAction] FOREIGN KEY ([PK_EventATAccessModuleAction]) REFERENCES [dbo].[EventATAccessModuleActions] ([PK_EventATAccessModuleAction]),
    CONSTRAINT [EventATAccessUserTypeModuleActions_PK_EventATAccessUserType] FOREIGN KEY ([PK_EventATAccessUserType]) REFERENCES [dbo].[EventATAccessUserTypes] ([PK_EventATAccessUserType])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessUserTypeModuleActions_PK_EventATAccessUserType]
    ON [dbo].[EventATAccessUserTypeModuleActions]([PK_EventATAccessUserType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessUserTypeModuleActions_PK_EventATAccessModule]
    ON [dbo].[EventATAccessUserTypeModuleActions]([PK_EventATAccessModule] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessUserTypeModuleActions_PK_EventATAccessModuleAction]
    ON [dbo].[EventATAccessUserTypeModuleActions]([PK_EventATAccessModuleAction] ASC);

