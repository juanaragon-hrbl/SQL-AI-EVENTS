CREATE PROCEDURE [dbo].[usp_EventAPI_Ins_AssignTickets]
				@DSIDQty VARCHAR(MAX)
				,@FromDistributorID VARCHAR(20)
				,@PK_Event INT

				-- Error Parameters
				,@Error	int = 0 OUTPUT
				,@ErrorMessage varchar(4000) = '' OUTPUT

				-- QA/DEV
				,@IsDevQA bit = 0	
AS
BEGIN
/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Ins_AssignTickets

USE:	        
		DECLARE @e int, @em varchar(4000)
        EXEC usp_EventAPI_Ins_AssignTickets
			@DSIDQty = '111111111,2;46112450,1;'
			,@FromDistributorID = 'staff'
			,@PK_Event = 6931
			,@Error = @e OUTPUT  /* @e must be defined in the local call */
			,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
            ,@IsDevQA = 1

		SELECT @e AS [Error], @em AS [Error Message]
				
DESCRIPTION:	Inserts the Ticket Assignments and retreives Ticket Assignment status

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
dbo.EventTicketAssignment

VERSIONS
--------------------------------------------------------------------
1.4	2019-09-05	NoeG		SRE template applied
1.3 2016-12-12	RogelioR	Added logic to identify invalid IDs correctly
1.2 2015-12-15	IniU		Added logic to handle assigning tickets for independent distributor events
1.1 2010-09-03	SandhyaP	Rewritten the code to check all the validations before committing the data
1.0 2010-07-13	Prabhu		Intitial
2.0 2018-11-20	SushmaA		China Exclusions
3.0 2019-10-17  SushmaA		SRE updates for NOLOCK, NOCOUNT, SELECT *
******************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* VARIABLE DECLARATION */
DECLARE @PK_ToDistributor INT
DECLARE @PK_FromDistributor INT
DECLARE @ToDistributorID VARCHAR(15)
DECLARE @TicketsCanAssign INT
DECLARE @PK_EventTicket INT
DECLARE @PK_EventSKU INT
DECLARE @PK_SKUPurchased INT
DECLARE @EventTypeCode VARCHAR(5)
DECLARE @MaxNoTickets INT
DECLARE @MaxNoTicketsAllowedByEvent INT
DECLARE @HasNotQualifiedForEvent INT = 0
DECLARE @TicketMaxExceeded INT = 0
DECLARE @TicketToBeAssigned INT = 0

/* Variables for While Loop Insert */
DECLARE @TotalQty INT
DECLARE @MaxRecord INT
DECLARE @QtyCounter INT
DECLARE @Count INT
DECLARE @Quantity INT

/* Variables for Validations on Failed IDs */

DECLARE @str VARCHAR(MAX)
DECLARE @EXTRACT VARCHAR (20)
DECLARE @START INT
DECLARE @DSID1 VARCHAR(20)
DECLARE @DSID2 VARCHAR(20)
DECLARE @DSID3 VARCHAR(20)
DECLARE @DSID4 VARCHAR(20)
DECLARE @DSID5 VARCHAR(20)
DECLARE @DSID6 VARCHAR(20)
DECLARE @DSID7 VARCHAR(20)
DECLARE @DSID8 VARCHAR(20)
DECLARE @DSID9 VARCHAR(20)
DECLARE @PK1 INT
DECLARE @PK2 INT
DECLARE @PK3 INT
DECLARE @PK4 INT
DECLARE @PK5 INT
DECLARE @PK6 INT
DECLARE @PK7 INT
DECLARE @PK8 INT
DECLARE @PK9 INT
DECLARE @V1FailedIDs VARCHAR(MAX)	
DECLARE @V2FailedIDs VARCHAR(MAX)	
DECLARE @V3FailedIDs VARCHAR(MAX) 
DECLARE @V4FailedIDs VARCHAR(MAX) 			 
DECLARE @V5FailedIDs VARCHAR(MAX) 
DECLARE @V6FailedIDs VARCHAR(MAX) 
DECLARE @V7FailedIDs VARCHAR(MAX)
DECLARE @V8FailedIDs VARCHAR(MAX)
DECLARE @V9FailedIDs VARCHAR(MAX)
DECLARE @FailedIDs VARCHAR(MAX)

/* Initialize */

SET @V1FailedIDs = ''
SET @V2FailedIDs = ''
SET @V3FailedIDs = ''
SET @V4FailedIDs = ''
SET @V5FailedIDs = ''
SET @V6FailedIDs = ''
SET @V7FailedIDs = ''
SET @V8FailedIDs = ''
SET @V9FailedIDs = ''

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
SELECT @Error = 0, @ErrorMessage = '';

SET @FailedIDs = ''


 /* Get PK for the From DS */
 SELECT 
	@PK_FromDistributor = nDistributorID 
FROM 
	dbo.v_Distributor 
WHERE 
	sDistributorID = @FromDistributorID

/* Get Event type code and max allowable tickets per disptributorship */
SELECT 
	@EventTypeCode = ET.EventTypeCode
	,@MaxNoTickets = ISNULL(E.MaxNoOfPrimaryGuest,0) + ISNULL(E.MaxNoOfGuest,0)
FROM
	dbo.Event E WITH (NOLOCK) INNER JOIN dbo.EventType ET WITH (NOLOCK)
ON
	E.PK_Event = @PK_Event AND E.PK_EventType = ET.PK_EventType
	
SET @MaxNoTicketsAllowedByEvent = CASE WHEN @EventTypeCode = 'IDE' THEN @MaxNoTickets ELSE 2 END
 
/* Split the string value, Put DS & Qty in the table */
DECLARE @DSAssign table (
		PK_DSAssign INT IDENTITY(1,1)
		,DSID VARCHAR(20)
		,PK_DSID INT NULL
		,Qty INT 
		,V1 INT DEFAULT 0
		,V2 INT DEFAULT 0
		,V3 INT DEFAULT 0
		,V4 INT DEFAULT 0
		,V5 INT DEFAULT 0
		,V6 INT DEFAULT 0
		,V7 INT DEFAULT 0
		,V8 INT DEFAULT 0
		,V9 INT DEFAULT 0
		,NotValid INT DEFAULT 0
)
 
WHILE LEN(@DSIDQTY) > 0

BEGIN
SET @START = CHARINDEX(';',@DSIDQty,1)

SET @EXTRACT = SUBSTRING (@DSIDQty , 1, @START-1)

INSERT INTO @DSAssign (DSID, Qty)
SELECT
	 SUBSTRING(@EXTRACT ,1,CHARINDEX(',',@EXTRACT)-1)
	,SUBSTRING (@EXTRACT,CHARINDEX(',',@EXTRACT)+ 1,1)
	
SET @DSIDQty = SUBSTRING(@DSIDQty , @START +1,LEN(@DSIDQty))
END

/* Validation 1: Check if the DS is Valid */

;WITH cte AS (
	SELECT	D.DSID
				,V.nDistributorID
				,CASE WHEN  V.nDistributorID IS NOT NULL THEN 0 ELSE 1 END AS V
	FROM @DSAssign D
	LEFT JOIN dbo.v_DistributorUnionTemp V
		ON V.sDistributorID = D.DSID
		AND V.DSClass IN ('Distributor','Temp')
		AND v.StatusCode = 'COMPLETE'
        AND V.sdistributorcountryprocessingcode <> 'CN'
)
UPDATE d
	SET	d.PK_DSID = c.nDistributorID
			,d.V1 = c.V
		FROM @DSAssign d
		LEFT JOIN cte AS c 
			ON c.DSID = d.DSID

/* Validation 2: Check if the To DS is already Registered */
UPDATE D
SET V2 = CASE WHEN ER.PK_Distributor IS NOT NULL THEN 1 ELSE 0 END
FROM @DSAssign D
INNER JOIN 
dbo.EventsRegistration ER WITH (NOLOCK)
 ON D.PK_DSID = ER.PK_Distributor
 AND PK_Event = @PK_Event
	
/* Validation 3: Check if there is a duplicate entry for the TO DSID */
UPDATE D
SET V3 = CASE WHEN D1.NCount > 1 THEN 1 ELSE 0 END
FROM @DSAssign D
INNER JOIN 
 (SELECT PK_DSID, COUNT(PK_DSAssign) NCount FROM @DSAssign GROUP BY PK_DSID) D1
ON D.PK_DSID = D1.PK_DSID

/* Validation 4: Check if the same From DS is assigning the ticket to the existing TO DS */
UPDATE D
SET V4 = CASE WHEN ETA.PK_ToDistributor IS NOT NULL THEN 1 ELSE 0 END
FROM @DSAssign D
INNER JOIN 
dbo.EventTicketAssignment ETA  WITH (NOLOCK)
	ON D.PK_DSID = ETA.PK_ToDistributor
	AND PK_FromDistributor = @PK_FromDistributor
	AND ETA.ValidToDateUTC = '2049-12-31'
	AND ETA.PK_Event = @PK_Event

/* Validation 5: Check total assignment doesnt exceed max allowable for the event  */	
UPDATE D
SET V5 = CASE WHEN E.TotalCount > @MaxNoTicketsAllowedByEvent THEN 1 ELSE 0 END
FROM @DSAssign D
INNER JOIN 
	(SELECT PK_DSID, (COUNT(1)+ DS.Qty) TotalCount
	FROM @DSAssign DS
	INNER JOIN
	dbo.EventTicketAssignment ETA (NOLOCK) 
	ON DS.PK_DSID = ETA.PK_ToDistributor
	AND ETA.PK_FromDistributor != @PK_FromDistributor
	AND ETA.PK_Event = @PK_Event
	AND ETA.ValidToDateUTC = '2049-12-31'
	GROUP BY PK_DSID, DS.Qty
	)E
		ON D.PK_DSID = E.PK_DSID
	
/* Validation 6: TicketsAvailable to Assign should not be less than Total Tickets to be assigned  */	
SELECT @TicketsCanAssign = COUNT(1) 
FROM 
	dbo.EventTicketAssignment ETM WITH (NOLOCK)
  INNER JOIN
  dbo.EventTickets ET WITH (NOLOCK)
  ON
  ETM.PK_EventTicket = ET.PK_EventTicket 
  AND ET.IsTicketUsed = 0
  AND ETM.PK_ToDistributor = @PK_FromDistributor
  AND ETM.ValidToDateUTC = '2049-12-31' 
  AND ETM.PK_Event = @PK_Event
  
SELECT @TotalQty = SUM(Qty)
FROM @DSAssign  
  
UPDATE D
SET V6 = CASE WHEN @TotalQty <= @TicketsCanAssign THEN 0 ELSE 1 END
FROM  
 @DSAssign D


 /* Validation 7: Person to be assigned ticket qualifies for the event if event type is IDA  */	
 IF @EventTypeCode = 'IDE'
 BEGIN
	UPDATE D
	SET V7 = CASE WHEN ISNULL(E.Qualified,0) > 0 THEN 0 ELSE 1 END
	FROM @DSAssign D
	INNER JOIN 
		(SELECT PK_DSID,SUM(Qualified) AS Qualified
			FROM
			(SELECT D.PK_DSID, ISNULL(SEQ.Qualified,0) AS Qualified
					 FROM
						@DSAssign D
					 LEFT JOIN
						dbo.SubEventQualifier SEQ WITH (NOLOCK)
					 ON
						D.PK_DSID = SEQ.PK_Distributor AND SEQ.PK_Event = @PK_Event AND SEQ.RemovedUTC = '2049-12-31'
			) Q
			GROUP BY
				PK_DSID
	  ) E
			ON D.PK_DSID = E.PK_DSID
END

 /* Validation 8: Check that allowable number of tickets are not exceeded for an IDE Event */	
 IF @EventTypeCode = 'IDE'
 BEGIN
	UPDATE D
	SET V8 = CASE WHEN ISNULL(E.TotalCount,0) > @MaxNoTicketsAllowedByEvent THEN 1 ELSE 0 END
	FROM @DSAssign D
	INNER JOIN 
		(SELECT PK_DSID, SUM(Qty) AS TotalCount
			FROM
			(SELECT PK_DSID, SUM(Qty) AS Qty
			FROM @DSAssign 
			GROUP BY PK_DSID
			UNION ALL
			SELECT DS.PK_DSID,COUNT(1) AS Qty
			FROM @DSAssign DS
			INNER JOIN
			dbo.EventTicketAssignment ETA WITH (NOLOCK) 
			ON DS.PK_DSID = ETA.PK_ToDistributor
			AND ETA.PK_Event = @PK_Event
			AND ETA.ValidToDateUTC = '2049-12-31'
			GROUP BY DS.PK_DSID
			) XX
			GROUP BY PK_DSID
		)E
			ON D.PK_DSID = E.PK_DSID
END

/* Validation 9: Tickets Available to be assigned should be from valid Event SKUs (SKU end date not exceeded)  */	
SELECT @TicketToBeAssigned = COUNT(1) 
FROM 
  dbo.EventTicketAssignment ETM WITH (NOLOCK)
  INNER JOIN
  dbo.EventTickets ET WITH (NOLOCK)
  ON
  ETM.PK_EventTicket = ET.PK_EventTicket 
  AND ET.IsTicketUsed = 0
  AND ETM.PK_ToDistributor = @PK_FromDistributor
  AND ETM.ValidToDateUTC = '2049-12-31' 
  AND ETM.PK_Event = @PK_Event
  INNER JOIN
  dbo.EventSKU ES  WITH (NOLOCK)
  ON
  ET.PK_Event = ES.PK_Event 
  AND ET.PK_EventSKU = ES.PK_EventSKU 
  AND ES.SKUValidEndUTC >= GETDATE()
  
UPDATE D
SET V9 = CASE WHEN @TicketToBeAssigned > 0 THEN 0 ELSE 1 END
FROM  
 @DSAssign D


	
/* Validation : Check if all the validations V1 thru V8   */	
UPDATE D
SET NotValid = CASE WHEN (V1 + V2 + V3 + V4 + V5 + V6 + V7 + V8 + V9) > 0 THEN 1 ELSE 0 END
FROM @DSAssign D	

/* Report all the DS IDs failed the Validations */

SELECT PK_DSAssign, DSID
INTO #TEMPDSV1
FROM @DSAssign
WHERE V1 = 1

SELECT PK_DSAssign, DSID
INTO #TEMPDSV2
FROM @DSAssign
WHERE V2 = 1

SELECT PK_DSAssign, DSID
INTO #TEMPDSV3
FROM @DSAssign
WHERE V3 = 1

SELECT PK_DSAssign, DSID
INTO #TEMPDSV4
FROM @DSAssign
WHERE V4 = 1

SELECT PK_DSAssign, DSID
INTO #TEMPDSV5
FROM @DSAssign
WHERE V5 = 1

SELECT PK_DSAssign, DSID
INTO #TEMPDSV6
FROM @DSAssign
WHERE V6 = 1

SELECT PK_DSAssign, DSID
INTO #TEMPDSV7
FROM @DSAssign
WHERE V7 = 1

SELECT PK_DSAssign, DSID
INTO #TEMPDSV8
FROM @DSAssign
WHERE V8 = 1

SELECT PK_DSAssign, DSID
INTO #TEMPDSV9
FROM @DSAssign
WHERE V9 = 1

WHILE exists (SELECT TOP 1 'exists' FROM #TEMPDSV1)
BEGIN

        SELECT TOP 1 @DSID1  = DSID, @PK1 = PK_DSAssign
        FROM #TEMPDSV1
        ORDER BY PK_DSAssign ASC

        SET @V1FailedIDs = @V1FailedIDs + ';' + @DSID1
        
        DELETE #TEMPDSV1
        WHERE PK_DSAssign= @PK1

 END
 

WHILE exists (SELECT TOP 1 'exists' FROM #TEMPDSV2)
BEGIN

        SELECT TOP 1 @DSID2  = DSID, @PK2 = PK_DSAssign
        FROM #TEMPDSV2
        ORDER BY PK_DSAssign ASC

        SET @V2FailedIDs = @V2FailedIDs + ';' + @DSID2

        DELETE #TEMPDSV2
        WHERE PK_DSAssign= @PK2

 END
 
 
 WHILE exists (SELECT TOP 1 'exists' FROM #TEMPDSV3)
BEGIN

        SELECT TOP 1 @DSID3  = DSID, @PK3 = PK_DSAssign
        FROM #TEMPDSV3
        ORDER BY PK_DSAssign ASC

        SET @V3FailedIDs = @V3FailedIDs + ';' + @DSID3

        DELETE #TEMPDSV3
        WHERE PK_DSAssign= @PK3

 END
 
 
 WHILE exists (SELECT TOP 1 'exists' FROM #TEMPDSV4)
BEGIN

        SELECT TOP 1 @DSID4  = DSID, @PK4 = PK_DSAssign
        FROM #TEMPDSV4
        ORDER BY PK_DSAssign ASC

        SET @V4FailedIDs = @V4FailedIDs + ';' + @DSID4

        DELETE #TEMPDSV4
        WHERE PK_DSAssign= @PK4

 END
 
 
  WHILE exists (SELECT TOP 1 'exists' FROM #TEMPDSV5)
BEGIN

        SELECT TOP 1 @DSID5  = DSID, @PK5 = PK_DSAssign
        FROM #TEMPDSV5
        ORDER BY PK_DSAssign ASC

        SET @V5FailedIDs = @V5FailedIDs + ';' + @DSID5

        DELETE #TEMPDSV5
        WHERE PK_DSAssign= @PK5

 END
 
 
  WHILE exists (SELECT TOP 1 'exists' FROM #TEMPDSV6)
BEGIN

        SELECT TOP 1 @DSID6  = DSID, @PK6 = PK_DSAssign
        FROM #TEMPDSV6
        ORDER BY PK_DSAssign ASC

        SET @V6FailedIDs = @V6FailedIDs + ';' + @DSID6
        
        DELETE #TEMPDSV6
        WHERE PK_DSAssign= @PK6

 END

   WHILE exists (SELECT TOP 1 'exists' FROM #TEMPDSV7)
BEGIN

        SELECT TOP 1 @DSID7  = DSID, @PK7 = PK_DSAssign
        FROM #TEMPDSV7
        ORDER BY PK_DSAssign ASC

        SET @V7FailedIDs = @V7FailedIDs + ';' + @DSID7
        
        DELETE #TEMPDSV7
        WHERE PK_DSAssign= @PK7

 END

    WHILE exists (SELECT TOP 1 'exists' FROM #TEMPDSV8)
BEGIN

        SELECT TOP 1 @DSID8  = DSID, @PK8 = PK_DSAssign
        FROM #TEMPDSV8
        ORDER BY PK_DSAssign ASC

        SET @V8FailedIDs = @V8FailedIDs + ';' + @DSID8
        
        DELETE #TEMPDSV8
        WHERE PK_DSAssign= @PK8

 END

     WHILE exists (SELECT TOP 1 'exists' FROM #TEMPDSV9)
BEGIN

        SELECT TOP 1 @DSID9  = DSID, @PK9 = PK_DSAssign
        FROM #TEMPDSV9
        ORDER BY PK_DSAssign ASC

        SET @V9FailedIDs = @V9FailedIDs + ';' + @DSID9
        
        DELETE #TEMPDSV9
        WHERE PK_DSAssign= @PK9

 END

/* Clear all the temp tables */

DROP TABLE #TEMPDSV1
DROP TABLE #TEMPDSV2
DROP TABLE #TEMPDSV3
DROP TABLE #TEMPDSV4
DROP TABLE #TEMPDSV5
DROP TABLE #TEMPDSV6
DROP TABLE #TEMPDSV7
DROP TABLE #TEMPDSV8
DROP TABLE #TEMPDSV9

/* Check for any Failed IDs that didnot meet the validations */

IF @V1FailedIDs <> ''
BEGIN  
SET @V1FailedIDs = RIGHT(@V1FailedIDs, LEN(@V1FailedIDs)-1) 
SELECT @Error = PK_ErrorCode, @V1FailedIDs = LEFT(ErrorMsg,LEN(ErrorMsg)-1) + ':' + @V1FailedIDs FROM dbo.ErrorCode WITH (NOLOCK) WHERE PK_ErrorCode = 267
IF @FailedIDs= '' BEGIN SET @FailedIDs = 'Report Failed IDS:' + '<br/>' END
SET @FailedIDs = @FailedIDs + @V1FailedIDs + '<br/>'
END

IF @V2FailedIDs <> ''
BEGIN  
SET @V2FailedIDs = RIGHT(@V2FailedIDs, LEN(@V2FailedIDs)-1) 
SELECT @Error = PK_ErrorCode, @V2FailedIDs = LEFT(ErrorMsg,LEN(ErrorMsg)-1) + ':' + @V2FailedIDs FROM dbo.ErrorCode WITH (NOLOCK) WHERE PK_ErrorCode = 275
IF @FailedIDs= '' BEGIN SET @FailedIDs = 'Report Failed IDS:' + '<br/>' END
SET @FailedIDs = @FailedIDs +  @V2FailedIDs + '<br/>'
END

IF @V3FailedIDs <> ''
BEGIN  
SET @V3FailedIDs = RIGHT(@V3FailedIDs, LEN(@V3FailedIDs)-1) 
SET @V3FailedIDs = 'Duplicate Entry. Please correct' + ':'
IF @FailedIDs= '' BEGIN SET @FailedIDs = 'Report Failed IDS:' + '<br/>' END
SET @FailedIDs = @FailedIDs +  @V3FailedIDs + '<br/>'
END

IF @V4FailedIDs <> ''
BEGIN 
SET @V4FailedIDs = RIGHT(@V4FailedIDs, LEN(@V4FailedIDs)-1) 
SELECT @Error = PK_ErrorCode, @V4FailedIDs = LEFT(ErrorMsg,LEN(ErrorMsg)-1) + ':' + @V4FailedIDs FROM dbo.ErrorCode WITH (NOLOCK) WHERE PK_ErrorCode = 276
IF @FailedIDs= '' BEGIN SET @FailedIDs = 'Report Failed IDS:' + '<br/>' END
SET @FailedIDs = @FailedIDs +  @V4FailedIDs + '<br/>'
END

IF @V5FailedIDs <> ''
BEGIN 
SET @V5FailedIDs = RIGHT(@V5FailedIDs, LEN(@V5FailedIDs)-1) 
SELECT @Error = PK_ErrorCode, @V5FailedIDs = LEFT(ErrorMsg,LEN(ErrorMsg)-1) + ':' + @V5FailedIDs FROM dbo.ErrorCode WITH (NOLOCK) WHERE PK_ErrorCode = 277
IF @FailedIDs= '' BEGIN SET @FailedIDs = 'Report Failed IDS:' + '<br/>' END
SET @FailedIDs = @FailedIDs +  @V5FailedIDs + '<br/>'
END

IF @V6FailedIDs <> ''
BEGIN 
SET @V6FailedIDs = RIGHT(@V6FailedIDs, LEN(@V6FailedIDs)-1) 
SELECT @Error = PK_ErrorCode, @V6FailedIDs = LEFT(ErrorMsg,LEN(ErrorMsg)-1) + ':' + @V6FailedIDs FROM dbo.ErrorCode WITH (NOLOCK) WHERE PK_ErrorCode = 268 
IF @FailedIDs= '' BEGIN SET @FailedIDs = 'Report Failed IDS:' + '<br/>' END
SET @FailedIDs = @FailedIDs + @V6FailedIDs + '<br/>'
END

IF @V7FailedIDs <> ''
BEGIN 
SET @V7FailedIDs = RIGHT(@V7FailedIDs, LEN(@V7FailedIDs)-1) 
SELECT @Error = PK_ErrorCode, @V7FailedIDs = ErrorMsg + ' : ' + @V7FailedIDs FROM dbo.ErrorCode WITH (NOLOCK) WHERE PK_ErrorCode = 417 
IF @FailedIDs= '' BEGIN SET @FailedIDs = 'Report Failed IDS:' + '<br/>' END
SET @FailedIDs = @FailedIDs + @V7FailedIDs + '<br/>'
END

IF @V8FailedIDs <> ''
BEGIN 
SET @V8FailedIDs = RIGHT(@V8FailedIDs, LEN(@V8FailedIDs)-1) 
SELECT @Error = PK_ErrorCode, @V8FailedIDs = LEFT(ErrorMsg,LEN(ErrorMsg)-1) + ':' + @V8FailedIDs FROM dbo.ErrorCode WITH (NOLOCK) WHERE PK_ErrorCode = 415 
IF @FailedIDs= '' BEGIN SET @FailedIDs = 'Report Failed IDS:' + '<br/>' END
SET @FailedIDs = @FailedIDs + @V8FailedIDs + '<br/>'
END

IF @V9FailedIDs <> ''
BEGIN 
SET @V9FailedIDs = RIGHT(@V9FailedIDs, LEN(@V9FailedIDs)-1) 
SELECT @Error = PK_ErrorCode, @V9FailedIDs = LEFT(ErrorMsg,LEN(ErrorMsg)-1) + ':' + @V9FailedIDs FROM dbo.ErrorCode WITH (NOLOCK) WHERE PK_ErrorCode = 416 
IF @FailedIDs= '' BEGIN SET @FailedIDs = 'Report Failed IDS:' + '<br/>' END
SET @FailedIDs = @FailedIDs + @V9FailedIDs + '<br/>'
END


/*********************************************************************************************
		      TICKET ASSIGNMENT WILL BE PERFORMED IF THE VALIDATIONS ARE TRUE
		      OTHERWISE SEND THE REPORT ON THE DS IDS WITH THE ERROR MESSAGE 
		      AND NONE OF THE RECORDS GETS INSERTED                     
*********************************************************************************************/

IF EXISTS (SELECT SUM(NotValid) FROM @DSAssign HAVING SUM(NotValid) > 0)
BEGIN

	/* ***************** SonarQube check 119 - Variables should not be self-assigned */
    ----SET @Error = @Error
	/* ***************** SonarQube check 119 */

	SET @ErrorMessage = @FailedIDs

	IF @IsDevQA = 1
		SELECT '1', @Error, @ErrorMessage

	RETURN 
END
ELSE

IF EXISTS (SELECT CASE WHEN ETA.PK_ToDistributor IS NOT NULL THEN 0 ELSE 1 END
FROM @DSAssign D
INNER JOIN 
dbo.EventTicketAssignment ETA WITH (NOLOCK)
	ON D.PK_DSID = ETA.PK_ToDistributor
	AND PK_FromDistributor = @PK_FromDistributor
	AND ETA.ValidToDateUTC = '2049-12-31'
	AND ETA.PK_Event = @PK_Event	
)
BEGIN
	SET @Error = 276 /* Extra Check if the same From DS is assigning the ticket to the existing TO DS */ 
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		 @ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT

	IF @IsDevQA = 1
		SELECT '2', @Error, @ErrorMessage

	RETURN
END
  
ELSE 
	
/* Perform the Assignment once the Ticket Assignment entries passes through all the validations */	
BEGIN TRY

SET @Count = 1
SELECT @MaxRecord = MAX(PK_DSAssign) FROM @DSAssign

WHILE
	@Count <= @MaxRecord
BEGIN

   SELECT @ToDistributorID = DSID, @PK_ToDistributor = PK_DSID, @Quantity = Qty
   FROM @DSAssign
   WHERE PK_DSAssign = @Count

SET @QtyCounter = 1

 /* Loop through Quantity for No Of Tickets to Assign */
 
 WHILE
	@QtyCounter <= @Quantity
 BEGIN	

	/* Select the respective Ticket Records */
	SELECT 
		 @PK_EventTicket = PK_EventTicket
		,@PK_EventSKU = ETA.PK_EventSKU
		,@PK_SKUPurchased = ETA.PK_SKUPurchased
	FROM 
		dbo.EventTicketAssignment ETA WITH (NOLOCK)
	WHERE 
	 PK_EventTicketAssignment IN 
	 (SELECT MIN(PK_EventTicketAssignment) 
	  FROM 
	  dbo.EventTicketAssignment ETM WITH (NOLOCK)
	  INNER JOIN
	  dbo.EventTickets ET WITH (NOLOCK)
	  ON
	  ETM.PK_EventTicket = ET.PK_EventTicket 
	  AND ET.IsTicketUsed = 0
	  AND ETM.PK_ToDistributor = @PK_FromDistributor
	  AND ETM.ValidToDateUTC = '12-31-2049' 
	  AND ETM.PK_Event = @PK_Event
	  INNER JOIN  
	  dbo.EventSKU ES  WITH (NOLOCK)
	  ON
	  ET.PK_Event = ES.PK_Event
	  AND ET.PK_EventSKU = ES.PK_EventSKU
	  AND ES.SKUValidEndUTC >= GETDATE()
	  )

	/* Expire the TO ID of the purchaser */

	UPDATE
		ETA
	SET
		 ETA.ValidToDateUTC = GETUTCDATE()
		,ETA.ModifiedDateUTC = GETUTCDATE()
		,ETA.ModifiedBy = REPLACE (suser_sname(),'HERBALIFECORP\','')
	FROM
		dbo.EventTicketAssignment ETA 
	WHERE
		PK_EventTicket = @PK_EventTicket
	AND
		ValidToDateUTC = '2049-12-31'
		 
	/* Perform the Insert */
	
	INSERT INTO dbo.EventTicketAssignment
			   ([PK_FromDistributor]
			   ,[PK_ToDistributor]
			   ,[CreatedDateUTC]
			   ,[CreatedBy]
			   ,[ModifiedDateUTC]
			   ,[ModifiedBy]
			   ,[PK_EventTicket]
			   ,[Ticketed]
			   ,[ValidFromDateUTC]
			   ,[ValidToDateUTC]
			   ,[PK_Event]
			   ,[PK_EventSKU]
			   ,[PK_SKUPurchased])
		 SELECT
			   @PK_FromDistributor
			   ,@PK_ToDistributor
			   ,GETUTCDATE()
			   ,REPLACE (suser_sname(),'HERBALIFECORP\','')
			   ,GETUTCDATE()
			   ,REPLACE (suser_sname(),'HERBALIFECORP\','')
			   ,@PK_EventTicket
			   ,1
			   ,GETUTCDATE()
			   ,'2049-12-31'
			   ,@PK_Event
			   ,@PK_EventSKU
			   ,@PK_SKUPurchased

	SET @QtyCounter = @QtyCounter + 1
	END	

	
 SET @Count = @Count + 1
 END

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

	IF @IsDevQA = 1
		SELECT '3', @Error, @ErrorMessage

	RETURN 
END CATCH
END