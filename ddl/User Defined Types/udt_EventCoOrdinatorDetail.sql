CREATE TYPE [dbo].[udt_EventCoOrdinatorDetail] AS TABLE (
    [PK_EventCoordinatorDetail] INT            NULL,
    [PK_Event]                  INT            NULL,
    [CoordinatorID]             VARCHAR (10)   NULL,
    [CoordinatorName]           NVARCHAR (500) NULL,
    [CoordinatorPhone]          NVARCHAR (200) NULL,
    [CoordinatorEmail]          NVARCHAR (400) NULL,
    [CoordinatorTitle]          NVARCHAR (200) NULL,
    [CoordinatorTeamLevel]      NVARCHAR (200) NULL,
    [CoordinatorWebsite]        NVARCHAR (MAX) NULL,
    [IsDelete]                  BIT            NULL);

