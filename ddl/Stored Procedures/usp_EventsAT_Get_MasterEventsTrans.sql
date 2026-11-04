
CREATE PROCEDURE [dbo].[usp_EventsAT_Get_MasterEventsTrans]			
	@PK_Locale int  /*Locale to filter by market*/
		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:			dbo.usp_EventsAT_Get_MasterEventsTrans

USE:	
	
	DECLARE @e int, @em varchar(4000)
		
	EXEC usp_EventsAT_Get_MasterEventsTrans
					@PK_Locale = 77
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
	                ,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]
			

DESCRIPTION: On Master Events Translations page, for a specific locale selected, this SP will provide all the master events and its translations
             that are defined in the system.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventSubTypeGroupMaster
dbo.EventSubTypeGroupLocale

VERSIONS
--------------------------------------------------------------------
1	2012-10-30		JuanH		Initial
2	2019-08-08		OrlandoL	Refactor code (SRE)
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

BEGIN TRY

SELECT DISTINCT
	SGM.PK_EventSubTypeGroupMaster
	, SGM.EventSubTypeGroupMasterName
	, COALESCE(@PK_Locale, SGL.PK_Locale)PK_Locale	
	, SGL.PK_EventSubTypeGroupLocale
	, SGL.EventSubTypeGroupLocale
	, [CanBeDeleted] AS CanBeDeleted
FROM
	dbo.EventSubTypeGroupMaster SGM WITH(NOLOCK)
INNER JOIN
	dbo.EventSubTypeGroup SG WITH(NOLOCK)
	ON
		SG.PK_EventSubTypeGroupMaster = SGM.PK_EventSubTypeGroupMaster	
LEFT JOIN
	dbo.EventSubTypeGroupLocale SGL	WITH(NOLOCK)
	ON
		SGL.PK_EventSubTypeGroupMaster = SGM.PK_EventSubTypeGroupMaster
		AND
		SGL.PK_Locale = COALESCE(@PK_Locale, SGL.PK_Locale)	
LEFT JOIN 
(
		SELECT 
		 A.PK_EventSubTypeGroupMaster, MAX(A.CanBeDeleted) AS [CanBeDeleted]
		from
		(			
			SELECT	
			 SGM.PK_EventSubTypeGroupMaster, 
			 CASE WHEN (EST.PK_EventSubTypeGroup IS NOT NULL OR SE.PK_EventSubTypeGroup IS NOT NULL OR DS.PK_EventSubTypeGroup IS NOT NULL)
			  THEN 1 ELSE 0 END [CanBeDeleted]
			  --,  EST.PK_EventSubTypeGroup EST, SE.PK_EventSubTypeGroup SE, DS.PK_EventSubTypeGroup DS, SG.PK_EventSubTypeGroup SG
			FROM
				dbo.EventSubTypeGroupMaster SGM WITH(NOLOCK)
			LEFT JOIN
				dbo.EventSubTypeGroup SG WITH(NOLOCK)
				ON
					SG.PK_EventSubTypeGroupMaster = SGM.PK_EventSubTypeGroupMaster			
			LEFT JOIN  --FOR SUB EVENT LOCALE DESC
			(
				SELECT DISTINCT EST.PK_EventSubTypeGroup, EST.PK_EventSubType FROM dbo.EventSubTypes EST WITH(NOLOCK)
				JOIN dbo.EventSubTypeLocaleDesc ELD WITH(NOLOCK) ON EST.PK_EventSubType = ELD.PK_EventSubType
				AND ELD.PK_Locale = COALESCE(@PK_Locale, ELD.PK_Locale)
			)EST
			ON SG.PK_EventSubTypeGroup = EST.PK_EventSubTypeGroup	
			LEFT JOIN -- FOR MASTER EVENTS ASSOC TO ANY EVENTS
			(
				SELECT DISTINCT EST.PK_EventSubTypeGroup, EES.PK_EventSubType
				FROM dbo.EventLocaleDesc ELD WITH(NOLOCK) --8508
				JOIN dbo.EventEventSubType EES WITH(NOLOCK) ON ELD.PK_Event = EES.PK_Event
				AND ELD.PK_EventType = EES.PK_EventType	
				JOIN dbo.EventSubTypes EST WITH(NOLOCK)
				ON EES.PK_EventSubType = EST.PK_EventSubType
				AND EST.PK_EventType = EES.PK_EventType	
				AND ELD.PK_Locale = COALESCE(@PK_Locale, ELD.PK_Locale)	
			)SE
			ON SE.PK_EventSubTypeGroup = SG.PK_EventSubTypeGroup	
			LEFT JOIN -- FOR MASTER EVENTS DS EVENTS
			(
				SELECT DISTINCT EST.PK_EventSubType, EST.PK_EventSubTypeGroup 
				FROM dbo.EventDSAccess  EDA WITH(NOLOCK)
				JOIN dbo.EventSubTypeLocaleDesc ESL WITH(NOLOCK) 
					ON EDA.PK_EventSubTypeLocaleDesc = ESL.PK_EventSubTypeLocaleDesc
				JOIN dbo.EventSubTypes EST WITH (NOLOCK)
					ON ESL.PK_EventSubType = EST.PK_EventSubType
			)DS		
			ON SG.PK_EventSubTypeGroup = DS.PK_EventSubTypeGroup AND (EST.PK_EventSubType = DS.PK_EventSubType OR SE.PK_EventSubType = DS.PK_EventSubType)		
		) A
		GROUP BY A.PK_EventSubTypeGroupMaster
)EST
ON SGM.PK_EventSubTypeGroupMaster = EST.PK_EventSubTypeGroupMaster		

WHERE
		SGM.IsActive = 1
ORDER BY 
	2	
	
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