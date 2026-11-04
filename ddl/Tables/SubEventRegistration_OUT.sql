CREATE TABLE [dbo].[SubEventRegistration_OUT]( 
	[PK_SubEventRegistration] [int] NOT NULL,
	[CreatedDateUTC] [datetime] NULL,
	[CreatedBy] [varchar](50) NULL,
	[ModifiedDateUTC] [datetime] NULL,
	[ModifiedBy] [varchar](50) NULL,
	[PK_EventsRegistration] [int] NOT NULL,
	[PK_SubEventQualifier] [bigint] NULL,
	[Registered] [int] NOT NULL,
)