CREATE TABLE [dbo].[LocalSubEventQualifier] (
    [PK_Event]          INT            NOT NULL,
    [PK_SubEvent]       INT            NOT NULL,
    [DistributorID]     VARCHAR (20)   NULL,
    [TimeZone]          VARCHAR (255)  NULL,
    [QualificationTime] DATETIME2 (7)  NULL,
    [Notes]             NVARCHAR (MAX) NULL,
    [CreatedUTC]        DATETIME       DEFAULT (getutcdate()) NULL,
    [CreatedBy]         VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [UpdatedUTC]        DATETIME       DEFAULT (getutcdate()) NULL,
    [UpdatedBy]         VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    FOREIGN KEY ([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);


GO
CREATE UNIQUE CLUSTERED INDEX [PK_ManualSubEventQualifier_Event_SubEvent_ID]
    ON [dbo].[LocalSubEventQualifier]([PK_Event] ASC, [PK_SubEvent] ASC, [DistributorID] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_LocalSubEventQualifier_PK_SubEvent] ON [dbo].[LocalSubEventQualifier]([PK_SubEvent] ASC);
GO
