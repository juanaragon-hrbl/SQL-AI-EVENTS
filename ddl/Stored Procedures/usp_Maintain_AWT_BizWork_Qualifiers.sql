CREATE PROCEDURE [dbo].[usp_Maintain_AWT_BizWork_Qualifiers]    
 -- Error Parameters    
 @Error INT = 0  OUTPUT, @ErrorMessage VARCHAR(4000) = NULL OUTPUT  
AS    
BEGIN    
/******************************************************************************    
OBJECT:   dbo.usp_Maintain_AWT_BizWork_Qualifiers    
    
USE:             
                 EXEC dbo.usp_Maintain_AWT_BizWork_Qualifiers    
    
DESCRIPTION: This stored procedure is used to maintain (monthly) AWT qualifiers that will eventually be replicated to BizWorks for reporting purposes.     
    Note that dboAWT_BizWork_Qualifiers cannot be truncated as it is going to be replicated to IAPRODETL.DistributorReporting    
    
NOTES:       
    
DEPENDENCIES    
----------------------------------------------------------------------------------    
dbo.AWT_Qualifiers    
    
    
VERSIONS    
----------------------------------------------------------------------------------    
1 2012-05-31  IniU  Intitial    
2 2019-08-14  NoeG  Refactor code (SRE)    
3 2021-12-23  SushmaA Filter the records not to include any DS ID with length > 10  
******************************************************************************/    
SET ANSI_NULLS ON    
SET QUOTED_IDENTIFIER ON    
SET NOCOUNT OFF       
    
DECLARE @RemovedUTC DATETIME = '2049-12-31'    
DECLARE @ToDay DATETIME = GETUTCDATE()    
DECLARE @ProcessededBy VARCHAR(30) = 'usp_AWT_BizWork_Qualifiers'    
  
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)    
DECLARE  @ProcParamRecur varchar(100) = ''  

IF EXISTS (SELECT 1 FROM [DevAdmin].[ScheduleException] WITH (NOLOCK)
WHERE Active = 1 AND CONVERT(DATE,GETUTCDATE()) BETWEEN StartDate AND EndDate
AND TRIM(REPLACE(REPLACE([StoredProcedureName],'[',''),']','')) = TRIM(REPLACE(REPLACE(@StoredProcedure,'[',''),']','')))
BEGIN
	PRINT 'ScheduleException; The process is skipped.'
	RETURN;
END
ELSE 
BEGIN

BEGIN TRY  
  
IF OBJECT_ID('tempdb..#AWT_Qualifiers') IS NOT NULL    
 DROP TABLE #AWT_Qualifiers     
  
SELECT [PK_AWT_Qualifiers]    
      ,[CreatedDateUTC]    
      ,[CreatedBy]    
      ,[Flg1]    
      ,[AWTYear]    
      ,[PK_Distributor]    
      ,[DistributorID]    
      ,[DateAdded]    
      ,[Qual_AWT]    
INTO #AWT_Qualifiers    
FROM dbo.AWT_Qualifiers WITH (NOLOCK)    
WHERE LEN(DistributorID) <= 10  
    
CREATE INDEX IX_#AWT_Qualifiers_DistributorID ON #AWT_Qualifiers(DistributorID)    
CREATE INDEX IX_#AWT_Qualifiers_PK_Distributor ON #AWT_Qualifiers(PK_Distributor)    
CREATE INDEX IX_#AWT_Qualifiers_PK_Distributor_AWTYear ON #AWT_Qualifiers(AWTYear)    
    
UPDATE     
 A    
SET    
 A.DistributorID = TF.RollupDS    
 ,A.PK_Distributor = D.nDistributorID    
FROM     
 #AWT_Qualifiers A     
INNER JOIN    
 [dbo].[wrk_DistributorTransferExtract] TF WITH (NOLOCK)    
 ON    
  A.DistributorID = TF.FromDS    
INNER JOIN     
 dbo.v_Distributor D    
 ON     
  D.sDistributorID = TF.RollupDS    
    
;WITH Dup AS    
(    
 SELECT    
  *    
  ,ROW_NUMBER() OVER (PARTITION BY DistributorID, AWTYear ORDER BY Qual_AWT, DateAdded) AS Rnk    
 FROM    
  #AWT_Qualifiers    
)    
    
DELETE    
FROM     
 Dup    
WHERE     
 Rnk > 1    
    
   
-- UPDATE, INSERT AND/OR DELETE FROM #AWT_Qualifiers    
  
 MERGE dbo.AWT_BizWork_Qualifiers BWQ    
 USING #AWT_Qualifiers AWQ    
 ON     
  BWQ.PK_Distributor_EDW = AWQ.PK_Distributor    
  AND    
  BWQ.AWTYear = AWQ.AWTYear    
  AND
  BWQ.DistributorID = AWQ.DistributorID
    WHEN MATCHED AND    
  (BWQ.Qual_AWT <> AWQ.Qual_AWT) THEN    
  UPDATE    
  SET    
    BWQ.Qual_AWT = AWQ.Qual_AWT    
   ,BWQ.DateAdded = AWQ.DateAdded     
   ,BWQ.ModifiedDateUTC = @Today    
   ,BWQ.ModifiedBy = @ProcessededBy    
 WHEN NOT MATCHED BY SOURCE THEN    
  DELETE    
 WHEN NOT MATCHED BY TARGET THEN    
  INSERT (PK_Distributor_EDW     
    ,DistributorID      
    ,AWTYear     
    ,DateAdded     
    ,Qual_AWT     
    ,CreatedDateUTC    
    ,CreatedBy     
    ,ModifiedDateUTC     
    ,ModifiedBy       
    )    
  VALUES (AWQ.PK_Distributor    
    ,AWQ.DistributorID      
    ,AWQ.AWTYear     
    ,AWQ.DateAdded     
    ,AWQ.Qual_AWT     
    ,AWQ.CreatedDateUTC     
    ,AWQ.CreatedBy     
    ,AWQ.CreatedDateUTC     
    ,AWQ.CreatedBy     
    );    
    
IF OBJECT_ID('tempdb..#AWT_Qualifiers')    IS NOT NULL DROP TABLE #AWT_Qualifiers  
  
EXEC usp_Utility_UpdateProcessingLog  
 @StoredProcedureName = @ProcessededBy  
 ,@StoredProcedureParameters = @ProcParamRecur  
 ,@StartTime = @ToDay  
  
END TRY  
BEGIN CATCH  
 SET @Error = ERROR_NUMBER()  
 SET @ErrorMessage = ERROR_MESSAGE()  
 SET @StoredProcedure = ERROR_PROCEDURE()  
  
 -- UPDATE ERROR LOG  
 EXEC dbo.usp_Utility_UpdateErrorLog   
   @ProcedureName = @ProcessededBy  
   ,@ErrorNumber = 3  
   ,@ErrorMessage = @ErrorMessage  
   ,@SQLErrorCode = @Error  
   ,@SQLErrorMsg = @ErrorMessage  
     
END CATCH;   

END    
END