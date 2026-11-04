CREATE TABLE [dbo].[UploadedMember] (
    [PK_Event]        INT           NOT NULL,
    [PK_SubEvent]     INT           NULL,
    [DistributorID]   VARCHAR (40)  NOT NULL,
    [CreatedDateUTC]  DATETIME2 (7) CONSTRAINT [DF_UploadedMember_CreatedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]       VARCHAR (255) CONSTRAINT [DF_UploadedMember_CreatedBy] DEFAULT (replace(suser_name(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC] DATETIME2 (7) CONSTRAINT [DF_UploadedMember_ModifiedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]      VARCHAR (255) CONSTRAINT [DF_UploadedMember_ModifiedBy] DEFAULT (replace(suser_name(),'HERBALIFECORP\','')) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_UploadedMember_EventSubEventDistributorID]
    ON [dbo].[UploadedMember]([PK_Event] ASC, [PK_SubEvent] ASC, [DistributorID] ASC) WITH (FILLFACTOR = 80);

GO
CREATE NONCLUSTERED INDEX [IX_PubEventManagement_PK_Event_DistributorID_Covering] 
	ON [dbo].[UploadedMember] ([PK_Event], [DistributorID]);