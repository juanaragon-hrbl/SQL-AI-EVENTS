CREATE TABLE [dbo].[PromotionAcceleratorCountry] (
    [PK_PromotionAcceleratorCountry] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]                 DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]                      VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]                DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]                     VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Country]                     INT          NOT NULL,
    [PK_PromotionAcceleratorMonth]   INT          NOT NULL,
    CONSTRAINT [PromotionAcceleratorCountry_PK] PRIMARY KEY CLUSTERED ([PK_PromotionAcceleratorCountry] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [PromotionAcceleratorMonthsPromotionAcceleratorCountry_FK] FOREIGN KEY ([PK_PromotionAcceleratorMonth]) REFERENCES [dbo].[PromotionAcceleratorMonths] ([PK_PromotionAcceleratorMonth])
);

