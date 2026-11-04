CREATE TABLE [dbo].[Inventory] (
    [PK_Inventory]     INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]   SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]        VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]  SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [PK_ColorType]     INT           NOT NULL,
    [PK_InventoryType] INT           NOT NULL,
    CONSTRAINT [Inventory_PK] PRIMARY KEY CLUSTERED ([PK_Inventory] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [ColorTypesInventory_FK] FOREIGN KEY ([PK_ColorType]) REFERENCES [dbo].[ColorTypes] ([PK_ColorType]),
    CONSTRAINT [InventoryTypesInventory_FK] FOREIGN KEY ([PK_InventoryType]) REFERENCES [dbo].[InventoryTypes] ([PK_InventoryType])
);

