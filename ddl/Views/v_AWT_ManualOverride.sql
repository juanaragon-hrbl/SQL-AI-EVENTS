
CREATE VIEW [dbo].[v_AWT_ManualOverride]
AS
SELECT 
	PK_AWT_ManualOverride
	,CreatedDateUTC
	,CreatedBy
	,Flg1
	,AWTYear
	,PK_Distributor
	,DistributorID
	,DateAdded
	,Qual_AWT
FROM 
	dbo.AWT_ManualOverride