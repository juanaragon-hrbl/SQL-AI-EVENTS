CREATE TABLE [dbo].[TempGuestSpeakers] (
    [PK_TempGuestSpeaker] INT            IDENTITY (-1, -1) NOT FOR REPLICATION NOT NULL,
    [TempSpeakerName]     NVARCHAR (100) NULL,
    [CreatedDateUTC]      DATETIME       NULL,
    [CreatedBy]           VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]     DATETIME       NULL,
    [ModifiedBy]          VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    CONSTRAINT [PK_TempGuestSpeakers_PK_TempGuestSpeaker] PRIMARY KEY CLUSTERED ([PK_TempGuestSpeaker] ASC)
);

