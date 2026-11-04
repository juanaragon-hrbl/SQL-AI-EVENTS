CREATE TABLE dbo.WRK_DistributorAssociation
(
	[PK_DistributorAssociation]	INT IDENTITY(1,1) NOT NULL,
	[PK_Distributor]			INT,	
	[PK_AssociatedID]			INT NOT NULL,
	[AssociationType]			INT NULL,
	[nMainDistributorID]		INT NULL

)
GO