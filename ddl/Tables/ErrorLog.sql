CREATE TABLE [dbo].[ErrorLog] (
    [PK_ErrorLog]       INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]    SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]         VARCHAR (100)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]   SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]        VARCHAR (100)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_TransactionKey] INT            NULL,
    [PK_ErrorCode]      INT            NULL,
    [SQLErrorCode]      VARCHAR (100)  NULL,
    [SQLErrorMsg]       VARCHAR (1000) NULL,
    [Program]           VARCHAR (100)  NULL,
    CONSTRAINT [ErrorLog_PK] PRIMARY KEY CLUSTERED ([PK_ErrorLog] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [ErrorCodeErrorLog_FK] FOREIGN KEY ([PK_ErrorCode]) REFERENCES [dbo].[ErrorCode] ([PK_ErrorCode])
);

