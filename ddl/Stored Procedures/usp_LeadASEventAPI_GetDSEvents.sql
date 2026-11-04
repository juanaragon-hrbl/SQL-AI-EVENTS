
CREATE PROCEDURE [dbo].[usp_LeadASEventAPI_GetDSEvents] 
			@DistributorID VARCHAR(10)					-- REQUIRED	       	
	       ,@Error         INT = 0			OUTPUT		-- OPTIONAL
	       ,@ErrorMessage  VARCHAR(4000) = '' OUTPUT	-- OPTIONAL
AS
BEGIN

/******************************************************************************
OBJECT:			usp_LeadASEventAPI_GetDSEvents

USE:	        EXEC usp_LeadASEventAPI_GetDSEvents '2222222222'

DESCRIPTION:

NOTES:			

VERSIONS
----------------------------------------------------------------------------------
1							Intitial
2	2019-11-04	NoeG		SRE Hardcode changed

******************************************************************************/

	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

-- DECLARE LOCAL VARIABLES

	DECLARE @StoredProcedure		VARCHAR(100),
	        @StartTime				DATETIME,	
	        @CountryID				INT,
	        @PeriodInMonths			SMALLINT,
	        @EventsAttended			INT,
	        @CorporateEventsAttended INT, 	        	        
	        @FromDate				DATETIME,
	        @COP					VARCHAR(2),
	        @IsRuleExistsForCountry INT,
	        @PK_Distributor			INT,
	        @SqlErrorMessage        VARCHAR(200),
	        @nMainID				int,
	        @IsPresTeam				bit 
			,@ValidDate DATETIME = '2049-12-31'

	SET @StoredProcedure = 'usp_LeadASEventAPI_GetDSEvents'
	SET @StartTime       = GETUTCDATE()
	SET @Error           = 0
	SET @ErrorMessage    = 'No Error.'
	SET @IsPresTeam		 = 0


BEGIN TRY


PRINT 'Check if the DistributorID passed is Valid'

	   IF ISNULL(@DistributorID, '') = '' OR LEN(@DistributorID) < 1 
       BEGIN  
            RAISERROR('Please enter valid DistributorID', 16,1)  
            RETURN(-1)  
       END 
       
PRINT 'Get Distributor Info' 
       
SELECT
	@PK_Distributor = DS.nDistributorID
	,@CountryID		= DS.nDistributorCOuntryProcessingID
	,@COP			= DS.sDistributorCountryProcessingCode
	,@IsPresTeam    = CASE WHEN DSS.nDistributorID IS NOT NULL THEN 1 ELSE 0 END
FROM
	dbo.v_Distributor DS 
LEFT JOIN
	dbo.v_DistributorSet DSS
ON
	DSS.nTypeLID = 2372
	AND
	DS.nDistributorID = DSS.nDistributorID
WHERE
	DS.sDistributorID = @DistributorID
	
SELECT
	@nMainID = nMainDistributorID
FROM
	dbo.v_DistributorAssociate2
WHERE
	sDistributorID = @DistributorID AND Transfer = 0 AND dThrough = @ValidDate
	
PRINT 'Check if the DistributorID exists in v_Distributor'

	   IF @PK_Distributor IS NULL
       BEGIN  
            SET @SqlErrorMessage = ('sDistributorID : ' +  CAST (@DistributorID AS VARCHAR(10)) + ' , does not exist in the view dbo.v_Distributor')
            RAISERROR(@SqlErrorMessage, 16,1)  
            RETURN(-1)  
       END       

PRINT 'Get the PeriodInMonths based on CountryID'

		SELECT 
			@PeriodInMonths =  PeriodInMonths
		  FROM dbo.LeadAssgnDSEventQual (NOLOCK)
		 WHERE PK_Country = @CountryID

PRINT '  -- PeriodInMonths :' + CAST(@PeriodInMonths AS VARCHAR(2))


PRINT 'Calculate the FromDate based on @PeriodInMonths'

       SET @FromDate = DATEADD(MM, -(@PeriodInMonths - 1), GETDATE())

       SET @FromDate = CAST(CAST(YEAR(@FromDate) * 10000 + MONTH(@FromDate) * 100 + 01 AS VARCHAR(8)) AS DATETIME)

PRINT '  -- @FromDate : ' + CONVERT(VARCHAR(25),@FromDate,120) 

IF OBJECT_ID('tempdb..#wrk_Assoc', 'U') IS NOT NULL DROP TABLE #wrk_Assoc

CREATE TABLE #wrk_Assoc
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	PK_Distributor		int,
	DistributorID		varchar(20)
)

-- Get DS and any association ID(s)
INSERT INTO #wrk_Assoc(PK_Distributor)
SELECT @PK_Distributor
UNION
SELECT nMainDistributorID FROM dbo.v_DistributorAssociate2 WHERE nMainDistributorID = @PK_Distributor AND Transfer = 1 AND dThrough = @ValidDate
UNION
SELECT nDistributorID FROM dbo.v_DistributorAssociate2 WHERE nMainDistributorID = @PK_Distributor AND Transfer = 1 AND dThrough = @ValidDate
UNION
SELECT nMainDistributorID FROM dbo.v_DistributorAssociate2 WHERE nDistributorID = @PK_Distributor AND Transfer = 1 AND dThrough = @ValidDate
UNION
SELECT nDistributorID FROM dbo.v_DistributorAssociate2 WHERE nDistributorID = @PK_Distributor AND Transfer = 1 AND dThrough = @ValidDate
UNION
SELECT nDistributorID FROM dbo.v_DistributorAssociate2 WHERE nMainDistributorID = @nMainID AND Transfer = 0 AND dThrough = @ValidDate

UPDATE 
	WK 
SET
	WK.DistributorID = DS.sDistributorID 
FROM
	#wrk_Assoc WK 
INNER JOIN
	dbo.v_Distributor DS
ON
	WK.PK_Distributor = DS.nDistributorID 
	

CREATE INDEX IX_#wrk_Assoc_PK_Distributor ON #wrk_Assoc(PK_Distributor)
CREATE INDEX IX_#wrk_Assoc_DistributorID ON #wrk_Assoc(DistributorID)

IF OBJECT_ID('tempdb..#wrk_EQ', 'U') IS NOT NULL DROP TABLE #wrk_EQ

CREATE TABLE #wrk_EQ
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	PK_Event			int,
	PK_Distributor		int
)

INSERT INTO #wrk_EQ (PK_Event,PK_Distributor)
SELECT DISTINCT PK_Event,EQ.PK_Distributor FROM dbo.EventQualifier EQ (NOLOCK)
				INNER JOIN #wrk_Assoc DA
			ON EQ.PK_Distributor = DA.PK_Distributor 

CREATE INDEX IX_#wrk_EQ_PK_Event ON #wrk_EQ(PK_Event)
CREATE INDEX IX_#wrk_EQ_PK_Distributor ON #wrk_EQ(PK_Distributor)

IF OBJECT_ID('tempdb..#wrk_ETA', 'U') IS NOT NULL DROP TABLE #wrk_ETA

CREATE TABLE #wrk_ETA
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	PK_Event				int,
	PK_ToDistributor		int,
	ValidToDateUTC			datetime
)
		
INSERT INTO #wrk_ETA(PK_Event,PK_ToDistributor,ValidToDateUTC)	
SELECT DISTINCT PK_Event, PK_ToDistributor, ValidToDateUTC FROM dbo.EventTicketAssignment ETA (NOLOCK)
				INNER JOIN #wrk_Assoc DA
			ON ETA.PK_ToDistributor = DA.PK_Distributor 
WHERE ETA.ValidToDateUTC = @ValidDate	
			
CREATE INDEX IX_#wrk_ETA_PK_Event ON #wrk_ETA(PK_Event)
CREATE INDEX IX_#wrk_ETA_PK_ToDistributor ON #wrk_ETA(PK_ToDistributor)

IF OBJECT_ID('tempdb..#wrk_CNT', 'U') IS NOT NULL DROP TABLE #wrk_CNT

CREATE TABLE #wrk_CNT
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	PK_Event				int,
	CNT						int
)

INSERT #wrk_CNT(PK_Event, CNT)
SELECT PK_Event,COUNT(1) AS nCnt 
			 FROM dbo.EventsRegistration (NOLOCK)
			 GROUP BY PK_Event
			 HAVING COUNT(1) > 10
			 
CREATE INDEX IX_#wrk_CNT_PK_Event ON #wrk_CNT(PK_Event) INCLUDE ([CNT])

IF OBJECT_ID('tempdb..#wrk_LER', 'U') IS NOT NULL DROP TABLE #wrk_LER

CREATE TABLE #wrk_LER
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	PK_EventType				int,
	PK_Event					int,
	PK_Distributor				int,
	PK_LeadEvent				int
) 

INSERT INTO #wrk_LER(PK_EventType,PK_Event,PK_Distributor,PK_LeadEvent)			 
SELECT DISTINCT LE.PK_EventType, LE.PK_Event, LE.PK_Distributor, LE.PK_LeadEvent
			 FROM dbo.LeadEventsRegistration LE (NOLOCK)
			 INNER JOIN #wrk_Assoc DA
			 ON LE.PK_Distributor = DA.PK_Distributor  
			 
CREATE INDEX IX_#wrk_LER_PK_EventType ON #wrk_LER(PK_EventType)
CREATE INDEX IX_#wrk_LER_PK_Event ON #wrk_LER(PK_Event)
CREATE INDEX IX_#wrk_LER_PK_Distributor ON #wrk_LER(PK_Distributor)
CREATE INDEX IX_#wrk_LER_PK_LeadEvent ON #wrk_LER(PK_LeadEvent)

IF OBJECT_ID('tempdb..#wrk_EER', 'U') IS NOT NULL DROP TABLE #wrk_EER

CREATE TABLE #wrk_EER
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	PK_Event				int,
	PK_Distributor			int,
	HasCheckedIn			int
) 

INSERT INTO #wrk_EER(PK_Event,PK_Distributor,HasCheckedIn)			 
SELECT DISTINCT PK_Event,ER.PK_Distributor,HasCheckedIn FROM dbo.EventsRegistration ER (NOLOCK)
					INNER JOIN #wrk_Assoc DA
					ON ER.PK_Distributor = DA.PK_Distributor 
					
CREATE INDEX IX_#wrk_EER_PK_Event ON #wrk_EER(PK_Event)
CREATE INDEX IX_#wrk_EER_PK_Distributor ON #wrk_EER(PK_Distributor)
CREATE INDEX IX_#wrk_EER_HasCheckedIn ON #wrk_EER(HasCheckedIn)

			
IF OBJECT_ID('tempdb..#wrk_LERD', 'U') IS NOT NULL DROP TABLE #wrk_LERD

CREATE TABLE #wrk_LERD
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	PK_EventType				int,
	PK_Event					int,
	PK_Distributor				int,
	EventDate					datetime,
	CreatedBy					varchar(30)
) 

INSERT INTO #wrk_LERD(EventDate,PK_EventType,PK_Event,PK_Distributor,CreatedBy)			 
SELECT DISTINCT LE.EventDate, LE.PK_EventType, LE.PK_Event, LE.PK_Distributor, LE.CreatedBy 
		 FROM dbo.LeadEventsRegistration LE (NOLOCK)
		 INNER JOIN #wrk_Assoc DA
		 ON LE.PK_Distributor = DA.PK_Distributor 
			 
CREATE INDEX IX_#wrk_LERD_PK_EventType ON #wrk_LERD(PK_EventType)
CREATE INDEX IX_#wrk_LERD_PK_Event ON #wrk_LERD(PK_Event)
CREATE INDEX IX_#wrk_LERD_PK_Distributor ON #wrk_LERD(PK_Distributor)
CREATE INDEX IX_#wrk_LERD_EventDate ON #wrk_LERD(EventDate)	
CREATE INDEX IX_#wrk_LERD_CreatedBy ON #wrk_LERD(CreatedBy)


IF OBJECT_ID('tempdb..#wrk_DSReg', 'U') IS NOT NULL DROP TABLE #wrk_DSReg

CREATE TABLE #wrk_DSReg
(
	PK int IDENTITY(1,1) PRIMARY KEY,
	PK_Event					int,
	PK_Distributor				int,
	HasCheckedIn				int
) 

INSERT INTO #wrk_DSReg(PK_Event,PK_Distributor,HasCheckedIn)
SELECT DISTINCT PK_Event,ER.PK_Distributor,HasCheckedIn 
FROM dbo.EventsRegistration ER (NOLOCK)
INNER JOIN #wrk_Assoc DA ON ER.PK_Distributor = DA.PK_Distributor 

CREATE INDEX IX_#wrk_DSReg_PK_Event ON #wrk_DSReg(PK_Event)
CREATE INDEX IX_#wrk_DSReg_PK_Distributor ON #wrk_DSReg(PK_Distributor) 
CREATE INDEX IX_#wrk_DSReg_HasCheckedIn ON #wrk_DSReg(HasCheckedIn)  


PRINT 'Display EventDate,EventName,EventCity,COP For the DistributorID ' + @DistributorID

		SELECT  E.dStartUTC AS EventDate,
				E.EventName AS EventName, 
				E.EventCity AS EventCity,
				E.Location  AS EventLocation,
				@COP AS COP,
			    CASE WHEN @PeriodInMonths IS NULL THEN 0 ELSE 1 END AS IsRuleExistsForCountry,
			    ET.PK_EventType AS PK_EventType,
			    'CREG' AS EventClass,
			    1 AS Qualify,
			    1 AS Attend,
			    E.PK_Event,
			    NULL AS PK_LeadEvent	    
		FROM dbo.EventType ET (NOLOCK)
		INNER JOIN dbo.Event E (NOLOCK) ON ET.PK_EventType = E.PK_EventType
		INNER JOIN #wrk_DSReg ER ON E.PK_Event = ER.PK_Event 
		INNER JOIN #wrk_Assoc DA ON ER.PK_Distributor = DA.PK_Distributor 
		WHERE ET.EventTypeCode IN ('CE','CP','CR') 
		AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()  
		AND ER.HasCheckedIn = 1
		UNION ALL
		SELECT 
				E.dStartUTC AS EventDate,
				E.EventName AS EventName,
				E.EventCity AS EventCity,
				E.Location  AS EventLocation,
				@COP AS COP,
				CASE WHEN @PeriodInMonths IS NULL THEN 0 ELSE 1 END AS IsRuleExistsForCountry,
				ET.PK_EventType AS PK_EventType,
				'CNOREG' AS EventClass,
				COUNT(1) AS Qualify,
				CASE WHEN LE.PK_Distributor IS NOT NULL THEN 1 ELSE 0 END AS Attend,
				E.PK_Event,
			    LE.PK_LeadEvent AS PK_LeadEvent
		FROM 
			dbo.Event E (NOLOCK)
		INNER JOIN
			dbo.EventType ET (nolock)
		ON
			E.PK_EventType = ET.PK_EventType
			AND
			ET.EventTypeCode IN ('CE','CP','CR')
		INNER JOIN
			#wrk_EQ EQ
		ON
			E.PK_Event = EQ.PK_Event
		INNER JOIN
			#wrk_ETA ETA
		ON
			ETA.PK_Event = E.PK_Event
			AND
			ETA.PK_ToDistributor = EQ.PK_Distributor
			AND
			ETA.ValidToDateUTC = @ValidDate
		INNER JOIN
			#wrk_Assoc DA ON EQ.PK_Distributor = DA.PK_Distributor 
		LEFT JOIN
			#wrk_CNT ER
		ON
			ER.PK_Event = E.PK_Event
		LEFT JOIN
			#wrk_LER LE
		ON
			LE.PK_EventType = E.PK_EventType
			AND
			LE.PK_Event = EQ.PK_Event
			AND
			LE.PK_Distributor = DA.PK_Distributor 
		WHERE
			EQ.PK_Distributor = DA.PK_Distributor 
			AND
			ER.PK_Event IS NULL
			AND
			E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()  
		GROUP BY
			E.dStartUTC,
				E.EventName,
				E.EventCity,
				E.Location,
				CASE WHEN LE.PK_Distributor IS NOT NULL THEN 1 ELSE 0 END,
				ET.PK_EventType,
				E.PK_Event,
			    LE.PK_LeadEvent
		UNION ALL
		SELECT  DISTINCT 
				E.EventDate AS EventDate,
				E.EventName AS EventName, 
				E.EventCity AS EventCity,
				E.Location  AS EventLocation,
				@COP AS COP,
				CASE WHEN @PeriodInMonths IS NULL THEN 0 ELSE 1 END AS IsRuleExistsForCountry,
				ET.PK_EventType AS PK_EventType,
				'WriteIn' AS EventClass,
			    1 AS Qualify,
			    1 AS Attend,
			    E.PK_Event,
			    E.PK_LeadEvent AS PK_LeadEvent
		FROM dbo.EventType ET (NOLOCK)
		INNER JOIN dbo.LeadEventsRegistration E (NOLOCK) ON ET.PK_EventType = E.PK_EventType 
		INNER JOIN #wrk_Assoc DA
		ON E.CreatedBy = DA.DistributorID 
		WHERE ET.EventTypeCode = 'LA'
		AND E.EventDate > = @FromDate AND E.EventDate < = GETDATE()
  		ORDER BY 1 DESC

PRINT 'Get the number of Coprorate Events attended by the DistributorID ' + @DistributorID

SELECT  @CorporateEventsAttended = SUM(nCnt) 
	FROM
	(SELECT COUNT(1) AS nCnt
FROM
(SELECT DISTINCT E.PK_Event 
		FROM dbo.EventType ET (NOLOCK)
		INNER JOIN dbo.Event E (NOLOCK) ON ET.PK_EventType = E.PK_EventType
		INNER JOIN #wrk_EER ER  ON E.PK_Event = ER.PK_Event
		INNER JOIN #wrk_Assoc DA ON ER.PK_Distributor = DA.PK_Distributor 
		WHERE ET.EventTypeCode IN ('CE','CP','CR')
		AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()
		AND ER.HasCheckedIn = 1 
        UNION
        SELECT DISTINCT E.PK_Event 
		FROM dbo.EventType ET (NOLOCK)
		INNER JOIN dbo.Event E (NOLOCK) ON ET.PK_EventType = E.PK_EventType
		INNER JOIN #wrk_EER ER 	ON E.PK_Event = ER.PK_Event
		INNER JOIN #wrk_Assoc DA ON ER.PK_Distributor = DA.PK_Distributor 
		WHERE ET.EventTypeCode IN ('CE','CP','CR')
		AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()
		AND ER.HasCheckedIn = 1 
		UNION
        SELECT DISTINCT E.PK_Event 
		FROM dbo.EventType ET (NOLOCK)
		INNER JOIN dbo.Event E (NOLOCK)  ON ET.PK_EventType = E.PK_EventType
		INNER JOIN dbo.EventsRegistration ER (NOLOCK) ON E.PK_Event = ER.PK_Event
		INNER JOIN #wrk_Assoc DA ON ER.PK_Distributor = DA.PK_Distributor 
		WHERE ET.EventTypeCode IN ('CE','CP','CR')
		AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()
		AND ER.HasCheckedIn = 1
) TOT
	UNION ALL
		SELECT 
				COUNT(1) AS nCnt
		FROM 
			dbo.Event E (NOLOCK)
		INNER JOIN
			dbo.EventType ET (nolock)
		ON
			E.PK_EventType = ET.PK_EventType
			AND
			ET.EventTypeCode IN ('CE','CP','CR')
		INNER JOIN
			dbo.EventQualifier EQ (NOLOCK)
		ON
			E.PK_Event = EQ.PK_Event
		INNER JOIN
			#wrk_ETA ETA
		ON
			ETA.PK_Event = E.PK_Event
			AND
			ETA.PK_ToDistributor = EQ.PK_Distributor
			AND
			ETA.ValidToDateUTC = @ValidDate
		LEFT JOIN 
			#wrk_Assoc DA
		ON
			EQ.PK_Distributor = DA.PK_Distributor 
		LEFT JOIN
			#wrk_CNT ER
		ON
			ER.PK_Event = E.PK_Event
		LEFT JOIN
			#wrk_LER LE
		ON
			LE.PK_EventType = E.PK_EventType
			AND
			LE.PK_Event = EQ.PK_Event
			AND
			LE.PK_Distributor = CASE WHEN DA.PK_Distributor IS NOT NULL THEN DA.PK_Distributor ELSE EQ.PK_Distributor END 
		WHERE
			ER.PK_Event IS NULL
			AND
			E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()  
		GROUP BY
			E.dStartUTC,
				E.EventName,
				E.EventCity,
				E.Location,
				CASE WHEN LE.PK_Distributor IS NOT NULL THEN 1 ELSE 0 END,
				ET.PK_EventType,
				E.PK_Event,
			    LE.PK_LeadEvent ) CORP
		

PRINT 'Get the number of Events attended by the DistributorID ' + @DistributorID

SELECT @EventsAttended = SUM(nCnt)  
FROM (
		SELECT COUNT(1) AS nCnt
FROM
(SELECT DISTINCT E.PK_Event 
		FROM dbo.EventType ET (NOLOCK)
		INNER JOIN dbo.Event E (NOLOCK) ON ET.PK_EventType = E.PK_EventType
		INNER JOIN #wrk_EER ER ON E.PK_Event = ER.PK_Event
		INNER JOIN #wrk_Assoc DA ON ER.PK_Distributor = DA.PK_Distributor 
		WHERE ET.EventTypeCode IN ('CE','CP','CR')
		AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()
		AND ER.HasCheckedIn = 1 
        UNION
        SELECT DISTINCT E.PK_Event 
		FROM dbo.EventType ET (NOLOCK)
		INNER JOIN dbo.Event E (NOLOCK) ON ET.PK_EventType = E.PK_EventType
		INNER JOIN #wrk_EER ER ON E.PK_Event = ER.PK_Event
		INNER JOIN #wrk_Assoc DA ON ER.PK_Distributor = DA.PK_Distributor 
		WHERE ET.EventTypeCode IN ('CE','CP','CR')
		AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()
		AND ER.HasCheckedIn = 1 
		UNION
        SELECT DISTINCT E.PK_Event 
		FROM dbo.EventType ET (NOLOCK)
		INNER JOIN dbo.Event E (NOLOCK)  ON ET.PK_EventType = E.PK_EventType
		INNER JOIN dbo.EventsRegistration ER (NOLOCK) ON E.PK_Event = ER.PK_Event
		INNER JOIN #wrk_Assoc DA ON ER.PK_Distributor = DA.PK_Distributor 
		WHERE ET.EventTypeCode IN ('CE','CP','CR')
		AND E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()
		AND ER.HasCheckedIn = 1
) TOT
		UNION ALL
		SELECT 
				COUNT(1) AS nCnt
		FROM 
			dbo.Event E (NOLOCK)
		INNER JOIN
			dbo.EventType ET (nolock)
		ON
			E.PK_EventType = ET.PK_EventType
			AND
			ET.EventTypeCode IN ('CE','CP','CR')
		INNER JOIN
			dbo.EventQualifier EQ (NOLOCK)
		ON
			E.PK_Event = EQ.PK_Event
		INNER JOIN
			#wrk_ETA ETA
		ON
			ETA.PK_Event = E.PK_Event
			AND
			ETA.PK_ToDistributor = EQ.PK_Distributor
			AND
			ETA.ValidToDateUTC = @ValidDate
		LEFT JOIN 
			#wrk_Assoc DA
		ON
			EQ.PK_Distributor = DA.PK_Distributor 
		LEFT JOIN
			#wrk_CNT ER
		ON
			ER.PK_Event = E.PK_Event
		LEFT JOIN
			#wrk_LER LE
		ON
			LE.PK_EventType = E.PK_EventType
			AND
			LE.PK_Event = EQ.PK_Event
			AND
			LE.PK_Distributor = CASE WHEN DA.PK_Distributor IS NOT NULL THEN DA.PK_Distributor ELSE EQ.PK_Distributor END 
		WHERE
			ER.PK_Event IS NULL
			AND
			E.dStartUTC > = @FromDate AND E.dStartUTC < = GETDATE()  
		GROUP BY
			E.dStartUTC,
				E.EventName,
				E.EventCity,
				E.Location,
				CASE WHEN LE.PK_Distributor IS NOT NULL THEN 1 ELSE 0 END,
				ET.PK_EventType,
				E.PK_Event,
			    LE.PK_LeadEvent
		UNION ALL
		SELECT  COUNT(1) AS nCnt	
		FROM dbo.EventType ET (NOLOCK)
		INNER JOIN #wrk_LERD E ON ET.PK_EventType = E.PK_EventType  
		INNER JOIN #wrk_Assoc DA ON E.PK_Distributor = DA.PK_Distributor 
		WHERE ET.EventTypeCode = 'LA'
		AND E.CreatedBy = DA.DistributorID 
		AND E.EventDate > = @FromDate AND E.EventDate < = GETDATE()
  	) AS A
	
PRINT '  -- EventsAttended :' + CAST(@EventsAttended AS VARCHAR(5))

PRINT 'Check if the DistributorID ' + @DistributorID	+ ' is qualified'

      SELECT CASE WHEN @IsPresTeam = 0 THEN @EventsAttended 
				  WHEN @IsPresTeam = 1 AND @EventsAttended >= MinEventCount THEN @EventsAttended 
				  WHEN @IsPresTeam = 1 AND @EventsAttended < MinEventCount THEN MinEventCount END AS EventsAttended,
			 CASE WHEN @IsPresTeam = 0 THEN @CorporateEventsAttended 
				  WHEN @IsPresTeam = 1 AND @CorporateEventsAttended >= 2 THEN @CorporateEventsAttended 
				  WHEN @IsPresTeam = 1 AND @CorporateEventsAttended < 2 THEN 2 END AS CorporateEventsAttended,
			 MinEventCount   AS MinimumEventsRequired,
             CASE WHEN @IsPresTeam = 0 THEN (@EventsAttended - MinEventCount) 
                  WHEN @IsPresTeam = 1 AND (@EventsAttended - MinEventCount) > 0 THEN (@EventsAttended - MinEventCount) 
                  WHEN @IsPresTeam = 1 AND (@EventsAttended - MinEventCount) <= 0 THEN 1 END AS EventQualifier,
             CASE WHEN @IsPresTeam = 1 THEN 0
                  WHEN @IsPresTeam = 0 AND (@EventsAttended - MinEventCount) < 0  THEN ABS(@EventsAttended - MinEventCount) 
             ELSE 0 END AS EventsNeeded,
             CountryCode
        FROM dbo.LeadAssgnDSEventQual (NOLOCK)      
       WHERE PK_Country = @CountryID    
              

PRINT 'Done'
END TRY

BEGIN CATCH

		SET @Error = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @StoredProcedure = ERROR_PROCEDURE()
		-- Update ErrorLog
		EXEC dbo.usp_Utility_UpdateErrorLog 
				 @ProcedureName = @StoredProcedure
				,@ErrorNumber  = 3
				,@ErrorMessage = @ErrorMessage OUTPUT
				,@SQLErrorCode = @Error
				,@SQLErrorMsg  = @ErrorMessage
		RETURN 
		
END CATCH

-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	 @StoredProcedureName = @StoredProcedure
	,@StartTime           = @StartTime

END