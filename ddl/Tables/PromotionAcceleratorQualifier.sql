CREATE TABLE [dbo].[PromotionAcceleratorQualifier] (
    [PK_PromotionAcceleratorQualifier] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [RoyaltyMonth]                     DATETIME     NOT NULL,
    [TotalPoints]                      INT          NOT NULL,
    [CreatedDateUTC]                   DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]                        VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]                  DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]                       VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Distributor]                   INT          NOT NULL,
    [PK_PromotionAcceleratorCountry]   INT          NOT NULL,
    CONSTRAINT [PromotionAcceleratorQualifier_PK] PRIMARY KEY CLUSTERED ([PK_PromotionAcceleratorQualifier] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [PromotionAcceleratorCountryPromotionAcceleratorQualifier_FK] FOREIGN KEY ([PK_PromotionAcceleratorCountry]) REFERENCES [dbo].[PromotionAcceleratorCountry] ([PK_PromotionAcceleratorCountry])
);

