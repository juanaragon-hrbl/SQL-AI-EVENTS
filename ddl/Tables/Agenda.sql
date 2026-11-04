CREATE TABLE [dbo].[Agenda] (
    [PK_Agenda]         INT           IDENTITY (1, 1) NOT NULL,
    [PK_Event]          INT           NULL,
    [AgendaLanguage]    VARCHAR (10)  NULL,
    [AgendaDescription] VARCHAR (200) NULL,
    [CreatedUTC]        DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]         VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [UpdatedUTC]        DATETIME      DEFAULT (getutcdate()) NULL,
    [UpdatedBy]         VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    PRIMARY KEY CLUSTERED ([PK_Agenda] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Agenda_PK_Event]
    ON [dbo].[Agenda]([PK_Event] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_Agenda_AgendaLanguage]
    ON [dbo].[Agenda]([AgendaLanguage] ASC) WITH (FILLFACTOR = 80);

