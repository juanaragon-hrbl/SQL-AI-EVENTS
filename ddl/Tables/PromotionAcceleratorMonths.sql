CREATE TABLE [dbo].[PromotionAcceleratorMonths] (
    [PK_PromotionAcceleratorMonth] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [RoyaltyMonth]                 DATETIME      NOT NULL,
    [CreatedDateUTC]               SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                    VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]              SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                   VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [PK_PromotionAccelerator]      INT           NOT NULL,
    [PromotionType]                VARCHAR (5)   NULL,
    [BreakPoint]                   MONEY         NULL,
    [FactorType]                   VARCHAR (1)   NULL,
    [AcceleratorFactor]            SMALLINT      NULL,
    [MaxAcceleratorPoint]          MONEY         NULL,
    CONSTRAINT [PromotionAcceleratorMonths_PK] PRIMARY KEY NONCLUSTERED ([PK_PromotionAcceleratorMonth] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [PromotionAcceleratorPromotionAcceleratorMonths_FK] FOREIGN KEY ([PK_PromotionAccelerator]) REFERENCES [dbo].[PromotionAccelerator] ([PK_PromotionAccelerator])
);

