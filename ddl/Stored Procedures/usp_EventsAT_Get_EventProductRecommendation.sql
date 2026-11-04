CREATE PROCEDURE [dbo].[usp_EventsAT_Get_EventProductRecommendation]   
 -- MANDATORY  
 @PK_Event INT  
 ,@UserID nVARCHAR(30)
-- Error Parameters
,@Error	int = 0 OUTPUT
,@ErrorMessage varchar(4000) = '' OUTPUT

-- QA/DEV
,@IsDevQA bit = 0
AS  
BEGIN  
    
/*  
OBJECT:  dbo.usp_EventsAT_Get_EventProductRecommendation  
  
USE:  
	DECLARE @e int, @em varchar(4000)
   EXEC usp_EventsAT_Get_EventProductRecommendation  
      @PK_Event = 61904  
	 ,@UserID = 'SushmaA'
     ,@Error = @e OUTPUT  -- @e must be defined in the local call   
     ,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call   
    ,@IsDevQA = 1

SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION: On the admin page, this API will fetch all the product recommendation information of a particular event
  
NOTES:     
  
DEPENDENCIES  
--------------------------------------------------------------------  
SQL SERVER 2008  
  
VERSIONS  
--------------------------------------------------------------------  
1 2018-07-05	SushmaA		Initial  
2 2018-07-27	SushmaA		Add condition to show only subevents that have accumulate logic in the qual defn
							Bug fixes to include only CE/CP and only active events
3 2018-11-01	RogelioR	Bug fix (double subevents on second dataset)
4 2019-08-08	OrlandoL	Refactor code (SRE)
*/  
  
SET ANSI_NULLS ON  
SET QUOTED_IDENTIFIER ON  
SET NOCOUNT ON  
  
/******************************************************************************  
 variable declaration  
******************************************************************************/  
	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';
  
  
/******************************************************************************  
Retrieve Master Events and SubEvents for Distributor Events (DE) only  
******************************************************************************/  
BEGIN TRY  

IF OBJECT_ID('tempdb..#Events') IS NOT NULL   
    DROP TABLE #Events 
   
 SELECT DISTINCT   
  E.PK_Event, 
  E.EventName, 
  E.dStartUTC, 
  E.dEndUTC, 
  E.[Location]
 INTO #Events
 FROM    
  dbo.[Event]  E WITH(NOLOCK)
 JOIN 
  [dbo].[EventDistributorCountryLocales] EL WITH (NOLOCK)
 ON
  E.PK_Event = EL.PK_Event
 JOIN 
  dbo.EventATAccessUserModules EUM WITH(NOLOCK)
 ON
  EL.PK_Locale = EUM.PK_Locale
 JOIN
  dbo.EventATAccessUser EU WITH(NOLOCK)
 ON
  EU.PK_EventATAccessUser = EUM.PK_EventATAccessUser
 WHERE
  EventATAccessUserName = @UserID
 AND
  E.PK_Event = @PK_Event
 AND
  E.PK_EventType IN (1,2)
 AND
   E.IsPublish = 1 
 AND 
   E.dEndUTC >= CONVERT(DATE,GETUTCDATE(), 110)
 
 SELECT  PK_Event, 
  EventName, 
  dStartUTC, 
  dEndUTC, 
  [Location] FROM #Events

 SELECT DISTINCT
  E.PK_Event, 
  SE.PK_SubEvent, 
  SE.SubEventName
 FROM    
  #Events  E
 LEFT JOIN
  dbo.[SubEvent] SE WITH(NOLOCK)
 ON 
  E.PK_Event = SE.PK_Event
 JOIN 
  dbo.SubEventQualification SEQ WITH(NOLOCK)
 ON 
  SE.PK_SubEvent = SEQ.PK_SubEvent
 AND
  SEQ.PK_Event = SE.PK_Event
 JOIN 
   dbo.Qualification Q WITH(NOLOCK)
  ON 
   SEQ.PK_Qualification = Q.PK_Qualification
 WHERE
  E.PK_Event = @PK_Event
 AND
  Q.PK_QualificationFrequencyType IN (2,3)

 SELECT DISTINCT   
   E.PK_Event, 
   EPR.[PK_EventProductRecommendation], 
   EPR.[IsProductRecommended],
   EPR.[IsLinkedToMainEvent],
   EPR.[PK_SubEvent], 
   SE.SubEventName,    
   EPR.[IsThresholdEnabled],
   EPR.[Goal], 
   EPR.[Threshold], 
   EPR.[IsThresholdMonthBased]
 FROM    
  #Events E
 LEFT JOIN
  dbo.[EventProductRecommendation] EPR WITH(NOLOCK)
 ON 
  E.PK_Event = EPR.PK_Event
 LEFT JOIN
  dbo.SubEvent SE WITH(NOLOCK)
 ON 
  E.PK_Event = SE.PK_Event 
 AND 
  EPR.PK_Event = SE.PK_Event 
 AND
  EPR.PK_SubEvent = SE.PK_SubEvent
 WHERE
  E.PK_Event = @PK_Event
     
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
  
  
/******************************************************************************  
 END Procedure  
******************************************************************************/  
END