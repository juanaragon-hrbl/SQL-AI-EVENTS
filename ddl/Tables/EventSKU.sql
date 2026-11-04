CREATE TABLE [dbo].[EventSKU] (
    [PK_EventSKU]           INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]        DATETIME       DEFAULT (getutcdate()) NULL,
    [CreatedBy]             VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]       DATETIME       DEFAULT (getutcdate()) NULL,
    [ModifiedBy]            VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]              INT            NOT NULL,
    [SKUCode]               VARCHAR (4)    NOT NULL,
    [SKUDesc]               NVARCHAR (100)  NULL,
    [Price]                 MONEY          NULL,
    [VolumePoints]          NUMERIC (8, 2) NULL,
    [QuantityInStock]       INT            NULL,
    [QuantitySold]          INT            NULL,
    [WareHouseID]           INT            NULL,
    [SKUValidBeginUTC]      SMALLDATETIME  NULL,
    [SKUValidEndUTC]        SMALLDATETIME  NULL,
    [NumberOfTicketsPerSKU] INT            DEFAULT ((1)) NOT NULL,
    [PK_EventSKUType]       INT            NOT NULL,
    [PK_Country]            INT            NULL,
    [IsEventTicketSKU]      INT            DEFAULT ((1)) NULL,
    [ProcessSKU]            BIT            DEFAULT ((1)) NULL,
    [PK_Locale]             INT            NULL,
    [IsGenerateNote]        BIT            DEFAULT ((0)) NULL,
    [IsTrackingVisible]     BIT            DEFAULT ((1)) NOT NULL,
    [IsSKUUsedInPreOrder]   BIT            DEFAULT ((0)) NOT NULL,
    [SubEventAssociated]    INT            DEFAULT ((0)) NULL,
    [AllowedCOP]            NVARCHAR (MAX) NULL,
    [IsFromAdmin]           BIT            DEFAULT ((0)) NOT NULL,
    [IsEnabledForNonQualifiers] BIT        NULL,
    CONSTRAINT [EventSKU_PK] PRIMARY KEY CLUSTERED ([PK_EventSKU] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventEventSKU_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [EventSKUTypeEventSKU_FK] FOREIGN KEY ([PK_EventSKUType]) REFERENCES [dbo].[EventSKUType] ([PK_EventSKUType])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventSKU_PK_Event]
    ON [dbo].[EventSKU]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventSKU_SKUValidBeginUTC]
    ON [dbo].[EventSKU]([SKUValidBeginUTC] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventSKU_SKUValidEndUTC]
    ON [dbo].[EventSKU]([SKUValidEndUTC] ASC) WITH (FILLFACTOR = 80);

