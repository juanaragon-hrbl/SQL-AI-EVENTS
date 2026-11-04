CREATE TABLE [dbo].[AWT_Qualifiers_Tracking] (
    [PK_AWT_Tracking] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CreatedDateUTC]  DATETIME      CONSTRAINT [DF__AWT_Quali__Creat__01CA7C66] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]       VARCHAR (100) CONSTRAINT [DF__AWT_Quali__Creat__02BEA09F] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC] DATETIME      CONSTRAINT [DF__AWT_Quali__Modif__03B2C4D8] DEFAULT (getutcdate()) NOT NULL,
    [ModifiedBy]      VARCHAR (100) CONSTRAINT [DF__AWT_Quali__Modif__04A6E911] DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
    [AWTYear]         INT           NULL,
    [PK_Distributor]  INT           NULL,
    [DistributorID]   VARCHAR (30)  NULL,
    [COP]             VARCHAR (2)   NULL,
    [Jan]             BIT           CONSTRAINT [DF__AWT_Qualifi__Jan__7658C9BA] DEFAULT ((0)) NULL,
    [Feb]             BIT           CONSTRAINT [DF__AWT_Qualifi__Feb__774CEDF3] DEFAULT ((0)) NULL,
    [Mar]             BIT           CONSTRAINT [DF__AWT_Qualifi__Mar__7841122C] DEFAULT ((0)) NULL,
    [Apr]             BIT           CONSTRAINT [DF__AWT_Qualifi__Apr__79353665] DEFAULT ((0)) NULL,
    [May]             BIT           CONSTRAINT [DF__AWT_Qualifi__May__7A295A9E] DEFAULT ((0)) NULL,
    [Jun]             BIT           CONSTRAINT [DF__AWT_Qualifi__Jun__7B1D7ED7] DEFAULT ((0)) NULL,
    [Jul]             BIT           CONSTRAINT [DF__AWT_Qualifi__Jul__7C11A310] DEFAULT ((0)) NULL,
    [Aug]             BIT           CONSTRAINT [DF__AWT_Qualifi__Aug__7D05C749] DEFAULT ((0)) NULL,
    [Sep]             BIT           CONSTRAINT [DF__AWT_Qualifi__Sep__7DF9EB82] DEFAULT ((0)) NULL,
    [Oct]             BIT           CONSTRAINT [DF__AWT_Qualifi__Oct__7EEE0FBB] DEFAULT ((0)) NULL,
    [Nov]             BIT           CONSTRAINT [DF__AWT_Qualifi__Nov__7FE233F4] DEFAULT ((0)) NULL,
    [Dec]             BIT           CONSTRAINT [DF__AWT_Qualifi__Dec__00D6582D] DEFAULT ((0)) NULL,
    CONSTRAINT [PK__AWT_Qual__88A2499B74708148] PRIMARY KEY CLUSTERED ([PK_AWT_Tracking] ASC)
);



