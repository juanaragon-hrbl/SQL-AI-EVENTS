CREATE VIEW [dbo].[v_aggDSFinancial]
AS
SELECT 
	p.RoyaltyMonth AS dRoyaltyMonth
	,p.PK_Distributor AS nDistributorID
	,p.DistributorID AS sDistributorID
	,MAX(p.DeletedDate) AS dDeleted
	,MAX(p.Qual_SPDate) AS dQual_SP
	,MAX(p.Qual_QSDate) AS dQual_QS
	,MAX(p.Qual_QSDate_Actual) AS dQual_QS_Actual
	,MAX(p.Team) AS sTeam
	,MAX(p.COP) AS sCOP
	,MAX(PK_COP) AS PK_COP
	,MAX(COALESCE(p.IsAssocType23,0)) AS nIsAssocType23
	,MAX(COALESCE(p.IsMainID,0)) AS nIsMainID
	,MAX(COALESCE(p.IsInAssocTable,0)) AS nIsInAssocTable
	,SUM(((p.SP_TV) + ISNULL(p.SP_MainTV,0)) + ISNULL([SP_GCAssoc_TV],0)) AS mVolumePoints
	,SUM((p.RO + ISNULL([GCAssoc_RO],0))) AS mRoyaltyOverrides
	,SUM(p.PB) AS mProductionBonus
	,SUM(p.SP_PV) AS mPersonalVolume
	,SUM(p.SP_GV) AS mGroupVolume
	,SUM(p.PPV) AS mPersonalPurchaseVolume
	,SUM(p.SP_OV ) AS mOrganizationalVolume
	,MAX(p.PK_MainDistributor) AS nMainDistributorID
	,MAX(p.MainDistributorID) AS sMainDistributorID
	,MAX(p.MainDeletedDate) AS dMainDeleted
	,MAX(p.MainQual_SPDate) AS dMainQual_SP
	,MAX(p.MainTeam) AS sMainTeam
	,MAX(p.MainCOP) AS sMainCOP
	,MAX(COALESCE(p.MainIsType23,0)) AS nMainIsType23
	,SUM(p.SP_MainTV ) AS mMainVolumePoints
	,SUM(p.MainRO ) AS mMainRoyaltyOverrides
	,SUM(p.MainPB ) AS mMainProductionBonus
	,SUM(p.SP_MainPV ) AS mMainPersonalVolume
	,SUM(p.SP_MainGV ) AS mMainGroupVolume
	,SUM(p.MainPPV ) AS mMainPersonalPurchaseVolume
	,SUM(p.SP_MainOV ) AS mMainOrganizationalVolume
    ,SUM(p.DLV ) AS mDownLineVolume 	
	,SUM(p.MPCV ) AS mMyPreferredCustomerVolume
	,SUM(p.TOTAL_POINTS ) AS mPPVFromPCAndPPVDirectReferredPC
	,SUM(p.QCPV ) AS mQualifyingCustomerPersonalVolume
	,SUM(p.QDV ) AS mQualifyingDownlineVolume 													
	,SUM(p.QDV_DV ) AS mDocumentedQualifyingDownlineVolume 	
	,SUM(p.PPV_DLV ) AS mPersonalPurchasedAndDownlineVolume
	,SUM(p.DV_DLVDV ) AS mDocumentedPersonalPurchasedAndDownlineVolume
	,SUM(p.MainMPCV ) AS mMainMyPreferredCustomerVolume
	,SUM(p.MainTOTAL_POINTS ) AS mMainmPPVFromPCAndPPVDirectReferredPC											
	,SUM(p.MainQCPV ) AS mMainQualifyingCustomerPersonalVolume
	,SUM(p.MainQDV ) AS mMainQualifyingDownlineVolume											
	,SUM(p.MainQDV_DV ) AS mMainDocumentedQualifyingDownlineVolume 	
	,SUM(p.MainPPV_DLV ) AS mMainPersonalPurchasedAndDownlineVolume
	,SUM(p.MainDV_DLVDV ) AS mMainDocumentedPersonalPurchasedAndDownlineVolume
	,SUM(IIF(d.PK_COP = p.PK_Country, ((p.SP_TV) + ISNULL(p.SP_MainTV,0)),0)) AS mVolumePointsLocal
	,SUM(IIF(d.PK_COP = p.PK_Country, p.RO,0)) AS mRoyaltyOverridesLocal
	,SUM(IIF(d.PK_COP = p.PK_Country, p.MainRO,0))  AS mMainRoyaltyOverridesLocal
	,SUM(p.SP_TV) AS mVolumePointsPersonal
	,SUM(ISNULL(p.SP_MainTV,0)) AS mVolumePointsMain
	,SUM([SP_GCAssoc_TV]) mGCAssocVolumePoints
	,SUM([GCAssoc_RO]) mGCAssocRoyaltyOverrides	
FROM 
	[PubEvents].[dbo].[aggDSFinancial_ctry] AS p WITH (NOLOCK)
		INNER JOIN [PubEvents].[dbo].[dimDistributor] AS d WITH (NOLOCK)
			ON p.PK_Distributor = d.PK_Distributor
GROUP BY 
	p.RoyaltyMonth 
	,p.PK_Distributor 
	,p.DistributorID 
	 

