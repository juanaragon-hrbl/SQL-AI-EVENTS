CREATE TYPE [dbo].[udt_EventURL] AS TABLE (
    [PK_EventURL]  INT             NULL,
    [PK_Event]     INT             NULL,
    [LocaleCode]   CHAR (5)        NULL,
    [EventURL]     NVARCHAR (4000) NULL,
    [EventURLDesc] NVARCHAR (4000) NULL,
    [Flyer]        NVARCHAR (4000) NULL,
    [IsDelete]     BIT             NULL);

