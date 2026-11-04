CREATE TABLE [dbo].[Schedule] (
    [PK_Schedule]     INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]  DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ScheduleName]    VARCHAR (100) NULL,
    CONSTRAINT [Schedule_PK] PRIMARY KEY CLUSTERED ([PK_Schedule] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_Schedule_ModifiedDateUTC]
    ON [dbo].[Schedule]([ModifiedDateUTC] ASC) WITH (FILLFACTOR = 80);

