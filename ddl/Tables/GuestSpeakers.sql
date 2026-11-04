CREATE TABLE [dbo].[GuestSpeakers] (
    [PK_GuestSpeaker] INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [SpeakerName]     NVARCHAR (100) NULL,
    [CreatedDateUTC]  DATETIME       NULL,
    [CreatedBy]       VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] DATETIME       NULL,
    [ModifiedBy]      VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [PK_GuestSpeakers_PK_GuestSpeaker] PRIMARY KEY CLUSTERED ([PK_GuestSpeaker] ASC)
);

