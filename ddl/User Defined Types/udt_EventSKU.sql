CREATE TYPE [dbo].[udt_EventSKU] AS TABLE (
    [PK_EventSKULocaleDesc] INT            NULL,
    [PK_Event]              INT            NULL,
    [PK_EventSKU]           INT            NULL,
    [SKUCode]               VARCHAR (4)    NULL,
    [SKUDesc]               VARCHAR (100)  NULL,
    [SKUValidBeginUTC]      DATETIME       NULL,
    [SKUValidEndUTC]        DATETIME       NULL,
    [PK_Country]            INT            NULL,
    [IsEventTicketSKU]      INT            NULL,
    [SKUDescLocale]         NVARCHAR (200) NULL,
    [PK_Locale]             INT            NULL,
    [PK_EventSKUType]       INT            NULL,
    [IsDelete]              BIT            NULL,
    [IsTrackingVisible]     BIT            NULL);

