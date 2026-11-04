CREATE TABLE [dbo].[EventSourceSystem] (
    [PK_EventSourceSystem] INT           IDENTITY (1, 1) NOT NULL,
    [SourceCode]           VARCHAR (10)  NULL,
    [SourceName]           VARCHAR (50)  NULL,
    [SourceDescription]    VARCHAR (100) NULL,
    [IsValid]              BIT           NULL,
    [CreatedDate]          DATETIME      NULL,
    [CreatedBy]            VARCHAR (20)  NULL,
    [ModifiedDate]         DATETIME      NULL,
    [ModifiedBy]           VARCHAR (20)  NULL,
    CONSTRAINT [EventSourceSystem_PK] PRIMARY KEY CLUSTERED ([PK_EventSourceSystem] ASC)
);

