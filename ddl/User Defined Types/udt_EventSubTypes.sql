CREATE TYPE [dbo].[udt_EventSubTypes] AS TABLE (
    [PK_SubType]        INT            NULL,
    [SubTypeName]       NVARCHAR (200) NULL,
    [SubTypeTraslation] NVARCHAR (400) NULL,
    [SubTypeDesc]       NVARCHAR (200) NULL,
    [CodeType]          INT            NULL,
    [IsActive]          BIT            NULL,
    [Image]             NVARCHAR (255) NULL);

