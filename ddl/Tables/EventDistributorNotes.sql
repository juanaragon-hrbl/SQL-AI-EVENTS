CREATE TABLE [dbo].[EventDistributorNotes] (
    [PK_EventDistributorNote] INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Distributor]          INT             NOT NULL,
    [Notes]                   NVARCHAR (1000) NULL,
    [CreatedDateUTC]          DATETIME        DEFAULT (getutcdate()) NULL,
    [CreatedBy]               VARCHAR (50)    DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]         DATETIME        DEFAULT (getutcdate()) NULL,
    [ModifiedBy]              VARCHAR (50)    DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]                INT             NOT NULL,
    [PK_EventNoteType]        INT             NOT NULL,
    [PK_NoteFiles]            INT             NULL,
    CONSTRAINT [EventDistributorNotes_PK] PRIMARY KEY CLUSTERED ([PK_EventDistributorNote] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventEventDistributorNotes_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [EventNoteTypesEventDistributorNotes_FK] FOREIGN KEY ([PK_EventNoteType]) REFERENCES [dbo].[EventNoteTypes] ([PK_EventNoteType])
);




GO
CREATE NONCLUSTERED INDEX [IX_EventDistributorNotes_PK_Distributor]
    ON [dbo].[EventDistributorNotes]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventDistributorNotes_PK_Event]
    ON [dbo].[EventDistributorNotes]([PK_Event] ASC) WITH (FILLFACTOR = 80);

