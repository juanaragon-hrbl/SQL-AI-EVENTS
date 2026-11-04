CREATE TABLE [dbo].[EventSubTypeLocaleDesc] (
    [PK_EventSubTypeLocaleDesc] INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_EventSubType]           INT            NOT NULL,
    [PK_Locale]                 INT            NOT NULL,
    [EventSubTypeDesc]          NVARCHAR (400) NULL,
    [CreatedDateUTC]            SMALLDATETIME  DEFAULT (getutcdate()) NULL,
    [CreatedBy]                 NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]           SMALLDATETIME  DEFAULT (getutcdate()) NULL,
    [ModifiedBy]                NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [LocaleDescription]         NVARCHAR (400) NULL,
    [Image]                     NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([PK_EventSubTypeLocaleDesc] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_EventSubTypeLocaleDesc_PK_EventSubType_PK_Locale] 
	ON [dbo].[EventSubTypeLocaleDesc] ([PK_EventSubType], [PK_Locale])
	INCLUDE(EventSubTypeDesc, LocaleDescription, Image)
GO
CREATE NONCLUSTERED INDEX [IX_EventSubTypeLocaleDesc_PK_Locale]
    ON [dbo].[EventSubTypeLocaleDesc]([PK_Locale] ASC) WITH (FILLFACTOR = 80);


GO
