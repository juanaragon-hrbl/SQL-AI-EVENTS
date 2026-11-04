CREATE PROCEDURE [dbo].[usp_EventsAT_Del_MasterEventsTrans]			
	@PK_EventSubTypeGroupLocale int

	-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

	-- QA/DEV
	,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:			dbo.usp_EventsAT_Del_MasterEventsTrans

USE:	
	DECLARE @e int, @em varchar(4000)
		
	EXEC usp_EventsAT_Del_MasterEventsTrans
					@PK_EventSubTypeGroupLocale = 9
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
                ,@IsDevQA = 1

	SELECT @e AS [Error], @em AS [Error Message]

DESCRIPTION:	Delete Master Events Translations 

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventSubTypeGroup
dbo.EventSubTypeGroupLocale
dbo.EventType

VERSIONS
--------------------------------------------------------------------
1	2012-10-30	JuanH Initial
2	2019-08-15	NoeG	Refactor code (SRE)
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

	/*Delete the default translations of EventSubtypes created for Atomic Master Event Translations*/
		DELETE ESL
		FROM 
			dbo.EventSubTypeLocaleDesc ESL
		INNER JOIN 
			dbo.EventSubTypes EST 
			ON 
			ESL.PK_EventSubType = EST.PK_EventSubType
		INNER JOIN 
			dbo.EventSubTypeGroup ESG 
			ON 
			EST.PK_EventSubTypeGroup = ESG.PK_EventSubTypeGroup
		INNER JOIN 
			dbo.EventSubTypeGroupMaster ESM 
			ON 
			ESG.PK_EventSubTypeGroupMaster = ESM.PK_EventSubTypeGroupMaster
		INNER JOIN 
			dbo.EventSubTypeGroupLocale ESGL 
			ON 
			ESM.PK_EventSubTypeGroupMaster = ESGL.PK_EventSubTypeGroupMaster 
			AND 
			ESL.PK_Locale = ESGL.PK_Locale
			AND 
			ISNULL(ESL.EventSubTypeDesc, '') = ISNULL(ESGL.EventSubTypeGroupLocale, '')
		WHERE 
			ESGL.PK_EventSubTypeGroupLocale = @PK_EventSubTypeGroupLocale
			AND 
			ESM.IsAtomic = 1

		DELETE FROM
			EventSubTypeGroupLocale
		WHERE 
			PK_EventSubTypeGroupLocale = @PK_EventSubTypeGroupLocale

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
	END CATCH
END
GO

