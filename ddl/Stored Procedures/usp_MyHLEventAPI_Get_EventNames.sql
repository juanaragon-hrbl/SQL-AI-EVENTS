
CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_EventNames]
		-- Error Parameters
		@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/******************************************************************************
OBJECT:			dbo.usp_MyHLEventAPI_Get_EventNames

USE:
				DECLARE @e int, @em varchar(4000)
                EXEC dbo.usp_MyHLEventAPI_Get_EventNames
						@Error = @e OUTPUT  /* @e must be defined in the local call */
						,@ErrorMessage = @em OUTPUT /* @em must be defined in the local call */
						,@IsDevQA = 1

				SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	For Search Bar auto-complete the event names, this SP lists all active events which are published and is cached on the service 
				in order to assist the user entered text to have auto-complete in the search bar. This list gets refreshed every 50 min.

NOTES:			

DEPENDENCIES
----------------------------------------------------------------------------------
dbo.Event

VERSIONS
----------------------------------------------------------------------------------
1	2014-10-30	SandhyaP	Intitial
2	2019-08-14	NoeG		Refactor code (SRE)

******************************************************************************/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
		,@StartTime datetime2 = GETUTCDATE();
	
DECLARE @CreatedDateUTC DATETIME2 

SELECT @Error = 0, @ErrorMessage = '';

/*Get the list of all Active events*/
BEGIN TRY
	SELECT A.PK_Event
		  ,A.EventName
		  ,A.PK_EventType
		  ,A.[STATUS]
		  ,A.LowestTeamOrder
		  ,A.IsPublic

	FROM
	(
	SELECT E.PK_Event, E.EventName, E.PK_EventType,
	CASE WHEN E.PK_EventType = 3 AND E.IsActive = 0  THEN 5 /* Inactive */
			  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 0 THEN 0 /* Pending Review */
			  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 1 THEN 1 /* Published */
			  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 2 THEN 2 /* Rejected */
			  WHEN E.PK_EventType = 3 AND E.EventApprovalStatus = 3 THEN 3 /* Draft */
			  WHEN E.PK_EventType IN (1,2) AND E.IsPublish = 1 AND E.DisplayEndDate >= CONVERT(DATE,GETUTCDATE(), 110) THEN 4 /* Published */
			  WHEN E.PK_EventType IN (1,2) AND (E.IsPublish = 0 OR E.DisplayEndDate < CONVERT(DATE,GETUTCDATE(), 110) OR E.dEndUTC < CONVERT(DATE,GETUTCDATE(), 110))  THEN 5 /* Inactive */
			  END STATUS
			  ,EDS.TeamOrder [LowestTeamOrder]
			  ,MakePublic [IsPublic]
	FROM dbo.Event E  WITH(NOLOCK) 
	LEFT JOIN 
	(
		SELECT EDS.PK_Event, MAX(DS.TeamOrder) TeamOrder FROM dbo.EventDSTeamType EDS  WITH(NOLOCK) INNER JOIN dbo.DSTeamType DS WITH(NOLOCK) ON EDS.DSTeamTypeCode = DS.DSTeamTypeCode GROUP BY EDS.PK_Event
	)EDS
	ON
		E.PK_Event = EDS.PK_Event
	WHERE
	(E.PK_EventType = 3 AND E.EventApprovalStatus = 1 AND (CONVERT(DATE,GETUTCDATE(), 110) BETWEEN E.DisplayStartDate AND (E.DisplayEndDate+1)))
	OR
	(E.PK_EventType IN (1,2) AND E.IsPublish = 1 AND (CONVERT(DATE,GETUTCDATE(), 110) BETWEEN E.DisplayStartDate AND (E.DisplayEndDate+1)))
	)A
	WHERE Status <> 5
	ORDER BY 2

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

END
