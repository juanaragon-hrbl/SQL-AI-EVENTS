CREATE TABLE [dbo].[GDPRDataElements](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ColumnName] [nvarchar](100) NOT NULL,
	[Description] [nvarchar](200) NOT NULL,
	[Mask] [nvarchar](100) NULL,
	[CreatedDateUTC] [datetime] DEFAULT (getutcdate()) NULL,
	[CreatedBy] [nvarchar](50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,	
	[ModifiedDateUTC] [datetime] DEFAULT (getutcdate()) NULL,
	[ModifiedBy] [nvarchar](50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
 CONSTRAINT [PK_GDPRDataElements] PRIMARY KEY CLUSTERED ([Id] ASC));