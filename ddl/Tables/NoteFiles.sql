CREATE TABLE [dbo].[NoteFiles] (
    [PK_Notefiles] INT           IDENTITY (1, 1) NOT NULL,
    [FileName]     VARCHAR (150) NOT NULL,
    [UploadDate]   DATETIME      NOT NULL,
    [UploadBy]     VARCHAR (100) NULL,
    [Records]      INT           NULL,
    [EventID]      INT           NOT NULL,
    CONSTRAINT [PK_NoteFiles] PRIMARY KEY CLUSTERED ([PK_Notefiles] ASC)
);

