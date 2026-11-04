CREATE TABLE [dbo].[EventGroupQualifiers] (
    [PK_EventGroupQualifier] INT           IDENTITY (1, 1) NOT NULL,
    [PK_Distributor]         INT           NOT NULL,
    [CreatedBy]              VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]         SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]             VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]        SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [PK_EventGroupMember]    INT           NOT NULL,
    CONSTRAINT [EventGroupQualifiers_PK] PRIMARY KEY CLUSTERED ([PK_EventGroupQualifier] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [EventGroupMembersEventGroupQualifiers_FK] FOREIGN KEY ([PK_EventGroupMember]) REFERENCES [dbo].[EventGroupMembers] ([PK_EventGroupMember])
);

