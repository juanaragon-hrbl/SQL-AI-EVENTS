CREATE TABLE [dbo].[EventNoteTypes] (
    [PK_EventNoteType] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Description]      VARCHAR (200) NOT NULL,
    [CreatedDateUTC]   DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]        VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]  DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [EventNoteTypes_PK] PRIMARY KEY CLUSTERED ([PK_EventNoteType] ASC) WITH (FILLFACTOR = 80)
);

