CREATE TYPE [dbo].[udt_LPImage] AS TABLE (
    [PK_EventGroupImageLocale] INT            NULL,
    [PK_EventGroup]            INT            NULL,
    [PK_EventImageType]        INT            NOT NULL,
    [PK_Locale]                INT            NOT NULL,
    [ImageTitle]               NVARCHAR (50)  NULL,
    [ImageLocation]            NVARCHAR (250) NOT NULL,
    [IsActive]                 BIT            NOT NULL);

