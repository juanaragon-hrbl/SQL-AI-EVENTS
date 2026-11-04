CREATE TYPE [dbo].[udt_EventVideo] AS TABLE (
    [PK_EventVideo] INT            NULL,
    [VideoName]     NVARCHAR (100) NULL,
    [VideoHTML]     NVARCHAR (MAX) NULL,
    [VideoDesc]     VARCHAR (100)  NULL);

