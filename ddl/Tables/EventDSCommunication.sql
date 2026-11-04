CREATE TABLE [dbo].[EventDSCommunication] (
    [PK_EventDSCommunication] INT           IDENTITY (1, 1) NOT NULL,
    [CreatedDate]             DATETIME      DEFAULT (getdate()) NULL,
    [CreatedBy]               VARCHAR (30)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDate]            DATETIME      DEFAULT (getdate()) NULL,
    [ModifiedBy]              VARCHAR (30)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [EventType]               INT           NULL,
    [PK_Country]              INT           NULL,
    [Email]                   VARCHAR (250) NULL,
    [Phone]                   VARCHAR (100) NULL,
    [Fax]                     VARCHAR (100) NULL,
    [PK_Event]                INT           NULL,
    CONSTRAINT [CS_EventDSCommunication_PK_EventDSCommunication] PRIMARY KEY CLUSTERED ([PK_EventDSCommunication] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventDSCommunication_PK_Country]
    ON [dbo].[EventDSCommunication]([PK_Country] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventDSCommunication_EventType]
    ON [dbo].[EventDSCommunication]([EventType] ASC);

