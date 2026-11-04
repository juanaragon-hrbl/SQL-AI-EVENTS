CREATE PROCEDURE [dbo].[usp_QualStd_DSTypeQualifiedProducers]  
----WITH EXECUTE AS 'dbo'  
/******************************************************************************  
OBJECT:  dbo.usp_QualStd_DSTypeQualifiedProducers
  
USE:  EXEC dbo.usp_QualStd_DSTypeQualifiedProducers
  
DESCRIPTION:  Get QP records
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
VERSIONS  
--------------------------------------------------------------------  

2   2016-11-11   SandhyaP  Netizza reference changes  
******************************************************************************/  
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
  
SET @ProcName = 'usp_QualStd_DSTypeQualifiedProducers'  
SET @ProcParam = ''  
SET @StartTime = GETUTCDATE()  
SELECT @QualID = PK_Qualification FROM dbo.Qualification WITH (NOLOCK) WHERE QualificationAbbreviation = 'QP'  
  
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
 QP (PK_Distributor) AS  
 (  
  SELECT  
   nDistributorID  
  FROM  
   dbo.v_Distributor   
  WHERE   
   sSubTeam = 'QP'   --changed
 )  
 ,QPQual (PK_Distributor, Qual_QP) AS  
 (  
  SELECT  
   H.PK_Distributor  
   ,MAX(FromDate)  
  FROM  
   pubEvents.dbo.dimDSHistory H WITH (NOLOCK)
  INNER JOIN  
   QP  
   ON   
    H.PK_Distributor = QP.PK_Distributor  
  INNER JOIN 
	pubEvents.dbo.dimDSLifeCycle L WITH (NOLOCK)
   ON
	L.PK_LifeCycle = H.PK_LifeCycle
  WHERE  
   L.LifeCycleName = 'Qualified Producer'   --changed
  GROUP BY  
   H.PK_Distributor  
 )  
 ,QPQualDSID (DistributorID, QPQualDate) AS  
 (  
  SELECT  
   D.DistributorID  
   ,QPQual.Qual_QP  
  FROM  
   QPQual  
  INNER JOIN  
   pubEvents.dbo.dimDistributor D WITH (NOLOCK)
   ON   
    D.PK_Distributor = QPQual.PK_Distributor  
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
 ,CONVERT(varchar,D2.QPQualDate)  
 ,C.nCountryID  
 ,CASE WHEN D.dDeleted = '2049-12-31' THEN 0 ELSE 1 END  
 ,CASE WHEN T.nDistributorID IS NULL THEN 0 ELSE 1 END  
 ,CASE WHEN R.PK_Distributor IS NULL THEN 0 ELSE 1 END  
FROM  
 dbo.v_Distributor D  
INNER JOIN  
 QPQualDSID D2
 ON  
  D.sDistributorID = D2.DistributorID  
INNER JOIN  
 dbo.v_Countries C  
 ON  
  D.sDistributorCountryProcessingCode = C.sCountryCode  
LEFT JOIN  
 (SELECT nDistributorID FROM dbo.v_IsType23Distributor) T  
 ON D.nDistributorID = T.nDistributorID  
LEFT JOIN  
 dbo.v_DistributorDoNotRecognize R  
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