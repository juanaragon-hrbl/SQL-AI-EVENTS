CREATE PROCEDURE [dbo].[usp_QualStd_DSTypeSeniorConsultant]  
----WITH EXECUTE AS 'dbo'  
AS  
BEGIN  
/******************************************************************************  
OBJECT:  dbo.usp_QualStd_DSTypeSeniorConsultant
  
USE:  EXEC dbo.usp_QualStd_DSTypeSeniorConsultant 
  
DESCRIPTION:  Get SC records
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
VERSIONS  
--------------------------------------------------------------------    
2   2016-11-11   SandhyaP  Netizza reference changes  
******************************************************************************/  
  
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
DECLARE   
 @QualID int  
 ,@ProcName varchar(100)  
 ,@ProcParam varchar(100)  
 ,@StartTime datetime  
  
SET @ProcName = 'usp_QualStd_DSTypeSeniorConsultant'  
SET @ProcParam = ''  
SET @StartTime = GETUTCDATE()  
SELECT @QualID = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'SC'  
  
/******************************************************************************  
 get current distriburor who are not supervisors  
******************************************************************************/  
IF OBJECT_ID ('tempdb..#distqual') IS NOT NULL DROP TABLE #distqual  
CREATE TABLE #distqual (  
 PK_Qualification int  
 ,PK_Distributor int  
 ,RoyaltyMonth smalldatetime  
 ,PK_Country int  
 ,IsDeleted bit  
 ,IsType23 bit  
 ,IsDNR bit  
)  

;WITH   
 SC (PK_Distributor) AS  
 (  
  SELECT  
   PK_Distributor 
  FROM  
   pubEvents.dbo.dimDistributor WITH (NOLOCK)  
  WHERE   
   SubTypeCode = 'SC' --changed  
 )  
 ,SCQual (PK_Distributor, Qual_SC) AS  
 (  
  SELECT  
   H.PK_Distributor  
   ,MAX(FromDate)  
  FROM  
   pubEvents.dbo.dimDSHistory H  WITH (NOLOCK)
  INNER JOIN  
   SC  
   ON   
    H.PK_Distributor = SC.PK_Distributor  
  INNER JOIN 
	pubEvents.dbo.dimDSLifeCycle L WITH (NOLOCK)
   ON
	L.PK_LifeCycle = H.PK_LifeCycle
  WHERE  
   L.LifeCycleName = 'Qual Senior Consultant'   --changed 
  GROUP BY  
   H.PK_Distributor  
 )  
 ,SCQualDSID (PK_Distributor,DistributorID, SCQualDate) AS  
 (  
  SELECT  
   D.PK_Distributor
   ,D.DistributorID  
   ,SCQual.Qual_SC  
  FROM  
   SCQual WITH (NOLOCK)
  INNER JOIN  
   pubEvents.dbo.dimDistributor D WITH (NOLOCK)  
   ON   
    D.PK_Distributor = SCQual.PK_Distributor  
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
 ,D.PK_Distributor  
 ,CONVERT(varchar,D2.SCQualDate)  
 ,D.PK_COP  
 ,CASE WHEN D.StatusCode = 'COMPLETE' THEN 0 ELSE 1 END  
 ,CASE WHEN T.nDistributorID IS NULL THEN 0 ELSE 1 END  
 ,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END  
FROM  
 pubEvents.dbo.dimDistributor D WITH (NOLOCK)
INNER JOIN  
 SCQualDSID D2 WITH (NOLOCK)
 ON  
  D.PK_Distributor = D2.PK_Distributor  
LEFT JOIN  
 (SELECT nDistributorID FROM dbo.v_IsType23Distributor) T  
 ON D.PK_Distributor = T.nDistributorID  
LEFT JOIN  
 dbo.v_DistributorDoNotRecognize R  
 ON  
  D.PK_Distributor = R.PK_Distributor  
  
 CREATE INDEX IX_#distqual_PK_Distributor ON #distqual(PK_Distributor)
/******************************************************************************
	Merge distributors from qualfication in production table
******************************************************************************/
; WITH Teams(PK_Qualification,PK_Distributor,RoyaltyMonth,PK_Country,IsDeleted,IsType23,IsDNR) AS
(SELECT PK_Qualification,PK_Distributor,RoyaltyMonth,PK_Country,IsDeleted,IsType23,IsDNR 
 FROM dbo.QualificationDistributor WITH (NOLOCK) WHERE PK_Qualification = @QualID)
 MERGE Teams SC
 USING #distqual DQ
 ON SC.PK_Distributor = DQ.PK_Distributor
 WHEN MATCHED AND (SC.IsDeleted <> DQ.IsDeleted OR SC.IsType23 <> DQ.IsType23 OR SC.IsDNR <> DQ.IsDNR) THEN
 UPDATE
	SET
		SC.RoyaltyMonth = DQ.RoyaltyMonth
		,SC.PK_Country = DQ.PK_Country
		,SC.IsDeleted = DQ.IsDeleted
		,SC.IsType23 = DQ.IsType23
		,SC.IsDNR = DQ.IsDNR
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
 end procedure  
******************************************************************************/  
EXEC usp_Utility_UpdateProcessingLog  
 @StoredProcedureName = @ProcName  
 ,@StoredProcedureParameters = @ProcParam  
 ,@StartTime = @StartTime  
  
END
GO

