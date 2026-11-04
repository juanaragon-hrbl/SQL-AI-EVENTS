CREATE TABLE [dbo].[BadgeStatus] (
    [PK_BadgeStatus]  INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]  DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]       NVARCHAR (30) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      NVARCHAR (30) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [BadgeStatus]     VARCHAR (11)  NULL,
    PRIMARY KEY CLUSTERED ([PK_BadgeStatus] ASC) WITH (FILLFACTOR = 80)
);

