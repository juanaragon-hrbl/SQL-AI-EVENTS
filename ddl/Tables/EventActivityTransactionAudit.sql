CREATE TABLE [dbo].[EventActivityTransactionAudit] (
    [PK_EventActivityTransactionAudit] INT             IDENTITY (1, 1) NOT NULL,
    [PK_EventActivityTransaction]      INT             NOT NULL,
    [PK_TransactionStatus]             INT             NOT NULL,
    [TotalQty]                         INT             NOT NULL,
    [CompQty]                          INT             NOT NULL,
    [TotalPrice]                       NUMERIC (17, 4) NOT NULL,
    [CreatedUTC]                       SMALLDATETIME   CONSTRAINT [DF_EventActivityTransactionAudit_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                        NVARCHAR (50)   CONSTRAINT [DF_EventActivityTransactionAudit_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventActivityTransactionAudit] PRIMARY KEY CLUSTERED ([PK_EventActivityTransactionAudit] ASC),
    CONSTRAINT [FK_EventActivityTransactionAudit_TransactionStatus] FOREIGN KEY ([PK_TransactionStatus]) REFERENCES [dbo].[TransactionStatus] ([PK_TransactionStatus])
);

