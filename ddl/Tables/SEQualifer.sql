CREATE TABLE [dbo].[SEQualifer] (
    [PK_SubEventQualifier] INT           IDENTITY (1, 1) NOT NULL,
    [CreatedDateUTC]       DATETIME      NULL,
    [CreatedBy]            VARCHAR (50)  NULL,
    [ModifiedDateUTC]      DATETIME      NULL,
    [ModifiedBy]           VARCHAR (50)  NULL,
    [PK_Event]             INT           NOT NULL,
    [PK_SubEvent]          INT           NOT NULL,
    [PK_Distributor]       INT           NOT NULL,
    [DistributorID]        VARCHAR (10)  NULL,
    [QualDate]             SMALLDATETIME NULL,
    [AddedUTC]             SMALLDATETIME NULL,
    [RemovedUTC]           SMALLDATETIME NULL,
    [IsManualOverride]     BIT           NOT NULL,
    [IsDeleted]            BIT           NULL,
    [IsDNR]                BIT           NULL,
    [IsType23]             BIT           NULL,
    [Qualified]            INT           NOT NULL
)
WITH (DATA_COMPRESSION = PAGE);

