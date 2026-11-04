CREATE TABLE [dbo].[EventsRegistration_BizWorks] (
    [PK_EventsRegistration] INT             NOT NULL,
    [PK_Distributor_EDW]    INT             NOT NULL,
    [PK_Distributor]        INT             CONSTRAINT [DF__EventsReg__PK_Di__16BD0E59] DEFAULT ((0)) NULL,
    [DistributorID]         VARCHAR (20)    NULL,
    [FirstName]             NVARCHAR (40)   NULL,
    [LastName]              NVARCHAR (40)   NULL,
    [Phones]                VARCHAR (100)   NULL,
    [EmailAddress]          VARCHAR (100)   NULL,
    [IsPrimaryGuest]        BIT             NULL,
    [HasCheckedIn]          BIT             NULL,
    [CreatedDateUTC]        DATETIME        NULL,
    [IsDistributor]         BIT             NULL,
    [CreatedBy]             VARCHAR (50)    NULL,
    [UnRegister]            BIT             NULL,
    [ModifiedDateUTC]       DATETIME        NULL,
    [IsPreRegistered]       BIT             NULL,
    [ModifiedBy]            VARCHAR (50)    NULL,
    [DistributorTeam]       VARCHAR (10)    NULL,
    [PK_EventTicket]        INT             NULL,
    [PK_Event]              INT             NULL,
    [Registered]            INT             NULL,
    [DSPreferredname]       NVARCHAR (1000) NULL,
    CONSTRAINT [PK_EventsRegistration_BizWorks_PK_EventsRegistration] PRIMARY KEY CLUSTERED ([PK_EventsRegistration] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_BizWorks_ModifiedDateUTC]
    ON [dbo].[EventsRegistration_BizWorks]([ModifiedDateUTC] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_BizWorks_PK_EventTicket]
    ON [dbo].[EventsRegistration_BizWorks]([PK_EventTicket] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_BizWorks_PK_Event]
    ON [dbo].[EventsRegistration_BizWorks]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_BizWorks_PK_Distributor]
    ON [dbo].[EventsRegistration_BizWorks]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_BizWorks_LastName]
    ON [dbo].[EventsRegistration_BizWorks]([LastName] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_BizWorks_FirstName]
    ON [dbo].[EventsRegistration_BizWorks]([FirstName] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_BizWorks_DistributorID]
    ON [dbo].[EventsRegistration_BizWorks]([DistributorID] ASC) WITH (FILLFACTOR = 80);

