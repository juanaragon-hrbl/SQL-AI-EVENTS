CREATE TABLE [dbo].[MemberList] (
    [PK_MemberList]     INT           IDENTITY (1, 1) NOT NULL,
    [PK_MemberListName] INT           NULL,
    [MemberID]          INT           NULL,
    [CreatedBy]         NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]    SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]        NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]   SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_MemberList] PRIMARY KEY CLUSTERED ([PK_MemberList] ASC),
    CONSTRAINT [FK_MemberList_MemberListName] FOREIGN KEY ([PK_MemberListName]) REFERENCES [dbo].[MemberListName] ([PK_MemberListName]) ON DELETE CASCADE ON UPDATE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_MemberList_MemberID]
    ON [dbo].[MemberList]([MemberID] ASC);

