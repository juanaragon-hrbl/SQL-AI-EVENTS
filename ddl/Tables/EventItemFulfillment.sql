CREATE TABLE [dbo].[EventItemFulfillment] (
    [PK_EventItemFulfillment] INT            IDENTITY (1, 1) NOT NULL,
    [PK_Distributor]          INT            NOT NULL,
    [DistributorID]           VARCHAR (10)   NOT NULL,
    [PK_Event]                INT            NOT NULL,
    [PK_ShippingMethod]       INT            NULL,
    [PK_EventMarketLocation]  INT            NULL,
    [EmailAddress]            VARCHAR (100)  NULL,
    [Phone]                   VARCHAR (100)  NULL,
    [Address1]                NVARCHAR (240) NULL,
    [Address2]                NVARCHAR (240) NULL,
    [City]                    NVARCHAR (60)  NULL,
    [State]                   NVARCHAR (60)  NULL,
    [PostalCode]              NVARCHAR (60)  NULL,
    [CountryCodeISO]          NVARCHAR (5)   NULL,
    [PK_Country]              INT            NULL,
    [CreatedDateUTC]          SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]               NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]         SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]              NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ShippingName]            NVARCHAR (240) NULL,
    [ClaimPrize]              VARCHAR (200)  NULL,
    CONSTRAINT [PK_EventItemFulfillment] PRIMARY KEY CLUSTERED ([PK_EventItemFulfillment] ASC),
    CONSTRAINT [FK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [FK_ShippingMethod] FOREIGN KEY ([PK_ShippingMethod]) REFERENCES [dbo].[ShippingMethod] ([PK_ShippingMethod])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventItemFulfillment_PK_Distributor]
    ON [dbo].[EventItemFulfillment]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventItemFulfillment_DistributorID]
    ON [dbo].[EventItemFulfillment]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventItemFulfillment_PK_Event]
    ON [dbo].[EventItemFulfillment]([PK_Event] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventItemFulfillment_PK_ShippingMethod]
    ON [dbo].[EventItemFulfillment]([PK_ShippingMethod] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventItemFulfillment_PK_EventMarketLocation]
    ON [dbo].[EventItemFulfillment]([PK_EventMarketLocation] ASC);

