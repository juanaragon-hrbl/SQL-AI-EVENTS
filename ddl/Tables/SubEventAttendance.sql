CREATE TABLE [dbo].[SubEventAttendance] (
    [PK_SubEventAttendance]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AttendanceFromTimeUTC]   SMALLDATETIME NULL,
    [AttendanceToTimeUTC]     SMALLDATETIME NULL,
    [CreatedDateUTC]          SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]               VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]         SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]              VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [PK_SubEventRegistration] INT           NOT NULL,
    [PK_EventSecurityBadge]   INT           NULL,
    CONSTRAINT [SubEventAttendance_PK] PRIMARY KEY CLUSTERED ([PK_SubEventAttendance] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [SubEventRegistrationSubEventAttendance_FK] FOREIGN KEY ([PK_SubEventRegistration]) REFERENCES [dbo].[SubEventRegistration] ([PK_SubEventRegistration])
);

