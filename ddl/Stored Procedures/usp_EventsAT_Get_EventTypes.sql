
CREATE PROCEDURE [dbo].[usp_EventsAT_Get_EventTypes]			
		-- Error Parameters
		@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:			dbo.usp_EventsAT_Get_EventTypes

USE:	
				DECLARE @e int, @em varchar(4000)
		
				EXEC usp_EventsAT_Get_EventTypes
					@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 1

DESCRIPTION:	Return the EventTypes from the Master Event Selected

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventType

VERSIONS
--------------------------------------------------------------------
1	2012-11-15		SandhyaP		Initial
2	2019-08-08		OrlandoL		Refactor code (SRE)
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

/**********************************************************
		Get EventTypes
***********************************************************/
	
	SELECT DISTINCT
		ET.PK_EventType
		,ET.EventType
		,ET.EventTypeCode
	FROM 
		dbo.EventType ET WITH (NOLOCK)
	WHERE
		ET.EventTypeCode IN ('CE','CP','DE')
	
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

