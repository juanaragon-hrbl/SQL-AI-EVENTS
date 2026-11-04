CREATE TABLE [dbo].[QualificationFrequencyType] (
    [PK_QualificationFrequencyType] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]                DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]                     VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]               DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]                    VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [FrequencyType]                 VARCHAR (50) NULL,
    [FrequencyDesc]                 VARCHAR (50) NULL,
    CONSTRAINT [QualificationFrequencyType_PK] PRIMARY KEY CLUSTERED ([PK_QualificationFrequencyType] ASC) WITH (FILLFACTOR = 80)
);

