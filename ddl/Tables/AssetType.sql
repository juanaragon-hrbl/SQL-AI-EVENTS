CREATE TABLE [dbo].[AssetType] (
    [PK_AssetType] INT           IDENTITY (1, 1) NOT NULL,
    [AssetType]    VARCHAR (50)  NOT NULL,
    [CreatedUTC]   DATETIME      CONSTRAINT [DF_AssetType_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]    NVARCHAR (50) CONSTRAINT [DF_AssetType_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC]  DATETIME      CONSTRAINT [DF_AssetType_ModifiedUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]   NVARCHAR (50) CONSTRAINT [DF_AssetType_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_AssetType] PRIMARY KEY CLUSTERED ([PK_AssetType] ASC)
);

