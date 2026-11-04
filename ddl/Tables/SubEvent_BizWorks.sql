CREATE TABLE [dbo].[SubEvent_BizWorks] (
    [PK_SubEvent]            INT            NOT NULL,
    [CreatedDate]            DATETIME       NULL,
    [CreatedBy]              VARCHAR (50)   NULL,
    [ModifiedDate]           DATETIME       NULL,
    [ModifiedBy]             VARCHAR (50)   NULL,
    [PK_Event]               INT            NULL,
    [SubEventNumber]         INT            NULL,
    [SubEventName]           VARCHAR (200)  NULL,
    [Location]               NVARCHAR (300) NULL,
    [LocalName]              NVARCHAR (300) NULL,
    [BeginTime]              DATETIME       NULL,
    [EndTime]                DATETIME       NULL,
    [IncludeInBizworkReport] BIT            CONSTRAINT [DF__SubEvent___Inclu__5073458F] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_SubEvent_BizWorks_PK_SubEvent] PRIMARY KEY CLUSTERED ([PK_SubEvent] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_SubEvent_BizWorks_PK_Event]
    ON [dbo].[SubEvent_BizWorks]([PK_Event] ASC) WITH (FILLFACTOR = 80);

