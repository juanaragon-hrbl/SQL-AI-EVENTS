CREATE TABLE [dbo].[EventBadgePortSetup] (
    [PK_EventBadgePortSetup] INT           IDENTITY (1, 1) NOT NULL,
    [PK_Event]               INT           NULL,
    [BeginUserID]            INT           NULL,
    [EndUserID]              INT           NULL,
    [PortNumber]             INT           NULL,
    [CreatedDateUTC]         SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]              NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]        SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]             NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventBadgePortSetup] PRIMARY KEY CLUSTERED ([PK_EventBadgePortSetup] ASC),
    CONSTRAINT [EventBadgePortSetup_PK_Event] FOREIGN KEY ([PK_Event]) REFERENCES [dbo].[Event] ([PK_Event])
);

