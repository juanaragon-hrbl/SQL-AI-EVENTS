CREATE TABLE [dbo].[MemberType] (
    [PK_MemberType]   INT           IDENTITY (1, 1) NOT NULL,
    [MemberTypeID]    VARCHAR (2)   NULL,
    [Descript]        VARCHAR (20)  NULL,
    [CreatedBy]       NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]  SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]      NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC] SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_MemberType] PRIMARY KEY CLUSTERED ([PK_MemberType] ASC)
);

