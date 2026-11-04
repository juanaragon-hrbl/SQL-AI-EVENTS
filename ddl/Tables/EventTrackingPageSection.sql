CREATE TABLE [dbo].[EventTrackingPageSection] (
    [PK_EventTrackingPageSection]  INT            IDENTITY (1, 1) NOT NULL,
    [EventTrackingPageSectionName] NVARCHAR (250) NOT NULL,
    [CreatedDateUTC]               SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                    NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]              SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                   NVARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventTrackingPageSection] PRIMARY KEY CLUSTERED ([PK_EventTrackingPageSection] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventTrackingPageSection_EventTrackingPageSectionName]
    ON [dbo].[EventTrackingPageSection]([EventTrackingPageSectionName] ASC);

