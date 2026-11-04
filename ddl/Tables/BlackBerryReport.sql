CREATE TABLE [dbo].[BlackBerryReport] (
    [PK_BlackberryReport] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Event]            INT           NULL,
    [RunSequence]         INT           NULL,
    [Report]              VARCHAR (MAX) NULL,
    CONSTRAINT [BlackBerryReport_PK] PRIMARY KEY CLUSTERED ([PK_BlackberryReport] ASC) WITH (DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IX_BlackBerryReport_PK_Event_Covering] 
	ON [dbo].[BlackBerryReport] ([PK_Event]) INCLUDE ([RunSequence]);


