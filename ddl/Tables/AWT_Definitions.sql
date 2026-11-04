CREATE TABLE [dbo].[AWT_Definitions] (
    [PK_AWT_Definitions] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]     DATETIME      CONSTRAINT [DF__AWT_Defin__Creat__2B1FD79A] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]          VARCHAR (100) CONSTRAINT [DF__AWT_Defin__Creat__2C13FBD3] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [Flg1]               INT           CONSTRAINT [DF__AWT_Defini__Flg1__2D08200C] DEFAULT ((1)) NULL,
    [AWTYear]            INT           NOT NULL,
    [StartDate]          SMALLDATETIME NOT NULL,
    [EndDate]            SMALLDATETIME NOT NULL,
    [NonTABDate]         SMALLDATETIME NOT NULL,
    [DistributorSet]     INT           CONSTRAINT [DF__AWT_Defin__Distr__2DFC4445] DEFAULT ((0)) NULL,
    DistributorSetManualQualifiers INT NULL
    CONSTRAINT [PK__AWT_Defi__A6AFC24C29378F28] PRIMARY KEY CLUSTERED ([PK_AWT_Definitions] ASC)
);



