CREATE TABLE [dbo].[EventLocaleDesc] (
    [PK_EventLocaleDesc]     INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Event]               INT             NOT NULL,
    [PK_EventType]           INT             NOT NULL,
    [PK_Locale]              INT             NOT NULL,
    [PK_DefaultLocale]       INT             NULL,
    [PK_TeamSite]            INT             NULL,
    [EventName]              NVARCHAR (500)  NULL,
    [EventDesc]              NVARCHAR (MAX)  NULL,
    [EventSummary]           NVARCHAR (MAX)  NULL,
    [EventLocation]          NVARCHAR (200)  NULL,
    [EventVenueName]         NVARCHAR (200)  NULL,
    [EventAddress]           NVARCHAR (1000) NULL,
    [EventCity]              NVARCHAR (250)  NULL,
    [EventState]             NVARCHAR (250)  NULL,
    [Keywords]               NVARCHAR (500)  NULL,
    [EventCostDetails]       NVARCHAR (2000) NULL,
    [EventDisplayAddress]    NVARCHAR (4000) NULL,
    [EventTrainingLanguages] NVARCHAR (4000) NULL,
    [EventApprovalNotes]     NVARCHAR (4000) NULL,
    [EventComments]          NVARCHAR (4000) NULL,
    [EventRules]             NVARCHAR (MAX)  NULL,
    [TeamSiteModifiedDate]   SMALLDATETIME   DEFAULT (getutcdate()) NULL,
    [CreatedDateUTC]         SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]              NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]        SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]             NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [DistributorNotes]       NVARCHAR (2000) NULL,
    [ParticipatingCountries] NVARCHAR (MAX)  NULL,
    [TicketRules]            NVARCHAR (MAX)  NULL,
    [EventAddress2]          NVARCHAR (2000) NULL,
    [IsCTAEnabledOnUpcoming] BIT             NULL,
    [CustomTrackingCode]     NVARCHAR (MAX)  NULL,
	[AudioLanguagesDesc]	 NVARCHAR(150)	 NULL,
    CONSTRAINT [PK_EventLocaleDesc] PRIMARY KEY NONCLUSTERED ([PK_EventLocaleDesc] ASC),
    CONSTRAINT [EventQualEvent_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [EventQualPK_EventType_FK] FOREIGN KEY ([PK_EventType]) REFERENCES [dbo].[EventType] ([PK_EventType]),
    CONSTRAINT [EventQualPK_Locale_FK] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale])
);


GO

CREATE CLUSTERED INDEX [IX_EventLocaleDesc_PK_Event_PK_Locale]
	ON [dbo].[EventLocaleDesc]([PK_Event], [PK_Locale])


GO

CREATE NONCLUSTERED INDEX [IX_EventLocaleDesc_PK_Locale]
    ON [dbo].[EventLocaleDesc]([PK_Locale] ASC) WITH (FILLFACTOR = 80);


GO