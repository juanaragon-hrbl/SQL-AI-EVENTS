CREATE TABLE [dbo].[EventDistributorCountry] (
    [PK_EventDistributorCountry] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]             DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]                  VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]            DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]                 VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]                   INT          NULL,
    [PK_Country]                 INT          NULL,
    CONSTRAINT [EventDistributorCountry_PK] PRIMARY KEY CLUSTERED ([PK_EventDistributorCountry] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventEventDistributorCountry_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_EventDistributorCountry_PK_Country_PK_Event]
    ON [dbo].[EventDistributorCountry]([PK_Country] ASC, [PK_Event] ASC) WITH (FILLFACTOR = 80);

GO
CREATE NONCLUSTERED INDEX [IX_EventDistributorCountry_PK_Event_Covering] 
	ON [dbo].[EventDistributorCountry] ([PK_Event]) INCLUDE ([PK_Country]);