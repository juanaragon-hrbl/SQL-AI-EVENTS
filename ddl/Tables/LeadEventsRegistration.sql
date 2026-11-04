CREATE TABLE [dbo].[LeadEventsRegistration] (
    [CreatedDate]    DATETIME       DEFAULT (getdate()) NULL,
    [CreatedBy]      VARCHAR (30)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDate]   DATETIME       DEFAULT (getdate()) NULL,
    [ModifiedBy]     VARCHAR (30)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_LeadEvent]   INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_EventType]   INT            NOT NULL,
    [PK_Event]       INT            NULL,
    [PK_Distributor] INT            NOT NULL,
    [DistributorID]  VARCHAR (10)   NOT NULL,
    [EventName]      NVARCHAR (200) NOT NULL,
    [EventDate]      DATETIME       NOT NULL,
    [EventCity]      NVARCHAR (100) NULL,
    [Location]       NVARCHAR (300) NULL,
    [Qualified]      INT            DEFAULT ((1)) NOT NULL,
    [PurchasedSKU]   INT            DEFAULT ((1)) NOT NULL,
    [Attend]         AS             (case when [PK_EventType]=(9) then (1) when [Qualified]=(1) AND [PurchasedSKU]=(1) then (1) else (0) end),
    CONSTRAINT [PK_LeadEventsRegistration_CS] PRIMARY KEY CLUSTERED ([PK_LeadEvent] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_LeadEventsRegistration_PK_Distributor]
    ON [dbo].[LeadEventsRegistration]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_LeadEventsRegistration_DistributorID]
    ON [dbo].[LeadEventsRegistration]([DistributorID] ASC) WITH (FILLFACTOR = 80);

