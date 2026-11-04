
CREATE PROCEDURE [dbo].[usp_QualStd_SPTeamNone]
AS
BEGIN

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE 
	@QualID int
	,@ProcName varchar(100)
	,@ProcParam varchar(100)
	,@StartTime datetime

SET @ProcName = 'usp_QualStd_SPTeamNone'
SET @ProcParam = ''
SET @StartTime = GETUTCDATE()
SELECT @QualID = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'NoTeam'

/******************************************************************************
	get current supervisors with no team status
******************************************************************************/
CREATE TABLE #distqual (
	PK_Qualification int
	,PK_Distributor int
	,RoyaltyMonth smalldatetime
	,PK_Country int
	,IsDeleted bit
	,IsType23 bit
	,IsDNR bit
)

INSERT
	#distqual
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
	@QualID
	,D.nDistributorID
	,D.dSupervisorQualification
	,C.nCountryID
	,CASE WHEN D.dDeleted = '2049-12-31' THEN 0 ELSE 1 END
	,CASE WHEN T.nDistributorID IS NULL THEN 0 ELSE 1 END 
	,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
FROM
	dbo.v_Distributor D WITH (NOLOCK)
INNER JOIN
	dbo.v_Countries C WITH (NOLOCK)
	ON
		D.sDistributorCountryProcessingCode = C.sCountryCode
LEFT JOIN
	(SELECT nDistributorID FROM dbo.v_IsType23Distributor WITH (NOLOCK)) T
	ON D.nDistributorID = T.nDistributorID
LEFT JOIN
	dbo.v_DistributorDoNotRecognize R WITH (NOLOCK)
	ON
		D.nDistributorID = R.PK_Distributor
WHERE
	D.sType IN ('SP','RS','RB')
	AND
	(D.sTeam IS NULL OR D.sTeam = '')

/******************************************************************************
	remove distributors from qualfication in production table
******************************************************************************/
DELETE FROM
	dbo.QualificationDistributor
WHERE
	PK_Qualification = @QualID

/******************************************************************************
	add new qualifiers
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
	PK_Qualification
	,PK_Distributor
	,RoyaltyMonth
	,PK_Country
	,IsDeleted
	,IsType23
	,IsDNR
FROM
	#distqual

/******************************************************************************
	end procedure
******************************************************************************/
EXEC usp_Utility_UpdateProcessingLog
	@StoredProcedureName = @ProcName
	,@StoredProcedureParameters = @ProcParam
	,@StartTime = @StartTime

END
GO

