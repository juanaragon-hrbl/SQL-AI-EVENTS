
CREATE VIEW [dbo].[v_AWT_Metrics]
AS
SELECT 
	PK_AWT_Metrics
	,CreatedDateUTC
	,CreatedBy
	,Flg1
	,PK_Distributor
	,DistributorID
	,COP
	,isType23
	,Qual_SP
	,RoyaltyMonth
	,TV
	,TV_Accelerator
	,RO
	,did2500KTV
	,did10KTV
	,did500RO
	,did2500KTVL6M
	,did10KTVL6M
	,did500ROL6M
	,didAcc10KTV2CML6M
	,didAWT
FROM 
	dbo.AWT_Metrics