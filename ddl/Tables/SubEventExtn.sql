CREATE TABLE [dbo].[SubEventExtn] (
    [PK_SubEventExtn]			INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]			DATETIME      DEFAULT (getutcdate()) NULL,
    [CreatedBy]					VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]			DATETIME      DEFAULT (getutcdate()) NULL,
    [ModifiedBy]				VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_Event]					INT           NOT NULL,
    [PK_SubEvent]				INT           NOT NULL,
    [Icon]						VARCHAR (MAX) NULL,
    [Color]						VARCHAR (MAX) NULL,
	[AllowPartnerRegistration]	BIT			  NULL,
	[HideToPM]					BIT	DEFAULT 0,
    [RegistrationStartDate] DATETIME NULL, 
    [RegistrationDeadlineDate] DATETIME NULL, 
	[ManageLanguages]			BIT NOT NULL DEFAULT 0,
    CONSTRAINT [SubEventExtn_PK] PRIMARY KEY CLUSTERED ([PK_SubEventExtn] ASC),
    CONSTRAINT [Event_SubEventExtn_FK] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event]),
    CONSTRAINT [SubEvent_SubEventExtn_FK] FOREIGN KEY ([PK_SubEvent]) REFERENCES [dbo].[SubEvent] ([PK_SubEvent])
);
GO

CREATE INDEX [IX_SubEventExtn_PK_Event_PK_SubEvent] 
	ON [dbo].[SubEventExtn] ([PK_Event], [PK_SubEvent]) 
INCLUDE ([Icon], [Color])
GO

CREATE INDEX [IX_SubEventExtn_PK_SubEvent] 
	ON [dbo].[SubEventExtn] ([PK_SubEvent]) 
INCLUDE ([Icon], [Color])
GO
