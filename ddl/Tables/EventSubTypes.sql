CREATE TABLE [dbo].[EventSubTypes] (
    [PK_EventSubType]      INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_EventType]         INT            NOT NULL,
    [EventSubType]         VARCHAR (200)  NOT NULL,
    [EventSubTypeDesc]     NVARCHAR (400) NULL,
    [CreatedDateUTC]       SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]            NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]      SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]           NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [PK_EventSubTypeGroup] INT            NULL,
    [IsActive]             BIT            DEFAULT ((0)) NULL,
    CONSTRAINT [EventSubTypes_PK_EventSubType] PRIMARY KEY CLUSTERED ([PK_EventSubType] ASC),
    CONSTRAINT [EventSubTypes_PK_EventSubTypeGroup] FOREIGN KEY ([PK_EventSubTypeGroup]) REFERENCES [dbo].[EventSubTypeGroup] ([PK_EventSubTypeGroup]),
    CONSTRAINT [EventType_FK] FOREIGN KEY ([PK_EventType]) REFERENCES [dbo].[EventType] ([PK_EventType])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventSubType_PK_EventSubType]
    ON [dbo].[EventSubTypes]([PK_EventSubType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventSubType_PK_EventType]
    ON [dbo].[EventSubTypes]([PK_EventType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventSubType_EventSubType]
    ON [dbo].[EventSubTypes]([EventSubType] ASC) WITH (FILLFACTOR = 80);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_EventSubType_PK_EventType_EventSubType]
    ON [dbo].[EventSubTypes]([PK_EventType] ASC, [EventSubType] ASC) WITH (FILLFACTOR = 80);

