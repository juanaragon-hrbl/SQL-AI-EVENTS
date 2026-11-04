CREATE VIEW [dbo].[v_aggFQS_ID]
AS
SELECT 
	RoyaltyMonth AS dRoyaltyMonth
	,PK_Distributor AS nDistributorID
	,DistributorID AS sDistributorID
	,DeletedDate AS dDeleted
	,Qual_SPDate AS dQual_SP
	,Qual_QSDate AS dQual_QS
	,Qual_QSDate_Actual AS dQual_QS_Actual
	,Team AS sTeam
	,COP AS sCOP
	,IsAssocType23 AS nIsAssocType23
	,IsMainID AS nIsMainID
	,IsInAssocTable AS nIsInAssocTable
	,((SP_TV) + ISNULL(SP_MainTV,0) + ISNULL([SP_GCAssoc_TV],0)) AS mVolumePoints
	,(RO + ISNULL([GCAssoc_RO],0)) AS mRoyaltyOverrides 
	,PB AS mProductionBonus
	,SP_PV AS mPersonalVolume
	,SP_GV AS mGroupVolume
	,PPV AS mPersonalPurchaseVolume
	,SP_OV AS mOrganizationalVolume
	,PK_MainDistributor AS nMainDistributorID
	,MainDistributorID AS sMainDistributorID
	,MainDeletedDate AS dMainDeleted
	,MainQual_SPDate AS dMainQual_SP
	,MainTeam AS sMainTeam
	,MainCOP AS sMainCOP
	,MainIsType23 AS nMainIsType23
	,SP_MainTV AS mMainVolumePoints
	,MainRO AS mMainRoyaltyOverrides
	,MainPB AS mMainProductionBonus
	,SP_MainPV AS mMainPersonalVolume
	,SP_MainGV AS mMainGroupVolume
	,MainPPV AS mMainPersonalPurchaseVolume
	,SP_MainOV AS mMainOrganizationalVolume
    ,DLV AS mDownLineVolume 	
	,MPCV AS mMyPreferredCustomerVolume
	,TOTAL_POINTS AS mPPVFromPCAndPPVDirectReferredPC
	,QCPV AS mQualifyingCustomerPersonalVolume
	,QDV AS mQualifyingDownlineVolume 													
	,QDV_DV AS mDocumentedQualifyingDownlineVolume 	
	,PPV_DLV AS mPersonalPurchasedAndDownlineVolume
	,DV_DLVDV AS mDocumentedPersonalPurchasedAndDownlineVolume
	,MainMPCV AS mMainMyPreferredCustomerVolume
	,MainTOTAL_POINTS AS mMainmPPVFromPCAndPPVDirectReferredPC											
	,MainQCPV AS mMainQualifyingCustomerPersonalVolume
	,MainQDV AS mMainQualifyingDownlineVolume											
	,MainQDV_DV AS mMainDocumentedQualifyingDownlineVolume 	
	,MainPPV_DLV AS mMainPersonalPurchasedAndDownlineVolume
	,MainDV_DLVDV AS mMainDocumentedPersonalPurchasedAndDownlineVolume
	,[SP_GCAssoc_TV] mGCAssocVolumePoints
	,[GCAssoc_RO] mGCAssocRoyaltyOverrides	
FROM 
	PubEvents.dbo.aggDSFinancial WITH (NOLOCK)
