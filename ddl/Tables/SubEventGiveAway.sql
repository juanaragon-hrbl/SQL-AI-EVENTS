CREATE TABLE [dbo].[SubEventGiveAway] (
    [PK_SubEventGiveAway]     INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Distributor]          INT            NOT NULL,
    [PK_Event]                INT            NOT NULL,
    [Pk_SubEvent]             INT            NOT NULL,
    [CreatedDateUTC]          SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]               NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]         SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]              NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [Quantity]                INT            NOT NULL,
    [GiveAwayID]              NVARCHAR (500) NULL,
    [DateOfGiveAway]          SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [RemovedUTC]              SMALLDATETIME  DEFAULT ('2049-12-31') NOT NULL,
    [ImageID]                 NVARCHAR (500) NULL,
    [PK_EventDistributorNote] INT            NULL,
    CONSTRAINT [PK_SubEventGiveAway] PRIMARY KEY CLUSTERED ([PK_SubEventGiveAway] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [SubEventGiveAway_Event_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [SubEventGiveAway_Note_FK] FOREIGN KEY ([PK_EventDistributorNote]) REFERENCES [dbo].[EventDistributorNotes] ([PK_EventDistributorNote]),
    CONSTRAINT [SubEventGiveAway_SubEvent_FK] FOREIGN KEY ([Pk_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventGiveAway_PK_Event]
    ON [dbo].[SubEventGiveAway]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventGiveAway_PK_Distributor]
    ON [dbo].[SubEventGiveAway]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventGiveAway_PK_SubEvent]
    ON [dbo].[SubEventGiveAway]([Pk_SubEvent] ASC) WITH (FILLFACTOR = 80);

