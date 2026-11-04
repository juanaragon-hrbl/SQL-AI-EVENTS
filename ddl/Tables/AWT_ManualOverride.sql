CREATE TABLE [dbo].[AWT_ManualOverride] (
    [PK_AWT_ManualOverride] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]        DATETIME      CONSTRAINT [DF__AWT_Manua__Creat__332B0DB6] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]             VARCHAR (100) CONSTRAINT [DF__AWT_Manua__Creat__341F31EF] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [Flg1]                  INT           CONSTRAINT [DF__AWT_Manual__Flg1__35135628] DEFAULT ((1)) NULL,
    [AWTYear]               INT           NOT NULL,
    [PK_Distributor]        INT           NOT NULL,
    [DistributorID]         VARCHAR (30)  NULL,
    [DateAdded]             SMALLDATETIME CONSTRAINT [DF__AWT_Manua__DateA__36077A61] DEFAULT (getutcdate()) NULL,
    [Qual_AWT]              SMALLDATETIME NOT NULL,
    CONSTRAINT [PK__AWT_Manu__6E5251143142C544] PRIMARY KEY CLUSTERED ([PK_AWT_ManualOverride] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_AWT_ManualOverride_DistributorID]
    ON [dbo].[AWT_ManualOverride]([DistributorID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_ManualOverride_PK_Distributor]
    ON [dbo].[AWT_ManualOverride]([PK_Distributor] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_ManualOverride_AWTYear]
    ON [dbo].[AWT_ManualOverride]([AWTYear] ASC);

