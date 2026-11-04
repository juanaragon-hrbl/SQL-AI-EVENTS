CREATE TYPE [dbo].[udt_EventGuestSpeakers] AS TABLE (
    [PK_EventGuestSpeaker]       INT            NULL,
    [PK_GuestSpeaker]            INT            NULL,
    [PK_EventGuestSpeakerLocale] INT            NULL,
    [PK_Event]                   INT            NULL,
    [EventSpeakerName]           NVARCHAR (100) NULL,
    [EventSpeakerTitle]          NVARCHAR (100) NULL,
    [EventSpeakerPhone]          NVARCHAR (20)  NULL,
    [EventSpeakerEmail]          NVARCHAR (50)  NULL,
    [EventSpeakerTeamLevel]      NVARCHAR (100) NULL,
    [EventSpeakerBio]            NVARCHAR (MAX) NULL,
    [EventGuestSpeakerImage]     NVARCHAR (MAX) NULL,
    [EventGuestSpeakerURL]       NVARCHAR (MAX) NULL,
    [LocaleCode]                 VARCHAR (5)    NULL);

