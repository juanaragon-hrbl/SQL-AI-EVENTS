CREATE TABLE [dbo].[InLocalSubEventQualifier] (
    [PK_Event]          INT           NULL,
    [PK_SubEvent]       INT           NULL,
    [DistributorID]     VARCHAR (30)  NULL,
    [TimeZone]          VARCHAR (255) NULL,
    [QualificationTime] DATETIME2 (7) NULL,
    [Notes]             VARCHAR (MAX) NULL,
    [IsQualified]       BIT           NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_InLocalSubEventQualifier_pk_event_pk_subevent_distributor_id]
    ON [dbo].[InLocalSubEventQualifier]([PK_Event] ASC, [PK_SubEvent] ASC, [DistributorID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_InLocalSubEventQualifier_PK_Event_PK_SubEvent_DistributorID]
    ON [dbo].[InLocalSubEventQualifier]([PK_Event] ASC, [PK_SubEvent] ASC, [DistributorID] ASC);

