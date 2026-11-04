CREATE TABLE [dbo].[SubEvent] (
    [PK_SubEvent]            INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]         DATETIME       DEFAULT (getutcdate()) NULL,
    [CreatedBy]              VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]        DATETIME       DEFAULT (getutcdate()) NULL,
    [ModifiedBy]             VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]               INT            NOT NULL,
    [PK_SubEventType]        INT            NOT NULL,
    [MaxCapacity]            INT            DEFAULT ((1)) NOT NULL,
    [ExpectedCapacity]       INT            DEFAULT ((1)) NOT NULL,
    [SubEventName]           VARCHAR (200)  NULL,
    [SubEventNumber]         INT            NULL,
    [SubEventFormula]        VARCHAR (2000) NULL,
    [KeepDNR]                BIT            DEFAULT ((1)) NULL,
    [KeepDeleted]            BIT            DEFAULT ((0)) NULL,
    [SubEventNamePositionID] INT            NULL,
    [Location]               NVARCHAR (300) NULL,
    [LocalName]              NVARCHAR (300) NULL,
    [BeginTime]              DATETIME       NULL,
    [EndTime]                DATETIME       NULL,
    [PK_SubEventGroup]       INT            NULL,
    [isTrackingVisible]      BIT            DEFAULT ((1)) NULL,
    [IsMainEventQual]        BIT            DEFAULT ((0)) NULL,
    [CanProcessQual]         BIT            DEFAULT ((1)) NULL,
    [IsBBBreakDownReqd]      BIT            DEFAULT ((0)) NULL,
    [IsDiamondRptReqd]       BIT            DEFAULT ((0)) NULL,
    [IncludeInBizworkReport] BIT            DEFAULT ((0)) NULL,
    [EvalOrder]         INT            NULL,
    CONSTRAINT [SubEvent_PK] PRIMARY KEY CLUSTERED ([PK_SubEvent] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventSubEvent_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [SubEventGroup_SubEvent_FK] FOREIGN KEY ([PK_SubEventGroup]) REFERENCES [dbo].[SubEventGroup] ([PK_SubEventGroup]),
    CONSTRAINT [SubEventTypeSubEvent_FK] FOREIGN KEY ([PK_SubEventType]) REFERENCES [dbo].[SubEventType] ([PK_SubEventType])
);


GO
CREATE NONCLUSTERED INDEX [IX_SubEvent_PK_Event]
    ON [dbo].[SubEvent]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEvent_PK_SubEventType]
    ON [dbo].[SubEvent]([PK_SubEventType] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEvent_SubEventNumber]
    ON [dbo].[SubEvent]([SubEventNumber] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEvent_PK_Event_SubEventNumber]
    ON [dbo].[SubEvent]([PK_Event] ASC, [SubEventNumber] ASC) WITH (FILLFACTOR = 80);

