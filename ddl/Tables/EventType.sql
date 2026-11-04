CREATE TABLE [dbo].[EventType] (
    [PK_EventType]    INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]  DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]       VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [EventType]       VARCHAR (25) NULL,
    [EventTypeCode]   CHAR (3)     NULL,
    CONSTRAINT [EventType_PK] PRIMARY KEY CLUSTERED ([PK_EventType] ASC) WITH (FILLFACTOR = 80)
);

