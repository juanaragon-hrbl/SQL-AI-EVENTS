CREATE TABLE dbo.WRK_QualPointsConfig
(
	[PK_Event]				int,
	[QualificationNumber]	int,
	[Part]					int,
	[MetricType]			varchar(5),
	[dStartDate]			datetime2,
	[dEndDate]				datetime2,
	[Frequency]				int,
	[Consecutive]			bit, 
	[Accumulated]			bit, 
	[MinPoints]				money,
	[GoalPoints]			money,
	[Countries]				varchar(max)
)
GO
	