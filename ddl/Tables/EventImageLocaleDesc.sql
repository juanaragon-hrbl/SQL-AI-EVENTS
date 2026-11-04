CREATE TABLE [dbo].[EventImageLocaleDesc] (
    [PK_EventImageLocaleDesc] INT            IDENTITY (1, 1) NOT NULL,
    [EventImageLocation]      NVARCHAR (MAX) NULL,
    [CreatedDateUTC]          DATETIME       NULL,
    [CreatedBy]               VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]         DATETIME       NULL,
    [ModifiedBy]              VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_EventImage]           INT            NULL,
    [PK_Event]                INT            NULL,
    [PK_Locale]               INT            NULL,
    CONSTRAINT [PK_EventImage_PK_EventImageLocaleDesc] PRIMARY KEY CLUSTERED ([PK_EventImageLocaleDesc] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_EventImageLocaleDesc_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [FK_EventImageLocaleDesc_PK_EventImage] FOREIGN KEY ([PK_EventImage]) REFERENCES [dbo].[EventImage] ([PK_EventImage]),
    CONSTRAINT [FK_EventImageLocaleDesc_PK_Locale] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventImageLocaleDesc_PK_Event_PK_Locale_Covering] 
	ON [dbo].[EventImageLocaleDesc] ([PK_Event], [PK_Locale])
	INCLUDE(EventImageLocation)
GO
CREATE NONCLUSTERED INDEX [IX_EventImageLocaleDesc_PK_EventImage_PK_Event_PK_Locale]
    ON [dbo].[EventImageLocaleDesc]([PK_EventImage] ASC, [PK_Event] ASC, [PK_Locale] ASC)
    INCLUDE([EventImageLocation]);


GO
CREATE NONCLUSTERED INDEX [IX_EventImageLocaleDesc_PK_Locale]
    ON [dbo].[EventImageLocaleDesc]([PK_Locale] ASC)
    INCLUDE([CreatedDateUTC], [CreatedBy], [PK_EventImage], [EventImageLocation], [PK_Event]) WITH (FILLFACTOR = 80);

