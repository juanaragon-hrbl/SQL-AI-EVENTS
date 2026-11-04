CREATE TABLE [dbo].[LanguageGroup] (
    [PK_LanguageGroup] INT           IDENTITY (1, 1) NOT NULL,
    [LanguageGroup]    VARCHAR (30)  NOT NULL,
    [CreatedUTC]       DATETIME      CONSTRAINT [DF_LanguageGroup_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]        NVARCHAR (50) CONSTRAINT [DF_LanguageGroup_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC]      DATETIME      CONSTRAINT [DF_LanguageGroup_ModifiedUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]       NVARCHAR (50) CONSTRAINT [DF_LanguageGroup_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_LanguageGroup] PRIMARY KEY CLUSTERED ([PK_LanguageGroup] ASC)
);

