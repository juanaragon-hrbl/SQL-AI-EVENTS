CREATE TABLE [dbo].[LanguageList] (
    [PK_LanguageList]  INT           IDENTITY (1, 1) NOT NULL,
    [PK_LanguageGroup] INT           NOT NULL,
    [LanguageID]       INT           NOT NULL,
    [Sequence]         INT           CONSTRAINT [DF_LanguageList_Sequence] DEFAULT ((0)) NOT NULL,
    [CreatedUTC]       DATETIME      CONSTRAINT [DF_LanguageList_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]        NVARCHAR (50) CONSTRAINT [DF_LanguageList_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC]      DATETIME      CONSTRAINT [DF_LanguageList_ModifiedUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]       NVARCHAR (50) CONSTRAINT [DF_LanguageList_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_LanguageList] PRIMARY KEY CLUSTERED ([PK_LanguageList] ASC),
    CONSTRAINT [FK_LanguageList_LanguageGroup] FOREIGN KEY ([PK_LanguageGroup]) REFERENCES [dbo].[LanguageGroup] ([PK_LanguageGroup])
);

