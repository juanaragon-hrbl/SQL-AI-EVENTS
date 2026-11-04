CREATE TABLE [dbo].[AWT] (
    [PK_AWT]                BIGINT         IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]        DATETIME       CONSTRAINT [DF__AWT__CreatedDate__1B538425] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]             VARCHAR (100)  CONSTRAINT [DF__AWT__CreatedBy__1C47A85E] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [Flg1]                  TINYINT        CONSTRAINT [DF__AWT__Flg1__1D3BCC97] DEFAULT ((1)) NULL,
    [AWTYear]               INT            NOT NULL,
    [PK_Distributor]        INT            NULL,
    [DistributorID]         VARCHAR (30)   NULL,
    [FirstName]             NVARCHAR (50)  NULL,
    [LastName]              NVARCHAR (50)  NULL,
    [Address1]              NVARCHAR (480) NULL,
    [Address2]              NVARCHAR (480) NULL,
    [Address3]              NVARCHAR (480) NULL,
    [Address4]              NVARCHAR (480) NULL,
    [City]                  NVARCHAR (120) NULL,
    [County]                NVARCHAR (120) NULL,
    [PostalCode]            NVARCHAR (120) NULL,
    [CountryCode]           NVARCHAR (2)   NULL,
    [State]                 NVARCHAR (120) NULL,
    [SpouseFirstName]       NVARCHAR (50)  NULL,
    [SpouseLastName]        NVARCHAR (50)  NULL,
    [COP]                   CHAR (2)       NULL,
    [COPRegion]             VARCHAR (50)   NULL,
    [Email]                 VARCHAR (100)  NULL,
    [Phone]                 VARCHAR (100)  NULL,
    [Team]                  VARCHAR (2)    NULL,
    [PK_Sponsor]            INT            NULL,
    [SponsorID]             VARCHAR (30)   NULL,
    [SponsorFirstName]      NVARCHAR (50)  NULL,
    [SponsorLastName]       NVARCHAR (50)  NULL,
    [Qual_SP]               SMALLDATETIME  NULL,
    [Qual_G]                SMALLDATETIME  NULL,
    [Qual_W]                SMALLDATETIME  NULL,
    [Qual_AWT]              SMALLDATETIME  NULL,
    [IsDeleted]             INT            CONSTRAINT [DF__AWT__IsDeleted__1E2FF0D0] DEFAULT ((0)) NULL,
    [DeletedDate]           SMALLDATETIME  NULL,
    [IsDNR]                 INT            CONSTRAINT [DF__AWT__IsDNR__1F241509] DEFAULT ((0)) NULL,
    [DateAdded]             SMALLDATETIME  NULL,
    [IsType23]              INT            CONSTRAINT [DF__AWT__IsType23__20183942] DEFAULT ((0)) NULL,
    [PastAWT]               VARCHAR (MAX)  CONSTRAINT [DF__AWT__PastAWT__210C5D7B] DEFAULT ('No') NULL,
    [isNonTAB]              TINYINT        CONSTRAINT [DF__AWT__isNonTAB__220081B4] DEFAULT ((0)) NULL,
    [PK_UplinePres1]        INT            NULL,
    [UplinePresID1]         VARCHAR (10)   CONSTRAINT [DF__AWT__UplinePresI__22F4A5ED] DEFAULT ('') NULL,
    [UplinePres1FirstName]  NVARCHAR (50)  NULL,
    [UplinePres1LastName]   NVARCHAR (50)  NULL,
    [PK_UplinePres2]        INT            NULL,
    [UplinePresID2]         VARCHAR (10)   CONSTRAINT [DF__AWT__UplinePresI__23E8CA26] DEFAULT ('') NULL,
    [PK_UplinePres3]        INT            NULL,
    [UplinePresID3]         VARCHAR (10)   CONSTRAINT [DF__AWT__UplinePresI__24DCEE5F] DEFAULT ('') NULL,
    [PK_UplineSP1]          INT            NULL,
    [UplineSPID1]           VARCHAR (10)   CONSTRAINT [DF__AWT__UplineSPID1__25D11298] DEFAULT ('') NULL,
    [PK_UplineSP2]          INT            NULL,
    [UplineSPID2]           VARCHAR (10)   CONSTRAINT [DF__AWT__UplineSPID2__26C536D1] DEFAULT ('') NULL,
    [PK_UplineSP3]          INT            NULL,
    [UplineSPID3]           VARCHAR (10)   CONSTRAINT [DF__AWT__UplineSPID3__27B95B0A] DEFAULT ('') NULL,
    [PK_MainDistributor]    INT            NULL,
    [MainDistributorID]     VARCHAR (30)   NULL,
    [MainFirstName]         NVARCHAR (50)  NULL,
    [MainLastName]          NVARCHAR (50)  NULL,
    [MainAddress1]          NVARCHAR (480) NULL,
    [MainAddress2]          NVARCHAR (480) NULL,
    [MainAddress3]          NVARCHAR (480) NULL,
    [MainAddress4]          NVARCHAR (480) NULL,
    [MainCity]              NVARCHAR (120) NULL,
    [MainCounty]            NVARCHAR (120) NULL,
    [MainPostalCode]        NVARCHAR (120) NULL,
    [MainCountryCode]       NVARCHAR (2)   NULL,
    [MainState]             NVARCHAR (120) NULL,
    [FirstNameLocal]        NVARCHAR (200) NULL,
    [LastNameLocal]         NVARCHAR (200) NULL,
    [Address1Local]         NVARCHAR (240) NULL,
    [Address2Local]         NVARCHAR (240) NULL,
    [Address3Local]         NVARCHAR (240) NULL,
    [Address4Local]         NVARCHAR (240) NULL,
    [CityLocal]             NVARCHAR (60)  NULL,
    [CountyLocal]           NVARCHAR (60)  NULL,
    [PostalCodeLocal]       NVARCHAR (60)  NULL,
    [StateLocal]            NVARCHAR (60)  NULL,
    [SpouseFirstNameLocal]  NVARCHAR (200) NULL,
    [SpouseLastNameLocal]   NVARCHAR (200) NULL,
    [SponsorFirstNameLocal] NVARCHAR (200) NULL,
    [SponsorLastNameLocal]  NVARCHAR (200) NULL,
    [MainFirstNameLocal]    NVARCHAR (200) NULL,
    [MainLastNameLocal]     NVARCHAR (200) NULL,
    [MainAddress1Local]     NVARCHAR (240) NULL,
    [MainAddress2Local]     NVARCHAR (240) NULL,
    [MainAddress3Local]     NVARCHAR (240) NULL,
    [MainAddress4Local]     NVARCHAR (240) NULL,
    [MainCityLocal]         NVARCHAR (60)  NULL,
    [MainCountyLocal]       NVARCHAR (60)  NULL,
    [MainPostalCodeLocal]   NVARCHAR (60)  NULL,
    [MainStateLocal]        NVARCHAR (60)  NULL,
    [PK_UplineTAB1]         INT            NULL,
    [UplineTABID1]          VARCHAR (10)   NULL,
    [LPFirstname]           NVARCHAR (100) NULL,
    [LPLastName]            NVARCHAR (100) NULL,
    [LPFirstNameLocal]      NVARCHAR (100) NULL,
    [LPLastNameLocal]       NVARCHAR (100) NULL,
    [earnPlaque]            AS             (case when [PastAWT]='No' then (1) else (0) end),
    [earn500Bonus]          AS             (case when [PastAWT]='No' AND [isNonTAB]=(1) then (1) else (0) end),
    CONSTRAINT [PK__AWT__11698D78196B3BB3] PRIMARY KEY CLUSTERED ([PK_AWT] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_AWTYear]
    ON [dbo].[AWT]([AWTYear] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_COP]
    ON [dbo].[AWT]([COP] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_DistributorID]
    ON [dbo].[AWT]([DistributorID] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_MainDistributorID]
    ON [dbo].[AWT]([MainDistributorID] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_PK_Distributor]
    ON [dbo].[AWT]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_PK_MainDistributor]
    ON [dbo].[AWT]([PK_MainDistributor] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_Qual_AWT]
    ON [dbo].[AWT]([Qual_AWT] ASC);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_Qual_G]
    ON [dbo].[AWT]([Qual_G] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_Qual_SP]
    ON [dbo].[AWT]([Qual_SP] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_Qual_W]
    ON [dbo].[AWT]([Qual_W] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_UplinePresID1]
    ON [dbo].[AWT]([UplinePresID1] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_UplinePresID2]
    ON [dbo].[AWT]([UplinePresID2] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_UplinePresID3]
    ON [dbo].[AWT]([UplinePresID3] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_UplineSPID1]
    ON [dbo].[AWT]([UplineSPID1] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_UplineSPID2]
    ON [dbo].[AWT]([UplineSPID2] ASC) WITH (FILLFACTOR = 80);
GO

CREATE NONCLUSTERED INDEX [IX_AWT_UplineSPID3]
    ON [dbo].[AWT]([UplineSPID3] ASC) WITH (FILLFACTOR = 80);
GO
