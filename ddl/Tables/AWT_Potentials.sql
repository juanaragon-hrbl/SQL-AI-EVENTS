CREATE TABLE [dbo].[AWT_Potentials] (
    [PK_AWT_Potential]     INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PK_Distributor_EDW]   INT            NULL,
    [PK_Distributor]       INT            CONSTRAINT [DF__AWT_Poten__PK_Di__4F3542BB] DEFAULT ((0)) NULL,
    [DistributorID]        VARCHAR (30)   NULL,
    [COP]                  VARCHAR (2)    NULL,
    [IsType23]             BIT            CONSTRAINT [DF__AWT_Poten__IsTyp__502966F4] DEFAULT ((0)) NULL,
    [PromoMonths]          VARCHAR (1000) NULL,
    [M6_RO]                MONEY          CONSTRAINT [DF__AWT_Poten__M6_RO__511D8B2D] DEFAULT ((0)) NULL,
    [M5_RO]                MONEY          CONSTRAINT [DF__AWT_Poten__M5_RO__5211AF66] DEFAULT ((0)) NULL,
    [M4_RO]                MONEY          CONSTRAINT [DF__AWT_Poten__M4_RO__5305D39F] DEFAULT ((0)) NULL,
    [M3_RO]                MONEY          CONSTRAINT [DF__AWT_Poten__M3_RO__53F9F7D8] DEFAULT ((0)) NULL,
    [M2_RO]                MONEY          CONSTRAINT [DF__AWT_Poten__M2_RO__54EE1C11] DEFAULT ((0)) NULL,
    [M1_RO]                MONEY          CONSTRAINT [DF__AWT_Poten__M1_RO__55E2404A] DEFAULT ((0)) NULL,
    [M6_TV]                MONEY          CONSTRAINT [DF__AWT_Poten__M6_TV__56D66483] DEFAULT ((0)) NULL,
    [M5_TV]                MONEY          CONSTRAINT [DF__AWT_Poten__M5_TV__57CA88BC] DEFAULT ((0)) NULL,
    [M4_TV]                MONEY          CONSTRAINT [DF__AWT_Poten__M4_TV__58BEACF5] DEFAULT ((0)) NULL,
    [M3_TV]                MONEY          CONSTRAINT [DF__AWT_Poten__M3_TV__59B2D12E] DEFAULT ((0)) NULL,
    [M2_TV]                MONEY          CONSTRAINT [DF__AWT_Poten__M2_TV__5AA6F567] DEFAULT ((0)) NULL,
    [M1_TV]                MONEY          CONSTRAINT [DF__AWT_Poten__M1_TV__5B9B19A0] DEFAULT ((0)) NULL,
    [Is1800_In1M_InL6M]    TINYINT        CONSTRAINT [DF__AWT_Poten__Is180__5C8F3DD9] DEFAULT ((0)) NULL,
    [Is1800_In2CM_InL6M]   TINYINT        CONSTRAINT [DF__AWT_Poten__Is180__5D836212] DEFAULT ((0)) NULL,
    [Is1800_In3CM_InL6M]   TINYINT        CONSTRAINT [DF__AWT_Poten__Is180__5E77864B] DEFAULT ((0)) NULL,
    [Is1800_In4CM_InL6M]   TINYINT        CONSTRAINT [DF__AWT_Poten__Is180__5F6BAA84] DEFAULT ((0)) NULL,
    [Is2000_In1M_InL6M]    TINYINT        CONSTRAINT [DF__AWT_Poten__Is200__605FCEBD] DEFAULT ((0)) NULL,
    [Is2000_In2CM_InL6M]   TINYINT        CONSTRAINT [DF__AWT_Poten__Is200__6153F2F6] DEFAULT ((0)) NULL,
    [Is2000_In3CM_InL6M]   TINYINT        CONSTRAINT [DF__AWT_Poten__Is200__6248172F] DEFAULT ((0)) NULL,
    [Is2000_In4CM_InL6M]   TINYINT        CONSTRAINT [DF__AWT_Poten__Is200__633C3B68] DEFAULT ((0)) NULL,
    [Is2200_In1M_InL6M]    TINYINT        CONSTRAINT [DF__AWT_Poten__Is220__64305FA1] DEFAULT ((0)) NULL,
    [Is2200_In2CM_InL6M]   TINYINT        CONSTRAINT [DF__AWT_Poten__Is220__652483DA] DEFAULT ((0)) NULL,
    [Is2200_In3CM_InL6M]   TINYINT        CONSTRAINT [DF__AWT_Poten__Is220__6618A813] DEFAULT ((0)) NULL,
    [Is2200_In4CM_InL6M]   TINYINT        CONSTRAINT [DF__AWT_Poten__Is220__670CCC4C] DEFAULT ((0)) NULL,
    [Is2500_In1M_InL6M]    TINYINT        CONSTRAINT [DF__AWT_Poten__Is250__6800F085] DEFAULT ((0)) NULL,
    [Is2500_In2CM_InL6M]   TINYINT        CONSTRAINT [DF__AWT_Poten__Is250__68F514BE] DEFAULT ((0)) NULL,
    [Is2500_In3CM_InL6M]   TINYINT        CONSTRAINT [DF__AWT_Poten__Is250__69E938F7] DEFAULT ((0)) NULL,
    [Is2500_In4CM_InL6M]   TINYINT        CONSTRAINT [DF__AWT_Poten__Is250__6ADD5D30] DEFAULT ((0)) NULL,
    [MaxCM_1800TV_InL6M]   AS             ((([Is1800_In1M_InL6M]+[Is1800_In2CM_InL6M])+[Is1800_In3CM_InL6M])+[Is1800_In4CM_InL6M]),
    [MaxCM_2000TV_InL6M]   AS             ((([Is2000_In1M_InL6M]+[Is2000_In2CM_InL6M])+[Is2000_In3CM_InL6M])+[Is2000_In4CM_InL6M]),
    [MaxCM_2200TV_InL6M]   AS             ((([Is2200_In1M_InL6M]+[Is2200_In2CM_InL6M])+[Is2200_In3CM_InL6M])+[Is2200_In4CM_InL6M]),
    [MaxCM_2500TV_InL6M]   AS             ((([Is2500_In1M_InL6M]+[Is2500_In2CM_InL6M])+[Is2500_In3CM_InL6M])+[Is2500_In4CM_InL6M]),
    [CreatedBy]            NVARCHAR (50)  CONSTRAINT [DF__AWT_Poten__Creat__6BD18169] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]      SMALLDATETIME  CONSTRAINT [DF__AWT_Poten__Modif__6CC5A5A2] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]           NVARCHAR (50)  CONSTRAINT [DF__AWT_Poten__Modif__6DB9C9DB] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [M0_TV]                MONEY          CONSTRAINT [DF__AWT_Poten__M0_TV__46CAAB1B] DEFAULT ((0)) NULL,
    [M0_RO]                MONEY          CONSTRAINT [DF__AWT_Poten__M0_RO__47BECF54] DEFAULT ((0)) NULL,
    [Is2500_In1M_InL6M_0]  TINYINT        CONSTRAINT [DF__AWT_Poten__Is250__48B2F38D] DEFAULT ((0)) NULL,
    [Is2500_In2CM_InL6M_0] TINYINT        CONSTRAINT [DF__AWT_Poten__Is250__49A717C6] DEFAULT ((0)) NULL,
    [Is2500_In3CM_InL6M_0] TINYINT        CONSTRAINT [DF__AWT_Poten__Is250__4A9B3BFF] DEFAULT ((0)) NULL,
    [Is2500_In4CM_InL6M_0] TINYINT        CONSTRAINT [DF__AWT_Poten__Is250__4B8F6038] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_AWT_Potential] PRIMARY KEY CLUSTERED ([PK_AWT_Potential] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_AWT_Potentials_DistributorID]
    ON [dbo].[AWT_Potentials]([DistributorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Potentials_PK_Distributor]
    ON [dbo].[AWT_Potentials]([PK_Distributor] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Potentials_PK_Distributor_EDW]
    ON [dbo].[AWT_Potentials]([PK_Distributor_EDW] ASC) WITH (FILLFACTOR = 80);

