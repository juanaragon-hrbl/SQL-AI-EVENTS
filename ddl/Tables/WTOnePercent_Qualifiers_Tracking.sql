CREATE TABLE dbo.WTOnePercent_Qualifiers_Tracking (
    [PK_WTOnePercent_Tracking] INT			IDENTITY (1, 1) NOT NULL,
    [PK_Distributor]		INT				NULL,
    [DistributorID]			VARCHAR (35)	NULL,
    [COP]					VARCHAR (2)		NULL,
	[QualifiedYear]         INT				NULL,
    [Jan]					BIT				DEFAULT ((0)) NULL,
    [Feb]					BIT				DEFAULT ((0)) NULL,
    [Mar]					BIT				DEFAULT ((0)) NULL,
    [Apr]					BIT				DEFAULT ((0)) NULL,
    [May]					BIT				DEFAULT ((0)) NULL,
    [Jun]					BIT				DEFAULT ((0)) NULL,
    [Jul]					BIT				DEFAULT ((0)) NULL,
    [Aug]					BIT				DEFAULT ((0)) NULL,
    [Sep]					BIT				DEFAULT ((0)) NULL,
    [Oct]					BIT				DEFAULT ((0)) NULL,
    [Nov]					BIT				DEFAULT ((0)) NULL,
    [Dec]					BIT				DEFAULT ((0)) NULL,
	[CreatedDateUTC]		DATETIME		DEFAULT (GETUTCDATE()) NOT NULL,
    [CreatedBy]				VARCHAR (100)	DEFAULT (REPLACE(SUSER_SNAME(),'HERBALIFECORP\','')) NOT NULL,
    [ModifiedDateUTC]		DATETIME		DEFAULT (GETUTCDATE()) NOT NULL,
    [ModifiedBy]			VARCHAR (100)	DEFAULT (REPLACE(SUSER_SNAME(),'HERBALIFECORP\','')) NOT NULL
   );
GO

CREATE NONCLUSTERED INDEX [IX_WTOnePercent_Tracking_PK_Distributor] ON dbo.WTOnePercent_Qualifiers_Tracking (PK_Distributor)
GO

CREATE NONCLUSTERED INDEX [IX_WTOnePercent_Tracking_QualifiedYear] ON WTOnePercent_Qualifiers_Tracking (QualifiedYear);
GO



