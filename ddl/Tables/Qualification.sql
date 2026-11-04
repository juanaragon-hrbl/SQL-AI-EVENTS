CREATE TABLE [dbo].[Qualification] (
    [PK_Qualification]              INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]                DATETIME      CONSTRAINT [DF__Qualifica__Creat__4461B9CA] DEFAULT (getutcdate()) NULL,
    [CreatedBy]                     VARCHAR (50)  CONSTRAINT [DF__Qualifica__Creat__4555DE03] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]               DATETIME      CONSTRAINT [DF__Qualifica__Modif__464A023C] DEFAULT (getutcdate()) NULL,
    [ModifiedBy]                    VARCHAR (50)  CONSTRAINT [DF__Qualifica__Modif__473E2675] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_QualificationType]          INT           NULL,
    [Qualification]                 VARCHAR (100) NULL,
    [QualificationAbbreviation]     VARCHAR (30)  NULL,
    [QualificationMetric]           VARCHAR (50)  NULL,
    [QualificationFrequency]        INT           NULL,
    [QualificationDuration]         INT           NULL,
    [StoredProcedureName]           VARCHAR (250) NULL,
    [PK_QualificationFrequencyType] INT           NULL,
    CONSTRAINT [Qualification_PK] PRIMARY KEY CLUSTERED ([PK_Qualification] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [QualificationFrequencyTypeQualification_FK] FOREIGN KEY ([PK_QualificationFrequencyType]) REFERENCES [dbo].[QualificationFrequencyType] ([PK_QualificationFrequencyType]),
    CONSTRAINT [QualificationTypeQualification_FK] FOREIGN KEY ([PK_QualificationType]) REFERENCES [dbo].[QualificationType] ([PK_QualificationType])
);


GO
CREATE NONCLUSTERED INDEX [IX_Qualification_PK_QualificationType]
    ON [dbo].[Qualification]([PK_QualificationType] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_Qualification_QualificationDuration]
    ON [dbo].[Qualification]([QualificationDuration] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_Qualification_QualificationFrequency]
    ON [dbo].[Qualification]([QualificationFrequency] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_Qualification_QualificationMetric]
    ON [dbo].[Qualification]([QualificationMetric] ASC) WITH (FILLFACTOR = 80);

