/*
	This stored procedure is used to update the qualifications for lead assignment events that are based on rolling months as the months roll by.
	For instance, if a qualification says achieve 2500 TV in 3CM in the last 6 months. Well, the values in Valid From and Valid Through dates will
	change as the months roll by. So this procedure has to be maintained/updated for every such qualification for lead assignment events.
*/
/*
2019-01-02  Longs for MX, MY and Italy
2019-06-14  CarlosPerez for FR shop now
2020-04-28  CarlosPerez for EC shop now
*/

CREATE PROCEDURE [dbo].[usp_Update_LeadMgmtEvents] 
      @InAWTPreviousYear INT
      ,@InAWTCurrentYear INT

--OPTIONAL
       ,@IsDevQA		BIT = 0   
	   ,@Error	int = 0 OUTPUT
	   ,@ErrorMessage varchar(4000) = NULL OUTPUT

AS
BEGIN

/*********************************************************************************************************************
	OBJECT:		dbo.usp_Update_LeadMgmtEvents
		
	USE:			
			DECLARE @e int, @em varchar(max)
			
			EXEC dbo.usp_Update_LeadMgmtEvents 
				
				@Error = @e OUTPUT
                ,@ErrorMessage = @em OUTPUT
                ,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
	NOTES:		

	DEPENDENCIES
	-----------------------------------------------------------------------------------------------------------------
	SQL SERVER 2010
	
	VERSIONS
	-------------------------------------------------------------------------------------------------------------------------------
	1 
	2	2019-10-16	 JonathanO		Refactor code (SRE)


***********************************************************************************************************************************/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON


DECLARE @PrevMonth DATETIME
DECLARE @2MonthsFromPrevMonth DATETIME
DECLARE @3MonthsFromPrevMonth DATETIME
DECLARE @FirstDayOfLastYear DATETIME
DECLARE @LastMonthOfLastYear DATETIME
DECLARE @FirstDayOfThisYear DATETIME
DECLARE @StartMonthForLastYear DATETIME
DECLARE @Prev7Month DATETIME
DECLARE @Prev6Month DATETIME
DECLARE @Prev5Month DATETIME
DECLARE @Prev10Month DATETIME
DECLARE @PreviousYear VARCHAR(4)
DECLARE @CurrentYear  VARCHAR(4)
DECLARE @CurrMonth DATETIME
DECLARE @1MonthFromPrevMonth DATETIME
-- Note that PreviousYear, CurrentYear, FirstDayofLastYear,FirstDayofThisYear are all relative to the AWT Year

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();

SET @PrevMonth             = DATEADD(M,-1,CONVERT(DATETIME,CONVERT(VARCHAR(8),GETUTCDATE(),120)+'01',120))
SET @2MonthsFromPrevMonth  = DATEADD(M,-2,@PrevMonth)
SET @3MonthsFromPrevMonth  = DATEADD(M,-3,@PrevMonth)

SET @CurrMonth             = CONVERT(DATETIME,CONVERT(VARCHAR(8),GETUTCDATE(),120)+'01',120)
SET @1MonthFromPrevMonth  = DATEADD(M,-1,@PrevMonth)


IF MONTH(GETUTCDATE()) <> 1 
BEGIN
SET @FirstDayOfLastYear    = DATEADD(M,-12,DATEADD(YEAR,DATEDIFF(YEAR,0,GETUTCDATE()),0))
SET @LastMonthOfLastYear   = DATEADD(M,11,@FirstDayOfLastYear)
SET @FirstDayOfThisYear    = DATEADD(YEAR,DATEDIFF(YEAR,0,GETUTCDATE()),0)
SET @StartMonthForLastYear = DATEADD(M,-12,@PrevMonth)
END
ELSE
BEGIN
SET @FirstDayOfLastYear    = DATEADD(M,-24,DATEADD(YEAR,DATEDIFF(YEAR,0,GETUTCDATE()),0))
SET @LastMonthOfLastYear   = DATEADD(M,11,@FirstDayOfLastYear)
SET @FirstDayOfThisYear    = DATEADD(YEAR,1,@FirstDayOfLastYear)
SET @StartMonthForLastYear = DATEADD(M,-12,@PrevMonth)
END

SET @Prev7Month            = DATEADD(M,-6,@PrevMonth)
SET @Prev6Month            = DATEADD(M,-5,@PrevMonth)
SET @Prev5Month            = DATEADD(M,-4,@PrevMonth)
SET @Prev10Month           = DATEADD(M,-9,@PrevMonth)
SET @PreviousYear          = CONVERT(VARCHAR(4),DATEPART(YEAR,@FirstDayOfLastYear))
SET @CurrentYear           = CONVERT(VARCHAR(4),DATEPART(YEAR,@FirstDayOfThisYear))

BEGIN TRY

IF DATEPART(D,GETUTCDATE()) IN (16,17,18)
BEGIN

-- Ecuador
UPDATE
      SEQ
SET
      ValidFromDateUTC = @PrevMonth
      ,ValidThroughDateUTC = DATEADD(D,-1,@CurrMonth)
FROM
      dbo.SubEventQualification SEQ
WHERE
      (PK_Event IN (755) AND SortOrder = 3)

--Achieved any RO in 6CM in L12M
UPDATE 
      SEQ
SET 
      ValidFromDateUTC = @Prev7Month
      ,ValidThroughDateUTC = @PrevMonth 
FROM
      dbo.SubEventQualification SEQ
WHERE 
	  (PK_Event IN (1001) AND SortOrder = 7)

--Achieved 1000 RO in any month during last 3 months

UPDATE 
      SEQ
SET 
      ValidFromDateUTC = @2MonthsFromPrevMonth
      ,ValidThroughDateUTC = @PrevMonth 
FROM
      dbo.SubEventQualification SEQ
WHERE 
	  (PK_Event IN (226) AND SortOrder = 3)


--Achieved PB > 0 In 3CM In L6M From Last PB Month Run Back 
-- 2500 TVP In 3CM in L6M From Last PB Run Month Back
UPDATE 
      SEQ
SET 
      ValidFromDateUTC = @3MonthsFromPrevMonth
      ,ValidThroughDateUTC = @PrevMonth 
FROM
      dbo.SubEventQualification SEQ
WHERE 
	  (PK_Event IN (561,830,831,832) AND SortOrder = 2)
					OR
      (PK_Event IN (224,225,935,939) AND SortOrder = 3)
					OR
	  (PK_Event IN (686) AND SortOrder = 4)
					OR
	  (PK_Event IN (579) AND SortOrder = 5)
					OR
	  (PK_Event IN (829) AND SortOrder = 6)
					OR
	  (PK_Event IN (948) AND SortOrder = 7)     

-- Achieved 1000 RO In Last RO Run Month or Achieved 2500 TVP In The Last PB Run Month
-- 2500 TVP in 3CM in L3M From Last PB Run Month Back
-- 1500 TVP in A4M in L12M From Last PB Run Month Back
-- 2500 TVP in A1M in Last PB Run Month   
-- 2500 TVP in 6CM in L12M From Last PB Run Month Back 
-- 2500 TVP In 2CM In L2M From Last PB Run Month Back(577) and Achieve 2500 TVP in Last PB Run Month (583) and 2500 TVP In 3CM In L3M (767, 768)
-- 2500 TVP In 3CM in L3M From Last PB Month Run Back 
-- 2500 TVP In 3CM in L3M From Last PB Month Run Back 
-- 1000 TVP In 3CM in L3M From Last PB Month Run Back 
-- 2500 TVP In A4M in L6M From Last PB Month Run Back 
-- 1000 TVP In 5CM in L5M From Last PB Month Run Back 
UPDATE
      SEQ
SET
      ValidFromDateUTC = @PrevMonth
      ,ValidThroughDateUTC = @PrevMonth 
FROM
      dbo.SubEventQualification SEQ
WHERE 
	  (PK_Event IN (749,750,751,752,753,754,755,756,757,758,759,760,761,762,763,764,765,766) AND SortOrder = 1)
								OR
	  (PK_Event IN (230,234,236,555,556,558,559,562,563,564,566,578,584,557,588,684,938,21734,25743) AND SortOrder = 2)
								OR
      (PK_Event IN (227,228,229,232,1003,1008,18347, 25743) AND SortOrder = 3)
								OR
	  (PK_Event IN (235, 577, 583, 767, 768, 687) AND SortOrder = 4)
								OR
	  (PK_Event IN (769,770,937,1002,1005,1006,1007) AND SortOrder = 5)
	  							OR
	  (PK_Event IN (3950) AND SortOrder IN (5,6))
	                            OR
      (PK_Event IN (3739,3741) AND SortORder = 6)
      
--AWT qualifiers in the last 12 months
-- Months to be considered in Last Year's AWT
UPDATE 
      SEQ
SET 
      ValidFromDateUTC = @StartMonthForLastYear
      ,ValidThroughDateUTC = @LastMonthOfLastYear 
      ,QualificationValue = @InAWTPreviousYear
      ,SubEventQualTxt = 'AWT ' + @PreviousYear + ' Qualifiers'   
FROM
      dbo.SubEventQualification SEQ 
WHERE
	  (PK_Event IN (685) AND SortOrder = 1) 
					OR
	  (PK_Event IN (235) AND SortOrder = 2) 
					OR
	  (PK_Event IN (231) AND SortOrder = 3)
					OR
	  (PK_Event IN (558,561,830,831,832) AND SortOrder = 4)
					OR
	  (PK_Event IN (948,18705) AND SortOrder = 6)
      
-- Months to be considered in this year's AWT
UPDATE 
      SEQ
SET 
      ValidFromDateUTC = @FirstDayOfThisYear
      ,ValidThroughDateUTC = @PrevMonth 
      ,QualificationValue = @InAWTCurrentYear
      ,SubEventQualTxt = 'AWT ' + @CurrentYear + ' Qualifiers'    
FROM
      dbo.SubEventQualification SEQ
WHERE 
	  (PK_Event IN (685,231) AND SortOrder = 2)
					OR
	  (PK_Event IN (235) AND SortOrder = 3) 
					OR
	  (PK_Event IN (558,561,830,831,832,948,18705) AND SortOrder = 5)
      
     
-- 1000 TVP In 3CM in L12M From Last PB Month Run Back
-- 2500 TVP In 3CM in L12M From Last PB Month Run Back
UPDATE
      SEQ
SET 
      ValidFromDateUTC = @Prev10Month
      ,ValidThroughDateUTC = @PrevMonth   
FROM
      dbo.SubEventQualification SEQ
WHERE 
      (PK_Event IN (580) AND SortOrder = 4)
					OR
	  (PK_Event IN (936) AND SortOrder = 5)

-- 2500 TVP In A1M in L6M From Last PB Month Run Back 
UPDATE
      SEQ
SET 
      ValidFromDateUTC = @Prev6Month
      ,ValidThroughDateUTC = @PrevMonth   
FROM
      dbo.SubEventQualification SEQ 
WHERE 
      PK_Event IN (581,582) 
      AND 
      SortOrder = 5
      
END

-- Update Brazil Gold and Silver Pin Event
IF DATEPART(D,GETUTCDATE()) BETWEEN 2 AND 10
BEGIN
--Achieved 2500 TVP in 12CM in L12M (From Previous month and 11 months back) 
--Achieved 2500 TVP in 6CM in L6M (From Previous month and 5 months back) 
UPDATE 
      SEQ
SET 
      ValidFromDateUTC = @PrevMonth
      ,ValidThroughDateUTC = @PrevMonth 
FROM
      dbo.SubEventQualification SEQ
WHERE 
      PK_Event = 678
      AND 
      SortOrder = 1
      
-- BizWorks AWT_Potential Event
-- 4CM  
UPDATE 
	SEQ
SET 
	ValidFromDateUTC = @2MonthsFromPrevMonth
	,ValidThroughDateUTC = @PrevMonth
FROM
	dbo.SubEventQualification  SEQ 
INNER JOIN
	dbo.SubEvent SE WITH (NOLOCK)
ON
	SEQ.PK_Event = SE.PK_Event 
	AND
	 SEQ.PK_SubEvent = SE.PK_SubEvent 
WHERE
	SEQ.PK_Event = 720 AND SEQ.SortOrder = 1	
	AND
	SE.SubEventNumber IN (4,8,12,16)
 
UPDATE 
	SEQ
SET 
	ValidFromDateUTC = @1MonthFromPrevMonth
	,ValidThroughDateUTC = @CurrMonth
FROM
	dbo.SubEventQualification  SEQ 
INNER JOIN
	dbo.SubEvent SE WITH (NOLOCK)
ON
	SEQ.PK_Event = SE.PK_Event 
	AND
	 SEQ.PK_SubEvent = SE.PK_SubEvent 
WHERE
	SEQ.PK_Event = 720 AND SEQ.SortOrder = 1	
	AND
	SE.SubEventNumber IN (20)
 
-- 3CM
UPDATE 
	SEQ
SET 
	ValidFromDateUTC = @3MonthsFromPrevMonth
	,ValidThroughDateUTC = @PrevMonth
FROM
	dbo.SubEventQualification  SEQ
INNER JOIN
	dbo.SubEvent SE WITH (NOLOCK)
ON
	SEQ.PK_Event = SE.PK_Event 
	AND
	SEQ.PK_SubEvent = SE.PK_SubEvent 
WHERE
	SEQ.PK_Event = 720 AND SEQ.SortOrder = 1	
	AND
	SE.SubEventNumber IN (3,7,11,15)
 
UPDATE 
	SEQ
SET 
	ValidFromDateUTC = @2MonthsFromPrevMonth
	,ValidThroughDateUTC = @CurrMonth
FROM
	dbo.SubEventQualification  SEQ
INNER JOIN
	dbo.SubEvent SE WITH (NOLOCK)
ON
	SEQ.PK_Event = SE.PK_Event 
	AND
	SEQ.PK_SubEvent = SE.PK_SubEvent 
WHERE
	SEQ.PK_Event = 720 AND SEQ.SortOrder = 1	
	AND
	SE.SubEventNumber IN (19)
 
-- 2CM
UPDATE 
	SEQ
SET 
	ValidFromDateUTC = @Prev5Month
	,ValidThroughDateUTC = @PrevMonth
FROM
	dbo.SubEventQualification  SEQ
INNER JOIN
	dbo.SubEvent SE WITH (NOLOCK)
ON
	SEQ.PK_Event = SE.PK_Event 
	AND
	SEQ.PK_SubEvent = SE.PK_SubEvent 
WHERE
	SEQ.PK_Event = 720 AND SEQ.SortOrder = 1	
	AND
	SE.SubEventNumber IN (2,6,10,14)
 
UPDATE 
	SEQ
SET 
	ValidFromDateUTC = @3MonthsFromPrevMonth
	,ValidThroughDateUTC = @CurrMonth
FROM
	dbo.SubEventQualification  SEQ
INNER JOIN
	dbo.SubEvent SE WITH (NOLOCK)
ON
	SEQ.PK_Event = SE.PK_Event 
	AND
	SEQ.PK_SubEvent = SE.PK_SubEvent 
WHERE
	SEQ.PK_Event = 720 AND SEQ.SortOrder = 1	
	AND
	SE.SubEventNumber IN (18)
 
-- 1M
UPDATE 
	SEQ
SET 
	ValidFromDateUTC = @Prev6Month
	,ValidThroughDateUTC = @PrevMonth
FROM
	dbo.SubEventQualification  SEQ
INNER JOIN
	dbo.SubEvent SE WITH (NOLOCK)
ON
	SEQ.PK_Event = SE.PK_Event 
	AND
	SEQ.PK_SubEvent = SE.PK_SubEvent 
WHERE
	SEQ.PK_Event = 720 AND SEQ.SortOrder = 1	
	AND
	SE.SubEventNumber IN (1,5,9,13)

UPDATE 
	SEQ
SET 
	ValidFromDateUTC = @Prev5Month
	,ValidThroughDateUTC = @CurrMonth
FROM
	dbo.SubEventQualification  SEQ
INNER JOIN
	dbo.SubEvent SE WITH (NOLOCK)
ON
	SEQ.PK_Event = SE.PK_Event 
	AND
	SEQ.PK_SubEvent = SE.PK_SubEvent 
WHERE
	SEQ.PK_Event = 720 AND SEQ.SortOrder = 1	
	AND
	SE.SubEventNumber IN (17)

END


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