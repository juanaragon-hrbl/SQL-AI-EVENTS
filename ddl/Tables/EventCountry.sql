CREATE TABLE [dbo].[EventCountry] (
    [PK_EventCountry] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]  DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]       VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]        INT          NULL,
    [PK_Country]      INT          NULL,
    CONSTRAINT [EventCountry_PK] PRIMARY KEY CLUSTERED ([PK_EventCountry] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventEventCountry_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventCountry_PK_Country]
    ON [dbo].[EventCountry]([PK_Country] ASC) WITH (FILLFACTOR = 80);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_EventCountry_PK_Event]
    ON [dbo].[EventCountry]([PK_Event] ASC) WITH (FILLFACTOR = 80);

