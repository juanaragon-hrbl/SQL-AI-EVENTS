CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_DSEventsandPromotionsRegionAndEventType] 
		-- Mandatory Parameters
		@UserID VARCHAR(30) = NULL
		,@LocaleCode CHAR(5) = NULL
		,@EventTypeCode varchar(7) = 'NULL' --[DE, CE, CP, ALL, ALLCORP][optional][default distributor event]		

		-- Error Parameters
		,@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT
		
		-- QA/DEV
		,@IsDevQA bit = 0		
	            
AS
BEGIN

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_DSEventsandPromotionsRegionAndEventType

USE:	        
				DECLARE @e int, @em varchar(4000)
                EXEC dbo.usp_MyHLEventAPI_Get_DSEventsandPromotionsRegionAndEventType
                     -- Mandatory Parameters
                     @UserID = '11110190'
                     ,@LocaleCode = 'es-MX'
                     ,@EventTypeCode = 'DE'
					,@Error = @e OUTPUT
					,@ErrorMessage = @em OUTPUT
					,@IsDevQA = 0

				SELECT @e AS [Error], @em AS [Error Message]
                     
                     select * from dbo.EVENTATACCESSUSER
                 
DESCRIPTION:	Retrieves all region codes and eventtypes available

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event, dbo.EventLocaleDesc, dbo.EventSubTypes

VERSIONS
----------------------------------------------------------------------------------
1	2010-11-15	Prabhu			Intitial
1.1 2013-02-21  SandhyaP		Changes to this API
2	2013-07-03	SushmaA			Target Market CR Changes
3	2013-07-04  Juan			Bypass @userid for search 
4	2013-07-27  Juan			Add Filter for EventsTypeCode on Result
5	2018-08-06	RogelioR		Add [HasDSAccess] to third dataset
6	2019-08-14	NoeG			Refactor code (SRE)
7	2019-06-28	Noeg			Add Master Locales information
8	2020-04-27	Noeg			Changes added for features management
9	2020-06-10  Noeg			Add Virtual and WorldWide as Country options to select
10  2020-08-12	puertac			BUG 266825 PK_Country missing on table EventCountry, because of sCountryCode, it will now use sCountryCodeISO
11	2020-08-24	puertac			BUG 332151 Remove Invalid Locales (China & Virgin Islands)	
12  2020-09-28	puertac			US 33768 : Languages & Locales in the eventsadmin tool should be aligned with myHL (Locales cleanup)
								This fix overwrites BUG 332151, the exclusion is now made by a column EnabledOnMyHL in dbo.Locale table. 
13	2021-08-24	ivanci			US 93530 - Manage My Events - No access to Manage or Create Distributor Events 
14	2022-03-20	ivanci			Merge access by locale and ds access
******************************************************************************/


/******************************************************************************
	VARIABLE DECLARATION
******************************************************************************/
DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
	
DECLARE @PK_Locale int
DECLARE @PK_DefaultLocale int
DECLARE @tblEventType TABLE (PK_EventType int)
DECLARE @DSTeam VARCHAR(10)
DECLARE @DSCop VARCHAR(5)
DECLARE @HasManageEventAccess BIT

DECLARE @tbl TABLE (code nVARCHAR(3), name nVARCHAR(100))

DECLARE @RegionClassCode VARCHAR(20) = 'CORP'
		,@ThroughDate DATE = '2049-12-31'	

/******************************************************************************
	SET THE VARIABLES REQUIRED
******************************************************************************/

	BEGIN TRY

		SELECT @Error = 0, @ErrorMessage = '';


		SELECT @PK_Locale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = @LocaleCode
		SELECT @PK_DefaultLocale = PK_Locale FROM dbo.Locales WITH (NOLOCK) WHERE LocaleCode = 'en-US'

        SELECT @DSTeam = sSubTeam FROM dbo.v_Distributor WITH (NOLOCK) where sDistributorid = @UserID
        SELECT @DSCop = sDistributorCountryProcessingCode FROM dbo.v_Distributor WITH (NOLOCK) where sDistributorid = @UserID
        
        SELECT @HasManageEventAccess = CASE WHEN COUNT(1) > 0 THEN 1 ELSE 0 END 			
			FROM dbo.[EventTeamLevelAccess] etla WITH (NOLOCK)
			INNER JOIN EventSubTypeLocaleDesc stl WITH (NOLOCK)
			ON stl.pk_EventSubtypeLocaleDesc = etla.pk_EventSubtypeLocaleDesc AND stl.pk_Locale = @PK_Locale
			WHERE SubTypeCode = @DSTeam

		IF @EventTypeCode = 'ALL'
		BEGIN
			INSERT @tblEventType (PK_EventType)
			SELECT PK_EventType FROM dbo.EventType	WITH (NOLOCK) 
		END 

		ELSE

		IF @EventTypeCode = 'ALLCORP'
		BEGIN
			INSERT @tblEventType (PK_EventType)
			SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCode IN ('CP','CE')	
	
		END

		ELSE

		IF @EventTypeCode = 'CE'
		BEGIN
			INSERT @tblEventType (PK_EventType)
			SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCode IN ('CE')	
	
		END

		ELSE

		IF @EventTypeCode = 'CP'
		BEGIN
			INSERT @tblEventType (PK_EventType)
			SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCode IN ('CP')	
	
		END

		ELSE

		IF @EventTypeCode = 'DE'
		BEGIN
			INSERT @tblEventType (PK_EventType)
			SELECT PK_EventType FROM dbo.EventType WITH (NOLOCK) WHERE EventTypeCode = @EventTypeCode
	
		END

		/******************************************************************************
			DROPDOWN FOR COUNTRIES
		******************************************************************************/

		INSERT @tbl (Code, Name)
			  SELECT DISTINCT 'R' + sRegionCode sRegionCode, sRegionLabel FROM v_Countries ORDER BY sRegionLabel
		INSERT @tbl (Code, Name)
			  SELECT '', '---------------'
		INSERT @tbl (Code, Name) 
				SELECT DISTINCT	
						Case 
							when ISNULL(sCountryCodeISO,'') = '' then sCountryCode 
							else sCountryCodeISO 
						end as Code
						, sCountryName 
				FROM	v_Countries 
				WHERE	sCountryCodeISO IS NOT NULL  
				ORDER BY sCountryName

		SELECT Code, Name FROM @tbl WHERE code IS NOT NULL



		/*******************************************************************************************
			GET DROPDOWNS FOR ADMIN TOOL FOR CORP/DS EVENTS SETUP IF @UserID IS A STAFF USER
		*******************************************************************************************/

		IF EXISTS (SELECT EventATAccessUserName FROM dbo.EventATAccessUser EU WITH (NOLOCK) WHERE EventATAccessUserName = @UserID)

		BEGIN


		/******************************************************************************
			DROPDOWN FOR CORP-EVENT MASTER TYPES - EVENT SUBTYPES
		******************************************************************************/

		SELECT DISTINCT
			 EST.PK_EventSubType
			,ESL.EventSubTypeDesc 'EventSubType'
			,ETE.EventType
			,ETE.EventTypeCode	
		FROM 
			dbo.EventSubTypeGroupMaster EM WITH (NOLOCK) 
		INNER JOIN
			dbo.EventSubTypeGroupLocale EML WITH (NOLOCK) 
		ON
				EML.PK_EventSubTypeGroupMaster = EM.PK_EventSubTypeGroupMaster
				AND 
				EML.PK_Locale = @PK_Locale
		INNER JOIN
			dbo.EventSubTypeGroup ESG WITH (NOLOCK) 
		ON
			ESG.PK_EventSubTypeGroupMaster = EM.PK_EventSubTypeGroupMaster
		INNER JOIN
			@tblEventType ET
		ON
			ESG.PK_EventType = ET.PK_EventType
		INNER JOIN
			dbo.EventType ETE WITH (NOLOCK) 
		ON
			ETE.PK_EventType = ET.PK_EventType		
		INNER JOIN
			dbo.EventSubTypes EST WITH (NOLOCK) 
		ON
			EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
			AND
			EST.PK_EventType = ESG.PK_EventType
			AND
			EST.IsActive = 1 	
		INNER JOIN
			dbo.EventSubTypeLocaleDesc ESL WITH (NOLOCK) 
		ON
				EST.PK_EventSubType = ESL.PK_EventSubType
				AND 
				ESL.PK_Locale = @PK_Locale	
		INNER JOIN
			dbo.EventATAccessUserModules EUM WITH (NOLOCK) 
		ON
			EUM.PK_Locale = EML.PK_Locale
		INNER JOIN
			dbo.EventATAccessUser EU WITH (NOLOCK) 
		ON
			EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser					
		WHERE
			EM.IsActive = 1
			AND
			EU.EventATAccessUserName = @UserID
			AND
			ESL.EventSubTypeDesc IS NOT NULL	
		ORDER BY
			2

	
		/******************************************************************************
			DROPDOWN FOR LANGUAGE-SELECTOR 
		******************************************************************************/
	

		SELECT
			 L.LocaleCode
			,L.LanguageCountryRegion
			,'R' + C.sRegionCode As RegionCode
			,C.sRegionLabel As RegionName
			,sCountryCode
			,sCountryCodeISO					--BUG 266825 PK_Country missing on table EventCountry, because of sCountryCode, it will now use sCountryCodeISO
			,L.PK_Locale
			,ISNULL(cm.[AllowDistributorEvents], 0) AS [HasDSAccess]
			,LE.PK_MasterLocale
			,LE.IsMasterLocale
			,LE.MasterLanguageCountryRegion 
			,LE.MasterLocaleCode 
			,LE.MasterLocaleLanguage
		FROM			dbo.Locales L WITH (NOLOCK) 
		LEFT JOIN 
			(	SELECT 	LE.PK_Locale, LE.PK_MasterLocale, LE.MasterLocaleLanguage, LE.IsMasterlocale, ML.LanguageCountryRegion MasterLanguageCountryRegion, ML.LocaleCode MasterLocaleCode
				FROM	LocalesExtn LE WITH (NOLOCK)
						inner join Locales ML WITH (NOLOCK)
							ON LE.PK_MasterLocale = ML.PK_Locale
			) LE
			ON L.PK_Locale = LE.PK_Locale
		INNER JOIN dbo.v_Countries C
			ON SUBSTRING(L.LocaleCode, CHARINDEX('-', L.LocaleCode)+1, 2) = C.sCountryCodeISO
		INNER JOIN	dbo.EventATAccessUserModules EUM WITH (NOLOCK) 
			ON	EUM.PK_Locale = L.PK_Locale
		INNER JOIN dbo.EventATAccessUser EU WITH (NOLOCK) 
			ON	EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
		LEFT JOIN	PubEvents.dbo.dimCountry DC WITH (NOLOCK) 
			ON	SUBSTRING(L.LocaleCode,CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = DC.CountryCodeISO 
		LEFT JOIN	PubEvents.dbo.dimCountryRegion_XREF XREF WITH (NOLOCK) 
			ON XREF.PK_Country = DC.PK_Country 
		LEFT JOIN 	PubEvents.dbo.dimRegion R WITH (NOLOCK)  
			ON	R.PK_Region = XREF.PK_Region 
		LEFT JOIN	PubEvents.dbo.dimRegionClass RC WITH (NOLOCK) 
			ON 	R.PK_RegionClass = RC.PK_RegionClass
		LEFT JOIN [CountryPM] AS cm WITH (NOLOCK) 
			ON cm.[PK_Country] = DC.[PK_Country]
		WHERE RC.RegionClassCode = @RegionClassCode
		AND XREF.ThroughDate = @ThroughDate
		AND EU.EventATAccessUserName = @UserID		
		AND L.EnabledOnMyHL = 1						-- 33768 : Return only Locales aligned with myHL	
		ORDER BY L.LanguageCountryRegion	



		/******************************************************************************
			DROPDOWN FOR Eligible COuntries List
		******************************************************************************/

			SELECT	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 10000 as Ordering					
					,Case 
						when ISNULL(sCountryCodeISO,'') = '' then sCountryCode 
						else sCountryCodeISO 
					end as Countrycode
					,C.sCountryName As CountryName
					,'R' + C.sRegionCode  As RegionCode
					,C.sRegionLabel As RegionName
			FROM	dbo.v_countries C
			WHERE	sCountryCode in('-1','-2','-V','-W')				/* Codes for N.A., Unknown, Virtual and Worldwide Options */
			UNION	
			SELECT	ROW_NUMBER() OVER (ORDER BY C.CountryName ASC) as Ordering
					,C.Countrycode
					,C.CountryName
					,C.RegionCode
					,C.RegionName
			FROM	(	SELECT	DISTINCT 
								COALESCE(C.sCountryCodeISO,C.sCountryCode) As Countrycode
								,C.sCountryName As CountryName
								,'R' + C.sRegionCode  As RegionCode
								,C.sRegionLabel As RegionName
						FROM	dbo.v_countries C
								INNER JOIN dbo.Locales L WITH (NOLOCK) 
									ON SUBSTRING(L.LocaleCode, CHARINDEX('-', L.LocaleCode)+1, 2) = C.sCountryCodeISO
								INNER JOIN dbo.EventATAccessUserModules EUM WITH (NOLOCK) 
									ON EUM.PK_Locale = L.PK_Locale
								INNER JOIN dbo.EventATAccessUser EU WITH (NOLOCK) 	
									ON EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser	
								LEFT JOIN PubEvents.dbo.dimCountry DC WITH (NOLOCK) 
									ON SUBSTRING(L.LocaleCode,CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = DC.CountryCodeISO 
								LEFT JOIN PubEvents.dbo.dimCountryRegion_XREF XREF WITH (NOLOCK) 
									ON XREF.PK_Country = DC.PK_Country 
								LEFT JOIN PubEvents.dbo.dimRegion R  WITH (NOLOCK) 
									ON R.PK_Region = XREF.PK_Region 
								LEFT JOIN PubEvents.dbo.dimRegionClass RC  WITH (NOLOCK) 
									ON R.PK_RegionClass = RC.PK_RegionClass 
						WHERE	RC.RegionClassCode = @RegionClassCode
								AND XREF.ThroughDate = @ThroughDate	
								AND C.sCountryCodeISO IS NOT NULL
								AND EU.EventATAccessUserName = @UserID	
								AND L.EnabledOnMyHL = 1						-- 33768 : Return only Locales aligned with myHL					
								AND sCountryCode not in('-1','-2','-V','-W')
					) C
			ORDER BY Ordering

		END

		/******************************************************************************************
			GET DROPDOWNS FOR SUBMIT DISTRIBUTOR EVENTS PAGE ON MYHL IF @UserID IS A DISTRIBUTOR
		******************************************************************************************/

		ELSE IF (EXISTS (SELECT DistributorID FROM dbo.EventDSAccess EU  WITH (NOLOCK) WHERE DistributorID = @UserID)) OR (@HasManageEventAccess = 1)

		BEGIN		
	
		/******************************************************************************
			DROPDOWN FOR DS EVENT MASTER TYPES - EVENT SUBTYPES
		******************************************************************************/

	
		SELECT DISTINCT
			 EST.PK_EventSubType
			,ESL.EventSubTypeDesc 'EventSubType'
			,ETE.EventType
			,ETE.EventTypeCode	
		FROM 
			dbo.EventSubTypeGroupMaster EM  WITH (NOLOCK) 
		INNER JOIN
			dbo.EventSubTypeGroupLocale EML  WITH (NOLOCK) 
		ON
				EM.PK_EventSubTypeGroupMaster = EML.PK_EventSubTypeGroupMaster
				AND 
				EML.PK_Locale = @PK_Locale
		INNER JOIN
			dbo.EventSubTypeGroup ESG  WITH (NOLOCK) 
		ON
			ESG.PK_EventSubTypeGroupMaster = EM.PK_EventSubTypeGroupMaster
		INNER JOIN
			@tblEventType ET
		ON
			ESG.PK_EventType = ET.PK_EventType
		INNER JOIN
			dbo.EventType ETE  WITH (NOLOCK) 
		ON
			ETE.PK_EventType = ET.PK_EventType		
		INNER JOIN
			dbo.EventSubTypes EST  WITH (NOLOCK) 
		ON
			EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
			AND
			EST.PK_EventType = ESG.PK_EventType
			AND
			EST.IsActive = 1 	
		INNER JOIN
			dbo.EventSubTypeLocaleDesc ESL  WITH (NOLOCK) 
		ON
			EST.PK_EventSubType = ESL.PK_EventSubType
			AND 
			ESL.PK_Locale = @PK_Locale
		INNER JOIN
			dbo.EventDSAccess ED  WITH (NOLOCK) 
		ON
		ED.PK_EventSubTypeLocaleDesc=ESL.PK_EventSubTypeLocaleDesc  		
		WHERE
			EM.IsActive = 1
			AND
			ED.DistributorID = @UserID
			AND
			ESL.EventSubTypeDesc IS NOT NULL	
		ORDER BY
			2
	
		/******************************************************************************
			DROPDOWN FOR MYHERBALIFE SITE DROPDOWN
		******************************************************************************/
	
        IF (EXISTS (SELECT DistributorID FROM dbo.EventDSAccess EU  WITH (NOLOCK) WHERE DistributorID = @UserID))
        BEGIN
            SELECT DISTINCT
                L.LocaleCode
                ,L.LanguageCountryRegion
                ,'R' + C.sRegionCode As RegionCode
                ,C.sRegionLabel As RegionName
                ,sCountryCode
                ,sCountryCodeISO						--BUG 266825 PK_Country missing on table EventCountry, because of sCountryCode, it will now use sCountryCodeISO	
                ,L.PK_Locale
                ,ISNULL(cm.[AllowDistributorEvents], 0) AS [HasDSAccess]
                ,LE.PK_MasterLocale
                ,LE.IsMasterLocale
                ,LE.MasterLanguageCountryRegion 
                ,LE.MasterLocaleCode 
                ,LE.MasterLocaleLanguage
            FROM
                dbo.Locales L  WITH (NOLOCK) 
            LEFT JOIN
                (	SELECT 	LE.PK_Locale, LE.PK_MasterLocale, LE.MasterLocaleLanguage, LE.IsMasterlocale, ML.LanguageCountryRegion MasterLanguageCountryRegion, ML.LocaleCode MasterLocaleCode
                    FROM	LocalesExtn LE WITH (NOLOCK)
                            inner join Locales ML WITH (NOLOCK)
                                ON LE.PK_MasterLocale = ML.PK_Locale
                ) LE
                ON L.PK_Locale = LE.PK_Locale
            INNER JOIN 	dbo.v_Countries C
                ON SUBSTRING(L.LocaleCode, CHARINDEX('-', L.LocaleCode)+1, 2) = C.sCountryCodeISO
            INNER JOIN dbo.EventSubTypeLocaleDesc ESL   WITH (NOLOCK) 
                ON  L.PK_Locale=ESL.PK_Locale 
            INNER JOIN dbo.EventDSAccess EDA  WITH (NOLOCK) 
                ON	ESL.PK_EventSubTypeLocaleDesc=EDA.PK_EventSubTypeLocaleDesc
             LEFT JOIN dbo.EventTeamLevelAccess ETA  WITH (NOLOCK) 
                            ON	ESL.PK_EventSubTypeLocaleDesc=ETA.PK_EventSubTypeLocaleDesc AND RIGHT(L.LocaleCode, 2) = @DsCop
            LEFT JOIN PubEvents.dbo.dimCountry DC  WITH (NOLOCK) 
                ON SUBSTRING(L.LocaleCode,CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = DC.CountryCodeISO 
            LEFT JOIN PubEvents.dbo.dimCountryRegion_XREF XREF  WITH (NOLOCK) 
                ON	XREF.PK_Country = DC.PK_Country 
            LEFT JOIN PubEvents.dbo.dimRegion R  WITH (NOLOCK) 
                ON R.PK_Region = XREF.PK_Region 
            LEFT JOIN PubEvents.dbo.dimRegionClass RC  WITH (NOLOCK) 
                ON	R.PK_RegionClass = RC.PK_RegionClass 
            LEFT JOIN [CountryPM] AS cm  WITH (NOLOCK) ON cm.[PK_Country] = DC.[PK_Country]
            WHERE RC.RegionClassCode = @RegionClassCode
            AND XREF.ThroughDate = @ThroughDate	
            AND	(EDA.DistributorID = @UserID OR ETA.SubTypeCode = @DSTeam)
            AND L.EnabledOnMyHL = 1						-- 33768 : Return only Locales aligned with myHL	
            ORDER BY L.LanguageCountryRegion
        END
        ELSE
        BEGIN
            SELECT DISTINCT
                            L.LocaleCode
                            ,L.LanguageCountryRegion
                            ,'R' + C.sRegionCode As RegionCode
                            ,C.sRegionLabel As RegionName
                            ,sCountryCode
                            ,sCountryCodeISO						--BUG 266825 PK_Country missing on table EventCountry, because of sCountryCode, it will now use sCountryCodeISO	
                            ,L.PK_Locale
                            ,ISNULL(cm.[AllowDistributorEvents], 0) AS [HasDSAccess]
                            ,LE.PK_MasterLocale
                            ,LE.IsMasterLocale
                            ,LE.MasterLanguageCountryRegion 
                            ,LE.MasterLocaleCode 
                            ,LE.MasterLocaleLanguage
                        FROM
                            dbo.Locales L  WITH (NOLOCK) 
                        LEFT JOIN
                            (	SELECT 	LE.PK_Locale, LE.PK_MasterLocale, LE.MasterLocaleLanguage, LE.IsMasterlocale, ML.LanguageCountryRegion MasterLanguageCountryRegion, ML.LocaleCode MasterLocaleCode
                                FROM	LocalesExtn LE WITH (NOLOCK)
                                        inner join Locales ML WITH (NOLOCK)
                                            ON LE.PK_MasterLocale = ML.PK_Locale
                            ) LE
                            ON L.PK_Locale = LE.PK_Locale
                        INNER JOIN 	dbo.v_Countries C
                            ON SUBSTRING(L.LocaleCode, CHARINDEX('-', L.LocaleCode)+1, 2) = C.sCountryCodeISO
                        INNER JOIN dbo.EventSubTypeLocaleDesc ESL   WITH (NOLOCK) 
                            ON  L.PK_Locale=ESL.PK_Locale 
                        INNER JOIN dbo.EventTeamLevelAccess EDA  WITH (NOLOCK) 
                            ON	ESL.PK_EventSubTypeLocaleDesc=EDA.PK_EventSubTypeLocaleDesc AND RIGHT(L.LocaleCode, 2) = @DsCop
                        LEFT JOIN PubEvents.dbo.dimCountry DC  WITH (NOLOCK) 
                            ON SUBSTRING(L.LocaleCode,CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = DC.CountryCodeISO 
                        LEFT JOIN PubEvents.dbo.dimCountryRegion_XREF XREF  WITH (NOLOCK) 
                            ON	XREF.PK_Country = DC.PK_Country 
                        LEFT JOIN PubEvents.dbo.dimRegion R  WITH (NOLOCK) 
                            ON R.PK_Region = XREF.PK_Region 
                        LEFT JOIN PubEvents.dbo.dimRegionClass RC  WITH (NOLOCK) 
                            ON	R.PK_RegionClass = RC.PK_RegionClass 
                        LEFT JOIN [CountryPM] AS cm  WITH (NOLOCK) ON cm.[PK_Country] = DC.[PK_Country]
                        WHERE RC.RegionClassCode = @RegionClassCode
                        AND XREF.ThroughDate = @ThroughDate	
                        AND	EDA.SubTypeCode = @DSTeam	
                        AND L.EnabledOnMyHL = 1						-- 33768 : Return only Locales aligned with myHL	
                        ORDER BY L.LanguageCountryRegion
        END

		/******************************************************************************
			DROPDOWN FOR COUNTRY WHERE EVENT IS TAKING PLACE
		******************************************************************************/

			SELECT	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 10000 as Ordering
					,Case 
						when ISNULL(sCountryCodeISO,'') = '' then sCountryCode 
						else sCountryCodeISO 
					end as Countrycode
					,C.sCountryName As CountryName
					,'R' + C.sRegionCode  As RegionCode
					,C.sRegionLabel As RegionName
			FROM	dbo.v_countries C
			WHERE	sCountryCode in('-1','-2','-V','-W')				/* Codes for N.A., Unknown, Virtual and Worldwide Options */
			UNION	
			SELECT	ROW_NUMBER() OVER (ORDER BY C.sCountryName ASC)  as Ordering
					,C.sCountryCodeISO As Countrycode
					,C.sCountryName As CountryName
					,'R' + C.sRegionCode  As RegionCode
					,C.sRegionLabel As RegionName
			FROM	dbo.v_countries C
			WHERE	C.sCountryCodeISO IS NOT NULL
					AND sCountryCode not in('-1','-2','-V','-W')
			Order by Ordering

		END

		ELSE 
		--OR NOT EXISTS (SELECT EventATAccessUserName FROM dbo.EventATAccessUser EU WHERE EventATAccessUserName = @UserID)
		--OR EXISTS (SELECT DistributorID FROM dbo.EventDSAccess EU WHERE DistributorID = @UserID)
		BEGIN

			SELECT
			 NULL AS [PK_EventSubType]
			,'' AS [EventSubType]
			,'' AS [EventType]
			,'' AS [EventTypeCode]

			IF @UserID IS NULL
			BEGIN
				SELECT DISTINCT
					 L.LocaleCode
					,L.LanguageCountryRegion
					,'R' + C.sRegionCode As RegionCode
					,C.sRegionLabel As RegionName
					,sCountryCode
					,sCountryCodeISO								--BUG 266825 PK_Country missing on table EventCountry, because of sCountryCode, it will now use sCountryCodeISO					
					,L.PK_Locale
					,ISNULL(cm.[AllowDistributorEvents], 0) AS [HasDSAccess]
				FROM dbo.Locales L WITH (NOLOCK) 
				INNER JOIN dbo.v_Countries C
					ON SUBSTRING(L.LocaleCode, CHARINDEX('-', L.LocaleCode)+1, 2) = C.sCountryCodeISO
				LEFT JOIN PubEvents.dbo.dimCountry DC  WITH (NOLOCK) 
					ON SUBSTRING(L.LocaleCode,CHARINDEX('-',L.LocaleCode)+1, LEN(L.LocaleCode)) = DC.CountryCodeISO 
				LEFT JOIN PubEvents.dbo.dimCountryRegion_XREF XREF  WITH (NOLOCK) 
					ON XREF.PK_Country = DC.PK_Country 
				LEFT JOIN PubEvents.dbo.dimRegion R  WITH (NOLOCK) 
					ON R.PK_Region = XREF.PK_Region 
				LEFT JOIN PubEvents.dbo.dimRegionClass RC  WITH (NOLOCK) 
					ON	R.PK_RegionClass = RC.PK_RegionClass 
				LEFT JOIN [CountryPM] AS cm  WITH (NOLOCK) ON cm.[PK_Country] = DC.[PK_Country]
				WHERE RC.RegionClassCode = @RegionClassCode
				AND XREF.ThroughDate = @ThroughDate
				AND L.EnabledOnMyHL = 1						-- 33768 : Return only Locales aligned with myHL	
				ORDER BY L.LanguageCountryRegion
			END
			ELSE
			BEGIN
				SELECT
				 '' AS [LocaleCode]
				,'' AS [LanguageCountryRegion]
				,'' AS [RegionCode]
				,'' AS [RegionName]
				,'' AS [sCountryCode]
				,NULL AS [PK_Locale]
			END


			SELECT
				 '' As Countrycode
				,'' As CountryName
				,''  As RegionCode
				,'' As RegionName

		END

		/******************************************************************************
			DROPDOWN FOR EVENT SUBTYPES -- TRANSLATIONS ARE DISPLAYED FIRST FOR MYHL
		******************************************************************************/

		DECLARE @EventSubTypes TABLE (PK INT IDENTITY(1,1), EventSubTypeGroupMasterName varchar(200), EventSubType varchar(200), EventSubTypeLocal nvarchar(400))


		INSERT INTO @EventSubTypes  --- GET THE TRANSLATIONS FIRST
		SELECT DISTINCT EventSubTypeGroupMasterName, REPLACE(ES.EventSubType,'�','') EventSubType, REPLACE(COALESCE(ESLD.EventSubTypeDesc,ES.EventSubType),'�','') EventSubTypeLocal
		FROM	
			dbo.EventSubTypes ES WITH (NOLOCK) 
		INNER JOIN 
			@tblEventType T
		ON
			T.PK_EventType = ES.PK_EventType
		INNER JOIN
			dbo.EventSubTypeLocaleDesc ESLD WITH (NOLOCK) 	
			ON
				ES.PK_EventSubType = ESLD.PK_EventSubType
				AND
				ESLD.PK_Locale = COALESCE(@PK_Locale, @PK_DefaultLocale)
		INNER JOIN
			dbo.EventSubTypeGroup ESG WITH (NOLOCK) 
		ON
			ES.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
		INNER JOIN
			dbo.EventSubTypeGroupMaster ESM WITH (NOLOCK) 
		ON
			ESG.PK_EventSubTypeGroupMaster = ESM.PK_EventSubTypeGroupMaster
		WHERE
			ES.IsActive = 1
		ORDER BY 
			ESM.EventSubTypeGroupMasterName, REPLACE(COALESCE(ESLD.EventSubTypeDesc,ES.EventSubType),'�','')
	
		INSERT INTO @EventSubTypes  --- GET THE SUBTYPES THAT DOESN'T HAVE ANY TRANSLATIONS
		SELECT DISTINCT EventSubTypeGroupMasterName, REPLACE(ES.EventSubType,'�','') EventSubType, REPLACE(ES.EventSubType,'�','') EventSubTypeLocal
		FROM	
			dbo.EventSubTypes ES WITH (NOLOCK) 
		INNER JOIN 
			@tblEventType T
		ON
			T.PK_EventType = ES.PK_EventType	
		INNER JOIN
			dbo.EventSubTypeGroup ESG WITH (NOLOCK) 
		ON
			ES.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
		INNER JOIN
			dbo.EventSubTypeGroupMaster ESM WITH (NOLOCK) 
		ON
			ESG.PK_EventSubTypeGroupMaster = ESM.PK_EventSubTypeGroupMaster

	/* ***************** SonarQube check 162 - Nullable subqueries should not be used in "NOT IN" conditions */
		WHERE
			ES.IsActive = 1
			AND
			ES.EventSubType NOT IN (SELECT EventSubType FROM @EventSubTypes WHERE EventSubType IS NOT NULL)
		ORDER BY 
			ESM.EventSubTypeGroupMasterName, REPLACE(ES.EventSubType,'�','')
	/* ***************** SonarQube check 162 */


		SELECT EventSubType, EventSubTypeLocal  -- SORT THEM TO GET THE TRANSLATIONS FIRST
		FROM @EventSubTypes
		ORDER BY PK	

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
	END CATCH

/******************************************************************************
	END PROCEDURE
******************************************************************************/
END