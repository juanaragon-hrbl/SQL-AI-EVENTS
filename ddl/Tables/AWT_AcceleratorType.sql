CREATE TABLE [dbo].[AWT_AcceleratorType] (
    [PK_AWT_AcceleratorType] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]         DATETIME      CONSTRAINT [DF__AWT_Accel__Creat__3ACC2F7E] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]              VARCHAR (100) CONSTRAINT [DF__AWT_Accel__Creat__3BC053B7] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [Flg1]                   INT           CONSTRAINT [DF__AWT_Accele__Flg1__3CB477F0] DEFAULT ((1)) NULL,
    [AcceleratorType]        VARCHAR (100) NULL,
    CONSTRAINT [PK__AWT_Acce__21B68CF738E3E70C] PRIMARY KEY CLUSTERED ([PK_AWT_AcceleratorType] ASC)
);



