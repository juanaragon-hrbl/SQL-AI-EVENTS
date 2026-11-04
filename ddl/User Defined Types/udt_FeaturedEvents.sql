CREATE TYPE [dbo].[udt_FeaturedEvents] AS TABLE (
    [PK_Event]  INT           NOT NULL,
    [Locales]   VARCHAR (MAX) NULL,
    [PK_DSTeam] INT           NOT NULL,
    [IsActive]  BIT           NULL);

