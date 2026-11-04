CREATE TABLE [dbo].[SKUPurchasedPivot] (
    [PK_SKUPurchasedPivot]     BIGINT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]           DATETIME       DEFAULT (getutcdate()) NULL,
    [CreatedBy]                VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]          DATETIME       DEFAULT (getutcdate()) NULL,
    [ModifiedBy]               VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]                 INT            NOT NULL,
    [PK_Distributor_Purchaser] INT            NULL,
    [DistributorID]            VARCHAR (10)   NULL,
    [Quantity]                 INT            NULL,
    [OrderInformation]         VARCHAR (4000) NULL,
    CONSTRAINT [SKUPurchasedPivot_PK] PRIMARY KEY CLUSTERED ([PK_SKUPurchasedPivot] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventSKUPurchasedPivot_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchasedPivot_PK_Distributor_DistributorID]
    ON [dbo].[SKUPurchasedPivot]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchasedPivot_PK_Distributor_Purchaser]
    ON [dbo].[SKUPurchasedPivot]([PK_Distributor_Purchaser] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchasedPivot_PK_Event]
    ON [dbo].[SKUPurchasedPivot]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchasedPivot_Quantity]
    ON [dbo].[SKUPurchasedPivot]([Quantity] ASC) WITH (FILLFACTOR = 80);

