CREATE TABLE [dbo].[Event_BizWorks] (
    [PK_Event]               INT            NOT NULL,
    [EventName]              NVARCHAR (200) NULL,
    [EventTypeCode]          VARCHAR (3)    NULL,
    [EventType]              VARCHAR (25)   NULL,
    [EventStartDate]         SMALLDATETIME  NULL,
    [EventEndDate]           SMALLDATETIME  NULL,
    [QualPeriodStart]        SMALLDATETIME  NULL,
    [QualPeriodEnd]          SMALLDATETIME  NULL,
    [EventLocation]          NVARCHAR (300) NULL,
    [CreatedDate]            DATETIME       NULL,
    [CreatedBy]              VARCHAR (50)   NULL,
    [ModifiedDate]           DATETIME       NULL,
    [ModifiedBy]             VARCHAR (50)   NULL,
    [IsPublish]              BIT            NULL,
    [IsBizworkReportEnabled] BIT            CONSTRAINT [DF__Event_Biz__IsBiz__739A2436] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_Event_BizWorks_PK_Event] PRIMARY KEY CLUSTERED ([PK_Event] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_Event_BizWorks_EventEndDate]
    ON [dbo].[Event_BizWorks]([EventEndDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Event_BizWorks_EventStartDate]
    ON [dbo].[Event_BizWorks]([EventStartDate] ASC);

