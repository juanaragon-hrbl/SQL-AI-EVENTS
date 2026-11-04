CREATE TABLE [dbo].[RecurrenceType] (
    [PK_RecurrenceType]     INT           IDENTITY (1, 1) NOT NULL,
    [RecurrenceCode]        CHAR (2)      NULL,
    [RecurrenceType]        VARCHAR (30)  NULL,
    [RecuurenceDescription] VARCHAR (200) NULL,
    PRIMARY KEY CLUSTERED ([PK_RecurrenceType] ASC)
);

