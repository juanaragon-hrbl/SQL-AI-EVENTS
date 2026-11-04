CREATE TABLE dbo.[EventSKU_DependencyRemoval]
(
	[PK_EventSKU_DependencyRemoval] INT IDENTITY(1,1),
	[CreatedDateUTC] DATETIME DEFAULT (getutcdate()), 
	[CreatedBy] VARCHAR(50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')),  
	[ModifiedDateUTC] DATETIME DEFAULT (getutcdate()), 
	[ModifiedBy] VARCHAR(50) DEFAULT (replace(suser_sname(),'HERBALIFECORP\','')),  
	PK_Event BIGINT,
	PK_EventSKU BIGINT,
	[SKUCode] VARCHAR(25),
	[Status] VARCHAR(35),
	[Active] BIT 
)