CREATE TABLE [dbo].[QualificationType] (
    [PK_QualificationType] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]       DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]            VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]      DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]           VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [QualType]             VARCHAR (50) NULL,
    CONSTRAINT [QualificationType_PK] PRIMARY KEY CLUSTERED ([PK_QualificationType] ASC) WITH (FILLFACTOR = 80)
);

