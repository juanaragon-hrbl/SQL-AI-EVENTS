CREATE TABLE [dbo].[SubEventQualGroups] (
    [PK_SubEventQualGroup]  INT           IDENTITY (1, 1) NOT NULL,
    [SubEventQualGroupName] VARCHAR (100) NOT NULL,
    [QualificationDuration] INT           NOT NULL,
    [CreatedDateUTC]        DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]             VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]       DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]            VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [SubEventQualGroups_PK] PRIMARY KEY CLUSTERED ([PK_SubEventQualGroup] ASC) WITH (FILLFACTOR = 80)
);

