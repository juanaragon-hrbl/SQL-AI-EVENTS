CREATE TABLE [dbo].[DistributorEventAttendance] (
    [PK_DistributorEventAttendance] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [DistributorID]                 VARCHAR (14) NOT NULL,
    [AddEvents]                     VARCHAR (20) NULL,
    [MinEventCount]                 SMALLINT     NULL,
    [EventsAttended]                INT          NULL,
    [CorpEventsAttended]            INT          NULL,
    CONSTRAINT [PK_DistributorEventAttendance] PRIMARY KEY CLUSTERED ([PK_DistributorEventAttendance] ASC)
);

