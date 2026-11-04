CREATE TABLE [dbo].[FeaturedEvents] (
    [PK_FeaturedEvents] INT           IDENTITY (1, 1) NOT NULL,
    [PK_Event]          INT           NOT NULL,
    [PK_DSTeam]         INT           NOT NULL,
    [PK_Locale]         INT           NOT NULL,
    [IsActive]          BIT           CONSTRAINT [DF_FeaturedEvents_IsActive] DEFAULT ((0)) NULL,
    [CreatedUTC]        DATETIME      CONSTRAINT [DF_FeaturedEvents_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]         NVARCHAR (50) CONSTRAINT [DF_FeaturedEvents_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedUTC]       DATETIME      CONSTRAINT [DF_FeaturedEvents_ModifiedUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]        NVARCHAR (50) CONSTRAINT [DF_FeaturedEvents_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_FeaturedEvents] PRIMARY KEY CLUSTERED ([PK_FeaturedEvents] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_FeaturedEvents_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [FK_FeaturedEvents_PK_Locale] FOREIGN KEY ([PK_Locale]) REFERENCES [dbo].[Locales] ([PK_Locale])
);

