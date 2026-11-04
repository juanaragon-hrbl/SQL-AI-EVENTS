CREATE FUNCTION [dbo].[ufn_GetDownlineMX](@StartDateP DATETIME , @EndDateP DATETIME, @StartDateSP DATETIME , @EndDateSP DATETIME, @Points MONEY)
RETURNS @ASP TABLE 
(
	 PK_Distributor INT
	,PK_FirstDownline INT
	,PK_DSDownline INT
	,DSLevel INT
)

/*********************************************************************************************************************
	OBJECT:		dbo.ufn_GetDownlineMX
		
	USE:						
			SELECT FROM ufn_GetDownlineMX 
				
				@StartDateP		= The start date of the points
                ,@EndDateP		= The end date of the points
                ,@StartDateSP	= The SP Qual start date
				,@EndDateSP		= The SP Qual end date
				,@Points		= The Achieve points

	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	SQL SERVER 2010
	
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1	2022-02-03   JonathanO  	Initial 
***********************************************************************************************************************************/


AS
BEGIN


;WITH 
FirstDL (PK_Distributor, PK_FirstDownline) AS 
(
	SELECT 
		DL.PK_Distributor
		,DL.PK_DSDownline 
	FROM
		dbo.v_dimDSLngDownline DL
	INNER JOIN
		dbo.v_Distributor DS
	ON
		DL.PK_Distributor = DS.nDistributorID 
	WHERE  DL.DSLevelFromUL BETWEEN  2 AND 2 
),
LevelDL(PK_Distributor,PK_FirstDownline, PK_DSDownline, DSLevel, COP, Metric) AS
(
	SELECT 
		FL.PK_Distributor
		,FL.PK_FirstDownline
		,DL.PK_DSDownline 
		,DL.DSLevelFromUL
		,DS.nDistributorCountryProcessingID 
		,V.TotalVP
	FROM
		FirstDL FL
	INNER JOIN 
		dbo.v_dimDSLngDownline DL
	ON
		FL.PK_FirstDownline = DL.PK_Distributor 
	INNER JOIN 
		dbo.v_Distributor DS 
	ON
		DL.PK_DSDownline = DS.nDistributorID 
	LEFT JOIN          
	(
		SELECT
			A.nDistributorID, SUM(A.TotalVP) AS TotalVP
		FROM
			(
				SELECT
					vAgg.nDistributorID
					,dRoyaltyMonth
					,CASE WHEN dRoyaltyMonth < ISNULL(vAgg.dQual_SP,DATEADD(MM,1,dRoyaltyMonth)) THEN (SUM(ISNULL(vAgg.mPersonalPurchaseVolume, 0)) + SUM(ISNULL(vAgg.mDownLineVolume, 0)) + SUM(ISNULL(vAgg.mGroupVolume, 0))) 
							ELSE SUM(ISNULL(vAgg.mVolumePoints, 0)) END AS TotalVP
				FROM		
					v_aggFQS_ID vAgg
				WHERE
					vAgg.dRoyaltyMonth BETWEEN @StartDateP AND @EndDateP
				GROUP BY 
					vAgg.nDistributorID,dRoyaltyMonth,vAgg.dQual_SP
			) A 
		GROUP BY 
			A.nDistributorID
	) V
	ON
		DL.PK_DSDownline = V.nDistributorID 
	WHERE
		DL.DSLevelFromUL BETWEEN 1 AND 3
		AND DS.sType = 'SP'
		AND DS.dSupervisorQualification BETWEEN @StartDateSP AND @EndDateSP
	GROUP BY
		FL.PK_Distributor 
		,FL.PK_FirstDownline 
		,DL.DSLevelFromUL
		,DS.nDistributorCountryProcessingID 
		,DL.PK_DSDownline 
		,V.TotalVP
	HAVING  SUM(V.TotalVP)  >= @Points
) 

INSERT INTO @ASP 
	SELECT
		 PK_Distributor
		,PK_FirstDownline
		,PK_DSDownline
		,DSLevel
	FROM
		LevelDL 
		
	RETURN 
END