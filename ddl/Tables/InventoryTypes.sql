CREATE TABLE [dbo].[InventoryTypes] (
    [PK_InventoryType] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [InventoryName]    VARCHAR (100) NOT NULL,
    [CreatedBy]        VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]   SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]  SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [InventoryTypes_PK] PRIMARY KEY CLUSTERED ([PK_InventoryType] ASC) WITH (FILLFACTOR = 80)
);

