CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_CustomTrackingPage_NAMVacation20001]
	-- Mandatory parameters
	 @PK_Event INT
	,@LocaleCode CHAR(5) = 'en-US'
	-- Optional Parameters
	,@DistributorID VARCHAR(10) 

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN 
/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMVacation20001

USE:	        
			DECLARE @e int, @em varchar(4000)

                 EXEC dbo.usp_MyHLEventAPI_CustomTrackingPage_NAMVacation20001
					 	 @DistributorID = N'2222222222'
					 	,@PK_Event = 23506
						,@LocaleCode = 'en-US'
						,@Error = @e OUTPUT
						,@ErrorMessage = @em OUTPUT
						,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Tracker for NAM Regional and President Vacations

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------

dbo.v_aggFQS_ID, 

VERSIONS
----------------------------------------------------------------------------------
1	2018-11-23	JoseB			Intitial
2	2019-07-15	alejandramed	Setting error parameters as optionals
3	2019-08-14		NoeG		Refactor code (SRE)

******************************************************************************/

DECLARE @PK_Event_NAMPTVacation2020 INT  = 23506
		,@PK_event_NAMRegionalVacation2020 INT  =  23508
		,@dThrough DATETIME = '2049-12-31'


	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	DECLARE @PK_Distributor INT
	
	BEGIN TRY

		SELECT @PK_Distributor = nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID

		IF OBJECT_ID('tempdb..#Temp') IS NOT NULL DROP TABLE #Temp
		IF OBJECT_ID('tempdb..#Associated') IS NOT NULL DROP TABLE #Associated
		IF OBJECT_ID('tempdb..#EventsAttended') IS NOT NULL DROP TABLE #EventsAttended

		CREATE TABLE #Temp
		(
			DistributorID VARCHAR(30),
			PK_Distributor INT,
			TotalEvents INT
		)

		CREATE TABLE #Associated
		(
			PK int IDENTITY(1,1) PRIMARY KEY,
			nMainAssociatedID INT,
			PK_Distributor INT,
			TotalEvents INT DEFAULT 0
		)

		CREATE TABLE #EventsAttended
		(
		DistributorID VARCHAR(20),
		PK_Distributor INT,
		EventID INT

		)
		-- GET ASSOCIATIONS IDs
		INSERT INTO #Associated(nMainAssociatedID,PK_Distributor)
		SELECT nMainDistributorID,nDistributorID
		FROM dbo.v_DistributorAssociate2 
		WHERE nMainDistributorID IN (
		SELECT DISTINCT nMainDistributorID 
		FROM   dbo.v_DistributorAssociate2 A 
		INNER JOIN dbo.v_Distributor D
		ON A.nMainDistributorID = D.nDistributorID
		INNER JOIN	dbo.v_Countries C
		ON D.nDistributorCountryProcessingID = C.nCountryID
		--AND (C.sRegionCode = 'EU' OR C.sCountryCode IN ('CO','BR'))
		WHERE  dThrough = @dThrough
		AND Transfer = 0
		AND A.nDistributorID = @PK_Distributor
		GROUP BY nMainDistributorID
		/*HAVING COUNT(1) >= 3*/) AND nMainDistributorID <> nDistributorID AND dThrough = @dThrough

		CREATE INDEX IX_#Associated_nMainAssociatedID ON #Associated(nMainAssociatedID)
		CREATE INDEX IX_#Associated_nDistributorID ON #Associated(PK_Distributor)

		INSERT  #Temp
		(
			DistributorID,
			PK_Distributor,
			TotalEvents
		)
		SELECT DistributorID,PK_Distributor, COUNT(1)
		FROM
		(
		SELECT ER.DistributorID,ER.PK_Distributor
		FROM 
			dbo.EventsRegistration ER WITH (NOLOCK)
		INNER JOIN dbo.WRK_NAMVacationEventList EL WITH (NOLOCK)
		ON
			ER.PK_Event = EL.EventID
			AND EL.EType = 'E'
			AND EL.PK_Event = @PK_Event
		WHERE 
			HasCheckedIn = 1 
			AND
			ER.PK_Distributor = @PK_Distributor

	
		UNION ALL

		SELECT 
			S.DistributorID,S.nDistributorID AS PK_Distributor
		FROM
		dbo.v_DistributorSet S
		INNER JOIN dbo.WRK_NAMVacationEventList EL WITH (NOLOCK)
		ON
			S.nTypeLID = EL.EventID
			AND EL.EType = 'L'
			AND EL.PK_Event = @PK_Event
		INNER JOIN dbo.v_Distributor D
		ON S.nDistributorID = D.nDistributorID
		AND S.dThrough = @dThrough
		WHERE
			S.nDistributorID = @PK_Distributor
		) AS X
		GROUP BY DistributorID,PK_Distributor

		UPDATE
			A
		SET
			A.TotalEvents = D.TotalEvents
		FROM
			#Associated A
		INNER JOIN
			#Temp D
		ON
			A.nMainAssociatedID = D.PK_Distributor


		UPDATE
			D
		SET
			D.TotalEvents = D.TotalEvents + A.TotalEvents
		FROM
			#Temp D
		INNER JOIN
			#Associated A
		ON
			A.PK_Distributor = D.PK_Distributor

		--SELECT * FROM #Temp WHERE TotalEvents >= 4

		INSERT INTO #EventsAttended (DistributorID, PK_Distributor, EventID)

		SELECT DISTINCT 
			ER.DistributorID,
			ER.PK_Distributor,
			ER.PK_Event AS EventID 
		FROM 
			dbo.EventsRegistration ER WITH (NOLOCK)
		INNER JOIN dbo.WRK_NAMVacationEventList EL WITH (NOLOCK)
		ON
			ER.PK_Event = EL.EventID
			AND EL.EType = 'E'
			AND EL.PK_Event = @PK_Event
		WHERE 
			HasCheckedIn = 1 
			AND
			ER.PK_Distributor = @PK_Distributor

		UNION ALL

		SELECT
			S.DistributorID,
			S.nDistributorID AS PK_Distributor,
			EL.EventID
		FROM
		dbo.v_DistributorSet S
		INNER JOIN dbo.WRK_NAMVacationEventList EL WITH (NOLOCK)
		ON
			S.nTypeLID = EL.EventID
			AND EL.EType = 'L'
			AND EL.PK_Event = @PK_Event
		AND S.dThrough = @dThrough
		WHERE
			S.nDistributorID = @PK_Distributor



		--SELECT * FROM #EventsAttended 

		SELECT 
 				DistributorID
				,PK_Distributor
				,MetricType
				,SUM(CASE WHEN RoyaltyMonth = '2019-01-01' THEN Points ELSE 0 END) AS JanPoints
				,SUM(CASE WHEN RoyaltyMonth = '2019-02-01' THEN Points ELSE 0 END) AS FebPoints
				,SUM(CASE WHEN RoyaltyMonth = '2019-03-01' THEN Points ELSE 0 END) AS MarPoints
				,SUM(CASE WHEN RoyaltyMonth = '2019-04-01' THEN Points ELSE 0 END) AS AprPoints
				,SUM(CASE WHEN RoyaltyMonth = '2019-05-01' THEN Points ELSE 0 END) AS MayPoints
				,SUM(CASE WHEN RoyaltyMonth = '2019-06-01' THEN Points ELSE 0 END) AS JunPoints
				,SUM(CASE WHEN RoyaltyMonth = '2019-07-01' THEN Points ELSE 0 END) AS JulPoints
				,SUM(CASE WHEN RoyaltyMonth = '2019-08-01' THEN Points ELSE 0 END) AS AugPoints
				,SUM(CASE WHEN RoyaltyMonth = '2019-09-01' THEN Points ELSE 0 END) AS SepPoints
				,SUM(CASE WHEN RoyaltyMonth = '2019-10-01' THEN Points ELSE 0 END) AS OctPoints
				,SUM(CASE WHEN RoyaltyMonth = '2019-11-01' THEN Points ELSE 0 END) AS NovPoints
				,SUM(CASE WHEN RoyaltyMonth = '2019-12-01' THEN Points ELSE 0 END) AS DecPoints
		FROM(
			SELECT 
				'2019-01-01' AS RoyaltyMonth
				,@DistributorID AS DistributorID
				,@PK_Distributor AS PK_Distributor
				,0 AS TV
				,0 AS RO
				,0 AS VP
	
			UNION ALL
	
			SELECT 
				a.dRoyaltyMonth AS RoyaltyMonth
				,a.DistributorID
				,a.PK_Distributor
				,a.TV
				,a.RO
				,a.VP
			FROM 
		  (
		  SELECT
			@DistributorID AS DistributorID,
			PK_Distributor,
			dRoyaltyMonth,
			SPQualDate,
			QSQualDate,
			CountryCode,
			TV,
			RO,
			VP
		  FROM	dbo.WRK_NAMPTVacation2020Points WITH (NOLOCK)
		  WHERE
			@PK_Event = @PK_Event_NAMPTVacation2020
			AND
			PK_Distributor = @PK_Distributor
 
		  UNION ALL
 
		  SELECT
			@DistributorID AS DistributorID,
			PK_Distributor,
			dRoyaltyMonth,
			SPQualDate,
			QSQualDate,
			CountryCode,
			TV,
			RO,
			VP
		  FROM	dbo.WRK_NAMRegionalVacation2020Points WITH (NOLOCK)
		  WHERE
			@PK_Event = @PK_event_NAMRegionalVacation2020
			AND
			PK_Distributor = @PK_Distributor
		  ) AS a

			) P
			UNPIVOT 
			(
				Points FOR MetricType IN (TV,RO,VP)

			) AS unpvt
			GROUP BY DistributorID, PK_Distributor,MetricType
			ORDER BY DistributorID, PK_Distributor,MetricType

		SELECT
			DistributorID,
			PK_Distributor,
			SUM(TotalEvents) AS TotalEvents
		FROM(
			SELECT
				@DistributorID AS DistributorID,
				@PK_Distributor AS PK_Distributor,
				0 AS TotalEvents
	
			UNION ALL
	
			SELECT 
				DistributorID,
				PK_Distributor,
				COUNT(1) AS TotalEvents
			FROM #EventsAttended 
			GROUP BY
				DistributorID, PK_Distributor
		) AS X
		GROUP BY DistributorID, PK_Distributor

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
	END CATCH

END
GO

