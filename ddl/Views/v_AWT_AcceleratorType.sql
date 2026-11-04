
CREATE VIEW [dbo].[v_AWT_AcceleratorType]
AS
SELECT 
	PK_AWT_AcceleratorType
	,CreatedDateUTC
	,CreatedBy
	,Flg1
	,AcceleratorType
FROM 
	dbo.AWT_AcceleratorType