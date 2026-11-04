CREATE TABLE [dbo].[EventExtn] (
    [PK_EventExtn]           INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]         DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]              VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]        DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]             VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]               INT           NOT NULL,
    [IsDisplayTVP]           BIT           DEFAULT ((0)) NULL,
    [IsDisplayRO]            BIT           DEFAULT ((0)) NULL,
    [IsDisplayPPV]           BIT           DEFAULT ((0)) NULL,
    [IsDisplayPB]            BIT           DEFAULT ((0)) NULL,
    [IsDisplayDLV]           BIT           DEFAULT ((0)) NULL,
    [IsDisplayPPVDLV]        BIT           DEFAULT ((0)) NULL,
    [IsDisplayAWT]           BIT           NULL,
    [IsDisplayAWTQualPeriod] BIT           NULL,
    [IsDisplayAWTFirstTime]  BIT           NULL,
    [AWTStartDate]           DATETIME2 (7) NULL,
    [AWTEndDate]             DATETIME2 (7) NULL,
    [IsUmbracoHosted]        BIT           DEFAULT ((0)) NULL,
    [IsDisplayPDF]           BIT           NULL,
    [IsDisplayDV]            BIT           NULL,
    [HasDownlineTable]       BIT           DEFAULT ((0)) NULL,
    [PromotionCode]          VARCHAR (255) NULL,
    [DisplayQualStatus]      BIT           NULL,
    [RSVPRegistrations]      INT           NULL,
    [RSVPGuests]             INT           NULL,
    [IsDisplayPMPPV]         BIT           NULL,
    [DisplayDates]           BIT           NULL,
    [TimeZoneDesc]			 VARCHAR (50)  NULL,
	[EventCode]				 VARCHAR(20)   NULL,
	[ServiceKey]			 VARCHAR(100)  NULL,
	[IsLanguageGrouped]		 BIT		   DEFAULT ((0)) NULL,
	[PK_DefaultMasterLocale] INT		   NULL,
    [EnabledAddToCalendar]   BIT           DEFAULT ((0)) NOT NULL,
    [HideLandingPage]        BIT           DEFAULT ((0)) NULL,
    [IsInPersonEvent]        BIT           DEFAULT ((0)) NULL,
    [IsVirtualEvent]         BIT           DEFAULT ((0)) NULL,
    [IsMajorEvent]           BIT           DEFAULT ((0)) NULL,
	[AudioLanguagesList]	 NVARCHAR(200) NULL,
    [DisplayVirtualQualifiedOnly] BIT      DEFAULT ((0)) NULL,
    [HasMailout]             BIT           DEFAULT ((0)) NULL,
    [HideTeamLevelInfo]      BIT            NULL,
    [EnableTesting]          BIT            NULL,
    [IsDisplayDownline]      BIT            NULL,
    [IsDisplayTicketsTypPage] BIT           NULL,
    [IsDisplayGtaLink]        BIT           NULL,
    [HideQualifiedBadge] BIT          DEFAULT ((0)) NULL
    CONSTRAINT [EventExtn_PK] PRIMARY KEY CLUSTERED ([PK_EventExtn] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [Event_EventExtn_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);
GO

CREATE NONCLUSTERED INDEX [IX_EventExtn_ModifiedDateUTC]
    ON [dbo].[EventExtn]([ModifiedDateUTC] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_EventExtn_PK_Event]
    ON [dbo].[EventExtn]([PK_Event] ASC) WITH (FILLFACTOR = 80);
GO
