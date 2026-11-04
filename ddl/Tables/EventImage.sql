CREATE TABLE [dbo].[EventImage] (
    [PK_EventImage]      INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [EventImageLocation] NVARCHAR (4000) NULL,
    [CreatedDateUTC]     DATETIME        NULL,
    [CreatedBy]          VARCHAR (50)    DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]    DATETIME        NULL,
    [ModifiedBy]         VARCHAR (50)    DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]           INT             NULL,
    [PK_EventImageType]  INT             NULL,
    CONSTRAINT [PK_EventImage_PK_EventImage] PRIMARY KEY CLUSTERED ([PK_EventImage] ASC),
    CONSTRAINT [FK_EventImage_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [FK_EventImage_PK_EventImageType] FOREIGN KEY ([PK_EventImageType]) REFERENCES [dbo].[EventImageType] ([PK_EventImageType])
);


GO
CREATE NONCLUSTERED INDEX [IX_EventImage_PK_Event_Covering] 
	ON [dbo].[EventImage] ([PK_Event])
	INCLUDE(EventImageLocation, PK_EventImageType)
GO

CREATE NONCLUSTERED INDEX [IX_EventImage_PK_EventImageType]
    ON [dbo].[EventImage]([PK_EventImageType] ASC);

