CREATE TABLE [dbo].[EventTickets] (
    [PK_EventTicket]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Purchaser]     INT           NOT NULL,
    [IsTicketUsed]     BIT           DEFAULT ((0)) NOT NULL,
    [CanAssignTicket]  BIT           DEFAULT ((1)) NOT NULL,
    [IsTicketReserved] BIT           DEFAULT ((0)) NOT NULL,
    [ReservedFor]      VARCHAR (200) NULL,
    [CreatedDateUTC]   DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]        VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]  DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]         INT           NOT NULL,
    [PK_EventSKU]      INT           NULL,
    [PK_SKUPurchased]  INT           NULL,
    CONSTRAINT [EventTickets_PK] PRIMARY KEY CLUSTERED ([PK_EventTicket] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE),
    CONSTRAINT [EventEventTickets_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [EventSKUEventTickets_FK] FOREIGN KEY ([PK_EventSKU]) REFERENCES [dbo].[EventSKU] ([PK_EventSKU]),
    CONSTRAINT [EventTicketsSKUPurchased_FK] FOREIGN KEY ([PK_SKUPurchased]) REFERENCES [dbo].[SKUPurchased] ([PK_SKUPurchased])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventTickets_PK_SKUPurchased]
    ON [dbo].[EventTickets]([PK_SKUPurchased] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_EventTickets_PK_Purchaser]
    ON [dbo].[EventTickets]([PK_Purchaser] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventTickets_PK_Event]
    ON [dbo].[EventTickets]([PK_Event] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventTickets_PK_EventSKU]
    ON [dbo].[EventTickets]([PK_EventSKU] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_EventTickets_PK_Event_Covering] 
	ON [dbo].[EventTickets] ([PK_Event]) INCLUDE ([PK_Purchaser], [PK_EventSKU], [PK_SKUPurchased], [IsTicketUsed]);
