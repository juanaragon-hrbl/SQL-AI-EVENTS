CREATE TABLE [dbo].[SKUPurchased_Extract] (
    [PK_SKUPurchased_Extract]  INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]           SMALLDATETIME DEFAULT (getutcdate()) NULL,
    [CreatedBy]                VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]          SMALLDATETIME DEFAULT (getutcdate()) NULL,
    [ModifiedBy]               VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]                 INT           NULL,
    [PK_EventSKU]              INT           NULL,
    [PK_Distributor_Purchaser] INT           NULL,
    [DistributorID]            VARCHAR (10)  NULL,
    [OrderDate]                SMALLDATETIME NULL,
    [NTSDate]                  SMALLDATETIME NULL,
    [OrderNumber]              VARCHAR (10)  NULL,
    [OrderType]                VARCHAR (2)   NULL,
    [Quantity]                 INT           NULL,
    PRIMARY KEY CLUSTERED ([PK_SKUPurchased_Extract] ASC) WITH (FILLFACTOR = 80)
);






GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_Extract_OrderNumber]
    ON [dbo].[SKUPurchased_Extract]([OrderNumber] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_Extract_OrderDate]
    ON [dbo].[SKUPurchased_Extract]([OrderDate] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_Extract_OrderType]
    ON [dbo].[SKUPurchased_Extract]([OrderType] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_Extract_PK_Distributor_Purchaser]
    ON [dbo].[SKUPurchased_Extract]([PK_Distributor_Purchaser] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_Extract_DistributorID]
    ON [dbo].[SKUPurchased_Extract]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_Extract_PK_Event]
    ON [dbo].[SKUPurchased_Extract]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_Extract_PK_EventSKU]
    ON [dbo].[SKUPurchased_Extract]([PK_EventSKU] ASC) WITH (FILLFACTOR = 80);

