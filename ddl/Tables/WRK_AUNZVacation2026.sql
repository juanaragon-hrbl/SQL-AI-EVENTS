CREATE TABLE dbo.WRK_AUNZVacation2026(
	 PK_Distributor			INT
	,COPFreeze				VARCHAR(3)
	,IsAddedFromLists		BIT DEFAULT 0
	,IsFQSNonTABFreeze		BIT DEFAULT 0
	,IsGETMillFreeze		BIT DEFAULT 0	
	,IsPTFreeze				BIT DEFAULT 0	
	,Total_ROCOP			MONEY
	,Total_ROWW				MONEY
	,Total_TVP				MONEY
	,Local_VacationPoints	MONEY
	,WW_VacationPoints		MONEY
	,FirstTimerBonus		MONEY
	,HPLBonus				MONEY
	,MarchBonus				MONEY
	,MayBonus				MONEY
	,Total_BonusesOnly		MONEY
	,Total_Local			MONEY
	,Total_WW				MONEY
)
GO

CREATE CLUSTERED INDEX [IX_WRK_AUNZVacation2026_PK_Distributor] ON [dbo].[WRK_AUNZVacation2026] ([PK_Distributor])