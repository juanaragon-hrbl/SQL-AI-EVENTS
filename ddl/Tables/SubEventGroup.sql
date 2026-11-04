CREATE TABLE [dbo].[SubEventGroup] (
    [PK_SubEventGroup]  INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [SubEventGroup]     VARCHAR (5)  NOT NULL,
    [SubEventGroupName] VARCHAR (50) NOT NULL,
    [CreatedDateUTC]    DATETIME     DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]         VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]   DATETIME     DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]        VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [DisplayOrder]      INT          DEFAULT ((4)) NOT NULL,
	[IsActive]			BIT,
    CONSTRAINT [SubEventGroup_PK] PRIMARY KEY CLUSTERED ([PK_SubEventGroup] ASC) WITH (FILLFACTOR = 80)
);

