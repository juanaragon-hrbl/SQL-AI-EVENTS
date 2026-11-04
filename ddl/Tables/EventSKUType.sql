CREATE TABLE [dbo].[EventSKUType] (
    [PK_EventSKUType]  INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [EventSKUTypeDesc] VARCHAR (100) NOT NULL,
    [CreatedDateUTC]   DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]        VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]  DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [EventSKUType_PK] PRIMARY KEY CLUSTERED ([PK_EventSKUType] ASC) WITH (FILLFACTOR = 80)
);

