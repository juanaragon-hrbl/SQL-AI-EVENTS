CREATE PROCEDURE [dbo].[usp_MyHLEventAPI_Get_SubEventGroups] 
		-- Error Parameters
		@Error int = 0 OUTPUT
		,@ErrorMessage varchar(4000) = '' OUTPUT

		-- QA/DEV
		,@IsDevQA bit = 0

AS
BEGIN
/******************************************************************************
OBJECT:		dbo.usp_MyHLEventAPI_Get_SubEventGroups

USE:		
		DECLARE @e int, @em varchar(4000)
		EXEC dbo.usp_MyHLEventAPI_Get_SubEventGroups
			@Error = @e OUTPUT				-- @e must be defined in the local call   
			,@ErrorMessage = @em OUTPUT		-- @em must be defined in the local call   
			,@IsDevQA = 1  
					
		SELECT @e, @em


DESCRIPTION:	Get the SubEventGroups Dropdown

NOTES:			

DEPENDENCIES
--------------------------------------------------------------------
SQL SERVER 2008

VERSIONS
--------------------------------------------------------------------
1.0.0	2016-11-22		SushmaA 		Initial
1.1.0	2019-08-14		NoeG			Refactor code (SRE)
1.2.0	2023-05-18		puertac			US 1254550 - Grouping funcionality adding new SubEventGroup(s)																		  

******************************************************************************/
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON
	SET NOCOUNT ON

	DECLARE @StoredProcedure varchar(255) = OBJECT_NAME(@@PROCID)
			,@StartTime datetime2 = GETUTCDATE();
	
	SELECT @Error = 0, @ErrorMessage = '';

	BEGIN TRY


		SELECT SE.SubEventGroupName
			  ,SE.DisplayOrder
			  ,SE.PK_SubEventGroup
			  ,SE.SubEventGroup
		FROM dbo.SubEventGroup SE WITH (NOLOCK)
		WHERE IsActive = 1
		ORDER BY SubEventGroupName ASC


		-- Update processing Log
		EXEC [dbo].[usp_Utility_UpdateProcessingLog]
			@StoredProcedureName = @StoredProcedure
			,@StartTime = @StartTime


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
		 
	END CATCH

END