CREATE TABLE [dbo].[EventSecurityRoles] (
    [PK_EventSecurityRoles] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]        DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]             VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]       DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]            VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_SecurityRole]       INT          NOT NULL,
    [PK_Event]              INT          NOT NULL,
    [PK_SecurityUser]       INT          NOT NULL,
    CONSTRAINT [EventSecurityRoles_PK] PRIMARY KEY CLUSTERED ([PK_EventSecurityRoles] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventEventSecurityRoles_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [SecurityRolesEventSecurityRoles_FK] FOREIGN KEY ([PK_SecurityRole]) REFERENCES [dbo].[SecurityRoles] ([PK_SecurityRole]),
    CONSTRAINT [SecurityUsersEventSecurityRoles_FK] FOREIGN KEY ([PK_SecurityUser]) REFERENCES [dbo].[SecurityUsers] ([PK_SecurityUser])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_EventSecurityRoles_PK_Security_User_Roles]
    ON [dbo].[EventSecurityRoles]([PK_Event] ASC, [PK_SecurityUser] ASC, [PK_SecurityRole] ASC) WITH (FILLFACTOR = 80);

