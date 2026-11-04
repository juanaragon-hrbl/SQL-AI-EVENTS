CREATE TABLE [dbo].[HLCBIEventMapping] (
    [PK_HLCBIMapping] INT            IDENTITY (1, 1) NOT NULL,
    [PK_Event]        INT            NULL,
    [EventID]         INT            NOT NULL,
    [EventName]       NVARCHAR (200) NULL,
    [CreatedDate]     DATETIME       DEFAULT (getutcdate()) NULL,
    [CreatedBy]       VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDate]    DATETIME       DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [HLCBIEventMapping_PK_HLCBIMapping] PRIMARY KEY CLUSTERED ([PK_HLCBIMapping] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [HLCBIEventMapping_PK_Event_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);


GO
CREATE NONCLUSTERED INDEX [IX_HLCBIEventMapping_EventID]
    ON [dbo].[HLCBIEventMapping]([EventID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_HLCBIEventMapping_PK_Event]
    ON [dbo].[HLCBIEventMapping]([PK_Event] ASC) WITH (FILLFACTOR = 80);

