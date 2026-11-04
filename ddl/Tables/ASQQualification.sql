CREATE TABLE [dbo].[ASQQualification] (
    [PK_ASQQualification] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CreatedDate]         DATETIME      DEFAULT (getutcdate()) NULL,
    [PK_Distributor]      INT           NULL,
    [DistributorID]       VARCHAR (10)  NULL,
    [Qual_SP]             SMALLDATETIME NULL,
    [PinType]             INT           NULL,
    [Qual_Pin]            SMALLDATETIME NULL,
    PRIMARY KEY CLUSTERED ([PK_ASQQualification] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_ASQQualification_CreatedDate]
    ON [dbo].[ASQQualification]([CreatedDate] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_ASQQualification_Qual_Pin]
    ON [dbo].[ASQQualification]([Qual_Pin] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_ASQQualification_PinType]
    ON [dbo].[ASQQualification]([PinType] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_ASQQualification_Qual_SP]
    ON [dbo].[ASQQualification]([Qual_SP] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_ASQQualification_DistributorID]
    ON [dbo].[ASQQualification]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_ASQQualification_PK_Distributor]
    ON [dbo].[ASQQualification]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);

