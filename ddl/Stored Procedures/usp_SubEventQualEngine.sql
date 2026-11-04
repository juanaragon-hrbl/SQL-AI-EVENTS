CREATE PROCEDURE [dbo].[usp_SubEventQualEngine]    
    @IsDevQA  BIT = 0   
AS    
BEGIN    
/*********************************************************************************************************************    
 OBJECT:  dbo.usp_SubEventQualEngine    
      
 USE: EXEC dbo.usp_SubEventQualEngine @IsDevQA = 0    
 
 NOTES:      
    
 DEPENDENCIES    
 -----------------------------------------------------------------------------------------------------------------    
 SQL SERVER 2010    
     
 VERSIONS    
 -------------------------------------------------------------------------------------------------------------------------------    
 1  2019-10-16  JonathanO  Refactor code (SRE)    
 1  2026-04-28  rosarioo   Removing inactive promotions    
    
    
***********************************************************************************************************************/      
SET ANSI_NULLS ON    
SET QUOTED_IDENTIFIER ON    
SET NOCOUNT ON    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    

DECLARE    
 @StoredProcedure varchar(100)    
 ,@ProcParam varchar(100)    
 ,@ProcParamRecur varchar(100)    
 ,@StartTime datetime2    
 ,@StartTimeRecur datetime    
 ,@DropTableSQL nvarchar(MAX)    
 ,@PK_Event   int    
 ,@SubEventID int    
 ,@SubEventNumber int    
 ,@CheckDBVQual int     
 ,@EnabledStats bit
 
SET @StoredProcedure = OBJECT_NAME(@@PROCID) 
SET @ProcParam = ''    
SET @StartTime = GETUTCDATE()    
SET @DropTableSQL = ''    
SET @EnabledStats =  ISNULL((SELECT CONVERT(INT,MAX([value])) FROM [Promo].[Options] WITH (NOLOCK) WHERE [Key] = 'EnabledStats' AND [IsActive] = 1 AND [Group] = 'QualEngine'),1)

IF EXISTS (SELECT 1 FROM [DevAdmin].[ScheduleException] WITH (NOLOCK)
WHERE Active = 1 AND CONVERT(DATE,GETUTCDATE()) BETWEEN StartDate AND EndDate
AND TRIM(REPLACE(REPLACE([StoredProcedureName],'[',''),']','')) = TRIM(REPLACE(REPLACE(@StoredProcedure,'[',''),']','')))
BEGIN
	PRINT 'ScheduleException; The process is skipped.'
	RETURN;
END
ELSE 
BEGIN

 -- Rebuild Statistics  
BEGIN TRY  
    IF @IsDevQA = 0 AND @EnabledStats = 1 
    BEGIN
    PRINT 'Rebuilding statistics before processing subevent qualifications...'
    EXEC dbo.sp_updatestats  
    PRINT 'Statistics update completed.'
    END
END TRY
BEGIN CATCH    
       PRINT 'Error occurred while updating statistics.'   
END CATCH

/******************************************************************************    
 process current STANDARD subevent qualifications    
 current subevents are those subevents that are a part of events that     
 have update qualfications schedule active as of @StartTime    
******************************************************************************/    
DECLARE subevent_cursor CURSOR STATIC FOR    
 SELECT DISTINCT    
  SEQ.PK_Event    
  ,SEQ.PK_SubEvent    
  ,SE.SubEventNumber     
 FROM    
  dbo.SubEventQualification SEQ WITH (NOLOCK)    
 INNER JOIN     
  dbo.v_EventCurrentQualificationToUpdate V     
  ON     
   SEQ.PK_Event = V.PK_Event    
 INNER JOIN    
  dbo.Event E WITH (NOLOCK)    
  ON    
   E.PK_Event = V.PK_Event     
   AND    
   E.PK_EventType <> 12    
 INNER JOIN    
  dbo.SubEvent SE WITH (NOLOCK)    
  ON    
   SEQ.PK_Event = SE.PK_Event     
   AND    
   SEQ.PK_SubEvent = SE.PK_SubEvent     
 UNION    
 SELECT     
  SEQ.PK_Event    
  ,SEQ.PK_SubEvent    
  ,SE.SubEventNumber     
 FROM    
  dbo.SubEventQualification SEQ WITH (NOLOCK)    
 INNER JOIN    
  dbo.Event E1 WITH (NOLOCK)    
  ON    
   E1.PK_Event = SEQ.PK_Event     
   AND    
   E1.PK_EventType = 12    
 INNER JOIN    
  dbo.SubEvent SE WITH (NOLOCK)    
  ON    
   SEQ.PK_Event = SE.PK_Event     
   AND    
   SEQ.PK_SubEvent = SE.PK_SubEvent     
 INNER JOIN     
  dbo.v_EventCurrentQualificationToUpdate V1     
  ON     
   V1.PK_Event = E1.PK_Event     
 INNER JOIN    
  dbo.Event E2 WITH (NOLOCK)    
  ON    
   E2.PK_Event = SE.SubEventNumber      
   AND    
   E2.PK_EventType <> 12    
 INNER JOIN     
  dbo.v_EventCurrentQualificationToUpdate V2     
  ON     
   V2.PK_Event = E2.PK_Event    
 ORDER BY    
  SEQ.PK_Event    
  ,SE.SubEventNumber        
    
OPEN subevent_cursor    
FETCH NEXT FROM subevent_cursor INTO @PK_Event, @SubEventID, @SubEventNumber    
    
WHILE @@FETCH_STATUS = 0    
BEGIN    
 SET @StartTimeRecur = GETUTCDATE()    
 SET @ProcParamRecur = CONVERT(VARCHAR,@PK_Event) + ' : ' + CONVERT(VARCHAR,@SubEventID)    
 SET @CheckDBVQual = 0    
     
 SELECT @CheckDBVQual = COUNT(1) FROM dbo.SubEventQualification SEQ  WITH (NOLOCK)    
 INNER JOIN dbo.Qualification Q  WITH (NOLOCK)    
 ON SEQ.PK_Qualification = Q.PK_Qualification AND Q.PK_QualificationType = 18 AND Q.PK_QualificationFrequencyType = 1 AND Q.QualificationFrequency = 0    
 WHERE PK_Event = @PK_Event AND PK_SubEvent = @SubEventID    
     
 -- ONLY Process if SubEvent has DB Volume or NewFQS Promotion criteria    
 IF @CheckDBVQual > 0    
 BEGIN     
  EXEC dbo.usp_QualStd_Accumulate_TV_WithDBVANDNewFQSMonths @PK_Event,@SubEventID,'TV',0,@IsDevQA    
 END    
 EXEC dbo.usp_SubEventQualEngine_ProcessFormula @SubEventID, @IsDevQA    
 EXEC dbo.usp_SubEventQualEngine_ProcessQualifications @SubEventID, @DropTableSQL OUTPUT, @IsDevQA    
 EXEC dbo.usp_SubEventQualEngine_ProcessQualifiers @SubEventID, @DropTableSQL OUTPUT, @IsDevQA    
     
EXEC usp_Utility_UpdateProcessingLog    
 @StoredProcedureName = @StoredProcedure    
 ,@StoredProcedureParameters = @ProcParamRecur    
 ,@StartTime = @StartTimeRecur    
    
 IF @IsDevQA = 1 PRINT @DropTableSQL    
 EXEC sp_executesql @DropTableSQL    
    
 -- Reset variable so that it does not overflow size    
 SET @DropTableSQL = ''     
    
 FETCH NEXT FROM subevent_cursor INTO @PK_Event, @SubEventID, @SubEventNumber    
END    
    
CLOSE subevent_cursor    
DEALLOCATE subevent_cursor    
   
 
/* Process to obtain the contributors' IDs for those distributors involved in divorces cases */       
EXEC [Shared].[usp_GetDistributorAssociation]

/* Process to obtain the contributors' IDs for those distributors involved in transfer cases */       
EXEC [Shared].[usp_GetDistributorTransfers]


-- Insert Leads By COP
IF DAY(GETUTCDATE()) >= 15 AND DAY(GETUTCDATE()) <= 18    
BEGIN    
    EXEC dbo.usp_InsertLeadsByCOP_EventQualifier 
END
    
-- Virtual events custom registration
IF (DAY(GETUTCDATE()) IN (10,20))			-- Run every 10 and 20 each month
BEGIN
    EXEC dbo.usp_CustomEventRegistration
END

-- Unpublish PM Promos with dEndUTC +12 months old. Task 327640
IF (DAY(GETUTCDATE()) IN (1,8,15,22,28))			-- Run every 1,8,15,22 & 28 each month
BEGIN
		UPDATE Event
		SET IsPublish = 0
		WHERE PK_EventType = 15		-- PM Promos
		AND IsPublish = 1				
		AND DATEADD(MONTH,12,dEndUTC)<= GETDATE() 
END
        
/* Update PinReport Table With New Qualifiers */    
EXEC dbo.usp_Update_PinReport @PK_Event = 678    

-- Rebuild Statistics  
BEGIN TRY  
    IF @IsDevQA = 0 AND @EnabledStats = 1 
    BEGIN
    PRINT 'Rebuilding statistics after processing subevent qualifications...'
    EXEC dbo.sp_updatestats  
    PRINT 'Statistics update completed.'
    END          
END TRY
BEGIN CATCH    
       PRINT 'Error occurred while updating statistics.'   
END CATCH

/******************************************************************************    
 END PROCEDURE    
******************************************************************************/    
EXEC usp_Utility_UpdateProcessingLog  
 @StoredProcedureName = @StoredProcedure  
 ,@StoredProcedureParameters = @ProcParam  
 ,@StartTime = @StartTime  
  
END
END;