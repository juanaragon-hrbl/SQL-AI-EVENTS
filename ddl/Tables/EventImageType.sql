CREATE TABLE [dbo].[EventImageType] (
    [PK_EventImageType] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [EventImageType]    VARCHAR (30) NULL,
    [CreatedDateUTC]    DATETIME     NULL,
    [CreatedBy]         VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]   DATETIME     NULL,
    [ModifiedBy]        VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [PK_EventImageType_PK_EventImageType] PRIMARY KEY CLUSTERED ([PK_EventImageType] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventImageType_EventImageType]
    ON [dbo].[EventImageType]([EventImageType] ASC);

