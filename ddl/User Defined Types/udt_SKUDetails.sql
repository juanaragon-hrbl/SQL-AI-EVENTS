CREATE TYPE [dbo].[udt_SKUDetails] AS TABLE (
    [SKUCode]      NVARCHAR (4) NULL,
    [CountryCode]  NVARCHAR (2) NULL,
    [LocaleCode]   NVARCHAR (5) NULL,
    [SKUBeginDate] DATETIME     NULL,
    [SKUEndDate]   DATETIME     NULL);

