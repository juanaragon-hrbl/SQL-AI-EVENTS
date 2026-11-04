CREATE TABLE [dbo].[EventBadgeSubEvents_Archive](
	[PK_EventBadgeSubEvent] [int] NOT NULL,
	[PK_EventBadgePrinting] [int] NOT NULL,
	[PK_Event] [int] NOT NULL,
	[PK_SubEvent] [int] NOT NULL,
	[PK_Distributor] [int] NOT NULL,
	[DistributorID] [varchar](20) NOT NULL,
	[SubEventDisplayName] [nvarchar](100) NULL,
	[SequenceNo] [int] NULL,
	[CreatedDateUTC] [smalldatetime] NOT NULL,
	[CreatedBy] [nvarchar](50) NOT NULL,
	[ModifiedDateUTC] [smalldatetime] NOT NULL,
	[ModifiedBy] [nvarchar](50) NOT NULL 
)