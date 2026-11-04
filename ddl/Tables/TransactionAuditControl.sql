CREATE TABLE [dbo].[TransactionAuditControl] (
    [PK_TransactionAuditControl] SMALLINT      IDENTITY (1, 1) NOT NULL,
    [AuditType]                  VARCHAR (64)  NOT NULL,
    [AuditOn]                    BIT           NOT NULL,
    [CreatedUTC]                 SMALLDATETIME CONSTRAINT [DF_TransactionAuditControl_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                  VARCHAR (50)  CONSTRAINT [DF_TransactionAuditControl_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC]                SMALLDATETIME CONSTRAINT [DF_TransactionAuditControl_ModifiedUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                 VARCHAR (50)  CONSTRAINT [DF_TransactionAuditControl_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_TransactionAuditControl] PRIMARY KEY CLUSTERED ([PK_TransactionAuditControl] ASC)
);

