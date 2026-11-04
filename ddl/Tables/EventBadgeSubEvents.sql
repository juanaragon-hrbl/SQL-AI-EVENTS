CREATE TABLE [dbo].[EventBadgeSubEvents] (
    [PK_EventBadgeSubEvent] INT            IDENTITY (1, 1) NOT NULL,
    [PK_EventBadgePrinting] INT            NOT NULL,
    [PK_Event]              INT            NOT NULL,
    [PK_SubEvent]           INT            NOT NULL,
    [PK_Distributor]        INT            NOT NULL,
    [DistributorID]         VARCHAR (20)   NOT NULL,
    [SubEventDisplayName]   NVARCHAR (100) NULL,
    [SequenceNo]            INT            NULL,
    [CreatedDateUTC]        SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]             NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]       SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]            NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventBadgeSubEvent] PRIMARY KEY CLUSTERED ([PK_EventBadgeSubEvent] ASC),
    CONSTRAINT [EventBadgeSubEvents_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [EventBadgeSubEvents_PK_EventBadgePrinting] FOREIGN KEY ([PK_EventBadgePrinting]) REFERENCES [dbo].[EventBadgePrinting] ([PK_EventBadgePrinting]),
    CONSTRAINT [EventBadgeSubEvents_PK_SubEvent] FOREIGN KEY ([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);
GO

CREATE NONCLUSTERED INDEX [IX_EventBadgeSubEvents_PK_SubEvent] ON [dbo].[EventBadgeSubEvents]([PK_SubEvent] ASC);
GO