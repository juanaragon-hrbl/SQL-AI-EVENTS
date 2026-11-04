CREATE PROCEDURE [dbo].[uspEvent_UpdateEventSKU]  
AS  
BEGIN  
/******************************************************************************  
OBJECT:  dbo.uspEvent_UpdateEventSKU
  
USE:  EXEC dbo.uspEvent_UpdateEventSKU 
  
DESCRIPTION:  SKU job populates SKUPurchased_Extract 
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
VERSIONS  
--------------------------------------------------------------------    
1   2016-11-11   SandhyaP       Netizza reference changes 
2   2019-09-05   OrlandoL       Add missing NOLOCKs
3   2020-01-10	 IniU	        Changed logic to improve performance
4   2025-06-25   alejandramed   Including AllowedCOP on EventSKU table: Filtering if the tickets are applicable for the DS COP.
******************************************************************************/  
  
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON  
  
/******************************************************************************  
 VARIABLE DECLARATION  
******************************************************************************/  
  
DECLARE  
  @Timestamp datetime  
 ,@ScheduleID int  
  
SET @Timestamp = GETUTCDATE()  
  
/******************************************************************************  
 GET THE SCHEDULE ID FOR THE SKU UPDATES  
******************************************************************************/  
SELECT  
 @ScheduleID = PK_Schedule  
FROM  
 dbo.Schedule  WITH (NOLOCK)
WHERE  
 ScheduleName = 'Update SKU Purchase'  
  
/******************************************************************************  
 GET THE SKUs FOR ALL ACTIVE EVENTS  
******************************************************************************/  
IF OBJECT_ID('tempdb..#EventSKU') IS NOT NULL DROP TABLE #EventSKU  
  
CREATE TABLE  
 #EventSKU  
(  
 PK_Event int  
 ,PK_EventSKU int  
 ,SKUCode char(4)  
 ,SKUValidBeginUTC smalldatetime  
 ,SKUValidEndUTC smalldatetime  
 ,[AllowedCOP] VARCHAR(MAX)
)  
  
INSERT  
 #EventSKU  
(  
 PK_Event  
 ,PK_EventSKU  
 ,SKUCode  
 ,SKUValidBeginUTC  
 ,SKUValidEndUTC 
,[AllowedCOP]
)  
SELECT  
 S.PK_Event  
 ,S.PK_EventSKU  
 ,S.SKUCode  
 ,S.SKUValidBeginUTC  
 ,S.SKUValidEndUTC  
 ,S.[AllowedCOP]
FROM  
  dbo.EventSKU S  WITH (NOLOCK)
INNER JOIN  
  dbo.EventSchedule ES  WITH (NOLOCK)
 ON  
  S.PK_Event = ES.PK_Event  
  AND  
  ES.PK_Schedule = 6  
  AND   
  @Timestamp BETWEEN ES.BeginUTC AND ES.EndUTC  
  
CREATE INDEX IX_tmpEventSKU_PK_Event ON #EventSKU (PK_Event)  
CREATE INDEX IX_tmpEventSKU_PK_EventSKU ON #EventSKU (PK_EventSKU)  
CREATE INDEX IX_tmpEventSKU_SKUCode ON #EventSKU (SKUCode)  
CREATE INDEX IX_tmpEventSKU_SKUValidBeginUTC ON #EventSKU (SKUValidBeginUTC)  
CREATE INDEX IX_tmpEventSKU_SKUValidEndUTC ON #EventSKU (SKUValidEndUTC)  
  
/******************************************************************************  
 GET THE SKU PURCHASED INFORMATION FOR THE APPLICABLE DISTRIBUTORS  
******************************************************************************/  
IF OBJECT_ID('tempdb..#SKUPurchased') IS NOT NULL   
 DROP TABLE #SKUPurchased  

IF OBJECT_ID('tempdb..#OrderLineSKUs') IS NOT NULL   
 DROP TABLE #OrderLineSKUs 
  
CREATE TABLE #SKUPurchased (  
 PK_Event int  
 ,PK_EventSKU int  
 ,PK_Distributor_Purchaser int  
 ,DistributorID varchar(10)  
 ,CountryCode_COP varchar(10)  
 ,OrderDate datetime  
 ,OrderNumber varchar(10)  
 ,OrderType varchar(2)  
 ,SKUCode char(4)  
 ,NTSDate smalldatetime  
 ,Quantity int 
 ,IsValidTicket bit default(1)  
)  

SELECT S.PK_Event, S.PK_EventSKU, S.SKUCode, S.SKUValidBeginUTC, S.SKUValidEndUTC, OL.PK_Order, OL.QtyOrdered
INTO #OrderLineSKUs
From #EventSKU S  
INNER JOIN  
 pubEvents.dbo.dimSellingSKU SS WITH (NOLOCK) 
 ON  
 S.SKUCode = SS.SKUCode  
INNER JOIN  
 pubEvents.dbo.factOrderLine OL WITH (NOLOCK) 
 ON 
 SS.PK_SellingSKU = OL.PK_SellingSKU

CREATE INDEX IX_PK_Order ON #OrderLineSKUs(PK_Order)
  
INSERT  
 #SKUPurchased  
(  
 PK_Event  
 ,PK_EventSKU  
 ,DistributorID  
 ,CountryCode_COP
 ,OrderDate  
 ,OrderNumber  
 ,OrderType  
 ,SKUCode  
 ,NTSDate  
 ,Quantity  
)  
SELECT  
  S.PK_Event  
 ,S.PK_EventSKU  
 ,D.DistributorID  
 ,D.CountryCode_COP
 ,CONVERT(DATE,CAST(OrderDate AS VARCHAR))  
 ,O.ORDERNUMBER  
 ,CASE SC.ChannelCode WHEN 'Direct' THEN 'DI'   
                          WHEN 'INDIRECT' THEN 'ID'  
                          WHEN 'AUTOMATIC' THEN 'AO'  
                          WHEN 'EMAIL' THEN 'EM'  
                          WHEN 'EMAIL_CENTER' THEN 'EC'  
                          WHEN 'EVENT_TKT_ONLINE' THEN 'EO'  
                          WHEN 'FAX' THEN 'FI'   
                          WHEN 'INTERNET' THEN 'IE'  
                          WHEN 'MAILIN' THEN 'MI'  
                          WHEN 'PHONE' THEN 'PI'  
                          WHEN 'SYSTEM' THEN 'SY'  
                          WHEN 'WALKIN' THEN 'WI'  
                          END OrderType  
                            
 ,S.SKUCode  
 ,CONVERT(DATE,CAST(O.NTSDate AS VARCHAR))  
 ,SUM(S.QtyOrdered)  
FROM  
 #OrderLineSKUs S  
INNER JOIN  
 pubEvents.dbo.FactOrder O WITH (NOLOCK) 
 ON  
  S.PK_Order = O.PK_Order
  AND CONVERT(DATE,CAST(OrderDate AS VARCHAR)) BETWEEN S.SKUValidBeginUTC AND S.SKUValidEndUTC  
  AND S.QtyOrdered > 0
INNER JOIN
pubEvents.dbo.dimDistributor D WITH (NOLOCK)
ON
O.PK_Distributor = D.PK_Distributor
AND
O.ISLATESTORDER = 1
INNER JOIN  
 pubEvents.dbo.dimOrderStatus OS WITH (NOLOCK) 
 ON  
 O.PK_OrderStatus = OS.PK_OrderStatus   
 AND  
 OS.StatusCode IN ('03', '-2') 
INNER JOIN  
 pubEvents.dbo.dimOrderSalesChannel SC WITH (NOLOCK) 
    ON  
    O.PK_SalesChannel = SC.PK_SalesChannel  
WHERE NTSDATE <> '1900101'
GROUP BY  
  S.PK_Event  
 ,S.PK_EventSKU  
 ,D.DistributorID 
 ,D.CountryCode_COP 
 ,CONVERT(DATE,CAST(OrderDate AS VARCHAR))  
 ,O.ORDERNUMBER  
 ,CASE SC.ChannelCode WHEN 'Direct' THEN 'DI'   
                          WHEN 'INDIRECT' THEN 'ID'  
                          WHEN 'AUTOMATIC' THEN 'AO'  
                          WHEN 'EMAIL' THEN 'EM'  
                          WHEN 'EMAIL_CENTER' THEN 'EC'  
                          WHEN 'EVENT_TKT_ONLINE' THEN 'EO'  
                          WHEN 'FAX' THEN 'FI'   
                          WHEN 'INTERNET' THEN 'IE'  
                          WHEN 'MAILIN' THEN 'MI'  
                          WHEN 'PHONE' THEN 'PI'  
                          WHEN 'SYSTEM' THEN 'SY'  
                          WHEN 'WALKIN' THEN 'WI'  
                          END   
 ,S.SKUCode  
 ,CONVERT(DATE,CAST(O.NTSDate AS VARCHAR))  
  
CREATE INDEX IX_tmpSKUPurchased_DistributorID ON #SKUPurchased (DistributorID)  
  
  
/******************************************************************************  
 UPDATE THE PK_Distributor_Purchaser VALUE FROM THE MAIN DISTRIBUTOR TABLE  
******************************************************************************/  
UPDATE  
 S  
SET  
 PK_Distributor_Purchaser = D.nDistributorID  
FROM  
 #SKUPurchased S  
INNER JOIN  
 dbo.v_Distributor D  
 ON  
  S.DistributorID = D.sDistributorID  
    
/******************************************************************************  
 UPDATE THE SKU Purchaser in case of transfers  
******************************************************************************/  
UPDATE  
 S  
SET  
 DistributorID = DA.sMainDistributorID  
 ,PK_Distributor_Purchaser = DA.nMainDistributorID  
FROM  
 #SKUPurchased S  
INNER JOIN  
 dbo.v_DistributorAssociate2 DA  
ON  
 S.DistributorID = DA.sDistributorID   
 AND  
 DA.Transfer = 1  
 AND  
 DA.dThrough = '2049-12-31'  
INNER JOIN  
 dbo.v_Distributor D  
ON  
 DA.nMainDistributorID = D.nDistributorID  
 AND  
 D.StatusCode = 'COMPLETE'  
WHERE  
 NOT EXISTS (SELECT 1 FROM dbo.EventsRegistration ER WITH (NOLOCK) 
    WHERE S.PK_Event = ER.PK_Event AND S.DistributorID = ER.DistributorID AND ER.HasCheckedIn = 1)  
 
--// Evaluate if the tickets are applicable for the DS COP.
 
DROP TABLE IF EXISTS #EventSKUAllowedCOP

SELECT 
	PK_Event,PK_EventSKU,SKUCode,SKUValidBeginUTC,SKUValidEndUTC,[value] AS [COP]
INTO #EventSKUAllowedCOP
FROM #EventSKU AS s
	CROSS APPLY string_split(s.[AllowedCOP],',') AS c
 
 UPDATE s
	SET IsValidTicket = 0 
 FROM #SKUPurchased AS s
	INNER JOIN #EventSKUAllowedCOP AS c 
		ON c.PK_Event = s.PK_Event AND c.PK_EventSKU = s.PK_EventSKU 
		AND s.CountryCode_COP NOT IN (SELECT COP FROM #EventSKUAllowedCOP WHERE c.PK_Event = s.PK_Event AND c.PK_EventSKU = s.PK_EventSKU)

/******************************************************************************  
INSERT SKU INFORMATION IN TO THE SKUPURCHASED EXTRACT TABLE  
******************************************************************************/  

/* ***************** SonarQube check 118 - "DELETE" statements should contain "WHERE" clauses */
----DELETE FROM dbo.SKUPurchased_Extract  
TRUNCATE TABLE dbo.SKUPurchased_Extract  
/* ***************** SonarQube check 118 */
  
INSERT  
 dbo.SKUPurchased_Extract  
(  
  PK_Event  
 ,PK_EventSKU  
 ,PK_Distributor_Purchaser  
 ,DistributorID  
 ,OrderDate  
 ,OrderNumber  
 ,OrderType  
 ,NTSDate  
 ,Quantity  
)  
SELECT  
  PK_Event  
 ,PK_EventSKU  
 ,PK_Distributor_Purchaser  
 ,DistributorID  
 ,OrderDate  
 ,OrderNumber  
 ,OrderType  
 ,NTSDate  
 ,Quantity  
FROM  
 #SKUPurchased P  
  WHERE IsValidTicket = 1
/******************************************************************************  
 END PROCEDURE  
******************************************************************************/  
END

