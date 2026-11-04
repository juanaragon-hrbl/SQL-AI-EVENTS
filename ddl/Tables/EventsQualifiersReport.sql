CREATE TABLE [dbo].[EventsQualifiersReport](
    [PK_EventsQualifierReport] [INT] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PK_Subevent] 			[INT] NULL ,
	[SubEventName] 			[VARCHAR] (200) NULL,
	[PK_Distributor] 		[INT] NULL,
	[DistributorId] 		[VARCHAR] (30) NULL,
	[FirstName]				[NVARCHAR] (150) NULL,
	[LastName] 				[NVARCHAR] (150) NULL,
	[PK_Country] 			[INT] NULL,
	[CountryCode] 			[VARCHAR] (2) NULL,
	[CountryName] 			[VARCHAR] (200) NULL,
	[PK_Region] 			[INT] NOT NULL,
	[RegionName] 			[VARCHAR] (100) NULL,
	[PK_DsTeam] 			[INT] NULL,
	[TeamDesc] 				[VARCHAR] (80) NULL,
	[PK_DsType] 			[INT] NULL,
	[TypeDesc] 				[VARCHAR] (30) NULL,
	[PK_Distributor0] 		[INT] NULL,
	[DistributorId0] 		[VARCHAR] (30) NULL,
	[FirstName0] 			[NVARCHAR] (150) NULL,
	[LastName0] 			[NVARCHAR] (150) NULL,
	[CustCol_32] 			[NVARCHAR] (300) NULL,
	[PK_Distributor1] 		[INT] NULL,
	[DistributorId1] 		[VARCHAR] (30) NULL,
	[FirstName1] 			[NVARCHAR] (150) NULL,
	[LastName1] 			[NVARCHAR] (150) NULL,
	[CustCol_33] 			[NVARCHAR] (300) NULL,
	[PK_DSContactInfo] 		[INT] NULL,
	[Address01] 			[NVARCHAR] (240) NULL,
	[Address02] 			[NVARCHAR] (240) NULL,
	[Address03] 			[NVARCHAR] (240) NULL,
	[Address04] 			[NVARCHAR] (240) NULL,
	[City] 					[NVARCHAR] (60) NULL,
	[County] 				[NVARCHAR] (60) NULL,
	[PostalCode] 			[NVARCHAR] (60) NULL,
	[State] 				[NVARCHAR] (60) NULL,
	[OrderInformation] 		[VARCHAR] (MAX) NULL,
	[Quantity] 				[INT] NULL,
	[IsTicketPurchaser] 	[BIT] NULL,
	[PK_Distributor2] 		[BIGINT] NULL,
	[DistributorId2] 		[VARCHAR] (30) NULL,
	[FirstName2] 			[NVARCHAR] (150) NULL,
	[LastName2] 			[NVARCHAR] (150) NULL,
	[CustCol_2] 			[NVARCHAR] (300) NULL,
	[DSSpouseFirstName] 	[NVARCHAR] (150) NULL,
	[DSSpouseLastName] 		[NVARCHAR] (150) NULL,
	[CustCol_3] 			[NVARCHAR] (300) NULL,
	[CellPhone2] 			[NVARCHAR] (200) NULL,
	[DayPhone2] 			[NVARCHAR] (200) NULL,
	[EvePhone2] 			[NVARCHAR] (200) NULL,
	[Email2] 				[NVARCHAR] (250) NULL,
	[PK_Event] 				[INT] NULL,
	[EventName] 			[NVARCHAR] (200) NULL,
	[PK_Day] 				[INT] NULL,
	[SPQualDate] 			[DATETIME] NULL,
	[PK_Day2] 				[INT] NULL,
	[SPReQualDate] 			[DATETIME] NULL,
	[PK_DsSubType] 			[INT] NULL,
	[SubTypeCode] 			[VARCHAR] (5) NULL,
	[SubTypeDesc] 			[VARCHAR] (80) NULL,
	[PK_Day1] 				[INT] NULL,
	[DayDate9] 				[DATETIME] NULL,
	[PK_Language] 			[INT] NULL,
	[LanguageName] 			[VARCHAR] (100) NULL,
	[PK_Country0] 			[INT] NULL,
	[CountryName0] 			[VARCHAR] (200) NULL,
	[MainId] 				[VARCHAR] (30) NULL,
	[TeamQualDate] 			[DATETIME] NULL,
	[SubTeamQualDate] 		[DATETIME] NULL,
	[FirstTimeAwtYear] 		[INT] NULL,
	[IsEventQualifier] 		[INT] NULL,
	[EventQualified] 		[INT] NULL,
	[PK_Distributor_Mill] 	[INT] NULL,
	[DistributorId_Mill] 	[VARCHAR] (30) NULL,
	[FirstName_Mill] 		[NVARCHAR] (150) NULL,
	[LastName_Mill] 		[NVARCHAR] (150) NULL,
	[Name_Mill] 			[NVARCHAR] (300) NULL,
	[PK_Distributor_Tab] 	[INT] NULL,
	[DistributorId_Tab] 	[VARCHAR] (30) NULL,
	[FirstName_Tab] 		[NVARCHAR] (150) NULL,
	[LastName_Tab] 			[NVARCHAR] (150) NULL,
	[Name_Tab] 				[NVARCHAR] (300) NULL,
	[CreatedDateUTC]        DATETIME      DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]             VARCHAR (100)  DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')) NOT NULL,		
 CONSTRAINT [PK_EventsQualifiersReport] PRIMARY KEY CLUSTERED ([PK_EventsQualifierReport] ASC));
 GO
CREATE NONCLUSTERED INDEX [IX_EventsQualifiersReport_PK_Distributor] ON [dbo].[EventsQualifiersReport]
(
	[PK_Distributor] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_EventsQualifiersReport_PK_Distributor2] ON [dbo].[EventsQualifiersReport]
(
	[PK_Distributor2] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_EventsQualifiersReport_PK_Event] ON [dbo].[EventsQualifiersReport]
(	
	[PK_Event] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_EventsQualifiersReport_PK_Event_PK_Region] ON [dbo].[EventsQualifiersReport]
(	
	[PK_Event] ASC,
	[PK_Region] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO