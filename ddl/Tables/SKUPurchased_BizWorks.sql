CREATE TABLE [dbo].[SKUPurchased_BizWorks] (
    [PK_SKUPurchased]    INT           NOT NULL,
    [CreatedDate]        DATETIME      NULL,
    [CreatedBy]          VARCHAR (50)  NULL,
    [ModifiedDate]       DATETIME      NULL,
    [ModifiedBy]         VARCHAR (50)  NULL,
    [PK_Event]           INT           NOT NULL,
    [PK_EventSKU]        INT           NOT NULL,
    [SKUCode]            VARCHAR (10)  NOT NULL,
    [PK_Distributor_EDW] INT           NULL,
    [PK_Distributor]     INT           CONSTRAINT [DF__SKUPurcha__PK_Di__1D6A0BE8] DEFAULT ((0)) NULL,
    [DistributorID]      VARCHAR (10)  NULL,
    [OrderDate]          SMALLDATETIME NULL,
    [NTSDate]            DATETIME      NULL,
    [OrderNumber]        VARCHAR (10)  NULL,
    [OrderType]          VARCHAR (2)   NULL,
    [Quantity]           INT           NULL,
    [IsManual]           BIT           NULL,
    [UnitListPrice]      MONEY         NULL,
    CONSTRAINT [PK_SKUPurchased_BizWorks_PK_SKUPurchased] PRIMARY KEY CLUSTERED ([PK_SKUPurchased] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_BizWorks_Include]
    ON [dbo].[SKUPurchased_BizWorks]([PK_Distributor] ASC)
    INCLUDE([PK_Event], [DistributorID], [SKUCode]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_BizWorks_PK_Event]
    ON [dbo].[SKUPurchased_BizWorks]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_BizWorks_DistributorID]
    ON [dbo].[SKUPurchased_BizWorks]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SKUPurchased_BizWorks_PK_Distributor]
    ON [dbo].[SKUPurchased_BizWorks]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);

