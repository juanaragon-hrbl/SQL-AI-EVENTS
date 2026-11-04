CREATE TABLE [dbo].[SecurityRoles] (
    [PK_SecurityRole] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [RoleName]        VARCHAR (40) NOT NULL,
    [CreatedDateUTC]  DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]       VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [SecurityRoles_PK] PRIMARY KEY CLUSTERED ([PK_SecurityRole] ASC) WITH (FILLFACTOR = 80)
);

