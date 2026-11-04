CREATE VIEW [dbo].[v_aggDSFinancial_ctry]
AS
 SELECT
	p.RoyaltyMonth AS dRoyaltyMonth
	,p.PK_Country
	,p.PK_Distributor AS nDistributorID
	,p.DistributorID AS sDistributorID
	,p.DeletedDate AS dDeleted
	,p.Qual_SPDate AS dQual_SP
	,p.Qual_QSDate AS dQual_QS
	,p.Qual_QSDate_Actual AS dQual_QS_Actual
	,p.Team AS sTeam
	,p.COP AS sCOP
	,PK_COP
	,p.IsAssocType23 AS nIsAssocType23
	,p.IsMainID AS nIsMainID
	,p.IsInAssocTable AS nIsInAssocTable
	,((p.SP_TV) + ISNULL(p.SP_MainTV,0) + ISNULL([SP_GCAssoc_TV],0))AS mVolumePoints
	,(RO + ISNULL([GCAssoc_RO],0)) AS mRoyaltyOverrides 
	,p.PB AS mProductionBonus
	,p.SP_PV AS mPersonalVolume
	,p.SP_GV AS mGroupVolume
	,p.PPV AS mPersonalPurchaseVolume
	,p.SP_OV AS mOrganizationalVolume
	,p.PK_MainDistributor AS nMainDistributorID
	,p.MainDistributorID AS sMainDistributorID
	,p.MainDeletedDate AS dMainDeleted
	,p.MainQual_SPDate AS dMainQual_SP
	,p.MainTeam AS sMainTeam
	,p.MainCOP AS sMainCOP
	,p.MainIsType23 AS nMainIsType23
	,p.SP_MainTV AS mMainVolumePoints
	,p.MainRO AS mMainRoyaltyOverrides
	,p.MainPB AS mMainProductionBonus
	,p.SP_MainPV AS mMainPersonalVolume
	,p.SP_MainGV AS mMainGroupVolume
	,p.MainPPV AS mMainPersonalPurchaseVolume
	,p.SP_MainOV AS mMainOrganizationalVolume
    ,p.DLV AS mDownLineVolume 	
	,p.MPCV AS mMyPreferredCustomerVolume
	,p.TOTAL_POINTS AS mPPVFromPCAndPPVDirectReferredPC
	,p.QCPV AS mQualifyingCustomerPersonalVolume
	,p.QDV AS mQualifyingDownlineVolume 													
	,p.QDV_DV AS mDocumentedQualifyingDownlineVolume 	
	,p.PPV_DLV AS mPersonalPurchasedAndDownlineVolume
	,p.DV_DLVDV AS mDocumentedPersonalPurchasedAndDownlineVolume
	,p.MainMPCV AS mMainMyPreferredCustomerVolume
	,p.MainTOTAL_POINTS AS mMainmPPVFromPCAndPPVDirectReferredPC											
	,p.MainQCPV AS mMainQualifyingCustomerPersonalVolume
	,p.MainQDV AS mMainQualifyingDownlineVolume											
	,p.MainQDV_DV AS mMainDocumentedQualifyingDownlineVolume 	
	,p.MainPPV_DLV AS mMainPersonalPurchasedAndDownlineVolume
	,p.MainDV_DLVDV AS mMainDocumentedPersonalPurchasedAndDownlineVolume
	,[SP_GCAssoc_TV] mGCAssocVolumePoints
	,[GCAssoc_RO] mGCAssocRoyaltyOverrides	
	,IIF(d.PK_COP = p.PK_Country, 1,0) IsLocalVolume
FROM 
	[PubEvents].[dbo].[aggDSFinancial_ctry] AS p WITH (NOLOCK)
		INNER JOIN [PubEvents].[dbo].[dimDistributor] AS d WITH (NOLOCK)
			ON p.PK_Distributor = d.PK_Distributor
GO


