CREATE TABLE [dbo].[EventSubTypeGroup] (
    [PK_EventSubTypeGroup]       INT           IDENTITY (1, 1) NOT NULL,
    [PK_EventSubTypeGroupMaster] INT           NOT NULL,
    [PK_EventType]               INT           NOT NULL,
    [CreatedDateUTC]             SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                  NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]            SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                 NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventSubTypeGroup] PRIMARY KEY CLUSTERED ([PK_EventSubTypeGroup] ASC),
    CONSTRAINT [EventSubTypeGroup_PK_EventSubTypeGroupMaster] FOREIGN KEY ([PK_EventSubTypeGroupMaster]) REFERENCES [dbo].[EventSubTypeGroupMaster] ([PK_EventSubTypeGroupMaster]),
    CONSTRAINT [EventSubTypeGroup_PK_EventType] FOREIGN KEY ([PK_EventType]) REFERENCES [dbo].[EventType] ([PK_EventType]),
    CONSTRAINT [IX_EventSubTypeGroup_EventType] UNIQUE NONCLUSTERED ([PK_EventType] ASC, [PK_EventSubTypeGroupMaster] ASC)
);

