
CREATE PROCEDURE [dbo].[usp_NAMExtravaganza_UpdateSubEventQualifier]
	 @PK_InEvent INT
	 ,@TabName varchar(200)
	 ,@IsDevQA bit = 0	-- optional

AS
BEGIN

/******************************************************************************
OBJECT:		dbo.usp_NAMExtravaganza_UpdateSubEventQualifier

USE:		EXEC dbo.usp_NAMExtravaganza_UpdateSubEventQualifier

DESCRIPTION:   

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1	2012-03-12  OrlandoL  	Initial
2	2019-11-04	NoeG		SRE Hardcode changed

******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/******************************************************************************
	VARIABLE DECLARETION
******************************************************************************/
DECLARE  @PK_SubEvent5 INT
		,@PK_SubEvent6 INT
		,@PK_SubEvent7 INT
		,@SQLStatement nVarchar(1000)
		,@ValidDate DATETIME = '2049-12-31'
		,@UsrSQLProd VARCHAR(20) = 'UsrSQLProd'


/******************************************************************************
	SELECT PK_SubEvent for each subevent 
******************************************************************************/
SELECT @PK_SubEvent5 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 5
SELECT @PK_SubEvent6 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 6
SELECT @PK_SubEvent7 = PK_SubEvent FROM dbo.SubEvent (NOLOCK) WHERE PK_Event = @PK_InEvent AND SubEventNumber = 7

--IF OBJECT_ID('WRK_NAMExtravaganza','U') IS NOT NULL DROP TABLE dbo.WRK_NAMExtravaganza

--SET @SQLStatement = 'SELECT * INTO dbo.WRK_NAMExtravaganza FROM LS_SQL_BI_DB02.dbo.'+@TabName

--IF OBJECT_ID('WRK_NAMExtravaganza','U') IS NOT NULL DROP TABLE dbo.WRK_NAMExtravaganza

--EXEC sp_executesql @SQLStatement

CREATE INDEX IX_WRK_NAMExtravaganza_PK_Distributor ON dbo.WRK_NAMExtravaganza(PK_Distributor)
	
/* IsE5Qualifier */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ (NOLOCK)
LEFT JOIN
	dbo.WRK_NAMExtravaganza T (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent5
	AND T.IsE5Qualifier = 1
LEFT JOIN
	dbo.EventsRegistration ER (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent5
	
/* IsE6Qualifier */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ (NOLOCK)
LEFT JOIN
	dbo.WRK_NAMExtravaganza T (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent6
	AND T.IsE6Qualifier = 1
LEFT JOIN
	dbo.EventsRegistration ER (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent6
	
/* IsE7Qualifier */
UPDATE
	SQ
SET
	 RemovedUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.RemovedUTC END
	,ModifiedDateUTC = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN GETUTCDATE() ELSE SQ.ModifiedDateUTC END
	,Qualified = CASE WHEN T.PK_Distributor IS NULL AND ER.PK_Distributor IS NULL THEN 0 ELSE SQ.Qualified END
FROM
	dbo.SubEventQualifier SQ (NOLOCK)
LEFT JOIN
	dbo.WRK_NAMExtravaganza T (NOLOCK) 
ON
	T.PK_Distributor = SQ.PK_Distributor 
	AND PK_Event = @PK_InEvent 
	AND PK_SubEvent = @PK_SubEvent7
	AND T.IsE7Qualifier = 1
LEFT JOIN
	dbo.EventsRegistration ER (NOLOCK)
ON
	ER.PK_Event = @PK_InEvent 
	AND
	ER.PK_Distributor = T.PK_Distributor
WHERE
	SQ.PK_Event = @PK_InEvent
AND
	SQ.PK_SubEvent = @PK_SubEvent7

	
/*IsE5Qualifier*/
INSERT
	dbo.SubEventQualifier
(
	CreatedDateUTC
	,CreatedBy
	,ModifiedDateUTC
	,ModifiedBy
	,PK_Event
	,PK_SubEvent
	,PK_Distributor
	,DistributorID
	,QualDate
	,AddedUTC
	,RemovedUTC
	,IsManualOverride
	,IsDeleted
	,IsDNR
	,IsType23
	,Qualified
	,Quantity
)
SELECT DISTINCT
	GETUTCDATE()
	,@UsrSQLProd
	,GETUTCDATE()
	,@UsrSQLProd
	,@PK_InEvent
	,@PK_SubEvent5
	,T.PK_Distributor
	,DS.sDistributorID
	,GETUTCDATE()
	,GETUTCDATE()
	,@ValidDate
	,0
	,0
	,0
	,0
	,1
	,NULL
FROM
	dbo.WRK_NAMExtravaganza T (NOLOCK)
INNER JOIN
	dbo.v_Distributor DS
ON
	T.PK_Distributor = DS.nDistributorID
LEFT JOIN
	 dbo.SubEventQualifier SQ1 (NOLOCK) 
ON
	 SQ1.PK_Event = @PK_InEvent 
	 AND SQ1.PK_SubEvent = @PK_SubEvent5 
	 AND SQ1.RemovedUTC = @ValidDate 
	 AND T.PK_Distributor = SQ1.PK_Distributor
WHERE
	T.IsE5Qualifier = 1
AND
	SQ1.PK_Distributor IS NULL
	
/*Level 5*/
INSERT
	dbo.SubEventQualifier
(
	CreatedDateUTC
	,CreatedBy
	,ModifiedDateUTC
	,ModifiedBy
	,PK_Event
	,PK_SubEvent
	,PK_Distributor
	,DistributorID
	,QualDate
	,AddedUTC
	,RemovedUTC
	,IsManualOverride
	,IsDeleted
	,IsDNR
	,IsType23
	,Qualified
	,Quantity
)
SELECT DISTINCT
	GETUTCDATE()
	,@UsrSQLProd
	,GETUTCDATE()
	,@UsrSQLProd
	,@PK_InEvent
	,@PK_SubEvent6
	,T.PK_Distributor
	,DS.sDistributorID
	,GETUTCDATE()
	,GETUTCDATE()
	,@ValidDate
	,0
	,0
	,0
	,0
	,1
	,NULL
FROM
	dbo.WRK_NAMExtravaganza T (NOLOCK)
INNER JOIN
	dbo.v_Distributor DS
ON
	T.PK_Distributor = DS.nDistributorID
LEFT JOIN
	 dbo.SubEventQualifier SQ1 (NOLOCK) 
ON
	 SQ1.PK_Event = @PK_InEvent 
	 AND SQ1.PK_SubEvent = @PK_SubEvent6 
	 AND SQ1.RemovedUTC = @ValidDate 
	 AND T.PK_Distributor = SQ1.PK_Distributor
WHERE
	T.IsE6Qualifier = 1
AND
	SQ1.PK_Distributor IS NULL
	
/*Ston 3*/
INSERT
	dbo.SubEventQualifier
(
	CreatedDateUTC
	,CreatedBy
	,ModifiedDateUTC
	,ModifiedBy
	,PK_Event
	,PK_SubEvent
	,PK_Distributor
	,DistributorID
	,QualDate
	,AddedUTC
	,RemovedUTC
	,IsManualOverride
	,IsDeleted
	,IsDNR
	,IsType23
	,Qualified
	,Quantity
)
SELECT DISTINCT
	GETUTCDATE()
	,@UsrSQLProd
	,GETUTCDATE()
	,@UsrSQLProd
	,@PK_InEvent
	,@PK_SubEvent7
	,T.PK_Distributor
	,DS.sDistributorID
	,GETUTCDATE()
	,GETUTCDATE()
	,@ValidDate
	,0
	,0
	,0
	,0
	,1
	,NULL
FROM
	dbo.WRK_NAMExtravaganza T (NOLOCK)
INNER JOIN
	dbo.v_Distributor DS
ON
	T.PK_Distributor = DS.nDistributorID
LEFT JOIN
	 dbo.SubEventQualifier SQ1 (NOLOCK) 
ON
	 SQ1.PK_Event = @PK_InEvent 
	 AND SQ1.PK_SubEvent = @PK_SubEvent7 
	 AND SQ1.RemovedUTC = @ValidDate 
	 AND T.PK_Distributor = SQ1.PK_Distributor
WHERE
	T.IsE7Qualifier = 1
AND
	SQ1.PK_Distributor IS NULL
	
	
/******************************************************************************
	UPDATE EVENT QUALIFIER
******************************************************************************/	
EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = @PK_InEvent

/******************************************************************************
	END PROCEDURE
******************************************************************************/	
END