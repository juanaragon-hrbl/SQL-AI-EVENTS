
CREATE VIEW [dbo].[v_AWT_Qualifiers]
AS
SELECT 
	PK_AWT_Qualifiers
	,CreatedDateUTC
	,CreatedBy
	,Flg1
	,AWTYear
	,PK_Distributor
	,DistributorID
	,DateAdded
	,Qual_AWT
FROM 
	dbo.AWT_Qualifiers