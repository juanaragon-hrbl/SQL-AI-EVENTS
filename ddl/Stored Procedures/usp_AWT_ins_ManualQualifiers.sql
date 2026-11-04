CREATE PROCEDURE [dbo].[usp_AWT_ins_ManualQualifiers]
	@AWTYear	INT 
	,@DateAdded smalldatetime =  NULL
  --Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = NULL OUTPUT

	--QA/DEV
	,@IsDevQA SMALLINT = 0 -- 0 PROD 1 QA 2 UT 3 DEBUG

AS
BEGIN
/*********************************************************************************************************************
	OBJECT:		dbo.[usp_AWT_ins_ManualQualifiers]

	USE:		EXEC dbo.[usp_AWT_ins_ManualQualifiers] @AWTYear = 2021
			
	DESCRIPTION: 

	NOTES:		

	DEPENDENCIES:

	WORK TABLES (WRK):


	VERSIONS
	-----------------------------------------------------------------------------------------------------------------------------
	1	2021-07-27		alejandramed		Initial 
	
	***********************************************************************************************************************************/

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()

	
	SELECT @Error = 0, @ErrorMessage = '';	

BEGIN TRY
		
		IF (@IsDevQA = 2)
		BEGIN
			SELECT 'Forcing to fail for unit testing purpose';
			THROW 60000, N'Unit test Error', 1
		END
		
		SET @DateAdded = ISNULL(@DateAdded,getutcdate())
		DECLARE @Year int = 2016
		DECLARE @NonTABDate smalldatetime
		DECLARE @DistributorSet int
		DECLARE @SetTypeCode varchar(10)
		DECLARE @SetName varchar(10)
		DECLARE @CreatedBy varchar(30)
		DECLARE @System int

		SET @SetTypeCode = 'AWT'
		SET @SetName = 'AWT '+CONVERT(VARCHAR,@AWTYear)
		SET @CreatedBy = 'AWT_Manual'
		SET @System = 3
		-----------------------------------------------------------------------------------
		DROP TABLE IF EXISTS #AWT

		CREATE TABLE #AWT(
			[PK_AWT] [bigint] IDENTITY(1,1) NOT NULL,
			[Flg1] [tinyint] NULL,
			[AWTYear] [int] NOT NULL,
			[PK_Distributor] [int] NULL,
			[DistributorID] [varchar](30) NULL,
			[FirstName] [nvarchar](50) NULL,
			[LastName] [nvarchar](50) NULL,
			[Address1] [nvarchar](480) NULL,
			[Address2] [nvarchar](480) NULL,
			[Address3] [nvarchar](480) NULL,
			[Address4] [nvarchar](480) NULL,
			[City] [nvarchar](120) NULL,
			[County] [nvarchar](120) NULL,
			[PostalCode] [nvarchar](120) NULL,
			[CountryCode] [nvarchar](2) NULL,
			[State] [nvarchar](120) NULL,
			[SpouseFirstName] [nvarchar](50) NULL,
			[SpouseLastName] [nvarchar](50) NULL,
			[COP] [char](2) NULL,
			[COPRegion] [varchar](50) NULL,
			[Email] [varchar](100) NULL,
			[Phone] [varchar](100) NULL,
			[Team] [varchar](2) NULL,
			[PK_Sponsor] [int] NULL,
			[SponsorID] [varchar](30) NULL,
			[SponsorFirstName] [nvarchar](50) NULL,
			[SponsorLastName] [nvarchar](50) NULL,
			[Qual_SP] [smalldatetime] NULL,
			[Qual_G] [smalldatetime] NULL,
			[Qual_W] [smalldatetime] NULL,
			[Qual_AWT] [smalldatetime] NULL,
			[IsDeleted] [int] NULL,
			[DeletedDate] [smalldatetime] NULL,
			[IsDNR] [int] NULL,
			[DateAdded] [smalldatetime] NULL,
			[IsType23] [int] NULL,
			[PastAWT] [varchar](50) NULL,
			[isNonTAB] [tinyint] NULL,
			[earnPlaque]  AS (case when [PastAWT]='No' then (1) else (0) end),
			[earn500Bonus]  AS (case when [PastAWT]='No' AND [isNonTAB]=(1) then (1) else (0) end),
			[PK_UplinePres1] [int] NULL,
			[UplinePresID1] [varchar](10) NULL,
			[UplinePres1FirstName] [nvarchar](50) NULL,
			[UplinePres1LastName] [nvarchar](50) NULL,
			[PK_UplinePres2] [int] NULL,
			[UplinePresID2] [varchar](10) NULL,
			[PK_UplinePres3] [int] NULL,
			[UplinePresID3] [varchar](10) NULL,
			[PK_UplineSP1] [int] NULL,
			[UplineSPID1] [varchar](10) NULL,
			[PK_UplineSP2] [int] NULL,
			[UplineSPID2] [varchar](10) NULL,
			[PK_UplineSP3] [int] NULL,
			[UplineSPID3] [varchar](10) NULL,
			[PK_MainDistributor] [int] NULL,
			[MainDistributorID] [varchar](30) NULL,
			[MainFirstName] [nvarchar](50) NULL,
			[MainLastName] [nvarchar](50) NULL,
			[MainAddress1] [nvarchar](480) NULL,
			[MainAddress2] [nvarchar](480) NULL,
			[MainAddress3] [nvarchar](480) NULL,
			[MainAddress4] [nvarchar](480) NULL,
			[MainCity] [nvarchar](120) NULL,
			[MainCounty] [nvarchar](120) NULL,
			[MainPostalCode] [nvarchar](120) NULL,
			[MainCountryCode] [nvarchar](2) NULL,
			[MainState] [nvarchar](120) NULL,
			[FirstNameLocal] [nvarchar](200) NULL,
			[LastNameLocal] [nvarchar](200) NULL,
			[Address1Local] [nvarchar](240) NULL,
			[Address2Local] [nvarchar](240) NULL,
			[Address3Local] [nvarchar](240) NULL,
			[Address4Local] [nvarchar](240) NULL,
			[CityLocal] [nvarchar](60) NULL,
			[CountyLocal] [nvarchar](60) NULL,
			[PostalCodeLocal] [nvarchar](60) NULL,
			[StateLocal] [nvarchar](60) NULL,
			[SpouseFirstNameLocal] [nvarchar](200) NULL,
			[SpouseLastNameLocal] [nvarchar](200) NULL,
			[SponsorFirstNameLocal] [nvarchar](200) NULL,
			[SponsorLastNameLocal] [nvarchar](200) NULL,
			[MainFirstNameLocal] [nvarchar](200) NULL,
			[MainLastNameLocal] [nvarchar](200) NULL,
			[MainAddress1Local] [nvarchar](240) NULL,
			[MainAddress2Local] [nvarchar](240) NULL,
			[MainAddress3Local] [nvarchar](240) NULL,
			[MainAddress4Local] [nvarchar](240) NULL,
			[MainCityLocal] [nvarchar](60) NULL,
			[MainCountyLocal] [nvarchar](60) NULL,
			[MainPostalCodeLocal] [nvarchar](60) NULL,
			[MainStateLocal] [nvarchar](60) NULL,
			[PK_UplineTAB1] [int] NULL,
			[UplineTABID1] [varchar](10) NULL,
			[LPFirstname] [nvarchar](100) NULL,
			[LPLastName] [nvarchar](100) NULL,
			[LPFirstNameLocal] [nvarchar](100) NULL,
			[LPLastNameLocal] [nvarchar](100) NULL
		)

		DROP TABLE IF EXISTS #AWT_Manual_Qualifiers

		CREATE TABLE #AWT_Manual_Qualifiers
		(
			DistributorID varchar(30)
			,PK_Distributor int
			,Qual_AWT date
		)

		-----------------------------------------------------------------------------------
			SELECT @NonTABDate = NonTABDate FROM dbo.AWT_Definitions WITH (NOLOCK) WHERE AWTYear = @AWTYear

			SELECT
				@DistributorSet = DistributorSet
			FROM dbo.AWT_Definitions WITH (NOLOCK) WHERE AWTYear = @AWTYear

			INSERT INTO #AWT_Manual_Qualifiers(DistributorID,PK_Distributor,Qual_AWT)
				SELECT  
					D.sDistributorID AS DistributorID,
					AM.PK_Distributor,
					AM.Qual_AWT
				FROM 
					dbo.AWT_ManualOverride AM WITH (NOLOCK)
						INNER JOIN dbo.v_Distributor D 
						ON AM.PK_Distributor = D.nDistributorID 
				WHERE
					AWTYear = @AWTYear
					AND
					NOT EXISTS (SELECT 1 FROM dbo.AWT A WITH (NOLOCK) WHERE AWTYear = @AWTYear AND A.PK_Distributor = AM.PK_Distributor AND A.Qual_AWT = AM.Qual_AWT)
		

				INSERT #AWT(AWTYear,PK_Distributor,Qual_AWT)
				SELECT
					@AWTYear
					,PK_Distributor 
					,Qual_AWT
				FROM 
					#AWT_Manual_Qualifiers

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
					#AWT A
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor 
				INNER JOIN
					dbo.v_Distributor D
				ON
					AWQ.PK_Distributor = D.nDistributorID 	
				WHERE
					A.AWTYear = @AWTYear
	
				-- Update DS and spouse local info
				UPDATE
					A
				SET
					FirstNameLocal = D.FirstNameLocal 
					,LastNameLocal = D.LastNameLocal 
					,SpouseFirstNameLocal = D.SpouseFirstNameLocal 
					,SpouseLastNameLocal = D.SpouseLastNameLocal 
				FROM
					#AWT A
				INNER JOIN
					pubEvents.dbo.dimDistributor D (NOLOCK)
				ON
					A.PK_Distributor = D.PK_Distributor
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor
				WHERE
					A.AWTYear = @AWTYear
	
				-- Update sponsor local info
				UPDATE
					A
				SET
					SponsorFirstNameLocal = D.FirstNameLocal 
					,SponsorLastNameLocal = D.LastNameLocal 
				FROM
					#AWT A
				INNER JOIN
					pubEvents.dbo.dimDistributor D (NOLOCK)
				ON
					A.PK_Sponsor = D.PK_Distributor
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor
				WHERE
					A.AWTYear = @AWTYear

				/******************************************************************************
					Update MAIN info
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
					#AWT A
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor
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
	
				-- Update main local info
				UPDATE
					A
				SET
					MainFirstNameLocal = D.FirstNameLocal 
					,MainLastNameLocal = D.LastNameLocal 
				FROM
					#AWT A
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor
				INNER JOIN
					pubEvents.dbo.dimDistributor D (NOLOCK)
					ON
						A.PK_MainDistributor = D.PK_Distributor
				WHERE
					A.AWTYear = @AWTYear

				/******************************************************************************
					Update qual dates
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
							#AWT A
							ON
								H.nDistributorIDFK = A.PK_Distributor
								AND A.AWTYear = @AWTYear
						INNER JOIN
							#AWT_Manual_Qualifiers AWQ
						ON
							A.PK_Distributor = AWQ.PK_Distributor
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
					#AWT A
				INNER JOIN
					History H
					ON
						A.PK_Distributor = H.PK_Distributor
				WHERE
					A.AWTYear = @AWTYear

				/******************************************************************************
					update mailing address info for distributor
				******************************************************************************/

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
					pubEvents.dbo.dimDSContactInfo M (NOLOCK)
				INNER JOIN
					#AWT A
					ON
						M.PK_Distributor = A.PK_Distributor
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor

				/******************************************************************************
					Update mailing address info for main
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
					pubEvents.dbo.dimDSContactInfo M (NOLOCK)
				INNER JOIN
					#AWT A
					ON
						M.PK_Distributor = A.PK_MainDistributor
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor

				/******************************************************************************
					Update country of processing region
				******************************************************************************/	
				UPDATE
					A
				SET
					COPRegion = C.sRegionLabel
				FROM
					#AWT A
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor
				INNER JOIN
					dbo.v_Countries C
					ON
						A.COP = C.sCountryCode
				WHERE
					A.AWTYear = @AWTYear

				/******************************************************************************
					Update email
				******************************************************************************/
	
				UPDATE
					A
				SET 
					Email = E.sString
				FROM 
					dbo.v_DistributorEmail E
				INNER JOIN
					#AWT A
					ON
						E.nDistributorIDFK = A.PK_Distributor
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor

				/******************************************************************************
					Update phone
				******************************************************************************/
	
				UPDATE
					A
				SET 
					Phone = P.sString
				FROM 
					dbo.v_DistributorPrimaryPhone P
				INNER JOIN
					#AWT A
					ON
						P.nDistributorIDFK = A.PK_Distributor
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor

				/******************************************************************************
					Update spouse
				******************************************************************************/
	
				UPDATE
					A
				SET 
					SpouseFirstName = S.sSpouseFirstName
					,SpouseLastName = S.sSpouseLastName
				FROM 
					dbo.v_DistributorSpouse S
				INNER JOIN
					#AWT A
					ON
						S.nDistributorID = A.PK_Distributor
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor

				/******************************************************************************
					Update sponsor firstname, lastname
				******************************************************************************/
	
				UPDATE
					A
				SET 
					SponsorFirstName = D.sFirstName
					,SponsorLastName = D.sLastName
				FROM 
					dbo.v_Distributor D
				INNER JOIN
					#AWT A
					ON
						D.nDistributorID = A.PK_Sponsor
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor

				/******************************************************************************  
				 Update lineage pks  
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
				 #AWT A
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
				 #AWT A
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
				 #AWT A
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
					#AWT A
					ON
						D.nDistributorID = A.PK_UplinePres1
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor

				UPDATE
					A
				SET 
					UplinePresID2 = D.sDistributorID
				FROM 
					dbo.v_Distributor D
				INNER JOIN
					#AWT A
					ON
						D.nDistributorID = A.PK_UplinePres2
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor

				UPDATE
					A
				SET 
					UplinePresID3 = D.sDistributorID
				FROM 
					dbo.v_Distributor D
				INNER JOIN
					#AWT A
					ON
						D.nDistributorID = A.PK_UplinePres3
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor

				UPDATE
					A
				SET 
					UplineSPID1 = D.sDistributorID
				FROM 
					dbo.v_Distributor D
				INNER JOIN
					#AWT A
					ON
						D.nDistributorID = A.PK_UplineSP1
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor

				UPDATE
					A
				SET 
					UplineSPID2 = D.sDistributorID
				FROM 
					dbo.v_Distributor D
				INNER JOIN
					#AWT A
					ON
						D.nDistributorID = A.PK_UplineSP2
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor
	
				UPDATE
					A
				SET 
					UplineSPID3 = D.sDistributorID
				FROM 
					dbo.v_Distributor D
				INNER JOIN
					#AWT A
					ON
						D.nDistributorID = A.PK_UplineSP3
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor
			
				UPDATE
					A
				SET 
					UplineTABID1 = D.sDistributorID
				FROM 
					dbo.v_Distributor D
				INNER JOIN
					#AWT A
					ON
						D.nDistributorID = A.PK_UplineTAB1
						AND	A.AWTYear = @AWTYear
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor
				/******************************************************************************
					mark DNR records
				******************************************************************************/
				UPDATE
					A
				SET
					IsDNR = 1
				FROM
					#AWT A
				INNER JOIN
					dbo.v_DistributorDoNotRecognize D
					ON
						A.PK_Distributor = D.PK_Distributor
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor
				WHERE
					A.AWTYear = @AWTYear

				/******************************************************************************
					update date added
				******************************************************************************/
				UPDATE
					A
				SET
					DateAdded = @DateAdded 
				FROM
					#AWT A
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor
				WHERE
					A.AWTYear = @AWTYear
					AND A.DateAdded IS NULL	
	

				-- GET Qual must be greater than or equal to this date to be non-tab
				-- or if GET Qual is less than the DS is not a non-TAB

				UPDATE
					A
				SET
					IsNonTAB = CASE WHEN Qual_G <= @NonTABDate THEN 0 ELSE 1 END
				FROM
					#AWT A
				INNER JOIN
					#AWT_Manual_Qualifiers AWQ
				ON
					A.PK_Distributor = AWQ.PK_Distributor
				WHERE
					A.AWTYear = @AWTYear

				WHILE @Year < @AWTYear
				BEGIN
					UPDATE
						A
					SET
						PastAWT = 
							CASE 
								WHEN AWQ.PastAWT = 'No' THEN RIGHT(CONVERT(varchar,@Year),2)
								ELSE AWQ.PastAWT + '-' + RIGHT(CONVERT(varchar,@Year),2) END
					FROM
						#AWT A
					INNER JOIN
						dbo.AWT AWQ
					ON
						A.PK_Distributor = AWQ.PK_Distributor
					LEFT JOIN
						dbo.v_DistributorAssociate2 DT
					ON
						A.PK_Distributor IN (DT.nMainDistributorID, DT.nDistributorID) 
					INNER JOIN
						dbo.AWT_Qualifiers Q
						ON
							Q.AWTYear = @Year
							AND 
							Q.PK_Distributor IN (A.PK_Distributor,DT.nDistributorID, DT.nMainDistributorID)
					WHERE
						A.AWTYear = @AWTYear

					SET @Year += 1
				END

				IF @IsDevQA = 0
				BEGIN
		
					INSERT INTO [dbo].[AWT]
					   ([Flg1]
					   ,[AWTYear]
					   ,[PK_Distributor]
					   ,[DistributorID]
					   ,[FirstName]
					   ,[LastName]
					   ,[Address1]
					   ,[Address2]
					   ,[Address3]
					   ,[Address4]
					   ,[City]
					   ,[County]
					   ,[PostalCode]
					   ,[CountryCode]
					   ,[State]
					   ,[SpouseFirstName]
					   ,[SpouseLastName]
					   ,[COP]
					   ,[COPRegion]
					   ,[Email]
					   ,[Phone]
					   ,[Team]
					   ,[PK_Sponsor]
					   ,[SponsorID]
					   ,[SponsorFirstName]
					   ,[SponsorLastName]
					   ,[Qual_SP]
					   ,[Qual_G]
					   ,[Qual_W]
					   ,[Qual_AWT]
					   ,[IsDeleted]
					   ,[DeletedDate]
					   ,[IsDNR]
					   ,[DateAdded]
					   ,[IsType23]
					   ,[PastAWT]
					   ,[isNonTAB]
					   ,[PK_UplinePres1]
					   ,[UplinePresID1]
					   ,[UplinePres1FirstName]
					   ,[UplinePres1LastName]
					   ,[PK_UplinePres2]
					   ,[UplinePresID2]
					   ,[PK_UplinePres3]
					   ,[UplinePresID3]
					   ,[PK_UplineSP1]
					   ,[UplineSPID1]
					   ,[PK_UplineSP2]
					   ,[UplineSPID2]
					   ,[PK_UplineSP3]
					   ,[UplineSPID3]
					   ,[PK_MainDistributor]
					   ,[MainDistributorID]
					   ,[MainFirstName]
					   ,[MainLastName]
					   ,[MainAddress1]
					   ,[MainAddress2]
					   ,[MainAddress3]
					   ,[MainAddress4]
					   ,[MainCity]
					   ,[MainCounty]
					   ,[MainPostalCode]
					   ,[MainCountryCode]
					   ,[MainState]
					   ,[FirstNameLocal]
					   ,[LastNameLocal]
					   ,[Address1Local]
					   ,[Address2Local]
					   ,[Address3Local]
					   ,[Address4Local]
					   ,[CityLocal]
					   ,[CountyLocal]
					   ,[PostalCodeLocal]
					   ,[StateLocal]
					   ,[SpouseFirstNameLocal]
					   ,[SpouseLastNameLocal]
					   ,[SponsorFirstNameLocal]
					   ,[SponsorLastNameLocal]
					   ,[MainFirstNameLocal]
					   ,[MainLastNameLocal]
					   ,[MainAddress1Local]
					   ,[MainAddress2Local]
					   ,[MainAddress3Local]
					   ,[MainAddress4Local]
					   ,[MainCityLocal]
					   ,[MainCountyLocal]
					   ,[MainPostalCodeLocal]
					   ,[MainStateLocal]
					   ,[PK_UplineTAB1]
					   ,[UplineTABID1]
					   ,[LPFirstname]
					   ,[LPLastName]
					   ,[LPFirstNameLocal]
					   ,[LPLastNameLocal])
					SELECT
						[Flg1]
					   ,[AWTYear]
					   ,[PK_Distributor]
					   ,[DistributorID]
					   ,[FirstName]
					   ,[LastName]
					   ,[Address1]
					   ,[Address2]
					   ,[Address3]
					   ,[Address4]
					   ,[City]
					   ,[County]
					   ,[PostalCode]
					   ,[CountryCode]
					   ,[State]
					   ,[SpouseFirstName]
					   ,[SpouseLastName]
					   ,[COP]
					   ,[COPRegion]
					   ,[Email]
					   ,[Phone]
					   ,[Team]
					   ,[PK_Sponsor]
					   ,[SponsorID]
					   ,[SponsorFirstName]
					   ,[SponsorLastName]
					   ,[Qual_SP]
					   ,[Qual_G]
					   ,[Qual_W]
					   ,[Qual_AWT]
					   ,[IsDeleted]
					   ,[DeletedDate]
					   ,[IsDNR]
					   ,[DateAdded]
					   ,[IsType23]
					   ,[PastAWT]
					   ,[isNonTAB]
					   ,[PK_UplinePres1]
					   ,[UplinePresID1]
					   ,[UplinePres1FirstName]
					   ,[UplinePres1LastName]
					   ,[PK_UplinePres2]
					   ,[UplinePresID2]
					   ,[PK_UplinePres3]
					   ,[UplinePresID3]
					   ,[PK_UplineSP1]
					   ,[UplineSPID1]
					   ,[PK_UplineSP2]
					   ,[UplineSPID2]
					   ,[PK_UplineSP3]
					   ,[UplineSPID3]
					   ,[PK_MainDistributor]
					   ,[MainDistributorID]
					   ,[MainFirstName]
					   ,[MainLastName]
					   ,[MainAddress1]
					   ,[MainAddress2]
					   ,[MainAddress3]
					   ,[MainAddress4]
					   ,[MainCity]
					   ,[MainCounty]
					   ,[MainPostalCode]
					   ,[MainCountryCode]
					   ,[MainState]
					   ,[FirstNameLocal]
					   ,[LastNameLocal]
					   ,[Address1Local]
					   ,[Address2Local]
					   ,[Address3Local]
					   ,[Address4Local]
					   ,[CityLocal]
					   ,[CountyLocal]
					   ,[PostalCodeLocal]
					   ,[StateLocal]
					   ,[SpouseFirstNameLocal]
					   ,[SpouseLastNameLocal]
					   ,[SponsorFirstNameLocal]
					   ,[SponsorLastNameLocal]
					   ,[MainFirstNameLocal]
					   ,[MainLastNameLocal]
					   ,[MainAddress1Local]
					   ,[MainAddress2Local]
					   ,[MainAddress3Local]
					   ,[MainAddress4Local]
					   ,[MainCityLocal]
					   ,[MainCountyLocal]
					   ,[MainPostalCodeLocal]
					   ,[MainStateLocal]
					   ,[PK_UplineTAB1]
					   ,[UplineTABID1]
					   ,[LPFirstname]
					   ,[LPLastName]
					   ,[LPFirstNameLocal]
					   ,[LPLastNameLocal]
					FROM #AWT

				INSERT INTO dbo.AWT_Qualifiers (Flg1,AWTYear,PK_Distributor,DistributorID,DateAdded,Qual_AWT)
				SELECT 1,@AWTYear,PK_Distributor,DistributorID,@DateAdded,Qual_AWT 
				FROM	
					#AWT_Manual_Qualifiers
	
				INSERT INTO dbo.AWT_BizWork_Qualifiers (AWTYear,PK_Distributor_EDW,DistributorID,DateAdded,Qual_AWT,CreatedBy,ModifiedBy,CreatedDateUTC,ModifiedDateUTC )
				SELECT @AWTYear,PK_Distributor,DistributorID,@DateAdded,Qual_AWT,@CreatedBy,@CreatedBy,@DateAdded,@DateAdded  
				FROM	
					#AWT_Manual_Qualifiers
	
				;WITH DSSet (PK_DSSet, PK_Distributor, Fromdate, ThroughDare, QualifiedDate, DelFlg, CreatedDate) AS
				(
					SELECT
						@DistributorSet
						,A.PK_Distributor
						,A.DateAdded
						,'2049-12-31'			
						,A.Qual_AWT
						,A.Flg1
						,A.CreatedDateUTC			
					FROM
						dbo.AWT_Qualifiers A (NOLOCK)
					INNER JOIN
						#AWT_Manual_Qualifiers AWQ
					ON
						A.PK_Distributor = AWQ.PK_Distributor
					WHERE
						A.AWTYear = @AWTYear
				)

				INSERT INTO DBLists.dbo.DSListDetail
				(PK_DSList
				,PK_Distributor
				,DistributorID
				,ValidFromDateUTC
				,ValidThroughDateUTC
				,Date01
				,Date02
				,CreatedDateUTC
				,CreatedBy
				,ModifiedDateUTC
				,ModifiedBy)
				SELECT
					DS.PK_DSSet
					,DS.PK_Distributor
					,D.sDistributorID
					,DS.Fromdate
					,DS.ThroughDare
					,DS.QualifiedDate
					,NULL
					,CreatedDate
					,@CreatedBy
					,@DateAdded 
					,@CreatedBy
				FROM
					DSSet DS
				INNER JOIN
					dbo.v_Distributor D
				ON
					DS.PK_Distributor = D.nDistributorID  
	
				END

		/******************************************************************************
					END PROCEDURE
		******************************************************************************/
		
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
	END CATCH;
END;