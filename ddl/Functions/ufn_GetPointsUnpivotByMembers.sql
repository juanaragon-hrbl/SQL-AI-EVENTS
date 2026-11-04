CREATE FUNCTION [dbo].[ufn_GetPointsUnpivotByMembers] (
@StartDate SMALLDATETIME, 
@EndDate SMALLDATETIME,
@MBIDs [dbo].[MemberList] READONLY)
RETURNS TABLE
AS RETURN(
SELECT 
 		RoyaltyMonth
		,PK_Distributor
		,DistributorID
		,dDeleted
		,dQual_SP
		,dQual_QS
		,dQual_QS_Actual
		,sTeam
		,sCOP
		,nIsAssocType23
		,nIsMainID
		,nIsInAssocTable
		,nMainDistributorID
		,sMainDistributorID
		,dMainDeleted
		,dMainQual_SP
		,sMainTeam
		,sMainCOP
		,nMainIsType23
		,MetricType
		,Points

FROM(
	SELECT 
		a.RoyaltyMonth
		,a.PK_Distributor
		,a.DistributorID
		,a.DeletedDate AS dDeleted
		,a.Qual_SPDate AS dQual_SP
		,a.Qual_QSDate AS dQual_QS
		,a.Qual_QSDate_Actual AS dQual_QS_Actual
		,a.Team AS sTeam
		,a.COP AS sCOP
		,a.IsAssocType23 AS nIsAssocType23
		,a.IsMainID AS nIsMainID
		,a.IsInAssocTable AS nIsInAssocTable
		,a.PK_MainDistributor AS nMainDistributorID
		,a.MainDistributorID AS sMainDistributorID
		,a.MainDeletedDate AS dMainDeleted
		,a.MainQual_SPDate AS dMainQual_SP
		,a.MainTeam AS sMainTeam
		,a.MainCOP AS sMainCOP
		,a.MainIsType23 AS nMainIsType23
		,a.PPV
		,((a.SP_TV) + ISNULL(a.SP_MainTV,0)) AS TV
		,(a.RO + a.MainRO) AS RO
		,a.DLV
		,a.PB
	FROM 
	pubEvents.dbo.aggDSFinancial a WITH (NOLOCK)
		INNER JOIN @MBIDs M ON M.[MemberID] = a.PK_Distributor
	WHERE a.RoyaltyMonth BETWEEN @StartDate AND @EndDate) P
	UNPIVOT 
	(
		Points FOR MetricType IN (PPV,TV,RO, DLV, PB)

	) AS unpvt
);
GO
