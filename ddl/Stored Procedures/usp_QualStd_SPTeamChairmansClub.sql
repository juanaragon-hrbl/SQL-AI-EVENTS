
CREATE PROCEDURE [dbo].[usp_QualStd_SPTeamChairmansClub]
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

SET @ProcName = 'usp_QualStd_SPTeamChairmansClub'
SET @ProcParam = ''
SET @StartTime = GETUTCDATE()
SELECT @QualID = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'Chairman'

/******************************************************************************
	get current chairman's club members
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
	,CC.PK_Distributor
	,CONVERT(DATETIME,CONVERT(VARCHAR,CC.ChairmanQualificationDate), 112)
	,C.nCountryID
	,CASE WHEN D.dDeleted = '2049-12-31' THEN 0 ELSE 1 END
	,CASE WHEN T.nDistributorID IS NULL THEN 0 ELSE 1 END
	,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
FROM
	dbo.v_DistributorCurrentChairmanClub CC WITH (NOLOCK)
INNER JOIN
	dbo.v_Distributor D WITH (NOLOCK)
	ON
		CC.PK_Distributor = D.nDistributorID
LEFT JOIN
	(SELECT nDistributorID FROM dbo.v_IsType23Distributor WITH (NOLOCK)) T
	ON D.nDistributorID = T.nDistributorID
INNER JOIN
	dbo.v_Countries C WITH (NOLOCK)
	ON
		D.sDistributorCountryProcessingCode = C.sCountryCode
LEFT JOIN
	dbo.v_DistributorDoNotRecognize R WITH (NOLOCK)
	ON
		D.nDistributorID = R.PK_Distributor

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

