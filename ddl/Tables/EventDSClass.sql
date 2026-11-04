CREATE TABLE [dbo].[EventDSClass] (
    [PK_EventDSClass] INT           IDENTITY (1, 1) NOT NULL,
    [DSClassCode]     VARCHAR (30)  NOT NULL,
    [CreatedDateUTC]  SMALLDATETIME DEFAULT (getdate()) NOT NULL,
    [CreatedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC] SMALLDATETIME DEFAULT (getdate()) NOT NULL,
    [ModifiedBy]      VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [EventDSClass_PK] PRIMARY KEY CLUSTERED ([PK_EventDSClass] ASC)
);

