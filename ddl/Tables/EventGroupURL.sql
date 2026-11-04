CREATE TABLE [dbo].[EventGroupURL] (
    [PK_EventGroupURL]  INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_EventGroup]     INT             NOT NULL,
    [PK_Locale]         INT             NOT NULL,
    [PK_EventURLType]   INT             DEFAULT ((1)) NULL,
    [EventGroupURL]     NVARCHAR (4000) NULL,
    [EventGroupURLDesc] NVARCHAR (4000) NULL,
    [Flyer]             NVARCHAR (4000) NULL,
    [CreatedDateUTC]    SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]         NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]   SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]        NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventGroupURL] PRIMARY KEY CLUSTERED ([PK_EventGroupURL] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_EventGroupURL_PK_EventGroup] FOREIGN KEY ([PK_EventGroup]) REFERENCES [dbo].[EventGroups] ([PK_EventGroup]),
    CONSTRAINT [FK_EventGroupURL_PK_EventURLType] FOREIGN KEY ([PK_EventURLType]) REFERENCES [dbo].[EventURLType] ([PK_EventURLType]),
    CONSTRAINT [FK_EventGroupURL_PK_Locale] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale])
);

