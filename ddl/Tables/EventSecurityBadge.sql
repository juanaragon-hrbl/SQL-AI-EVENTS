CREATE TABLE [dbo].[EventSecurityBadge] (
    [PK_EventSecurityBadge]    INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]           DATETIME      CONSTRAINT [DF__EventSecu__Creat__186E28F3] DEFAULT (getutcdate()) NULL,
    [CreatedBy]                NVARCHAR (30) CONSTRAINT [DF__EventSecu__Creat__19624D2C] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]          DATETIME      CONSTRAINT [DF__EventSecu__Modif__1A567165] DEFAULT (getutcdate()) NULL,
    [ModifiedBy]               NVARCHAR (30) CONSTRAINT [DF__EventSecu__Modif__1B4A959E] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]                 INT           NOT NULL,
    [VendorEventID]            VARCHAR (10)  NULL,
    [PK_EventsRegistration]    INT           NOT NULL,
    [EventRegistrationName]    NVARCHAR (80) NULL,
    [PK_Distributor]           INT           NOT NULL,
    [DistributorID]            VARCHAR (10)  NULL,
    [BadgeUID]                 VARCHAR (20)  NOT NULL,
    [PK_BadgeStatus]           INT           NULL,
    [EventQualificationString] VARCHAR (500) NULL,
    [IsActive]                 BIT           NULL,
    CONSTRAINT [PK__EventSecurityBad__177A04BA] PRIMARY KEY CLUSTERED ([PK_EventSecurityBadge] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventSecurityBadge_PK_Event]
    ON [dbo].[EventSecurityBadge]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventSecurityBadge_PK_EventsRegistration]
    ON [dbo].[EventSecurityBadge]([PK_EventsRegistration] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventSecurityBadge_PK_Distributor]
    ON [dbo].[EventSecurityBadge]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventSecurityBadge_DistributorID]
    ON [dbo].[EventSecurityBadge]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventSecurityBadge_BadgeUID]
    ON [dbo].[EventSecurityBadge]([BadgeUID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventSecurityBadge_IsActive]
    ON [dbo].[EventSecurityBadge]([IsActive] ASC) WITH (FILLFACTOR = 80);

