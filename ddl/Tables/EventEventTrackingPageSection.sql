CREATE TABLE [dbo].[EventEventTrackingPageSection] (
    [PK_EventEventTrackingPageSection] INT           IDENTITY (1, 1) NOT NULL,
    [PK_Event]                         INT           NOT NULL,
    [PK_EventTrackingPageSection]      INT           NOT NULL,
    [TrackingPageSectionDisplayOrder]  INT           NOT NULL,
    [CreatedDateUTC]                   SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                        NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]                  SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                       NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventEventTrackingPageSection] PRIMARY KEY CLUSTERED ([PK_EventEventTrackingPageSection] ASC),
    CONSTRAINT [EventEventTrackingPageSection_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [EventEventTrackingPageSection_PK_EventTrackingPageSection] FOREIGN KEY ([PK_EventTrackingPageSection]) REFERENCES [dbo].[EventTrackingPageSection] ([PK_EventTrackingPageSection])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventEventTrackingPageSection_PK_Event]
    ON [dbo].[EventEventTrackingPageSection]([PK_Event] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventEventTrackingPageSection_PK_EventTrackingPageSection]
    ON [dbo].[EventEventTrackingPageSection]([PK_EventTrackingPageSection] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EventEventTrackingPageSection_TrackingPageSectionDisplayOrder]
    ON [dbo].[EventEventTrackingPageSection]([TrackingPageSectionDisplayOrder] ASC);

