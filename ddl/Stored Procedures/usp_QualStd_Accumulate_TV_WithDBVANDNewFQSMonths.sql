CREATE PROCEDURE [dbo].[usp_QualStd_Accumulate_TV_WithDBVANDNewFQSMonths] 
	@PK_Event int
	,@PK_SubEvent int
	,@QualificationType varchar(3) -- TV, RO, PB, PPV, DLV
	,@UseAllQualfications bit = 0 -- Default is to use only qualification that are used by current events
	,@IsDevQA bit = 0
AS
BEGIN

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @SQL NVARCHAR(4000)
DECLARE @PK_QualificationType INT = 18	-- Accumulate TV with Double Volume Month(s) and New FQS Promotion Month(s)
DECLARE @PK_QualificationFrequencyType INT = 1 -- Accumulated
DECLARE @StartTime SMALLDATETIME = GETUTCDATE()
DECLARE @minDate SMALLDATETIME
DECLARE @maxDate SMALLDATETIME
DECLARE @ProcName varchar(100)
DECLARE @ProcParam varchar(100)
DECLARE @Error varchar(200)

SET @ProcName = 'usp_QualStd_Accumulate_TV_WithDBVANDNewFQSMonths'
SET @ProcParam = @QualificationType
SET @StartTime = GETUTCDATE()

/******************************************************************************************
7/8/2012 Ini: This is for implementing standard qualifications for total volume points with
			  double volume month(s) and New FQS promotion month(s)
2014-06-25 Ini: Moving this procedure call from step 2 to step 3 (Event/SubEvent level processing). 
				The reason is because of potential issues of diferent events/subevents using same PK_Qualifications
				of PK_QualificationType = 18 but different promotion months and metrics. This way, each event/subevent
				processes and uses its accurate promotion acceleration metrics as applicable.
2020-03-12 SushmaA: Updated the condition to consider only volumes made on or after SP Qual Date if ExtSubEventQualFilter = 1
******************************************************************************************/

SELECT
	@minDate = MIN(dRoyaltyMonth)
	,@maxDate = MAX(dRoyaltyMonth)
FROM
	dbo.v_aggFQS_ID
	
IF OBJECT_ID('tempdb..##Qualification') IS NOT NULL DROP TABLE ##Qualification

CREATE TABLE ##Qualification (
	PK_Qualification int
	,QualificationMetric money
	,QualificationFrequency int
	,QualificationDuration int
	,RoyaltyMonth smalldatetime
	,QualifyMonth smalldatetime
	,PK_PromotionAccelerator int
	,AllowDoubleCounting smallint
	,ExtSubEventQualFilter smallint
)

IF @UseAllQualfications = 0
BEGIN
	INSERT
		##Qualification
	(
		PK_Qualification
		,QualificationMetric
		,QualificationFrequency
		,QualificationDuration
		,RoyaltyMonth
		,QualifyMonth
		,PK_PromotionAccelerator
		,AllowDoubleCounting
		,ExtSubEventQualFilter
	)
	SELECT DISTINCT   /* Added Distinct to eliminate duplicate entries -- Sandhya */ 
		Q.PK_Qualification
		,CONVERT(money,Q.QualificationMetric)
		,Q.QualificationFrequency
		,Q.QualificationDuration
		,M.dMonth
		,SEQ.ValidThroughDateUTC 
		,SEQ.PK_PromotionAccelerator
		,CASE WHEN ISNULL(SEQ.SubEventQualFilter,1) = 1 THEN 1 ELSE 0 END
		,ISNULL(SEQ.ExtSubEventQualFilter, 0)
	FROM
		dbo.Qualification Q WITH(NOLOCK)
	INNER JOIN
		dbo.SubEventQualification SEQ WITH(NOLOCK)
		ON
			SEQ.PK_Event = @PK_Event 
			AND
			SEQ.PK_SubEvent = @PK_SubEvent 
			AND
			Q.PK_Qualification = SEQ.PK_Qualification
	INNER JOIN 
		dbo.EventSchedule ES WITH(NOLOCK)
		ON 
			SEQ.PK_Event = ES.PK_Event
			AND
			ES.PK_Schedule = 5 -- Update Qualfication from dbo.Schedule
			AND
			@StartTime BETWEEN ES.BeginUTC AND ES.EndUTC
	CROSS JOIN
		dbo.v_Months M
	WHERE
		Q.QualificationFrequency = 0	-- This filter is added 3/8/2011 to only do for where all months are in the accumulation
		AND
		M.dMonth BETWEEN DATEADD(M,-1*(QualificationDuration-1),SEQ.ValidThroughDateUTC) AND SEQ.ValidThroughDateUTC  
      /* ValidFromDateUTC is replaced with ValidThroughDateUTC so it doesnt count prior to ValidFromDateUTC in the below temp table -- Sandhya */ 
		AND
		Q.PK_QualificationType = @PK_QualificationType
		AND
		Q.PK_QualificationFrequencyType = @PK_QualificationFrequencyType

END 

IF OBJECT_ID('tempdb..##InitialQuals') IS NOT NULL DROP TABLE ##InitialQuals

CREATE TABLE ##InitialQuals (
      PK_Qualification int
      ,QualificationMetric money
      ,QualificationDuration int
      ,PK_Distributor int
      ,RoyaltyMonth smalldatetime
      ,QualifyMonth smalldatetime
      ,COP varchar(5)
      ,PromotionType varchar(5)
      ,IsDeleted SMALLINT
      ,IsType23 SMALLINT
      ,TV MONEY
      ,DBL_Volume_Points MONEY
	  ,DBL_Volume_Points_Limit MONEY
      ,NewFQS_Points MONEY
      ,IsDoublePromoAllowed SMALLINT
      ,PK_PromotionAccelerator int
)

INSERT INTO ##InitialQuals(
      PK_Qualification 
      ,QualificationMetric 
      ,QualificationDuration
      ,PK_Distributor 
      ,RoyaltyMonth 
      ,QualifyMonth 
      ,COP 
      ,PromotionType 
      ,IsDeleted 
      ,IsType23 
      ,TV 
      ,DBL_Volume_Points
	  ,DBL_Volume_Points_Limit 
      ,NewFQS_Points 
      ,IsDoublePromoAllowed
      ,PK_PromotionAccelerator
)
SELECT DISTINCT  
            Q.PK_Qualification 
            ,Q.QualificationMetric  
            ,Q.QualificationDuration
            ,F1.nDistributorID  
            ,F1.dRoyaltyMonth 
            ,Q.QualifyMonth  
            ,F1.sCOP  
            ,PA.PromotionType 
            ,CASE WHEN F1.dDeleted != '2049-12-31' THEN 1 ELSE 0 END  
            ,F1.nIsAssocType23 AS IsType23  
            ,F1.mVolumePoints 
            ,CASE WHEN PA.PromotionType = 'DBV' AND F1.dRoyaltyMonth = PA.RoyaltyMonth  AND F1.dRoyaltyMonth >= (CASE WHEN Q.ExtSubEventQualFilter = 1 THEN F1.dQual_SP ELSE F1.dRoyaltyMonth END)
															THEN CASE WHEN F1.mVolumePoints >= PA.BreakPoint THEN PA.MaxAcceleratorPoint ELSE F1.mVolumePoints END ELSE 0 END AS DoubleVolPoints
			,CASE WHEN PA.PromotionType = 'DBVL' AND F1.dRoyaltyMonth = PA.RoyaltyMonth THEN CASE WHEN F1.mVolumePoints >= PA.BreakPoint THEN PA.MaxAcceleratorPoint ELSE 0 END ELSE 0 END AS DoubleVolPointsLimit
            ,CASE WHEN PA.PromotionType = 'NWFQS' AND F1.dRoyaltyMonth = PA.RoyaltyMonth AND F1.dRoyaltyMonth = F1.dQual_SP THEN CASE WHEN F1.mVolumePoints >= PA.BreakPoint THEN PA.MaxAcceleratorPoint ELSE F1.mVolumePoints END ELSE 0 END AS NewFQSPoints
            ,Q.AllowDoubleCounting 
            ,Q.PK_PromotionAccelerator
FROM
      dbo.v_aggFQS_ID F1  
INNER JOIN
      ##Qualification Q
ON
      Q.RoyaltyMonth = F1.dRoyaltyMonth
LEFT JOIN
      dbo.PromotionAcceleratorMonths PA (NOLOCK)
ON
      F1.dRoyaltyMonth = PA.RoyaltyMonth 
      AND
      Q.PK_PromotionAccelerator = PA.PK_PromotionAccelerator 
LEFT JOIN
	  dbo.PromotionAcceleratorCountry PC (NOLOCK)
ON
	  PA.PK_PromotionAcceleratorMonth = PC.PK_PromotionAcceleratorMonth	 
INNER JOIN
      dbo.v_Distributor DS
ON
      DS.nDistributorID = F1.nDistributorID 
      AND
      DS.sType = 'SP'
      AND
      DS.sDistributorCountryProcessingCode = F1.sCOP 
      
CREATE INDEX IX_#InitialQuals_PK_Qualification ON ##InitialQuals(PK_Qualification)
CREATE INDEX IX_#InitialQuals_PK_Distributor ON ##InitialQuals(PK_Distributor) 
CREATE INDEX IX_#InitialQuals_RoyaltyMonth ON ##InitialQuals(RoyaltyMonth)           

IF OBJECT_ID('tempdb..##FinalQuals') IS NOT NULL DROP TABLE ##FinalQuals
      
CREATE TABLE ##FinalQuals (
      PK_Qualification int
      ,QualificationMetric money
      ,QualificationDuration int
      ,PK_Distributor int
      ,RoyaltyMonth smalldatetime
      ,QualifyMonth smalldatetime
      ,COP varchar(5)
      ,IsDeleted SMALLINT
      ,IsType23 SMALLINT
      ,TV MONEY
      ,DBL_Volume_Points MONEY
	  ,DBL_Volume_Points_Limit MONEY
      ,NewFQS_Points MONEY
      ,IsDoublePromoAllowed SMALLINT
      ,PK_PromotionAccelerator int
      ,TotalTV AS (ISNULL([TV],0)+CASE WHEN [IsDoublePromoAllowed] = 1 THEN ISNULL([DBL_Volume_Points],0)+ISNULL([NewFQS_Points],0) ELSE 
                                         CASE WHEN ISNULL([DBL_Volume_Points],0) > ISNULL([NewFQS_Points],0) THEN ISNULL([DBL_Volume_Points],0) 
                                              ELSE CASE WHEN ISNULL([DBL_Volume_Points_Limit],0) > ISNULL([NewFQS_Points],0) THEN ISNULL([DBL_Volume_Points_Limit],0)
											  ELSE ISNULL([NewFQS_Points],0) END END END)
)

INSERT INTO ##FinalQuals(
      PK_Qualification
      ,PK_Distributor
      ,RoyaltyMonth
      ,QualifyMonth
      ,QualificationMetric
      ,QualificationDuration
      ,COP
      ,IsDeleted
      ,IsType23
      ,TV
      ,PK_PromotionAccelerator)
SELECT DISTINCT 
      PK_Qualification
      ,PK_Distributor
      ,RoyaltyMonth
      ,QualifyMonth
      ,QualificationMetric
      ,QualificationDuration
      ,COP
      ,IsDeleted
      ,IsType23
      ,TV
      ,PK_PromotionAccelerator
FROM 
      ##InitialQuals

UPDATE
	FQ 
SET
	DBL_Volume_Points				= IQ.DBV
	,DBL_Volume_Points_Limit		= IQ.DBVL
	,NewFQS_Points					= IQ.NewFQSVol 
	,IsDoublePromoAllowed			= CASE WHEN ISNULL(IQ.IsDBLAllowed,0) > 0 THEN 1 ELSE 0 END
FROM	
	##FinalQuals FQ
INNER JOIN
	(SELECT 
            PK_Qualification, 
            PK_Distributor,
            RoyaltyMonth, 
            QualifyMonth,
            PK_PromotionAccelerator,
            QualificationDuration,
            SUM(DBL_Volume_Points) AS DBV, 
			SUM(DBL_Volume_Points_Limit) AS DBVL, 
            SUM(NewFQS_points) AS NewFQSVol,
            SUM(IsDoublePromoAllowed) AS IsDBLAllowed
      FROM
            ##InitialQuals 
      GROUP BY
            PK_Qualification, 
            PK_Distributor,
            RoyaltyMonth,
            QualifyMonth,
            PK_PromotionAccelerator,
            QualificationDuration
      ) IQ
ON
      FQ.PK_Qualification = IQ.PK_Qualification
      AND
      FQ.PK_Distributor = IQ.PK_Distributor 
      AND
      FQ.RoyaltyMonth = IQ.RoyaltyMonth 
      AND
      FQ.QualifyMonth = IQ.QualifyMonth
      AND
      FQ.PK_PromotionAccelerator = IQ.PK_PromotionAccelerator  
      AND
      FQ.QualificationDuration = IQ.QualificationDuration
	
CREATE INDEX IX_#FinalQuals_PK_Qualification ON ##FinalQuals(PK_Qualification)
CREATE INDEX IX_#FinalQuals_PK_Distributor ON ##FinalQuals(PK_Distributor)	
CREATE INDEX IX_#FinalQuals_COP ON ##FinalQuals(COP)

DELETE FROM
	dbo.QualificationDistributor
WHERE
	PK_Qualification IN (
		SELECT
			PK_Qualification
		FROM
			dbo.Qualification WITH(NOLOCK)
		WHERE
			PK_QualificationType = @PK_QualificationType
			AND
			PK_QualificationFrequencyType = 1
			AND
			QualificationFrequency = 0)
			
/******************************************************************************
	Add new qualifiers
******************************************************************************/
INSERT
	dbo.QualificationDistributor
(
	PK_Qualification
	,PK_Distributor
	,RoyaltyMonth
	,PK_Country
	,IsDeleted
	,IsType23
	,IsDNR
)
SELECT
	DISTINCT 
	FQ.PK_Qualification 
	,FQ.PK_Distributor 
	,FQ.RoyaltyMonth 
	,C.nCountryID AS PK_Country
	,FQ.IsDeleted 
	,FQ.IsType23 
	,CASE WHEN R.PK_Distributor IS NOT NULL THEN 1 ELSE 0 END
FROM
(SELECT DISTINCT
      PK_Qualification 
      ,PK_Distributor 
      ,PK_PromotionAccelerator
      ,COP 
      ,IsDeleted 
      ,IsType23 
      ,QualifyMonth AS RoyaltyMonth
      ,MAX(QualificationMetric) AS QualificationMetric
      ,SUM(TotalTV) AS TotalTV
FROM
      ##FinalQuals 
GROUP BY 
      PK_Qualification 
      ,PK_Distributor
      ,PK_PromotionAccelerator
      ,QualifyMonth 
      ,COP 
      ,IsDeleted 
      ,IsType23) FQ
INNER JOIN    
      dbo.v_Countries C   
ON    
      FQ.COP = C.sCountryCode  
LEFT JOIN   
      dbo.v_DistributorDoNotRecognize R   
ON    
      FQ.PK_Distributor = R.PK_Distributor  
WHERE
      FQ.TotalTV >= FQ.QualificationMetric 

/******************************************************************************
	clean up
******************************************************************************/
IF OBJECT_ID('tempdb..##Qualifications') IS NOT NULL DROP TABLE ##Qualifications
IF OBJECT_ID('tempdb..##InitialQuals') IS NOT NULL DROP TABLE ##InitialQuals
IF OBJECT_ID('tempdb..##FinalQuals') IS NOT NULL DROP TABLE ##FinalQuals

/******************************************************************************
	end procedure
******************************************************************************/
EXEC usp_Utility_UpdateProcessingLog
	@StoredProcedureName = @ProcName
	,@StoredProcedureParameters = @ProcParam
	,@StartTime = @StartTime

END