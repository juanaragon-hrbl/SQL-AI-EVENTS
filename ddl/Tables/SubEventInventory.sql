CREATE TABLE [dbo].[SubEventInventory] (
    [PK_SubEventInventory] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [QuantityInStock]      INT           NULL,
    [QuantityRequired]     INT           NULL,
    [CreatedBy]            VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]       SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]           VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]      SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [PK_EventInventory]    INT           NOT NULL,
    [PK_SubEvent]          INT           NOT NULL,
    CONSTRAINT [SubEventInventory_PK] PRIMARY KEY CLUSTERED ([PK_SubEventInventory] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventInventorySubEventInventory_FK] FOREIGN KEY ([PK_EventInventory]) REFERENCES [dbo].[EventInventory] ([PK_EventInventory]),
    CONSTRAINT [SubEventSubEventInventory_FK] FOREIGN KEY ([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);
GO

CREATE NONCLUSTERED INDEX [IX_SubEventInventory_PK_SubEvent] ON [dbo].[SubEventInventory]([PK_SubEvent] ASC);
GO
