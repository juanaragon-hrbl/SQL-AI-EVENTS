CREATE TABLE [dbo].[SubEventQualification] (
    [PK_SubEventQualification] INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]           DATETIME       DEFAULT (getutcdate()) NULL,
    [CreatedBy]                VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]          DATETIME       DEFAULT (getutcdate()) NULL,
    [ModifiedBy]               VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]                 INT            NULL,
    [PK_SubEvent]              INT            NULL,
    [PK_Qualification]         INT            NULL,
    [IsQualMember]             BIT            DEFAULT ((1)) NULL,
    [ValidFromDateUTC]         SMALLDATETIME  NULL,
    [ValidThroughDateUTC]      SMALLDATETIME  NULL,
    [QualificationValue]       VARCHAR (500)  NULL,
    [SortOrder]                INT            NULL,
    [SubEventQualFilter]       VARCHAR (100)  NULL,
    [SubEventQualTxt]          VARCHAR (4000) NULL,
    [PK_PromotionAccelerator]  INT            NULL,
    [PK_SubEventQualGroup]     INT            NULL,
    [ExtValidFromDate]         SMALLDATETIME  NULL,
    [ExtValidThroughDate]      SMALLDATETIME  NULL,
    [DateType]                 VARCHAR (30)   NULL,
    [MetricType]               VARCHAR (10)   NULL,
    [LevelType]                VARCHAR (10)   NULL,
    [BeginLevel]               SMALLINT       NULL,
    [EndLevel]                 SMALLINT       NULL,
    [ExtSubEventQualFilter]    VARCHAR (500)  NULL,
    [MonthFrequency]           SMALLINT       NULL,
    [CountLimit]               SMALLINT       NULL,
    [CountMax]                 SMALLINT       NULL,
    [QId]                      INT            NULL,
    CONSTRAINT [SubEventQualfication_PK] PRIMARY KEY CLUSTERED ([PK_SubEventQualification] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventSubEventQualfication_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [PromotionAcceleratorSubEventQualfication_FK] FOREIGN KEY ([PK_PromotionAccelerator]) REFERENCES [dbo].[PromotionAccelerator] ([PK_PromotionAccelerator]),
    CONSTRAINT [QualificationSubEventQualfication_FK] FOREIGN KEY ([PK_Qualification]) REFERENCES [dbo].[Qualification] ([PK_Qualification]),
    CONSTRAINT [SubEventQualGroupsSubEventQualfication_FK] FOREIGN KEY ([PK_SubEventQualGroup]) REFERENCES [dbo].[SubEventQualGroups] ([PK_SubEventQualGroup]),
    CONSTRAINT [SubEventSubEventQualfication_FK] FOREIGN KEY ([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualfication_IsQualMember]
    ON [dbo].[SubEventQualification]([IsQualMember] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualfication_PK_Event]
    ON [dbo].[SubEventQualification]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualfication_PK_Qualification]
    ON [dbo].[SubEventQualification]([PK_Qualification] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualfication_PK_SubEvent]
    ON [dbo].[SubEventQualification]([PK_SubEvent] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualfication_SortOrder]
    ON [dbo].[SubEventQualification]([SortOrder] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualfication_ValidFromDate]
    ON [dbo].[SubEventQualification]([ValidFromDateUTC] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualfication_ValidThroughDate]
    ON [dbo].[SubEventQualification]([ValidThroughDateUTC] ASC) WITH (FILLFACTOR = 80);

