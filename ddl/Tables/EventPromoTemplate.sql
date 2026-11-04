CREATE TABLE [dbo].[EventPromoTemplate] (
    [PK_Event]                  INT           NOT NULL,
    [PK_EventPromoTemplateType] INT           NULL,
    [WorkTable]                 VARCHAR (255) NULL,
    [StatusSP]                  VARCHAR (255) NULL,
    [TrackProgressSP]           VARCHAR (255) NULL,
    [TrackDownlineSP]           VARCHAR (255) NULL,
    [TrackDownlineSummarySP]    VARCHAR (255) NULL,
    [CreatedDateUTC]            DATETIME2 (7) CONSTRAINT [DF_EventPromoTemplate_CreatedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                 VARCHAR (255) CONSTRAINT [DF_EventPromoTemplate_CreatedBy] DEFAULT (replace(suser_name(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]           DATETIME2 (7) CONSTRAINT [DF_EventPromoTemplate_ModifiedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                VARCHAR (255) CONSTRAINT [DF_EventPromoTemplate_ModifiedBy] DEFAULT (replace(suser_name(),'HERBALIFECORP\','')) NOT NULL,
	[CustomValue]				NVARCHAR(4000),
    [VolumeByCOP]               NVARCHAR (1000)  NULL,
    [CustomEvalDate]            NVARCHAR (1000)  NULL,
    [OrderPurpose]              VARCHAR(100) NULL,
	[QualificationsSP]			VARCHAR(500) NULL,
	[QualsWithPK_Event]			BIT NULL,
    [RunPriorMonth]             BIT NULL,
    [ExecutionEndDate]          DATETIME2 NULL
    CONSTRAINT [FK_EventPromoTemplate_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_EventPromoTemplate_PK_Event]
    ON [dbo].[EventPromoTemplate]([PK_Event] ASC);

