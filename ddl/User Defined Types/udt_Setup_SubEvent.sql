CREATE TYPE [dbo].[udt_Setup_SubEvent] AS TABLE(
	[CreatedDateUTC] [datetime] NULL DEFAULT (getutcdate()),
	[CreatedBy] [varchar](50) NULL DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')),
	[ModifiedDateUTC] [datetime] NULL DEFAULT (getutcdate()),
	[ModifiedBy] [varchar](50) NULL DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')),
	[PK_Event] [int] NOT NULL,
	[PK_SubEventType] [int] NOT NULL,
	[MaxCapacity] [int] NOT NULL DEFAULT ((1)),
	[ExpectedCapacity] [int] NOT NULL DEFAULT ((1)),
	[SubEventName] [varchar](200) NULL,
	[SubEventNumber] [int] NULL,
	[SubEventFormula] [varchar](2000) NULL,
	[KeepDNR] [bit] NULL DEFAULT ((1)),
	[KeepDeleted] [bit] NULL DEFAULT ((0)),
	[SubEventNamePositionID] [int] NULL,
	[Location] [nvarchar](300) NULL,
	[LocalName] [nvarchar](300) NULL,
	[BeginTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[PK_SubEventGroup] [int] NULL,
	[isTrackingVisible] [bit] NULL DEFAULT ((1)),
	[IsMainEventQual] [bit] NULL DEFAULT ((0)),
	[CanProcessQual] [bit] NULL DEFAULT ((1)),
	[IsBBBreakDownReqd] [bit] NULL DEFAULT ((0)),
	[IsDiamondRptReqd] [bit] NULL DEFAULT ((0)),
	[IncludeInBizworkReport] [bit] NULL DEFAULT ((0))
)
GO


