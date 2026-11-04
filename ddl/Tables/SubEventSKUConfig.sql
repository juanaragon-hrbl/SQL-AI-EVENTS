CREATE TABLE [dbo].[SubEventSKUConfig] (
    [PK_SubEventSKUConfig] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]       DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]            VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]      DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]           VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_SubEvent]          INT          NOT NULL,
    [PK_Event]             INT          NOT NULL,
    [PK_EventSKU]          INT          NOT NULL,
    [IsSKUExclusive]       BIT          DEFAULT ((1)) NULL,
    CONSTRAINT [SubEventSKUConfig_PK] PRIMARY KEY CLUSTERED ([PK_SubEventSKUConfig] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventSKUSubEventSKUConfig_FK] FOREIGN KEY ([PK_EventSKU]) REFERENCES [dbo].[EventSKU] ([PK_EventSKU]),
    CONSTRAINT [EventSubEventSKUConfig_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [SubEventSubEventSKUConfig_FK] FOREIGN KEY ([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent]),
    CONSTRAINT [IX_SubEventSKUConfig_Unique] UNIQUE NONCLUSTERED ([PK_SubEvent] ASC, [PK_Event] ASC, [PK_EventSKU] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventSKUConfig_PK_Event]
    ON [dbo].[SubEventSKUConfig]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventSKUConfig_PK_SubEvent]
    ON [dbo].[SubEventSKUConfig]([PK_SubEvent] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventSKUConfig_PK_EventSKU]
    ON [dbo].[SubEventSKUConfig]([PK_EventSKU] ASC) WITH (FILLFACTOR = 80);

