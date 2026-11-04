CREATE TABLE [dbo].[Scheduler] (
    [PK_Scheduler]     INT            IDENTITY (1, 1) NOT NULL,
    [SchedulerID]      VARCHAR (10)   NOT NULL,
    [LongDescrp]       VARCHAR (1000) NULL,
    [FreqType]         VARCHAR (15)   NOT NULL,
    [Frequency]        INT            NOT NULL,
    [Unit]             INT            NULL,
    [YearMonth]        INT            NULL,
    [ExactDate]        DATE           NULL,
    [RunTimeUTC]       TIME (7)       DEFAULT ('00:00') NOT NULL,
    [BusinessCalendar] VARCHAR (1)    DEFAULT ('N') NULL,
    [CreatedBy]        NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]   SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]       NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]  SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_Scheduler] PRIMARY KEY CLUSTERED ([PK_Scheduler] ASC),
    CONSTRAINT [CK_Scheduler_ExactDate] CHECK (case when [FreqType]='Custom' then case when [ExactDate] IS NOT NULL then (1) else (0) end else (1) end=(1)),
    CONSTRAINT [CK_Scheduler_FreqType] CHECK ([FreqType]='Yearly' OR [FreqType]='Monthly' OR [FreqType]='Weekly' OR [FreqType]='Daily' OR [FreqType]='Custom'),
    CONSTRAINT [CK_Scheduler_Unit] CHECK (case when [FreqType]='Weekly' then case when [Unit]>=(1) AND [Unit]<=(7) then (1) else (0) end when [FreqType]='Yearly' OR [FreqType]='Monthly' then case when [Unit]>=(1) AND [Unit]<=(31) then (1) else (0) end else (1) end=(1))
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Scheduler_Multi]
    ON [dbo].[Scheduler]([FreqType] ASC, [Frequency] ASC, [Unit] ASC, [YearMonth] ASC, [ExactDate] ASC, [RunTimeUTC] ASC, [BusinessCalendar] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Scheduler_SchedulerID]
    ON [dbo].[Scheduler]([SchedulerID] ASC);

