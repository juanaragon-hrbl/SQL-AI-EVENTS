CREATE TABLE [dbo].[SubEventQualifier] (
    [PK_SubEventQualifier] BIGINT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]       DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]            VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]      DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]           VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]             INT           NOT NULL,
    [PK_SubEvent]          INT           NOT NULL,
    [PK_Distributor]       INT           NOT NULL,
    [DistributorID]        VARCHAR (30)  NULL,
    [QualDate]             SMALLDATETIME NULL,
    [AddedUTC]             SMALLDATETIME NULL,
    [RemovedUTC]           SMALLDATETIME NULL,
    [IsManualOverride]     BIT           DEFAULT ((0)) NOT NULL,
    [IsDeleted]            BIT           NULL,
    [IsDNR]                BIT           NULL,
    [IsType23]             BIT           NULL,
    [Qualified]            INT           DEFAULT ((1)) NOT NULL,
    [Quantity]             INT           DEFAULT ((0)) NULL,
    CONSTRAINT [SubEventQualifier_PK] PRIMARY KEY CLUSTERED ([PK_SubEventQualifier] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE),
    CONSTRAINT [EventSubEventQualifier_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [SubEventSubEventQualifier_FK] FOREIGN KEY ([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_AddedUTC]
    ON [dbo].[SubEventQualifier]([AddedUTC] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_IsManualOverride]
    ON [dbo].[SubEventQualifier]([IsManualOverride] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_PK_Distributor]
    ON [dbo].[SubEventQualifier]([PK_Distributor] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_RemovedUTC]
    ON [dbo].[SubEventQualifier]([RemovedUTC] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_DistributorID]
    ON [dbo].[SubEventQualifier]([DistributorID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_Qualified]
    ON [dbo].[SubEventQualifier]([Qualified] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_PK_Event]
    ON [dbo].[SubEventQualifier]([PK_Event] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_PK_Event_PK_SubEvent_Covering] 
	ON [dbo].[SubEventQualifier] ([PK_Event], [PK_SubEvent]) INCLUDE ([ModifiedDateUTC], [PK_Distributor], [RemovedUTC], [Qualified], [DistributorID]);

GO
CREATE NONCLUSTERED INDEX IX_SubEventQualifier_PK_Event_RemovedUTC_Qualified_Covering 
	ON [dbo].[SubEventQualifier]([PK_Event],[RemovedUTC],[Qualified]) INCLUDE ([PK_Distributor],[DistributorID]);

GO

CREATE NONCLUSTERED INDEX [IX_SubEventQualifier_PK_SubEvent] ON [dbo].[SubEventQualifier]([PK_SubEvent] ASC);
GO