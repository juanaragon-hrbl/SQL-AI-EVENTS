CREATE TABLE [dbo].[EventGroups] (
    [PK_EventGroup]     INT            IDENTITY (1, 1) NOT NULL,
    [EventGroupName]    VARCHAR (100)  NOT NULL,
    [EventGroupDesc]    VARCHAR (1000) NULL,
    [PK_DefaultLocale]  INT            NULL,
    [CreatedBy]         VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]    SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]        VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]   SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [PK_EventGroupType] INT            NULL,
    [IsPublished]       BIT            NULL,
    [IsPersistentGroup] BIT            NULL,
    CONSTRAINT [EventGroups_PK] PRIMARY KEY CLUSTERED ([PK_EventGroup] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventGroupType_EventGroups_FK] FOREIGN KEY ([PK_EventGroupType]) REFERENCES [dbo].[EventGroupType] ([PK_EventGroupType]),
    CONSTRAINT [Locales_EventGroups_FK] FOREIGN KEY ([PK_DefaultLocale]) REFERENCES [dbo].[Locales] ([PK_Locale])
);
GO

CREATE NONCLUSTERED INDEX [IX_EventGroups_EventGroupName]
    ON [dbo].[EventGroups]([EventGroupName] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_EventGroups_PK_DefaultLocale]
    ON [dbo].[EventGroups]([PK_DefaultLocale] ASC);
GO

