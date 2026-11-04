CREATE VIEW [dbo].[v_AWT]
AS

WITH cte_cyAWTAssoc AS
(
	SELECT
		PK_AWT,
		ROW_NUMBER() OVER (PARTITION BY sMainDistributorId ORDER BY DateAdded) AS Rnk
	from (
			SELECT DISTINCT
				A.PK_AWT, 
				A.DateAdded,
				DT.sMainDistributorID
			FROM (
				SELECT MAX(AWTYear) AS AWTYear
				FROM dbo.AWT_Definitions (NOLOCK)
			) AY
			CROSS JOIN dbo.v_DistributorAssociate2 DT (NOLOCK)
			INNER JOIN dbo.AWT A (NOLOCK)
				ON A.AWTYear = AY.AWTYear
					AND A.PK_Distributor IN (DT.nDistributorID, DT.nMainDistributorID)
			WHERE DT.dThrough = '2049-12-31'
				AND DT.Transfer = 1
	) t
)

SELECT 
      AWT.PK_AWT
      ,CreatedDateUTC
      ,CreatedBy
      ,Flg1
      ,AWT.AWTYear
      ,AWT.PK_Distributor
      ,DistributorID
      ,FirstName
      ,LastName
      ,FirstNameLocal
      ,LastNameLocal
      ,Address1
      ,Address2
      ,Address3
      ,Address4
      ,City
      ,County
      ,PostalCode
      ,CountryCode
      ,State
      ,Address1Local
      ,Address2Local
      ,Address3Local
      ,Address4Local
      ,CityLocal
      ,CountyLocal
      ,PostalCodeLocal
      ,StateLocal
      ,SpouseFirstName
      ,SpouseLastName
      ,SpouseFirstNameLocal
      ,SpouseLastNameLocal
	  ,LPFirstName
      ,LPLastName
      ,LPFirstNameLocal
      ,LPLastNameLocal
      ,AWT.COP
      ,C.sCountryName AS CountryName
      ,COPRegion
      ,Email
      ,Phone
      ,Team
      ,PK_Sponsor
      ,SponsorID
      ,SponsorFirstName
      ,SponsorLastName
      ,SponsorFirstNameLocal
      ,SponsorLastNameLocal
      ,Qual_SP
      ,Qual_G
      ,Qual_W
      ,AWT.Qual_AWT
      ,CASE WHEN Q5.PK_Distributor IS NOT NULL THEN 'Y' ELSE 'N' END AS Used5Get5ToQualify
      ,CASE WHEN Q5.PK_Distributor IS NOT NULL THEN Q5.[5Get5Month] ELSE NULL END AS [5Get5Month]
      ,IsDeleted
      ,DeletedDate
      ,IsDNR
      ,DateAdded
      ,IsType23
      ,PastAWT
      ,isNonTAB
      ,CASE WHEN ISNULL(XFER.Rnk,0) = 2 THEN 0 ELSE earnPlaque END AS earnPlaque
      ,CASE WHEN ISNULL(XFER.Rnk,0) = 2 THEN 0 ELSE earn500Bonus END AS earn500Bonus
      ,PK_UplinePres1
      ,UplinePresID1
      ,UplinePres1FirstName
      ,UplinePres1LastName
      ,PK_UplinePres2
      ,UplinePresID2
      ,PK_UplinePres3
      ,UplinePresID3
      ,PK_UplineSP1
      ,UplineSPID1
      ,PK_UplineSP2
      ,UplineSPID2
      ,PK_UplineSP3
      ,UplineSPID3
      ,PK_UplineTAB1
      ,UplineTABID1
      ,PK_MainDistributor
      ,MainDistributorID
      ,MainFirstName
      ,MainLastName
      ,MainFirstNameLocal
      ,MainLastNameLocal
      ,MainAddress1 
      ,MainAddress2 
      ,MainAddress3 
      ,MainAddress4 
      ,MainCity 
      ,MainCounty 
      ,MainState 
      ,MainPostalCode 
      ,MainCountryCode 
      ,MainAddress1Local
      ,MainAddress2Local
      ,MainAddress3Local
      ,MainAddress4Local
      ,MainCityLocal
      ,MainCountyLocal
      ,MainStateLocal
      ,MainPostalCodeLocal
FROM 
      dbo.AWT AWT (NOLOCK)
LEFT JOIN 
        dbo.v_AWT_Qualifiers_Using_5Get5 Q5
ON
      AWT.AWTYear = Q5.AWTYear
      AND
      AWT.PK_Distributor = Q5.PK_Distributor
LEFT JOIN
      dbo.v_Countries C
ON
      AWT.COP = C.sCountryCode 
LEFT JOIN 
	cte_cyAWTAssoc XFER
ON
	AWT.PK_AWT = XFER.PK_AWT