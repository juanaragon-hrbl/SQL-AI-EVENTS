CREATE TABLE [dbo].[Event] (
    [PK_Event]                      INT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]                DATETIME         DEFAULT (getutcdate()) NULL,
    [CreatedBy]                     VARCHAR (50)     DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]               DATETIME         DEFAULT (getutcdate()) NULL,
    [IsTicketPurchaseRequired]      BIT              CONSTRAINT [DF_Event_IsTicketPurchaseRequired] DEFAULT ((0)) NOT NULL,
    [IsPreRegistrationRequired]     BIT              CONSTRAINT [DF_Event_IsPreRegistrationRequired] DEFAULT ((0)) NOT NULL,
    [CanAssignTickets]              BIT              CONSTRAINT [DF_Event_CanAssignTickets] DEFAULT ((0)) NOT NULL,
    [CanPurchaseTicketOnline]       BIT              CONSTRAINT [DF_Event_CanPurchaseTicketOnline] DEFAULT ((0)) NOT NULL,
    [IsRFIDRequired]                BIT              DEFAULT ((0)) NOT NULL,
    [CanRegisterOnline]             BIT              CONSTRAINT [DF_Event_CanRegisterOnline] DEFAULT ((0)) NOT NULL,
    [IsHotelEnabled]                BIT              DEFAULT ((0)) NOT NULL,
    [CanShowCurrentQualOnline]      BIT              CONSTRAINT [DF_Event_CanShowCurrentQualOnline] DEFAULT ((0)) NOT NULL,
    [IsRecordLocked]                BIT              NULL,
    [MaxNoOfGuest]                  INT              DEFAULT ((0)) NOT NULL,
    [MaxNoOfPrimaryGuest]           INT              DEFAULT ((1)) NOT NULL,
    [MaxCapacity]                   INT              DEFAULT ((1)) NOT NULL,
    [ExpectedCapacity]              INT              DEFAULT ((1)) NOT NULL,
    [EventNamePositionID]           INT              NULL,
    [EventTimeZone]                 DECIMAL (5, 2)   DEFAULT ((-8)) NULL,
    [ModifiedBy]                    VARCHAR (50)     DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_EventType]                  INT              NOT NULL,
    [PK_OldEventApp]                INT              NULL,
    [EventName]                     NVARCHAR (200)   NULL,
    [dStartUTC]                     SMALLDATETIME    NULL,
    [dEndUTC]                       SMALLDATETIME    NULL,
    [StoredProcedure]               VARCHAR (200)    NULL,
    [Location]                      NVARCHAR (300)   NULL,
    [LocalName]                     NVARCHAR (300)   NULL,
    [IsPromotion]                   INT              NULL,
    [VendorEventID]                 VARCHAR (10)     NULL,
    [IsInventoryEnabled]            BIT              DEFAULT ((0)) NOT NULL,
    [IsTrackLogoAvail]              BIT              DEFAULT ((0)) NOT NULL,
    [EventImageURL]                 NVARCHAR (1000)  NULL,
    [EventDesc]                     NVARCHAR (MAX)   NULL,
    [IsQualifytoPurchaseTickets]    INT              DEFAULT ((0)) NULL,
    [EventZipCode]                  VARCHAR (10)     NULL,
    [QualPeriodStart]               DATETIME         NULL,
    [QualPeriodEnd]                 DATETIME         NULL,
    [IsDisplayEvent]                BIT              DEFAULT ((0)) NULL,
    [IsRecurring]                   BIT              DEFAULT ((0)) NULL,
    [EventVenueName]                NVARCHAR (250)   NULL,
    [EventAddress]                  NVARCHAR (500)   NULL,
    [EventCity]                     NVARCHAR (100)   NULL,
    [EventState]                    NVARCHAR (100)   NULL,
    [DisplayStartDate]              DATETIME         NULL,
    [DisplayEndDate]                DATETIME         NULL,
    [IsActive]                      BIT              DEFAULT ((0)) NULL,
    [MakePublic]                    BIT              DEFAULT ((0)) NULL,
    [EventCostDetails]              NVARCHAR (2000)  NULL,
    [EventApprovalStatus]           INT              NULL,
    [PK_DefaultLocale]              INT              NULL,
    [IsPublish]                     BIT              DEFAULT ((0)) NULL,
    [CanDisplayQualPeriod]          BIT              CONSTRAINT [DF_Event_CanDisplayQualPeriod] DEFAULT ((0)) NULL,
    [IsPublishQualTracking]         BIT              CONSTRAINT [DF_Event_IsPublishQualTracking] DEFAULT ((0)) NULL,
    [PK_EventSourceSystem]          INT              NULL,
    [IsCustomTrackingSiteAvailable] BIT              DEFAULT ((0)) NULL,
    [CustomTrackingSiteSPName]      NVARCHAR (1000)  NULL,
    [IsBadgePrinting]               BIT              DEFAULT ((0)) NULL,
    [IsAlwaysVisible]               BIT              DEFAULT ((0)) NULL,
    [IsSocialNetworkEnabled]        BIT              DEFAULT ((0)) NULL,
    [CreatedDistributorID]          VARCHAR (10)     NULL,
    [IsPreRegRecordEditable]        BIT              DEFAULT ((0)) NULL,
    [CanDisplayTicketDetails]       BIT              DEFAULT ((0)) NULL,
    [PK_RecurrenceType]             INT              NULL,
    [RecurrenceEndDate]             DATETIME2 (7)    NULL,
    [IsTicketforQualifiedDS]        BIT              DEFAULT ((0)) NULL,
    [TicketThirdPartyLink]          BIT              DEFAULT ((0)) NULL,
    [Latitude]                      NUMERIC (18, 10) NULL,
    [Longitude]                     NUMERIC (18, 10) NULL,
    [IsBizworkReportEnabled]        BIT              DEFAULT ((0)) NULL,
    [CustomTrackingCode]            NVARCHAR (MAX)   NULL,
    [Version]                       INT              NULL,
    CONSTRAINT [Event_PK] PRIMARY KEY CLUSTERED ([PK_Event] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventTypeEvent_FK] FOREIGN KEY ([PK_EventType]) REFERENCES [dbo].[EventType] ([PK_EventType]),
    CONSTRAINT [FK_Event_PK_RecurrenceType] FOREIGN KEY ([PK_RecurrenceType]) REFERENCES [dbo].[RecurrenceType] ([PK_RecurrenceType])
);


GO
CREATE NONCLUSTERED INDEX [IX_Event_ModifiedDateUTC]
    ON [dbo].[Event]([ModifiedDateUTC] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_Event_PK_EventType]
    ON [dbo].[Event]([PK_EventType] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_Event_PK_OldEventApp]
    ON [dbo].[Event]([PK_OldEventApp] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_Event_sEventName]
    ON [dbo].[Event]([EventName] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_Event_CreatedDistributorID]
    ON [dbo].[Event]([CreatedDistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_Event_DisplayStartDate]
    ON [dbo].[Event]([DisplayStartDate] ASC)
    INCLUDE([PK_Event], [CreatedDateUTC], [ModifiedDateUTC], [IsPreRegistrationRequired], [ModifiedBy], [PK_EventType], [PK_OldEventApp], [EventName], [dStartUTC], [dEndUTC], [EventZipCode], [IsRecurring], [EventCity], [EventState], [DisplayEndDate], [IsActive], [MakePublic], [EventApprovalStatus], [PK_DefaultLocale], [IsPublish], [CreatedDistributorID], [PK_RecurrenceType], [RecurrenceEndDate]);


GO
CREATE NONCLUSTERED INDEX [IX_Event_DisplayEndDate]
    ON [dbo].[Event]([DisplayEndDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventType_IsRecurring]
    ON [dbo].[Event]([PK_EventType] ASC, [IsRecurring] ASC)
    INCLUDE([PK_Event]);


GO
CREATE NONCLUSTERED INDEX [IX_Event_DisplayStartDate_Covering]
    ON [dbo].[Event]([DisplayStartDate] ASC)
    INCLUDE([CreatedDateUTC], [ModifiedDateUTC], [IsPreRegistrationRequired], [ModifiedBy], [PK_EventType], [PK_OldEventApp], [EventName], [dStartUTC], [dEndUTC], [EventZipCode], [IsRecurring], [EventCity], [EventState], [DisplayEndDate], [IsActive], [MakePublic], [EventApprovalStatus], [PK_DefaultLocale], [IsPublish], [CreatedDistributorID], [PK_RecurrenceType], [RecurrenceEndDate], [Latitude], [Longitude], [CanDisplayTicketDetails], [IsTicketforQualifiedDS], [TicketThirdPartyLink], [CreatedBy], [CanPurchaseTicketOnline]);


GO
CREATE NONCLUSTERED INDEX [IX_Event_IsActive_IsPublish_PK_EventType_DisplayStartDate]
    ON [dbo].[Event]([IsActive] ASC, [IsPublish] ASC, [PK_EventType] ASC, [DisplayStartDate] ASC)
    INCLUDE([PK_Event], [dEndUTC], [DisplayEndDate]);


GO
CREATE NONCLUSTERED INDEX [IX_Event_IsTicketforQualifiedDS_PK_EventType_dEndUTC]
    ON [dbo].[Event]([IsTicketforQualifiedDS] ASC, [PK_EventType] ASC, [dEndUTC] ASC)
    INCLUDE([PK_Event]);

