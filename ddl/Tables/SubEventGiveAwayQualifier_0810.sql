CREATE TABLE [dbo].[SubEventGiveAwayQualifier_0810] (
    [PK_SubEventGiveAwayQualifier] INT           IDENTITY (1, 1) NOT NULL,
    [PK_Distributor]               INT           NOT NULL,
    [PK_Event]                     INT           NOT NULL,
    [Pk_SubEvent]                  INT           NOT NULL,
    [CreatedDateUTC]               SMALLDATETIME NOT NULL,
    [CreatedBy]                    NVARCHAR (50) NOT NULL,
    [ModifiedDateUTC]              SMALLDATETIME NOT NULL,
    [ModifiedBy]                   NVARCHAR (50) NOT NULL,
    [Quantity]                     INT           NOT NULL,
    [RemovedUTC]                   SMALLDATETIME NOT NULL
);

