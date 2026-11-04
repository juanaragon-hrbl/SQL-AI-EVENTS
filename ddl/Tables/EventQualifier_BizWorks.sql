CREATE TABLE [dbo].[EventQualifier_BizWorks] (
    [PK_EventQualifier]  BIGINT       NOT NULL,
    [CreatedDate]        DATETIME     NULL,
    [CreatedBy]          VARCHAR (50) NULL,
    [ModifiedDate]       DATETIME     NULL,
    [ModifiedBy]         VARCHAR (50) NULL,
    [PK_Event]           INT          NULL,
    [PK_Distributor_EDW] INT          NULL,
    [PK_Distributor]     INT          CONSTRAINT [DF__EventQual__PK_Di__13E0A1AE] DEFAULT ((0)) NULL,
    [DistributorID]      VARCHAR (20) NULL,
    [Qualified]          INT          NULL,
    CONSTRAINT [PK_EventQualifier_BizWorks_PK_EventQualifier] PRIMARY KEY CLUSTERED ([PK_EventQualifier] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventQualifier_BizWorks_Include]
    ON [dbo].[EventQualifier_BizWorks]([PK_Distributor] ASC)
    INCLUDE([PK_Event], [DistributorID]);


GO
CREATE NONCLUSTERED INDEX [IX_EventQualifier_BizWorks_PK_Event]
    ON [dbo].[EventQualifier_BizWorks]([PK_Event] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventQualifier_BizWorks_DistributorID]
    ON [dbo].[EventQualifier_BizWorks]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventQualifier_BizWorks_PK_Distributor]
    ON [dbo].[EventQualifier_BizWorks]([PK_Distributor] ASC);

