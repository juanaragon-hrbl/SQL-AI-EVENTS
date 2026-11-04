CREATE TABLE [dbo].[LeadershipActivityRecognition] (
    [PK_LAR]         INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Distributor] INT          NOT NULL,
    [DistributorID]  VARCHAR (20) NOT NULL,
    [Category]       INT          NULL,
    [PK_Downline]    INT          NOT NULL,
    [DownlineID]     VARCHAR (20) NOT NULL,
    [TotalDLMAP]     INT          NULL,
    [PK_Event]       INT          NULL,
    PRIMARY KEY CLUSTERED ([PK_LAR] ASC) WITH (FILLFACTOR = 80)
);



