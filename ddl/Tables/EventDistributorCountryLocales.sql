CREATE TABLE [dbo].[EventDistributorCountryLocales] (
    [PK_EventDistributorCountryLocales] INT           IDENTITY (1, 1) NOT NULL,
    [PK_Event]                          INT           NOT NULL,
    [PK_Locale]                         INT           NOT NULL,
    [IsDefault]                         BIT           DEFAULT ((0)) NULL,
    [CreatedDateUTC]                    DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]                         NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]                   DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]                        NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [PK_EventDistributorCountryLocales] PRIMARY KEY CLUSTERED ([PK_EventDistributorCountryLocales] ASC),
    CONSTRAINT [FK_EventDistributorCountryLocales_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [IX_EventDistributorCountryLocales_Locale] UNIQUE NONCLUSTERED ([PK_Event] ASC, [PK_Locale] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventDistributorCountryLocales_PK_Locale]
    ON [dbo].[EventDistributorCountryLocales]([PK_Locale] ASC)
    INCLUDE([PK_Event]) WITH (FILLFACTOR = 80);

