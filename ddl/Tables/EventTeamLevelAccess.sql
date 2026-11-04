CREATE TABLE [dbo].[EventTeamLevelAccess](
	[PK_EventTypeTeamLevelAccessEvent] INT IDENTITY(1,1) NOT NULL
	,[PK_DSSubType]					   INT			NOT NULL
	,[SubTypeCode]					   VARCHAR(8)	NOT NULL
	,[PK_EventSubTypeLocaleDesc]	   INT			NULL
	,[Message]						   NVARCHAR(MAX) NULL
	,[CreatedDateUTC]				   DATETIME2	NOT NULL DEFAULT (GETUTCDATE())
	,[CreatedBy]					   NVARCHAR(50) NOT NULL DEFAULT (REPLACE(SUSER_SNAME(),'HERBALIFECORP\','')) 
	,[ModifiedDateUTC]				   DATETIME2	NOT NULL DEFAULT (GETUTCDATE())
	,[ModifiedBy]					   NVARCHAR(50) NOT NULL DEFAULT (REPLACE(SUSER_SNAME(),'HERBALIFECORP\',''))
 CONSTRAINT [PK_EventTypeTeamLevelAccessEvent] PRIMARY KEY CLUSTERED 
([PK_EventTypeTeamLevelAccessEvent] ASC)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
CONSTRAINT [EventTeamLevelAccess_PK_EventSubTypeLocaleDesc] FOREIGN KEY([PK_EventSubTypeLocaleDesc]) REFERENCES [dbo].[EventSubTypeLocaleDesc] ([PK_EventSubTypeLocaleDesc])
)
GO

