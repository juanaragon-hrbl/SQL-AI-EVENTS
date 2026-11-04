CREATE TABLE [dbo].[EventOwners] (
    [PK_EventOwners]   INT            IDENTITY (1, 1) NOT NULL,
    [PK_Event]        INT            NOT NULL,
    [PK_EventATAccessUser]    INT            NOT NULL,
    [CreatedBy]       NVARCHAR (100) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [CreatedDateUTC]  DATETIME2 (7)  DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_EventOwners] PRIMARY KEY CLUSTERED ([PK_EventOwners] ASC),
    CONSTRAINT [PK_EventOwners_PK_EventATAccessUser] FOREIGN KEY ([PK_EventATAccessUser]) REFERENCES [dbo].[EventATAccessUser] ([PK_EventATAccessUser]),
    CONSTRAINT [FK_EventOwners_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
);