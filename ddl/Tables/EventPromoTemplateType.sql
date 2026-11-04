CREATE TABLE [dbo].[EventPromoTemplateType] (
    [PK_EventPromoTemplateType] INT NOT NULL,
    [EventPromoTemplateType]    VARCHAR (255) NOT NULL,
    [CreatedDateUTC]            DATETIME2 (7) CONSTRAINT [DF_EventPromoTemplateType_CreatedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                 VARCHAR (255) CONSTRAINT [DF_EventPromoTemplateType_CreatedBy] DEFAULT (replace(suser_name(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]           DATETIME2 (7) CONSTRAINT [DF_EventPromoTemplateType_ModifiedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                VARCHAR (255) CONSTRAINT [DF_EventPromoTemplateType_ModifiedBy] DEFAULT (replace(suser_name(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [DF_EventPromoTemplateType_PK_EventPromoTemplateType] PRIMARY KEY CLUSTERED ([PK_EventPromoTemplateType] ASC)
);

