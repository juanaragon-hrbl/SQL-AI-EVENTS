CREATE TABLE [dbo].[AgendaItemType] (
    [PK_AgendaItemType] INT          IDENTITY (1, 1) NOT NULL,
    [TypeDescription]   VARCHAR (50) NULL,
    [CreatedUTC]        DATETIME     DEFAULT (getutcdate()) NULL,
    [CreatedBy]         VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [UpdatedUTC]        DATETIME     DEFAULT (getutcdate()) NULL,
    [UpdatedBy]         VARCHAR (50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    PRIMARY KEY CLUSTERED ([PK_AgendaItemType] ASC)
);

