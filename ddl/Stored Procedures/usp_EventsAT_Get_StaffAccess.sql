
CREATE PROCEDURE [dbo].[usp_EventsAT_Get_StaffAccess]	
    -- MANDATORY
    @PK_EventATAccessUserType INT	

		-- Error Parameters
	,@Error	int = 0 OUTPUT
	,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0
AS
BEGIN

/*
OBJECT:			dbo.usp_EventsAT_Get_StaffAccess

USE:	
				DECLARE @e INT, @em VARCHAR(4000)
		
				EXEC usp_EventsAT_Get_StaffAccess
					@PK_EventATAccessUserType = 1
					,@Error = @e OUTPUT  -- @e must be defined in the local call 
					,@ErrorMessage = @em OUTPUT -- @em must be defined in the local call 
					,@IsDevQA = 1

DESCRIPTION: This API is to provide the UserTypes and their access levels to the functionality.

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventATAccessModules
dbo.EventATAccessUserTypeModuleActions
dbo.EventATAccessUserTypes

VERSIONS
--------------------------------------------------------------------
1	2012-11-19		SandhyaP		Initial
2	2019-08-08		NoeG			Refactor code (SRE)
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
	
		SELECT 
			EUT.PK_EventATAccessUserType
			,EUT.EventATAccessUserType
			,EA.PK_EventATAccessModule
			,EA.EventATAccessModuleName
			,EAM.PK_EventATAccessModuleAction
			,EAM.EventATAccessModuleActionName
		FROM
			dbo.EventATAccessModules EA WITH (NOLOCK)
		INNER JOIN
			dbo.EventATAccessModuleActions EAM WITH (NOLOCK)
			ON
				EA.PK_EventATAccessModule = EAM.PK_EventATAccessModule
		INNER JOIN
			dbo.EventATAccessUserTypeModuleActions EAMA WITH (NOLOCK)
			ON
				EAMA.PK_EventATAccessModule = EA.PK_EventATAccessModule
				AND
				EAMA.PK_EventATAccessModuleAction = EAM.PK_EventATAccessModuleAction
		INNER JOIN
			dbo.EventATAccessUserTypes EUT WITH (NOLOCK)
			ON
				EAMA.PK_EventATAccessUserType = EUT.PK_EventATAccessUserType
		WHERE
			EUT.PK_EventATAccessUserType = COALESCE(@PK_EventATAccessUserType, EUT.PK_EventATAccessUserType)		
		ORDER BY 1
		
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

