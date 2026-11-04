CREATE TABLE [dbo].[EventSubTypeGroupLocale] (
    [PK_EventSubTypeGroupLocale] INT            IDENTITY (1, 1) NOT NULL,
    [PK_EventSubTypeGroupMaster] INT            NOT NULL,
    [PK_Locale]                  INT            NOT NULL,
    [EventSubTypeGroupLocale]    NVARCHAR (200) NOT NULL,
    [CreatedDateUTC]             SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                  NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]            SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                 NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventSubTypeGroupMasterLocale] PRIMARY KEY CLUSTERED ([PK_EventSubTypeGroupLocale] ASC),
    CONSTRAINT [EventSubTypeGroupLocale_PK_EventSubTypeGroupMaster] FOREIGN KEY ([PK_EventSubTypeGroupMaster]) REFERENCES [dbo].[EventSubTypeGroupMaster] ([PK_EventSubTypeGroupMaster]),
    CONSTRAINT [EventSubTypeGroupLocale_PK_Locale] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale]),
    CONSTRAINT [IX_EventSubTypeGroupLocale_Locale] UNIQUE NONCLUSTERED ([PK_Locale] ASC, [PK_EventSubTypeGroupMaster] ASC) WITH (FILLFACTOR = 80)
);

