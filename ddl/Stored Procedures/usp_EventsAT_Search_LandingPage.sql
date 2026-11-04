
CREATE PROCEDURE [dbo].[usp_EventsAT_Search_LandingPage]			

		-- Error Parameters
		@Error	int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN

/*
OBJECT:			dbo.usp_EventsAT_Search_LandingPage

USE:			
	DECLARE @e int, @em varchar(4000)   

		EXEC [usp_EventsAT_Search_LandingPage]
			@Error = @e OUTPUT				-- @e must be defined in the local call   
			,@ErrorMessage = @em OUTPUT		-- @em must be defined in the local call   
			,@IsDevQA = 1  

		Print @em  

DESCRIPTION:	Search Landing Page Title

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008
dbo.EventGroups

VERSIONS
--------------------------------------------------------------------
1	2015-11-19			SandhyaP			Initial 
*/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY

		-- Get the Landing Page Title/Summary

		SELECT EG.PK_EventGroup, 
			   EG.EventGroupName, 
			   EG.EventGroupName + ' - ' + CONVERT(VARCHAR, EG.PK_EventGroup) EventGroup,
			   EG.EventGroupDesc, 
			   EG.PK_DefaultLocale,
			   EG.CreatedDateUTC,
			   EG.CreatedBy,
			   EG.ModifiedDateUTC,
			   EG.ModifiedBy
		FROM 
		dbo.EventGroups EG WITH (NOLOCK)
		
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

