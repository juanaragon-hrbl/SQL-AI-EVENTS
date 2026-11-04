CREATE TABLE [dbo].[EventATAccessUserTypes] (
    [PK_EventATAccessUserType] INT            IDENTITY (1, 1) NOT NULL,
    [EventATAccessUserType]    NVARCHAR (500) NOT NULL,
    [CreatedDateUTC]           SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]          SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]               NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventATAccessUserType] PRIMARY KEY CLUSTERED ([PK_EventATAccessUserType] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessUserTypes_PK_EventATAccessUserType]
    ON [dbo].[EventATAccessUserTypes]([PK_EventATAccessUserType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessUserTypes_EventATAccessUserType]
    ON [dbo].[EventATAccessUserTypes]([EventATAccessUserType] ASC);

