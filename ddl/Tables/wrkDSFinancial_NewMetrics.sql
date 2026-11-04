CREATE TABLE [dbo].[wrkDSFinancial_NewMetrics] (
    [PK_aggDSFinancial]      INT           IDENTITY (1, 1) NOT NULL,
    [LastModifiedDate]       DATETIME      NULL,
    [RoyaltyMonth]           SMALLDATETIME NULL,
    [PK_Distributor]         INT           NULL,
    [DistributorID]          VARCHAR (30)  NULL,
    [DeletedDate]            SMALLDATETIME NULL,
    [Qual_SPDate]            SMALLDATETIME NULL,
    [Qual_QSDate]            SMALLDATETIME NULL,
    [Qual_QSDate_Actual]     SMALLDATETIME NULL,
    [Team]                   VARCHAR (2)   NULL,
    [COP]                    VARCHAR (2)   NULL,
    [IsAssocType23]          BIT           DEFAULT ((0)) NULL,
    [IsMainID]               BIT           DEFAULT ((1)) NULL,
    [IsInAssocTable]         BIT           DEFAULT ((0)) NULL,
    [TV]                     MONEY         DEFAULT ((0)) NULL,
    [RO]                     MONEY         DEFAULT ((0)) NULL,
    [PB]                     MONEY         DEFAULT ((0)) NULL,
    [PV]                     MONEY         DEFAULT ((0)) NULL,
    [GV]                     MONEY         DEFAULT ((0)) NULL,
    [PPV]                    MONEY         DEFAULT ((0)) NULL,
    [OV]                     MONEY         DEFAULT ((0)) NULL,
    [PK_MainDistributor]     INT           NULL,
    [MainDistributorID]      VARCHAR (30)  NULL,
    [MainDeletedDate]        SMALLDATETIME NULL,
    [MainQual_SPDate]        SMALLDATETIME NULL,
    [MainQual_QSDate]        SMALLDATETIME NULL,
    [MainQual_QSDate_Actual] SMALLDATETIME NULL,
    [MainTeam]               VARCHAR (2)   NULL,
    [MainCOP]                CHAR (2)      NULL,
    [MainIsType23]           BIT           DEFAULT ((0)) NULL,
    [MainTV]                 MONEY         DEFAULT ((0)) NULL,
    [MainRO]                 MONEY         DEFAULT ((0)) NULL,
    [MainPB]                 MONEY         DEFAULT ((0)) NULL,
    [MainPV]                 MONEY         DEFAULT ((0)) NULL,
    [MainGV]                 MONEY         DEFAULT ((0)) NULL,
    [MainPPV]                MONEY         DEFAULT ((0)) NULL,
    [MainOV]                 MONEY         DEFAULT ((0)) NULL,
    [SP_PV]                  AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else [PV] end),
    [SP_GV]                  AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else [GV] end),
    [SP_OV]                  AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else [OV] end),
    [SP_TV]                  AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else coalesce([PV],(0))+coalesce([GV],(0)) end),
    [SP_MainPV]              AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else [MainPV] end),
    [SP_MainGV]              AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else [MainGV] end),
    [SP_MainOV]              AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else [MainOV] end),
    [SP_MainTV]              AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else coalesce([MainPV],(0))+coalesce([MainGV],(0)) end),
    [DLV]                    MONEY         DEFAULT ((0)) NULL,
    [MainDLV]                MONEY         DEFAULT ((0)) NULL,
    [SP_DLV]                 AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else [DLV] end),
    [SP_MainDLV]             AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else [MainDLV] end),
    [MPV]                    MONEY         DEFAULT ((0)) NULL,
    [MTV]                    MONEY         DEFAULT ((0)) NULL,
    [SP_MPV]                 AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else [MPV] end),
    [SP_MTV]                 AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else [MTV] end),
    [MainMPV]                MONEY         DEFAULT ((0)) NULL,
    [MainMTV]                MONEY         DEFAULT ((0)) NULL,
    [SP_MainMPV]             AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else [MainMPV] end),
    [SP_MainMTV]             AS            (case when [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate] IS NULL then (0) when [Qual_QSDate] IS NULL AND [Qual_SPDate]='1900-01-01' then (0) when [Qual_SPDate] IS NULL AND [Qual_QSDate]='1900-01-01' then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate] IS NULL AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate] IS NOT NULL AND [Qual_QSDate]<>'1900-01-01' AND [Qual_SPDate]='1900-01-01' AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate] IS NULL AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_SPDate] IS NOT NULL AND [Qual_SPDate]<>'1900-01-01' AND [Qual_QSDate]='1900-01-01' AND [Qual_SPDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]<=[Qual_SPDate] AND [Qual_QSDate]>[RoyaltyMonth] then (0) when [Qual_QSDate]>[Qual_SPDate] AND [Qual_SPDate]>[RoyaltyMonth] then (0) else [MainMTV] end),
    [DV]                     MONEY         DEFAULT ((0)) NULL,
    [PPC]                    MONEY         DEFAULT ((0)) NULL,
    [PRV]                    MONEY         DEFAULT ((0)) NULL,
    [NDV]                    MONEY         DEFAULT ((0)) NULL,
    [SPC]                    MONEY         DEFAULT ((0)) NULL,
    [SRV]                    MONEY         DEFAULT ((0)) NULL,
    [PV_PPC]                 MONEY         DEFAULT ((0)) NULL,
    [PV_PRV]                 MONEY         DEFAULT ((0)) NULL,
    [PV_NDV]                 MONEY         DEFAULT ((0)) NULL,
    [PV_SPC]                 MONEY         DEFAULT ((0)) NULL,
    [PV_SRV]                 MONEY         DEFAULT ((0)) NULL,
    [DLV_PPC]                MONEY         DEFAULT ((0)) NULL,
    [DLV_PRV]                MONEY         DEFAULT ((0)) NULL,
    [DLV_NDV]                MONEY         DEFAULT ((0)) NULL,
    [DLV_SPC]                MONEY         DEFAULT ((0)) NULL,
    [DLV_SRV]                MONEY         DEFAULT ((0)) NULL,
    [GV_PPC]                 MONEY         DEFAULT ((0)) NULL,
    [GV_PRV]                 MONEY         DEFAULT ((0)) NULL,
    [GV_NDV]                 MONEY         DEFAULT ((0)) NULL,
    [GV_SPC]                 MONEY         DEFAULT ((0)) NULL,
    [GV_SRV]                 MONEY         DEFAULT ((0)) NULL,
    [EV]                     MONEY         DEFAULT ((0)) NULL,
    [UV]                     MONEY         DEFAULT ((0)) NULL,
    [MainDV]                 MONEY         DEFAULT ((0)) NULL,
    [MainPPC]                MONEY         DEFAULT ((0)) NULL,
    [MainPRV]                MONEY         DEFAULT ((0)) NULL,
    [MainNDV]                MONEY         DEFAULT ((0)) NULL,
    [MainSPC]                MONEY         DEFAULT ((0)) NULL,
    [MainSRV]                MONEY         DEFAULT ((0)) NULL,
    [MainPV_PPC]             MONEY         DEFAULT ((0)) NULL,
    [MainPV_PRV]             MONEY         DEFAULT ((0)) NULL,
    [MainPV_NDV]             MONEY         DEFAULT ((0)) NULL,
    [MainPV_SPC]             MONEY         DEFAULT ((0)) NULL,
    [MainPV_SRV]             MONEY         DEFAULT ((0)) NULL,
    [MainDLV_PPC]            MONEY         DEFAULT ((0)) NULL,
    [MainDLV_PRV]            MONEY         DEFAULT ((0)) NULL,
    [MainDLV_NDV]            MONEY         DEFAULT ((0)) NULL,
    [MainDLV_SPC]            MONEY         DEFAULT ((0)) NULL,
    [MainDLV_SRV]            MONEY         DEFAULT ((0)) NULL,
    [MainGV_PPC]             MONEY         DEFAULT ((0)) NULL,
    [MainGV_PRV]             MONEY         DEFAULT ((0)) NULL,
    [MainGV_NDV]             MONEY         DEFAULT ((0)) NULL,
    [MainGV_SPC]             MONEY         DEFAULT ((0)) NULL,
    [MainGV_SRV]             MONEY         DEFAULT ((0)) NULL,
    [MainEV]                 MONEY         DEFAULT ((0)) NULL,
    [MainUV]                 MONEY         DEFAULT ((0)) NULL,
    [IsValidRecord]          AS            (case when [TV]=(0) AND [RO]=(0) AND [PB]=(0) AND [PPV]=(0) AND [MainTV]=(0) AND [MainRO]=(0) AND [MainPB]=(0) AND [MainPPV]=(0) AND [DLV]=(0) AND [MainDLV]=(0) AND [MPV]=(0) AND [MTV]=(0) AND [MainMPV]=(0) AND [MainMTV]=(0) AND [DV]=(0) then (0) else (1) end),
    PRIMARY KEY CLUSTERED ([PK_aggDSFinancial] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainCOP]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainCOP] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainQual_QSDate_Actual]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainQual_QSDate_Actual] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainQual_QSDate]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainQual_QSDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainQual_SPDate]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainQual_SPDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainTeam]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainTeam] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainDeletedDate]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainDeletedDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_COP]
    ON [dbo].[wrkDSFinancial_NewMetrics]([COP] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_Qual_QSDate_Actual]
    ON [dbo].[wrkDSFinancial_NewMetrics]([Qual_QSDate_Actual] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_Qual_QSDate]
    ON [dbo].[wrkDSFinancial_NewMetrics]([Qual_QSDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_Qual_SPDate]
    ON [dbo].[wrkDSFinancial_NewMetrics]([Qual_SPDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_Team]
    ON [dbo].[wrkDSFinancial_NewMetrics]([Team] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_DeletedDate]
    ON [dbo].[wrkDSFinancial_NewMetrics]([DeletedDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainDistributorID]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainDistributorID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_DistributorID]
    ON [dbo].[wrkDSFinancial_NewMetrics]([DistributorID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinancial_Composite1]
    ON [dbo].[wrkDSFinancial_NewMetrics]([IsAssocType23] ASC, [IsMainID] ASC)
    INCLUDE([PK_Distributor]);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainUV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainUV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainEV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainEV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainGV_SRV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainGV_SRV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainGV_NDV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainGV_NDV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainGV_SPC]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainGV_SPC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainGV_PRV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainGV_PRV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainGV_PPC]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainGV_PPC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainDLV_SRV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainDLV_SRV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainDLV_SPC]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainDLV_SPC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainDLV_NDV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainDLV_NDV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainDLV_PRV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainDLV_PRV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainDLV_PPC]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainDLV_PPC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainPV_SRV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainPV_SRV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainPV_SPC]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainPV_SPC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainPV_NDV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainPV_NDV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainPV_PRV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainPV_PRV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainPV_PPC]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainPV_PPC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_UV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([UV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_EV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([EV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_GV_SRV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([GV_SRV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_GV_NDV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([GV_NDV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_GV_SPC]
    ON [dbo].[wrkDSFinancial_NewMetrics]([GV_SPC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_GV_PRV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([GV_PRV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_GV_PPC]
    ON [dbo].[wrkDSFinancial_NewMetrics]([GV_PPC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_DLV_SRV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([DLV_SRV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_DLV_SPC]
    ON [dbo].[wrkDSFinancial_NewMetrics]([DLV_SPC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_DLV_NDV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([DLV_NDV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_DLV_PRV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([DLV_PRV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_DLV_PPC]
    ON [dbo].[wrkDSFinancial_NewMetrics]([DLV_PPC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_PV_SRV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([PV_SRV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_PV_SPC]
    ON [dbo].[wrkDSFinancial_NewMetrics]([PV_SPC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_PV_NDV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([PV_NDV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_PV_PRV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([PV_PRV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_PV_PPC]
    ON [dbo].[wrkDSFinancial_NewMetrics]([PV_PPC] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainMTV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainMTV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainMPV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainMPV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MTV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MTV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MPV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainMPV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainDLV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainDLV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_DLV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([DLV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainOV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainOV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainPPV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainPPV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainGV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainGV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainPV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainPV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainPB]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainPB] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainRO]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainRO] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainTV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainTV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_MainIsType23]
    ON [dbo].[wrkDSFinancial_NewMetrics]([MainIsType23] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_PK_MainDistributor]
    ON [dbo].[wrkDSFinancial_NewMetrics]([PK_MainDistributor] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_OV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([OV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_PPV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([PPV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_GV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([GV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_PV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([PV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_PB]
    ON [dbo].[wrkDSFinancial_NewMetrics]([PB] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_RO]
    ON [dbo].[wrkDSFinancial_NewMetrics]([RO] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_TV]
    ON [dbo].[wrkDSFinancial_NewMetrics]([TV] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_IsInAssocTable]
    ON [dbo].[wrkDSFinancial_NewMetrics]([IsInAssocTable] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_IsMainID]
    ON [dbo].[wrkDSFinancial_NewMetrics]([IsMainID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_IsAssocType23]
    ON [dbo].[wrkDSFinancial_NewMetrics]([IsAssocType23] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_PK_Distributor]
    ON [dbo].[wrkDSFinancial_NewMetrics]([PK_Distributor] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_aggDSFinacial_RoyaltyMonth]
    ON [dbo].[wrkDSFinancial_NewMetrics]([RoyaltyMonth] ASC);

