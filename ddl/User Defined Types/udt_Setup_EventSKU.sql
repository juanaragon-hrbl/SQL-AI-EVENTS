CREATE TYPE [dbo].[udt_Setup_EventSKU] AS TABLE(
	[CreatedDateUTC] [datetime] NULL DEFAULT (getutcdate()),
	[CreatedBy] [varchar](50) NULL DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')),
	[ModifiedDateUTC] [datetime] NULL DEFAULT (getutcdate()),
	[ModifiedBy] [varchar](50) NULL DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')),
	[PK_Event] [int] NOT NULL,
	[SKUCode] [varchar](4) NOT NULL,
	[SKUDesc] [varchar](100) NULL,
	[Price] [money] NULL,
	[VolumePoints] [numeric](8, 2) NULL,
	[QuantityInStock] [int] NULL,
	[QuantitySold] [int] NULL,
	[WareHouseID] [int] NULL,
	[SKUValidBeginUTC] [smalldatetime] NULL,
	[SKUValidEndUTC] [smalldatetime] NULL,
	[NumberOfTicketsPerSKU] [int] NOT NULL DEFAULT ((1)),
	[PK_EventSKUType] [int] NOT NULL,
	[PK_Country] [int] NULL,
	[IsEventTicketSKU] [int] NULL DEFAULT ((1)),
	[ProcessSKU] [bit] NULL DEFAULT ((1)),
	[PK_Locale] [int] NULL,
	[IsGenerateNote] [bit] NULL DEFAULT ((0)),
	[IsTrackingVisible] [bit] NOT NULL DEFAULT ((1)),
	[IsSKUUsedInPreOrder] [bit] NOT NULL DEFAULT ((0)),
	[SubEventAssociated] [int] NULL DEFAULT ((0))
)
GO


