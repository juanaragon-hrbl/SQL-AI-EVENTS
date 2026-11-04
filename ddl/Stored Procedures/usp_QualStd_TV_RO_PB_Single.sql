CREATE PROCEDURE [dbo].[usp_QualStd_TV_RO_PB_Single]
	@QualificationType varchar(3) -- TV, RO, PB, PPV, DLV
	,@UseAllQualfications bit = 0 -- Default is to use only qualification that are used by current events
	,@IsDevQA bit = 0
AS
BEGIN

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE 
	@minDate smalldatetime
	,@maxDate smalldatetime
	,@metric varchar(100)
	,@SQL nvarchar(4000)
	,@PK_QualificationType int
	,@PK_QualificationFrequencyType int
	,@ProcName varchar(100)
	,@ProcParam varchar(100)
	,@StartTime datetime
	,@Error varchar(200)

/* Single (In Any xx Months) PK_QualificationFrequencyType = 2 */
SET @PK_QualificationFrequencyType = 2
SET @ProcName = 'usp_QualStd_TV_RO_PB_Single'
SET @ProcParam = @QualificationType
SET @StartTime = GETUTCDATE()

/******************************************************************************************
	defined in dbo.QualificationType
	we're not hard coding the number in the parameter so the job call is more descriptive
	if the qual type is not specified correctly, the procedure will error out, which
	is what we want.
******************************************************************************************/
IF @QualificationType NOT IN ('TV','RO','PB','PPV','DLV','PLV')
BEGIN
	SET @Error = 'Qualification Type Not Valid: ' + @ProcName + ' ' + @ProcParam
	RAISERROR (@Error,18,1)
	RETURN
END

SELECT
	@PK_QualificationType = CASE @QualificationType
								WHEN 'TV' THEN 1
								WHEN 'RO' THEN 2
								WHEN 'PB' THEN 3 
								WHEN 'PPV' THEN 16
								WHEN 'DLV' THEN 17 
								WHEN 'PLV' THEN 37 END

SELECT
	@metric = 	CASE @QualificationType
					WHEN 'TV' THEN 'F.mVolumePoints'
					WHEN 'RO' THEN 'F.mRoyaltyOverrides + F.mMainRoyaltyOverrides'
					WHEN 'PB' THEN 'F.mProductionBonus' 
					WHEN 'PPV' THEN 'F.mPersonalPurchaseVolume'
					WHEN 'DLV' THEN 'F.mDownlineVolume' 
					WHEN 'PLV' THEN 'F.mPersonalPurchaseVolume + F.mDownlineVolume'  END  

/******************************************************************************************
	get date range in aggFQS_ID
******************************************************************************************/
SELECT
	@minDate = MIN(dRoyaltyMonth)
	,@maxDate = MAX(dRoyaltyMonth)
FROM
	dbo.v_aggFQS_ID

IF @IsDevQA = 1 SELECT @minDate AS '@minDate', @maxDate AS '@maxDate'

/******************************************************************************************
	get qualifications	
******************************************************************************************/
if object_id('tempdb..##qualification') is not null drop table ##qualification
CREATE TABLE ##qualification (
	PK_Qualification int
	,QualificationMetric money
	,QualificationFrequency int
	,QualificationDuration int
	,RoyaltyMonth smalldatetime
)

IF @UseAllQualfications = 0
BEGIN
	INSERT
		##qualification
	(
		PK_Qualification
		,QualificationMetric
		,QualificationFrequency
		,QualificationDuration
		,RoyaltyMonth
	)
	SELECT DISTINCT  /* Added Distinct to have eliminate duplicate entries -- Sandhya */ 
		Q.PK_Qualification
		,CONVERT(money,Q.QualificationMetric)
		,Q.QualificationFrequency
		,Q.QualificationDuration
		,M.dMonth
	FROM
		dbo.Qualification Q WITH (NOLOCK)
	INNER JOIN
		dbo.SubEventQualification SEQ WITH (NOLOCK)
		ON
			Q.PK_Qualification = SEQ.PK_Qualification
	INNER JOIN 
		dbo.EventSchedule ES WITH (NOLOCK)
		ON 
			SEQ.PK_Event = ES.PK_Event
			AND
			ES.PK_Schedule = 5 -- Update Qualfication from dbo.Schedule
			AND
			@StartTime BETWEEN ES.BeginUTC AND ES.EndUTC
	CROSS JOIN
		dbo.v_Months M
	WHERE
		M.dMonth BETWEEN SEQ.ValidFromDateUTC AND SEQ.ValidThroughDateUTC
		AND
		Q.PK_QualificationType = @PK_QualificationType
		AND
		Q.PK_QualificationFrequencyType = @PK_QualificationFrequencyType

END ELSE BEGIN
	
	INSERT
		##qualification
	(
		PK_Qualification
		,QualificationMetric
		,QualificationFrequency
		,QualificationDuration
		,RoyaltyMonth
	)
	SELECT
		Q.PK_Qualification
		,CONVERT(money,Q.QualificationMetric)
		,Q.QualificationFrequency
		,Q.QualificationDuration
		,M.dMonth
	FROM
		dbo.Qualification Q WITH (NOLOCK)
	CROSS JOIN
		dbo.v_Months M
	WHERE
		M.dMonth BETWEEN @minDate AND @maxDate
		AND
		Q.PK_QualificationType = @PK_QualificationType
		AND
		Q.PK_QualificationFrequencyType = @PK_QualificationFrequencyType
END

CREATE INDEX IX_qualification_PK_Qualification ON ##qualification (PK_Qualification)
CREATE INDEX IX_qualification_QualificationMetric ON ##qualification (QualificationMetric)
CREATE INDEX IX_qualification_QualificationFrequency ON ##qualification (QualificationFrequency)
CREATE INDEX IX_qualification_QualificationDuration ON ##qualification (QualificationDuration)
CREATE INDEX IX_qualification_RoyaltyMonth ON ##qualification (RoyaltyMonth)

IF @IsDevQA = 1 SELECT PK_Qualification FROM ##qualification

/******************************************************************************************
	get qualifiers	
******************************************************************************************/
IF OBJECT_ID('tempdb..##Quals') IS NOT NULL DROP TABLE ##Quals
CREATE TABLE ##Quals (
	PK_Qualification int
	,PK_Distributor int
	,RoyaltyMonth smalldatetime
	,PK_Country int
	,IsDeleted bit
	,IsType23 bit
	,IsDNR	bit
)

SET @SQL = '
INSERT
	##Quals
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
	Q.PK_Qualification
	,F.nDistributorID
	,Q.RoyaltyMonth
	,C.nCountryID
	,CASE WHEN F.dDeleted = ''2049-12-31'' THEN 0 ELSE 1 END
	,F.nIsAssocType23
	,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
FROM
	##qualification Q
INNER JOIN
	dbo.v_aggFQS_ID F
	ON
		F.dRoyaltyMonth BETWEEN DATEADD(m,-(Q.QualificationDuration)+1,Q.RoyaltyMonth) AND Q.RoyaltyMonth
		AND
		' + @metric + ' >= Q.QualificationMetric
INNER JOIN
	dbo.v_Countries C
	ON
		F.sCOP = C.sCountryCode
LEFT JOIN
	dbo.v_DistributorDoNotRecognize R
	ON
		F.nDistributorID = R.PK_Distributor
GROUP BY
	Q.PK_Qualification
	,Q.QualificationFrequency
	,F.nDistributorID
	,Q.RoyaltyMonth
	,C.nCountryID
	,CASE WHEN F.dDeleted = ''2049-12-31'' THEN 0 ELSE 1 END
	,F.nIsAssocType23
	,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
HAVING
	COUNT(F.dRoyaltyMonth) >= Q.QualificationFrequency'

IF @IsDevQA = 1 PRINT @SQL
EXEC sp_executesql @SQL

CREATE INDEX IX_##Quals_PK_DS_Qual_RoyaltyMonth ON ##Quals(PK_Distributor,PK_Qualification,RoyaltyMonth)
/******************************************************************************
	Merge distributors from qualfication in production table
******************************************************************************/
; WITH Qualifiers(PK_Qualification,PK_Distributor,RoyaltyMonth,PK_Country,IsDeleted,IsType23,IsDNR) AS
(SELECT QD.PK_Qualification,QD.PK_Distributor,QD.RoyaltyMonth,QD.PK_Country,QD.IsDeleted,QD.IsType23,QD.IsDNR 
 FROM dbo.QualificationDistributor QD WITH (NOLOCK) 
 INNER JOIN ##qualification Q ON QD.PK_Qualification = Q.PK_Qualification AND QD.RoyaltyMonth = Q.RoyaltyMonth) 
 MERGE Qualifiers QL
 USING ##Quals DQ
 ON QL.PK_Distributor = DQ.PK_Distributor AND QL.PK_Qualification = DQ.PK_Qualification AND QL.RoyaltyMonth = DQ.RoyaltyMonth
 WHEN MATCHED AND (QL.IsDeleted <> DQ.IsDeleted OR QL.IsType23 <> DQ.IsType23 OR QL.IsDNR <> DQ.IsDNR) THEN
 UPDATE
	SET
		QL.PK_Country = DQ.PK_Country
		,QL.IsDeleted = DQ.IsDeleted
		,QL.IsType23 = DQ.IsType23
		,QL.IsDNR = DQ.IsDNR
WHEN NOT MATCHED BY SOURCE THEN
	DELETE
WHEN NOT MATCHED BY TARGET THEN
	INSERT	(PK_Qualification
			,PK_Distributor
			,RoyaltyMonth
			,PK_Country
			,IsDeleted
			,IsType23
			,IsDNR
		   )
	VALUES (DQ.PK_Qualification
			,DQ.PK_Distributor
			,DQ.RoyaltyMonth
			,DQ.PK_Country
			,DQ.IsDeleted
			,DQ.IsType23
			,DQ.IsDNR
		   );

/******************************************************************************
	clean up
******************************************************************************/
IF OBJECT_ID('tempdb..##Quals') IS NOT NULL DROP TABLE ##Quals
IF OBJECT_ID('tempdb..##qualification') IS NOT NULL DROP TABLE ##qualification

/******************************************************************************
	end procedure
******************************************************************************/
EXEC usp_Utility_UpdateProcessingLog
	@StoredProcedureName = @ProcName
	,@StoredProcedureParameters = @ProcParam
	,@StartTime = @StartTime

END
GO

