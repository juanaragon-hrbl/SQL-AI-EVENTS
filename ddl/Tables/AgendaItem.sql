CREATE TABLE [dbo].[AgendaItem] (
    [PK_AgendaItem]      INT            IDENTITY (1, 1) NOT NULL,
    [PK_Agenda]          INT            NULL,
    [PK_AgendaItemType]  INT            NULL,
    [SubEventNumber]     VARCHAR (200)  NULL,
    [DisplayDescription] NVARCHAR (500)  NULL,
    [DisplayTime]        NVARCHAR (200) NULL,
    [DisplayLocation]    NVARCHAR (300) NULL,
    [DisplayAttire]      NVARCHAR (100) NULL,
    [TeamLevelRequired]  VARCHAR (50)   NULL,
    [IsSubHeader]        BIT            DEFAULT ((0)) NULL,
    [IsImage]            BIT            NULL,
    [Width]              INT            DEFAULT ((0)) NULL,
    [Height]             INT            DEFAULT ((0)) NULL,
    [XPos]               INT            DEFAULT ((0)) NULL,
    [YPos]               INT            DEFAULT ((0)) NULL,
    [LocalStartDate]     DATETIME       NULL,
    [LocalEndDate]       DATETIME       NULL,
    [SortOrder]          INT            NULL,
    [CreatedUTC]         DATETIME       DEFAULT (getutcdate()) NULL,
    [CreatedBy]          VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [UpdatedUTC]         DATETIME       DEFAULT (getutcdate()) NULL,
    [UpdatedBy]          VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [IsSubEvent]         BIT            NULL,
    [PK_SubEvent]        INT            NULL,
    PRIMARY KEY CLUSTERED ([PK_AgendaItem] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_AgendaItem_PK_Agenda]
    ON [dbo].[AgendaItem]([PK_Agenda] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_AgendaItem_PK_AgendaItemType]
    ON [dbo].[AgendaItem]([PK_AgendaItemType] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_AgendaItem_LocalStartDate]
    ON [dbo].[AgendaItem]([LocalStartDate] ASC) WITH (FILLFACTOR = 80);

