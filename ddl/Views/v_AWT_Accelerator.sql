
CREATE VIEW [dbo].[v_AWT_Accelerator]
AS
SELECT 
	PK_AWT_Accelerator
	,CreatedDateUTC
	,CreatedBy
	,Flg1
	,PK_AWT_AcceleratorType
	,AWTYear
	,Royaltymonth
	,COP
FROM 
	dbo.AWT_Accelerator