CREATE TABLE [dbo].[SubEventType] (
    [PK_SubEventType]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]    DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]         VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]   DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]        VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [SubEventType]      VARCHAR (200) NULL,
    [IsGeneralSubEvent] BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [SubEventType_PK] PRIMARY KEY CLUSTERED ([PK_SubEventType] ASC) WITH (FILLFACTOR = 80)
);

