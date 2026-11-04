CREATE TABLE [dbo].[SKUPurchased] (
    [PK_SKUPurchased]          INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]           DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]                VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]          DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]               VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]                 INT           NOT NULL,
    [PK_EventSKU]              INT           NOT NULL,
    [PK_Distributor_Purchaser] INT           NULL,
    [DistributorID]            VARCHAR (10)  NULL,
    [OrderDate]                SMALLDATETIME NULL,
    [NTSDate]                  DATETIME      NULL,
    [OrderNumber]              VARCHAR (10)  NULL,
    [OrderType]                VARCHAR (2)   NULL,
    [Quantity]                 INT           NULL,
    [IsManual]                 BIT           NULL,
    CONSTRAINT [SKUPurchased_PK] PRIMARY KEY CLUSTERED ([PK_SKUPurchased] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventSKUPurchased_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [EventSKUSKUPurchased_FK] FOREIGN KEY ([PK_EventSKU]) REFERENCES [dbo].[EventSKU] ([PK_EventSKU])
);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_OrderType]
    ON [dbo].[SKUPurchased]([OrderType] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_PK_Distributor_DistributorID]
    ON [dbo].[SKUPurchased]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_PK_Distributor_Purchaser]
    ON [dbo].[SKUPurchased]([PK_Distributor_Purchaser] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_PK_EventSKU]
    ON [dbo].[SKUPurchased]([PK_EventSKU] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_Quantity]
    ON [dbo].[SKUPurchased]([Quantity] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_OrderNumber]
    ON [dbo].[SKUPurchased]([OrderNumber] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_OrderDate]
    ON [dbo].[SKUPurchased]([OrderDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_PK_Event_PK_Distributor_Purchaser]
    ON [dbo].[SKUPurchased]([PK_Event] ASC, [PK_Distributor_Purchaser] ASC)
    INCLUDE([PK_EventSKU]);

GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_PK_Event_PK_EventSKU_Covering] 
	ON [dbo].[SKUPurchased] ([PK_Event], [PK_EventSKU]) INCLUDE ([PK_Distributor_Purchaser], [Quantity], [IsManual], [DistributorID], [OrderDate], [OrderNumber], [OrderType]);
