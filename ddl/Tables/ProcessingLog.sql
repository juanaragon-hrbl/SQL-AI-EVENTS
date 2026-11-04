CREATE TABLE [dbo].[ProcessingLog] (
    [PK_ProcessingLog]    INT           IDENTITY (1, 1) NOT NULL,
    [CreatedDateUTC]      DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]           VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]     DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]          VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ProcedureName]       VARCHAR (100) NULL,
    [ProcedureParameters] VARCHAR (100) NULL,
    [StartTime]           DATETIME      NULL,
    [EndTime]             DATETIME      NULL,
    [RunTime]             VARCHAR (10)  NULL,
    CONSTRAINT [ProcessingLog_PK] PRIMARY KEY CLUSTERED ([PK_ProcessingLog] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IX_ProcessingLog_ProcedureName]
    ON [dbo].[ProcessingLog]([ProcedureName] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_ProcessingLog_ProcedureParameters]
    ON [dbo].[ProcessingLog]([ProcedureParameters] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = ROW);


GO
CREATE NONCLUSTERED INDEX [IX_ProcessingLog_RunTime]
    ON [dbo].[ProcessingLog]([RunTime] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

