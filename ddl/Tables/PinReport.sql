CREATE TABLE [dbo].[PinReport] (
    [PK_PinReport]    INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Distributor]  INT           NOT NULL,
    [DistributorID]   VARCHAR (10)  NOT NULL,
    [Team]            VARCHAR (10)  NULL,
    [PinType]         VARCHAR (10)  NULL,
    [RoyaltyMonth]    SMALLDATETIME NULL,
    [CreatedBy]       VARCHAR (30)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedDateUTC]  SMALLDATETIME DEFAULT (getutcdate()) NULL,
    [ModifiedBy]      VARCHAR (30)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
    [ModifiedDateUTC] SMALLDATETIME DEFAULT (getutcdate()) NULL,
    [PK_Event]        INT           NOT NULL,
    [PK_SubEvent]     INT           NULL,
    PRIMARY KEY CLUSTERED ([PK_PinReport] ASC)
);






GO
CREATE NONCLUSTERED INDEX [IX_PinReport_RoyaltyMonth]
    ON [dbo].[PinReport]([RoyaltyMonth] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PinReport_PK_Distributor]
    ON [dbo].[PinReport]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_PinReport_DistributorID]
    ON [dbo].[PinReport]([DistributorID] ASC) WITH (FILLFACTOR = 80);

