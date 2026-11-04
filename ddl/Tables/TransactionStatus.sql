CREATE TABLE [dbo].[TransactionStatus] (
    [PK_TransactionStatus] INT           IDENTITY (1, 1) NOT NULL,
    [PK_Parent]            INT           NULL,
    [TransactionGroup]     VARCHAR (30)  NOT NULL,
    [StatusDesc]           VARCHAR (256) NOT NULL,
    [IsFinalState]         BIT           NOT NULL,
    [CreatedUTC]           SMALLDATETIME CONSTRAINT [DF_TransactionStatus_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]            VARCHAR (50)  CONSTRAINT [DF_TransactionStatus_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC]          SMALLDATETIME CONSTRAINT [DF_TransactionStatus_ModifiedUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]           VARCHAR (50)  CONSTRAINT [DF_TransactionStatus_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_TransactionStatus] PRIMARY KEY CLUSTERED ([PK_TransactionStatus] ASC),
    CONSTRAINT [FK_TransactionStatus_PK_Parent] FOREIGN KEY ([PK_Parent]) REFERENCES [dbo].[TransactionStatus] ([PK_TransactionStatus])
);


GO
CREATE NONCLUSTERED INDEX [IX_TransactionStatus_PK_Parent]
    ON [dbo].[TransactionStatus]([PK_Parent] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_TransactionStatus_StatusDesc]
    ON [dbo].[TransactionStatus]([StatusDesc] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_TransactionStatus_TransactionGroup]
    ON [dbo].[TransactionStatus]([TransactionGroup] ASC);

