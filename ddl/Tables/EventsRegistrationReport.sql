CREATE TABLE [dbo].[EventsRegistrationReport] (
    [PK_EventsregistrationReport] INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [DistributorID]               VARCHAR (900)  NULL,
    [PK_Distributor]              INT            NULL,
    [PK_Event]                    INT            NULL,
    [DSName]                      VARCHAR (1000) NULL,
    [DSType]                      VARCHAR (10)   NULL,
    [IsPartnerAttending]          VARCHAR (10)   NULL,
    [PartnerName]                 VARCHAR (300)  NULL,
    [DSTeam]                      VARCHAR (1000) NULL,
    [Address1]                    VARCHAR (200)  NULL,
    [Address2]                    VARCHAR (200)  NULL,
    [City]                        VARCHAR (50)   NULL,
    [State]                       VARCHAR (200)   NULL,
    [MailingCountry]              VARCHAR (1000) NULL,
    [PostalCode]                  VARCHAR (50)   NULL,
    [COP]                         VARCHAR (10)   NULL,
    [PrimaryLanguage]             VARCHAR (255)  NULL,
    [Email]                       VARCHAR (150)  NULL,
    [DayPhone]                    VARCHAR (255)  NULL,
    [TicketsPurchased]            INT            NULL,
    [CurrentEventTickets]         INT            NULL,
    [DRComments]                  NVARCHAR (MAX) NULL,
    [RegistrationDate]            VARCHAR (50)   NULL,
    [RegisteredBy]                VARCHAR (300)  NULL,
    [CreatedDate]                 DATETIME       CONSTRAINT [DF__EventsReg__Creat__5ED5B086] DEFAULT (getdate()) NULL,
    [CreatedBy]                   VARCHAR (25)   CONSTRAINT [DF__EventsReg__Creat__5FC9D4BF] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [PK_EventsregistrationReport] PRIMARY KEY CLUSTERED ([PK_EventsregistrationReport] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistrationReport_PK_Event]
    ON [dbo].[EventsRegistrationReport]([PK_Event] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistrationReport_PK_Distributor]
    ON [dbo].[EventsRegistrationReport]([PK_Distributor] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistrationReport_DistributorID]
    ON [dbo].[EventsRegistrationReport]([DistributorID] ASC);

