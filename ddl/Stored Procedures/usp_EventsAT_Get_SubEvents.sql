CREATE PROCEDURE [dbo].[usp_EventsAT_Get_SubEvents]	
    -- MANDATORY
    @PK_Locale INT
    ,@PK_MasterEvent INT		

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:			dbo.usp_EventsAT_Get_SubEvents

USE:	
			DECLARE @e int, @em varchar(4000)
		
				exec usp_EventsAT_Get_SubEvents 
					@PK_Locale=10
					,@PK_MasterEvent=9
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 1

			SELECT @e AS [Error], @em AS [Error Message]
				
DESCRIPTION:	Return the SubEvents from the Master Event Selected

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventSubTypeGroup
dbo.EventType

VERSIONS
--------------------------------------------------------------------
1	2012-10-29		OrlandoL	Initial
2	2012-12-05		JuanH		Missing comment
3	2917-09-14		Rogelior	Include [Image] column from [EventSubTypeLocaleDesc]
4	2019-08-08		NoeG		Refactor code (SRE)
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

DECLARE @LocaleID INT

	BEGIN TRY
	
		SELECT DISTINCT
			STM.PK_EventSubTypeGroupMaster
			,SEL.PK_EventSubTypeLocaleDesc
			,STM.EventSubTypeGroupMasterName
			,SE.PK_EventSubType
			,SE.EventSubType	
			,SEL.EventSubTypeDesc AS [EventSubTypeTranslation]	
			,ET.PK_EventType 			
			,ET.EventTypeCode
			,SEL.LocaleDescription AS [EventSubTypeDesc]
			,SE.IsActive 
			,CASE WHEN PE.PK_EventSubType IS NOT NULL THEN 1 ELSE 0 END AS [HasEvent]
			,SEL.[Image]
		FROM 
			dbo.EventSubTypeGroupMaster STM WITH (NOLOCK)
		INNER JOIN
			dbo.EventSubTypeGroup ESTG WITH (NOLOCK)
		ON
			STM.PK_EventSubTypeGroupMaster = ESTG.PK_EventSubTypeGroupMaster 
		INNER JOIN
			dbo.EventSubTypes SE WITH (NOLOCK)
		ON
			ESTG.PK_EventSubTypeGroup = SE.PK_EventSubTypeGroup
		INNER JOIN
			dbo.EventType ET WITH (NOLOCK)
		ON
			SE.PK_EventType = ET.PK_EventType		

/* ***************** SonarQube check 160 - Identical expressions should not be used on both sides of a binary operator */
		INNER JOIN
			dbo.EventSubTypeLocaleDesc SEL WITH (NOLOCK)
		ON
			SE.PK_EventSubType = SEL.PK_EventSubType
			--AND
			--SEL.PK_Locale = SEL.PK_Locale		
			AND
			SEL.PK_Locale =  COALESCE(@PK_Locale,  SEL.PK_Locale)		
/* ***************** SonarQube check 160 */

		LEFT JOIN
		(
			SELECT EES.PK_EventSubType	-- CHECK IF SUBTYPES ARE ASSOCIATED TO EVENTS
			FROM 
				dbo.EventEventSubType EES WITH (NOLOCK)
			INNER JOIN 
				dbo.Event E WITH (NOLOCK)
				ON 
					E.PK_Event = EES.PK_Event	
			WHERE
				E.isPublish = 1
				AND
				E.dEndUTC > GETUTCDATE()			
			
		)PE
			ON 
			SE.PK_EventSubType = PE.PK_EventSubType
		WHERE
			STM.PK_EventSubTypeGroupMaster = @PK_MasterEvent
			AND 
			STM.IsAtomic = 0
		ORDER BY
			SE.IsActive DESC, SE.EventSubType ASC

		SELECT 
			A.PK_EventSubTypeGroupMaster
			,B.PK_EventType
			,C.EventTypeCode
		FROM 
			dbo.EventSubTypeGroupMaster A WITH (NOLOCK)
		INNER JOIN
			dbo.EventSubTypeGroup  B WITH (NOLOCK)
		ON
			A.PK_EventSubTypeGroupMaster = B.PK_EventSubTypeGroupMaster
		INNER JOIN
			dbo.EventType C WITH (NOLOCK)
		ON
			C.PK_EventType = B.PK_EventType

		WHERE 
			A.PK_EventSubTypeGroupMaster = @PK_MasterEvent
		AND 
			IsAtomic = 0
		
	
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

