CREATE TABLE [dbo].[EventGroupMembers] (
    [PK_EventGroupMember] INT           IDENTITY (1, 1) NOT NULL,
    [CreatedBy]           VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]      SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]          VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]     SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [PK_Event]            INT           NOT NULL,
    [PK_EventGroup]       INT           NOT NULL,
    CONSTRAINT [EventGroupMembers_PK] PRIMARY KEY CLUSTERED ([PK_EventGroupMember] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventEventGroupMembers_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [EventGroupsEventGroupMembers_FK] FOREIGN KEY ([PK_EventGroup]) REFERENCES [dbo].[EventGroups] ([PK_EventGroup])
);

