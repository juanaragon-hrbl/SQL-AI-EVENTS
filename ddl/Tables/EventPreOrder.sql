CREATE TABLE [dbo].[EventPreOrder] (
    [PK_EventPreOrder] INT           IDENTITY (1, 1) NOT NULL,
    [PK_Event]         INT           NOT NULL,
    [SubEventNumber]   INT           NOT NULL,
    [CreatedDateUTC]   SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]        NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]  SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]       NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventPreOrder] PRIMARY KEY CLUSTERED ([PK_EventPreOrder] ASC),
    CONSTRAINT [FK_PK_EventPreOrder_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventPreOrder_PK_Event]
    ON [dbo].[EventPreOrder]([PK_Event] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventPreOrder_SubEventNumber]
    ON [dbo].[EventPreOrder]([SubEventNumber] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventPreOrder_PK_Event_SubEventNumber]
    ON [dbo].[EventPreOrder]([PK_Event] ASC, [SubEventNumber] ASC);

