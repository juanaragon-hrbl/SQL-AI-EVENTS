CREATE TABLE [dbo].[ErrorCode] (
    [PK_ErrorCode]    INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]  SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]       VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC] SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]      VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ErrorMsg]        VARCHAR (1000) NULL,
    CONSTRAINT [ErrorCode_PK] PRIMARY KEY CLUSTERED ([PK_ErrorCode] ASC) WITH (FILLFACTOR = 80)
);

