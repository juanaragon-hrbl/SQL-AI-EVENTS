
CREATE PROCEDURE [dbo].[usp_EventAPI_Get_DistributorSubEvents]
    -- REQUIRED
   @DistributorID varchar(10)
  ,@EventID int
	-- OPTIONAL
  ,@Error int OUTPUT
  ,@ErrorMessage varchar(200) OUTPUT	
	-- QA/DEV
  ,@IsDevQA bit = 0 
    
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_EventAPI_Get_DistributorSubEvents
USE:			DECLARE @e int
                       ,@em varchar(200)
                EXEC usp_EventAPI_Get_DistributorSubEvents @DistributorID = '2222222222' --'10169823'
                                                          ,@EventID=140
                                                          ,@Error = @e OUTPUT  /* @e must be defined in the local call */
						                                  ,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						                                  ,@IsDevQA = 0
DESCRIPTION:	Retrieves records from dbo.SubEventQualifier (has subevents DS has qualified for)
NOTES:			
DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2005
dbo.SubEvent
VERSIONS
--------------------------------------------------------------------
1	2009-01-22	Sandhya		Initial
2   2010-01-18	Sandhya		Added GiveAway flag
3	2019-11-04	NoeG		SRE Hardcode changed
******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

DECLARE @StoredProcedure varchar(100)
DECLARE @StartTime datetime
DECLARE @e int
DECLARE @em varchar(200)

DECLARE @ValidDate DATETIME = '2049-12-31'

SET @StoredProcedure = 'usp_EventAPI_Get_DistrubutorSubEvents'
SET @StartTime = GETUTCDATE()
SET @Error = 0
SET @ErrorMessage = 'No Error.'

/******************************************************************************
 Check if Distributor exist
******************************************************************************/

IF EXISTS  (SELECT nDistributorID FROM dbo.v_Distributor WHERE sDistributorID = @DistributorID
		    UNION
			SELECT PK_Temp FROM dbo.TempDistributors WITH (NOLOCK) WHERE DistributorID = @DistributorID) 
BEGIN
  IF EXISTS (SELECT 1 FROM dbo.Event WITH(NOLOCK) WHERE PK_Event = @EventID)
    BEGIN
 
/******************************************************************************
select record from SubEventQualifiers
******************************************************************************/
      BEGIN
        SELECT DISTINCT
            ISNULL(DistributorID,@DistributorID) AS DistributorID
           ,S.SubEventNumber
           ,CASE WHEN S.LocalName IS NOT NULL THEN S.LocalName + ' (' + S.SubEventName + ')' ELSE S.SubEventName END AS SubEventName
           ,CASE WHEN SQ.PK_SubEvent=S.PK_SubEvent AND SQ.PK_EVENT = S.PK_EVENT AND SQ.Qualified = 1 AND SQ.RemovedUTC = @ValidDate THEN 1 
            ELSE 0 END Qualified
           ,CASE WHEN S.PK_SubEventGroup = 16 THEN 1 ELSE 0 END AS GiveAway
        FROM 
           dbo.SubEvent S WITH(NOLOCK)
        LEFT JOIN
           dbo.SubEventQualifier SQ WITH(NOLOCK)
         ON 
           SQ.PK_SubEvent = S.PK_SubEvent
           AND
           SQ.PK_Event = S.PK_Event
		   AND
		   SQ.DistributorID = @DistributorID
			AND 
			SQ.RemovedUTC = @ValidDate
        WHERE
           S.PK_Event = @EventID
        ORDER BY
           S.SubEventNumber
      END
    END
  ELSE
  BEGIN
	SET @Error = 169  -- Error for Invalid Event
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN
  END
END
ELSE
BEGIN
	SET @Error = 8  -- Error for Inavlid Distributor
	-- Update ErrorLog
	EXEC dbo.usp_Utility_UpdateErrorLog 
		@ProcedureName = @StoredProcedure 
		,@ErrorNumber = @Error
		,@ErrorMessage = @ErrorMessage OUTPUT
	RETURN
END
-- Update processing Log
EXEC dbo.usp_Utility_UpdateProcessingLog 
	@StoredProcedureName = @StoredProcedure
	,@StartTime = @StartTime 
  

/******************************************************************************
	end procedure
******************************************************************************/
END