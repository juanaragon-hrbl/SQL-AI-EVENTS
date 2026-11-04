CREATE PROCEDURE [dbo].[usp_Event_EventsRegistrationReport] 
	   @IsDevQA		BIT = 0,   
	   @Error	int = 0 OUTPUT,
	   @ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN

--****************************************************************************************
--   OBJECT NAME   : usp_Event_EventsRegistrationReport
--   MSSQL VERSION : SQL 2008
--   SERVER NAME   : BIPRODRPT
--   DATABASE NAME : EventManagement
--   PURPOSE       : To build Onsite Registration report table for Microstragy Reporting. 
--                   This is also to replace writing the sql scripts to generate the reports.
--                   This runs every day to capture the onsite registration information for active events. 
--                   History of the previous events is not stored.
--   INPUT PARAMS  : NONE
--   EXECUTE STATEMENT:  EXEC dbo.usp_Event_EventsRegistrationReport
--   VERSION HISTORY:
--   DATE       	DEVELOPER           		COMMENTS
--   ========   	=========          			========
--   08-Dec-2014     Sandhya Pendyala            Removed COP from Insert
--   15-Sep-2014    Sandhya Pendyala            Alter DRComments column length to nVARCHAR(MAX)
--   09-Nov-2011    Sandhya Pendyala            Build EventsRegistrationReport
--	 04-Nov-2019	NoeG						SRE Hardcode changed
--	 21-Sep-2021	SushmaA						Error handling + system exception fixed

--****************************************************************************************	

DECLARE @ValidDate DATETIME = '2049-12-31'

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

/******************************************************************************
	Create OnisteReg  table
******************************************************************************/

DECLARE @EventsRegistrationReport TABLE (
	DistributorID VARCHAR(900)
	,PK_Distributor INT
	,PK_Event INT
	,DSName VARCHAR(1000)
	,DSType VARCHAR(10) DEFAULT ''
	,IsPartnerAttending VARCHAR(10) DEFAULT 'N'
	,PartnerName VARCHAR(300) DEFAULT ''
	,DSTeam VARCHAR(1000)
	,Address1 VARCHAR(200)
	,Address2 VARCHAR(200)
	,City VARCHAR(50)
	,[State] VARCHAR(200)
	,MailingCountry VARCHAR(1000)  DEFAULT ''
	,PostalCode VARCHAR(50)  DEFAULT ''
	,COP VARCHAR(10)  DEFAULT ''
	,PrimaryLanguage VARCHAR(255)  DEFAULT ''
	,Email VARCHAR(150)  DEFAULT ''
	,DayPhone VARCHAR(255)
	,TicketsPurchased INT DEFAULT 0
	,CurrentEventTickets INT DEFAULT 0
	,DRComments nVARCHAR(MAX)  DEFAULT ''
	,RegistrationDate VARCHAR(50)
	,RegisteredBy VARCHAR(300)
	,UNIQUE(PK_Event, PK_Distributor)
)

BEGIN TRY	
/******************************************************************************
	Data from EventRegistration Table
******************************************************************************/

;WITH MinE (PK_Event, PK_EventsRegistration, PK_Distributor) AS
(
	SELECT 
		ER.PK_Event
		,MIN(ER.PK_EventsRegistration)
		,ER.PK_Distributor 
	FROM 
		dbo.EventsRegistration ER WITH (NOLOCK)
		INNER JOIN
		dbo.v_EventOnSiteReportToUpdate CE WITH (NOLOCK)
		ON
			CE.PK_Event = ER.PK_Event
	WHERE 
		ER.Registered = 1
	GROUP BY 
		ER.PK_Event, ER.PK_Distributor
)
INSERT 
	@EventsRegistrationReport
(
	DistributorID
	,PK_Distributor
	,PK_Event
	,DSName
	,DSTeam
	,Address1 
	,Address2 
	,City 
	,[State] 
	,PostalCode 
	--,COP 
	,DayPhone
	,RegistrationDate	
	,RegisteredBy
)
SELECT    
	E.DistributorID
	,E.PK_Distributor
	,E.PK_Event
	,RTRIM(COALESCE(E.LastName,'')) + ' ' + RTRIM(COALESCE(E.FirstName,''))
	,COALESCE(E.DistributorTeam,'')
	,COALESCE(E.AddressLine1,'')
	,COALESCE(E.AddressLine2,'')
	,COALESCE(E.City,'')
	,COALESCE(E.State,'')
	,COALESCE(E.ZipCode,'')
	--,COALESCE(E.Country,'')
	,COALESCE(E.Phones,'')
	,CONVERT(VARCHAR(10),E.CreatedDateUTC,120) AS RegisteredDate	
	,COALESCE(E.CreatedBy,'')	
FROM
	dbo.EventsRegistration E WITH (NOLOCK)
INNER JOIN
	MinE
	ON
		E.PK_Event = MinE.PK_Event
		AND E.PK_EventsRegistration = MinE.PK_EventsRegistration
		And E.PK_Distributor = MinE.PK_Distributor


/******************************************************************************
	Update PartnerAttending
******************************************************************************/
IF OBJECT_ID('tempdb..#PartnerYN') IS NOT NULL  DROP TABLE #PartnerYN


SELECT 
	PK_Event
	,PK_Distributor
	,CASE WHEN COUNT(*) > 1 THEN 'Y' ELSE 'N' END AS IsPartnerAttending
INTO 
	#PartnerYN		
FROM 
	dbo.EventsRegistration WITH (NOLOCK)	
GROUP BY 
	PK_Event, PK_Distributor
	
CREATE INDEX IX_PK_Event ON #PartnerYN(PK_Event)
CREATE INDEX IX_PK_Distributor ON #PartnerYN(PK_Distributor)
CREATE INDEX IX_IsPartnerAttending ON #PartnerYN(IsPartnerAttending)


IF OBJECT_ID('tempdb..#GetPartnerName') IS NOT NULL  DROP TABLE #GetPartnerName

SELECT 
	E.PK_Event
	,E.PK_Distributor
	,E.FirstName + ' ' + E.LastName AS PartnerName
INTO
	#GetPartnerName	
FROM 
	dbo.EventsRegistration E WITH (NOLOCK)
WHERE
	PK_EventsRegistration IN (SELECT 
									MAX(ER.PK_EventsRegistration)
							  FROM
									dbo.EventsRegistration ER WITH (NOLOCK)
							  INNER JOIN
									#PartnerYN P	
							  ON
									ER.PK_Distributor = P.PK_Distributor
									AND
									ER.PK_Event = P.PK_Event
							  WHERE
									P.IsPartnerAttending = 'Y'
							  GROUP BY 
									ER.PK_Event, ER.PK_Distributor)

CREATE INDEX IX_PK_Event ON #GetPartnerName(PK_Event)
CREATE INDEX IX_PK_Distributor ON #GetPartnerName(PK_Distributor)
CREATE INDEX IX_PartnerName ON #GetPartnerName(PartnerName)


UPDATE 
	R
SET  
	IsPartnerAttending = P.IsPartnerAttending
	,PartnerName = GP.PartnerName 
FROM 
	@EventsRegistrationReport R
INNER JOIN 
	#PartnerYN P
ON 
	R.PK_Distributor = P.PK_Distributor
	AND
	R.PK_Event = P.PK_Event
INNER JOIN
	#GetPartnerName GP
ON
	R.PK_Distributor = GP.PK_Distributor
	AND
	R.PK_Event = GP.PK_Event

/******************************************************************************
	Update DSType
******************************************************************************/

UPDATE 
	R
SET 
	DSType = D.sType            
FROM 
	@EventsRegistrationReport R
INNER JOIN 
	dbo.v_Distributor D WITH (NOLOCK)
	ON 
		R.PK_Distributor = D.nDistributorID


/*  Update Distributor E-Mail  */

UPDATE
      T
SET
 Email = LEFT(COALESCE(D.sString,''),100)
FROM
      @EventsRegistrationReport T
INNER JOIN
      dbo.v_DistributorEmail D WITH (NOLOCK)
      ON
        T.PK_Distributor = D.nDistributorIDFK


/*  Update DRComments  */

IF OBJECT_ID('tempdb..#notes') IS NOT NULL  DROP TABLE #notes

CREATE TABLE #Notes
(PK_Distributor INT
,PK_Event INT
,Notes varchar(4000))

CREATE INDEX IX_Notes_PK_Distributor ON #Notes(PK_Distributor)
CREATE INDEX IX_Notes_PK_Event ON #Notes(PK_Event)


INSERT #Notes (
   PK_Distributor
  ,PK_Event
  ,Notes)
SELECT DISTINCT
   EDR.PK_Distributor
  ,EDR.PK_Event
  ,Notes
FROM
   dbo.EventDistributorNotes  EDR WITH (NOLOCK)
INNER JOIN
	@EventsRegistrationReport ER
	ON
		EDR.PK_Distributor = ER.PK_Distributor
		AND
		EDR.PK_Event = ER.PK_Event
		
		
	
IF OBJECT_ID('tempdb..#Events') IS NOT NULL  DROP TABLE #Events	
SELECT DISTINCT PK_Event INTO #Events 
FROM @EventsRegistrationReport 	

DECLARE @PK_Event INT

WHILE (SELECT MIN(PK_Event) FROM #Events) <= (SELECT MAX(PK_Event) FROM #Events)

BEGIN


SELECT @PK_Event = MIN(PK_Event) FROM #Events

	UPDATE ER
	SET DRComments = STUFF((
			SELECT 
					  ' | ' + T.[Notes]
			FROM 
					  #Notes T
			WHERE 
					  T.PK_Distributor = T1.PK_Distributor
					  AND
					  T.PK_Event = T1.PK_Event
			ORDER BY 
					  T.[Notes]
			FOR XML PATH('')
		),1,1,'')
	FROM 
		  #Notes T1
    INNER JOIN
		@EventsRegistrationReport ER
		ON
			T1.PK_Distributor = ER.PK_Distributor
			AND
			T1.PK_Event = ER.PK_Event		
			AND
			T1.PK_Event = @PK_Event  
		  
		  
	DELETE FROM #Events WHERE PK_Event = @PK_Event

  
  END
  

/* Update TicketsPurchased */
;WITH GetTicketsPurchased (PK_Event, PK_Distributor, TicketsPurchased) AS
(
	SELECT 
		PK_Event
	   ,PK_Purchaser
	   ,Count(1) NoTickets
    FROM 
		dbo.EventTickets WITH (NOLOCK)
	GROUP BY
		 PK_Event
		,PK_Purchaser
)
UPDATE 
	ONR
SET 
	ONR.TicketsPurchased = GTP.TicketsPurchased
FROM 
	@EventsRegistrationReport ONR
INNER JOIN 
    GetTicketsPurchased GTP WITH (NOLOCK)   
ON 
	ONR.PK_Distributor = GTP.PK_Distributor
	AND
	ONR.PK_Event = GTP.PK_Event
	



/* Update CurrentEventsTickets */

;WITH GetCurrentEventTickets (PK_Event, PK_Distributor, CurrentEventTickets) AS
(
	SELECT 
	    EA.PK_Event
	   ,EA.PK_ToDistributor
	   ,Count(1) TicketsUsed
    FROM
		dbo.EventTicketAssignment EA WITH (NOLOCK)
	INNER JOIN
		dbo.EventTickets E WITH (NOLOCK)
	ON 
		E.PK_EventTicket = EA.PK_EventTicket
		AND 
		EA.ValidToDateUTC = @ValidDate
	WHERE 
		E.IsTicketused = 1 
	GROUP BY
	    EA.PK_Event
	   ,EA.PK_ToDistributor
)
UPDATE 
	ONR
SET 
	ONR.CurrentEventTickets = GCT.CurrentEventTickets
FROM 
	@EventsRegistrationReport ONR
INNER JOIN 
	GetCurrentEventTickets GCT WITH (NOLOCK)
ON 
	ONR.PK_Distributor = GCT.PK_Distributor
	AND
	ONR.PK_Event = GCT.PK_Event


-- Update Language
UPDATE 
	@EventsRegistrationReport
SET 
	COP = D.sDistributorCountryProcessingCode
	,PrimaryLanguage = D.sLanguagePreference
FROM 
	@EventsRegistrationReport ONR
INNER JOIN 
	dbo.v_Distributor D WITH (NOLOCK)
ON 
	ONR.PK_Distributor = D.nDistributorID

/******************************************************************************
	CLEAR THE TABLE AND RELOAD THE TABLE
******************************************************************************/

TRUNCATE TABLE dbo.EventsRegistrationReport 

INSERT INTO dbo.EventsRegistrationReport
	(DistributorID, PK_Distributor, PK_Event, DSName, DSType, IsPartnerAttending, PartnerName, DSTeam, Address1, Address2, City, State, MailingCountry, PostalCode, COP, PrimaryLanguage, Email, DayPhone, TicketsPurchased, CurrentEventTickets, DRComments, RegistrationDate, RegisteredBy)
SELECT
	DistributorID, PK_Distributor, PK_Event, DSName, DSType, IsPartnerAttending, PartnerName, DSTeam, Address1, Address2, City, State, MailingCountry, PostalCode, COP, PrimaryLanguage, Email, DayPhone, TicketsPurchased, CurrentEventTickets, DRComments, RegistrationDate, RegisteredBy
FROM
	@EventsRegistrationReport

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
/**************************************************************************************************************
									END OF STORED PROCEDURE									
***************************************************************************************************************/

END