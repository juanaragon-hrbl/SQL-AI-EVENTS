
CREATE TABLE dbo.WRK_AUNZVacation2026_Points(
	  PK_Distributor	INT
	 ,RoyaltyMonth		DATETIME
	 ,ROWW				MONEY
	 ,ROCOP				MONEY
	 ,TVP				MONEY
)
GO

CREATE CLUSTERED INDEX [IX_WRK_AUNZVacation2026_Points_PK_Distributor] ON [dbo].[WRK_AUNZVacation2026_Points] ([PK_Distributor])