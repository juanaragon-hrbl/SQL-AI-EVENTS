CREATE TABLE [dbo].[AWT_BizWork_Qualifiers] (
    [PK_AWT_BizWork]     INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Distributor_EDW] INT           NULL,
    [PK_Distributor]     INT           CONSTRAINT [DF__AWT_BizWo__PK_Di__546E2DCD] DEFAULT ((0)) NULL,
    [DistributorID]      VARCHAR (10)  NULL,
    [AWTYear]            INT           NOT NULL,
    [DateAdded]          SMALLDATETIME NULL,
    [Qual_AWT]           SMALLDATETIME NULL,
    [CreatedDateUTC]     SMALLDATETIME NULL,
    [CreatedBy]          NVARCHAR (50) NOT NULL,
    [ModifiedDateUTC]    SMALLDATETIME NOT NULL,
    [ModifiedBy]         NVARCHAR (50) NOT NULL,
    CONSTRAINT [PK_AWT_BizWork] PRIMARY KEY CLUSTERED ([PK_AWT_BizWork] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_AWT_BizWork_Qualifiers_Qual_AWT]
    ON [dbo].[AWT_BizWork_Qualifiers]([Qual_AWT] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_BizWork_Qualifiers_DistributorID]
    ON [dbo].[AWT_BizWork_Qualifiers]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_BizWork_Qualifiers_PK_Distributor]
    ON [dbo].[AWT_BizWork_Qualifiers]([PK_Distributor] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_BizWork_Qualifiers_PK_Distributor_EDW]
    ON [dbo].[AWT_BizWork_Qualifiers]([PK_Distributor_EDW] ASC) WITH (FILLFACTOR = 80);

