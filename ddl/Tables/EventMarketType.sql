CREATE TABLE [dbo].[EventMarketType] (
    [PK_EventMarketType] INT           IDENTITY (1, 1) NOT NULL,
    [EventMarketType]    VARCHAR (50)  NULL,
    [CreatedDateUTC]     SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]          NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]    SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]         NVARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    CONSTRAINT [PK_EventMarketType] PRIMARY KEY CLUSTERED ([PK_EventMarketType] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EventMarketType_EventMarketType]
    ON [dbo].[EventMarketType]([EventMarketType] ASC);

