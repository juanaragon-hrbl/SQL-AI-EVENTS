/* 02/18/2012 IniU: Added Code to eliminate the MainIDs of Type23s that have more than 2 valid association IDs */


CREATE PROCEDURE [dbo].[usp_SubEventQualEngine_UpdateSubEventQualifier]
	@SubEventID int											-- id of subevent being updated
	,@sTableName varchar(100)								-- table name with list of id's to add to group
	,@IsDevQA bit = 0										-- optional
	,@PK_DistributorColumn varchar(50) = 'PK_Distributor'	-- optional, name of column in table to equate to PK_Distributor
	,@nOverwriteGroup bit = 0								-- optional, if set to 1, then all records for a group are removed first
AS
BEGIN

SET ANSI_NULLS ON
SET XACT_ABORT  ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE 
	@SQL nvarchar(4000)
	,@EventID int
	,@ProcName varchar(100)
	,@ProcParam varchar(100)
	,@StartTime datetime

SET @ProcName = 'usp_SubEventQualEngine_UpdateSubEventQualifier'
SET @ProcParam = CONVERT(varchar,@SubEventID)
SET @StartTime = GETUTCDATE()
SELECT @EventID = PK_Event FROM dbo.SubEvent WITH(NOLOCK) WHERE PK_SubEvent = @SubEventID

/* Declare a Parameter table for Logging Insert/Update/Delete operations on SubEventQualifier(in IAPRODIA) table */

-- UPDATE STATISTICS
-- UPDATE STATISTICS dbo.SubEventQualifier
-- UPDATE STATISTICS dbo.SubEventRegistration

IF OBJECT_ID('tempdb..##SubEventQualifier') IS NOT NULL DROP TABLE ##SubEventQualifier
CREATE TABLE ##SubEventQualifier
(
	PK INT IDENTITY (1,1)
	,CreatedDateUTC DATETIME DEFAULT GETUTCDATE()
	,CreatedBy VARCHAR(20) DEFAULT 'UsrSQLProd'
	,ModifiedDateUTC DATETIME DEFAULT GETUTCDATE()
	,ModifiedBy VARCHAR(20) DEFAULT 'UsrSQLProd'
	,PK_Event INT
	,PK_SubEvent INT
	,PK_Distributor INT
	,DistributorID VARCHAR(30)
	,QualDate DATETIME
	,AddedUTC DATETIME DEFAULT GETUTCDATE()
	,RemovedUTC DATETIME
	,IsManualOverride BIT
	,IsDeleted BIT
	,IsDNR BIT
	,IsType23 BIT
	,Qualified INT
	,Quantity INT
	,ActionFlg CHAR(1)
)

/* update */

	SET @SQL = '
	INSERT INTO ##SubEventQualifier 
		(PK_Event 
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
		,ActionFlg 	
		)
	SELECT
		' + CONVERT(varchar,@EventID) + '
		,' + CONVERT(varchar,@SubEventID) + '
		,Q.PK_Distributor
		,Q.DistributorID
		,Q.QualDate
		,Q.AddedUTC
		,''' + CONVERT(varchar,@StartTime) + '''
		,Q.IsManualOverride 		
		,Q.IsDeleted 
		,Q.IsDNR 
		,Q.IsType23 
		,Q.Qualified 
		,Q.Quantity 
		,''U'' 
	FROM
		dbo.SubEventQualifier Q WITH (NOLOCK)
	WHERE
		Q.PK_SubEvent = ' + CONVERT(varchar,@SubEventID) + '
		AND
		Q.RemovedUTC = ''2049-12-31''
		AND
		Q.IsManualOverride = 0
		AND
		Q.PK_Distributor NOT IN (SELECT ' + @PK_DistributorColumn + ' FROM ' + @sTableName + ')'
	


IF @IsDevQA = 1 BEGIN PRINT @SQL PRINT REPLICATE('-',80) END
EXEC sp_executesql @SQL

/* insert */

SET @SQL = '
	INSERT INTO 
		##SubEventQualifier
		(PK_Event 
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
		,ActionFlg 	
		)
	SELECT DISTINCT
		' + CONVERT(varchar,@EventID) + '
		,' + CONVERT(varchar,@SubEventID) + '
		,P.' + @PK_DistributorColumn + '
		,D.sDistributorID
		,''' + CONVERT(varchar,@StartTime) + '''
		,''' + CONVERT(varchar,@StartTime) + '''
		,''2049-12-31''
		,0
		,CASE WHEN D.dDeleted = ''2049-12-31'' THEN 0 ELSE 1 END
		,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END
		,CASE WHEN T.nDistributorID IS NULL THEN 0 ELSE T.nIsAssocType23 END
		,1
		,NULL
		,''I''
	FROM 
		' + @sTableName + ' P
	INNER JOIN
		dbo.v_Distributor D
		ON
			P.PK_Distributor = D.nDistributorID
	LEFT JOIN 
		(SELECT DISTINCT nDistributorID,nIsAssocType23,dDeleted FROM dbo.v_aggFQS_ID) T
		ON
			P.PK_Distributor = T.nDistributorID							
	LEFT JOIN
		dbo.v_DistributorDoNotRecognize R
		ON
			P.' + @PK_DistributorColumn + ' = R.PK_Distributor		
	WHERE
		NOT EXISTS (
				SELECT *
				FROM
					(SELECT nMainDistributorID,nDistributorID
					 FROM dbo.v_DistributorAssociate2 
					 WHERE Transfer = 0) Type23
				LEFT JOIN
					(SELECT nMainDistributorID,COUNT(1) nCnt
					 FROM dbo.v_DistributorAssociate2 
					 WHERE Transfer = 0
					 AND dThrough = ''2049-12-31''
					 GROUP BY nMainDistributorID) Type23Count
				ON
					Type23.nMainDistributorID = Type23Count.nMainDistributorID
				WHERE
					Type23Count.nCnt > 2 
					AND 
					Type23.nMainDistributorID = Type23.nDistributorID
					AND 
					P.' + @PK_DistributorColumn + ' = Type23.nMainDistributorID
					)
		AND
		NOT EXISTS (
				SELECT 1  
				FROM dbo.SubEventQualifier S WITH (NOLOCK)
				WHERE
					P.' + @PK_DistributorColumn + ' = S.PK_Distributor
					AND S.PK_SubEvent = ' + CONVERT(varchar,@SubEventID) + '
					AND
					S.RemovedUTC = ''2049-12-31'')'
									

IF @IsDevQA = 1 BEGIN PRINT @SQL PRINT REPLICATE('-',80) END
EXEC sp_executesql @SQL


/* delete type 2,3 */

SET @SQL = '
INSERT INTO 
		##SubEventQualifier
		(PK_Event 
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
		,ActionFlg 	
		)
SELECT DISTINCT
		' + CONVERT(varchar,@EventID) + '
		,' + CONVERT(varchar,@SubEventID) + '
		,Q.PK_Distributor
		,Q.DistributorID
		,''' + CONVERT(varchar,@StartTime) + '''
		,''' + CONVERT(varchar,@StartTime) + '''
		,''2049-12-31''
		,Q.IsManualOverride
		,Q.IsDeleted
		,Q.IsDNR
		,Q.IsType23
		,Q.Qualified
		,Q.Quantity
		,''D''
FROM
	dbo.SubEventQualifier Q WITH (NOLOCK)
WHERE 
	Q.PK_SubEvent = ' + CONVERT(varchar,@SubEventID) + '
	AND Q.PK_Distributor IN (	
        SELECT 
             distinct nDistributorID
        FROM
             dbo.v_aggFQS_ID
        WHERE
              nIsAssocType23 = 1
              and
              nIsMainID = 1) 
		AND NOT EXISTS (SELECT 1 FROM dbo.SubEventRegistration R WITH (NOLOCK)
				WHERE R.PK_SubEventQualifier = Q.PK_SubEventQualifier)'

IF @IsDevQA = 1 BEGIN PRINT @SQL PRINT REPLICATE('-',80) END
EXEC sp_executesql @SQL


/* delete TestIDs */


SET @SQL = '
INSERT INTO 
		##SubEventQualifier
		(PK_Event 
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
		,ActionFlg 	
		)
SELECT DISTINCT
		' + CONVERT(varchar,@EventID) + '
		,' + CONVERT(varchar,@SubEventID) + '
		,Q.PK_Distributor
		,Q.DistributorID
		,''' + CONVERT(varchar,@StartTime) + '''
		,''' + CONVERT(varchar,@StartTime) + '''
		,''2049-12-31''
		,Q.IsManualOverride
		,Q.IsDeleted
		,Q.IsDNR
		,Q.IsType23
		,Q.Qualified
		,Q.Quantity
		,''D''
FROM
	dbo.SubEventQualifier Q WITH (NOLOCK)
WHERE 
    Q.PK_SubEvent = ' + CONVERT(varchar,@SubEventID) + '
	AND
	 Q.PK_Distributor IN (	
        SELECT 
             distinct PK_Distributor
        FROM
             dbo.v_DistributorTestIDs)
AND NOT EXISTS (SELECT 1 FROM dbo.SubEventRegistration R WITH (NOLOCK)
				WHERE R.PK_SubEventQualifier = Q.PK_SubEventQualifier)'

IF @IsDevQA = 1 BEGIN PRINT @SQL PRINT REPLICATE('-',80) END
EXEC sp_executesql @SQL

/* Update Quantity */

UPDATE
	SQ
SET
	SQ.Quantity = SAQ.Quantity
FROM	
	##SubEventQualifier SQ
INNER JOIN	
	dbo.SubEventQualifier SEQ WITH (NOLOCK)
	ON
		SQ.PK_SubEvent = SEQ.PK_SubEvent
		AND
		SQ.PK_Distributor = SEQ.PK_Distributor
		AND
		SQ.RemovedUTC = '2049-12-31'
INNER JOIN
	dbo.v_EventCurrentQualificationToUpdate CU
	ON
		CU.PK_Event = SEQ.PK_Event
INNER JOIN
	dbo.SubEvent S WITH (NOLOCK)
	ON
		CU.PK_Event = S.PK_Event
INNER JOIN
	dbo.SubEventGroup G WITH (NOLOCK)
	ON
		G.PK_SubEventGroup = S.PK_SubEventGroup
INNER JOIN
	dbo.SubEventGiveAwayQualifier SAQ WITH (NOLOCK)
	ON
		SAQ.PK_Distributor = SEQ.PK_Distributor
		AND
		SAQ.PK_Event = SEQ.PK_Event
		AND
		SAQ.PK_SubEvent = SEQ.PK_SubEvent
WHERE
	SEQ.RemovedUTC = '2049-12-31'
	AND
	SAQ.RemovedUTC = '2049-12-31'
	AND
	G.SubEventGroup = 'GIVE'
	AND
	NOT EXISTS (SELECT 1 FROM dbo.EventsRegistration ER WITH (NOLOCK) WHERE SEQ.PK_Distributor = ER.PK_Distributor AND SEQ.PK_Event = ER.PK_Event)
	  
IF @IsDevQA = 1 BEGIN PRINT @SQL PRINT REPLICATE('-',80) END
EXEC sp_executesql @SQL

-- Clean data for MERGE Success
DELETE 
	Q
FROM
	##SubEventQualifier Q
INNER JOIN
(
SELECT  
	PK					
	,CreatedDateUTC		
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
	,ActionFlg 
FROM ##SubEventQualifier D where ActionFlg = 'D' 
AND EXISTS (SELECT 1 FROM ##SubEventQualifier U 
WHERE U.ActionFlg = 'U' AND U.PK_Distributor = D.PK_Distributor 
AND D.PK_Event = U.PK_Event AND D.PK_SubEvent = U.PK_SubEvent)
) DD
ON
	Q.PK_Event = DD.PK_Event AND Q.PK_SubEvent = DD.PK_SubEvent AND Q.PK_Distributor = DD.PK_Distributor AND Q.ActionFlg = DD.ActionFlg 

/* TRUNCATE THE TABLE IN THE IA SERVER BEFORE DOING THE FRESH INSERT */

TRUNCATE TABLE dbo.SubEventQualifier_Extract

/* DO THE INSERT NOW */
INSERT INTO
	dbo.SubEventQualifier_Extract
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
	,ActionFlg
)
SELECT
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
	,ActionFlg
FROM
	##SubEventQualifier

-- Update Records for those that have registered and checked into the event already so that their subevent qualifiers records are not touched.	

UPDATE
	EXT
SET
	Registered = 1 
FROM
	dbo.SubEventQualifier_Extract EXT
INNER JOIN
	dbo.EventsRegistration ER (NOLOCK)
ON
	EXT.PK_Event = ER.PK_Event 
	AND
	EXT.PK_Distributor = ER.PK_Distributor 
	AND
	ER.HasCheckedIn = 1


/*** call procedure to update SubEventQualifier table in IAPRODIA */

EXEC dbo.usp_SubEventQualifier_UpdateSubEventQualifier
SET XACT_ABORT  OFF

/******************************************************************************
	end procedure
******************************************************************************/
EXEC usp_Utility_UpdateProcessingLog
	@StoredProcedureName = @ProcName
	,@StoredProcedureParameters = @ProcParam
	,@StartTime = @StartTime

END