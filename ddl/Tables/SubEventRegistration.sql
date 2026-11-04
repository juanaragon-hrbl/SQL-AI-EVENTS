CREATE TABLE [dbo].[SubEventRegistration] (
    [PK_SubEventRegistration] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]          DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]               VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC]         DATETIME     DEFAULT (getutcdate()) NULL,
    [ModifiedBy]              VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [PK_EventsRegistration]   INT          NOT NULL,
    [PK_SubEventQualifier]    BIGINT       NULL,
    [Registered]              INT          DEFAULT ((1)) NOT NULL,
    CONSTRAINT [SubEventRegistration_PK] PRIMARY KEY CLUSTERED ([PK_SubEventRegistration] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventsRegistrationSubEventRegistration_FK] FOREIGN KEY ([PK_EventsRegistration]) REFERENCES [dbo].[EventsRegistration] ([PK_EventsRegistration]),
    CONSTRAINT [SubEventQualifierSubEventRegistration_FK] FOREIGN KEY ([PK_SubEventQualifier]) REFERENCES [dbo].[SubEventQualifier] ([PK_SubEventQualifier])
);


GO
CREATE NONCLUSTERED INDEX [IX_SubEventRegistration_PK_SubEventQual]
    ON [dbo].[SubEventRegistration]([PK_SubEventQualifier] ASC) WITH (FILLFACTOR = 80);

GO
CREATE NONCLUSTERED INDEX [IX_SubEventRegistration_PK_EventsRegistration] 
	ON [dbo].[SubEventRegistration] ([PK_EventsRegistration]);

GO
CREATE NONCLUSTERED INDEX [IX_SubEventRegistration_Registered_Covering] 
	ON [dbo].[SubEventRegistration] ([Registered]) INCLUDE ([PK_EventsRegistration], [PK_SubEventQualifier]);