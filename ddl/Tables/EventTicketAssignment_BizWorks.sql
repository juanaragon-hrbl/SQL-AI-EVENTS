CREATE TABLE [dbo].[EventTicketAssignment_BizWorks] (
    [PK_EventTicketAssignment] INT          NOT NULL,
    [PK_FromDistributor_EDW]   INT          NOT NULL,
    [PK_ToDistributor_EDW]     INT          NOT NULL,
    [FromDistributorID]        VARCHAR (20) NOT NULL,
    [ToDistributorID]          VARCHAR (20) NOT NULL,
    [PK_FromDistributor]       INT          CONSTRAINT [DF__EventTick__PK_Fr__19997B04] DEFAULT ((0)) NOT NULL,
    [PK_ToDistributor]         INT          CONSTRAINT [DF__EventTick__PK_To__1A8D9F3D] DEFAULT ((0)) NOT NULL,
    [CreatedDate]              DATETIME     NULL,
    [CreatedBy]                VARCHAR (50) NULL,
    [ModifiedDate]             DATETIME     NULL,
    [ModifiedBy]               VARCHAR (50) NULL,
    [Ticketed]                 INT          NOT NULL,
    [ValidFromDate]            DATETIME     NULL,
    [ValidToDate]              DATETIME     NULL,
    [PK_Event]                 INT          NULL,
    [PK_EventSKU]              INT          NULL,
    [SKUCode]                  VARCHAR (10) NULL,
    [PK_SKUPurchased]          INT          NULL,
    CONSTRAINT [PK_EventTicketAssignment_BizWorks_PK_EventTicketAssignment] PRIMARY KEY CLUSTERED ([PK_EventTicketAssignment] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_BizWorks_Include]
    ON [dbo].[EventTicketAssignment_BizWorks]([PK_ToDistributor] ASC)
    INCLUDE([PK_Event], [ToDistributorID], [SKUCode]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_BizWorks_PK_Event]
    ON [dbo].[EventTicketAssignment_BizWorks]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_BizWorks_ToDistributorID]
    ON [dbo].[EventTicketAssignment_BizWorks]([ToDistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_BizWorks_FromDistributorID]
    ON [dbo].[EventTicketAssignment_BizWorks]([FromDistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_BizWorks_PK_ToDistributor]
    ON [dbo].[EventTicketAssignment_BizWorks]([PK_ToDistributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_BizWorks_PK_FromDistributor]
    ON [dbo].[EventTicketAssignment_BizWorks]([PK_FromDistributor] ASC) WITH (FILLFACTOR = 80);

