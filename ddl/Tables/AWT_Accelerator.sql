CREATE TABLE [dbo].[AWT_Accelerator] (
    [PK_AWT_Accelerator]     INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]         DATETIME      CONSTRAINT [DF__AWT_Accel__Creat__41792D0D] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]              VARCHAR (100) CONSTRAINT [DF__AWT_Accel__Creat__426D5146] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [Flg1]                   INT           CONSTRAINT [DF__AWT_Accele__Flg1__4361757F] DEFAULT ((1)) NULL,
    [PK_AWT_AcceleratorType] INT           NOT NULL,
    [AWTYear]                INT           NOT NULL,
    [Royaltymonth]           SMALLDATETIME NOT NULL,
    [COP]                    VARCHAR (2)   NOT NULL,
    CONSTRAINT [PK__AWT_Acce__D6DEC4663F90E49B] PRIMARY KEY CLUSTERED ([PK_AWT_Accelerator] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_AWT_Accelerator_COP]
    ON [dbo].[AWT_Accelerator]([COP] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Accelerator_Royaltymonth]
    ON [dbo].[AWT_Accelerator]([Royaltymonth] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Accelerator_PK_AWT_AcceleratorType]
    ON [dbo].[AWT_Accelerator]([PK_AWT_AcceleratorType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AWT_Accelerator_AWTYear]
    ON [dbo].[AWT_Accelerator]([AWTYear] ASC);

