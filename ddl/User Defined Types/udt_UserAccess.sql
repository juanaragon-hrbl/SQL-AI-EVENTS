CREATE TYPE [dbo].[udt_UserAccess] AS TABLE (
    [UserID]        NVARCHAR (50)   NULL,
    [UserFirstName] NVARCHAR (50)   NULL,
    [UserLastName]  NVARCHAR (50)   NULL,
    [Country]       NVARCHAR (50)   NULL,
    [EmailAddress]  NVARCHAR (50)   NULL,
    [Locale]        NVARCHAR (4000) NULL,
    [AccessLevel]   INT             NULL,
    [CheckedYN]     INT             NULL);

