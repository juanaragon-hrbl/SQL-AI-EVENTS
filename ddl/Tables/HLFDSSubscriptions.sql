CREATE TABLE [dbo].[HLFDSSubscriptions] (
    [PK_HLFDSSubscriptions] INT             IDENTITY (1, 1) NOT NULL,
    [nDistributorID]        INT             NOT NULL,
    [DistributorID]         VARCHAR (10)    NOT NULL,
    [FirstName]             NVARCHAR (1000) NULL,
    [LastName]              NVARCHAR (1000) NULL,
    [DSType]                CHAR (2)        NULL,
    [Team]                  CHAR (2)        NULL,
    [ApplicationDate]       DATETIME        NULL,
    [ApplicationMonth]      VARCHAR (100)   NULL,
    [ApplicationYear]       INT             NULL,
    [COP]                   CHAR (2)        NULL,
    [CountryofResidence]    CHAR (2)        NULL,
    [Phone]                 NVARCHAR (100)  NULL,
    [City]                  NVARCHAR (500)  NULL,
    [State]                 NVARCHAR (250)  NULL,
    [PostalCode]            NVARCHAR (250)  NULL,
    [EmailAddress]          NVARCHAR (1000) NULL,
    [Subscription]          NVARCHAR (MAX)  NULL,
    [SubscriptionKey]       NVARCHAR (4000) NULL,
    [CreatedDateUTC]        SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]             NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]       SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]            NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_HLFDSSubscriptions] PRIMARY KEY CLUSTERED ([PK_HLFDSSubscriptions] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_HLFDSSubscriptions_DistributorID]
    ON [dbo].[HLFDSSubscriptions]([DistributorID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_HLFDSSubscriptions_EmailAddress]
    ON [dbo].[HLFDSSubscriptions]([EmailAddress] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_HLFDSSubscriptions_nDistributorID]
    ON [dbo].[HLFDSSubscriptions]([nDistributorID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_HLFDSSubscriptions_SubscriptionKey]
    ON [dbo].[HLFDSSubscriptions]([SubscriptionKey] ASC);

