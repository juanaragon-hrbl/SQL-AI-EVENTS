CREATE TABLE [dbo].[EventInventory] (
    [PK_EventInventory] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [QuantityInStock]   INT           NOT NULL,
    [QuantityRequired]  INT           NULL,
    [CreatedBy]         VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]    SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]        VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]   SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [PK_Event]          INT           NOT NULL,
    [PK_Inventory]      INT           NOT NULL,
    CONSTRAINT [EventInventory_PK] PRIMARY KEY CLUSTERED ([PK_EventInventory] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventEventInventory_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [InventoryEventInventory_FK] FOREIGN KEY ([PK_Inventory]) REFERENCES [dbo].[Inventory] ([PK_Inventory])
);

