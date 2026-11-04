CREATE TABLE [dbo].[EventManageDetails] (
    [PK_EventManageDetails] INT            IDENTITY (1, 1) NOT NULL,
    [PK_Event]              INT            NOT NULL,
    [PK_RefEvent]           INT            NULL,
    [EstimatedDS]           INT            NULL,
    [ActualDS]              INT            NULL,
    [EstimatedNonDS]        INT            NULL,
    [ActualNonDS]           INT            NULL,
    [ContactName]           NVARCHAR (100) NULL,
    [ContactPhone]          NVARCHAR (50)  NULL,
    [ContactEmail]          NVARCHAR (50)  NULL,
    [Street]                NVARCHAR (500) NULL,
    [City]                  NVARCHAR (100) NULL,
    [State]                 NVARCHAR (50)  NULL,
    [ZipCode]               NVARCHAR (50)  NULL,
    [CreatedDate]           SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]             VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDate]          SMALLDATETIME  DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]            VARCHAR (50)   DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventManageDetails] PRIMARY KEY CLUSTERED ([PK_EventManageDetails] ASC),
    CONSTRAINT [IX_EventManageDetails_PK_Event] UNIQUE NONCLUSTERED ([PK_Event] ASC) WITH (FILLFACTOR = 80)
);

