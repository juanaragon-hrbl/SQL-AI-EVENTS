CREATE PROCEDURE [dbo].[usp_AWT_Add_ManualQualifier]
	 @AWTYear INT 
	,@DistributorID varchar(25) 
	,@Qual_AWT date
	-- Optional Parameters
	-- Error Parameters
	,@Error	int = 0  OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA smallint = 0 --0  PROD, 1 QA, >= 20 UT, 3 DEBUG
 
		
AS
BEGIN
/******************************************************************************
	OBJECT: [dbo].[usp_AWT_Add_ManualQualifier]
	
	USE:			
			DECLARE @e int, @em varchar(max)

			EXEC [dbo].[usp_AWT_Add_ManualQualifier]
				@AWTYear = 2022
				,@DistributorID = '82Y2088892'
				,@Qual_AWT = '2022-11-01'
				,@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 0

			SELECT @e AS [Error], @em AS [Error Message]

	DESCRIPTION:	

	NOTES:
	/api?/Awt?/InsertAwtManualQualifier

	DEPENDENCIES
	--------------------------------------------------------------------
	
	VERSIONS
	--------------------------------------------------------------------
	1.0.0		2022-02-09		alejandramed		Initial
   
******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	--Variables for logging
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE()
			,@e  INT = 0 
			,@em VARCHAR(4000) = '';
 
	SELECT @Error = 0 ,   @ErrorMessage = ''

	DECLARE @DateAdded smalldatetime = GETUTCDATE()
	,@Year int = 2016
	,@NonTABDate smalldatetime
	,@DistributorSet int
	,@SetType int
	,@SetTypeCode varchar(10)
	,@DSSet int
	,@SetName varchar(10)
	,@CreatedBy varchar(30)
	,@CreatedDate datetime
	,@System int

	SET @SetTypeCode = 'AWT'
	SET @SetName = 'AWT '+CONVERT(VARCHAR,@AWTYear)
	SET @CreatedBy = 'AWT_Manual'
	SET @System = 3

BEGIN TRY
	
IF (@IsDevQA = 21)
	BEGIN
		PRINT 'Forcing to fail for unit testing purpose';
		THROW 60000, N'Unit test Error', 1
	END
 
	SELECT 
		@DistributorSet = DistributorSet, 
		@NonTABDate = NonTABDate 
	FROM dbo.AWT_Definitions (NOLOCK) WHERE AWTYear = @AWTYear

	IF @DistributorSet IS NULL
	BEGIN
		SET @Error = '80001'
		SET @ErrorMessage = 'Invalid AWT definition'
		RETURN;
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID)
	BEGIN
		SET @Error = '80002'
		SET @ErrorMessage = 'Invalid Distributor ID'
		RETURN;
	END

	IF OBJECT_ID('tempdb..#AWT_Manual_Qualifiers', 'U') IS NOT NULL DROP TABLE #AWT_Manual_Qualifiers

	CREATE TABLE #AWT_Manual_Qualifiers
	(
		DistributorID varchar(30)
		,PK_Distributor int
		,Qual_AWT date
	)

	INSERT INTO #AWT_Manual_Qualifiers(DistributorID,PK_Distributor,Qual_AWT)
	SELECT sDistributorID,nDistributorID, @Qual_AWT
	FROM
		dbo.v_Distributor WHERE sDistributorID = @DistributorID

	INSERT INTO dbo.AWT_ManualOverride(Flg1,AWTYear,PK_Distributor,DistributorID,DateAdded,Qual_AWT)
	SELECT 1,@AWTYear,PK_Distributor,DistributorID,@DateAdded,Qual_AWT
	FROM #AWT_Manual_Qualifiers

	INSERT
		dbo.AWT
	(
		AWTYear
		,PK_Distributor
		,Qual_AWT
	)
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
		dbo.AWT A
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
	
	-- update DS and spouse local info
	UPDATE
		A
	SET
		FirstNameLocal = D.FirstNameLocal 
		,LastNameLocal = D.LastNameLocal 
		,SpouseFirstNameLocal = D.SpouseFirstNameLocal 
		,SpouseLastNameLocal = D.SpouseLastNameLocal 
	FROM
		dbo.AWT A
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
	
	-- update sponsor local info
	UPDATE
		A
	SET
		SponsorFirstNameLocal = D.FirstNameLocal 
		,SponsorLastNameLocal = D.LastNameLocal 
	FROM
		dbo.AWT A
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
	
	-- update main local info
	UPDATE
		A
	SET
		MainFirstNameLocal = D.FirstNameLocal 
		,MainLastNameLocal = D.LastNameLocal 
	FROM
		dbo.AWT A
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
		dbo.AWT A
		ON
			M.PK_Distributor = A.PK_Distributor
			AND	A.AWTYear = @AWTYear
	INNER JOIN
		#AWT_Manual_Qualifiers AWQ
	ON
		A.PK_Distributor = AWQ.PK_Distributor

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
		pubEvents.dbo.dimDSContactInfo M (NOLOCK)
	INNER JOIN
		dbo.AWT A
		ON
			M.PK_Distributor = A.PK_MainDistributor
			AND	A.AWTYear = @AWTYear
	INNER JOIN
		#AWT_Manual_Qualifiers AWQ
	ON
		A.PK_Distributor = AWQ.PK_Distributor

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
			AND	A.AWTYear = @AWTYear
	INNER JOIN
		#AWT_Manual_Qualifiers AWQ
	ON
		A.PK_Distributor = AWQ.PK_Distributor

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
			AND	A.AWTYear = @AWTYear
	INNER JOIN
		#AWT_Manual_Qualifiers AWQ
	ON
		A.PK_Distributor = AWQ.PK_Distributor

	/******************************************************************************
		update spouse
	******************************************************************************/
	UPDATE
		A
	SET 
		SpouseFirstName = S.sSpouseFirstName
		,SpouseLastName = S.sSpouseLastName
	FROM 
		dbo.v_DistributorSpouse S
	INNER JOIN
		dbo.AWT A
		ON
			S.nDistributorID = A.PK_Distributor
			AND	A.AWTYear = @AWTYear
	INNER JOIN
		#AWT_Manual_Qualifiers AWQ
	ON
		A.PK_Distributor = AWQ.PK_Distributor

	/******************************************************************************
		update sponsor firstname, lastname
	******************************************************************************/
	UPDATE
		A
	SET 
		SponsorFirstName = D.sFirstName
		,SponsorLastName = D.sLastName
	FROM 
		dbo.v_Distributor D
	INNER JOIN
		dbo.AWT A
		ON
			D.nDistributorID = A.PK_Sponsor
			AND	A.AWTYear = @AWTYear
	INNER JOIN
		#AWT_Manual_Qualifiers AWQ
	ON
		A.PK_Distributor = AWQ.PK_Distributor

	/******************************************************************************
		update lineage pks
	******************************************************************************/
	UPDATE
		A
	SET 
		PK_UplinePres1 = L.nFirstUplinePres
		,PK_UplineSP1 = L.nFirstUplineSP
		,PK_UplineSP2 = L.nSecondUplineSP
		,PK_UplineSP3 = L.nThirdUplineSP
		,PK_UplineTAB1 = L.nFirstUplineTAB
	FROM 
		dbo.v_SupervisorLineage L
	INNER JOIN
		dbo.AWT A
		ON
			L.nDistributorID = A.PK_Distributor
			AND	A.AWTYear = @AWTYear
	INNER JOIN
		#AWT_Manual_Qualifiers AWQ
	ON
		A.PK_Distributor = AWQ.PK_Distributor

	-- SECOND UPLINE PRES
	UPDATE
		A
	SET 
		PK_UplinePres2 = L.nFirstUplinePres
	FROM 
		dbo.v_SupervisorLineage L
	INNER JOIN
		dbo.AWT A
		ON
			L.nDistributorID = A.PK_UplinePres1
			AND	A.AWTYear = @AWTYear
	INNER JOIN
		#AWT_Manual_Qualifiers AWQ
	ON
		A.PK_Distributor = AWQ.PK_Distributor


	-- THIRD UPLINE PRES
	UPDATE
		A
	SET 
		PK_UplinePres3 = L.nFirstUplinePres
	FROM 
		dbo.v_SupervisorLineage L
	INNER JOIN
		dbo.AWT A
		ON
			L.nDistributorID = A.PK_UplinePres2
			AND	A.AWTYear = @AWTYear
	INNER JOIN
		#AWT_Manual_Qualifiers AWQ
	ON
		A.PK_Distributor = AWQ.PK_Distributor

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
		dbo.AWT A
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
		dbo.AWT A
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
		dbo.AWT A
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
		dbo.AWT A
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
		dbo.AWT A
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
		dbo.AWT A
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
		dbo.AWT A
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
		dbo.AWT A
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
		dbo.AWT A
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
					WHEN A.PastAWT = 'No' THEN RIGHT(CONVERT(varchar,@Year),2)
					ELSE A.PastAWT + '-' + RIGHT(CONVERT(varchar,@Year),2) END
		FROM
			dbo.AWT A
		INNER JOIN
			#AWT_Manual_Qualifiers AWQ
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
	WHERE DS.PK_DSSet IS NOT NULL

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
GO

 