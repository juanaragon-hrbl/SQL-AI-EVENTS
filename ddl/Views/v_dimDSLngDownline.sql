CREATE VIEW [dbo].[v_dimDSLngDownline]
AS
SELECT 
	--DSL.PK_DSLngDownline
	 DSL.PK_Distributor
	,DSL.PK_MainDistributor
	,DSL.PK_DSDownline
	,DSL.DSLevelFromHL
	,DSL.DSLevelFromUL
	,DSL.SPLevelFromHL
	,DSL.SPLevelFromUL
FROM
	PubEvents.dbo.dimDSLngDownline_wBlock DSL (NOLOCK)
GO

