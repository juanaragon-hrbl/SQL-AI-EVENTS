CREATE TABLE [dbo].[EventSchedule] (
    [PK_EventSchedule] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]   DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]        VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]  DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]         INT           NOT NULL,
    [PK_Schedule]      INT           NOT NULL,
    [BeginUTC]         SMALLDATETIME NULL,
    [EndUTC]           SMALLDATETIME NULL,
    CONSTRAINT [EventSchedule_PK] PRIMARY KEY CLUSTERED ([PK_EventSchedule] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventEventSchedule_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [ScheduleEventSchedule_FK] FOREIGN KEY ([PK_Schedule]) REFERENCES [dbo].[Schedule] ([PK_Schedule]),
    CONSTRAINT [EventSchedule_PK_Event_PK_Schedule] UNIQUE NONCLUSTERED ([PK_Event] ASC, [PK_Schedule] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventSchedule_BeginUTC]
    ON [dbo].[EventSchedule]([BeginUTC] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventSchedule_EndUTC]
    ON [dbo].[EventSchedule]([EndUTC] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventSchedule_PK_Event]
    ON [dbo].[EventSchedule]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventSchedule_PK_Schedule]
    ON [dbo].[EventSchedule]([PK_Schedule] ASC) WITH (FILLFACTOR = 80);

