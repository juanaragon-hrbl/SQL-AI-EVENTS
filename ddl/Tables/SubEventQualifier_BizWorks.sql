CREATE TABLE [dbo].[SubEventQualifier_BizWorks] (
    [PK_SubEventQualifier] INT           NOT NULL,
    [CreatedDate]          DATETIME      NULL,
    [CreatedBy]            VARCHAR (50)  NULL,
    [ModifiedDate]         DATETIME      NULL,
    [ModifiedBy]           VARCHAR (50)  NULL,
    [PK_Event]             INT           NULL,
    [PK_SubEvent]          INT           NULL,
    [PK_Distributor_EDW]   INT           NULL,
    [PK_Distributor]       INT           CONSTRAINT [DF__SubEventQ__PK_Di__222EC105] DEFAULT ((0)) NULL,
    [DistributorID]        VARCHAR (20)  NULL,
    [QualDate]             SMALLDATETIME NULL,
    [AddedDate]            SMALLDATETIME NULL,
    [RemovedDate]          SMALLDATETIME NULL,
    [IsManualOverride]     BIT           NULL,
    [Qualified]            INT           NULL,
    CONSTRAINT [PK_SubEventQualifier_BizWorks_PK_SubEventQualifier] PRIMARY KEY CLUSTERED ([PK_SubEventQualifier] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_BizWorks_Include]
    ON [dbo].[SubEventQualifier_BizWorks]([PK_Distributor] ASC)
    INCLUDE([PK_Event], [PK_SubEvent], [DistributorID], [RemovedDate]);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_BizWorks_RemovedDate]
    ON [dbo].[SubEventQualifier_BizWorks]([RemovedDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_BizWorks_PK_SubEvent]
    ON [dbo].[SubEventQualifier_BizWorks]([PK_SubEvent] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_BizWorks_PK_Event]
    ON [dbo].[SubEventQualifier_BizWorks]([PK_Event] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_BizWorks_DistributorID]
    ON [dbo].[SubEventQualifier_BizWorks]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_BizWorks_PK_Distributor]
    ON [dbo].[SubEventQualifier_BizWorks]([PK_Distributor] ASC);

