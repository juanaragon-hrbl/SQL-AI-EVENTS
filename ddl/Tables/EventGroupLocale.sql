CREATE TABLE [dbo].[EventGroupLocale] (
    [PK_EventGroupLocale]    INT            IDENTITY (1, 1) NOT NULL,
    [PK_EventGroup]          INT            NOT NULL,
    [PK_Locale]              INT            NOT NULL,
    [EventGroupName]         VARCHAR (100)  NOT NULL,
    [EventGroupDesc]         VARCHAR (1000) NULL,
    [CreatedBy]              VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]         SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]             VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]        SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [PageTitle]              VARCHAR (255)  NULL,
    [PageSummary]            VARCHAR (MAX)  NULL,
    [TicketLink]             VARCHAR (255)  NULL,
    [IsTicketLinkDisplayed]  BIT            NULL,
    [ProductLink]            VARCHAR (255)  NULL,
    [IsProductLinkDisplayed] BIT            NULL,
    CONSTRAINT [PK_EventGroupLocale] PRIMARY KEY CLUSTERED ([PK_EventGroupLocale] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_EventGroupLocale_EventGroups] FOREIGN KEY ([PK_EventGroup]) REFERENCES [dbo].[EventGroups] ([PK_EventGroup]),
    CONSTRAINT [FK_EventGroupLocale_Locales] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale])
);

