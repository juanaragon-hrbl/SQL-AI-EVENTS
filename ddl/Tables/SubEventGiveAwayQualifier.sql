CREATE TABLE [dbo].[SubEventGiveAwayQualifier] (
    [PK_SubEventGiveAwayQualifier] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Distributor]               INT           NOT NULL,
    [PK_Event]                     INT           NOT NULL,
    [Pk_SubEvent]                  INT           NOT NULL,
    [CreatedDateUTC]               SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                    NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]              SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                   NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [Quantity]                     INT           NOT NULL,
    [RemovedUTC]                   SMALLDATETIME DEFAULT ('2049-12-31') NOT NULL,
    CONSTRAINT [PK_SubEventGiveAwayQualifier] PRIMARY KEY CLUSTERED ([PK_SubEventGiveAwayQualifier] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [SubEventGiveAwayQualifier_Event_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [SubEventGiveAwayQualifier_SubEvent_FK] FOREIGN KEY ([Pk_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventGiveAwayQualifier_PK_Event]
    ON [dbo].[SubEventGiveAwayQualifier]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventGiveAwayQualifier_PK_Distributor]
    ON [dbo].[SubEventGiveAwayQualifier]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventGiveAwayQualifier_PK_SubEvent]
    ON [dbo].[SubEventGiveAwayQualifier]([Pk_SubEvent] ASC) WITH (FILLFACTOR = 80);

