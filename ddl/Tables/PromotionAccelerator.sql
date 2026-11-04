CREATE TABLE [dbo].[PromotionAccelerator] (
    [PK_PromotionAccelerator] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PromotionName]           VARCHAR (100) NOT NULL,
    [BreakPoint]              INT           NOT NULL,
    [AcceleratorPoint]        INT           NOT NULL,
    [CreatedDateUTC]          DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]               VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]         DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]              VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_QualificationType]    INT           NOT NULL,
    CONSTRAINT [PromotionAccelerator_PK] PRIMARY KEY CLUSTERED ([PK_PromotionAccelerator] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [QualificationTypePromotionAccelerator_FK] FOREIGN KEY ([PK_QualificationType]) REFERENCES [dbo].[QualificationType] ([PK_QualificationType])
);

