CREATE TYPE [dbo].[udt_TeamLevelAccess] AS TABLE(
	[SubTypeCode] [nvarchar](8) NULL,
	[PK_EventSubTypeLocaleDesc] [int] NULL,
	[CheckedYN] [int] NULL,
	[Message] [nvarchar](max) NULL
)
GO
