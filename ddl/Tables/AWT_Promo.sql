CREATE TABLE [dbo].[AWT_Promo] (
    [PK_AWT_Promo] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [COP]          VARCHAR (2)   NOT NULL,
    [StartMonth]   SMALLDATETIME NOT NULL,
    [EndMonth]     SMALLDATETIME NULL,
    [CreatedBy]    VARCHAR (50)  CONSTRAINT [DF_AWT_Promo_CreatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [CreatedUTC]   DATETIME      CONSTRAINT [DF_AWT_Promo_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]    VARCHAR (50)  CONSTRAINT [DF_AWT_Promo_UpdatedBy] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [UpdatedUTC]   DATETIME      CONSTRAINT [DF_AWT_Promo_UpdatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [COPISO]       VARCHAR (2)   NULL,
    CONSTRAINT [PK__AWT_Prom__0A3566FE73CD65E8] PRIMARY KEY CLUSTERED ([PK_AWT_Promo] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_AWT_Promo_EndMonth]
    ON [dbo].[AWT_Promo]([EndMonth] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Promo_StartMonth]
    ON [dbo].[AWT_Promo]([StartMonth] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Promo_COP]
    ON [dbo].[AWT_Promo]([COP] ASC);

