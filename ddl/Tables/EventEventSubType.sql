CREATE TABLE [dbo].[EventEventSubType] (
    [PK_EventEventSubType] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Event]             INT           NOT NULL,
    [PK_EventType]         INT           NOT NULL,
    [PK_EventSubType]      INT           NOT NULL,
    [CreatedDateUTC]       SMALLDATETIME DEFAULT (getutcdate()) NULL,
    [CreatedBy]            NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]      SMALLDATETIME DEFAULT (getutcdate()) NULL,
    [ModifiedBy]           NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    PRIMARY KEY CLUSTERED ([PK_EventEventSubType] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventEventSubType_Event_EventType]
    ON [dbo].[EventEventSubType]([PK_Event] ASC, [PK_EventSubType] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventEventSubType_PK_EventType]
    ON [dbo].[EventEventSubType]([PK_EventType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventEventSubType_PK_EventSubType]
    ON [dbo].[EventEventSubType]([PK_EventSubType] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventEventSubType_PK_Event]
    ON [dbo].[EventEventSubType]([PK_Event] ASC) WITH (FILLFACTOR = 80);

