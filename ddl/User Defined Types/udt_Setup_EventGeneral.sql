CREATE TYPE [dbo].[udt_Setup_EventGeneral] AS TABLE(
	[CreatedDateUTC] [datetime] NULL DEFAULT (getutcdate()),
	[CreatedBy] [varchar](50) NULL DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')),
	[ModifiedDateUTC] [datetime] NULL DEFAULT (getutcdate()),
	[ModifiedBy] [varchar](50) NULL DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')),
	[ProjectID] [int] NOT NULL,
	[PK_Event] [int] NOT NULL,
	[RFID] [varchar](3) NULL,
	[CountryCode] [varchar](5) NULL,
	[PK_Country] [int] NULL,
	[RegionCode] [varchar](20) NULL,
	[CountryList] [varchar](500) NULL,
	[Location] [varchar](300) NULL,
	[EventTimeZone] [decimal](5, 2) NULL,
	[EventType] [varchar](25) NOT NULL,
	[SubEventType] [varchar](50) NULL,
	[EventName] [varchar](100) NOT NULL,
	[StartUTC] [datetime] NULL,
	[EndUTC] [datetime] NULL,
	[QualPeriodStart] [datetime] NULL,
	[QualPeriodEnd] [datetime] NULL,
	[DisplayStartDate] [datetime] NULL,
	[DisplayEndDate] [datetime] NULL,
	[IsCustomTrackingSiteAvailable] [bit] NULL,
	[CustomTrackingSiteSPName] [nvarchar](150) NULL,
	[CanAssignTickets] [bit] NULL
)
GO





