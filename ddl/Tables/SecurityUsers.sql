CREATE TABLE [dbo].[SecurityUsers] (
    [PK_SecurityUser] INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [UserID]          VARCHAR (20)   NOT NULL,
    [UserPassword]    VARCHAR (20)   NOT NULL,
    [CreatedDateUTC]  DATETIME       DEFAULT (getutcdate()) NULL,
    [UserTimeZone]    NUMERIC (5, 2) DEFAULT ((-8)) NOT NULL,
    [CreatedBy]       VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME       DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [SecurityUsers_PK] PRIMARY KEY CLUSTERED ([PK_SecurityUser] ASC) WITH (FILLFACTOR = 80)
);

