CREATE TABLE [dbo].[MediaType] (
    [PK_MediaType]    INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [MediaTypeDesc]   VARCHAR (100) NOT NULL,
    [CreatedDateUTC]  DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [MediaType_PK] PRIMARY KEY CLUSTERED ([PK_MediaType] ASC) WITH (FILLFACTOR = 80)
);

