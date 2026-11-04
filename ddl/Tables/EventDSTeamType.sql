CREATE TABLE [dbo].[EventDSTeamType] (
    [PK_EventDSTeamType] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [DSTeamTypeCode]     VARCHAR (5)   NOT NULL,
    [PK_Event]           INT           NOT NULL,
    [CreatedDateUTC]     SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]          NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]    SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]         NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventDSTeamType] PRIMARY KEY CLUSTERED ([PK_EventDSTeamType] ASC),
    CONSTRAINT [PK_Event_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventDSTeamType_DSTeamTypeCode]
    ON [dbo].[EventDSTeamType]([DSTeamTypeCode] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventDSTeamType_PK_Event]
    ON [dbo].[EventDSTeamType]([PK_Event] ASC)
    INCLUDE([DSTeamTypeCode]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventDSTeamType_DSTeamTypeCode_PK_Event]
    ON [dbo].[EventDSTeamType]([DSTeamTypeCode] ASC)
    INCLUDE([PK_Event]);

