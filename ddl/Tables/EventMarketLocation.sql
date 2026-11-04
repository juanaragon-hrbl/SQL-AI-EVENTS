CREATE TABLE [dbo].[EventMarketLocation] (
    [PK_EventMarketLocation] INT           IDENTITY (1, 1) NOT NULL,
    [PK_Event]               INT           NOT NULL,
    [PK_EventMarketType]     INT           NULL,
    [StartDate]              SMALLDATETIME NULL,
    [EndDate]                SMALLDATETIME NULL,
    [Location]               NVARCHAR (60) NULL,
    [City]                   NVARCHAR (60) NULL,
    [State]                  NVARCHAR (60) NULL,
    [CountryCodeISO]         NVARCHAR (60) NULL,
    [IsActive]               BIT           NOT NULL,
    [CreatedDateUTC]         SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]              NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]        SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]             NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventMarketLocation] PRIMARY KEY CLUSTERED ([PK_EventMarketLocation] ASC),
    CONSTRAINT [FK_EventMarketLocation_EventMarketType] FOREIGN KEY ([PK_EventMarketType]) REFERENCES [dbo].[EventMarketType] ([PK_EventMarketType]),
    CONSTRAINT [FK_EventMarketLocation_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventMarketLocation_PK_Event]
    ON [dbo].[EventMarketLocation]([PK_Event] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventMarketLocation_PK_EventMarketType]
    ON [dbo].[EventMarketLocation]([PK_EventMarketType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventMarketLocation_City]
    ON [dbo].[EventMarketLocation]([City] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventMarketLocation_StateCode]
    ON [dbo].[EventMarketLocation]([State] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventMarketLocation_CountryCodeISO]
    ON [dbo].[EventMarketLocation]([CountryCodeISO] ASC);

