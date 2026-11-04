CREATE TABLE [dbo].[LeadAssgnDSEventQual] (
    [PK_LeadAssgnDSEventQualID] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_EventType]              INT          NOT NULL,
    [PK_Country]                INT          NOT NULL,
    [CountryCode]               VARCHAR (2)  NOT NULL,
    [MinEventCount]             SMALLINT     NOT NULL,
    [PeriodInMonths]            SMALLINT     NOT NULL,
    [CreatedBy]                 VARCHAR (50) CONSTRAINT [DF_LeadAssgnDSEventQual_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]            DATETIME     CONSTRAINT [DF_LeadAssgnDSEventQual_CreatedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]                VARCHAR (50) CONSTRAINT [DF_LeadAssgnDSEventQual_ModifiedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]           DATETIME     CONSTRAINT [DF_LeadAssgnDSEventQual_ModifiedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([PK_LeadAssgnDSEventQualID] ASC)
);



