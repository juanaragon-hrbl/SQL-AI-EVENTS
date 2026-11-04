CREATE TABLE dbo.WRK_NAMLDWFSL_Apr2024_BonusJanToDec
(
	  PK_Distributor	INT
	 ,dApplication		DATETIME
	 ,StatusCode		VARCHAR(30)
	 ,PPV				MONEY DEFAULT 0.00
	 ,IsContributor		BIT DEFAULT 0
	 ,IsActive			BIT DEFAULT 1
)

