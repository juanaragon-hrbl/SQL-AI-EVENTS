CREATE TABLE [dbo].[UploadedMemberConfig] (
    [PK_UploadedMemberConfig] INT           IDENTITY (1, 1) NOT NULL,
    [Running]                 BIT           NULL,
    [LastUser]                VARCHAR (255) NULL,
    [LastRun]                 DATETIME2 (7) NULL,
    [CreatedDateUTC]          DATETIME2 (7) CONSTRAINT [DF_UploadedMemberConfig_CreatedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]               VARCHAR (255) CONSTRAINT [DF_UploadedMemberConfig_CreatedBy] DEFAULT (replace(suser_name(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]         DATETIME2 (7) CONSTRAINT [DF_UploadedMemberConfig_ModifiedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]              VARCHAR (255) CONSTRAINT [DF_UploadedMemberConfig_ModifiedBy] DEFAULT (replace(suser_name(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_UploadedMemberConfig_PK_UploadedMemberConfig] PRIMARY KEY CLUSTERED ([PK_UploadedMemberConfig] ASC)
);

