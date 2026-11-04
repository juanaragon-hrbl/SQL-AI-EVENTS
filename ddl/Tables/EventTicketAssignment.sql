CREATE TABLE [dbo].[EventTicketAssignment] (
    [PK_EventTicketAssignment] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_FromDistributor]       INT          NOT NULL,
    [PK_ToDistributor]         INT          NOT NULL,
    [CreatedDateUTC]           DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]                VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]          DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]               VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_EventTicket]           INT          NOT NULL,
    [Ticketed]                 INT          DEFAULT ((1)) NOT NULL,
    [ValidFromDateUTC]         DATETIME     NULL,
    [ValidToDateUTC]           DATETIME     NULL,
    [PK_Event]                 INT          NULL,
    [PK_EventSKU]              INT          NULL,
    [PK_SKUPurchased]          INT          NULL,
    CONSTRAINT [EventTicketAssignment_PK] PRIMARY KEY CLUSTERED ([PK_EventTicketAssignment] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE),
    CONSTRAINT [EventTicketAssignmentEvent_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [EventTicketAssignmentEventSKU_FK] FOREIGN KEY ([PK_EventSKU]) REFERENCES [dbo].[EventSKU] ([PK_EventSKU]),
    CONSTRAINT [EventTicketAssignmentSKUPurchased_FK] FOREIGN KEY ([PK_SKUPurchased]) REFERENCES [dbo].[SKUPurchased] ([PK_SKUPurchased]),
    CONSTRAINT [EventTicketsEventTicketAssignment_FK] FOREIGN KEY ([PK_EventTicket]) REFERENCES [dbo].[EventTickets] ([PK_EventTicket])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_ValidFrom]
    ON [dbo].[EventTicketAssignment]([ValidFromDateUTC] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_ValidTo]
    ON [dbo].[EventTicketAssignment]([ValidToDateUTC] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_PK_Event]
    ON [dbo].[EventTicketAssignment]([PK_Event] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_PK_EventSKU]
    ON [dbo].[EventTicketAssignment]([PK_EventSKU] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_PK_SKUPurchased]
    ON [dbo].[EventTicketAssignment]([PK_SKUPurchased] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_PK_EventTicket]
    ON [dbo].[EventTicketAssignment]([PK_EventTicket] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_PK_ToDistributor_ValidToDateUTC]
    ON [dbo].[EventTicketAssignment]([PK_ToDistributor] ASC, [ValidToDateUTC] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_PK_FromDistributor_PK_EventSKU]
    ON [dbo].[EventTicketAssignment]([PK_FromDistributor] ASC, [PK_EventSKU] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_PK_FromDistributor_ValidToDateUTC_PK_EventSKU]
    ON [dbo].[EventTicketAssignment]([PK_FromDistributor] ASC, [ValidToDateUTC] ASC, [PK_EventSKU] ASC) WITH (FILLFACTOR = 80);

GO
CREATE NONCLUSTERED INDEX [IX_EventTicketAssignment_ValidToDateUTC_PK_Event_Covering] 
	ON [dbo].[EventTicketAssignment] ([ValidToDateUTC], [PK_Event]) INCLUDE ([PK_ToDistributor], [ValidFromDateUTC], [PK_EventTicket], [PK_FromDistributor], [CreatedDateUTC]);
