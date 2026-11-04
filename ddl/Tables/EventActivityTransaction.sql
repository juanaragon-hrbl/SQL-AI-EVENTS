CREATE TABLE [dbo].[EventActivityTransaction] (
    [PK_EventActivityTransaction] INT             IDENTITY (1, 1) NOT NULL,
    [PK_EventActivity]            INT             NOT NULL,
    [PK_TransactionStatus]        INT             NOT NULL,
    [DistributorID]               VARCHAR (30)    NOT NULL,
    [TotalQty]                    INT             NOT NULL,
    [CompQty]                     INT             NOT NULL,
    [TotalPrice]                  NUMERIC (17, 4) CONSTRAINT [DF_EventActivityTransaction_TotalPrice] DEFAULT ((0)) NOT NULL,
    [ConfirmationNumber]          NVARCHAR (50)   NULL,
    [Timeout]                     DATETIME        NOT NULL,
    [ManualOverride]              BIT             CONSTRAINT [DF_EventActivityTransaction_ManualOverride] DEFAULT ((0)) NOT NULL,
    [OverrideBy]                  NVARCHAR (50)   NULL,
    [ErrorMsg]                    NVARCHAR (1000) NULL,
    [CreatedUTC]                  SMALLDATETIME   CONSTRAINT [DF_EventActivityTransaction_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                   NVARCHAR (50)   CONSTRAINT [DF_EventActivityTransaction_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC]                 SMALLDATETIME   CONSTRAINT [DF_EventActivityTransaction_ModifiedUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                  NVARCHAR (50)   CONSTRAINT [DF_EventActivityTransaction_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventActivityTransaction] PRIMARY KEY CLUSTERED ([PK_EventActivityTransaction] ASC),
    CONSTRAINT [FK_EventActivityTransaction_EventActivity] FOREIGN KEY ([PK_EventActivity]) REFERENCES [dbo].[EventActivity] ([PK_EventActivity]),
    CONSTRAINT [FK_EventActivityTransaction_TransactionStatus] FOREIGN KEY ([PK_TransactionStatus]) REFERENCES [dbo].[TransactionStatus] ([PK_TransactionStatus])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityTransaction_DistributorID]
    ON [dbo].[EventActivityTransaction]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityTransaction_PK_EventActivity]
    ON [dbo].[EventActivityTransaction]([PK_EventActivity] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityTransaction_PK_TransactionStatus]
    ON [dbo].[EventActivityTransaction]([PK_TransactionStatus] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityTransactionAudit_PK_EventActivityTransaction]
    ON [dbo].[EventActivityTransaction]([PK_EventActivityTransaction] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivityTransactionAudit_PK_TransactionStatus]
    ON [dbo].[EventActivityTransaction]([PK_TransactionStatus] ASC) WITH (FILLFACTOR = 80);

