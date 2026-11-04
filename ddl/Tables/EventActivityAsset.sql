CREATE TABLE [dbo].[EventActivityAsset] (
    [PK_EventActivityAsset] INT           IDENTITY (1, 1) NOT NULL,
    [PK_AssetType]          INT           NOT NULL,
    [PK_EventActivity]      INT           NOT NULL,
    [ActivityAsset]         VARCHAR (50)  NOT NULL,
    [AssetOrder]            INT           NOT NULL,
    [CreatedUTC]            DATETIME      CONSTRAINT [DF_EventActivityAsset_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]             NVARCHAR (50) CONSTRAINT [DF_EventActivityAsset_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC]           DATETIME      CONSTRAINT [DF_EventActivityAsset_ModifiedUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]            NVARCHAR (50) CONSTRAINT [DF_EventActivityAsset_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventActivityAsset] PRIMARY KEY CLUSTERED ([PK_EventActivityAsset] ASC),
    CONSTRAINT [FK_EventActivityAsset_AssetType] FOREIGN KEY ([PK_AssetType]) REFERENCES [dbo].[AssetType] ([PK_AssetType]),
    CONSTRAINT [FK_EventActivityAsset_EventActivity] FOREIGN KEY ([PK_EventActivity]) REFERENCES [dbo].[EventActivity] ([PK_EventActivity])
);

