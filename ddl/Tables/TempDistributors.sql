CREATE TABLE [dbo].[TempDistributors] (
    [PK_Temp]         INT           IDENTITY (-1, -1) NOT FOR REPLICATION NOT NULL,
    [DistributorID]   VARCHAR (10)  NOT NULL,
    [FirstName]       VARCHAR (100) NULL,
    [LastName]        VARCHAR (100) NULL,
    [Address1]        VARCHAR (100) NULL,
    [Address2]        VARCHAR (100) NULL,
    [Address3]        VARCHAR (100) NULL,
    [City]            VARCHAR (50)  NULL,
    [State]           VARCHAR (50)  NULL,
    [ZipCode]         VARCHAR (20)  NULL,
    [Country]         VARCHAR (50)  NULL,
    [DayPhone]        VARCHAR (30)  NULL,
    [EveningPhone]    VARCHAR (30)  NULL,
    [MobilePhone]     VARCHAR (30)  NULL,
    [CreatedOnSite]   CHAR (1)      DEFAULT ('Y') NOT NULL,
    [CreatedDateUTC]  SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]       VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC] SMALLDATETIME DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]      VARCHAR (50)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [PK_Distributor]  INT           NULL,
    [OtherIDSrc]      INT           NULL,
    [PK_Event]        INT           NULL,
    CONSTRAINT [TempDistributors_PK] PRIMARY KEY CLUSTERED ([PK_Temp] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_TempDistributor_DistributorID]
    ON [dbo].[TempDistributors]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_TempDistributor_FirstName]
    ON [dbo].[TempDistributors]([FirstName] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_TempDistributor_LastName]
    ON [dbo].[TempDistributors]([LastName] ASC) WITH (FILLFACTOR = 80);

