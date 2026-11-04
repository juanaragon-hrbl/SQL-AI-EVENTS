CREATE TABLE [dbo].[EventCoordinatorDetail] (
    [PK_EventCoordinatorDetail] INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Event]                  INT            NOT NULL,
    [CreatedDistributorID]      VARCHAR (10)   NULL,
    [CoordinatorID]             VARCHAR (10)   NULL,
    [CoordinatorName]           NVARCHAR (250) NULL,
    [CoordinatorPhone]          NVARCHAR (100) NULL,
    [CoordinatorEmail]          NVARCHAR (200) NULL,
    [CreatedDateUTC]            SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                 NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]           SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CoordinatorTitle]          NVARCHAR (100) NULL,
    [CoordinatorTeamLevel]      NVARCHAR (100) NULL,
    [CoordinatorWebsite]        NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_EventCoordinatorDetail] PRIMARY KEY CLUSTERED ([PK_EventCoordinatorDetail] ASC),
    CONSTRAINT [EventCoordinatorDetailEvent_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventCoordinatorDetail_PK_Event]
    ON [dbo].[EventCoordinatorDetail]([PK_Event] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventCoordinatorDetail_CoordinatorID]
    ON [dbo].[EventCoordinatorDetail]([CoordinatorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventCoordinatorDetail_CreatedDistributorID]
    ON [dbo].[EventCoordinatorDetail]([CreatedDistributorID] ASC) WITH (FILLFACTOR = 80);

