CREATE TABLE [dbo].[AWT_Country](
	[PK_AWT_Country] [int] IDENTITY(1,1) NOT NULL,
	[CreatedBy] [varchar](50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
	[CreatedUTC] [datetime] DEFAULT (getutcdate()) NULL,
	[UpdatedBy] [varchar](50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
	[UpdatedUTC] [datetime] DEFAULT (getutcdate()) NULL,
	[AWTYear] [int] NOT NULL,
	[COP] [varchar](2) NOT NULL,
	[COPISO] [varchar](2) NULL
 );
GO
 
