CREATE TABLE [dbo].[GDPRTables](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [nvarchar](100) NOT NULL,
	[SchemaName] [nvarchar](100) NOT NULL,
	[TableName] [nvarchar](100) NOT NULL,
	[ConditionId] [nvarchar](400) NOT NULL,
	[Active] [bit] NOT NULL,
	[Removed] [bit] NOT NULL,
	[CreatedDateUTC] [datetime] DEFAULT (getutcdate()) NULL,
	[CreatedBy] [nvarchar](50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,	
	[ModifiedDateUTC] [datetime] DEFAULT (getutcdate()) NULL,
	[ModifiedBy] [nvarchar](50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NULL,
 CONSTRAINT [PK_GDPRTables] PRIMARY KEY CLUSTERED ([Id] ASC));