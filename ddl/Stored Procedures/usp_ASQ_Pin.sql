
CREATE PROCEDURE [dbo].[usp_ASQ_Pin]
	@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_ASQ_Pin

USE:			EXEC usp_ASQ_Pin

DESCRIPTION:	Determines who qualifies for 3Pin, 5Pin, 10Pin

DEPENDENCIES
--------------------------------------------------------------------
dbo.app_log_processing

VERSIONS
--------------------------------------------------------------------
1	2010-04-27	Scott & Prabhu	Initial
3	2019-11-04	NoeG	SRE Hardcode changed
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE 
	@startMonth smalldatetime = '2009-02-01'
	,@CreatedDate datetime = GETUTCDATE()
	,@ValidDate DATETIME = '2049-12-31'

/******************************************************************************
	
IF OBJECT_ID('dbo.ASQQualification','U') IS NOT NULL DROP TABLE dbo.ASQQualification
CREATE TABLE dbo.ASQQualification (
	PK_ASQQualification bigint IDENTITY(1,1) PRIMARY KEY
	,CreatedDate datetime DEFAULT GETUTCDATE()
	,PK_Distributor int
	,DistributorID varchar (10)
	,Qual_SP smalldatetime
	,PinType int /* 3; 5; 10 */
	,Qual_Pin smalldatetime
)

CREATE INDEX IX_ASQQualification_PK_Distributor ON ASQQualification (PK_Distributor)
CREATE INDEX IX_ASQQualification_DistributorID ON ASQQualification (DistributorID)
CREATE INDEX IX_ASQQualification_Qual_SP ON ASQQualification (Qual_SP)
CREATE INDEX IX_ASQQualification_PinType ON ASQQualification (PinType)
CREATE INDEX IX_ASQQualification_Qual_Pin ON ASQQualification (Qual_Pin)
CREATE INDEX IX_ASQQualification_CreatedDate ON ASQQualification (CreatedDate)

IF OBJECT_ID('dbo.ASQQualification_IDsForQual','U') IS NOT NULL DROP TABLE dbo.ASQQualification_IDsForQual
CREATE TABLE dbo.ASQQualification_IDsForQual (
	ASQQualification_IDsForQual bigint IDENTITY(1,1) PRIMARY KEY
	,CreatedDate datetime DEFAULT GETUTCDATE()
	,Qual_Pin smalldatetime
	,PK_FirstUplineSP int
	,FirstUplineSPID varchar(10)
	,PK_Distributor int
	,DistributorID varchar (10)
)

CREATE INDEX IX_ASQQualification_IDsForQual_CreatedDate ON ASQQualification_IDsForQual (CreatedDate)
CREATE INDEX IX_ASQQualification_IDsForQual_Qual_Pin ON ASQQualification_IDsForQual (Qual_Pin)
CREATE INDEX IX_ASQQualification_IDsForQual_PK_FirstUplineSP ON ASQQualification_IDsForQual (PK_FirstUplineSP)
CREATE INDEX IX_ASQQualification_IDsForQual_FirstUplineSPID ON ASQQualification_IDsForQual (FirstUplineSPID)
CREATE INDEX IX_ASQQualification_IDsForQual_PK_Distributor ON ASQQualification_IDsForQual (PK_Distributor)
CREATE INDEX IX_ASQQualification_IDsForQual_DistributorID ON ASQQualification_IDsForQual (DistributorID)

******************************************************************************/

IF OBJECT_ID('wrk_ASQQualification','U') IS NOT NULL DROP TABLE wrk_ASQQualification
CREATE TABLE dbo.wrk_ASQQualification (
	PK int IDENTITY(1,1) PRIMARY KEY
	,PK_Distributor int
	,DistributorID varchar (10)
	,PK_FirstUplineSP int
	,FirstUplineSPID varchar(10)
	,Qual_SP smalldatetime
	,Qual_ASQ_3Pin smalldatetime
	,Downline3PinCount int DEFAULT 0
)

CREATE INDEX IX_wrk_ASQQualification_PK_Distributor ON wrk_ASQQualification (PK_Distributor)
CREATE INDEX IX_wrk_ASQQualification_DistributorID ON wrk_ASQQualification (DistributorID)
CREATE INDEX IX_wrk_ASQQualification_PK_FirstUplineSP ON wrk_ASQQualification (PK_FirstUplineSP)
CREATE INDEX IX_wrk_ASQQualification_FirstUplineSPID ON wrk_ASQQualification (FirstUplineSPID)
CREATE INDEX IX_wrk_ASQQualification_Qual_SP ON wrk_ASQQualification (Qual_SP)
CREATE INDEX IX_wrk_ASQQualification_Qual_ASQ_3Pin ON wrk_ASQQualification (Qual_ASQ_3Pin)


/******************************************************************************
	get 3 pin qualifiers
******************************************************************************/
INSERT 
	dbo.wrk_ASQQualification 
(
	PK_Distributor
	,DistributorID
	,Qual_SP
	,Qual_ASQ_3Pin
)
SELECT
	F1.nDistributorID
	,T.sDistributorID
	,dSupervisorQualification
	,DATEADD(m,1,F1.dRoyaltyMonth)
FROM
	dbo.v_aggFQS_ID F1
INNER JOIN
	dbo.v_aggFQS_ID F2
	ON
		F1.nDistributorID = F2.nDistributorID
		AND F2.dRoyaltyMonth = DATEADD(m,-1,F1.dRoyaltyMonth)
		AND F2.mVolumePoints >= 2500
INNER JOIN
	dbo.v_aggFQS_ID F3
	ON
		F1.nDistributorID = F3.nDistributorID
		AND F3.dRoyaltyMonth = DATEADD(m,-2,F1.dRoyaltyMonth)
		AND F3.mVolumePoints >= 2500
INNER JOIN
	dbo.v_Distributor T
	ON
		T.nDistributorID = F1.nDistributorID
WHERE
	F1.mVolumePoints >= 2500
	AND F1.dDeleted = @ValidDate
	AND F1.dRoyaltyMonth >= @startMonth

/******************************************************************************
	get first upline SP
******************************************************************************/
UPDATE
	A
SET
	PK_FirstUplineSP = L.n1stSupervisorID
FROM
	dbo.wrk_ASQQualification A
INNER JOIN
	dbo.v_DistributorLineage L
	ON
		A.PK_Distributor = L.nDistributorID

UPDATE
	A
SET
	FirstUplineSPID = D.sDistributorID
FROM
	dbo.wrk_ASQQualification A
INNER JOIN
	dbo.v_Distributor D
	ON
		A.PK_FirstUplineSP = D.nDistributorID

/******************************************************************************
	get downline count
******************************************************************************/
;WITH DownlineCount (DistributorID, Qual_ASQ_3Pin, Downline3PinCount) AS
(
	SELECT
		UL.DistributorID
		,UL.Qual_ASQ_3Pin
		,COUNT(DL.DistributorID)
	FROM
		dbo.wrk_ASQQualification UL WITH (NOLOCK)
	INNER JOIN
		dbo.wrk_ASQQualification DL WITH (NOLOCK)
		ON
			UL.DistributorID = DL.FirstUplineSPID
			AND UL.Qual_ASQ_3Pin = DL.Qual_ASQ_3Pin
	GROUP BY
		UL.DistributorID
		,UL.Qual_ASQ_3Pin
)
UPDATE
	UL
SET
	Downline3PinCount = DL.Downline3PinCount
FROM
	dbo.wrk_ASQQualification UL
INNER JOIN
	DownlineCount DL
	ON
		UL.DistributorID = DL.DistributorID
		AND UL.Qual_ASQ_3Pin = DL.Qual_ASQ_3Pin

/******************************************************************************
	check 3 pin
******************************************************************************/
;WITH PinType3 (PK_Distributor, DistributorID, Qual_SP, Qual_Pin) AS
(
	SELECT
		W.PK_Distributor
		,W.DistributorID
		,W.Qual_SP
		,MIN(W.Qual_ASQ_3Pin)
	FROM
		dbo.wrk_ASQQualification W WITH (NOLOCK)
	LEFT JOIN
		dbo.ASQQualification A WITH (NOLOCK)
		ON
			W.DistributorID = A.DistributorID
			AND W.Qual_SP = A.Qual_SP
			AND A.PinType = 3
	WHERE
		A.DistributorID IS NULL
		AND W.Qual_SP IS NOT NULL
	GROUP BY
		W.PK_Distributor
		,W.DistributorID
		,W.Qual_SP
)
INSERT
	dbo.ASQQualification
(
	CreatedDate
	,PK_Distributor
	,DistributorID
	,Qual_SP
	,PinType
	,Qual_Pin
)
SELECT
	@CreatedDate
	,PK_Distributor
	,DistributorID
	,Qual_SP
	,3
	,Qual_Pin
FROM
	PinType3

/******************************************************************************
	check 5 pin
******************************************************************************/
;WITH PinType5 (PK_Distributor, DistributorID, Qual_SP, Qual_Pin) AS
(
	SELECT
		W.PK_Distributor
		,W.DistributorID
		,W.Qual_SP
		,MIN(W.Qual_ASQ_3Pin)
	FROM
		dbo.wrk_ASQQualification W WITH (NOLOCK)
	LEFT JOIN
		dbo.ASQQualification A WITH (NOLOCK)
		ON
			W.DistributorID = A.DistributorID
			AND W.Qual_SP = A.Qual_SP
			AND A.PinType = 5
	WHERE
		A.DistributorID IS NULL
		AND W.Downline3PinCount >= 5
		AND W.Qual_SP IS NOT NULL
	GROUP BY
		W.PK_Distributor
		,W.DistributorID
		,W.Qual_SP
)
INSERT
	dbo.ASQQualification
(
	CreatedDate
	,PK_Distributor
	,DistributorID
	,Qual_SP
	,PinType
	,Qual_Pin
)
SELECT
	@CreatedDate
	,PK_Distributor
	,DistributorID
	,Qual_SP
	,5
	,Qual_Pin
FROM
	PinType5

/******************************************************************************
	check 10 pin
******************************************************************************/
;WITH PinType10 (PK_Distributor, DistributorID, Qual_SP, Qual_Pin) AS
(
	SELECT
		W.PK_Distributor
		,W.DistributorID
		,W.Qual_SP
		,MIN(W.Qual_ASQ_3Pin)
	FROM
		dbo.wrk_ASQQualification W WITH (NOLOCK)
	LEFT JOIN
		dbo.ASQQualification A WITH (NOLOCK)
		ON
			W.DistributorID = A.DistributorID
			AND W.Qual_SP = A.Qual_SP
			AND A.PinType = 10
	WHERE
		A.DistributorID IS NULL
		AND W.Downline3PinCount >= 10
		AND W.Qual_SP IS NOT NULL
	GROUP BY
		W.PK_Distributor
		,W.DistributorID
		,W.Qual_SP
)
INSERT
	dbo.ASQQualification
(
	CreatedDate
	,PK_Distributor
	,DistributorID
	,Qual_SP
	,PinType
	,Qual_Pin
)
SELECT
	@CreatedDate
	,PK_Distributor
	,DistributorID
	,Qual_SP
	,10
	,Qual_Pin
FROM
	PinType10


/******************************************************************************
	get the list of ds used to qualify 5 and 10 pin people
******************************************************************************/
;WITH NewQualifiers (DistributorID, Qual_Pin) AS
(
	SELECT DISTINCT
		A.DistributorID
		,A.Qual_Pin
	FROM 
		dbo.ASQQualification A WITH (NOLOCK)
	WHERE
		A.CreatedDate = @CreatedDate
		AND A.PinType > 3
)
INSERT
	dbo.ASQQualification_IDsForQual
(
	CreatedDate
	,Qual_Pin
	,PK_FirstUplineSP
	,FirstUplineSPID
	,PK_Distributor
	,DistributorID
)
SELECT
	@CreatedDate
	,W.Qual_ASQ_3Pin
	,W.PK_FirstUplineSP
	,W.FirstUplineSPID
	,W.PK_Distributor
	,W.DistributorID
FROM
	dbo.wrk_ASQQualification W WITH (NOLOCK)
INNER JOIN
	NewQualifiers NQ
	ON	
		W.FirstUplineSPID = NQ.DistributorID
		AND W.Qual_ASQ_3Pin = NQ.Qual_Pin
ORDER BY
	W.FirstUplineSPID
	,W.Qual_ASQ_3Pin
	,W.PK_Distributor
	,W.DistributorID

/******************************************************************************
	CLEAN UP
******************************************************************************/
IF @IsDevQA = 0
BEGIN
	IF OBJECT_ID('wrk_ASQQualification','U') IS NOT NULL DROP TABLE wrk_ASQQualification
END

/******************************************************************************
	end procedure
******************************************************************************/
END