CREATE TABLE [dbo].[EventsTicketsReport](
    [PK_EventsTicketsReport] 	[INT] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PK_Distributor2] 			[INT] NOT NULL ,
	[DistributorId2] 			[VARCHAR] (30) NULL,
	[FirstName2] 				[NVARCHAR] (150) NULL,
	[LastName2] 				[NVARCHAR] (150) NULL,
	[CustCol_2] 				[NVARCHAR] (300) NULL,
	[SpouseFirstName] 			[NVARCHAR] (150) NULL,
	[SpouseLastName] 			[NVARCHAR] (150) NULL,
	[PK_DSType] 				[INT] NULL,
	[TypeDesc] 					[VARCHAR] (30) NULL,
	[PK_Day] 					[INT] NULL,
	[DayDate] 					[DATETIME] NULL,
	[PK_Day1] 					[INT] NULL,
	[SPReQualdate] 				[DATETIME] NULL,
	[PK_DSTeam] 				[INT] NULL,
	[TeamDesc] 					[VARCHAR] (80) NULL,
	[TeamQualDate] 				[DATETIME] NULL,
	[PK_DSSubType] 				[INT] NULL,
	[SubTypeCode] 				[VARCHAR] (5) NULL,
	[SubTypeDesc] 				[VARCHAR] (80) NULL,
	[OrderInformationSKU] 		[VARCHAR] (MAX) NULL,
	[QuantityPurchased] 		[INT] NULL,
	[PK_Country] 				[INT] NULL,
	[CountryCode] 				[VARCHAR] (2) NULL,
	[CountryName] 				[VARCHAR] (200) NULL,
	[PK_Region] 				[INT] NULL,
	[RegionName] 				[VARCHAR] (100) NULL,
	[PK_DSContactInfo] 			[INT] NULL,
	[Address01] 				[NVARCHAR] (240) NULL,
	[Address02] 				[NVARCHAR] (240) NULL,
	[Address03] 				[NVARCHAR] (240) NULL,
	[Address04] 				[NVARCHAR] (240) NULL,
	[City] 						[NVARCHAR] (60) NULL,
	[State] 					[NVARCHAR] (60) NULL,
	[County] 					[NVARCHAR] (60) NULL,
	[PostalCode] 				[NVARCHAR] (60) NULL,
	[Email2] 					[VARCHAR] (250) NULL,
	[CellPhone] 				[VARCHAR] (200) NULL,
	[DayPhone] 					[VARCHAR] (200) NULL,
	[EveningPhone] 				[VARCHAR] (200) NULL,
	[PK_Distributor1] 			[INT] NULL,
	[DistributorId1] 			[VARCHAR] (30) NULL,
	[FirstName1] 				[NVARCHAR] (150) NULL,
	[LastName1] 				[NVARCHAR] (150) NULL,
	[CustCol_33] 				[NVARCHAR] (300) NULL,
	[PK_Distributor0] 			[INT] NULL,
	[DistributorId0] 			[VARCHAR] (30) NULL,
	[FirstName0] 				[NVARCHAR] (150) NULL,
	[LastName0] 				[NVARCHAR] (150) NULL,
	[CustCol_32] 				[NVARCHAR] (300) NULL,
	[PK_Distributor] 			[INT] NULL,
	[DistributorId] 			[VARCHAR] (30) NULL,
	[FirstName] 				[NVARCHAR] (150) NULL,
	[LastName] 					[NVARCHAR] (150) NULL,
	[PK_SubEvent] 				[INT] NULL,
	[SubEventName] 				[VARCHAR] (200) NULL,
	[PK_Event] 					[INT] NULL,
	[EventName] 				[NVARCHAR] (200) NULL,
	[Qualified] 				[BIT] NULL,
	[PK_Distributor_Mill] 		[INT] NULL,
	[DistributorId_Mill] 		[VARCHAR] (30) NULL,
	[FirstName_Mill] 			[NVARCHAR] (150) NULL,
	[LastName_Mill] 			[NVARCHAR] (150) NULL,
	[Name_Mill] 				[NVARCHAR] (300) NULL,
	[PK_Distributor_Tab] 		[INT] NULL,
	[DistributorId_Tab] 		[VARCHAR] (30) NULL,
	[FirstName_Tab] 			[NVARCHAR] (150) NULL,
	[LastName_Tab] 				[NVARCHAR] (150) NULL,
	[Name_Tab] 					[NVARCHAR] (300) NULL,	
	[CreatedDateUTC]            DATETIME      DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]                 VARCHAR (100)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,
 CONSTRAINT [PK_EventsTicketsReport] PRIMARY KEY CLUSTERED ([PK_EventsTicketsReport] ASC));
 GO
CREATE NONCLUSTERED INDEX [IX_EventsTicketsReport_PK_Distributor] ON [dbo].[EventsTicketsReport]
(
	[PK_Distributor] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_EventsTicketsReport_PK_Distributor2] ON [dbo].[EventsTicketsReport]
(
	[PK_Distributor2] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_EventsTicketsReport_PK_Event] ON [dbo].[EventsTicketsReport]
(
	[PK_Event] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO