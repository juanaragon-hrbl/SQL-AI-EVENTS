CREATE TABLE [dbo].[EventDeleteQueue] (
    [PK_Event]       INT           NULL,
    [DeletedDateUTC] SMALLDATETIME DEFAULT (getutcdate()) NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_EventDelete_PK_Event]
    ON [dbo].[EventDeleteQueue]([PK_Event] ASC);

