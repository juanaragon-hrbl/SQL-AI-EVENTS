CREATE TABLE [dbo].[SubEventQualificationFormula] (
    [PK_SubEventQualificationFormula] INT          IDENTITY (1, 1) NOT NULL,
    [CreatedDateUTC]                  DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]                       VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]                 DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]                      VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]                        INT          NULL,
    [PK_SubEvent]                     INT          NULL,
    [Value]                           VARCHAR (3)  NULL,
    [NestLevel]                       INT          DEFAULT ((1)) NULL,
    [IndentLevel]                     INT          DEFAULT ((0)) NULL,
    CONSTRAINT [SubEventQualificationFormula_PK] PRIMARY KEY CLUSTERED ([PK_SubEventQualificationFormula] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventSubEventQualificationFormula_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [SubEventSubEventQualificationFormula_FK] FOREIGN KEY ([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualificationFormula_IndentLevel]
    ON [dbo].[SubEventQualificationFormula]([IndentLevel] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualificationFormula_NestLevel]
    ON [dbo].[SubEventQualificationFormula]([NestLevel] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualificationFormula_PK_Event]
    ON [dbo].[SubEventQualificationFormula]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualificationFormula_PK_SubEvent]
    ON [dbo].[SubEventQualificationFormula]([PK_SubEvent] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventQualificationFormula_Value]
    ON [dbo].[SubEventQualificationFormula]([Value] ASC) WITH (FILLFACTOR = 80);

