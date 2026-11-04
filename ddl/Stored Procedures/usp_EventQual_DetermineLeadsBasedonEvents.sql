CREATE PROCEDURE [dbo].[usp_EventQual_DetermineLeadsBasedonEvents]
	    @PK_Qualification int
       ,@IsDevQA bit = 0    
AS
BEGIN

/******************************************************************************************
	OBJECT:		dbo.usp_EventQual_DetermineLeadsBasedonEvents

	USE:		EXEC dbo.usp_EventQual_DetermineLeadsBasedonEvents @PK_Qualification = 690

	DESCRIPTION:    Determines if a distributor qualifies for accepting a lead based on:
				1) All Pres team members automatically qualify
				2) Others must attend a total of 4 events comprising of a minimum of 2 corporate events
	
	NOTES:		Corporate events consist of events the registered and those that there was no registeration but they qualified and also purchased/were assigned a ticket
				Events considered must be within the last 12 months

	DEPENDENCIES
	--------------------------------------------------------------------------------------
	SQL SERVER 2008
	
	VERSIONS
	--------------------------------------------------------------------------------------
	1	2011-12-08   IniU  	Initial
	2	2015-03-03	 IniU	Everyone must meet the number of events criterion where applicable except the people in list 5087 that automatically qualify
	3   2019-10-17   SushmaA	SRE updates for NOLOCK, NOCOUNT, SELECT *
	4   2024-12-23   JonathanO	Updating to 1 for corporate events and events attended

******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

/******************************************************************************
	variable declaration
******************************************************************************/
DECLARE 
	@StoredProcedure varchar(100)
	,@StartTime datetime
	,@RoyaltyMonth smalldatetime
	,@StartDate datetime
	,@EndDate datetime
	,@ProcName varchar(100)
	,@ProcParam varchar(100)

SET @StoredProcedure = 'usp_EventQual_DetermineLeadsBasedonEvents'
SET @ProcName = 'usp_EventQual_DetermineLeadsBasedonEvents'
SET @ProcParam = ''
SET @StartTime = GETUTCDATE()
SET @StartDate = dateadd(m,-12,getdate())
SET @EndDate = getdate()

--set royaltymonth to 1st of current month 
SET @RoyaltyMonth = CONVERT(varchar,(YEAR(DATEADD(m,0,@StartTime))*10000)+(MONTH(DATEADD(m,0,@StartTime))*100)+1)

IF OBJECT_ID('tempdb..#Potentials') IS NOT NULL DROP TABLE #Potentials
IF OBJECT_ID('tempdb..#EventsNoReg') IS NOT NULL DROP TABLE #EventsNoReg
IF OBJECT_ID('tempdb..#DSEventTickets') IS NOT NULL DROP TABLE #DSEventTickets
IF OBJECT_ID('tempdb..#FirstCut') IS NOT NULL DROP TABLE #FirstCut
IF OBJECT_ID('tempdb..#SecondCut') IS NOT NULL DROP TABLE #SecondCut
IF OBJECT_ID('tempdb..#ThirdCut') IS NOT NULL DROP TABLE #ThirdCut
IF OBJECT_ID('tempdb..#CNREG') IS NOT NULL DROP TABLE #CNREG
IF OBJECT_ID('tempdb..#WriteIn') IS NOT NULL DROP TABLE #WriteIn

CREATE TABLE #Potentials(PK INT IDENTITY(1,1),PK_Distributor INT, CREG INT DEFAULT 0, CNREG INT DEFAULT 0, WRITEIN INT DEFAULT 0, IsPresTeam INT DEFAULT 0, IsQualified INT DEFAULT 0)
CREATE TABLE #EventsNoReg(PK INT IDENTITY(1,1),PK_Event INT, Cnt INT)
CREATE TABLE #DSEventTickets(PK INT IDENTITY(1,1),PK_Event INT, PK_Distributor INT, Tickets INT)
CREATE TABLE #FirstCut(PK INT IDENTITY(1,1),PK_Distributor INT, PK_Event INT)
CREATE TABLE #SecondCut(PK INT IDENTITY(1,1),PK_Distributor INT, PK_Event INT)
CREATE TABLE #ThirdCut(PK INT IDENTITY(1,1),PK_Distributor INT, PK_Event INT)
CREATE TABLE #CNREG(PK INT IDENTITY(1,1),PK_Distributor INT, CNREG INT)
CREATE TABLE #WriteIn(PK INT IDENTITY(1,1),PK_Distributor INT, WriteIn INT)

INSERT INTO #FirstCut(PK_Event,PK_Distributor)
SELECT DISTINCT r.PK_Event,r.PK_Distributor -- Get Registrants
FROM  
	dbo.EventsRegistration r (NOLOCK) 
INNER JOIN
	dbo.Event b (NOLOCK)
ON 
	r.PK_Event = b.PK_Event
INNER JOIN
	dbo.EventType c (NOLOCK)
ON 
	b.PK_EventType = c.PK_EventType
WHERE
	c.EventTypeCode IN ('CE','CP','CR')
	AND b.dStartUTC BETWEEN @StartDate AND @EndDate
UNION
SELECT DISTINCT r.PK_Event,r.PK_Distributor  -- Get Main IDs for IDs that were transferred 
FROM  
	dbo.EventsRegistration r (NOLOCK) 
INNER JOIN
	dbo.v_DistributorAssociate2 DA 
ON
	DA.Transfer = 1 AND
	DA.nDistributorID = r.PK_Distributor 
INNER JOIN
	dbo.Event b (NOLOCK)
ON 
	r.PK_Event = b.PK_Event
INNER JOIN
	dbo.EventType c (NOLOCK)
ON 
	b.PK_EventType = c.PK_EventType
WHERE
	c.EventTypeCode IN ('CE','CP','CR')
	AND b.dStartUTC BETWEEN @StartDate AND @EndDate
UNION
SELECT DISTINCT r.PK_Event,DA.nDistributorID  -- Get IDs in Association 
FROM  
	dbo.EventsRegistration r (NOLOCK) 
INNER JOIN
	dbo.v_DistributorAssociate2 DA 
ON
	DA.Transfer = 0 AND
	DA.nMainDistributorID = r.PK_Distributor 
INNER JOIN
	dbo.Event b (NOLOCK)
ON 
	r.PK_Event = b.PK_Event
INNER JOIN
	dbo.EventType c (NOLOCK)
ON 
	b.PK_EventType = c.PK_EventType
WHERE
	c.EventTypeCode IN ('CE','CP','CR')
	AND b.dStartUTC BETWEEN @StartDate AND @EndDate

CREATE INDEX IX_#FirstCut_PK_Distributor ON #FirstCut(PK_Distributor)
CREATE INDEX IX_#FirstCut_PK_Event ON #FirstCut(PK_Event)

UPDATE 
	FC 
SET 
	PK_Distributor = DA.nMainDistributorID 
FROM 
	#FirstCut FC 
INNER JOIN
	dbo.v_DistributorAssociate2 DA
ON
	FC.PK_Distributor = DA.nDistributorID 
	AND DA.Transfer = 1
	
-- Get count of registration required events attended
INSERT INTO #Potentials
(PK_Distributor,CREG)
SELECT PK_Distributor, COUNT(1) AS CREG
FROM
(SELECT DISTINCT PK_Event,PK_Distributor
FROM #FirstCut ) R
GROUP BY PK_Distributor 

CREATE INDEX IX_Potentials_PK_Distributor ON #Potentials(PK_Distributor)

-- Get corporate Events that do not require registration
INSERT INTO #EventsNoReg(PK_Event,Cnt)
SELECT 
	a.PK_Event,COUNT(1) AS Cnt
FROM 
	dbo.Event a (NOLOCK)
INNER JOIN 
	dbo.EventType b (NOLOCK)
ON 
	a.PK_EventType = b.PK_EventType
LEFT JOIN
	dbo.EventsRegistration r (NOLOCK)
ON 
	a.PK_Event = r.PK_Event
WHERE 
	b.EventTypeCode IN ('CE','CP','CR')
GROUP BY 
	a.PK_Event
HAVING COUNT(1) < 10

CREATE INDEX IX_#EventsNoReg_PK_Event ON #EventsNoReg(PK_Event)

-- Get Tickets DS purchased for those events not requiring registration
INSERT INTO #DSEventTickets(PK_Event, PK_Distributor, Tickets)
SELECT 
	ETA.PK_Event,ETA.PK_ToDistributor AS PK_Distributor,COUNT(1) AS Tickets
FROM 
	 #EventsNoReg ENR
INNER JOIN
	 dbo.EventTicketAssignment ETA (NOLOCK)
ON
	ENR.PK_Event = ETA.PK_Event 
WHERE 
	ETA.ValidToDateUTC = '2049-12-31'
GROUP BY 
	ETA.PK_Event,ETA.PK_ToDistributor
UNION
SELECT 
	ETA.PK_Event,DA.nDistributorID AS PK_Distributor,COUNT(1) AS Tickets
FROM 
	 #EventsNoReg ENR
INNER JOIN
	 dbo.EventTicketAssignment ETA (NOLOCK)
ON
	ENR.PK_Event = ETA.PK_Event 
INNER JOIN
	dbo.v_DistributorAssociate2 DA
ON
	ETA.PK_ToDistributor = DA.nMainDistributorID 
	AND
	DA.Transfer = 0
WHERE 
	ETA.ValidToDateUTC = '2049-12-31'
GROUP BY 
	ETA.PK_Event,DA.nDistributorID 
	
CREATE INDEX IX_#DSEventTickets_PK_Event_PK_Distributor ON #DSEventTickets(PK_Event,PK_Distributor)

-- Get count of no-registration events qualified for and purchased ticket
INSERT INTO #SecondCut(PK_Event,PK_Distributor)
SELECT
	DISTINCT Q.PK_Event,Q.PK_Distributor
FROM
	#EventsNoReg E
INNER JOIN
	dbo.EventQualifier Q (NOLOCK)
ON 
	E.PK_Event = Q.PK_Event
INNER JOIN
	dbo.Event EV (NOLOCK)
ON
	EV.PK_Event = E.PK_Event
	AND
	Ev.dStartUTC BETWEEN @StartDate AND @EndDate
INNER JOIN
	#DSEventTickets ETA
ON
	ETA.PK_Event = E.PK_Event 
	AND 
	ETA.PK_Distributor = Q.PK_Distributor
UNION		-- Get any qualifiers who had transferred ID
SELECT
	DISTINCT Q.PK_Event,Q.PK_Distributor
FROM
	#EventsNoReg E
INNER JOIN
	dbo.EventQualifier Q (NOLOCK)
ON 
	E.PK_Event = Q.PK_Event
INNER JOIN
	dbo.v_DistributorAssociate2 DA
ON
	DA.nDistributorID = Q.PK_Distributor 
	AND	DA.Transfer = 1
INNER JOIN
	dbo.Event EV (NOLOCK)
ON
	EV.PK_Event = E.PK_Event
	AND
	Ev.dStartUTC BETWEEN @StartDate AND @EndDate
INNER JOIN
	#DSEventTickets ETA
ON
	ETA.PK_Event = E.PK_Event 
	AND 
	ETA.PK_Distributor = Q.PK_Distributor
UNION		-- Get any qualifiers who had associations ID
SELECT
	DISTINCT Q.PK_Event,DA.nDistributorID AS PK_Distributor
FROM
	#EventsNoReg E
INNER JOIN
	dbo.EventQualifier Q (NOLOCK)
ON 
	E.PK_Event = Q.PK_Event
INNER JOIN
	dbo.v_DistributorAssociate2 DA
ON
	DA.nMainDistributorID = Q.PK_Distributor 
	AND	DA.Transfer = 0
INNER JOIN
	dbo.Event EV (NOLOCK)
ON
	EV.PK_Event = E.PK_Event
	AND
	Ev.dStartUTC BETWEEN @StartDate AND @EndDate
INNER JOIN
	#DSEventTickets ETA
ON
	ETA.PK_Event = E.PK_Event 
	AND 
	ETA.PK_Distributor = Q.PK_Distributor

CREATE INDEX IX_#SecondCut_PK_Distributor ON #SecondCut(PK_Distributor)

-- For Transfers
UPDATE 
	SC 
SET 
	PK_Distributor = DA.nMainDistributorID 
FROM 
	#SecondCut SC 
INNER JOIN
	dbo.v_DistributorAssociate2 DA
ON
	SC.PK_Distributor = DA.nDistributorID 
	AND DA.Transfer = 1

-- For Associations	
UPDATE 
	SC 
SET 
	PK_Distributor = DA.nDistributorID 
FROM 
	#SecondCut SC 
INNER JOIN
	dbo.v_DistributorAssociate2 DA
ON
	SC.PK_Distributor = DA.nDistributorID 
	AND DA.Transfer = 0
	
INSERT INTO #CNREG(PK_Distributor,CNREG)
SELECT PK_Distributor, COUNT(1) AS CNREG
FROM
(SELECT DISTINCT PK_Event,PK_Distributor
FROM #SecondCut ) R
GROUP BY PK_Distributor 

CREATE INDEX IX_CNREG_PK_Distributor ON #CNREG(PK_Distributor)

-- update count of events qualified for and purchased tickets but no registration
UPDATE
	P
SET
	CNREG = B.CNREG
FROM
	#Potentials P
INNER JOIN
	#CNREG B
ON
	P.PK_Distributor = B.PK_Distributor
	
-- Insert records if not exist already
INSERT INTO #Potentials
(PK_Distributor,CNREG)		
SELECT PK_Distributor,CNREG
FROM #CNREG A
WHERE NOT EXISTS (SELECT 1 FROM #Potentials B WHERE A.PK_Distributor = B.PK_Distributor)

-- Get count of distributors claimed writein events

INSERT INTO #ThirdCut(PK_Event,PK_Distributor)
SELECT 
	DISTINCT LR.PK_LeadEvent,LR.PK_Distributor 
FROM 
	dbo.LeadEventsRegistration LR (nolock)
INNER JOIN
	dbo.EventType ET (NOLOCK)
ON 
	LR.PK_EventType = ET.PK_EventType
WHERE
	ET.EventTypeCode = 'LA'
	AND
	LR.EventDate BETWEEN @StartDate AND @EndDate
UNION -- Transfers
SELECT 
	DISTINCT LR.PK_LeadEvent,LR.PK_Distributor 
FROM 
	dbo.LeadEventsRegistration LR (nolock)
INNER JOIN
	dbo.v_DistributorAssociate2 DA
ON
	DA.nDistributorID = LR.PK_Distributor 
	AND DA.Transfer = 1
INNER JOIN
	dbo.EventType ET (NOLOCK)
ON 
	LR.PK_EventType = ET.PK_EventType
WHERE
	ET.EventTypeCode = 'LA'
	AND
	LR.EventDate BETWEEN @StartDate AND @EndDate
UNION -- Associations
SELECT 
	DISTINCT LR.PK_LeadEvent,DA.nDistributorID AS PK_Distributor 
FROM 
	dbo.LeadEventsRegistration LR (nolock)
INNER JOIN
	dbo.v_DistributorAssociate2 DA
ON
	DA.nMainDistributorID = LR.PK_Distributor 
	AND DA.Transfer = 0
INNER JOIN
	dbo.EventType ET (NOLOCK)
ON 
	LR.PK_EventType = ET.PK_EventType
WHERE
	ET.EventTypeCode = 'LA'
	AND
	LR.EventDate BETWEEN @StartDate AND @EndDate
	
CREATE INDEX IX_#ThirdCut_PK_Distributor ON #ThirdCut(PK_Distributor)
	
UPDATE 
	TC 
SET 
	PK_Distributor = DA.nMainDistributorID 
FROM 
	#ThirdCut TC 
INNER JOIN
	dbo.v_DistributorAssociate2 DA
ON
	TC.PK_Distributor = DA.nDistributorID 
	AND DA.Transfer = 1
	
UPDATE 
	TC 
SET 
	PK_Distributor = DA.nDistributorID 
FROM 
	#ThirdCut TC 
INNER JOIN
	dbo.v_DistributorAssociate2 DA
ON
	TC.PK_Distributor = DA.nDistributorID 
	AND DA.Transfer = 0
	
INSERT INTO #WriteIn (PK_Distributor,WriteIn)
SELECT PK_Distributor, COUNT(1) AS WriteIn
FROM
(SELECT DISTINCT PK_Event,PK_Distributor
FROM #ThirdCut ) R
GROUP BY PK_Distributor 

CREATE INDEX IX_WriteIn_PK_Distributor ON #WriteIn(PK_Distributor)

-- update counts of writein events
UPDATE
	P
SET
	WRITEIN = B.WRITEIN
FROM
	#Potentials P
INNER JOIN
	#WriteIn B
ON
	P.PK_Distributor = B.PK_Distributor

-- insert records for loosers if you are a Pres. HaHa!!!!
INSERT INTO #Potentials
(PK_Distributor,WriteIn)		
SELECT PK_Distributor,WriteIn 
FROM #WriteIn A
WHERE NOT EXISTS (SELECT 1 FROM #Potentials B WHERE A.PK_Distributor = B.PK_Distributor)

-- Flag all the people in the special list 5087
UPDATE
	P
SET
	IsPresTeam = 1
FROM
	#Potentials P
INNER JOIN
	dbo.v_DistributorSet DSS
ON
	DSS.nTypeLID = 2372
	AND
	P.PK_Distributor = DSS.nDistributorID 


-- Insert lucky Pres Team members if they are not already there	
INSERT INTO #Potentials
(PK_Distributor,IsPresTeam)	
SELECT
	DSS.nDistributorID,1
FROM
	dbo.v_DistributorSet DSS
WHERE
	nTypeLID = 2372 AND NOT EXISTS (SELECT 1 FROM #Potentials P WHERE P.PK_Distributor = DSS.nDistributorID)

-- make people that do at least 2 corporate events (CREG+CNREG) and at least 4 events in total
UPDATE 
	P
SET
	IsQualified = 1
FROM
	#Potentials P
WHERE
	CREG+CNREG >= 1 AND CREG+CNREG+WRITEIN >= 1

-- Set Chairmans club members to qualified anyway	
UPDATE 
	P
SET
	IsQualified = 1
FROM
	#Potentials P
WHERE
	IsPresTeam = 1

-- Remove prior qualifiers
DELETE 
	T
FROM 
	dbo.QualificationDistributor T
WHERE
	PK_Qualification = @PK_Qualification

-- Insert current qualifiers into QualificationDistributor table so qual engine may use in determining eventual qualifiers	
INSERT
	dbo.QualificationDistributor
(
	PK_Qualification
	,PK_Distributor
	,RoyaltyMonth
	,PK_Country
	,IsDeleted
	,IsDNR
	,IsType23
)
SELECT
	@PK_Qualification
	,P.PK_Distributor
	,@RoyaltyMonth
	,DS.nDistributorCountryProcessingID	
	,CASE WHEN DS.StatusCode = 'COMPLETE' THEN 0 ELSE 1 END
	,CASE WHEN DNR.PK_Distributor IS NULL THEN 0 ELSE 1 END
	,CASE WHEN T23.nDistributorID IS NULL THEN 0 ELSE 1 END
FROM
	#Potentials P
INNER JOIN
	dbo.v_Distributor DS
ON
	P.PK_Distributor = DS.nDistributorID
LEFT JOIN
	dbo.v_DistributorDoNotRecognize DNR
ON
	P.PK_Distributor = DNR.PK_Distributor
LEFT JOIN
	dbo.v_IsType23Distributor T23
ON
	P.PK_Distributor = T23.nDistributorID
WHERE
	P.IsQualified = 1
	
/******************************************************************************
	end procedure
******************************************************************************/
EXEC usp_Utility_UpdateProcessingLog
	@StoredProcedureName = @ProcName
	,@StoredProcedureParameters = @ProcParam
	,@StartTime = @StartTime
	
END