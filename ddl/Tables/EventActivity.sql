CREATE TABLE [dbo].[EventActivity] (
    [PK_EventActivity]     INT             IDENTITY (1, 1) NOT NULL,
    [PK_Event]             INT             NOT NULL,
    [ActivityName]         NVARCHAR (200)  NOT NULL,
    [ActivityDesc]         NVARCHAR (MAX)  NULL,
    [ActivitySequence]     INT             NULL,
    [Location]             NVARCHAR (200)  NULL,
    [Address1]             NVARCHAR (100)  NULL,
    [Address2]             NVARCHAR (100)  NULL,
    [City]                 NVARCHAR (100)  NULL,
    [StateProvince]        NVARCHAR (100)  NULL,
    [PostalCode]           VARCHAR (25)    NULL,
    [PK_Country]           INT             NULL,
    [StartUTC]             DATETIME        NULL,
    [EndUTC]               DATETIME        NULL,
    [RegistrationStartUTC] DATETIME        NULL,
    [RegistrationEndUTC]   DATETIME        NULL,
    [UnitPrice]            DECIMAL (17, 2) NULL,
    [CurrencyType]         VARCHAR (3)     NULL,
    [CompQtyPerDS]         INT             NULL,
    [MaxQtyPerDS]          INT             NULL,
    [MaxQty]               INT             NOT NULL,
    [SoldQty]              INT             NOT NULL,
    [ProcessingQty]        INT             NOT NULL,
    [AvailableQty]         INT             NOT NULL,
    [ReserveTimeOut]       INT             NOT NULL,
    [PaymentTimeOut]       INT             NOT NULL,
    [DeletedUTC]           DATETIME        NULL,
    [CreatedUTC]           DATETIME        CONSTRAINT [DF_EventActivity_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]            NVARCHAR (50)   CONSTRAINT [DF_EventActivity_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC]          DATETIME        CONSTRAINT [DF_EventActivity_ModifiedUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]           NVARCHAR (50)   CONSTRAINT [DF_EventActivity_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventActivity] PRIMARY KEY CLUSTERED ([PK_EventActivity] ASC),
    CONSTRAINT [CK_EventActivity_AvailableQty] CHECK ([AvailableQty]>=(0)),
    CONSTRAINT [CK_EventActivity_MaxQty] CHECK ([MaxQty]>=(0)),
    CONSTRAINT [CK_EventActivity_ProcessingQty] CHECK ([ProcessingQty]>=(0)),
    CONSTRAINT [CK_EventActivity_SoldQty] CHECK ([SoldQty]>=(0)),
    CONSTRAINT [FK_EventActivity_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivity_AvailableQty]
    ON [dbo].[EventActivity]([AvailableQty] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivity_DeletedUTC]
    ON [dbo].[EventActivity]([DeletedUTC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivity_EndUTC]
    ON [dbo].[EventActivity]([EndUTC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivity_EventActivityName]
    ON [dbo].[EventActivity]([ActivityName] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivity_Location]
    ON [dbo].[EventActivity]([Location] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivity_MaxQty]
    ON [dbo].[EventActivity]([MaxQty] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivity_ProcessingQty]
    ON [dbo].[EventActivity]([ProcessingQty] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivity_SoldQty]
    ON [dbo].[EventActivity]([SoldQty] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventActivity_StartUTC]
    ON [dbo].[EventActivity]([StartUTC] ASC);

