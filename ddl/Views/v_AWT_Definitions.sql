
CREATE VIEW [dbo].[v_AWT_Definitions]
AS
SELECT 
	PK_AWT_Definitions
	,CreatedDateUTC
	,CreatedBy
	,Flg1
	,AWTYear
	,StartDate
	,EndDate
	,NonTABDate
FROM 
	dbo.AWT_Definitions