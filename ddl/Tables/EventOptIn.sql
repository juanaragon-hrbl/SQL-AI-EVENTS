CREATE TABLE [dbo].[EventOptIn] (
    [PK_EventOptIn]   INT             IDENTITY (1, 1) NOT NULL,
    [PK_Event]        INT             NULL,
    [DistributorID]   VARCHAR (30)    NULL,
    [PK_Distributor]  INT             NULL,
    [OptInDate]       DATETIME        DEFAULT (getutcdate()) NULL,
    [CreatedDateUTC]  DATETIME        DEFAULT (getutcdate()) NULL,
    [CreatedBy]       VARCHAR (50)    DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME        DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      VARCHAR (50)    DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL
    CONSTRAINT [PK_EventOptIn_PK_EventOptIn] PRIMARY KEY CLUSTERED ([PK_EventOptIn] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_EventOptIn_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT UQ_Event_Distributor UNIQUE NONCLUSTERED (PK_Event, PK_Distributor) 
);


GO
CREATE NONCLUSTERED INDEX [IX_EventOptIn_PK_Event]
    ON [dbo].[EventOptIn]([PK_Event] ASC);