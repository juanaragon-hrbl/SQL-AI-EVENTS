CREATE TABLE [dbo].[EventSKULocaleDesc] (
    [PK_EventSKULocaleDesc] INT            IDENTITY (1, 1) NOT NULL,
    [PK_EventSKU]           INT            NOT NULL,
    [PK_Event]              INT            NOT NULL,
    [SKUDesc]               NVARCHAR (MAX) NULL,
    [PK_Locale]             INT            NULL,
    [CreatedDateUTC]        DATETIME       DEFAULT (getutcdate()) NULL,
    [CreatedBy]             VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]       DATETIME       DEFAULT (getutcdate()) NULL,
    [ModifiedBy]            VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_EventURL]           INT            NULL,
    [PK_Currency]           INT            NULL,
    PRIMARY KEY CLUSTERED ([PK_EventSKULocaleDesc] ASC),
    FOREIGN KEY ([PK_EventSKU]) REFERENCES [dbo].[EventSKU] ([PK_EventSKU])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventSKULocaleDesc_PK_EventSKU_PK_Event_PK_Locale]
    ON [dbo].[EventSKULocaleDesc]([PK_EventSKU] ASC, [PK_Event] ASC, [PK_Locale] ASC)
    INCLUDE([SKUDesc], [PK_EventURL], [PK_Currency]);


GO
CREATE NONCLUSTERED INDEX [IX_EventSKULocaleDesc_PK_EventSKU_PK_Locale]
    ON [dbo].[EventSKULocaleDesc]([PK_EventSKU] ASC, [PK_Locale] ASC)
    INCLUDE([SKUDesc], [PK_EventURL], [PK_Currency], [PK_Event]);


GO
CREATE NONCLUSTERED INDEX [IX_EventSKULocaleDesc_PK_Locale]
    ON [dbo].[EventSKULocaleDesc]([PK_Locale] ASC)
    INCLUDE([PK_EventSKU], [PK_Event], [SKUDesc]);

