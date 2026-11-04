CREATE TABLE [dbo].[EventBadgePrinting] (
    [PK_EventBadgePrinting] INT            IDENTITY (1, 1) NOT NULL,
    [PK_EventsRegistration] INT            NOT NULL,
    [PK_Event]              INT            NOT NULL,
    [PK_Distributor]        INT            NOT NULL,
    [DistributorID]         VARCHAR (20)   NOT NULL,
    [FirstName]             NVARCHAR (100) NULL,
    [LastName]              NVARCHAR (100) NULL,
    [COP]                   VARCHAR (30)   NULL,
    [TeamStatus]            VARCHAR (50)   NULL,
    [Title]                 VARCHAR (30)   NULL,
    [Salutation]            VARCHAR (30)   NULL,
    [BadgeStatus]           VARCHAR (10)   NULL,
    [TerminalID]            VARCHAR (20)   NULL,
    [PortNumber]            VARCHAR (20)   NULL,
    [CreatedDateUTC]        SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]             NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]       SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]            NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventBadgePrinting] PRIMARY KEY CLUSTERED ([PK_EventBadgePrinting] ASC),
    CONSTRAINT [EventBadgePrinting_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [EventBadgePrinting_PK_EventsRegistration] FOREIGN KEY ([PK_EventsRegistration]) REFERENCES [dbo].[EventsRegistration] ([PK_EventsRegistration])
);

