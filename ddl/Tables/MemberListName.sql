CREATE TABLE [dbo].[MemberListName] (
    [PK_MemberListName] INT           IDENTITY (1, 1) NOT NULL,
    [ListName]          VARCHAR (20)  NULL,
    [PK_MemberType]     INT           NULL,
    [IsSystem]          BIT           DEFAULT ((0)) NULL,
    [CreatedBy]         NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]    SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]        NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]   SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_MemberListName] PRIMARY KEY CLUSTERED ([PK_MemberListName] ASC)
);

