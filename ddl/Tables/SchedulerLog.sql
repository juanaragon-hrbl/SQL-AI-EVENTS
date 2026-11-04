CREATE TABLE [dbo].[SchedulerLog] (
    [PK_SchedulerLog] INT             IDENTITY (1, 1) NOT NULL,
    [SchedulerType]   VARCHAR (25)    NOT NULL,
    [SchedulerTypeID] INT             NOT NULL,
    [StartTimeUTC]    DATETIME        NULL,
    [EndTimeUTC]      DATETIME        NULL,
    [RunStatus]       VARCHAR (25)    NULL,
    [SQLProcedure]    NVARCHAR (128)  NULL,
    [SQLScript]       NVARCHAR (4000) NULL,
    [SQLErrorNumber]  INT             NULL,
    [SQLErrorMsg]     NVARCHAR (4000) NULL,
    [CreatedBy]       NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]  SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]      NVARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC] SMALLDATETIME   DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_SchedulerLog] PRIMARY KEY CLUSTERED ([PK_SchedulerLog] ASC)
);

