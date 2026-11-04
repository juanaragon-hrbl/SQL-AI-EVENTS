CREATE TABLE [dbo].[MealTypeLocale] (
    [PK_MealTypeLocale] INT            IDENTITY (1, 1) NOT NULL,
    [PK_MealType]       SMALLINT       NOT NULL,
    [PK_Locale]         INT            NOT NULL,
    [MealType]          NVARCHAR (128) NOT NULL,
    [CreatedUTC]        DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]         NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC]       DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]        NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_MealTypeLocale] PRIMARY KEY CLUSTERED ([PK_MealTypeLocale] ASC),
    CONSTRAINT [FK_MealTypeLocale_Locale] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale]),
    CONSTRAINT [FK_MealTypeLocale_MealType] FOREIGN KEY ([PK_MealType]) REFERENCES [dbo].[MealType] ([PK_MealType])
);


GO
CREATE NONCLUSTERED INDEX [IX_MealTypeLocale_MealType]
    ON [dbo].[MealTypeLocale]([MealType] ASC);

