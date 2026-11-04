CREATE TABLE [dbo].[EventsRegistration] (
    [PK_EventsRegistration] INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Distributor]        INT             NOT NULL,
    [DistributorID]         VARCHAR (10)    NULL,
    [FirstName]             NVARCHAR (40)   NULL,
    [LastName]              VARCHAR (40)    NULL,
    [AddressLine1]          NVARCHAR (500)  NULL,
    [AddressLine2]          NVARCHAR (500)  NULL,
    [City]                  NVARCHAR (100)  NULL,
    [State]                 NVARCHAR (100)  NULL,
    [ZipCode]               VARCHAR (20)    NULL,
    [Country]               VARCHAR (100)   NULL,
    [Phones]                VARCHAR (100)   NULL,
    [FaxNo]                 VARCHAR (100)   NULL,
    [EmailAddress]          VARCHAR (100)   NULL,
    [IsPrimaryGuest]        BIT             CONSTRAINT [DF__EventsReg__IsPri__7BE6F8DE] DEFAULT ((0)) NOT NULL,
    [HasCheckedIn]          BIT             CONSTRAINT [DF__EventsReg__HasCh__7CDB1D17] DEFAULT ((0)) NOT NULL,
    [CreatedDateUTC]        DATETIME        CONSTRAINT [DF__EventsReg__Creat__7DCF4150] DEFAULT (getutcdate()) NULL,
    [IsDistributor]         BIT             NULL,
    [CreatedBy]             VARCHAR (50)    CONSTRAINT [DF__EventsReg__Creat__7EC36589] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [UnRegister]            BIT             NULL,
    [ModifiedDateUTC]       DATETIME        CONSTRAINT [DF__EventsReg__Modif__7FB789C2] DEFAULT (getutcdate()) NULL,
    [IsPreRegistered]       BIT             CONSTRAINT [DF__EventsReg__IsPre__00ABADFB] DEFAULT ((0)) NOT NULL,
    [ModifiedBy]            VARCHAR (50)    CONSTRAINT [DF__EventsReg__Modif__019FD234] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [DistributorTeam]       VARCHAR (10)    NULL,
    [PK_EventTicket]        INT             NULL,
    [PK_Event]              INT             NOT NULL,
    [PK_PrimaryLanguage]    INT             NULL,
    [PK_SecondaryLanguage]  INT             NULL,
    [PK_EventHotel]         INT             NULL,
    [Registered]            INT             CONSTRAINT [DF__EventsReg__Regis__0293F66D] DEFAULT ((1)) NOT NULL,
    [DSPreferredname]       NVARCHAR (1000) NULL,
    [IsPublicUser]          BIT             DEFAULT ((0)) NULL,
    [IsUsingVolume]         BIT             DEFAULT ((0)) NULL,
    [Apartment]             NVARCHAR (10)   DEFAULT ('') NULL,
    [CustomValue]           VARCHAR (100)   DEFAULT ('') NULL,
    [CustomFields]          NVARCHAR(MAX)   DEFAULT ('') NULL,
    CONSTRAINT [EventsRegistration_PK] PRIMARY KEY CLUSTERED ([PK_EventsRegistration] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventEventsRegistration_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [EventHotelEventsRegistration_FK] FOREIGN KEY ([PK_EventHotel]) REFERENCES [dbo].[EventHotel] ([PK_EventHotel]),
    CONSTRAINT [EventLanguagesEventsRegistration39] FOREIGN KEY ([PK_SecondaryLanguage]) REFERENCES [dbo].[EventLanguages] ([PK_EventLanguage]),
    CONSTRAINT [EventTicketsEventsRegistration_FK] FOREIGN KEY ([PK_EventTicket]) REFERENCES [dbo].[EventTickets] ([PK_EventTicket])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_FirstName]
    ON [dbo].[EventsRegistration]([FirstName] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_LastName]
    ON [dbo].[EventsRegistration]([LastName] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_DistributorID]
    ON [dbo].[EventsRegistration]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_PK_Distributor]
    ON [dbo].[EventsRegistration]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_PK_Event]
    ON [dbo].[EventsRegistration]([PK_Event] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_PK_EventTicket]
    ON [dbo].[EventsRegistration]([PK_EventTicket] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_EventsRegistration_HasCheckedIn_PK_Event_Covering] 
	ON [dbo].[EventsRegistration] ([HasCheckedIn], [PK_Event]) INCLUDE ([PK_Distributor], [ModifiedDateUTC], [PK_EventTicket], [DistributorID]);

