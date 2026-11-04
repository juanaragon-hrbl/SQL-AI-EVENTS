CREATE TABLE [dbo].[wrk_DistributorTransferExtract] (
    [DistributorTransferExtractID] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [FromDS]                       VARCHAR (10) NOT NULL,
    [ToDS]                         VARCHAR (10) NOT NULL,
    [RollupDS]                     VARCHAR (10) NOT NULL,
    [SrcModifiedDate]              DATETIME     NULL,
    [CreatedBy]                    VARCHAR (50) CONSTRAINT [DF_wrk_DistributorTransferExtract_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [CreatedUTC]                   DATETIME     CONSTRAINT [DF_wrk_DistributorTransferExtract_CreatedUTC] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_wrk_DistributorTransferExtract] PRIMARY KEY CLUSTERED ([DistributorTransferExtractID] ASC)
);



