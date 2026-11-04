CREATE TABLE [dbo].[EventURLType] (
    [PK_EventURLType] INT           IDENTITY (1, 1) NOT NULL,
    [EventURLType]    VARCHAR (50)  NULL,
    [CreatedDateUTC]  DATETIME      CONSTRAINT [df_CreatedDate] DEFAULT (getutcdate()) NULL,
    [ModifiedDateUTC] DATETIME      CONSTRAINT [df_ModifiedDate] DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      NVARCHAR (50) CONSTRAINT [df_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [CreatedBy]       NVARCHAR (50) CONSTRAINT [df_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    PRIMARY KEY CLUSTERED ([PK_EventURLType] ASC)
);

