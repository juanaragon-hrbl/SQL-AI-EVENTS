CREATE TABLE [dbo].[EventGroupType] (
    [PK_EventGroupType]  INT           IDENTITY (1, 1) NOT NULL,
    [EventGroupType]     VARCHAR (5)   NOT NULL,
    [EventGroupTypeName] VARCHAR (100) NOT NULL,
    [CreatedDateUTC]     DATETIME      DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]          VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]    DATETIME      DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]         VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [EventGroupType_PK] PRIMARY KEY CLUSTERED ([PK_EventGroupType] ASC) WITH (FILLFACTOR = 80)
);

