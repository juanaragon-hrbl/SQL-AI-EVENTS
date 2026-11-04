CREATE TABLE [dbo].[ASQQualification_IDsForQual] (
    [ASQQualification_IDsForQual] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CreatedDate]                 DATETIME      DEFAULT (getutcdate()) NULL,
    [Qual_Pin]                    SMALLDATETIME NULL,
    [PK_FirstUplineSP]            INT           NULL,
    [FirstUplineSPID]             VARCHAR (10)  NULL,
    [PK_Distributor]              INT           NULL,
    [DistributorID]               VARCHAR (10)  NULL,
    PRIMARY KEY CLUSTERED ([ASQQualification_IDsForQual] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_ASQQualification_IDsForQual_DistributorID]
    ON [dbo].[ASQQualification_IDsForQual]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_ASQQualification_IDsForQual_PK_Distributor]
    ON [dbo].[ASQQualification_IDsForQual]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_ASQQualification_IDsForQual_FirstUplineSPID]
    ON [dbo].[ASQQualification_IDsForQual]([FirstUplineSPID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_ASQQualification_IDsForQual_PK_FirstUplineSP]
    ON [dbo].[ASQQualification_IDsForQual]([PK_FirstUplineSP] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_ASQQualification_IDsForQual_Qual_Pin]
    ON [dbo].[ASQQualification_IDsForQual]([Qual_Pin] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_ASQQualification_IDsForQual_CreatedDate]
    ON [dbo].[ASQQualification_IDsForQual]([CreatedDate] ASC) WITH (FILLFACTOR = 80);

