CREATE TABLE [dbo].[EventProductRecommendation] (
    [PK_EventProductRecommendation] INT          IDENTITY (1, 1) NOT NULL,
    [PK_Event]                      INT          NOT NULL,
    [PK_SubEvent]                   INT          NULL,
    [IsProductRecommended]          BIT          DEFAULT ((0)) NULL,
    [IsLinkedToMainEvent]           BIT          DEFAULT ((0)) NULL,
    [IsThresholdEnabled]            BIT          DEFAULT ((0)) NULL,
    [Goal]                          MONEY        NULL,
    [Threshold]                     MONEY        NULL,
    [IsThresholdMonthBased]         BIT          DEFAULT ((0)) NULL,
    [CreatedDateUTC]                DATETIME     DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                     VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]               DATETIME     DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                    VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventProductRecommendation] PRIMARY KEY CLUSTERED ([PK_EventProductRecommendation] ASC),
    CONSTRAINT [FK_EventProductRecommendation_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [FK_EventProductRecommendation_PK_SubEvent] FOREIGN KEY ([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);
GO

CREATE NONCLUSTERED INDEX [IX_EventProductRecommendation_PK_SubEvent] ON [dbo].[EventProductRecommendation]([PK_SubEvent] ASC);
GO
