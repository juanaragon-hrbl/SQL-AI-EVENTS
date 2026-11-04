CREATE TABLE [dbo].[EventDSAccess] (
    [PK_EventTypeDSAccessEvent] INT           IDENTITY (1, 1) NOT NULL,
    [PK_Distributor]            INT           NOT NULL,
    [DistributorID]             VARCHAR (10)  NOT NULL,
    [PK_EventSubTypeLocaleDesc] INT           NULL,
    [CreatedDateUTC]            SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                 NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]           SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventTypeDSAccessEvent] PRIMARY KEY CLUSTERED ([PK_EventTypeDSAccessEvent] ASC),
    CONSTRAINT [EventDSAccess_PK_EventSubTypeLocaleDesc] FOREIGN KEY ([PK_EventSubTypeLocaleDesc]) REFERENCES [dbo].[EventSubTypeLocaleDesc] ([PK_EventSubTypeLocaleDesc])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventDSAccess_PK_Distributor]
    ON [dbo].[EventDSAccess]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventDSAccess_DistributorID]
    ON [dbo].[EventDSAccess]([DistributorID] ASC) WITH (FILLFACTOR = 80);

