CREATE PROCEDURE [dbo].[usp_AWT_upd_DSInfo]  
 @AWTYear int, 

       @IsDevQA			BIT = 0,   
	   @Error			int = 0 OUTPUT,
	   @ErrorMessage	varchar(4000) = NULL OUTPUT
AS  
BEGIN  
  
/******************************************************************************  
OBJECT:   dbo.usp_AWT_upd_DSInfo  
  
USE:   	DECLARE @e int, @em varchar(max)
			
			EXEC dbo.usp_AWT_upd_DSInfo 
				
				@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1
				,@AWTYear = 2010

			SELECT @e AS [Error], @em AS [Error Message]

  
DESCRIPTION: updates the PastAWT column  
  
DEPENDENCIES  
--------------------------------------------------------------------  
everything  
  
VERSIONS  
--------------------------------------------------------------------  
1 2010-01-05 Scott Initial  
2   2013-08-22  Emi				Populate First Upline TAB  
3   2016-11-11  SandhyaP		Netizza reference changes  
4	2019-10-14	JonathanO		Refactor code (SRE)
5	2021-06-11	alejandramed	Removing v_SupervisorLineage,  PubEvents.dbo.dimSPLngUpline invalid object, using v_DistributorLineage  instead
******************************************************************************/  
  
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON  

DECLARE @StoredProcedure varchar(255)	= 'usp_AWT_upd_DSInfo'  
	   ,@StartTime datetime2			= GETUTCDATE();

BEGIN TRY
/******************************************************************************  
 update distributor info  
******************************************************************************/  
UPDATE  
 A  
SET  
 DistributorID = LTRIM(RTRIM(D.sDistributorID))  
 ,FirstName = D.sFirstName  
 ,LastName = D.sLastName  
 ,COP = D.sDistributorCountryProcessingCode  
 ,Team = LEFT(D.sTeam,1)  
 ,PK_Sponsor = D.nSponsorID  
 ,SponsorID = D.sSponsorID  
 ,DeletedDate = D.dDeleted  
 ,isDeleted = CASE WHEN D.dDeleted = '2049-12-31' THEN 0 ELSE 1 END  
 ,PK_MainDistributor = D.nDistributorID  
 ,MainDistributorID = LTRIM(RTRIM(D.sDistributorID))  
 ,MainFirstName = D.sFirstName  
 ,MainLastName = D.sLastName  
 ,Qual_SP = D.dSupervisorQualification  
FROM  
 dbo.AWT A 
INNER JOIN  
 dbo.v_Distributor D
 ON  
  A.PK_Distributor = D.nDistributorID  
WHERE  
 A.AWTYear = @AWTYear  
   
-- update DS and spouse local info  
UPDATE  
 A  
SET  
 FirstNameLocal = D.FirstNameLocal   
 ,LastNameLocal = D.LastNameLocal  
 ,SpouseFirstName = D.SpouseFirstName  
 ,SpouseLastName = D.SpouseLastName   
 ,SpouseFirstNameLocal = D.SpouseFirstNameLocal   
 ,SpouseLastNameLocal = D.SpouseLastNameLocal  
 ,LPFirstName = D.LP_First_Name  
 ,LPLastName = D.LP_Last_Name   
 ,LPFirstNameLocal = D.LP_First_Local_Name   
 ,LPLastNameLocal = D.LP_Last_Local_Name     
FROM  
 dbo.AWT A 
INNER JOIN  
 pubEvents.dbo.dimDistributor D WITH (NOLOCK)
 ON  
  A.PK_Distributor = D.PK_Distributor  
WHERE  
 A.AWTYear = @AWTYear  
   
-- update sponsor local info  
UPDATE  
 A  
SET  
 SponsorFirstName = D.FirstName  
 ,SponsorLastName = D.LastName  
 ,SponsorFirstNameLocal = D.FirstNameLocal   
 ,SponsorLastNameLocal = D.LastNameLocal   
FROM  
 dbo.AWT A 
INNER JOIN  
 pubEvents.dbo.dimDistributor D WITH (NOLOCK)
 ON  
  A.PK_Sponsor = D.PK_Distributor  
WHERE  
 A.AWTYear = @AWTYear  
  
/******************************************************************************  
 update MAIN info  
******************************************************************************/  
UPDATE  
 A  
SET  
 PK_MainDistributor = M.nDistributorID  
 ,MainDistributorID = LTRIM(RTRIM(M.sDistributorID))  
 ,MainFirstName = M.sFirstName  
 ,MainLastName = M.sLastName  
 ,IsType23 = CASE WHEN DA.sType IN ('2','3') THEN 1 ELSE 0 END  
FROM  
 dbo.AWT A 
INNER JOIN  
 dbo.v_DistributorAssociate2 DA
 ON  
  A.PK_Distributor = DA.nDistributorID  
INNER JOIN  
 dbo.v_Distributor M
 ON  
  DA.nMainDistributorID = M.nDistributorID  
WHERE  
 A.AWTYear = @AWTYear  
   
-- update main local info  
UPDATE  
 A  
SET  
 MainFirstNameLocal = D.FirstNameLocal   
 ,MainLastNameLocal = D.LastNameLocal   
FROM  
 dbo.AWT A 
INNER JOIN  
 pubEvents.dbo.dimDistributor D WITH (NOLOCK)
 ON  
  A.PK_MainDistributor = D.PK_Distributor  
WHERE  
 A.AWTYear = @AWTYear  
  
/******************************************************************************  
 update qual dates  
******************************************************************************/  
;WITH History (    
 PK_Distributor  
 ,Qual_W  
 ,Qual_G   
) AS (  
 SELECT  
  nDistributorIDFK --'PK_Distributor'  
  ,[224] --'Qual_W'  
  ,[225] --'Qual_G'  
 FROM  
 (  
  SELECT  
   H.nDistributorIDFK  
   ,H.sDistributorID  
   ,H.nEventTypeLID  
   ,H.dFrom  
  FROM  
   dbo.v_DistributorHistory H
  INNER JOIN  
   dbo.AWT A WITH (NOLOCK)
   ON  
    H.nDistributorIDFK = A.PK_Distributor  
    AND A.AWTYear = @AWTYear  
  WHERE  
   H.nEventTypeLID BETWEEN 224 AND 225  
   AND H.dThrough = '2049-12-31'  
 )P1 PIVOT (  
  MIN(dFrom)  
  FOR nEventTypeLID   
   IN ([224],[225])  
 )P2  
)  
UPDATE  
 A  
SET  
 Qual_W = H.Qual_W  
 ,Qual_G = H.Qual_G  
FROM  
 dbo.AWT A 
INNER JOIN  
 History H  
 ON  
  A.PK_Distributor = H.PK_Distributor  
WHERE  
 A.AWTYear = @AWTYear  
  
/******************************************************************************  
 update mailing address info for distributor  
******************************************************************************/  
--UPDATE  
-- A  
--SET   
-- Address1 = CASE WHEN M.sAddress1 = 'Unknown' THEN NULL ELSE M.sAddress1 END  
-- ,Address2 = CASE WHEN M.sAddress2 = 'Unknown' THEN NULL ELSE M.sAddress2 END  
-- ,Address3 = CASE WHEN M.sAddress3 = 'Unknown' THEN NULL ELSE M.sAddress3 END  
-- ,Address4 = CASE WHEN M.sAddress4 = 'Unknown' THEN NULL ELSE M.sAddress4 END  
-- ,City = CASE WHEN M.sCity = 'Unknown' THEN NULL ELSE M.sCity END  
-- ,County = CASE WHEN M.sCounty = 'Unknown' THEN NULL ELSE M.sCounty END  
-- ,State = CASE WHEN M.sState = 'Unknown' THEN NULL ELSE M.sState END  
-- ,PostalCode = CASE WHEN M.sPostalCode = 'Unknown' THEN NULL ELSE M.sPostalCode END  
-- ,CountryCode = CASE WHEN M.sCountry = 'Unknown' THEN NULL ELSE M.sCountry END  
--FROM   
-- dbo.v_MailingAddress M  
--INNER JOIN  
-- dbo.AWT A  
-- ON  
--  M.nDistributorID = A.PK_Distributor  
--  AND A.AWTYear = @AWTYear  
  
UPDATE  
 A  
SET   
 Address1 = CASE WHEN M.Address01 = 'Unknown' THEN NULL ELSE M.Address01 END  
 ,Address2 = CASE WHEN M.Address02 = 'Unknown' THEN NULL ELSE M.Address02 END  
 ,Address3 = CASE WHEN M.Address03 = 'Unknown' THEN NULL ELSE M.Address03 END  
 ,Address4 = CASE WHEN M.Address04 = 'Unknown' THEN NULL ELSE M.Address04 END  
 ,City = CASE WHEN M.City = 'Unknown' THEN NULL ELSE M.City END  
 ,County = CASE WHEN M.County = 'Unknown' THEN NULL ELSE M.County END  
 ,State = CASE WHEN M.State = 'Unknown' THEN NULL ELSE M.State END  
 ,PostalCode = CASE WHEN M.PostalCode = 'Unknown' THEN NULL ELSE M.PostalCode END  
 ,CountryCode = CASE WHEN M.CountryCode = 'Unknown' THEN NULL ELSE M.CountryCode END  
 ,Address1Local = CASE WHEN M.Address01Local = 'Unknown' THEN NULL ELSE M.Address01Local END  
 ,Address2Local = CASE WHEN M.Address02Local = 'Unknown' THEN NULL ELSE M.Address02Local  END  
 ,Address3Local = CASE WHEN M.Address03Local = 'Unknown' THEN NULL ELSE M.Address03Local END  
 ,Address4Local = CASE WHEN M.Address04Local = 'Unknown' THEN NULL ELSE M.Address04Local END  
 ,CityLocal = CASE WHEN M.CityLocal = 'Unknown' THEN NULL ELSE M.CityLocal END  
 ,CountyLocal = CASE WHEN M.CountyLocal = 'Unknown' THEN NULL ELSE M.CountyLocal END  
 ,StateLocal = CASE WHEN M.StateLocal = 'Unknown' THEN NULL ELSE M.StateLocal END  
 ,PostalCodeLocal = CASE WHEN M.PostalCodeLocal = 'Unknown' THEN NULL ELSE M.PostalCodeLocal END  
FROM   
 pubEvents.dbo.dimDSContactInfo M WITH (NOLOCK)
INNER JOIN  
 dbo.AWT A
 ON  
  M.PK_Distributor = A.PK_Distributor  
  AND A.AWTYear = @AWTYear  
  AND M.PK_Country NOT IN (1,2)
  
/******************************************************************************  
 update mailing address info for main  
******************************************************************************/  
UPDATE  
 A  
SET   
 MainAddress1 = CASE WHEN M.Address01 = 'Unknown' THEN NULL ELSE M.Address01 END  
 ,MainAddress2 = CASE WHEN M.Address02 = 'Unknown' THEN NULL ELSE M.Address02 END  
 ,MainAddress3 = CASE WHEN M.Address03 = 'Unknown' THEN NULL ELSE M.Address03 END  
 ,MainAddress4 = CASE WHEN M.Address04 = 'Unknown' THEN NULL ELSE M.Address04 END  
 ,MainCity = CASE WHEN M.City = 'Unknown' THEN NULL ELSE M.City END  
 ,MainCounty = CASE WHEN M.County = 'Unknown' THEN NULL ELSE M.County END  
 ,MainState = CASE WHEN M.State = 'Unknown' THEN NULL ELSE M.State END  
 ,MainPostalCode = CASE WHEN M.PostalCode = 'Unknown' THEN NULL ELSE M.PostalCode END  
 ,MainCountryCode = CASE WHEN M.CountryCode = 'Unknown' THEN NULL ELSE M.CountryCode END  
 ,MainAddress1Local = CASE WHEN M.Address01Local = 'Unknown' THEN NULL ELSE M.Address01Local END  
 ,MainAddress2Local = CASE WHEN M.Address02Local = 'Unknown' THEN NULL ELSE M.Address02Local  END  
 ,MainAddress3Local = CASE WHEN M.Address03Local = 'Unknown' THEN NULL ELSE M.Address03Local END  
 ,MainAddress4Local = CASE WHEN M.Address04Local = 'Unknown' THEN NULL ELSE M.Address04Local END  
 ,MainCityLocal = CASE WHEN M.CityLocal = 'Unknown' THEN NULL ELSE M.CityLocal END  
 ,MainCountyLocal = CASE WHEN M.CountyLocal = 'Unknown' THEN NULL ELSE M.CountyLocal END  
 ,MainStateLocal = CASE WHEN M.StateLocal = 'Unknown' THEN NULL ELSE M.StateLocal END  
 ,MainPostalCodeLocal = CASE WHEN M.PostalCodeLocal = 'Unknown' THEN NULL ELSE M.PostalCodeLocal END  
FROM   
 pubEvents.dbo.dimDSContactInfo M WITH (NOLOCK)
INNER JOIN  
 dbo.AWT A
 ON  
  M.PK_Distributor = A.PK_MainDistributor  
  AND A.AWTYear = @AWTYear  
  AND M.PK_Country NOT IN (1,2)
  
/******************************************************************************  
 update country of processing region  
******************************************************************************/   
UPDATE  
 A  
SET  
 COPRegion = C.sRegionLabel  
FROM  
 dbo.AWT A
INNER JOIN  
 dbo.v_Countries C
 ON  
  A.COP = C.sCountryCode  
WHERE  
 A.AWTYear = @AWTYear  
  
/******************************************************************************  
 update email  
******************************************************************************/  
UPDATE  
 A  
SET   
 Email = E.sString  
FROM   
 dbo.v_DistributorEmail E
INNER JOIN  
 dbo.AWT A
 ON  
  E.nDistributorIDFK = A.PK_Distributor  
  AND A.AWTYear = @AWTYear  
  
/******************************************************************************  
 update phone  
******************************************************************************/  
UPDATE  
 A  
SET   
 Phone = P.sString  
FROM   
 dbo.v_DistributorPrimaryPhone P
INNER JOIN  
 dbo.AWT A
 ON  
  P.nDistributorIDFK = A.PK_Distributor  
  AND A.AWTYear = @AWTYear  
   
/******************************************************************************  
 update lineage pks  
******************************************************************************/  
UPDATE  
 A  
SET   
 PK_UplinePres1 = L.n1stPresidentID  
 ,PK_UplineSP1 = L.n1stSupervisorID
 ,PK_UplineSP2 = SP1.FIRSTUPLINESP  
 ,PK_UplineSP3 = SP2.FIRSTUPLINESP  
 ,PK_UplineTAB1 = L.nIstTABID  
FROM   
 dbo.v_DistributorLineage L
INNER JOIN  
 dbo.AWT A
 ON  
  L.nDistributorID = A.PK_Distributor  
  AND A.AWTYear = @AWTYear 
INNER JOIN
	PubEvents.dbo.dimDSLngUpline SP1 (NOLOCK)
ON
	SP1.PK_DISTRIBUTOR = L.n1stSupervisorID
INNER JOIN
	PubEvents.dbo.dimDSLngUpline SP2 (NOLOCK)
ON
	SP2.PK_DISTRIBUTOR = SP1.FirstUplineSP
INNER JOIN
	PubEvents.dbo.dimDistributor DS (NOLOCK)
ON
	DS.PK_Distributor = L.nDistributorID
WHERE
	DS.TypeCode = 'SP'
  
-- SECOND UPLINE PRES  
UPDATE  
 A  
SET   
 PK_UplinePres2 = L.n1stPresidentID  
FROM   
 dbo.v_DistributorLineage L
INNER JOIN  
 dbo.AWT A
 ON  
  L.nDistributorID = A.PK_UplinePres1  
  AND A.AWTYear = @AWTYear  
  
-- THIRD UPLINE PRES  
UPDATE  
 A  
SET   
 PK_UplinePres3 = L.n1stPresidentID  
FROM   
 dbo.v_DistributorLineage L
INNER JOIN  
 dbo.AWT A
 ON  
  L.nDistributorID = A.PK_UplinePres2  
  AND A.AWTYear = @AWTYear  
  
/******************************************************************************  
 update lineage id INFO  
******************************************************************************/  
UPDATE  
 A  
SET   
 UplinePresID1 = D.sDistributorID  
 ,UplinePres1FirstName = D.sFirstName  
 ,UplinePres1LastName = D.sLastName  
FROM   
 dbo.v_Distributor D
INNER JOIN  
 dbo.AWT A
 ON  
  D.nDistributorID = A.PK_UplinePres1  
  AND A.AWTYear = @AWTYear  
  
UPDATE  
 A  
SET   
 UplinePresID2 = D.sDistributorID  
FROM   
 dbo.v_Distributor D
INNER JOIN  
 dbo.AWT A
 ON  
  D.nDistributorID = A.PK_UplinePres2  
  AND A.AWTYear = @AWTYear  
  
UPDATE  
 A  
SET   
 UplinePresID3 = D.sDistributorID  
FROM   
 dbo.v_Distributor D
INNER JOIN  
 dbo.AWT A
 ON  
  D.nDistributorID = A.PK_UplinePres3  
  AND A.AWTYear = @AWTYear  
  
UPDATE  
 A  
SET   
 UplineSPID1 = D.sDistributorID  
FROM   
 dbo.v_Distributor D
INNER JOIN  
 dbo.AWT A
 ON  
  D.nDistributorID = A.PK_UplineSP1  
  AND A.AWTYear = @AWTYear  
  
UPDATE  
 A  
SET   
 UplineSPID2 = D.sDistributorID  
FROM   
 dbo.v_Distributor D
INNER JOIN  
 dbo.AWT A
 ON  
  D.nDistributorID = A.PK_UplineSP2  
  AND A.AWTYear = @AWTYear  
  
UPDATE  
 A  
SET   
 UplineSPID3 = D.sDistributorID  
FROM   
 dbo.v_Distributor D
INNER JOIN  
 dbo.AWT A
 ON  
  D.nDistributorID = A.PK_UplineSP3  
  AND A.AWTYear = @AWTYear  
    
UPDATE  
 A  
SET   
 UplineTABID1 = D.sDistributorID  
FROM   
 dbo.v_Distributor D
INNER JOIN  
 dbo.AWT A
 ON  
  D.nDistributorID = A.PK_UplineTAB1  
  AND A.AWTYear = @AWTYear  
  
/******************************************************************************  
 mark DNR records  
******************************************************************************/  
UPDATE  
 A  
SET  
 IsDNR = 1  
FROM  
 dbo.AWT A
INNER JOIN  
 dbo.v_DistributorDoNotRecognize D
 ON  
  A.PK_Distributor = D.PK_Distributor  
WHERE  
 A.AWTYear = @AWTYear  

		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
				@StoredProcedureName = @StoredProcedure
				,@StartTime = @StartTime;

END TRY
	BEGIN CATCH
		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()

		IF @IsDevQA = 1 SELECT @Error AS [Error], @ErrorMessage AS [Error Message];

		-- UPDATE ERROR LOG
		EXEC dbo.usp_Utility_UpdateErrorLog 
				@ProcedureName = @StoredProcedure
				,@ErrorNumber = 3
				,@ErrorMessage = @ErrorMessage
				,@SQLErrorCode = @Error
				,@SQLErrorMsg = @ErrorMessage
		RETURN 
	END CATCH;

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END;