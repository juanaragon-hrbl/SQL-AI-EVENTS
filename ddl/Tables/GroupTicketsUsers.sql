CREATE TABLE [dbo].[GroupTicketsUsers] (
    [PK_GroupTicketsUsers] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [UserName]             NVARCHAR (50) NULL,
    [Password]             NVARCHAR (50) NULL,
    [CreatedDateUTC]       SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]            NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]      SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]           NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_GroupTicketsUsers] PRIMARY KEY CLUSTERED ([PK_GroupTicketsUsers] ASC) WITH (FILLFACTOR = 80)
);

