CREATE TABLE [dbo].[UploadedMemberDump] (
    [PK_Event]        INT           NOT NULL,
    [PK_SubEvent]     INT           NULL,
    [DistributorID]   VARCHAR (40)  NOT NULL,
    [ValidMember]     BIT           NOT NULL,
    [ValidSubEvent]   BIT           NOT NULL,
    [CreatedDateUTC]  DATETIME2 (7) CONSTRAINT [DF_UploadedMemberDump_CreatedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]       VARCHAR (255) CONSTRAINT [DF_UploadedMemberDump_CreatedBy] DEFAULT (replace(suser_name(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC] DATETIME2 (7) CONSTRAINT [DF_UploadedMemberDump_ModifiedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]      VARCHAR (255) CONSTRAINT [DF_UploadedMemberDump_ModifiedBy] DEFAULT (replace(suser_name(),'HERBALIFECORP\','')) NOT NULL
);

