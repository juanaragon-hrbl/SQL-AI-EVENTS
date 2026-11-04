CREATE TYPE [dbo].[udt_EventAudio] AS TABLE (
    [PK_EventAudio] INT            NULL,
    [AudioName]     NVARCHAR (100) NULL,
    [AudioHTML]     NVARCHAR (MAX) NULL,
    [AudioDesc]     VARCHAR (100)  NULL,
    [MediaType]     INT            NULL,
    [LocaleCode]    CHAR (5)       NULL);

