CREATE TABLE [dbo].[AWT_Qualifiers] (
    [PK_AWT_Qualifiers] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]    DATETIME      CONSTRAINT [DF__AWT_Quali__Creat__2C7E1027] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]         VARCHAR (100) CONSTRAINT [DF__AWT_Quali__Creat__2D723460] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [Flg1]              INT           CONSTRAINT [DF__AWT_Qualif__Flg1__2E665899] DEFAULT ((1)) NULL,
    [AWTYear]           INT           NOT NULL,
    [PK_Distributor]    INT           NOT NULL,
    [DistributorID]     VARCHAR (30)  NULL,
    [DateAdded]         SMALLDATETIME NULL,
    [Qual_AWT]          SMALLDATETIME NULL,
    CONSTRAINT [PK__AWT_Qual__71226C9E2A95C7B5] PRIMARY KEY CLUSTERED ([PK_AWT_Qualifiers] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_AWT_Qualifiers_DistributorID]
    ON [dbo].[AWT_Qualifiers]([DistributorID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Qualifiers_PK_Distributor]
    ON [dbo].[AWT_Qualifiers]([PK_Distributor] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Qualifiers_AWTYear]
    ON [dbo].[AWT_Qualifiers]([AWTYear] ASC);

