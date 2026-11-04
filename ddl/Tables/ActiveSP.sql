CREATE TABLE [dbo].[ActiveSP] (
    [ActiveSPID]     INT          IDENTITY (1, 1) NOT NULL,
    [nDistributorID] INT          NULL,
    [nIsQualifier]   BIT          DEFAULT ((0)) NULL,
    [SP_Qual]        DATETIME     NULL,
    [CurrentYear]    INT          NULL,
    [CurrentMonth]   VARCHAR (20) NULL,
    [OneMonth]       MONEY        NULL,
    [TwoMonth]       MONEY        NULL,
    [ThreeMonth]     MONEY        NULL,
    [Processed]      BIT          DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([ActiveSPID] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_ActiveSP_nDistributorID]
    ON [dbo].[ActiveSP]([nDistributorID] ASC) WITH (FILLFACTOR = 80);

