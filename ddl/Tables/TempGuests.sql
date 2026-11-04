CREATE TABLE [dbo].[TempGuests] (
    [PK_TempGuest]    INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [DistributorID]   VARCHAR (10)  NOT NULL,
    [PK_Event]        INT           NULL,
    [GuestFirstName]  VARCHAR (100) NULL,
    [GuestLastName]   VARCHAR (100) NULL,
    [CreatedDateUTC]  SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC] SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]      VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [TempGuests_PK] PRIMARY KEY CLUSTERED ([PK_TempGuest] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_TempGuests_DistributorID]
    ON [dbo].[TempGuests]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_TempGuests_PK_Event]
    ON [dbo].[TempGuests]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_TempGuests_GuestLastName]
    ON [dbo].[TempGuests]([GuestLastName] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_TempGuests_GuestFirstName]
    ON [dbo].[TempGuests]([GuestFirstName] ASC) WITH (FILLFACTOR = 80);

