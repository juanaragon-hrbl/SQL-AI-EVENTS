CREATE TABLE [dbo].[DSTeamType] (
    [PK_DSTeamType]    INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [DSTeamTypeCode]   VARCHAR (5)   NOT NULL,
    [TeamOrder]        INT           NOT NULL,
    [TeamDisplayOrder] INT           NULL,
    [CreatedDateUTC]   SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]        NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]  SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]       NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
	[TransitionLevelGroup] VARCHAR(5) NULL,
    CONSTRAINT [PK_DSTeamType] PRIMARY KEY CLUSTERED ([PK_DSTeamType] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_DSTeamType_PK_DSTeamType]
    ON [dbo].[DSTeamType]([PK_DSTeamType] ASC);


GO

CREATE NONCLUSTERED INDEX [IX_DSTeamType_DSTeamTypeCode_Covering] 
	ON [dbo].[DSTeamType] ([DSTeamTypeCode])
	INCLUDE(TeamOrder, TeamDisplayOrder)
GO