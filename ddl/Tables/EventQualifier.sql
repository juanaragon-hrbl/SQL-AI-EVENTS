CREATE TABLE [dbo].[EventQualifier] (
    [PK_EventQualifier] BIGINT       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]    DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]         VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]   DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]        VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]          INT          NULL,
    [PK_Distributor]    INT          NULL,
    [DistributorID]     VARCHAR (30) NULL,
    [Qualified]         INT          DEFAULT ((1)) NOT NULL,
    CONSTRAINT [EventQualifier_PK] PRIMARY KEY CLUSTERED ([PK_EventQualifier] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventQualifier_PK_Distributor]
    ON [dbo].[EventQualifier]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventQualifier_PK_Event]
    ON [dbo].[EventQualifier]([PK_Event] ASC);


GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
    ON [dbo].[EventQualifier]([DistributorID] ASC)
    INCLUDE([PK_Event]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_EventQualifier_PK_Event_Covering]
    ON [dbo].[EventQualifier]([PK_Event] ASC)
    INCLUDE([PK_EventQualifier], [PK_Distributor]);

