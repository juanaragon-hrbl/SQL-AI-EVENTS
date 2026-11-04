CREATE TABLE [dbo].[BrazilActiveSP] (
    [PK_BrazilActiveSP]      INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [nDistributorID]         INT      NULL,
    [nIsQualifier]           BIT      CONSTRAINT [DF__BrazilAct__nIsQu__01CDDB8C] DEFAULT ((0)) NULL,
    [SP_Qual]                DATETIME NULL,
    [LastDateProcessed]      DATETIME NULL,
    [ActiveSupervisor]       DATETIME NULL,
    [ActiveSupervisorSilver] DATETIME NULL,
    [ActiveSupervisorGold]   DATETIME NULL,
    CONSTRAINT [PK__BrazilAc__292C802F7FE5931A] PRIMARY KEY CLUSTERED ([PK_BrazilActiveSP] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_BrazilActiveSP_nDistributorID]
    ON [dbo].[BrazilActiveSP]([nDistributorID] ASC) WITH (FILLFACTOR = 80);

