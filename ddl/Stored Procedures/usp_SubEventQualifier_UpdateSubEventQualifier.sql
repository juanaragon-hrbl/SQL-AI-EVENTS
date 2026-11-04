CREATE PROCEDURE [dbo].[usp_SubEventQualifier_UpdateSubEventQualifier]
	 @IsDevQA bit = 0	-- optional

AS
BEGIN

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE 
	 @ProcName varchar(100)
	,@StartTime datetime
	,@ProcParam varchar(100)	
	,@PKEvent  INT
	
SET @ProcName = 'usp_SubEventQualifier_UpdateSubEventQualifier'
SET @StartTime = GETUTCDATE()
SET @ProcParam = ''

-- Rebuild Statistics in PubEventManagement For dbo.SubEventQualifier
--EXEC dbo.usp_UpdateStatistics @StatType = 'I'

/* DO THE LOCAL TRUNCATE ON THE SUBEVENTQUALIFIER_EXTRACT TABLE */

IF EXISTS (SELECT 1 FROM sysindexes WHERE id=OBJECT_ID('dbo.SubEventQualifier_Extract') AND name='IX_SubEventQualifiers_Extract_Composite')
BEGIN
    DROP INDEX dbo.SubEventQualifier_Extract.IX_SubEventQualifiers_Extract_Composite
    PRINT '<<< DROPPED INDEX dbo.SubEventQualifier_Extract.INDEX IX_SubEventQualifiers_Extract_Composite >>>'
END
/* 
 * INDEX: IX_SubEventQualifiers_Extract_Composite 
 */

IF EXISTS (SELECT 1 FROM sysindexes WHERE id=OBJECT_ID('dbo.SubEventQualifier_Extract') AND name='IX_SubEventQualifiers_Extract_ActionFlg')
BEGIN
    DROP INDEX dbo.SubEventQualifier_Extract.IX_SubEventQualifiers_Extract_ActionFlg
    PRINT '<<< DROPPED INDEX dbo.SubEventQualifier_Extract.INDEX IX_SubEventQualifiers_Extract_ActionFlg >>>'
END
/* 
 * INDEX: IX_SubEventQualifiers_Extract_ActionFlg 
 */
 

IF EXISTS (SELECT 1 FROM sysindexes WHERE id=OBJECT_ID('dbo.SubEventQualifier_Extract') AND name='IX_SubEventQualifiers_Extract_Composite')
BEGIN
    DROP INDEX dbo.SubEventQualifier_Extract.IX_SubEventQualifiers_Extract_Composite
    PRINT '<<< DROPPED INDEX dbo.SubEventQualifier_Extract.INDEX IX_SubEventQualifiers_Extract_Composite >>>'
END
/* 
 * INDEX: IX_SubEventQualifiers_Extract_Composite 
 */
CREATE INDEX IX_SubEventQualifiers_Extract_Composite ON dbo.SubEventQualifier_Extract (PK_Event, PK_SubEvent, PK_Distributor) INCLUDE ([ActionFlg])

IF EXISTS (SELECT 1 FROM sysindexes WHERE id=OBJECT_ID('dbo.SubEventQualifier_Extract') AND name='IX_SubEventQualifiers_Extract_ActionFlg')
BEGIN
    DROP INDEX dbo.SubEventQualifier_ExtractIX_SubEventQualifiers_Extract_ActionFlg
    PRINT '<<< DROPPED INDEX dbo.SubEventQualifier_Extract.INDEX IX_SubEventQualifiers_Extract_ActionFlg >>>'
END
/* 
 * INDEX: IX_SubEventQualifiers_Extract_ActionFlg 
 */
 
CREATE INDEX IX_SubEventQualifiers_Extract_ActionFlg ON dbo.SubEventQualifier_Extract (ActionFlg)

-- UPDATE, INSERT AND/OR DELETE FROM dbo.SubEventQualifier

BEGIN
	MERGE dbo.SubEventQualifier SEQ
	USING (SELECT EXT.PK_Event 
				,EXT.PK_SubEvent 
				,EXT.PK_Distributor 
				,EXT.DistributorID 
				,EXT.QualDate 
				,EXT.AddedUTC 
				,EXT.RemovedUTC 
				,EXT.IsManualOverride 
				,EXT.IsDeleted 
				,EXT.IsDNR 
				,EXT.IsType23 
				,EXT.Qualified 
				,EXT.Quantity 
				,EXT.ActionFlg
				,EXT.Registered
				,ES.PK_Event AS PK_Sche_Event 
		FROM 
			dbo.SubEventQualifier_Extract EXT WITH (NOLOCK) 
		LEFT JOIN
			dbo.EventSchedule ES WITH (NOLOCK) 
		ON 
			EXT.PK_Event = ES.PK_Event AND ES.PK_Schedule = 2 AND ES.EndUTC >= GETUTCDATE()) EXT
	ON 
		SEQ.PK_Event = EXT.PK_Event AND SEQ.PK_SubEvent = EXT.PK_SubEvent AND SEQ.PK_Distributor = EXT.PK_Distributor AND SEQ.RemovedUTC = '2049-12-31'
    WHEN MATCHED AND EXT.ActionFlg = 'U' AND EXT.Registered = CASE WHEN EXT.PK_Sche_Event IS NULL THEN 0 ELSE EXT.Registered END THEN
		UPDATE
		SET
			SEQ.ModifiedDateUTC = GETUTCDATE()
			,SEQ.RemovedUTC = GETUTCDATE()
			,SEQ.Qualified = 0
	WHEN MATCHED AND EXT.ActionFlg = 'D' AND EXT.Registered = 0 THEN
		DELETE
	WHEN NOT MATCHED AND EXT.ActionFlg = 'I' AND EXT.Registered = CASE WHEN EXT.PK_Sche_Event IS NULL THEN 0 ELSE EXT.Registered END THEN
		INSERT (PK_Event 
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
		VALUES (EXT.PK_Event 
				,EXT.PK_SubEvent 
				,EXT.PK_Distributor 
				,EXT.DistributorID 
				,EXT.QualDate 
				,EXT.AddedUTC 
				,EXT.RemovedUTC 
				,EXT.IsManualOverride 
				,EXT.IsDeleted 
				,EXT.IsDNR 
				,EXT.IsType23 
				,EXT.Qualified 
				,EXT.Quantity  
				);
END


-- Get PK_Event processed
SELECT TOP 1 @PKEvent = PK_Event FROM dbo.SubEventQualifier_Extract WITH (NOLOCK) 

-- Generate qualifiers for the evnt
EXEC dbo.usp_SubEventQualEngine_UpdateEventQualifier @PK_Event = @PKEvent

/* END THE PROCEDURE */

SET @ProcParam = CONVERT(VARCHAR,@PKEvent)

/******************************************************************************
	end procedure
******************************************************************************/
EXEC usp_Utility_UpdateProcessingLog
	@StoredProcedureName = @ProcName
	,@StoredProcedureParameters = @ProcParam
	,@StartTime = @StartTime


END
GO

