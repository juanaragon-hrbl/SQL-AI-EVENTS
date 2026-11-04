CREATE TABLE dbo.WRK_DSPoints
(
	PK_Distributor			int,
	[PK_Event]				int,
	[PK_Country]			int,
	[RoyaltyMonth]			int,
	[MetricType]			varchar(5),
	[Points]				money,
	[AssociationType]		int,
	[PK_AssociatedID]		int
)
GO

			