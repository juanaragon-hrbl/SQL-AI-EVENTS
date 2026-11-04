CREATE TABLE [dbo].[SubEventQualifier_Extract] (
    [PK_SubEventQualifier_Extract] INT          IDENTITY (1, 1) NOT NULL,
    [CreatedDateUTC]               DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]                    VARCHAR (20) DEFAULT ('UsrSQLProd') NULL,
    [ModifiedDateUTC]              DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]                   VARCHAR (20) DEFAULT ('UsrSQLProd') NULL,
    [PK_Event]                     INT          NULL,
    [PK_SubEvent]                  INT          NULL,
    [PK_Distributor]               INT          NULL,
    [DistributorID]                VARCHAR (30) NULL,
    [QualDate]                     DATETIME     NULL,
    [AddedUTC]                     DATETIME     DEFAULT (getutcdate()) NULL,
    [RemovedUTC]                   DATETIME     NULL,
    [IsManualOverride]             BIT          NULL,
    [IsDeleted]                    BIT          NULL,
    [IsDNR]                        BIT          NULL,
    [IsType23]                     BIT          NULL,
    [Qualified]                    INT          NULL,
    [Quantity]                     INT          NULL,
    [ActionFlg]                    CHAR (1)     NULL,
    [Registered]                   BIT          DEFAULT ((0)) NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifiers_Extract_Composite]
    ON [dbo].[SubEventQualifier_Extract]([PK_Event] ASC, [PK_SubEvent] ASC, [PK_Distributor] ASC)
    INCLUDE([ActionFlg]);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifiers_Extract_ActionFlg]
    ON [dbo].[SubEventQualifier_Extract]([ActionFlg] ASC);

