CREATE FUNCTION dbo.ufn_GetPointsByType (@PK_Distributor INT, @MetricType VARCHAR(3),@StartDate SMALLDATETIME,@EndDate SMALLDATETIME)
RETURNS TABLE
AS RETURN(
	SELECT 
		RoyaltyMonth
		,PK_Distributor
		,DistributorID
		,DeletedDate AS dDeleted
		,Qual_SPDate AS dQual_SP
		,Qual_QSDate AS dQual_QS
		,Qual_QSDate_Actual AS dQual_QS_Actual
		,Team AS sTeam
		,COP AS sCOP
		,IsAssocType23 AS nIsAssocType23
		,IsMainID AS nIsMainID
		,IsInAssocTable AS nIsInAssocTable
		,PK_MainDistributor AS nMainDistributorID
		,MainDistributorID AS sMainDistributorID
		,MainDeletedDate AS dMainDeleted
		,MainQual_SPDate AS dMainQual_SP
		,MainTeam AS sMainTeam
		,MainCOP AS sMainCOP
		,MainIsType23 AS nMainIsType23
		,@MetricType AS MetricType   
		,CASE @MetricType
			WHEN 'PPV'	THEN PPV
			WHEN 'TV'	THEN ((SP_TV) + ISNULL(SP_MainTV,0))
			WHEN 'RO'	THEN RO + MainRO
			WHEN 'DLV'	THEN DLV
			WHEN 'PB'	THEN PB
		END AS [Points]
		,CASE @MetricType
			WHEN 'PPV'	THEN 1
			WHEN 'TV'	THEN 2
			WHEN 'RO'	THEN 3
			WHEN 'DLV'	THEN 4
			WHEN 'PB'	THEN 5
		END AS [MetricTypeID]
	FROM 
	pubEvents.dbo.aggDSFinancial WITH (NOLOCK)
	WHERE (PK_Distributor = @PK_Distributor OR @PK_Distributor IS NULL)
	AND RoyaltyMonth BETWEEN @StartDate AND @EndDate
);