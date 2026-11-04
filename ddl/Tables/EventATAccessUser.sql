CREATE TABLE [dbo].[EventATAccessUser] (
    [PK_EventATAccessUser]          INT            IDENTITY (1, 1) NOT NULL,
    [PK_EventATAccessUserType]      INT            NOT NULL,
    [EventATAccessUserName]         NVARCHAR (500) NOT NULL,
    [EventATAccessUserFirstName]    NVARCHAR (500) NULL,
    [EventATAccessUserLastName]     NVARCHAR (500) NULL,
    [EventATAccessUserCountry]      NVARCHAR (50)  NULL,
    [CreatedDateUTC]                SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                     NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]               SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                    NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [EventATAccessUserEmailAddress] NVARCHAR (50)  NULL,
    [IsDeleted]                     BIT NULL,
    [DeletedBy]                     NVARCHAR (50) NULL,
    [DeletedDateUTC]                SMALLDATETIME NULL,
    CONSTRAINT [PK_EventATAccessUser] PRIMARY KEY CLUSTERED ([PK_EventATAccessUser] ASC),
    CONSTRAINT [EventATAccessUser_PK_EventATAccessUserType] FOREIGN KEY ([PK_EventATAccessUserType]) REFERENCES [dbo].[EventATAccessUserTypes] ([PK_EventATAccessUserType])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessUser_PK_EventATAccessUser]
    ON [dbo].[EventATAccessUser]([PK_EventATAccessUser] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessUser_PK_EventATAccessUserType]
    ON [dbo].[EventATAccessUser]([PK_EventATAccessUserType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessUser_EventATAccessUserFirstName]
    ON [dbo].[EventATAccessUser]([EventATAccessUserFirstName] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessUser_EventATAccessUserLastName]
    ON [dbo].[EventATAccessUser]([EventATAccessUserLastName] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventATAccessUser_EventATAccessUserCountry]
    ON [dbo].[EventATAccessUser]([EventATAccessUserCountry] ASC) WITH (FILLFACTOR = 80);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_EventATAccessUserName]
    ON [dbo].[EventATAccessUser]([EventATAccessUserName] ASC);

